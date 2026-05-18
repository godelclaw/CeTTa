!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:item-type
    (codex:exec-command-begin-event
      "call-exec-1"
      CodexAbsent
      "turn-1"
      ("rg" "-n" "TODO" "src")
      "/repo"
      ((CodexParsedCommandSearch "rg -n TODO src" "TODO" "src"))
      (codex:exec-command-source-agent)
      CodexAbsent))
  ("exec_command_begin"))

!(assertEqualToResult
  (codex:item-json-string
    (codex:exec-command-begin-event
      "call-exec-1"
      CodexAbsent
      "turn-1"
      ("rg" "-n" "TODO" "src")
      "/repo"
      ((CodexParsedCommandSearch "rg -n TODO src" "TODO" "src"))
      (codex:exec-command-source-agent)
      CodexAbsent))
  ("{\"type\":\"exec_command_begin\",\"call_id\":\"call-exec-1\",\"turn_id\":\"turn-1\",\"command\":[\"rg\",\"-n\",\"TODO\",\"src\"],\"cwd\":\"/repo\",\"parsed_cmd\":[{\"type\":\"search\",\"cmd\":\"rg -n TODO src\",\"query\":\"TODO\",\"path\":\"src\"}],\"source\":\"agent\"}"))

!(assertEqualToResult
  (codex:item-type
    (codex:exec-command-end-event
      "call-exec-2"
      "proc-9"
      "turn-2"
      ("cat")
      "/repo"
      ((CodexParsedCommandUnknown "cat"))
      (codex:exec-command-source-unified-exec-interaction)
      "exit\n"
      "out\n"
      "err\n"
      "out\nerr\n"
      1
      (codex:duration 0 12000000)
      "formatted"
      (codex:exec-command-status-failed)))
  ("exec_command_end"))

!(assertEqualToResult
  (codex:item-json-string
    (codex:exec-command-end-event
      "call-exec-2"
      "proc-9"
      "turn-2"
      ("cat")
      "/repo"
      ((CodexParsedCommandUnknown "cat"))
      (codex:exec-command-source-unified-exec-interaction)
      "exit\n"
      "out\n"
      "err\n"
      "out\nerr\n"
      1
      (codex:duration 0 12000000)
      "formatted"
      (codex:exec-command-status-failed)))
  ("{\"type\":\"exec_command_end\",\"call_id\":\"call-exec-2\",\"process_id\":\"proc-9\",\"turn_id\":\"turn-2\",\"command\":[\"cat\"],\"cwd\":\"/repo\",\"parsed_cmd\":[{\"type\":\"unknown\",\"cmd\":\"cat\"}],\"source\":\"unified_exec_interaction\",\"interaction_input\":\"exit\\n\",\"stdout\":\"out\\n\",\"stderr\":\"err\\n\",\"aggregated_output\":\"out\\nerr\\n\",\"exit_code\":1,\"duration\":{\"secs\":0,\"nanos\":12000000},\"formatted_output\":\"formatted\",\"status\":\"failed\"}"))

!(assertEqualToResult
  (codex:item-type
    (codex:dynamic-tool-call-request-event
      "dyn-call-1"
      "turn-3"
      CodexAbsent
      "lookup"
      (JsonObject
        ((JsonPair "query" (JsonString "alpha"))))))
  ("dynamic_tool_call_request"))

!(assertEqualToResult
  (codex:item-json-string
    (codex:dynamic-tool-call-request-event
      "dyn-call-1"
      "turn-3"
      CodexAbsent
      "lookup"
      (JsonObject
        ((JsonPair "query" (JsonString "alpha"))))))
  ("{\"type\":\"dynamic_tool_call_request\",\"call_id\":\"dyn-call-1\",\"turn_id\":\"turn-3\",\"namespace\":null,\"tool\":\"lookup\",\"arguments\":{\"query\":\"alpha\"}}"))

