!(register-module! ../codex)
!(import! &self codex:commit_attribution)
!(import! &self str)

!(assertEqualToResult
  (codex:build-commit-message-trailer "")
  (Empty))

!(assertEqualToResult
  (codex:commit-message-trailer-instruction "   ")
  (Empty))

!(assertEqualToResult
  (codex:build-commit-message-trailer CodexAbsent)
  ("Co-authored-by: Codex <noreply@openai.com>"))

!(assertEqualToResult
  (codex:resolve-attribution-value CodexAbsent)
  ("Codex <noreply@openai.com>"))

!(assertEqualToResult
  (codex:resolve-attribution-value "MyAgent <me@example.com>")
  ("MyAgent <me@example.com>"))

!(assertEqualToResult
  (codex:resolve-attribution-value "MyAgent")
  ("MyAgent"))

!(assertEqualToResult
  (codex:resolve-attribution-value "   ")
  (Empty))

!(assertEqualToResult
  (codex:commit-message-trailer-instruction "AgentX <agent@example.com>")
  ("When you write or edit a git commit message, ensure the message ends with this trailer exactly once:\nCo-authored-by: AgentX <agent@example.com>\n\nRules:\n- Keep existing trailers and append this trailer at the end if missing.\n- Do not duplicate this trailer if it already exists.\n- Keep one blank line between the commit body and trailer block."))
