!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:exec_policy)

!(assertEqualToResult
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
             (codex:decision-forbidden))
           (codex:prefix-rule
             ((codex:pattern-any-of ("bash" "sh"))
              (codex:pattern-any-of ("-c" "-l"))))))
        ("git" "status"))))
  ("{\"matchedRules\":[{\"prefixRuleMatch\":{\"matchedPrefix\":[\"git\"],\"decision\":\"prompt\"}}],\"decision\":\"prompt\"}"))

!(assertEqualToResult
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
             (codex:decision-forbidden))
           (codex:prefix-rule
             ((codex:pattern-any-of ("bash" "sh"))
              (codex:pattern-any-of ("-c" "-l"))))))
        ("git" "commit" "-m" "hi"))))
  ("{\"matchedRules\":[{\"prefixRuleMatch\":{\"matchedPrefix\":[\"git\"],\"decision\":\"prompt\"}},{\"prefixRuleMatch\":{\"matchedPrefix\":[\"git\",\"commit\"],\"decision\":\"forbidden\"}}],\"decision\":\"forbidden\"}"))

!(assertEqualToResult
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
             (codex:decision-forbidden))
           (codex:prefix-rule
             ((codex:pattern-any-of ("bash" "sh"))
              (codex:pattern-any-of ("-c" "-l"))))))
        ("bash" "-c" "echo hi"))))
  ("{\"matchedRules\":[{\"prefixRuleMatch\":{\"matchedPrefix\":[\"bash\",\"-c\"],\"decision\":\"allow\"}}],\"decision\":\"allow\"}"))

!(assertEqualToResult
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
             (codex:decision-forbidden))
           (codex:prefix-rule
             ((codex:pattern-any-of ("bash" "sh"))
              (codex:pattern-any-of ("-c" "-l"))))))
        ("rg" "-n" "TODO" "src"))))
  ("{\"matchedRules\":[]}"))

!(assertEqualToResult
  (json-stringify
    (codex:check-output-json
      (codex:check-policy-multiple
        (codex:policy
          ((codex:prefix-rule
             ((codex:pattern-token "git"))
             (codex:decision-prompt))
           (codex:prefix-rule
             ((codex:pattern-token "git")
              (codex:pattern-token "commit"))
             (codex:decision-forbidden))
           (codex:prefix-rule
             ((codex:pattern-any-of ("bash" "sh"))
              (codex:pattern-any-of ("-c" "-l"))))))
        (("git" "status")
         ("git" "commit" "-m" "hi")))))
  ("{\"matchedRules\":[{\"prefixRuleMatch\":{\"matchedPrefix\":[\"git\"],\"decision\":\"prompt\"}},{\"prefixRuleMatch\":{\"matchedPrefix\":[\"git\"],\"decision\":\"prompt\"}},{\"prefixRuleMatch\":{\"matchedPrefix\":[\"git\",\"commit\"],\"decision\":\"forbidden\"}}],\"decision\":\"forbidden\"}"))
