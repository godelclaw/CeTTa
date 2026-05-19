; Rust-faithful pure unified-exec state/error slice.
;
; This ports the deterministic state and error contracts from:
; - openai-codex/codex-rs/core/src/unified_exec/process_state.rs
; - openai-codex/codex-rs/core/src/unified_exec/errors.rs
;
; Covered in this increment:
; - ProcessState::default
; - ProcessState::exited
; - ProcessState::failed
; - UnifiedExecError variants and constructor helpers
; - UnifiedExecError display text from the Rust `thiserror` annotations
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust uses `Option<i32>` / `Option<String>`. This port follows the existing
;   CeTTa Codex convention and represents `None` as `CodexAbsent`; present
;   values are carried directly.
; - Rust `SandboxDenied` stores `ExecToolCallOutput` by value. The surrounding
;   CeTTa exec-output protocol surface is still split across context/tools
;   slices, so this constructor preserves the output as an opaque value until
;   the full unified-exec runtime boundary is ported.

(= (codex:unified-exec-process-state
      $has-exited
      $exit-code
      $failure-message)
   (CodexUnifiedExecProcessState
     $has-exited
     $exit-code
     $failure-message))

(= (codex:unified-exec-process-state-default)
   (CodexUnifiedExecProcessState False CodexAbsent CodexAbsent))

(= (codex:unified-exec-process-state-has-exited
      (CodexUnifiedExecProcessState
        $has-exited
        $exit-code
        $failure-message))
   $has-exited)

(= (codex:unified-exec-process-state-exit-code
      (CodexUnifiedExecProcessState
        $has-exited
        $exit-code
        $failure-message))
   $exit-code)

(= (codex:unified-exec-process-state-failure-message
      (CodexUnifiedExecProcessState
        $has-exited
        $exit-code
        $failure-message))
   $failure-message)

(= (codex:unified-exec-process-state-exited
      (CodexUnifiedExecProcessState
        $has-exited
        $current-exit-code
        $failure-message)
      $exit-code)
   (CodexUnifiedExecProcessState
     True
     $exit-code
     $failure-message))

(= (codex:unified-exec-process-state-failed
      (CodexUnifiedExecProcessState
        $has-exited
        $exit-code
        $failure-message)
      $message)
   (CodexUnifiedExecProcessState
     True
     $exit-code
     $message))

(= (codex:unified-exec-error-create-process $message)
   (CodexUnifiedExecErrorCreateProcess $message))

(= (codex:unified-exec-error-process-failed $message)
   (CodexUnifiedExecErrorProcessFailed $message))

(= (codex:unified-exec-error-unknown-process-id $process-id)
   (CodexUnifiedExecErrorUnknownProcessId $process-id))

(= (codex:unified-exec-error-write-to-stdin)
   CodexUnifiedExecErrorWriteToStdin)

(= (codex:unified-exec-error-stdin-closed)
   CodexUnifiedExecErrorStdinClosed)

(= (codex:unified-exec-error-missing-command-line)
   CodexUnifiedExecErrorMissingCommandLine)

(= (codex:unified-exec-error-sandbox-denied $message $output)
   (CodexUnifiedExecErrorSandboxDenied $message $output))

(= (codex:unified-exec-error-kind
      (CodexUnifiedExecErrorCreateProcess $message))
   create_process)

(= (codex:unified-exec-error-kind
      (CodexUnifiedExecErrorProcessFailed $message))
   process_failed)

(= (codex:unified-exec-error-kind
      (CodexUnifiedExecErrorUnknownProcessId $process-id))
   unknown_process_id)

(= (codex:unified-exec-error-kind CodexUnifiedExecErrorWriteToStdin)
   write_to_stdin)

(= (codex:unified-exec-error-kind CodexUnifiedExecErrorStdinClosed)
   stdin_closed)

(= (codex:unified-exec-error-kind CodexUnifiedExecErrorMissingCommandLine)
   missing_command_line)

(= (codex:unified-exec-error-kind
      (CodexUnifiedExecErrorSandboxDenied $message $output))
   sandbox_denied)

(= (codex:unified-exec-error-message
      (CodexUnifiedExecErrorCreateProcess $message))
   $message)

(= (codex:unified-exec-error-message
      (CodexUnifiedExecErrorProcessFailed $message))
   $message)

(= (codex:unified-exec-error-message
      (CodexUnifiedExecErrorSandboxDenied $message $output))
   $message)

(= (codex:unified-exec-error-process-id
      (CodexUnifiedExecErrorUnknownProcessId $process-id))
   $process-id)

(= (codex:unified-exec-error-output
      (CodexUnifiedExecErrorSandboxDenied $message $output))
   $output)

(= (codex:unified-exec-error-display
      (CodexUnifiedExecErrorCreateProcess $message))
   (format-args
     "Failed to create unified exec process: {}"
     ($message)))

(= (codex:unified-exec-error-display
      (CodexUnifiedExecErrorProcessFailed $message))
   (format-args
     "Unified exec process failed: {}"
     ($message)))

(= (codex:unified-exec-error-display
      (CodexUnifiedExecErrorUnknownProcessId $process-id))
   (format-args
     "Unknown process id {}"
     ($process-id)))

(= (codex:unified-exec-error-display CodexUnifiedExecErrorWriteToStdin)
   "failed to write to stdin")

(= (codex:unified-exec-error-display CodexUnifiedExecErrorStdinClosed)
   "stdin is closed for this session; rerun exec_command with tty=true to keep stdin open")

(= (codex:unified-exec-error-display CodexUnifiedExecErrorMissingCommandLine)
   "missing command line for unified exec request")

(= (codex:unified-exec-error-display
      (CodexUnifiedExecErrorSandboxDenied $message $output))
   (format-args
     "Command denied by sandbox: {}"
     ($message)))
