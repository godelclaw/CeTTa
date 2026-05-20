; Rust-faithful user-shell-command record bridge.
;
; This ports the visible pure behavior from:
; - openai-codex/codex-rs/core/src/user_shell_command.rs
; - openai-codex/codex-rs/core/src/tools/mod.rs::format_exec_output_str
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust receives a full `TurnContext` and reads `turn_context.truncation_policy`.
;   The current CeTTa slice receives the already-lowered `max_output_tokens`
;   value used by adjacent tool-formatting helpers.
; - Rust's `ExecToolCallOutput.duration` is a `Duration`; this CeTTa surface
;   keeps the duration in milliseconds, matching the surrounding restarted exec
;   runtime slices.

!(import! &self context_fragment)
!(import! &self tools)

(= (codex:exec-tool-call-output
      $exit-code
      $stdout
      $stderr
      $aggregated-output
      $duration-ms
      $timed-out)
   (CodexExecToolCallOutput
     $exit-code
     $stdout
     $stderr
     $aggregated-output
     $duration-ms
     $timed-out))

(= (codex:exec-tool-call-output-exit-code
      (CodexExecToolCallOutput
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $timed-out))
   $exit-code)

(= (codex:exec-tool-call-output-stdout
      (CodexExecToolCallOutput
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $timed-out))
   $stdout)

(= (codex:exec-tool-call-output-stderr
      (CodexExecToolCallOutput
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $timed-out))
   $stderr)

(= (codex:exec-tool-call-output-aggregated-output
      (CodexExecToolCallOutput
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $timed-out))
   $aggregated-output)

(= (codex:exec-tool-call-output-duration-ms
      (CodexExecToolCallOutput
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $timed-out))
   $duration-ms)

(= (codex:exec-tool-call-output-timed-out
      (CodexExecToolCallOutput
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $timed-out))
   $timed-out)

(= (codex:user-shell-build-content-with-timeout
      (CodexExecToolCallOutput
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        True))
   (format-args
     "command timed out after {} milliseconds\n{}"
     ($duration-ms $aggregated-output)))

(= (codex:user-shell-build-content-with-timeout
      (CodexExecToolCallOutput
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        False))
   $aggregated-output)

(= (codex:user-shell-format-exec-output-str $exec-output $max-output-tokens)
   (once
     (codex:format-truncated-output
       (codex:user-shell-build-content-with-timeout $exec-output)
       $max-output-tokens)))

(= (codex:format-user-shell-command-record
      $command
      $exec-output
      $max-output-tokens)
   (once
     (codex:contextual-fragment-render
       (codex:user-shell-command
         $command
         (codex:exec-tool-call-output-exit-code $exec-output)
         (codex:exec-tool-call-output-duration-ms $exec-output)
         (codex:user-shell-format-exec-output-str
           $exec-output
           $max-output-tokens)))))

(= (codex:user-shell-command-record-item
      $command
      $exec-output
      $max-output-tokens)
   (once
     (codex:contextual-fragment-response-item
       (codex:user-shell-command
         $command
         (codex:exec-tool-call-output-exit-code $exec-output)
         (codex:exec-tool-call-output-duration-ms $exec-output)
         (codex:user-shell-format-exec-output-str
           $exec-output
           $max-output-tokens)))))
