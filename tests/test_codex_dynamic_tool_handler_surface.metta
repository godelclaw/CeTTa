!(register-module! ../codex)
!(import! &self codex:dynamic_tool_handler)

(= (test:dynamic-tool-start)
   (codex:dynamic-tool-handler-start-plan
     "turn-1"
     "call-dyn-1"
     (codex:namespaced-tool-name "browser" "screenshot")
     (CodexToolPayloadFunction "{\"url\":\"https://example.com\"}")))

!(assertEqualToResult
  (codex:dynamic-tool-handler-kind)
  ("function"))

!(assertEqualToResult
  (codex:dynamic-tool-handler-start-plan-error-value
    (codex:dynamic-tool-handler-start-plan
      "turn-1"
      "call-dyn-custom"
      (codex:plain-tool-name "lookup")
      (CodexToolPayloadCustom "raw")))
  ((CodexFunctionCallErrorRespondToModel
     "dynamic tool handler received unsupported payload")))

!(assertEqualToResult
  (codex:dynamic-tool-handler-start-plan-error-value
    (codex:dynamic-tool-handler-start-plan
      "turn-1"
      "call-bad-json"
      (codex:plain-tool-name "lookup")
      (CodexToolPayloadFunction "{bad")))
  ((CodexFunctionCallErrorRespondToModel
     "failed to parse function arguments: expected JSON string")))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:dynamic-tool-handler-start-plan-event
        (test:dynamic-tool-start))))
  ("{\"type\":\"dynamic_tool_call_request\",\"call_id\":\"call-dyn-1\",\"turn_id\":\"turn-1\",\"namespace\":\"browser\",\"tool\":\"screenshot\",\"arguments\":{\"url\":\"https://example.com\"}}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:dynamic-tool-handler-complete-plan-event
        (codex:dynamic-tool-handler-complete-plan
          (test:dynamic-tool-start)
          (codex:protocol-dynamic-tool-response
            ((codex:protocol-dynamic-tool-output-item-input-text "caption")
             (codex:protocol-dynamic-tool-output-item-input-image "data:image/png;base64,AAA"))
            True)
          (codex:duration 1 5000000)))))
  ("{\"type\":\"dynamic_tool_call_response\",\"call_id\":\"call-dyn-1\",\"turn_id\":\"turn-1\",\"namespace\":\"browser\",\"tool\":\"screenshot\",\"arguments\":{\"url\":\"https://example.com\"},\"content_items\":[{\"type\":\"inputText\",\"text\":\"caption\"},{\"type\":\"inputImage\",\"imageUrl\":\"data:image/png;base64,AAA\"}],\"success\":true,\"error\":null,\"duration\":{\"secs\":1,\"nanos\":5000000}}"))

!(assertEqualToResult
  (codex:dynamic-tool-handler-complete-plan-output
    (codex:dynamic-tool-handler-complete-plan
      (test:dynamic-tool-start)
      (codex:protocol-dynamic-tool-response
        ((codex:protocol-dynamic-tool-output-item-input-text "caption")
         (codex:protocol-dynamic-tool-output-item-input-image "data:image/png;base64,AAA"))
        True)
      (codex:duration 1 5000000)))
  ((CodexToolOutputFunction
     ((CodexInputText "caption")
      (CodexInputImage "data:image/png;base64,AAA" "high"))
     True
     CodexAbsent)))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:dynamic-tool-handler-complete-plan-event
        (codex:dynamic-tool-handler-complete-plan
          (test:dynamic-tool-start)
          CodexAbsent
          (codex:duration 0 7000000)))))
  ("{\"type\":\"dynamic_tool_call_response\",\"call_id\":\"call-dyn-1\",\"turn_id\":\"turn-1\",\"namespace\":\"browser\",\"tool\":\"screenshot\",\"arguments\":{\"url\":\"https://example.com\"},\"content_items\":[],\"success\":false,\"error\":\"dynamic tool call was cancelled before receiving a response\",\"duration\":{\"secs\":0,\"nanos\":7000000}}"))

!(assertEqualToResult
  (codex:dynamic-tool-handler-complete-plan-error-value
    (codex:dynamic-tool-handler-complete-plan
      (test:dynamic-tool-start)
      CodexAbsent
      (codex:duration 0 7000000)))
  ((CodexFunctionCallErrorRespondToModel
     "dynamic tool call was cancelled before receiving a response")))
