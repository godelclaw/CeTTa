!(register-module! ../codex)
!(import! &self codex:agent_jobs_recovery)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:agent-job-recover-running-item
    (codex:agent-job-recovery-item "item-1" "67E5504410B1426F9247BB680E5FE0C8" 200)
    2000
    1800
    (codex:protocol-agent-status-running))
  ((CodexAgentJobRecoveryMarkFailed
     "item-1"
     "worker exceeded max runtime of 1800s"
     "67e55044-10b1-426f-9247-bb680e5fe0c8")))

!(assertEqualToResult
  (codex:agent-job-recover-running-item
    (codex:agent-job-recovery-item "item-1" "not-a-uuid" 200)
    2000
    1800
    (codex:protocol-agent-status-running))
  ((CodexAgentJobRecoveryMarkFailed
     "item-1"
     "worker exceeded max runtime of 1800s"
     CodexAbsent)))
