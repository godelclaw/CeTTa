#!/usr/bin/env python3
"""Generate deterministic CeTTa WM/FCA fixtures from an exact CXT receipt."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Iterable


def metta_list(items: Iterable[str]) -> str:
    return f"({' '.join(items)})"


def indented_list(items: list[str], indent: str = "   ") -> str:
    if not items:
        return "()"
    return "(\n" + "\n".join(f"{indent}{item}" for item in items) + ")"


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


def optional_symbol_list(value: object, label: str) -> list[str] | None:
    if value is None:
        return None
    return symbol_list(value, label)


def receipt_symbols(
    receipt: dict[str, object], names_key: str, symbols_key: str
) -> list[str]:
    names = symbol_list(receipt.get(names_key), names_key)
    symbols = require_mapping(receipt.get(symbols_key), symbols_key)
    if set(symbols) != set(names):
        raise ValueError(f"{symbols_key} keys must exactly match {names_key}")
    return [require_string(symbols[name], f"{symbols_key}[{name}]") for name in names]


def receipt_source_metadata(
    receipt: dict[str, object],
) -> tuple[str, str, str, str]:
    upstream = require_mapping(receipt["upstream"], "upstream")
    repository = require_string(upstream["repository"], "upstream.repository").rstrip(
        "/"
    )
    commit = require_string(upstream["commit"], "upstream.commit")
    raw_source_id = upstream.get("source_id")
    source_id = require_string(
        raw_source_id if raw_source_id is not None else "fcatools-contexts",
        "upstream.source_id",
    )
    source_path = require_string(receipt["source_path"], "source_path")
    context_id = require_string(receipt["context_id"], "context_id")
    raw_group = receipt.get("dependence_group")
    group = require_string(
        raw_group if raw_group is not None else f"{context_id}-published-matrix",
        "dependence_group",
    )
    raw_matrix_label = receipt.get("matrix_label")
    matrix_label = require_string(
        raw_matrix_label if raw_matrix_label is not None else "published matrix",
        "matrix_label",
    )
    return (
        f"{source_id}-{commit[:8]}",
        group,
        f"{repository}/blob/{commit}/{source_path}",
        matrix_label,
    )


def validate_receipt(receipt: dict[str, object]) -> None:
    if receipt.get("schema") != "wm-fca-cxt-oracle-v1":
        raise ValueError("unsupported oracle receipt schema")
    context_id = require_string(receipt.get("context_id"), "context_id")
    if not context_id.replace("_", "").replace(".", "").isalnum():
        raise ValueError(
            "context_id must contain only letters, digits, underscores, and dots"
        )

    objects = receipt_symbols(receipt, "objects", "object_symbols")
    attributes = receipt_symbols(receipt, "attributes", "attribute_symbols")
    if len(objects) != receipt.get("object_count"):
        raise ValueError("object_count does not match object_symbols")
    if len(attributes) != receipt.get("attribute_count"):
        raise ValueError("attribute_count does not match attribute_symbols")
    if len(set(objects)) != len(objects) or len(set(attributes)) != len(attributes):
        raise ValueError("generated object and attribute symbols must be unique")

    expected_cells = len(objects) * len(attributes)
    if receipt.get("true_cell_count", 0) + receipt.get("false_cell_count", 0) != expected_cells:
        raise ValueError("true and false cell counts do not cover the complete context")
    if len(require_list(receipt.get("intents"), "intents")) != receipt.get("concept_count"):
        raise ValueError("intent count does not match concept_count")
    if len(require_list(receipt.get("concepts"), "concepts")) != receipt.get("concept_count"):
        raise ValueError("concept list does not match concept_count")
    if len(require_list(receipt.get("canonical_basis"), "canonical_basis")) != receipt.get(
        "canonical_basis_count"
    ):
        raise ValueError("canonical basis list does not match its count")
    if len(require_list(receipt.get("covers"), "covers")) != receipt.get("cover_count"):
        raise ValueError("cover list does not match cover_count")
    agreement = require_mapping(receipt.get("oracle_agreement"), "oracle_agreement")
    if not agreement or not all(value is True for value in agreement.values()):
        raise ValueError("all independent oracle agreement checks must be true")


def render_context(receipt: dict[str, object]) -> str:
    context_id = require_string(receipt["context_id"], "context_id")
    digest = require_string(receipt["context_sha256"], "context_sha256")
    object_symbols = receipt_symbols(receipt, "objects", "object_symbols")
    attribute_symbols = receipt_symbols(
        receipt, "attributes", "attribute_symbols"
    )
    true_incidence = require_mapping(receipt["true_incidence"], "true_incidence")
    true_cells = {
        (obj, attribute)
        for obj, raw_attributes in true_incidence.items()
        for attribute in symbol_list(raw_attributes, f"true_incidence[{obj}]")
    }
    source, group, source_url, matrix_label = receipt_source_metadata(receipt)

    observations: list[str] = []
    for object_index, obj in enumerate(object_symbols):
        for attribute_index, attribute in enumerate(attribute_symbols):
            status = "WMTrue" if (obj, attribute) in true_cells else "WMFalse"
            stamp = f"{context_id}-cell-{object_index:03d}-{attribute_index:03d}"
            observations.append(
                f"(WMFCAObservation {context_id} {obj} {attribute} {status}\n"
                f"  {stamp} {source} {group})"
            )

    intents = [
        metta_list(symbol_list(value, "intent"))
        for value in require_list(receipt["intents"], "intents")
    ]
    concepts: list[str] = []
    for raw_concept in require_list(receipt["concepts"], "concepts"):
        concept = require_mapping(raw_concept, "concept")
        concepts.append(
            "(WMFCAConcept "
            f"{metta_list(symbol_list(concept['extent'], 'concept.extent'))} "
            f"{metta_list(symbol_list(concept['intent'], 'concept.intent'))})"
        )
    implications: list[str] = []
    for raw_implication in require_list(receipt["canonical_basis"], "canonical_basis"):
        implication = require_mapping(raw_implication, "canonical implication")
        implications.append(
            "(WMFCAImplication "
            f"{metta_list(symbol_list(implication['antecedent'], 'antecedent'))} "
            f"{metta_list(symbol_list(implication['consequent'], 'consequent'))})"
        )
    covers: list[str] = []
    for raw_cover in require_list(receipt["covers"], "covers"):
        cover = require_mapping(raw_cover, "cover")
        covers.append(
            "(WMFCACover "
            f"{metta_list(symbol_list(cover['general'], 'cover.general'))} "
            f"{metta_list(symbol_list(cover['specific'], 'cover.specific'))})"
        )

    return f"""; Generated from a pinned public Formal Concept Analysis context.
