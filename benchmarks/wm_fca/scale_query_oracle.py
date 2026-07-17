#!/usr/bin/env python3
"""Receipt-producing, non-enumerating FCA oracle for scale contexts."""

from __future__ import annotations

import argparse
import hashlib
import importlib.metadata
import json
from pathlib import Path
from typing import Iterable

import concepts

from cxt_oracle import read_cxt, symbol_slug


def require_mapping(value: object, label: str) -> dict[str, object]:
    if not isinstance(value, dict):
        raise ValueError(f"{label} must be an object")
    return value


def require_list(value: object, label: str) -> list[object]:
    if not isinstance(value, list):
        raise ValueError(f"{label} must be a list")
    return value


def require_int(value: object, label: str) -> int:
    if not isinstance(value, int) or isinstance(value, bool):
        raise ValueError(f"{label} must be an integer")
    return value


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def ordered(values: Iterable[str], order: dict[str, int]) -> list[str]:
    return sorted(values, key=order.__getitem__)


def query_candidates(
    attributes: tuple[str, ...], protocol: dict[str, object]
) -> tuple[frozenset[str], ...]:
    candidates: list[frozenset[str]] = []
    seen: set[frozenset[str]] = set()

    def add(values: Iterable[str]) -> None:
        candidate = frozenset(values)
        if candidate not in seen:
            seen.add(candidate)
            candidates.append(candidate)

    if protocol.get("include_empty") is True:
        add(())
    if protocol.get("include_all_singletons") is True:
        for attribute in attributes:
            add((attribute,))

    stride = require_int(
        protocol.get("adjacent_pair_stride"),
        "query_protocol.adjacent_pair_stride",
    )
    if stride <= 0:
        raise ValueError("adjacent_pair_stride must be positive")
    for start in range(0, max(0, len(attributes) - 1), stride):
        add(attributes[start : start + 2])

    for raw_size in require_list(
        protocol.get("prefix_sizes"), "query_protocol.prefix_sizes"
    ):
        size = require_int(raw_size, "query_protocol.prefix_sizes[]")
        if size <= 0:
            raise ValueError("query prefix sizes must be positive")
        if size <= len(attributes):
            add(attributes[:size])
    if protocol.get("include_full") is True:
        add(attributes)
    if not candidates:
        raise ValueError("query protocol produced no candidates")
    return tuple(candidates)


