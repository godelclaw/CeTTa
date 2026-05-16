!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:op-type
    (codex:interrupt-op))
  ("interrupt"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:interrupt-op)))
  ("{\"type\":\"interrupt\"}"))

!(assertEqualToResult
  (codex:op-type
    (codex:clean-background-terminals-op))
  ("clean_background_terminals"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:clean-background-terminals-op)))
  ("{\"type\":\"clean_background_terminals\"}"))
