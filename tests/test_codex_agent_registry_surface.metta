!(register-module! ../codex)
!(import! &self codex:agent_path)
!(import! &self codex:agent_registry)
!(import! &self codex:error)
!(import! &self codex:protocol)

(= (test:thread-a)
   "67e55044-10b1-426f-9247-bb680e5fe0c8")

(= (test:thread-b)
   "123e4567-e89b-12d3-a456-426614174000")

(= (test:scout-path)
   (codex:agent-path "/root/scout"))

(= (test:scout-metadata)
   (codex:agent-registry-metadata
     (test:thread-a)
     (test:scout-path)
     "Scout"
     "explorer"
     CodexAbsent))

(= (test:reserved-path-state)
   (codex:agent-registry-state
     ((codex:agent-registry-entry
        "/root/scout"
        (codex:agent-registry-metadata
          CodexAbsent
          (test:scout-path)
          CodexAbsent
          CodexAbsent
          CodexAbsent)))
     ()
     0
     1))

(= (test:path-reservation)
   (codex:agent-registry-spawn-reservation
     True
     CodexAbsent
     (test:scout-path)))

(= (test:root-state-a)
   (codex:agent-registry-state
     ((codex:agent-registry-entry
        "/root"
        (codex:agent-registry-metadata
          (test:thread-a)
          (codex:agent-path-root)
          CodexAbsent
          CodexAbsent
          CodexAbsent)))
     ()
     0
     0))

(= (test:root-state-a-not-first)
   (codex:agent-registry-state
     ((codex:agent-registry-entry
        "/root/scout"
        (test:scout-metadata))
      (codex:agent-registry-entry
        "/root"
        (codex:agent-registry-metadata
          (test:thread-a)
          (codex:agent-path-root)
          CodexAbsent
          CodexAbsent
          CodexAbsent)))
     ()
     0
     1))

(= (test:scout-path-not-first-state)
   (codex:agent-registry-state
     ((codex:agent-registry-entry
        "/root"
        (codex:agent-registry-metadata
          (test:thread-a)
          (codex:agent-path-root)
          CodexAbsent
          CodexAbsent
          CodexAbsent))
      (codex:agent-registry-entry
        "/root/scout"
        (test:scout-metadata)))
     ()
     0
     1))

(= (test:scout-committed-state)
   (codex:agent-registry-commit-reservation
     (test:reserved-path-state)
     (test:path-reservation)
     (test:scout-metadata)))

(= (test:nickname-metadata $thread-id $nickname)
   (codex:agent-registry-metadata
     $thread-id
     CodexAbsent
     $nickname
     CodexAbsent
     CodexAbsent))

(= (test:reserve-nickname $state $names $preferred $choice-index)
   (case (codex:agent-registry-reserve-spawn-slot
           (eval $state)
           CodexAbsent)
     (((CodexAgentRegistryReserveOk $slot-state $reservation)
       (codex:agent-registry-reserve-agent-nickname-with-preference
         $slot-state
         $reservation
         $names
         $preferred
         $choice-index)))))

(= (test:nickname-reserve-nickname $result)
   (case $result
     (((CodexAgentRegistryReserveOk $state $reservation)
       (codex:agent-registry-spawn-reservation-reserved-agent-nickname
         $reservation)))))

(= (test:drop-nickname-reserve $result)
   (case $result
     (((CodexAgentRegistryReserveOk $state $reservation)
       (codex:agent-registry-drop-reservation $state $reservation)))))

(= (test:commit-nickname-reserve $result $metadata)
   (case $result
     (((CodexAgentRegistryReserveOk $state $reservation)
       (codex:agent-registry-commit-reservation
         $state
         $reservation
         $metadata)))))

(= (test:first-alpha-nickname-reserve)
   (test:reserve-nickname
     (codex:agent-registry-state-empty)
     ("alpha")
     CodexAbsent
     0))

(= (test:after-failed-alpha-nickname)
   (test:drop-nickname-reserve
     (test:first-alpha-nickname-reserve)))

(= (test:after-committed-alpha-nickname)
   (test:commit-nickname-reserve
     (test:first-alpha-nickname-reserve)
     (test:nickname-metadata (test:thread-a) "alpha")))

(= (test:after-released-alpha-nickname)
   (codex:agent-registry-release-spawned-thread
     (test:after-committed-alpha-nickname)
     (test:thread-a)))

