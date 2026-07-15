#!/usr/bin/env python3

import json
import subprocess
import sys
import tempfile
from pathlib import Path


def run(binary: Path, workload: Path) -> str:
    result = subprocess.run(
        [str(binary), "--profile", "he-extended", "--lang", "he", str(workload)],
        cwd=Path(__file__).resolve().parents[1],
        text=True,
        capture_output=True,
        check=True,
    )
    return result.stdout.strip()


def workload(path: Path) -> str:
    return f'''!(collapse
  (group-fold
    (external-merge 2)
    (fs:stream-atom-lines {json.dumps(str(path))})
    0
    $acc
    $item
    (let ($key $value) $item $key)
    (eval (+ $acc 1))))
'''


def main() -> int:
    if len(sys.argv) != 2:
        raise SystemExit("usage: test_atom_line_stream.py CETTA_BINARY")
    binary = Path(sys.argv[1]).resolve()
    runtime = Path(__file__).resolve().parents[1] / "runtime"
    runtime.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="atom-lines-test-", dir=runtime) as raw:
        root = Path(raw)

        long_source = root / "long.atom-lines"
        long_source.write_text(f'(long "{"x" * 131072}")\n', encoding="utf-8")
        long_workload = root / "long.metta"
        long_workload.write_text(workload(long_source), encoding="utf-8")
        output = run(binary, long_workload)
        assert "(group-result long 1 (group-audit 1 " in output, output

        missing_workload = root / "missing.metta"
        missing_workload.write_text(workload(root / "absent.atom-lines"), encoding="utf-8")
        output = run(binary, missing_workload)
        assert "AtomLinesOpenFailed" in output, output
        assert "group-result" not in output, output

        multiple_source = root / "multiple.atom-lines"
        multiple_source.write_text("(a 1) (b 2)\n", encoding="utf-8")
        multiple_workload = root / "multiple.metta"
        multiple_workload.write_text(workload(multiple_source), encoding="utf-8")
        output = run(binary, multiple_workload)
        assert "AtomLinesMultipleAtoms" in output, output
        assert "group-result" not in output, output

    print("atom-line stream long-record and transactional error checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
