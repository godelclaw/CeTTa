#!/usr/bin/env python3
"""Generate bounded CeTTa lifecycle gates from an independent event receipt."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Iterable


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


def metta_list(items: Iterable[str]) -> str:
    return f"({' '.join(items)})"


def indented_list(items: list[str], indent: str = "   ") -> str:
    if not items:
        return "()"
    return "(\n" + "\n".join(f"{indent}{item}" for item in items) + ")"


def render_stamp(raw_value: object) -> str:
    raw = require_mapping(raw_value, "stamp")
    kind = require_string(raw.get("kind"), "stamp.kind")
    values = [
        require_string(item, f"stamp.values[{index}]")
        for index, item in enumerate(require_list(raw.get("values"), "stamp.values"))
    ]
    if kind == "packed" and len(values) == 3:
        return f"(WMFCAPackedStamp {values[0]} {values[1]} {values[2]})"
    if kind == "symbol" and len(values) == 1:
        return values[0]
    raise ValueError(f"unsupported stamp encoding: {kind}/{len(values)}")


def render_observation(raw_value: object) -> str:
    raw = require_mapping(raw_value, "observation")
    return (
        "(WMFCAObservation "
        + " ".join(
            [
                require_string(raw.get("context"), "observation.context"),
                require_string(raw.get("object"), "observation.object"),
                require_string(raw.get("attribute"), "observation.attribute"),
                require_string(raw.get("status"), "observation.status"),
                render_stamp(raw.get("stamp")),
                require_string(raw.get("source"), "observation.source"),
                require_string(raw.get("group"), "observation.group"),
            ]
        )
        + ")"
    )


def render_scope(raw_value: object) -> str:
    raw = require_mapping(raw_value, "scope")
    kind = require_string(raw.get("kind"), "scope.kind")
    values = [
        require_string(item, f"scope.values[{index}]")
        for index, item in enumerate(require_list(raw.get("values"), "scope.values"))
    ]
    if kind == "stamp" and values:
        if values[0] == "packed" and len(values) == 4:
            stamp = f"(WMFCAPackedStamp {values[1]} {values[2]} {values[3]})"
        elif values[0] == "symbol" and len(values) == 2:
            stamp = values[1]
        else:
            raise ValueError("unsupported stamp scope encoding")
        return f"(WMFCAScopeStamp {stamp})"
    heads = {
        "source": "WMFCAScopeSource",
        "group": "WMFCAScopeDependenceGroup",
        "context": "WMFCAScopeContext",
        "cell": "WMFCAScopeCell",
    }
    expected = {"source": 1, "group": 1, "context": 1, "cell": 3}
    if kind not in heads or len(values) != expected[kind]:
        raise ValueError(f"unsupported scope encoding: {kind}/{len(values)}")
    return f"({heads[kind]} {' '.join(values)})"


def render_gate(raw_value: object) -> str:
    raw = require_mapping(raw_value, "gate")
    kind = require_string(raw.get("kind"), "gate.kind")
    if kind == "exact":
        return "WMFCAExactStatusGate"
    threshold = require_int(raw.get("threshold"), "gate.threshold")
    heads = {
        "positive-observations": "WMFCAPositiveObservationThreshold",
        "positive-sources": "WMFCAPositiveSourceThreshold",
        "positive-groups": "WMFCAPositiveDependenceGroupThreshold",
    }
    if kind not in heads:
        raise ValueError(f"unsupported gate kind: {kind}")
    return f"({heads[kind]} {threshold})"


def render_query_results(raw_value: object) -> str:
    results = []
    for index, raw_result in enumerate(require_list(raw_value, "query_results")):
        result = require_mapping(raw_result, f"query_results[{index}]")
        candidate = metta_list(
            require_string(item, "candidate item")
            for item in require_list(result.get("candidate"), "candidate")
        )
        extent = metta_list(
            require_string(item, "extent item")
            for item in require_list(result.get("extent"), "extent")
        )
        closure = metta_list(
            require_string(item, "closure item")
            for item in require_list(result.get("closure"), "closure")
        )
        results.append(
            f"(WMFCABatchQueryResult {candidate} {extent} {closure})"
        )
    return indented_list(results, "     ")


def render_event_context(receipt: dict[str, object]) -> str:
    context = require_string(receipt.get("context_id"), "context_id")
    objects = [
        require_string(item, f"objects[{index}]")
        for index, item in enumerate(require_list(receipt.get("objects"), "objects"))
    ]
    attributes = [
        require_string(item, f"attributes[{index}]")
        for index, item in enumerate(
            require_list(receipt.get("attributes"), "attributes")
        )
    ]
    definitions = [
        f"(= (wm-fca-{context}-event-state-00)\n   (wm-fca-{context}-state))"
    ]
    for index, raw_event_value in enumerate(
        require_list(receipt.get("events"), "events"), start=1
    ):
        raw_event = require_mapping(raw_event_value, f"events[{index - 1}]")
        operation = require_string(raw_event.get("operation"), "event.operation")
        previous = f"(wm-fca-{context}-event-state-{index - 1:02d})"
        if operation == "forget":
            expression = f"(wm-fca-forget {previous} {render_scope(raw_event.get('scope'))})"
        elif operation == "remember":
            observations = require_list(raw_event.get("observations"), "event.observations")
            if len(observations) != 1:
                raise ValueError("remember event must carry exactly one observation")
            expression = f"(wm-fca-remember {previous} {render_observation(observations[0])})"
        elif operation == "revise":
            observations = [
                render_observation(item)
                for item in require_list(raw_event.get("observations"), "event.observations")
            ]
            right_state = (
                f"(WMFCAState {metta_list(objects)} {metta_list(attributes)} "
                f"{indented_list(observations, '       ')})"
            )
            expression = f"(wm-fca-revise {previous} {right_state})"
        else:
            raise ValueError(f"unsupported event operation: {operation}")
        definitions.append(
            f"(= (wm-fca-{context}-event-state-{index:02d})\n   {expression})"
        )
    candidates = [
        metta_list(
            require_string(item, "query candidate item")
            for item in require_list(raw, "query candidate")
        )
        for raw in require_list(receipt.get("query_candidates"), "query_candidates")
    ]
    return f"""; Generated from an independent, receipt-backed WM event oracle.
