#!/usr/bin/env python3
"""Run frozen lower/upper-completion FCA comparators.

This is an independent Python comparator for the native WM/FCA corruption
study.  It reconstructs every source layer deterministically and refuses to
score a case unless the reconstruction exactly matches the pinned source
receipt.
"""

from __future__ import annotations

import argparse
import gzip
import hashlib
import json
import math
import statistics
from pathlib import Path
from types import ModuleType


LOWER_ID = "incomplete-lower-completion"
UPPER_ID = "incomplete-upper-completion"
EXPECTED_MAPPINGS = {
    LOWER_ID: {".": "0", "0": "0", "1": "1", "u": "0"},
    UPPER_ID: {".": "1", "0": "0", "1": "1", "u": "1"},
}


def require_mapping(value: object, label: str) -> dict[str, object]:
    if not isinstance(value, dict):
        raise ValueError(f"{label} must be an object")
    return value


def require_list(value: object, label: str) -> list[object]:
    if not isinstance(value, list):
        raise ValueError(f"{label} must be an array")
    return value


def require_string(value: object, label: str) -> str:
    if not isinstance(value, str) or not value:
        raise ValueError(f"{label} must be a nonempty string")
    return value


def require_int(value: object, label: str) -> int:
    if not isinstance(value, int) or isinstance(value, bool):
        raise ValueError(f"{label} must be an integer")
    return value


def require_rate(value: object, label: str) -> float:
    if not isinstance(value, (int, float)) or isinstance(value, bool):
        raise ValueError(f"{label} must be numeric")
    result = float(value)
    if not math.isfinite(result) or not 0.0 <= result <= 1.0:
        raise ValueError(f"{label} must lie in [0, 1]")
    return result


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load_source_api() -> ModuleType:
    """Load the pinned FCA oracle only for full comparator execution."""
    import run_corruption_experiment as source_api

    return source_api


def load_json(path: Path) -> dict[str, object]:
    return require_mapping(json.loads(path.read_text(encoding="utf-8")), str(path))


def load_gzip_json(path: Path) -> tuple[dict[str, object], str]:
    with gzip.open(path, "rb") as handle:
        payload = handle.read()
    return require_mapping(json.loads(payload), str(path)), hashlib.sha256(payload).hexdigest()


def write_deterministic_gzip_json(path: Path, value: object) -> str:
    payload = (json.dumps(value, indent=2, sort_keys=True) + "\n").encode()
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("wb") as raw:
        with gzip.GzipFile(filename="", mode="wb", fileobj=raw, mtime=0) as handle:
            handle.write(payload)
    return hashlib.sha256(payload).hexdigest()


def relative_file(root: Path, value: object, label: str) -> Path:
    relative = Path(require_string(value, label))
    if relative.is_absolute():
        raise ValueError(f"{label} must be relative")
    resolved = (root / relative).resolve()
    try:
        resolved.relative_to(root)
    except ValueError as exc:
        raise ValueError(f"{label} escapes the benchmark directory") from exc
    if not resolved.is_file():
        raise ValueError(f"{label} does not identify a file: {relative}")
    return resolved


def relative_directory(root: Path, value: object, label: str) -> Path:
    relative = Path(require_string(value, label))
    if relative.is_absolute():
        raise ValueError(f"{label} must be relative")
    resolved = (root / relative).resolve()
    try:
        resolved.relative_to(root)
    except ValueError as exc:
        raise ValueError(f"{label} escapes the benchmark directory") from exc
    if not resolved.is_dir():
        raise ValueError(f"{label} does not identify a directory: {relative}")
    return resolved


def require_sha(value: object, label: str) -> str:
    result = require_string(value, label)
    if len(result) != 64 or any(character not in "0123456789abcdef" for character in result):
        raise ValueError(f"{label} must be a lowercase SHA-256 digest")
    return result


