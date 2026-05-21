!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:code_mode_nested_tool_plan)

(= (test:router)
   (codex:tool-router-dispatch-router
     ((codex:tool-router-specs-configured-spec
        (codex:tool-router-specs-function-spec "exec_command")
        True)
      (codex:tool-router-specs-configured-spec
        (codex:tool-router-specs-freeform-spec "apply_patch")
        True)
      (codex:tool-router-specs-configured-spec
        (CodexToolSpecNamespace
          (CodexResponsesApiNamespace
            "mcp__memory__"
            "memory tools"
            ((codex:tool-router-specs-namespace-function "read_graph"))))
        True))
     ("parallel-mcp")
     False))

(= (test:runtime)
   (codex:tool-call-runtime
     (test:router)
     test-session
     test-turn
     test-tracker))

!(assertEqualToResult
  (codex:code-mode-is-exec-tool-name
    (codex:plain-tool-name "exec"))
  (True))

!(assertEqualToResult
  (codex:code-mode-is-exec-tool-name
    (codex:namespaced-tool-name "mcp" "exec"))
  (False))

!(assertEqualToResult
  (codex:code-mode-build-nested-tool-payload
    (codex:tool-router-specs-function-spec "exec_command")
    (codex:plain-tool-name "exec_command")
    CodexAbsent)
  ((CodexCodeModeBuildPayloadOk
     (CodexToolPayloadFunction "{}"))))

!(assertEqualToResult
  (codex:code-mode-build-nested-tool-payload
    (codex:tool-router-specs-function-spec "exec_command")
    (codex:plain-tool-name "exec_command")
    (JsonObject
      ((JsonPair "cmd" (JsonString "pwd")))))
  ((CodexCodeModeBuildPayloadOk
     (CodexToolPayloadFunction "{\"cmd\":\"pwd\"}"))))

!(assertEqualToResult
  (codex:code-mode-build-nested-tool-payload
    (codex:tool-router-specs-function-spec "exec_command")
    (codex:plain-tool-name "exec_command")
    (JsonString "not object"))
  ((CodexCodeModeBuildPayloadError
     "tool `exec_command` expects a JSON object for arguments")))

!(assertEqualToResult
  (codex:code-mode-build-nested-tool-payload
    (codex:tool-router-specs-freeform-spec "apply_patch")
    (codex:plain-tool-name "apply_patch")
    (JsonString "*** Begin Patch\n*** End Patch\n"))
  ((CodexCodeModeBuildPayloadOk
     (CodexToolPayloadCustom "*** Begin Patch\n*** End Patch\n"))))

!(assertEqualToResult
  (codex:code-mode-build-nested-tool-payload
    (codex:tool-router-specs-freeform-spec "apply_patch")
    (codex:plain-tool-name "apply_patch")
    CodexAbsent)
  ((CodexCodeModeBuildPayloadError
     "tool `apply_patch` expects a string input")))

!(assertEqualToResult
  (codex:code-mode-build-nested-tool-payload
    CodexAbsent
    (codex:plain-tool-name "unknown_tool")
    (JsonObject ()))
  ((CodexCodeModeBuildPayloadError
     "tool `unknown_tool` is not enabled in exec")))

(= (test:local-function-plan)
   (codex:code-mode-nested-tool-call-plan
     (test:runtime)
     ()
     (codex:code-mode-nested-tool-call
       "cell-1"
       "runtime-call-1"
       (codex:plain-tool-name "exec_command")
       (JsonObject
         ((JsonPair "cmd" (JsonString "pwd")))))
     "uuid-1"))

!(assertEqualToResult
  (codex:code-mode-nested-tool-plan-tool-call
    (test:local-function-plan))
  ((CodexToolCall
     (CodexToolName "exec_command" CodexAbsent)
     "exec-uuid-1"
     (CodexToolPayloadFunction "{\"cmd\":\"pwd\"}"))))

