!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:approval)
!(import! &self codex:exec_policy)

!(assertEqualToResult
  (json-stringify
    (codex:approval-requirement-json
      (codex:approval-for-command
        (codex:ask-for-approval-on-request)
        (codex:file-system-sandbox-restricted)
        (codex:policy
          ((codex:prefix-rule
             ((codex:pattern-token "echo"))
             (codex:decision-allow))))
        ("echo" "hi"))))
  ("{\"type\":\"skip\",\"bypass_sandbox\":true,\"proposed_execpolicy_amendment\":null}"))

!(assertEqualToResult
  (json-stringify
    (codex:approval-requirement-json
      (codex:approval-for-command
        (codex:ask-for-approval-never)
        (codex:file-system-sandbox-restricted)
        (codex:policy
          ((codex:prefix-rule
             ((codex:pattern-token "git"))
             (codex:decision-prompt))))
        ("git" "status"))))
  ("{\"type\":\"forbidden\",\"reason\":\"approval required by policy, but AskForApproval is set to Never\"}"))