def parse_baselines(protocol: dict[str, object]) -> dict[str, dict[str, str]]:
    result: dict[str, dict[str, str]] = {}
    for index, raw_value in enumerate(
        require_list(protocol.get("baseline_family"), "baseline_family")
    ):
        raw = require_mapping(raw_value, f"baseline_family[{index}]")
        baseline_id = require_string(raw.get("id"), f"baseline_family[{index}].id")
        mapping_raw = require_mapping(
            raw.get("status_to_incidence"),
            f"baseline_family[{index}].status_to_incidence",
        )
        mapping = {
            status: require_string(mapping_raw.get(status), f"{baseline_id}[{status}]")
            for status in (".", "0", "1", "u")
        }
        if set(mapping_raw) != set(mapping) or any(value not in {"0", "1"} for value in mapping.values()):
            raise ValueError(f"{baseline_id}: invalid completion mapping")
        if baseline_id in result:
            raise ValueError(f"duplicate baseline id: {baseline_id}")
        result[baseline_id] = mapping
    if result != EXPECTED_MAPPINGS:
        raise ValueError("protocol completion semantics differ from the frozen contract")
    return result


def complete_rows(rows: tuple[str, ...], mapping: dict[str, str]) -> tuple[str, ...]:
    try:
        return tuple("".join(mapping[status] for status in row) for row in rows)
    except KeyError as exc:
        raise ValueError(f"unsupported observation status: {exc.args[0]}") from exc


def incidence_sha(rows: tuple[str, ...]) -> str:
    return hashlib.sha256(("\n".join(rows) + "\n").encode()).hexdigest()


def point_result(
    *,
    source_api: ModuleType,
    context_id: str,
    objects: tuple[str, ...],
    attributes: tuple[str, ...],
    rows: tuple[str, ...],
    truth_rows: tuple[str, ...],
    candidates: tuple[tuple[int, ...], ...],
    truth_artifacts: dict[str, set[object]],
    exact_limits: dict[str, object],
) -> dict[str, object]:
    artifacts = source_api.exact_artifacts(
        context_id, objects, attributes, rows, exact_limits
    )
    return {
        "canonical_basis": source_api.set_scores(
            artifacts["basis"], truth_artifacts["basis"]
        ),
        "cells": source_api.cell_scores(rows, truth_rows),
        "closures": source_api.closure_scores(rows, truth_rows, candidates),
        "concepts": source_api.set_scores(
            artifacts["concepts"], truth_artifacts["concepts"]
        ),
        "incidence_sha256": incidence_sha(rows),
        "lattice_covers": source_api.set_scores(
            artifacts["covers"], truth_artifacts["covers"]
        ),
    }


def midpoint_cell_scores(
    lower_rows: tuple[str, ...],
    upper_rows: tuple[str, ...],
    truth_rows: tuple[str, ...],
) -> dict[str, object]:
    probabilities: list[float] = []
    outcomes: list[int] = []
    covered: list[float] = []
    widths: list[float] = []
    for lower_row, upper_row, truth_row in zip(
        lower_rows, upper_rows, truth_rows, strict=True
    ):
        for lower, upper, truth in zip(lower_row, upper_row, truth_row, strict=True):
            lower_value = int(lower)
            upper_value = int(upper)
            outcome = int(truth)
            if lower_value > upper_value:
                raise ValueError("lower completion is not contained in upper completion")
            probabilities.append((lower_value + upper_value) / 2)
            outcomes.append(outcome)
            covered.append(float(lower_value <= outcome <= upper_value))
            widths.append(float(upper_value - lower_value))
    if not probabilities:
        raise ValueError("cannot score an empty context")
    brier = statistics.fmean(
        (probability - outcome) ** 2
        for probability, outcome in zip(probabilities, outcomes, strict=True)
    )
    ece = 0.0
    for probability in (0.0, 0.5, 1.0):
        indices = [
            index for index, value in enumerate(probabilities) if value == probability
        ]
        if indices:
            observed = statistics.fmean(outcomes[index] for index in indices)
            ece += len(indices) / len(probabilities) * abs(observed - probability)
    return {
        "brier": brier,
        "ece": ece,
        "forecast_values": [0.0, 0.5, 1.0],
        "interval_coverage": statistics.fmean(covered),
        "mean_width": statistics.fmean(widths),
    }


