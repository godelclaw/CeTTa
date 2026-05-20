!(register-module! ../codex)
!(import! &self codex:mcp_tool_call)

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
