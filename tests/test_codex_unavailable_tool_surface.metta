!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)
!(import! &self codex:unavailable_tool)

(= (codex-unavailable-tool-function-call $name $namespace)
   (CodexResponseItemFunctionCall
     CodexAbsent
     $name
     $namespace
     "{}"
     (format-args "call-{}" ($name))))

!(assertEqual
  (codex:collect-unavailable-called-tools
    ((codex-unavailable-tool-function-call "shell" CodexAbsent)
     (codex-unavailable-tool-function-call "mcp__server__lookup" CodexAbsent)
     (codex-unavailable-tool-function-call
       "_create_event"
       "mcp__codex_apps__calendar"))
    ())
  ((CodexToolName "_create_event" "mcp__codex_apps__calendar")
   (CodexToolName "mcp__server__lookup" CodexAbsent)))

!(assertEqual
  (codex:collect-unavailable-called-tools
    ((codex-unavailable-tool-function-call "mcp__server__lookup" CodexAbsent)
     (codex-unavailable-tool-function-call "mcp__server__search" CodexAbsent)
     (codex-unavailable-tool-function-call "mcp__server__missing" CodexAbsent))
    ("mcp__server__lookup" "mcp__server__search"))
  ((CodexToolName "mcp__server__missing" CodexAbsent)))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:function-call-response-item
        "call-1"
        "_create_event"
        "mcp__codex_apps__calendar"
        "{}"
        "call-_create_event")))
  ("{\"type\":\"function_call\",\"id\":\"call-1\",\"name\":\"_create_event\",\"namespace\":\"mcp__codex_apps__calendar\",\"arguments\":\"{}\",\"call_id\":\"call-_create_event\"}"))
