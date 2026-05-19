!(register-module! ../codex)
!(import! &self codex:stream_events_utils)

(= (test:mcp-image-response-input)
   (codex:response-input-mcp-tool-call-output
     "call-mcp-image"
     (JsonObject
       ((JsonPair "content"
          (JsonArray
            ((JsonObject
               ((JsonPair "type" (JsonString "text"))
                (JsonPair "text" (JsonString "caption"))))
             (JsonObject
               ((JsonPair "type" (JsonString "image"))
                (JsonPair "data" (JsonString "AAA"))
                (JsonPair "mimeType" (JsonString "image/png"))
                (JsonPair "_meta"
                  (JsonObject
                    ((JsonPair
                       "codex/imageDetail"
                       (JsonString "low"))))))))))))))

!(assertEqual
  (codex:response-input-to-response-item
    (test:mcp-image-response-input))
  (CodexResponseItemFunctionCallOutput
    "call-mcp-image"
    (CodexFunctionCallOutputContentItems
      ((CodexInputText "caption")
       (CodexInputImage "data:image/png;base64,AAA" "low")))))

!(assertEqual
  (json-stringify
    (codex:item-json
      (codex:response-input-to-response-item
        (test:mcp-image-response-input))))
  "{\"type\":\"function_call_output\",\"call_id\":\"call-mcp-image\",\"output\":[{\"type\":\"input_text\",\"text\":\"caption\"},{\"type\":\"input_image\",\"image_url\":\"data:image/png;base64,AAA\",\"detail\":\"low\"}]}")
