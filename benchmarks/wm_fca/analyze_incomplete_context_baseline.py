#!/usr/bin/env python3
"""Validate and analyze the frozen incomplete-context FCA comparator receipt."""

from __future__ import annotations

import argparse
import json
import statistics
from pathlib import Path

from run_incomplete_context_baseline import (
    LOWER_ID,
    UPPER_ID,
    aggregate_cases,
    case_key,
    load_gzip_json,
    load_json,
    relative_file,
    require_int,
    require_list,
    require_mapping,
    require_sha,
    require_string,
    sha256,
)


METRIC_PATHS = {
    "basis_f1": ("canonical_basis", "f1"),
    "cell_f1": ("cells", "f1"),
    "closure_exact_accuracy": ("closures", "exact_accuracy"),
    "closure_mean_jaccard": ("closures", "mean_jaccard"),
    "concept_f1": ("concepts", "f1"),
    "cover_f1": ("lattice_covers", "f1"),
}


def require_unit(value: object, label: str) -> float:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise ValueError(f"{label} must be numeric")
    result = float(value)
    if not 0.0 <= result <= 1.0:
        raise ValueError(f"{label} must lie in [0, 1]")
    return result


def require_nonnegative_int(value: object, label: str) -> int:
    result = require_int(value, label)
    if result < 0:
        raise ValueError(f"{label} must be nonnegative")
    return result


def validate_set_scores(value: object, label: str) -> None:
    scores = require_mapping(value, label)
    for field in ("f1", "precision", "recall"):
        require_unit(scores.get(field), f"{label}.{field}")
    for field in ("false_negative", "false_positive", "true_positive"):
        require_nonnegative_int(scores.get(field), f"{label}.{field}")


def validate_baseline(value: object, label: str) -> None:
    baseline = require_mapping(value, label)
    if set(baseline) != {
        "canonical_basis",
        "cells",
        "closures",
        "concepts",
        "incidence_sha256",
        "lattice_covers",
    }:
        raise ValueError(f"{label} has an unexpected field set")
    validate_set_scores(baseline.get("canonical_basis"), f"{label}.canonical_basis")
    validate_set_scores(baseline.get("concepts"), f"{label}.concepts")
    validate_set_scores(baseline.get("lattice_covers"), f"{label}.lattice_covers")
    cells = require_mapping(baseline.get("cells"), f"{label}.cells")
    validate_set_scores(cells, f"{label}.cells")
    require_unit(cells.get("accuracy"), f"{label}.cells.accuracy")
    closures = require_mapping(baseline.get("closures"), f"{label}.closures")
    for field in ("exact_accuracy", "mean_jaccard", "micro_f1"):
        require_unit(closures.get(field), f"{label}.closures.{field}")
    if require_int(closures.get("query_count"), f"{label}.closures.query_count") <= 0:
        raise ValueError(f"{label}.closures.query_count must be positive")
    require_sha(baseline.get("incidence_sha256"), f"{label}.incidence_sha256")


def metric(case: dict[str, object], model_id: str, metric_id: str) -> float:
    baselines = require_mapping(case.get("baselines"), "case.baselines")
    model = require_mapping(baselines.get(model_id), f"case.baselines.{model_id}")
    section, field = METRIC_PATHS[metric_id]
    return require_unit(
        require_mapping(model.get(section), f"{model_id}.{section}").get(field),
        f"{model_id}.{metric_id}",
    )


def source_metric(case: dict[str, object], model_id: str, metric_id: str) -> float:
    models = require_mapping(case.get("models"), "source case.models")
    model = require_mapping(models.get(model_id), f"source case.models.{model_id}")
    section, field = METRIC_PATHS[metric_id]
    return require_unit(
        require_mapping(model.get(section), f"{model_id}.{section}").get(field),
        f"{model_id}.{metric_id}",
    )


def paired_summary(left: list[float], right: list[float]) -> dict[str, object]:
    if len(left) != len(right) or not left:
        raise ValueError("paired comparison requires equal nonempty samples")
    differences = [a - b for a, b in zip(left, right, strict=True)]
    return {
        "mean_difference": statistics.fmean(differences),
        "losses": sum(value < 0.0 for value in differences),
        "ties": sum(value == 0.0 for value in differences),
        "wins": sum(value > 0.0 for value in differences),
    }


