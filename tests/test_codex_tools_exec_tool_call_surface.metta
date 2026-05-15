!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)
 
!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:tool-call
        "call_exec_tool"
        "exec_command"
        "{\"cmd\":\"printf hello\",\"login\":false,\"yield_time_ms\":1000}")))
  ("{\"type\":\"custom_tool_call\",\"call_id\":\"call_exec_tool\",\"name\":\"exec_command\",\"input\":\"{\\\"cmd\\\":\\\"printf hello\\\",\\\"login\\\":false,\\\"yield_time_ms\\\":1000}\"}"))