def scalar_metrics(case: dict[str, object], baseline_id: str) -> dict[str, float]:
    baselines = require_mapping(case.get("baselines"), "case.baselines")
    baseline = require_mapping(baselines.get(baseline_id), baseline_id)
    return {
        "basis_f1": float(require_mapping(baseline.get("canonical_basis"), "basis")["f1"]),
        "cell_f1": float(require_mapping(baseline.get("cells"), "cells")["f1"]),
        "closure_exact_accuracy": float(
            require_mapping(baseline.get("closures"), "closures")["exact_accuracy"]
        ),
        "closure_mean_jaccard": float(
            require_mapping(baseline.get("closures"), "closures")["mean_jaccard"]
        ),
        "concept_f1": float(require_mapping(baseline.get("concepts"), "concepts")["f1"]),
        "cover_f1": float(require_mapping(baseline.get("lattice_covers"), "covers")["f1"]),
    }


def aggregate_cases(cases: list[dict[str, object]]) -> dict[str, object]:
    if not cases:
        raise ValueError("cannot aggregate zero cases")
    baselines: dict[str, object] = {}
    for baseline_id in (LOWER_ID, UPPER_ID):
        rows = [scalar_metrics(case, baseline_id) for case in cases]
        baselines[baseline_id] = {
            metric: {
                "mean": statistics.fmean(row[metric] for row in rows),
                "population_stddev": statistics.pstdev(row[metric] for row in rows),
            }
            for metric in rows[0]
        }
    midpoint_rows = [
        require_mapping(case.get("cell_midpoint"), "case.cell_midpoint")
        for case in cases
    ]
    return {
        "baselines": baselines,
        "case_count": len(cases),
        "cell_midpoint": {
            key: statistics.fmean(float(row[key]) for row in midpoint_rows)
            for key in ("brier", "ece", "interval_coverage", "mean_width")
        },
    }


def case_key(case: dict[str, object]) -> tuple[str, int, float, float, float]:
    parameters = require_mapping(case.get("parameters"), "case.parameters")
    return (
        require_string(parameters.get("context_id"), "context_id"),
        require_int(parameters.get("seed"), "seed"),
        require_rate(parameters.get("missing_rate"), "missing_rate"),
        require_rate(parameters.get("flip_rate"), "flip_rate"),
        require_rate(parameters.get("unknown_rate"), "unknown_rate"),
    )


