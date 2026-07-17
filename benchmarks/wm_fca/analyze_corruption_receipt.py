#!/usr/bin/env python3
"""Validate and summarize a complete WM/FCA corruption receipt.

This is deliberately a descriptive analysis.  The frozen experiment protocol
did not preregister a sampling model or an inferential test, so this program
does not manufacture post-hoc p-values or confidence intervals.
"""

from __future__ import annotations

import argparse
import gzip
import hashlib
import itertools
import json
import math
import re
import statistics
from pathlib import Path
from typing import Callable


MODEL_METRICS = {
    "basis_f1": ("canonical_basis", "f1"),
    "cell_accuracy": ("cells", "accuracy"),
    "cell_f1": ("cells", "f1"),
    "closure_exact_accuracy": ("closures", "exact_accuracy"),
    "closure_mean_jaccard": ("closures", "mean_jaccard"),
    "concept_f1": ("concepts", "f1"),
    "cover_f1": ("lattice_covers", "f1"),
}
BASELINE_ID = "crisp-single-source"
CONTEXT_RE = re.compile(r"^random_(\d+)_(\d+)_(0(?:\.\d+)?|1(?:\.0+)?)$")


def decoded_bytes(path: Path) -> bytes:
    payload = path.read_bytes()
    return gzip.decompress(payload) if path.suffix == ".gz" else payload


