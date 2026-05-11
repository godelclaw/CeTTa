!(register-module! ../codex)
!(import! &self codex:protocol)
!(import! &self codex:tools)

!(assertEqual
  (let $run
    (codex:run-exec-command
      "call_live"
      "{\"cmd\":\"sleep 0.4; printf hello\",\"login\":false,\"yield_time_ms\":250}")
    (if (codex:is-exec-command-run-running $run)
        (and
          (> (codex:exec-command-run-session-id $run) 0)
          (codex:is-string-contains
            (codex:exec-command-run-text $run)
            "Process running with session ID"))
        False))
  True)

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
