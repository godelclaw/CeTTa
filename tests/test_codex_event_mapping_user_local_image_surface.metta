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
          ((CodexInputText (codex:local-image-open-tag-text 1))
           (CodexInputImage
             "data:image/png;base64,abc"
             (codex:default-image-detail))
           (CodexInputText (codex:image-close-tag-text))
           (CodexInputText "Please review this image."))
          CodexAbsent))))
  (((CodexTurnUserInputImage "data:image/png;base64,abc")
    (CodexTurnUserInputText "Please review this image."))))
