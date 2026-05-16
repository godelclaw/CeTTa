!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (json-stringify
    (codex:product-json
      (codex:product-from-session-source-name " chatgpt ")))
  ("\"chatgpt\""))

!(assertEqualToResult
  (json-stringify
    (codex:product-json
      (codex:product-from-session-source-name "ATLAS")))
  ("\"atlas\""))

!(assertEqualToResult
  (codex:product-from-session-source-name "atlas-dev")
  (CodexAbsent))
