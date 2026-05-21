!(register-module! ../codex)
!(import! &self codex:js_repl_run_tool_task_flow)

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

(= (test:flow-context)
   (codex:js-repl-run-tool-request-flow-context
     tools-config-1
     (mcp-tools-1)
     ()
     ((codex:js-repl-run-tool-function-spec "exec_command"))
     ()))

(= (test:contexts)
   (codex:js-repl-run-tool-exec-contexts
     ((codex:js-repl-run-tool-exec-context-entry
        "exec-1"
        (test:flow-context)))))

(= (test:recent-stderr)
   (codex:js-repl-arc-mutex
     (codex:js-repl-recent-stderr-buffer
       (codex:js-repl-stderr-tail-line-limit)
       ("stderr tail"))))

(= (test:request)
   (codex:js-repl-kernel-to-host-run-tool
     "tool-1"
     "exec-1"
     "exec_command"
     "{\"cmd\":\"pwd\"}"))

(= (test:response-json)
   (JsonObject
     ((JsonPair "type" (JsonString "function_call_output"))
      (JsonPair "call_id" (JsonString "tool-1"))
      (JsonPair "output" (JsonString "ok")))))

(= (test:task-result)
   (codex:js-repl-run-tool-task-step-with-request-flow
     (test:request)
     (test:contexts)
     (test:in-flight-tool-calls)
     (codex:js-repl-run-tool-task-observation-run-request-flow
       (codex:js-repl-run-tool-dispatch-ok
         (codex:js-repl-run-tool-any-tool-result
           "tool-1"
           (CodexToolPayloadFunction "{\"cmd\":\"pwd\"}")
           (CodexToolOutputFunction
             ((CodexInputText "ok"))
             True
             CodexAbsent)
           CodexAbsent)))
     stdin-1
     (codex:js-repl-stdin-write-ok)
     (codex:js-repl-stdin-write-ok)
     (test:recent-stderr)))

!(assertEqual
  (case (test:task-result)
    (((CodexJsReplRunToolTaskResult
        $exec-tool-calls $run-tool-result $response $write-result
        $actions $warnings)
      $run-tool-result)))
  (CodexJsReplRunToolResult
    "tool-1"
    True
    (test:response-json)
    CodexAbsent))

!(assertEqual
  (case (test:task-result)
    (((CodexJsReplRunToolTaskResult
        $exec-tool-calls $run-tool-result $response $write-result
        $actions $warnings)
      (codex:js-repl-exec-tool-calls-state-in-flight
        (codex:js-repl-exec-tool-calls-map-find-state
          $exec-tool-calls
          "exec-1")))))
  0)

!(assertEqual
  (case (test:task-result)
    (((CodexJsReplRunToolTaskResult
        $exec-tool-calls $run-tool-result $response $write-result
        $actions $warnings)
      $actions)))
  ((CodexJsReplRunToolRequestActionLogToolCallResponse
     "js_repl nested tool call completed"
     "exec-1"
     "tool-1"
     "exec_command"
     True
     (CodexJsReplToolCallResponseSummary
       "function_call_output"
       (CodexJsReplToolCallPayloadKindFunctionText)
       "ok"
       2
       CodexAbsent
       CodexAbsent
       CodexAbsent
       CodexAbsent
       CodexAbsent)
     (test:response-json)
     CodexAbsent)
   (CodexJsReplExecToolCallActionNotifyWaiters notify-1)
   (CodexJsReplReadStdoutRunToolActionWriteMessage
     (CodexJsReplHostToKernelRunToolResult
       (CodexJsReplRunToolResult
         "tool-1"
         True
         (test:response-json)
         CodexAbsent))
     (CodexJsReplWriteMessageOk
       ((CodexJsReplStdinWrite
          stdin-1
          "{\"type\":\"run_tool_result\",\"id\":\"tool-1\",\"ok\":true,\"response\":{\"type\":\"function_call_output\",\"call_id\":\"tool-1\",\"output\":\"ok\"},\"error\":null}")
        (CodexJsReplStdinWrite stdin-1 "\n"))))))

!(assertEqual
  (case (test:task-result)
    (((CodexJsReplRunToolTaskResult
        $exec-tool-calls $run-tool-result $response $write-result
        $actions $warnings)
      $warnings)))
  ())
