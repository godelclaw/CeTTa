#!/usr/bin/env python3
"""Independent receipt oracle for packed WM/FCA revision and forgetting."""

from __future__ import annotations

import argparse
import hashlib
import importlib.metadata
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

import concepts


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


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


@dataclass(frozen=True)
class Stamp:
    kind: str
    values: tuple[str, ...]

    def record(self) -> dict[str, object]:
        return {"kind": self.kind, "values": list(self.values)}


@dataclass(frozen=True)
class Observation:
    context: str
    object: str
    attribute: str
    status: str
    stamp: Stamp
    source: str
    group: str

    def record(self) -> dict[str, object]:
        return {
            "attribute": self.attribute,
            "context": self.context,
            "group": self.group,
            "object": self.object,
            "source": self.source,
            "stamp": self.stamp.record(),
            "status": self.status,
        }


@dataclass(frozen=True)
class Scope:
    kind: str
    values: tuple[str, ...]

    def record(self) -> dict[str, object]:
        return {"kind": self.kind, "values": list(self.values)}


@dataclass(frozen=True)
class Event:
    id: str
    operation: str
    observations: tuple[Observation, ...] = ()
    scope: Scope | None = None

    def record(self) -> dict[str, object]:
        result: dict[str, object] = {
            "id": self.id,
            "operation": self.operation,
        }
        if self.observations:
            result["observations"] = [item.record() for item in self.observations]
        if self.scope is not None:
            result["scope"] = self.scope.record()
        return result


@dataclass
class Snapshot:
    base_active: set[tuple[str, str]]
    additions: list[Observation]

    def clone(self) -> Snapshot:
        return Snapshot(set(self.base_active), list(self.additions))


def packed_stamp(context: str, cell: tuple[str, str]) -> Stamp:
    return Stamp("packed", (context, cell[0], cell[1]))


def scope_matches(observation: Observation, scope: Scope) -> bool:
    if scope.kind == "stamp":
        return observation.stamp == Stamp(scope.values[0], scope.values[1:])
    if scope.kind == "source":
        return observation.source == scope.values[0]
    if scope.kind == "group":
        return observation.group == scope.values[0]
    if scope.kind == "context":
        return observation.context == scope.values[0]
    if scope.kind == "cell":
        return (
            observation.context,
            observation.object,
            observation.attribute,
        ) == scope.values
    raise ValueError(f"unsupported scope kind: {scope.kind}")


def remember(
    snapshot: Snapshot,
    observation: Observation,
    base: dict[tuple[str, str], Observation],
) -> None:
    cell = (observation.object, observation.attribute)
    if cell in snapshot.base_active and base.get(cell) == observation:
        return
    if observation not in snapshot.additions:
        snapshot.additions.append(observation)


def apply_event(
    snapshot: Snapshot,
    event: Event,
    base: dict[tuple[str, str], Observation],
) -> None:
    if event.operation == "forget":
        if event.scope is None:
            raise ValueError(f"{event.id}: forget event lacks a scope")
        snapshot.base_active = {
            cell
            for cell in snapshot.base_active
            if not scope_matches(base[cell], event.scope)
        }
        snapshot.additions = [
            observation
            for observation in snapshot.additions
            if not scope_matches(observation, event.scope)
        ]
        return
    if event.operation not in {"remember", "revise"}:
        raise ValueError(f"{event.id}: unsupported operation {event.operation}")
    for observation in event.observations:
        remember(snapshot, observation, base)


def active_observations(
    snapshot: Snapshot,
    base: dict[tuple[str, str], Observation],
    objects: tuple[str, ...],
    attributes: tuple[str, ...],
) -> list[Observation]:
    result = [
        base[(obj, attribute)]
        for attribute in attributes
        for obj in objects
        if (obj, attribute) in snapshot.base_active
    ]
    result.extend(snapshot.additions)
    return result


def canonical_observation_digest(observations: Iterable[Observation]) -> str:
    records = sorted(
        (
            json.dumps(item.record(), sort_keys=True, separators=(",", ":"))
            for item in observations
        )
    )
    payload = ("\n".join(records) + ("\n" if records else "")).encode()
    return hashlib.sha256(payload).hexdigest()


def evidence_for_cell(
    observations: Iterable[Observation],
    context: str,
    cell: tuple[str, str],
) -> list[Observation]:
    return [
        item
        for item in observations
        if item.context == context
        and item.object == cell[0]
        and item.attribute == cell[1]
    ]


