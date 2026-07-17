#!/usr/bin/env python3
"""Exact, receipt-producing FCA oracle for pinned Burmeister CXT contexts."""

from __future__ import annotations

import argparse
import hashlib
import importlib.metadata
import itertools
import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

import concepts


@dataclass(frozen=True)
class FormalContext:
    name: str
    objects: tuple[str, ...]
    attributes: tuple[str, ...]
    rows: tuple[frozenset[str], ...]


def read_cxt(path: Path) -> FormalContext:
    lines = path.read_text(encoding="utf-8").splitlines()
    if len(lines) < 5 or lines[0] != "B":
        raise ValueError(f"{path}: expected Burmeister CXT header 'B'")
    name = lines[1]
    try:
        object_count = int(lines[2])
        attribute_count = int(lines[3])
    except ValueError as exc:
        raise ValueError(f"{path}: invalid object/attribute count") from exc

    cursor = 4
    if cursor < len(lines) and lines[cursor] == "":
        cursor += 1
    expected = cursor + object_count + attribute_count + object_count
    if len(lines) != expected:
        raise ValueError(
            f"{path}: expected {expected} lines after parsing counts, got {len(lines)}"
        )

    objects = tuple(lines[cursor : cursor + object_count])
    cursor += object_count
    attributes = tuple(lines[cursor : cursor + attribute_count])
    cursor += attribute_count
    matrix_rows = lines[cursor : cursor + object_count]

    if len(set(objects)) != len(objects) or len(set(attributes)) != len(attributes):
        raise ValueError(f"{path}: object and attribute names must be unique")
    rows: list[frozenset[str]] = []
    for row_number, row in enumerate(matrix_rows):
        if len(row) != attribute_count:
            raise ValueError(
                f"{path}: matrix row {row_number} has width {len(row)}, "
                f"expected {attribute_count}"
            )
        invalid = set(row) - {"X", "x", "."}
        if invalid:
            raise ValueError(f"{path}: unsupported matrix marks {sorted(invalid)}")
        rows.append(
            frozenset(
                attribute
                for attribute, mark in zip(attributes, row, strict=True)
                if mark in {"X", "x"}
            )
        )
    return FormalContext(name, objects, attributes, tuple(rows))


def powerset(items: tuple[str, ...]) -> Iterable[frozenset[str]]:
    for size in range(len(items) + 1):
        for subset in itertools.combinations(items, size):
            yield frozenset(subset)


def symbol_slug(value: str, prefix: str, index: int) -> str:
    normalized = re.sub(r"[^A-Za-z0-9_]+", "_", value.strip()).strip("_").lower()
    if not normalized or normalized[0].isdigit():
        normalized = f"{prefix}_{normalized}"
    return f"{prefix}_{index:03d}_{normalized}"


