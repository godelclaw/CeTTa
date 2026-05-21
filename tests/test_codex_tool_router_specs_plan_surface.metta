!(register-module! ../codex)
!(import! &self codex:tool_router_specs_plan)

(= (test:configured-specs)
   ((codex:tool-router-specs-configured-spec
      (codex:tool-router-specs-function-spec "exec")
      True)
    (codex:tool-router-specs-configured-spec
      (codex:tool-router-specs-function-spec "wait")
      True)
    (codex:tool-router-specs-configured-spec
      (codex:tool-router-specs-function-spec "exec_command")
      True)
    (codex:tool-router-specs-configured-spec
      (codex:tool-router-specs-freeform-spec "apply_patch")
      True)
    (codex:tool-router-specs-configured-spec
      (codex:tool-router-specs-namespace-spec
        "mcp__memory__"
        "memory tools"
        ((codex:tool-router-specs-namespace-function "create_entities")
         (codex:tool-router-specs-namespace-function "read_graph")))
      True)
    (codex:tool-router-specs-configured-spec
      (CodexToolSpecToolSearch)
      True)
    (codex:tool-router-specs-configured-spec
      (CodexToolSpecLocalShell)
      True)
    (codex:tool-router-specs-configured-spec
      (CodexToolSpecImageGeneration "png")
      True)
    (codex:tool-router-specs-configured-spec
      (CodexToolSpecWebSearch)
      True)))

!(assertEqualToResult
  (codex:tool-router-specs-from-configured
    (test:configured-specs))
  (((CodexToolSpecFunction
      (CodexResponsesApiTool
        "exec"
        CodexAbsent
        False
        CodexAbsent
        CodexAbsent
        CodexAbsent))
    (CodexToolSpecFunction
      (CodexResponsesApiTool
        "wait"
        CodexAbsent
        False
        CodexAbsent
        CodexAbsent
        CodexAbsent))
    (CodexToolSpecFunction
      (CodexResponsesApiTool
        "exec_command"
        CodexAbsent
        False
        CodexAbsent
        CodexAbsent
        CodexAbsent))
    (CodexToolSpecFreeform
      (CodexFreeformTool
        "apply_patch"
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent))
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
             CodexAbsent))
         (CodexResponsesApiNamespaceToolFunction
           (CodexResponsesApiTool
             "read_graph"
             CodexAbsent
             False
             CodexAbsent
             CodexAbsent
             CodexAbsent)))))
    (CodexToolSpecToolSearch)
    (CodexToolSpecLocalShell)
    (CodexToolSpecImageGeneration "png")
    (CodexToolSpecWebSearch))))

!(assertEqualToResult
  (codex:tool-router-model-visible-specs-from-configured
    (test:configured-specs)
    True)
  (((CodexToolSpecFunction
      (CodexResponsesApiTool
        "exec"
        CodexAbsent
        False
        CodexAbsent
        CodexAbsent
        CodexAbsent))
    (CodexToolSpecFunction
      (CodexResponsesApiTool
        "wait"
        CodexAbsent
        False
        CodexAbsent
        CodexAbsent
        CodexAbsent)))))

!(assertEqual
  (codex:tool-router-model-visible-specs-from-configured
    (test:configured-specs)
    False)
  (codex:tool-router-specs-from-configured (test:configured-specs)))

!(assertEqualToResult
  (codex:tool-router-find-spec-from-configured
    (test:configured-specs)
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
  (codex:tool-router-find-spec-from-configured
    (test:configured-specs)
    (codex:plain-tool-name "apply_patch"))
  ((CodexToolSpecFreeform
     (CodexFreeformTool
       "apply_patch"
       CodexAbsent
       CodexAbsent
       CodexAbsent
       CodexAbsent))))

!(assertEqualToResult
  (codex:tool-router-find-spec-from-configured
    (test:configured-specs)
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
  (codex:tool-router-find-spec-from-configured
    (test:configured-specs)
    (codex:namespaced-tool-name "mcp__other__" "read_graph"))
  (CodexAbsent))

!(assertEqualToResult
  (codex:tool-router-find-spec-from-configured
    (test:configured-specs)
    (codex:plain-tool-name "tool_search"))
  (CodexAbsent))
