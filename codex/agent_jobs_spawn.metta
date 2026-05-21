; Rust-faithful pure agent job pending-worker spawn slice.
;
; This ports deterministic branch behavior from:
; - openai-codex/codex-rs/core/src/tools/handlers/agent_jobs.rs
;
; Covered in this increment:
; - pending-worker spawn gate: cancellation and concurrency slots
; - worker prompt spawn request shape
; - SubAgentSource::Other("agent_job:{job_id}") payload
; - spawn outcome handling for success, AgentLimitReached, and other errors
; - mark-running assignment outcome handling
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust performs async DB queries/mutations and agent-control spawn/shutdown
;   inline while iterating pending items. This pure slice emits the same ordered
;   action plan for each boundary: list-pending request, spawn request,
;   mark-running request, optional shutdown, and active-map insertion. The
;   runtime bridge must execute those actions in order and stop the pending-item
;   loop when this slice returns the break control.
; - Rust maps `TurnEnvironment::selection` just before spawn. This slice accepts
;   the already-selected environment projections so the later runtime bridge can
;   preserve the Rust mapping at the turn boundary.
; - Rust carries a full `Config` spawn config. This slice treats spawn config as
;   an opaque value because this branch only clones and forwards it.

!(import! &self agent_jobs)
!(import! &self agent_jobs_active)
!(import! &self str)

(= (codex:agent-job-spawn-loop-continue)
   (CodexAgentJobSpawnLoopContinue))

(= (codex:agent-job-spawn-loop-break)
   (CodexAgentJobSpawnLoopBreak))

(= (codex:agent-job-spawn-pending-skip)
   (CodexAgentJobSpawnPendingSkip))

(= (codex:agent-job-spawn-pending-list $slots)
   (CodexAgentJobSpawnPendingList $slots))

(= (codex:agent-job-spawn-pending-gate
      $cancel-requested
      $active-count
      $max-concurrency)
   (if $cancel-requested
       (codex:agent-job-spawn-pending-skip)
       (if (< $active-count $max-concurrency)
           (codex:agent-job-spawn-pending-list
             (- $max-concurrency $active-count))
           (codex:agent-job-spawn-pending-skip))))

(= (codex:agent-job-spawn-worker-source $job-id)
   (str-concat "agent_job:" $job-id))

(= (codex:agent-job-spawn-worker-user-input-text $text)
   (CodexAgentJobSpawnWorkerUserInputText $text ()))

(= (codex:agent-job-spawn-worker-user-input-text-text
      (CodexAgentJobSpawnWorkerUserInputText $text $text-elements))
   $text)

(= (codex:agent-job-spawn-worker-request
      $spawn-config
      $items
      $subagent-source-other
      $environment-selections)
   (CodexAgentJobSpawnWorkerRequest
     $spawn-config
     $items
     $subagent-source-other
     $environment-selections))

(= (codex:agent-job-spawn-worker-request-items
      (CodexAgentJobSpawnWorkerRequest
        $spawn-config
        $items
        $subagent-source-other
        $environment-selections))
   $items)

(= (codex:agent-job-spawn-worker-request-source
      (CodexAgentJobSpawnWorkerRequest
        $spawn-config
        $items
        $subagent-source-other
        $environment-selections))
   $subagent-source-other)

(= (codex:agent-job-spawn-worker-request-environments
      (CodexAgentJobSpawnWorkerRequest
        $spawn-config
        $items
        $subagent-source-other
        $environment-selections))
   $environment-selections)

(= (codex:agent-job-spawn-worker-request-first-text
      (CodexAgentJobSpawnWorkerRequest
        $spawn-config
        ((CodexAgentJobSpawnWorkerUserInputText $text $text-elements))
        $subagent-source-other
        $environment-selections))
   $text)

