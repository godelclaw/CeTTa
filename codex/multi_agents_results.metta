; Rust-faithful pure multi-agent tool result/output slice.
;
; This ports deterministic result serialization and ToolOutput behavior from:
; - openai-codex/codex-rs/core/src/tools/handlers/multi_agents/spawn.rs
; - openai-codex/codex-rs/core/src/tools/handlers/multi_agents/send_input.rs
; - openai-codex/codex-rs/core/src/tools/handlers/multi_agents/wait.rs
; - openai-codex/codex-rs/core/src/tools/handlers/multi_agents/resume_agent.rs
; - openai-codex/codex-rs/core/src/tools/handlers/multi_agents/close_agent.rs
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust serializes concrete structs through serde. This slice represents each
;   struct as a CeTTa constructor and projects it to JsonValue before using the
;   shared multi-agent tool-output helpers.
; - Rust `WaitAgentResult.status` is a `HashMap<String, AgentStatus>`. CeTTa
;   uses an ordered list of `CodexMultiAgentWaitStatusEntry`; duplicate keys are
;   outside Rust HashMap semantics.

!(import! &self context)
!(import! &self json)
!(import! &self protocol)
!(import! &self multi_agents_common)

(= (codex:multi-agent-spawn-agent-result $agent-id $nickname)
   (CodexMultiAgentSpawnAgentResult $agent-id $nickname))

(= (codex:multi-agent-send-input-result $submission-id)
   (CodexMultiAgentSendInputResult $submission-id))

(= (codex:multi-agent-wait-status-entry $target $status)
   (CodexMultiAgentWaitStatusEntry $target $status))

(= (codex:multi-agent-wait-agent-result $status-entries $timed-out)
   (CodexMultiAgentWaitAgentResult $status-entries $timed-out))

(= (codex:multi-agent-resume-agent-result $status)
   (CodexMultiAgentResumeAgentResult $status))

(= (codex:multi-agent-close-agent-result $previous-status)
   (CodexMultiAgentCloseAgentResult $previous-status))

(= (codex:multi-agent-json-option-string $value)
   (case $value
     ((CodexAbsent JsonNull)
      ($text (JsonString $text)))))

(= (codex:multi-agent-wait-status-entry-json-pair
      (CodexMultiAgentWaitStatusEntry $target $status))
   (JsonPair $target (codex:protocol-agent-status-json $status)))

(= (codex:multi-agent-wait-status-entries-json-pairs ())
   ())

(= (codex:multi-agent-wait-status-entries-json-pairs $entries)
   (let ($head $tail) (decons-atom $entries)
     (case (codex:multi-agent-wait-status-entries-json-pairs $tail)
       (($tail-pairs
         (cons-atom
           (codex:multi-agent-wait-status-entry-json-pair $head)
           $tail-pairs))))))

(= (codex:multi-agent-spawn-agent-result-json
      (CodexMultiAgentSpawnAgentResult $agent-id $nickname))
   (JsonObject
     ((JsonPair "agent_id" (JsonString $agent-id))
      (JsonPair "nickname" (codex:multi-agent-json-option-string $nickname)))))

(= (codex:multi-agent-send-input-result-json
      (CodexMultiAgentSendInputResult $submission-id))
   (JsonObject
     ((JsonPair "submission_id" (JsonString $submission-id)))))

(= (codex:multi-agent-wait-agent-result-json
      (CodexMultiAgentWaitAgentResult $status-entries $timed-out))
   (JsonObject
     ((JsonPair
        "status"
        (JsonObject
          (codex:multi-agent-wait-status-entries-json-pairs $status-entries)))
      (JsonPair "timed_out" (JsonBool $timed-out)))))

(= (codex:multi-agent-resume-agent-result-json
      (CodexMultiAgentResumeAgentResult $status))
   (JsonObject
     ((JsonPair "status" (codex:protocol-agent-status-json $status)))))

(= (codex:multi-agent-close-agent-result-json
      (CodexMultiAgentCloseAgentResult $previous-status))
   (JsonObject
     ((JsonPair
        "previous_status"
        (codex:protocol-agent-status-json $previous-status)))))

(= (codex:multi-agent-result-json
      (CodexMultiAgentSpawnAgentResult $agent-id $nickname))
   (codex:multi-agent-spawn-agent-result-json
     (CodexMultiAgentSpawnAgentResult $agent-id $nickname)))

(= (codex:multi-agent-result-json
      (CodexMultiAgentSendInputResult $submission-id))
   (codex:multi-agent-send-input-result-json
     (CodexMultiAgentSendInputResult $submission-id)))