def evidence_status(evidence: Iterable[Observation]) -> str:
    statuses = {item.status for item in evidence}
    if not statuses:
        return "WMMissing"
    if statuses == {"WMTrue"}:
        return "WMTrue"
    if statuses == {"WMFalse"}:
        return "WMFalse"
    return "WMUnknown"


def gate_accepts(evidence: list[Observation], gate: dict[str, object]) -> bool:
    kind = require_string(gate.get("kind"), "gate.kind")
    positive = [item for item in evidence if item.status == "WMTrue"]
    if kind == "exact":
        return bool(positive) and len(positive) == len(evidence)
    threshold = require_int(gate.get("threshold"), "gate.threshold")
    if threshold < 0:
        raise ValueError("gate thresholds must be nonnegative")
    if kind == "positive-observations":
        count = len(positive)
    elif kind == "positive-sources":
        count = len({item.source for item in positive})
    elif kind == "positive-groups":
        count = len({item.group for item in positive})
    else:
        raise ValueError(f"unsupported extraction gate: {kind}")
    return count >= threshold


def ordered(values: Iterable[str], order: dict[str, int]) -> list[str]:
    return sorted(values, key=order.__getitem__)


def query_projection(
    observations: list[Observation],
    context: str,
    objects: tuple[str, ...],
    attributes: tuple[str, ...],
    candidates: tuple[tuple[str, ...], ...],
    gate: dict[str, object],
) -> tuple[list[dict[str, object]], bool]:
    object_order = {value: index for index, value in enumerate(objects)}
    attribute_order = {value: index for index, value in enumerate(attributes)}
    evidence_index: dict[tuple[str, str, str], list[Observation]] = {}
    for observation in observations:
        evidence_index.setdefault(
            (observation.context, observation.object, observation.attribute), []
        ).append(observation)
    incidence = {
        obj: frozenset(
            attribute
            for attribute in attributes
            if gate_accepts(
                evidence_index.get((context, obj, attribute), []), gate
            )
        )
        for obj in objects
    }

    def extent(candidate: frozenset[str]) -> frozenset[str]:
        return frozenset(obj for obj in objects if candidate <= incidence[obj])

    def intent(object_set: frozenset[str]) -> frozenset[str]:
        if not object_set:
            return frozenset(attributes)
        iterator = iter(object_set)
        result = set(incidence[next(iterator)])
        for obj in iterator:
            result.intersection_update(incidence[obj])
        return frozenset(result)

    external = concepts.Context(
        objects,
        attributes,
        tuple(
            tuple(attribute in incidence[obj] for attribute in attributes)
            for obj in objects
        ),
    )
    results: list[dict[str, object]] = []
    agrees = True
    for candidate_items in candidates:
        candidate = frozenset(candidate_items)
        direct_extent = extent(candidate)
        direct_closure = intent(direct_extent)
        external_extent = frozenset(external.extension(list(candidate_items)))
        external_closure = frozenset(
            external.intension(ordered(external_extent, object_order))
        )
        agrees = agrees and (
            direct_extent == external_extent
            and direct_closure == external_closure
        )
        results.append(
            {
                "candidate": list(candidate_items),
                "closure": ordered(direct_closure, attribute_order),
                "extent": ordered(direct_extent, object_order),
            }
        )
    return results, agrees


def selected_queries(
    attributes: tuple[str, ...],
    true_cell: tuple[str, str],
    false_cell: tuple[str, str],
    selections: list[object],
) -> tuple[tuple[str, ...], ...]:
    named = {
        "empty": (),
        "true-anchor": (true_cell[1],),
        "false-anchor": (false_cell[1],),
        "anchor-pair": (true_cell[1], false_cell[1]),
        "first-two": attributes[:2],
        "first-four": attributes[:4],
        "last-attribute": attributes[-1:],
    }
    order = {value: index for index, value in enumerate(attributes)}
    result: list[tuple[str, ...]] = []
    seen: set[tuple[str, ...]] = set()
    for index, raw_name in enumerate(selections):
        name = require_string(raw_name, f"query_selection[{index}]")
        if name not in named:
            raise ValueError(f"unsupported query selection: {name}")
        candidate = tuple(ordered(set(named[name]), order))
        if candidate not in seen:
            seen.add(candidate)
            result.append(candidate)
    if not result:
        raise ValueError("event protocol selected no queries")
    return tuple(result)


