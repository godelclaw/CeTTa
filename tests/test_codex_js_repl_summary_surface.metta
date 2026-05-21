!(register-module! ../codex)
!(import! &self codex:js_repl)

!(assertEqual
  (codex:js-repl-summarize-tool-call-error "boom")
  (CodexJsReplToolCallResponseSummary
    CodexAbsent
    (CodexJsReplToolCallPayloadKindError)
    "boom"
    4
    CodexAbsent
    CodexAbsent
    CodexAbsent
    CodexAbsent
    CodexAbsent))

!(assertEqual
  (codex:js-repl-summarize-tool-call-error "")
  (CodexJsReplToolCallResponseSummary
    CodexAbsent
    (CodexJsReplToolCallPayloadKindError)
    CodexAbsent
    0
    CodexAbsent
    CodexAbsent
    CodexAbsent
    CodexAbsent
    CodexAbsent))

!(assertEqual
  (codex:js-repl-summarize-tool-call-response
    (CodexResponseItemMessage
      "assistant"
      ((CodexInputText "line 1")
       (CodexInputImage "data:image/png;base64,AAA" "high")
       (CodexOutputText "line 2")
       (CodexOutputText "   "))
      CodexAbsent))
  (CodexJsReplToolCallResponseSummary
    "message"
    (CodexJsReplToolCallPayloadKindMessageContent)
    "line 1\nline 2"
    13
    4
    3
    1
    CodexAbsent
    CodexAbsent))

!(assertEqual
  (codex:js-repl-summarize-tool-call-response
    (CodexResponseItemFunctionCallOutput
      "fn-call"
      (CodexFunctionCallOutputText "plain output")))
  (CodexJsReplToolCallResponseSummary
    "function_call_output"
    (CodexJsReplToolCallPayloadKindFunctionText)
    "plain output"
    12
    CodexAbsent
    CodexAbsent
    CodexAbsent
    CodexAbsent
    CodexAbsent))

!(assertEqual
  (codex:js-repl-summarize-tool-call-response
    (CodexResponseItemFunctionCallOutput
      "fn-call"
      (CodexFunctionCallOutputContentItems
        ((CodexInputText "alpha")
         (CodexInputImage "data:image/png;base64,BBB" "low")
         (CodexInputText "beta")))))
  (CodexJsReplToolCallResponseSummary
    "function_call_output"
    (CodexJsReplToolCallPayloadKindFunctionContentItems)
    "alpha\nbeta"
    10
    3
    2
    1
    CodexAbsent
    CodexAbsent))

!(assertEqual
  (codex:js-repl-summarize-tool-call-response
    (CodexResponseItemCustomToolCallOutput
      "custom-call"
      "tool"
      (CodexFunctionCallOutputText "custom output")))
  (CodexJsReplToolCallResponseSummary
    "custom_tool_call_output"
    (CodexJsReplToolCallPayloadKindCustomText)
    "custom output"
    13
    CodexAbsent
    CodexAbsent
    CodexAbsent
    CodexAbsent
    CodexAbsent))

!(assertEqual
  (codex:js-repl-summarize-tool-call-response
    (CodexResponseItemCustomToolCallOutput
      "custom-call"
      "tool"
      (CodexFunctionCallOutputContentItems
        ((CodexInputText "one")
         (CodexInputText "two")))))
  (CodexJsReplToolCallResponseSummary
    "custom_tool_call_output"
    (CodexJsReplToolCallPayloadKindCustomContentItems)
    "one\ntwo"
    7
    2
    2
    0
    CodexAbsent
    CodexAbsent))

!(assertEqual
  (codex:js-repl-summarize-tool-call-response
    (CodexResponseItemMcpToolCallOutput
      "mcp-call"
      (CodexMcpCallToolResult
        ((JsonObject
           ((JsonPair "type" (JsonString "text"))
            (JsonPair "text" (JsonString "ignored")))))
        (JsonObject ((JsonPair "ok" (JsonBool True))))
        False
        CodexAbsent)))
  (CodexJsReplToolCallResponseSummary
    "mcp_tool_call_output"
    (CodexJsReplToolCallPayloadKindMcpResult)
    "{\"ok\":true}"
    11
    1
    CodexAbsent
    CodexAbsent
    True
    False))

!(assertEqual
  (codex:js-repl-summarize-tool-call-response
    (CodexResponseItemMcpToolCallOutput
      "mcp-call"
      (JsonObject
        ((JsonPair "content"
           (JsonArray
             ((JsonObject
                ((JsonPair "type" (JsonString "text"))
                 (JsonPair "text" (JsonString "bad")))))))
         (JsonPair "isError" (JsonBool True))))))
  (CodexJsReplToolCallResponseSummary
    "mcp_tool_call_output"
    (CodexJsReplToolCallPayloadKindMcpErrorResult)
    "[{\"type\":\"text\",\"text\":\"bad\"}]"
    30
    1
    CodexAbsent
    CodexAbsent
    False
    True))

!(assertEqual
  (codex:js-repl-summarize-tool-call-response
    (CodexResponseItemMcpToolCallOutput
      "mcp-call"
      (JsonObject
        ((JsonPair "content"
           (JsonArray
             ((JsonObject
                ((JsonPair "type" (JsonString "text"))
                 (JsonPair "text" (JsonString "hello"))))
              (JsonObject
                ((JsonPair "type" (JsonString "image"))
                 (JsonPair "data" (JsonString "AAA"))
                 (JsonPair "mimeType" (JsonString "image/png"))
                 (JsonPair "_meta"
                   (JsonObject
                     ((JsonPair
                        "codex/imageDetail"
                        (JsonString "low"))))))))))
         (JsonPair "isError" (JsonBool False))))))
  (CodexJsReplToolCallResponseSummary
    "mcp_tool_call_output"
    (CodexJsReplToolCallPayloadKindMcpResult)
    "hello"
    5
    2
    1
    1
    False
    False))

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
