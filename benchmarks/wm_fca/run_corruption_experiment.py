#!/usr/bin/env python3
"""Run the preregistered CPU-only WM/FCA corruption experiment.

CeTTa is the load-bearing runtime for every evidence projection and closure
batch.  Python constructs frozen corruptions, supplies independent expected
values, computes evaluation statistics, and emits machine-auditable receipts.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import statistics
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from cxt_oracle import FormalContext, read_cxt
from scalable_cxt_oracle import (
    cover_relation,
    lectic_canonical_system,
)


def require_mapping(value: object, label: str) -> dict[str, object]:
    if not isinstance(value, dict):
        raise ValueError(f"{label} must be an object")
    return value


def require_list(value: object, label: str) -> list[object]:
    if not isinstance(value, list):
        raise ValueError(f"{label} must be a list")
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
    if not math.isfinite(result) or result < 0.0 or result > 1.0:
        raise ValueError(f"{label} must lie in [0, 1]")
    return result


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def canonical_sha(value: object) -> str:
    encoded = json.dumps(value, sort_keys=True, separators=(",", ":")).encode()
    return hashlib.sha256(encoded).hexdigest()


def deterministic_unit(*parts: object) -> float:
    payload = "\x1f".join(str(part) for part in parts).encode()
    return int.from_bytes(hashlib.sha256(payload).digest()[:8], "big") / 2**64


@dataclass(frozen=True)
class Layer:
    role: str
    identity: str
    context: str
    source: str
    group: str
    rows: tuple[str, ...]

    def record(self) -> dict[str, object]:
        return {
            "dependence_group": self.group,
            "identity": self.identity,
            "nonmissing_count": sum(
                status != "." for row in self.rows for status in row
            ),
            "role": self.role,
            "rows_sha256": hashlib.sha256(
                ("\n".join(self.rows) + "\n").encode()
            ).hexdigest(),
            "source": self.source,
            "status_counts": {
                status: sum(cell == status for row in self.rows for cell in row)
                for status in ("1", "0", "u", ".")
            },
        }


@dataclass(frozen=True)
class Model:
    id: str
    roles: tuple[str, ...]
    gate_kind: str
    threshold: int | None


def set_scores(predicted: set[object], truth: set[object]) -> dict[str, float | int]:
    tp = len(predicted & truth)
    fp = len(predicted - truth)
    fn = len(truth - predicted)
    precision = 1.0 if not predicted and not truth else tp / (tp + fp) if tp + fp else 0.0
    recall = 1.0 if not truth else tp / (tp + fn)
    f1 = (
        1.0
        if not predicted and not truth
        else 2 * precision * recall / (precision + recall)
        if precision + recall
        else 0.0
    )
    return {
        "f1": f1,
        "false_negative": fn,
        "false_positive": fp,
        "precision": precision,
        "recall": recall,
        "true_positive": tp,
    }


def jaccard(left: set[int], right: set[int]) -> float:
    union = left | right
    return 1.0 if not union else len(left & right) / len(union)


def parse_models(protocol: dict[str, object]) -> tuple[Model, ...]:
    models: list[Model] = []
    seen: set[str] = set()
    for index, raw_value in enumerate(require_list(protocol.get("models"), "models")):
        raw = require_mapping(raw_value, f"models[{index}]")
        model_id = require_string(raw.get("id"), f"models[{index}].id")
        if model_id in seen:
            raise ValueError(f"duplicate model id: {model_id}")
        seen.add(model_id)
        roles = tuple(
            require_string(role, f"models[{index}].layers[{role_index}]")
            for role_index, role in enumerate(
                require_list(raw.get("layers"), f"models[{index}].layers")
            )
        )
        gate = require_mapping(raw.get("gate"), f"models[{index}].gate")
        kind = require_string(gate.get("kind"), f"models[{index}].gate.kind")
        threshold = None if kind == "exact" else require_int(
            gate.get("threshold"), f"models[{index}].gate.threshold"
        )
        if kind not in {
            "exact",
            "positive-observations",
            "positive-sources",
            "positive-groups",
        }:
            raise ValueError(f"{model_id}: unsupported gate kind {kind}")
        if threshold is not None and threshold < 0:
            raise ValueError(f"{model_id}: threshold must be nonnegative")
        models.append(Model(model_id, roles, kind, threshold))
    if not models:
        raise ValueError("protocol defines no models")
    return tuple(models)


def corrupt_rows(
    truth_rows: tuple[str, ...],
    *,
    context_id: str,
    seed: int,
    channel: str,
    missing_rate: float,
    flip_rate: float,
    unknown_rate: float,
) -> tuple[str, ...]:
    result: list[str] = []
    for object_index, truth_row in enumerate(truth_rows):
        statuses: list[str] = []
        for attribute_index, truth in enumerate(truth_row):
            key = (context_id, seed, channel, object_index, attribute_index)
            if deterministic_unit(*key, "missing") < missing_rate:
                statuses.append(".")
                continue
            if deterministic_unit(*key, "unknown") < unknown_rate:
                statuses.append("u")
                continue
            flipped = deterministic_unit(*key, "flip") < flip_rate
            statuses.append(("0" if truth == "1" else "1") if flipped else truth)
        result.append("".join(statuses))
    return tuple(result)


def build_layers(
    truth_rows: tuple[str, ...],
    *,
    case_token: str,
    context_id: str,
    seed: int,
    missing_rate: float,
    flip_rate: float,
    unknown_rate: float,
    correlated_group_label: str,
    independent_group_label: str,
) -> dict[str, Layer]:
    primary_rows = corrupt_rows(
        truth_rows,
        context_id=context_id,
        seed=seed,
        channel=correlated_group_label,
        missing_rate=missing_rate,
        flip_rate=flip_rate,
        unknown_rate=unknown_rate,
    )
    independent_rows = corrupt_rows(
        truth_rows,
        context_id=context_id,
        seed=seed,
        channel=independent_group_label,
        missing_rate=missing_rate,
        flip_rate=flip_rate,
        unknown_rate=unknown_rate,
    )
    return {
        "primary": Layer(
            "primary",
            f"{case_token}-primary-layer",
            context_id,
            f"{case_token}-primary-source",
            f"{case_token}-{correlated_group_label}",
            primary_rows,
        ),
        "correlated_copy": Layer(
            "correlated_copy",
            f"{case_token}-correlated-copy-layer",
            context_id,
            f"{case_token}-correlated-copy-source",
            f"{case_token}-{correlated_group_label}",
            primary_rows,
        ),
        "independent": Layer(
            "independent",
            f"{case_token}-independent-layer",
            context_id,
            f"{case_token}-independent-source",
            f"{case_token}-{independent_group_label}",
            independent_rows,
        ),
    }


def project_rows(
    layers: Iterable[Layer],
    model: Model,
    object_count: int,
    attribute_count: int,
) -> tuple[str, ...]:
    selected: list[Layer] = []
    by_identity: dict[str, Layer] = {}
    for layer in layers:
        prior = by_identity.get(layer.identity)
        if prior is not None:
            if prior != layer:
                raise ValueError(
                    f"conflicting packed evidence layer identity: {layer.identity}"
                )
            continue
        by_identity[layer.identity] = layer
        selected.append(layer)
    rows: list[str] = []
    for object_index in range(object_count):
        result: list[str] = []
        for attribute_index in range(attribute_count):
            evidence = [
                (layer, layer.rows[object_index][attribute_index])
                for layer in selected
                if layer.rows[object_index][attribute_index] != "."
            ]
            positive = [(layer, status) for layer, status in evidence if status == "1"]
            if model.gate_kind == "exact":
                accepted = bool(positive) and len(positive) == len(evidence)
            elif model.gate_kind == "positive-observations":
                accepted = len(positive) >= int(model.threshold)
            elif model.gate_kind == "positive-sources":
                accepted = (
                    len({layer.source for layer, _ in positive})
                    >= int(model.threshold)
                )
            else:
                accepted = (
                    len({layer.group for layer, _ in positive})
                    >= int(model.threshold)
                )
            result.append("1" if accepted else "0")
        rows.append("".join(result))
    return tuple(rows)


def row_masks(rows: tuple[str, ...]) -> tuple[int, ...]:
    return tuple(
        sum(1 << index for index, value in enumerate(row) if value == "1")
        for row in rows
    )


def closure_query(rows: tuple[str, ...], candidate: tuple[int, ...]) -> tuple[set[int], set[int]]:
    masks = row_masks(rows)
    candidate_mask = sum(1 << item for item in candidate)
    extent = {
        object_index
        for object_index, mask in enumerate(masks)
        if candidate_mask & ~mask == 0
    }
    attribute_count = len(rows[0]) if rows else 0
    if not extent:
        closure_mask = (1 << attribute_count) - 1
    else:
        iterator = iter(extent)
        closure_mask = masks[next(iterator)]
        for object_index in iterator:
            closure_mask &= masks[object_index]
    closure = {
        attribute for attribute in range(attribute_count)
        if closure_mask & (1 << attribute)
    }
    return extent, closure


def exact_artifacts(
    context_id: str,
    objects: tuple[str, ...],
    attributes: tuple[str, ...],
    rows: tuple[str, ...],
    limits: dict[str, object],
) -> dict[str, set[object]]:
    context = FormalContext(
        context_id,
        objects,
        attributes,
        tuple(
            frozenset(
                attribute
                for attribute, status in zip(attributes, row, strict=True)
                if status == "1"
            )
            for row in rows
        ),
    )
    intents, basis, _ = lectic_canonical_system(
        context,
        require_int(limits.get("logical_steps"), "exact_limits.logical_steps"),
        require_int(limits.get("concepts"), "exact_limits.concepts"),
        require_int(limits.get("basis"), "exact_limits.basis"),
    )
    covers = cover_relation(
        intents, require_int(limits.get("covers"), "exact_limits.covers")
    )
    masks = row_masks(rows)
    concepts = {
        (
            tuple(
                object_index
                for object_index, row_mask in enumerate(masks)
                if intent & ~row_mask == 0
            ),
            intent,
        )
        for intent in intents
    }
    return {
        "basis": set(basis),
        "concepts": set(concepts),
        "covers": set(covers),
        "intents": set(intents),
    }


def cell_scores(predicted: tuple[str, ...], truth: tuple[str, ...]) -> dict[str, float | int]:
    predicted_set = {
        (object_index, attribute_index)
        for object_index, row in enumerate(predicted)
        for attribute_index, value in enumerate(row)
        if value == "1"
    }
    truth_set = {
        (object_index, attribute_index)
        for object_index, row in enumerate(truth)
        for attribute_index, value in enumerate(row)
        if value == "1"
    }
    scores = set_scores(predicted_set, truth_set)
    correct = sum(
        predicted_value == truth_value
        for predicted_row, truth_row in zip(predicted, truth, strict=True)
        for predicted_value, truth_value in zip(predicted_row, truth_row, strict=True)
    )
    scores["accuracy"] = correct / sum(len(row) for row in truth)
    return scores


def closure_scores(
    predicted: tuple[str, ...],
    truth: tuple[str, ...],
    candidates: tuple[tuple[int, ...], ...],
) -> dict[str, float | int]:
    exact = 0
    jaccards: list[float] = []
    tp = fp = fn = 0
    for candidate in candidates:
        _, predicted_closure = closure_query(predicted, candidate)
        _, truth_closure = closure_query(truth, candidate)
        exact += predicted_closure == truth_closure
        jaccards.append(jaccard(predicted_closure, truth_closure))
        tp += len(predicted_closure & truth_closure)
        fp += len(predicted_closure - truth_closure)
        fn += len(truth_closure - predicted_closure)
    precision = tp / (tp + fp) if tp + fp else 1.0
    recall = tp / (tp + fn) if tp + fn else 1.0
    return {
        "exact_accuracy": exact / len(candidates),
        "mean_jaccard": statistics.fmean(jaccards),
        "micro_f1": 2 * precision * recall / (precision + recall)
        if precision + recall
        else 0.0,
        "query_count": len(candidates),
    }


def envelope_scores(
    model_rows: list[tuple[str, ...]],
    truth: tuple[str, ...],
    candidates: tuple[tuple[int, ...], ...],
) -> dict[str, object]:
    probabilities: list[float] = []
    outcomes: list[int] = []
    coverages: list[float] = []
    widths: list[float] = []
    for object_index, truth_row in enumerate(truth):
        for attribute_index, truth_value in enumerate(truth_row):
            values = [
                rows[object_index][attribute_index] == "1" for rows in model_rows
            ]
            lower = int(all(values))
            upper = int(any(values))
            outcome = int(truth_value == "1")
            probabilities.append((lower + upper) / 2)
            outcomes.append(outcome)
            coverages.append(float(lower <= outcome <= upper))
            widths.append(float(upper - lower))
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

    closure_covered = 0
    closure_widths: list[float] = []
    attribute_count = len(truth[0]) if truth else 0
    for candidate in candidates:
        model_closures = [closure_query(rows, candidate)[1] for rows in model_rows]
        lower_closure = set.intersection(*model_closures)
        upper_closure = set.union(*model_closures)
        truth_closure = closure_query(truth, candidate)[1]
        closure_covered += lower_closure <= truth_closure <= upper_closure
        closure_widths.append(
            (len(upper_closure) - len(lower_closure)) / attribute_count
            if attribute_count
            else 0.0
        )
    return {
        "cell": {
            "brier": brier,
            "ece": ece,
            "interval_coverage": statistics.fmean(coverages),
            "mean_width": statistics.fmean(widths),
        },
        "closure": {
            "interval_coverage": closure_covered / len(candidates),
            "mean_normalized_width": statistics.fmean(closure_widths),
        },
    }


def metta_list(items: Iterable[str]) -> str:
    return f"({' '.join(items)})"


def render_layer(layer: Layer, objects: tuple[str, ...]) -> str:
    rows = "\n".join(
        f'       (WMFCAStatusRow {obj} "{statuses}")'
        for obj, statuses in zip(objects, layer.rows, strict=True)
    )
    return (
        f"(WMFCAEvidenceLayer\n"
        f"       {layer.identity} {layer.context} {layer.source} {layer.group}\n"
        f"       (\n{rows}))"
    )


def render_gate(model: Model) -> str:
    if model.gate_kind == "exact":
        return "WMFCAExactStatusGate"
    heads = {
        "positive-observations": "WMFCAPositiveObservationThreshold",
        "positive-sources": "WMFCAPositiveSourceThreshold",
        "positive-groups": "WMFCAPositiveDependenceGroupThreshold",
    }
    return f"({heads[model.gate_kind]} {model.threshold})"


def render_columns(
    rows: tuple[str, ...], objects: tuple[str, ...], attributes: tuple[str, ...]
) -> str:
    columns = []
    for attribute_index, attribute in enumerate(attributes):
        members = [
            obj
            for obj, row in zip(objects, rows, strict=True)
            if row[attribute_index] == "1"
        ]
        columns.append(f"(WMFCAColumn {attribute} {metta_list(members)})")
    return "(\n" + "\n".join(f"     {column}" for column in columns) + ")"


def render_batch(
    rows: tuple[str, ...],
    objects: tuple[str, ...],
    attributes: tuple[str, ...],
    candidates: tuple[tuple[int, ...], ...],
) -> str:
    results = []
    for candidate in candidates:
        extent, closure = closure_query(rows, candidate)
        candidate_symbols = [attributes[index] for index in candidate]
        extent_symbols = [
            objects[index] for index in range(len(objects)) if index in extent
        ]
        closure_symbols = [
            attributes[index] for index in range(len(attributes)) if index in closure
        ]
        results.append(
            "(WMFCABatchQueryResult "
            f"{metta_list(candidate_symbols)} {metta_list(extent_symbols)} "
            f"{metta_list(closure_symbols)})"
        )
    return "(\n" + "\n".join(f"     {result}" for result in results) + ")"


def render_case_fixture(
    *,
    case_slug: str,
    context_id: str,
    objects: tuple[str, ...],
    attributes: tuple[str, ...],
    layers: dict[str, Layer],
    models: tuple[Model, ...],
    candidates: tuple[tuple[int, ...], ...],
    projections: dict[tuple[str, tuple[str, ...]], tuple[str, ...]],
) -> tuple[str, str, int]:
    role_sets = {
        model.roles for model in models
    } | {
        tuple(role for role in model.roles if role != "correlated_copy")
        for model in models
    }
    definitions = []
    state_names: dict[tuple[str, ...], str] = {}
    duplicate_names: dict[tuple[str, ...], str] = {}
    for index, roles in enumerate(sorted(role_sets)):
        name = f"wm-fca-corruption-{case_slug}-state-{index}"
        duplicate_name = f"{name}-exact-duplicate"
        state_names[roles] = name
        duplicate_names[roles] = duplicate_name
        rendered = [render_layer(layers[role], objects) for role in roles]
        duplicate_rendered = rendered + ([render_layer(layers[roles[0]], objects)] if roles else [])
        definitions.append(
            f"(= ({name})\n"
            f"   (WMFCAPackedEvidenceState\n"
            f"     {metta_list(objects)} {metta_list(attributes)}\n"
            f"     (\n{chr(10).join(rendered)})))"
        )
        definitions.append(
            f"(= ({duplicate_name})\n"
            f"   (WMFCAPackedEvidenceState\n"
            f"     {metta_list(objects)} {metta_list(attributes)}\n"
            f"     (\n{chr(10).join(duplicate_rendered)})))"
        )
    candidate_symbols = [
        metta_list(attributes[index] for index in candidate)
        for candidate in candidates
    ]
    candidates_name = f"wm-fca-corruption-{case_slug}-queries"
    definitions.append(
        f"(= ({candidates_name})\n   (\n"
        + "\n".join(f"     {item}" for item in candidate_symbols)
        + "))"
    )

    assertions = []
    for roles, state_name in state_names.items():
        expected_count = sum(
            status != "." for role in roles for row in layers[role].rows for status in row
        )
        assertions.append(
            f"!(assertEqual (wm-fca-state-observation-count ({state_name})) {expected_count})"
        )
        assertions.append(
            f"!(assertEqual (wm-fca-state-observation-count ({duplicate_names[roles]})) {expected_count})"
        )
    for model in models:
        base_rows = projections[(model.id, model.roles)]
        no_copy_roles = tuple(role for role in model.roles if role != "correlated_copy")
        no_copy_rows = projections[(model.id, no_copy_roles)]
        gate = render_gate(model)
        expected_columns = render_columns(base_rows, objects, attributes)
        expected_batch = render_batch(base_rows, objects, attributes, candidates)
        no_copy_columns = render_columns(no_copy_rows, objects, attributes)
        state = state_names[model.roles]
        duplicate_state = duplicate_names[model.roles]
        no_copy_state = state_names[no_copy_roles]
        assertions.extend(
            [
                f"""!(assertEqual
   (wm-fca-index-columns
     (wm-fca-build-index ({state}) {context_id} {gate}))
   {expected_columns})""",
                f"""!(assertEqual
   (wm-fca-batch-queries
     ({state}) {context_id} {gate} ({candidates_name}))
   {expected_batch})""",
                f"""!(assertEqual
   (wm-fca-index-columns
     (wm-fca-build-index ({duplicate_state}) {context_id} {gate}))
   {expected_columns})""",
                f"""!(assertEqual
   (wm-fca-index-columns
     (wm-fca-build-index ({no_copy_state}) {context_id} {gate}))
   {no_copy_columns})""",
            ]
        )
    text = f"""; Generated corruption case.  Results are checked against the