def resolve_observation(
    raw: dict[str, object],
    true_cell: tuple[str, str],
    false_cell: tuple[str, str],
    context: str,
    foreign_context: str,
    base_source: str,
    base_group: str,
    base: dict[tuple[str, str], Observation],
) -> Observation:
    cells = {"true-anchor": true_cell, "false-anchor": false_cell}
    cell_name = require_string(raw.get("cell"), "observation.cell")
    if cell_name not in cells:
        raise ValueError(f"unsupported observation cell: {cell_name}")
    cell = cells[cell_name]
    context_name = require_string(raw.get("context"), "observation.context")
    contexts = {"base": context, "foreign": foreign_context}
    if context_name not in contexts:
        raise ValueError(f"unsupported observation context: {context_name}")
    status_name = require_string(raw.get("status"), "observation.status")
    statuses = {"true": "WMTrue", "false": "WMFalse", "unknown": "WMUnknown"}
    if status_name == "base":
        status = base[cell].status
    elif status_name in statuses:
        status = statuses[status_name]
    else:
        raise ValueError(f"unsupported observation status: {status_name}")
    source_name = require_string(raw.get("source"), "observation.source")
    group_name = require_string(raw.get("group"), "observation.group")
    source = base_source if source_name == "base" else source_name
    group = base_group if group_name == "base" else group_name
    raw_stamp = require_mapping(raw.get("stamp"), "observation.stamp")
    stamp_kind = require_string(raw_stamp.get("kind"), "observation.stamp.kind")
    if stamp_kind == "packed":
        stamp_cell_name = require_string(
            raw_stamp.get("cell"), "observation.stamp.cell"
        )
        if stamp_cell_name not in cells:
            raise ValueError(f"unsupported packed stamp cell: {stamp_cell_name}")
        stamp = packed_stamp(context, cells[stamp_cell_name])
    elif stamp_kind == "symbol":
        stamp = Stamp(
            "symbol",
            (require_string(raw_stamp.get("value"), "observation.stamp.value"),),
        )
    else:
        raise ValueError(f"unsupported observation stamp: {stamp_kind}")
    return Observation(
        contexts[context_name], cell[0], cell[1], status, stamp, source, group
    )


def resolve_scope(
    raw: dict[str, object],
    true_cell: tuple[str, str],
    false_cell: tuple[str, str],
    context: str,
    foreign_context: str,
    base_source: str,
) -> Scope:
    kind = require_string(raw.get("kind"), "scope.kind")
    cells = {"true-anchor": true_cell, "false-anchor": false_cell}
    if kind == "packed-stamp":
        cell_name = require_string(raw.get("cell"), "scope.cell")
        if cell_name not in cells:
            raise ValueError(f"unsupported scope cell: {cell_name}")
        stamp = packed_stamp(context, cells[cell_name])
        return Scope("stamp", (stamp.kind, *stamp.values))
    if kind == "stamp":
        return Scope(
            "stamp",
            ("symbol", require_string(raw.get("value"), "scope.value")),
        )
    if kind == "group":
        return Scope("group", (require_string(raw.get("value"), "scope.value"),))
    if kind == "base-source":
        return Scope("source", (base_source,))
    if kind == "foreign-context":
        return Scope("context", (foreign_context,))
    if kind == "cell":
        cell_name = require_string(raw.get("cell"), "scope.cell")
        if cell_name not in cells:
            raise ValueError(f"unsupported scope cell: {cell_name}")
        cell = cells[cell_name]
        return Scope("cell", (context, cell[0], cell[1]))
    raise ValueError(f"unsupported scope kind: {kind}")