; Context SHA-256: {require_string(receipt.get('context_sha256'), 'context_sha256')}
; Protocol SHA-256: {require_string(receipt.get('protocol_sha256'), 'protocol_sha256')}
;
; Each state is immutable.  The runtime stores events newest-first and replays
; them oldest-first; no interpreted matrix recursion or lattice enumeration is
; used by this lifecycle fixture.

!(import! &self ./{context}_context.metta)

{chr(10).join(definitions)}

(= (wm-fca-{context}-event-query-candidates)
   {indented_list(candidates)})
"""


def render_prefix_test(receipt: dict[str, object], prefix: dict[str, object]) -> str:
    context = require_string(receipt.get("context_id"), "context_id")
    foreign_context = require_string(receipt.get("foreign_context"), "foreign_context")
    prefix_number = require_int(prefix.get("prefix"), "prefix")
    true_cell = [
        require_string(item, "true_anchor item")
        for item in require_list(receipt.get("true_anchor"), "true_anchor")
    ]
    false_cell = [
        require_string(item, "false_anchor item")
        for item in require_list(receipt.get("false_anchor"), "false_anchor")
    ]
    if len(true_cell) != 2 or len(false_cell) != 2:
        raise ValueError("anchor cells must have object and attribute")
    state = f"(wm-fca-{context}-event-state-{prefix_number:02d})"
    statuses = require_mapping(prefix.get("status_examples"), "status_examples")
    evidence = require_mapping(prefix.get("evidence_examples"), "evidence_examples")
    assertions = [
        f"""!(assertEqual
   (wm-fca-state-observation-count {state})
   {require_int(prefix.get('active_observation_count'), 'active_observation_count')})"""
    ]
    if prefix_number > 0:
        assertions.append(
            f"""!(assertEqual
   (let $events (eval (wm-fca-state-events {state}))
     (size-atom $events))
   {require_int(prefix.get('event_count'), 'event_count')})"""
        )
    status_specs = [
        ("true_anchor", context, true_cell),
        ("false_anchor", context, false_cell),
        ("foreign_true_anchor", foreign_context, true_cell),
    ]
    for name, query_context, cell in status_specs:
        expected_status = require_string(statuses.get(name), f"status_examples[{name}]")
        assertions.append(
            f"""!(assertEqual
   (wm-fca-cell-status {state} {query_context} {cell[0]} {cell[1]})
   {expected_status})"""
        )
        expected_evidence = [
            render_observation(item)
            for item in require_list(evidence.get(name), f"evidence_examples[{name}]")
        ]
        assertions.append(
            f"""!(assertEqual
   (wm-fca-explain-cell {state} {query_context} {cell[0]} {cell[1]})
   {indented_list(expected_evidence, '   ')})"""
        )
    for projection_index, raw_projection in enumerate(
        require_list(prefix.get("projections"), "projections")
    ):
        projection = require_mapping(raw_projection, f"projections[{projection_index}]")
        gate = render_gate(projection.get("gate"))
        expected = render_query_results(projection.get("query_results"))
        assertions.append(
            f"""!(assertEqual
   (wm-fca-batch-queries
     {state}
     {context}
     {gate}
     (wm-fca-{context}-event-query-candidates))
   {expected})"""
        )
    return f"""!(import! &self ./{context}_event_context.metta)