!(assertEqualToResult
  (codex:item-type
    (codex:dynamic-tool-call-response-event
      "dyn-call-2"
      "turn-4"
      "browser"
      "screenshot"
      (JsonObject
        ((JsonPair "url" (JsonString "https://example.com"))))
      ((codex:protocol-dynamic-tool-output-item-input-text "caption")
       (codex:protocol-dynamic-tool-output-item-input-image "data:image/png;base64,AAA"))
      True
      CodexAbsent
      (codex:duration 1 5000000)))
  ("dynamic_tool_call_response"))

!(assertEqualToResult
  (codex:item-json-string
    (codex:dynamic-tool-call-response-event
      "dyn-call-2"
      "turn-4"
      "browser"
      "screenshot"
      (JsonObject
        ((JsonPair "url" (JsonString "https://example.com"))))
      ((codex:protocol-dynamic-tool-output-item-input-text "caption")
       (codex:protocol-dynamic-tool-output-item-input-image "data:image/png;base64,AAA"))
      True
      CodexAbsent
      (codex:duration 1 5000000)))
  ("{\"type\":\"dynamic_tool_call_response\",\"call_id\":\"dyn-call-2\",\"turn_id\":\"turn-4\",\"namespace\":\"browser\",\"tool\":\"screenshot\",\"arguments\":{\"url\":\"https://example.com\"},\"content_items\":[{\"type\":\"inputText\",\"text\":\"caption\"},{\"type\":\"inputImage\",\"imageUrl\":\"data:image/png;base64,AAA\"}],\"success\":true,\"error\":null,\"duration\":{\"secs\":1,\"nanos\":5000000}}"))

!(assertEqualToResult
  (codex:item-type
    (codex:mcp-tool-call-end-event
      "mcp-call-3"
      (codex:mcp-invocation "memory" "read_graph" CodexAbsent)
      CodexAbsent
      (codex:duration 0 250000000)
      (codex:mcp-tool-call-result-ok
        (codex:mcp-call-tool-result
          ((JsonObject
             ((JsonPair "type" (JsonString "text"))
              (JsonPair "text" (JsonString "ok")))))
          CodexAbsent
          False
          CodexAbsent))))
  ("mcp_tool_call_end"))

!(assertEqualToResult
  (codex:item-json-string
    (codex:mcp-tool-call-end-event
      "mcp-call-3"
      (codex:mcp-invocation "memory" "read_graph" CodexAbsent)
      CodexAbsent
      (codex:duration 0 250000000)
      (codex:mcp-tool-call-result-ok
        (codex:mcp-call-tool-result
          ((JsonObject
             ((JsonPair "type" (JsonString "text"))
              (JsonPair "text" (JsonString "ok")))))
          CodexAbsent
          False
          CodexAbsent))))
  ("{\"type\":\"mcp_tool_call_end\",\"call_id\":\"mcp-call-3\",\"invocation\":{\"server\":\"memory\",\"tool\":\"read_graph\",\"arguments\":null},\"duration\":{\"secs\":0,\"nanos\":250000000},\"result\":{\"Ok\":{\"content\":[{\"type\":\"text\",\"text\":\"ok\"}],\"isError\":false}}}"))

!(assertEqualToResult
  (codex:item-json-string
    (codex:mcp-tool-call-end-event
      "mcp-call-4"
      (codex:mcp-invocation "memory" "read_graph" (JsonObject ()))
      "app://memory"
      (codex:duration 1 0)
      (codex:mcp-tool-call-result-err "tool timed out")))
  ("{\"type\":\"mcp_tool_call_end\",\"call_id\":\"mcp-call-4\",\"invocation\":{\"server\":\"memory\",\"tool\":\"read_graph\",\"arguments\":{}},\"mcp_app_resource_uri\":\"app://memory\",\"duration\":{\"secs\":1,\"nanos\":0},\"result\":{\"Err\":\"tool timed out\"}}"))
