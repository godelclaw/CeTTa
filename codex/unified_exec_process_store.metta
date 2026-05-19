; Rust-faithful pure unified-exec process-store slice.
;
; This ports the deterministic store/allocation behavior from:
; - openai-codex/codex-rs/core/src/unified_exec/mod.rs
;   - ProcessStore
;   - ProcessStore::remove
;   - ProcessEntry field shape
; - openai-codex/codex-rs/core/src/unified_exec/process_manager.rs
;   - allocate_process_id
;   - release_process_id store mutation
;   - prune_processes_if_needed store mutation
;
; Covered in this increment:
; - list-backed ProcessStore process map and reserved-ID set
; - deterministic process-id allocation
; - production candidate allocation retry/accept boundary
; - process-id release/remove
; - store-level pruning with actual entry removal
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust stores `HashMap<i32, ProcessEntry>` and `HashSet<i32>`. This pure
;   CeTTa slice uses ordered lists and explicit key/set helpers; list order is
;   not a Rust-visible contract.
; - Rust production allocation draws `rand::rng().random_range(1_000..100_000)`
;   inside a retry loop. Until a numeric RNG library is part of the CeTTa
;   runtime boundary, the production path is exposed as one candidate step:
;   accepted candidates reserve the ID; colliding or out-of-range candidates
;   return a retry marker so the caller can supply the next RNG candidate.
; - Rust stores `FORCE_DETERMINISTIC_PROCESS_IDS` in a process-global
;   `AtomicBool` and also checks `cfg!(test)`. This pure boundary represents
;   those two inputs explicitly; the later runtime manager can own the mutable
;   flag and feed the same decision helper.
; - Rust `ProcessEntry.process` is `Arc<UnifiedExecProcess>` and pruning reads
;   `entry.process.has_exited()`. Early pure slices stored the ported
;   `CodexUnifiedExecProcessState` atom directly in the process slot because
;   `has_exited` was the only process property used there. Later runtime-shape
;   slices may wrap that state with side-effect handles; the store still reads
;   only the same state bit Rust reads.
; - Rust `release_process_id` unregisters any deferred network approval after
;   removal. This pure helper returns the removed entry so the later side-effect
;   runtime slice can perform that unregister step without changing store
;   mutation semantics.

!(import! &self list)
!(import! &self unified_exec_process_pruning)

(= (codex:unified-exec-process-entry
      $process
      $call-id
      $process-id
      $hook-command
      $tty
      $network-approval-id
      $session
      $last-used)
   (CodexUnifiedExecProcessEntry
     $process
     $call-id
     $process-id
     $hook-command
     $tty
     $network-approval-id
     $session
     $last-used))

(= (codex:unified-exec-process-entry-process
      (CodexUnifiedExecProcessEntry
        $process
        $call-id
        $process-id
        $hook-command
        $tty
        $network-approval-id
        $session
        $last-used))
   $process)

(= (codex:unified-exec-process-entry-call-id
      (CodexUnifiedExecProcessEntry
        $process
        $call-id
        $process-id
        $hook-command
        $tty
        $network-approval-id
        $session
        $last-used))
   $call-id)

(= (codex:unified-exec-process-entry-process-id
      (CodexUnifiedExecProcessEntry
        $process
        $call-id
        $process-id
        $hook-command
        $tty
        $network-approval-id
        $session
        $last-used))
   $process-id)

(= (codex:unified-exec-process-entry-hook-command
      (CodexUnifiedExecProcessEntry
        $process
        $call-id
        $process-id
        $hook-command
        $tty
        $network-approval-id
        $session
        $last-used))
   $hook-command)

(= (codex:unified-exec-process-entry-tty
      (CodexUnifiedExecProcessEntry
        $process
        $call-id
        $process-id
        $hook-command
        $tty
        $network-approval-id
        $session
        $last-used))
   $tty)

(= (codex:unified-exec-process-entry-network-approval-id
      (CodexUnifiedExecProcessEntry
        $process
        $call-id
        $process-id
        $hook-command
        $tty
        $network-approval-id
        $session
        $last-used))
   $network-approval-id)

