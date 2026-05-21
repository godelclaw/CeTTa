; Rust-faithful pure agent job loop iteration slice.
;
; This ports deterministic branch behavior from:
; - openai-codex/codex-rs/core/src/tools/handlers/agent_jobs.rs
;
; Covered in this increment:
; - missing job lookup error
; - initial loop setup action order after the job is loaded
; - cancellation poll result handling and notification text
; - pending-worker spawn gate based on cancellation and active item count
; - no-finished-thread break/wait/continue decision
; - finished-thread finalization/removal/progress-emission action order
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust mutates an async `HashMap<ThreadId, ActiveJobItem>`, performs DB
;   queries/mutations, awaits status changes, and emits progress inline. This
;   pure slice receives immutable snapshots and emits the same ordered action
;   plan. The runtime bridge must execute these actions in order and feed the
;   resulting DB/progress/status facts back into the next pure decision.
; - Rust does not define an ordering guarantee for `HashMap` iteration. This
;   slice accepts ordered active/finished snapshots from the runtime bridge; the
;   bridge is responsible for preserving whatever order it observes when
;   matching Rust behavior for a concrete run.

!(import! &self agent_jobs)
!(import! &self agent_jobs_active)
!(import! &self agent_jobs_completion)
!(import! &self agent_jobs_spawn)
!(import! &self list)
!(import! &self str)

(= (codex:agent-job-loop-control-break)
   (CodexAgentJobLoopControlBreak))

(= (codex:agent-job-loop-control-continue)
   (CodexAgentJobLoopControlContinue))

(= (codex:agent-job-loop-job-not-found-error $job-id)
   (format-args "agent job {} was not found" ($job-id)))

(= (codex:agent-job-loop-recover-running-items
      $job-id
      $runtime-timeout-seconds)
   (CodexAgentJobLoopRecoverRunningItems
     $job-id
     $runtime-timeout-seconds))

(= (codex:agent-job-loop-load-progress $job-id)
   (CodexAgentJobLoopLoadProgress $job-id))

(= (codex:agent-job-loop-emit-loaded-progress $job-id $force)
   (CodexAgentJobLoopEmitLoadedProgress $job-id $force))

(= (codex:agent-job-loop-check-cancelled $job-id)
   (CodexAgentJobLoopCheckCancelled $job-id))

(= (codex:agent-job-loop-skip-cancelled-check)
   (CodexAgentJobLoopSkipCancelledCheck))

(= (codex:agent-job-loop-start-plan-value
      $runtime-timeout-seconds
      $actions)
   (CodexAgentJobLoopStartPlan
     $runtime-timeout-seconds
     $actions))

(= (codex:agent-job-loop-start-plan $job-id CodexAbsent)
   (codex:agent-job-err
     (codex:agent-job-loop-job-not-found-error $job-id)))

(= (codex:agent-job-loop-start-plan
      $job-id
      (CodexAgentJob
        $id
        $name
        $status
        $instruction
        $auto-export
        $max-runtime-seconds
        $output-schema-json
        $input-headers
        $input-csv-path
        $output-csv-path
        $created-at
        $updated-at
        $started-at
        $completed-at
        $last-error))
   (let $runtime-timeout-seconds
     (if (== $max-runtime-seconds CodexAbsent)
         (codex:agent-job-default-item-timeout-seconds)
         $max-runtime-seconds)
     (codex:agent-job-ok
       (codex:agent-job-loop-start-plan-value
         $runtime-timeout-seconds
         ((CodexAgentJobLoopRecoverRunningItems
            $job-id
            $runtime-timeout-seconds)
          (CodexAgentJobLoopLoadProgress $job-id)
          (CodexAgentJobLoopEmitLoadedProgress $job-id True)
          (CodexAgentJobLoopCheckCancelled $job-id))))))

(= (codex:agent-job-loop-cancellation-message $job-id)
   (format-args
     "agent job {} cancellation requested; stopping new workers"
     ($job-id)))

(= (codex:agent-job-loop-cancellation-state $cancel-requested $actions)
   (CodexAgentJobLoopCancellationState $cancel-requested $actions))

