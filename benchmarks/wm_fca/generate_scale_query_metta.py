#!/usr/bin/env python3
"""Generate bounded native CeTTa query gates from a scale-query receipt."""

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


def symbol_list(value: object, label: str) -> list[str]:
    return [
        require_string(item, f"{label}[{index}]")
        for index, item in enumerate(require_list(value, label))
    ]


def metta_list(items: Iterable[str]) -> str:
    return f"({' '.join(items)})"


def indented_list(items: list[str], indent: str = "   ") -> str:
    if not items:
        return "()"
    return "(\n" + "\n".join(f"{indent}{item}" for item in items) + ")"


def receipt_symbols(
    receipt: dict[str, object], names_key: str, symbols_key: str
) -> list[str]:
    names = symbol_list(receipt.get(names_key), names_key)
    symbols = require_mapping(receipt.get(symbols_key), symbols_key)
    if set(names) != set(symbols):
        raise ValueError(f"{symbols_key} keys must exactly match {names_key}")
    return [require_string(symbols[name], f"{symbols_key}[{name}]") for name in names]


def validate_receipt(receipt: dict[str, object]) -> None:
    if receipt.get("schema") != "wm-fca-scale-query-oracle-v1":
        raise ValueError("unsupported scale query receipt schema")
    context_id = require_string(receipt.get("context_id"), "context_id")
    if not context_id.replace("_", "").replace(".", "").isalnum():
        raise ValueError("context_id contains unsupported characters")
    objects = receipt_symbols(receipt, "objects", "object_symbols")
    attributes = receipt_symbols(receipt, "attributes", "attribute_symbols")
    if len(objects) != receipt.get("object_count"):
        raise ValueError("object_count does not match object symbols")
    if len(attributes) != receipt.get("attribute_count"):
        raise ValueError("attribute_count does not match attribute symbols")
    if len(require_list(receipt.get("queries"), "queries")) != receipt.get(
        "query_count"
    ):
        raise ValueError("query_count does not match query records")
    if not all(
        value is True
        for value in require_mapping(
            receipt.get("oracle_agreement"), "oracle_agreement"
        ).values()
    ):
        raise ValueError("all scale query oracle agreement checks must be true")


def render_context(receipt: dict[str, object]) -> str:
    context_id = require_string(receipt.get("context_id"), "context_id")
    objects = receipt_symbols(receipt, "objects", "object_symbols")
    attributes = receipt_symbols(receipt, "attributes", "attribute_symbols")
    incidence = require_mapping(receipt.get("true_incidence"), "true_incidence")
    true_cells = {
        (obj, attribute)
        for obj, raw_attributes in incidence.items()
        for attribute in symbol_list(raw_attributes, f"true_incidence[{obj}]")
    }
    upstream = require_mapping(receipt.get("upstream"), "upstream")
    repository = require_string(upstream.get("repository"), "upstream.repository")
    commit = require_string(upstream.get("commit"), "upstream.commit")
    source_id = require_string(upstream.get("source_id"), "upstream.source_id")
    source_path = require_string(receipt.get("source_path"), "source_path")
    source = f"{source_id}-{commit[:8]}"
    group = require_string(receipt.get("dependence_group"), "dependence_group")
    binary_rows = [
        f'(WMFCABinaryRow {obj} "'
        + "".join(
            "1" if (obj, attribute) in true_cells else "0"
            for attribute in attributes
        )
        + '")'
        for obj in objects
    ]

    candidates: list[str] = []
    results: list[str] = []
    for index, raw_query in enumerate(require_list(receipt.get("queries"), "queries")):
        query = require_mapping(raw_query, f"queries[{index}]")
        candidate = metta_list(
            symbol_list(query.get("candidate"), "candidate")
        )
        extent = metta_list(symbol_list(query.get("extent"), "extent"))
        closure = metta_list(symbol_list(query.get("closure"), "closure"))
        candidates.append(candidate)
        results.append(
            f"(WMFCABatchQueryResult {candidate} {extent} {closure})"
        )
    return f"""; Generated from a pinned complete FCA scale context.
; Source: {repository}/blob/{commit}/{source_path}
; SHA-256: {require_string(receipt.get('context_sha256'), 'context_sha256')}
;
; Zeroes denote explicit WMFalse base observations, never missing observations.
; The complete matrix stays packed into bounded rows; cell-level evidence is
; synthesized only when queried.  This fixture contains no full-lattice oracle.

!(import! &self lib_wm_fca)

(= (wm-fca-{context_id}-objects)
   {metta_list(objects)})

(= (wm-fca-{context_id}-attributes)
   {metta_list(attributes)})

(= (wm-fca-{context_id}-state)
   (WMFCACompleteBinaryState
     {metta_list(objects)}
     {metta_list(attributes)}
     {indented_list(binary_rows, '     ')}
     {context_id} {source} {group}))

(= (wm-fca-{context_id}-scale-candidates)
   {indented_list(candidates)})

(= (wm-fca-{context_id}-scale-results)
   {indented_list(results)})
"""


