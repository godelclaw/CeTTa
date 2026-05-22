!(register-module! ../codex)
!(import! &self codex:context)
!(import! &self codex:tool_registry_builder_plan)
!(import! &self codex:tool_registry_dispatch_trace_plan)
!(import! &self codex:tool_router_dispatch_plan)
!(import! &self codex:tool_runtime_parallel_plan)

(= (test:trace-registry-empty)
   (codex:tool-registry ()))

(= (test:trace-registry-exec)
   (codex:tool-registry
     ((codex:tool-registry-handler-binding
        "exec_command"
        (codex:tool-handler-kind-unified-exec)))))

(= (test:trace-function-invocation $call-id $tool-name $source)
   (codex:tool-router-tool-invocation
     test-session
     test-turn
     test-cancellation-token
     test-tracker
     $call-id
     (codex:plain-tool-name $tool-name)
     $source
     (codex:tool-router-dispatch-function-payload "{}")))

(= (test:trace-custom-invocation $call-id $tool-name $source)
   (codex:tool-router-tool-invocation
     test-session
     test-turn
     test-cancellation-token
     test-tracker
     $call-id
     (codex:plain-tool-name $tool-name)
     $source
     (codex:tool-router-dispatch-custom-payload "1 + 1")))

(= (test:trace-plan $registry $invocation)
   (codex:tool-registry-dispatch-any-trace-plan
     "thread-1"
     "turn-1"
     $registry
     $invocation))

!(assertEqualToResult
  (codex:tool-registry-dispatch-trace-plan-start-event
    (test:trace-plan
      (test:trace-registry-empty)
      (test:trace-function-invocation
        "missing-call"
        "missing"
        (codex:tool-router-dispatch-source-direct))))
  ((CodexToolDispatchStartedEvent
     (CodexToolDispatchKindOther "missing")
     "missing"
     "{}"
     (CodexToolDispatchRequesterFields
       "missing-call"
       CodexAbsent
       (CodexToolDispatchRawRequesterModel))
     (JsonObject
       ((JsonPair "type" (JsonString "function"))
        (JsonPair "arguments" (JsonString "{}")))))))

!(assertEqualToResult
  (codex:tool-registry-dispatch-plan-error-value
    (codex:tool-registry-dispatch-trace-plan-dispatch-plan
      (test:trace-plan
        (test:trace-registry-empty)
        (test:trace-function-invocation
          "missing-call"
          "missing"
          (codex:tool-router-dispatch-source-direct)))))
  ((CodexFunctionCallErrorRespondToModel "unsupported call: missing")))

!(assertEqualToResult
  (codex:tool-registry-dispatch-trace-plan-end-event
    (test:trace-plan
      (test:trace-registry-empty)
      (test:trace-function-invocation
        "missing-call"
        "missing"
        (codex:tool-router-dispatch-source-direct))))
  ((CodexToolDispatchCompletedEvent
     (CodexToolDispatchExecutionStatusFailed)
     (CodexToolDispatchResultError "unsupported call: missing"))))

!(assertEqualToResult
  (codex:tool-registry-dispatch-trace-plan-end-event
    (test:trace-plan
      (test:trace-registry-exec)
      (test:trace-custom-invocation
        "bad-payload-call"
        "exec_command"
        (codex:tool-router-dispatch-source-direct))))
  ((CodexToolDispatchCompletedEvent
     (CodexToolDispatchExecutionStatusFailed)
     (CodexToolDispatchResultError
       "Fatal error: tool exec_command invoked with incompatible payload"))))

!(assertEqualToResult
  (codex:tool-registry-handler-binding-kind
    (codex:tool-registry-dispatch-plan-ready-binding
      (codex:tool-registry-dispatch-trace-plan-dispatch-plan
        (test:trace-plan
          (test:trace-registry-exec)
          (test:trace-function-invocation
            "ready-call"
            "exec_command"
            (codex:tool-router-dispatch-source-direct))))))
  ("UnifiedExec"))

!(assertEqual
  (codex:tool-registry-dispatch-trace-plan-end-event
    (test:trace-plan
      (test:trace-registry-exec)
      (test:trace-function-invocation
        "ready-call"
        "exec_command"
        (codex:tool-router-dispatch-source-direct))))
  CodexAbsent)

!(assertEqual
  (codex:tool-registry-dispatch-trace-plan-start-event
    (test:trace-plan
      (test:trace-registry-empty)
      (test:trace-function-invocation
        "js-call"
        "missing"
        (codex:tool-router-dispatch-source-js-repl))))
  CodexAbsent)

!(assertEqual
  (codex:tool-registry-dispatch-trace-plan-end-event
    (test:trace-plan
      (test:trace-registry-empty)
      (test:trace-function-invocation
        "js-call"
        "missing"
        (codex:tool-router-dispatch-source-js-repl))))
  CodexAbsent)

!(assertEqual
  (codex:tool-registry-dispatch-trace-plan-start-event
    (test:trace-plan
      (test:trace-registry-empty)
      (test:trace-custom-invocation
        "exec-public"
        "exec"
        (codex:tool-router-dispatch-source-direct))))
  CodexAbsent)

!(assertEqualToResult
  (codex:tool-registry-dispatch-trace-record-completed
    (codex:tool-registry-dispatch-trace-start
      "thread-1"
      "turn-1"
      (test:trace-function-invocation
        "done-call"
        "exec_command"
        (codex:tool-router-dispatch-source-direct)))
    (test:trace-function-invocation
      "done-call"
      "exec_command"
      (codex:tool-router-dispatch-source-direct))
    (codex:tool-call-runtime-any-tool-result
      "done-call"
      (codex:tool-router-dispatch-function-payload "{}")
      (codex:function-tool-output-from-text "ok" True)
      CodexAbsent))
  ((CodexToolDispatchCompletedEvent
     (CodexToolDispatchExecutionStatusCompleted)
     (CodexToolDispatchResultDirectResponse
       (CodexResponseItemFunctionCallOutput
         "done-call"
         (CodexFunctionCallOutputText "ok"))))))
