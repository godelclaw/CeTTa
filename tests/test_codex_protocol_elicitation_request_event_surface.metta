!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:item-type
    (codex:elicitation-request-event
      CodexAbsent
      "memory"
      (codex:mcp-request-id-string "req-1")
      (codex:elicitation-request-form
        CodexAbsent
        "Provide a value."
        (JsonObject
          ((JsonPair "type" (JsonString "object")))))))
  ("elicitation_request"))

!(assertEqualToResult
  (codex:elicitation-request-message
    (codex:elicitation-request-url
      CodexAbsent
      "Open auth."
      "https://example.test/auth"
      "elicit-1"))
  ("Open auth."))

!(assertEqualToResult
  (codex:item-json-string
    (codex:elicitation-request-event
      CodexAbsent
      "memory"
      (codex:mcp-request-id-string "req-1")
      (codex:elicitation-request-form
        CodexAbsent
        "Provide a value."
        (JsonObject
          ((JsonPair "type" (JsonString "object")))))))
  ("{\"type\":\"elicitation_request\",\"server_name\":\"memory\",\"id\":\"req-1\",\"request\":{\"mode\":\"form\",\"message\":\"Provide a value.\",\"requested_schema\":{\"type\":\"object\"}}}"))

!(assertEqualToResult
  (codex:item-json-string
    (codex:elicitation-request-event
      "turn-7"
      "oauth"
      (codex:mcp-request-id-integer 42)
      (codex:elicitation-request-url
        (JsonObject
          ((JsonPair "client" (JsonString "codex"))))
        "Open auth."
        "https://example.test/auth"
        "elicit-1")))
  ("{\"type\":\"elicitation_request\",\"turn_id\":\"turn-7\",\"server_name\":\"oauth\",\"id\":42,\"request\":{\"mode\":\"url\",\"_meta\":{\"client\":\"codex\"},\"message\":\"Open auth.\",\"url\":\"https://example.test/auth\",\"elicitation_id\":\"elicit-1\"}}"))
