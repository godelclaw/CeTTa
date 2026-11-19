#!/usr/bin/env python3
"""Removing rows under a column index costs each removal a constant.

A space holds rows (p i k z) with k = i mod 2.  Lookups of (p $x k z) build
the column index of k, whose two postings each hold half the rows.  The
rows are then removed in ascending order, which takes the first position of
a long posting each time: half of them, a lookup that must not meet the
removed rows, then the rest.  The answers must be exact, and 32,000 rows
must cost at most sixteen times 4,000 rows (linear work gives about eight,
a posting shifted at each removal about sixty-four).  Work is counted in
user-space instructions, start-up taken off, so one run at each size
decides, whatever the machine's load.

Usage: check_index_removal_scaling.py CETTA
"""
import sys

from instruction_count import instructions, startup

PROGRAM = """!(bind! &s (new-space))
(= (fill $i $n) (if (>= $i $n) done
  (let $k (% $i 2) (let $_ (add-atom &s (p $i $k z)) (fill (+ $i 1) $n)))))
!(fill 0 {n})
(= (look $k $j) (if (== $j 0) done
  (let $c (size-atom (collapse (match &s (p $x $k z) $x))) (look $k (- $j 1)))))
!(look 0 8)
!(look 1 8)
(= (step $i $n) (if (>= $i $n) done
  (let $k (% $i 2) (let $u (remove-atom &s (p $i $k z)) (step (+ $i 1) $n)))))
!(step 0 {half})
!(size-atom (collapse (match &s (p $x 1 z) $x)))
!(step {half} {n})
!(size-atom (collapse (match &s (p $x 1 z) $x)))
"""


def work(cetta, n):
    return instructions(cetta, PROGRAM.format(n=n, half=n // 2),
                        ["done", "done", "done", "done", str(n // 4), "done", "0"])


def main():
    cetta = sys.argv[1]
    base = startup(cetta)
    small = work(cetta, 4000) - base
    large = work(cetta, 32000) - base
    ratio = large / max(small, 1)
    if ratio > 16.0:
        print(f"FAIL: 32,000 rows removed in {large / 1e6:.0f}M instructions against "
              f"{small / 1e6:.0f}M for 4,000 ({ratio:.1f}x)")
        sys.exit(1)
    print(f"PASS: rows leave a column index in constant time: 32,000 removals "
          f"{large / 1e6:.0f}M instructions, 4,000 {small / 1e6:.0f}M ({ratio:.1f}x)")


if __name__ == "__main__":
    main()
