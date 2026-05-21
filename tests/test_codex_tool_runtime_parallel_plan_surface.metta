!(register-module! ../codex)
!(import! &self codex:tool_runtime_parallel_plan)

(= (test:router $js-repl-tools-only)
   (codex:tool-router-dispatch-router
     ((codex:tool-router-dispatch-function-configured-spec
        "exec_command"
        True)
      (codex:tool-router-dispatch-function-configured-spec
        "serial_tool"
        False))
     ("parallel-mcp")
     $js-repl-tools-only))

(= (test:runtime $js-repl-tools-only)
   (codex:tool-call-runtime
     (test:router $js-repl-tools-only)
     test-session
     test-turn-context
     test-tracker))

(= (test:function-call $name $call-id)
   (codex:tool-router-dispatch-tool-call
     (codex:plain-tool-name $name)
     $call-id
     (codex:tool-router-dispatch-function-payload "{\"x\":1}")))

(= (test:custom-call)
   (codex:tool-router-dispatch-tool-call
     (codex:plain-tool-name "apply_patch")
     "call-custom"
     (codex:tool-router-dispatch-custom-payload "*** Begin Patch\n*** End Patch\n")))

(= (test:tool-search-call)
   (codex:tool-router-dispatch-tool-call
     (codex:plain-tool-name "tool_search")
     "call-search"
     (codex:tool-router-dispatch-tool-search-payload "find me" 3)))

(= (test:mcp-call $server)
   (codex:tool-router-dispatch-tool-call
     (codex:namespaced-tool-name "mcp__memory__" "read_graph")
     "call-mcp"
     (codex:tool-router-dispatch-mcp-payload
       $server
       "read_graph"
       "{}")))

(= (test:parallel-plan $call)
   (codex:tool-call-runtime-handle-tool-call-with-source-plan
     (test:runtime False)
     $call
     (codex:tool-router-dispatch-source-direct)
     test-cancellation-token))

!(assertEqualToResult
  (codex:tool-call-runtime-dispatch-plan-supports-parallel
    (test:parallel-plan (test:function-call "exec_command" "call-1")))
  (True))

!(assertEqualToResult
  (codex:tool-call-runtime-dispatch-plan-lock-mode
    (test:parallel-plan (test:function-call "exec_command" "call-1")))
  (CodexToolCallRuntimeLockRead))

!(assertEqualToResult
  (codex:tool-call-runtime-dispatch-plan-lock-mode
    (test:parallel-plan (test:function-call "serial_tool" "call-2")))
  (CodexToolCallRuntimeLockWrite))

!(assertEqualToResult
  (codex:tool-call-runtime-dispatch-plan-lock-mode
    (test:parallel-plan (test:mcp-call "parallel-mcp")))
  (CodexToolCallRuntimeLockRead))

!(assertEqualToResult
  (codex:tool-call-runtime-dispatch-plan-lock-mode
    (test:parallel-plan (test:mcp-call "serial-mcp")))
  (CodexToolCallRuntimeLockWrite))

!(assertEqualToResult
  (codex:tool-router-dispatch-plan-error
    (codex:tool-call-runtime-dispatch-plan-router-dispatch-plan
      (codex:tool-call-runtime-handle-tool-call-with-source-plan
        (test:runtime True)
        (test:function-call "exec_command" "call-3")
        (codex:tool-router-dispatch-source-direct)
        test-cancellation-token)))
  ((CodexFunctionCallErrorRespondToModel
     "direct tool calls are disabled; use js_repl and codex.tool(...) instead")))

!(assertEqualToResult
  (codex:tool-call-runtime-failure-response
    (test:function-call "exec_command" "call-fn")
    (CodexFunctionCallErrorRespondToModel "bad input"))
  ((CodexResponseItemFunctionCallOutput
     "call-fn"
     (CodexFunctionCallOutputText "bad input"))))

!(assertEqualToResult
  (codex:tool-call-runtime-failure-response
    (test:custom-call)
    (CodexFunctionCallErrorRespondToModel "patch failed"))
  ((CodexResponseItemCustomToolCallOutput
     "call-custom"
     CodexAbsent
     (CodexFunctionCallOutputText "patch failed"))))

!(assertEqualToResult
  (codex:tool-call-runtime-failure-response
    (test:tool-search-call)
    (CodexFunctionCallErrorRespondToModel "ignored for search"))
  ((CodexResponseItemToolSearchOutput
     "call-search"
     "completed"
     "client"
     ())))

!(assertEqualToResult
  (codex:tool-call-runtime-handle-result-fatal-message
    (codex:tool-call-runtime-handle-tool-call-dispatch-result
      (test:function-call "exec_command" "call-fatal")
      (codex:tool-call-runtime-dispatch-error
        (CodexFunctionCallErrorFatal "handler crashed"))))
  ("handler crashed"))

!(assertEqualToResult
  (codex:tool-call-runtime-handle-result-response
    (codex:tool-call-runtime-handle-tool-call-dispatch-result
      (test:function-call "exec_command" "call-ok")
      (codex:tool-call-runtime-dispatch-ok
        (codex:tool-call-runtime-any-tool-result
          "call-ok"
          (CodexToolPayloadFunction "{}")
          (CodexToolOutputFunction
            ((CodexInputText "ok"))
            True
            CodexAbsent)
          CodexAbsent))))
  ((CodexResponseItemFunctionCallOutput
     "call-ok"
     (CodexFunctionCallOutputText "ok"))))

!(assertEqualToResult
  (codex:tool-call-runtime-abort-message
    (test:function-call "unified_exec" "call-shell")
    1.24)
  ("Wall time: 1.2 seconds\naborted by user"))

!(assertEqualToResult
  (codex:tool-call-runtime-abort-message
    (test:function-call "exec_command" "call-tool")
    1.26)
  ("aborted by user after 1.3s"))

!(assertEqualToResult
  (codex:tool-call-runtime-any-tool-result-tool-output
    (codex:tool-call-runtime-cancelled-response
      (test:function-call "exec_command" "call-cancel")
      0.02))
  ((CodexToolOutputAborted "aborted by user after 0.1s")))