(= (codex:unified-exec-process-entry-session
      (CodexUnifiedExecProcessEntry
        $process
        $call-id
        $process-id
        $hook-command
        $tty
        $network-approval-id
        $session
        $last-used))
   $session)

(= (codex:unified-exec-process-entry-last-used
      (CodexUnifiedExecProcessEntry
        $process
        $call-id
        $process-id
        $hook-command
        $tty
        $network-approval-id
        $session
        $last-used))
   $last-used)

(= (codex:unified-exec-process-entry-with-last-used
      (CodexUnifiedExecProcessEntry
        $process
        $call-id
        $process-id
        $hook-command
        $tty
        $network-approval-id
        $session
        $last-used)
      $new-last-used)
   (CodexUnifiedExecProcessEntry
     $process
     $call-id
     $process-id
     $hook-command
     $tty
     $network-approval-id
     $session
     $new-last-used))

(= (codex:unified-exec-process-entry-has-exited
      (CodexUnifiedExecProcessEntry
        (CodexUnifiedExecProcessState
          $has-exited
          $exit-code
          $failure-message)
        $call-id
        $process-id
        $hook-command
        $tty
        $network-approval-id
        $session
        $last-used))
   $has-exited)

(= (codex:unified-exec-process-entry-has-exited
      (CodexUnifiedExecProcessEntry
        (CodexUnifiedExecProcessWithOutputHandles
          (CodexUnifiedExecProcessState
            $has-exited
            $exit-code
            $failure-message)
          $output-handles)
        $call-id
        $process-id
        $hook-command
        $tty
        $network-approval-id
        $session
        $last-used))
   $has-exited)

(= (codex:unified-exec-process-entry-meta $entry)
   (codex:unified-exec-process-meta
     (codex:unified-exec-process-entry-process-id $entry)
     (codex:unified-exec-process-entry-last-used $entry)
     (codex:unified-exec-process-entry-has-exited $entry)))

(= (codex:unified-exec-process-store $processes $reserved-process-ids)
   (CodexUnifiedExecProcessStore $processes $reserved-process-ids))

(= (codex:unified-exec-process-store-default)
   (CodexUnifiedExecProcessStore () ()))

(= (codex:unified-exec-process-store-processes
      (CodexUnifiedExecProcessStore $processes $reserved-process-ids))
   $processes)

(= (codex:unified-exec-process-store-reserved-process-ids
      (CodexUnifiedExecProcessStore $processes $reserved-process-ids))
   $reserved-process-ids)

(= (codex:unified-exec-process-store-with-processes
      (CodexUnifiedExecProcessStore $processes $reserved-process-ids)
      $new-processes)
   (CodexUnifiedExecProcessStore $new-processes $reserved-process-ids))

(= (codex:unified-exec-process-store-with-reserved-process-ids
      (CodexUnifiedExecProcessStore $processes $reserved-process-ids)
      $new-reserved-process-ids)
   (CodexUnifiedExecProcessStore $processes $new-reserved-process-ids))

(= (codex:unified-exec-process-id-set-contains $ids $process-id)
   (if (== $ids ())
       False
       (let $head (list:first $ids)
         (let $tail (list:rest $ids)
           (if (== $head $process-id)
               True
               (codex:unified-exec-process-id-set-contains
                 $tail
                 $process-id))))))

(= (codex:unified-exec-process-id-set-insert $ids $process-id)
   (if (codex:unified-exec-process-id-set-contains $ids $process-id)
       $ids
       (cons-atom $process-id $ids)))

(= (codex:unified-exec-process-id-set-remove $ids $process-id)
   (if (== $ids ())
       ()
       (let $head (list:first $ids)
         (let $tail (list:rest $ids)
           (let $rest
             (eval
               (codex:unified-exec-process-id-set-remove
                 $tail
                 $process-id))
             (if (== $head $process-id)
                 $rest
                 (cons-atom $head $rest)))))))

(= (codex:unified-exec-process-id-set-max $ids)
   (if (== $ids ())
       CodexAbsent
       (codex:unified-exec-process-id-set-max-from
         (list:rest $ids)
         (list:first $ids))))

