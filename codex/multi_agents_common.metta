; Rust-faithful pure multi-agent handler common helper slice.
;
; This ports deterministic helper behavior from:
; - openai-codex/codex-rs/core/src/tools/handlers/multi_agents_common.rs
;
; Covered in this increment:
; - wait timeout constants
; - function_arguments
; - build_wait_agent_statuses ordering
; - collab_spawn_error / collab_agent_error display mapping
; - thread_spawn_source
; - parse_collab_input
; - reject_full_fork_spawn_overrides
; - find_spawn_agent_model_name / validate_spawn_agent_reasoning_effort
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust receives `HashMap<ThreadId, AgentStatus>` for status lookup. This pure
;   CeTTa slice uses `CodexMultiAgentStatusEntry` lists with the same lookup
;   contract; duplicate keys are outside Rust `HashMap` semantics.
; - Rust receives full `CodexErr` and model preset structs. This slice exposes
;   the concrete error variants and model/reasoning strings needed by the
;   ported branch table, preserving the exact visible `FunctionCallError`
;   messages.
; - Rust mutates `Config` for runtime/model overrides. Those side-effecting
;   helpers remain with a later config/session port; this slice covers the
;   pure validation helpers those branches call.

!(import! &self agent_path)
!(import! &self context)
!(import! &self function_tool)
!(import! &self list)
!(import! &self protocol)
!(import! &self str)

(= (codex:multi-agent-min-wait-timeout-ms)
   10000)

(= (codex:multi-agent-default-wait-timeout-ms)
   30000)

(= (codex:multi-agent-max-wait-timeout-ms)
   3600000)

(= (codex:multi-agent-common-ok $value)
   (CodexMultiAgentCommonOk $value))

(= (codex:multi-agent-common-err $error)
   (CodexMultiAgentCommonErr $error))

(= (codex:multi-agent-function-arguments $payload)
   (case $payload
     (((CodexToolPayloadFunction $arguments)
       (codex:multi-agent-common-ok $arguments))
      ($other
       (codex:multi-agent-common-err
         (codex:function-call-error-respond-to-model
           "collab handler received unsupported payload"))))))

(= (codex:multi-agent-status-map-entry $thread-id $status)
   (CodexMultiAgentStatusEntry $thread-id $status))

(= (codex:multi-agent-status-map-entry-thread-id
      (CodexMultiAgentStatusEntry $thread-id $status))
   $thread-id)

(= (codex:multi-agent-status-map-entry-status
      (CodexMultiAgentStatusEntry $thread-id $status))
   $status)

(= (codex:multi-agent-status-lookup () $thread-id)
   CodexAbsent)

(= (codex:multi-agent-status-lookup $statuses $thread-id)
   (let $head (list:first $statuses)
     (let $tail (list:rest $statuses)
       (if (== (codex:multi-agent-status-map-entry-thread-id $head) $thread-id)
           (codex:multi-agent-status-map-entry-status $head)
           (codex:multi-agent-status-lookup $tail $thread-id)))))

(= (codex:multi-agent-string-list-contains () $needle)
   False)

(= (codex:multi-agent-string-list-contains $items $needle)
   (let $head (list:first $items)
     (let $tail (list:rest $items)
       (if (== $head $needle)
           True
           (codex:multi-agent-string-list-contains $tail $needle)))))

(= (codex:multi-agent-receiver-thread-ids ())
   ())

(= (codex:multi-agent-receiver-thread-ids $receiver-agents)
   (let ($head $tail) (decons-atom $receiver-agents)
     (case (codex:multi-agent-receiver-thread-ids $tail)
       (($tail-thread-ids
         ; CeTTa evaluation accommodation: materialize the recursive tail
         ; before consing so imported callers receive a concrete list, matching
         ; Rust's Vec collection behavior.
         (case $head
           (((CodexCollabAgentRef $thread-id $agent-nickname $agent-role)
             (cons-atom $thread-id $tail-thread-ids))
            ((codex:collab-agent-ref $thread-id $agent-nickname $agent-role)
             (cons-atom $thread-id $tail-thread-ids)))))))))

(= (codex:multi-agent-receiver-status-entries () $statuses)
   ())

(= (codex:multi-agent-receiver-status-entry-from-ref
      (CodexCollabAgentRef $thread-id $agent-nickname $agent-role)
      $statuses
      $tail-entries)
   (case (codex:multi-agent-status-lookup $statuses $thread-id)
     ((CodexAbsent $tail-entries)
      ($status
       (cons-atom
         (codex:collab-agent-status-entry
           $thread-id
           $agent-nickname
           $agent-role
           $status)
         $tail-entries)))))

(= (codex:multi-agent-receiver-status-entry-from-ref
      (codex:collab-agent-ref $thread-id $agent-nickname $agent-role)
      $statuses
      $tail-entries)
   (case (codex:multi-agent-status-lookup $statuses $thread-id)
     ((CodexAbsent $tail-entries)
      ($status
       (cons-atom
         (codex:collab-agent-status-entry
           $thread-id
           $agent-nickname
           $agent-role
           $status)
         $tail-entries)))))

