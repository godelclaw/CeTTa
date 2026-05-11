!(register-module! ../codex)
!(import! &self codex:tools)

!(assertEqualToResult
  (codex:exec-command-run-stdout
    (once
      (codex:run-exec-command
        "call_exec_stdout"
        "{\"cmd\":\"printf hello\",\"login\":false,\"yield_time_ms\":1000}")))
  ("hello"))
