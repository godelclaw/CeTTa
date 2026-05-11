!(register-module! ../codex)
!(import! &self codex:protocol)
!(import! &self codex:tools)

!(assertEqualToResult
  (codex:is-string-contains
    (codex:tool-result-output-text
      (once
        (codex:run-tool-call-item
          (codex:tool-call
            "call_exec_tool"
            "exec_command"
            "{\"cmd\":\"printf hello\",\"login\":false,\"yield_time_ms\":1000}"))))
    "Output:\nhello")
  (True))