!(assertEqual
  (codex:agent-registry-format-agent-nickname "Plato" 0)
  "Plato")

!(assertEqual
  (codex:agent-registry-format-agent-nickname "Plato" 1)
  "Plato the 2nd")

!(assertEqual
  (codex:agent-registry-format-agent-nickname "Plato" 2)
  "Plato the 3rd")

!(assertEqual
  (codex:agent-registry-format-agent-nickname "Plato" 10)
  "Plato the 11th")

!(assertEqual
  (codex:agent-registry-format-agent-nickname "Plato" 20)
  "Plato the 21st")

!(assertEqual
  (codex:agent-registry-session-depth (codex:session-source-cli))
  0)

!(assertEqual
  (codex:agent-registry-next-thread-spawn-depth
    (codex:session-source-subagent
      (codex:subagent-source-thread-spawn
        (test:thread-a)
        1
        CodexAbsent
        CodexAbsent
        CodexAbsent)))
  2)

!(assertEqual
  (codex:agent-registry-next-thread-spawn-depth
    (codex:session-source-subagent
      (codex:subagent-source-review)))
  1)

!(assertEqual
  (codex:agent-registry-saturating-add-one-i32 2147483647)
  2147483647)

!(assertEqual
  (codex:agent-registry-exceeds-thread-spawn-depth-limit 2 1)
  True)

!(assertEqual
  (codex:agent-registry-agent-id-for-path
    (codex:agent-registry-register-root-thread
      (codex:agent-registry-state-empty)
      (test:thread-a))
    (codex:agent-path-root))
  (test:thread-a))

!(assertEqual
  (codex:agent-registry-agent-id-for-path
    (codex:agent-registry-register-root-thread
      (test:root-state-a)
      (test:thread-b))
    (codex:agent-path-root))
  (test:thread-a))

!(assertEqual
  (codex:agent-registry-agent-id-for-path
    (codex:agent-registry-register-root-thread
      (test:root-state-a-not-first)
      (test:thread-b))
    (codex:agent-path-root))
  (test:thread-a))

!(assertEqual
  (codex:agent-registry-live-agents
    (codex:agent-registry-register-root-thread
      (codex:agent-registry-state-empty)
      (test:thread-a)))
  ())

!(assertEqual
  (codex:agent-registry-state-used-agent-nicknames
    (codex:agent-registry-register-spawned-thread
      (codex:agent-registry-state-empty)
      (test:scout-metadata)))
  ("Scout"))

!(assertEqual
  (test:nickname-reserve-nickname
    (test:first-alpha-nickname-reserve))
  "alpha")

!(assertEqual
  (codex:agent-registry-state-total-count
    (test:after-failed-alpha-nickname))
  0)

!(assertEqual
  (codex:agent-registry-state-used-agent-nicknames
    (test:after-failed-alpha-nickname))
  ("alpha"))

!(assertEqual
  (case
    (test:reserve-nickname
      (test:after-failed-alpha-nickname)
      ("alpha" "beta")
      CodexAbsent
      0)
    (((CodexAgentRegistryReserveOk $state $reservation)
      (codex:agent-registry-spawn-reservation-reserved-agent-nickname
        $reservation))))
  "beta")

!(assertEqual
  (case
    (test:reserve-nickname
      (codex:agent-registry-state-empty)
      ()
      CodexAbsent
      0)
    (((CodexAgentRegistryReserveErr $error)
      $error)))
  (codex:error-unsupported-operation
    "no available agent nicknames"))

!(assertEqual
  (case
    (test:reserve-nickname
      (test:after-failed-alpha-nickname)
      ()
      "alpha"
      0)
    (((CodexAgentRegistryReserveOk $state $reservation)
      (codex:agent-registry-spawn-reservation-reserved-agent-nickname
        $reservation))))
  "alpha")

!(assertEqual
  (case
    (test:reserve-nickname
      (test:after-committed-alpha-nickname)
      ("alpha")
      CodexAbsent
      0)
    (((CodexAgentRegistryReserveOk $state $reservation)
      (codex:agent-registry-spawn-reservation-reserved-agent-nickname
        $reservation))))
  "alpha the 2nd")

