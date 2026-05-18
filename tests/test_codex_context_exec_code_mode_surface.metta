!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:context)

!(assertEqualToResult
  (codex:tool-output-code-mode-result-json-string
    (codex:exec-command-tool-output
      "call-42"
      "abc123"
      1250
      "hello"
      10
      CodexAbsent
      0
      2
      "hook")
    (codex:function-payload "{}"))
  ("{\"chunk_id\":\"abc123\",\"wall_time_seconds\":1.25,\"exit_code\":0,\"original_token_count\":2,\"output\":\"hello\"}"))
