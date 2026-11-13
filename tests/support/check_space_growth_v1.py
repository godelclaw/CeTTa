#!/usr/bin/env python3
"""Space lookups grow linearly with the space, in PeTTa.

Each workload is timed inside its program, the least of three runs, among
N and 8N atoms of string keys (a notice scan's tasks); its time must grow
less than 16 times, twice linear, where a pass over the space per lookup
grows 64 times:

  - 8 lookups per atom of a head the space does not hold, the first argument
    unbound;
  - the same of a head one atom holds;
  - a notice scan forgetting its tasks in one space: its seen records
    removed one by one through a function, as the scan does (they are
    removed by mark, so later lookups meet removed rows), then per task a
    ground lookup of the removed seen record, a lookup of the pending
    record and its removal.

N is 500: a head with 4096 facts or more has its facts kept in a relation,
which lookups of another head pass over at once, so the costs measured here
are those of spaces below that size.  A lookup with no atom at all,
($h $x $x $a $b), reads every row, as no index serves it: the check must
reject that control, or it could not tell a quadratic workload."""
import os
import re
import subprocess
import sys
import tempfile

SMALL, LARGE, THRESHOLD = 500, 4000, 16.0

PRELUDE = """!(import! &self (library system))
!(import! &self (library str))
(= (ms $t0) (/ (- (system:monotonic-ns) $t0) 1000000))
(= (name $i) (str:concat "task-" (repr $i)))
(= (put $p $s $t) (let $_ (add-atom $p (P $t 100.0 False "lane")) (add-atom $s (S $t))))
(= (fill $p $s $i $n) (if (>= $i $n) () (let $_ (put $p $s (name $i)) (fill $p $s (+ $i 1) $n))))
(= (unsee $s $t) (remove-atom $s (S $t)))
(= (unsee-all $s $i $n) (if (>= $i $n) () (let $_ (unsee $s (name $i)) (unsee-all $s (+ $i 1) $n))))
(= (seen? $s $t) (not (== (collapse (match $s (S $t) True)) ())))
(= (pending $p $t) (case (collapse (match $p (P $t $a $b $c) ($a $b $c))) ((() none) ($e (car-atom $e)))))
(= (forget $p $t) (case (pending $p $t) ((none ()) (($a $b $c) (remove-atom $p (P $t $a $b $c))))))
(= (step forget $p $i) (let $t (name $i) (if (seen? $p $t) () (forget $p $t))))
(= (step absent $p $i) (collapse (match $p (F $x) $x)))
(= (step rare $p $i) (collapse (match $p (Q $x) $x)))
(= (step control $p $i) (collapse (match $p ($h $x $x $a $b) $h)))
(= (loop $look $p $i $n) (if (>= $i $n) () (let $_ (step $look $p $i) (loop $look $p (+ $i 1) $n))))
(= (prepare forget $p $n) (unsee-all $p 0 $n))
(= (prepare rare $p $n) (add-atom $p (Q 7)))
(= (prepare $other $p $n) ())
(= (lookups forget $n) $n)
(= (lookups control $n) $n)
(= (lookups $other $n) (* 8 $n))
(= (run $look $n)
   (let* (($p (new-space)) ($_ (fill $p $p 0 $n)) ($_ (prepare $look $p $n))
          ($t0 (system:monotonic-ns)) ($_ (loop $look $p 0 (lookups $look $n))))
     (println! (elapsed (ms $t0)))))
"""

WORKLOADS = [("absent", "a head the space does not hold"),
             ("rare", "a head one atom holds"),
             ("forget", "a notice scan forgetting its tasks")]


def elapsed(binary, work, look, n):
    source = os.path.join(work, f"{look}-{n}.metta")
    with open(source, "w") as handle:
        handle.write(PRELUDE + f"!(run {look} {n})\n")
    best = None
    for _ in range(3):
        proc = subprocess.run([binary, "--lang", "petta", source], cwd=work,
                              capture_output=True, text=True, timeout=600)
        found = re.search(r"\(elapsed ([0-9.eE+-]+)\)", proc.stdout)
        if not found:
            raise SystemExit(f"FAIL: {look} at {n} gave no time: "
                             f"{proc.stdout[-300:]} {proc.stderr[-300:]}")
        value = float(found.group(1))
        best = value if best is None else min(best, value)
    return best


def main():
    binary = os.path.abspath(sys.argv[1])
    failures = []
    with tempfile.TemporaryDirectory(prefix="space-growth-") as work:
        for look, label in WORKLOADS + [("control", "a lookup with no atom (control)")]:
            small = elapsed(binary, work, look, SMALL)
            large = elapsed(binary, work, look, LARGE)
            ratio = large / max(small, 1e-3)
            print(f"{label}: {small:.1f} ms at {SMALL}, {large:.1f} ms at {LARGE}, ratio {ratio:.1f}")
            if look == "control":
                if ratio < THRESHOLD:
                    failures.append(f"the check accepted the quadratic control ({ratio:.1f})")
            elif ratio >= THRESHOLD:
                failures.append(f"{label} grows {ratio:.1f} times for {LARGE // SMALL} times the atoms")
    for failure in failures:
        print("FAIL: " + failure)
    if not failures:
        print(f"PASS: space lookups grow linearly in PeTTa (threshold {THRESHOLD:.0f} "
              f"for {LARGE // SMALL} times the atoms)")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
