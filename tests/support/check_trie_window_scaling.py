#!/usr/bin/env python3
"""Lookups keyed past the match trie's window read their own rows.

Usage: check_trie_window_scaling.py CETTA_BINARY

The trie reads a row's first 511 elements and 8 levels.  Rows of 522
columns asked by their last bound column, and facts ten deep asked by a
value below the trie's levels (fewer than make a relation), each asked
once per row: from N to 4 N rows the lookups' work grows at most eightfold,
where reading every row per lookup grows it sixteenfold, and every lookup
answers.  Work is counted in user-space instructions, start-up taken off,
so one run at each size decides, whatever the machine's load.
"""
import os
import sys

from instruction_count import instructions, startup


def wide(rows, key_column=521):
    def columns(key):
        cols = [f"c{j}" for j in range(521)]
        cols[key_column - 1] = key
        return " ".join(cols)
    lines = [f"(wide {columns(str(i))} v{i})" for i in range(rows)]
    lines.append(f"(= (ask $i) (match &self (wide {columns('$i')} $v) $v))")
    return lines


def deep(rows):
    def nest(t):
        for _ in range(10):
            t = f"(w {t})"
        return t
    lines = [f"(d {nest(f'(k {i} v{i})')})" for i in range(rows)]
    lines.append(f"(= (ask $i) (match &self (d {nest('(k $i $v)')}) $v))")
    return lines


def run(binary, lines, rows):
    lines = lines + [
        "(= (all $n $acc) (if (== $n 0) $acc "
        "(let $v (ask (- $n 1)) (all (- $n 1) (+ $acc 1)))))",
        f"!(all {rows} 0)"]
    return instructions(binary, "\n".join(lines) + "\n", [str(rows)], timeout=900)


def main():
    binary = os.path.abspath(sys.argv[1])
    base = startup(binary)
    cases = (("wide", wide, (400, 1600)),
             ("wide-first-unindexed", lambda n: wide(n, 511), (400, 1600)),
             ("wide-middle-unindexed", lambda n: wide(n, 516), (400, 1600)),
             ("deep", deep, (800, 3200)))
    for name, make, (small, large) in cases:
        per = [run(binary, make(n), n) - base for n in (small, large)]
        ratio = per[1] / max(per[0], 1)
        if ratio > 8.0:
            print(f"FAIL: {name} lookups took {per[0] / 1e6:.0f}M instructions over "
                  f"{small} rows and {per[1] / 1e6:.0f}M over {large} ({ratio:.1f}x)")
            return 1
        print(f"PASS: {name} lookups past the trie's window: {per[0] / 1e6:.0f}M and "
              f"{per[1] / 1e6:.0f}M instructions over {small} and {large} rows "
              f"({ratio:.1f}x)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