(= (codex:multi-agent-receiver-status-entries $receiver-agents $statuses)
   (let ($head $tail) (decons-atom $receiver-agents)
     (case (codex:multi-agent-receiver-status-entries $tail $statuses)
       (($tail-entries
         (codex:multi-agent-receiver-status-entry-from-ref
           $head
           $statuses
           $tail-entries))))))

(= (codex:multi-agent-extra-status-thread-ids () $seen-thread-ids)
   ())

(= (codex:multi-agent-extra-status-thread-ids $statuses $seen-thread-ids)
   (let ($head $tail) (decons-atom $statuses)
     (let $thread-id
       (codex:multi-agent-status-map-entry-thread-id $head)
       (case (codex:multi-agent-extra-status-thread-ids $tail $seen-thread-ids)
         (($rest
           (case
             (codex:multi-agent-string-list-contains
               $seen-thread-ids
               $thread-id)
             ((True $rest)
              (False (cons-atom $thread-id $rest))))))))))

(= (codex:multi-agent-extra-status-entries-from-thread-ids
      $statuses
      ())
   ())

(= (codex:multi-agent-extra-status-entries-from-thread-ids
      $statuses
      $thread-ids)
   (let ($thread-id $tail) (decons-atom $thread-ids)
     (case (codex:multi-agent-extra-status-entries-from-thread-ids
             $statuses
             $tail)
       (($tail-entries
         (case (codex:multi-agent-status-lookup $statuses $thread-id)
           ((CodexAbsent $tail-entries)
            ($status
             (cons-atom
               (codex:collab-agent-status-entry
                 $thread-id
                 CodexAbsent
                 CodexAbsent
                 $status)
               $tail-entries)))))))))

(= (codex:multi-agent-extra-status-entries $statuses $receiver-agents)
   (let $seen-thread-ids
     (once (eval (codex:multi-agent-receiver-thread-ids $receiver-agents)))
     (let $extra-thread-ids
       (once
         (eval
           (codex:multi-agent-extra-status-thread-ids
             $statuses
             $seen-thread-ids)))
       (case (sort-strings $extra-thread-ids)
         (($sorted-thread-ids
           (codex:multi-agent-extra-status-entries-from-thread-ids
             $statuses
             $sorted-thread-ids)))))))

(= (codex:multi-agent-build-wait-agent-statuses
      ()
      $receiver-agents)
   ())

(= (codex:multi-agent-build-wait-agent-statuses
      $statuses
      $receiver-agents)
   (let $receiver-entries
     (once
       (eval
         (codex:multi-agent-receiver-status-entries
           $receiver-agents
           $statuses)))
     (let $extra-entries
       (once
         (eval
           (codex:multi-agent-extra-status-entries
             $statuses
             $receiver-agents)))
       (list:append $receiver-entries $extra-entries))))

(= (codex:multi-agent-codex-err-unsupported-operation $message)
   (CodexErrUnsupportedOperation $message))

(= (codex:multi-agent-codex-err-thread-not-found $thread-id)
   (CodexErrThreadNotFound $thread-id))

(= (codex:multi-agent-codex-err-internal-agent-died)
   (CodexErrInternalAgentDied))

(= (codex:multi-agent-codex-err-other $display)
   (CodexErrOther $display))

(= (codex:multi-agent-codex-err-display
      (CodexErrUnsupportedOperation $message))
   (str-concat "unsupported operation: " $message))

(= (codex:multi-agent-codex-err-display
      (CodexErrThreadNotFound $thread-id))
   (str-concat "no thread with id: " $thread-id))

(= (codex:multi-agent-codex-err-display
      (CodexErrInternalAgentDied))
   "internal error; agent loop died unexpectedly")

(= (codex:multi-agent-codex-err-display
      (CodexErrOther $display))
   $display)

(= (codex:multi-agent-collab-spawn-error $err)
   (case $err
     (((CodexErrUnsupportedOperation "thread manager dropped")
       (codex:function-call-error-respond-to-model
         "collab manager unavailable"))
      ((CodexErrUnsupportedOperation $message)
       (codex:function-call-error-respond-to-model $message))
      ($other
       (codex:function-call-error-respond-to-model
         (str-concat
           "collab spawn failed: "
           (codex:multi-agent-codex-err-display $other)))))))

(= (codex:multi-agent-collab-agent-error $agent-id $err)
   (case $err
     (((CodexErrThreadNotFound $thread-id)
       (codex:function-call-error-respond-to-model
         (str-concat "agent with id " (str-concat $thread-id " not found"))))
      ((CodexErrInternalAgentDied)
       (codex:function-call-error-respond-to-model
         (str-concat "agent with id " (str-concat $agent-id " is closed"))))
      ((CodexErrUnsupportedOperation $message)
       (codex:function-call-error-respond-to-model
         "collab manager unavailable"))
      ($other
       (codex:function-call-error-respond-to-model
         (str-concat
           "collab tool failed: "
           (codex:multi-agent-codex-err-display $other)))))))

