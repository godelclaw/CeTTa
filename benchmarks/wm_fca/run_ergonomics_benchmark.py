#!/usr/bin/env python3
"""Run the small, descriptive WM/FCA ergonomics campaign.

This is deliberately not a full scientific benchmark.  It measures three
already-validated golden fixtures end to end and records enough hashes and
environment metadata to identify exactly what ran.  Every invocation is
checked byte-for-byte against its golden output before a timing is retained.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import resource
import statistics
import subprocess
import sys
import time
from typing import Any


class ErgonomicsError(ValueError):
    """The protocol or an executed measurement failed validation."""


def sha256(path: Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(block)
    return value.hexdigest()


def load_object(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ErgonomicsError(f"cannot read JSON object {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise ErgonomicsError(f"expected JSON object in {path}")
    return value


def relative_file(root: Path, value: Any, label: str) -> Path:
    if not isinstance(value, str) or not value:
        raise ErgonomicsError(f"{label} must be a nonempty relative path")
    relative = Path(value)
    if relative.is_absolute():
        raise ErgonomicsError(f"{label} must be relative")
    resolved = (root / relative).resolve()
    try:
        resolved.relative_to(root)
    except ValueError as exc:
        raise ErgonomicsError(f"{label} escapes the repository root") from exc
    if not resolved.is_file():
        raise ErgonomicsError(f"missing {label}: {relative}")
    return resolved


def require_positive_int(value: Any, label: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
        raise ErgonomicsError(f"{label} must be a positive integer")
    return value


def peak_child_rss_kib() -> int:
    value = resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss
    if sys.platform == "darwin":
        return int(value / 1024)
    return int(value)


def execute_checked(
    root: Path,
    binary: Path,
    profile: str,
    language: str,
    program: Path,
    expected: bytes,
) -> float:
    started = time.perf_counter()
    process = subprocess.run(
        [
            str(binary),
            "--profile",
            profile,
            "--lang",
            language,
            str(program),
        ],
        cwd=root,
        check=False,
        capture_output=True,
    )
    elapsed = time.perf_counter() - started
    if process.returncode != 0:
        stderr = process.stderr.decode("utf-8", errors="replace")[-1000:]
        raise ErgonomicsError(
            f"{program.name} exited {process.returncode}: {stderr}"
        )
    if process.stderr:
        stderr = process.stderr.decode("utf-8", errors="replace")[-1000:]
        raise ErgonomicsError(f"{program.name} wrote to stderr: {stderr}")
    if process.stdout != expected:
        raise ErgonomicsError(f"{program.name} disagrees with its golden output")
    return elapsed


def source_metrics(path: Path) -> dict[str, int | str]:
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    return {
        "path": path.name,
        "sha256": sha256(path),
        "bytes": path.stat().st_size,
        "lines": len(lines),
        "type_declarations": sum(line.startswith("(: ") for line in lines),
        "equation_definitions": sum(line.startswith("(= ") for line in lines),
    }


def render_receipt(
    root: Path,
    binary: Path,
    protocol_path: Path,
    repetitions: int,
) -> dict[str, Any]:
    runner = Path(__file__).resolve()
    try:
        runner_relative = runner.relative_to(root)
    except ValueError as exc:
        raise ErgonomicsError("runner must be inside the repository") from exc
    protocol = load_object(protocol_path)
    if protocol.get("schema") != "wm-fca-ergonomics-protocol-v1":
        raise ErgonomicsError("unexpected ergonomics protocol schema")
    profile = protocol.get("profile")
    language = protocol.get("language")
    if not isinstance(profile, str) or not isinstance(language, str):
        raise ErgonomicsError("protocol profile and language must be strings")
    warmups = require_positive_int(
        protocol.get("warmup_runs_per_case"), "warmup_runs_per_case"
    )
    cases = protocol.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ErgonomicsError("protocol cases must be a nonempty array")
    coverage = protocol.get("certificate_coverage")
    if (
        not isinstance(coverage, list)
        or not coverage
        or any(not isinstance(item, str) or not item for item in coverage)
        or len(set(coverage)) != len(coverage)
    ):
        raise ErgonomicsError("certificate_coverage must contain unique names")

    measurements: list[dict[str, Any]] = []
    seen_case_ids: set[str] = set()
    for index, case_value in enumerate(cases):
        if not isinstance(case_value, dict):
            raise ErgonomicsError(f"case {index} must be an object")
        case_id = case_value.get("id")
        unit = case_value.get("work_unit")
        interpretation = case_value.get("interpretation")
        if not all(isinstance(value, str) and value for value in [case_id, unit, interpretation]):
            raise ErgonomicsError(f"case {index} has invalid descriptive fields")
        if case_id in seen_case_ids:
            raise ErgonomicsError(f"duplicate case id: {case_id}")
        seen_case_ids.add(case_id)
        count = require_positive_int(case_value.get("work_unit_count"), f"{case_id}.work_unit_count")
        program = relative_file(root, case_value.get("program"), f"{case_id}.program")
        expected_path = relative_file(root, case_value.get("expected"), f"{case_id}.expected")
        expected = expected_path.read_bytes()

        for _ in range(warmups):
            execute_checked(root, binary, profile, language, program, expected)
        samples = [
            execute_checked(root, binary, profile, language, program, expected)
            for _ in range(repetitions)
        ]
        median = statistics.median(samples)
        measurements.append(
            {
                "id": case_id,
                "program": str(program.relative_to(root)),
                "program_sha256": sha256(program),
                "expected": str(expected_path.relative_to(root)),
                "expected_sha256": sha256(expected_path),
                "golden_output_bytes": len(expected),
                "golden_output_rows": len(expected.splitlines()),
                "work_unit": unit,
                "work_unit_count": count,
                "interpretation": interpretation,
                "warmup_runs": warmups,
                "measured_runs": repetitions,
                "elapsed_seconds": {
                    "minimum": min(samples),
                    "median": median,
                    "maximum": max(samples),
                },
                "end_to_end_work_units_per_second_at_median": count / median,
                "all_runs_golden_equal": True,
                "campaign_peak_child_rss_kib_after_case": peak_child_rss_kib(),
            }
        )

    query_oracle = load_object(
        root / "benchmarks/wm_fca/scale_oracles/bob_ross_query_oracle.json"
    )
    object_count = require_positive_int(query_oracle.get("object_count"), "object_count")
    attribute_count = require_positive_int(
        query_oracle.get("attribute_count"), "attribute_count"
    )
    true_cells = require_positive_int(query_oracle.get("true_cell_count"), "true_cell_count")
    false_cells = require_positive_int(query_oracle.get("false_cell_count"), "false_cell_count")
    query_count = require_positive_int(query_oracle.get("query_count"), "query_count")
    uname = os.uname()
    measured_peak_kib = peak_child_rss_kib()
    return {
        "schema": "wm-fca-ergonomics-receipt-v1",
        "measurement_kind": "descriptive_microbenchmark",
        "measurement_scope": protocol.get("measurement_scope"),
        "protocol": str(protocol_path.relative_to(root)),
        "protocol_sha256": sha256(protocol_path),
        "runner": {
            "path": str(runner_relative),
            "sha256": sha256(runner),
        },
        "binary": {
            "sha256": sha256(binary),
            "bytes": binary.stat().st_size,
            "profile": profile,
            "language": language,
        },
        "environment": {
            "system": uname.sysname,
            "release": uname.release,
            "machine": uname.machine,
            "logical_cpu_count": os.cpu_count(),
            "python": sys.version.split()[0],
        },
        "scale_context": {
            "objects": object_count,
            "attributes": attribute_count,
            "observed_cells": true_cells + false_cells,
            "query_count": query_count,
            "oracle_sha256": sha256(
                root / "benchmarks/wm_fca/scale_oracles/bob_ross_query_oracle.json"
            ),
        },
        "wm_fca_library": source_metrics(root / "lib/lib_wm_fca.metta"),
        "certificate_coverage": coverage,
        "measurements": measurements,
        "campaign_peak_child_rss_kib": measured_peak_kib,
        "interpretation_guard": (
            "Timings include startup and parsing, are machine-specific, and do not "
            "support a performance claim against specialized FCA engines."
        ),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, required=True)
    parser.add_argument("--cetta", type=Path, required=True)
    parser.add_argument("--protocol", type=Path, required=True)
    parser.add_argument("--repetitions", type=int, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    root = args.repo_root.resolve()
    binary = args.cetta.resolve()
    protocol = args.protocol.resolve()
    if not root.is_dir() or not binary.is_file() or not protocol.is_file():
        raise ErgonomicsError("repository, executable, and protocol must exist")
    try:
        protocol.relative_to(root)
    except ValueError as exc:
        raise ErgonomicsError("protocol must be inside the repository") from exc
    repetitions = require_positive_int(args.repetitions, "repetitions")
    receipt = render_receipt(root, binary, protocol, repetitions)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