def load_object(path: Path, label: str) -> dict[str, object]:
    value = json.loads(decoded_bytes(path).decode("utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{label} must be a JSON object")
    return value


def require_mapping(value: object, label: str) -> dict[str, object]:
    if not isinstance(value, dict):
        raise ValueError(f"{label} must be an object")
    return value


def require_list(value: object, label: str) -> list[object]:
    if not isinstance(value, list):
        raise ValueError(f"{label} must be a list")
    return value


def require_number(value: object, label: str) -> float:
    if not isinstance(value, (int, float)) or isinstance(value, bool):
        raise ValueError(f"{label} must be numeric")
    result = float(value)
    if not math.isfinite(result):
        raise ValueError(f"{label} must be finite")
    return result


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def content_sha256(path: Path) -> str:
    return hashlib.sha256(decoded_bytes(path)).hexdigest()


def canonical_sha(value: object) -> str:
    payload = json.dumps(value, sort_keys=True, separators=(",", ":")).encode()
    return hashlib.sha256(payload).hexdigest()


def model_metric(case: dict[str, object], model_id: str, metric: str) -> float:
    outer, inner = MODEL_METRICS[metric]
    models = require_mapping(case.get("models"), "case.models")
    model = require_mapping(models.get(model_id), f"case.models[{model_id}]")
    values = require_mapping(model.get(outer), f"{model_id}.{outer}")
    return require_number(values.get(inner), f"{model_id}.{outer}.{inner}")


def model_flag(case: dict[str, object], model_id: str, field: str) -> bool:
    models = require_mapping(case.get("models"), "case.models")
    model = require_mapping(models.get(model_id), f"case.models[{model_id}]")
    value = model.get(field)
    if not isinstance(value, bool):
        raise ValueError(f"{model_id}.{field} must be Boolean")
    return value


def envelope_metric(case: dict[str, object], section: str, field: str) -> float:
    envelope = require_mapping(case.get("envelope"), "case.envelope")
    values = require_mapping(envelope.get(section), f"case.envelope.{section}")
    return require_number(values.get(field), f"case.envelope.{section}.{field}")


def require_aggregate_mean(
    recorded: dict[str, object], field: str, values: list[float], label: str
) -> float:
    derived = statistics.fmean(values)
    supplied = require_number(recorded.get(field), f"{label}.{field}")
    if not math.isclose(derived, supplied, rel_tol=1e-15, abs_tol=1e-15):
        raise ValueError(f"{label}.{field} disagrees with the case receipts")
    return derived


def context_factors(context_id: str) -> tuple[int, int, float]:
    match = CONTEXT_RE.fullmatch(context_id)
    if match is None:
        raise ValueError(f"unsupported context identifier: {context_id}")
    return int(match.group(1)), int(match.group(2)), float(match.group(3))


def paired_summary(
    cases: list[dict[str, object]], contender: str, metric: str
) -> dict[str, object]:
    baseline = [model_metric(case, BASELINE_ID, metric) for case in cases]
    candidate = [model_metric(case, contender, metric) for case in cases]
    deltas = [right - left for left, right in zip(baseline, candidate, strict=True)]
    epsilon = 1e-15
    return {
        "baseline_mean": statistics.fmean(baseline),
        "contender_mean": statistics.fmean(candidate),
        "losses": sum(delta < -epsilon for delta in deltas),
        "maximum_delta": max(deltas),
        "mean_delta": statistics.fmean(deltas),
        "minimum_delta": min(deltas),
        "paired_case_count": len(deltas),
        "population_stddev_delta": statistics.pstdev(deltas),
        "ties": sum(abs(delta) <= epsilon for delta in deltas),
        "wins": sum(delta > epsilon for delta in deltas),
    }


def grouped_delta(
    cases: list[dict[str, object]],
    contender: str,
    metric: str,
    key: Callable[[dict[str, object]], str],
) -> dict[str, object]:
    groups: dict[str, list[float]] = {}
    for case in cases:
        label = key(case)
        groups.setdefault(label, []).append(
            model_metric(case, contender, metric)
            - model_metric(case, BASELINE_ID, metric)
        )
    return {
        label: {
            "case_count": len(values),
            "mean_delta": statistics.fmean(values),
            "wins": sum(value > 1e-15 for value in values),
            "ties": sum(abs(value) <= 1e-15 for value in values),
            "losses": sum(value < -1e-15 for value in values),
        }
        for label, values in sorted(groups.items())
    }


def grouped_envelope_coverage(
    cases: list[dict[str, object]], key: Callable[[dict[str, object]], str]
) -> dict[str, object]:
    groups: dict[str, list[dict[str, object]]] = {}
    for case in cases:
        groups.setdefault(key(case), []).append(case)
    result: dict[str, object] = {}
    for label, group in sorted(groups.items()):
        cell_gains: list[float] = []
        closure_gains: list[float] = []
        cell_widths: list[float] = []
        closure_widths: list[float] = []
        for case in group:
            envelope = require_mapping(case.get("envelope"), "case.envelope")
            cell = require_mapping(envelope.get("cell"), "case.envelope.cell")
            closure = require_mapping(
                envelope.get("closure"), "case.envelope.closure"
            )
            cell_gains.append(
                require_number(cell.get("interval_coverage"), "cell coverage")
                - model_metric(case, BASELINE_ID, "cell_accuracy")
            )
            closure_gains.append(
                require_number(closure.get("interval_coverage"), "closure coverage")
                - model_metric(case, BASELINE_ID, "closure_exact_accuracy")
            )
            cell_widths.append(require_number(cell.get("mean_width"), "cell width"))
            closure_widths.append(
                require_number(
                    closure.get("mean_normalized_width"), "closure width"
                )
            )
        result[label] = {
            "case_count": len(group),
            "cell_coverage_gain": statistics.fmean(cell_gains),
            "cell_mean_width": statistics.fmean(cell_widths),
            "closure_coverage_gain": statistics.fmean(closure_gains),
            "closure_mean_normalized_width": statistics.fmean(closure_widths),
        }
    return result


def calibration_summary(cases: list[dict[str, object]]) -> dict[str, object]:
    crisp_errors = [
        1.0 - model_metric(case, BASELINE_ID, "cell_accuracy") for case in cases
    ]
    midpoint_brier = [envelope_metric(case, "cell", "brier") for case in cases]
    midpoint_ece = [envelope_metric(case, "cell", "ece") for case in cases]
    crisp = statistics.fmean(crisp_errors)
    brier = statistics.fmean(midpoint_brier)
    ece = statistics.fmean(midpoint_ece)
    return {
        "target": "truth-incidence cells",
        "crisp_hard_point": {
            "forecast_values": [0.0, 1.0],
            "brier": crisp,
            "ece": crisp,
            "note": (
                "For hard zero/one forecasts, Brier score and two-bin ECE both "
                "equal the cell misclassification rate."
            ),
        },
        "wm_envelope_midpoint": {
            "forecast_values": [0.0, 0.5, 1.0],
            "brier": brier,
            "ece": ece,
            "note": (
                "The midpoint of the lower/upper incidence interval is scored "
                "as a three-valued point forecast."
            ),
        },
        "midpoint_minus_crisp": {
            "brier": brier - crisp,
            "ece": ece - crisp,
        },
        "interpretation_guard": (
            "This evaluates calibration of the interval midpoint as a point "
            "forecast; it does not establish calibration of the set-valued "
            "interval itself."
        ),
    }


def grouped_calibration(
    cases: list[dict[str, object]], key: Callable[[dict[str, object]], str]
) -> dict[str, object]:
    groups: dict[str, list[dict[str, object]]] = {}
    for case in cases:
        groups.setdefault(key(case), []).append(case)
    result: dict[str, object] = {}
    for label, group in sorted(groups.items()):
        summary = calibration_summary(group)
        crisp = require_mapping(summary.get("crisp_hard_point"), "crisp calibration")
        midpoint = require_mapping(
            summary.get("wm_envelope_midpoint"), "midpoint calibration"
        )
        delta = require_mapping(summary.get("midpoint_minus_crisp"), "calibration delta")
        result[label] = {
            "case_count": len(group),
            "crisp_brier": require_number(crisp.get("brier"), "crisp brier"),
            "crisp_ece": require_number(crisp.get("ece"), "crisp ece"),
            "midpoint_brier": require_number(midpoint.get("brier"), "midpoint brier"),
            "midpoint_ece": require_number(midpoint.get("ece"), "midpoint ece"),
            "brier_delta": require_number(delta.get("brier"), "brier delta"),
            "ece_delta": require_number(delta.get("ece"), "ece delta"),
        }
    return result


def case_parameter(case: dict[str, object], name: str) -> object:
    return require_mapping(case.get("parameters"), "case.parameters").get(name)


def validate_cases(
    protocol: dict[str, object], receipt: dict[str, object], protocol_digest: str
) -> tuple[list[dict[str, object]], list[str], dict[str, str]]:
    if protocol.get("schema") != "wm-fca-corruption-protocol-v1":
        raise ValueError("unsupported protocol schema")
    if receipt.get("schema") != "wm-fca-corruption-run-v1":
        raise ValueError("unsupported receipt schema")
    if receipt.get("protocol_sha256") != protocol_digest:
        raise ValueError("receipt does not pin the supplied protocol")
    if receipt.get("protocol_complete") is not True:
        raise ValueError("analysis requires a complete protocol receipt")
    metrics = require_list(protocol.get("metrics"), "protocol.metrics")
    if any(not isinstance(metric, str) or not metric for metric in metrics):
        raise ValueError("protocol metrics must be nonempty strings")
    if len(set(metrics)) != len(metrics):
        raise ValueError("protocol metrics contain duplicates")
    required_metrics = {
        "cell_precision_recall_f1",
        "held_out_closure_exact_and_jaccard",
        "concept_set_recovery",
        "canonical_basis_recovery",
        "lattice_cover_recovery",
        "envelope_brier_ece_coverage_sharpness",
        "closure_envelope_coverage_sharpness",
        "exact_duplicate_invariance",
        "correlated_copy_invariance",
    }
    if not required_metrics <= set(metrics):
        raise ValueError("protocol omits a required registered metric")
    raw_models = require_list(protocol.get("models"), "protocol.models")
    model_gates: dict[str, str] = {}
    for index, raw_model in enumerate(raw_models):
        model = require_mapping(raw_model, f"protocol.models[{index}]")
        model_id = model.get("id")
        if not isinstance(model_id, str) or not model_id:
            raise ValueError(f"protocol.models[{index}].id must be a string")
        gate = require_mapping(model.get("gate"), f"protocol.models[{index}].gate")
        kind = gate.get("kind")
        if not isinstance(kind, str):
            raise ValueError(f"protocol.models[{index}].gate.kind must be a string")
        if model_id in model_gates:
            raise ValueError(f"duplicate model id: {model_id}")
        model_gates[model_id] = kind
    if BASELINE_ID not in model_gates:
        raise ValueError(f"protocol lacks baseline {BASELINE_ID}")
    envelope_ids = require_list(
        protocol.get("envelope_model_ids"), "protocol.envelope_model_ids"
    )
    if (
        not envelope_ids
        or any(not isinstance(model_id, str) for model_id in envelope_ids)
        or len(set(envelope_ids)) != len(envelope_ids)
        or not set(envelope_ids) <= set(model_gates)
    ):
        raise ValueError("protocol envelope model identifiers are invalid")

    contexts = require_list(protocol.get("contexts"), "protocol.contexts")
    seeds = require_list(protocol.get("seeds"), "protocol.seeds")
    grid = require_mapping(protocol.get("corruption_grid"), "corruption_grid")
    missing = require_list(grid.get("missing_rates"), "missing_rates")
    flips = require_list(grid.get("flip_rates"), "flip_rates")
    expected = {
        (context, seed, missing_rate, flip_rate)
        for context, seed, missing_rate, flip_rate in itertools.product(
            contexts, seeds, missing, flips
        )
    }
    raw_cases = require_list(receipt.get("cases"), "receipt.cases")
    cases = [require_mapping(case, f"receipt.cases[{index}]") for index, case in enumerate(raw_cases)]
    actual = {
        (
            case_parameter(case, "context_id"),
            case_parameter(case, "seed"),
            case_parameter(case, "missing_rate"),
            case_parameter(case, "flip_rate"),
        )
        for case in cases
    }
    if actual != expected or len(cases) != len(expected):
        raise ValueError("receipt cases do not equal the protocol Cartesian grid")
    if receipt.get("executed_case_count") != len(cases):
        raise ValueError("executed_case_count disagrees with receipt cases")
    if receipt.get("planned_case_count") != len(expected):
        raise ValueError("planned_case_count disagrees with protocol grid")
    driver_digest = receipt.get("driver_sha256")
    binary_digest = receipt.get("cetta_binary_sha256")
    if not isinstance(driver_digest, str) or not isinstance(binary_digest, str):
        raise ValueError("receipt lacks driver or CeTTa binary digest")
    seen_identities: set[str] = set()
    for index, case in enumerate(cases):
        models = require_mapping(case.get("models"), f"cases[{index}].models")
        if set(models) != set(model_gates):
            raise ValueError(f"cases[{index}] has the wrong model set")
        validation = require_mapping(case.get("cetta_validation"), "cetta_validation")
        if validation.get("passed") is not True or validation.get("binary_sha256") != binary_digest:
            raise ValueError(f"cases[{index}] lacks a valid pinned CeTTa result")
        expected_identity = canonical_sha(
            {
                "cetta_sha256": binary_digest,
                "context_sha256": case.get("context_sha256"),
                "driver_sha256": driver_digest,
                "parameters": case.get("parameters"),
                "protocol_sha256": protocol_digest,
            }
        )
        if case.get("case_identity_sha256") != expected_identity:
            raise ValueError(f"cases[{index}] has an invalid identity digest")
        if expected_identity in seen_identities:
            raise ValueError(f"cases[{index}] duplicates a case identity")
        seen_identities.add(expected_identity)
        layers = require_mapping(case.get("layers"), "case.layers")
        primary = require_mapping(layers.get("primary"), "layers.primary")
        copy = require_mapping(layers.get("correlated_copy"), "layers.correlated_copy")
        if primary.get("rows_sha256") != copy.get("rows_sha256"):
            raise ValueError(f"cases[{index}] correlated copy is not matrix-identical")
        if primary.get("dependence_group") != copy.get("dependence_group"):
            raise ValueError(f"cases[{index}] correlated copy has the wrong group")
        if primary.get("identity") == copy.get("identity"):
            raise ValueError(f"cases[{index}] correlated copy reuses the layer identity")
        for section, fields in {
            "cell": ("brier", "ece", "interval_coverage", "mean_width"),
            "closure": ("interval_coverage", "mean_normalized_width"),
        }.items():
            for field in fields:
                value = envelope_metric(case, section, field)
                if not 0.0 <= value <= 1.0:
                    raise ValueError(
                        f"cases[{index}].envelope.{section}.{field} is outside [0,1]"
                    )
    return cases, list(model_gates), model_gates


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--protocol", type=Path, required=True)
    parser.add_argument("--receipt", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    protocol = load_object(args.protocol, "protocol")
    receipt = load_object(args.receipt, "receipt")
    protocol_digest = sha256(args.protocol)
    cases, model_ids, model_gates = validate_cases(protocol, receipt, protocol_digest)

    comparisons = {
        model_id: {
            metric: paired_summary(cases, model_id, metric)
            for metric in MODEL_METRICS
        }
        for model_id in model_ids
        if model_id != BASELINE_ID
    }
    focus = "wm-permissive-group-1"
    focus_strata = {
        metric: {
            "context": grouped_delta(
                cases, focus, metric, lambda case: str(case_parameter(case, "context_id"))
            ),
            "flip_rate": grouped_delta(
                cases, focus, metric, lambda case: str(case_parameter(case, "flip_rate"))
            ),
            "missing_rate": grouped_delta(
                cases, focus, metric, lambda case: str(case_parameter(case, "missing_rate"))
            ),
            "object_count": grouped_delta(
                cases,
                focus,
                metric,
                lambda case: str(context_factors(str(case_parameter(case, "context_id")))[0]),
            ),
            "truth_density": grouped_delta(
                cases,
                focus,
                metric,
                lambda case: str(context_factors(str(case_parameter(case, "context_id")))[2]),
            ),
        }
        for metric in MODEL_METRICS
    }

    aggregate = require_mapping(receipt.get("aggregate"), "receipt.aggregate")
    aggregate_models = require_mapping(aggregate.get("models"), "aggregate.models")
    duplicate_rates: dict[str, float] = {}
    correlated_rates: dict[str, float] = {}
    for model_id in model_ids:
        recorded_model = require_mapping(aggregate_models.get(model_id), model_id)
        duplicate_rates[model_id] = require_aggregate_mean(
            recorded_model,
            "exact_duplicate_invariance_rate",
            [
                float(model_flag(case, model_id, "exact_duplicate_invariant"))
                for case in cases
            ],
            model_id,
        )
        correlated_rates[model_id] = require_aggregate_mean(
            recorded_model,
            "correlated_copy_invariance_rate",
            [
                float(model_flag(case, model_id, "correlated_copy_invariant"))
                for case in cases
            ],
            model_id,
        )
    group_models = [model_id for model_id in model_ids if model_gates[model_id] == "positive-groups"]
    raw_models = [
        model_id
        for model_id in model_ids
        if model_gates[model_id] in {"positive-observations", "positive-sources"}
        and model_id != BASELINE_ID
    ]

    envelope = require_mapping(aggregate.get("envelope"), "aggregate.envelope")
    envelope_cell = require_mapping(envelope.get("cell"), "envelope.cell")
    envelope_closure = require_mapping(envelope.get("closure"), "envelope.closure")
    cell_brier = require_aggregate_mean(
        envelope_cell,
        "brier",
        [envelope_metric(case, "cell", "brier") for case in cases],
        "envelope.cell",
    )
    cell_ece = require_aggregate_mean(
        envelope_cell,
        "ece",
        [envelope_metric(case, "cell", "ece") for case in cases],
        "envelope.cell",
    )
    cell_coverage = require_aggregate_mean(
        envelope_cell,
        "interval_coverage",
        [envelope_metric(case, "cell", "interval_coverage") for case in cases],
        "envelope.cell",
    )
    cell_width = require_aggregate_mean(
        envelope_cell,
        "mean_width",
        [envelope_metric(case, "cell", "mean_width") for case in cases],
        "envelope.cell",
    )
    closure_coverage = require_aggregate_mean(
        envelope_closure,
        "interval_coverage",
        [envelope_metric(case, "closure", "interval_coverage") for case in cases],
        "envelope.closure",
    )
    closure_width = require_aggregate_mean(
        envelope_closure,
        "mean_normalized_width",
        [
            envelope_metric(case, "closure", "mean_normalized_width")
            for case in cases
        ],
        "envelope.closure",
    )
    point_cell_coverage = statistics.fmean(
        model_metric(case, BASELINE_ID, "cell_accuracy") for case in cases
    )
    point_closure_coverage = statistics.fmean(
        model_metric(case, BASELINE_ID, "closure_exact_accuracy") for case in cases
    )
    coverage = {
        "cell": {
            "crisp_singleton_coverage": point_cell_coverage,
            "wm_envelope_coverage": cell_coverage,
            "coverage_gain": cell_coverage - point_cell_coverage,
            "mean_width": cell_width,
        },
        "closure": {
            "crisp_singleton_coverage": point_closure_coverage,
            "wm_envelope_coverage": closure_coverage,
            "coverage_gain": closure_coverage - point_closure_coverage,
            "mean_normalized_width": closure_width,
        },
    }
    calibration = calibration_summary(cases)
    calibration_midpoint = require_mapping(
        calibration.get("wm_envelope_midpoint"), "midpoint calibration"
    )
    if not math.isclose(
        require_number(calibration_midpoint.get("brier"), "midpoint brier"),
        cell_brier,
        rel_tol=1e-15,
        abs_tol=1e-15,
    ) or not math.isclose(
        require_number(calibration_midpoint.get("ece"), "midpoint ece"),
        cell_ece,
        rel_tol=1e-15,
        abs_tol=1e-15,
    ):
        raise ValueError("calibration summary disagrees with receipt aggregates")
    calibration["strata"] = {
        "flip_rate": grouped_calibration(
            cases, lambda case: str(case_parameter(case, "flip_rate"))
        ),
        "missing_rate": grouped_calibration(
            cases, lambda case: str(case_parameter(case, "missing_rate"))
        ),
    }
    coverage_strata = {
        "flip_rate": grouped_envelope_coverage(
            cases, lambda case: str(case_parameter(case, "flip_rate"))
        ),
        "missing_rate": grouped_envelope_coverage(
            cases, lambda case: str(case_parameter(case, "missing_rate"))
        ),
    }
    stratum_coverage_gains = [
        require_number(values.get(metric), f"coverage_strata.{factor}.{label}.{metric}")
        for factor, strata in coverage_strata.items()
        for label, raw_values in strata.items()
        for values in [require_mapping(raw_values, f"coverage_strata.{factor}.{label}")]
        for metric in ("cell_coverage_gain", "closure_coverage_gain")
    ]

    analysis = {
        "schema": "wm-fca-corruption-analysis-v1",
        "analysis_scope": {
            "kind": "post-run-descriptive",
            "confidence_intervals": False,
            "p_values": False,
            "reason": "The frozen protocol did not preregister a sampling model or inferential test.",
        },
        "analysis_script_sha256": sha256(Path(__file__)),
        "calibration_evaluation": calibration,
        "case_count": len(cases),
        "comparisons_against_crisp_single_source": comparisons,
        "focus_model": focus,
        "focus_model_strata": focus_strata,
        "hypothesis_evaluation": {
            "exact_duplicate_invariance": {
                "passed": all(rate == 1.0 for rate in duplicate_rates.values()),
                "rates": duplicate_rates,
            },
            "declared_dependence_group_invariance": {
                "passed": all(correlated_rates[model_id] == 1.0 for model_id in group_models),
                "dependence_group_models": group_models,
                "dependence_group_model_rates": {
                    model_id: correlated_rates[model_id] for model_id in group_models
                },
                "raw_or_source_counting_rates": {
                    model_id: correlated_rates[model_id] for model_id in raw_models
                },
            },
            "wm_envelope_coverage": {
                "passed": coverage["cell"]["coverage_gain"] > 0.0
                and coverage["closure"]["coverage_gain"] > 0.0
                and all(gain > 0.0 for gain in stratum_coverage_gains),
                "coverage_and_width": coverage,
                "strata": coverage_strata,
            },
            "no_post_outcome_model_selection": {
                "kind": "design-assurance-not-empirical-test",
                "protocol_sha256": protocol_digest,
                "model_ids": model_ids,
            },
        },
        "protocol_hypotheses": require_list(
            protocol.get("preregistered_hypotheses"), "preregistered_hypotheses"
        ),
        "protocol_sha256": protocol_digest,
        "source_receipt_artifact_sha256": sha256(args.receipt),
        "source_receipt_content_sha256": content_sha256(args.receipt),
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(analysis, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print(
        json.dumps(
            {
                "case_count": len(cases),
                "output_sha256": sha256(args.output),
                "structural_hypotheses_passed": {
                    key: value.get("passed")
                    for key, value in analysis["hypothesis_evaluation"].items()
                    if isinstance(value, dict) and "passed" in value
                },
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
