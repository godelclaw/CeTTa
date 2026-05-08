# Codex-in-CeTTa Restart Plan

## Baseline

Restart the Codex port from the clean green baseline at commit `f17be19`.
Treat every new Codex slice as invalid until it is proven green by output-aware
checking, not by `./cetta` exit code alone.

## Rules

1. Never work on top of red.
2. Every slice must be visible and runnable with:
   `./cetta --lang he --profile he_extended <file.metta>`
3. Every slice must include:
   - one runnable demo under `examples/`
   - one narrow surface under `tests/`
4. Validation must fail on CeTTa outputs containing `[(Error` or `NoReturn`,
   even when the process exits `0`.
5. Any Rust-to-CeTTa algorithmic deviation must be documented in comments next
   to the implementation that needs it.

## Slice Ladder

1. `codex/protocol`
   - Rust-shaped protocol items and JSON serialization
   - visible demo plus one JSON surface
2. `codex/turn`
   - deterministic fixture turns with canned tool calls and final responses
3. `codex/command`
   - command parsing surfaces
4. `codex/exec_policy`
   - prefix-rule evaluation first
5. `codex/approval`
   - approval decisions for the already-supported tool set
6. `codex/tools`
   - real execution paths for the minimal tool set
7. `apply_patch`
   - approval plus execution plus intercept behavior
8. `request_user_input`
   - protocol, handler, then fixture execution
9. `request_permissions`
   - protocol, handler, approval propagation, same-turn carry-over
10. higher-order exec-policy slices
   - amendments, host executables, network, persistence, and related details

## Green Lane

Early in the restart, the green lane is explicit and staged:

- affected support-library surfaces
- new `tests/test_codex_*.metta` files
- new `examples/codex_*_demo.metta` demos when they are asserted or checked

Once the committed Codex suite becomes large enough, expand the gate to the full
`tests/test_codex_*.metta` sweep.

## Verification

Use `scripts/check_codex_surfaces.sh` for output-aware Codex checks.

Required validation flow for a new slice:

1. `make -j4`
2. affected baseline surfaces
3. new Codex surfaces
4. new Codex demos
5. current staged Codex green lane
