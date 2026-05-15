; Narrow Rust-faithful session-prefix helper slice.
;
; This ports:
; - openai-codex/codex-rs/core/src/session_prefix.rs
;
; Covered in this increment:
; - format_subagent_notification_message
; - format_subagent_context_line
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust uses `Option<&str>` for `agent_nickname`. The current CeTTa port keeps
;   the same visible behavior and uses `CodexAbsent` for the absent branch.

!(import! &self context_fragment)

(= (codex:format-subagent-notification-message $agent-reference $status)
   (codex:contextual-fragment-render
     (codex:subagent-notification $agent-reference $status)))

(= (codex:format-subagent-context-line $agent-reference $agent-nickname)
   (if (== $agent-nickname CodexAbsent)
       (format-args "- {}" ($agent-reference))
       (if (== $agent-nickname "")
           (format-args "- {}" ($agent-reference))
           (format-args "- {}: {}" ($agent-reference $agent-nickname)))))