; Source: {source_url}
; SHA-256: {digest}
;
; The context is complete: all {len(object_symbols)} x {len(attribute_symbols)} cells are
; explicit observations.  Matrix zeroes are WMFalse, never WMMissing.  A single
; dependence group records that the cells belong to one {matrix_label}.

!(import! &self lib_wm_fca)

(= (wm-fca-{context_id}-objects)
   {metta_list(object_symbols)})

(= (wm-fca-{context_id}-attributes)
   {metta_list(attribute_symbols)})

(= (wm-fca-{context_id}-state)
   (WMFCAState
     {metta_list(object_symbols)}
     {metta_list(attribute_symbols)}
     {indented_list(observations, '     ')}))

(= (wm-fca-{context_id}-oracle-intents)
   {indented_list(intents)})

(= (wm-fca-{context_id}-oracle-concepts)
   {indented_list(concepts)})

(= (wm-fca-{context_id}-oracle-basis)
   {indented_list(implications)})

; Cover direction follows intent inclusion: general intent -> specific intent.
(= (wm-fca-{context_id}-oracle-covers)
   {indented_list(covers)})
"""


def render_implication(value: object, label: str) -> str:
    implication = require_mapping(value, label)
    return (
        "(WMFCAImplication "
        f"{metta_list(symbol_list(implication['antecedent'], f'{label}.antecedent'))} "
        f"{metta_list(symbol_list(implication['consequent'], f'{label}.consequent'))})"
    )


def exact_basis_logical_closure_count(receipt: dict[str, object]) -> int:
    """Exact fail-loud bound for canonical-basis NextClosure.

    The logical pseudo-closure system consists exactly of the context intents
    and pseudo-intents.  The latter are in one-to-one correspondence with the
    canonical implications recorded by the independent oracle.
    """
    return int(receipt["concept_count"]) + int(receipt["canonical_basis_count"])


def render_native_intents_test(receipt: dict[str, object]) -> str:
    context_id = require_string(receipt["context_id"], "context_id")
    concept_count = int(receipt["concept_count"])
    return f"""!(import! &self ./{context_id}_context.metta)

; This scale-ladder gate isolates native Ganter enumeration from the more
; expensive implication-basis and cover calculations in the full exact test.
; The independent oracle count is also the fail-loud enumeration cap.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-{context_id}-state)
            {context_id} WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index {concept_count}))
       (and
         (== (size-atom $intents) {concept_count})
         (wm-fca-same-set?
           $intents (wm-fca-{context_id}-oracle-intents)))))
   True)
