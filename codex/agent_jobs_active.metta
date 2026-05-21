; Rust-faithful pure agent job active-item monitoring slice.
;
; This ports deterministic branch behavior from:
; - openai-codex/codex-rs/core/src/tools/handlers/agent_jobs.rs
;
; Covered in this increment:
; - ActiveJobItem projection
; - active_item_status watch-receiver preference and fallback status lookup
; - find_finished_threads final-status filtering
; - wait_for_status_change sleep-vs-watch decision
; - reap_stale_active_items stale action collection
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust stores active items in a `HashMap<ThreadId, ActiveJobItem>`, awaits
;   status receivers/control lookups, sleeps with Tokio, mutates DB state, and
;   removes active map entries inline. This pure slice receives an ordered
;   active-item snapshot with already-observed fallback statuses and emits the
;   exact decisions/actions; the runtime bridge must perform the DB mutation,
;   live-agent shutdown, and active-map removal in the same order.
; - Rust `Receiver::has_changed().is_ok()` ignores the returned bool and uses
;   `borrow().clone()` for any live receiver. The `status-rx` projection below
;   therefore carries `has-changed-ok` rather than a changed bool.
; - Rust `Instant::elapsed()` cannot be negative for active items created by the
;   loop. The pure elapsed helper treats future explicit timestamps as
;   non-stale so malformed bridge inputs do not invent stale actions.

!(import! &self agent_jobs)
!(import! &self agent_jobs_recovery)
!(import! &self agent_status)

(= (codex:agent-job-active-item $item-id $started-at-seconds $status-rx)
   (CodexAgentJobActiveItem $item-id $started-at-seconds $status-rx))

(= (codex:agent-job-active-item-id
      (CodexAgentJobActiveItem $item-id $started-at-seconds $status-rx))
   $item-id)

(= (codex:agent-job-active-item-started-at-seconds
      (CodexAgentJobActiveItem $item-id $started-at-seconds $status-rx))
   $started-at-seconds)

(= (codex:agent-job-active-item-status-rx
      (CodexAgentJobActiveItem $item-id $started-at-seconds $status-rx))
   $status-rx)

(= (codex:agent-job-status-rx $has-changed-ok $borrowed-status)
   (CodexAgentJobStatusRx $has-changed-ok $borrowed-status))

(= (codex:agent-job-status-rx-is-present $status-rx)
   (case $status-rx
     ((CodexAbsent False)
      ($other True))))

(= (codex:agent-job-active-item-status $item $fallback-status)
   (case (codex:agent-job-active-item-status-rx $item)
     (((CodexAgentJobStatusRx True $borrowed-status)
       $borrowed-status)
      ($other $fallback-status))))

(= (codex:agent-job-active-observation
      $thread-id
      $item
      $fallback-status)
   (CodexAgentJobActiveObservation $thread-id $item $fallback-status))

(= (codex:agent-job-active-observation-thread-id
      (CodexAgentJobActiveObservation $thread-id $item $fallback-status))
   $thread-id)

(= (codex:agent-job-active-observation-item
      (CodexAgentJobActiveObservation $thread-id $item $fallback-status))
   $item)

(= (codex:agent-job-active-observation-fallback-status
      (CodexAgentJobActiveObservation $thread-id $item $fallback-status))
   $fallback-status)

(= (codex:agent-job-finished-thread $thread-id $item-id)
   (CodexAgentJobFinishedThread $thread-id $item-id))

(= (codex:agent-job-find-finished-threads ())
   ())

(= (codex:agent-job-find-finished-threads $observations)
   (let ($observation $tail) (decons-atom $observations)
     (let $item
       (codex:agent-job-active-observation-item $observation)
       (let $status
         (codex:agent-job-active-item-status
           $item
           (codex:agent-job-active-observation-fallback-status
             $observation))
         (let $tail-finished
           (codex:agent-job-find-finished-threads $tail)
           (if (codex:is-agent-status-final $status)
               (let $thread-id
                 (codex:agent-job-active-observation-thread-id $observation)
                 (let $item-id (codex:agent-job-active-item-id $item)
                   (cons-atom
                     (CodexAgentJobFinishedThread $thread-id $item-id)
                     $tail-finished)))
               $tail-finished))))))

