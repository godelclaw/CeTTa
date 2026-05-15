; Narrow Rust-faithful FunctionCallError slice.
;
; This ports:
; - openai-codex/codex-rs/core/src/function_tool.rs
;
; Covered in this increment:
; - FunctionCallError variants
; - display text matching the Rust `thiserror` strings
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust derives `Error` and `PartialEq`. The current CeTTa port preserves the
;   same visible variant/data surface with explicit constructors plus a display
;   helper instead of trait-derived formatting.

!(import! &self str)

(= (codex:function-call-error-respond-to-model $message)
   (CodexFunctionCallErrorRespondToModel $message))

(= (codex:function-call-error-missing-local-shell-call-id)
   (CodexFunctionCallErrorMissingLocalShellCallId))

(= (codex:function-call-error-fatal $message)
   (CodexFunctionCallErrorFatal $message))

(= (codex:function-call-error-display
      (CodexFunctionCallErrorRespondToModel $message))
   $message)

(= (codex:function-call-error-display
      (CodexFunctionCallErrorMissingLocalShellCallId))
   "LocalShellCall without call_id or id")

(= (codex:function-call-error-display
      (CodexFunctionCallErrorFatal $message))
   (str-concat "Fatal error: " $message))
