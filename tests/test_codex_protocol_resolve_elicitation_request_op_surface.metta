!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:op-type
    (codex:resolve-elicitation-op
      "rmcp"
      (codex:mcp-request-id-string "req_123")
      (codex:elicitation-action-accept)))
  ("resolve_elicitation"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:resolve-elicitation-op
        "rmcp"
        (codex:mcp-request-id-string "req_123")
        (codex:elicitation-action-accept))))
  ("{\"type\":\"resolve_elicitation\",\"server_name\":\"rmcp\",\"request_id\":\"req_123\",\"decision\":\"accept\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:resolve-elicitation-op
        "rmcp"
        (codex:mcp-request-id-integer 17)
        (codex:elicitation-action-cancel)
        (JsonObject
          ((JsonPair "approved" (JsonBool True))
           (JsonPair "values" (JsonArray ((JsonString "x"))))))
        (JsonObject
          ((JsonPair "source" (JsonString "mcp"))
           (JsonPair "n" (JsonNumber 1)))))))
  ("{\"type\":\"resolve_elicitation\",\"server_name\":\"rmcp\",\"request_id\":17,\"decision\":\"cancel\",\"content\":{\"approved\":true,\"values\":[\"x\"]},\"meta\":{\"source\":\"mcp\",\"n\":1}}"))