def compute_receipt(
    context_id: str,
    cxt_path: Path,
    manifest_path: Path,
    manifest: dict[str, object],
    entry: dict[str, object],
) -> dict[str, object]:
    raw = cxt_path.read_bytes()
    digest = hashlib.sha256(raw).hexdigest()
    if digest != entry["sha256"]:
        raise ValueError(
            f"{context_id}: SHA-256 mismatch: expected {entry['sha256']}, got {digest}"
        )
    context = read_cxt(cxt_path)
    objects = context.objects
    attributes = context.attributes
    incidence = dict(zip(objects, context.rows, strict=True))
    object_order = {value: index for index, value in enumerate(objects)}
    attribute_order = {value: index for index, value in enumerate(attributes)}

    def ordered(values: Iterable[str], order: dict[str, int]) -> list[str]:
        return sorted(values, key=order.__getitem__)

    def extent(intent_value: frozenset[str]) -> frozenset[str]:
        return frozenset(obj for obj in objects if intent_value <= incidence[obj])

    def intent(extent_value: frozenset[str]) -> frozenset[str]:
        if not extent_value:
            return frozenset(attributes)
        iterator = iter(extent_value)
        result = set(incidence[next(iterator)])
        for obj in iterator:
            result.intersection_update(incidence[obj])
        return frozenset(result)

    def closure(candidate: frozenset[str]) -> frozenset[str]:
        return intent(extent(candidate))

    candidates = tuple(powerset(attributes))
    closed_intents = frozenset(closure(candidate) for candidate in candidates)
    concepts_set = frozenset((extent(value), value) for value in closed_intents)

    pseudo_intents: list[frozenset[str]] = []
    for candidate in candidates:
        candidate_closure = closure(candidate)
        if candidate == candidate_closure:
            continue
        if all(
            not (prior < candidate) or closure(prior) <= candidate
            for prior in pseudo_intents
        ):
            pseudo_intents.append(candidate)
    basis = frozenset(
        (candidate, closure(candidate) - candidate) for candidate in pseudo_intents
    )
    covers = frozenset(
        (general, specific)
        for general in closed_intents
        for specific in closed_intents
        if general < specific
        and not any(general < middle < specific for middle in closed_intents)
    )

    external_context = concepts.Context(
        objects,
        attributes,
        tuple(tuple(attribute in row for attribute in attributes) for row in context.rows),
    )
    external_concepts = frozenset(
        (frozenset(extent_value), frozenset(intent_value))
        for extent_value, intent_value in external_context.lattice
    )
    external_covers = frozenset(
        (
            frozenset(concept.intent),
            frozenset(neighbor.intent),
        )
        for concept in external_context.lattice
        for neighbor in concept.lower_neighbors
    )

    all_mask = (1 << len(attributes)) - 1
    row_masks = []
    for row in context.rows:
        mask = 0
        for index, attribute in enumerate(attributes):
            if attribute in row:
                mask |= 1 << index
        row_masks.append(mask)

    def mask_closure(candidate_mask: int) -> int:
        matching = [
            row_mask
            for row_mask in row_masks
            if candidate_mask & ~row_mask == 0
        ]
        if not matching:
            return all_mask
        result = all_mask
        for row_mask in matching:
            result &= row_mask
        return result

    pseudo_masks: list[int] = []
    for size in range(len(attributes) + 1):
        for indexes in itertools.combinations(range(len(attributes)), size):
            candidate_mask = sum(1 << index for index in indexes)
            candidate_closure = mask_closure(candidate_mask)
            if candidate_mask == candidate_closure:
                continue
            if all(
                not (
                    prior_mask != candidate_mask
                    and prior_mask & candidate_mask == prior_mask
                )
                or mask_closure(prior_mask) & candidate_mask
                == mask_closure(prior_mask)
                for prior_mask in pseudo_masks
            ):
                pseudo_masks.append(candidate_mask)

    def mask_to_set(mask: int) -> frozenset[str]:
        return frozenset(
            attribute
            for index, attribute in enumerate(attributes)
            if mask & (1 << index)
        )

    bitset_basis = frozenset(
        (
            mask_to_set(candidate_mask),
            mask_to_set(mask_closure(candidate_mask) & ~candidate_mask),
        )
        for candidate_mask in pseudo_masks
    )

    if concepts_set != external_concepts:
        raise ValueError(f"{context_id}: brute-force concepts differ from concepts 0.9.2")
    if covers != external_covers:
        raise ValueError(f"{context_id}: cover edges differ from concepts 0.9.2")
    if basis != bitset_basis:
        raise ValueError(f"{context_id}: set and bitset canonical bases differ")

    def set_sort_key(value: frozenset[str]) -> tuple[object, ...]:
        return (len(value), tuple(attribute_order[item] for item in ordered(value, attribute_order)))

    def concept_sort_key(
        value: tuple[frozenset[str], frozenset[str]],
    ) -> tuple[object, ...]:
        return set_sort_key(value[1])

    nonclosed = next(
        (
            candidate
            for candidate in candidates
            if closure(candidate) != candidate
        ),
        None,
    )
    closed_nonempty = next(
        (
            value
            for value in sorted(closed_intents, key=set_sort_key)
            if value
        ),
        frozenset(),
    )
    negative_implication = next(
        (
            (frozenset((left,)), frozenset((right,)))
            for left in attributes
            for right in attributes
            if left != right and right not in closure(frozenset((left,)))
        ),
        None,
    )
    if basis:
        positive_implication = min(basis, key=lambda pair: set_sort_key(pair[0]))
    else:
        reflexive = frozenset((attributes[0],)) if attributes else frozenset()
        positive_implication = (reflexive, reflexive)
    true_cell = next(
        (obj, attribute)
        for obj in objects
        for attribute in attributes
        if attribute in incidence[obj]
    )
    false_cell = next(
        (
            (obj, attribute)
            for obj in objects
            for attribute in attributes
            if attribute not in incidence[obj]
        ),
        None,
    )

    object_symbols = {
        value: symbol_slug(value, "object", index)
        for index, value in enumerate(objects)
    }
    attribute_symbols = {
        value: symbol_slug(value, "attribute", index)
        for index, value in enumerate(attributes)
    }

    def render_set(value: frozenset[str], symbols: dict[str, str], order: dict[str, int]) -> list[str]:
        return [symbols[item] for item in ordered(value, order)]

    receipt: dict[str, object] = {
        "schema": "wm-fca-cxt-oracle-v1",
        "context_id": context_id,
        "context_name": context.name,
        "context_sha256": digest,
        "manifest_sha256": hashlib.sha256(manifest_path.read_bytes()).hexdigest(),
        "upstream": entry.get("upstream", manifest.get("upstream")),
        "source_path": entry["source_path"],
        "citation": entry["citation"],
        "dependency_versions": {
            "concepts": importlib.metadata.version("concepts"),
            "bitsets": importlib.metadata.version("bitsets"),
        },
        "object_count": len(objects),
        "attribute_count": len(attributes),
        "true_cell_count": sum(len(row) for row in context.rows),
        "false_cell_count": len(objects) * len(attributes)
        - sum(len(row) for row in context.rows),
        "concept_count": len(concepts_set),
        "canonical_basis_count": len(basis),
        "cover_count": len(covers),
        "oracle_agreement": {
            "bruteforce_equals_concepts_0_9_2": concepts_set == external_concepts,
            "covers_equal_concepts_0_9_2_neighbors": covers == external_covers,
            "set_basis_equals_bitset_basis": basis == bitset_basis,
        },
        "objects": list(objects),
        "attributes": list(attributes),
        "object_symbols": object_symbols,
        "attribute_symbols": attribute_symbols,
        "true_incidence": {
            object_symbols[obj]: render_set(
                incidence[obj], attribute_symbols, attribute_order
            )
            for obj in objects
        },
        "intents": [
            render_set(value, attribute_symbols, attribute_order)
            for value in sorted(closed_intents, key=set_sort_key)
        ],
        "concepts": [
            {
                "extent": render_set(value[0], object_symbols, object_order),
                "intent": render_set(value[1], attribute_symbols, attribute_order),
            }
            for value in sorted(concepts_set, key=concept_sort_key)
        ],
        "canonical_basis": [
            {
                "antecedent": render_set(left, attribute_symbols, attribute_order),
                "consequent": render_set(right, attribute_symbols, attribute_order),
            }
            for left, right in sorted(
                basis,
                key=lambda pair: (set_sort_key(pair[0]), set_sort_key(pair[1])),
            )
        ],
        "covers": [
            {
                "general": render_set(general, attribute_symbols, attribute_order),
                "specific": render_set(specific, attribute_symbols, attribute_order),
            }
            for general, specific in sorted(
                covers,
                key=lambda pair: (set_sort_key(pair[0]), set_sort_key(pair[1])),
            )
        ],
        "examples": {
            "true_cell": [object_symbols[true_cell[0]], attribute_symbols[true_cell[1]]],
            "false_cell": None
            if false_cell is None
            else [
                object_symbols[false_cell[0]],
                attribute_symbols[false_cell[1]],
            ],
            "nonclosed_candidate": None
            if nonclosed is None
            else render_set(nonclosed, attribute_symbols, attribute_order),
            "nonclosed_closure": None
            if nonclosed is None
            else render_set(
                closure(nonclosed), attribute_symbols, attribute_order
            ),
            "closed_candidate": render_set(
                closed_nonempty, attribute_symbols, attribute_order
            ),
            "positive_implication": {
                "antecedent": render_set(
                    positive_implication[0], attribute_symbols, attribute_order
                ),
                "consequent": render_set(
                    positive_implication[1], attribute_symbols, attribute_order
                ),
            },
            "negative_implication": None
            if negative_implication is None
            else {
                "antecedent": render_set(
                    negative_implication[0], attribute_symbols, attribute_order
                ),
                "consequent": render_set(
                    negative_implication[1], attribute_symbols, attribute_order
                ),
            },
        },
    }
    return receipt


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--context", required=True)
    parser.add_argument("--receipt", type=Path, required=True)
    args = parser.parse_args()

    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    entry = manifest["contexts"].get(args.context)
    if entry is None:
        raise SystemExit(f"unknown context id: {args.context}")
    cxt_path = args.manifest.parent / entry["path"]
    receipt = compute_receipt(
        args.context, cxt_path, args.manifest, manifest, entry
    )
    args.receipt.parent.mkdir(parents=True, exist_ok=True)
    args.receipt.write_text(
        json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print(
        json.dumps(
            {
                "context_id": receipt["context_id"],
                "context_sha256": receipt["context_sha256"],
                "objects": receipt["object_count"],
                "attributes": receipt["attribute_count"],
                "concepts": receipt["concept_count"],
                "canonical_basis": receipt["canonical_basis_count"],
                "covers": receipt["cover_count"],
                "oracle_agreement": receipt["oracle_agreement"],
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
