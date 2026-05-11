!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)
!(import! &self codex:tools)

!(println! "=== Codex tools demo ===")

!(println!
  (once
    (codex:is-exec-command-run-running
      (codex:run-exec-command
        "call_demo"
        "{\"cmd\":\"printf codex-tools-demo\",\"login\":false,\"yield_time_ms\":1000}"))))

!(println!
  (once
    (codex:run-write-stdin-output-text
      "call_write_demo"
      "{\"session_id\":99999,\"chars\":\"x\",\"yield_time_ms\":250}")))

!(println!
  (once
    (codex:exec-command-run-text
      (codex:run-exec-command
        "call_demo_text"
        "{\"cmd\":\"printf codex-tools-demo\",\"login\":false,\"yield_time_ms\":1000}"))))
