#!/usr/bin/env python3
"""PeTTa's != answers without starting the embedded Prolog engine.

With SWI-Prolog linked, != is the reference library's bridge
(petta_libpl_standard_not_equal). A runtime that has run no Prolog yet
answers it natively for values that cross to Prolog as the terms they are;
starting SWI only to ask the bridge cost milliseconds and megabytes on the
first use in every process.

Every ordered pair of a value list is asked twice: as written, and after a
call that starts the engine, so that each != then crosses to the bridge. Both
runs must give the same answers, and those must be the truth values computed
here. The run as written must not start the engine: its peak memory stays
within 2 MiB of the same program asking == instead (starting SWI costs about
8 MiB). Single calls run first in a process of their own, as written and
after the engine started, and must give the bridge's answer: those the native
answer leaves to the bridge (a string the bridge reads only to its first NUL,
a big integer, a free variable) and a != in a condition."""
import os
import subprocess
import sys
import tempfile

VALUES = [
    ("a", ("sym", "a")), ("b", ("sym", "b")), ("λ", ("sym", "λ")),
    ("True", ("sym", "true")), ("false", ("sym", "false")),
    ('"a"', ("str", "a")), ('""', ("str", "")), ('"λ"', ("str", "λ")),
    ('"true"', ("str", "true")),
    ("0", ("num", 0)), ("1", ("num", 1)), ("-1", ("num", -1)),
    ("9223372036854775807", ("num", 9223372036854775807)),
    ("0.0", ("num", 0.0)), ("-0.0", ("num", -0.0)), ("1.0", ("num", 1.0)),
    ("2.5", ("num", 2.5)),
    ("()", ("expr", ())), ("(a)", ("expr", (("sym", "a"),))),
    ("(a b)", ("expr", (("sym", "a"), ("sym", "b")))),
    ('("a" 1)', ("expr", (("str", "a"), ("num", 1)))),
    ("(a (b 1.0))", ("expr", (("sym", "a"), ("expr", (("sym", "b"), ("num", 1.0)))))),
    ("(a (b 1))", ("expr", (("sym", "a"), ("expr", (("sym", "b"), ("num", 1)))))),
    ('(a (b "c"))', ("expr", (("sym", "a"), ("expr", (("sym", "b"), ("str", "c")))))),
]

# Single calls, with the bridge's answers.
SINGLE = [
    ('!(!= "a\\u0000b" "a\\u0000c")', "false"),
    ("!(!= 99999999999999999999 99999999999999999999)", "false"),
    ("!(!= 99999999999999999999 1)", "true"),
    ("!(!= $free a)", "true"),
    ("!(if (!= a a) yes no)", "no"),
]

STARTER = "!(term_hash x)\n"


def same(left, right):
    """PeTTa's == on these values: numbers by value, the rest as written."""
    if left[0] == "num" and right[0] == "num":
        return left[1] == right[1]
    if left[0] != right[0]:
        return False
    if left[0] == "expr":
        return len(left[1]) == len(right[1]) and all(
            same(a, b) for a, b in zip(left[1], right[1]))
    return left[1] == right[1]


def run(binary, directory, name, program):
    """The program's answer lines and its peak resident memory in KiB."""
    path = os.path.join(directory, name)
    with open(path, "w") as handle:
        handle.write(program)
    with open(path + ".out", "w") as output:
        child = subprocess.Popen([binary, "--lang", "petta", path],
                                 stdout=output, stderr=subprocess.STDOUT)
        _, status, usage = os.wait4(child.pid, 0)
    with open(path + ".out") as output:
        lines = output.read().splitlines()
    if status != 0:
        sys.exit(f"FAIL: {name} exited with status {status}\n" + "\n".join(lines[-10:]))
    return lines, usage.ru_maxrss


def main():
    binary = os.path.abspath(sys.argv[1])
    pairs = [(l, r) for l in VALUES for r in VALUES]
    sources = [f"!(!= {l[0]} {r[0]})" for l, r in pairs]
    expected = ["false" if same(l[1], r[1]) else "true" for l, r in pairs]
    program = "".join(line + "\n" for line in sources)
    with tempfile.TemporaryDirectory(prefix="petta-neq-") as directory:
        native, native_rss = run(binary, directory, "native.metta", program)
        bridge, _ = run(binary, directory, "bridge.metta", STARTER + program)
        _, equal_rss = run(binary, directory, "equal.metta", program.replace("!(!=", "!(=="))
        bridge = bridge[1:]
        for source, a, b, want in zip(sources, native, bridge, expected):
            if a != b:
                sys.exit(f"FAIL: {source} answers {a} unstarted, {b} through the bridge")
            if a != want:
                sys.exit(f"FAIL: {source} answers {a}, expected {want}")
        if len(native) != len(sources) or len(bridge) != len(sources):
            sys.exit(f"FAIL: {len(native)} and {len(bridge)} answers for {len(sources)} calls")
        growth = native_rss - equal_rss
        if growth > 2048:
            sys.exit(f"FAIL: asking != raises peak memory by {growth} KiB over =="
                     " (the engine started)")
        for index, (line, want) in enumerate(SINGLE):
            for prefix in ("", STARTER):
                got, _ = run(binary, directory, f"single-{index}.metta", prefix + line + "\n")
                got = got[1:] if prefix else got
                if got != [want]:
                    sys.exit(f"FAIL: {line} answers {got} {'after' if prefix else 'before'}"
                             f" the engine started, expected {want}")
    print(f"PASS: != unstarted and through the bridge agree on {len(pairs)} pairs"
          f" and {len(SINGLE)} single calls; unstarted, != adds {growth} KiB"
          " of peak memory over ==")


if __name__ == "__main__":
    main()