"""


def render_native_basis_test(receipt: dict[str, object]) -> str:
    context_id = require_string(receipt["context_id"], "context_id")
    basis_count = int(receipt["canonical_basis_count"])
    logical_closure_count = exact_basis_logical_closure_count(receipt)
    return f"""!(import! &self ./{context_id}_context.metta)

; This scale-ladder gate isolates native Duquenne-Guigues basis construction.
; Independent oracle counts bound both logical-closure traversal and output.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-{context_id}-state)
            {context_id} WMFCAExactStatusGate))
     (let $basis
          (eval
            (wm-fca-index-canonical-basis-native
              $index {logical_closure_count} {basis_count}))
       (and
         (== (size-atom $basis) {basis_count})
         (and
           (wm-fca-same-set?
             $basis (wm-fca-{context_id}-oracle-basis))
           (wm-fca-index-all-implications-hold? $index $basis)))))
   True)
"""


def render_native_lattice_test(receipt: dict[str, object]) -> str:
    context_id = require_string(receipt["context_id"], "context_id")
    concept_count = int(receipt["concept_count"])
    cover_count = int(receipt["cover_count"])
    return f"""!(import! &self ./{context_id}_context.metta)

; One native intent enumeration feeds typed concepts and exact Hasse covers.
; This isolates lattice parity from basis and state-update checks.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-{context_id}-state)
            {context_id} WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index {concept_count}))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $covers
              (eval
                (wm-fca-covers-from-intents-native
                  $intents {concept_count} {cover_count}))
           (and
             (and
               (== (size-atom $concepts) {concept_count})
               (wm-fca-same-set?
                 $concepts (wm-fca-{context_id}-oracle-concepts))
             )
             (and
               (== (size-atom $covers) {cover_count})
               (wm-fca-same-set?
                 $covers (wm-fca-{context_id}-oracle-covers))))))))
   True)
"""


def render_state_update_test(receipt: dict[str, object]) -> str:
    context_id = require_string(receipt["context_id"], "context_id")
    examples = require_mapping(receipt["examples"], "examples")
    true_cell = symbol_list(examples["true_cell"], "examples.true_cell")
    false_cell = optional_symbol_list(
        examples.get("false_cell"), "examples.false_cell"
    )
    if len(true_cell) != 2 or (false_cell is not None and len(false_cell) != 2):
        raise ValueError("cell examples must contain object and attribute symbols")
    object_symbols = receipt_symbols(receipt, "objects", "object_symbols")
    attribute_symbols = receipt_symbols(
        receipt, "attributes", "attribute_symbols"
    )
    observation_count = len(object_symbols) * len(attribute_symbols)
    source, group, _, _ = receipt_source_metadata(receipt)
    true_stamp = (
        f"{context_id}-cell-{object_symbols.index(true_cell[0]):03d}-"
        f"{attribute_symbols.index(true_cell[1]):03d}"
    )
    missing_cell = false_cell if false_cell is not None else true_cell
    false_checks = ""
    if false_cell is not None:
        false_stamp = (
            f"{context_id}-cell-{object_symbols.index(false_cell[0]):03d}-"
            f"{attribute_symbols.index(false_cell[1]):03d}"
        )
        false_checks = f"""!(assertEqual
   (wm-fca-cell-status
     (wm-fca-{context_id}-state) {context_id} {false_cell[0]} {false_cell[1]})
   WMFalse)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-{context_id}-state) {context_id} {false_cell[0]} {false_cell[1]})
   ((WMFCAObservation
      {context_id} {false_cell[0]} {false_cell[1]} WMFalse
      {false_stamp} {source} {group})))
"""
    return f"""!(import! &self ./{context_id}_context.metta)

; Complete-matrix status and provenance remain explicit before projection.
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-{context_id}-state) {context_id} {true_cell[0]} {true_cell[1]})
   WMTrue)
{false_checks}!(assertEqual
   (wm-fca-cell-status
     (wm-fca-{context_id}-state) another-context
     {missing_cell[0]} {missing_cell[1]})
   WMMissing)
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-{context_id}-state)
              (wm-fca-{context_id}-state))))
     (size-atom $observations))
   {observation_count})

; Forgetting makes the cell missing; remembering its exact observation restores
; both the query and the freshly compiled finite context.
(= (wm-fca-{context_id}-update-test-forgotten)
   (wm-fca-forget
     (wm-fca-{context_id}-state) (WMFCAScopeStamp {true_stamp})))
