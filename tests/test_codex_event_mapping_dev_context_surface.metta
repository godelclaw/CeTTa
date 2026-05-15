!(register-module! ../codex)
!(import! &self codex:event_mapping)

!(assertEqualToResult
  (codex:is-contextual-dev-message-content
    ((CodexInputText "<permissions instructions>body</permissions instructions>")
     (CodexInputText "plain")))
  (True))

!(assertEqualToResult
  (codex:has-non-contextual-dev-message-content
    ((CodexInputText "<model_switch>\nbody\n</model_switch>")
     (CodexInputText "plain")))
  (True))

!(assertEqualToResult
  (codex:has-non-contextual-dev-message-content
    ((CodexInputText "<realtime_conversation>\nbody\n</realtime_conversation>")
     (CodexInputText "<personality_spec> body </personality_spec>")))
  (False))
