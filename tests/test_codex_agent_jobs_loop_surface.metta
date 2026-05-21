!(register-module! ../codex)
!(import! &self codex:agent_jobs_loop)

!(assertEqual
  (codex:agent-job-loop-job-not-found-error "job-404")
  "agent job job-404 was not found")

!(assertEqual
  (codex:agent-job-loop-start-plan "job-404" CodexAbsent)
  (CodexAgentJobErr "agent job job-404 was not found"))

!(assertEqual
  (codex:agent-job-loop-start-plan
    "job-1"
    (CodexAgentJob
      "job-1"
      "example"
      (CodexAgentJobStatusRunning)
      "Review {path}"
      True
      75
      CodexAbsent
      ("path")
      "/tmp/input.csv"
      "/tmp/output.csv"
      "2026-05-21T00:00:00+00:00"
      "2026-05-21T00:00:00+00:00"
      CodexAbsent
      CodexAbsent
      CodexAbsent))
  (CodexAgentJobOk
    (codex:agent-job-loop-start-plan-value
      75
      ((CodexAgentJobLoopRecoverRunningItems "job-1" 75)
       (CodexAgentJobLoopLoadProgress "job-1")
       (CodexAgentJobLoopEmitLoadedProgress "job-1" True)
       (CodexAgentJobLoopCheckCancelled "job-1")))))

!(assertEqual
  (codex:agent-job-loop-cancellation-after-poll
    "job-1"
    False
    True)
  (codex:agent-job-loop-cancellation-state
    True
    ((codex:agent-job-loop-notify
       "agent job job-1 cancellation requested; stopping new workers"))))

!(assertEqual
  (codex:agent-job-loop-cancellation-poll-action "job-1" False)
  (CodexAgentJobLoopCheckCancelled "job-1"))

!(assertEqual
  (codex:agent-job-loop-cancellation-poll-action "job-1" True)
  (CodexAgentJobLoopSkipCancelledCheck))

!(assertEqual
  (codex:agent-job-loop-cancellation-after-poll
    "job-1"
    True
    True)
  (codex:agent-job-loop-cancellation-state True ()))

!(assertEqual
  (codex:agent-job-loop-spawn-pending-gate
    False
    ((CodexAgentJobActiveItem "item-a" 100 CodexAbsent)
     (CodexAgentJobActiveItem
       "item-b"
       110
       (CodexAgentJobStatusRx True (CodexAgentStatusRunning))))
    5)
  (CodexAgentJobSpawnPendingList 3))

!(assertEqual
  (codex:agent-job-loop-spawn-pending-gate
    True
    ((CodexAgentJobActiveItem "item-a" 100 CodexAbsent))
    5)
  (CodexAgentJobSpawnPendingSkip))

!(assertEqual
  (codex:agent-job-loop-no-finished-plan
    True
    (CodexAgentJobProgress 5 2 0 2 1)
    ()
    False)
  (codex:agent-job-loop-no-finished-decision
    (codex:agent-job-loop-control-break)
    ()))

!(assertEqual
  (codex:agent-job-loop-no-finished-plan
    False
    (CodexAgentJobProgress 5 0 0 4 1)
    ()
    False)
  (codex:agent-job-loop-no-finished-decision
    (codex:agent-job-loop-control-break)
    ()))

!(assertEqual
  (codex:agent-job-loop-no-finished-plan
    False
    (CodexAgentJobProgress 5 1 1 2 1)
    ((CodexAgentJobActiveItem "item-a" 100 CodexAbsent))
    False)
  (codex:agent-job-loop-no-finished-decision
    (codex:agent-job-loop-control-continue)
    ((codex:agent-job-loop-wait-for-status-change
       (codex:agent-job-wait-for-status-change-sleep 250)))))

!(assertEqual
  (codex:agent-job-loop-no-finished-plan
    False
    (CodexAgentJobProgress 5 1 1 2 1)
    ((CodexAgentJobActiveItem "item-a" 100 CodexAbsent))
    True)
  (codex:agent-job-loop-no-finished-decision
    (codex:agent-job-loop-control-continue)
    ()))
