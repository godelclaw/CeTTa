"""Count the user-space instructions a CeTTa program runs, with perf stat.

A count does not depend on the machine's load, so one run at each size
decides a growth check, and small sizes suffice to show the growth.
"""
import os
import subprocess
import sys
import tempfile


def instructions(cetta, text, expected=None, options=("--lang", "petta"), timeout=600):
    """Run TEXT with CETTA and return its user-space instruction count.

    The run must exit 0 and, when EXPECTED is given, print exactly those
    whitespace-separated answers; otherwise the check fails here."""
    with tempfile.TemporaryDirectory(prefix="cetta-instructions-") as directory:
        path = os.path.join(directory, "program.metta")
        counts = path + ".perf"
        with open(path, "w") as handle:
            handle.write(text)
        result = subprocess.run(
            ["perf", "stat", "-x,", "-e", "instructions:u", "-o", counts, "--",
             cetta, *options, path],
            capture_output=True, text=True, timeout=timeout)
        answers = result.stdout.split()
        if result.returncode != 0 or (expected is not None and answers != expected):
            print(f"FAIL: exit {result.returncode}, answers {answers[:8]} against "
                  f"{expected}; {result.stderr[-300:]}")
            sys.exit(1)
        if os.path.exists(counts):
            with open(counts) as handle:
                for line in handle:
                    fields = line.split(",")
                    if len(fields) > 2 and fields[2].startswith("instructions") \
                            and fields[0].isdigit():
                        return int(fields[0])
    print("FAIL: perf stat gave no instruction count")
    sys.exit(1)


def startup(cetta, options=("--lang", "petta")):
    """The instructions of a run that does nothing but start and add."""
    return instructions(cetta, "!(+ 1 1)\n", None, options)
