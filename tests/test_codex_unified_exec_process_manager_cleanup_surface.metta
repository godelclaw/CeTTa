!(register-module! ../codex)
!(import! &self codex:unified_exec_process_manager_state)
!(import! &self codex:unified_exec_process_manager_cleanup)

(= (pm-cleanup-process-state $has-exited $exit-code)
   (CodexUnifiedExecProcessState $has-exited $exit-code CodexAbsent))

(= (pm-cleanup-entry
      $process-id
      $network-approval-id
      $session
      $has-exited
      $exit-code)
   (codex:unified-exec-process-entry
     (pm-cleanup-process-state $has-exited $exit-code)
     (format-args "call-{}" ($process-id))
     $process-id
     "bash"
     False
     $network-approval-id
     $session
     10))

(= (pm-cleanup-store-with-entry $entry)
   (codex:unified-exec-process-store-put-entry
     (codex:unified-exec-process-store-reserve-process-id
       (codex:unified-exec-process-store-default)
       (codex:unified-exec-process-entry-process-id $entry))
     $entry))

!(assertEqual
  (codex:unified-exec-process-cleanup-action-kind
    (codex:unified-exec-process-cleanup-unregister-network-approval
      session-1
      "approval-1"))
  unregister-network-approval)

!(assertEqual
  (codex:unified-exec-process-cleanup-action-network-approval-id
    (codex:unified-exec-process-cleanup-unregister-network-approval
      session-1
      "approval-1"))
  "approval-1")

!(assertEqual
  (codex:unified-exec-process-cleanup-action-kind
    (codex:unified-exec-process-cleanup-terminate-process process-1))
  terminate-process)

!(assertEqual
  (let $actions
    (codex:unified-exec-process-entry-network-approval-cleanup-actions
      (pm-cleanup-entry 10 "approval-10" session-1 False CodexAbsent))
    (list:len $actions))
  1)

!(assertEqual
  (let $actions
    (codex:unified-exec-process-entry-network-approval-cleanup-actions
      (pm-cleanup-entry 10 "approval-10" session-1 False CodexAbsent))
    (codex:unified-exec-process-cleanup-action-session
      (list:first $actions)))
  session-1)

!(assertEqual
  (codex:unified-exec-process-entry-network-approval-cleanup-actions
    (pm-cleanup-entry 11 CodexAbsent session-1 False CodexAbsent))
  ())

!(assertEqual
  (codex:unified-exec-process-entry-network-approval-cleanup-actions
    (pm-cleanup-entry 12 "approval-12" CodexAbsent False CodexAbsent))
  ())

!(assertEqual
  (let $release
    (codex:unified-exec-process-store-release
      (pm-cleanup-store-with-entry
        (pm-cleanup-entry 20 "approval-20" session-1 False CodexAbsent))
      20)
    (codex:unified-exec-process-cleanup-action-network-approval-id
      (list:first
        (codex:unified-exec-process-store-remove-result-cleanup-actions
          $release))))
  "approval-20")

!(assertEqual
  (let $release
    (codex:unified-exec-process-store-release
      (pm-cleanup-store-with-entry
        (pm-cleanup-entry 21 CodexAbsent session-1 False CodexAbsent))
      21)
    (codex:unified-exec-process-store-remove-result-cleanup-actions
      $release))
  ())

!(assertEqual
  (let $result
    (codex:unified-exec-refresh-process-state
      (pm-cleanup-store-with-entry
        (pm-cleanup-entry 30 "approval-30" session-1 True 0))
      30)
    (codex:unified-exec-process-cleanup-action-network-approval-id
      (list:first
        (codex:unified-exec-refresh-process-state-result-cleanup-actions
          $result))))
  "approval-30")

!(assertEqual
  (let $result
    (codex:unified-exec-refresh-process-state
      (pm-cleanup-store-with-entry
        (pm-cleanup-entry 31 "approval-31" session-1 False CodexAbsent))
      31)
    (codex:unified-exec-refresh-process-state-result-cleanup-actions
      $result))
  ())

!(assertEqual
  (let $actions
    (codex:unified-exec-process-entry-pruned-cleanup-actions
      (pm-cleanup-entry 40 "approval-40" session-1 False CodexAbsent))
    (codex:unified-exec-process-cleanup-action-kind
      (list:first $actions)))
  unregister-network-approval)

!(assertEqual
  (let $actions
    (codex:unified-exec-process-entry-pruned-cleanup-actions
      (pm-cleanup-entry 40 "approval-40" session-1 False CodexAbsent))
    (codex:unified-exec-process-cleanup-action-process
      (list:first (list:rest $actions))))
  (pm-cleanup-process-state False CodexAbsent))

!(assertEqual
  (let $result
    (codex:unified-exec-store-process-result
      (codex:unified-exec-process-store-default)
      (pm-cleanup-entry 50 CodexAbsent session-1 False CodexAbsent)
      (pm-cleanup-entry 51 CodexAbsent session-1 False CodexAbsent)
      60
      CodexAbsent
      watcher-1)
    (codex:unified-exec-process-cleanup-action-kind
      (list:first
        (codex:unified-exec-store-process-result-cleanup-actions
          $result))))
  terminate-process)

!(assertEqual
  (let $result
    (codex:unified-exec-terminate-all-processes-result
      ((pm-cleanup-entry 60 "approval-60" session-1 False CodexAbsent)
       (pm-cleanup-entry 61 CodexAbsent session-1 False CodexAbsent))
      (codex:unified-exec-process-store-default))
    (list:len
      (codex:unified-exec-terminate-all-processes-result-cleanup-actions
        $result)))
  3)

!(assertEqual
  (let $result
    (codex:unified-exec-terminate-all-processes-result
      ((pm-cleanup-entry 60 "approval-60" session-1 False CodexAbsent)
       (pm-cleanup-entry 61 CodexAbsent session-1 False CodexAbsent))
      (codex:unified-exec-process-store-default))
    (codex:unified-exec-process-cleanup-action-kind
      (list:first
        (list:rest
          (codex:unified-exec-terminate-all-processes-result-cleanup-actions
            $result)))))
  terminate-process)
