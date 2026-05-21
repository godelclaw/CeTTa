!(register-module! ../codex)
!(import! &self codex:agent_control)
!(import! &self codex:agent_path)
!(import! &self codex:agent_registry)
!(import! &self codex:agent_role)
!(import! &self codex:error)
!(import! &self codex:protocol)
!(import! &self codex:thread_rollout_truncation)

(= (test:root-thread)
   "00000000-0000-0000-0000-000000000001")

(= (test:scout-thread)
   "00000000-0000-0000-0000-000000000002")

(= (test:tester-thread)
   "00000000-0000-0000-0000-000000000003")

(= (test:alpha-thread)
   "00000000-0000-0000-0000-000000000004")

(= (test:missing-thread)
   "00000000-0000-0000-0000-000000000005")

(= (test:anonymous-thread)
   "00000000-0000-0000-0000-000000000006")

(= (test:exec-thread)
   "00000000-0000-0000-0000-000000000007")

(= (test:scout-path)
   (codex:agent-path "/root/scout"))

(= (test:tester-path)
   (codex:agent-path "/root/scout/tester"))

(= (test:alpha-path)
   (codex:agent-path "/root/alpha"))

(= (test:research-role-entry)
   (codex:agent-role-entry
     "researcher"
     (codex:agent-role-config
       "Research role"
       CodexAbsent
       ("Atlas"))))

(= (test:prepared-spawn-check
      $reserved-agent-path
      $reserved-agent-nickname
      $session-source
      $metadata)
   (CodexAgentControlPreparedSpawnCheck
     $reserved-agent-path
     $reserved-agent-nickname
     $session-source
     $metadata))

(= (test:request-outcome-check
      $last-task-message
      $result)
   (CodexAgentControlRequestOutcomeCheck
     $last-task-message
     $result))

(= (test:request-release-check
      $metadata
      $total-count
      $result)
   (CodexAgentControlRequestReleaseCheck
     $metadata
     $total-count
     $result))

(= (test:root-metadata)
   (codex:agent-registry-metadata
     (test:root-thread)
     (codex:agent-path-root)
     CodexAbsent
     CodexAbsent
     CodexAbsent))

(= (test:scout-metadata)
   (codex:agent-registry-metadata
     (test:scout-thread)
     (test:scout-path)
     "Scout"
     "explorer"
     "Scan repository"))

(= (test:tester-metadata)
   (codex:agent-registry-metadata
     (test:tester-thread)
     (test:tester-path)
     CodexAbsent
     "worker"
     CodexAbsent))

(= (test:alpha-metadata)
   (codex:agent-registry-metadata
     (test:alpha-thread)
     (test:alpha-path)
     "Alpha"
     "reviewer"
     "Review changes"))

(= (test:missing-status-metadata)
   (codex:agent-registry-metadata
     (test:missing-thread)
     (codex:agent-path "/root/no_status")
     "NoStatus"
     CodexAbsent
     CodexAbsent))

(= (test:anonymous-fallback-metadata)
   (codex:agent-registry-metadata
     (test:anonymous-thread)
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent))

(= (test:registry-state)
   (codex:agent-registry-state
     ((codex:agent-registry-entry
        "/root/scout/tester"
        (test:tester-metadata))
      (codex:agent-registry-entry
        "/root"
        (test:root-metadata))
      (codex:agent-registry-entry
        "/root/no_status"
        (test:missing-status-metadata))
      (codex:agent-registry-entry
        "/root/scout"
        (test:scout-metadata))
      (codex:agent-registry-entry
        "/root/alpha"
        (test:alpha-metadata)))
     ()
     0
     4))

(= (test:status-entries)
   ((codex:agent-control-status-entry
      (test:scout-thread)
      (codex:protocol-agent-status-completed "done"))
    (codex:agent-control-status-entry
      (test:root-thread)
      (codex:protocol-agent-status-running))
    (codex:agent-control-status-entry
      (test:tester-thread)
      (codex:protocol-agent-status-errored "failed"))
    (codex:agent-control-status-entry
      (test:alpha-thread)
      (codex:protocol-agent-status-running))))

(= (test:scout-session-source)
   (codex:session-source-subagent
     (codex:subagent-source-thread-spawn
       (test:root-thread)
       1
       (test:scout-path)
       "Scout"
       "explorer")))

