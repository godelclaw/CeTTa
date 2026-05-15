!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:context)

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:tool-output-to-response-item
        (codex:exec-command-tool-output
          "call-42"
          "abc123"
          1250
          "hello"
          10
          CodexAbsent
          0
          2
          CodexAbsent)
        "call-42"
        (codex:function-payload "{}"))))
  ("{\"type\":\"function_call_output\",\"call_id\":\"call-42\",\"output\":\"Chunk ID: abc123\\nWall time: 1.2500 seconds\\nProcess exited with code 0\\nOriginal token count: 2\\nOutput:\\nhello\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:tool-output-post-tool-use-response
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
      "call-42"
      (codex:function-payload "{}")))
  ("\"hello\""))

!(assertEqualToResult
  (codex:tool-output-post-tool-use-response
    (codex:exec-command-tool-output
      "call-42"
      "abc123"
      1250
      "hello"
      10
      45
      CodexAbsent
      CodexAbsent
      "hook")
    "call-42"
    (codex:function-payload "{}"))
  (CodexAbsent))
