#!/usr/bin/env python3
"""Reproducibility, leakage, evaluation, and run-control utilities.

The module deliberately uses only the Python standard library so the data
boundary and synthetic gates can be audited without installing the training
stack.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import random
import shutil
import subprocess
import sys
from collections import Counter
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Iterator, Mapping, Sequence


HERE = Path(__file__).resolve().parent
UPSTREAM_MANIFEST = HERE / "upstream_manifest.json"
EXPERIMENT_CONFIG = HERE / "experiment_config.json"
TRAINING_ENVIRONMENT = HERE / "training_environment.json"

SUITE_FINGERPRINT_FILES = (
    "biopathnet_suite.py",
    "control_runner.py",
    "pln_path_model.py",
    "certificate.schema.json",
    "experiment_config.json",
    "training_environment.json",
    "upstream_manifest.json",
    "biopathnet_symmetric_candidates.patch",
    "torchdrug_pytorch212.patch",
)


class SuiteError(ValueError):
    """Raised when a scientific or reproducibility invariant is violated."""


@dataclass(frozen=True, order=True)
class Triple:
    head: str
    relation: str
    tail: str

    def as_tuple(self) -> tuple[str, str, str]:
        return self.head, self.relation, self.tail


def canonical_json_bytes(value: Any) -> bytes:
    return (json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False) + "\n").encode("utf-8")


def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def sha256_bytes(payload: bytes) -> str:
    return hashlib.sha256(payload).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def atomic_write(path: Path, payload: bytes, *, exclusive: bool = False) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if exclusive:
        flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
        descriptor = os.open(path, flags, 0o664)
        with os.fdopen(descriptor, "wb") as handle:
            handle.write(payload)
            handle.flush()
            os.fsync(handle.fileno())
        return
    temporary = path.with_name(path.name + ".new")
    with temporary.open("wb") as handle:
        handle.write(payload)
        handle.flush()
        os.fsync(handle.fileno())
    os.replace(temporary, path)


def write_json(path: Path, value: Any, *, exclusive: bool = False) -> None:
    atomic_write(path, canonical_json_bytes(value), exclusive=exclusive)


def parse_triples(path: Path) -> Iterator[tuple[int, Triple]]:
    with path.open("r", encoding="utf-8", newline="") as handle:
        for line_number, raw in enumerate(handle, start=1):
            line = raw.rstrip("\r\n")
            fields = line.split("\t")
            if len(fields) != 3 or any(not field for field in fields):
                raise SuiteError(f"{path.name}:{line_number}: expected three nonempty tab-separated fields")
            yield line_number, Triple(fields[0], fields[1], fields[2])


def parse_entity_map(path: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    with path.open("r", encoding="utf-8", newline="") as handle:
        for line_number, raw in enumerate(handle, start=1):
            fields = raw.rstrip("\r\n").split("\t")
            if len(fields) != 2 or any(not field for field in fields):
                raise SuiteError(f"{path.name}:{line_number}: expected two nonempty tab-separated fields")
            if fields[0] in result:
                raise SuiteError(f"{path.name}:{line_number}: duplicate entity {fields[0]!r}")
            result[fields[0]] = fields[1]
    return result


def _validate_file_pin(path: Path, pin: Mapping[str, Any]) -> dict[str, Any]:
    if not path.is_file():
        raise SuiteError(f"missing pinned file: {path.name}")
    size = path.stat().st_size
    digest = sha256_file(path)
    with path.open("rb") as handle:
        lines = sum(1 for _ in handle)
    if size != pin["bytes"]:
        raise SuiteError(f"{path.name}: byte count {size} != pinned {pin['bytes']}")
    if lines != pin["lines"]:
        raise SuiteError(f"{path.name}: line count {lines} != pinned {pin['lines']}")
    if digest != pin["sha256"]:
        raise SuiteError(f"{path.name}: sha256 {digest} != pinned {pin['sha256']}")
    return {"bytes": size, "lines": lines, "sha256": digest}


def validate_dataset(data_dir: Path, manifest: Mapping[str, Any] | None = None) -> dict[str, Any]:
    manifest = manifest or load_json(UPSTREAM_MANIFEST)
    pins = manifest["task"]["files"]
    pinned = {name: _validate_file_pin(data_dir / name, pin) for name, pin in pins.items()}

    entity_types = parse_entity_map(data_dir / "entity_types.txt")
    entity_names = parse_entity_map(data_dir / "entity_names.txt")
    if set(entity_types) != set(entity_names):
        only_types = sorted(set(entity_types) - set(entity_names))[:5]
        only_names = sorted(set(entity_names) - set(entity_types))[:5]
        raise SuiteError(f"entity maps disagree: types-only={only_types}, names-only={only_names}")

    split_names = ("train1.txt", "train2.txt", "valid.txt", "test.txt")
    split_sets: dict[str, set[Triple]] = {}
    relation_counts: dict[str, dict[str, int]] = {}
    graph_entities: set[str] = set()
    for name in split_names:
        triples: set[Triple] = set()
        counter: Counter[str] = Counter()
        for line_number, triple in parse_triples(data_dir / name):
            if triple in triples:
                raise SuiteError(f"{name}:{line_number}: duplicate triple {triple.as_tuple()!r}")
            triples.add(triple)
            counter[triple.relation] += 1
            graph_entities.add(triple.head)
            graph_entities.add(triple.tail)
        pin = pins[name]
        if len(triples) != pin["unique_triples"]:
            raise SuiteError(f"{name}: unique triple count {len(triples)} != pinned {pin['unique_triples']}")
        if len(counter) != pin["relations"]:
            raise SuiteError(f"{name}: relation count {len(counter)} != pinned {pin['relations']}")
        split_sets[name] = triples
        relation_counts[name] = dict(sorted(counter.items()))

    overlaps: dict[str, int] = {}
    for left_index, left in enumerate(split_names):
        for right in split_names[left_index + 1 :]:
            overlap = split_sets[left] & split_sets[right]
            overlaps[f"{left}|{right}"] = len(overlap)
            if overlap:
                example = min(overlap).as_tuple()
                raise SuiteError(f"split leakage: {left} and {right} share {len(overlap)} triples; example={example!r}")

    missing_types = sorted(graph_entities - set(entity_types))
    if missing_types:
        raise SuiteError(f"{len(missing_types)} graph entities lack a type; first={missing_types[:5]}")

    expected_counts = manifest["task"]["supervision_relation_counts"]
    for split, expected in expected_counts.items():
        if relation_counts[split] != expected:
            raise SuiteError(f"{split}: relation counts differ from the pin")

    return {
        "status": "ok",
        "files": pinned,
        "unique_triples": {name: len(split_sets[name]) for name in split_names},
        "relations": relation_counts,
        "pairwise_exact_overlap": overlaps,
        "entity_count": len(entity_types),
        "entity_type_count": len(set(entity_types.values())),
    }


def verify_upstream(repository: Path) -> dict[str, Any]:
    manifest = load_json(UPSTREAM_MANIFEST)
    try:
        commit = subprocess.check_output(
            ["git", "rev-parse", "HEAD"], cwd=repository, text=True, stderr=subprocess.STDOUT
        ).strip()
    except (OSError, subprocess.CalledProcessError) as error:
        raise SuiteError(f"cannot inspect upstream git repository: {error}") from error
    expected_commit = manifest["source"]["commit"]
    if commit != expected_commit:
        raise SuiteError(f"upstream commit {commit} != pinned {expected_commit}")

    config_pin = manifest["source"]["official_config"]
    config_path = repository / config_pin["path"]
    config_hash = sha256_file(config_path)
    if config_hash != config_pin["sha256"]:
        raise SuiteError(f"official config sha256 {config_hash} != pinned {config_pin['sha256']}")
    data_dir = repository / manifest["task"]["data_directory"]
    dataset = validate_dataset(data_dir, manifest)
    return {"status": "ok", "commit": commit, "official_config_sha256": config_hash, "dataset": dataset}


def _control_yaml() -> str:
    return """output_dir: {{ output_dir }}