(= (codex:unified-exec-process-id-set-max-from $ids $current-max)
   (if (== $ids ())
       $current-max
       (let $head (list:first $ids)
         (let $tail (list:rest $ids)
           (codex:unified-exec-process-id-set-max-from
             $tail
             (if (> $head $current-max)
                 $head
                 $current-max))))))

(= (codex:unified-exec-process-entry-list-get $entries $process-id)
   (if (== $entries ())
       CodexAbsent
       (let $head (list:first $entries)
         (let $tail (list:rest $entries)
           (if (== (codex:unified-exec-process-entry-process-id $head)
                   $process-id)
               $head
               (codex:unified-exec-process-entry-list-get
                 $tail
                 $process-id))))))

(= (codex:unified-exec-process-entry-list-remove $entries $process-id)
   (if (== $entries ())
       ()
       (let $head (list:first $entries)
         (let $tail (list:rest $entries)
           (let $rest
             (eval
               (codex:unified-exec-process-entry-list-remove
                 $tail
                 $process-id))
             (if (== (codex:unified-exec-process-entry-process-id $head)
                     $process-id)
                 $rest
                 (cons-atom $head $rest)))))))

(= (codex:unified-exec-process-entry-list-insert $entries $entry)
   (let $rest
     (eval
       (codex:unified-exec-process-entry-list-remove
         $entries
         (codex:unified-exec-process-entry-process-id $entry)))
     (cons-atom $entry $rest)))

(= (codex:unified-exec-process-store-get-entry $store $process-id)
   (codex:unified-exec-process-entry-list-get
     (codex:unified-exec-process-store-processes $store)
     $process-id))

(= (codex:unified-exec-process-store-put-entry $store $entry)
   (let $processes
     (eval
       (codex:unified-exec-process-entry-list-insert
         (codex:unified-exec-process-store-processes $store)
         $entry))
     (codex:unified-exec-process-store-with-processes
       $store
       $processes)))

(= (codex:unified-exec-process-store-reserve-process-id
      $store
      $process-id)
   (let $reserved
     (eval
       (codex:unified-exec-process-id-set-insert
         (codex:unified-exec-process-store-reserved-process-ids $store)
         $process-id))
     (codex:unified-exec-process-store-with-reserved-process-ids
       $store
       $reserved)))

(= (codex:unified-exec-process-store-remove-result $removed $store)
   (CodexUnifiedExecProcessStoreRemoveResult $removed $store))

(= (codex:unified-exec-process-store-remove-result-removed
      (CodexUnifiedExecProcessStoreRemoveResult $removed $store))
   $removed)

(= (codex:unified-exec-process-store-remove-result-store
      (CodexUnifiedExecProcessStoreRemoveResult $removed $store))
   $store)

(= (codex:unified-exec-process-store-remove $store $process-id)
   (let $removed
     (codex:unified-exec-process-store-get-entry $store $process-id)
     (let $processes
       (eval
         (codex:unified-exec-process-entry-list-remove
           (codex:unified-exec-process-store-processes $store)
           $process-id))
       (let $reserved
         (eval
           (codex:unified-exec-process-id-set-remove
             (codex:unified-exec-process-store-reserved-process-ids $store)
             $process-id))
         (codex:unified-exec-process-store-remove-result
           $removed
           (codex:unified-exec-process-store $processes $reserved))))))

(= (codex:unified-exec-process-store-release $store $process-id)
   (codex:unified-exec-process-store-remove $store $process-id))

(= (codex:unified-exec-process-store-next-deterministic-process-id
      $store)
   (let $max-id
     (codex:unified-exec-process-id-set-max
       (codex:unified-exec-process-store-reserved-process-ids $store))
     (if (== $max-id CodexAbsent)
         1000
         (if (> $max-id 999)
             (+ $max-id 1)
             1000))))

(= (codex:unified-exec-process-id-allocation $process-id $store)
   (CodexUnifiedExecProcessIdAllocation $process-id $store))

(= (codex:unified-exec-process-id-allocation-process-id
      (CodexUnifiedExecProcessIdAllocation $process-id $store))
   $process-id)

