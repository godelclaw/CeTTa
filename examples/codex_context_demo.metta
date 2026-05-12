!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:context)

(= (codex-context-demo-mcp-result)
   (JsonObject
     ((JsonPair "content"
        (JsonArray
          ((JsonObject
             ((JsonPair "type" (JsonString "image"))
              (JsonPair "mimeType" (JsonString "image/png"))
              (JsonPair "data" (JsonString "AAA")))))))
      (JsonPair "isError" (JsonBool False)))))

!(println! "=== Codex context demo ===")
!(println!
  (json-stringify
    (codex:item-json
      (codex:tool-output-to-response-item
        (codex:function-tool-output-from-text "ok" True)
        "fn-1"
        (codex:function-payload "{}")))))
!(println!
  (json-stringify
    (codex:item-json
      (codex:tool-output-to-response-item
        (codex:mcp-tool-output
          (codex-context-demo-mcp-result)
          (JsonObject ())
          500
          False)
        "mcp-2"
        (codex:mcp-payload "server" "tool" "{}")))))
!(println!
  (json-stringify
    (codex:tool-output-code-mode-result
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
      (codex:function-payload "{}"))))
