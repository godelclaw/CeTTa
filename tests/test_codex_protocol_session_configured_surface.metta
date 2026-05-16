!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:item-type
    (codex:session-configured-event
      "session-1"
      CodexAbsent
      CodexAbsent
      "gpt-5"
      "openai"
      CodexAbsent
      (codex:session-approval-policy-never)
      (codex:session-approvals-reviewer-user)
      (codex:session-sandbox-policy-read-only
        (codex:session-read-only-access-full)
        False)
      CodexAbsent
      "/home/user/project"
      (codex:session-reasoning-effort-medium)
      0
      0
      CodexAbsent
      CodexAbsent
      "/tmp/rollout.jsonl"))
  ("session_configured"))
