!(register-module! ../codex)
!(import! &self codex:js_repl)

!(assertEqual
  (codex:js-repl-stderr-tail-line-limit)
  20)

!(assertEqual
  (codex:js-repl-stderr-tail-line-max-bytes)
  512)

!(assertEqual
  (codex:js-repl-stderr-tail-max-bytes)
  4096)

!(assertEqual
  (codex:js-repl-stderr-tail-separator)
  " | ")

!(assertEqual
  (codex:js-repl-exec-id-log-limit)
  8)

!(assertEqual
  (codex:js-repl-model-diag-stderr-max-bytes)
  1024)

!(assertEqual
  (codex:js-repl-model-diag-error-max-bytes)
  256)

!(assertEqual
  (codex:js-repl-top-level-exec-state-registered-exec-id
    (codex:js-repl-top-level-exec-state-idle))
  CodexAbsent)

!(assertEqual
  (codex:js-repl-top-level-exec-state-registered-exec-id
    (codex:js-repl-top-level-exec-state-fresh-kernel
      "turn-1"
      CodexAbsent))
  CodexAbsent)

!(assertEqual
  (codex:js-repl-top-level-exec-state-registered-exec-id
    (codex:js-repl-top-level-exec-state-submitted
      "turn-1"
      "exec-1"))
  "exec-1")

!(assertEqual
  (codex:js-repl-top-level-exec-state-should-reset-for-interrupt
    (codex:js-repl-top-level-exec-state-fresh-kernel
      "turn-1"
      CodexAbsent)
    "turn-1")
  True)

!(assertEqual
  (codex:js-repl-top-level-exec-state-should-reset-for-interrupt
    (codex:js-repl-top-level-exec-state-reused-kernel-pending
      "turn-1"
      "exec-1")
    "turn-1")
  False)

!(assertEqual
  (codex:js-repl-register-top-level-exec-state
    (codex:js-repl-top-level-exec-state-fresh-kernel
      "turn-1"
      CodexAbsent)
    "exec-1"
    "turn-1")
  (CodexJsReplTopLevelExecStateFreshKernel "turn-1" "exec-1"))

!(assertEqual
  (codex:js-repl-register-top-level-exec-state
    (codex:js-repl-top-level-exec-state-idle)
    "exec-1"
    "turn-1")
  (CodexJsReplTopLevelExecStateReusedKernelPending "turn-1" "exec-1"))

!(assertEqual
  (codex:js-repl-mark-top-level-exec-submitted-state
    (codex:js-repl-top-level-exec-state-reused-kernel-pending
      "turn-1"
      "exec-1")
    "exec-1")
  (CodexJsReplTopLevelExecStateSubmitted "turn-1" "exec-1"))

!(assertEqual
  (codex:js-repl-clear-top-level-exec-if-matches-state
    (codex:js-repl-top-level-exec-state-submitted
      "turn-1"
      "exec-1")
    "exec-1")
  (CodexJsReplTopLevelExecStateIdle))

!(assertEqual
  (codex:js-repl-clear-top-level-exec-if-matches-any-state
    (codex:js-repl-top-level-exec-state-submitted
      "turn-1"
      "exec-2")
    ("exec-1" "exec-2"))
  (CodexJsReplTopLevelExecStateIdle))

!(assertEqual
  (codex:js-repl-kernel-stream-end-reason
    (codex:js-repl-kernel-stream-end-shutdown))
  "shutdown")

!(assertEqual
  (codex:js-repl-kernel-stream-end-reason
    (codex:js-repl-kernel-stream-end-stdout-read-error "bad read"))
  "stdout_read_error")

!(assertEqual
  (codex:js-repl-kernel-stream-end-error
    (codex:js-repl-kernel-stream-end-stdout-read-error "bad read"))
  "bad read")

!(assertEqual
  (codex:js-repl-kernel-stream-end-error
    (codex:js-repl-kernel-stream-end-stdout-eof))
  CodexAbsent)

!(assertEqual
  (codex:js-repl-truncate-utf8-prefix-by-bytes "abcdef" 3)
  "abc")

!(assertEqual
  (codex:js-repl-truncate-utf8-prefix-by-bytes "😀abc" 5)
  "😀a")

!(assertEqual
  (codex:js-repl-truncate-utf8-prefix-by-bytes "😀abc" 1)
  "")

!(assertEqual
  (codex:js-repl-format-stderr-tail ())
  "<empty>")

!(assertEqual
  (codex:js-repl-format-stderr-tail ("alpha" "beta"))
  "alpha | beta")

!(assertEqual
  (codex:js-repl-stderr-tail-formatted-bytes ("aa" "bbb"))
  8)

!(assertEqual
  (codex:js-repl-stderr-tail-bytes-with-candidate ("aa" "bbb") "c")
  12)

!(assertEqual
  (codex:js-repl-push-stderr-tail-line
    ("0" "1" "2" "3" "4" "5" "6" "7" "8" "9"
     "10" "11" "12" "13" "14" "15" "16" "17" "18" "19")
    "20")
  (CodexJsReplStderrTailPushResult
    ("1" "2" "3" "4" "5" "6" "7" "8" "9"
     "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20")
    "20"))

!(assertEqual
  (codex:js-repl-is-kernel-status-exited "exited(code=1)")
  True)

!(assertEqual
  (codex:js-repl-is-kernel-status-exited "running")
  False)

!(assertEqual
  (codex:js-repl-should-include-model-diagnostics-for-write-error
    "Broken pipe"
    (codex:js-repl-kernel-debug-snapshot CodexAbsent "running" "<empty>"))
  True)

!(assertEqual
  (codex:js-repl-should-include-model-diagnostics-for-write-error
    "write failed"
    (codex:js-repl-kernel-debug-snapshot 123 "exited(code=1)" "tail"))
  True)

!(assertEqual
  (codex:js-repl-should-include-model-diagnostics-for-write-error
    "permission denied"
    (codex:js-repl-kernel-debug-snapshot CodexAbsent "running" "tail"))
  False)

!(assertEqual
  (codex:js-repl-format-model-kernel-failure-details
    "write_failed"
    CodexAbsent
    (codex:js-repl-kernel-debug-snapshot CodexAbsent "running" "tail"))
  "js_repl diagnostics: {\"reason\":\"write_failed\",\"stream_error\":null,\"kernel_pid\":null,\"kernel_status\":\"running\",\"kernel_stderr_tail\":\"tail\"}")

!(assertEqual
  (codex:js-repl-with-model-kernel-failure-message
    "failed to write to kernel"
    "write_failed"
    "Broken pipe"
    (codex:js-repl-kernel-debug-snapshot 123 "exited(code=1)" "stderr"))
  "failed to write to kernel\n\njs_repl diagnostics: {\"reason\":\"write_failed\",\"stream_error\":\"Broken pipe\",\"kernel_pid\":123,\"kernel_status\":\"exited(code=1)\",\"kernel_stderr_tail\":\"stderr\"}")
