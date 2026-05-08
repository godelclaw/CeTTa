!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:approval)
!(import! &self codex:exec_policy)

!(println! "=== Codex approval demo ===")
!(println!
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
        ("git" "status")))))
!(println!
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
        ("git" "commit" "-m" "hi")))))
!(println!
  (json-stringify
    (codex:approval-requirement-json
      (codex:approval-for-command
        (codex:ask-for-approval-unless-trusted)
        (codex:file-system-sandbox-restricted)
        (codex:policy ())
        ("rg" "-n" "TODO" "src")))))
!(println!
  (json-stringify
    (codex:approval-requirement-json
      (codex:approval-for-command
        (codex:ask-for-approval-on-request)
        (codex:file-system-sandbox-restricted)
        (codex:policy
          ((codex:prefix-rule
             ((codex:pattern-token "echo"))
             (codex:decision-allow))))
        ("echo" "hi")))))
