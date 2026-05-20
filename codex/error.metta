; Narrow Rust-faithful CodexErr slice.
;
; This ports the visible minimum needed from:
; - openai-codex/codex-rs/protocol/src/error.rs
;
; Covered in this increment:
; - CodexErr::Fatal
; - CodexErr::InvalidRequest
; - EnvVarError / CodexErr::EnvVar display surface
; - display formatting for the Fatal variant
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust exposes a full enum with `thiserror` display impls. The current CeTTa
;   slice ports the variants required by active CeTTa Codex modules.

!(import! &self str)

(= (codex:error-fatal $message)
   (CodexErrFatal $message))

(= (codex:error-fatal-message (CodexErrFatal $message))
   $message)

(= (codex:error-invalid-request $message)
   (CodexErrInvalidRequest $message))

(= (codex:error-invalid-request-message (CodexErrInvalidRequest $message))
   $message)

(= (codex:env-var-error $var $instructions)
   (CodexEnvVarError $var $instructions))

(= (codex:env-var-error-var (CodexEnvVarError $var $instructions))
   $var)

(= (codex:env-var-error-instructions (CodexEnvVarError $var $instructions))
   $instructions)

(= (codex:error-env-var $env-var-error)
   (case $env-var-error
     (($materialized-error
       (CodexErrEnvVar $materialized-error)))))

(= (codex:error-display (CodexErrFatal $message))
   (str-concat "Fatal error: " $message))

(= (codex:error-display (CodexErrInvalidRequest $message))
   $message)

(= (codex:env-var-error-display (CodexEnvVarError $var $instructions))
   (if (== $instructions CodexAbsent)
       (str-concat "Missing environment variable: `"
         (str-concat $var "`."))
       (str-concat
         (str-concat "Missing environment variable: `"
           (str-concat $var "`. "))
         $instructions)))

(= (codex:error-display (CodexErrEnvVar $env-var-error))
   (codex:env-var-error-display $env-var-error))
