!(import! &self json)

!(assertEqualToResult
  (json-string-value
    (json-object-get
      (json-parse "{\"type\":\"message\",\"count\":2,\"ok\":true,\"items\":[\"a\",null]}")
      "type"))
  ("message"))

!(assertEqualToResult
  (json-number-value
    (json-object-get
      (json-parse "{\"type\":\"message\",\"count\":2,\"ok\":true,\"items\":[\"a\",null]}")
      "count"))
  ("2"))

!(assertEqualToResult
  (json-bool-value
    (json-object-get
      (json-parse "{\"type\":\"message\",\"count\":2,\"ok\":true,\"items\":[\"a\",null]}")
      "ok"))
  (True))

!(assertEqualToResult
  (json-stringify
    (JsonObject
      ((JsonPair "type" (JsonString "assistant_message"))
       (JsonPair "text" (JsonString "hello\nworld"))
       (JsonPair "done" (JsonBool True)))))
  ("{\"type\":\"assistant_message\",\"text\":\"hello\\nworld\",\"done\":true}"))