!(assertEqualToResult
  (codex:code-mode-nested-tool-plan-source
    (test:local-function-plan))
  ((CodexToolCallSourceCodeMode "cell-1" "runtime-call-1")))

(= (test:freeform-plan)
   (codex:code-mode-nested-tool-call-plan
     (test:runtime)
     ()
     (codex:code-mode-nested-tool-call
       "cell-2"
       "runtime-call-2"
       (codex:plain-tool-name "apply_patch")
       (JsonString "*** Begin Patch\n*** End Patch\n"))
     "uuid-2"))

!(assertEqualToResult
  (codex:code-mode-nested-tool-plan-tool-call
    (test:freeform-plan))
  ((CodexToolCall
     (CodexToolName "apply_patch" CodexAbsent)
     "exec-uuid-2"
     (CodexToolPayloadCustom "*** Begin Patch\n*** End Patch\n"))))

(= (test:mcp-plan)
   (codex:code-mode-nested-tool-call-plan
     (test:runtime)
     ((codex:code-mode-nested-tool-mcp-tool-info
        "mcp__memory__"
        "read_graph"
        "memory"
        "read_graph"))
     (codex:code-mode-nested-tool-call
       "cell-3"
       "runtime-call-3"
       (codex:namespaced-tool-name "mcp__memory__" "read_graph")
       (JsonObject
         ((JsonPair "query" (JsonString "alpha")))))
     "uuid-3"))

!(assertEqualToResult
  (codex:code-mode-nested-tool-plan-tool-call
    (test:mcp-plan))
  ((CodexToolCall
     (CodexToolName "read_graph" "mcp__memory__")
     "exec-uuid-3"
     (CodexToolPayloadMcp
       "memory"
       "read_graph"
       "{\"query\":\"alpha\"}"))))

!(assertEqualToResult
  (codex:code-mode-nested-tool-plan-error-value
    (codex:code-mode-nested-tool-call-plan
      (test:runtime)
      ()
      (codex:code-mode-nested-tool-call
        "cell-4"
        "runtime-call-4"
        (codex:plain-tool-name "exec")
        (JsonString "console.log(1)"))
      "uuid-4"))
  ((CodexFunctionCallErrorRespondToModel
     "exec cannot invoke itself")))

!(assertEqualToResult
  (codex:code-mode-nested-tool-runtime-plan-dispatch-plan
    (codex:code-mode-nested-tool-runtime-plan
      (test:runtime)
      ()
      (codex:code-mode-nested-tool-call
        "cell-5"
        "runtime-call-5"
        (codex:plain-tool-name "exec_command")
        CodexAbsent)
      "uuid-5"
      test-cancellation-token))
  ((CodexToolCallRuntimeDispatchPlan
     True
     CodexToolCallRuntimeLockRead
     (CodexToolRouterDispatchPlanOk
       (CodexToolInvocation
         test-session
         test-turn
         test-cancellation-token
         test-tracker
         "exec-uuid-5"
         (CodexToolName "exec_command" CodexAbsent)
         (CodexToolCallSourceCodeMode "cell-5" "runtime-call-5")
         (CodexToolPayloadFunction "{}"))))))

!(assertEqualToResult
  (codex:code-mode-nested-tool-dispatch-result
    (codex:tool-call-runtime-dispatch-ok
      (codex:tool-call-runtime-any-tool-result
        "exec-uuid-6"
        (CodexToolPayloadFunction "{}")
        (codex:function-tool-output-from-text "ok" True)
        CodexAbsent)))
  ((CodexCodeModeNestedToolResultOk
     (JsonString "ok"))))

!(assertEqualToResult
  (codex:code-mode-nested-tool-dispatch-result
    (codex:tool-call-runtime-dispatch-error
      (codex:function-call-error-respond-to-model "failed")))
  ((CodexCodeModeNestedToolResultError
     (CodexFunctionCallErrorRespondToModel "failed"))))