(= (codex:unified-exec-process-id-allocation-store
      (CodexUnifiedExecProcessIdAllocation $process-id $store))
   $store)

(= (codex:unified-exec-process-id-allocation-retry $store)
   (CodexUnifiedExecProcessIdAllocationRetry $store))

(= (codex:unified-exec-process-id-allocation-retry-store
      (CodexUnifiedExecProcessIdAllocationRetry $store))
   $store)

(= (codex:unified-exec-process-store-allocate-deterministic $store)
   (let $process-id
     (codex:unified-exec-process-store-next-deterministic-process-id
       $store)
     (codex:unified-exec-process-id-allocation
       $process-id
       (codex:unified-exec-process-store-reserve-process-id
         $store
         $process-id))))

(= (codex:unified-exec-process-id-in-production-range $process-id)
   (if (< $process-id 1000)
       False
       (if (< $process-id 100000)
           True
           False)))

(= (codex:unified-exec-process-store-allocate-candidate
      $store
      $process-id)
   (if (codex:unified-exec-process-id-in-production-range $process-id)
       (if (codex:unified-exec-process-id-set-contains
             (codex:unified-exec-process-store-reserved-process-ids $store)
             $process-id)
           (codex:unified-exec-process-id-allocation-retry $store)
           (codex:unified-exec-process-id-allocation
             $process-id
             (codex:unified-exec-process-store-reserve-process-id
               $store
               $process-id)))
       (codex:unified-exec-process-id-allocation-retry $store)))

(= (codex:unified-exec-should-use-deterministic-process-ids
      $is-test-build
      $deterministic-process-ids-forced)
   (if $is-test-build
       True
       $deterministic-process-ids-forced))

(= (codex:unified-exec-process-store-allocate-process-id
      $store
      $is-test-build
      $deterministic-process-ids-forced
      $production-candidate-process-id)
   (if (codex:unified-exec-should-use-deterministic-process-ids
         $is-test-build
         $deterministic-process-ids-forced)
       (codex:unified-exec-process-store-allocate-deterministic $store)
       (codex:unified-exec-process-store-allocate-candidate
         $store
         $production-candidate-process-id)))

(= (codex:unified-exec-process-store-metas $store)
   (codex:unified-exec-process-entry-list-metas
     (codex:unified-exec-process-store-processes $store)))

(= (codex:unified-exec-process-entry-list-metas $entries)
   (if (== $entries ())
       ()
       (let $head (list:first $entries)
         (let $tail (list:rest $entries)
           (let $rest
             (eval
               (codex:unified-exec-process-entry-list-metas $tail))
             (let $meta
               (eval (codex:unified-exec-process-entry-meta $head))
               (cons-atom $meta $rest)))))))

(= (codex:unified-exec-process-store-prune-result $removed $store)
   (CodexUnifiedExecProcessStorePruneResult $removed $store))

(= (codex:unified-exec-process-store-prune-result-removed
      (CodexUnifiedExecProcessStorePruneResult $removed $store))
   $removed)

(= (codex:unified-exec-process-store-prune-result-store
      (CodexUnifiedExecProcessStorePruneResult $removed $store))
   $store)

(= (codex:unified-exec-process-store-prune-if-needed $store)
   (let $processes
     (codex:unified-exec-process-store-processes $store)
     (if (< (list:len $processes) (codex:max-unified-exec-processes))
         (codex:unified-exec-process-store-prune-result
           CodexAbsent
           $store)
         (let $process-id
           (once
             (eval
               (codex:unified-exec-process-id-to-prune-from-meta
                 (codex:unified-exec-process-store-metas $store))))
           (if (== $process-id CodexAbsent)
               (codex:unified-exec-process-store-prune-result
                 CodexAbsent
                 $store)
               (let $removed
                 (codex:unified-exec-process-store-remove
                   $store
                   $process-id)
                 (codex:unified-exec-process-store-prune-result
                   (codex:unified-exec-process-store-remove-result-removed
                     $removed)
                   (codex:unified-exec-process-store-remove-result-store
                     $removed))))))))
