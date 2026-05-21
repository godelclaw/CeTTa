!(register-module! ../codex)
!(import! &self codex:js_repl_stdout_run_tool_task)

(= (test:registered-tool-calls)
   (codex:js-repl-register-exec-tool-calls-map
     (codex:js-repl-exec-tool-calls-map-empty)
     "exec-1"
     notify-1
     cancel-1))

(= (test:in-flight-tool-calls)
   (codex:js-repl-begin-exec-tool-call-result-map
     (codex:js-repl-begin-exec-tool-call-map
       (test:registered-tool-calls)
       "exec-1")))

(= (test:contexts)
   (codex:js-repl-run-tool-exec-contexts
     ((codex:js-repl-run-tool-exec-context-entry
        "exec-1"
        context-1))))

(= (test:recent-stderr)
   (codex:js-repl-arc-mutex
     (codex:js-repl-recent-stderr-buffer
       (codex:js-repl-stderr-tail-line-limit)
       ("stderr tail"))))

(= (test:request)
   (codex:js-repl-kernel-to-host-run-tool
     "tool-1"
     "exec-1"
     "shell"
     "{\"cmd\":\"pwd\"}"))

(= (test:ok-task-result)
   (codex:js-repl-run-tool-task-step
     (test:request)
     (test:contexts)
     (test:in-flight-tool-calls)
     (codex:js-repl-run-tool-task-observation-run-completed
       (codex:js-repl-run-tool-result
         "tool-1"
         True
         (JsonObject ((JsonPair "text" (JsonString "ok"))))
         CodexAbsent))
     stdin-1
     (codex:js-repl-stdin-write-ok)
     (codex:js-repl-stdin-write-ok)
     (test:recent-stderr)))

!(assertEqual
  (case (test:ok-task-result)
    (((CodexJsReplRunToolTaskResult
        $exec-tool-calls $run-tool-result $response $write-result
        $actions $warnings)
      (codex:js-repl-exec-tool-calls-state-in-flight
        (codex:js-repl-exec-tool-calls-map-find-state
          $exec-tool-calls
          "exec-1")))))
  0)

!(assertEqual
  (case (test:ok-task-result)
    (((CodexJsReplRunToolTaskResult
        $exec-tool-calls $run-tool-result $response $write-result
        $actions $warnings)
      $run-tool-result)))
  (CodexJsReplRunToolResult
    "tool-1"
    True
    (JsonObject ((JsonPair "text" (JsonString "ok"))))
    CodexAbsent))

!(assertEqual
  (case (test:ok-task-result)
    (((CodexJsReplRunToolTaskResult
        $exec-tool-calls $run-tool-result $response $write-result
        $actions $warnings)
      $actions)))
  ((CodexJsReplExecToolCallActionNotifyWaiters notify-1)
   (CodexJsReplReadStdoutRunToolActionWriteMessage
     (CodexJsReplHostToKernelRunToolResult
       (CodexJsReplRunToolResult
         "tool-1"
         True
         (JsonObject ((JsonPair "text" (JsonString "ok"))))
         CodexAbsent))
     (CodexJsReplWriteMessageOk
       ((CodexJsReplStdinWrite
          stdin-1
          "{\"type\":\"run_tool_result\",\"id\":\"tool-1\",\"ok\":true,\"response\":{\"text\":\"ok\"},\"error\":null}")
        (CodexJsReplStdinWrite stdin-1 "\n"))))))

!(assertEqual
  (case (test:ok-task-result)
    (((CodexJsReplRunToolTaskResult
        $exec-tool-calls $run-tool-result $response $write-result
        $actions $warnings)
      $warnings)))
  ())

(= (test:reset-task-result)
   (codex:js-repl-run-tool-task-step
     (test:request)
     (test:contexts)
     (test:in-flight-tool-calls)
     (codex:js-repl-run-tool-task-observation-reset-cancelled)
     stdin-1
     (codex:js-repl-stdin-write-ok)
     (codex:js-repl-stdin-write-ok)
     (test:recent-stderr)))

!(assertEqual
  (case (test:reset-task-result)
    (((CodexJsReplRunToolTaskResult
        $exec-tool-calls $run-tool-result $response $write-result
        $actions $warnings)
      $run-tool-result)))
  (CodexJsReplRunToolResult
    "tool-1"
    False
    CodexAbsent
    "js_repl execution reset"))

(= (test:missing-context-task-result)
   (codex:js-repl-run-tool-task-step
     (test:request)
     (codex:js-repl-run-tool-exec-contexts ())
     (test:in-flight-tool-calls)
     (codex:js-repl-run-tool-task-observation-run-completed
       (codex:js-repl-run-tool-result
         "tool-1"
         True
         (JsonObject ((JsonPair "text" (JsonString "ignored"))))
         CodexAbsent))
     stdin-1
     (codex:js-repl-stdin-write-ok)
     (codex:js-repl-stdin-write-ok)
     (test:recent-stderr)))

!(assertEqual
  (case (test:missing-context-task-result)
    (((CodexJsReplRunToolTaskResult
        $exec-tool-calls $run-tool-result $response $write-result
        $actions $warnings)
      $run-tool-result)))
  (CodexJsReplRunToolResult
    "tool-1"
    False
    CodexAbsent
    "js_repl exec context not found"))

(= (test:write-error-task-result)
   (codex:js-repl-run-tool-task-step
     (test:request)
     (test:contexts)
     (test:in-flight-tool-calls)
     (codex:js-repl-run-tool-task-observation-run-completed
       (codex:js-repl-run-tool-result
         "tool-1"
         False
         CodexAbsent
         "tool failed"))
     stdin-1
     (codex:js-repl-stdin-write-error "broken pipe")
     (codex:js-repl-stdin-write-ok)
     (test:recent-stderr)))

!(assertEqual
  (case (test:write-error-task-result)
    (((CodexJsReplRunToolTaskResult
        $exec-tool-calls $run-tool-result $response $write-result
        $actions $warnings)
      $warnings)))
  ((CodexJsReplRunToolTaskWarningWriteFailed
     "failed to reply to kernel run_tool request"
     "exec-1"
     "tool-1"
     "shell"
     "failed to write to kernel: broken pipe"
     "stderr tail")))
