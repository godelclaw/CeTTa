#!/usr/bin/env python3
"""A generator nested to the right and a loop of removals grow linearly.

Two findings of the adversarial audit, fixed, kept fixed here:

* A right-nested `superpose` generator,
  `(= (range $a $b) (if (>= $a $b) (empty) (superpose ($a (range (+ $a 1) $b)))))`,
  handed each answer back through every pending alternative: 32,000
  answers took 1.81 s (exponent 2.11).  Collected for N and for 4 N, its
  work may grow at most sixfold, where a cost per answer growing with the
  depth grows it sixteenfold; and its answers, sorted, are exactly 0 to
  N - 1, each once.
* A recursive loop of `remove-atom` calls slowed as it ran: 64k to 512k
  calls took 0.1 to 1.17 s.  Removing N atoms from a space of N rows, and
  then 4 N from 4 N, its work may grow at most sixfold as well, and the
  space ends empty.

Work is counted in user-space instructions, start-up taken off, so one run
at each size decides, whatever the machine's load; N is 16,000.

Usage: check_generator_loop_scaling.py CETTA [N]
"""
import sys

from instruction_count import instructions, startup

GROWTH = 6.0

RANGE = ("(= (range $a $b) (if (>= $a $b) (empty)"
         " (superpose ($a (range (+ $a 1) $b)))))\n")


def nested(n):
    return RANGE + f"!(size-atom (collapse (range 0 {n})))\n"


def law(n):
    every = " ".join(str(i) for i in range(n))
    return RANGE + f"!(== (sort-atom (collapse (range 0 {n}))) ({every}))\n"


def removals(n):
    rows = "".join(f"(x {i})\n" for i in range(1, n + 1))
    return (rows +
            "(= (drop $n) (if (== $n 0) done"
            " (let $_ (remove-atom &self (x $n)) (drop (- $n 1)))))\n"
            f"!(drop {n})\n!(size-atom (collapse (match &self (x $i) $i)))\n")


def ladder(cetta, base, name, program, n, expected):
    small = instructions(cetta, program(n), expected(n)) - base
    large = instructions(cetta, program(4 * n), expected(4 * n)) - base
    ratio = large / max(small, 1)
    verdict = "PASS" if ratio <= GROWTH else "FAIL"
    print(f"{verdict}: {name} from {n} to {4 * n}: {small / 1e6:.0f}M to "
          f"{large / 1e6:.0f}M instructions ({ratio:.1f}x, at most {GROWTH:.0f}x)")
    return verdict == "PASS"


def main():
    cetta = sys.argv[1]
    n = int(sys.argv[2]) if len(sys.argv) > 2 else 16000
    base = startup(cetta)
    ok = ladder(cetta, base, "a right-nested superpose generator", nested, n,
                lambda m: [str(m)])
    ok = ladder(cetta, base, "a loop of removals", removals, n,
                lambda m: ["done", "0"]) and ok
    # The sorted answers must be 0 to 4095, each once; a mismatch fails here.
    instructions(cetta, law(4096), ["true"])
    print("PASS: the right-nested generator answers 0 to 4095, each once")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
