#!/usr/bin/env python3
"""Materialize pinned FCApy-random and Bob Ross Burmeister contexts."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
from itertools import product
from pathlib import Path
from typing import Iterable

import numpy as np


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


def density_label(value: float) -> str:
    if value not in {0.1, 0.5, 0.9}:
        raise ValueError(f"unsupported preregistered density: {value}")
    return f"{value:.1f}"


def write_cxt(
    path: Path,
    name: str,
    objects: Iterable[str],
    attributes: Iterable[str],
    rows: Iterable[Iterable[bool]],
) -> None:
    object_list = list(objects)
    attribute_list = list(attributes)
    row_list = [tuple(row) for row in rows]
    if len(set(object_list)) != len(object_list):
        raise ValueError(f"{name}: object names must be unique")
    if len(set(attribute_list)) != len(attribute_list):
        raise ValueError(f"{name}: attribute names must be unique")
    if len(row_list) != len(object_list):
        raise ValueError(f"{name}: row count does not match objects")
    if any(len(row) != len(attribute_list) for row in row_list):
        raise ValueError(f"{name}: row width does not match attributes")

    lines = [
        "B",
        name,
        str(len(object_list)),
        str(len(attribute_list)),
        "",
        *object_list,
        *attribute_list,
        *("".join("X" if value else "." for value in row) for row in row_list),
    ]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def source_entry(source: dict[str, object]) -> dict[str, object]:
    return {
        "commit": require_string(source.get("commit"), "source.commit"),
        "license": require_string(source.get("license"), "source.license"),
        "repository": require_string(
            source.get("repository"), "source.repository"
        ),
        "source_id": require_string(source.get("source_id"), "source.source_id"),
    }


def random_contexts(
    protocol: dict[str, object], output_dir: Path
) -> dict[str, dict[str, object]]:
    family = require_mapping(protocol.get("random_family"), "random_family")
    expected = require_mapping(
        family.get("expected_true_cell_counts"),
        "random_family.expected_true_cell_counts",
    )
    object_counts = [
        require_int(value, "random_family.object_counts[]")
        for value in require_list(family.get("object_counts"), "object_counts")
    ]
    attribute_counts = [
        require_int(value, "random_family.attribute_counts[]")
        for value in require_list(family.get("attribute_counts"), "attribute_counts")
    ]
    densities = [
        float(value)
        for value in require_list(family.get("densities"), "densities")
    ]
    seed = require_int(family.get("seed"), "random_family.seed")
    required_numpy = require_string(
        family.get("numpy_version"), "random_family.numpy_version"
    )
    if np.__version__ != required_numpy:
        raise ValueError(
            f"NumPy version mismatch: expected {required_numpy}, got {np.__version__}"
        )

    rng = np.random.RandomState(seed)
    source = require_mapping(family.get("source"), "random_family.source")
    upstream = source_entry(source)
    source_path = require_string(source.get("source_path"), "source.source_path")
    citation = require_string(family.get("citation"), "random_family.citation")
    entries: dict[str, dict[str, object]] = {}
    for object_count, attribute_count, density in product(
        object_counts, attribute_counts, densities
    ):
        label = density_label(density)
        context_id = f"random_{object_count}_{attribute_count}_{label}"
        matrix = rng.binomial(1, density, size=(object_count, attribute_count))
        true_count = int(matrix.sum())
        expected_count = require_int(expected.get(context_id), f"expected[{context_id}]")
        if true_count != expected_count:
            raise ValueError(
                f"{context_id}: generated {true_count} incidences, "
                f"published statistics require {expected_count}"
            )
        path = output_dir / f"{context_id}.cxt"
        write_cxt(
            path,
            context_id,
            (f"g_{index}" for index in range(object_count)),
            (f"m_{index}" for index in range(attribute_count)),
            ((bool(value) for value in row) for row in matrix),
        )
        entries[context_id] = {
            "attribute_count": attribute_count,
            "citation": citation,
            "dependence_group": f"{context_id}-generated-matrix",
            "execution_policy": (
                "exact-enumeration"
                if attribute_count <= 10
                else "query-only"
            ),
            "matrix_label": "FCApy controlled random matrix",
            "object_count": object_count,
            "path": str(path.relative_to(output_dir.parent)),
            "sha256": sha256(path),
            "source_path": source_path,
            "true_cell_count": true_count,
            "upstream": upstream,
        }
    if set(entries) != set(expected):
        raise ValueError("random context grid does not match expected statistics")
    return entries


def bob_ross_context(
    protocol: dict[str, object], protocol_path: Path, output_dir: Path
) -> tuple[str, dict[str, object]]:
    spec = require_mapping(protocol.get("bob_ross"), "bob_ross")
    context_id = require_string(spec.get("context_id"), "bob_ross.context_id")
    input_path = protocol_path.parent / require_string(
        spec.get("input_path"), "bob_ross.input_path"
    )
    expected_digest = require_string(
        spec.get("input_sha256"), "bob_ross.input_sha256"
    )
    if sha256(input_path) != expected_digest:
        raise ValueError("Bob Ross input SHA-256 does not match the pinned protocol")

    with input_path.open(newline="", encoding="utf-8-sig") as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames is None or reader.fieldnames[:2] != ["EPISODE", "TITLE"]:
            raise ValueError("Bob Ross input must begin with EPISODE,TITLE")
        attributes = reader.fieldnames[2:]
        records = list(reader)
    objects = [f"{row['EPISODE']} {row['TITLE']}" for row in records]
    rows: list[tuple[bool, ...]] = []
    for row_index, record in enumerate(records):
        values = tuple(record[attribute] for attribute in attributes)
        if set(values) - {"0", "1"}:
            raise ValueError(f"Bob Ross row {row_index} contains a nonbinary cell")
        rows.append(tuple(value == "1" for value in values))

    expected_objects = require_int(spec.get("object_count"), "bob_ross.object_count")
    expected_attributes = require_int(
        spec.get("attribute_count"), "bob_ross.attribute_count"
    )
    expected_true = require_int(
        spec.get("true_cell_count"), "bob_ross.true_cell_count"
    )
    if len(objects) != expected_objects or len(attributes) != expected_attributes:
        raise ValueError("Bob Ross shape does not match the pinned protocol")
    if sum(sum(row) for row in rows) != expected_true:
        raise ValueError("Bob Ross incidence count does not match the pinned protocol")

    path = output_dir / f"{context_id}.cxt"
    write_cxt(path, context_id, objects, attributes, rows)
    source = require_mapping(spec.get("source"), "bob_ross.source")
    return context_id, {
        "attribute_count": len(attributes),
        "citation": require_string(spec.get("citation"), "bob_ross.citation"),
        "dependence_group": "bob-ross-published-matrix",
        "execution_policy": require_string(
            spec.get("execution_policy"), "bob_ross.execution_policy"
        ),
        "input_sha256": expected_digest,
        "matrix_label": "published Bob Ross episode-element matrix",
        "object_count": len(objects),
        "path": str(path.relative_to(output_dir.parent)),
        "sha256": sha256(path),
        "source_path": require_string(source.get("source_path"), "source.source_path"),
        "true_cell_count": expected_true,
        "upstream": source_entry(source),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--protocol", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--manifest", type=Path, required=True)
    args = parser.parse_args()

    protocol = require_mapping(
        json.loads(args.protocol.read_text(encoding="utf-8")), "protocol"
    )
    if protocol.get("schema") != "wm-fca-scale-protocol-v1":
        raise ValueError("unsupported scale protocol schema")
    entries = random_contexts(protocol, args.output_dir)
    bob_id, bob_entry = bob_ross_context(protocol, args.protocol, args.output_dir)
    entries[bob_id] = bob_entry
    manifest = {
        "schema": "wm-fca-context-manifest-v1",
        "protocol_sha256": sha256(args.protocol),
        "query_protocol": protocol["query_protocol"],
        "contexts": entries,
    }
    args.manifest.parent.mkdir(parents=True, exist_ok=True)
    args.manifest.write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print(
        json.dumps(
            {
                "contexts": len(entries),
                "exact_enumeration": sum(
                    entry["execution_policy"] == "exact-enumeration"
                    for entry in entries.values()
                ),
                "query_only": sum(
                    entry["execution_policy"] == "query-only"
                    for entry in entries.values()
                ),
                "manifest": str(args.manifest),
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
