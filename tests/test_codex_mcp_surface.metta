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

!(assertEqual
  (codex:resolve-mcp-oauth-scopes
    ("explicit")
    ("configured")
    ("discovered"))
  (codex:resolved-mcp-oauth-scopes
    ("explicit")
    (codex:mcp-oauth-scopes-source-explicit)))

!(assertEqual
  (codex:resolve-mcp-oauth-scopes
    CodexAbsent
    ("configured")
    ("discovered"))
  (codex:resolved-mcp-oauth-scopes
    ("configured")
    (codex:mcp-oauth-scopes-source-configured)))

!(assertEqual
  (codex:resolve-mcp-oauth-scopes
    CodexAbsent
    CodexAbsent
    ("discovered"))
  (codex:resolved-mcp-oauth-scopes
    ("discovered")
    (codex:mcp-oauth-scopes-source-discovered)))

!(assertEqual
  (codex:resolve-mcp-oauth-scopes
    CodexAbsent
    ()
    ("ignored"))
  (codex:resolved-mcp-oauth-scopes
    ()
    (codex:mcp-oauth-scopes-source-configured)))

!(assertEqual
  (codex:resolve-mcp-oauth-scopes
    CodexAbsent
    CodexAbsent
    CodexAbsent)
  (codex:resolved-mcp-oauth-scopes
    ()
    (codex:mcp-oauth-scopes-source-empty)))

!(assertEqual
  (codex:resolve-mcp-oauth-scopes
    CodexAbsent
    CodexAbsent
    ())
  (codex:resolved-mcp-oauth-scopes
    ()
    (codex:mcp-oauth-scopes-source-empty)))

!(assertEqual
  (codex:mcp-oauth-should-retry-without-scopes
    (codex:resolved-mcp-oauth-scopes
      ("scope")
      (codex:mcp-oauth-scopes-source-discovered))
    (codex:mcp-oauth-provider-error
      "invalid_scope"
      "scope rejected"))
  True)

!(assertEqual
  (codex:mcp-oauth-should-retry-without-scopes
    (codex:resolved-mcp-oauth-scopes
      ("scope")
      (codex:mcp-oauth-scopes-source-configured))
    (codex:mcp-oauth-provider-error
      "invalid_scope"
      "scope rejected"))
  False)

!(assertEqual
  (codex:mcp-oauth-should-retry-without-scopes
    (codex:resolved-mcp-oauth-scopes
      ("scope")
      (codex:mcp-oauth-scopes-source-discovered))
    "timed out waiting for OAuth callback")
  False)
