!(register-module! ../codex)
!(import! &self codex:tool_router_dispatch_plan)

(= (test:router $js-repl-tools-only)
   (codex:tool-router-dispatch-router
     ((codex:tool-router-dispatch-function-configured-spec
        "exec_command"
        True)
      (codex:tool-router-dispatch-freeform-configured-spec
        "apply_patch"
        True)
      (codex:tool-router-dispatch-function-configured-spec
        "serial_only"
        False)
      (CodexConfiguredToolSpec
        (CodexToolSpecNamespace
          (CodexResponsesApiNamespace
            "mcp__memory__"
            "memory tools"
            ((CodexResponsesApiNamespaceToolFunction
               (CodexResponsesApiTool
                 "create_entities"
                 CodexAbsent
                 False
                 CodexAbsent
                 CodexAbsent
                 CodexAbsent)))))
        True)
      (CodexConfiguredToolSpec
        (CodexToolSpecToolSearch)
        True)
      (CodexConfiguredToolSpec
        (CodexToolSpecLocalShell)
        True)
      (CodexConfiguredToolSpec
        (CodexToolSpecImageGeneration "png")
        True)
      (CodexConfiguredToolSpec
        (CodexToolSpecWebSearch)
        True))
     ("parallel-mcp")
     $js-repl-tools-only))

(= (test:function-call $name)
   (codex:tool-router-dispatch-tool-call
     (codex:plain-tool-name $name)
     "call-function"
     (codex:tool-router-dispatch-function-payload "{\"x\":1}")))

(= (test:custom-call $name)
   (codex:tool-router-dispatch-tool-call
     (codex:plain-tool-name $name)
     "call-custom"
     (codex:tool-router-dispatch-custom-payload "input")))

(= (test:mcp-call $server)
   (codex:tool-router-dispatch-tool-call
     (codex:namespaced-tool-name "mcp__memory__" "create_entities")
     "call-mcp"
     (codex:tool-router-dispatch-mcp-payload
       $server
       "create_entities"
       "{\"entities\":[]}")))

(= (test:dispatch-plan $router $call $source)
   (codex:tool-router-dispatch-tool-call-with-code-mode-result-plan
     $router
     test-session
     test-turn
     test-cancellation-token
     test-tracker
     $call
     $source))

!(assertEqualToResult
  (codex:tool-router-configured-tool-supports-parallel
    (test:router False)
    (codex:plain-tool-name "exec_command"))
  (True))

!(assertEqualToResult
  (codex:tool-router-configured-tool-supports-parallel
    (test:router False)
    (codex:plain-tool-name "apply_patch"))
  (True))

!(assertEqualToResult
  (codex:tool-router-configured-tool-supports-parallel
    (test:router False)
    (codex:plain-tool-name "serial_only"))
  (False))

!(assertEqualToResult
  (codex:tool-router-configured-tool-supports-parallel
    (test:router False)
    (codex:namespaced-tool-name "mcp__memory__" "create_entities"))
  (False))

!(assertEqualToResult
  (codex:tool-router-tool-supports-parallel
    (test:router False)
    (test:function-call "exec_command"))
  (True))

!(assertEqualToResult
  (codex:tool-router-tool-supports-parallel
    (test:router False)
    (test:custom-call "apply_patch"))
  (True))

!(assertEqualToResult
  (codex:tool-router-tool-supports-parallel
    (test:router False)
    (test:mcp-call "parallel-mcp"))
  (True))

!(assertEqualToResult
  (codex:tool-router-tool-supports-parallel
    (test:router False)
    (test:mcp-call "serial-mcp"))
  (False))

!(assertEqualToResult
  (codex:tool-router-dispatch-plan-error
    (test:dispatch-plan
      (test:router True)
      (test:function-call "exec_command")
      (codex:tool-router-dispatch-source-direct)))
  ((CodexFunctionCallErrorRespondToModel
     "direct tool calls are disabled; use js_repl and codex.tool(...) instead")))

!(assertEqualToResult
  (codex:tool-router-tool-invocation-tool-name
    (codex:tool-router-dispatch-plan-invocation
      (test:dispatch-plan
        (test:router True)
        (test:function-call "js_repl")
        (codex:tool-router-dispatch-source-direct))))
  ((CodexToolName "js_repl" CodexAbsent)))

!(assertEqualToResult
  (codex:tool-router-tool-invocation-tool-name
    (codex:tool-router-dispatch-plan-invocation
      (test:dispatch-plan
        (test:router True)
        (test:function-call "js_repl_reset")
        (codex:tool-router-dispatch-source-direct))))
  ((CodexToolName "js_repl_reset" CodexAbsent)))

!(assertEqualToResult
  (codex:tool-router-tool-invocation-source
    (codex:tool-router-dispatch-plan-invocation
      (test:dispatch-plan
        (test:router True)
        (test:function-call "exec_command")
        (codex:tool-router-dispatch-source-js-repl))))
  ((CodexToolCallSourceJsRepl)))

!(assertEqualToResult
  (codex:tool-router-tool-invocation-call-id
    (codex:tool-router-dispatch-plan-invocation
      (test:dispatch-plan
        (test:router False)
        (test:function-call "exec_command")
        (codex:tool-router-dispatch-source-code-mode
          "cell-1"
          "runtime-call-1"))))
  ("call-function"))
