!(register-module! ../codex)
!(import! &self codex:protocol)
!(import! &self codex:tools)

!(assertEqual
  (codex:is-string-contains
    (codex:run-exec-command-then-write-stdin-output-text
      "call_live"
      "{\"cmd\":\"sleep 0.4; printf hello\",\"login\":false,\"yield_time_ms\":250}"
      "call_live_poll"
      ""
      100)
    "hello")
  True)

!(assertEqualToResult
  (codex:is-write-stdin-result-success
    (codex:run-exec-command-then-write-stdin-result
      "exec_call_original"
      "{\"cmd\":\"sleep 0.4; printf hello\",\"login\":false,\"yield_time_ms\":250}"
      "write_call_followup"
      ""
      100))
  (True))

!(assertEqualToResult
  (codex:exec-command-run-event-call-id
    (codex:write-stdin-result-run
      (codex:run-exec-command-then-write-stdin-result
        "exec_call_original"
        "{\"cmd\":\"sleep 0.4; printf hello\",\"login\":false,\"yield_time_ms\":250}"
        "write_call_followup"
        ""
        100)))
  ("exec_call_original"))

!(assertEqualToResult
  (codex:exec-command-run-hook-command
    (codex:write-stdin-result-run
      (codex:run-exec-command-then-write-stdin-result
        "exec_call_original"
        "{\"cmd\":\"sleep 0.4; printf hello\",\"login\":false,\"yield_time_ms\":250}"
        "write_call_followup"
        ""
        100)))
  ("sleep 0.4; printf hello"))

!(assertEqualToResult
  (codex:tool-result-call-id
    (codex:exec-command-run-output-item
      "write_call_followup"
      (codex:write-stdin-result-run
        (codex:run-exec-command-then-write-stdin-result
          "exec_call_original"
          "{\"cmd\":\"sleep 0.4; printf hello\",\"login\":false,\"yield_time_ms\":250}"
          "write_call_followup"
          ""
          100))))
  ("write_call_followup"))

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
