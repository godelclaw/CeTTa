; Narrow Rust-faithful CodexErr slice.
;
; This ports the visible minimum needed from:
; - openai-codex/codex-rs/protocol/src/error.rs
;
; Covered in this increment:
; - CodexErr::Fatal
; - display formatting for the Fatal variant
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust exposes a full enum with `thiserror` display impls. The current CeTTa
;   slice ports only the Fatal branch required by the session-init mapper.

!(import! &self str)

(= (codex:error-fatal $message)
   (CodexErrFatal $message))

(= (codex:error-fatal-message (CodexErrFatal $message))
   $message)

(= (codex:error-display (CodexErrFatal $message))
   (str-concat "Fatal error: " $message))