def compute_receipt(
    context_id: str,
    manifest_path: Path,
    manifest: dict[str, object],
    entry: dict[str, object],
) -> dict[str, object]:
    cxt_path = manifest_path.parent / str(entry["path"])
    digest = sha256(cxt_path)
    if digest != entry.get("sha256"):
        raise ValueError(f"{context_id}: context SHA-256 mismatch")
    context = read_cxt(cxt_path)
    if len(context.objects) != entry.get("object_count"):
        raise ValueError(f"{context_id}: object count differs from manifest")
    if len(context.attributes) != entry.get("attribute_count"):
        raise ValueError(f"{context_id}: attribute count differs from manifest")
    true_cell_count = sum(len(row) for row in context.rows)
    if true_cell_count != entry.get("true_cell_count"):
        raise ValueError(f"{context_id}: incidence count differs from manifest")

    objects = context.objects
    attributes = context.attributes
    object_order = {value: index for index, value in enumerate(objects)}
    attribute_order = {value: index for index, value in enumerate(attributes)}
    incidence = dict(zip(objects, context.rows, strict=True))

    def direct_extent(candidate: frozenset[str]) -> frozenset[str]:
        return frozenset(obj for obj in objects if candidate <= incidence[obj])

    def direct_intent(extent: frozenset[str]) -> frozenset[str]:
        if not extent:
            return frozenset(attributes)
        iterator = iter(extent)
        result = set(incidence[next(iterator)])
        for obj in iterator:
            result.intersection_update(incidence[obj])
        return frozenset(result)

    external = concepts.Context(
        objects,
        attributes,
        tuple(
            tuple(attribute in row for attribute in attributes)
            for row in context.rows
        ),
    )
    candidates = query_candidates(
        attributes,
        require_mapping(manifest.get("query_protocol"), "query_protocol"),
    )
    raw_queries: list[
        tuple[frozenset[str], frozenset[str], frozenset[str]]
    ] = []
    for candidate in candidates:
        extent = direct_extent(candidate)
        closure = direct_intent(extent)
        external_extent = frozenset(external.extension(ordered(candidate, attribute_order)))
        external_closure = frozenset(
            external.intension(ordered(external_extent, object_order))
        )
        if extent != external_extent or closure != external_closure:
            raise ValueError(
                f"{context_id}: direct and concepts 0.9.2 query oracles differ"
            )
        raw_queries.append((candidate, extent, closure))

    true_cell = next(
        (obj, attribute)
        for obj, row in zip(objects, context.rows, strict=True)
        for attribute in attributes
        if attribute in row
    )
    false_cell = next(
        (obj, attribute)
        for obj, row in zip(objects, context.rows, strict=True)
        for attribute in attributes
        if attribute not in row
    )
    object_symbols = {
        value: symbol_slug(value, "object", index)
        for index, value in enumerate(objects)
    }
    attribute_symbols = {
        value: symbol_slug(value, "attribute", index)
        for index, value in enumerate(attributes)
    }

    def render_attributes(values: Iterable[str]) -> list[str]:
        return [
            attribute_symbols[value]
            for value in ordered(values, attribute_order)
        ]

    def render_objects(values: Iterable[str]) -> list[str]:
        return [object_symbols[value] for value in ordered(values, object_order)]

    return {
        "schema": "wm-fca-scale-query-oracle-v1",
        "context_id": context_id,
        "context_name": context.name,
        "context_sha256": digest,
        "manifest_sha256": sha256(manifest_path),
        "protocol_sha256": manifest.get("protocol_sha256"),
        "upstream": entry.get("upstream"),
        "source_path": entry.get("source_path"),
        "citation": entry.get("citation"),
        "matrix_label": entry.get("matrix_label"),
        "dependence_group": entry.get("dependence_group"),
        "execution_policy": entry.get("execution_policy"),
        "dependency_versions": {
            "concepts": importlib.metadata.version("concepts"),
            "bitsets": importlib.metadata.version("bitsets"),
        },
        "object_count": len(objects),
        "attribute_count": len(attributes),
        "true_cell_count": true_cell_count,
        "false_cell_count": len(objects) * len(attributes) - true_cell_count,
        "query_count": len(raw_queries),
        "objects": list(objects),
        "attributes": list(attributes),
        "object_symbols": object_symbols,
        "attribute_symbols": attribute_symbols,
        "true_incidence": {
            object_symbols[obj]: render_attributes(row)
            for obj, row in zip(objects, context.rows, strict=True)
        },
        "queries": [
            {
                "candidate": render_attributes(candidate),
                "extent": render_objects(extent),
                "closure": render_attributes(closure),
            }
            for candidate, extent, closure in raw_queries
        ],
        "examples": {
            "true_cell": [
                object_symbols[true_cell[0]],
                attribute_symbols[true_cell[1]],
            ],
            "false_cell": [
                object_symbols[false_cell[0]],
                attribute_symbols[false_cell[1]],
            ],
        },
        "oracle_agreement": {
            "direct_extents_equal_concepts_0_9_2": True,
            "direct_closures_equal_concepts_0_9_2": True,
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--context", required=True)
    parser.add_argument("--receipt", type=Path, required=True)
    args = parser.parse_args()

    manifest = require_mapping(
        json.loads(args.manifest.read_text(encoding="utf-8")), "manifest"
    )
    if manifest.get("schema") != "wm-fca-context-manifest-v1":
        raise ValueError("unsupported context manifest schema")
    contexts = require_mapping(manifest.get("contexts"), "contexts")
    entry = require_mapping(contexts.get(args.context), f"contexts[{args.context}]")
    receipt = compute_receipt(args.context, args.manifest, manifest, entry)
    args.receipt.parent.mkdir(parents=True, exist_ok=True)
    args.receipt.write_text(
        json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print(
        json.dumps(
            {
                "attributes": receipt["attribute_count"],
                "context_id": receipt["context_id"],
                "objects": receipt["object_count"],
                "queries": receipt["query_count"],
                "oracle_agreement": receipt["oracle_agreement"],
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