def validate_case(value: object, index: int) -> dict[str, object]:
    case = require_mapping(value, f"cases[{index}]")
    if case.get("schema") != "wm-fca-incomplete-context-baseline-case-v1":
        raise ValueError(f"cases[{index}] has an unsupported schema")
    baselines = require_mapping(case.get("baselines"), f"cases[{index}].baselines")
    if set(baselines) != {LOWER_ID, UPPER_ID}:
        raise ValueError(f"cases[{index}] must contain both frozen completions")
    for baseline_id in (LOWER_ID, UPPER_ID):
        validate_baseline(baselines.get(baseline_id), f"cases[{index}].{baseline_id}")
    checks = require_mapping(
        case.get("completion_checks"), f"cases[{index}].completion_checks"
    )
    if checks != {
        "known_observations_preserved": True,
        "lower_relation_subset_upper": True,
    }:
        raise ValueError(f"cases[{index}] failed a completion invariant")
    midpoint = require_mapping(case.get("cell_midpoint"), f"cases[{index}].cell_midpoint")
    if midpoint.get("forecast_values") != [0.0, 0.5, 1.0]:
        raise ValueError(f"cases[{index}] has unexpected midpoint forecast values")
    for field in ("brier", "ece", "interval_coverage", "mean_width"):
        require_unit(midpoint.get(field), f"cases[{index}].cell_midpoint.{field}")
    require_sha(case.get("source_case_identity_sha256"), "source case identity")
    require_sha(case.get("source_primary_rows_sha256"), "source primary rows SHA")
    case_key(case)
    return case


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--protocol", type=Path, required=True)
    parser.add_argument("--receipt", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    protocol_path = args.protocol.resolve()
    root = protocol_path.parent
    protocol = load_json(protocol_path)
    if protocol.get("schema") != "wm-fca-incomplete-context-baseline-protocol-v1":
        raise ValueError("unsupported incomplete-context protocol schema")
    receipt, receipt_content_sha = load_gzip_json(args.receipt.resolve())
    if receipt.get("schema") != "wm-fca-incomplete-context-baseline-run-v1":
        raise ValueError("unsupported incomplete-context receipt schema")
    if receipt.get("protocol_sha256") != sha256(protocol_path):
        raise ValueError("receipt does not pin the supplied protocol")
    runner_path = root / "run_incomplete_context_baseline.py"
    if receipt.get("runner_sha256") != sha256(runner_path):
        raise ValueError("receipt does not pin the current comparator runner")
    if receipt.get("protocol_complete") is not True:
        raise ValueError("analysis requires a protocol-complete receipt")

    selection = require_mapping(protocol.get("case_selection"), "case_selection")
    expected_case_count = require_int(
        selection.get("expected_case_count"), "expected_case_count"
    )
    if receipt.get("planned_case_count") != expected_case_count:
        raise ValueError("receipt planned case count drifted")
    if receipt.get("executed_case_count") != expected_case_count:
        raise ValueError("receipt is missing comparator cases")
    cases = [
        validate_case(value, index)
        for index, value in enumerate(require_list(receipt.get("cases"), "cases"))
    ]
    if len(cases) != expected_case_count:
        raise ValueError("receipt case array has the wrong cardinality")
    keys = [case_key(case) for case in cases]
    if len(set(keys)) != len(keys):
        raise ValueError("receipt contains duplicate comparator cases")
    recomputed_aggregate = aggregate_cases(cases)
    if receipt.get("aggregate") != recomputed_aggregate:
        raise ValueError("receipt aggregate differs from exact case recomputation")

    source = require_mapping(protocol.get("source_study"), "source_study")
    source_receipt_path = relative_file(root, source.get("receipt"), "source receipt")
    if receipt.get("source_receipt_artifact_sha256") != sha256(source_receipt_path):
        raise ValueError("comparator receipt points to a different source artifact")
    source_receipt, source_content_sha = load_gzip_json(source_receipt_path)
    if receipt.get("source_receipt_content_sha256") != source_content_sha:
        raise ValueError("comparator receipt points to different source content")
    if source_content_sha != source.get("receipt_content_sha256"):
        raise ValueError("protocol and source receipt content disagree")
    source_cases = [
        require_mapping(value, f"source cases[{index}]")
        for index, value in enumerate(
            require_list(source_receipt.get("cases"), "source cases")
        )
    ]
    source_by_key = {case_key(case): case for case in source_cases}
    if len(source_by_key) != expected_case_count or set(source_by_key) != set(keys):
        raise ValueError("comparator and source case universes differ")
    for case in cases:
        source_case = source_by_key[case_key(case)]
        if case.get("source_case_identity_sha256") != source_case.get("case_identity_sha256"):
            raise ValueError("a comparator case points to the wrong source case")
        source_primary = require_mapping(
            require_mapping(source_case.get("layers"), "source layers").get("primary"),
            "source primary layer",
        )
        if case.get("source_primary_rows_sha256") != source_primary.get("rows_sha256"):
            raise ValueError("a comparator case points to the wrong primary matrix")

    comparison = require_mapping(protocol.get("comparison_policy"), "comparison_policy")
    source_model_ids = [
        require_string(value, f"source_models[{index}]")
        for index, value in enumerate(
            require_list(comparison.get("source_models"), "source_models")
        )
    ]
    if comparison.get("report_both_completions") is not True or comparison.get("selection") != "none":
        raise ValueError("comparison policy permits selection or hides a completion")
    if len(set(source_model_ids)) != len(source_model_ids):
        raise ValueError("comparison policy repeats a source model")
    for source_case in source_cases:
        if set(require_mapping(source_case.get("models"), "source models")) != set(source_model_ids):
            raise ValueError("comparison policy does not enumerate every source model")

    source_model_means = {
        model_id: {
            metric_id: statistics.fmean(
                source_metric(source_by_key[case_key(case)], model_id, metric_id)
                for case in cases
            )
            for metric_id in METRIC_PATHS
        }
        for model_id in source_model_ids
    }
    paired = {
        baseline_id: {
            source_model_id: {
                metric_id: paired_summary(
                    [metric(case, baseline_id, metric_id) for case in cases],
                    [
                        source_metric(
                            source_by_key[case_key(case)], source_model_id, metric_id
                        )
                        for case in cases
                    ],
                )
                for metric_id in METRIC_PATHS
            }
            for source_model_id in source_model_ids
        }
        for baseline_id in (LOWER_ID, UPPER_ID)
    }

    crisp_brier: list[float] = []
    wm_brier: list[float] = []
    wm_ece: list[float] = []
    wm_coverage: list[float] = []
    wm_width: list[float] = []
    for case in cases:
        source_case = source_by_key[case_key(case)]
        crisp = require_mapping(
            require_mapping(source_case.get("models"), "source models").get(
                "crisp-single-source"
            ),
            "crisp source model",
        )
        crisp_accuracy = require_unit(
            require_mapping(crisp.get("cells"), "crisp cells").get("accuracy"),
            "crisp cell accuracy",
        )
        crisp_brier.append(1.0 - crisp_accuracy)
        wm_cell = require_mapping(
            require_mapping(source_case.get("envelope"), "source envelope").get("cell"),
            "source envelope cell",
        )
        wm_brier.append(require_unit(wm_cell.get("brier"), "WM midpoint brier"))
        wm_ece.append(require_unit(wm_cell.get("ece"), "WM midpoint ece"))
        wm_coverage.append(
            require_unit(wm_cell.get("interval_coverage"), "WM interval coverage")
        )
        wm_width.append(require_unit(wm_cell.get("mean_width"), "WM interval width"))
    baseline_midpoint = require_mapping(
        recomputed_aggregate.get("cell_midpoint"), "baseline midpoint"
    )
    calibration = {
        "crisp_hard_point": {
            "brier": statistics.fmean(crisp_brier),
            "ece": statistics.fmean(crisp_brier),
            "interval_coverage": statistics.fmean(1.0 - value for value in crisp_brier),
            "mean_width": 0.0,
        },
        "incomplete_completion_midpoint": baseline_midpoint,
        "wm_model_family_midpoint": {
            "brier": statistics.fmean(wm_brier),
            "ece": statistics.fmean(wm_ece),
            "interval_coverage": statistics.fmean(wm_coverage),
            "mean_width": statistics.fmean(wm_width),
        },
        "interpretation_guard": (
            "Brier score and ECE evaluate point forecasts; interval coverage and "
            "width are reported separately and do not establish set-valued calibration."
        ),
    }

    output = {
        "schema": "wm-fca-incomplete-context-baseline-analysis-v1",
        "analysis_script_sha256": sha256(Path(__file__)),
        "baseline_aggregate": recomputed_aggregate,
        "baseline_receipt_artifact_sha256": sha256(args.receipt.resolve()),
        "baseline_receipt_content_sha256": receipt_content_sha,
        "calibration_and_coverage": calibration,
        "case_count": len(cases),
        "paired_comparisons": paired,
        "protocol_sha256": sha256(protocol_path),
        "source_model_means": source_model_means,
        "source_receipt_artifact_sha256": sha256(source_receipt_path),
        "source_receipt_content_sha256": source_content_sha,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(output, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print(
        json.dumps(
            {
                "case_count": len(cases),
                "output_sha256": sha256(args.output),
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
