!(register-module! ../codex)
!(import! &self codex:approval)
!(import! &self codex:cli_args)

!(assertEqualToResult
  (codex:approval-mode-cli-arg-to-ask-for-approval
    (codex:approval-mode-cli-arg-untrusted))
  ("unless_trusted"))

!(assertEqualToResult
  (codex:approval-mode-cli-arg-to-ask-for-approval
    (codex:approval-mode-cli-arg-on-failure))
  ("on_failure"))

!(assertEqualToResult
  (codex:approval-mode-cli-arg-to-ask-for-approval
    (codex:approval-mode-cli-arg-on-request))
  ("on_request"))

!(assertEqualToResult
  (codex:approval-mode-cli-arg-to-ask-for-approval
    (codex:approval-mode-cli-arg-never))
  ("never"))

!(assertEqualToResult
  (codex:approval-mode-cli-arg-kebab
    (codex:approval-mode-cli-arg-on-request))
  ("on-request"))

!(assertEqualToResult
  (codex:approval-mode-cli-arg-kebab
    (codex:approval-mode-cli-arg-from-kebab "on-failure"))
  ("on-failure"))

!(assertEqualToResult
  (codex:approval-mode-cli-arg-from-kebab "bogus")
  (CodexAbsent))

!(assertEqualToResult
  (codex:sandbox-mode-kebab
    (codex:sandbox-mode-cli-arg-to-sandbox-mode
      (codex:sandbox-mode-cli-arg-read-only)))
  ("read-only"))

!(assertEqualToResult
  (codex:sandbox-mode-kebab
    (codex:sandbox-mode-cli-arg-to-sandbox-mode
      (codex:sandbox-mode-cli-arg-workspace-write)))
  ("workspace-write"))

!(assertEqualToResult
  (codex:sandbox-mode-kebab
    (codex:sandbox-mode-cli-arg-to-sandbox-mode
      (codex:sandbox-mode-cli-arg-danger-full-access)))
  ("danger-full-access"))

!(assertEqualToResult
  (codex:sandbox-mode-cli-arg-kebab
    (codex:sandbox-mode-cli-arg-danger-full-access))
  ("danger-full-access"))

!(assertEqualToResult
  (codex:sandbox-mode-kebab
    (codex:sandbox-mode-workspace-write))
  ("workspace-write"))

!(assertEqualToResult
  (codex:sandbox-mode-cli-arg-kebab
    (codex:sandbox-mode-cli-arg-from-kebab "workspace-write"))
  ("workspace-write"))

!(assertEqualToResult
  (codex:sandbox-mode-cli-arg-from-kebab "bad")
  (CodexAbsent))
