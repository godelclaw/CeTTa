!(register-module! ../codex)
!(import! &self codex:js_repl_stdout_run_tool)

(= (test:tool-calls)
   (codex:js-repl-register-exec-tool-calls-map
     (codex:js-repl-exec-tool-calls-map-empty)
     "exec-1"
     notify-1
     cancel-1))

(= (test:recent-stderr)
   (codex:js-repl-arc-mutex
     (codex:js-repl-recent-stderr-buffer
       (codex:js-repl-stderr-tail-line-limit)
       ("stderr tail"))))

(= (test:run-tool-request)
   (codex:js-repl-kernel-to-host-run-tool
     "tool-1"
     "exec-1"
     "shell"
     "{\"cmd\":\"pwd\"}"))

(= (test:spawn-result)
   (codex:js-repl-read-stdout-run-tool-step
     (test:run-tool-request)
     (test:tool-calls)
     stdin-1
     (codex:js-repl-stdin-write-ok)
     (codex:js-repl-stdin-write-ok)
     (codex:js-repl-child-inspection
       42
       (codex:js-repl-child-try-wait-running))
     (test:recent-stderr)))

!(assertEqual
  (codex:js-repl-read-stdout-run-tool-step-result-status
    (test:spawn-result))
  CodexJsReplReadStdoutRunToolStatusSpawned)

!(assertEqual
  (codex:js-repl-exec-tool-calls-state-in-flight
    (codex:js-repl-exec-tool-calls-map-find-state
      (codex:js-repl-read-stdout-run-tool-step-result-exec-tool-calls
        (test:spawn-result))
      "exec-1"))
  1)

!(assertEqual
  (codex:js-repl-read-stdout-run-tool-step-result-response
    (test:spawn-result))
  CodexAbsent)

!(assertEqual
  (codex:js-repl-read-stdout-run-tool-step-result-write-result
    (test:spawn-result))
  CodexAbsent)

!(assertEqual
  (codex:js-repl-read-stdout-run-tool-step-result-actions
    (test:spawn-result))
  ((CodexJsReplReadStdoutRunToolActionSpawnTask
     (CodexJsReplKernelToHostRunTool
       "tool-1"
       "exec-1"
       "shell"
       "{\"cmd\":\"pwd\"}")
     cancel-1)))

!(assertEqual
  (codex:js-repl-read-stdout-run-tool-step-result-warnings
    (test:spawn-result))
  ())

(= (test:missing-result)
   (codex:js-repl-read-stdout-run-tool-step
     (codex:js-repl-kernel-to-host-run-tool
       "tool-2"
       "missing-exec"
       "shell"
       "{\"cmd\":\"pwd\"}")
     (codex:js-repl-exec-tool-calls-map-empty)
     stdin-1
     (codex:js-repl-stdin-write-ok)
     (codex:js-repl-stdin-write-ok)
     (codex:js-repl-child-inspection
       42
       (codex:js-repl-child-try-wait-running))
     (test:recent-stderr)))

!(assertEqual
  (codex:js-repl-read-stdout-run-tool-step-result-status
    (test:missing-result))
  CodexJsReplReadStdoutRunToolStatusRepliedMissingContext)

!(assertEqual
  (codex:js-repl-read-stdout-run-tool-step-result-response
    (test:missing-result))
  (CodexJsReplHostToKernelRunToolResult
    (CodexJsReplRunToolResult
      "tool-2"
      False
      CodexAbsent
      "js_repl exec context not found")))

!(assertEqual
  (codex:js-repl-read-stdout-run-tool-step-result-actions
    (test:missing-result))
  ((CodexJsReplReadStdoutRunToolActionWriteMessage
     (CodexJsReplHostToKernelRunToolResult
       (CodexJsReplRunToolResult
         "tool-2"
         False
         CodexAbsent
         "js_repl exec context not found"))
     (CodexJsReplWriteMessageOk
       ((CodexJsReplStdinWrite
          stdin-1
          "{\"type\":\"run_tool_result\",\"id\":\"tool-2\",\"ok\":false,\"response\":null,\"error\":\"js_repl exec context not found\"}")
        (CodexJsReplStdinWrite stdin-1 "\n"))))))

!(assertEqual
  (codex:js-repl-read-stdout-run-tool-step-result-warnings
    (test:missing-result))
  ())

(= (test:write-error-result)
   (codex:js-repl-read-stdout-run-tool-step
     (codex:js-repl-kernel-to-host-run-tool
       "tool-3"
       "missing-exec"
       "shell"
       "{\"cmd\":\"pwd\"}")
     (codex:js-repl-exec-tool-calls-map-empty)
     stdin-1
     (codex:js-repl-stdin-write-error "broken pipe")
     (codex:js-repl-stdin-write-ok)
     (codex:js-repl-child-inspection
       42
       (codex:js-repl-child-try-wait-exited
         (codex:js-repl-exit-status-code 9)))
     (test:recent-stderr)))

!(assertEqual
  (codex:js-repl-read-stdout-run-tool-step-result-warnings
    (test:write-error-result))
  ((CodexJsReplReadStdoutRunToolWarningWriteFailed
     "failed to reply to kernel run_tool request"
     "missing-exec"
     "tool-3"
     "failed to write to kernel: broken pipe"
     (CodexJsReplKernelDebugSnapshot
       42
       "exited(code=9)"
       "stderr tail"))))