def validate_source_grid(
    source_protocol: dict[str, object], source_receipt: dict[str, object]
) -> list[dict[str, object]]:
    if source_protocol.get("schema") != "wm-fca-corruption-protocol-v1":
        raise ValueError("unsupported source protocol schema")
    if source_receipt.get("schema") != "wm-fca-corruption-run-v1":
        raise ValueError("unsupported source receipt schema")
    if source_receipt.get("protocol_complete") is not True:
        raise ValueError("source receipt is not protocol-complete")
    cases = [
        require_mapping(value, f"source cases[{index}]")
        for index, value in enumerate(require_list(source_receipt.get("cases"), "source cases"))
    ]
    expected = (
        len(require_list(source_protocol.get("contexts"), "contexts"))
        * len(require_list(source_protocol.get("seeds"), "seeds"))
        * len(
            require_list(
                require_mapping(source_protocol.get("corruption_grid"), "grid").get("missing_rates"),
                "missing_rates",
            )
        )
        * len(
            require_list(
                require_mapping(source_protocol.get("corruption_grid"), "grid").get("flip_rates"),
                "flip_rates",
            )
        )
    )
    if len(cases) != expected or source_receipt.get("executed_case_count") != expected:
        raise ValueError("source receipt does not contain the complete Cartesian grid")
    keys = [case_key(case) for case in cases]
    if len(set(keys)) != len(keys):
        raise ValueError("source receipt contains duplicate case parameters")
    return cases


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--protocol", type=Path, required=True)
    parser.add_argument("--receipt", type=Path, required=True)
    parser.add_argument("--max-cases", type=int)
    args = parser.parse_args()
    if args.max_cases is not None and args.max_cases <= 0:
        raise ValueError("--max-cases must be positive")

    protocol_path = args.protocol.resolve()
    root = protocol_path.parent
    protocol = load_json(protocol_path)
    if protocol.get("schema") != "wm-fca-incomplete-context-baseline-protocol-v1":
        raise ValueError("unsupported incomplete-context protocol schema")
    if protocol.get("status") != "frozen-extension-before-comparator-execution":
        raise ValueError("protocol is not marked as a frozen extension")
    baselines = parse_baselines(protocol)

    source = require_mapping(protocol.get("source_study"), "source_study")
    source_protocol_path = relative_file(root, source.get("protocol"), "source protocol")
    source_receipt_path = relative_file(root, source.get("receipt"), "source receipt")
    source_driver_path = relative_file(
        root, source.get("reconstruction_driver"), "source reconstruction driver"
    )
    if sha256(source_protocol_path) != require_sha(source.get("protocol_sha256"), "source protocol SHA"):
        raise ValueError("source protocol hash drifted")
    if sha256(source_receipt_path) != require_sha(
        source.get("receipt_artifact_sha256"), "source receipt artifact SHA"
    ):
        raise ValueError("source receipt artifact hash drifted")
    if sha256(source_driver_path) != require_sha(
        source.get("reconstruction_driver_sha256"), "source driver SHA"
    ):
        raise ValueError("source reconstruction driver hash drifted")
    source_api = load_source_api()
    source_protocol = load_json(source_protocol_path)
    source_receipt, source_content_sha = load_gzip_json(source_receipt_path)
    if source_content_sha != require_sha(
        source.get("receipt_content_sha256"), "source receipt content SHA"
    ):
        raise ValueError("source receipt content hash drifted")
    if source_receipt.get("protocol_sha256") != sha256(source_protocol_path):
        raise ValueError("source receipt does not pin its protocol")
    source_cases = validate_source_grid(source_protocol, source_receipt)

    selection = require_mapping(protocol.get("case_selection"), "case_selection")
    if selection.get("evidence_layer") != "primary":
        raise ValueError("only the frozen primary-layer comparator is supported")
    expected_case_count = require_int(selection.get("expected_case_count"), "expected_case_count")
    if expected_case_count != len(source_cases):
        raise ValueError("comparator case count differs from the source grid")

    inputs = require_mapping(protocol.get("context_inputs"), "context_inputs")
    scale_dir = relative_directory(
        root, inputs.get("scale_context_directory"), "scale context directory"
    )
    oracle_dir = relative_directory(
        root, inputs.get("oracle_directory"), "oracle directory"
    )
    exact_limits = require_mapping(source_protocol.get("exact_limits"), "exact_limits")
    evidence_design = require_mapping(source_protocol.get("evidence_design"), "evidence_design")
    correlated_label = require_string(
        require_mapping(evidence_design.get("primary"), "primary design").get("dependence_group"),
        "primary dependence group",
    )
    independent_label = require_string(
        require_mapping(evidence_design.get("independent"), "independent design").get("dependence_group"),
        "independent dependence group",
    )

    context_cache: dict[
        str,
        tuple[
            tuple[str, ...],
            tuple[str, ...],
            tuple[str, ...],
            tuple[tuple[int, ...], ...],
            str,
            dict[str, set[object]],
        ],
    ] = {}
    cases: list[dict[str, object]] = []
    for source_case in source_cases:
        if args.max_cases is not None and len(cases) >= args.max_cases:
            break
        context_id, seed, missing_rate, flip_rate, unknown_rate = case_key(source_case)
        if context_id not in context_cache:
            (
                objects,
                attributes,
                truth_rows,
                candidates,
                context_sha,
            ) = source_api.load_scale_context(context_id, scale_dir, oracle_dir)
            truth_artifacts = source_api.exact_artifacts(
                f"{context_id}-truth",
                objects,
                attributes,
                truth_rows,
                exact_limits,
            )
            context_cache[context_id] = (
                objects,
                attributes,
                truth_rows,
                candidates,
                context_sha,
                truth_artifacts,
            )
        (
            objects,
            attributes,
            truth_rows,
            candidates,
            context_sha,
            truth_artifacts,
        ) = context_cache[context_id]
        if source_case.get("context_sha256") != context_sha:
            raise ValueError(f"{case_key(source_case)}: context hash drifted")

        source_layers = require_mapping(source_case.get("layers"), "source layers")
        source_primary = require_mapping(source_layers.get("primary"), "source primary layer")
        identity = require_string(source_primary.get("identity"), "primary identity")
        suffix = "-primary-layer"
        if not identity.endswith(suffix):
            raise ValueError("source primary identity has an unexpected form")
        case_token = identity[: -len(suffix)]
        reconstructed = source_api.build_layers(
            truth_rows,
            case_token=case_token,
            context_id=context_id,
            seed=seed,
            missing_rate=missing_rate,
            flip_rate=flip_rate,
            unknown_rate=unknown_rate,
            correlated_group_label=correlated_label,
            independent_group_label=independent_label,
        )
        for role, layer in reconstructed.items():
            if layer.record() != require_mapping(source_layers.get(role), f"source layer {role}"):
                raise ValueError(f"{case_key(source_case)}: reconstructed {role} layer differs")

        primary_rows = reconstructed["primary"].rows
        lower_rows = complete_rows(primary_rows, baselines[LOWER_ID])
        upper_rows = complete_rows(primary_rows, baselines[UPPER_ID])
        known_preserved = all(
            status not in {"0", "1"} or lower == upper == status
            for source_row, lower_row, upper_row in zip(
                primary_rows, lower_rows, upper_rows, strict=True
            )
            for status, lower, upper in zip(
                source_row, lower_row, upper_row, strict=True
            )
        )
        if not known_preserved:
            raise ValueError("a completion changed a known observation")

        baseline_results = {
            LOWER_ID: point_result(
                source_api=source_api,
                context_id=f"{context_id}-lower",
                objects=objects,
                attributes=attributes,
                rows=lower_rows,
                truth_rows=truth_rows,
                candidates=candidates,
                truth_artifacts=truth_artifacts,
                exact_limits=exact_limits,
            ),
            UPPER_ID: point_result(
                source_api=source_api,
                context_id=f"{context_id}-upper",
                objects=objects,
                attributes=attributes,
                rows=upper_rows,
                truth_rows=truth_rows,
                candidates=candidates,
                truth_artifacts=truth_artifacts,
                exact_limits=exact_limits,
            ),
        }
        cases.append(
            {
                "schema": "wm-fca-incomplete-context-baseline-case-v1",
                "baselines": baseline_results,
                "cell_midpoint": midpoint_cell_scores(lower_rows, upper_rows, truth_rows),
                "completion_checks": {
                    "known_observations_preserved": known_preserved,
                    "lower_relation_subset_upper": all(
                        lower != "1" or upper == "1"
                        for lower_row, upper_row in zip(lower_rows, upper_rows, strict=True)
                        for lower, upper in zip(lower_row, upper_row, strict=True)
                    ),
                },
                "parameters": require_mapping(source_case.get("parameters"), "parameters"),
                "source_case_identity_sha256": require_sha(
                    source_case.get("case_identity_sha256"), "source case identity"
                ),
                "source_primary_rows_sha256": require_sha(
                    source_primary.get("rows_sha256"), "source primary rows SHA"
                ),
            }
        )

    if not cases:
        raise ValueError("no comparator cases were executed")
    receipt = {
        "schema": "wm-fca-incomplete-context-baseline-run-v1",
        "aggregate": aggregate_cases(cases),
        "cases": cases,
        "executed_case_count": len(cases),
        "planned_case_count": expected_case_count,
        "protocol_complete": len(cases) == expected_case_count,
        "protocol_sha256": sha256(protocol_path),
        "runner_sha256": sha256(Path(__file__)),
        "source_receipt_artifact_sha256": sha256(source_receipt_path),
        "source_receipt_content_sha256": source_content_sha,
    }
    content_sha = write_deterministic_gzip_json(args.receipt, receipt)
    print(
        json.dumps(
            {
                "artifact_sha256": sha256(args.receipt),
                "content_sha256": content_sha,
                "executed_case_count": len(cases),
                "planned_case_count": expected_case_count,
                "protocol_complete": receipt["protocol_complete"],
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
