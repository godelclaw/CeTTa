!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:exec_policy)

!(println! "=== Codex exec_policy demo ===")
!(println!
  (json-stringify
    (codex:check-output-json
      (codex:check-policy
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
             ((codex:pattern-any-of ("bash" "sh"))
              (codex:pattern-any-of ("-c" "-lc"))))))
        ("git" "status")))))
!(println!
  (json-stringify
    (codex:check-output-json
      (codex:check-policy
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
             ((codex:pattern-any-of ("bash" "sh"))
              (codex:pattern-any-of ("-c" "-lc"))))))
        ("git" "commit" "-m" "hi")))))
!(println!
  (json-stringify
    (codex:check-output-json
      (codex:check-policy
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
             ((codex:pattern-any-of ("bash" "sh"))
              (codex:pattern-any-of ("-c" "-lc"))))))
        ("bash" "-c" "echo hi")))))
!(println!
  (json-stringify
    (codex:check-output-json
      (codex:check-policy
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
             ((codex:pattern-any-of ("bash" "sh"))
              (codex:pattern-any-of ("-c" "-lc"))))))
        ("rg" "-n" "TODO" "src")))))
