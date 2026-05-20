!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:code_mode_response_adapter)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:code-mode-response-adapter-image-detail-into-protocol "auto")
  ("auto"))

!(assertEqualToResult
  (codex:code-mode-response-adapter-image-detail-into-protocol "low")
  ("low"))

!(assertEqualToResult
  (codex:code-mode-response-adapter-image-detail-into-protocol "high")
  ("high"))

!(assertEqualToResult
  (codex:code-mode-response-adapter-image-detail-into-protocol "original")
  ("original"))

!(assertEqualToResult
  (codex:code-mode-response-adapter-content-item-into-protocol
    (codex:code-mode-input-text "hello"))
  ((CodexInputText "hello")))

!(assertEqualToResult
  (codex:code-mode-response-adapter-content-item-into-protocol
    (codex:code-mode-input-image "data:image/png;base64,AAA"))
  ((CodexInputImage "data:image/png;base64,AAA" "high")))

!(assertEqualToResult
  (codex:code-mode-response-adapter-content-item-into-protocol
    (codex:code-mode-input-image "data:image/png;base64,BBB" "original"))
  ((CodexInputImage "data:image/png;base64,BBB" "original")))

!(assertEqualToResult
  (json-stringify
    (codex:output-json
      (codex:function-call-output-content-items
        (codex:into-function-call-output-content-items
          ((codex:code-mode-input-text "line 1")
           (codex:code-mode-input-image "data:image/png;base64,AAA")
           (codex:code-mode-input-image "data:image/png;base64,BBB" "low")
           (codex:code-mode-input-text "line 2"))))))
  ("[{\"type\":\"input_text\",\"text\":\"line 1\"},{\"type\":\"input_image\",\"image_url\":\"data:image/png;base64,AAA\",\"detail\":\"high\"},{\"type\":\"input_image\",\"image_url\":\"data:image/png;base64,BBB\",\"detail\":\"low\"},{\"type\":\"input_text\",\"text\":\"line 2\"}]"))