dataset:
  class: biomedical
  path: {{ data_path }}
  include_factgraph: yes

task:
  class: KnowledgeGraphCompletionBiomed
  model:
    class: NBFNet
    input_dim: 32
    hidden_dims: [32, 32, 32, 32, 32, 32]
    message_func: distmult
    aggregate_func: pna
    short_cut: yes
    layer_norm: yes
    dependent: yes
    symmetric: yes
    symmetric_query_chunk_size: 32
  criterion: bce
  num_negative: 32
  strict_negative: yes
  adversarial_temperature: 0.5
  sample_weight: no
  heterogeneous_negative: yes
  heterogeneous_evaluation: yes
  full_batch_eval: no

optimizer:
  class: Adam
  lr: 5.0e-3

engine:
  gpus: {{ gpus }}
  batch_size: 32

train:
  num_epoch: 10
  batch_per_epoch: 150

metric: "mrr"
"""


def _job_id(model: str, seed: int) -> str:
    return f"{model}--seed-{seed}"


def generate_run_plan(output_dir: Path) -> dict[str, Any]:
    upstream = load_json(UPSTREAM_MANIFEST)
    config = load_json(EXPERIMENT_CONFIG)
    training_environment = load_json(TRAINING_ENVIRONMENT)
    suite_source_sha256 = {
        name: sha256_file(HERE / name) for name in SUITE_FINGERPRINT_FILES
    }
    experiment_fingerprint = sha256_bytes(
        canonical_json_bytes(
            {
                "upstream": upstream,
                "experiment": config,
                "training_environment": training_environment,
                "suite_source_sha256": suite_source_sha256,
            }
        )
    )
    jobs: list[dict[str, Any]] = []
    for seed in config["seeds"]:
        for model in config["models"]:
            job_id = _job_id(model, seed)
            jobs.append(
                {
                    "job_id": job_id,
                    "model": model,
                    "seed": seed,
                    "training_inputs": ["train1.txt", "train2.txt"],
                    "selection_input": "valid.txt",
                    "test_input": None,
                    "sampled_negative_semantics": "type-matched sampled negatives; not biological falsehoods",
                    "artifact_directory": f"jobs/{job_id}",
                }
            )
    jobs.sort(key=lambda job: job["job_id"])
    plan = {
        "schema_version": 1,
        "experiment_fingerprint": experiment_fingerprint,
        "upstream_commit": upstream["source"]["commit"],
        "suite_source_sha256": suite_source_sha256,
        "seeds": config["seeds"],
        "jobs": jobs,
        "test_policy": {
            "state": "unarmed",
            "split": "test.txt",
            "split_sha256": upstream["task"]["files"]["test.txt"]["sha256"],
            "required_job_ids": [job["job_id"] for job in jobs],
        },
    }
    write_json(output_dir / "run_plan.json", plan)
    yaml_text = _control_yaml().encode("utf-8")
    atomic_write(output_dir / "configs" / "biopathnet-control.yaml", yaml_text)
    write_json(output_dir / "configs" / "pln-path-evidence.json", config["pln_path_model"])
    write_json(output_dir / "configs" / "biopathnet-pln-hybrid.json", config["hybrid"])
    write_json(output_dir / "configs" / "training-environment.json", training_environment)
    write_json(
        output_dir / "plan_manifest.json",
        {
            "schema_version": 1,
            "experiment_fingerprint": experiment_fingerprint,
            "suite_source_sha256": suite_source_sha256,
            "files": {
                "run_plan.json": sha256_file(output_dir / "run_plan.json"),
                "configs/biopathnet-control.yaml": sha256_file(output_dir / "configs" / "biopathnet-control.yaml"),
                "configs/pln-path-evidence.json": sha256_file(output_dir / "configs" / "pln-path-evidence.json"),
                "configs/biopathnet-pln-hybrid.json": sha256_file(output_dir / "configs" / "biopathnet-pln-hybrid.json"),
                "configs/training-environment.json": sha256_file(output_dir / "configs" / "training-environment.json"),
            },
        },
    )
    return plan


def stage_selection_data(source: Path, destination: Path) -> dict[str, Any]:
    """Create a control-training view that contains no bytes from test.txt."""
    if destination.exists() and any(destination.iterdir()):
        raise SuiteError(f"selection data destination is not empty: {destination}")
    destination.mkdir(parents=True, exist_ok=True)
    for name in ("train1.txt", "train2.txt", "valid.txt", "entity_names.txt", "entity_types.txt"):
        shutil.copyfile(source / name, destination / name)
    shutil.copyfile(source / "valid.txt", destination / "test.txt")
    receipt = {
        "schema_version": 1,
        "purpose": "selection-only upstream compatibility view",
        "files": {
            name: sha256_file(destination / name)
            for name in ("train1.txt", "train2.txt", "valid.txt", "test.txt", "entity_names.txt", "entity_types.txt")
        },
        "real_test_bytes_present": False,
        "surrogate_test_is_validation": True,
    }
    write_json(destination / "selection_view_receipt.json", receipt)
    return receipt


def arm_test_plan(run_plan_path: Path, selections_path: Path, lock_path: Path) -> dict[str, Any]:
    plan = load_json(run_plan_path)
    selections = load_json(selections_path)
    if "test" in json.dumps(selections, sort_keys=True).lower():
        raise SuiteError("selection manifest contains a test-named field")
    expected = set(plan["test_policy"]["required_job_ids"])
    records = selections.get("selections", [])
    actual = {record.get("job_id") for record in records}
    if actual != expected or len(records) != len(expected):
        missing = sorted(expected - actual)
        extra = sorted(actual - expected)
        raise SuiteError(f"selection manifest does not cover the frozen jobs: missing={missing}, extra={extra}")
    for record in records:
        if not isinstance(record.get("checkpoint_sha256"), str) or len(record["checkpoint_sha256"]) != 64:
            raise SuiteError(f"{record.get('job_id')}: checkpoint_sha256 is required")
        if not math.isfinite(float(record.get("validation_mrr", math.nan))):
            raise SuiteError(f"{record.get('job_id')}: finite validation_mrr is required")
    lock = {
        "schema_version": 1,
        "state": "armed",
        "experiment_fingerprint": plan["experiment_fingerprint"],
        "test_split_sha256": plan["test_policy"]["split_sha256"],
        "selection_manifest_sha256": sha256_file(selections_path),
        "pending_job_ids": sorted(expected),
        "consumed": {},
    }
    write_json(lock_path, lock, exclusive=True)
    return lock


def _parse_prediction_rows(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    seen: set[str] = set()
    with path.open("r", encoding="utf-8") as handle:
        for line_number, raw in enumerate(handle, start=1):
            try:
                row = json.loads(raw)
            except json.JSONDecodeError as error:
                raise SuiteError(f"{path.name}:{line_number}: invalid JSON: {error}") from error
            query_id = row.get("query_id")
            rank = row.get("rank")
            candidate_count = row.get("candidate_count")
            if not isinstance(query_id, str) or not query_id or query_id in seen:
                raise SuiteError(f"{path.name}:{line_number}: query_id must be unique and nonempty")
            if not isinstance(rank, (int, float)) or rank < 1 or not math.isfinite(float(rank)):
                raise SuiteError(f"{path.name}:{line_number}: rank must be finite and >= 1")
            if not isinstance(candidate_count, int) or candidate_count < 1 or rank > candidate_count:
                raise SuiteError(f"{path.name}:{line_number}: candidate_count must contain rank")
            for example in row.get("calibration_examples", []):
                origin = example.get("label_origin")
                if origin not in {"observed-positive", "type-matched-sampled-negative"}:
                    raise SuiteError(f"{path.name}:{line_number}: calibration label origin is missing or dishonest")
                label = example.get("label")
                score = example.get("score")
                if label not in (0, 1) or not isinstance(score, (int, float)) or not 0 <= score <= 1:
                    raise SuiteError(f"{path.name}:{line_number}: invalid calibration example")
                if label == 0 and origin != "type-matched-sampled-negative":
                    raise SuiteError(f"{path.name}:{line_number}: zero labels must be named sampled negatives")
            seen.add(query_id)
            rows.append(row)
    if not rows:
        raise SuiteError(f"{path.name}: no prediction rows")
    return rows


def ranking_metrics(rows: Sequence[Mapping[str, Any]]) -> dict[str, Any]:
    ranks = [float(row["rank"]) for row in rows]
    result: dict[str, Any] = {
        "queries": len(ranks),
        "mr": sum(ranks) / len(ranks),
        "mrr": sum(1.0 / rank for rank in ranks) / len(ranks),
    }
    for cutoff in (1, 3, 10):
        result[f"hits@{cutoff}"] = sum(rank <= cutoff for rank in ranks) / len(ranks)
    calibration = [example for row in rows for example in row.get("calibration_examples", [])]
    if calibration:
        result["sampled_negative_brier"] = sum(
            (float(example["score"]) - int(example["label"])) ** 2 for example in calibration
        ) / len(calibration)
        result["sampled_negative_brier_examples"] = len(calibration)
        result["calibration_scope"] = "observed positives versus type-matched sampled negatives"
    return result


def paired_bootstrap(
    left_rows: Sequence[Mapping[str, Any]],
    right_rows: Sequence[Mapping[str, Any]],
    *,
    replicates: int,
    confidence: float,
    seed: int,
) -> dict[str, Any]:
    if replicates < 1:
        raise SuiteError("bootstrap replicates must be positive")
    if not 0 < confidence < 1:
        raise SuiteError("bootstrap confidence must be between zero and one")
    left = {str(row["query_id"]): 1.0 / float(row["rank"]) for row in left_rows}
    right = {str(row["query_id"]): 1.0 / float(row["rank"]) for row in right_rows}
    if set(left) != set(right):
        raise SuiteError("paired bootstrap inputs must contain the same query IDs")
    query_ids = sorted(left)
    differences = [left[query_id] - right[query_id] for query_id in query_ids]
    point = sum(differences) / len(differences)
    generator = random.Random(seed)
    samples = []
    for _ in range(replicates):
        samples.append(sum(differences[generator.randrange(len(differences))] for _ in differences) / len(differences))
    samples.sort()
    alpha = 1.0 - confidence
    lower_index = max(0, min(replicates - 1, int(math.floor(alpha * 0.5 * replicates))))
    upper_index = max(0, min(replicates - 1, int(math.ceil((1.0 - alpha * 0.5) * replicates)) - 1))
    return {
        "queries": len(query_ids),
        "replicates": replicates,
        "confidence": confidence,
        "seed": seed,
        "left_minus_right_mrr": point,
        "interval": [samples[lower_index], samples[upper_index]],
        "method": "paired query percentile bootstrap",
    }


def rank_candidate_rows(
    candidate_path: Path,
    output_path: Path,
    *,
    score_field: str,
    sampled_candidates: int,
    seed: int,
) -> dict[str, Any]:
    if sampled_candidates < 0:
        raise SuiteError("sampled candidate count must be nonnegative")
    grouped: dict[str, list[dict[str, Any]]] = {}
    with candidate_path.open("r", encoding="utf-8") as handle:
        for line_number, raw in enumerate(handle, start=1):
            try:
                row = json.loads(raw)
            except json.JSONDecodeError as error:
                raise SuiteError(f"{candidate_path.name}:{line_number}: invalid JSON: {error}") from error
            query_id = row.get("query_id")
            candidate_id = row.get("candidate_id")
            score = row.get(score_field)
            if not isinstance(query_id, str) or not isinstance(candidate_id, str):
                raise SuiteError(f"{candidate_path.name}:{line_number}: query_id and candidate_id are required")
            if not isinstance(score, (int, float)) or not math.isfinite(float(score)):
                raise SuiteError(f"{candidate_path.name}:{line_number}: finite {score_field} is required")
            grouped.setdefault(query_id, []).append(row)
    if not grouped:
        raise SuiteError(f"{candidate_path.name}: no candidate rows")
    generator = random.Random(seed)
    predictions = []
    for query_id, candidates in sorted(grouped.items()):
        positives = [candidate for candidate in candidates if candidate.get("is_observed_positive") is True]
        if len(positives) != 1:
            raise SuiteError(f"{query_id}: expected exactly one observed-positive candidate")
        positive = positives[0]
        positive_score = float(positive[score_field])
        higher = sum(float(candidate[score_field]) > positive_score for candidate in candidates)
        tied = sum(float(candidate[score_field]) == positive_score for candidate in candidates) - 1
        negatives = [candidate for candidate in candidates if candidate is not positive]
        sampled = generator.sample(negatives, min(sampled_candidates, len(negatives)))
        predictions.append(
            {
                "query_id": query_id,
                "rank": 1.0 + higher + tied / 2.0,
                "candidate_count": len(candidates),
                "positive_score": positive_score,
                "calibration_examples": [
                    {"label": 1, "label_origin": "observed-positive", "score": positive_score}
                ]
                + [
                    {
                        "label": 0,
                        "label_origin": "type-matched-sampled-negative",
                        "score": float(candidate[score_field]),
                    }
                    for candidate in sampled
                ],
            }
        )
    if output_path.exists():
        raise SuiteError(f"refusing to replace existing predictions: {output_path}")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    temporary = output_path.with_name(output_path.name + ".new")
    with temporary.open("wb") as handle:
        for row in predictions:
            handle.write(canonical_json_bytes(row))
        handle.flush()
    os.replace(temporary, output_path)
    return {
        "status": "ok",
        "queries": len(predictions),
        "predictions_sha256": sha256_file(output_path),
        "score_field": score_field,
    }


def evaluate_once(lock_path: Path, job_id: str, predictions_path: Path, output_path: Path) -> dict[str, Any]:
    lock = load_json(lock_path)
    if lock.get("state") not in {"armed", "partially-consumed"}:
        raise SuiteError("test plan is not armed")
    if job_id not in lock["pending_job_ids"]:
        if job_id in lock.get("consumed", {}):
            raise SuiteError(f"test evaluation for {job_id} was already consumed")
        raise SuiteError(f"job {job_id} is not part of the frozen test plan")
    rows = _parse_prediction_rows(predictions_path)
    metrics = ranking_metrics(rows)
    receipt = {
        "schema_version": 1,
        "job_id": job_id,
        "test_split_sha256": lock["test_split_sha256"],
        "predictions_sha256": sha256_file(predictions_path),
        "metrics": metrics,
    }
    write_json(output_path, receipt, exclusive=True)
    pending = [candidate for candidate in lock["pending_job_ids"] if candidate != job_id]
    lock["pending_job_ids"] = pending
    lock["consumed"][job_id] = {
        "predictions_sha256": receipt["predictions_sha256"],
        "result_sha256": sha256_file(output_path),
    }
    lock["state"] = "consumed" if not pending else "partially-consumed"
    write_json(lock_path, lock)
    return receipt


def claim_test_access(lock_path: Path, job_id: str, purpose: str) -> dict[str, Any]:
    """Irreversibly claim one frozen job before any test bytes are opened."""
    lock = load_json(lock_path)
    if lock.get("state") not in {"armed", "partially-consumed", "in-progress"}:
        raise SuiteError("test plan is not available for a new claim")
    if job_id not in lock.get("pending_job_ids", []):
        if job_id in lock.get("in_progress", {}):
            raise SuiteError(f"test access for {job_id} is already in progress")
        if job_id in lock.get("consumed", {}):
            raise SuiteError(f"test access for {job_id} was already consumed")
        raise SuiteError(f"job {job_id} is not part of the frozen test plan")
    lock["pending_job_ids"] = [candidate for candidate in lock["pending_job_ids"] if candidate != job_id]
    lock.setdefault("in_progress", {})[job_id] = {"purpose": purpose}
    lock["state"] = "in-progress"
    write_json(lock_path, lock)
    return lock


def complete_test_access(lock_path: Path, job_id: str, artifact_path: Path) -> dict[str, Any]:
    lock = load_json(lock_path)
    in_progress = lock.get("in_progress", {})
    if job_id not in in_progress:
        raise SuiteError(f"test job {job_id} has no active claim")
    if not artifact_path.is_file():
        raise SuiteError(f"test artifact does not exist: {artifact_path}")
    claim = in_progress.pop(job_id)
    lock.setdefault("consumed", {})[job_id] = {
        "purpose": claim["purpose"],
        "artifact_sha256": sha256_file(artifact_path),
    }
    if in_progress:
        lock["state"] = "in-progress"
    elif lock.get("pending_job_ids"):
        lock["state"] = "partially-consumed"
    else:
        lock["state"] = "consumed"
    write_json(lock_path, lock)
    return lock


def validate_certificate(certificate: Mapping[str, Any]) -> None:
    required = {
        "schema_version",
        "prediction_id",
        "model",
        "split",
        "seed",
        "query",
        "training_manifest_sha256",
        "score",
        "evidence",
        "aggregation",
    }
    if set(certificate) != required:
        raise SuiteError(f"certificate fields differ: expected={sorted(required)}, actual={sorted(certificate)}")
    if certificate["schema_version"] != 1:
        raise SuiteError("certificate schema_version must be 1")
    if certificate["model"] not in {"pln-path-evidence", "biopathnet-pln-hybrid"}:
        raise SuiteError("certificate model is not evidential")
    if certificate["split"] not in {"valid", "test"}:
        raise SuiteError("certificate split must be valid or test")
    score = certificate["score"]
    if score.get("kind") not in {"pln-evidence-probability", "hybrid-calibrated-probability"}:
        raise SuiteError("certificate score kind is invalid")
    if not isinstance(score.get("value"), (int, float)) or not 0 <= score["value"] <= 1:
        raise SuiteError("certificate score must be in [0, 1]")
    evidence_ids: list[str] = []
    for item in certificate["evidence"]:
        item_required = {
            "evidence_id",
            "path",
            "template",
            "positive_count",
            "sampled_negative_count",
            "dependence_group",
            "provenance",
        }
        if set(item) != item_required:
            raise SuiteError("certificate evidence fields differ from the schema")
        if item["positive_count"] < 0 or item["sampled_negative_count"] < 0:
            raise SuiteError("certificate evidence counts must be nonnegative")
        for provenance in item["provenance"]:
            if provenance.get("split") not in {"train1", "train2", "sampled-negative"}:
                raise SuiteError("certificate provenance split is invalid")
            digest = provenance.get("line_sha256", "")
            if len(digest) != 64 or any(character not in "0123456789abcdef" for character in digest):
                raise SuiteError("certificate provenance hash is invalid")
        evidence_ids.append(item["evidence_id"])
    if len(evidence_ids) != len(set(evidence_ids)):
        raise SuiteError("certificate evidence IDs must be unique")
    aggregation = certificate["aggregation"]
    if aggregation.get("dependence_policy") != "shared-first-edge-max-before-revision":
        raise SuiteError("certificate dependence policy is invalid")
    if set(aggregation.get("input_evidence_ids", [])) != set(evidence_ids):
        raise SuiteError("certificate aggregation inputs must match evidence IDs")


def _print_json(value: Any) -> None:
    sys.stdout.buffer.write(canonical_json_bytes(value))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    verify = subparsers.add_parser("verify-upstream")
    verify.add_argument("repository", type=Path)

    validate = subparsers.add_parser("validate-data")
    validate.add_argument("data_dir", type=Path)

    generate = subparsers.add_parser("generate-plan")
    generate.add_argument("output_dir", type=Path)

    stage = subparsers.add_parser("stage-selection-data")
    stage.add_argument("source", type=Path)
    stage.add_argument("destination", type=Path)

    arm = subparsers.add_parser("arm-test")
    arm.add_argument("run_plan", type=Path)
    arm.add_argument("selections", type=Path)
    arm.add_argument("lock", type=Path)

    evaluate = subparsers.add_parser("evaluate-once")
    evaluate.add_argument("lock", type=Path)
    evaluate.add_argument("job_id")
    evaluate.add_argument("predictions", type=Path)
    evaluate.add_argument("output", type=Path)

    compare = subparsers.add_parser("paired-bootstrap")
    compare.add_argument("left", type=Path)
    compare.add_argument("right", type=Path)
    compare.add_argument("--replicates", type=int, default=10000)
    compare.add_argument("--confidence", type=float, default=0.95)
    compare.add_argument("--seed", type=int, default=8675309)

    rank = subparsers.add_parser("rank-candidates")
    rank.add_argument("candidates", type=Path)
    rank.add_argument("output", type=Path)
    rank.add_argument("--score-field", required=True)
    rank.add_argument("--sampled-candidates", type=int, default=32)
    rank.add_argument("--seed", type=int, default=8675309)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if args.command == "verify-upstream":
        _print_json(verify_upstream(args.repository))
    elif args.command == "validate-data":
        _print_json(validate_dataset(args.data_dir))
    elif args.command == "generate-plan":
        _print_json(generate_run_plan(args.output_dir))
    elif args.command == "stage-selection-data":
        _print_json(stage_selection_data(args.source, args.destination))
    elif args.command == "arm-test":
        _print_json(arm_test_plan(args.run_plan, args.selections, args.lock))
    elif args.command == "evaluate-once":
        _print_json(evaluate_once(args.lock, args.job_id, args.predictions, args.output))
    elif args.command == "paired-bootstrap":
        left = _parse_prediction_rows(args.left)
        right = _parse_prediction_rows(args.right)
        _print_json(
            paired_bootstrap(
                left,
                right,
                replicates=args.replicates,
                confidence=args.confidence,
                seed=args.seed,
            )
        )
    elif args.command == "rank-candidates":
        _print_json(
            rank_candidate_rows(
                args.candidates,
                args.output,
                score_field=args.score_field,
                sampled_candidates=args.sampled_candidates,
                seed=args.seed,
            )
        )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except SuiteError as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(2)
