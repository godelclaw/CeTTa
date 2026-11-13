#!/usr/bin/env python3
"""fs:size agrees with os.path.getsize in HE, PeTTa and Prime.

Files of 0, 5 and multibyte-text sizes, a symbolic link to one (followed), a
directory and a large sparse file give os.path.getsize's integer. A missing
path and a dangling link give fs:metadata's (fs:failed fs:missing ...), and
a number in place of a path its (fs:failed fs:invalid-argument ...)."""
import os
import subprocess
import sys
import tempfile

DIALECTS = ("he", "petta", "prime")


def answers(binary, dialect, work, paths):
    library = "(library fs)" if dialect == "petta" else "fs"
    profile = [] if dialect == "prime" else ["--profile", "extended"]
    args = [binary, "--lang", dialect, *profile, "-e", f"!(import! &self {library})"]
    for path in paths:
        args += ["-e", f"!(fs:size {path})"]
    proc = subprocess.run(args, cwd=work, capture_output=True, text=True, timeout=60)
    out = [line[1:-1] if line.startswith("[") and line.endswith("]") else line
           for line in proc.stdout.splitlines()[1:]]
    return out


def main():
    binary = os.path.abspath(sys.argv[1])
    failures, checked = [], 0
    with tempfile.TemporaryDirectory(prefix="fs-size-") as work:
        with open(os.path.join(work, "empty"), "wb"):
            pass
        with open(os.path.join(work, "five"), "wb") as handle:
            handle.write(b"hello")
        with open(os.path.join(work, "multi"), "w", encoding="utf-8") as handle:
            handle.write("Δ✓ λ")
        with open(os.path.join(work, "sparse"), "wb") as handle:
            handle.truncate(5 * 2 ** 32 + 3)
        os.symlink("five", os.path.join(work, "link"))
        os.symlink("nowhere", os.path.join(work, "dangling"))
        os.mkdir(os.path.join(work, "dir"))
        sized = ["empty", "five", "multi", "sparse", "link", "dir"]
        wanted = [str(os.path.getsize(os.path.join(work, name))) for name in sized]
        cases = [(f'"{name}"', want) for name, want in zip(sized, wanted)]
        cases += [('"missing"', "(fs:failed fs:missing metadata"),
                  ('"dangling"', "(fs:failed fs:missing metadata"),
                  ("5", "(fs:failed fs:invalid-argument metadata")]
        for dialect in DIALECTS:
            got = answers(binary, dialect, work, [path for path, _ in cases])
            for index, (path, want) in enumerate(cases):
                checked += 1
                value = got[index] if index < len(got) else "(no answer)"
                ok = value.startswith(want) if want.startswith("(") else value == want
                if not ok:
                    failures.append((dialect, path, value, want))
    for dialect, path, value, want in failures[:12]:
        print(f"MISMATCH {dialect} (fs:size {path})\n  got    {value!r}\n  wanted {want!r}")
    print(f"fs-size: {checked} cases in {len(DIALECTS)} dialects, {len(failures)} mismatches")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
