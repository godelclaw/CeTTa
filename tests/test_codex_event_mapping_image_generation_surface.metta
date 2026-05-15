!(register-module! ../codex)
!(import! &self codex:event_mapping)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:turn-image-generation-item-result
    (codex:turn-item-image-generation-value
      (codex:parse-turn-item
        (codex:image-generation-call-response-item
          "ig_123"
          "completed"
          "A small blue square"
          "Zm9v"))))
  ("Zm9v"))

!(assertEqualToResult
  (codex:turn-image-generation-item-revised-prompt
    (codex:turn-item-image-generation-value
      (codex:parse-turn-item
        (codex:image-generation-call-response-item
          "ig_123"
          "completed"
          CodexAbsent
          "Zm9v"))))
  (Empty))
