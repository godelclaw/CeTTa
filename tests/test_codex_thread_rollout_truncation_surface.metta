!(register-module! ../codex)
!(import! &self codex:thread_rollout_truncation)

(= (test:user-response $text)
   (CodexResponseItemMessage "user" ((CodexOutputText $text)) CodexAbsent))

(= (test:assistant-response $text)
   (CodexResponseItemMessage "assistant" ((CodexOutputText $text)) CodexAbsent))

(= (test:inter-agent-response $text $trigger-turn)
   (codex:thread-rollout-inter-agent-response-message
     (CodexAgentPath "/root")
     (CodexAgentPath "/root/worker")
     ()
     $text
     $trigger-turn))

(= (test:rollout-user $text)
   (codex:rollout-response-item (test:user-response $text)))

(= (test:rollout-assistant $text)
   (codex:rollout-response-item (test:assistant-response $text)))

(= (test:rollout-inter-agent $text $trigger-turn)
   (codex:rollout-response-item
     (test:inter-agent-response $text $trigger-turn)))

(= (test:rollout-rollback $num-turns)
   (codex:rollout-event-msg (codex:thread-rolled-back-event $num-turns)))

(= (test:rollback-user-rollout)
   ((test:rollout-user "u1")
    (test:rollout-assistant "a1")
    (test:rollout-user "u2")
    (test:rollout-assistant "a2")
    (test:rollout-rollback 1)
    (test:rollout-user "u3")
    (test:rollout-assistant "a3")
    (test:rollout-user "u4")
    (test:rollout-assistant "a4")))

(= (test:rollback-user-rollout-prefix-before-u4)
   ((test:rollout-user "u1")
    (test:rollout-assistant "a1")
    (test:rollout-user "u2")
    (test:rollout-assistant "a2")
    (test:rollout-rollback 1)
    (test:rollout-user "u3")
    (test:rollout-assistant "a3")))

!(assertEqual
  (codex:user-message-positions-in-rollout
    (test:rollback-user-rollout))
  (0 5 7))

!(assertEqual
  (codex:truncate-rollout-before-nth-user-message-from-start
    (test:rollback-user-rollout)
    2)
  (test:rollback-user-rollout-prefix-before-u4))

!(assertEqual
  (codex:truncate-rollout-before-nth-user-message-from-start
    (test:rollback-user-rollout)
    (codex:thread-rollout-usize-max))
  (test:rollback-user-rollout))

!(assertEqual
  (codex:is-thread-rollout-user-turn-boundary
    (test:inter-agent-response "queued message" False))
  True)

!(assertEqual
  (codex:is-trigger-turn-boundary
    (test:inter-agent-response "queued message" False))
  False)

!(assertEqual
  (codex:is-thread-rollout-user-turn-boundary
    (test:assistant-response
      "author: /root\nrecipient: /root/worker\nother_recipients: []\nContent: continue"))
  False)

(= (test:fork-rollout)
   ((test:rollout-user "u1")
    (test:rollout-assistant "a1")
    (test:rollout-inter-agent "queued message" False)
    (test:rollout-assistant "a2")
    (test:rollout-inter-agent "triggered task" True)
    (test:rollout-assistant "a3")
    (test:rollout-user "u2")
    (test:rollout-assistant "a4")))

(= (test:fork-rollout-last-two)
   ((test:rollout-inter-agent "triggered task" True)
    (test:rollout-assistant "a3")
    (test:rollout-user "u2")
    (test:rollout-assistant "a4")))

!(assertEqual
  (codex:fork-turn-positions-in-rollout (test:fork-rollout))
  (0 4 6))

!(assertEqual
  (codex:truncate-rollout-to-last-n-fork-turns
    (test:fork-rollout)
    2)
  (test:fork-rollout-last-two))

(= (test:rollback-fork-rollout)
   ((test:rollout-user "u1")
    (test:rollout-assistant "a1")
    (test:rollout-inter-agent "triggered task" True)
    (test:rollout-assistant "a2")
    (test:rollout-rollback 1)
    (test:rollout-user "u2")
    (test:rollout-assistant "a3")))

!(assertEqual
  (codex:truncate-rollout-to-last-n-fork-turns
    (test:rollback-fork-rollout)
    2)
  (test:rollback-fork-rollout))

(= (test:zero-rollback-fork-rollout)
   ((test:rollout-user "u1")
    (test:rollout-inter-agent "triggered task" True)
    (test:rollout-rollback 0)
    (test:rollout-user "u2")))

!(assertEqual
  (codex:fork-turn-positions-in-rollout
    (test:zero-rollback-fork-rollout))
  (0 1 3))

(= (test:rolled-back-suffix-fork-rollout)
   ((test:rollout-user "u1")
    (test:rollout-user "u2")
    (test:rollout-inter-agent "triggered task" True)
    (test:rollout-assistant "a1")
    (test:rollout-rollback 1)
    (test:rollout-user "u3")
    (test:rollout-assistant "a2")))

(= (test:rolled-back-suffix-fork-rollout-last-two)
   ((test:rollout-user "u2")
    (test:rollout-inter-agent "triggered task" True)
    (test:rollout-assistant "a1")
    (test:rollout-rollback 1)
    (test:rollout-user "u3")
    (test:rollout-assistant "a2")))

!(assertEqual
  (codex:truncate-rollout-to-last-n-fork-turns
    (test:rolled-back-suffix-fork-rollout)
    2)
  (test:rolled-back-suffix-fork-rollout-last-two))

!(assertEqual
  (codex:truncate-rollout-to-last-n-fork-turns
    (test:fork-rollout)
    0)
  ())

!(assertEqual
  (codex:initial-history-has-prior-user-turns
    (codex:initial-history-new))
  False)

!(assertEqual
  (codex:initial-history-has-prior-user-turns
    (codex:initial-history-forked
      ((test:rollout-assistant "a1")
       (test:rollout-user "u1"))))
  True)

!(assertEqual
  (codex:initial-history-has-prior-user-turns
    (codex:initial-history-resumed
      (codex:resumed-history
        "thread-1"
        ((test:rollout-inter-agent "triggered task" True))
        "/tmp/rollout.jsonl")))
  True)
