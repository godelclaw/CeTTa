#!/usr/bin/env python3
"""Binary relations kept as bits answer probes of either column in time
proportional to their answers, and joins over them read the smaller leg at
each visit.

Two programs, each at N and 8N, must answer exactly and cost at most sixteen
times as much at 8N (linear work gives about eight, a scan or a kept leg
paying a hub's degree about sixty-four).  Work is counted in user-space
instructions, start-up taken off, so one run at each size decides:
- reverse lookups: N pairs, N/8 sources with 8 targets each; a lookup per
  target binding only the second column;
- star triangles: a hub with an edge to and from each of N leaves and a
  ring through them; the triangles counted by one conjunctive match.

Usage: check_bits_join_scaling.py CETTA
"""
import sys

from instruction_count import instructions, startup


def reverse_program(n):
    nodes = n // 8
    facts = []
    for i in range(nodes):
        for j in range(8):
            facts.append(f"(e {i} {(i * 7919 + j * 104729 + 13) % nodes})")
    loop = ("(= (go $k $n $acc) (if (>= $k $n) $acc "
            "(go (+ $k 1) $n (+ $acc (size-atom (collapse (match &self (e $x $k) $x)))))))\n")
    return "\n".join(facts) + "\n" + loop + f"!(go 0 {nodes} 0)\n", [str(n)]


def star_program(n):
    hub = n
    facts = []
    for i in range(n):
        facts.append(f"(e {hub} {i})")
        facts.append(f"(e {i} {hub})")
        facts.append(f"(e {i} {(i + 1) % n})")
    query = "!(size-atom (collapse (match &self (, (e $a $b) (e $b $c) (e $c $a)) 1)))\n"
    # Triangles: the hub with each ring edge, hub -> i -> i+1 -> hub, counted
    # once per rotation: three per ring edge.
    return "\n".join(facts) + "\n" + query, [str(3 * n)]


def ladder(cetta, base, make, small_n, large_n, what):
    small = instructions(cetta, *make(small_n)) - base
    large = instructions(cetta, *make(large_n)) - base
    ratio = large / max(small, 1)
    if ratio > 16.0:
        print(f"FAIL: {what}: {large / 1e6:.0f}M instructions at {large_n} against "
              f"{small / 1e6:.0f}M at {small_n} ({ratio:.1f}x)")
        sys.exit(1)
    return (f"{what} {large / 1e6:.0f}M instructions at {large_n}, "
            f"{small / 1e6:.0f}M at {small_n} ({ratio:.1f}x)")


def main():
    cetta = sys.argv[1]
    base = startup(cetta)
    first = ladder(cetta, base, reverse_program, 4000, 32000, "reverse lookups")
    second = ladder(cetta, base, star_program, 500, 4000, "star triangles")
    print(f"PASS: bits answer either column by their answers: {first}; {second}")


if __name__ == "__main__":
    main()
