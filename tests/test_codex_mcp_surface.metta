!(register-module! ../codex)
!(import! &self codex:approval)
!(import! &self codex:mcp)

!(assertEqualToResult
  (codex:mcp-permission-prompt-is-auto-approved
    (codex:ask-for-approval-never)
    (codex:approval-sandbox-policy-danger-full-access))
  (True))

!(assertEqualToResult
  (codex:mcp-permission-prompt-is-auto-approved
    (codex:ask-for-approval-never)
    (codex:approval-sandbox-policy-external-sandbox))
  (True))

!(assertEqualToResult
  (codex:mcp-permission-prompt-is-auto-approved
    (codex:ask-for-approval-never)
    (codex:approval-sandbox-policy-read-only))
  (False))

!(assertEqualToResult
  (codex:mcp-permission-prompt-is-auto-approved
    (codex:ask-for-approval-never)
    (codex:approval-sandbox-policy-workspace-write))
  (False))

!(assertEqualToResult
  (codex:mcp-permission-prompt-is-auto-approved
    (codex:ask-for-approval-on-request)
    (codex:approval-sandbox-policy-danger-full-access))
  (False))

!(assertEqualToResult
  (codex:mcp-permission-prompt-is-auto-approved
    (codex:ask-for-approval-granular True)
    (codex:approval-sandbox-policy-external-sandbox))
  (False))
