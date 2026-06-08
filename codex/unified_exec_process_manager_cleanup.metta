; Rust-faithful pure unified-exec process-manager cleanup planning slice.
;
; This ports deterministic cleanup responsibility from:
; - openai-codex/codex-rs/core/src/unified_exec/process_manager.rs
;   - release_process_id
;   - unregister_network_approval_for_entry
;   - refresh_process_state post-lock cleanup
;   - store_process pruned-entry cleanup
;   - terminate_all_processes drained-entry cleanup
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust performs async network-approval unregister calls and process termination
;   after releasing the `process_store` mutex. This pure boundary materializes
;   those side-effect requests as cleanup actions for the later runtime slice.
; - Rust stores a weak `Session` pointer and unregisters only when `upgrade()`
;   succeeds. The pure CeTTa boundary represents a failed/missing upgrade as
;   `CodexAbsent` in the entry session field.
; - Rust drains a `HashMap` in unspecified order in `terminate_all_processes`.
;   The list-backed CeTTa store carries its existing list order; no Rust-visible
;   behavior depends on this ordering.

!(import! &self list)
!(import! &self unified_exec_process_manager_state)

(= (codex:unified-exec-process-cleanup-unregister-network-approval
      $session
      $network-approval-id)
   (CodexUnifiedExecProcessCleanupUnregisterNetworkApproval
     $session
     $network-approval-id))

(= (codex:unified-exec-process-cleanup-terminate-process $process)
   (CodexUnifiedExecProcessCleanupTerminateProcess $process))

(= (codex:unified-exec-process-cleanup-action-kind
      (CodexUnifiedExecProcessCleanupUnregisterNetworkApproval
        $session
        $network-approval-id))
   unregister-network-approval)

(= (codex:unified-exec-process-cleanup-action-kind
      (CodexUnifiedExecProcessCleanupTerminateProcess $process))
   terminate-process)

(= (codex:unified-exec-process-cleanup-action-session
      (CodexUnifiedExecProcessCleanupUnregisterNetworkApproval
        $session
        $network-approval-id))
   $session)

(= (codex:unified-exec-process-cleanup-action-network-approval-id
      (CodexUnifiedExecProcessCleanupUnregisterNetworkApproval
        $session
        $network-approval-id))
   $network-approval-id)

(= (codex:unified-exec-process-cleanup-action-process
      (CodexUnifiedExecProcessCleanupTerminateProcess $process))
   $process)

(= (codex:unified-exec-process-entry-network-approval-cleanup-actions $entry)
   (let $network-approval-id
     (codex:unified-exec-process-entry-network-approval-id $entry)
     (let $session
       (codex:unified-exec-process-entry-session $entry)
       (if (or (== $network-approval-id CodexAbsent)
               (== $session CodexAbsent))
           ()
           (let $action
             (codex:unified-exec-process-cleanup-unregister-network-approval
               $session
               $network-approval-id)
             (cons-atom $action ()))))))

(= (codex:unified-exec-process-entry-terminate-cleanup-actions $entry)
   (let $action
     (codex:unified-exec-process-cleanup-terminate-process
       (codex:unified-exec-process-entry-process $entry))
     (cons-atom $action ())))

(= (codex:unified-exec-process-entry-pruned-cleanup-actions $entry)
   (if (== $entry CodexAbsent)
       ()
       (list:append
         (codex:unified-exec-process-entry-network-approval-cleanup-actions
           $entry)
         (codex:unified-exec-process-entry-terminate-cleanup-actions
           $entry))))

(= (codex:unified-exec-process-store-remove-result-cleanup-actions
      $remove-result)
   (let $entry
     (codex:unified-exec-process-store-remove-result-removed $remove-result)
     (if (== $entry CodexAbsent)
         ()
         (codex:unified-exec-process-entry-network-approval-cleanup-actions
           $entry))))

(= (codex:unified-exec-store-process-result-cleanup-actions
      $store-process-result)
   (codex:unified-exec-process-entry-pruned-cleanup-actions
     (codex:unified-exec-store-process-result-pruned-entry
       $store-process-result)))

(= (codex:unified-exec-refresh-process-state-result-cleanup-actions
      $refresh-result)
   (let $status
     (codex:unified-exec-refresh-process-state-result-status $refresh-result)
     (if (== (codex:unified-exec-process-status-kind $status) exited)
         (codex:unified-exec-process-entry-network-approval-cleanup-actions
           (codex:unified-exec-process-status-entry $status))
         ())))

(= (codex:unified-exec-process-entries-terminate-cleanup-actions $entries)
   (if (== $entries ())
       ()
       (let ($entry $rest) (decons-atom $entries)
         (list:append
           (codex:unified-exec-process-entry-pruned-cleanup-actions $entry)
           (codex:unified-exec-process-entries-terminate-cleanup-actions
             $rest)))))

(= (codex:unified-exec-terminate-all-processes-result-cleanup-actions
      $terminate-result)
   (codex:unified-exec-process-entries-terminate-cleanup-actions
     (codex:unified-exec-terminate-all-processes-result-entries
       $terminate-result)))
