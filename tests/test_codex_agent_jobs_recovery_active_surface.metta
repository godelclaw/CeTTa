!(register-module! ../codex)
!(import! &self codex:agent_jobs_recovery)
!(import! &self codex:protocol)

!(assertEqual
  (codex:agent-job-recover-running-item
    (codex:agent-job-recovery-item "item-5" "67E5504410B1426F9247BB680E5FE0C8" 900)
    1000
    1800
    (codex:protocol-agent-status-interrupted))
  (CodexAgentJobRecoveryActivate
    "item-5"
    "67e55044-10b1-426f-9247-bb680e5fe0c8"
    900))

!(assertEqual
  (codex:agent-job-started-at-from-item 1000 900 500)
  400)

!(assertEqual
  (codex:agent-job-started-at-from-item 1000 1100 500)
  500)

!(assertEqual
  (codex:agent-job-started-at-from-item 1000 100 500)
  500)

!(assertEqual
  (codex:agent-job-recover-running-item-with-clock
    (codex:agent-job-recovery-item "item-6" "67E5504410B1426F9247BB680E5FE0C8" 900)
    1000
    1800
    (codex:protocol-agent-status-interrupted)
    500)
  (CodexAgentJobRecoveryActivate
    "item-6"
    "67e55044-10b1-426f-9247-bb680e5fe0c8"
    400))
