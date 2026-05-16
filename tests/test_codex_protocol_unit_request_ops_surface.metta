!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:op-type
    (codex:compact-op))
  ("compact"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:compact-op)))
  ("{\"type\":\"compact\"}"))

!(assertEqualToResult
  (codex:op-type
    (codex:drop-memories-op))
  ("drop_memories"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:drop-memories-op)))
  ("{\"type\":\"drop_memories\"}"))

!(assertEqualToResult
  (codex:op-type
    (codex:update-memories-op))
  ("update_memories"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:update-memories-op)))
  ("{\"type\":\"update_memories\"}"))