(= (wm-fca-{context_id}-update-test-restored)
   (wm-fca-remember
     (wm-fca-{context_id}-update-test-forgotten)
     (WMFCAObservation
       {context_id} {true_cell[0]} {true_cell[1]} WMTrue
       {true_stamp} {source} {group})))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-{context_id}-update-test-forgotten)
     {context_id} {true_cell[0]} {true_cell[1]})
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-{context_id}-update-test-restored)
     {context_id} {true_cell[0]} {true_cell[1]})
   WMTrue)
!(assertEqual
   (let $restored-state
        (eval (wm-fca-{context_id}-update-test-restored))
     (let $original-index
          (eval
            (wm-fca-build-index
              (wm-fca-{context_id}-state)
              {context_id} WMFCAExactStatusGate))
       (let $restored-index
            (eval
              (wm-fca-build-index
                $restored-state
                {context_id} WMFCAExactStatusGate))
         (wm-fca-same-set?
           (wm-fca-index-columns $original-index)
           (wm-fca-index-columns $restored-index)))))
   True)
"""


def render_revision_test(receipt: dict[str, object]) -> str:
    context_id = require_string(receipt["context_id"], "context_id")
    observation_count = int(receipt["object_count"]) * int(
        receipt["attribute_count"]
    )
    return f"""!(import! &self ./{context_id}_context.metta)

; Identical provenance-bearing chunks revise idempotently at scale.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-{context_id}-state)
              (wm-fca-{context_id}-state))))
     (size-atom $observations))
   {observation_count})
"""


def render_recompute_test(receipt: dict[str, object]) -> str:
    context_id = require_string(receipt["context_id"], "context_id")
    examples = require_mapping(receipt["examples"], "examples")
    true_cell = symbol_list(examples["true_cell"], "examples.true_cell")
    object_symbols = receipt_symbols(receipt, "objects", "object_symbols")
    attribute_symbols = receipt_symbols(
        receipt, "attributes", "attribute_symbols"
    )
    source, group, _, _ = receipt_source_metadata(receipt)
    stamp = (
        f"{context_id}-cell-{object_symbols.index(true_cell[0]):03d}-"
        f"{attribute_symbols.index(true_cell[1]):03d}"
    )
    return f"""!(import! &self ./{context_id}_context.metta)

(= (wm-fca-{context_id}-recompute-forgotten)
   (wm-fca-forget
     (wm-fca-{context_id}-state) (WMFCAScopeStamp {stamp})))
(= (wm-fca-{context_id}-recompute-restored)
   (wm-fca-remember
     (wm-fca-{context_id}-recompute-forgotten)
     (WMFCAObservation
       {context_id} {true_cell[0]} {true_cell[1]} WMTrue
       {stamp} {source} {group})))

; The incremental forget/remember sequence and fresh compilation agree exactly.
!(assertEqual
   (let $restored-state
        (eval (wm-fca-{context_id}-recompute-restored))
     (let $original-index
          (eval
            (wm-fca-build-index
              (wm-fca-{context_id}-state)
              {context_id} WMFCAExactStatusGate))
       (let $restored-index
            (eval
              (wm-fca-build-index
                $restored-state
                {context_id} WMFCAExactStatusGate))
         (wm-fca-same-set?
           (wm-fca-index-columns $original-index)
           (wm-fca-index-columns $restored-index)))))
   True)
"""


def render_forget_remember_test(receipt: dict[str, object]) -> str:
    context_id = require_string(receipt["context_id"], "context_id")
    examples = require_mapping(receipt["examples"], "examples")
    true_cell = symbol_list(examples["true_cell"], "examples.true_cell")
    object_symbols = receipt_symbols(receipt, "objects", "object_symbols")
    attribute_symbols = receipt_symbols(
        receipt, "attributes", "attribute_symbols"
    )
    observation_count = len(object_symbols) * len(attribute_symbols)
    source, group, _, _ = receipt_source_metadata(receipt)
    stamp = (
        f"{context_id}-cell-{object_symbols.index(true_cell[0]):03d}-"
        f"{attribute_symbols.index(true_cell[1]):03d}"
    )
    return f"""!(import! &self ./{context_id}_context.metta)