; independent Python oracle; runtime statistics are recorded outside this file.
!(import! &self lib_wm_fca)

{chr(10).join(definitions)}

{chr(10).join(assertions)}
"""
    # CeTTa prints one successful unit result for the import in addition to one
    # result per assertion.  Keep the executable-output count distinct from the
    # scientific assertion count recorded in the receipt.
    expected = "[()]\n" * (1 + len(assertions))
    return text, expected, len(assertions)


def load_scale_context(
    context_id: str,
    scale_dir: Path,
    oracle_dir: Path,
) -> tuple[
    tuple[str, ...],
    tuple[str, ...],
    tuple[str, ...],
    tuple[tuple[int, ...], ...],
    str,
]:
    cxt_path = scale_dir / f"{context_id}.cxt"
    receipt_path = oracle_dir / f"{context_id}_exact_oracle.json"
    context = read_cxt(cxt_path)
    receipt = require_mapping(
        json.loads(receipt_path.read_text(encoding="utf-8")), "exact receipt"
    )
    if receipt.get("context_sha256") != sha256(cxt_path):
        raise ValueError(f"{context_id}: exact receipt does not pin the context")
    object_symbols = require_mapping(receipt.get("object_symbols"), "object_symbols")
    attribute_symbols = require_mapping(
        receipt.get("attribute_symbols"), "attribute_symbols"
    )
    objects = tuple(
        require_string(object_symbols[name], f"object_symbols[{name}]")
        for name in context.objects
    )
    attributes = tuple(
        require_string(attribute_symbols[name], f"attribute_symbols[{name}]")
        for name in context.attributes
    )
    rows = tuple(
        "".join("1" if attribute in row else "0" for attribute in context.attributes)
        for row in context.rows
    )
    # Ten-attribute contexts have exact receipts rather than query receipts.
    # Use the same frozen structural query protocol as the scale suite.
    candidates: list[tuple[int, ...]] = [()]
    candidates.extend((index,) for index in range(len(attributes)))
    candidates.extend(
        (index, index + 1) for index in range(0, len(attributes) - 1, 8)
    )
    for size in (2, 4, 8):
        if size <= len(attributes):
            candidates.append(tuple(range(size)))
    candidates.append(tuple(range(len(attributes))))
    unique_candidates = tuple(dict.fromkeys(candidates))
    return objects, attributes, rows, unique_candidates, sha256(cxt_path)


def run_case(
    *,
    context_id: str,
    context_sha256: str,
    objects: tuple[str, ...],
    attributes: tuple[str, ...],
    truth_rows: tuple[str, ...],
    candidates: tuple[tuple[int, ...], ...],
    seed: int,
    missing_rate: float,
    flip_rate: float,
    unknown_rate: float,
    correlated_group_label: str,
    independent_group_label: str,
    models: tuple[Model, ...],
    envelope_ids: tuple[str, ...],
    exact_limits: dict[str, object],
    protocol_sha256: str,
    driver_sha256: str,
    cetta_path: Path,
    cetta_sha256: str,
    cetta_version: str,
    scratch_dir: Path,
) -> dict[str, object]:
    case_parameters = {
        "context_id": context_id,
        "flip_rate": flip_rate,
        "missing_rate": missing_rate,
        "seed": seed,
        "unknown_rate": unknown_rate,
    }
    case_digest = canonical_sha(
        {
            "cetta_sha256": cetta_sha256,
            "context_sha256": context_sha256,
            "driver_sha256": driver_sha256,
            "parameters": case_parameters,
            "protocol_sha256": protocol_sha256,
        }
    )
    case_token = f"wmfca-{case_digest[:16]}"
    case_slug = case_digest[:16]
    layers = build_layers(
        truth_rows,
        case_token=case_token,
        context_id=context_id,
        seed=seed,
        missing_rate=missing_rate,
        flip_rate=flip_rate,
        unknown_rate=unknown_rate,
        correlated_group_label=correlated_group_label,
        independent_group_label=independent_group_label,
    )
    projections: dict[tuple[str, tuple[str, ...]], tuple[str, ...]] = {}
    for model in models:
        for roles in {
            model.roles,
            tuple(role for role in model.roles if role != "correlated_copy"),
        }:
            projections[(model.id, roles)] = project_rows(
                (layers[role] for role in roles),
                model,
                len(objects),
                len(attributes),
            )

    fixture, expected, assertion_count = render_case_fixture(
        case_slug=case_slug,
        context_id=context_id,
        objects=objects,
        attributes=attributes,
        layers=layers,
        models=models,
        candidates=candidates,
        projections=projections,
    )
    fixture_path = scratch_dir / f"case_{case_slug}.metta"
    expected_path = scratch_dir / f"case_{case_slug}.expected"
    fixture_path.write_text(fixture, encoding="utf-8")
    expected_path.write_text(expected, encoding="utf-8")
    completed = subprocess.run(
        [
            str(cetta_path),
            "--profile",
            "he-extended",
            "--lang",
            "he",
            str(fixture_path),
        ],
        check=False,
        capture_output=True,
        text=True,
    )
    if completed.returncode != 0 or completed.stdout != expected or completed.stderr:
        actual_path = scratch_dir / f"case_{case_slug}.actual"
        stderr_path = scratch_dir / f"case_{case_slug}.stderr"
        actual_path.write_text(completed.stdout, encoding="utf-8")
        stderr_path.write_text(completed.stderr, encoding="utf-8")
        raise RuntimeError(
            f"{case_digest}: CeTTa validation failed "
            f"(exit={completed.returncode}, stdout_match={completed.stdout == expected}, "
            f"stderr_bytes={len(completed.stderr.encode())}; "
            f"actual={actual_path}, stderr={stderr_path})"
        )

    truth_artifacts = exact_artifacts(
        f"{context_id}-truth", objects, attributes, truth_rows, exact_limits
    )
    model_results: dict[str, object] = {}
    for model in models:
        predicted = projections[(model.id, model.roles)]
        selected_layers = tuple(layers[role] for role in model.roles)
        duplicated = project_rows(
            (*selected_layers, selected_layers[0]),
            model,
            len(objects),
            len(attributes),
        )
        without_copy_roles = tuple(
            role for role in model.roles if role != "correlated_copy"
        )
        without_copy = projections[(model.id, without_copy_roles)]
        artifacts = exact_artifacts(
            f"{context_id}-{model.id}", objects, attributes, predicted, exact_limits
        )
        model_results[model.id] = {
            "canonical_basis": set_scores(
                artifacts["basis"], truth_artifacts["basis"]
            ),
            "cells": cell_scores(predicted, truth_rows),
            "closures": closure_scores(predicted, truth_rows, candidates),
            "concepts": set_scores(
                artifacts["concepts"], truth_artifacts["concepts"]
            ),
            "correlated_copy_invariant": predicted == without_copy,
            "exact_duplicate_invariant": predicted == duplicated,
            "lattice_covers": set_scores(
                artifacts["covers"], truth_artifacts["covers"]
            ),
            "predicted_incidence_sha256": hashlib.sha256(
                ("\n".join(predicted) + "\n").encode()
            ).hexdigest(),
            "without_correlated_copy_sha256": hashlib.sha256(
                ("\n".join(without_copy) + "\n").encode()
            ).hexdigest(),
        }
    envelope_rows = [
        projections[(model_id, next(model.roles for model in models if model.id == model_id))]
        for model_id in envelope_ids
    ]
    envelope = envelope_scores(envelope_rows, truth_rows, candidates)
    return {
        "schema": "wm-fca-corruption-case-v1",
        "case_identity_sha256": case_digest,
        "cetta_validation": {
            "assertion_count": assertion_count,
            "binary_sha256": cetta_sha256,
            "binary_version": cetta_version,
            "fixture_sha256": hashlib.sha256(fixture.encode()).hexdigest(),
            "passed": True,
            "stdout_sha256": hashlib.sha256(completed.stdout.encode()).hexdigest(),
        },
        "context_sha256": context_sha256,
        "envelope": envelope,
        "layers": {role: layer.record() for role, layer in layers.items()},
        "models": model_results,
        "parameters": case_parameters,
    }


def scalar_paths(case: dict[str, object], model_id: str) -> dict[str, float]:
    models = require_mapping(case.get("models"), "case.models")
    model = require_mapping(models.get(model_id), f"case.models[{model_id}]")
    cells = require_mapping(model.get("cells"), "cells")
    closures = require_mapping(model.get("closures"), "closures")
    concepts = require_mapping(model.get("concepts"), "concepts")
    basis = require_mapping(model.get("canonical_basis"), "canonical_basis")
    covers = require_mapping(model.get("lattice_covers"), "lattice_covers")
    return {
        "basis_f1": float(basis["f1"]),
        "cell_f1": float(cells["f1"]),
        "closure_exact_accuracy": float(closures["exact_accuracy"]),
        "closure_mean_jaccard": float(closures["mean_jaccard"]),
        "concept_f1": float(concepts["f1"]),
        "cover_f1": float(covers["f1"]),
    }


def aggregate_cases(cases: list[dict[str, object]], models: tuple[Model, ...]) -> dict[str, object]:
    model_aggregates: dict[str, object] = {}
    for model in models:
        scalars = [scalar_paths(case, model.id) for case in cases]
        model_aggregates[model.id] = {
            metric: {
                "mean": statistics.fmean(item[metric] for item in scalars),
                "population_stddev": statistics.pstdev(item[metric] for item in scalars),
            }
            for metric in scalars[0]
        }
        model_aggregates[model.id]["exact_duplicate_invariance_rate"] = statistics.fmean(
            float(
                require_mapping(
                    require_mapping(case.get("models"), "models").get(model.id),
                    model.id,
                )["exact_duplicate_invariant"]
            )
            for case in cases
        )
        model_aggregates[model.id]["correlated_copy_invariance_rate"] = statistics.fmean(
            float(
                require_mapping(
                    require_mapping(case.get("models"), "models").get(model.id),
                    model.id,
                )["correlated_copy_invariant"]
            )
            for case in cases
        )
    envelope_cells = [
        require_mapping(
            require_mapping(case.get("envelope"), "envelope").get("cell"),
            "envelope.cell",
        )
        for case in cases
    ]
    envelope_closures = [
        require_mapping(
            require_mapping(case.get("envelope"), "envelope").get("closure"),
            "envelope.closure",
        )
        for case in cases
    ]
    return {
        "case_count": len(cases),
        "envelope": {
            "cell": {
                key: statistics.fmean(float(value[key]) for value in envelope_cells)
                for key in envelope_cells[0]
            },
            "closure": {
                key: statistics.fmean(float(value[key]) for value in envelope_closures)
                for key in envelope_closures[0]
            },
        },
        "models": model_aggregates,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--protocol", type=Path, required=True)
    parser.add_argument("--scale-context-dir", type=Path, required=True)
    parser.add_argument("--oracle-dir", type=Path, required=True)
    parser.add_argument("--cetta", type=Path, required=True)
    parser.add_argument("--scratch-dir", type=Path, required=True)
    parser.add_argument("--receipt", type=Path, required=True)
    parser.add_argument("--max-cases", type=int)
    args = parser.parse_args()
    if args.max_cases is not None and args.max_cases <= 0:
        raise ValueError("--max-cases must be positive")
    protocol = require_mapping(
        json.loads(args.protocol.read_text(encoding="utf-8")), "protocol"
    )
    if protocol.get("schema") != "wm-fca-corruption-protocol-v1":
        raise ValueError("unsupported corruption protocol schema")
    models = parse_models(protocol)
    model_by_id = {model.id: model for model in models}
    envelope_ids = tuple(
        require_string(item, f"envelope_model_ids[{index}]")
        for index, item in enumerate(
            require_list(protocol.get("envelope_model_ids"), "envelope_model_ids")
        )
    )
    if not envelope_ids or any(model_id not in model_by_id for model_id in envelope_ids):
        raise ValueError("envelope_model_ids must select known models")
    evidence_design = require_mapping(
        protocol.get("evidence_design"), "evidence_design"
    )
    primary_design = require_mapping(
        evidence_design.get("primary"), "evidence_design.primary"
    )
    copy_design = require_mapping(
        evidence_design.get("correlated_copy"),
        "evidence_design.correlated_copy",
    )
    independent_design = require_mapping(
        evidence_design.get("independent"), "evidence_design.independent"
    )
    correlated_group_label = require_string(
        primary_design.get("dependence_group"),
        "evidence_design.primary.dependence_group",
    )
    if require_string(
        copy_design.get("dependence_group"),
        "evidence_design.correlated_copy.dependence_group",
    ) != correlated_group_label:
        raise ValueError("primary and correlated copy must share a dependence group")
    if copy_design.get("shares_status_matrix_with") != "primary":
        raise ValueError("correlated copy must explicitly share the primary matrix")
    independent_group_label = require_string(
        independent_design.get("dependence_group"),
        "evidence_design.independent.dependence_group",
    )
    known_roles = {"primary", "correlated_copy", "independent"}
    if any(set(model.roles) - known_roles for model in models):
        raise ValueError("models select an unknown evidence layer role")
    contexts = tuple(
        require_string(item, f"contexts[{index}]")
        for index, item in enumerate(require_list(protocol.get("contexts"), "contexts"))
    )
    seeds = tuple(
        require_int(item, f"seeds[{index}]")
        for index, item in enumerate(require_list(protocol.get("seeds"), "seeds"))
    )
    grid = require_mapping(protocol.get("corruption_grid"), "corruption_grid")
    missing_rates = tuple(
        require_rate(item, f"missing_rates[{index}]")
        for index, item in enumerate(
            require_list(grid.get("missing_rates"), "missing_rates")
        )
    )
    flip_rates = tuple(
        require_rate(item, f"flip_rates[{index}]")
        for index, item in enumerate(require_list(grid.get("flip_rates"), "flip_rates"))
    )
    unknown_rate = require_rate(grid.get("unknown_rate"), "unknown_rate")
    exact_limits = require_mapping(protocol.get("exact_limits"), "exact_limits")
    planned_case_count = len(contexts) * len(seeds) * len(missing_rates) * len(flip_rates)
    protocol_digest = sha256(args.protocol)
    driver_digest = sha256(Path(__file__))
    cetta_path = args.cetta.resolve()
    if not cetta_path.is_file():
        raise ValueError("--cetta must identify an existing binary")
    cetta_digest = sha256(cetta_path)
    version = subprocess.run(
        [str(cetta_path), "-v"], check=True, capture_output=True, text=True
    ).stdout.strip()
    args.scratch_dir.mkdir(parents=True, exist_ok=True)
    cases: list[dict[str, object]] = []
    for context_id in contexts:
        objects, attributes, truth_rows, candidates, context_digest = load_scale_context(
            context_id, args.scale_context_dir, args.oracle_dir
        )
        for seed in seeds:
            for missing_rate in missing_rates:
                for flip_rate in flip_rates:
                    if args.max_cases is not None and len(cases) >= args.max_cases:
                        break
                    case = run_case(
                        context_id=context_id,
                        context_sha256=context_digest,
                        objects=objects,
                        attributes=attributes,
                        truth_rows=truth_rows,
                        candidates=candidates,
                        seed=seed,
                        missing_rate=missing_rate,
                        flip_rate=flip_rate,
                        unknown_rate=unknown_rate,
                        correlated_group_label=correlated_group_label,
                        independent_group_label=independent_group_label,
                        models=models,
                        envelope_ids=envelope_ids,
                        exact_limits=exact_limits,
                        protocol_sha256=protocol_digest,
                        driver_sha256=driver_digest,
                        cetta_path=cetta_path,
                        cetta_sha256=cetta_digest,
                        cetta_version=version,
                        scratch_dir=args.scratch_dir,
                    )
                    cases.append(case)
                if args.max_cases is not None and len(cases) >= args.max_cases:
                    break
            if args.max_cases is not None and len(cases) >= args.max_cases:
                break
        if args.max_cases is not None and len(cases) >= args.max_cases:
            break
    if not cases:
        raise ValueError("no corruption cases were executed")
    receipt = {
        "schema": "wm-fca-corruption-run-v1",
        "aggregate": aggregate_cases(cases, models),
        "cases": cases,
        "cetta_binary_sha256": cetta_digest,
        "cetta_version": version,
        "driver_sha256": driver_digest,
        "executed_case_count": len(cases),
        "planned_case_count": planned_case_count,
        "protocol_complete": len(cases) == planned_case_count,
        "protocol_sha256": protocol_digest,
    }
    args.receipt.parent.mkdir(parents=True, exist_ok=True)
    args.receipt.write_text(
        json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print(
        json.dumps(
            {
                "executed_case_count": len(cases),
                "planned_case_count": planned_case_count,
                "protocol_complete": receipt["protocol_complete"],
                "receipt_sha256": sha256(args.receipt),
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
