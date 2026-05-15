!(register-module! ../codex)
!(import! &self codex:event_mapping)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:turn-reasoning-item-summary-text
    (codex:turn-item-reasoning-value
      (codex:parse-turn-item
        (codex:reasoning-response-item
          "reasoning_2"
          ((codex:reasoning-summary-text "Summarized step"))
          ((codex:reasoning-content-reasoning-text "raw step")
           (codex:reasoning-content-text "final thought"))))))
  (("Summarized step")))

!(assertEqualToResult
  (codex:turn-reasoning-item-raw-content
    (codex:turn-item-reasoning-value
      (codex:parse-turn-item
        (codex:reasoning-response-item
          "reasoning_2"
          ((codex:reasoning-summary-text "Summarized step"))
          ((codex:reasoning-content-reasoning-text "raw step")
           (codex:reasoning-content-text "final thought"))))))
  (("raw step" "final thought")))
