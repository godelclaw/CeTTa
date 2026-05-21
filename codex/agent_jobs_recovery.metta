; Rust-faithful pure agent job running-item recovery slice.
;
; This ports deterministic branch behavior from:
; - openai-codex/codex-rs/core/src/tools/handlers/agent_jobs.rs
;
; Covered in this increment:
; - is_item_stale wall-clock age check
; - stale running item mark-failed action and optional thread shutdown
; - missing assigned_thread_id recovery failure
; - invalid assigned_thread_id recovery failure
; - final thread status finalization action
; - non-final thread status activation action
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust `recover_running_items` performs DB mutations, live-agent shutdown,
;   status lookups, and status subscriptions inline. This pure slice receives
;   the looked-up `AgentStatus` and emits the exact side-effect plan for one
;   item; the runtime bridge must execute those plans in the same branch order.
; - Rust computes staleness from `Utc::now().signed_duration_since(updated_at)`.
;   This slice takes `now_seconds` and item `updated_at_seconds` explicitly;
;   negative wall-clock age is treated as non-stale, matching Rust's `to_std`
;   failure branch.
; - Rust stores active `started_at` as an `Instant` reconstructed from the item
;   update age. This pure recovery action carries `updated_at_seconds` so the
;   runtime bridge can perform that `Instant` reconstruction at subscription
;   time.

!(import! &self agent_status)
!(import! &self function_tool)
!(import! &self str)
!(import! &self thread_id)

(= (codex:agent-job-recovery-item
      $item-id
      $assigned-thread-id
      $updated-at-seconds)
   (CodexAgentJobRecoveryItem
     $item-id
     $assigned-thread-id
     $updated-at-seconds))

(= (codex:agent-job-recovery-item-id
      (CodexAgentJobRecoveryItem
        $item-id
        $assigned-thread-id
        $updated-at-seconds))
   $item-id)

(= (codex:agent-job-recovery-item-assigned-thread-id
      (CodexAgentJobRecoveryItem
        $item-id
        $assigned-thread-id
        $updated-at-seconds))
   $assigned-thread-id)

(= (codex:agent-job-recovery-item-updated-at-seconds
      (CodexAgentJobRecoveryItem
        $item-id
        $assigned-thread-id
        $updated-at-seconds))
   $updated-at-seconds)

(= (codex:agent-job-recovery-mark-failed
      $item-id
      $error-message
      $shutdown-thread-id)
   (CodexAgentJobRecoveryMarkFailed
     $item-id
     $error-message
     $shutdown-thread-id))

(= (codex:agent-job-recovery-finalize $item-id $thread-id)
   (CodexAgentJobRecoveryFinalize $item-id $thread-id))

(= (codex:agent-job-recovery-activate
      $item-id
      $thread-id
      $updated-at-seconds)
   (CodexAgentJobRecoveryActivate
     $item-id
     $thread-id
     $updated-at-seconds))

(= (codex:agent-job-is-item-stale
      $now-seconds
      $updated-at-seconds
      $runtime-timeout-seconds)
   (let $age-seconds (- $now-seconds $updated-at-seconds)
     (if (< $age-seconds 0)
         False
         (>= $age-seconds $runtime-timeout-seconds))))

(= (codex:agent-job-duration-debug-seconds $seconds)
   (format-args "{}s" ($seconds)))

(= (codex:agent-job-runtime-timeout-error-message $runtime-timeout-seconds)
   (str-concat
     "worker exceeded max runtime of "
     (codex:agent-job-duration-debug-seconds $runtime-timeout-seconds)))

(= (codex:agent-job-parse-assigned-thread-id $assigned-thread-id)
   (case $assigned-thread-id
     ((CodexAbsent CodexAbsent)
      ($thread-id-text
       (codex:thread-id-from-string $thread-id-text)))))

(= (codex:agent-job-recover-stale-running-item
      $item
      $runtime-timeout-seconds)
   (case
     (codex:agent-job-parse-assigned-thread-id
       (codex:agent-job-recovery-item-assigned-thread-id $item))
     (((CodexThreadIdOk $thread-id)
       (codex:agent-job-recovery-mark-failed
         (codex:agent-job-recovery-item-id $item)
         (codex:agent-job-runtime-timeout-error-message
           $runtime-timeout-seconds)
         $thread-id))
      ($other
       (codex:agent-job-recovery-mark-failed
         (codex:agent-job-recovery-item-id $item)
         (codex:agent-job-runtime-timeout-error-message
           $runtime-timeout-seconds)
         CodexAbsent)))))

(= (codex:agent-job-invalid-assigned-thread-id-message $debug-error)
   (str-concat "invalid assigned_thread_id: " $debug-error))

(= (codex:agent-job-recover-running-item
      $item
      $now-seconds
      $runtime-timeout-seconds
      $thread-status)
   (if (codex:agent-job-is-item-stale
         $now-seconds
         (codex:agent-job-recovery-item-updated-at-seconds $item)
         $runtime-timeout-seconds)
       (codex:agent-job-recover-stale-running-item
         $item
         $runtime-timeout-seconds)
       (case
         (codex:agent-job-parse-assigned-thread-id
           (codex:agent-job-recovery-item-assigned-thread-id $item))
         ((CodexAbsent
           (codex:agent-job-recovery-mark-failed
             (codex:agent-job-recovery-item-id $item)
             "running item is missing assigned_thread_id"
             CodexAbsent))
          ((CodexThreadIdErr $debug-error)
           (codex:agent-job-recovery-mark-failed
             (codex:agent-job-recovery-item-id $item)
             (codex:agent-job-invalid-assigned-thread-id-message
               $debug-error)
             CodexAbsent))
          ((CodexThreadIdOk $thread-id)
           (if (codex:is-agent-status-final $thread-status)
               (codex:agent-job-recovery-finalize
                 (codex:agent-job-recovery-item-id $item)
                 $thread-id)
               (codex:agent-job-recovery-activate
                 (codex:agent-job-recovery-item-id $item)
                 $thread-id
                 (codex:agent-job-recovery-item-updated-at-seconds
                   $item))))))))
