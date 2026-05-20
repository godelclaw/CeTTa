!(register-module! ../codex)
!(import! &self codex:mcp_tool_call)
!(import! &self codex:protocol)

(= (test:mcp-usage-tool-info
      $server
      $tool-name
      $connector-id
      $connector-name)
   (codex:mcp-tool-info
     $server
     (codex:mcp-tool
       $tool-name
       CodexAbsent
       CodexAbsent
       (JsonObject ())
       CodexAbsent
       CodexAbsent
       ()
       CodexAbsent)
     $connector-id
     $connector-name))

!(assertEqualToResult
  (codex:lookup-mcp-app-usage-metadata
    ((test:mcp-usage-tool-info
       "filesystem"
       "read_file"
       CodexAbsent
       CodexAbsent)
     (test:mcp-usage-tool-info
       "codex_apps"
       "create_event"
       "calendar"
       "Calendar"))
    "codex_apps"
    "create_event")
  ((CodexMcpAppUsageMetadata "calendar" "Calendar")))

!(assertEqualToResult
  (codex:lookup-mcp-app-usage-metadata
    ((test:mcp-usage-tool-info
       "codex_apps"
       "create_event"
       "calendar"
       "Calendar"))
    "codex_apps"
    "search_mail")
  (Empty))

!(assertEqualToResult
  (codex:maybe-track-codex-app-used-plan
    "filesystem"
    (codex:mcp-app-usage-metadata "files" "Files")
    ("files")
    "gpt-5"
    "thread-1"
    "turn-1")
  (Empty))

!(assertEqualToResult
  (codex:maybe-track-codex-app-used-plan
    "codex_apps"
    CodexAbsent
    ()
    "gpt-5"
    "thread-1"
    "turn-1")
  ((CodexMcpAppUsedTrackingPlan
     (CodexMcpTrackEventsContext "gpt-5" "thread-1" "turn-1")
     (CodexMcpAppInvocation
       CodexAbsent
       CodexAbsent
       (CodexMcpAppInvocationTypeImplicit)))))

!(assertEqualToResult
  (codex:maybe-track-codex-app-used-plan
    "codex_apps"
    (codex:mcp-app-usage-metadata "calendar" "Calendar")
    ("calendar" "drive")
    "gpt-5"
    "thread-1"
    "turn-1")
  ((CodexMcpAppUsedTrackingPlan
     (CodexMcpTrackEventsContext "gpt-5" "thread-1" "turn-1")
     (CodexMcpAppInvocation
       "calendar"
       "Calendar"
       (CodexMcpAppInvocationTypeExplicit)))))

!(assertEqualToResult
  (codex:maybe-track-codex-app-used-plan
    "codex_apps"
    (codex:mcp-app-usage-metadata "drive" "Drive")
    ("calendar")
    "gpt-5"
    "thread-1"
    "turn-1")
  ((CodexMcpAppUsedTrackingPlan
     (CodexMcpTrackEventsContext "gpt-5" "thread-1" "turn-1")
     (CodexMcpAppInvocation
       "drive"
       "Drive"
       (CodexMcpAppInvocationTypeImplicit)))))

!(assertEqualToResult
  (codex:maybe-track-codex-app-used-plan
    "codex_apps"
    (codex:mcp-app-usage-metadata CodexAbsent "Unknown App")
    ("calendar")
    "gpt-5"
    "thread-1"
    "turn-1")
  ((CodexMcpAppUsedTrackingPlan
     (CodexMcpTrackEventsContext "gpt-5" "thread-1" "turn-1")
     (CodexMcpAppInvocation
       CodexAbsent
       "Unknown App"
       (CodexMcpAppInvocationTypeImplicit)))))

!(assertEqualToResult
  (codex:maybe-track-codex-app-used-plan-from-tools
    "codex_apps"
    "create_event"
    ((test:mcp-usage-tool-info
       "codex_apps"
       "create_event"
       "calendar"
       "Calendar"))
    ("calendar")
    "gpt-5"
    "thread-1"
    "turn-1")
  ((CodexMcpAppUsedTrackingPlan
     (CodexMcpTrackEventsContext "gpt-5" "thread-1" "turn-1")
     (CodexMcpAppInvocation
       "calendar"
       "Calendar"
       (CodexMcpAppInvocationTypeExplicit)))))

!(assertEqualToResult
  (codex:maybe-track-codex-app-used-plan-from-tools
    "filesystem"
    "read_file"
    ((test:mcp-usage-tool-info
       "filesystem"
       "read_file"
       "files"
       "Files"))
    ("files")
    "gpt-5"
    "thread-1"
    "turn-1")
  (Empty))

!(assertEqualToResult
  (codex:maybe-track-codex-app-used-plan-from-tools
    "codex_apps"
    "missing_tool"
    ()
    ("calendar")
    "gpt-5"
    "thread-1"
    "turn-1")
  ((CodexMcpAppUsedTrackingPlan
     (CodexMcpTrackEventsContext "gpt-5" "thread-1" "turn-1")
     (CodexMcpAppInvocation
       CodexAbsent
       CodexAbsent
       (CodexMcpAppInvocationTypeImplicit)))))
