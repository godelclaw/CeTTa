#!/usr/bin/env python3
"""A stored term's levels cost the same however deep they are: one term
800,000 levels deep, stored, read back by a match and counted, takes at most
twice as long as eight terms of 100,000 levels.

Decoding a stored term recursed once per level and overflowed the C stack
near 100,000 levels; interning a chain compared each level with its
neighbours down to their depth, which costs about eight times more for the
one deep term.  Both runs hold the same number of levels, so caches weigh
on them alike.

Work is counted in user-space instructions, start-up taken off, so one
run of each decides, whatever the machine's load.

Usage: check_deep_terms_scaling.py CETTA
"""
import sys

from instruction_count import instructions, startup

PROGRAM = """(= (build $n $acc) (if (== $n 0) $acc (build (- $n 1) (s $acc))))
(= (peel $t $k) (case $t (((s $u) (peel $u (+ $k 1))) ($other $k))))
(= (fill $i $c $d) (if (>= $i $c) done
  (let $t (build $d (z $i)) (let $_ (add-atom &self (d $t)) (fill (+ $i 1) $c $d)))))
!(fill 0 {count} {depth})
!(match &self (d $x) (peel $x 0))
"""


def run(cetta, count, depth):
    return instructions(cetta, PROGRAM.format(count=count, depth=depth),
                        ["done"] + [str(depth)] * count)


def main():
    cetta = sys.argv[1]
    base = startup(cetta)
    shallow = run(cetta, 8, 100000) - base
    deep = run(cetta, 1, 800000) - base
    ratio = deep / max(shallow, 1)
    if ratio > 2.0:
        print(f"FAIL: one term of 800,000 levels took {deep / 1e6:.0f}M instructions "
              f"against {shallow / 1e6:.0f}M for eight of 100,000 ({ratio:.1f}x)")
        sys.exit(1)
    print(f"PASS: a stored term's levels cost the same at any depth: one of "
          f"800,000 levels {deep / 1e6:.0f}M instructions, eight of 100,000 "
          f"{shallow / 1e6:.0f}M ({ratio:.1f}x)")


if __name__ == "__main__":
    main()
