; Rust-faithful CodexErr slice: turn-loop variants.
;
; This ports the additional CodexErr variants the turn loop dispatches on
; from:
; - openai-codex/codex-rs/protocol/src/error.rs
;
; Covered in this increment:
; - CodexErr::TurnAborted
; - CodexErr::InvalidImageRequest
; - CodexErr::ContextWindowExceeded
; - CodexErr::UsageLimitReached
; - CodexErr::Stream (message plus optional server-suggested retry delay)
; - CodexErr::Timeout
; - CodexErr::is_retryable over all ported variants
;
; Required slice-local deviations from Rust, documented for audit:
; - These variants live apart from codex/error.metta because extending that
;   module broke an importer's previously-green surface (the documented
;   module-growth evaluator failure mode; see
;   tests/repro_evaluator_materialization.metta). Function names keep the
;   codex:error-* prefix: it is the same Rust enum surface, only housed in
;   a second file. is_retryable matches base-module variants through their
;   inert constructor terms without importing the module.
; - Rust's Stream delay is Option<Duration>; the port carries milliseconds
;   or CodexAbsent.

(= (codex:error-turn-aborted)
   (CodexErrTurnAborted))

(= (codex:error-invalid-image-request)
   (CodexErrInvalidImageRequest))

(= (codex:error-context-window-exceeded)
   (CodexErrContextWindowExceeded))

; Rust: CodexErr::UsageLimitReached(UsageLimitReachedError) — the payload
; carries optional rate-limit data the retry wrapper forwards to the
; session before passing the error through.
(= (codex:error-usage-limit-reached $rate-limits)
   (CodexErrUsageLimitReached $rate-limits))

(= (codex:error-usage-limit-reached-rate-limits
      (CodexErrUsageLimitReached $rate-limits))
   $rate-limits)

(= (codex:error-stream $message $requested-delay-ms)
   (CodexErrStream $message $requested-delay-ms))

(= (codex:error-stream-message (CodexErrStream $message $requested-delay-ms))
   $message)

(= (codex:error-stream-requested-delay-ms
      (CodexErrStream $message $requested-delay-ms))
   $requested-delay-ms)

(= (codex:error-timeout)
   (CodexErrTimeout))

; --- is_retryable ------------------------------------------------------------

; Mirrors protocol/src/error.rs CodexErr::is_retryable for the ported
; variants: Stream/Timeout/InternalAgentDied retry; the rest do not.
(= (codex:error-is-retryable (CodexErrStream $message $requested-delay-ms))
   True)

(= (codex:error-is-retryable (CodexErrTimeout))
   True)

(= (codex:error-is-retryable (CodexErrInternalAgentDied))
   True)

(= (codex:error-is-retryable (CodexErrTurnAborted))
   False)

(= (codex:error-is-retryable (CodexErrInvalidImageRequest))
   False)

(= (codex:error-is-retryable (CodexErrContextWindowExceeded))
   False)

(= (codex:error-is-retryable (CodexErrUsageLimitReached $rate-limits))
   False)

(= (codex:error-is-retryable (CodexErrFatal $message))
   False)

(= (codex:error-is-retryable (CodexErrInvalidRequest $message))
   False)

(= (codex:error-is-retryable (CodexErrThreadNotFound $thread-id))
   False)

(= (codex:error-is-retryable (CodexErrAgentLimitReached $max-threads))
   False)

(= (codex:error-is-retryable (CodexErrUnsupportedOperation $message))
   False)

(= (codex:error-is-retryable (CodexErrEnvVar $env-var-error))
   False)
