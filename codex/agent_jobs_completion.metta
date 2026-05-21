; Rust-faithful pure agent job loop completion slice.
;
; This ports deterministic branch behavior from:
; - openai-codex/codex-rs/core/src/tools/handlers/agent_jobs.rs
;
; Covered in this increment:
; - post-loop auto-export error handling
; - cancellation message and forced progress emission
; - failed-item completion notification
; - final mark-completed and forced progress emission
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust has already fetched progress, then performs auto-export, optionally
;   queries cancellation again, mutates DB state, notifies the session, and
;   invokes the progress emitter inline. This pure slice receives the export
;   result, cancellation facts, and post-completion progress explicitly and
;   emits the same ordered action plan for the runtime bridge to execute.

!(import! &self agent_jobs)
!(import! &self str)

(= (codex:agent-job-loop-export-ok)
   (CodexAgentJobLoopExportOk))

(= (codex:agent-job-loop-export-err $error-display)
   (CodexAgentJobLoopExportErr $error-display))

(= (codex:agent-job-loop-notify $message)
   (CodexAgentJobLoopNotify $message))

(= (codex:agent-job-loop-mark-job-failed $job-id $error-message)
   (CodexAgentJobLoopMarkJobFailed $job-id $error-message))

(= (codex:agent-job-loop-mark-job-completed $job-id)
   (CodexAgentJobLoopMarkJobCompleted $job-id))

(= (codex:agent-job-loop-emit-progress $progress $force)
   (CodexAgentJobLoopEmitProgress $progress $force))

(= (codex:agent-job-loop-completion-actions $actions)
   (CodexAgentJobLoopCompletionActions $actions))

(= (codex:agent-job-loop-auto-export-error-message $error-display)
   (str-concat "auto-export failed: " $error-display))

(= (codex:agent-job-loop-cancelled-message $job-id $pending-items)
   (format-args
     "agent job {} cancelled with {} unprocessed items"
     ($job-id $pending-items)))

(= (codex:agent-job-loop-failed-items-message $failed-items)
   (format-args
     "agent job completed with {} failed items"
     ($failed-items)))

(= (codex:agent-job-loop-cancelled $cancel-requested $db-cancelled)
   (if $cancel-requested True $db-cancelled))

(= (codex:agent-job-loop-completion-plan
      $job-id
      $progress-before-export
      (CodexAgentJobLoopExportErr $error-display)
      $cancel-requested
      $db-cancelled
      $progress-after-complete)
   (codex:agent-job-loop-completion-actions
     ((CodexAgentJobLoopMarkJobFailed
        $job-id
        (codex:agent-job-loop-auto-export-error-message $error-display)))))

(= (codex:agent-job-loop-completion-plan
      $job-id
      $progress-before-export
      (CodexAgentJobLoopExportOk)
      $cancel-requested
      $db-cancelled
      $progress-after-complete)
   (if (codex:agent-job-loop-cancelled $cancel-requested $db-cancelled)
       (codex:agent-job-loop-completion-actions
         ((CodexAgentJobLoopNotify
            (codex:agent-job-loop-cancelled-message
              $job-id
              (codex:agent-job-progress-pending-items
                $progress-before-export)))
          (CodexAgentJobLoopEmitProgress $progress-before-export True)))
       (let $failed-items
         (codex:agent-job-progress-failed-items $progress-before-export)
         (if (> $failed-items 0)
             (codex:agent-job-loop-completion-actions
               ((CodexAgentJobLoopNotify
                  (codex:agent-job-loop-failed-items-message $failed-items))
                (CodexAgentJobLoopMarkJobCompleted $job-id)
                (CodexAgentJobLoopEmitProgress
                  $progress-after-complete
                  True)))
             (codex:agent-job-loop-completion-actions
               ((CodexAgentJobLoopMarkJobCompleted $job-id)
                (CodexAgentJobLoopEmitProgress
                  $progress-after-complete
                  True)))))))
