#!/usr/bin/env python3

import csv
import os
import sys
import tempfile
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SUITE_DIR = REPO_ROOT / "benchmarks" / "cafa5_pln"
sys.path.insert(0, str(SUITE_DIR))

from cafa5_suite import (  # noqa: E402
    CeTTaGroupFoldReducer,
    SourceSpec,
    fuse_prediction_files,
)


def main() -> int:
    binary = Path(
        os.environ.get("CETTA_WRAPPED_BIN")
        or (sys.argv[1] if len(sys.argv) > 1 else REPO_ROOT / "cetta")
    ).resolve()
    row_count = int(sys.argv[2]) if len(sys.argv) > 2 else 20_000
    runtime = REPO_ROOT / "runtime"
    runtime.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="cafa5-stream-scale-", dir=runtime) as raw:
        root = Path(raw)
        source = root / "source.tsv"
        with source.open("w", newline="", encoding="utf-8") as stream:
            writer = csv.writer(stream, delimiter="\t", lineterminator="\n")
            for index in range(row_count):
                writer.writerow(("P-SCALE", f"GO:{index + 1:07d}", "0.5"))

        summary = fuse_prediction_files(
            [SourceSpec("scale-source", "scale-group", source)],
            root / "fused.tsv",
            root / "trails.jsonl",
            root / "workspace",
            reducer_backend=CeTTaGroupFoldReducer(
                binary,
                shard_count=1,
                max_shard_packets=row_count,
            ),
        )
        assert summary["input_rows"] == row_count, summary
        assert summary["packet_rows"] == row_count, summary
        assert summary["candidate_rows"] == row_count, summary
        assert summary["differential_oracle"]["status"] == "passed", summary
        assert (
            summary["differential_oracle"]["comparison"]["maximum_absolute_error"]
            == 0.0
        ), summary
        work = root / "workspace" / "reduced-shards" / "0000" / "work"
        assert (work / "stage1.metta").stat().st_size < 4096
        assert (work / "stage1.atom-lines").stat().st_size > row_count * 40
    print(f"CAFA5 atom-line/group-fold scale passed: {row_count} packets")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
