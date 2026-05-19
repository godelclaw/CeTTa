!(register-module! ../codex)
!(import! &self codex:unified_exec_async_watcher)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:item-json-string
    (codex:unified-exec-emit-exec-end-for-unified-exec-with-parsed
      "call-end-ok"
      "turn-end"
      ("cat" "README.md")
      "/repo"
      ((CodexParsedCommandRead "cat README.md" "README.md" "README.md"))
      "123"
      (codex:unified-exec-async-watcher-transcript 6 "hello\n")
      "fallback"
      0
      (codex:duration 1 250000000)
      "hello\n"))
  ("{\"type\":\"exec_command_end\",\"call_id\":\"call-end-ok\",\"process_id\":\"123\",\"turn_id\":\"turn-end\",\"command\":[\"cat\",\"README.md\"],\"cwd\":\"/repo\",\"parsed_cmd\":[{\"type\":\"read\",\"cmd\":\"cat README.md\",\"name\":\"README.md\",\"path\":\"README.md\"}],\"source\":\"unified_exec_startup\",\"stdout\":\"hello\\n\",\"stderr\":\"\",\"aggregated_output\":\"hello\\n\",\"exit_code\":0,\"duration\":{\"secs\":1,\"nanos\":250000000},\"formatted_output\":\"hello\\n\",\"status\":\"completed\"}"))

!(assertEqualToResult
  (codex:item-json-string
    (codex:unified-exec-emit-exec-end-for-unified-exec-with-parsed
      "call-end-nonzero"
      "turn-end"
      ("false")
      "/repo"
      ((CodexParsedCommandUnknown "false"))
      CodexAbsent
      (codex:unified-exec-async-watcher-transcript 0 "")
      "fallback err"
      2
      (codex:duration 0 1)
      "fallback err"))
  ("{\"type\":\"exec_command_end\",\"call_id\":\"call-end-nonzero\",\"turn_id\":\"turn-end\",\"command\":[\"false\"],\"cwd\":\"/repo\",\"parsed_cmd\":[{\"type\":\"unknown\",\"cmd\":\"false\"}],\"source\":\"unified_exec_startup\",\"stdout\":\"fallback err\",\"stderr\":\"\",\"aggregated_output\":\"fallback err\",\"exit_code\":2,\"duration\":{\"secs\":0,\"nanos\":1},\"formatted_output\":\"fallback err\",\"status\":\"failed\"}"))

!(assertEqualToResult
  (codex:item-json-string
    (codex:unified-exec-spawn-exit-watcher-finished-event-with-parsed
      (codex:unified-exec-async-watcher-process-snapshot
        "pty failed"
        0)
      "call-watch-failed"
      "turn-end"
      ("cat")
      "/repo"
      ((CodexParsedCommandUnknown "cat"))
      CodexAbsent
      (codex:unified-exec-async-watcher-transcript 3 "out")
      (codex:duration 2 0)
      "out\npty failed"))
  ("{\"type\":\"exec_command_end\",\"call_id\":\"call-watch-failed\",\"turn_id\":\"turn-end\",\"command\":[\"cat\"],\"cwd\":\"/repo\",\"parsed_cmd\":[{\"type\":\"unknown\",\"cmd\":\"cat\"}],\"source\":\"unified_exec_startup\",\"stdout\":\"out\",\"stderr\":\"pty failed\",\"aggregated_output\":\"out\\npty failed\",\"exit_code\":-1,\"duration\":{\"secs\":2,\"nanos\":0},\"formatted_output\":\"out\\npty failed\",\"status\":\"failed\"}"))
