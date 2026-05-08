#!/usr/bin/env bash
set -euo pipefail

shopt -s nullglob

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CETTA_BIN="${CETTA_BIN:-$ROOT/cetta}"
LANG_ARGS=(--lang he --profile he_extended)

if command -v rg >/dev/null 2>&1; then
  MATCHER=(rg -q '\[\((Error|NoReturn)|NoReturn')
else
  MATCHER=(grep -Eq '\[\((Error|NoReturn)|NoReturn')
fi

if (($# > 0)); then
  TARGETS=("$@")
else
  TARGETS=(
    "$ROOT/tests"/test_codex_*.metta
    "$ROOT/examples"/codex_*_demo.metta
  )
fi

if ((${#TARGETS[@]} == 0)); then
  echo "No Codex surfaces or demos found."
  exit 0
fi

FAILED=0

for target in "${TARGETS[@]}"; do
  echo "==> $target"
  if ! output="$("$CETTA_BIN" "${LANG_ARGS[@]}" "$target" 2>&1)"; then
    printf '%s\n' "$output"
    FAILED=1
    continue
  fi
  printf '%s\n' "$output"
  if printf '%s\n' "$output" | "${MATCHER[@]}"; then
    echo "FAIL: output-aware check failed for $target" >&2
    FAILED=1
  fi
done

exit "$FAILED"