def render_test(receipt: dict[str, object]) -> str:
    context_id = require_string(receipt.get("context_id"), "context_id")
    examples = require_mapping(receipt.get("examples"), "examples")
    true_cell = symbol_list(examples.get("true_cell"), "examples.true_cell")
    false_cell = symbol_list(examples.get("false_cell"), "examples.false_cell")
    if len(true_cell) != 2 or len(false_cell) != 2:
        raise ValueError("cell examples must contain object and attribute symbols")
    observation_count = int(receipt["object_count"]) * int(receipt["attribute_count"])
    return f"""!(import! &self ./{context_id}_context.metta)

; The packed backend compiles the matrix once for this bounded query batch.
; No interpreted recursion or full-lattice enumeration is involved.

!(assertEqual
   (wm-fca-state-observation-count (wm-fca-{context_id}-state))
   {observation_count})
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-{context_id}-state) {context_id} {true_cell[0]} {true_cell[1]})
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-{context_id}-state) {context_id} {false_cell[0]} {false_cell[1]})
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-{context_id}-state) another-context
     {false_cell[0]} {false_cell[1]})
   WMMissing)
!(assertEqual
   (wm-fca-batch-queries
     (wm-fca-{context_id}-state)
     {context_id}
     WMFCAExactStatusGate
     (wm-fca-{context_id}-scale-candidates))
   (wm-fca-{context_id}-scale-results))
"""


def render_context_load_test(receipt: dict[str, object]) -> str:
    context_id = require_string(receipt.get("context_id"), "context_id")
    examples = require_mapping(receipt.get("examples"), "examples")
    true_cell = symbol_list(examples.get("true_cell"), "examples.true_cell")
    false_cell = symbol_list(examples.get("false_cell"), "examples.false_cell")
    if len(true_cell) != 2 or len(false_cell) != 2:
        raise ValueError("cell examples must contain object and attribute symbols")
    observation_count = int(receipt["object_count"]) * int(receipt["attribute_count"])
    return f"""!(import! &self ./{context_id}_context.metta)

!(assertEqual
   (wm-fca-state-observation-count (wm-fca-{context_id}-state))
   {observation_count})
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-{context_id}-state) {context_id} {true_cell[0]} {true_cell[1]})
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-{context_id}-state) {context_id} {false_cell[0]} {false_cell[1]})
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-{context_id}-state) another-context
     {false_cell[0]} {false_cell[1]})
   WMMissing)
"""


def render_index_build_test(receipt: dict[str, object]) -> str:
    context_id = require_string(receipt.get("context_id"), "context_id")
    return f"""!(import! &self ./{context_id}_context.metta)

!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-{context_id}-state)
            {context_id} WMFCAExactStatusGate))
     (wm-fca-index-column-count $index))
   {int(receipt['attribute_count'])})
"""


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--receipt", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()

    receipt = require_mapping(
        json.loads(args.receipt.read_text(encoding="utf-8")), "receipt"
    )
    validate_receipt(receipt)
    context_id = require_string(receipt.get("context_id"), "context_id")
    context_path = args.output_dir / f"{context_id}_context.metta"
    test_path = args.output_dir / f"test_{context_id}_scale_queries.metta"
    expected_path = args.output_dir / f"test_{context_id}_scale_queries.expected"
    load_test_path = args.output_dir / f"test_{context_id}_context_load.metta"
    load_expected_path = args.output_dir / f"test_{context_id}_context_load.expected"
    index_test_path = args.output_dir / f"test_{context_id}_index_build.metta"
    index_expected_path = args.output_dir / f"test_{context_id}_index_build.expected"
    context_text = render_context(receipt)
    test_text = render_test(receipt)
    load_test_text = render_context_load_test(receipt)
    index_test_text = render_index_build_test(receipt)
    success_count = sum(
        line.lstrip().startswith("!(") for line in test_text.splitlines()
    )
    load_success_count = sum(
        line.lstrip().startswith("!(") for line in load_test_text.splitlines()
    )
    index_success_count = sum(
        line.lstrip().startswith("!(") for line in index_test_text.splitlines()
    )
    context_path.parent.mkdir(parents=True, exist_ok=True)
    context_path.write_text(context_text, encoding="utf-8")
    test_path.write_text(test_text, encoding="utf-8")
    expected_path.write_text("[()]\n" * success_count, encoding="utf-8")
    load_test_path.write_text(load_test_text, encoding="utf-8")
    load_expected_path.write_text(
        "[()]\n" * load_success_count, encoding="utf-8"
    )
    index_test_path.write_text(index_test_text, encoding="utf-8")
    index_expected_path.write_text(
        "[()]\n" * index_success_count, encoding="utf-8"
    )
    print(
        json.dumps(
            {
                "context": str(context_path),
                "expected": str(expected_path),
                "index_test": str(index_test_path),
                "load_test": str(load_test_path),
                "success_expressions": success_count,
                "test": str(test_path),
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