(= (test:thread-snapshots)
   ((codex:agent-control-thread-snapshot-entry
      (test:root-thread)
      (codex:session-source-cli))
    (codex:agent-control-thread-snapshot-entry
      (test:scout-thread)
      (test:scout-session-source))
    (codex:agent-control-thread-snapshot-entry
      (test:tester-thread)
      (codex:session-source-subagent
        (codex:subagent-source-thread-spawn
          (test:scout-thread)
          2
          (test:tester-path)
          CodexAbsent
          "worker")))
    (codex:agent-control-thread-snapshot-entry
      (test:alpha-thread)
      (codex:session-source-subagent
        (codex:subagent-source-thread-spawn
          (test:root-thread)
          1
          (test:alpha-path)
          "Alpha"
          "reviewer")))
    (codex:agent-control-thread-snapshot-entry
      (test:anonymous-thread)
      (codex:session-source-subagent
        (codex:subagent-source-thread-spawn
          (test:root-thread)
          1
          CodexAbsent
          "Anon"
          CodexAbsent)))
    (codex:agent-control-thread-snapshot-entry
      (test:exec-thread)
      (codex:session-source-exec))))

(= (test:send-input-operation)
   (codex:user-input-op
     ((codex:user-input-text "Review src/lib.rs" ()))))

(= (test:inter-agent-communication)
   (codex:inter-agent-communication
     (test:root-thread)
     (test:tester-thread)
     ()
     "child update"
     True))

(= (test:fork-user $text)
   (codex:rollout-response-item
     (CodexResponseItemMessage "user" ((CodexInputText $text)) CodexAbsent)))

(= (test:fork-assistant-final $text)
   (codex:rollout-response-item
     (CodexResponseItemMessage "assistant" ((CodexOutputText $text)) "final_answer")))

(= (test:fork-assistant-commentary $text)
   (codex:rollout-response-item
     (CodexResponseItemMessage "assistant" ((CodexOutputText $text)) "commentary")))

(= (test:fork-function-call $call-id)
   (codex:rollout-response-item
     (CodexResponseItemFunctionCall CodexAbsent "shell" CodexAbsent "{}" $call-id)))

(= (test:fork-inter-agent $text $trigger-turn)
   (codex:rollout-response-item
     (codex:thread-rollout-inter-agent-response-message
       (codex:agent-path-root)
       (test:scout-path)
       ()
       $text
       $trigger-turn)))

(= (test:fork-history-full)
   ((test:fork-user "u1")
    (test:fork-assistant-commentary "working")
    (test:fork-function-call "call-1")
    (test:fork-assistant-final "done")
    (codex:rollout-compacted "compact")
    (codex:rollout-turn-context "context")
    (codex:rollout-event-msg "event")
    (codex:rollout-session-meta "meta")))

(= (test:fork-history-last-n)
   ((test:fork-user "old parent context")
    (test:fork-inter-agent "triggered context" True)
    (test:fork-assistant-final "kept final")
    (test:fork-user "current parent task")
    (test:fork-assistant-commentary "drop commentary")))

!(assertEqual
  (codex:agent-control-agent-id-for-path
    (codex:agent-control-register-session-root
      (codex:agent-registry-state-empty)
      (test:root-thread)
      (codex:session-source-cli))
    (codex:agent-path-root))
  (test:root-thread))

!(assertEqual
  (codex:agent-control-agent-id-for-path
    (codex:agent-control-register-session-root
      (codex:agent-registry-state-empty)
      (test:scout-thread)
      (test:scout-session-source))
    (codex:agent-path-root))
  CodexAbsent)

!(assertEqual
  (codex:agent-control-thread-spawn-parent-thread-id
    (test:scout-session-source))
  (test:root-thread))

!(assertEqual
  (codex:agent-control-thread-spawn-parent-thread-id
    (codex:session-source-exec))
  CodexAbsent)

!(assertEqual
  (codex:agent-control-thread-spawn-depth
    (test:scout-session-source))
  1)

!(assertEqual
  (codex:agent-control-thread-spawn-depth
    (codex:session-source-cli))
  CodexAbsent)

!(assertEqual
  (codex:agent-control-persist-thread-spawn-edge-for-source
    (test:scout-thread)
    (test:scout-session-source)
    True)
  (codex:agent-control-thread-spawn-edge-upsert-action
    (test:root-thread)
    (test:scout-thread)
    (codex:thread-spawn-edge-status-open)))

!(assertEqual
  (codex:agent-control-persist-thread-spawn-edge-for-source
    (test:scout-thread)
    (codex:session-source-cli)
    True)
  CodexAbsent)

!(assertEqual
  (codex:agent-control-persist-thread-spawn-edge-for-source
    (test:scout-thread)
    (test:scout-session-source)
    False)
  CodexAbsent)

