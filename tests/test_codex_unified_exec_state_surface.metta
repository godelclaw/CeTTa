!(register-module! ../codex)
!(import! &self codex:unified_exec_state)

!(assertEqual
  (codex:unified-exec-process-state-has-exited
    (codex:unified-exec-process-state-default))
  False)

!(assertEqual
  (codex:unified-exec-process-state-exit-code
    (codex:unified-exec-process-state-default))
  CodexAbsent)

!(assertEqual
  (codex:unified-exec-process-state-failure-message
    (codex:unified-exec-process-state-default))
  CodexAbsent)

!(assertEqual
  (let $state
    (codex:unified-exec-process-state
      False
      CodexAbsent
      "prior failure")
    (let $exited
      (codex:unified-exec-process-state-exited $state 17)
      (codex:unified-exec-process-state-has-exited $exited)))
  True)

!(assertEqual
  (let $state
    (codex:unified-exec-process-state
      False
      CodexAbsent
      "prior failure")
    (let $exited
      (codex:unified-exec-process-state-exited $state 17)
      (codex:unified-exec-process-state-exit-code $exited)))
  17)

!(assertEqual
  (let $state
    (codex:unified-exec-process-state
      False
      CodexAbsent
      "prior failure")
    (let $exited
      (codex:unified-exec-process-state-exited $state 17)
      (codex:unified-exec-process-state-failure-message $exited)))
  "prior failure")

!(assertEqual
  (let $state
    (codex:unified-exec-process-state False 4 CodexAbsent)
    (let $failed
      (codex:unified-exec-process-state-failed $state "remote watcher failed")
      (codex:unified-exec-process-state-has-exited $failed)))
  True)

!(assertEqual
  (let $state
    (codex:unified-exec-process-state False 4 CodexAbsent)
    (let $failed
      (codex:unified-exec-process-state-failed $state "remote watcher failed")
      (codex:unified-exec-process-state-exit-code $failed)))
  4)

!(assertEqual
  (let $state
    (codex:unified-exec-process-state False 4 CodexAbsent)
    (let $failed
      (codex:unified-exec-process-state-failed $state "remote watcher failed")
      (codex:unified-exec-process-state-failure-message $failed)))
  "remote watcher failed")

!(assertEqual
  (codex:unified-exec-error-kind
    (codex:unified-exec-error-create-process "no pty"))
  create_process)

!(assertEqual
  (codex:unified-exec-error-message
    (codex:unified-exec-error-create-process "no pty"))
  "no pty")

!(assertEqual
  (codex:unified-exec-error-display
    (codex:unified-exec-error-create-process "no pty"))
  "Failed to create unified exec process: no pty")

!(assertEqual
  (codex:unified-exec-error-kind
    (codex:unified-exec-error-process-failed "transport lost"))
  process_failed)

!(assertEqual
  (codex:unified-exec-error-message
    (codex:unified-exec-error-process-failed "transport lost"))
  "transport lost")

!(assertEqual
  (codex:unified-exec-error-display
    (codex:unified-exec-error-process-failed "transport lost"))
  "Unified exec process failed: transport lost")

!(assertEqual
  (codex:unified-exec-error-kind
    (codex:unified-exec-error-unknown-process-id 42))
  unknown_process_id)

!(assertEqual
  (codex:unified-exec-error-process-id
    (codex:unified-exec-error-unknown-process-id 42))
  42)

!(assertEqual
  (codex:unified-exec-error-display
    (codex:unified-exec-error-unknown-process-id 42))
  "Unknown process id 42")

!(assertEqual
  (codex:unified-exec-error-kind
    (codex:unified-exec-error-write-to-stdin))
  write_to_stdin)

!(assertEqual
  (codex:unified-exec-error-display
    (codex:unified-exec-error-write-to-stdin))
  "failed to write to stdin")

!(assertEqual
  (codex:unified-exec-error-kind
    (codex:unified-exec-error-stdin-closed))
  stdin_closed)

!(assertEqual
  (codex:unified-exec-error-display
    (codex:unified-exec-error-stdin-closed))
  "stdin is closed for this session; rerun exec_command with tty=true to keep stdin open")

!(assertEqual
  (codex:unified-exec-error-kind
    (codex:unified-exec-error-missing-command-line))
  missing_command_line)

!(assertEqual
  (codex:unified-exec-error-display
    (codex:unified-exec-error-missing-command-line))
  "missing command line for unified exec request")

!(assertEqual
  (codex:unified-exec-error-kind
    (codex:unified-exec-error-sandbox-denied "permission denied" sample-output))
  sandbox_denied)

!(assertEqual
  (codex:unified-exec-error-message
    (codex:unified-exec-error-sandbox-denied "permission denied" sample-output))
  "permission denied")

!(assertEqual
  (codex:unified-exec-error-output
    (codex:unified-exec-error-sandbox-denied "permission denied" sample-output))
  sample-output)

!(assertEqual
  (codex:unified-exec-error-display
    (codex:unified-exec-error-sandbox-denied "permission denied" sample-output))
  "Command denied by sandbox: permission denied")
