!(register-module! ../codex)
!(import! &self codex:unified_exec_exec_command)

(= (exec-command-resources)
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

(= (exec-command-lifecycle)
   (codex:unified-exec-spawn-lifecycle () False))

(= (exec-command-process $has-exited $exit-code $sandbox)
   (CodexUnifiedExecManagedProcess
     (CodexUnifiedExecProcessHandleLocal
       local-session-1
       $has-exited
       $exit-code)
     (CodexUnifiedExecOutputHandles
       output-buffer-1
       output-notify-1
       False
       output-closed-notify-1
       cancellation-token-1)
     CodexAbsent
     output-drained-1
     (CodexUnifiedExecProcessState False CodexAbsent CodexAbsent)
     $sandbox
     (CodexUnifiedExecSpawnLifecycle () False)
     CodexAbsent
     False))

(= (exec-command-failed-process $message)
   (CodexUnifiedExecManagedProcess
     (CodexUnifiedExecProcessHandleLocal
       local-session-1
       True
       CodexAbsent)
     (CodexUnifiedExecOutputHandles
       output-buffer-1
       output-notify-1
       False
       output-closed-notify-1
       cancellation-token-1)
     CodexAbsent
     output-drained-1
     (CodexUnifiedExecProcessState True CodexAbsent $message)
     "None"
     (CodexUnifiedExecSpawnLifecycle () False)
     CodexAbsent
     False))

(= (exec-command-context)
   (codex:unified-exec-context-new
     session-1
     turn-1
     "call-exec"))

(= (exec-command-request $workdir $yield-time-ms)
   (codex:unified-exec-exec-command-request
     ("bash" "-lc" "printf hi")
     "printf hi"
     1001
     $yield-time-ms
     2000
     $workdir
     CodexAbsent
     False
     "use_default"
     CodexAbsent
     False
     CodexAbsent
     ("bash" "-lc")))

(= (exec-command-manager-reserved)
   (codex:unified-exec-process-manager
     (codex:unified-exec-process-store-reserve-process-id
       (codex:unified-exec-process-store-default)
       1001)
     12000))

(= (exec-command-open-ok $process)
   (CodexUnifiedExecOpenSessionWithSandboxResultOk
     $process
     (codex:unified-exec-deferred-network-approval "net-1")
     tool-request-1
     tool-ctx-1
     approval-request-1
     shell-mode-direct))

(= (exec-command-open-err $message)
   (CodexUnifiedExecOpenSessionWithSandboxResultErr
     (codex:unified-exec-error-create-process $message)
     tool-request-1
     tool-ctx-1
     approval-request-1
     shell-mode-direct))

(= (exec-command-transcript-empty)
   (codex:unified-exec-async-watcher-transcript 0 ""))

(= (exec-command-runtime
      $open-session-result
      $failure-message
      $refresh-result
      $sandbox-check-result)
   (codex:unified-exec-exec-command-runtime-inputs
     "/turn-cwd"
     "turn-1"
     10000
     125
     "hello"
     "abc123"
     pause-state-1
     (exec-command-transcript-empty)
     "hello"
     $open-session-result
     $failure-message
     $refresh-result
     $sandbox-check-result))

(= (exec-command-result
      $process
      $workdir
      $yield-time-ms
      $failure-message
      $refresh-result
      $sandbox-check-result)
   (codex:unified-exec-exec-command
     (exec-command-manager-reserved)
     (exec-command-request $workdir $yield-time-ms)
     (exec-command-context)
     (exec-command-runtime
       (exec-command-open-ok $process)
       $failure-message
       $refresh-result
       $sandbox-check-result)))

!(assertEqual
  (codex:unified-exec-exec-command-cwd
    (exec-command-request CodexAbsent 1000)
    (exec-command-runtime
      (exec-command-open-ok
        (exec-command-process False CodexAbsent "None"))
      CodexAbsent
      CodexAbsent
      (codex:unified-exec-process-check-ok)))
  "/turn-cwd")

!(assertEqual
  (codex:unified-exec-exec-command-cwd
    (exec-command-request "/explicit-cwd" 1000)
    (exec-command-runtime
      (exec-command-open-ok
        (exec-command-process False CodexAbsent "None"))
      CodexAbsent
      CodexAbsent
      (codex:unified-exec-process-check-ok)))
  "/explicit-cwd")

!(assertEqual
  (codex:unified-exec-exec-command-process-started-alive
    (exec-command-process False CodexAbsent "None"))
  True)

!(assertEqual
  (codex:unified-exec-exec-command-process-started-alive
    (exec-command-process True 0 "None"))
  False)

!(assertEqual
  (let $result
    (exec-command-result
      (exec-command-process False CodexAbsent "None")
      CodexAbsent
      50
      CodexAbsent
      (codex:unified-exec-refresh-process-state-result
        (codex:unified-exec-process-status-alive
          CodexAbsent
          "call-exec"
          1001)
        (codex:unified-exec-process-manager-process-store
          (exec-command-manager-reserved)))
      (codex:unified-exec-process-check-ok))
    (codex:unified-exec-exec-command-result-kind $result))
  ok)

!(assertEqual
  (let $result
    (exec-command-result
      (exec-command-process False CodexAbsent "None")
      CodexAbsent
      50
      CodexAbsent
      (codex:unified-exec-refresh-process-state-result
        (codex:unified-exec-process-status-alive
          CodexAbsent
          "call-exec"
          1001)
        (codex:unified-exec-process-manager-process-store
          (exec-command-manager-reserved)))
      (codex:unified-exec-process-check-ok))
    (let $lifecycle
      (codex:unified-exec-exec-command-result-lifecycle $result)
      (codex:unified-exec-exec-command-lifecycle-cwd
        $lifecycle)))
  "/turn-cwd")

!(assertEqual
  (let $result
    (exec-command-result
      (exec-command-process False CodexAbsent "None")
      CodexAbsent
      50
      CodexAbsent
      (codex:unified-exec-refresh-process-state-result
        (codex:unified-exec-process-status-alive
          CodexAbsent
          "call-exec"
          1001)
        (codex:unified-exec-process-manager-process-store
          (exec-command-manager-reserved)))
      (codex:unified-exec-process-check-ok))
    (let $lifecycle
      (codex:unified-exec-exec-command-result-lifecycle $result)
      (codex:unified-exec-exec-command-lifecycle-process-started-alive
        $lifecycle)))
  True)

!(assertEqual
  (let $result
    (exec-command-result
      (exec-command-process False CodexAbsent "None")
      CodexAbsent
      50
      CodexAbsent
      (codex:unified-exec-refresh-process-state-result
        (codex:unified-exec-process-status-alive
          CodexAbsent
          "call-exec"
          1001)
        (codex:unified-exec-process-manager-process-store
          (exec-command-manager-reserved)))
      (codex:unified-exec-process-check-ok))
    (let $lifecycle
      (codex:unified-exec-exec-command-result-lifecycle $result)
      (let $collection
        (codex:unified-exec-exec-command-lifecycle-collection-request
          $lifecycle)
        (codex:unified-exec-exec-command-collection-request-yield-time-ms
          $collection))))
  250)

!(assertEqual
  (let $result
    (exec-command-result
      (exec-command-process False CodexAbsent "None")
      CodexAbsent
      50
      CodexAbsent
      (codex:unified-exec-refresh-process-state-result
        (codex:unified-exec-process-status-alive
          CodexAbsent
          "call-exec"
          1001)
        (codex:unified-exec-process-manager-process-store
          (exec-command-manager-reserved)))
      (codex:unified-exec-process-check-ok))
    (let $lifecycle
      (codex:unified-exec-exec-command-result-lifecycle $result)
      (let $collection
        (codex:unified-exec-exec-command-lifecycle-collection-request
          $lifecycle)
        (codex:unified-exec-exec-command-collection-request-deadline-ms
          $collection))))
  10250)

!(assertEqual
  (let $result
    (exec-command-result
      (exec-command-process False CodexAbsent "None")
      CodexAbsent
      50
      CodexAbsent
      (codex:unified-exec-refresh-process-state-result
        (codex:unified-exec-process-status-alive
          CodexAbsent
          "call-exec"
          1001)
        (codex:unified-exec-process-manager-process-store
          (exec-command-manager-reserved)))
      (codex:unified-exec-process-check-ok))
    (let $lifecycle
      (codex:unified-exec-exec-command-result-lifecycle $result)
      (not (== (codex:unified-exec-exec-command-lifecycle-store-result
                 $lifecycle)
               CodexAbsent))))
  True)

!(assertEqual
  (let $result
    (exec-command-result
      (exec-command-process False CodexAbsent "None")
      CodexAbsent
      50
      CodexAbsent
      (codex:unified-exec-refresh-process-state-result
        (codex:unified-exec-process-status-alive
          CodexAbsent
          "call-exec"
          1001)
        (codex:unified-exec-process-manager-process-store
          (exec-command-manager-reserved)))
      (codex:unified-exec-process-check-ok))
    (let $output
      (codex:unified-exec-exec-command-result-output $result)
      (codex:unified-exec-exec-command-output-process-id $output)))
  1001)

!(assertEqual
  (let $result
    (exec-command-result
      (exec-command-process False CodexAbsent "None")
      CodexAbsent
      50
      CodexAbsent
      (codex:unified-exec-refresh-process-state-result
        (codex:unified-exec-process-status-alive
          CodexAbsent
          "call-exec"
          1001)
        (codex:unified-exec-process-manager-process-store
          (exec-command-manager-reserved)))
      (codex:unified-exec-process-check-ok))
    (let $output
      (codex:unified-exec-exec-command-result-output $result)
      (codex:unified-exec-exec-command-output-original-token-count $output)))
  2)

!(assertEqual
  (let $result
    (exec-command-result
      (exec-command-process False CodexAbsent "None")
      CodexAbsent
      50
      CodexAbsent
      (codex:unified-exec-refresh-process-state-result
        (codex:unified-exec-process-status-exited
          7
          exited-entry-1)
        (codex:unified-exec-process-store-default))
      (codex:unified-exec-process-check-ok))
    (let $output
      (codex:unified-exec-exec-command-result-output $result)
      (codex:unified-exec-exec-command-output-process-id $output)))
  CodexAbsent)

!(assertEqual
  (let $result
    (exec-command-result
      (exec-command-process False CodexAbsent "None")
      CodexAbsent
      50
      CodexAbsent
      (codex:unified-exec-refresh-process-state-result
        (codex:unified-exec-process-status-exited
          7
          exited-entry-1)
        (codex:unified-exec-process-store-default))
      (codex:unified-exec-process-check-ok))
    (let $output
      (codex:unified-exec-exec-command-result-output $result)
      (codex:unified-exec-exec-command-output-exit-code $output)))
  7)

!(assertEqual
  (let $result
    (exec-command-result
      (exec-command-process False CodexAbsent "None")
      CodexAbsent
      50
      CodexAbsent
      (codex:unified-exec-refresh-process-state-result
        (codex:unified-exec-process-status-unknown)
        (codex:unified-exec-process-store-default))
      (codex:unified-exec-process-check-ok))
    (codex:unified-exec-error-kind
      (codex:unified-exec-exec-command-result-error $result)))
  unknown_process_id)

!(assertEqual
  (let $result
    (exec-command-result
      (exec-command-process True 0 "None")
      "/explicit-cwd"
      1000
      CodexAbsent
      CodexAbsent
      (codex:unified-exec-process-check-ok))
    (let $lifecycle
      (codex:unified-exec-exec-command-result-lifecycle $result)
      (codex:unified-exec-exec-command-lifecycle-process-started-alive
        $lifecycle)))
  False)

!(assertEqual
  (let $result
    (exec-command-result
      (exec-command-process True 0 "None")
      "/explicit-cwd"
      1000
      CodexAbsent
      CodexAbsent
      (codex:unified-exec-process-check-ok))
    (let $lifecycle
      (codex:unified-exec-exec-command-result-lifecycle $result)
      (codex:unified-exec-exec-command-lifecycle-cwd
        $lifecycle)))
  "/explicit-cwd")

!(assertEqual
  (let $result
    (exec-command-result
      (exec-command-process True 0 "None")
      "/explicit-cwd"
      1000
      CodexAbsent
      CodexAbsent
      (codex:unified-exec-process-check-ok))
    (let $lifecycle
      (codex:unified-exec-exec-command-result-lifecycle $result)
      (not (== (codex:unified-exec-exec-command-lifecycle-end-event
                 $lifecycle)
               CodexAbsent))))
  True)

!(assertEqual
  (let $result
    (exec-command-result
      (exec-command-process True 0 "None")
      "/explicit-cwd"
      1000
      CodexAbsent
      CodexAbsent
      (codex:unified-exec-process-check-ok))
    (let $lifecycle
      (codex:unified-exec-exec-command-result-lifecycle $result)
      (not (== (codex:unified-exec-exec-command-lifecycle-finish-deferred-request
                 $lifecycle)
               CodexAbsent))))
  True)

!(assertEqual
  (let $result
    (exec-command-result
      (exec-command-failed-process "spawn failed")
      CodexAbsent
      1000
      "spawn failed"
      CodexAbsent
      (codex:unified-exec-process-check-ok))
    (codex:unified-exec-error-kind
      (codex:unified-exec-exec-command-result-error $result)))
  process_failed)

!(assertEqual
  (let $result
    (exec-command-result
      (exec-command-failed-process "spawn failed")
      CodexAbsent
      1000
      "spawn failed"
      CodexAbsent
      (codex:unified-exec-process-check-ok))
    (let $lifecycle
      (codex:unified-exec-exec-command-result-lifecycle $result)
      (not (== (codex:unified-exec-exec-command-lifecycle-end-event
                 $lifecycle)
               CodexAbsent))))
  True)

!(assertEqual
  (let $result
    (exec-command-result
      (exec-command-process True 159 "LinuxSeccomp")
      CodexAbsent
      1000
      CodexAbsent
      CodexAbsent
      (codex:unified-exec-process-check-err
        (codex:unified-exec-error-sandbox-denied
          "sandbox"
          sandbox-output-1)))
    (codex:unified-exec-error-kind
      (codex:unified-exec-exec-command-result-error $result)))
  sandbox_denied)

!(assertEqual
  (let $result
    (codex:unified-exec-exec-command
      (exec-command-manager-reserved)
      (exec-command-request CodexAbsent 1000)
      (exec-command-context)
      (exec-command-runtime
        (exec-command-open-err "open failed")
        CodexAbsent
        CodexAbsent
        (codex:unified-exec-process-check-ok)))
    (codex:unified-exec-error-kind
      (codex:unified-exec-exec-command-result-error $result)))
  create_process)

!(assertEqual
  (let $result
    (codex:unified-exec-exec-command
      (exec-command-manager-reserved)
      (exec-command-request CodexAbsent 1000)
      (exec-command-context)
      (exec-command-runtime
        (exec-command-open-err "open failed")
        CodexAbsent
        CodexAbsent
        (codex:unified-exec-process-check-ok)))
    (let $manager
      (codex:unified-exec-exec-command-result-manager $result)
      (codex:unified-exec-process-store-reserved-process-ids
        (codex:unified-exec-process-manager-process-store
          $manager))))
  ())
