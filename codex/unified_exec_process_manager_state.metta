; Rust-faithful pure unified-exec process-manager state transition slice.
;
; This ports deterministic store-transition behavior from:
; - openai-codex/codex-rs/core/src/unified_exec/process_manager.rs
;   - refresh_process_state
;   - store_process
;   - terminate_all_processes
;   - ProcessStatus
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust holds `process_store` behind `tokio::sync::Mutex` and performs async
;   network-approval cleanup after releasing that lock. This pure boundary
;   returns the exited/pruned/drained entries so the later runtime side-effect
;   slice can unregister approvals and terminate processes in the same order of
;   responsibility without embedding effects in store mutation.
; - Rust's `store_process` calls `spawn_exit_watcher` after storing and warning.
;   This slice returns a `CodexUnifiedExecSpawnExitWatcherRequest` carrying the
;   same arguments, leaving the actual task spawn to the later async runtime
;   port.
; - Rust drains a `HashMap` in unspecified order in `terminate_all_processes`.
;   The list-backed CeTTa store returns entries in its current list order; no
;   Rust-visible behavior depends on this ordering.

!(import! &self list)
!(import! &self unified_exec_core)

(= (codex:unified-exec-process-entry-exit-code
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
   $exit-code)

(= (codex:unified-exec-process-status-alive
      $exit-code
      $call-id
      $process-id)
   (CodexUnifiedExecProcessStatusAlive
     $exit-code
     $call-id
     $process-id))

(= (codex:unified-exec-process-status-exited
      $exit-code
      $entry)
   (CodexUnifiedExecProcessStatusExited
     $exit-code
     $entry))

(= (codex:unified-exec-process-status-unknown)
   CodexUnifiedExecProcessStatusUnknown)

(= (codex:unified-exec-process-status-kind
      (CodexUnifiedExecProcessStatusAlive
        $exit-code
        $call-id
        $process-id))
   alive)

(= (codex:unified-exec-process-status-kind
      (CodexUnifiedExecProcessStatusExited
        $exit-code
        $entry))
   exited)

(= (codex:unified-exec-process-status-kind
      CodexUnifiedExecProcessStatusUnknown)
   unknown)

(= (codex:unified-exec-process-status-exit-code
      (CodexUnifiedExecProcessStatusAlive
        $exit-code
        $call-id
        $process-id))
   $exit-code)

(= (codex:unified-exec-process-status-exit-code
      (CodexUnifiedExecProcessStatusExited
        $exit-code
        $entry))
   $exit-code)

(= (codex:unified-exec-process-status-call-id
      (CodexUnifiedExecProcessStatusAlive
        $exit-code
        $call-id
        $process-id))
   $call-id)

(= (codex:unified-exec-process-status-process-id
      (CodexUnifiedExecProcessStatusAlive
        $exit-code
        $call-id
        $process-id))
   $process-id)

(= (codex:unified-exec-process-status-entry
      (CodexUnifiedExecProcessStatusExited
        $exit-code
        $entry))
   $entry)

(= (codex:unified-exec-refresh-process-state-result
      $status
      $store)
   (CodexUnifiedExecRefreshProcessStateResult $status $store))

(= (codex:unified-exec-refresh-process-state-result-status
      (CodexUnifiedExecRefreshProcessStateResult $status $store))
   $status)

(= (codex:unified-exec-refresh-process-state-result-store
      (CodexUnifiedExecRefreshProcessStateResult $status $store))
   $store)

(= (codex:unified-exec-refresh-process-state $store $process-id)
   (let $entry
     (codex:unified-exec-process-store-get-entry $store $process-id)
     (if (== $entry CodexAbsent)
         (codex:unified-exec-refresh-process-state-result
           (codex:unified-exec-process-status-unknown)
           $store)
         (let $exit-code
           (codex:unified-exec-process-entry-exit-code $entry)
           (if (codex:unified-exec-process-entry-has-exited $entry)
               (let $removed
                 (codex:unified-exec-process-store-remove
                   $store
                   (codex:unified-exec-process-entry-process-id $entry))
                 (codex:unified-exec-refresh-process-state-result
                   (codex:unified-exec-process-status-exited
                     $exit-code
                     (codex:unified-exec-process-store-remove-result-removed
                       $removed))
                   (codex:unified-exec-process-store-remove-result-store
                     $removed)))
               (codex:unified-exec-refresh-process-state-result
                 (codex:unified-exec-process-status-alive
                   $exit-code
                   (codex:unified-exec-process-entry-call-id $entry)
                   (codex:unified-exec-process-entry-process-id $entry))
                 $store))))))

(= (codex:unified-exec-spawn-exit-watcher-request
      $process
      $session
      $turn
      $call-id
      $command
      $cwd
      $process-id
      $transcript
      $started-at)
   (CodexUnifiedExecSpawnExitWatcherRequest
     $process
     $session
     $turn
     $call-id
     $command
     $cwd
     $process-id
     $transcript
     $started-at))

(= (codex:unified-exec-spawn-exit-watcher-request-process
      (CodexUnifiedExecSpawnExitWatcherRequest
        $process
        $session
        $turn
        $call-id
        $command
        $cwd
        $process-id
        $transcript
        $started-at))
   $process)

(= (codex:unified-exec-spawn-exit-watcher-request-session
      (CodexUnifiedExecSpawnExitWatcherRequest
        $process
        $session
        $turn
        $call-id
        $command
        $cwd
        $process-id
        $transcript
        $started-at))
   $session)

(= (codex:unified-exec-spawn-exit-watcher-request-turn
      (CodexUnifiedExecSpawnExitWatcherRequest
        $process
        $session
        $turn
        $call-id
        $command
        $cwd
        $process-id
        $transcript
        $started-at))
   $turn)

(= (codex:unified-exec-spawn-exit-watcher-request-call-id
      (CodexUnifiedExecSpawnExitWatcherRequest
        $process
        $session
        $turn
        $call-id
        $command
        $cwd
        $process-id
        $transcript
        $started-at))
   $call-id)

(= (codex:unified-exec-spawn-exit-watcher-request-command
      (CodexUnifiedExecSpawnExitWatcherRequest
        $process
        $session
        $turn
        $call-id
        $command
        $cwd
        $process-id
        $transcript
        $started-at))
   $command)

(= (codex:unified-exec-spawn-exit-watcher-request-cwd
      (CodexUnifiedExecSpawnExitWatcherRequest
        $process
        $session
        $turn
        $call-id
        $command
        $cwd
        $process-id
        $transcript
        $started-at))
   $cwd)

(= (codex:unified-exec-spawn-exit-watcher-request-process-id
      (CodexUnifiedExecSpawnExitWatcherRequest
        $process
        $session
        $turn
        $call-id
        $command
        $cwd
        $process-id
        $transcript
        $started-at))
   $process-id)

(= (codex:unified-exec-spawn-exit-watcher-request-transcript
      (CodexUnifiedExecSpawnExitWatcherRequest
        $process
        $session
        $turn
        $call-id
        $command
        $cwd
        $process-id
        $transcript
        $started-at))
   $transcript)

(= (codex:unified-exec-spawn-exit-watcher-request-started-at
      (CodexUnifiedExecSpawnExitWatcherRequest
        $process
        $session
        $turn
        $call-id
        $command
        $cwd
        $process-id
        $transcript
        $started-at))
   $started-at)

(= (codex:unified-exec-store-process-result
      $store
      $stored-entry
      $pruned-entry
      $number-processes
      $warning-message
      $exit-watcher-request)
   (CodexUnifiedExecStoreProcessResult
     $store
     $stored-entry
     $pruned-entry
     $number-processes
     $warning-message
     $exit-watcher-request))

(= (codex:unified-exec-store-process-result-store
      (CodexUnifiedExecStoreProcessResult
        $store
        $stored-entry
        $pruned-entry
        $number-processes
        $warning-message
        $exit-watcher-request))
   $store)

(= (codex:unified-exec-store-process-result-stored-entry
      (CodexUnifiedExecStoreProcessResult
        $store
        $stored-entry
        $pruned-entry
        $number-processes
        $warning-message
        $exit-watcher-request))
   $stored-entry)

(= (codex:unified-exec-store-process-result-pruned-entry
      (CodexUnifiedExecStoreProcessResult
        $store
        $stored-entry
        $pruned-entry
        $number-processes
        $warning-message
        $exit-watcher-request))
   $pruned-entry)

(= (codex:unified-exec-store-process-result-number-processes
      (CodexUnifiedExecStoreProcessResult
        $store
        $stored-entry
        $pruned-entry
        $number-processes
        $warning-message
        $exit-watcher-request))
   $number-processes)

(= (codex:unified-exec-store-process-result-warning-message
      (CodexUnifiedExecStoreProcessResult
        $store
        $stored-entry
        $pruned-entry
        $number-processes
        $warning-message
        $exit-watcher-request))
   $warning-message)

(= (codex:unified-exec-store-process-result-exit-watcher-request
      (CodexUnifiedExecStoreProcessResult
        $store
        $stored-entry
        $pruned-entry
        $number-processes
        $warning-message
        $exit-watcher-request))
   $exit-watcher-request)

(= (codex:unified-exec-store-process-warning-message $number-processes)
   (if (>= $number-processes (codex:warning-unified-exec-processes))
       (format-args
         "The maximum number of unified exec processes you can keep open is {} and you currently have {} processes open. Reuse older processes or close them to prevent automatic pruning of old processes"
         ((codex:warning-unified-exec-processes) $number-processes))
       CodexAbsent))

(= (codex:unified-exec-store-process
      $store
      $process
      $context
      $command
      $hook-command
      $cwd
      $started-at
      $process-id
      $tty
      $network-approval-id
      $transcript)
   (let $entry
     (codex:unified-exec-process-entry
       $process
       (codex:unified-exec-context-call-id $context)
       $process-id
       $hook-command
       $tty
       $network-approval-id
       (codex:unified-exec-context-session $context)
       $started-at)
     (let $prune-result
       (codex:unified-exec-process-store-prune-if-needed $store)
       (let $store-after-prune
         (codex:unified-exec-process-store-prune-result-store
           $prune-result)
         (let $store-after-insert
           (eval
             (codex:unified-exec-process-store-put-entry
               $store-after-prune
               $entry))
           (let $number-processes
             (list:len
               (codex:unified-exec-process-store-processes
                 $store-after-insert))
             (codex:unified-exec-store-process-result
               $store-after-insert
               $entry
               (codex:unified-exec-process-store-prune-result-removed
                 $prune-result)
               $number-processes
               (codex:unified-exec-store-process-warning-message
                 $number-processes)
               (codex:unified-exec-spawn-exit-watcher-request
                 $process
                 (codex:unified-exec-context-session $context)
                 (codex:unified-exec-context-turn $context)
                 (codex:unified-exec-context-call-id $context)
                 $command
                 $cwd
                 $process-id
                 $transcript
                 $started-at))))))))

(= (codex:unified-exec-terminate-all-processes-result $entries $store)
   (CodexUnifiedExecTerminateAllProcessesResult $entries $store))

(= (codex:unified-exec-terminate-all-processes-result-entries
      (CodexUnifiedExecTerminateAllProcessesResult $entries $store))
   $entries)

(= (codex:unified-exec-terminate-all-processes-result-store
      (CodexUnifiedExecTerminateAllProcessesResult $entries $store))
   $store)

(= (codex:unified-exec-terminate-all-processes $store)
   (codex:unified-exec-terminate-all-processes-result
     (codex:unified-exec-process-store-processes $store)
     (codex:unified-exec-process-store () ())))