(= (codex:multi-agent-result-json
      (CodexMultiAgentWaitAgentResult $status-entries $timed-out))
   (codex:multi-agent-wait-agent-result-json
     (CodexMultiAgentWaitAgentResult $status-entries $timed-out)))

(= (codex:multi-agent-result-json
      (CodexMultiAgentResumeAgentResult $status))
   (codex:multi-agent-resume-agent-result-json
     (CodexMultiAgentResumeAgentResult $status)))

(= (codex:multi-agent-result-json
      (CodexMultiAgentCloseAgentResult $previous-status))
   (codex:multi-agent-close-agent-result-json
     (CodexMultiAgentCloseAgentResult $previous-status)))

(= (codex:multi-agent-result-log-preview $result $tool-name)
   (codex:multi-agent-tool-output-json-text
     (codex:multi-agent-result-json $result)
     $tool-name))

(= (codex:multi-agent-result-success-for-logging $result)
   True)

(= (codex:multi-agent-result-to-response-item
      $result
      $call-id
      $payload
      $success
      $tool-name)
   (codex:multi-agent-tool-output-response-item
     $call-id
     $payload
     (codex:multi-agent-result-json $result)
     $success
     $tool-name))

(= (codex:multi-agent-result-code-mode-result $result $tool-name)
   (codex:multi-agent-tool-output-code-mode-result
     (codex:multi-agent-result-json $result)
     $tool-name))

(= (codex:multi-agent-spawn-agent-result-log-preview $result)
   (codex:multi-agent-result-log-preview $result "spawn_agent"))

(= (codex:multi-agent-spawn-agent-result-success-for-logging $result)
   (codex:multi-agent-result-success-for-logging $result))

(= (codex:multi-agent-spawn-agent-result-to-response-item
      $result
      $call-id
      $payload)
   (codex:multi-agent-result-to-response-item
     $result
     $call-id
     $payload
     True
     "spawn_agent"))

(= (codex:multi-agent-spawn-agent-result-code-mode-result $result)
   (codex:multi-agent-result-code-mode-result $result "spawn_agent"))

(= (codex:multi-agent-send-input-result-log-preview $result)
   (codex:multi-agent-result-log-preview $result "send_input"))

(= (codex:multi-agent-send-input-result-success-for-logging $result)
   (codex:multi-agent-result-success-for-logging $result))

(= (codex:multi-agent-send-input-result-to-response-item
      $result
      $call-id
      $payload)
   (codex:multi-agent-result-to-response-item
     $result
     $call-id
     $payload
     True
     "send_input"))

(= (codex:multi-agent-send-input-result-code-mode-result $result)
   (codex:multi-agent-result-code-mode-result $result "send_input"))

(= (codex:multi-agent-wait-agent-result-log-preview $result)
   (codex:multi-agent-result-log-preview $result "wait_agent"))

(= (codex:multi-agent-wait-agent-result-success-for-logging $result)
   (codex:multi-agent-result-success-for-logging $result))

(= (codex:multi-agent-wait-agent-result-to-response-item
      $result
      $call-id
      $payload)
   (codex:multi-agent-result-to-response-item
     $result
     $call-id
     $payload
     CodexAbsent
     "wait_agent"))

(= (codex:multi-agent-wait-agent-result-code-mode-result $result)
   (codex:multi-agent-result-code-mode-result $result "wait_agent"))

(= (codex:multi-agent-resume-agent-result-log-preview $result)
   (codex:multi-agent-result-log-preview $result "resume_agent"))

(= (codex:multi-agent-resume-agent-result-success-for-logging $result)
   (codex:multi-agent-result-success-for-logging $result))

(= (codex:multi-agent-resume-agent-result-to-response-item
      $result
      $call-id
      $payload)
   (codex:multi-agent-result-to-response-item
     $result
     $call-id
     $payload
     True
     "resume_agent"))

(= (codex:multi-agent-resume-agent-result-code-mode-result $result)
   (codex:multi-agent-result-code-mode-result $result "resume_agent"))

(= (codex:multi-agent-close-agent-result-log-preview $result)
   (codex:multi-agent-result-log-preview $result "close_agent"))

(= (codex:multi-agent-close-agent-result-success-for-logging $result)
   (codex:multi-agent-result-success-for-logging $result))

(= (codex:multi-agent-close-agent-result-to-response-item
      $result
      $call-id
      $payload)
   (codex:multi-agent-result-to-response-item
     $result
     $call-id
     $payload
     True
     "close_agent"))

(= (codex:multi-agent-close-agent-result-code-mode-result $result)
   (codex:multi-agent-result-code-mode-result $result "close_agent"))