!(assertEqual
  (case
    (test:reserve-nickname
      (test:after-committed-alpha-nickname)
      ("alpha")
      CodexAbsent
      0)
    (((CodexAgentRegistryReserveOk $state $reservation)
      (codex:agent-registry-state-nickname-reset-count $state))))
  1)

!(assertEqual
  (case
    (test:reserve-nickname
      (test:after-released-alpha-nickname)
      ("alpha" "beta")
      CodexAbsent
      0)
    (((CodexAgentRegistryReserveOk $state $reservation)
      (codex:agent-registry-spawn-reservation-reserved-agent-nickname
        $reservation))))
  "beta")

!(assertEqual
  (codex:agent-registry-live-agents
    (codex:agent-registry-register-spawned-thread
      (codex:agent-registry-state-empty)
      (test:scout-metadata)))
  ((test:scout-metadata)))

!(assertEqual
  (codex:agent-registry-metadata-last-task-message
    (codex:agent-registry-agent-metadata-for-thread
      (codex:agent-registry-update-last-task-message
        (codex:agent-registry-register-spawned-thread
          (codex:agent-registry-state-empty)
          (test:scout-metadata))
        (test:thread-a)
        "Review src/lib.rs")
      (test:thread-a)))
  "Review src/lib.rs")

!(assertEqual
  (case (codex:agent-registry-reserve-spawn-slot
          (codex:agent-registry-state-empty)
          1)
    (((CodexAgentRegistryReserveOk $state $reservation)
      (codex:agent-registry-state-total-count $state))))
  1)

!(assertEqual
  (case (codex:agent-registry-reserve-spawn-slot
          (case (codex:agent-registry-reserve-spawn-slot
                  (codex:agent-registry-state-empty)
                  1)
            (((CodexAgentRegistryReserveOk $state $reservation)
              $state)))
          1)
    (((CodexAgentRegistryReserveErr $error)
      (codex:error-agent-limit-reached-max-threads $error))))
  1)

!(assertEqual
  (codex:agent-registry-state-total-count
    (case (codex:agent-registry-reserve-spawn-slot
            (codex:agent-registry-state-empty)
            1)
      (((CodexAgentRegistryReserveOk $state $reservation)
        (codex:agent-registry-drop-reservation $state $reservation)))))
  0)

!(assertEqual
  (case (codex:agent-registry-reserve-spawn-slot
          (codex:agent-registry-state-empty)
          CodexAbsent)
    (((CodexAgentRegistryReserveOk $state $reservation)
      (codex:agent-registry-reserve-agent-path-for-reservation
        $state
        $reservation
        (test:scout-path)))))
  (codex:agent-registry-reserve-ok
    (test:reserved-path-state)
    (test:path-reservation)))

!(assertEqual
  (case (codex:agent-registry-reserve-agent-path-for-reservation
          (test:reserved-path-state)
          (test:path-reservation)
          (test:scout-path))
    (((CodexAgentRegistryReserveErr $error)
      $error)))
  (codex:error-unsupported-operation
    "agent path `/root/scout` already exists"))

!(assertEqual
  (case (codex:agent-registry-reserve-agent-path-for-reservation
          (test:scout-path-not-first-state)
          (test:path-reservation)
          (test:scout-path))
    (((CodexAgentRegistryReserveErr $error)
      $error)))
  (codex:error-unsupported-operation
    "agent path `/root/scout` already exists"))

!(assertEqual
  (codex:agent-registry-agent-id-for-path
    (codex:agent-registry-drop-reservation
      (test:reserved-path-state)
      (test:path-reservation))
    (test:scout-path))
  CodexAbsent)

!(assertEqual
  (codex:agent-registry-agent-id-for-path
    (test:scout-committed-state)
    (test:scout-path))
  (test:thread-a))

!(assertEqual
  (codex:agent-registry-agent-id-for-path
    (codex:agent-registry-release-spawned-thread
      (test:scout-committed-state)
      (test:thread-a))
    (test:scout-path))
  CodexAbsent)

!(assertEqual
  (codex:agent-registry-state-total-count
    (codex:agent-registry-release-spawned-thread
      (case (codex:agent-registry-reserve-spawn-slot
              (codex:agent-registry-state-empty)
              CodexAbsent)
        (((CodexAgentRegistryReserveOk $state $reservation)
          (codex:agent-registry-commit-reservation
            $state
            $reservation
            (test:scout-metadata)))))
      (test:thread-b)))
  1)
