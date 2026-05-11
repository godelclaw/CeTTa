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
             ((codex:pattern-token "git"))
             (codex:decision-prompt))
           (codex:prefix-rule
             ((codex:pattern-token "git")
              (codex:pattern-token "commit"))
             (codex:decision-forbidden)
             "history rewrite is blocked")
           (codex:prefix-rule
             ((codex:pattern-token "bash")
              (codex:pattern-token "-c"))
             (codex:decision-allow))))
        ("git" "status"))))
  ("{\"type\":\"needs_approval\",\"reason\":\"`git status` requires approval by policy\",\"proposed_execpolicy_amendment\":null}"))

!(assertEqualToResult
  (json-stringify
    (codex:approval-requirement-json
      (codex:approval-for-command
        (codex:ask-for-approval-on-request)
        (codex:file-system-sandbox-restricted)
        (codex:policy
          ((codex:prefix-rule
             ((codex:pattern-token "git"))
             (codex:decision-prompt))
           (codex:prefix-rule
             ((codex:pattern-token "git")
              (codex:pattern-token "commit"))
             (codex:decision-forbidden)
             "history rewrite is blocked")
           (codex:prefix-rule
             ((codex:pattern-token "bash")
              (codex:pattern-token "-c"))
             (codex:decision-allow))))
        ("git" "commit" "-m" "hi"))))
  ("{\"type\":\"forbidden\",\"reason\":\"`git commit -m hi` rejected: history rewrite is blocked\"}"))