!(assertEqual
  (codex:agent-control-close-thread-spawn-edge-status-action
    (test:scout-thread)
    True
    True)
  (codex:agent-control-thread-spawn-edge-set-status-action
    (test:scout-thread)
    (codex:thread-spawn-edge-status-closed)))

!(assertEqual
  (codex:agent-control-close-thread-spawn-edge-status-action
    (test:scout-thread)
    False
    True)
  CodexAbsent)

!(assertEqual
  (codex:agent-control-close-thread-spawn-edge-status-action
    (test:scout-thread)
    True
    False)
  CodexAbsent)

!(assertEqual
  (codex:agent-control-close-agent
    (test:scout-thread)
    True
    True
    (codex:agent-control-ok "shutdown"))
  (codex:agent-control-close-agent-plan
    (codex:agent-control-thread-spawn-edge-set-status-action
      (test:scout-thread)
      (codex:thread-spawn-edge-status-closed))
    (codex:agent-control-ok "shutdown")))

!(assertEqual
  (case
    (codex:agent-registry-reserve-spawn-slot
      (codex:agent-registry-state-empty)
      CodexAbsent)
    (((CodexAgentRegistryReserveOk $slot-state $reservation)
      (case
        (codex:agent-control-prepare-thread-spawn
          $slot-state
          $reservation
          ((test:research-role-entry))
          (test:root-thread)
          1
          (test:scout-path)
          "researcher"
          CodexAbsent
          0)
        (((CodexAgentControlPrepareThreadSpawnOk
            $prepared-state
            $prepared-reservation
            $session-source
            $metadata)
          (test:prepared-spawn-check
            (codex:agent-registry-spawn-reservation-reserved-agent-path
              $prepared-reservation)
            (codex:agent-registry-spawn-reservation-reserved-agent-nickname
              $prepared-reservation)
            $session-source
            $metadata))
         ($other $other))))
     ($other $other)))
  (test:prepared-spawn-check
    (test:scout-path)
    "Atlas"
    (codex:session-source-subagent
      (codex:subagent-source-thread-spawn
        (test:root-thread)
        1
        (test:scout-path)
        "Atlas"
        "researcher"))
    (codex:agent-registry-metadata
      CodexAbsent
      (test:scout-path)
      "Atlas"
      "researcher"
      CodexAbsent)))

!(assertEqual
  (case
    (codex:agent-registry-reserve-spawn-slot
      (codex:agent-registry-state-empty)
      CodexAbsent)
    (((CodexAgentRegistryReserveOk $slot-state $reservation)
      (case
        (codex:agent-control-prepare-thread-spawn
          $slot-state
          $reservation
          ((test:research-role-entry))
          (test:root-thread)
          1
          (test:scout-path)
          "researcher"
          CodexAbsent
          0)
        (((CodexAgentControlPrepareThreadSpawnOk
            $prepared-state
            $prepared-reservation
            $session-source
            $metadata)
          (codex:agent-control-agent-id-for-path
            $prepared-state
            (codex:agent-path-root)))
         ($other $other))))
     ($other $other)))
  (test:root-thread))

!(assertEqual
  (case
    (codex:agent-registry-reserve-spawn-slot
      (codex:agent-registry-state-empty)
      CodexAbsent)
    (((CodexAgentRegistryReserveOk $slot-state $reservation)
      (case
        (codex:agent-control-prepare-thread-spawn
          $slot-state
          $reservation
          ()
          (test:root-thread)
          2
          CodexAbsent
          CodexAbsent
          "Stored"
          0)
        (((CodexAgentControlPrepareThreadSpawnOk
            $prepared-state
            $prepared-reservation
            $session-source
            $metadata)
          (test:prepared-spawn-check
            (codex:agent-registry-spawn-reservation-reserved-agent-path
              $prepared-reservation)
            (codex:agent-registry-spawn-reservation-reserved-agent-nickname
              $prepared-reservation)
            $session-source
            $metadata))
         ($other $other))))
     ($other $other)))
  (test:prepared-spawn-check
    CodexAbsent
    "Stored"
    (codex:session-source-subagent
      (codex:subagent-source-thread-spawn
        (test:root-thread)
        2
        CodexAbsent
        "Stored"
        CodexAbsent))
    (codex:agent-registry-metadata
      CodexAbsent
      CodexAbsent
      "Stored"
      CodexAbsent
      CodexAbsent)))

