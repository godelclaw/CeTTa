#!/usr/bin/env python3
"""Exercise external group-fold cleanup after reducer and I/O failures."""

from __future__ import annotations

import os
from pathlib import Path
import shutil
import subprocess
import sys


def run(binary: Path, repo: Path, source: Path, tmpdir: Path) -> str:
    environment = os.environ.copy()
    environment["TMPDIR"] = str(tmpdir)
    completed = subprocess.run(
        [str(binary), "--profile", "he-extended", "--lang", "he", str(source)],
        cwd=repo,
        env=environment,
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if completed.returncode != 0:
        raise RuntimeError(
            f"CeTTa exited {completed.returncode}: {completed.stderr}"
        )
    return completed.stdout


def main() -> int:
    repo = Path(__file__).resolve().parents[1]
    binary = (Path(sys.argv[1]) if len(sys.argv) > 1 else repo / "cetta").resolve()
    runtime = repo / "runtime" / "group-fold-cleanup"
    runs = runtime / "runs"
    if runs.exists():
        shutil.rmtree(runs)
    runs.mkdir(parents=True)

    reducer_failure = runtime / "reducer-failure.metta"
    items = " ".join(f"(k{i % 5} {i})" for i in range(70))
    reducer_failure.write_text(
        "!(group-fold (external-merge 1) "
        f"(superpose ({items})) 0 $acc $item "
        "(let ($key $value) $item $key) (superpose (0 1)))\n",
        encoding="utf-8",
    )
    output = run(binary, repo, reducer_failure, runs)
    if "ReduceStepMultipleResults" not in output:
        raise AssertionError(f"missing reducer failure: {output[:500]}")
    if list(runs.iterdir()):
        raise AssertionError("temporary runs leaked after reducer failure")

    blocked_tmpdir = runtime / "not-a-directory"
    blocked_tmpdir.write_text("intentional I/O failure fixture\n", encoding="utf-8")
    io_failure = runtime / "io-failure.metta"
    io_failure.write_text(
        "!(group-fold (external-merge 1) (superpose ((a 1))) "
        "0 $acc $item (let ($key $value) $item $key) (eval (+ $acc 1)))\n",
        encoding="utf-8",
    )
    output = run(binary, repo, io_failure, blocked_tmpdir)
    if "GroupFoldExternalIoError" not in output:
        raise AssertionError(f"missing external I/O failure: {output[:500]}")

    print("PASS group-fold external cleanup and I/O failure paths")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, RuntimeError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        raise SystemExit(1)