; Materialize each immutable transition once and check both cardinality and
; four-valued query behavior before any FCA compilation.
!(assertEqual
   (let $forgotten
        (eval
          (wm-fca-forget
            (wm-fca-{context_id}-state) (WMFCAScopeStamp {stamp})))
     (let $restored
          (eval
            (wm-fca-remember
              $forgotten
              (WMFCAObservation
                {context_id} {true_cell[0]} {true_cell[1]} WMTrue
                {stamp} {source} {group})))
       (let $forgotten-observations
            (eval (wm-fca-state-observations $forgotten))
         (let $restored-observations
              (eval (wm-fca-state-observations $restored))
           (let $forgotten-status
                (eval
                  (wm-fca-cell-status
                    $forgotten {context_id}
                    {true_cell[0]} {true_cell[1]}))
             (let $restored-status
                  (eval
                    (wm-fca-cell-status
                      $restored {context_id}
                      {true_cell[0]} {true_cell[1]}))
               (and
                 (and
                   (== (size-atom $forgotten-observations)
                       {observation_count - 1})
                   (== $forgotten-status WMMissing))
                 (and
                   (== (size-atom $restored-observations)
                       {observation_count})
                   (== $restored-status WMTrue)))))))))
   True)
"""


def render_semantic_queries_test(receipt: dict[str, object]) -> str:
    """Render bounded WM status, closure, implication, and explanation gates."""
    context_id = require_string(receipt["context_id"], "context_id")
    examples = require_mapping(receipt["examples"], "examples")
    true_cell = symbol_list(examples["true_cell"], "examples.true_cell")
    false_cell = optional_symbol_list(
        examples.get("false_cell"), "examples.false_cell"
    )
    if len(true_cell) != 2 or (false_cell is not None and len(false_cell) != 2):
        raise ValueError("cell examples must contain object and attribute symbols")
    raw_nonclosed = optional_symbol_list(
        examples.get("nonclosed_candidate"), "examples.nonclosed_candidate"
    )
    raw_nonclosed_closure = optional_symbol_list(
        examples.get("nonclosed_closure"), "examples.nonclosed_closure"
    )
    if (raw_nonclosed is None) != (raw_nonclosed_closure is None):
        raise ValueError(
            "nonclosed candidate and closure must either both be present or both be null"
        )
    closed = metta_list(
        symbol_list(examples["closed_candidate"], "examples.closed_candidate")
    )
    positive = render_implication(
        examples["positive_implication"], "positive implication"
    )
    raw_negative = examples.get("negative_implication")
    negative = (
        render_implication(raw_negative, "negative implication")
        if raw_negative is not None
        else None
    )
    object_symbols = receipt_symbols(receipt, "objects", "object_symbols")
    attribute_symbols = receipt_symbols(
        receipt, "attributes", "attribute_symbols"
    )
    observation_count = len(object_symbols) * len(attribute_symbols)
    source, group, _, matrix_label = receipt_source_metadata(receipt)
    missing_cell = false_cell if false_cell is not None else true_cell
    false_status_check = ""
    false_explanation = ""
    if false_cell is not None:
        false_stamp = (
            f"{context_id}-cell-{object_symbols.index(false_cell[0]):03d}-"
            f"{attribute_symbols.index(false_cell[1]):03d}"
        )
        false_status_check = f"""!(assertEqual
   (wm-fca-cell-status
     (wm-fca-{context_id}-state) {context_id} {false_cell[0]} {false_cell[1]})
   WMFalse)
"""
        false_explanation = f"""!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-{context_id}-state) {context_id} {false_cell[0]} {false_cell[1]})
   ((WMFCAObservation
      {context_id} {false_cell[0]} {false_cell[1]} WMFalse
      {false_stamp} {source} {group})))
"""
    negative_check = (
        f"(not (wm-fca-index-implication-holds? $index {negative}))"
        if negative is not None
        else "True"
    )
    nonclosed_check = (
        "True"
        if raw_nonclosed is None
        else (
            f"(== (wm-fca-index-closure $index {metta_list(raw_nonclosed)}) "
            f"{metta_list(raw_nonclosed_closure or [])})"
        )
    )
    return f"""!(import! &self ./{context_id}_context.metta)

