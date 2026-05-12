# Context Port Restart Notes

Restart point: `9f0cf75` (`Port unified exec hook payload helpers`)

## What Went Well

- The intended Rust slice boundary was reasonable:
  `protocol::FunctionCallOutput` and parts of
  `core::tools::{context,registry}` are still the right next area.
- The native UTF-8 helper direction was useful:
  byte-budget truncation at character boundaries is still needed for
  `telemetry_preview`.
- The isolated context surface was valuable:
  direct tests for function/custom response shaping and exec code-mode JSON
  exposed several evaluator edge cases early.
- Reconstructing `ExecCommandToolOutput` JSON from `CodexExecCommandRun` is
  still the correct visible CeTTa strategy until the run record gains closer
  Rust parity.

## What Went Wrong

- The attempted slice grew too large:
  protocol changes, native string helpers, a new `codex/context.metta`, and
  stabilization edits in `codex/tools.metta` and `codex/request_permissions.metta`
  were mixed into one dirty attempt.
- A new dependency edge from `codex:context` into `codex:tools` was unsafe.
  Even after that import was removed, the attempt had already spread evaluator
  workarounds into existing green subsystems.
- Too much time was spent fighting evaluator reduction order with nested
  `let`, `case`, `list:append`, and constructor matching.
  Some focused surfaces turned green, but the broader suite regressed.
- Several regressions were not true algorithm bugs in the Rust port. They were
  CeTTa surface-evaluation failures caused by composing unresolved constructor
  terms through existing helpers.
- The failed attempt eventually triggered a native abort during probing:
  `*** buffer overflow detected ***: terminated`.
  That makes the old dirty slice unfit for salvage-in-place.

## Restart Rules

- Keep the restart split into small audited slices:
  1. native/helper slice only
  2. protocol `FunctionCallOutput` slice only
  3. `codex/context.metta` response/log/code-mode slice only
- Do not edit `codex:tools` or `codex:request_permissions` unless a failing
  isolated surface proves a strict requirement.
- Do not import `codex:tools` from `codex:context`.
  Copy tiny formatting helpers under context-local names if necessary.
- Prefer direct concrete-shape tests over evaluator-sensitive nested projection
  chains.
- If a surface only passes after adding broad evaluator workarounds to already
  green modules, stop and split the slice smaller instead.

## Concrete Failed Patterns To Avoid

- Nested helper projections like:
  `tool-result-output-text (tool-output-to-response-item ...)`
  when the surface can instead assert on the concrete response item JSON.
- Wrappers that build large symbolic terms through nested `let` and return them
  without first proving the same form is stable elsewhere in the repo.
- Replacing stable green code in existing modules during exploratory debugging.

## Immediate Redo Plan

- Re-add the UTF-8 helper in `src/library.c`, `src/symbol.h`, and `lib/str.metta`.
- Re-add only the protocol `FunctionCallOutput` / content-item JSON/text slice
  in `codex/protocol.metta` with focused protocol tests.
- Run the focused protocol surface, then the full Codex sweep, before starting
  `codex/context.metta`.

## First Redo Slice Outcome

- The helper-plus-protocol restart boundary is green:
  the UTF-8 byte-boundary helper and `FunctionCallOutput` protocol slice passed
  their focused surfaces without touching `codex/tools.metta` or
  `codex/request_permissions.metta`.
- The focused-first workflow paid off:
  one ambiguous empty-list base case in the lossy text fold was fixed locally
  before the broader suite ran.
- Rebuilding immediately after the native helper change matters:
  the first string surface failure was only the expected missing builtin in the
  old `./cetta` binary, not a logic bug in the helper implementation.
- The restart rules were correct:
  keeping the slice out of the live-tool/runtime modules avoided the broader
  regressions seen in the failed dirty context attempt.
