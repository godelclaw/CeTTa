!(register-module! ../codex)
!(import! &self codex:tool_registry_builder_plan)
!(import! &self codex:tool_router_dispatch_plan)
!(import! &self codex:tool_router_runtime_access_plan)

(= (test:tool-router-runtime-access-dispatch-router)
   (codex:tool-router-dispatch-router
     ((codex:tool-router-dispatch-function-configured-spec
        "exec_command"
        True)
      (codex:tool-router-dispatch-freeform-configured-spec
        "apply_patch"
        True)
      (CodexConfiguredToolSpec
        (CodexToolSpecNamespace
          (CodexResponsesApiNamespace
            "mcp__memory__"
            "memory tools"
            ((CodexResponsesApiNamespaceToolFunction
               (CodexResponsesApiTool
                 "read_graph"
                 CodexAbsent
                 False
                 CodexAbsent
                 CodexAbsent
                 CodexAbsent)))))
        True))
     ()
     False))

(= (test:tool-router-runtime-access-registry)
   (codex:tool-registry
     ((codex:tool-registry-handler-binding
        "exec_command"
        (codex:tool-handler-kind-unified-exec))
      (codex:tool-registry-handler-binding
        "apply_patch"
        (codex:tool-handler-kind-apply-patch)))))

(= (test:tool-router-runtime-access-router)
   (codex:tool-router-runtime-access-router
     (test:tool-router-runtime-access-dispatch-router)
     (test:tool-router-runtime-access-registry)))

(= (test:tool-router-runtime-access-runtime)
   (codex:tool-call-runtime
     (test:tool-router-runtime-access-dispatch-router)
     test-session
     test-turn-context
     test-tracker))

(= (test:tool-router-runtime-access-runtime-access)
   (codex:tool-call-runtime-access
     (test:tool-router-runtime-access-runtime)
     (test:tool-router-runtime-access-registry)))

!(assertEqualToResult
  (codex:tool-router-runtime-access-find-spec
    (test:tool-router-runtime-access-router)
    (codex:plain-tool-name "exec_command"))
  ((CodexToolSpecFunction
     (CodexResponsesApiTool
       "exec_command"
       CodexAbsent
       False
       CodexAbsent
       CodexAbsent
       CodexAbsent))))

!(assertEqualToResult
  (codex:tool-router-runtime-access-find-spec
    (test:tool-router-runtime-access-router)
    (codex:plain-tool-name "apply_patch"))
  ((CodexToolSpecFreeform
     (CodexFreeformTool
       "apply_patch"
       CodexAbsent
       CodexAbsent
       CodexAbsent
       CodexAbsent))))

!(assertEqualToResult
  (codex:tool-router-runtime-access-find-spec
    (test:tool-router-runtime-access-router)
    (codex:namespaced-tool-name "mcp__memory__" "read_graph"))
  ((CodexToolSpecFunction
     (CodexResponsesApiTool
       "read_graph"
       CodexAbsent
       False
       CodexAbsent
       CodexAbsent
       CodexAbsent))))

!(assertEqualToResult
  (codex:tool-router-runtime-access-find-spec
    (test:tool-router-runtime-access-router)
    (codex:plain-tool-name "missing"))
  (CodexAbsent))

!(assertEqualToResult
  (codex:tool-router-runtime-access-create-diff-consumer
    (test:tool-router-runtime-access-router)
    (codex:plain-tool-name "exec_command"))
  (CodexAbsent))

!(assertEqualToResult
  (codex:tool-argument-diff-consumer-kind
    (codex:tool-router-runtime-access-create-diff-consumer
      (test:tool-router-runtime-access-router)
      (codex:plain-tool-name "apply_patch")))
  ("ApplyPatch"))

!(assertEqualToResult
  (codex:tool-call-runtime-access-find-spec
    (test:tool-router-runtime-access-runtime-access)
    (codex:plain-tool-name "exec_command"))
  ((CodexToolSpecFunction
     (CodexResponsesApiTool
       "exec_command"
       CodexAbsent
       False
       CodexAbsent
       CodexAbsent
       CodexAbsent))))

!(assertEqualToResult
  (codex:tool-argument-diff-consumer-kind
    (codex:tool-call-runtime-access-create-diff-consumer
      (test:tool-router-runtime-access-runtime-access)
      (codex:plain-tool-name "apply_patch")))
  ("ApplyPatch"))
