!(register-module! ../codex)
!(import! &self codex:protocol)
!(import! &self codex:tools)

!(assertEqualToResult
  (codex:duration-ms-to-seconds-text 1250)
  ("1.2500"))

!(assertEqualToResult
  (codex:exec-command-run-exit-code
    (codex:run-exec-command
      "call_1"
      "{\"cmd\":\"printf hello\",\"login\":false,\"yield_time_ms\":1000}"))
  (0))

!(assertEqualToResult
  (codex:exec-command-run-stdout
    (codex:run-exec-command
      "call_1"
      "{\"cmd\":\"printf hello\",\"login\":false,\"yield_time_ms\":1000}"))
  ("hello"))

!(assertEqualToResult
  (codex:is-string-contains
    (codex:exec-command-run-text
      (codex:run-exec-command
        "call_1"
        "{\"cmd\":\"printf hello\",\"login\":false,\"yield_time_ms\":1000}"))
    "Process exited with code 0")
  (True))

!(assertEqualToResult
  (codex:is-string-contains
    (codex:tool-result-output-text
      (codex:run-tool-call-item
        (codex:tool-call
          "call_1"
          "exec_command"
          "{\"cmd\":\"printf hello\",\"login\":false,\"yield_time_ms\":1000}")))
    "Output:\nhello")
  (True))