; Bounded semantic checks remain separate from potentially expensive complete
; enumeration.  In this {matrix_label}, every matrix cell is observed.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-{context_id}-state)))
     (size-atom $observations))
   {observation_count})
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-{context_id}-state) {context_id} {true_cell[0]} {true_cell[1]})
   WMTrue)
{false_status_check}!(assertEqual
   (wm-fca-cell-status
     (wm-fca-{context_id}-state) another-context
     {missing_cell[0]} {missing_cell[1]})
   WMMissing)
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-{context_id}-state)
            {context_id} WMFCAExactStatusGate))
     (and
       {nonclosed_check}
       (and
         (== (wm-fca-index-closure $index {closed}) {closed})
         (and
           (wm-fca-index-implication-holds? $index {positive})
           {negative_check}))))
   True)
{false_explanation}"""


def render_test(receipt: dict[str, object]) -> str:
    context_id = require_string(receipt["context_id"], "context_id")
    examples = require_mapping(receipt["examples"], "examples")
    true_cell = symbol_list(examples["true_cell"], "examples.true_cell")
    false_cell = optional_symbol_list(
        examples.get("false_cell"), "examples.false_cell"
    )
    if len(true_cell) != 2 or (false_cell is not None and len(false_cell) != 2):
        raise ValueError("cell examples must contain object and attribute symbols")
    raw_nonclosed = optional_symbol_list(
        examples.get("nonclosed_candidate"), "examples.nonclosed_candidate"
    )
    raw_nonclosed_closure = optional_symbol_list(
        examples.get("nonclosed_closure"), "examples.nonclosed_closure"
    )
    if (raw_nonclosed is None) != (raw_nonclosed_closure is None):
        raise ValueError(
            "nonclosed candidate and closure must either both be present or both be null"
        )
    closed = metta_list(
        symbol_list(examples["closed_candidate"], "examples.closed_candidate")
    )
    positive = render_implication(examples["positive_implication"], "positive implication")
    raw_negative = examples.get("negative_implication")
    negative = (
        render_implication(raw_negative, "negative implication")
        if raw_negative is not None
        else None
    )
    object_count = int(receipt["object_count"])
    attribute_count = int(receipt["attribute_count"])
    observation_count = object_count * attribute_count
    concept_count = int(receipt["concept_count"])
    basis_count = int(receipt["canonical_basis_count"])
    cover_count = int(receipt["cover_count"])
    logical_closure_count = exact_basis_logical_closure_count(receipt)
    source, group, _, matrix_label = receipt_source_metadata(receipt)
    object_symbols = receipt_symbols(receipt, "objects", "object_symbols")
    attribute_symbols = receipt_symbols(
        receipt, "attributes", "attribute_symbols"
    )
    true_object_index = object_symbols.index(true_cell[0])
    true_attribute_index = attribute_symbols.index(true_cell[1])
    true_stamp = f"{context_id}-cell-{true_object_index:03d}-{true_attribute_index:03d}"
    missing_cell = false_cell if false_cell is not None else true_cell
    false_status_check = ""
    false_explanation = ""
    if false_cell is not None:
        false_stamp = (
            f"{context_id}-cell-{object_symbols.index(false_cell[0]):03d}-"
            f"{attribute_symbols.index(false_cell[1]):03d}"
        )
        false_status_check = f"""!(assertEqual
   (wm-fca-cell-status
     (wm-fca-{context_id}-state) {context_id} {false_cell[0]} {false_cell[1]})
   WMFalse)
"""
        false_explanation = f"""; Explanations retain the exact negative observation and its provenance.
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-{context_id}-state) {context_id} {false_cell[0]} {false_cell[1]})
   ((WMFCAObservation
      {context_id} {false_cell[0]} {false_cell[1]} WMFalse
      {false_stamp} {source} {group})))

"""
    else:
        false_explanation = """; This full one-attribute relation has no false in-domain cell.  Missingness
; is still tested by querying the same coordinates in another context.

"""
    negative_check = (
        f"(not (wm-fca-index-implication-holds? $index {negative}))"
        if negative is not None
        else "True"
    )
    state_nonclosed_check = (
        ""
        if raw_nonclosed is None
        else f"""!(assertEqual
   (wm-fca-closure
     (wm-fca-{context_id}-state) {context_id} {metta_list(raw_nonclosed)})
   {metta_list(raw_nonclosed_closure or [])})

"""
    )
    index_nonclosed_check = (
        "True"
        if raw_nonclosed is None
        else (
            f"(== (wm-fca-index-closure $index {metta_list(raw_nonclosed)}) "
            f"{metta_list(raw_nonclosed_closure or [])})"
        )
    )

    return f"""!(import! &self ./{context_id}_context.metta)

; In this {matrix_label}, every matrix cell is observed rather than missing.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-{context_id}-state)))
     (size-atom $observations))
   {observation_count})
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-{context_id}-state) {context_id} {true_cell[0]} {true_cell[1]})
   WMTrue)
{false_status_check}!(assertEqual
   (wm-fca-cell-status
     (wm-fca-{context_id}-state) another-context
     {missing_cell[0]} {missing_cell[1]})
   WMMissing)
{state_nonclosed_check}

