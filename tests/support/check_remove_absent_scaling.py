#!/usr/bin/env python3
"""Removing an atom a space does not hold costs the same in a space eight
times larger.

A space holds N rows (r i), and a second space the rest of 64,000 rows, so
that both measured runs hold the same live data.  16,000 removals of
(r i absent), which no row holds and none unifies with, must cost about the
same for N = 64,000 as for N = 8,000: at most twice (a scan of the space
per removal costs about eight times).  Their cost is a run's less the same
run without them, both counted in user-space instructions, so one run of
each decides, whatever the machine's load.  A separate small run checks the answers: the removals
leave the space as it was, a row (r $y absent) added after them is still
removed by (remove-atom &s (r 7 absent)), which unifies with it, and (r 5)
still goes.

Usage: check_remove_absent_scaling.py CETTA
"""
import sys

from instruction_count import instructions

SETUP = """!(bind! &s (new-space))
!(bind! &pad (new-space))
(= (fill $i $n) (if (>= $i $n) done (let $_ (add-atom &s (r $i)) (fill (+ $i 1) $n))))
(= (pad $i $n) (if (>= $i $n) done (let $_ (add-atom &pad (p $i)) (pad (+ $i 1) $n))))
(= (drop $i $n) (if (>= $i $n) done
  (let $_ (remove-atom &s (r $i absent)) (drop (+ $i 1) $n))))
!(fill 0 {n})
!(pad 0 {padding})
"""

DROP = """!(drop 0 {m})
"""

PROBE = """!(match &s (r 5) present)
"""

ANSWERS = """!(size-atom (collapse (get-atoms &s)))
!(add-atom &s (r $y absent))
!(size-atom (collapse (get-atoms &s)))
!(remove-atom &s (r 7 absent))
!(size-atom (collapse (get-atoms &s)))
!(remove-atom &s (r 5))
!(size-atom (collapse (get-atoms &s)))
"""

REMOVALS = 16000
# Rows held in all, the target space and a second one together: both runs
# hold the same live data, so only the size of the space removed from differs.
LIVE = 64000


def removal_cost(cetta, n):
    setup = SETUP.format(n=n, padding=LIVE - n)
    base = instructions(cetta, setup + PROBE, ["done", "done", "present"])
    full = instructions(cetta, setup + DROP.format(m=REMOVALS) + PROBE,
                        ["done", "done", "done", "present"])
    return max(full - base, 0)


def main():
    cetta = sys.argv[1]
    n = 1000
    instructions(cetta, SETUP.format(n=n, padding=0) + DROP.format(m=n) + ANSWERS,
                 ["done", "done", "done", str(n), "true", str(n + 1), "true", str(n),
                  "true", str(n - 1)])
    small = removal_cost(cetta, 8000)
    large = removal_cost(cetta, 64000)
    ratio = large / max(small, 1)
    if ratio > 2.0:
        print(f"FAIL: 16,000 absent removals took {large / 1e6:.0f}M instructions in "
              f"64,000 rows against {small / 1e6:.0f}M in 8,000 ({ratio:.1f}x)")
        sys.exit(1)
    print(f"PASS: removing an absent atom costs the same in a larger space: "
          f"16,000 removals {large / 1e6:.0f}M instructions in 64,000 rows, "
          f"{small / 1e6:.0f}M in 8,000 ({ratio:.1f}x)")


if __name__ == "__main__":
    main()