!(assertEqual
  (case
    (codex:agent-registry-reserve-spawn-slot
      (codex:agent-registry-state-empty)
      CodexAbsent)
    (((CodexAgentRegistryReserveOk $slot-state $reservation)
      (case
        (codex:agent-control-prepare-thread-spawn
          $slot-state
          $reservation
          ()
          (test:root-thread)
          2
          CodexAbsent
          CodexAbsent
          CodexAbsent
          0)
        (((CodexAgentControlPrepareThreadSpawnOk
            $prepared-state
            $prepared-reservation
            $session-source
            $metadata)
          (codex:agent-registry-spawn-reservation-reserved-agent-nickname
            $prepared-reservation))
         ($other $other))))
     ($other $other)))
  "Euclid")

!(assertEqual
  (case
    (codex:agent-registry-reserve-spawn-slot
      (test:registry-state)
      CodexAbsent)
    (((CodexAgentRegistryReserveOk $slot-state $reservation)
      (codex:agent-control-prepare-thread-spawn
        $slot-state
        $reservation
        ()
        (test:root-thread)
        1
        (test:scout-path)
        CodexAbsent
        CodexAbsent
        0))
     ($other $other)))
  (codex:agent-control-prepare-thread-spawn-err
    (codex:error-unsupported-operation
      "agent path `/root/scout` already exists")))

!(assertEqual
  (codex:agent-control-keep-forked-rollout-item
    (codex:rollout-response-item
      (CodexResponseItemMessage
        "system"
        ((CodexInputText "system"))
        CodexAbsent)))
  True)

!(assertEqual
  (codex:agent-control-keep-forked-rollout-item
    (codex:rollout-response-item
      (CodexResponseItemMessage
        "developer"
        ((CodexInputText "developer"))
        "commentary")))
  True)

!(assertEqual
  (codex:agent-control-keep-forked-rollout-item
    (codex:rollout-response-item
      (CodexResponseItemMessageWithId
        "msg-user"
        "user"
        ((CodexInputText "user"))
        CodexAbsent)))
  True)

!(assertEqual
  (codex:agent-control-keep-forked-rollout-item
    (codex:rollout-response-item
      (CodexResponseItemMessage
        "assistant"
        ((CodexOutputText "done"))
        "final_answer")))
  True)

!(assertEqual
  (codex:agent-control-keep-forked-rollout-item
    (codex:rollout-response-item
      (CodexResponseItemMessageWithId
        "msg-final"
        "assistant"
        ((CodexOutputText "done"))
        (codex:message-phase-final-answer))))
  True)

!(assertEqual
  (codex:agent-control-keep-forked-rollout-item
    (codex:rollout-response-item
      (CodexResponseItemMessage
        "assistant"
        ((CodexOutputText "working"))
        CodexAbsent)))
  False)

!(assertEqual
  (codex:agent-control-keep-forked-rollout-item
    (codex:rollout-response-item
      (CodexResponseItemMessage
        "assistant"
        ((CodexOutputText "working"))
        "commentary")))
  False)

!(assertEqual
  (codex:agent-control-keep-forked-rollout-item
    (codex:rollout-response-item
      (CodexResponseItemMessage
        "tool"
        ((CodexOutputText "unknown"))
        "final_answer")))
  False)

!(assertEqual
  (codex:agent-control-keep-forked-rollout-item
    (codex:rollout-response-item
      (CodexResponseItemFunctionCall
        CodexAbsent
        "shell"
        CodexAbsent
        "{}"
        "call-1")))
  False)

!(assertEqual
  (codex:agent-control-keep-forked-rollout-item
    (codex:rollout-turn-context "context"))
  False)

!(assertEqual
  (codex:agent-control-keep-forked-rollout-item
    (codex:rollout-compacted "compacted"))
  True)

!(assertEqual
  (codex:agent-control-keep-forked-rollout-item
    (codex:rollout-event-msg "event"))
  True)

!(assertEqual
  (codex:agent-control-keep-forked-rollout-item
    (codex:rollout-session-meta "meta"))
  True)

!(assertEqual
  (codex:agent-control-prepare-forked-rollout-items
    (test:fork-history-full)
    (codex:agent-control-spawn-agent-fork-mode-full-history))
  ((test:fork-user "u1")
   (test:fork-assistant-final "done")
   (codex:rollout-compacted "compact")
   (codex:rollout-event-msg "event")
   (codex:rollout-session-meta "meta")))

!(assertEqual
  (codex:agent-control-prepare-forked-rollout-items
    (test:fork-history-last-n)
    (codex:agent-control-spawn-agent-fork-mode-last-n-turns 2))
  ((test:fork-assistant-final "kept final")
   (test:fork-user "current parent task")))

