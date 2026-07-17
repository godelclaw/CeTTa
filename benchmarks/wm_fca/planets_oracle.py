#!/usr/bin/env python3
"""Independent exact FCA oracle for the pinned fcaR Planets context."""

from __future__ import annotations

import argparse
import hashlib
import itertools
import json
from pathlib import Path
from typing import Iterable


def powerset(items: tuple[str, ...]) -> Iterable[frozenset[str]]:
    for size in range(len(items) + 1):
        for subset in itertools.combinations(items, size):
            yield frozenset(subset)


def canonical_set(values: Iterable[str], order: dict[str, int]) -> list[str]:
    return sorted(values, key=order.__getitem__)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--context",
        type=Path,
        default=Path(__file__).with_name("planets_fcar_v2.json"),
    )
    parser.add_argument("--receipt", type=Path)
    args = parser.parse_args()

    raw = args.context.read_bytes()
    document = json.loads(raw)
    objects = tuple(document["objects"])
    attributes = tuple(document["attributes"])
    object_order = {value: index for index, value in enumerate(objects)}
    attribute_order = {value: index for index, value in enumerate(attributes)}
    incidence = {
        obj: frozenset(document["true_incidence"][obj]) for obj in objects
    }

    def extent(intent: frozenset[str]) -> frozenset[str]:
        return frozenset(obj for obj in objects if intent <= incidence[obj])

    def intent(extent_value: frozenset[str]) -> frozenset[str]:
        if not extent_value:
            return frozenset(attributes)
        rows = iter(extent_value)
        result = set(incidence[next(rows)])
        for obj in rows:
            result.intersection_update(incidence[obj])
        return frozenset(result)

    def closure(candidate: frozenset[str]) -> frozenset[str]:
        return intent(extent(candidate))

    candidates = tuple(powerset(attributes))
    closed_intents = frozenset(closure(candidate) for candidate in candidates)

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

    published_intents = frozenset(
        frozenset(value) for value in document["published_intents"]
    )
    published_basis = frozenset(
        (frozenset(left), frozenset(right))
        for left, right in document["published_basis"]
    )

    concepts = [
        {
            "extent": canonical_set(extent(value), object_order),
            "intent": canonical_set(value, attribute_order),
        }
        for value in sorted(
            closed_intents,
            key=lambda item: (len(item), canonical_set(item, attribute_order)),
        )
    ]
    receipt = {
        "schema": "wm-fca-planets-oracle-v1",
        "context_sha256": hashlib.sha256(raw).hexdigest(),
        "source": document["source"],
        "object_count": len(objects),
        "attribute_count": len(attributes),
        "true_cell_count": sum(len(value) for value in incidence.values()),
        "false_cell_count": len(objects) * len(attributes)
        - sum(len(value) for value in incidence.values()),
        "concept_count": len(closed_intents),
        "canonical_basis_count": len(basis),
        "cover_count": len(covers),
        "published_intents_equal": closed_intents == published_intents,
        "published_basis_equal": basis == published_basis,
        "concepts": concepts,
        "canonical_basis": [
            {
                "antecedent": canonical_set(left, attribute_order),
                "consequent": canonical_set(right, attribute_order),
            }
            for left, right in sorted(
                basis,
                key=lambda pair: (
                    len(pair[0]),
                    canonical_set(pair[0], attribute_order),
                ),
            )
        ],
        "covers": [
            {
                "general": canonical_set(general, attribute_order),
                "specific": canonical_set(specific, attribute_order),
            }
            for general, specific in sorted(
                covers,
                key=lambda pair: (
                    len(pair[0]),
                    canonical_set(pair[0], attribute_order),
                    len(pair[1]),
                    canonical_set(pair[1], attribute_order),
                ),
            )
        ],
    }

    if not receipt["published_intents_equal"]:
        raise SystemExit("computed intents differ from the pinned published intents")
    if not receipt["published_basis_equal"]:
        raise SystemExit("computed basis differs from the pinned published basis")
    if len(closed_intents) != 12 or len(basis) != 10 or len(covers) != 18:
        raise SystemExit("computed Planets artifact counts differ from the oracle")

    rendered = json.dumps(receipt, indent=2, sort_keys=True) + "\n"
    if args.receipt:
        args.receipt.parent.mkdir(parents=True, exist_ok=True)
        args.receipt.write_text(rendered, encoding="utf-8")
    else:
        print(rendered, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