(= (codex:agent-job-active-status-rx-count ())
   0)

(= (codex:agent-job-active-status-rx-count $active-items)
   (let ($item $tail) (decons-atom $active-items)
     (let $tail-count (codex:agent-job-active-status-rx-count $tail)
       (if (codex:agent-job-status-rx-is-present
             (codex:agent-job-active-item-status-rx $item))
           (+ 1 $tail-count)
           $tail-count))))

(= (codex:agent-job-wait-for-status-change-sleep $timeout-seconds)
   (CodexAgentJobWaitForStatusChangeSleep $timeout-seconds))

(= (codex:agent-job-wait-for-status-change-watch
      $timeout-seconds
      $watch-count)
   (CodexAgentJobWaitForStatusChangeWatch $timeout-seconds $watch-count))

(= (codex:agent-job-wait-for-status-change-plan $active-items)
   (case (codex:agent-job-active-status-rx-count $active-items)
     ((0
       (codex:agent-job-wait-for-status-change-sleep
         (codex:agent-job-status-poll-interval-ms)))
      ($watch-count
       (codex:agent-job-wait-for-status-change-watch
         (codex:agent-job-status-poll-interval-ms)
         $watch-count)))))

(= (codex:agent-job-active-item-stale
      $now-seconds
      $started-at-seconds
      $runtime-timeout-seconds)
   (let $elapsed-seconds (- $now-seconds $started-at-seconds)
     (if (< $elapsed-seconds 0)
         False
         (>= $elapsed-seconds $runtime-timeout-seconds))))

(= (codex:agent-job-reap-stale-active-action
      $job-id
      $thread-id
      $item-id
      $error-message)
   (CodexAgentJobReapStaleActiveAction
     $job-id
     $thread-id
     $item-id
     $error-message))

(= (codex:agent-job-reap-stale-active-result $progressed $actions)
   (CodexAgentJobReapStaleActiveResult $progressed $actions))

(= (codex:agent-job-reap-stale-active-items
      $job-id
      $active-observations
      $now-seconds
      $runtime-timeout-seconds)
   (case
     (codex:agent-job-reap-stale-active-actions
       $job-id
       $active-observations
       $now-seconds
       $runtime-timeout-seconds)
     ((()
       (codex:agent-job-reap-stale-active-result False ()))
      ($actions
       (codex:agent-job-reap-stale-active-result True $actions)))))

(= (codex:agent-job-reap-stale-active-actions
      $job-id
      ()
      $now-seconds
      $runtime-timeout-seconds)
   ())

(= (codex:agent-job-reap-stale-active-actions
      $job-id
      $active-observations
      $now-seconds
      $runtime-timeout-seconds)
   (let ($observation $tail) (decons-atom $active-observations)
     (let $item
       (codex:agent-job-active-observation-item $observation)
       (let $tail-actions
         (codex:agent-job-reap-stale-active-actions
           $job-id
           $tail
           $now-seconds
           $runtime-timeout-seconds)
         (if (codex:agent-job-active-item-stale
               $now-seconds
               (codex:agent-job-active-item-started-at-seconds $item)
               $runtime-timeout-seconds)
             (let $thread-id
               (codex:agent-job-active-observation-thread-id $observation)
               (let $item-id (codex:agent-job-active-item-id $item)
                 (let $error-message
                   (codex:agent-job-runtime-timeout-error-message
                     $runtime-timeout-seconds)
                   (cons-atom
                     (CodexAgentJobReapStaleActiveAction
                       $job-id
                       $thread-id
                       $item-id
                       $error-message)
                     $tail-actions))))
             $tail-actions)))))