!(assertEqual
  (codex:agent-control-prepare-forked-rollout-items
    (test:fork-history-last-n)
    (codex:agent-control-spawn-agent-fork-mode-last-n-turns 0))
  ())

!(assertEqual
  (codex:agent-control-prepare-forked-initial-history
    ((test:fork-user "u"))
    (codex:agent-control-spawn-agent-fork-mode-full-history))
  (codex:initial-history-forked ((test:fork-user "u"))))

!(assertEqual
  (codex:agent-control-get-agent-metadata
    (test:registry-state)
    (test:scout-thread))
  (test:scout-metadata))

!(assertEqual
  (codex:agent-control-open-thread-spawn-children
    (test:registry-state)
    (test:thread-snapshots)
    (test:root-thread))
  ((codex:agent-control-thread-metadata-entry
     (test:anonymous-thread)
     (test:anonymous-fallback-metadata))
   (codex:agent-control-thread-metadata-entry
     (test:alpha-thread)
     (test:alpha-metadata))
   (codex:agent-control-thread-metadata-entry
     (test:scout-thread)
     (test:scout-metadata))))

!(assertEqual
  (codex:agent-control-open-thread-spawn-children
    (test:registry-state)
    (test:thread-snapshots)
    (test:scout-thread))
  ((codex:agent-control-thread-metadata-entry
     (test:tester-thread)
     (test:tester-metadata))))

!(assertEqual
  (codex:agent-control-open-thread-spawn-children
    (test:registry-state)
    (test:thread-snapshots)
    (test:missing-thread))
  ())

!(assertEqual
  (codex:agent-control-live-thread-spawn-descendants
    (test:registry-state)
    (test:thread-snapshots)
    (test:root-thread))
  ((test:anonymous-thread)
   (test:alpha-thread)
   (test:scout-thread)
   (test:tester-thread)))

!(assertEqual
  (codex:agent-control-list-live-agent-subtree-thread-ids
    (test:registry-state)
    (test:thread-snapshots)
    (test:scout-thread))
  ((test:scout-thread)
   (test:tester-thread)))

!(assertEqual
  (case
    (codex:agent-control-send-input-result
      (test:registry-state)
      (test:scout-thread)
      (test:send-input-operation)
      (codex:agent-control-ok "turn-1"))
    (((CodexAgentControlThreadRequestOutcome $state $result)
      (case
        (codex:agent-control-agent-metadata-for-thread
          $state
          (test:scout-thread))
        (($metadata
          (test:request-outcome-check
            (codex:agent-registry-metadata-last-task-message $metadata)
            $result)))))))
  (test:request-outcome-check
    "Review src/lib.rs"
    (codex:agent-control-ok "turn-1")))

!(assertEqual
  (case
    (codex:agent-control-send-input-result
      (test:registry-state)
      (test:scout-thread)
      (test:send-input-operation)
      (codex:agent-control-err
        (codex:error-unsupported-operation "busy")))
    (((CodexAgentControlThreadRequestOutcome $state $result)
      (case
        (codex:agent-control-agent-metadata-for-thread
          $state
          (test:scout-thread))
        (($metadata
          (test:request-outcome-check
            (codex:agent-registry-metadata-last-task-message $metadata)
            $result)))))))
  (test:request-outcome-check
    "Scan repository"
    (codex:agent-control-err
      (codex:error-unsupported-operation "busy"))))

!(assertEqual
  (case
    (codex:agent-control-send-input-result
      (test:registry-state)
      (test:scout-thread)
      (test:send-input-operation)
      (codex:agent-control-err
        (codex:error-internal-agent-died)))
    (((CodexAgentControlThreadRequestOutcome $state $result)
      (case
        (codex:agent-control-agent-metadata-for-thread
          $state
          (test:scout-thread))
        (($metadata
          (test:request-release-check
            $metadata
            (codex:agent-registry-state-total-count $state)
            $result)))))))
  (test:request-release-check
    CodexAbsent
    3
    (codex:agent-control-err
      (codex:error-internal-agent-died))))

!(assertEqual
  (case
    (codex:agent-control-send-inter-agent-communication-result
      (test:registry-state)
      (test:tester-thread)
      (test:inter-agent-communication)
      (codex:agent-control-ok "turn-2"))
    (((CodexAgentControlThreadRequestOutcome $state $result)
      (case
        (codex:agent-control-agent-metadata-for-thread
          $state
          (test:tester-thread))
        (($metadata
          (test:request-outcome-check
            (codex:agent-registry-metadata-last-task-message $metadata)
            $result)))))))
  (test:request-outcome-check
    "child update"
    (codex:agent-control-ok "turn-2")))

