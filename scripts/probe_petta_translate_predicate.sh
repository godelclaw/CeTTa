#!/usr/bin/env bash
# Compare the PeTTa translatePredicate oracle against current CeTTa/HE.
#
# This is a narrow compatibility probe. CeTTa/HE implements the small
# `translatePredicate` helper subset needed by the upstream PeTTa regression
# and old MeTTaClaw/OmegaClaw utilities, while broader PeTTa relation
# semantics remain on the language-adapter lane.

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PETTA_DIR="${PETTA_DIR:-$HOME/repos/PeTTa}"
PROBE="$ROOT/tests/fixtures/petta_translate_predicate_probe.metta"
CETTA_PROBE="$ROOT/tests/test_petta_translate_predicate_regression.metta"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

if [ ! -x "$PETTA_DIR/run.sh" ]; then
    echo "missing PeTTa runner: $PETTA_DIR/run.sh" >&2
    exit 1
fi
if [ ! -x "$ROOT/cetta" ]; then
    echo "missing CeTTa binary: $ROOT/cetta" >&2
    exit 1
fi
if [ ! -f "$PROBE" ]; then
    echo "missing probe: $PROBE" >&2
    exit 1
fi
if [ ! -f "$CETTA_PROBE" ]; then
    echo "missing CeTTa probe: $CETTA_PROBE" >&2
    exit 1
fi

echo "== PeTTa oracle =="
(
    cd "$ROOT"
    timeout 10s "$PETTA_DIR/run.sh" "$PROBE"
) >"$TMPDIR/petta.out" 2>&1
sed -E 's/\x1b\[[0-9;]*m//g' "$TMPDIR/petta.out"
if [ "$(grep -c 'is 42, should 42' "$TMPDIR/petta.out")" -ge 4 ] &&
   grep -q 'is 5, should 5' "$TMPDIR/petta.out" &&
   [ "$(grep -c 'is 7, should 7' "$TMPDIR/petta.out")" -ge 1 ] &&
   grep -q 'is 2, should 2' "$TMPDIR/petta.out" &&
   [ "$(grep -c 'is 3, should 3' "$TMPDIR/petta.out")" -ge 2 ]; then
    echo "PASS: PeTTa translatePredicate exports arithmetic bindings"
else
    echo "FAIL: PeTTa oracle did not prove the translatePredicate witness" >&2
    exit 1
fi
if grep -q 'is sam, should sam' "$TMPDIR/petta.out"; then
    echo "PASS: PeTTa translatePredicate exports equality bindings"
else
    echo "FAIL: PeTTa oracle did not prove the equality binding witness" >&2
    exit 1
fi
if [ "$(grep -Ec 'is [Tt]rue, should [Tt]rue' "$TMPDIR/petta.out")" -ge 6 ]; then
    echo "PASS: PeTTa translatePredicate exports ternary predicate bindings"
else
    echo "FAIL: PeTTa oracle did not prove the ternary predicate witness" >&2
    exit 1
fi
if [ "$(grep -Ec 'is [Ff]alse, should [Ff]alse' "$TMPDIR/petta.out")" -ge 3 ]; then
    echo "PASS: PeTTa translatePredicate exports false ternary equality"
else
    echo "FAIL: PeTTa oracle did not prove the false ternary equality witness" >&2
    exit 1
fi
if grep -Eq '#<|#>|#=|#\\+|#-|#\\*|#mod|#div|#//|#\\=|#min|#max' "$TMPDIR/petta.out" &&
   [ "$(grep -Ec 'is [Tt]rue, should [Tt]rue' "$TMPDIR/petta.out")" -ge 6 ] &&
   [ "$(grep -Ec 'is [Ff]alse, should [Ff]alse' "$TMPDIR/petta.out")" -ge 3 ]; then
    echo "PASS: PeTTa translatePredicate exports numeric CLPFD-style relation bindings"
else
    echo "FAIL: PeTTa oracle did not prove numeric CLPFD-style relation witnesses" >&2
    exit 1
fi
if [ "$(grep -c 'is "foobar", should "foobar"' "$TMPDIR/petta.out")" -ge 2 ] &&
   grep -q 'is "42", should "42"' "$TMPDIR/petta.out" &&
   grep -q 'is (), should ()' "$TMPDIR/petta.out" &&
   grep -q 'is ":- table name/2.", should ":- table name/2."' "$TMPDIR/petta.out" &&
   grep -q 'is "truefalse", should "truefalse"' "$TMPDIR/petta.out" &&
   grep -q 'is "answer", should "answer"' "$TMPDIR/petta.out" &&
   grep -q 'is answer, should answer' "$TMPDIR/petta.out" &&
   grep -q 'is 1, should 1' "$TMPDIR/petta.out" &&
   grep -q 'is (104 105), should (104 105)' "$TMPDIR/petta.out" &&
   grep -q 'is "hi", should "hi"' "$TMPDIR/petta.out" &&
   grep -q 'is "1970", should "1970"' "$TMPDIR/petta.out" &&
   grep -q 'is 19, should 19' "$TMPDIR/petta.out" &&
   grep -q 'is "cde", should "cde"' "$TMPDIR/petta.out" &&
   grep -q 'is (Pair 3 "abc"), should (Pair 3 "abc")' "$TMPDIR/petta.out" &&
   grep -q 'is "a", should "a"' "$TMPDIR/petta.out" &&
   grep -q 'is "b", should "b"' "$TMPDIR/petta.out"; then
    echo "PASS: PeTTa translatePredicate exports string/atom/file/time/substring conversion bindings"
else
    echo "FAIL: PeTTa oracle did not prove string/atom/file/time/substring conversion witnesses" >&2
    exit 1
fi

echo "== CeTTa HE current =="
(
    cd "$ROOT"
    ./cetta --lang he --profile he-extended "$CETTA_PROBE"
) >"$TMPDIR/cetta.out" 2>&1
cat "$TMPDIR/cetta.out"
if [ "$(grep -c '^\[()\]$' "$TMPDIR/cetta.out")" = "48" ]; then
    echo "PASS: CeTTa/HE matches the translatePredicate helper subset"
else
    echo "FAIL: CeTTa/HE did not match the translatePredicate helper subset" >&2
    exit 1
fi

cat <<'EOF'
== Reading ==
PeTTa succeeds because translatePredicate exports relation-goal bindings
through the surrounding progn (for example $z in (+ $x 40 $z), $who in
(= $who sam), $ok in (< 2 3 $ok), and $same in (= sam sam $same)).
It also checks false relation output for (= sam bob $same) and numeric
CLPFD-style #</#>/#=/#+/#-/#*/#mod/#div/#//#\=/#min/#max relation goals.
The string/number tail covers the old MeTTaClaw/OmegaClaw helpers:
string_concat/3, string_length/2, number_string/2, atom_number/2,
exists_file/1, read_file_to_string/3, sleep/1, format_time/3,
atom_string/2 including numeric/bool atoms, atomics_to_string/2, atom_codes/2 over
non-NUL byte codes, and the deterministic subset of sub_string/5.
CeTTa/HE now implements this
small helper subset as a syntax-taking special form, without importing the
broader PeTTa language adapter or Prolog relation layer.
EOF
