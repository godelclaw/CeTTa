!(register-module! ../codex)
!(import! &self codex:protocol)
!(import! &self codex:tools)

!(assertEqual
  (once
    (codex:run-write-stdin-output-text
      "call_write"
      "{\"session_id\":99999,\"chars\":\"x\",\"yield_time_ms\":250}"))
  "write_stdin failed: Unknown process id 99999")

!(assertEqual
  (once
    (codex:tool-result-output-text
      (once
        (codex:run-write-stdin-tool-call
          "call_write"
          "{\"session_id\":99999,\"chars\":\"x\",\"yield_time_ms\":250}"))))
  "write_stdin failed: Unknown process id 99999")
