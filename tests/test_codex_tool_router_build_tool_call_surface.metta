!(register-module! ../codex)
!(import! &self codex:tool_router_build_tool_call)

(= (test:mcp-tools)
   ((codex:tool-router-build-mcp-tool-info
      "mcp__memory__"
      "read_graph"
      "memory"
      "read_graph")))

!(assertEqualToResult
  (codex:tool-router-build-tool-call-result-tool-call
    (codex:tool-router-build-tool-call
      ()
      (CodexResponseItemFunctionCall
        CodexAbsent
        "exec_command"
        CodexAbsent
        "{\"cmd\":\"pwd\"}"
        "call-fn")))
  ((CodexToolCall
     (CodexToolName "exec_command" CodexAbsent)
     "call-fn"
     (CodexToolPayloadFunction "{\"cmd\":\"pwd\"}"))))

!(assertEqualToResult
  (codex:tool-router-build-tool-call-result-tool-call
    (codex:tool-router-build-tool-call
      ()
      (CodexResponseItemFunctionCall
        CodexAbsent
        "create_event"
        "mcp__codex_apps__calendar"
        "{}"
        "call-namespace")))
  ((CodexToolCall
     (CodexToolName "create_event" "mcp__codex_apps__calendar")
     "call-namespace"
     (CodexToolPayloadFunction "{}"))))

!(assertEqualToResult
  (codex:tool-router-build-tool-call-result-tool-call
    (codex:tool-router-build-tool-call
      (test:mcp-tools)
      (CodexResponseItemFunctionCall
        CodexAbsent
        "read_graph"
        "mcp__memory__"
        "{\"depth\":1}"
        "call-mcp")))
  ((CodexToolCall
     (CodexToolName "read_graph" "mcp__memory__")
     "call-mcp"
     (CodexToolPayloadMcp
       "memory"
       "read_graph"
       "{\"depth\":1}"))))

!(assertEqualToResult
  (codex:tool-router-build-tool-call-result-tool-call
    (codex:tool-router-build-tool-call
      ()
      (CodexResponseItemToolSearchCall
        CodexAbsent
        "call-search"
        CodexAbsent
        "client"
        (JsonObject
          ((JsonPair "query" (JsonString "calendar"))
           (JsonPair "limit" (JsonNumber 3)))))))
  ((CodexToolCall
     (CodexToolName "tool_search" CodexAbsent)
     "call-search"
     (CodexToolPayloadToolSearch "calendar" 3))))

!(assertEqualToResult
  (codex:tool-router-build-tool-call-result-tool-call
    (codex:tool-router-build-tool-call
      ()
      (CodexResponseItemToolSearchCall
        CodexAbsent
        "call-search-json"
        CodexAbsent
        "client"
        "{\"query\":\"tickets\"}")))
  ((CodexToolCall
     (CodexToolName "tool_search" CodexAbsent)
     "call-search-json"
     (CodexToolPayloadToolSearch "tickets" CodexAbsent))))

!(assertEqualToResult
  (codex:tool-router-build-tool-call
    ()
    (CodexResponseItemToolSearchCall
      CodexAbsent
      CodexAbsent
      CodexAbsent
      "client"
      "{\"query\":\"calendar\"}"))
  ((CodexToolRouterBuildToolCallNone)))

!(assertEqualToResult
  (codex:tool-router-build-tool-call
    ()
    (CodexResponseItemToolSearchCall
      CodexAbsent
      "call-search-server"
      CodexAbsent
      "server"
      "{\"query\":\"calendar\"}"))
  ((CodexToolRouterBuildToolCallNone)))

!(assertEqualToResult
  (codex:tool-router-build-tool-call-result-tool-call
    (codex:tool-router-build-tool-call
      ()
      (CodexResponseItemCustomToolCall
        "call-custom"
        "apply_patch"
        "*** Begin Patch\n*** End Patch\n")))
  ((CodexToolCall
     (CodexToolName "apply_patch" CodexAbsent)
     "call-custom"
     (CodexToolPayloadCustom "*** Begin Patch\n*** End Patch\n"))))

!(assertEqualToResult
  (codex:tool-router-build-tool-call-result-tool-call
    (codex:tool-router-build-tool-call
      ()
      (CodexResponseItemLocalShellCall
        CodexAbsent
        "call-local"
        "completed"
        (CodexLocalShellExecAction ("pwd")))))
  ((CodexToolCall
     (CodexToolName "local_shell" CodexAbsent)
     "call-local"
     (CodexToolPayloadLocalShellParams
       ("pwd")
       CodexAbsent
       CodexAbsent
       "use_default"
       CodexAbsent
       CodexAbsent
       CodexAbsent))))

!(assertEqualToResult
  (codex:tool-router-build-tool-call-result-tool-call
    (codex:tool-router-build-tool-call
      ()
      (CodexResponseItemLocalShellCall
        "id-local"
        CodexAbsent
        "completed"
        (codex:tool-router-build-local-shell-action-full
          ("bash" "-lc" "pwd")
          1000
          "/repo"
          CodexAbsent
          CodexAbsent))))
  ((CodexToolCall
     (CodexToolName "local_shell" CodexAbsent)
     "id-local"
     (CodexToolPayloadLocalShellParams
       ("bash" "-lc" "pwd")
       "/repo"
       1000
       "use_default"
       CodexAbsent
       CodexAbsent
       CodexAbsent))))

!(assertEqualToResult
  (codex:tool-router-build-tool-call-result-error
    (codex:tool-router-build-tool-call
      ()
      (CodexResponseItemLocalShellCall
        CodexAbsent
        CodexAbsent
        "completed"
        (CodexLocalShellExecAction ("pwd")))))
  ((CodexFunctionCallErrorMissingLocalShellCallId)))

!(assertEqualToResult
  (codex:tool-router-build-tool-call
    ()
    (CodexResponseItemMessage
      "assistant"
      ((CodexOutputText "done"))
      CodexAbsent))
  ((CodexToolRouterBuildToolCallNone)))
