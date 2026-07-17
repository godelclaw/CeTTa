#!/usr/bin/env python3
"""Scalable exact FCA receipts with independent lectic and level-wise oracles."""

from __future__ import annotations

import argparse
import hashlib
import importlib.metadata
import json
from pathlib import Path
from collections.abc import Callable, Iterable

import concepts

from cxt_oracle import FormalContext, read_cxt, symbol_slug


class OracleLimitExceeded(RuntimeError):
    """Raised instead of returning a partial exact receipt."""


def bit_context(
    context: FormalContext,
) -> tuple[tuple[int, ...], int, Callable[[int], int]]:
    attribute_index = {
        attribute: index for index, attribute in enumerate(context.attributes)
    }
    rows: list[int] = []
    for row in context.rows:
        mask = 0
        for attribute in row:
            mask |= 1 << attribute_index[attribute]
        rows.append(mask)
    all_attributes = (1 << len(context.attributes)) - 1

    def closure(candidate: int) -> int:
        result = all_attributes
        matched = False
        for row in rows:
            if candidate & ~row == 0:
                result &= row
                matched = True
        return result if matched else all_attributes

    return tuple(rows), all_attributes, closure


def lectic_canonical_system(
    context: FormalContext,
    logical_limit: int,
    concept_limit: int,
    basis_limit: int,
) -> tuple[set[int], list[tuple[int, int]], int]:
    """Enumerate intents and pseudo-intents with Ganter's NextClosure."""
    _, _, closure = bit_context(context)
    attribute_count = len(context.attributes)
    basis: list[tuple[int, int]] = []
    intents: set[int] = set()

    def pseudo_closure(candidate: int) -> int:
        while True:
            previous = candidate
            for antecedent, conclusion in basis:
                if antecedent != candidate and antecedent & ~candidate == 0:
                    candidate |= conclusion
            if candidate == previous:
                return candidate

    current = 0
    logical_count = 0
    while True:
        if logical_count >= logical_limit:
            raise OracleLimitExceeded("lectic logical-closure limit exceeded")
        logical_count += 1
        current_closure = closure(current)
        intents.add(current_closure)
        if len(intents) > concept_limit:
            raise OracleLimitExceeded("lectic concept limit exceeded")
        if current != current_closure:
            if len(basis) >= basis_limit:
                raise OracleLimitExceeded("lectic canonical-basis limit exceeded")
            basis.append((current, current_closure))

        following: int | None = None
        for pivot in range(attribute_count - 1, -1, -1):
            if current & (1 << pivot):
                continue
            prefix = current & ((1 << pivot) - 1)
            candidate = pseudo_closure(prefix | (1 << pivot))
            if candidate & ((1 << pivot) - 1) & ~current == 0:
                following = candidate
                break
        if following is None:
            return intents, basis, logical_count
        current = following


def levelwise_canonical_system(
    context: FormalContext,
    candidate_limit: int,
    concept_limit: int,
    basis_limit: int,
) -> tuple[set[int], list[tuple[int, int]], int]:
    """Independent cardinality-ordered NextClosures oracle."""
    _, _, closure = bit_context(context)
    attribute_count = len(context.attributes)
    candidates = [set() for _ in range(attribute_count + 1)]
    candidates[0].add(0)
    processed: set[int] = set()
    basis: list[tuple[int, int]] = []
    intents: set[int] = set()
    candidate_count = 0

    def implication_closure(candidate: int) -> int:
        while True:
            previous = candidate
            for antecedent, conclusion in basis:
                if antecedent & ~candidate == 0:
                    candidate |= conclusion
            if candidate == previous:
                return candidate

    for cardinality in range(attribute_count + 1):
        while candidates[cardinality]:
            candidate = min(candidates[cardinality])
            candidates[cardinality].remove(candidate)
            if candidate in processed:
                continue
            processed.add(candidate)
            if candidate_count >= candidate_limit:
                raise OracleLimitExceeded("level-wise candidate limit exceeded")
            candidate_count += 1

            logical_closure = implication_closure(candidate)
            if logical_closure != candidate:
                if logical_closure not in processed:
                    candidates[logical_closure.bit_count()].add(logical_closure)
                continue

            current_closure = closure(candidate)
            intents.add(current_closure)
            if len(intents) > concept_limit:
                raise OracleLimitExceeded("level-wise concept limit exceeded")
            if candidate != current_closure:
                if len(basis) >= basis_limit:
                    raise OracleLimitExceeded("level-wise basis limit exceeded")
                basis.append((candidate, current_closure))
            for attribute in range(attribute_count):
                if current_closure & (1 << attribute):
                    continue
                upper = current_closure | (1 << attribute)
                if upper not in processed:
                    candidates[upper.bit_count()].add(upper)

    return intents, basis, candidate_count


