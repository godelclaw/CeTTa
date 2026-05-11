!(register-module! ../codex)
!(import! &self codex:tools)

!(assertEqual
  (once
    (case
      (codex:run-exec-command
        "call_exec_exit"
        "{\"cmd\":\"printf hello\",\"login\":false,\"yield_time_ms\":1000}")
      (((CodexExecCommandRun
          $call-id
          $chunk-id
          $hook-command
          $max-output-tokens
          $is-running
          $session-id
          $has-exit-code
          $exit-code
          $stdout
          $stderr
          $aggregated-output
          $duration-ms
          $original-token-count
          $text)
        ($has-exit-code $exit-code)))))
  (True 0))
