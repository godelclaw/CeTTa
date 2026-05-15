!(register-module! ../codex)
!(import! &self codex:event_mapping)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:turn-user-message-item-content
    (codex:turn-item-user-message-value
      (codex:parse-turn-item
        (codex:response-message
          CodexAbsent
          "user"
          ((CodexInputText "Hello world")
           (CodexInputImage
             "https://example.com/one.png"
             (codex:default-image-detail))
           (CodexInputImage
             "https://example.com/two.jpg"
             (codex:default-image-detail)))
          CodexAbsent))))
  (((CodexTurnUserInputText "Hello world")
    (CodexTurnUserInputImage "https://example.com/one.png")
    (CodexTurnUserInputImage "https://example.com/two.jpg"))))
