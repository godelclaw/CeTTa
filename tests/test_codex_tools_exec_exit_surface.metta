!(register-module! ../codex)
!(import! &self codex:tools)

!(assertEqualToResult
  (codex:exec-command-run-exit-code
    (once
      (codex:run-exec-command
        "call_exec_exit"
        "{\"cmd\":\"printf hello\",\"login\":false,\"yield_time_ms\":1000}")))
  (0))
