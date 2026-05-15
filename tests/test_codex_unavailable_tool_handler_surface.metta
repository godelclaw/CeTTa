!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:context)
!(import! &self codex:function_tool)
!(import! &self codex:protocol)
!(import! &self codex:tool_name)
!(import! &self codex:unavailable_tool_handler)

!(assertEqualToResult
  (codex:function-call-error-display
    (codex:function-call-error-respond-to-model "bad input"))
  ("bad input"))

!(assertEqualToResult
  (codex:function-call-error-display
    (codex:function-call-error-missing-local-shell-call-id))
  ("LocalShellCall without call_id or id"))

!(assertEqualToResult
  (codex:function-call-error-display
    (codex:function-call-error-fatal "boom"))
  ("Fatal error: boom"))

!(assertEqualToResult
  (codex:unavailable-tool-handler-kind)
  ("function"))

!(assertEqualToResult
  (codex:unavailable-tool-message
    (codex:namespaced-tool-name "mcp__calendar__" "create_event")
    (codex:default-unavailable-tool-next-step))
  ("Tool `mcp__calendar__create_event` is not currently available. It appeared in earlier tool calls in this conversation, but its implementation is not available in the current request. Retry after the tool becomes available or ask the user to re-enable it."))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:tool-output-to-response-item
        (CodexToolOutputFunction
          ((CodexInputText
             (codex:unavailable-tool-message
               (codex:plain-tool-name "mcp__server__lookup")
               (codex:default-unavailable-tool-next-step))))
          False
          CodexAbsent)
        "call-1"
        (codex:function-payload "{}"))))
  ("{\"type\":\"function_call_output\",\"call_id\":\"call-1\",\"output\":\"Tool `mcp__server__lookup` is not currently available. It appeared in earlier tool calls in this conversation, but its implementation is not available in the current request. Retry after the tool becomes available or ask the user to re-enable it.\"}"))

!(assertEqualToResult
  (codex:tool-output-success-for-logging
    (CodexToolOutputFunction
      ((CodexInputText
         (codex:unavailable-tool-message
           (codex:plain-tool-name "mcp__server__lookup")
           (codex:default-unavailable-tool-next-step))))
      False
      CodexAbsent))
  (False))

!(assertEqualToResult
  (codex:run-unavailable-tool-handler
    (codex:plain-tool-name "mcp__server__lookup")
    (codex:function-payload "{}"))
  ((CodexUnavailableToolHandlerOk
     (CodexToolOutputFunction
       ((CodexInputText "Tool `mcp__server__lookup` is not currently available. It appeared in earlier tool calls in this conversation, but its implementation is not available in the current request. Retry after the tool becomes available or ask the user to re-enable it."))
       False
       CodexAbsent))))

!(assertEqualToResult
  (codex:function-call-error-display
    (case
      (codex:run-unavailable-tool-handler
        (codex:plain-tool-name "mcp__server__lookup")
        (codex:custom-payload "patch"))
      (((CodexUnavailableToolHandlerErr $error) $error))))
  ("unavailable tool handler received unsupported payload"))
