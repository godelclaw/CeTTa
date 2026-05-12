!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:context)

(= (codex-context-test-tool)
   (JsonObject
     ((JsonPair "type" (JsonString "function"))
      (JsonPair "name" (JsonString "create_event")))))

(= (codex-context-test-mcp-image-result)
   (JsonObject
     ((JsonPair "content"
        (JsonArray
          ((JsonObject
             ((JsonPair "type" (JsonString "image"))
              (JsonPair "mimeType" (JsonString "image/png"))
              (JsonPair "data" (JsonString "AAA")))))))
      (JsonPair "isError" (JsonBool False)))))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:tool-output-to-response-item
        (codex:tool-search-tool-output ((codex-context-test-tool)))
        "search-1"
        (codex:tool-search-payload "calendar"))))
  ("{\"type\":\"tool_search_output\",\"call_id\":\"search-1\",\"status\":\"completed\",\"execution\":\"client\",\"tools\":[{\"type\":\"function\",\"name\":\"create_event\"}]}"))

!(assertEqualToResult
  (json-stringify
    (codex:response-input-to-code-mode-result
      (codex:mcp-tool-call-output
        "mcp-1"
        (codex-context-test-mcp-image-result))))
  ("{\"content\":[{\"type\":\"image\",\"mimeType\":\"image/png\",\"data\":\"AAA\"}],\"isError\":false}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:tool-output-to-response-item
        (codex:mcp-tool-output
          (codex-context-test-mcp-image-result)
          (JsonObject ())
          500
          False)
        "mcp-2"
        (codex:mcp-payload "server" "tool" "{}"))))
  ("{\"type\":\"function_call_output\",\"call_id\":\"mcp-2\",\"output\":[{\"type\":\"input_text\",\"text\":\"Wall time: 0.5000 seconds\\nOutput:\"},{\"type\":\"input_image\",\"image_url\":\"data:image/png;base64,AAA\",\"detail\":\"high\"}]}"))

!(assertEqualToResult
  (json-stringify
    (codex:tool-output-code-mode-result
      (codex:mcp-tool-output
        (codex-context-test-mcp-image-result)
        (JsonObject ())
        500
        False)
      (codex:mcp-payload "server" "tool" "{}")))
  ("{\"content\":[{\"type\":\"image\",\"mimeType\":\"image/png\",\"data\":\"AAA\"}],\"isError\":false}"))