; Compile the exact projection once.  Native Next-Closure is capped at the
; independently established concept count, so a disagreement fails loudly
; rather than returning a partial lattice.  Concepts and covers consume that
; single result, while the canonical-basis fold carries its own prior closures.
; The lexical scope preserves computed data without turning large expressions
; back into executable surface syntax.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-{context_id}-state)
            {context_id} WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index {concept_count}))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $basis
              (eval
                (wm-fca-index-canonical-basis-native
                  $index {logical_closure_count} {basis_count}))
           (let $covers
                (eval
                  (wm-fca-covers-from-intents-native
                    $intents {concept_count} {cover_count}))
             (and
               {index_nonclosed_check}
               (and
                 (== (wm-fca-index-closure $index {closed}) {closed})
                 (and
                   (and
                     (== (size-atom $intents) {concept_count})
                     (wm-fca-same-set?
                       $intents (wm-fca-{context_id}-oracle-intents)))
                   (and
                     (and
                       (== (size-atom $concepts) {concept_count})
                       (wm-fca-same-set?
                         $concepts (wm-fca-{context_id}-oracle-concepts)))
                     (and
                       (and
                         (== (size-atom $basis) {basis_count})
                         (and
                           (wm-fca-same-set?
                             $basis (wm-fca-{context_id}-oracle-basis))
                           (wm-fca-index-all-implications-hold?
                             $index $basis)))
                       (and
                         (wm-fca-index-implication-holds? $index {positive})
                         (and
                           {negative_check}
                           (and
                             (== (size-atom $covers) {cover_count})
                             (wm-fca-same-set?
                               $covers
                               (wm-fca-{context_id}-oracle-covers)))))))))))))))
   True)

{false_explanation}
; Revision is idempotent by provenance-bearing observation identity.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-{context_id}-state)
              (wm-fca-{context_id}-state))))
     (size-atom $observations))
   {observation_count})

; Forgetting one true cell exposes missingness; restoring the same observation
; reconstructs the exact original indexed incidence from fresh state.
(= (wm-fca-{context_id}-without-example)
   (wm-fca-forget
     (wm-fca-{context_id}-state) (WMFCAScopeStamp {true_stamp})))
(= (wm-fca-{context_id}-restored-example)
   (wm-fca-remember
     (wm-fca-{context_id}-without-example)
     (WMFCAObservation
       {context_id} {true_cell[0]} {true_cell[1]} WMTrue
       {true_stamp} {source} {group})))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-{context_id}-without-example)
     {context_id} {true_cell[0]} {true_cell[1]})
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-{context_id}-restored-example)
     {context_id} {true_cell[0]} {true_cell[1]})
   WMTrue)
!(assertEqual
   (let $original-index
        (eval
          (wm-fca-build-index
            (wm-fca-{context_id}-state)
            {context_id} WMFCAExactStatusGate))
     (let $restored-index
          (eval
            (wm-fca-build-index
              (wm-fca-{context_id}-restored-example)
              {context_id} WMFCAExactStatusGate))
       (wm-fca-same-set?
         (wm-fca-index-columns $original-index)
         (wm-fca-index-columns $restored-index))))
   True)
