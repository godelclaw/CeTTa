; Narrow Rust-faithful CodexErr slice.
;
; This ports the visible minimum needed from:
; - openai-codex/codex-rs/protocol/src/error.rs
;
; Covered in this increment:
; - CodexErr::Fatal
; - CodexErr::InvalidRequest
; - CodexErr::ThreadNotFound
; - CodexErr::AgentLimitReached
; - CodexErr::InternalAgentDied
; - CodexErr::UnsupportedOperation
; - EnvVarError / CodexErr::EnvVar display surface
; - display formatting for the ported variants
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

(= (codex:error-thread-not-found $thread-id)
   (CodexErrThreadNotFound $thread-id))

(= (codex:error-thread-not-found-thread-id
      (CodexErrThreadNotFound $thread-id))
   $thread-id)

(= (codex:error-agent-limit-reached $max-threads)
   (CodexErrAgentLimitReached $max-threads))

(= (codex:error-agent-limit-reached-max-threads
      (CodexErrAgentLimitReached $max-threads))
   $max-threads)

(= (codex:error-internal-agent-died)
   (CodexErrInternalAgentDied))

(= (codex:error-unsupported-operation $message)
   (CodexErrUnsupportedOperation $message))

(= (codex:error-unsupported-operation-message
      (CodexErrUnsupportedOperation $message))
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

(= (codex:error-display (CodexErrThreadNotFound $thread-id))
   (format-args "no thread with id: {}" ($thread-id)))

(= (codex:error-display (CodexErrAgentLimitReached $max-threads))
   (format-args
     "agent thread limit reached (max {})"
     ($max-threads)))

(= (codex:error-display (CodexErrInternalAgentDied))
   "internal error; agent loop died unexpectedly")

(= (codex:error-display (CodexErrUnsupportedOperation $message))
   (str-concat "unsupported operation: " $message))

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
