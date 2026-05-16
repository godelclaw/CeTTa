!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:op-type
    (codex:dynamic-tool-response-op
      "call_dyn_1"
      (codex:protocol-dynamic-tool-response
        ((codex:protocol-dynamic-tool-output-item-input-text "done"))
        True)))
  ("dynamic_tool_response"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:dynamic-tool-response-op
        "call_dyn_1"
        (codex:protocol-dynamic-tool-response
          ((codex:protocol-dynamic-tool-output-item-input-text "done"))
          True))))
  ("{\"type\":\"dynamic_tool_response\",\"id\":\"call_dyn_1\",\"response\":{\"contentItems\":[{\"type\":\"inputText\",\"text\":\"done\"}],\"success\":true}}"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:dynamic-tool-response-op
        "call_dyn_2"
        (codex:protocol-dynamic-tool-response
          ((codex:protocol-dynamic-tool-output-item-input-text "caption")
           (codex:protocol-dynamic-tool-output-item-input-image
             "https://example.test/pixel.png"))
          False))))
  ("{\"type\":\"dynamic_tool_response\",\"id\":\"call_dyn_2\",\"response\":{\"contentItems\":[{\"type\":\"inputText\",\"text\":\"caption\"},{\"type\":\"inputImage\",\"imageUrl\":\"https://example.test/pixel.png\"}],\"success\":false}}"))
