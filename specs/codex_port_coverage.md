# Codex Port Coverage

Last updated: 2026-06-10 on branch `exp/codex` after the turn_diff_tracker
slice. This is the structural checklist for the "exact rough draft" phase:
what is ported, what remains, and in what order to take the gaps. Update it
whenever a slice lands.

Method: name- and content-level comparison of `codex/*.metta` (224 modules)
against `../openai-codex/codex-rs` (core/src modules plus functional crates).
Numbers are approximate; verify a module is really missing (grep the .metta
files for its characteristic names) before starting a slice.

## Summary

- Roughly 60% of the functional-core modules are ported.
- High coverage (>80%): protocol/serialization, model provider, network
  proxy, apply_patch, unified_exec/exec engine, tools
  (registry/router/orchestrator), js_repl, exec-server, sandboxing surfaces.
- Medium (40-80%): agent jobs/registry, state extract/paths, skills, login
  and auth, git utilities, rollout.
- Low (<40%): config system, session lifecycle, guardian/review,
  memories/context phases, hooks.

## Out of scope for the functional core

Front-ends and infrastructure crates are not part of this phase: `tui`,
`app-server*`, `cli`, `cloud-tasks*`, `debug-client`, `responses-api-proxy`,
`realtime-webrtc`, `otel`, `analytics`, `v8-poc`, `vendor`,
`windows-sandbox-rs`, test-support crates.

## Priority gaps (take roughly in this order)

Foundational, unblocks the most downstream behavior:

1. `core/src/config/mod.rs` (~2600 LOC) — agent settings model; the single
   largest missing piece. Slice it: defaults, overrides, profile resolution.
2. `core/src/config_loader` (~300 LOC) — layered config file loading;
   pairs with the network proxy loader already ported.
3. `core/src/session/session.rs` (~950 LOC) and `session/handlers`
   (~1300 LOC) — session state, lifecycle, request dispatch. Only turn
   handling is ported today.
4. `core/src/thread_manager.rs` (~1250 LOC) — multi-thread concurrency
   bookkeeping.

Behavioral completeness:

5. `core/src/guardian/review_session.rs` (~1150 LOC) plus guardian glue —
   human-in-the-loop review workflows (templates already ported).
6. `core/src/hook_runtime.rs` (~640 LOC) — policy hook execution
   (hook_names already ported).
7. `core/src/compact.rs` / `compact_remote.rs` — context compaction.
8. `core/src/rollout` remainder — persistence beyond the ported
   config/list/metadata/policy/state_db surfaces.
9. `core/src/file_watcher.rs`, `core/src/spawn.rs`,
   `core/src/codex_delegate.rs` / `codex_thread.rs` — process and delegate
   plumbing.

Recently closed:

- `core/src/turn_diff_tracker.rs` → `codex/turn_diff_tracker.metta`,
  `codex/turn_diff_file_diff.metta`, `codex/turn_diff_lines.metta`
  (2026-06-10), including an LCS unified-diff engine.

Optional for a working core (defer):

- `core/src/memories/*` (phase1/phase2/storage), realtime context modes,
  `git-utils/ghost_commits.rs` (~1800 LOC), `file-search`, `mcp-server`
  remainder, `state/log_db`.

## Slice rules (from specs/codex_restart_plan.md)

- Port algorithms exactly; comment any CeTTa-forced deviation at the site.
- Every slice: `tests/test_codex_<name>_surface.metta` plus an asserted
  `examples/codex_<name>_demo.metta`.
- Validate output-aware (`scripts/check_codex_surfaces.sh`), never by exit
  code; never work on top of red.
- Keep modules small and split aggressively: large modules (and importing
  `codex:protocol` into deep-recursion modules) degrade the evaluator; see
  the deviation notes in `codex/turn_diff_tracker.metta`.
