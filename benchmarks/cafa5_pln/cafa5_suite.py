#!/usr/bin/env python3
"""Pinned CAFA5 partial-knowledge setup and WM-PLN fusion harness."""

from __future__ import annotations

import argparse
import csv
import hashlib
import heapq
import json
import math
import os
import re
import shutil
import sqlite3
import subprocess
import sys
import sysconfig
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterator, Protocol, Sequence


SUITE_DIR = Path(__file__).resolve().parent
REPO_ROOT = SUITE_DIR.parents[1]
MANIFEST_PATH = SUITE_DIR / "benchmark_manifest.json"
ANNOTATION_HEADER = ["EntryID", "term", "aspect"]
ASPECTS = ("BPO", "CCO", "MFO")


@dataclass(frozen=True)
class SourceSpec:
    source: str
    dependence_group: str
    path: Path


@dataclass(frozen=True)
class CalibrationArtifact:
    """Pinned executable logistic calibration for one predictor source."""

    calibration_id: str
    sha256: str
    path: Path
    slope: float
    intercept: float

    def apply(self, score: float) -> float:
        """Apply the pinned monotone logistic map without overflow."""

        value = self.intercept + self.slope * score
        if value >= 0.0:
            return 1.0 / (1.0 + math.exp(-value))
        exponential = math.exp(value)
        return exponential / (1.0 + exponential)


@dataclass(frozen=True)
class FusionSpec:
    """Semantics required by a fusion reducer, independent of its runtime."""

    policy: str = "conservative-max"
    calibrations: dict[str, CalibrationArtifact] = field(default_factory=dict)
    independent_group_pairs: frozenset[tuple[str, str]] = frozenset()


@dataclass(frozen=True)
class EvaluationInputs:
    ground_truth: Path
    known_annotations: Path
    result_kind: str


class FusionReducerBackend(Protocol):
    """Benchmark-side adapter boundary for a load-bearing grouped reducer."""

    name: str

    def fuse(
        self,
        sources: Sequence[SourceSpec],
        output_tsv: Path,
        trail_jsonl: Path,
        workspace: Path,
        fusion_spec: FusionSpec,
    ) -> dict:
        ...


def load_manifest() -> dict:
    return json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))


def file_digest(path: Path, algorithm: str = "sha256") -> str:
    digest = hashlib.new(algorithm)
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def prefixed_file_digest(path: Path, prefix: bytes, algorithm: str = "sha256") -> str:
    digest = hashlib.new(algorithm)
    digest.update(prefix)
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def require_fresh_directory(path: Path) -> None:
    if path.exists() and any(path.iterdir()):
        raise FileExistsError(f"refusing to overwrite non-empty run directory: {path}")
    path.mkdir(parents=True, exist_ok=True)


def iter_annotation_rows(path: Path) -> Iterator[tuple[str, str, str]]:
    with path.open(newline="", encoding="utf-8") as stream:
        reader = csv.reader(stream, delimiter="\t")
        for row_number, row in enumerate(reader, start=1):
            if not row:
                continue
            if row_number == 1 and row[:3] == ANNOTATION_HEADER:
                continue
            if len(row) < 3:
                raise ValueError(f"{path}:{row_number}: expected at least three columns")
            yield row[0], row[1], row[2]


def iter_prediction_rows(path: Path) -> Iterator[tuple[str, str, float]]:
    with path.open(newline="", encoding="utf-8") as stream:
        reader = csv.reader(stream, delimiter="\t")
        for row_number, row in enumerate(reader, start=1):
            if not row:
                continue
            if row_number == 1 and row[0].lower() in {"entryid", "protein", "target"}:
                continue
            if len(row) < 3:
                raise ValueError(f"{path}:{row_number}: expected protein, term, score")
            try:
                score = float(row[2])
            except ValueError as exc:
                raise ValueError(f"{path}:{row_number}: invalid score {row[2]!r}") from exc
            if not math.isfinite(score) or not 0.0 <= score <= 1.0:
                raise ValueError(
                    f"{path}:{row_number}: score outside finite [0,1]: {score!r}"
                )
            yield row[0], row[1], score


def safe_metta_symbol(value: str) -> str:
    if value.startswith("GO:") and value[3:].isdigit():
        return f"go-{value[3:]}"
    if not re.fullmatch(r"[A-Za-z0-9_-]+", value):
        raise ValueError(f"identifier cannot be represented as an unquoted MeTTa symbol: {value!r}")
    return value


def validate_source_specs(sources: Sequence[SourceSpec]) -> None:
    if not sources:
        raise ValueError("at least one prediction source is required")
    labels = Counter(spec.source for spec in sources)
    duplicates = sorted(source for source, count in labels.items() if count > 1)
    if duplicates:
        raise ValueError(f"duplicate source labels: {duplicates}")
    for spec in sources:
        safe_metta_symbol(spec.source)
        safe_metta_symbol(spec.dependence_group)


def canonical_group_pair(left: str, right: str) -> tuple[str, str]:
    if left == right:
        raise ValueError("an independence declaration requires two distinct groups")
    return tuple(sorted((left, right)))


def load_calibration_artifact(
    path: Path, expected_id: str, expected_sha256: str
) -> CalibrationArtifact:
    """Load, pin, and validate an executable calibration transform."""

    if not re.fullmatch(r"[0-9a-f]{64}", expected_sha256):
        raise ValueError(f"invalid calibration artifact sha256: {expected_sha256!r}")
    path = path.resolve()
    if not path.is_file():
        raise FileNotFoundError(path)
    actual = file_digest(path)
    if actual != expected_sha256:
        raise ValueError(
            f"calibration artifact sha256 mismatch: {actual} != {expected_sha256}"
        )
    document = json.loads(path.read_text(encoding="utf-8"))
    if document.get("schema_version") != 1:
        raise ValueError("calibration artifact schema_version must be 1")
    if document.get("calibration_id") != expected_id:
        raise ValueError("calibration artifact identifier does not match its declaration")
    if document.get("method") != "logistic":
        raise ValueError("calibration artifact method must be logistic")
    try:
        slope = float(document["slope"])
        intercept = float(document["intercept"])
    except (KeyError, TypeError, ValueError) as exc:
        raise ValueError("logistic calibration requires numeric slope and intercept") from exc
    if not math.isfinite(slope) or slope <= 0.0:
        raise ValueError("logistic calibration slope must be finite and positive")
    if not math.isfinite(intercept):
        raise ValueError("logistic calibration intercept must be finite")
    return CalibrationArtifact(
        expected_id, expected_sha256, path, slope=slope, intercept=intercept
    )


def calibrated_score(fusion_spec: FusionSpec, source: str, score: float) -> float:
    if fusion_spec.policy == "conservative-max":
        return score
    return fusion_spec.calibrations[source].apply(score)


def validate_fusion_spec(sources: Sequence[SourceSpec], fusion_spec: FusionSpec) -> None:
    validate_source_specs(sources)
    if fusion_spec.policy == "conservative-max":
        if fusion_spec.calibrations or fusion_spec.independent_group_pairs:
            raise ValueError(
                "conservative-max does not consume calibration or independence declarations"
            )
        return
    if fusion_spec.policy != "calibrated-noisy-or":
        raise ValueError(f"unknown fusion policy: {fusion_spec.policy}")

    source_labels = {spec.source for spec in sources}
    if set(fusion_spec.calibrations) != source_labels:
        missing = sorted(source_labels - set(fusion_spec.calibrations))
        extra = sorted(set(fusion_spec.calibrations) - source_labels)
        raise ValueError(
            f"calibration declaration must match sources; missing={missing}, extra={extra}"
        )
    for source, artifact in fusion_spec.calibrations.items():
        if not artifact.calibration_id:
            raise ValueError(f"source {source} has an empty calibration identifier")
        loaded = load_calibration_artifact(
            artifact.path, artifact.calibration_id, artifact.sha256
        )
        if loaded.slope != artifact.slope or loaded.intercept != artifact.intercept:
            raise ValueError(
                f"source {source} executable calibration parameters differ from its pin"
            )
    calibration_ids = {
        artifact.calibration_id for artifact in fusion_spec.calibrations.values()
    }
    if len(calibration_ids) != 1:
        raise ValueError(
            "calibrated-noisy-or sources must share one calibration regime identifier"
        )

    groups = sorted({spec.dependence_group for spec in sources})
    required_pairs = {
        canonical_group_pair(groups[left], groups[right])
        for left in range(len(groups))
        for right in range(left + 1, len(groups))
    }
    if fusion_spec.independent_group_pairs != frozenset(required_pairs):
        missing = sorted(required_pairs - set(fusion_spec.independent_group_pairs))
        extra = sorted(set(fusion_spec.independent_group_pairs) - required_pairs)
        raise ValueError(
            "calibrated-noisy-or requires an explicit declaration for every and only "
            f"cross-group pair; missing={missing}, extra={extra}"
        )


