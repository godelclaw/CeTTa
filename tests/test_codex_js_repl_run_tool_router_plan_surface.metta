!(register-module! ../codex)
!(import! &self codex:js_repl_run_tool_router_plan)

(= (test:function-specs)
   ((codex:js-repl-run-tool-function-spec "exec_command")))

(= (test:freeform-specs)
   ((codex:js-repl-run-tool-freeform-spec "apply_patch")))

(= (test:namespace-specs)
   ((codex:js-repl-run-tool-namespace-spec
      "mcp"
      "Tools in the mcp namespace."
      ((codex:js-repl-run-tool-namespace-function "lookup")))))

(= (test:mcp-memory-specs)
   ((codex:js-repl-run-tool-namespace-spec
      "mcp__memory__"
      "Tools in the mcp__memory__ namespace."
      ((codex:js-repl-run-tool-namespace-function "create_entities")))))

!(assertEqual
  (codex:js-repl-run-tool-router-plan-params
    (codex:js-repl-run-tool-router-plan
      tools-config-1
      (mcp-tools-1)
      (dynamic-tool-1)
      (test:function-specs)))
  (CodexJsReplRunToolRouterParams
    CodexAbsent
    (CodexJsReplRunToolRouterParamsMcpToolsSome (mcp-tools-1))
    ()
    ()
    CodexAbsent
    (dynamic-tool-1)))

!(assertEqual
  (codex:js-repl-code-mode-name-for-tool-name
    (codex:plain-tool-name "exec_command"))
  "exec_command")

!(assertEqual
  (codex:js-repl-code-mode-name-for-tool-name
    (codex:namespaced-tool-name "mcp" "lookup"))
  "mcp_lookup")

!(assertEqual
  (codex:js-repl-code-mode-name-for-tool-name
    (codex:namespaced-tool-name "mcp__memory__" "create_entities"))
  "mcp__memory__create_entities")

(= (test:function-plan)
   (codex:js-repl-run-tool-request-dispatch-plan
     (codex:js-repl-kernel-to-host-run-tool
       "call-1"
       "exec-1"
       "exec_command"
       "{\"cmd\":\"pwd\"}")
     (test:function-specs)
     ()))

!(assertEqual
  (codex:js-repl-run-tool-dispatch-plan-requested-tool-name
    (test:function-plan))
  (codex:plain-tool-name "exec_command"))

!(assertEqual
  (codex:js-repl-run-tool-dispatch-plan-tool-call
    (test:function-plan))
  (CodexToolCall
    (codex:plain-tool-name "exec_command")
    "call-1"
    (CodexToolPayloadFunction "{\"cmd\":\"pwd\"}")))

!(assertEqual
  (codex:js-repl-run-tool-dispatch-plan-source
    (test:function-plan))
  (CodexToolCallSourceJsRepl))

(= (test:freeform-plan)
   (codex:js-repl-run-tool-request-dispatch-plan
     (codex:js-repl-kernel-to-host-run-tool
       "call-2"
       "exec-1"
       "apply_patch"
       "*** Begin Patch\n*** End Patch\n")
     (test:freeform-specs)
     ()))

!(assertEqual
  (codex:js-repl-run-tool-tool-call-payload
    (codex:js-repl-run-tool-dispatch-plan-tool-call
      (test:freeform-plan)))
  (CodexToolPayloadCustom "*** Begin Patch\n*** End Patch\n"))

(= (test:namespace-code-mode-plan)
   (codex:js-repl-run-tool-request-dispatch-plan
     (codex:js-repl-kernel-to-host-run-tool
       "call-3"
       "exec-1"
       "mcp_lookup"
       "{\"query\":\"alpha\"}")
     (test:namespace-specs)
     ()))

!(assertEqual
  (codex:js-repl-run-tool-dispatch-plan-requested-tool-name
    (test:namespace-code-mode-plan))
  (codex:namespaced-tool-name "mcp" "lookup"))

!(assertEqual
  (codex:js-repl-run-tool-tool-call-payload
    (codex:js-repl-run-tool-dispatch-plan-tool-call
      (test:namespace-code-mode-plan)))
  (CodexToolPayloadFunction "{\"query\":\"alpha\"}"))

(= (test:mcp-plan)
   (codex:js-repl-run-tool-request-dispatch-plan
     (codex:js-repl-kernel-to-host-run-tool
       "call-4"
       "exec-1"
       "mcp__memory__create_entities"
       "{\"entities\":[]}")
     (test:mcp-memory-specs)
     ((codex:js-repl-run-tool-mcp-tool-info
        "mcp__memory__"
        "create_entities"
        "memory"
        "create_entities"))))

!(assertEqual
  (codex:js-repl-run-tool-dispatch-plan-requested-tool-name
    (test:mcp-plan))
  (codex:namespaced-tool-name "mcp__memory__" "create_entities"))

!(assertEqual
  (codex:js-repl-run-tool-dispatch-plan-tool-call
    (test:mcp-plan))
  (CodexToolCall
    (codex:namespaced-tool-name "mcp__memory__" "create_entities")
    "call-4"
    (CodexToolPayloadMcp
      "memory"
      "create_entities"
      "{\"entities\":[]}")))

(= (test:fallback-plan)
   (codex:js-repl-run-tool-request-dispatch-plan
     (codex:js-repl-kernel-to-host-run-tool
       "call-5"
       "exec-1"
       "unknown_tool"
       "{\"x\":1}")
     ()
     ()))

!(assertEqual
  (codex:js-repl-run-tool-dispatch-plan-tool-call
    (test:fallback-plan))
  (CodexToolCall
    (codex:plain-tool-name "unknown_tool")
    "call-5"
    (CodexToolPayloadFunction "{\"x\":1}")))
