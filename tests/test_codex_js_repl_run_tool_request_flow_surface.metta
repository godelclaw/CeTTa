!(register-module! ../codex)
!(import! &self codex:js_repl_run_tool_request_flow)

(= (test:context)
   (codex:js-repl-run-tool-request-flow-context
     tools-config-1
     (mcp-tools-1)
     (dynamic-tool-1)
     ((codex:js-repl-run-tool-function-spec "exec_command"))
     ()))

(= (test:internal-request)
   (codex:js-repl-kernel-to-host-run-tool
     "call-internal"
     "exec-1"
     "js_repl"
     "{\"code\":\"1 + 1\"}"))

(= (test:internal-flow)
   (codex:js-repl-run-tool-request-flow-step
     (test:internal-request)
     (test:context)
     (codex:js-repl-run-tool-dispatch-error "should not dispatch")))

!(assertEqual
  (codex:js-repl-run-tool-request-flow-result-status
    (test:internal-flow))
  CodexJsReplRunToolRequestFlowStatusRejectedInternal)

!(assertEqual
  (codex:js-repl-run-tool-request-flow-result-router-plan
    (test:internal-flow))
  CodexAbsent)

!(assertEqual
  (codex:js-repl-run-tool-request-flow-result-dispatch-plan
    (test:internal-flow))
  CodexAbsent)

!(assertEqual
  (codex:js-repl-run-tool-request-flow-result-run-tool-result
    (test:internal-flow))
  (CodexJsReplRunToolResult
    "call-internal"
    False
    CodexAbsent
    "js_repl cannot invoke itself"))

(= (test:function-request)
   (codex:js-repl-kernel-to-host-run-tool
     "call-1"
     "exec-1"
     "exec_command"
     "{\"cmd\":\"pwd\"}"))

(= (test:function-json)
   (JsonObject
     ((JsonPair "type" (JsonString "function_call_output"))
      (JsonPair "call_id" (JsonString "call-1"))
      (JsonPair "output" (JsonString "ok")))))

(= (test:function-flow)
   (codex:js-repl-run-tool-request-flow-step
     (test:function-request)
     (test:context)
     (codex:js-repl-run-tool-dispatch-ok
       (codex:js-repl-run-tool-any-tool-result
         "call-1"
         (CodexToolPayloadFunction "{\"cmd\":\"pwd\"}")
         (CodexToolOutputFunction
           ((CodexInputText "ok"))
           True
           CodexAbsent)
         CodexAbsent))))

!(assertEqual
  (codex:js-repl-run-tool-request-flow-result-status
    (test:function-flow))
  CodexJsReplRunToolRequestFlowStatusDispatched)

!(assertEqual
  (codex:js-repl-run-tool-router-plan-params
    (codex:js-repl-run-tool-request-flow-result-router-plan
      (test:function-flow)))
  (CodexJsReplRunToolRouterParams
    CodexAbsent
    (CodexJsReplRunToolRouterParamsMcpToolsSome (mcp-tools-1))
    ()
    ()
    CodexAbsent
    (dynamic-tool-1)))

!(assertEqual
  (codex:js-repl-run-tool-request-flow-result-dispatch-plan
    (test:function-flow))
  (CodexJsReplRunToolDispatchPlan
    (codex:plain-tool-name "exec_command")
    (CodexToolCall
      (codex:plain-tool-name "exec_command")
      "call-1"
      (CodexToolPayloadFunction "{\"cmd\":\"pwd\"}"))
    (CodexToolCallSourceJsRepl)))

!(assertEqual
  (codex:js-repl-run-tool-request-flow-result-run-tool-result
    (test:function-flow))
  (CodexJsReplRunToolResult
    "call-1"
    True
    (test:function-json)
    CodexAbsent))

!(assertEqual
  (codex:js-repl-run-tool-request-flow-result-actions
    (test:function-flow))
  ((CodexJsReplRunToolRequestActionLogToolCallResponse
     "js_repl nested tool call completed"
     "exec-1"
     "call-1"
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
     (test:function-json)
     CodexAbsent)))
