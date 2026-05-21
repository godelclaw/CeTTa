!(register-module! ../codex)
!(import! &self codex:js_repl_run_tool_dispatch_result)

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

(= (test:function-step)
   (codex:js-repl-run-tool-dispatch-result-step
     (test:function-request)
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
  (codex:js-repl-run-tool-dispatch-result-step-result-run-tool-result
    (test:function-step))
  (CodexJsReplRunToolResult
    "call-1"
    True
    (test:function-json)
    CodexAbsent))

!(assertEqual
  (codex:js-repl-run-tool-dispatch-result-step-result-actions
    (test:function-step))
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

(= (test:custom-request)
   (codex:js-repl-kernel-to-host-run-tool
     "call-2"
     "exec-1"
     "apply_patch"
     "*** Begin Patch\n*** End Patch\n"))

(= (test:custom-step)
   (codex:js-repl-run-tool-dispatch-result-step
     (test:custom-request)
     (codex:js-repl-run-tool-dispatch-ok
       (codex:js-repl-run-tool-any-tool-result
         "call-2"
         (CodexToolPayloadCustom "*** Begin Patch\n*** End Patch\n")
         (CodexToolOutputApplyPatch "Done!")
         CodexAbsent))))

!(assertEqual
  (codex:js-repl-run-tool-dispatch-result-step-result-run-tool-result
    (test:custom-step))
  (CodexJsReplRunToolResult
    "call-2"
    True
    (JsonObject
      ((JsonPair "type" (JsonString "custom_tool_call_output"))
       (JsonPair "call_id" (JsonString "call-2"))
       (JsonPair "output" (JsonString "Done!"))))
    CodexAbsent))

(= (test:error-step)
   (codex:js-repl-run-tool-dispatch-result-step
     (test:function-request)
     (codex:js-repl-run-tool-dispatch-error "tool failed")))

!(assertEqual
  (codex:js-repl-run-tool-dispatch-result-step-result-run-tool-result
    (test:error-step))
  (CodexJsReplRunToolResult
    "call-1"
    False
    CodexAbsent
    "tool failed"))

!(assertEqual
  (codex:js-repl-run-tool-dispatch-result-step-result-actions
    (test:error-step))
  ((CodexJsReplRunToolRequestActionLogToolCallResponse
     "js_repl nested tool call completed"
     "exec-1"
     "call-1"
     "exec_command"
     False
     (CodexJsReplToolCallResponseSummary
       CodexAbsent
       (CodexJsReplToolCallPayloadKindError)
       "tool failed"
       11
       CodexAbsent
       CodexAbsent
       CodexAbsent
       CodexAbsent
       CodexAbsent)
     CodexAbsent
     "tool failed")))

(= (test:serialization-error-step)
   (codex:js-repl-run-tool-dispatch-result-step
     (test:function-request)
     (codex:js-repl-run-tool-dispatch-ok
       (codex:js-repl-run-tool-any-tool-result
         "call-1"
         (CodexToolPayloadFunction "{\"cmd\":\"pwd\"}")
         (codex:js-repl-run-tool-tool-output-serialization-failure
           "unsupported response")
         CodexAbsent))))

!(assertEqual
  (codex:js-repl-run-tool-dispatch-result-step-result-run-tool-result
    (test:serialization-error-step))
  (CodexJsReplRunToolResult
    "call-1"
    False
    CodexAbsent
    "failed to serialize tool output: unsupported response"))
