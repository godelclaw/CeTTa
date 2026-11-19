#!/usr/bin/env python3
"""Values crafted to share one home in a path index cost about what random
values cost: 20,000 facts (p I V) whose values V the index's former, public
placement hash (the splitmix64 finalizer, invertible) sends to one slot,
read back through the index by (p $x V), load and answer within three times
the random values' work (under that hash, 80,000 of them took about thirty
times as long).  Work is counted in user-space instructions, start-up taken
off, so one run of each decides, whatever the machine's load.

An integer field's key is the value itself, so the values are chosen by
inverting the finalizer at hashes whose low 24 bits are zero.

Usage: check_path_flood.py CETTA
"""
import random
import sys

from instruction_count import instructions, startup

M = (1 << 64) - 1
C1 = 0xbf58476d1ce4e5b9
C2 = 0x94d049bb133111eb
K = 24
N = 20000
QUERIES = 64


def inv_xorshift(y, s):
    x = y
    for _ in range(64 // s + 1):
        x = y ^ (x >> s)
    return x & M


def path_hash(k):
    k ^= k >> 30
    k = (k * C1) & M
    k ^= k >> 27
    k = (k * C2) & M
    return k ^ (k >> 31)


def path_hash_inv(h):
    x = inv_xorshift(h, 31)
    x = (x * pow(C2, -1, 1 << 64)) & M
    x = inv_xorshift(x, 27)
    x = (x * pow(C1, -1, 1 << 64)) & M
    return inv_xorshift(x, 30)


def signed(u):
    return u - (1 << 64) if u >= (1 << 63) else u


def crafted():
    values = []
    for j in range(1, N + 1):
        k = path_hash_inv(j << K)
        assert path_hash(k) & ((1 << K) - 1) == 0
        values.append(signed(k))
    return values


def scattered():
    rnd = random.Random(7)
    seen = set()
    values = []
    while len(values) < N:
        v = signed(rnd.getrandbits(64))
        if v not in seen:
            seen.add(v)
            values.append(v)
    return values


def work(cetta, values):
    probes = values[::max(1, len(values) // QUERIES)][:QUERIES]
    text = "".join(f"(p {i} {v})\n" for i, v in enumerate(values))
    text += "".join(f"!(match &self (p $x {v}) $x)\n" for v in probes)
    return instructions(cetta, text, [str(values.index(v)) for v in probes])


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    cetta = sys.argv[1]
    base = startup(cetta)
    plain = work(cetta, scattered()) - base
    flood = work(cetta, crafted()) - base
    ratio = flood / max(plain, 1)
    if ratio > 3.0:
        print(f"FAIL: crafted path keys take {flood / 1e6:.0f}M instructions against "
              f"{plain / 1e6:.0f}M for random ones ({ratio:.1f}x)")
        sys.exit(1)
    print(f"PASS: crafted path keys take {flood / 1e6:.0f}M instructions against "
          f"{plain / 1e6:.0f}M for random ones ({ratio:.1f}x; {N} facts, {QUERIES} reads)")


if __name__ == "__main__":
    main()
