!(register-module! ../codex)
!(import! &self codex:unified_exec_process_runtime)

(= (process-runtime-resources)
   (codex:unified-exec-process-runtime-resources
     output-buffer-1
     output-notify-1
     False
     output-closed-notify-1
     cancellation-token-1
     output-drained-1
     output-tx-1
     state-tx-1
     state-rx-1))

(= (process-runtime-lifecycle)
   (codex:unified-exec-spawn-lifecycle () False))

(= (spawned-pty
      $poll
      $grace
      $snapshot)
   (codex:unified-exec-spawned-pty
     local-session-1
     stdout-rx-1
     stderr-rx-1
     exit-rx-1
     $poll
     $grace
     $snapshot))

(= (from-spawned
      $sandbox
      $poll
      $grace
      $snapshot)
   (codex:unified-exec-process-from-spawned
     (spawned-pty $poll $grace $snapshot)
     $sandbox
     (process-runtime-lifecycle)
     (process-runtime-resources)
     (codex:host-platform-linux)))

!(assertEqual
  (codex:unified-exec-early-exit-grace-period-ms)
  150)

!(assertEqual
  (codex:unified-exec-sandbox-denial-notify-wait-ms)
  20)

!(assertEqual
  (codex:unified-exec-process-handle-kind
    (codex:unified-exec-process-handle-local
      local-session
      False
      CodexAbsent))
  local)

!(assertEqual
  (codex:unified-exec-process-handle-kind
    (codex:unified-exec-process-handle-exec-server
      remote-process))
  exec_server)

!(assertEqual
  (codex:unified-exec-process-has-exited
    (codex:unified-exec-process-new
      (codex:unified-exec-process-handle-local
        local-session
        True
        23)
      (codex:sandbox-type-none)
      (process-runtime-lifecycle)
      (process-runtime-resources)))
  True)

!(assertEqual
  (codex:unified-exec-process-exit-code
    (codex:unified-exec-process-new
      (codex:unified-exec-process-handle-local
        local-session
        True
        23)
      (codex:sandbox-type-none)
      (process-runtime-lifecycle)
      (process-runtime-resources)))
  23)

!(assertEqual
  (let $process
    (codex:unified-exec-process-new
      (codex:unified-exec-process-handle-exec-server
        remote-process)
      (codex:sandbox-type-none)
      CodexAbsent
      (process-runtime-resources))
    (codex:unified-exec-managed-process-output-drained
      $process))
  output-drained-1)

!(assertEqual
  (let $result
    (from-spawned
      (codex:sandbox-type-none)
      (codex:unified-exec-local-exit-poll-ok 7)
      (codex:unified-exec-local-exit-grace-timeout)
      "done")
    (codex:unified-exec-process-constructor-result-kind
      $result))
  ok)

!(assertEqual
  (let $result
    (from-spawned
      (codex:sandbox-type-none)
      (codex:unified-exec-local-exit-poll-ok 7)
      (codex:unified-exec-local-exit-grace-timeout)
      "done")
    (let $process
      (codex:unified-exec-process-constructor-result-process
        $result)
      (codex:unified-exec-process-exit-code $process)))
  7)

!(assertEqual
  (let $result
    (from-spawned
      (codex:sandbox-type-none)
      (codex:unified-exec-local-exit-poll-ok 7)
      (codex:unified-exec-local-exit-grace-timeout)
      "done")
    (let $process
      (codex:unified-exec-process-constructor-result-process
        $result)
      (codex:unified-exec-managed-process-cancellation-cancelled
        $process)))
  True)

!(assertEqual
  (let $result
    (from-spawned
      (codex:sandbox-type-none)
      (codex:unified-exec-local-exit-poll-closed)
      (codex:unified-exec-local-exit-grace-timeout)
      "closed")
    (let $process
      (codex:unified-exec-process-constructor-result-process
        $result)
      (codex:unified-exec-process-exit-code $process)))
  CodexAbsent)

!(assertEqual
  (let $result
    (from-spawned
      (codex:sandbox-type-none)
      (codex:unified-exec-local-exit-poll-empty)
      (codex:unified-exec-local-exit-grace-ok 2)
      "grace")
    (let $process
      (codex:unified-exec-process-constructor-result-process
        $result)
      (codex:unified-exec-process-exit-code $process)))
  2)

!(assertEqual
  (let $result
    (from-spawned
      (codex:sandbox-type-none)
      (codex:unified-exec-local-exit-poll-empty)
      (codex:unified-exec-local-exit-grace-timeout)
      "running")
    (let $process
      (codex:unified-exec-process-constructor-result-process
        $result)
      (codex:unified-exec-local-exit-watcher-request-kind
        (codex:unified-exec-managed-process-exit-watcher
          $process))))
  local_exit_watcher)

!(assertEqual
  (let $result
    (from-spawned
      (codex:sandbox-type-none)
      (codex:unified-exec-local-exit-poll-empty)
      (codex:unified-exec-local-exit-grace-timeout)
      "running")
    (let $process
      (codex:unified-exec-process-constructor-result-process
        $result)
      (codex:unified-exec-process-has-exited $process)))
  False)

!(assertEqual
  (let $result
    (from-spawned
      (codex:sandbox-type-none)
      (codex:unified-exec-local-exit-poll-empty)
      (codex:unified-exec-local-exit-grace-timeout)
      "running")
    (let $process
      (codex:unified-exec-process-constructor-result-process
        $result)
      (codex:unified-exec-local-output-task-request-kind
        (codex:unified-exec-managed-process-output-task
          $process))))
  local_output_task)

