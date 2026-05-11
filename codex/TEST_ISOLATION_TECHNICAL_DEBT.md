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
  Handler event/output/state assertions were rewritten to stable constructor and
  response-result checks because direct handler binding/extraction can collapse
  to `Empty` in combined evaluator runs.
  The cancellation-message assertion also has to live in its own file and read
  through the tool-call-result wrapper; direct handler-message extraction can
  still collapse to `Empty` in combined runs.
- `tests/test_codex_tools_surface.metta`
  `tests/test_codex_tools_exec_exit_surface.metta`
  `tests/test_codex_tools_exec_stdout_surface.metta`
  `tests/test_codex_tools_exec_text_surface.metta`
  `tests/test_codex_tools_exec_tool_call_surface.metta`
  Repeated session-backed `exec_command` / tool-call assertions do not stay
  stable in one combined surface file; the evaluator can re-materialize the
  session-backed term and intermittently observe the still-running branch
  instead of the settled one-shot result. These checks now live in one-purpose
  files and still keep a single `once` around the live expression.

Current workaround:
- Keep high-risk assertion clusters in separate surface files.
- Prefer smaller structural assertions over one giant full-turn JSON equality.
- For mutating patch/exec assertions, keep the side effect in the smallest
  possible file and avoid re-evaluating the same expression through multiple
  accessors inside one assertion group.

Desired fix:
- Identify and fix the evaluator/output-capture behavior so these cases can be
  recombined into the logically natural test files without changing coverage.
