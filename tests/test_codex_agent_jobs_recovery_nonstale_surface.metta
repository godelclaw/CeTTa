!(register-module! ../codex)
!(import! &self codex:agent_jobs_recovery)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:agent-job-recover-running-item
    (codex:agent-job-recovery-item "item-2" CodexAbsent 900)
    1000
    1800
    (codex:protocol-agent-status-running))
  ((CodexAgentJobRecoveryMarkFailed
     "item-2"
     "running item is missing assigned_thread_id"
     CodexAbsent)))

!(assertEqualToResult
  (codex:agent-job-recover-running-item
    (codex:agent-job-recovery-item "item-3" "not-a-uuid" 900)
    1000
    1800
    (codex:protocol-agent-status-running))
  ((CodexAgentJobRecoveryMarkFailed
     "item-3"
     "invalid assigned_thread_id: Error(ParseChar { character: 'n', index: 1 })"
     CodexAbsent)))
