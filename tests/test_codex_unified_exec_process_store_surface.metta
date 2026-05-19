!(register-module! ../codex)
!(import! &self codex:unified_exec_process_store)

(= (codex-store-process-state $has-exited)
   (CodexUnifiedExecProcessState $has-exited CodexAbsent CodexAbsent))

(= (codex-store-entry $process-id $last-used $has-exited)
   (codex:unified-exec-process-entry
     (codex-store-process-state $has-exited)
     (format-args "call-{}" ($process-id))
     $process-id
     "bash"
     True
     CodexAbsent
     test-session
     $last-used))

(= (codex-store-entry-with-approval $process-id $approval-id)
   (codex:unified-exec-process-entry
     (codex-store-process-state False)
     "call-with-approval"
     $process-id
     "bash"
     False
     $approval-id
     test-session
     10))

(= (codex-store-seed-64 $next-id $store)
   (if (> $next-id 64)
       $store
       (codex-store-seed-64
         (+ $next-id 1)
         (codex:unified-exec-process-store-put-entry
           (codex:unified-exec-process-store-reserve-process-id
             $store
             $next-id)
           (codex-store-entry
             $next-id
             $next-id
             (== $next-id 2))))))

!(assertEqual
  (codex:unified-exec-process-store-processes
    (codex:unified-exec-process-store-default))
  ())

!(assertEqual
  (codex:unified-exec-process-store-reserved-process-ids
    (codex:unified-exec-process-store-default))
  ())

!(assertEqual
  (codex:unified-exec-process-entry-process-id
    (codex-store-entry 42 99 False))
  42)

!(assertEqual
  (codex:unified-exec-process-entry-call-id
    (codex-store-entry 42 99 False))
  "call-42")

!(assertEqual
  (codex:unified-exec-process-entry-hook-command
    (codex-store-entry 42 99 False))
  "bash")

!(assertEqual
  (codex:unified-exec-process-entry-tty
    (codex-store-entry 42 99 False))
  True)

!(assertEqual
  (codex:unified-exec-process-entry-network-approval-id
    (codex-store-entry-with-approval 42 "approval-1"))
  "approval-1")

!(assertEqual
  (codex:unified-exec-process-entry-session
    (codex-store-entry 42 99 False))
  test-session)

!(assertEqual
  (codex:unified-exec-process-entry-last-used
    (codex-store-entry 42 99 False))
  99)

!(assertEqual
  (codex:unified-exec-process-entry-has-exited
    (codex-store-entry 42 99 True))
  True)

!(assertEqual
  (codex:unified-exec-process-id-set-contains (1000 1002) 1000)
  True)

!(assertEqual
  (codex:unified-exec-process-id-set-contains (1000 1002) 1001)
  False)

!(assertEqual
  (codex:unified-exec-process-id-set-insert (1000 1002) 1000)
  (1000 1002))

!(assertEqual
  (codex:unified-exec-process-id-set-insert (1000 1002) 1001)
  (1001 1000 1002))

!(assertEqual
  (codex:unified-exec-process-id-set-remove (1001 1000 1002) 1000)
  (1001 1002))

!(assertEqual
  (codex:unified-exec-process-id-set-max ())
  CodexAbsent)

!(assertEqual
  (codex:unified-exec-process-id-set-max (42 1200 1000))
  1200)

!(assertEqual
  (codex:unified-exec-process-store-next-deterministic-process-id
    (codex:unified-exec-process-store-default))
  1000)

!(assertEqual
  (codex:unified-exec-process-store-next-deterministic-process-id
    (codex:unified-exec-process-store
      ()
      (42)))
  1000)

!(assertEqual
  (codex:unified-exec-process-store-next-deterministic-process-id
    (codex:unified-exec-process-store
      ()
      (999)))
  1000)

!(assertEqual
  (codex:unified-exec-process-store-next-deterministic-process-id
    (codex:unified-exec-process-store
      ()
      (1000 1200)))
  1201)

!(assertEqual
  (let $allocation
    (codex:unified-exec-process-store-allocate-deterministic
      (codex:unified-exec-process-store-default))
    (codex:unified-exec-process-id-allocation-process-id
      $allocation))
  1000)

!(assertEqual
  (let $allocation
    (codex:unified-exec-process-store-allocate-deterministic
      (codex:unified-exec-process-store-default))
    (codex:unified-exec-process-id-set-contains
      (codex:unified-exec-process-store-reserved-process-ids
        (codex:unified-exec-process-id-allocation-store
          $allocation))
      1000))
  True)

!(assertEqual
  (let $first
    (codex:unified-exec-process-store-allocate-deterministic
      (codex:unified-exec-process-store-default))
    (let $second
      (codex:unified-exec-process-store-allocate-deterministic
        (codex:unified-exec-process-id-allocation-store $first))
      (codex:unified-exec-process-id-allocation-process-id
        $second)))
  1001)

!(assertEqual
  (codex:unified-exec-process-id-in-production-range 999)
  False)

!(assertEqual
  (codex:unified-exec-process-id-in-production-range 1000)
  True)

!(assertEqual
  (codex:unified-exec-process-id-in-production-range 99999)
  True)

!(assertEqual
  (codex:unified-exec-process-id-in-production-range 100000)
  False)

!(assertEqual
  (let $allocation
    (codex:unified-exec-process-store-allocate-candidate
      (codex:unified-exec-process-store-default)
      1234)
    (codex:unified-exec-process-id-allocation-process-id
      $allocation))
  1234)

!(assertEqual
  (let $allocation
    (codex:unified-exec-process-store-allocate-candidate
      (codex:unified-exec-process-store-default)
      1234)
    (codex:unified-exec-process-id-set-contains
      (codex:unified-exec-process-store-reserved-process-ids
        (codex:unified-exec-process-id-allocation-store
          $allocation))
      1234))
  True)

