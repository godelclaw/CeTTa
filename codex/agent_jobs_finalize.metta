; Rust-faithful pure agent job finished-item finalization slice.
;
; This ports deterministic branch behavior from:
; - openai-codex/codex-rs/core/src/tools/handlers/agent_jobs.rs
;
; Covered in this increment:
; - missing job item finalization error
; - running item with result_json -> mark completed
; - running item without result_json -> mark failed with Rust's exact message
; - non-running item -> no item status mutation
; - successful finalization always plans live-agent shutdown
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust `finalize_finished_item` performs DB lookup, conditional DB mutation,
;   and live-agent shutdown inline. This pure slice receives the looked-up item
;   as `CodexAbsent` or an `AgentJobItem` projection and emits the exact
;   mutation/shutdown plan; the runtime bridge must execute the DB mutation
;   before shutdown just as Rust does.

!(import! &self agent_jobs)

(= (codex:agent-job-finalize-ok $plan)
   (CodexAgentJobFinalizeOk $plan))

(= (codex:agent-job-finalize-err $message)
   (CodexAgentJobFinalizeErr $message))

(= (codex:agent-job-finalize-mark-completed $job-id $item-id)
   (CodexAgentJobFinalizeMarkCompleted $job-id $item-id))

(= (codex:agent-job-finalize-mark-failed
      $job-id
      $item-id
      $error-message)
   (CodexAgentJobFinalizeMarkFailed $job-id $item-id $error-message))

(= (codex:agent-job-finalize-plan $item-action $shutdown-thread-id)
   (CodexAgentJobFinalizePlan $item-action $shutdown-thread-id))

(= (codex:agent-job-finalize-plan-item-action
      (CodexAgentJobFinalizePlan $item-action $shutdown-thread-id))
   $item-action)

(= (codex:agent-job-finalize-plan-shutdown-thread-id
      (CodexAgentJobFinalizePlan $item-action $shutdown-thread-id))
   $shutdown-thread-id)

(= (codex:agent-job-finalize-missing-item-error $job-id $item-id)
   (format-args
     "job item not found for finalization: {}/{}"
     ($job-id $item-id)))

(= (codex:agent-job-finalize-missing-result-error)
   "worker finished without calling report_agent_job_result")

(= (codex:agent-job-finalize-item-action $job-id $item-id $item)
   (if (== (codex:agent-job-item-status $item)
           (codex:agent-job-item-status-running))
       (if (== (codex:agent-job-item-result-json $item) CodexAbsent)
           (codex:agent-job-finalize-mark-failed
             $job-id
             $item-id
             (codex:agent-job-finalize-missing-result-error))
           (codex:agent-job-finalize-mark-completed $job-id $item-id))
       CodexAbsent))

(= (codex:agent-job-finalize-finished-item
      $job-id
      $item-id
      $thread-id
      $item)
   (case $item
     ((CodexAbsent
       (codex:agent-job-finalize-err
         (codex:agent-job-finalize-missing-item-error $job-id $item-id)))
      ($found-item
       (codex:agent-job-finalize-ok
         (codex:agent-job-finalize-plan
           (codex:agent-job-finalize-item-action
             $job-id
             $item-id
             $found-item)
           $thread-id))))))