!(assertEqual
  (case
    (codex:agent-control-interrupt-agent-result
      (test:registry-state)
      (test:scout-thread)
      (codex:agent-control-err
        (codex:error-internal-agent-died)))
    (((CodexAgentControlThreadRequestOutcome $state $result)
      (case
        (codex:agent-control-agent-metadata-for-thread
          $state
          (test:scout-thread))
        (($metadata
          (test:request-release-check
            $metadata
            (codex:agent-registry-state-total-count $state)
            $result)))))))
  (test:request-release-check
    (test:scout-metadata)
    4
    (codex:agent-control-err
      (codex:error-internal-agent-died))))

!(assertEqual
  (case
    (codex:agent-control-shutdown-live-agent-result
      (test:registry-state)
      (test:scout-thread)
      (codex:agent-control-shutdown-live-thread
        (codex:agent-control-ok ())
        (codex:protocol-agent-status-running)
        (codex:agent-control-ok "shutdown-turn"))
      (codex:agent-control-err
        (codex:error-thread-not-found (test:scout-thread))))
    (((CodexAgentControlThreadRequestOutcome $state $result)
      (case
        (codex:agent-control-agent-metadata-for-thread
          $state
          (test:scout-thread))
        (($metadata
          (test:request-release-check
            $metadata
            (codex:agent-registry-state-total-count $state)
            $result)))))))
  (test:request-release-check
    CodexAbsent
    3
    (codex:agent-control-ok "shutdown-turn")))

!(assertEqual
  (case
    (codex:agent-control-shutdown-live-agent-result
      (test:registry-state)
      (test:scout-thread)
      (codex:agent-control-shutdown-live-thread
        (codex:agent-control-ok ())
        (codex:protocol-agent-status-shutdown)
        (codex:agent-control-err
          (codex:error-unsupported-operation "send should be skipped")))
      (codex:agent-control-err
        (codex:error-thread-not-found (test:scout-thread))))
    (((CodexAgentControlThreadRequestOutcome $state $result)
      (case
        (codex:agent-control-agent-metadata-for-thread
          $state
          (test:scout-thread))
        (($metadata
          (test:request-release-check
            $metadata
            (codex:agent-registry-state-total-count $state)
            $result)))))))
  (test:request-release-check
    CodexAbsent
    3
    (codex:agent-control-ok "")))

!(assertEqual
  (case
    (codex:agent-control-shutdown-live-agent-result
      (test:registry-state)
      (test:scout-thread)
      (codex:agent-control-shutdown-live-thread
        (codex:agent-control-err
          (codex:error-fatal "flush failed"))
        (codex:protocol-agent-status-running)
        (codex:agent-control-ok "shutdown-turn"))
      (codex:agent-control-err
        (codex:error-thread-not-found (test:scout-thread))))
    (((CodexAgentControlThreadRequestOutcome $state $result)
      (case
        (codex:agent-control-agent-metadata-for-thread
          $state
          (test:scout-thread))
        (($metadata
          (test:request-release-check
            $metadata
            (codex:agent-registry-state-total-count $state)
            $result)))))))
  (test:request-release-check
    (test:scout-metadata)
    4
    (codex:agent-control-err
      (codex:error-fatal "flush failed"))))

!(assertEqual
  (case
    (codex:agent-control-shutdown-live-agent-result
      (test:registry-state)
      (test:scout-thread)
      CodexAbsent
      (codex:agent-control-err
        (codex:error-thread-not-found (test:scout-thread))))
    (((CodexAgentControlThreadRequestOutcome $state $result)
      (case
        (codex:agent-control-agent-metadata-for-thread
          $state
          (test:scout-thread))
        (($metadata
          (test:request-release-check
            $metadata
            (codex:agent-registry-state-total-count $state)
            $result)))))))
  (test:request-release-check
    CodexAbsent
    3
    (codex:agent-control-err
      (codex:error-thread-not-found (test:scout-thread)))))