def cover_relation(intents: set[int], cover_limit: int) -> set[tuple[int, int]]:
    """Compute inclusion covers by retaining minimal strict supersets."""
    covers: set[tuple[int, int]] = set()
    for general in intents:
        supersets = sorted(
            (
                specific
                for specific in intents
                if general != specific and general & ~specific == 0
            ),
            key=lambda value: (value.bit_count(), value),
        )
        minimal: list[int] = []
        for specific in supersets:
            if any(prior & ~specific == 0 for prior in minimal):
                continue
            minimal.append(specific)
            covers.add((general, specific))
            if len(covers) > cover_limit:
                raise OracleLimitExceeded("cover limit exceeded")
    return covers


def compute_receipt(
    context_id: str,
    cxt_path: Path,
    manifest_path: Path,
    manifest: dict[str, object],
    entry: dict[str, object],
    *,
    logical_limit: int,
    level_candidate_limit: int,
    concept_limit: int,
    basis_limit: int,
    cover_limit: int,
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
    rows, _, closure = bit_context(context)
    object_order = {value: index for index, value in enumerate(objects)}
    attribute_order = {value: index for index, value in enumerate(attributes)}

    lectic_intents, lectic_basis, logical_count = lectic_canonical_system(
        context, logical_limit, concept_limit, basis_limit
    )
    level_intents, level_basis, level_count = levelwise_canonical_system(
        context, level_candidate_limit, concept_limit, basis_limit
    )
    if lectic_intents != level_intents:
        raise ValueError(f"{context_id}: lectic and level-wise intents differ")
    if set(lectic_basis) != set(level_basis):
        raise ValueError(f"{context_id}: lectic and level-wise bases differ")
    covers = cover_relation(lectic_intents, cover_limit)

    external_context = concepts.Context(
        objects,
        attributes,
        tuple(
            tuple(attribute in row for attribute in attributes)
            for row in context.rows
        ),
    )
    external_concepts = frozenset(
        (frozenset(extent), frozenset(intent))
        for extent, intent in external_context.lattice
    )
    attribute_index = {value: index for index, value in enumerate(attributes)}

    def set_mask(values: Iterable[str]) -> int:
        result = 0
        for value in values:
            result |= 1 << attribute_index[value]
        return result

    external_intents = {set_mask(intent) for _, intent in external_concepts}
    if lectic_intents != external_intents:
        raise ValueError(f"{context_id}: exact intents differ from concepts 0.9.2")
    external_covers = {
        (set_mask(concept.intent), set_mask(neighbor.intent))
        for concept in external_context.lattice
        for neighbor in concept.lower_neighbors
    }
    if covers != external_covers:
        raise ValueError(f"{context_id}: cover edges differ from concepts 0.9.2")

    def ordered(values: Iterable[str], order: dict[str, int]) -> list[str]:
        return sorted(values, key=order.__getitem__)

    def mask_values(mask: int) -> frozenset[str]:
        return frozenset(
            attribute
            for index, attribute in enumerate(attributes)
            if mask & (1 << index)
        )

    def extent_mask(intent_mask: int) -> frozenset[str]:
        return frozenset(
            obj for obj, row in zip(objects, rows, strict=True)
            if intent_mask & ~row == 0
        )

    def set_sort_key(value: frozenset[str]) -> tuple[object, ...]:
        return (
            len(value),
            tuple(attribute_order[item] for item in ordered(value, attribute_order)),
        )

    intents_as_sets = {mask_values(value) for value in lectic_intents}
    concepts_set = {
        (extent_mask(value), mask_values(value)) for value in lectic_intents
    }
    if concepts_set != external_concepts:
        raise ValueError(f"{context_id}: exact concepts differ from concepts 0.9.2")

    basis = {
        (mask_values(antecedent), mask_values(conclusion & ~antecedent))
        for antecedent, conclusion in lectic_basis
    }
    basis_full = {
        (mask_values(antecedent), mask_values(conclusion))
        for antecedent, conclusion in lectic_basis
    }
    covers_as_sets = {
        (mask_values(general), mask_values(specific))
        for general, specific in covers
    }

    true_cell = next(
        (obj, attribute)
        for obj, row in zip(objects, context.rows, strict=True)
        for attribute in attributes
        if attribute in row
    )
    false_cell = next(
        (
            (obj, attribute)
            for obj, row in zip(objects, context.rows, strict=True)
            for attribute in attributes
            if attribute not in row
        ),
        None,
    )
    if basis:
        positive_implication = min(basis, key=lambda pair: set_sort_key(pair[0]))
        nonclosed = positive_implication[0]
        nonclosed_closure = next(
            conclusion
            for antecedent, conclusion in basis_full
            if antecedent == nonclosed
        )
    else:
        # An empty canonical basis means the context closure is the identity:
        # every attribute set is already closed.  Preserve that fact instead
        # of inventing a nonclosed example.  A reflexive implication remains
        # a valid positive semantic canary without pretending it is canonical.
        reflexive = frozenset((attributes[0],)) if attributes else frozenset()
        positive_implication = (reflexive, reflexive)
        nonclosed = None
        nonclosed_closure = None
    negative_implication = next(
        (
            (frozenset((left,)), frozenset((right,)))
            for left in attributes
            for right in attributes
            if left != right
            and right not in mask_values(closure(1 << attribute_index[left]))
        ),
        None,
    )
    closed_nonempty = next(
        (
            value
            for value in sorted(intents_as_sets, key=set_sort_key)
            if value
        ),
        frozenset(),
    )

    object_symbols = {
        value: symbol_slug(value, "object", index)
        for index, value in enumerate(objects)
    }
    attribute_symbols = {
        value: symbol_slug(value, "attribute", index)
        for index, value in enumerate(attributes)
    }

    def render_set(
        value: frozenset[str], symbols: dict[str, str], order: dict[str, int]
    ) -> list[str]:
        return [symbols[item] for item in ordered(value, order)]

    def render_implication(
        value: tuple[frozenset[str], frozenset[str]] | None,
    ) -> dict[str, list[str]] | None:
        if value is None:
            return None
        return {
            "antecedent": render_set(value[0], attribute_symbols, attribute_order),
            "consequent": render_set(value[1], attribute_symbols, attribute_order),
        }

    true_incidence = {
        object_symbols[obj]: render_set(row, attribute_symbols, attribute_order)
        for obj, row in zip(objects, context.rows, strict=True)
    }
    receipt: dict[str, object] = {
        "schema": "wm-fca-cxt-oracle-v1",
        "context_id": context_id,
        "context_name": context.name,
        "context_sha256": digest,
        "manifest_sha256": hashlib.sha256(manifest_path.read_bytes()).hexdigest(),
        "upstream": entry.get("upstream", manifest.get("upstream")),
        "source_path": entry["source_path"],
        "citation": entry["citation"],
        "matrix_label": entry.get("matrix_label", "complete binary context"),
        "dependence_group": entry.get(
            "dependence_group", f"{context_id}-complete-matrix"
        ),
        "dependency_versions": {
            "concepts": importlib.metadata.version("concepts"),
            "bitsets": importlib.metadata.version("bitsets"),
        },
        "algorithm_counts": {
            "lectic_logical_closures": logical_count,
            "levelwise_candidates": level_count,
        },
        "object_count": len(objects),
        "attribute_count": len(attributes),
        "true_cell_count": sum(len(row) for row in context.rows),
        "false_cell_count": len(objects) * len(attributes)
        - sum(len(row) for row in context.rows),
        "concept_count": len(intents_as_sets),
        "canonical_basis_count": len(basis),
        "cover_count": len(covers_as_sets),
        "oracle_agreement": {
            "lectic_basis_equals_levelwise_nextclosures": set(lectic_basis)
            == set(level_basis),
            "lectic_intents_equals_levelwise_nextclosures": lectic_intents
            == level_intents,
            "lectic_intents_equal_concepts_0_9_2": lectic_intents
            == external_intents,
            "covers_equal_concepts_0_9_2_neighbors": covers == external_covers,
        },
        "objects": list(objects),
        "attributes": list(attributes),
        "object_symbols": object_symbols,
        "attribute_symbols": attribute_symbols,
        "true_incidence": true_incidence,
        "intents": [
            render_set(value, attribute_symbols, attribute_order)
            for value in sorted(intents_as_sets, key=set_sort_key)
        ],
        "concepts": [
            {
                "extent": render_set(extent, object_symbols, object_order),
                "intent": render_set(intent, attribute_symbols, attribute_order),
            }
            for extent, intent in sorted(
                concepts_set, key=lambda value: set_sort_key(value[1])
            )
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
                covers_as_sets,
                key=lambda pair: (set_sort_key(pair[0]), set_sort_key(pair[1])),
            )
        ],
        "examples": {
            "true_cell": [
                object_symbols[true_cell[0]],
                attribute_symbols[true_cell[1]],
            ],
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
            if nonclosed_closure is None
            else render_set(
                nonclosed_closure, attribute_symbols, attribute_order
            ),
            "closed_candidate": render_set(
                closed_nonempty, attribute_symbols, attribute_order
            ),
            "positive_implication": render_implication(positive_implication),
            "negative_implication": render_implication(negative_implication),
        },
    }
    return receipt