def load_fusion_spec(policy: str, declaration_path: Path | None) -> FusionSpec:
    if policy == "conservative-max":
        if declaration_path is not None:
            raise ValueError("conservative-max does not accept a fusion declaration")
        return FusionSpec()
    if policy != "calibrated-noisy-or":
        raise ValueError(f"unknown fusion policy: {policy}")
    if declaration_path is None:
        raise ValueError("calibrated-noisy-or requires --fusion-declaration")

    document = json.loads(declaration_path.read_text(encoding="utf-8"))
    if document.get("schema_version") != 1:
        raise ValueError("fusion declaration schema_version must be 1")
    if document.get("policy") != policy:
        raise ValueError("fusion declaration policy does not match the requested policy")
    calibration_entries = document.get("calibrations", {})
    if not isinstance(calibration_entries, dict):
        raise ValueError("fusion declaration calibrations must be an object")
    calibrations = {}
    for source, entry in calibration_entries.items():
        if not isinstance(entry, dict):
            raise ValueError(f"calibration entry for {source} must be an object")
        artifact_path = (declaration_path.resolve().parent / entry["artifact"]).resolve()
        calibrations[source] = load_calibration_artifact(
            artifact_path,
            entry["calibration_id"],
            entry["artifact_sha256"],
        )
    raw_pairs = document.get("independent_group_pairs", [])
    if not isinstance(raw_pairs, list) or any(
        not isinstance(pair, list)
        or len(pair) != 2
        or not all(isinstance(group, str) for group in pair)
        for pair in raw_pairs
    ):
        raise ValueError("independence pairs must be two-element string arrays")
    pairs = frozenset(canonical_group_pair(pair[0], pair[1]) for pair in raw_pairs)
    if len(pairs) != len(raw_pairs):
        raise ValueError("independence pairs must be unique two-element group pairs")
    return FusionSpec(policy, calibrations, pairs)


def verify_dataset_archive(data_root: Path, manifest_key: str) -> dict:
    archive_meta = load_manifest()["dataset"][manifest_key]
    archive = data_root / "downloads" / archive_meta["name"]
    if not archive.is_file():
        raise FileNotFoundError(archive)
    if archive.stat().st_size != archive_meta["bytes"]:
        raise ValueError(
            f"archive byte count mismatch: {archive.stat().st_size} != {archive_meta['bytes']}"
        )
    algorithm, expected = archive_meta["checksum"].split(":", 1)
    actual = file_digest(archive, algorithm)
    if actual != expected:
        raise ValueError(f"archive {algorithm} mismatch: {actual} != {expected}")
    return {
        "name": archive.name,
        "bytes": archive.stat().st_size,
        algorithm: actual,
    }


def verify_install(data_root: Path, evaluator_root: Path) -> dict:
    manifest = load_manifest()
    evaluation = data_root / "evaluation"
    archive = verify_dataset_archive(data_root, "archive")

    required = []
    for name in manifest["dataset"]["required_files"]:
        path = evaluation / name
        if not path.is_file():
            raise FileNotFoundError(path)
        required.append(
            {"name": name, "bytes": path.stat().st_size, "sha256": file_digest(path)}
        )

    commit = subprocess.run(
        ["git", "-C", str(evaluator_root), "rev-parse", "HEAD"],
        check=True,
        text=True,
        capture_output=True,
    ).stdout.strip()
    expected_commit = manifest["evaluator"]["commit"]
    if commit != expected_commit:
        raise ValueError(f"evaluator commit mismatch: {commit} != {expected_commit}")

    return {
        "dataset_doi": manifest["dataset"]["doi"],
        "archive": archive,
        "required_files": required,
        "evaluator_commit": commit,
    }


def deterministic_targets(ground_truth: Path, count: int, seed: str) -> list[str]:
    proteins = {protein for protein, _, _ in iter_annotation_rows(ground_truth)}
    ranked = sorted(
        proteins,
        key=lambda protein: (hashlib.sha256(f"{seed}\0{protein}".encode()).digest(), protein),
    )
    if count <= 0 or count > len(ranked):
        raise ValueError(f"target count must be in [1,{len(ranked)}], got {count}")
    return ranked[:count]


def write_annotation_subset(source: Path, destination: Path, proteins: set[str]) -> int:
    rows = 0
    with destination.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.writer(stream, delimiter="\t", lineterminator="\n")
        writer.writerow(ANNOTATION_HEADER)
        for protein, term, aspect in iter_annotation_rows(source):
            if protein in proteins:
                writer.writerow((protein, term, aspect))
                rows += 1
    return rows


