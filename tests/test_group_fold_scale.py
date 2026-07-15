#!/usr/bin/env python3
"""Deterministic scale ladder for CeTTa's stable external group fold."""

from __future__ import annotations

import argparse
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time


def group_digest(items: list[str]) -> str:
    digest = hashlib.sha256()
    for item in items:
        encoded = item.encode("utf-8")
        digest.update(len(encoded).to_bytes(8, "big"))
        digest.update(encoded)
    return digest.hexdigest()


def build_case(path: Path, size: int, group_count: int, run_size: int) -> str:
    grouped: list[list[str]] = [[] for _ in range(group_count)]
    with path.open("w", encoding="utf-8") as output:
        output.write("!(collapse (group-fold (external-merge ")
        output.write(str(run_size))
        output.write(") (superpose (")
        for ordinal in range(size):
            key = f"k{ordinal % group_count:03d}"
            item = f"({key} {ordinal})"
            grouped[ordinal % group_count].append(item)
            if ordinal:
                output.write(" ")
            if ordinal and ordinal % 16 == 0:
                output.write("\n")
            output.write(item)
        output.write(
            ")) 0 $acc $item "
            "(let ($key $value) $item $key) "
            "(eval (+ $acc 1))))\n"
        )

    results = []
    for group_index, items in enumerate(grouped):
        if not items:
            continue
        key = f"k{group_index:03d}"
        results.append(
            f'(group-result {key} {len(items)} '
            f'(group-audit {len(items)} "{group_digest(items)}"))'
        )
    return "[(" + " ".join(results) + ")]\n"


def run_case(repo: Path, binary: Path, size: int, group_count: int,
             run_size: int) -> tuple[float, int]:
    runtime = repo / "runtime" / "group-fold-scale"
    temp_runs = runtime / "tmp"
    runtime.mkdir(parents=True, exist_ok=True)
    if temp_runs.exists():
        shutil.rmtree(temp_runs)
    temp_runs.mkdir()
    source = runtime / f"scale-{size}.metta"
    expected = build_case(source, size, group_count, run_size)
    environment = os.environ.copy()
    environment["TMPDIR"] = str(temp_runs)
    started = time.monotonic()
    completed = subprocess.run(
        [str(binary), "--profile", "he-extended", "--lang", "he", str(source)],
        cwd=repo,
        env=environment,
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    elapsed = time.monotonic() - started
    if completed.returncode != 0:
        raise RuntimeError(
            f"CeTTa exited {completed.returncode} at n={size}:\n{completed.stderr}"
        )
    if completed.stdout != expected:
        actual_path = runtime / f"scale-{size}.actual"
        expected_path = runtime / f"scale-{size}.expected"
        actual_path.write_text(completed.stdout, encoding="utf-8")
        expected_path.write_text(expected, encoding="utf-8")
        raise AssertionError(
            f"external group fold mismatch at n={size}; "
            f"inspect {actual_path} and {expected_path}"
        )
    leftovers = list(temp_runs.iterdir())
    if leftovers:
        raise AssertionError(
            f"temporary external-merge runs leaked at n={size}: {leftovers[:5]}"
        )
    return elapsed, source.stat().st_size


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--binary", type=Path)
    parser.add_argument("--sizes", type=int, nargs="+", default=[1_000, 100_000])
    parser.add_argument("--groups", type=int, default=97)
    parser.add_argument("--run-size", type=int, default=2_048)
    args = parser.parse_args()
    repo = Path(__file__).resolve().parents[1]
    binary = (args.binary or (repo / "cetta")).resolve()
    if args.groups <= 0 or args.run_size <= 0 or any(size < 0 for size in args.sizes):
        parser.error("sizes must be nonnegative; groups and run-size must be positive")
    for size in args.sizes:
        elapsed, source_bytes = run_case(
            repo, binary, size, args.groups, args.run_size
        )
        print(
            f"PASS group-fold-scale n={size} groups={args.groups} "
            f"run_size={args.run_size} source_bytes={source_bytes} "
            f"elapsed_seconds={elapsed:.3f}"
        )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, RuntimeError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        raise SystemExit(1)