; Prefix {prefix_number}: incremental native state is checked against values
; freshly recomputed by the independent Python oracle from surviving evidence.

{chr(10).join(assertions)}
"""


def validate_receipt(receipt: dict[str, object]) -> None:
    if receipt.get("schema") != "wm-fca-event-oracle-v1":
        raise ValueError("unsupported event receipt schema")
    agreement = require_mapping(receipt.get("oracle_agreement"), "oracle_agreement")
    if not agreement or not all(value is True for value in agreement.values()):
        raise ValueError("event receipt oracle agreement is not complete")
    events = require_list(receipt.get("events"), "events")
    prefixes = require_list(receipt.get("prefixes"), "prefixes")
    if len(prefixes) != len(events) + 1:
        raise ValueError("event receipt must contain one result per event prefix")
    for index, raw_prefix in enumerate(prefixes):
        prefix = require_mapping(raw_prefix, f"prefixes[{index}]")
        if prefix.get("prefix") != index or prefix.get(
            "incremental_equals_fresh_recomputation"
        ) is not True:
            raise ValueError(f"prefix {index}: invalid fresh-recomputation record")
        if prefix.get("active_observation_sha256") != prefix.get(
            "fresh_recomputation_sha256"
        ):
            raise ValueError(f"prefix {index}: observation digests differ")
        for projection in require_list(prefix.get("projections"), "projections"):
            if require_mapping(projection, "projection").get(
                "direct_equals_concepts_0_9_2"
            ) is not True:
                raise ValueError(f"prefix {index}: external FCA oracle differs")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--receipt", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()
    receipt = require_mapping(
        json.loads(args.receipt.read_text(encoding="utf-8")), "receipt"
    )
    validate_receipt(receipt)
    context = require_string(receipt.get("context_id"), "context_id")
    args.output_dir.mkdir(parents=True, exist_ok=True)
    event_context_path = args.output_dir / f"{context}_event_context.metta"
    event_context_path.write_text(render_event_context(receipt), encoding="utf-8")
    generated_tests = []
    for raw_prefix in require_list(receipt.get("prefixes"), "prefixes"):
        prefix = require_mapping(raw_prefix, "prefix")
        prefix_number = require_int(prefix.get("prefix"), "prefix")
        test_path = args.output_dir / f"test_{context}_event_prefix_{prefix_number:02d}.metta"
        expected_path = test_path.with_suffix(".expected")
        test_text = render_prefix_test(receipt, prefix)
        success_count = sum(
            line.lstrip().startswith("!(") for line in test_text.splitlines()
        )
        test_path.write_text(test_text, encoding="utf-8")
        expected_path.write_text("[()]\n" * success_count, encoding="utf-8")
        generated_tests.append(str(test_path))
    print(
        json.dumps(
            {
                "context": context,
                "event_context": str(event_context_path),
                "tests": len(generated_tests),
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
