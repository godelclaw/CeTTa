!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:op-type
    (codex:set-thread-name-op "Session Notes"))
  ("set_thread_name"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:set-thread-name-op "Session Notes")))
  ("{\"type\":\"set_thread_name\",\"name\":\"Session Notes\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:thread-memory-mode-json
      (codex:thread-memory-mode-enabled)))
  ("\"enabled\""))

!(assertEqualToResult
  (json-stringify
    (codex:thread-memory-mode-json
      (codex:thread-memory-mode-disabled)))
  ("\"disabled\""))

!(assertEqualToResult
  (codex:op-type
    (codex:set-thread-memory-mode-op
      (codex:thread-memory-mode-disabled)))
  ("set_thread_memory_mode"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:set-thread-memory-mode-op
        (codex:thread-memory-mode-disabled))))
  ("{\"type\":\"set_thread_memory_mode\",\"mode\":\"disabled\"}"))

!(assertEqualToResult
  (codex:op-type
    (codex:undo-op))
  ("undo"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:undo-op)))
  ("{\"type\":\"undo\"}"))

!(assertEqualToResult
  (codex:op-type
    (codex:thread-rollback-op 3))
  ("thread_rollback"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:thread-rollback-op 3)))
  ("{\"type\":\"thread_rollback\",\"num_turns\":3}"))
