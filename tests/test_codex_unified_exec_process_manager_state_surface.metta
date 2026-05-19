!(register-module! ../codex)
!(import! &self codex:unified_exec_process_manager_state)

(= (pm-state-process-state $has-exited $exit-code)
   (CodexUnifiedExecProcessState $has-exited $exit-code CodexAbsent))

(= (pm-state-entry $process-id $last-used $has-exited $exit-code)
   (codex:unified-exec-process-entry
     (pm-state-process-state $has-exited $exit-code)
     (format-args "call-{}" ($process-id))
     $process-id
     "bash"
     True
     CodexAbsent
     session-1
     $last-used))

(= (pm-state-entry-with-approval $process-id $approval-id)
   (codex:unified-exec-process-entry
     (pm-state-process-state False CodexAbsent)
     "call-approval"
     $process-id
     "bash"
     False
     $approval-id
     session-1
     10))

(= (pm-state-store-with-entry $entry)
   (codex:unified-exec-process-store-put-entry
     (codex:unified-exec-process-store-reserve-process-id
       (codex:unified-exec-process-store-default)
       (codex:unified-exec-process-entry-process-id $entry))
     $entry))

(= (pm-state-seed $next-id $limit $store)
   (if (> $next-id $limit)
       $store
       (pm-state-seed
         (+ $next-id 1)
         $limit
         (codex:unified-exec-process-store-put-entry
           (codex:unified-exec-process-store-reserve-process-id
             $store
             $next-id)
           (pm-state-entry
             $next-id
             $next-id
             (== $next-id 2)
             (if (== $next-id 2) 0 CodexAbsent))))))

(= (pm-state-context)
   (codex:unified-exec-context-new session-1 turn-1 "call-new"))

!(assertEqual
  (codex:unified-exec-process-entry-exit-code
    (pm-state-entry 10 1 True 7))
  7)

!(assertEqual
  (codex:unified-exec-process-status-kind
    (codex:unified-exec-process-status-alive
      CodexAbsent
      "call-1"
      1))
  alive)

!(assertEqual
  (codex:unified-exec-process-status-kind
    (codex:unified-exec-process-status-exited
      0
      (pm-state-entry 1 1 True 0)))
  exited)

!(assertEqual
  (codex:unified-exec-process-status-kind
    (codex:unified-exec-process-status-unknown))
  unknown)

!(assertEqual
  (let $result
    (codex:unified-exec-refresh-process-state
      (pm-state-store-with-entry
        (pm-state-entry 10 1 False CodexAbsent))
      10)
    (codex:unified-exec-process-status-kind
      (codex:unified-exec-refresh-process-state-result-status
        $result)))
  alive)

!(assertEqual
  (let $result
    (codex:unified-exec-refresh-process-state
      (pm-state-store-with-entry
        (pm-state-entry 10 1 False 3))
      10)
    (codex:unified-exec-process-status-exit-code
      (codex:unified-exec-refresh-process-state-result-status
        $result)))
  3)

!(assertEqual
  (let $result
    (codex:unified-exec-refresh-process-state
      (pm-state-store-with-entry
        (pm-state-entry 10 1 False CodexAbsent))
      10)
    (codex:unified-exec-process-status-call-id
      (codex:unified-exec-refresh-process-state-result-status
        $result)))
  "call-10")

!(assertEqual
  (let $result
    (codex:unified-exec-refresh-process-state
      (pm-state-store-with-entry
        (pm-state-entry 10 1 False CodexAbsent))
      10)
    (codex:unified-exec-process-store-get-entry
      (codex:unified-exec-refresh-process-state-result-store
        $result)
      10))
  (pm-state-entry 10 1 False CodexAbsent))

!(assertEqual
  (let $result
    (codex:unified-exec-refresh-process-state
      (pm-state-store-with-entry
        (pm-state-entry 10 1 True 0))
      10)
    (codex:unified-exec-process-status-kind
      (codex:unified-exec-refresh-process-state-result-status
        $result)))
  exited)

!(assertEqual
  (let $result
    (codex:unified-exec-refresh-process-state
      (pm-state-store-with-entry
        (pm-state-entry 10 1 True 0))
      10)
    (codex:unified-exec-process-entry-process-id
      (codex:unified-exec-process-status-entry
        (codex:unified-exec-refresh-process-state-result-status
          $result))))
  10)

!(assertEqual
  (let $result
    (codex:unified-exec-refresh-process-state
      (pm-state-store-with-entry
        (pm-state-entry 10 1 True 0))
      10)
    (codex:unified-exec-process-store-get-entry
      (codex:unified-exec-refresh-process-state-result-store
        $result)
      10))
  CodexAbsent)

!(assertEqual
  (let $result
    (codex:unified-exec-refresh-process-state
      (pm-state-store-with-entry
        (pm-state-entry 10 1 True 0))
      10)
    (codex:unified-exec-process-id-set-contains
      (codex:unified-exec-process-store-reserved-process-ids
        (codex:unified-exec-refresh-process-state-result-store
          $result))
      10))
  False)

!(assertEqual
  (let $result
    (codex:unified-exec-refresh-process-state
      (codex:unified-exec-process-store-default)
      10)
    (codex:unified-exec-process-status-kind
      (codex:unified-exec-refresh-process-state-result-status
        $result)))
  unknown)

