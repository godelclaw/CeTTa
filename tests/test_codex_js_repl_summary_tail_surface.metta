!(register-module! ../codex)
!(import! &self codex:js_repl)

!(assertEqual
  (codex:js-repl-summarize-tool-call-response
    (CodexResponseItemMcpToolCallOutput
      "mcp-call"
      (JsonObject
        ((JsonPair "content" (JsonArray ()))
         (JsonPair "structuredContent" JsonNull)))))
  (CodexJsReplToolCallResponseSummary
    "mcp_tool_call_output"
    (CodexJsReplToolCallPayloadKindMcpResult)
    "[]"
    2
    0
    CodexAbsent
    CodexAbsent
    True
    False))

!(assertEqual
  (codex:js-repl-summarize-tool-call-response
    (CodexResponseItemToolSearchOutput
      "search-call"
      "completed"
      "success"
      ((JsonObject
         ((JsonPair "name" (JsonString "read_file"))))
       (JsonObject
         ((JsonPair "name" (JsonString "write_file")))))))
  (CodexJsReplToolCallResponseSummary
    "tool_search_output"
    (CodexJsReplToolCallPayloadKindFunctionText)
    "[{\"name\":\"read_file\"},{\"name\":\"write_file\"}]"
    44
    2
    CodexAbsent
    CodexAbsent
    CodexAbsent
    CodexAbsent))
