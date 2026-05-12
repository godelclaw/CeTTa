## CeTTa Evaluator/Test Isolation Technical Debt

This is a recurring CeTTa evaluator sensitivity in the restarted Codex
surfaces. It is technical debt, not a normal testing style.

Observed pattern:
- Large or repeated assertion groups that each independently pass can miscompare when combined in one `.metta` surface file.
- Large fixture-turn JSON assertions and redirected-output runs are more likely to trigger the issue.

Repeated cases currently split for stability:
- `tests/test_codex_approval_surface.metta`
  `tests/test_codex_approval_unless_trusted_surface.metta`
- `tests/test_codex_apply_patch_surface.metta`
  `tests/test_codex_apply_patch_output_direct_surface.metta`
  `tests/test_codex_apply_patch_output_shell_surface.metta`
  `tests/test_codex_apply_patch_struct_surface.metta`
  `tests/test_codex_apply_patch_reject_surface.metta`
- `tests/test_codex_request_user_input_surface.metta`
  `tests/test_codex_request_user_input_turn_final_surface.metta`
  `tests/test_codex_request_user_input_turn_output_surface.metta`
  `tests/test_codex_request_user_input_turn_phase_surface.metta`
  Default-mode tool-call output extraction is also evaluator-sensitive; use a
  single `once` around the tool wrapper before reading the output text.
  Multi-step fixture-turn assembly around a request_user_input step is also
  brittle; the stable checks go through smaller `fixture-steps-items` /
  direct item assertions instead of one four-step turn, and the
  `final-response-from-items` selector can still collapse to `Empty` on that
  mixed computed item list even when the final-answer item is present.
- `tests/test_codex_request_permissions_surface.metta`
  `tests/test_codex_request_permissions_cancel_surface.metta`
  `tests/test_codex_request_permissions_granular_surface.metta`
  `tests/test_codex_request_permissions_handler_output_surface.metta`
  `tests/test_codex_request_permissions_state_surface.metta`
  `tests/test_codex_request_permissions_apply_patch_runtime_shape_surface.metta`
  `tests/test_codex_request_permissions_apply_patch_runtime_apply_surface.metta`
  `tests/test_codex_request_permissions_apply_patch_strict_shape_surface.metta`
  `tests/test_codex_request_permissions_apply_patch_strict_apply_surface.metta`
  Handler event/output/state assertions were rewritten to stable constructor and
  response-result checks because direct handler binding/extraction can collapse
  to `Empty` in combined evaluator runs.
  The cancellation-message assertion also has to live in its own file and read
  through the tool-call-result wrapper; direct handler-message extraction can
  still collapse to `Empty` in combined runs.
  The granular-approval short-circuit branch now also asserts through the
  stable `handle-request-permissions-payload` output instead of the smaller
  tool-call wrapper, because that wrapper can collapse to `Empty` even when the
  underlying handler output is present.
  The request_permissions + apply_patch lane hit the same pattern again:
  one combined surface file could pass in isolation but fail in the full sweep
  after a neighboring mutating check changed the file baseline. The stable
  coverage now resets the target files explicitly and keeps runtime-shape vs
  runtime-apply / strict-shape vs strict-apply in separate files.
- `tests/test_codex_tools_surface.metta`
  `tests/test_codex_tools_exec_exit_surface.metta`
  `tests/test_codex_tools_exec_stdout_surface.metta`
  `tests/test_codex_tools_exec_text_surface.metta`
  `tests/test_codex_tools_exec_tool_call_surface.metta`
  `tests/test_codex_tools_permissions_parse_surface.metta`
  `tests/test_codex_tools_permissions_state_surface.metta`
  `tests/test_codex_tools_permissions_exec_surface.metta`
  `tests/test_codex_tools_write_stdin_error_surface.metta`
  `tests/test_codex_tools_live_background_surface.metta`
  `tests/test_codex_tools_exec_events_surface.metta`
  `tests/test_codex_tools_write_stdin_events_surface.metta`
  Repeated session-backed `exec_command` / tool-call assertions do not stay
  stable in one combined surface file; the evaluator can re-materialize the
  session-backed term and intermittently observe the still-running branch
  instead of the settled one-shot result. These checks now live in one-purpose
  files and still keep a single `once` around the live expression.
  Two smaller selectors are currently brittle even in one-purpose files:
  the direct `run-write-stdin-output-text` assertion path and the direct
  `parse-exec-command-args` -> `exec-command-additional-permissions` relative
  path normalization assertion. The committed green surfaces therefore pin
  those checks at the stable lowered boundaries instead:
  constructor/result-text lowering for the write_stdin error lane, and stable
  permission-profile JSON construction plus the separate sandbox-permission
  resolver assertion for the additional-permissions lane. The runtime behavior
  itself remains covered by the public demos and the broader green
  permission/exec surfaces.
  The permission-aware exec surfaces hit the same pattern: structural state and
  parse checks are stable in their own small files, while the live branch needs
  `once` around the exec wrapper before any output extraction. Exact output
  equality on the disabled-inline rejection branch was still brittle, so that
  case stays at substring level until the evaluator/output-capture behavior is
  fixed.
  The helper-only resumed-session metadata assertions that previously lived in
  `tests/test_codex_tools_live_surface.metta` are currently not kept as
  committed green surfaces after the watcher-thread port. The public live
  coverage remains in the background-drain surface and the write_stdin error
  surface; happy-path resumed-helper metadata checks are deferred until the
  helper/runtime timing can be stabilized again.
  The same evaluator behavior currently makes live multi-item event lowering
  from a real `exec_command` tool call brittle: direct tool-call -> event-list
  helper wrappers collapsed to `Empty` even though the underlying
  `CodexExecCommandRun` value was present and printable. The committed green
  event coverage therefore stays at the deterministic run/result-composition
  layer plus protocol JSON surfaces instead of a live tool-call event-list
  surface.

Current workaround:
- Keep high-risk assertion clusters in separate surface files.
- Prefer smaller structural assertions over one giant full-turn JSON equality.
- For mutating patch/exec assertions, keep the side effect in the smallest
  possible file and avoid re-evaluating the same expression through multiple
  accessors inside one assertion group.

Desired fix:
- Identify and fix the evaluator/output-capture behavior so these cases can be
  recombined into the logically natural test files without changing coverage.