def make_t0_frequency_smoke(
    data_root: Path,
    output: Path,
    target_count: int,
    terms_per_aspect: int,
    seed: str,
) -> dict:
    require_fresh_directory(output)
    evaluation = data_root / "evaluation"
    known_path = evaluation / "known_t0.tsv"
    ground_truth_path = evaluation / "eval_terms_partial_2025_03.tsv"
    toi_path = evaluation / "toi_2025_03.tsv"

    targets = deterministic_targets(ground_truth_path, target_count, seed)
    target_set = set(targets)
    terms_of_interest = {
        line.strip() for line in toi_path.read_text(encoding="utf-8").splitlines() if line.strip()
    }

    term_counts: Counter[tuple[str, str]] = Counter()
    aspect_proteins: dict[str, set[str]] = defaultdict(set)
    target_known: dict[str, set[str]] = defaultdict(set)
    for protein, term, aspect in iter_annotation_rows(known_path):
        if aspect not in ASPECTS or term not in terms_of_interest:
            continue
        term_counts[(aspect, term)] += 1
        aspect_proteins[aspect].add(protein)
        if protein in target_set:
            target_known[protein].add(term)

    ranked_terms: dict[str, list[tuple[str, float]]] = {}
    for aspect in ASPECTS:
        denominator = len(aspect_proteins[aspect])
        if denominator == 0:
            raise ValueError(f"no known proteins for aspect {aspect}")
        candidates = [
            (term, count / denominator)
            for (candidate_aspect, term), count in term_counts.items()
            if candidate_aspect == aspect
        ]
        candidates.sort(key=lambda item: (-item[1], item[0]))
        ranked_terms[aspect] = candidates[:terms_per_aspect]

    predictions_dir = output / "predictions"
    predictions_dir.mkdir()
    prediction_path = predictions_dir / "t0_frequency_smoke.tsv"
    metta_path = output / "t0_frequency_smoke.metta"
    prediction_rows = 0
    first_packet: tuple[str, str, float] | None = None
    with prediction_path.open("w", newline="", encoding="utf-8") as pred_stream, metta_path.open(
        "w", encoding="utf-8"
    ) as metta_stream:
        pred_writer = csv.writer(pred_stream, delimiter="\t", lineterminator="\n")
        metta_stream.write("; Generated only from known_t0.tsv; final labels are not read here.\n")
        for protein in sorted(targets):
            known = target_known[protein]
            for aspect in ASPECTS:
                for term, score in ranked_terms[aspect]:
                    if term in known:
                        continue
                    pred_writer.writerow((protein, term, f"{score:.12g}"))
                    metta_stream.write(
                        "(cafa-prediction t0-frequency annotations-shared "
                        f"{safe_metta_symbol(protein)} {safe_metta_symbol(term)} "
                        f"{score:.12g})\n"
                    )
                    if first_packet is None:
                        first_packet = (protein, term, score)
                    prediction_rows += 1

    ground_truth_subset = output / "eval_terms_partial_smoke.tsv"
    known_subset = output / "known_t0_smoke.tsv"
    ground_truth_rows = write_annotation_subset(
        ground_truth_path, ground_truth_subset, target_set
    )
    known_rows = write_annotation_subset(known_path, known_subset, target_set)
    if first_packet is None:
        raise ValueError("smoke baseline produced no prediction packets")

    result = {
        "kind": "deterministic-real-data-smoke-not-a-benchmark-result",
        "selection": {
            "algorithm": "sha256(seed + NUL + protein)",
            "seed": seed,
            "target_count": len(targets),
            "target_list_sha256": hashlib.sha256(
                "\n".join(sorted(targets)).encode()
            ).hexdigest(),
        },
        "training_input": "known_t0.tsv only",
        "ground_truth_use": "target membership and evaluator subset only",
        "terms_per_aspect": terms_per_aspect,
        "prediction_rows": prediction_rows,
        "ground_truth_rows": ground_truth_rows,
        "known_rows": known_rows,
        "first_packet": {
            "source": "t0-frequency",
            "dependence_group": "annotations-shared",
            "protein": first_packet[0],
            "term": first_packet[1],
            "score": first_packet[2],
        },
        "files": {
            "predictions": prediction_path.relative_to(output).as_posix(),
            "metta_packets": metta_path.relative_to(output).as_posix(),
            "ground_truth": ground_truth_subset.relative_to(output).as_posix(),
            "known": known_subset.relative_to(output).as_posix(),
        },
    }
    (output / "smoke_manifest.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    return result


class SQLiteDifferentialOracle:
    """Reference reducer used to check, not define, the CeTTa implementation."""

    name = "sqlite-differential-oracle"

    def fuse(
        self,
        sources: Sequence[SourceSpec],
        output_tsv: Path,
        trail_jsonl: Path,
        workspace: Path,
        fusion_spec: FusionSpec,
    ) -> dict:
        validate_fusion_spec(sources, fusion_spec)
        if workspace.exists() or output_tsv.exists() or trail_jsonl.exists():
            raise FileExistsError("fusion outputs must not already exist")
        output_tsv.parent.mkdir(parents=True, exist_ok=True)
        trail_jsonl.parent.mkdir(parents=True, exist_ok=True)

        connection = sqlite3.connect(workspace)
        try:
            connection.execute(
                "CREATE TABLE packets (protein TEXT NOT NULL, term TEXT NOT NULL, "
                "dep_group TEXT NOT NULL, source TEXT NOT NULL, "
                "raw_score REAL NOT NULL, score REAL NOT NULL)"
            )
            connection.execute(
                "CREATE TEMP TABLE source_packets (protein TEXT NOT NULL, "
                "term TEXT NOT NULL, raw_score REAL NOT NULL, score REAL NOT NULL)"
            )
            input_rows = 0
            packet_rows = 0
            exact_duplicates = 0
            for spec in sources:
                batch = []
                source_input_rows = 0
                for protein, term, score in iter_prediction_rows(spec.path):
                    batch.append(
                        (
                            protein,
                            term,
                            score,
                            calibrated_score(fusion_spec, spec.source, score),
                        )
                    )
                    source_input_rows += 1
                    if len(batch) == 50_000:
                        connection.executemany(
                            "INSERT INTO source_packets VALUES (?,?,?,?)", batch
                        )
                        batch.clear()
                if batch:
                    connection.executemany(
                        "INSERT INTO source_packets VALUES (?,?,?,?)", batch
                    )
                input_rows += source_input_rows

                conflicting = connection.execute(
                    "SELECT protein, term, MIN(raw_score), MAX(raw_score), COUNT(*) "
                    "FROM source_packets GROUP BY protein, term "
                    "HAVING MIN(raw_score) != MAX(raw_score) LIMIT 1"
                ).fetchone()
                if conflicting is not None:
                    protein, term, low, high, count = conflicting
                    raise ValueError(
                        "conflicting duplicate prediction for "
                        f"source={spec.source}, protein={protein}, term={term}: "
                        f"{count} rows span {low} to {high}"
                    )
                duplicate_count = connection.execute(
                    "SELECT COALESCE(SUM(n - 1), 0) FROM "
                    "(SELECT COUNT(*) AS n FROM source_packets GROUP BY protein, term)"
                ).fetchone()[0]
                exact_duplicates += int(duplicate_count)
                before = connection.total_changes
                connection.execute(
                    "INSERT INTO packets "
                    "SELECT protein, term, ?, ?, MIN(raw_score), MIN(score) "
                    "FROM source_packets GROUP BY protein, term",
                    (spec.dependence_group, spec.source),
                )
                packet_rows += connection.total_changes - before
                connection.execute("DELETE FROM source_packets")
            connection.commit()
            connection.execute(
                "CREATE INDEX packets_order ON packets "
                "(protein, term, dep_group, score DESC, source)"
            )

            cursor = connection.execute(
                "SELECT protein, term, dep_group, source, raw_score, score FROM packets "
                "ORDER BY protein, term, dep_group, score DESC, source"
            )
            candidate_rows = 0
            with output_tsv.open("w", newline="", encoding="utf-8") as pred_stream, trail_jsonl.open(
                "w", encoding="utf-8"
            ) as trail_stream:
                writer = csv.writer(pred_stream, delimiter="\t", lineterminator="\n")
                current_candidate: tuple[str, str] | None = None
                current_group: str | None = None
                group_packets: list[dict] = []
                groups: list[dict] = []

                def finish_group() -> None:
                    nonlocal group_packets, current_group
                    if current_group is None:
                        return
                    groups.append(
                        {
                            "group": current_group,
                            "max_score": group_packets[0]["score"],
                            "packets": group_packets,
                        }
                    )
                    group_packets = []

                def finish_candidate() -> None:
                    nonlocal candidate_rows, groups
                    if current_candidate is None:
                        return
                    if fusion_spec.policy == "conservative-max":
                        score = max(group["max_score"] for group in groups)
                    elif fusion_spec.policy == "calibrated-noisy-or":
                        score = 0.0
                        for group in groups:
                            score = 1.0 - (1.0 - score) * (1.0 - group["max_score"])
                    else:
                        raise AssertionError(fusion_spec.policy)
                    protein, term = current_candidate
                    writer.writerow((protein, term, f"{score:.12g}"))
                    trail = {
                        "protein": protein,
                        "term": term,
                        "score": score,
                        "policy": fusion_spec.policy,
                        "within_group": "maximum",
                        "between_groups": (
                            "maximum"
                            if fusion_spec.policy == "conservative-max"
                            else "noisy-or-over-declared-independent-groups"
                        ),
                        "duplicate_semantics": (
                            "identical-source-candidate-scores-idempotent; "
                            "conflicting-source-candidate-scores-rejected"
                        ),
                        "groups": groups,
                    }
                    if fusion_spec.calibrations:
                        trail["calibrations"] = {
                            source: {
                                "calibration_id": artifact.calibration_id,
                                "artifact_sha256": artifact.sha256,
                                "method": "logistic",
                                "slope": artifact.slope,
                                "intercept": artifact.intercept,
                            }
                            for source, artifact in sorted(
                                fusion_spec.calibrations.items()
                            )
                        }
                    trail_stream.write(json.dumps(trail, sort_keys=True) + "\n")
                    candidate_rows += 1
                    groups = []

                for protein, term, dep_group, source, raw_score, score in cursor:
                    candidate = (protein, term)
                    if current_candidate is not None and candidate != current_candidate:
                        finish_group()
                        finish_candidate()
                        current_group = None
                    if current_group is not None and dep_group != current_group:
                        finish_group()
                    current_candidate = candidate
                    current_group = dep_group
                    group_packets.append(
                        {
                            "source": source,
                            "raw_score": raw_score,
                            "score": score,
                        }
                    )

                finish_group()
                finish_candidate()

            return {
                "backend": self.name,
                "backend_role": "differential-oracle",
                "fusion_policy": fusion_spec.policy,
                "input_rows": input_rows,
                "packet_rows": packet_rows,
                "exact_duplicate_rows_collapsed": exact_duplicates,
                "candidate_rows": candidate_rows,
                "prediction_sha256": file_digest(output_tsv),
                "trail_sha256": file_digest(trail_jsonl),
            }
        finally:
            connection.close()


def parse_cetta_forms(text: str) -> list:
    """Parse the small canonical S-expression subset emitted by CeTTa."""

    tokens = re.findall(r'\[|\]|\(|\)|"(?:\\.|[^"\\])*"|[^\s\[\]()]+', text)
    position = 0

    def parse_one():
        nonlocal position
        if position >= len(tokens):
            raise ValueError("unexpected end of CeTTa output")
        token = tokens[position]
        position += 1
        if token in {"(", "["}:
            closing = ")" if token == "(" else "]"
            values = []
            while position < len(tokens) and tokens[position] != closing:
                values.append(parse_one())
            if position >= len(tokens):
                raise ValueError("unterminated form in CeTTa output")
            position += 1
            return values
        if token in {")",
            "]",
        }:
            raise ValueError(f"unexpected closing delimiter {token}")
        if token.startswith('"'):
            return json.loads(token)
        return token

    forms = []
    while position < len(tokens):
        forms.append(parse_one())
    return forms


def find_named_forms(tree, name: str) -> list[list]:
    found = []
    if isinstance(tree, list):
        if tree and tree[0] == name:
            found.append(tree)
        for child in tree:
            found.extend(find_named_forms(child, name))
    return found


class CeTTaGroupFoldReducer:
    """Load-bearing CAFA reducer over CeTTa's audited group-fold surface."""

    name = "cetta-group-fold"

    def __init__(
        self,
        cetta: Path,
        python_lib_dir: Path | None = None,
        run_size: int = 10_000,
        shard_count: int = 256,
        max_shard_packets: int = 500_000,
    ) -> None:
        self.cetta = cetta
        self.python_lib_dir = python_lib_dir
        self.run_size = run_size
        self.shard_count = shard_count
        self.max_shard_packets = max_shard_packets
        if run_size <= 0 or shard_count <= 0 or max_shard_packets <= 0:
            raise ValueError("CeTTa reducer sizes must be positive")

    def _run(self, workload: Path, source: str) -> tuple[str, str]:
        if workload.exists():
            raise FileExistsError(workload)
        workload.write_text(source, encoding="utf-8")
        environment = os.environ.copy()
        lib_dir = self.python_lib_dir or Path(sysconfig.get_config_var("LIBDIR") or "")
        if lib_dir:
            existing = environment.get("LD_LIBRARY_PATH", "")
            environment["LD_LIBRARY_PATH"] = (
                f"{lib_dir}:{existing}" if existing else str(lib_dir)
            )
        process = subprocess.run(
            [
                str(self.cetta),
                "--profile",
                "he-extended",
                "--lang",
                "he",
                str(workload),
            ],
            cwd=REPO_ROOT,
            env=environment,
            text=True,
            capture_output=True,
            check=True,
        )
        stdout_path = workload.with_suffix(workload.suffix + ".stdout")
        stderr_path = workload.with_suffix(workload.suffix + ".stderr")
        stdout_path.write_text(process.stdout, encoding="utf-8")
        stderr_path.write_text(process.stderr, encoding="utf-8")
        return process.stdout, file_digest(workload)

    @staticmethod
    def _parse_group_results(output: str, key_arity: int) -> dict[tuple[str, ...], dict]:
        results = {}
        for form in find_named_forms(parse_cetta_forms(output), "group-result"):
            if len(form) != 4 or not isinstance(form[1], list):
                raise ValueError(f"malformed CeTTa group-result: {form}")
            key_form = form[1]
            if len(key_form) != key_arity + 1 or key_form[0] != "candidate":
                raise ValueError(f"unexpected CeTTa candidate key: {key_form}")
            audit = form[3]
            if (
                not isinstance(audit, list)
                or len(audit) != 3
                or audit[0] != "group-audit"
                or not re.fullmatch(r"[0-9a-f]{64}", audit[2])
            ):
                raise ValueError(f"malformed CeTTa group audit: {audit}")
            key = tuple(key_form[1:])
            if key in results:
                raise ValueError(f"duplicate CeTTa group-result key: {key}")
            accumulator = form[2]
            if isinstance(accumulator, list):
                if not accumulator or accumulator[0] != "calibrated-probability":
                    raise ValueError(f"unexpected CeTTa accumulator: {accumulator}")
                score = float(accumulator[-1])
            else:
                score = float(accumulator)
            results[key] = {
                "score": score,
                "audit_count": int(audit[1]),
                "audit_sha256": audit[2],
            }
        return results

    @staticmethod
    def _protein_shard(protein: str, shard_count: int) -> int:
        digest = hashlib.sha256(protein.encode("utf-8")).digest()
        return int.from_bytes(digest[:8], "big") % shard_count

    @staticmethod
    def _merge_prediction_shards(paths: Sequence[Path], destination: Path) -> int:
        streams = [path.open(newline="", encoding="utf-8") for path in paths]
        readers = [csv.reader(stream, delimiter="\t") for stream in streams]
        heap: list[tuple[str, str, int, str]] = []
        try:
            for index, reader in enumerate(readers):
                row = next(reader, None)
                if row is not None:
                    if len(row) < 3:
                        raise ValueError(f"malformed shard prediction row: {row}")
                    heapq.heappush(heap, (row[0], row[1], index, row[2]))
            rows = 0
            previous: tuple[str, str] | None = None
            with destination.open("w", newline="", encoding="utf-8") as output:
                writer = csv.writer(output, delimiter="\t", lineterminator="\n")
                while heap:
                    protein, term, index, score = heapq.heappop(heap)
                    key = (protein, term)
                    if previous is not None and key <= previous:
                        raise ValueError(
                            f"shard prediction merge is not globally unique and ordered: {key}"
                        )
                    writer.writerow((protein, term, score))
                    previous = key
                    rows += 1
                    row = next(readers[index], None)
                    if row is not None:
                        if len(row) < 3:
                            raise ValueError(f"malformed shard prediction row: {row}")
                        heapq.heappush(heap, (row[0], row[1], index, row[2]))
            return rows
        finally:
            for stream in streams:
                stream.close()

    @staticmethod
    def _merge_trail_shards(paths: Sequence[Path], destination: Path) -> int:
        streams = [path.open(encoding="utf-8") for path in paths]
        heap: list[tuple[str, str, int, dict]] = []
        try:
            for index, stream in enumerate(streams):
                line = stream.readline()
                if line:
                    trail = json.loads(line)
                    heapq.heappush(
                        heap, (trail["protein"], trail["term"], index, trail)
                    )
            rows = 0
            previous: tuple[str, str] | None = None
            with destination.open("w", encoding="utf-8") as output:
                while heap:
                    protein, term, index, trail = heapq.heappop(heap)
                    key = (protein, term)
                    if previous is not None and key <= previous:
                        raise ValueError(
                            f"shard trail merge is not globally unique and ordered: {key}"
                        )
                    output.write(json.dumps(trail, sort_keys=True) + "\n")
                    previous = key
                    rows += 1
                    line = streams[index].readline()
                    if line:
                        next_trail = json.loads(line)
                        heapq.heappush(
                            heap,
                            (
                                next_trail["protein"],
                                next_trail["term"],
                                index,
                                next_trail,
                            ),
                        )
            return rows
        finally:
            for stream in streams:
                stream.close()

    def fuse(
        self,
        sources: Sequence[SourceSpec],
        output_tsv: Path,
        trail_jsonl: Path,
        workspace: Path,
        fusion_spec: FusionSpec,
    ) -> dict:
        validate_fusion_spec(sources, fusion_spec)
        if workspace.exists() or output_tsv.exists() or trail_jsonl.exists():
            raise FileExistsError("CeTTa fusion outputs must not already exist")
        output_tsv.parent.mkdir(parents=True, exist_ok=True)
        trail_jsonl.parent.mkdir(parents=True, exist_ok=True)
        workspace.mkdir(parents=True)
        spool = workspace / "input-shards"
        spool.mkdir()

        active_shards: set[int] = set()
        input_rows = 0
        for source_index, spec in enumerate(sources):
            streams: dict[int, object] = {}
            writers: dict[int, csv.writer] = {}
            try:
                for protein, term, score in iter_prediction_rows(spec.path):
                    shard = self._protein_shard(protein, self.shard_count)
                    if shard not in streams:
                        shard_dir = spool / f"{shard:04d}"
                        shard_dir.mkdir(exist_ok=True)
                        stream = (shard_dir / f"source-{source_index:04d}.tsv").open(
                            "w", newline="", encoding="utf-8"
                        )
                        streams[shard] = stream
                        writers[shard] = csv.writer(
                            stream, delimiter="\t", lineterminator="\n"
                        )
                    writers[shard].writerow((protein, term, f"{score:.12g}"))
                    active_shards.add(shard)
                    input_rows += 1
            finally:
                for stream in streams.values():
                    stream.close()
        if not active_shards:
            raise ValueError("no prediction packets were available for fusion")

        shard_root = workspace / "reduced-shards"
        shard_root.mkdir()
        prediction_shards: list[Path] = []
        trail_shards: list[Path] = []
        shard_summaries = []
        for shard in sorted(active_shards):
            shard_dir = spool / f"{shard:04d}"
            shard_sources = []
            for source_index, spec in enumerate(sources):
                path = shard_dir / f"source-{source_index:04d}.tsv"
                if not path.exists():
                    path.write_text("", encoding="utf-8")
                shard_sources.append(
                    SourceSpec(spec.source, spec.dependence_group, path)
                )
            reduced = shard_root / f"{shard:04d}"
            prediction = reduced / "predictions.tsv"
            trail = reduced / "trails.jsonl"
            summary = self._fuse_shard(
                shard_sources,
                prediction,
                trail,
                reduced / "work",
                fusion_spec,
            )
            summary["shard"] = shard
            prediction_shards.append(prediction)
            trail_shards.append(trail)
            shard_summaries.append(summary)

        candidate_rows = self._merge_prediction_shards(
            prediction_shards, output_tsv
        )
        trail_rows = self._merge_trail_shards(trail_shards, trail_jsonl)
        if candidate_rows != trail_rows:
            raise ValueError("prediction and trail shard merge counts differ")

        portable_shard_summaries = [
            {
                key: value
                for key, value in summary.items()
                if key
                not in {"stage1_workload_sha256", "stage2_workload_sha256"}
            }
            for summary in shard_summaries
        ]
        manifest = {
            "partition": "uint64-big-endian-prefix(sha256(protein)) modulo shard-count",
            "shard_count": self.shard_count,
            "active_shards": sorted(active_shards),
            "input_rows": input_rows,
            "shards": portable_shard_summaries,
        }
        manifest_path = workspace / "shard_manifest.json"
        manifest_path.write_text(
            json.dumps(manifest, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        return {
            "backend": self.name,
            "backend_role": "load-bearing-reducer",
            "fusion_policy": fusion_spec.policy,
            "input_rows": input_rows,
            "packet_rows": sum(item["packet_rows"] for item in shard_summaries),
            "exact_duplicate_rows_collapsed": sum(
                item["exact_duplicate_rows_collapsed"] for item in shard_summaries
            ),
            "group_rows": sum(item["group_rows"] for item in shard_summaries),
            "candidate_rows": candidate_rows,
            "partition_shards": self.shard_count,
            "active_shards": len(active_shards),
            "shard_manifest_sha256": file_digest(manifest_path),
            "prediction_sha256": file_digest(output_tsv),
            "trail_sha256": file_digest(trail_jsonl),
        }

    def _fuse_shard(
        self,
        sources: Sequence[SourceSpec],
        output_tsv: Path,
        trail_jsonl: Path,
        workspace: Path,
        fusion_spec: FusionSpec,
    ) -> dict:
        validate_fusion_spec(sources, fusion_spec)
        reserved = (workspace, output_tsv, trail_jsonl)
        if any(path.exists() for path in reserved):
            raise FileExistsError("CeTTa fusion outputs must not already exist")
        output_tsv.parent.mkdir(parents=True, exist_ok=True)
        trail_jsonl.parent.mkdir(parents=True, exist_ok=True)

        packets: dict[tuple[str, str, str], dict] = {}
        input_rows = 0
        exact_duplicates = 0
        encoded_proteins: dict[str, str] = {}
        encoded_terms: dict[str, str] = {}
        for spec in sources:
            for protein, term, score in iter_prediction_rows(spec.path):
                input_rows += 1
                key = (spec.source, protein, term)
                previous = packets.get(key)
                if previous is not None:
                    if previous["raw_score"] != score:
                        raise ValueError(
                            "conflicting duplicate prediction for "
                            f"source={spec.source}, protein={protein}, term={term}: "
                            f"{previous['raw_score']} != {score}"
                        )
                    exact_duplicates += 1
                    continue
                encoded_protein = safe_metta_symbol(protein)
                encoded_term = safe_metta_symbol(term)
                if encoded_protein in encoded_proteins and encoded_proteins[encoded_protein] != protein:
                    raise ValueError(f"protein symbol encoding collision: {protein}")
                if encoded_term in encoded_terms and encoded_terms[encoded_term] != term:
                    raise ValueError(f"term symbol encoding collision: {term}")
                encoded_proteins[encoded_protein] = protein
                encoded_terms[encoded_term] = term
                packets[key] = {
                    "source": spec.source,
                    "group": spec.dependence_group,
                    "protein": protein,
                    "term": term,
                    "encoded_protein": encoded_protein,
                    "encoded_term": encoded_term,
                    "raw_score": score,
                    "score": calibrated_score(fusion_spec, spec.source, score),
                }
                if len(packets) > self.max_shard_packets:
                    raise ValueError(
                        "CeTTa shard packet bound exceeded; increase shard_count so each "
                        "protein-local partition stays within the configured bound"
                    )
        if not packets:
            raise ValueError("no prediction packets were available for fusion")

        ordered_packets = sorted(
            packets.values(),
            key=lambda packet: (
                packet["encoded_protein"],
                packet["encoded_term"],
                packet["group"],
                -packet["score"],
                packet["source"],
            ),
        )
        workspace.mkdir(parents=True)
        stage1_records = workspace / "stage1.atom-lines"
        with stage1_records.open("w", encoding="utf-8") as stream:
            for packet in ordered_packets:
                stream.write(
                    "((candidate {protein} {term} {group}) ({source} {score}))\n".format(
                        protein=packet["encoded_protein"],
                        term=packet["encoded_term"],
                        group=packet["group"],
                        source=packet["source"],
                        score=f"{packet['score']:.12g}",
                    )
                )
        rule_library = os.path.relpath(
            (SUITE_DIR / "lib_cafa5_goal_chainer.metta").resolve(),
            workspace.resolve(),
        )
        stage1_source = f"""!(import! &self {rule_library})
!(collapse
  (group-fold
    ordered
    (fs:stream-atom-lines {json.dumps(str(stage1_records.resolve()))})
    0.0
    $acc
    $item
    (let ($key $payload) $item $key)
    (cafa-group-score-step $acc $item)))
"""
        bundle = workspace
        stage1_path = bundle / "stage1.metta"
        stage2_path = bundle / "stage2.metta"
        stage1_output, stage1_workload_sha = self._run(stage1_path, stage1_source)
        group_results = self._parse_group_results(stage1_output, key_arity=3)
        expected_group_keys = {
            (
                packet["encoded_protein"],
                packet["encoded_term"],
                packet["group"],
            )
            for packet in ordered_packets
        }
        if set(group_results) != expected_group_keys:
            raise ValueError(
                "CeTTa group maxima do not cover the expected candidate groups; "
                f"missing={sorted(expected_group_keys - set(group_results))[:5]}, "
                f"extra={sorted(set(group_results) - expected_group_keys)[:5]}, "
                f"stdout={stage1_output[:500]!r}"
            )
        expected_group_counts = Counter(
            (
                packet["encoded_protein"],
                packet["encoded_term"],
                packet["group"],
            )
            for packet in ordered_packets
        )
        for key, expected_count in expected_group_counts.items():
            actual_count = group_results[key]["audit_count"]
            if actual_count != expected_count:
                raise ValueError(
                    "CeTTa group certificate count differs from the packet frontier: "
                    f"key={key}, certificate={actual_count}, expected={expected_count}"
                )

        stage2_records = workspace / "stage2.atom-lines"
        with stage2_records.open("w", encoding="utf-8") as stream:
            for key, result in sorted(group_results.items()):
                protein, term, group = key
                stream.write(
                    f"((candidate {protein} {term}) ({group} {result['score']:.12g}))\n"
                )
        if fusion_spec.policy == "conservative-max":
            initial = "0.0"
            step = "(cafa-group-score-step $acc $item)"
        else:
            calibration_id = next(iter(fusion_spec.calibrations.values())).calibration_id
            safe_metta_symbol(calibration_id)
            initial = "(cafa-noisy-or-empty)"
            step = f"(cafa-calibrated-group-step {calibration_id} $acc $item)"
        stage2_source = f"""!(import! &self {rule_library})
!(collapse
  (group-fold
    ordered
    (fs:stream-atom-lines {json.dumps(str(stage2_records.resolve()))})
    {initial}
    $acc
    $item
    (let ($key $payload) $item $key)
    {step}))
"""
        stage2_output, stage2_workload_sha = self._run(stage2_path, stage2_source)
        candidate_results = self._parse_group_results(stage2_output, key_arity=2)
        expected_candidates = {(key[0], key[1]) for key in expected_group_keys}
        if set(candidate_results) != expected_candidates:
            raise ValueError("CeTTa fused results do not cover the expected candidates")
        expected_candidate_counts = Counter(key[:2] for key in expected_group_keys)
        for key, expected_count in expected_candidate_counts.items():
            actual_count = candidate_results[key]["audit_count"]
            if actual_count != expected_count:
                raise ValueError(
                    "CeTTa fusion certificate count differs from the group frontier: "
                    f"key={key}, certificate={actual_count}, expected={expected_count}"
                )

        by_candidate_group: dict[tuple[str, str, str], list[dict]] = defaultdict(list)
        for packet in ordered_packets:
            by_candidate_group[
                (
                    packet["encoded_protein"],
                    packet["encoded_term"],
                    packet["group"],
                )
            ].append(
                {
                    "source": packet["source"],
                    "raw_score": packet["raw_score"],
                    "score": packet["score"],
                }
            )

        with output_tsv.open("w", newline="", encoding="utf-8") as pred_stream, trail_jsonl.open(
            "w", encoding="utf-8"
        ) as trail_stream:
            writer = csv.writer(pred_stream, delimiter="\t", lineterminator="\n")
            decoded_order = sorted(
                candidate_results,
                key=lambda key: (
                    encoded_proteins[key[0]],
                    encoded_terms[key[1]],
                ),
            )
            for encoded_candidate in decoded_order:
                encoded_protein, encoded_term = encoded_candidate
                protein = encoded_proteins[encoded_protein]
                term = encoded_terms[encoded_term]
                final = candidate_results[encoded_candidate]
                writer.writerow((protein, term, f"{final['score']:.12g}"))
                groups = []
                for group_key in sorted(
                    key for key in group_results if key[:2] == encoded_candidate
                ):
                    group_result = group_results[group_key]
                    groups.append(
                        {
                            "group": group_key[2],
                            "max_score": group_result["score"],
                            "packets": by_candidate_group[group_key],
                            "audit": {
                                "count": group_result["audit_count"],
                                "sha256": group_result["audit_sha256"],
                            },
                        }
                    )
                trail = {
                    "protein": protein,
                    "term": term,
                    "score": final["score"],
                    "policy": fusion_spec.policy,
                    "within_group": "maximum",
                    "between_groups": (
                        "maximum"
                        if fusion_spec.policy == "conservative-max"
                        else "noisy-or-over-declared-independent-groups"
                    ),
                    "duplicate_semantics": (
                        "identical-source-candidate-scores-idempotent; "
                        "conflicting-source-candidate-scores-rejected"
                    ),
                    "groups": groups,
                    "fusion_audit": {
                        "count": final["audit_count"],
                        "sha256": final["audit_sha256"],
                    },
                }
                if fusion_spec.calibrations:
                    trail["calibrations"] = {
                        source: {
                            "calibration_id": artifact.calibration_id,
                            "artifact_sha256": artifact.sha256,
                            "method": "logistic",
                            "slope": artifact.slope,
                            "intercept": artifact.intercept,
                        }
                        for source, artifact in sorted(fusion_spec.calibrations.items())
                    }
                trail_stream.write(json.dumps(trail, sort_keys=True) + "\n")

        return {
            "backend": self.name,
            "backend_role": "load-bearing-reducer",
            "fusion_policy": fusion_spec.policy,
            "input_rows": input_rows,
            "packet_rows": len(packets),
            "exact_duplicate_rows_collapsed": exact_duplicates,
            "group_rows": len(group_results),
            "candidate_rows": len(candidate_results),
            "stage1_workload_sha256": stage1_workload_sha,
            "stage2_workload_sha256": stage2_workload_sha,
            "stage1_atom_lines_sha256": file_digest(stage1_records),
            "stage2_atom_lines_sha256": file_digest(stage2_records),
            "prediction_sha256": file_digest(output_tsv),
            "trail_sha256": file_digest(trail_jsonl),
        }


def get_reducer_backend(
    name: str,
    cetta: Path | None = None,
    python_lib_dir: Path | None = None,
    run_size: int = 10_000,
    shard_count: int = 256,
) -> FusionReducerBackend:
    if name == "sqlite-oracle":
        return SQLiteDifferentialOracle()
    if name == "cetta-group-fold":
        if cetta is None:
            raise ValueError("cetta-group-fold requires a CeTTa executable")
        return CeTTaGroupFoldReducer(
            cetta, python_lib_dir, run_size, shard_count
        )
    raise ValueError(f"unknown reducer backend: {name}")


def reducer_workspace(output: Path, backend_name: str) -> Path:
    return output / (
        "fusion.sqlite3" if backend_name == "sqlite-oracle" else "fusion-workspace"
    )


def fuse_prediction_files(
    sources: Sequence[SourceSpec],
    output_tsv: Path,
    trail_jsonl: Path,
    workspace: Path,
    fusion_spec: FusionSpec | None = None,
    reducer_backend: FusionReducerBackend | None = None,
) -> dict:
    """Fuse through the selected reducer and gate CeTTa on a real-shaped sample."""

    spec = fusion_spec or FusionSpec()
    backend = reducer_backend or SQLiteDifferentialOracle()
    result = backend.fuse(sources, output_tsv, trail_jsonl, workspace, spec)
    if result.get("backend_role") == "load-bearing-reducer":
        result["differential_oracle"] = run_differential_oracle_gate(
            sources,
            output_tsv,
            workspace / "differential-oracle-sample",
            spec,
        )
    return result


def compare_prediction_files(left: Path, right: Path, tolerance: float = 1e-12) -> dict:
    left_rows = {(p, t): s for p, t, s in iter_prediction_rows(left)}
    right_rows = {(p, t): s for p, t, s in iter_prediction_rows(right)}
    if left_rows.keys() != right_rows.keys():
        missing = sorted(left_rows.keys() - right_rows.keys())[:5]
        extra = sorted(right_rows.keys() - left_rows.keys())[:5]
        raise ValueError(f"prediction keys differ; missing={missing}, extra={extra}")
    maximum_error = max(
        (abs(left_rows[key] - right_rows[key]) for key in left_rows), default=0.0
    )
    if maximum_error > tolerance:
        raise ValueError(f"prediction scores differ by {maximum_error} > {tolerance}")
    return {"rows": len(left_rows), "maximum_absolute_error": maximum_error}


def deterministic_prediction_targets(
    sources: Sequence[SourceSpec], limit: int = 64
) -> list[str]:
    """Select a bounded, order-independent protein sample from prediction inputs."""

    if limit <= 0:
        raise ValueError("differential-oracle target limit must be positive")
    ranked: list[tuple[bytes, str]] = []
    selected: set[str] = set()
    for spec in sources:
        for protein, _, _ in iter_prediction_rows(spec.path):
            if protein in selected:
                continue
            rank = (
                hashlib.sha256(
                    f"cafa5-real-shaped-oracle-v1\0{protein}".encode("utf-8")
                ).digest(),
                protein,
            )
            if len(ranked) < limit:
                ranked.append(rank)
                ranked.sort()
                selected.add(protein)
            elif rank < ranked[-1]:
                selected.remove(ranked[-1][1])
                ranked[-1] = rank
                ranked.sort()
                selected.add(protein)
    if not ranked:
        raise ValueError("cannot construct a differential-oracle sample from empty inputs")
    return [protein for _, protein in ranked]


def run_differential_oracle_gate(
    sources: Sequence[SourceSpec],
    primary_output: Path,
    output: Path,
    fusion_spec: FusionSpec,
    target_limit: int = 64,
) -> dict:
    """Compare a deterministic real input slice against the independent SQLite reducer."""

    require_fresh_directory(output)
    proteins = deterministic_prediction_targets(sources, target_limit)
    protein_set = set(proteins)
    subset_dir = output / "sources"
    subset_dir.mkdir()
    subset_sources = []
    source_rows = {}
    for spec in sources:
        destination = subset_dir / f"{safe_metta_symbol(spec.source)}.tsv"
        rows = subset_prediction_file(spec.path, destination, protein_set)
        subset_sources.append(
            SourceSpec(spec.source, spec.dependence_group, destination)
        )
        source_rows[spec.source] = rows

    primary_subset = output / "cetta-primary.tsv"
    primary_rows = subset_prediction_file(primary_output, primary_subset, protein_set)
    oracle_output = output / "sqlite-oracle.tsv"
    oracle = SQLiteDifferentialOracle().fuse(
        subset_sources,
        oracle_output,
        output / "sqlite-oracle-trails.jsonl",
        output / "sqlite-oracle.sqlite3",
        fusion_spec,
    )
    comparison = compare_prediction_files(primary_subset, oracle_output)
    if comparison["rows"] != primary_rows:
        raise ValueError("differential-oracle comparison omitted primary candidates")
    target_digest = hashlib.sha256()
    for protein in proteins:
        encoded = protein.encode("utf-8")
        target_digest.update(len(encoded).to_bytes(8, "big"))
        target_digest.update(encoded)
    return {
        "status": "passed",
        "selection": "lowest-sha256(cafa5-real-shaped-oracle-v1, protein)",
        "target_limit": target_limit,
        "target_count": len(proteins),
        "target_sha256": target_digest.hexdigest(),
        "source_rows": source_rows,
        "primary_candidate_rows": primary_rows,
        "oracle": oracle,
        "comparison": comparison,
    }


def write_cetta_packets(sources: Sequence[SourceSpec], destination: Path) -> tuple[int, dict]:
    if destination.exists():
        raise FileExistsError(destination)
    validate_source_specs(sources)

    count = 0
    first_packet = None
    with destination.open("w", encoding="utf-8") as stream:
        stream.write("; Generated CAFA prediction packets for CeTTa proof audit.\n")
        for spec in sources:
            for protein, term, score in iter_prediction_rows(spec.path):
                stream.write(
                    f"(cafa-prediction {spec.source} {spec.dependence_group} "
                    f"{safe_metta_symbol(protein)} {safe_metta_symbol(term)} "
                    f"{score:.12g})\n"
                )
                if first_packet is None:
                    first_packet = {
                        "source": spec.source,
                        "dependence_group": spec.dependence_group,
                        "protein": protein,
                        "term": term,
                        "score": score,
                    }
                count += 1
    if first_packet is None:
        raise ValueError("no prediction packets were available for the CeTTa audit")
    return count, first_packet


def subset_prediction_file(source: Path, destination: Path, proteins: set[str]) -> int:
    if destination.exists():
        raise FileExistsError(destination)
    count = 0
    with destination.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.writer(stream, delimiter="\t", lineterminator="\n")
        for protein, term, score in iter_prediction_rows(source):
            if protein in proteins:
                writer.writerow((protein, term, f"{score:.12g}"))
                count += 1
    return count


def write_cetta_workload(
    output: Path, packet_file: Path, first_packet: dict
) -> Path:
    del output
    packet_hash = prefixed_file_digest(
        packet_file, b"cafa-goal-audit-v4\0"
    )[:16]
    bundle = REPO_ROOT / "runtime" / f"cafa5-real-smoke-{packet_hash}"
    bundle.mkdir(parents=True, exist_ok=True)
    local_packets = bundle / "cafa_packets.metta"
    if local_packets.exists():
        if file_digest(local_packets) != file_digest(packet_file):
            raise ValueError(f"CeTTa runtime packet bundle hash collision: {bundle}")
    else:
        with packet_file.open("rb") as source, local_packets.open("xb") as destination:
            shutil.copyfileobj(source, destination, length=1024 * 1024)
    workload = bundle / "real_smoke_goal_chainer.metta"
    protein = safe_metta_symbol(first_packet["protein"])
    term = safe_metta_symbol(first_packet["term"])
    source = safe_metta_symbol(first_packet["source"])
    group = safe_metta_symbol(first_packet["dependence_group"])
    score = first_packet["score"]
    packet_path = json.dumps(str(local_packets.resolve()))
    chainer_path = os.path.relpath(
        (SUITE_DIR / "lib_cafa5_goal_chainer.metta").resolve(), bundle.resolve()
    )
    rules_path = os.path.relpath(
        (SUITE_DIR / "cafa5_rules.metta").resolve(), bundle.resolve()
    )
    if any(character.isspace() for character in chainer_path + rules_path):
        raise ValueError("CeTTa import paths cannot contain whitespace")
    workload_text = f"""!(import! &self {chainer_path})
!(import! &cafa5-rb {rules_path})
!(bind! &cafa5-kb (new-space))
!(add-atom &cafa5-kb
  (cafa-prediction {source} {group} {protein} {term} {score:.12g}))

!(collapse
  (group-fold
    ordered
    (fs:stream-atom-lines {packet_path})
    0
    $acc
    $item
    all-packets
    (eval (+ $acc 1))))

!(collapse
   (let (: $proof
           (cafa-candidate {protein} {term} {group} {source} {score:.12g}))
        (bc &cafa5-kb &cafa5-rb (fromNumber 1)
            (: $proof
               (cafa-candidate {protein} {term} {group} {source} {score:.12g})))
     (cafa-real-proof (cafa-proof-packet $proof))))
"""
    if workload.exists():
        if workload.read_text(encoding="utf-8") != workload_text:
            raise ValueError(f"CeTTa runtime workload collision: {workload}")
    else:
        workload.write_text(workload_text, encoding="utf-8")
    return workload


def run_cetta_smoke(
    cetta: Path,
    output: Path,
    packet_file: Path,
    first_packet: dict,
    expected_count: int,
    python_lib_dir: Path | None,
) -> dict:
    workload = write_cetta_workload(output, packet_file, first_packet)
    environment = os.environ.copy()
    lib_dir = python_lib_dir or Path(sysconfig.get_config_var("LIBDIR") or "")
    if lib_dir:
        existing = environment.get("LD_LIBRARY_PATH", "")
        environment["LD_LIBRARY_PATH"] = f"{lib_dir}:{existing}" if existing else str(lib_dir)
    process = subprocess.run(
        [str(cetta), "--profile", "he-extended", "--lang", "he", str(workload)],
        cwd=REPO_ROOT,
        env=environment,
        text=True,
        capture_output=True,
        check=True,
    )
    (output / "cetta.stdout").write_text(process.stdout, encoding="utf-8")
    (output / "cetta.stderr").write_text(process.stderr, encoding="utf-8")
    match = re.search(
        r"group-result\s+all-packets\s+(\d+)\s+"
        r'\(group-audit\s+(\d+)\s+"([0-9a-f]{64})"\)',
        process.stdout,
    )
    if not match:
        raise ValueError("CeTTa output did not contain the packet group audit")
    accumulator_count = int(match.group(1))
    audit_count = int(match.group(2))
    if accumulator_count != expected_count or audit_count != expected_count:
        raise ValueError(
            "CeTTa packet group counts do not match the generated packet count: "
            f"accumulator={accumulator_count}, audit={audit_count}, "
            f"expected={expected_count}"
        )
    if "cafa-real-proof (cafa-prediction" not in process.stdout:
        raise ValueError("CeTTa output did not contain the requested concrete proof packet")
    return {
        "workload_sha256": file_digest(workload),
        "packet_audit_count": audit_count,
        "packet_audit_sha256": match.group(3),
        "concrete_proof_count": 1,
        "stdout_sha256": file_digest(output / "cetta.stdout"),
    }


def resolve_artifact_path(root: Path, value: str) -> Path:
    path = Path(value)
    return path if path.is_absolute() else root / path


def read_tsv_records(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    with path.open(newline="", encoding="utf-8") as stream:
        reader = csv.DictReader(stream, delimiter="\t")
        if reader.fieldnames is None:
            raise ValueError(f"TSV has no header: {path}")
        fieldnames = list(reader.fieldnames)
        rows = [dict(row) for row in reader]
    return fieldnames, rows


def canonical_tsv_semantic_digest(path: Path) -> str:
    """Hash TSV meaning independently of physical row and column order."""

    fieldnames, rows = read_tsv_records(path)
    columns = sorted(fieldnames)
    canonical_rows = sorted(
        ([row.get(column, "") for column in columns] for row in rows),
        key=lambda row: json.dumps(row, ensure_ascii=False, separators=(",", ":")),
    )
    payload = json.dumps(
        {"columns": columns, "rows": canonical_rows},
        ensure_ascii=False,
        separators=(",", ":"),
    ).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def select_best_evaluator_rows(
    rows: Sequence[dict[str, str]], metric: str, maximize: bool
) -> list[dict[str, float | str]]:
    required = {"filename", "ns", "tau", metric}
    selected: dict[tuple[str, str], tuple[tuple[float, float], dict[str, str]]] = {}
    for row in rows:
        missing = sorted(required - set(row))
        if missing:
            raise ValueError(f"official evaluator output lacks columns: {missing}")
        value = float(row[metric])
        threshold = float(row["tau"])
        if not math.isfinite(value) or not math.isfinite(threshold):
            raise ValueError(f"non-finite evaluator metric {metric}")
        rank = ((-value if maximize else value), threshold)
        key = (row["filename"], row["ns"])
        if key not in selected or rank < selected[key][0]:
            selected[key] = (rank, row)

    result = []
    for key in sorted(selected):
        row = selected[key][1]
        result.append(
            {
                "method": row["filename"],
                "namespace": row["ns"],
                "threshold": float(row["tau"]),
                "value": float(row[metric]),
                "coverage": float(row["cov_w"] if metric.endswith("_w") else row["cov"]),
            }
        )
    return result


def build_canonical_evaluator_summary(results: Path, result_kind: str) -> dict:
    evaluation_all = results / "evaluation_all.tsv"
    if not evaluation_all.is_file():
        raise FileNotFoundError(evaluation_all)
    _, rows = read_tsv_records(evaluation_all)
    if not rows:
        raise ValueError("official evaluator produced an empty evaluation_all.tsv")
    summary = {
        "schema_version": 1,
        "result_kind": result_kind,
        "semantic_sha256": canonical_tsv_semantic_digest(evaluation_all),
        "metrics": {
            "f_max": select_best_evaluator_rows(rows, "f", maximize=True),
            "weighted_f_max": select_best_evaluator_rows(rows, "f_w", maximize=True),
            "unweighted_semantic_distance_min": select_best_evaluator_rows(
                rows, "s", maximize=False
            ),
            "weighted_semantic_distance_min": select_best_evaluator_rows(
                rows, "s_w", maximize=False
            ),
        },
        "metric_notes": {
            "unweighted_semantic_distance_min": "minimum of evaluator column s",
            "weighted_semantic_distance_min": (
                "minimum of evaluator column s_w using information accretion; "
                "this is the weighted semantic-distance result"
            ),
        },
    }
    destination = results / "evaluation_canonical_summary.json"
    destination.write_text(
        json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    return summary


def run_official_evaluator(
    evaluator: Path,
    data_root: Path,
    output: Path,
    evaluation_inputs: EvaluationInputs,
    threads: int,
) -> dict:
    evaluation = data_root / "evaluation"
    results = output / "official_results"
    results.mkdir()
    command = [
        str(evaluator),
        str(evaluation / "go-basic.obo"),
        str(output / "predictions"),
        str(evaluation_inputs.ground_truth),
        "-out_dir",
        str(results),
        "-ia",
        str(evaluation / "IA_t0.tsv"),
        "-toi",
        str(evaluation / "toi_2025_03.tsv"),
        "-known",
        str(evaluation_inputs.known_annotations),
        "-prop",
        "fill",
        "-th_step",
        "0.001",
        "-norm",
        "cafa",
        "-no_orphans",
        "-threads",
        str(threads),
    ]
    process = subprocess.run(command, text=True, capture_output=True, check=True)
    (output / "cafaeval.stdout").write_text(process.stdout, encoding="utf-8")
    (output / "cafaeval.stderr").write_text(process.stderr, encoding="utf-8")
    raw_result_files = [
        {"name": path.name, "bytes": path.stat().st_size, "sha256": file_digest(path)}
        for path in sorted(results.glob("*.tsv"))
    ]
    if not raw_result_files:
        raise ValueError("official evaluator produced no TSV results")
    canonical = build_canonical_evaluator_summary(results, evaluation_inputs.result_kind)
    return {
        "protocol": {
            "propagation": "fill",
            "threshold_step": 0.001,
            "normalization": "cafa",
            "exclude_orphans": True,
            "threads": threads,
        },
        "raw_result_files": raw_result_files,
        "canonical_summary": canonical,
        "canonical_summary_sha256": file_digest(
            results / "evaluation_canonical_summary.json"
        ),
    }


def run_smoke(args: argparse.Namespace) -> dict:
    output = args.output.resolve()
    require_fresh_directory(output)
    verification = verify_install(args.data_root.resolve(), args.evaluator_root.resolve())
    smoke = make_t0_frequency_smoke(
        args.data_root.resolve(),
        output / "smoke",
        args.targets,
        args.terms_per_aspect,
        args.seed,
    )

    fused_path = output / "smoke" / "predictions" / "pln_single_source_fused.tsv"
    trails = output / "smoke" / "pln_single_source_trails.jsonl"
    database = reducer_workspace(output / "smoke", args.reducer_backend)
    fusion = fuse_prediction_files(
        [
            SourceSpec(
                "t0-frequency",
                "annotations-shared",
                output / "smoke" / smoke["files"]["predictions"],
            )
        ],
        fused_path,
        trails,
        database,
        FusionSpec(),
        get_reducer_backend(
            args.reducer_backend,
            args.cetta.resolve(),
            args.python_lib_dir.resolve() if args.python_lib_dir else None,
            args.reducer_run_size,
            args.reducer_shards,
        ),
    )
    parity = compare_prediction_files(
        output / "smoke" / smoke["files"]["predictions"], fused_path
    )
    cetta = run_cetta_smoke(
        args.cetta.resolve(),
        output / "smoke",
        output / "smoke" / smoke["files"]["metta_packets"],
        smoke["first_packet"],
        smoke["prediction_rows"],
        args.python_lib_dir.resolve() if args.python_lib_dir else None,
    )
    evaluator = run_official_evaluator(
        args.evaluator.resolve(),
        args.data_root.resolve(),
        output / "smoke",
        EvaluationInputs(
            output / "smoke" / smoke["files"]["ground_truth"],
            output / "smoke" / smoke["files"]["known"],
            "integration-smoke-not-biological-performance",
        ),
        args.threads,
    )
    summary = {
        "status": "real-data-smoke-complete-not-a-benchmark-result",
        "verification": verification,
        "smoke": smoke,
        "single_source_fusion": fusion,
        "single_source_parity": parity,
        "cetta": cetta,
        "official_evaluator": evaluator,
    }
    (output / "run_summary.json").write_text(
        json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    return summary


def run_multisource_smoke(args: argparse.Namespace) -> dict:
    output = args.output.resolve()
    require_fresh_directory(output)
    verification = verify_install(args.data_root.resolve(), args.evaluator_root.resolve())
    verification["baseline_archive"] = verify_dataset_archive(
        args.data_root.resolve(), "baseline_archive"
    )
    validate_source_specs(args.source)
    fusion_spec = load_fusion_spec(args.fusion_policy, args.fusion_declaration)
    validate_fusion_spec(args.source, fusion_spec)
    context = json.loads(args.smoke_manifest.read_text(encoding="utf-8"))
    context_root = args.smoke_manifest.resolve().parent
    ground_truth = resolve_artifact_path(
        context_root, context["files"]["ground_truth"]
    )
    target_set = {protein for protein, _, _ in iter_annotation_rows(ground_truth)}
    if not target_set:
        raise ValueError("smoke context has no target proteins")

    predictions_dir = output / "predictions"
    predictions_dir.mkdir()
    subset_specs = []
    source_rows = {}
    for spec in args.source:
        destination = predictions_dir / f"{safe_metta_symbol(spec.source)}.tsv"
        rows = subset_prediction_file(spec.path.resolve(), destination, target_set)
        if rows == 0:
            raise ValueError(f"source {spec.source} has no predictions for smoke targets")
        subset_specs.append(SourceSpec(spec.source, spec.dependence_group, destination))
        source_rows[spec.source] = rows

    fused_path = predictions_dir / "pln_dependence_fused.tsv"
    trails = output / "pln_dependence_trails.jsonl"
    fusion = fuse_prediction_files(
        subset_specs,
        fused_path,
        trails,
        reducer_workspace(output, args.reducer_backend),
        fusion_spec,
        get_reducer_backend(
            args.reducer_backend,
            args.cetta.resolve(),
            args.python_lib_dir.resolve() if args.python_lib_dir else None,
            args.reducer_run_size,
            args.reducer_shards,
        ),
    )
    packet_file = output / "cafa_packets.metta"
    packet_count, first_packet = write_cetta_packets(subset_specs, packet_file)
    cetta = run_cetta_smoke(
        args.cetta.resolve(),
        output,
        packet_file,
        first_packet,
        packet_count,
        args.python_lib_dir.resolve() if args.python_lib_dir else None,
    )
    evaluator = run_official_evaluator(
        args.evaluator.resolve(),
        args.data_root.resolve(),
        output,
        EvaluationInputs(
            ground_truth,
            resolve_artifact_path(context_root, context["files"]["known"]),
            "multisource-integration-smoke-not-biological-performance",
        ),
        args.threads,
    )
    summary = {
        "status": "released-baseline-multisource-smoke-not-a-full-benchmark-result",
        "verification": verification,
        "target_count": len(target_set),
        "sources": [
            {
                "source": spec.source,
                "dependence_group": spec.dependence_group,
                "input_name": args.source[index].path.name,
                "input_bytes": args.source[index].path.resolve().stat().st_size,
                "input_sha256": file_digest(args.source[index].path.resolve()),
                "subset_name": spec.path.name,
                "subset_rows": source_rows[spec.source],
                "subset_sha256": file_digest(spec.path),
            }
            for index, spec in enumerate(subset_specs)
        ],
        "fusion": fusion,
        "cetta": cetta,
        "official_evaluator": evaluator,
    }
    (output / "run_summary.json").write_text(
        json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    return summary


def run_full(args: argparse.Namespace) -> dict:
    """Run a frozen full-target evaluation, distinct from integration smokes."""

    output = args.output.resolve()
    require_fresh_directory(output)
    data_root = args.data_root.resolve()
    verification = verify_install(data_root, args.evaluator_root.resolve())
    validate_source_specs(args.source)
    fusion_spec = load_fusion_spec(args.fusion_policy, args.fusion_declaration)
    validate_fusion_spec(args.source, fusion_spec)

    predictions = output / "predictions"
    predictions.mkdir()
    fused_path = predictions / f"pln_{fusion_spec.policy}.tsv"
    trails = output / f"pln_{fusion_spec.policy}_trails.jsonl"
    fusion = fuse_prediction_files(
        [
            SourceSpec(spec.source, spec.dependence_group, spec.path.resolve())
            for spec in args.source
        ],
        fused_path,
        trails,
        reducer_workspace(output, args.reducer_backend),
        fusion_spec,
        get_reducer_backend(
            args.reducer_backend,
            args.cetta.resolve(),
            args.python_lib_dir.resolve() if args.python_lib_dir else None,
            args.reducer_run_size,
            args.reducer_shards,
        ),
    )

    evaluation = data_root / "evaluation"
    ground_truth = evaluation / "eval_terms_partial_2025_03.tsv"
    known = evaluation / "known_t0.tsv"
    target_count = len({protein for protein, _, _ in iter_annotation_rows(ground_truth)})
    evaluator = run_official_evaluator(
        args.evaluator.resolve(),
        data_root,
        output,
        EvaluationInputs(ground_truth, known, "full-partial-knowledge-evaluation"),
        args.threads,
    )
    summary = {
        "status": (
            "full-data-cetta-group-fold-evaluation-complete"
            if fusion["backend_role"] == "load-bearing-reducer"
            else "full-data-differential-oracle-evaluation-complete; "
            "not-a-final-cetta-reducer-result"
        ),
        "verification": verification,
        "target_count": target_count,
        "source_inputs": [
            {
                "source": spec.source,
                "dependence_group": spec.dependence_group,
                "bytes": spec.path.resolve().stat().st_size,
                "sha256": file_digest(spec.path.resolve()),
            }
            for spec in args.source
        ],
        "fusion": fusion,
        "official_evaluator": evaluator,
    }
    (output / "run_summary.json").write_text(
        json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    return summary


def parse_source_spec(text: str) -> SourceSpec:
    parts = text.split(":", 2)
    if len(parts) != 3:
        raise argparse.ArgumentTypeError("source must be SOURCE:GROUP:PATH")
    return SourceSpec(parts[0], parts[1], Path(parts[2]))


def add_fusion_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument(
        "--fusion-policy",
        choices=("conservative-max", "calibrated-noisy-or"),
        default="conservative-max",
        help="conservative max is primary; noisy-OR requires a pinned declaration",
    )
    parser.add_argument(
        "--fusion-declaration",
        type=Path,
        help="JSON calibration and cross-group independence declaration",
    )
    parser.add_argument(
        "--reducer-backend",
        choices=("cetta-group-fold", "sqlite-oracle"),
        default="cetta-group-fold",
        help="CeTTa group-fold is primary; SQLite is a differential oracle",
    )
    parser.add_argument("--reducer-run-size", type=int, default=10_000)
    parser.add_argument(
        "--reducer-shards",
        type=int,
        default=256,
        help="deterministic protein-local CeTTa partitions",
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    verify = subparsers.add_parser("verify", help="verify pinned data and evaluator")
    verify.add_argument("--data-root", type=Path, required=True)
    verify.add_argument("--evaluator-root", type=Path, required=True)

    make_smoke = subparsers.add_parser("make-smoke", help="make a deterministic real-data smoke slice")
    make_smoke.add_argument("--data-root", type=Path, required=True)
    make_smoke.add_argument("--output", type=Path, required=True)
    make_smoke.add_argument("--targets", type=int, default=64)
    make_smoke.add_argument("--terms-per-aspect", type=int, default=25)
    make_smoke.add_argument("--seed", default="cafa5-pln-smoke-v1")

    fuse = subparsers.add_parser("fuse", help="dependence-aware fusion of CAFA prediction TSVs")
    fuse.add_argument("--source", action="append", type=parse_source_spec, required=True)
    fuse.add_argument("--output-tsv", type=Path, required=True)
    fuse.add_argument("--trail-jsonl", type=Path, required=True)
    fuse.add_argument("--workspace", type=Path, required=True)
    fuse.add_argument("--cetta", type=Path, required=True)
    fuse.add_argument("--python-lib-dir", type=Path)
    add_fusion_arguments(fuse)

    smoke = subparsers.add_parser("run-smoke", help="run data, CeTTa, fusion, and official evaluator smoke")
    smoke.add_argument("--data-root", type=Path, required=True)
    smoke.add_argument("--evaluator-root", type=Path, required=True)
    smoke.add_argument("--evaluator", type=Path, required=True)
    smoke.add_argument("--cetta", type=Path, required=True)
    smoke.add_argument("--python-lib-dir", type=Path)
    smoke.add_argument("--output", type=Path, required=True)
    smoke.add_argument("--targets", type=int, default=64)
    smoke.add_argument("--terms-per-aspect", type=int, default=25)
    smoke.add_argument("--seed", default="cafa5-pln-smoke-v1")
    smoke.add_argument("--threads", type=int, default=1)
    smoke.add_argument(
        "--reducer-backend",
        choices=("cetta-group-fold", "sqlite-oracle"),
        default="cetta-group-fold",
    )
    smoke.add_argument("--reducer-run-size", type=int, default=10_000)
    smoke.add_argument("--reducer-shards", type=int, default=256)

    multi = subparsers.add_parser(
        "run-multisource-smoke",
        help="subset sources, fuse them, audit leaf routes in CeTTa, and evaluate",
    )
    multi.add_argument("--smoke-manifest", type=Path, required=True)
    multi.add_argument("--source", action="append", type=parse_source_spec, required=True)
    multi.add_argument("--data-root", type=Path, required=True)
    multi.add_argument("--evaluator-root", type=Path, required=True)
    multi.add_argument("--evaluator", type=Path, required=True)
    multi.add_argument("--cetta", type=Path, required=True)
    multi.add_argument("--python-lib-dir", type=Path)
    multi.add_argument("--output", type=Path, required=True)
    multi.add_argument("--threads", type=int, default=1)
    add_fusion_arguments(multi)

    full = subparsers.add_parser(
        "run-full",
        help="fuse complete frozen prediction sources and run the official evaluator",
    )
    full.add_argument("--source", action="append", type=parse_source_spec, required=True)
    full.add_argument("--data-root", type=Path, required=True)
    full.add_argument("--evaluator-root", type=Path, required=True)
    full.add_argument("--evaluator", type=Path, required=True)
    full.add_argument("--cetta", type=Path, required=True)
    full.add_argument("--python-lib-dir", type=Path)
    full.add_argument("--output", type=Path, required=True)
    full.add_argument("--threads", type=int, default=1)
    add_fusion_arguments(full)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if args.command == "verify":
        result = verify_install(args.data_root.resolve(), args.evaluator_root.resolve())
    elif args.command == "make-smoke":
        result = make_t0_frequency_smoke(
            args.data_root.resolve(),
            args.output.resolve(),
            args.targets,
            args.terms_per_aspect,
            args.seed,
        )
    elif args.command == "fuse":
        fusion_spec = load_fusion_spec(args.fusion_policy, args.fusion_declaration)
        result = fuse_prediction_files(
            args.source,
            args.output_tsv.resolve(),
            args.trail_jsonl.resolve(),
            args.workspace.resolve(),
            fusion_spec,
            get_reducer_backend(
                args.reducer_backend,
                args.cetta.resolve(),
                args.python_lib_dir.resolve() if args.python_lib_dir else None,
                args.reducer_run_size,
                args.reducer_shards,
            ),
        )
    elif args.command == "run-smoke":
        result = run_smoke(args)
    elif args.command == "run-multisource-smoke":
        result = run_multisource_smoke(args)
    elif args.command == "run-full":
        result = run_full(args)
    else:
        raise AssertionError(args.command)
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
