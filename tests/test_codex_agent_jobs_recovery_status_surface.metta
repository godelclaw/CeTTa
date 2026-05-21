!(register-module! ../codex)
!(import! &self codex:agent_jobs_recovery)
!(import! &self codex:protocol)

!(assertEqual
  (codex:agent-job-recover-running-item
    (codex:agent-job-recovery-item "item-4" "67E5504410B1426F9247BB680E5FE0C8" 900)
    1000
    1800
    (codex:protocol-agent-status-completed "done"))
  (CodexAgentJobRecoveryFinalize
    "item-4"
    "67e55044-10b1-426f-9247-bb680e5fe0c8"))
