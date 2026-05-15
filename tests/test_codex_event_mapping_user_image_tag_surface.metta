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
          ((CodexInputText (codex:image-open-tag-text))
           (CodexInputImage
             "data:image/png;base64,def"
             (codex:default-image-detail))
           (CodexInputText (codex:image-close-tag-text))
           (CodexInputText "Please review this image too."))
          CodexAbsent))))
  (((CodexTurnUserInputImage "data:image/png;base64,def")
    (CodexTurnUserInputText "Please review this image too."))))
