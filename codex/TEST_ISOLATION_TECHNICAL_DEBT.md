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
- `tests/test_codex_request_permissions_surface.metta`
  `tests/test_codex_request_permissions_cancel_surface.metta`
  Handler event/output/state assertions were rewritten to stable constructor and
  response-result checks because direct handler binding/extraction can collapse
  to `Empty` in combined evaluator runs.
  The cancellation-message assertion also has to live in its own file and read
  through the tool-call-result wrapper; direct handler-message extraction can
  still collapse to `Empty` in combined runs.

Current workaround:
- Keep high-risk assertion clusters in separate surface files.
- Prefer smaller structural assertions over one giant full-turn JSON equality.
- For mutating patch/exec assertions, keep the side effect in the smallest
  possible file and avoid re-evaluating the same expression through multiple
  accessors inside one assertion group.

Desired fix:
- Identify and fix the evaluator/output-capture behavior so these cases can be
  recombined into the logically natural test files without changing coverage.
