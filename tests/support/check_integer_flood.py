#!/usr/bin/env python3
"""Integers crafted to share one home in the integer table cost about what
random integers cost: 5,000 values whose pages' prefixes the table's former,
public hash sent to one slot load within three times the random values' work
(under that hash, 40,000 of them took about sixty times as long).  Work is
counted in user-space instructions, start-up taken off, so one run of each
decides, whatever the machine's load.

Usage: check_integer_flood.py CETTA
"""
import random
import sys

from instruction_count import instructions, startup

M = (1 << 64) - 1
C1 = 0xbf58476d1ce4e5b9
C1_INVERSE = pow(C1, -1, 1 << 64)
K = 24
N = 5000


def inv_xorshift(y, s):
    x = y
    for _ in range(64 // s + 1):
        x = y ^ (x >> s)
    return x & M


def public_hash(x):
    x ^= x >> 30
    x = (x * C1) & M
    x ^= x >> 27
    return x


def public_hash_inv(h):
    x = inv_xorshift(h, 27)
    x = (x * C1_INVERSE) & M
    return inv_xorshift(x, 30)


def signed(u):
    return u - (1 << 64) if u >= (1 << 63) else u


def crafted(n):
    values, j = [], 1
    while len(values) < n:
        prefix = public_hash_inv(j << K)
        j += 1
        if prefix < (1 << 55):
            assert public_hash(prefix) & ((1 << K) - 1) == 0
            values.append(signed(prefix << 9))
    return values


def scattered(n):
    rnd, seen, values = random.Random(7), set(), []
    while len(values) < n:
        u = rnd.getrandbits(64)
        if (u >> 9) in seen:
            continue
        seen.add(u >> 9)
        values.append(signed(u))
    return values


def work(cetta, values):
    return instructions(cetta, "".join(f"(n {v})\n" for v in values) + "!(+ 1 1)\n", ["2"])


def main():
    cetta = sys.argv[1]
    base = startup(cetta)
    flood = work(cetta, crafted(N)) - base
    plain = work(cetta, scattered(N)) - base
    ratio = flood / max(plain, 1)
    if ratio > 3.0:
        print(f"FAIL: crafted integers take {flood / 1e6:.0f}M instructions against "
              f"{plain / 1e6:.0f}M for random ones ({ratio:.1f}x)")
        sys.exit(1)
    print(f"PASS: crafted integers take {flood / 1e6:.0f}M instructions against "
          f"{plain / 1e6:.0f}M for random ones ({ratio:.1f}x)")


if __name__ == "__main__":
    main()