!(assertEqual
  (case
    (codex:agent-control-shutdown-agent-tree-result
      (test:registry-state)
      (test:scout-thread)
      (codex:agent-control-shutdown-live-thread
        (codex:agent-control-ok ())
        (codex:protocol-agent-status-running)
        (codex:agent-control-ok "root-shutdown"))
      (codex:agent-control-err
        (codex:error-thread-not-found (test:scout-thread)))
      ((codex:agent-control-shutdown-agent-tree-entry
         (test:tester-thread)
         CodexAbsent
         (codex:agent-control-err
           (codex:error-thread-not-found (test:tester-thread))))
       (codex:agent-control-shutdown-agent-tree-entry
         (test:alpha-thread)
         (codex:agent-control-shutdown-live-thread
           (codex:agent-control-ok ())
           (codex:protocol-agent-status-running)
           (codex:agent-control-err
             (codex:error-internal-agent-died)))
         (codex:agent-control-err
           (codex:error-thread-not-found (test:alpha-thread))))))
    (((CodexAgentControlThreadRequestOutcome $state $result)
      (case
        (codex:agent-control-agent-metadata-for-thread
          $state
          (test:scout-thread))
        (($metadata
          (test:request-release-check
            $metadata
            (codex:agent-registry-state-total-count $state)
            $result)))))))
  (test:request-release-check
    CodexAbsent
    1
    (codex:agent-control-ok "root-shutdown")))

!(assertEqual
  (case
    (codex:agent-control-shutdown-agent-tree-result
      (test:registry-state)
      (test:scout-thread)
      (codex:agent-control-shutdown-live-thread
        (codex:agent-control-ok ())
        (codex:protocol-agent-status-running)
        (codex:agent-control-err
          (codex:error-fatal "root send failed")))
      (codex:agent-control-err
        (codex:error-thread-not-found (test:scout-thread)))
      ((codex:agent-control-shutdown-agent-tree-entry
         (test:tester-thread)
         (codex:agent-control-shutdown-live-thread
           (codex:agent-control-ok ())
           (codex:protocol-agent-status-running)
           (codex:agent-control-ok "tester-shutdown"))
         (codex:agent-control-err
           (codex:error-thread-not-found (test:tester-thread))))))
    (((CodexAgentControlThreadRequestOutcome $state $result)
      (case
        (codex:agent-control-agent-metadata-for-thread
          $state
          (test:scout-thread))
        (($metadata
          (test:request-release-check
            $metadata
            (codex:agent-registry-state-total-count $state)
            $result)))))))
  (test:request-release-check
    CodexAbsent
    2
    (codex:agent-control-err
      (codex:error-fatal "root send failed"))))

!(assertEqual
  (case
    (codex:agent-control-shutdown-agent-tree-result
      (test:registry-state)
      (test:scout-thread)
      (codex:agent-control-shutdown-live-thread
        (codex:agent-control-ok ())
        (codex:protocol-agent-status-running)
        (codex:agent-control-ok "root-shutdown"))
      (codex:agent-control-err
        (codex:error-thread-not-found (test:scout-thread)))
      ((codex:agent-control-shutdown-agent-tree-entry
         (test:tester-thread)
         (codex:agent-control-shutdown-live-thread
           (codex:agent-control-ok ())
           (codex:protocol-agent-status-running)
           (codex:agent-control-err
             (codex:error-fatal "child failed")))
         (codex:agent-control-err
           (codex:error-thread-not-found (test:tester-thread))))
       (codex:agent-control-shutdown-agent-tree-entry
         (test:alpha-thread)
         (codex:agent-control-shutdown-live-thread
           (codex:agent-control-ok ())
           (codex:protocol-agent-status-running)
           (codex:agent-control-ok "alpha-should-not-run"))
         (codex:agent-control-err
           (codex:error-thread-not-found (test:alpha-thread))))))
    (((CodexAgentControlThreadRequestOutcome $state $result)
      (case
        (codex:agent-control-agent-metadata-for-thread
          $state
          (test:alpha-thread))
        (($metadata
          (test:request-release-check
            $metadata
            (codex:agent-registry-state-total-count $state)
            $result)))))))
  (test:request-release-check
    (test:alpha-metadata)
    2
    (codex:agent-control-err
      (codex:error-fatal "child failed"))))

!(assertEqual
  (codex:agent-control-resolve-agent-reference
    (test:registry-state)
    (test:root-thread)
    (codex:session-source-cli)
    "scout")
  (codex:agent-control-ok (test:scout-thread)))

!(assertEqual
  (codex:agent-control-resolve-agent-reference
    (test:registry-state)
    (test:scout-thread)
    (test:scout-session-source)
    "tester")
  (codex:agent-control-ok (test:tester-thread)))

!(assertEqual
  (codex:agent-control-resolve-agent-reference
    (test:registry-state)
    (test:root-thread)
    (codex:session-source-cli)
    "../bad")
  (codex:agent-control-err
    (codex:error-unsupported-operation
      "agent_name `..` is reserved")))