def positive(value: str) -> int:
    parsed = int(value)
    if parsed <= 0:
        raise argparse.ArgumentTypeError("expected a positive integer")
    return parsed


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--context", required=True)
    parser.add_argument("--receipt", type=Path, required=True)
    parser.add_argument("--logical-limit", type=positive, required=True)
    parser.add_argument("--level-candidate-limit", type=positive, required=True)
    parser.add_argument("--concept-limit", type=positive, required=True)
    parser.add_argument("--basis-limit", type=positive, required=True)
    parser.add_argument("--cover-limit", type=positive, required=True)
    args = parser.parse_args()

    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    entry = manifest["contexts"].get(args.context)
    if entry is None:
        raise SystemExit(f"unknown context id: {args.context}")
    cxt_path = args.manifest.parent / entry["path"]
    receipt = compute_receipt(
        args.context,
        cxt_path,
        args.manifest,
        manifest,
        entry,
        logical_limit=args.logical_limit,
        level_candidate_limit=args.level_candidate_limit,
        concept_limit=args.concept_limit,
        basis_limit=args.basis_limit,
        cover_limit=args.cover_limit,
    )
    args.receipt.parent.mkdir(parents=True, exist_ok=True)
    args.receipt.write_text(
        json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print(
        json.dumps(
            {
                "context_id": receipt["context_id"],
                "objects": receipt["object_count"],
                "attributes": receipt["attribute_count"],
                "concepts": receipt["concept_count"],
                "canonical_basis": receipt["canonical_basis_count"],
                "covers": receipt["cover_count"],
                "algorithm_counts": receipt["algorithm_counts"],
                "oracle_agreement": receipt["oracle_agreement"],
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
