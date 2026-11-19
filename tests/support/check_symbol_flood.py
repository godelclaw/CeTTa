#!/usr/bin/env python3
"""Spellings crafted to share one home in the symbol table intern about as
fast as random spellings of the same length: 8,192 spellings whose public
hash (FNV-1a) agrees in its low 20 bits, the bits a table of up to 2^20
slots placed them by before placement took a key of its own, intern within
three times the random spellings' work (placed by the hash alone, 32,768 of
them took about a hundred times as long).  Work is counted in user-space
instructions, start-up taken off, so one run of each decides, whatever the
machine's load.

The crafted set: FNV-1a's low k bits depend only on the low k bits before
them.  At each of 13 positions two 3-byte blocks are found that reach the
same low 20 bits from the state the position starts in; any choice of one
block per position reaches the same state, so the 2^13 spellings share one
home.

Usage: check_symbol_flood.py CETTA
"""
import itertools
import random
import sys

from instruction_count import instructions, startup

MASK20 = (1 << 20) - 1
P = 1099511628211
ALPHABET = b"abcdefghijklmnopqrstuvwxyz0123456789"


def fnv_low(state, data):
    for byte in data:
        state = ((state ^ byte) * P) & MASK20
    return state


def crafted():
    prefix = b"qkm8"
    state = fnv_low(1469598103934665603 & MASK20, prefix)
    pairs = []
    for _ in range(13):
        seen = {}
        for block in itertools.product(ALPHABET, repeat=3):
            block = bytes(block)
            low = fnv_low(state, block)
            if low in seen:
                pairs.append((seen[low], block))
                state = low
                break
            seen[low] = block
        else:
            raise SystemExit("FAIL: no colliding blocks")
    return [prefix + b"".join(choice) for choice in itertools.product(*pairs)]


def scattered(n, length):
    rnd = random.Random(7)
    names = set()
    while len(names) < n:
        names.add(bytes(rnd.choice(ALPHABET) for _ in range(length)))
    return sorted(names)


def work(cetta, names):
    return instructions(cetta, "".join(f"({name.decode()})\n" for name in names)
                        + "!(+ 1 1)\n", ["2"])


def main():
    cetta = sys.argv[1]
    flood = crafted()
    base = startup(cetta)
    flood_work = work(cetta, flood) - base
    plain_work = work(cetta, scattered(len(flood), len(flood[0]))) - base
    ratio = flood_work / max(plain_work, 1)
    if ratio > 3.0:
        print(f"FAIL: crafted spellings take {flood_work / 1e6:.0f}M instructions "
              f"against {plain_work / 1e6:.0f}M for random ones ({ratio:.1f}x)")
        sys.exit(1)
    print(f"PASS: crafted spellings take {flood_work / 1e6:.0f}M instructions against "
          f"{plain_work / 1e6:.0f}M for random ones ({ratio:.1f}x)")


if __name__ == "__main__":
    main()