!(assertEqual
  (codex:agent-control-resolve-agent-reference
    (test:registry-state)
    (test:root-thread)
    (codex:session-source-cli)
    "/root/missing")
  (codex:agent-control-err
    (codex:error-unsupported-operation
      "live agent path `/root/missing` not found")))

!(assertEqualToResult
  (codex:agent-control-format-environment-context-subagents
    (codex:agent-control-ok
      ((codex:agent-control-thread-metadata-entry
         (test:scout-thread)
         (test:scout-metadata))
       (codex:agent-control-thread-metadata-entry
         (test:tester-thread)
         (codex:agent-registry-metadata
           (test:tester-thread)
           CodexAbsent
           CodexAbsent
           CodexAbsent
           CodexAbsent)))))
  ("- scout: Scout\n- 00000000-0000-0000-0000-000000000003"))

!(assertEqual
  (codex:agent-control-format-environment-context-subagents
    (codex:agent-control-err
      (codex:error-unsupported-operation "thread manager dropped")))
  "")

!(assertEqual
  (codex:agent-control-agent-matches-prefix
    CodexAbsent
    (codex:agent-path-root))
  True)

!(assertEqual
  (codex:agent-control-agent-matches-prefix
    (test:tester-path)
    (test:scout-path))
  True)

!(assertEqual
  (codex:agent-control-agent-matches-prefix
    (test:scout-path)
    (test:scout-path))
  True)

!(assertEqual
  (codex:agent-control-agent-matches-prefix
    (codex:agent-path "/root/scouting")
    (test:scout-path))
  False)

!(assertEqual
  (codex:agent-control-agent-matches-prefix
    CodexAbsent
    (test:scout-path))
  False)

!(assertEqual
  (codex:agent-control-list-agents
    (test:registry-state)
    (test:status-entries)
    (codex:session-source-cli)
    CodexAbsent)
  (codex:agent-control-ok
    ((codex:agent-control-listed-agent
       "/root"
       (codex:protocol-agent-status-running)
       "Main thread")
     (codex:agent-control-listed-agent
       "/root/alpha"
       (codex:protocol-agent-status-running)
       "Review changes")
     (codex:agent-control-listed-agent
       "/root/scout"
       (codex:protocol-agent-status-completed "done")
       "Scan repository")
     (codex:agent-control-listed-agent
       "/root/scout/tester"
       (codex:protocol-agent-status-errored "failed")
       CodexAbsent))))

!(assertEqual
  (codex:agent-control-list-agents
    (test:registry-state)
    (test:status-entries)
    (codex:session-source-cli)
    "scout")
  (codex:agent-control-ok
    ((codex:agent-control-listed-agent
       "/root/scout"
       (codex:protocol-agent-status-completed "done")
       "Scan repository")
     (codex:agent-control-listed-agent
       "/root/scout/tester"
       (codex:protocol-agent-status-errored "failed")
       CodexAbsent))))

!(assertEqual
  (codex:agent-control-list-agents
    (test:registry-state)
    (test:status-entries)
    (test:scout-session-source)
    "tester")
  (codex:agent-control-ok
    ((codex:agent-control-listed-agent
       "/root/scout/tester"
       (codex:protocol-agent-status-errored "failed")
       CodexAbsent))))

!(assertEqual
  (codex:agent-control-list-agents
    (test:registry-state)
    (test:status-entries)
    (codex:session-source-cli)
    "")
  (codex:agent-control-err
    (codex:error-unsupported-operation
      "agent path must not be empty")))

!(assertEqual
  (codex:agent-control-render-input-preview
    (codex:user-input-op
      ((codex:user-input-text "hello" ())
       (codex:user-input-image "data:image/png;base64,abc")
       (codex:user-input-local-image "/tmp/screenshot.png")
       (codex:user-input-skill "planner" "/repo/SKILL.md")
       (codex:user-input-mention "calendar" "app://calendar")
       (CodexUserInputFuture "payload"))))
  "hello\n[image]\n[local_image:/tmp/screenshot.png]\n[skill:$planner](/repo/SKILL.md)\n[mention:$calendar](app://calendar)\n[input]")

!(assertEqual
  (codex:agent-control-render-input-preview
    (codex:inter-agent-communication-op
      (codex:inter-agent-communication
        (test:root-thread)
        (test:scout-thread)
        ()
        "child update"
        CodexAbsent)))
  "child update")

!(assertEqual
  (codex:agent-control-render-input-preview
    (codex:interrupt-op))
  "")
