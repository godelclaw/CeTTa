!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:op-type
    (codex:user-input-with-turn-context-op
      ((codex:user-input-text "Hello with context."))))
  ("user_input_with_turn_context"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:user-input-with-turn-context-op
        ((codex:user-input-text "Hello with context.")))))
  ("{\"type\":\"user_input_with_turn_context\",\"items\":[{\"type\":\"text\",\"text\":\"Hello with context.\",\"text_elements\":[]}]}"))

!(assertEqualToResult
  (json-stringify
    (codex:windows-sandbox-level-json
      (codex:windows-sandbox-level-restricted-token)))
  ("\"restricted-token\""))

!(assertEqualToResult
  (json-stringify
    (codex:reasoning-summary-json
      (codex:reasoning-summary-detailed)))
  ("\"detailed\""))

!(assertEqualToResult
  (json-stringify
    (codex:personality-json
      (codex:personality-pragmatic)))
  ("\"pragmatic\""))
