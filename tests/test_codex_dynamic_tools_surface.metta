!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:dynamic_tools)

(= (test:ticket-schema)
   (JsonObject
     ((JsonPair "type" (JsonString "object"))
      (JsonPair
        "properties"
        (JsonObject
          ((JsonPair
             "id"
             (JsonObject
               ((JsonPair "type" (JsonString "string")))))))))))

(= (test:dynamic-spec-json-defer-loading)
   (JsonObject
     ((JsonPair "name" (JsonString "lookup_ticket"))
      (JsonPair "description" (JsonString "Fetch a ticket"))
      (JsonPair "inputSchema" (test:ticket-schema))
      (JsonPair "deferLoading" (JsonBool True)))))

(= (test:dynamic-spec-json-legacy-hidden)
   (JsonObject
     ((JsonPair "name" (JsonString "lookup_ticket"))
      (JsonPair "description" (JsonString "Fetch a ticket"))
      (JsonPair "inputSchema" (JsonObject ((JsonPair "properties" (JsonObject ())))))
      (JsonPair "exposeToContext" (JsonBool False)))))

(= (test:dynamic-spec-json-legacy-visible)
   (JsonObject
     ((JsonPair "name" (JsonString "lookup_ticket"))
      (JsonPair "description" (JsonString "Fetch a ticket"))
      (JsonPair "inputSchema" (JsonObject ((JsonPair "properties" (JsonObject ())))))
      (JsonPair "exposeToContext" (JsonBool True)))))

(= (test:dynamic-spec-json-defaults)
   (JsonObject
     ((JsonPair "name" (JsonString "lookup_ticket"))
      (JsonPair "description" (JsonString "Fetch a ticket"))
      (JsonPair "inputSchema" (JsonObject ((JsonPair "properties" (JsonObject ()))))))))

!(assertEqualToResult
  (codex:dynamic-tool-spec-defer-loading
    (codex:dynamic-tool-spec-from-json
      (test:dynamic-spec-json-defer-loading)))
  (True))

!(assertEqualToResult
  (codex:dynamic-tool-spec-defer-loading
    (codex:dynamic-tool-spec-from-json
      (test:dynamic-spec-json-legacy-hidden)))
  (True))

!(assertEqualToResult
  (codex:dynamic-tool-spec-defer-loading
    (codex:dynamic-tool-spec-from-json
      (test:dynamic-spec-json-legacy-visible)))
  (False))

!(assertEqualToResult
  (codex:dynamic-tool-spec-defer-loading
    (codex:dynamic-tool-spec-from-json
      (test:dynamic-spec-json-defaults)))
  (False))

!(assertEqualToResult
  (json-stringify
    (codex:dynamic-tool-spec-json
      (codex:dynamic-tool-spec
        CodexAbsent
        "lookup_ticket"
        "Fetch a ticket"
        (test:ticket-schema)
        False)))
  ("{\"name\":\"lookup_ticket\",\"description\":\"Fetch a ticket\",\"inputSchema\":{\"type\":\"object\",\"properties\":{\"id\":{\"type\":\"string\"}}},\"deferLoading\":false}"))

!(assertEqualToResult
  (json-stringify
    (codex:dynamic-tool-spec-json
      (codex:dynamic-tool-spec
        "tickets"
        "lookup_ticket"
        "Fetch a ticket"
        (test:ticket-schema)
        True)))
  ("{\"namespace\":\"tickets\",\"name\":\"lookup_ticket\",\"description\":\"Fetch a ticket\",\"inputSchema\":{\"type\":\"object\",\"properties\":{\"id\":{\"type\":\"string\"}}},\"deferLoading\":true}"))

!(assertEqualToResult
  (json-stringify
    (codex:dynamic-tool-call-request-json
      (codex:dynamic-tool-call-request
        "call_1"
        "turn_1"
        CodexAbsent
        "lookup_ticket"
        (JsonObject ((JsonPair "id" (JsonString "OPS-7")))))))
  ("{\"callId\":\"call_1\",\"turnId\":\"turn_1\",\"namespace\":null,\"tool\":\"lookup_ticket\",\"arguments\":{\"id\":\"OPS-7\"}}"))

!(assertEqualToResult
  (codex:dynamic-tool-call-request-namespace
    (codex:dynamic-tool-call-request-from-json
      (JsonObject
        ((JsonPair "callId" (JsonString "call_1"))
         (JsonPair "turnId" (JsonString "turn_1"))
         (JsonPair "tool" (JsonString "lookup_ticket"))
         (JsonPair "arguments" (JsonObject ()))))))
  (CodexAbsent))

!(assertEqualToResult
  (json-stringify
    (codex:dynamic-tool-response-json
      (codex:dynamic-tool-response
        ((codex:dynamic-tool-output-item-input-text "done")
         (codex:dynamic-tool-output-item-input-image
           "data:image/png;base64,AAA"))
        False)))
  ("{\"contentItems\":[{\"type\":\"inputText\",\"text\":\"done\"},{\"type\":\"inputImage\",\"imageUrl\":\"data:image/png;base64,AAA\"}],\"success\":false}"))

!(assertEqualToResult
  (codex:dynamic-tool-response-success
    (codex:dynamic-tool-response-from-json
      (JsonObject
        ((JsonPair
           "contentItems"
           (JsonArray
             ((JsonObject
                ((JsonPair "type" (JsonString "inputText"))
                 (JsonPair "text" (JsonString "done")))))))
         (JsonPair "success" (JsonBool True))))))
  (True))
