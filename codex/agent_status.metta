; Rust-faithful agent status reducer slice.
;
; This ports the pure helper behavior from:
; - openai-codex/codex-rs/core/src/agent/status.rs
;
; Covered in this increment:
; - agent_status_from_event
; - is_final

!(import! &self protocol)

(= (codex:agent-status-from-event $event)
   (case (once (eval $event))
     (((CodexEventTurnStarted
         $turn-id
         $started-at
         $model-context-window
         $collaboration-mode-kind)
       (codex:protocol-agent-status-running))
      ((CodexEventTurnComplete
         $turn-id
         $last-agent-message
         $completed-at
         $duration-ms
         $time-to-first-token-ms)
       (codex:protocol-agent-status-completed $last-agent-message))
      ((CodexEventTurnAborted
         $turn-id
         (CodexTurnAbortReasonInterrupted)
         $completed-at
         $duration-ms)
       (codex:protocol-agent-status-interrupted))
      ((CodexEventTurnAborted
         $turn-id
         $reason
         $completed-at
         $duration-ms)
       (codex:protocol-agent-status-errored
         (codex:turn-abort-reason-debug $reason)))
      ((CodexEventError $message $codex-error-info)
       (codex:protocol-agent-status-errored $message))
      ((CodexEventShutdownComplete)
       (codex:protocol-agent-status-shutdown))
      ($other CodexAbsent))))

(= (codex:turn-abort-reason-debug (CodexTurnAbortReasonInterrupted))
   "Interrupted")

(= (codex:turn-abort-reason-debug (CodexTurnAbortReasonReplaced))
   "Replaced")

(= (codex:turn-abort-reason-debug (CodexTurnAbortReasonReviewEnded))
   "ReviewEnded")

(= (codex:is-agent-status-final $status)
   (case (once (eval $status))
     (((CodexProtocolAgentStatusPendingInit)
       False)
      ((CodexProtocolAgentStatusRunning)
       False)
      ((CodexProtocolAgentStatusInterrupted)
       False)
      ($other True))))