!(assertEqual
  (codex:unified-exec-process-is-likely-sandbox-denied
    (codex:sandbox-type-none)
    (codex:unified-exec-process-exec-tool-call-output
      1
      ""
      "permission denied"
      "permission denied"
      CodexAbsent
      False)
    (codex:host-platform-linux))
  False)

!(assertEqual
  (codex:unified-exec-process-is-likely-sandbox-denied
    (codex:sandbox-type-linux-seccomp)
    (codex:unified-exec-process-exec-tool-call-output
      126
      ""
      "PERMISSION DENIED"
      "PERMISSION DENIED"
      CodexAbsent
      False)
    (codex:host-platform-linux))
  True)

!(assertEqual
  (codex:unified-exec-process-is-likely-sandbox-denied
    (codex:sandbox-type-linux-seccomp)
    (codex:unified-exec-process-exec-tool-call-output
      127
      ""
      "command not found"
      "command not found"
      CodexAbsent
      False)
    (codex:host-platform-linux))
  False)

!(assertEqual
  (codex:unified-exec-process-is-likely-sandbox-denied
    (codex:sandbox-type-linux-seccomp)
    (codex:unified-exec-process-exec-tool-call-output
      159
      ""
      ""
      ""
      CodexAbsent
      False)
    (codex:host-platform-linux))
  True)

!(assertEqual
  (let $result
    (from-spawned
      (codex:sandbox-type-linux-seccomp)
      (codex:unified-exec-local-exit-poll-ok 1)
      (codex:unified-exec-local-exit-grace-timeout)
      "PERMISSION DENIED")
    (codex:unified-exec-process-constructor-result-kind
      $result))
  err)

!(assertEqual
  (let $result
    (from-spawned
      (codex:sandbox-type-linux-seccomp)
      (codex:unified-exec-local-exit-poll-ok 1)
      (codex:unified-exec-local-exit-grace-timeout)
      "PERMISSION DENIED")
    (codex:unified-exec-error-kind
      (codex:unified-exec-process-constructor-result-error
        $result)))
  sandbox_denied)

!(assertEqual
  (let $result
    (from-spawned
      (codex:sandbox-type-linux-seccomp)
      (codex:unified-exec-local-exit-poll-ok 1)
      (codex:unified-exec-local-exit-grace-timeout)
      "PERMISSION DENIED")
    (codex:unified-exec-error-message
      (codex:unified-exec-process-constructor-result-error
        $result)))
  "PERMISSION DENIED")

!(assertEqual
  (codex:unified-exec-process-sandbox-denial-message "" 9)
  "Process exited with code 9")

!(assertEqual
  (codex:unified-exec-process-formatted-truncate-text
    "abcdef"
    1)
  "Total output lines: 1\n\nab…1 tokens truncated…ef")

!(assertEqual
  (let $started
    (codex:unified-exec-started-exec-process
      remote-process
      (codex:unified-exec-exec-server-grace-timeout)
      "permission denied")
    (let $result
      (codex:unified-exec-process-from-exec-server-started
        $started
        (codex:sandbox-type-linux-seccomp)
        (process-runtime-resources)
        (codex:host-platform-linux))
      (codex:unified-exec-process-constructor-result-kind
        $result)))
  ok)

!(assertEqual
  (let $started
    (codex:unified-exec-started-exec-process
      remote-process
      (codex:unified-exec-exec-server-grace-state
        (codex:unified-exec-process-state-exited
          (codex:unified-exec-process-state-default)
          3))
      "ordinary failure")
    (let $result
      (codex:unified-exec-process-from-exec-server-started
        $started
        (codex:sandbox-type-linux-seccomp)
        (process-runtime-resources)
        (codex:host-platform-linux))
      (let $process
        (codex:unified-exec-process-constructor-result-process
          $result)
        (codex:unified-exec-process-exit-code
          $process))))
  3)

!(assertEqual
  (let $started
    (codex:unified-exec-started-exec-process
      remote-process
      (codex:unified-exec-exec-server-grace-state
        (codex:unified-exec-process-state-failed
          (codex:unified-exec-process-state-default)
          "remote read failed"))
      "sandbox blocked")
    (let $result
      (codex:unified-exec-process-from-exec-server-started
        $started
        (codex:sandbox-type-linux-seccomp)
        (process-runtime-resources)
        (codex:host-platform-linux))
      (codex:unified-exec-error-kind
        (codex:unified-exec-process-constructor-result-error
          $result))))
  sandbox_denied)

!(assertEqual
  (let $started
    (codex:unified-exec-started-exec-process
      remote-process
      (codex:unified-exec-exec-server-grace-channel-closed)
      "permission denied")
    (let $result
      (codex:unified-exec-process-from-exec-server-started
        $started
        (codex:sandbox-type-linux-seccomp)
        (process-runtime-resources)
        (codex:host-platform-linux))
      (codex:unified-exec-process-constructor-result-kind
        $result)))
  ok)

!(assertEqual
  (let $started
    (codex:unified-exec-started-exec-process
      remote-process
      (codex:unified-exec-exec-server-grace-timeout)
      "still running")
    (let $result
      (codex:unified-exec-process-from-exec-server-started
        $started
        (codex:sandbox-type-none)
        (process-runtime-resources)
        (codex:host-platform-linux))
      (let $process
        (codex:unified-exec-process-constructor-result-process
          $result)
        (codex:unified-exec-exec-server-output-task-request-kind
          (codex:unified-exec-managed-process-output-task
            $process)))))
  exec_server_output_task)
