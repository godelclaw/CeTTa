!(register-module! ../codex)
!(import! &self codex:image_detail)
!(import! &self codex:protocol)
!(import! &self codex:tool_config)

(= (codex-image-detail-supported-model)
   (codex:tool-config-model-info
     (codex:config-shell-tool-type-unified-exec)
     CodexAbsent
     ()
     True))

(= (codex-image-detail-unsupported-model)
   (codex:tool-config-model-info
     (codex:config-shell-tool-type-unified-exec)
     CodexAbsent
     ()
     False))

!(assertEqualToResult
  (codex:can-request-original-image-detail
    (codex-image-detail-supported-model))
  (True))

!(assertEqualToResult
  (codex:normalize-output-image-detail
    (codex-image-detail-supported-model)
    "original")
  ("original"))

!(assertEqualToResult
  (codex:normalize-output-image-detail
    (codex-image-detail-supported-model)
    CodexAbsent)
  (CodexAbsent))

!(assertEqualToResult
  (codex:normalize-output-image-detail
    (codex-image-detail-unsupported-model)
    "original")
  (CodexAbsent))

!(assertEqualToResult
  (codex:normalize-output-image-detail
    (codex-image-detail-supported-model)
    "low")
  ("low"))

!(assertEqualToResult
  (codex:normalize-output-image-detail
    (codex-image-detail-supported-model)
    "high")
  ("high"))

!(assertEqualToResult
  (codex:sanitize-original-image-detail-items
    False
    ((codex:input-text "header")
     (codex:input-image "data:image/png;base64,AAA" "original")
     (codex:input-image "data:image/png;base64,BBB" "low")))
  (((codex:input-text "header")
    (CodexInputImage "data:image/png;base64,AAA" "high")
    (CodexInputImage "data:image/png;base64,BBB" "low"))))