(= (codex:multi-agent-parent-agent-path-or-root $parent-session-source)
   (case (codex:session-source-get-agent-path $parent-session-source)
     ((CodexAbsent (codex:agent-path-root))
      ($agent-path $agent-path))))

(= (codex:multi-agent-thread-spawn-agent-path
      $parent-session-source
      $task-name)
   (case $task-name
     ((CodexAbsent
       (codex:multi-agent-common-ok CodexAbsent))
      ($name
       (let $parent-path
         (codex:multi-agent-parent-agent-path-or-root $parent-session-source)
         (case (codex:agent-path-join $parent-path $name)
           (((CodexAgentPathOk $agent-path)
             (codex:multi-agent-common-ok $agent-path))
            ((CodexAgentPathErr $message)
             (codex:multi-agent-common-err
               (codex:function-call-error-respond-to-model $message))))))))))

(= (codex:multi-agent-thread-spawn-source
      $parent-thread-id
      $parent-session-source
      $depth
      $agent-role
      $task-name)
   (case
     (codex:multi-agent-thread-spawn-agent-path
       $parent-session-source
       $task-name)
     (((CodexMultiAgentCommonOk $agent-path)
       (codex:multi-agent-common-ok
         (codex:session-source-subagent
           (codex:subagent-source-thread-spawn
             $parent-thread-id
             $depth
             $agent-path
             CodexAbsent
             $agent-role))))
      ((CodexMultiAgentCommonErr $error)
       (codex:multi-agent-common-err $error)))))

(= (codex:multi-agent-parse-collab-input $message $items)
   (if (and (not (== $message CodexAbsent))
            (not (== $items CodexAbsent)))
       (codex:multi-agent-common-err
         (codex:function-call-error-respond-to-model
           "Provide either message or items, but not both"))
       (if (and (== $message CodexAbsent)
                (== $items CodexAbsent))
           (codex:multi-agent-common-err
             (codex:function-call-error-respond-to-model
               "Provide one of: message or items"))
           (if (not (== $message CodexAbsent))
               (if (== (str-trim $message) "")
                   (codex:multi-agent-common-err
                     (codex:function-call-error-respond-to-model
                       "Empty message can't be sent to an agent"))
                   (codex:multi-agent-common-ok
                     (codex:user-input-op
                       ((codex:user-input-text $message)))))
               (if (== $items ())
                   (codex:multi-agent-common-err
                     (codex:function-call-error-respond-to-model
                       "Items can't be empty"))
                   (codex:multi-agent-common-ok
                     (codex:user-input-op $items)))))))

(= (codex:multi-agent-reject-full-fork-spawn-overrides
      $agent-type
      $model
      $reasoning-effort)
   (if (or (not (== $agent-type CodexAbsent))
           (or (not (== $model CodexAbsent))
               (not (== $reasoning-effort CodexAbsent))))
       (codex:multi-agent-common-err
         (codex:function-call-error-respond-to-model
           "Full-history forked agents inherit the parent agent type, model, and reasoning effort; omit agent_type, model, and reasoning_effort, or spawn without a full-history fork."))
       (codex:multi-agent-common-ok ())))

(= (codex:multi-agent-model-list-contains () $requested-model)
   False)

(= (codex:multi-agent-model-list-contains $available-models $requested-model)
   (let $head (list:first $available-models)
     (let $tail (list:rest $available-models)
       (if (== $head $requested-model)
           True
           (codex:multi-agent-model-list-contains $tail $requested-model)))))

(= (codex:multi-agent-find-spawn-agent-model-name
      $available-models
      $requested-model)
   (case
     (codex:multi-agent-model-list-contains
       $available-models
       $requested-model)
     ((True
       (codex:multi-agent-common-ok $requested-model))
      (False
       (codex:multi-agent-common-err
         (codex:function-call-error-respond-to-model
           (format-args
             "Unknown model `{}` for spawn_agent. Available models: {}"
             ($requested-model (str-join ", " $available-models)))))))))

(= (codex:multi-agent-validate-spawn-agent-reasoning-effort
      $model
      $supported-reasoning-levels
      $requested-reasoning-effort)
   (case
     (codex:multi-agent-string-list-contains
       $supported-reasoning-levels
       $requested-reasoning-effort)
     ((True
       (codex:multi-agent-common-ok ()))
      (False
       (codex:multi-agent-common-err
         (codex:function-call-error-respond-to-model
           (format-args
             "Reasoning effort `{}` is not supported for model `{}`. Supported reasoning efforts: {}"
             ($requested-reasoning-effort
              $model
              (str-join ", " $supported-reasoning-levels)))))))))
