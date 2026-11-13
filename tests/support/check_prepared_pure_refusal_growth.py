#!/usr/bin/env python3
"""A refused preparation is recorded once, however often it is asked for.

The single-value preparation of source-context:split? is refused for good,
which does not settle a call that wants an optional value from it. Each such
call compiled, failed and stored the same refusal once more, so the
prepared-call cache grew by one entry per call and each later lookup walked
all of them: n calls took time proportional to n squared. The program makes
4n such calls in PeTTa. Going from n to 8n costs about 8x when the refusal
is recorded once; the duplicates made it about 50x. Times are the child's
CPU seconds, the fastest of three runs at each size."""
import os
import resource
import subprocess
import sys
import tempfile

PROGRAM = """!(import! &self (library lib_source_context))
(= (calls $terms)
   (filter-atom $terms $term
     (case (source-context:split? $term) (((Ctx:Call $name $args) True) ($other False)))))
(= (probe $terms $n $acc)
   (if (== $n 0) $acc (probe $terms (- $n 1) (size-atom (calls $terms)))))
!(probe ((f x) (g y z) w (h)) {n} 0)
"""
SMALL, LARGE = 1000, 8000
LIMIT = 16.0  # an 8x step: one refusal per key is about 8, duplicates about 50
REPEATS = 3


def cpu_seconds(binary, path):
    before = resource.getrusage(resource.RUSAGE_CHILDREN)
    result = subprocess.run([binary, "--lang", "petta", path],
                            capture_output=True, text=True, timeout=600)
    after = resource.getrusage(resource.RUSAGE_CHILDREN)
    answers = result.stdout.split()
    if result.returncode != 0 or answers[-1:] != ["0"]:
        sys.exit("FAIL: prepared refusal growth probe answered %r (status %d): %s"
                 % (answers[-1:], result.returncode, result.stderr.strip()[-400:]))
    return (after.ru_utime - before.ru_utime) + (after.ru_stime - before.ru_stime)


def main():
    if len(sys.argv) != 2:
        sys.exit("usage: check_prepared_pure_refusal_growth.py CETTA")
    binary = os.path.abspath(sys.argv[1])
    times = {}
    with tempfile.TemporaryDirectory(prefix="refusal-growth.") as work:
        for n in (SMALL, LARGE):
            path = os.path.join(work, "probe_%d.metta" % n)
            with open(path, "w") as handle:
                handle.write(PROGRAM.format(n=n))
            times[n] = min(cpu_seconds(binary, path) for _ in range(REPEATS))
    ratio = times[LARGE] / max(times[SMALL], 1e-3)
    detail = "%d calls %.3fs, %d calls %.3fs, ratio %.1f (limit %.0f)" % (
        4 * SMALL, times[SMALL], 4 * LARGE, times[LARGE], ratio, LIMIT)
    if ratio > LIMIT:
        sys.exit("FAIL: a repeated preparation refusal grows the cache: " + detail)
    print("PASS: a repeated preparation refusal is recorded once (" + detail + ")")


if __name__ == "__main__":
    main()
