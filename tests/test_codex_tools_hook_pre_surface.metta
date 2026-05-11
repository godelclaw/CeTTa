!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)
!(import! &self codex:tools)

!(assertEqualToResult
  (json-stringify
    (codex:pre-tool-use-payload-json
      (codex:exec-command-pre-tool-use-payload
        (codex:tool-call
          "call-43"
          "exec_command"
          "{\"cmd\":\"printf exec command\"}"))))
  ("{\"tool_name\":{\"name\":\"Bash\",\"matcher_aliases\":[]},\"tool_input\":{\"command\":\"printf exec command\"}}"))

!(assertEqual
  (codex:exec-command-pre-tool-use-payload
    (codex:tool-call
      "call-44"
      "write_stdin"
      "{\"session_id\":45,\"chars\":\"echo hi\"}"))
  Empty)