(= (codex:agent-job-loop-cancellation-poll-action
      $job-id
      True)
   (CodexAgentJobLoopSkipCancelledCheck))

(= (codex:agent-job-loop-cancellation-poll-action
      $job-id
      False)
   (CodexAgentJobLoopCheckCancelled $job-id))

(= (codex:agent-job-loop-cancellation-after-poll
      $job-id
      True
      $db-cancelled)
   (codex:agent-job-loop-cancellation-state True ()))

(= (codex:agent-job-loop-cancellation-after-poll
      $job-id
      False
      True)
   (codex:agent-job-loop-cancellation-state
     True
     ((CodexAgentJobLoopNotify
        (codex:agent-job-loop-cancellation-message $job-id)))))

(= (codex:agent-job-loop-cancellation-after-poll
      $job-id
      False
      False)
   (codex:agent-job-loop-cancellation-state False ()))

(= (codex:agent-job-loop-spawn-pending-gate
      $cancel-requested
      $active-items
      $max-concurrency)
   (codex:agent-job-spawn-pending-gate
     $cancel-requested
     (size-atom $active-items)
     $max-concurrency))

(= (codex:agent-job-loop-wait-for-status-change $wait-plan)
   (CodexAgentJobLoopWaitForStatusChange $wait-plan))

(= (codex:agent-job-loop-no-finished-decision $control $actions)
   (CodexAgentJobLoopNoFinishedDecision $control $actions))

(= (codex:agent-job-loop-no-finished-should-break
      $cancel-requested
      $progress
      $active-items)
   (if (== $active-items ())
       (if $cancel-requested
           (== (codex:agent-job-progress-running-items $progress) 0)
           (if (== (codex:agent-job-progress-pending-items $progress) 0)
               (== (codex:agent-job-progress-running-items $progress) 0)
               False))
       False))

(= (codex:agent-job-loop-no-finished-plan
      $cancel-requested
      $progress
      $active-items
      $progressed)
   (if (codex:agent-job-loop-no-finished-should-break
         $cancel-requested
         $progress
         $active-items)
       (codex:agent-job-loop-no-finished-decision
         (codex:agent-job-loop-control-break)
         ())
       (if $progressed
           (codex:agent-job-loop-no-finished-decision
             (codex:agent-job-loop-control-continue)
             ())
           (codex:agent-job-loop-no-finished-decision
             (codex:agent-job-loop-control-continue)
             ((CodexAgentJobLoopWaitForStatusChange
                (codex:agent-job-wait-for-status-change-plan
                  $active-items)))))))

(= (codex:agent-job-loop-finalize-finished-item
      $job-id
      $item-id
      $thread-id)
   (CodexAgentJobLoopFinalizeFinishedItem
     $job-id
     $item-id
     $thread-id))

(= (codex:agent-job-loop-remove-active-thread $thread-id)
   (CodexAgentJobLoopRemoveActiveThread $thread-id))

(= (codex:agent-job-loop-finished-plan-value $actions)
   (CodexAgentJobLoopFinishedPlan $actions))

(= (codex:agent-job-loop-finished-actions $job-id ())
   ())

(= (codex:agent-job-loop-finished-actions $job-id $finished)
   (let ($finished-thread $tail) (decons-atom $finished)
     (let $materialized-finished-thread (once (eval $finished-thread))
       (case $materialized-finished-thread
         (((CodexAgentJobFinishedThread $thread-id $item-id)
           (list:append
             ((CodexAgentJobLoopFinalizeFinishedItem
                $job-id
                $item-id
                $thread-id)
              (CodexAgentJobLoopRemoveActiveThread $thread-id)
              (CodexAgentJobLoopLoadProgress $job-id)
              (CodexAgentJobLoopEmitLoadedProgress $job-id False))
             (codex:agent-job-loop-finished-actions $job-id $tail))))))))

(= (codex:agent-job-loop-finished-plan $job-id $finished)
   (case (codex:agent-job-loop-finished-actions $job-id $finished)
     (($actions
       (CodexAgentJobLoopFinishedPlan $actions)))))
