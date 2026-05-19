!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:approval)
!(import! &self codex:exec_policy)

!(assertEqualToResult
  (json-stringify
    (codex:approval-requirement-json
      (codex:approval-for-command-with-sandbox
        (codex:ask-for-approval-on-request)
        (codex:approval-sandbox-policy-danger-full-access)
        (codex:file-system-sandbox-restricted)
        (codex:approval-sandbox-permissions-require-escalated)
        (codex:policy ())
        ("madeup-cmd"))))
  ("{\"type\":\"needs_approval\",\"reason\":null,\"proposed_execpolicy_amendment\":[\"madeup-cmd\"]}"))

!(assertEqualToResult
  (json-stringify
    (codex:approval-requirement-json
      (codex:approval-for-command-with-sandbox
        (codex:ask-for-approval-on-request)
        (codex:approval-sandbox-policy-read-only)
        (codex:file-system-sandbox-restricted)
        (codex:approval-sandbox-permissions-use-default)
        (codex:policy ())
        ("madeup-cmd"))))
  ("{\"type\":\"skip\",\"bypass_sandbox\":false,\"proposed_execpolicy_amendment\":[\"madeup-cmd\"]}"))

!(assertEqualToResult
  (json-stringify
    (codex:approval-requirement-json
      (codex:approval-for-command-with-sandbox
        (codex:ask-for-approval-granular-config
          False
          True
          True
          True
          True)
        (codex:approval-sandbox-policy-read-only)
        (codex:file-system-sandbox-restricted)
        (codex:approval-sandbox-permissions-require-escalated)
        (codex:policy ())
        ("madeup-cmd"))))
  ("{\"type\":\"forbidden\",\"reason\":\"approval required by policy, but AskForApproval::Granular.sandbox_approval is false\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:approval-requirement-json
      (codex:approval-for-command-with-sandbox
        (codex:ask-for-approval-granular-config
          True
          False
          True
          True
          True)
        (codex:approval-sandbox-policy-read-only)
        (codex:file-system-sandbox-restricted)
        (codex:approval-sandbox-permissions-require-escalated)
        (codex:policy
          ((codex:prefix-rule
             ((codex:pattern-token "git"))
             (codex:decision-prompt))))
        ("bash" "-lc" "git status && madeup-cmd"))))
  ("{\"type\":\"forbidden\",\"reason\":\"approval required by policy rule, but AskForApproval::Granular.rules is false\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:approval-requirement-json
      (codex:approval-for-command-with-sandbox
        (codex:ask-for-approval-never)
        (codex:approval-sandbox-policy-external-sandbox)
        (codex:file-system-sandbox-external-sandbox)
        (codex:approval-sandbox-permissions-use-default)
        (codex:policy ())
        ("rm" "-rf" "/tmp/codex"))))
  ("{\"type\":\"skip\",\"bypass_sandbox\":false,\"proposed_execpolicy_amendment\":[\"rm\",\"-rf\",\"/tmp/codex\"]}"))