(= (codex:agent-job-build-spawn-worker-request
      $job
      $item
      $spawn-config
      $environment-selections)
   (let $job-id (codex:agent-job-id (once (eval $job)))
     (let $prompt (codex:agent-job-build-worker-prompt $job $item)
       (codex:agent-job-spawn-worker-request
         $spawn-config
         ((codex:agent-job-spawn-worker-user-input-text $prompt))
         (codex:agent-job-spawn-worker-source $job-id)
         $environment-selections))))

(= (codex:agent-job-spawn-worker-ok $thread-id)
   (CodexAgentJobSpawnWorkerOk $thread-id))

(= (codex:agent-job-spawn-worker-agent-limit-reached)
   (CodexAgentJobSpawnWorkerAgentLimitReached))

(= (codex:agent-job-spawn-worker-err $error-display)
   (CodexAgentJobSpawnWorkerErr $error-display))

(= (codex:agent-job-spawn-mark-pending
      $job-id
      $item-id
      $error-message)
   (CodexAgentJobSpawnMarkPending $job-id $item-id $error-message))

(= (codex:agent-job-spawn-mark-failed
      $job-id
      $item-id
      $error-message)
   (CodexAgentJobSpawnMarkFailed $job-id $item-id $error-message))

(= (codex:agent-job-spawn-mark-running-with-thread
      $job-id
      $item-id
      $thread-id)
   (CodexAgentJobSpawnMarkRunningWithThread $job-id $item-id $thread-id))

(= (codex:agent-job-spawn-shutdown-thread $thread-id)
   (CodexAgentJobSpawnShutdownThread $thread-id))

(= (codex:agent-job-spawn-activate-thread
      $thread-id
      $active-item)
   (CodexAgentJobSpawnActivateThread $thread-id $active-item))

(= (codex:agent-job-spawn-item-result
      $progressed
      $loop-control
      $actions)
   (CodexAgentJobSpawnItemResult $progressed $loop-control $actions))

(= (codex:agent-job-spawn-worker-error-message $error-display)
   (str-concat "failed to spawn worker: " $error-display))

(= (codex:agent-job-spawn-item-after-attempt
      $job-id
      $item
      (CodexAgentJobSpawnWorkerAgentLimitReached)
      $assigned
      $now-seconds
      $status-rx)
   (codex:agent-job-spawn-item-result
     False
     (codex:agent-job-spawn-loop-break)
     ((codex:agent-job-spawn-mark-pending
        $job-id
        (codex:agent-job-item-id $item)
        CodexAbsent))))

(= (codex:agent-job-spawn-item-after-attempt
      $job-id
      $item
      (CodexAgentJobSpawnWorkerErr $error-display)
      $assigned
      $now-seconds
      $status-rx)
   (codex:agent-job-spawn-item-result
     True
     (codex:agent-job-spawn-loop-continue)
     ((codex:agent-job-spawn-mark-failed
        $job-id
        (codex:agent-job-item-id $item)
        (codex:agent-job-spawn-worker-error-message $error-display)))))

(= (codex:agent-job-spawn-item-after-attempt
      $job-id
      $item
      (CodexAgentJobSpawnWorkerOk $thread-id)
      False
      $now-seconds
      $status-rx)
   (let $item-id (codex:agent-job-item-id $item)
     (codex:agent-job-spawn-item-result
       False
       (codex:agent-job-spawn-loop-continue)
       ((codex:agent-job-spawn-mark-running-with-thread
          $job-id
          $item-id
          $thread-id)
        (codex:agent-job-spawn-shutdown-thread $thread-id)))))

(= (codex:agent-job-spawn-item-after-attempt
      $job-id
      $item
      (CodexAgentJobSpawnWorkerOk $thread-id)
      True
      $now-seconds
      $status-rx)
   (let $item-id (codex:agent-job-item-id $item)
     (codex:agent-job-spawn-item-result
       True
       (codex:agent-job-spawn-loop-continue)
       ((codex:agent-job-spawn-mark-running-with-thread
          $job-id
          $item-id
          $thread-id)
        (codex:agent-job-spawn-activate-thread
          $thread-id
          (codex:agent-job-active-item
            $item-id
            $now-seconds
            $status-rx))))))
