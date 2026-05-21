!(register-module! ../codex)
!(import! &self codex:js_repl)
!(import! &self codex:protocol)

!(assertEqual
  (codex:item-json-string
    (codex:emit-js-repl-exec-begin-event
      "call-js"
      "turn-js"
      "/repo"))
  "{\"type\":\"exec_command_begin\",\"call_id\":\"call-js\",\"turn_id\":\"turn-js\",\"command\":[\"js_repl\"],\"cwd\":\"/repo\",\"parsed_cmd\":[{\"type\":\"unknown\",\"cmd\":\"js_repl\"}],\"source\":\"agent\"}")

!(assertEqual
  (codex:item-json-string
    (codex:emit-js-repl-exec-end-event
      "call-js"
      "turn-js"
      "/repo"
      "hello"
      CodexAbsent
      12))
  "{\"type\":\"exec_command_end\",\"call_id\":\"call-js\",\"turn_id\":\"turn-js\",\"command\":[\"js_repl\"],\"cwd\":\"/repo\",\"parsed_cmd\":[{\"type\":\"unknown\",\"cmd\":\"js_repl\"}],\"source\":\"agent\",\"stdout\":\"hello\",\"stderr\":\"\",\"aggregated_output\":\"hello\",\"exit_code\":0,\"duration\":{\"secs\":0,\"nanos\":12000000},\"formatted_output\":\"hello\",\"status\":\"completed\"}")

!(assertEqual
  (codex:item-json-string
    (codex:emit-js-repl-exec-end-event
      "call-js"
      "turn-js"
      "/repo"
      ""
      "boom"
      1012))
  "{\"type\":\"exec_command_end\",\"call_id\":\"call-js\",\"turn_id\":\"turn-js\",\"command\":[\"js_repl\"],\"cwd\":\"/repo\",\"parsed_cmd\":[{\"type\":\"unknown\",\"cmd\":\"js_repl\"}],\"source\":\"agent\",\"stdout\":\"\",\"stderr\":\"boom\",\"aggregated_output\":\"boom\",\"exit_code\":1,\"duration\":{\"secs\":1,\"nanos\":12000000},\"formatted_output\":\"boom\",\"status\":\"failed\"}")