!(assertEqual
  (codex:unified-exec-spawn-exit-watcher-request-call-id
    (codex:unified-exec-spawn-exit-watcher-request
      process-1
      session-1
      turn-1
      "call-1"
      ("bash")
      "/repo"
      10
      transcript-1
      99))
  "call-1")

!(assertEqual
  (let $result
    (codex:unified-exec-store-process
      (codex:unified-exec-process-store-default)
      (pm-state-process-state False CodexAbsent)
      (pm-state-context)
      ("bash" "-lc" "sleep 1")
      "sleep 1"
      "/repo"
      100
      1000
      True
      CodexAbsent
      transcript-1)
    (codex:unified-exec-process-entry-call-id
      (codex:unified-exec-store-process-result-stored-entry
        $result)))
  "call-new")

!(assertEqual
  (let $result
    (codex:unified-exec-store-process
      (codex:unified-exec-process-store-default)
      (pm-state-process-state False CodexAbsent)
      (pm-state-context)
      ("bash" "-lc" "sleep 1")
      "sleep 1"
      "/repo"
      100
      1000
      True
      CodexAbsent
      transcript-1)
    (codex:unified-exec-process-entry-session
      (codex:unified-exec-process-store-get-entry
        (codex:unified-exec-store-process-result-store $result)
        1000)))
  session-1)

!(assertEqual
  (let $result
    (codex:unified-exec-store-process
      (codex:unified-exec-process-store-default)
      (pm-state-process-state False CodexAbsent)
      (pm-state-context)
      ("bash" "-lc" "sleep 1")
      "sleep 1"
      "/repo"
      100
      1000
      True
      CodexAbsent
      transcript-1)
    (codex:unified-exec-store-process-result-number-processes
      $result))
  1)

!(assertEqual
  (let $result
    (codex:unified-exec-store-process
      (pm-state-seed 1 58 (codex:unified-exec-process-store-default))
      (pm-state-process-state False CodexAbsent)
      (pm-state-context)
      ("bash")
      "bash"
      "/repo"
      200
      1000
      True
      CodexAbsent
      transcript-1)
    (codex:unified-exec-store-process-result-warning-message
      $result))
  CodexAbsent)

!(assertEqual
  (let $result
    (codex:unified-exec-store-process
      (pm-state-seed 1 59 (codex:unified-exec-process-store-default))
      (pm-state-process-state False CodexAbsent)
      (pm-state-context)
      ("bash")
      "bash"
      "/repo"
      200
      1000
      True
      CodexAbsent
      transcript-1)
    (codex:unified-exec-store-process-result-number-processes
      $result))
  60)

!(assertEqual
  (let $result
    (codex:unified-exec-store-process
      (pm-state-seed 1 59 (codex:unified-exec-process-store-default))
      (pm-state-process-state False CodexAbsent)
      (pm-state-context)
      ("bash")
      "bash"
      "/repo"
      200
      1000
      True
      CodexAbsent
      transcript-1)
    (codex:unified-exec-store-process-result-warning-message
      $result))
  "The maximum number of unified exec processes you can keep open is 60 and you currently have 60 processes open. Reuse older processes or close them to prevent automatic pruning of old processes")

!(assertEqual
  (let $result
    (codex:unified-exec-store-process
      (pm-state-seed 1 64 (codex:unified-exec-process-store-default))
      (pm-state-process-state False CodexAbsent)
      (pm-state-context)
      ("bash")
      "bash"
      "/repo"
      200
      2000
      True
      CodexAbsent
      transcript-1)
    (codex:unified-exec-process-entry-process-id
      (codex:unified-exec-store-process-result-pruned-entry
        $result)))
  2)

!(assertEqual
  (let $result
    (codex:unified-exec-store-process
      (pm-state-seed 1 64 (codex:unified-exec-process-store-default))
      (pm-state-process-state False CodexAbsent)
      (pm-state-context)
      ("bash")
      "bash"
      "/repo"
      200
      2000
      True
      CodexAbsent
      transcript-1)
    (codex:unified-exec-process-store-get-entry
      (codex:unified-exec-store-process-result-store
        $result)
      2))
  CodexAbsent)

!(assertEqual
  (let $result
    (codex:unified-exec-store-process
      (pm-state-seed 1 64 (codex:unified-exec-process-store-default))
      (pm-state-process-state False CodexAbsent)
      (pm-state-context)
      ("bash")
      "bash"
      "/repo"
      200
      2000
      True
      CodexAbsent
      transcript-1)
    (codex:unified-exec-spawn-exit-watcher-request-process-id
      (codex:unified-exec-store-process-result-exit-watcher-request
        $result)))
  2000)

!(assertEqual
  (let $result
    (codex:unified-exec-terminate-all-processes
      (pm-state-seed 1 3 (codex:unified-exec-process-store-default)))
    (list:len
      (codex:unified-exec-terminate-all-processes-result-entries
        $result)))
  3)

!(assertEqual
  (let $result
    (codex:unified-exec-terminate-all-processes
      (pm-state-seed 1 3 (codex:unified-exec-process-store-default)))
    (codex:unified-exec-process-store-processes
      (codex:unified-exec-terminate-all-processes-result-store
        $result)))
  ())

!(assertEqual
  (let $result
    (codex:unified-exec-terminate-all-processes
      (pm-state-seed 1 3 (codex:unified-exec-process-store-default)))
    (codex:unified-exec-process-store-reserved-process-ids
      (codex:unified-exec-terminate-all-processes-result-store
        $result)))
  ())