"""


def write_generated(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--receipt", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()

    receipt = require_mapping(
        json.loads(args.receipt.read_text(encoding="utf-8")), "receipt"
    )
    validate_receipt(receipt)
    context_id = require_string(receipt["context_id"], "context_id")
    context_path = args.output_dir / f"{context_id}_context.metta"
    test_path = args.output_dir / f"test_{context_id}_exact.metta"
    expected_path = args.output_dir / f"test_{context_id}_exact.expected"
    intents_test_path = args.output_dir / f"test_{context_id}_native_intents.metta"
    intents_expected_path = (
        args.output_dir / f"test_{context_id}_native_intents.expected"
    )
    basis_test_path = args.output_dir / f"test_{context_id}_native_basis.metta"
    basis_expected_path = args.output_dir / f"test_{context_id}_native_basis.expected"
    lattice_test_path = args.output_dir / f"test_{context_id}_native_lattice.metta"
    lattice_expected_path = (
        args.output_dir / f"test_{context_id}_native_lattice.expected"
    )
    update_test_path = args.output_dir / f"test_{context_id}_state_updates.metta"
    update_expected_path = (
        args.output_dir / f"test_{context_id}_state_updates.expected"
    )
    revision_test_path = args.output_dir / f"test_{context_id}_revision.metta"
    revision_expected_path = args.output_dir / f"test_{context_id}_revision.expected"
    recompute_test_path = args.output_dir / f"test_{context_id}_recompute.metta"
    recompute_expected_path = args.output_dir / f"test_{context_id}_recompute.expected"
    forget_test_path = args.output_dir / f"test_{context_id}_forget_remember.metta"
    forget_expected_path = (
        args.output_dir / f"test_{context_id}_forget_remember.expected"
    )
    semantic_test_path = args.output_dir / f"test_{context_id}_semantic_queries.metta"
    semantic_expected_path = (
        args.output_dir / f"test_{context_id}_semantic_queries.expected"
    )

    context_text = render_context(receipt)
    test_text = render_test(receipt)
    intents_test_text = render_native_intents_test(receipt)
    basis_test_text = render_native_basis_test(receipt)
    lattice_test_text = render_native_lattice_test(receipt)
    update_test_text = render_state_update_test(receipt)
    revision_test_text = render_revision_test(receipt)
    recompute_test_text = render_recompute_test(receipt)
    forget_test_text = render_forget_remember_test(receipt)
    semantic_test_text = render_semantic_queries_test(receipt)
    success_count = sum(
        1 for line in test_text.splitlines() if line.lstrip().startswith("!(")
    )
    intents_success_count = sum(
        1
        for line in intents_test_text.splitlines()
        if line.lstrip().startswith("!(")
    )
    basis_success_count = sum(
        1
        for line in basis_test_text.splitlines()
        if line.lstrip().startswith("!(")
    )
    lattice_success_count = sum(
        1
        for line in lattice_test_text.splitlines()
        if line.lstrip().startswith("!(")
    )
    update_success_count = sum(
        1
        for line in update_test_text.splitlines()
        if line.lstrip().startswith("!(")
    )
    revision_success_count = sum(
        1
        for line in revision_test_text.splitlines()
        if line.lstrip().startswith("!(")
    )
    recompute_success_count = sum(
        1
        for line in recompute_test_text.splitlines()
        if line.lstrip().startswith("!(")
    )
    forget_success_count = sum(
        1
        for line in forget_test_text.splitlines()
        if line.lstrip().startswith("!(")
    )
    semantic_success_count = sum(
        1
        for line in semantic_test_text.splitlines()
        if line.lstrip().startswith("!(")
    )
    write_generated(context_path, context_text)
    write_generated(test_path, test_text)
    write_generated(expected_path, "[()]\n" * success_count)
    write_generated(intents_test_path, intents_test_text)
    write_generated(intents_expected_path, "[()]\n" * intents_success_count)
    write_generated(basis_test_path, basis_test_text)
    write_generated(basis_expected_path, "[()]\n" * basis_success_count)
    write_generated(lattice_test_path, lattice_test_text)
    write_generated(lattice_expected_path, "[()]\n" * lattice_success_count)
    write_generated(update_test_path, update_test_text)
    write_generated(update_expected_path, "[()]\n" * update_success_count)
    write_generated(revision_test_path, revision_test_text)
    write_generated(revision_expected_path, "[()]\n" * revision_success_count)
    write_generated(recompute_test_path, recompute_test_text)
    write_generated(recompute_expected_path, "[()]\n" * recompute_success_count)
    write_generated(forget_test_path, forget_test_text)
    write_generated(forget_expected_path, "[()]\n" * forget_success_count)
    write_generated(semantic_test_path, semantic_test_text)
    write_generated(semantic_expected_path, "[()]\n" * semantic_success_count)
    print(
        json.dumps(
            {
                "context": str(context_path),
                "basis_expected": str(basis_expected_path),
                "basis_success_expressions": basis_success_count,
                "basis_test": str(basis_test_path),
                "test": str(test_path),
                "expected": str(expected_path),
                "intents_expected": str(intents_expected_path),
                "intents_test": str(intents_test_path),
                "lattice_expected": str(lattice_expected_path),
                "lattice_success_expressions": lattice_success_count,
                "lattice_test": str(lattice_test_path),
                "update_expected": str(update_expected_path),
                "update_success_expressions": update_success_count,
                "update_test": str(update_test_path),
                "revision_expected": str(revision_expected_path),
                "revision_success_expressions": revision_success_count,
                "revision_test": str(revision_test_path),
                "recompute_expected": str(recompute_expected_path),
                "recompute_success_expressions": recompute_success_count,
                "recompute_test": str(recompute_test_path),
                "forget_expected": str(forget_expected_path),
                "forget_success_expressions": forget_success_count,
                "forget_test": str(forget_test_path),
                "semantic_expected": str(semantic_expected_path),
                "semantic_success_expressions": semantic_success_count,
                "semantic_test": str(semantic_test_path),
                "intents_success_expressions": intents_success_count,
                "success_expressions": success_count,
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