!(assertEqual
  (codex:unified-exec-process-store-allocate-candidate
    (codex:unified-exec-process-store () (1234))
    1234)
  (CodexUnifiedExecProcessIdAllocationRetry
    (codex:unified-exec-process-store () (1234))))

!(assertEqual
  (codex:unified-exec-process-store-allocate-candidate
    (codex:unified-exec-process-store-default)
    999)
  (CodexUnifiedExecProcessIdAllocationRetry
    (codex:unified-exec-process-store-default)))

!(assertEqual
  (codex:unified-exec-should-use-deterministic-process-ids
    True
    False)
  True)

!(assertEqual
  (codex:unified-exec-should-use-deterministic-process-ids
    False
    True)
  True)

!(assertEqual
  (codex:unified-exec-should-use-deterministic-process-ids
    False
    False)
  False)

!(assertEqual
  (let $allocation
    (codex:unified-exec-process-store-allocate-process-id
      (codex:unified-exec-process-store-default)
      True
      False
      1234)
    (codex:unified-exec-process-id-allocation-process-id
      $allocation))
  1000)

!(assertEqual
  (let $allocation
    (codex:unified-exec-process-store-allocate-process-id
      (codex:unified-exec-process-store-default)
      False
      True
      1234)
    (codex:unified-exec-process-id-allocation-process-id
      $allocation))
  1000)

!(assertEqual
  (let $allocation
    (codex:unified-exec-process-store-allocate-process-id
      (codex:unified-exec-process-store-default)
      False
      False
      1234)
    (codex:unified-exec-process-id-allocation-process-id
      $allocation))
  1234)

!(assertEqual
  (let $store
    (codex:unified-exec-process-store-put-entry
      (codex:unified-exec-process-store-default)
      (codex-store-entry 1000 10 False))
    (codex:unified-exec-process-entry-call-id
      (codex:unified-exec-process-store-get-entry $store 1000)))
  "call-1000")

!(assertEqual
  (let $store
    (codex:unified-exec-process-store-put-entry
      (codex:unified-exec-process-store-put-entry
        (codex:unified-exec-process-store-default)
        (codex-store-entry 1000 10 False))
      (codex-store-entry 1000 20 True))
    (codex:unified-exec-process-entry-last-used
      (codex:unified-exec-process-store-get-entry $store 1000)))
  20)

!(assertEqual
  (let $store
    (codex:unified-exec-process-store-put-entry
      (codex:unified-exec-process-store-reserve-process-id
        (codex:unified-exec-process-store-default)
        1000)
      (codex-store-entry-with-approval 1000 "approval-1"))
    (let $removed
      (codex:unified-exec-process-store-release $store 1000)
      (codex:unified-exec-process-entry-network-approval-id
        (codex:unified-exec-process-store-remove-result-removed
          $removed))))
  "approval-1")

!(assertEqual
  (let $store
    (codex:unified-exec-process-store-put-entry
      (codex:unified-exec-process-store-reserve-process-id
        (codex:unified-exec-process-store-default)
        1000)
      (codex-store-entry 1000 10 False))
    (let $removed
      (codex:unified-exec-process-store-release $store 1000)
      (codex:unified-exec-process-id-set-contains
        (codex:unified-exec-process-store-reserved-process-ids
          (codex:unified-exec-process-store-remove-result-store
            $removed))
        1000)))
  False)

!(assertEqual
  (let $store
    (codex:unified-exec-process-store () (1000))
    (let $removed
      (codex:unified-exec-process-store-release $store 1000)
      (codex:unified-exec-process-store-remove-result-removed
        $removed)))
  CodexAbsent)

!(assertEqual
  (let $store
    (codex:unified-exec-process-store () (1000))
    (let $removed
      (codex:unified-exec-process-store-release $store 1000)
      (codex:unified-exec-process-store-reserved-process-ids
        (codex:unified-exec-process-store-remove-result-store
          $removed))))
  ())

!(assertEqual
  (let $store
    (codex:unified-exec-process-store-put-entry
      (codex:unified-exec-process-store-default)
      (codex-store-entry 9 9 True))
    (codex:unified-exec-process-meta-has-exited
      (list:first
        (codex:unified-exec-process-store-metas $store))))
  True)

!(assertEqual
  (let $store
    (codex-store-seed-64
      1
      (codex:unified-exec-process-store-default))
    (let $pruned
      (codex:unified-exec-process-store-prune-if-needed $store)
      (codex:unified-exec-process-entry-process-id
        (codex:unified-exec-process-store-prune-result-removed
          $pruned))))
  2)

!(assertEqual
  (let $store
    (codex-store-seed-64
      1
      (codex:unified-exec-process-store-default))
    (let $pruned
      (codex:unified-exec-process-store-prune-if-needed $store)
      (codex:unified-exec-process-store-get-entry
        (codex:unified-exec-process-store-prune-result-store
          $pruned)
        2)))
  CodexAbsent)

!(assertEqual
  (let $store
    (codex-store-seed-64
      1
      (codex:unified-exec-process-store-default))
    (let $pruned
      (codex:unified-exec-process-store-prune-if-needed $store)
      (codex:unified-exec-process-id-set-contains
        (codex:unified-exec-process-store-reserved-process-ids
          (codex:unified-exec-process-store-prune-result-store
            $pruned))
        2)))
  False)

!(assertEqual
  (let $store
    (codex:unified-exec-process-store-put-entry
      (codex:unified-exec-process-store-default)
      (codex-store-entry 1 1 True))
    (let $pruned
      (codex:unified-exec-process-store-prune-if-needed $store)
      (codex:unified-exec-process-store-prune-result-removed
        $pruned)))
  CodexAbsent)