def compute_receipt(
    protocol_path: Path,
    protocol: dict[str, object],
    scale_receipt_path: Path,
    scale_receipt: dict[str, object],
) -> dict[str, object]:
    if protocol.get("schema") != "wm-fca-event-protocol-v1":
        raise ValueError("unsupported event protocol schema")
    if scale_receipt.get("schema") != "wm-fca-scale-query-oracle-v1":
        raise ValueError("unsupported scale query receipt schema")
    context = require_string(scale_receipt.get("context_id"), "context_id")
    allowed_contexts = [
        require_string(item, f"contexts[{index}]")
        for index, item in enumerate(require_list(protocol.get("contexts"), "contexts"))
    ]
    if context not in allowed_contexts:
        raise ValueError(f"{context}: not selected by event protocol")

    objects = tuple(
        require_string(item, f"objects[{index}]")
        for index, item in enumerate(require_list(scale_receipt.get("objects"), "objects"))
    )
    attributes = tuple(
        require_string(item, f"attributes[{index}]")
        for index, item in enumerate(
            require_list(scale_receipt.get("attributes"), "attributes")
        )
    )
    object_symbols = require_mapping(scale_receipt.get("object_symbols"), "object_symbols")
    attribute_symbols = require_mapping(
        scale_receipt.get("attribute_symbols"), "attribute_symbols"
    )
    object_values = tuple(
        require_string(object_symbols[name], f"object_symbols[{name}]")
        for name in objects
    )
    attribute_values = tuple(
        require_string(attribute_symbols[name], f"attribute_symbols[{name}]")
        for name in attributes
    )
    incidence = require_mapping(scale_receipt.get("true_incidence"), "true_incidence")
    true_by_object = {
        require_string(obj, "true_incidence key"): {
            require_string(attribute, f"true_incidence[{obj}]")
            for attribute in require_list(raw_attributes, f"true_incidence[{obj}]")
        }
        for obj, raw_attributes in incidence.items()
    }
    examples = require_mapping(scale_receipt.get("examples"), "examples")
    raw_true_cell = require_list(examples.get("true_cell"), "examples.true_cell")
    raw_false_cell = require_list(examples.get("false_cell"), "examples.false_cell")
    if len(raw_true_cell) != 2 or len(raw_false_cell) != 2:
        raise ValueError("cell examples must contain object and attribute symbols")
    true_cell = (
        require_string(raw_true_cell[0], "examples.true_cell[0]"),
        require_string(raw_true_cell[1], "examples.true_cell[1]"),
    )
    false_cell = (
        require_string(raw_false_cell[0], "examples.false_cell[0]"),
        require_string(raw_false_cell[1], "examples.false_cell[1]"),
    )
    upstream = require_mapping(scale_receipt.get("upstream"), "upstream")
    base_source = (
        require_string(upstream.get("source_id"), "upstream.source_id")
        + "-"
        + require_string(upstream.get("commit"), "upstream.commit")[:8]
    )
    base_group = require_string(scale_receipt.get("dependence_group"), "dependence_group")
    foreign_context = f"{context}-foreign-context"

    base: dict[tuple[str, str], Observation] = {}
    for obj in object_values:
        for attribute in attribute_values:
            cell = (obj, attribute)
            status = "WMTrue" if attribute in true_by_object[obj] else "WMFalse"
            base[cell] = Observation(
                context,
                obj,
                attribute,
                status,
                packed_stamp(context, cell),
                base_source,
                base_group,
            )
    if base[true_cell].status != "WMTrue" or base[false_cell].status != "WMFalse":
        raise ValueError("scale receipt cell examples disagree with the matrix")

    raw_templates = require_mapping(
        protocol.get("observation_templates"), "observation_templates"
    )
    templates = {
        name: resolve_observation(
            require_mapping(raw, f"observation_templates[{name}]"),
            true_cell,
            false_cell,
            context,
            foreign_context,
            base_source,
            base_group,
            base,
        )
        for name, raw in raw_templates.items()
    }
    events: list[Event] = []
    for index, raw_event_value in enumerate(require_list(protocol.get("events"), "events")):
        raw_event = require_mapping(raw_event_value, f"events[{index}]")
        event_id = require_string(raw_event.get("id"), f"events[{index}].id")
        operation = require_string(
            raw_event.get("operation"), f"events[{index}].operation"
        )
        if operation == "forget":
            scope = resolve_scope(
                require_mapping(raw_event.get("scope"), f"events[{index}].scope"),
                true_cell,
                false_cell,
                context,
                foreign_context,
                base_source,
            )
            events.append(Event(event_id, operation, scope=scope))
        elif operation == "remember":
            name = require_string(
                raw_event.get("observation"), f"events[{index}].observation"
            )
            if name not in templates:
                raise ValueError(f"{event_id}: unknown observation template {name}")
            events.append(Event(event_id, operation, (templates[name],)))
        elif operation == "revise":
            names = [
                require_string(item, f"events[{index}].observations[{item_index}]")
                for item_index, item in enumerate(
                    require_list(raw_event.get("observations"), f"events[{index}].observations")
                )
            ]
            if any(name not in templates for name in names):
                raise ValueError(f"{event_id}: unknown observation template")
            events.append(Event(event_id, operation, tuple(templates[name] for name in names)))
        else:
            raise ValueError(f"{event_id}: unsupported operation {operation}")

    candidates = selected_queries(
        attribute_values,
        true_cell,
        false_cell,
        require_list(protocol.get("query_selection"), "query_selection"),
    )
    gates = [
        require_mapping(item, f"extraction_gates[{index}]")
        for index, item in enumerate(
            require_list(protocol.get("extraction_gates"), "extraction_gates")
        )
    ]
    if len({require_string(gate.get("id"), "gate.id") for gate in gates}) != len(gates):
        raise ValueError("extraction gate ids must be unique")

    incremental = Snapshot(set(base), [])
    prefixes: list[dict[str, object]] = []
    for prefix in range(len(events) + 1):
        if prefix:
            apply_event(incremental, events[prefix - 1], base)
        fresh = Snapshot(set(base), [])
        for event in events[:prefix]:
            apply_event(fresh, event, base)
        incremental_observations = active_observations(
            incremental, base, object_values, attribute_values
        )
        fresh_observations = active_observations(
            fresh, base, object_values, attribute_values
        )
        incremental_digest = canonical_observation_digest(incremental_observations)
        fresh_digest = canonical_observation_digest(fresh_observations)
        if incremental_digest != fresh_digest:
            raise ValueError(f"prefix {prefix}: incremental and fresh replay differ")

        examples_to_check = {
            "true_anchor": (context, true_cell),
            "false_anchor": (context, false_cell),
            "foreign_true_anchor": (foreign_context, true_cell),
        }
        status_examples: dict[str, str] = {}
        evidence_examples: dict[str, list[dict[str, object]]] = {}
        for name, (query_context, cell) in examples_to_check.items():
            cell_evidence = evidence_for_cell(
                incremental_observations, query_context, cell
            )
            status_examples[name] = evidence_status(cell_evidence)
            evidence_examples[name] = [item.record() for item in cell_evidence]

        projections: list[dict[str, object]] = []
        all_agree = True
        for gate in gates:
            results, agrees = query_projection(
                incremental_observations,
                context,
                object_values,
                attribute_values,
                candidates,
                gate,
            )
            all_agree = all_agree and agrees
            projections.append(
                {
                    "gate": gate,
                    "query_results": results,
                    "direct_equals_concepts_0_9_2": agrees,
                }
            )
        if not all_agree:
            raise ValueError(f"prefix {prefix}: direct and concepts oracles differ")
        prefixes.append(
            {
                "active_addition_count": len(incremental.additions),
                "active_base_count": len(incremental.base_active),
                "active_observation_count": len(incremental_observations),
                "active_observation_sha256": incremental_digest,
                "event_count": prefix,
                "evidence_examples": evidence_examples,
                "fresh_recomputation_sha256": fresh_digest,
                "incremental_equals_fresh_recomputation": True,
                "last_event_id": None if prefix == 0 else events[prefix - 1].id,
                "prefix": prefix,
                "projections": projections,
                "status_examples": status_examples,
            }
        )

    return {
        "schema": "wm-fca-event-oracle-v1",
        "context_id": context,
        "context_sha256": require_string(scale_receipt.get("context_sha256"), "context_sha256"),
        "scale_receipt_sha256": sha256(scale_receipt_path),
        "protocol_sha256": sha256(protocol_path),
        "dependency_versions": {
            "concepts": importlib.metadata.version("concepts"),
            "bitsets": importlib.metadata.version("bitsets"),
        },
        "base_source": base_source,
        "base_group": base_group,
        "base_context": context,
        "foreign_context": foreign_context,
        "object_count": len(object_values),
        "attribute_count": len(attribute_values),
        "objects": list(object_values),
        "attributes": list(attribute_values),
        "true_anchor": list(true_cell),
        "false_anchor": list(false_cell),
        "query_candidates": [list(candidate) for candidate in candidates],
        "events": [event.record() for event in events],
        "prefixes": prefixes,
        "oracle_agreement": {
            "all_incremental_states_equal_fresh_recomputation": True,
            "all_direct_queries_equal_concepts_0_9_2": True,
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--protocol", type=Path, required=True)
    parser.add_argument("--scale-receipt", type=Path, required=True)
    parser.add_argument("--receipt", type=Path, required=True)
    args = parser.parse_args()
    protocol = require_mapping(
        json.loads(args.protocol.read_text(encoding="utf-8")), "protocol"
    )
    scale_receipt = require_mapping(
        json.loads(args.scale_receipt.read_text(encoding="utf-8")),
        "scale receipt",
    )
    receipt = compute_receipt(
        args.protocol, protocol, args.scale_receipt, scale_receipt
    )
    args.receipt.parent.mkdir(parents=True, exist_ok=True)
    args.receipt.write_text(
        json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print(
        json.dumps(
            {
                "context_id": receipt["context_id"],
                "events": len(receipt["events"]),
                "prefixes": len(receipt["prefixes"]),
                "oracle_agreement": receipt["oracle_agreement"],
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
