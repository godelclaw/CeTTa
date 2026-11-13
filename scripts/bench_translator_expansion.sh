#!/usr/bin/env bash
# Per-use cost of translator rules, expanded once and run at each call.
# usage: [VARIANTS="..."] scripts/bench_translator_expansion.sh [CETTA] [BENCH] [N] [RUNS]
# Prints: variant mode n median_ns ns_per_use, for n = N, 4N and 16N.  The
# two modes alternate run by run, so load on a shared host shifts both alike.
set -u
cetta=${1:-./cetta}
bench=${2:-benchmarks/bench_translator_expansion_petta.metta}
base=${3:-1000}
runs=${4:-5}
variants=${VARIANTS:-"rule hand plain checked out out-by-hand guard-hand guard-out fail-hand fail-out if-hand if-out"}
work=$(mktemp -d "${TMPDIR:-/tmp}/cetta-translator-bench.XXXXXX")
trap 'rm -rf "$work"' EXIT
for variant in $variants; do
  for n in "$base" $((base * 4)) $((base * 16)); do
    printf '!(import! &self %s)\n!(tx:one %s %s)\n' "$(realpath "$bench")" "$variant" "$n" > "$work/one.metta"
    expanded=() per_call=()
    for ((r = 0; r < runs; r++)); do
      for mode in expanded per-call; do
        flag=1; [ "$mode" = per-call ] && flag=0
        ns=$(CETTA_PETTA_TRANSLATOR_EXPANSION=$flag timeout 600 "$cetta" --lang petta --profile extended "$work/one.metta" 2>/dev/null |
             grep -oE "^\\($variant $n [0-9]+\\)" | awk '{print $3}' | tr -d ')')
        if [ "$mode" = expanded ]; then expanded+=("${ns:-NA}"); else per_call+=("${ns:-NA}"); fi
      done
    done
    for mode in expanded per-call; do
      if [ "$mode" = expanded ]; then values=("${expanded[@]}"); else values=("${per_call[@]}"); fi
      median=$(printf '%s\n' "${values[@]}" | sort -n | sed -n "$(( (runs + 1) / 2 ))p")
      case $median in ''|NA) echo "$variant $mode $n NA NA" ;;
        *) echo "$variant $mode $n $median $(( median / n ))" ;; esac
    done
  done
done
