!(register-module! ../codex)
!(import! &self codex:agent_jobs_recovery)

!(assertEqualToResult
  (codex:agent-job-is-item-stale 2000 200 1800)
  (True))

!(assertEqualToResult
  (codex:agent-job-is-item-stale 1999 200 1800)
  (False))

!(assertEqualToResult
  (codex:agent-job-is-item-stale 100 200 1800)
  (False))
