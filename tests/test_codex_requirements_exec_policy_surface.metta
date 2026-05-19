!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:exec_policy)
!(import! &self codex:requirements_exec_policy)

(= (requirements-test-policy-toml)
   (codex:requirements-exec-policy-toml
     ((codex:requirements-exec-policy-prefix-rule-toml
        ((codex:requirements-exec-policy-pattern-any-of
           ("python" "python3"))
         (codex:requirements-exec-policy-pattern-token "-m")
         (codex:requirements-exec-policy-pattern-token "pip"))
        (codex:requirements-exec-policy-decision-prompt)
        "Package installs need review")
      (codex:requirements-exec-policy-prefix-rule-toml
        ((codex:requirements-exec-policy-pattern-token "rm")
         (codex:requirements-exec-policy-pattern-token "-rf"))
        (codex:requirements-exec-policy-decision-forbidden)))))

!(assertEqualToResult
  (json-stringify
    (codex:check-output-json
      (codex:check-policy
        (codex:requirements-exec-policy-parse-value
          (codex:requirements-exec-policy-to-policy
            (requirements-test-policy-toml)))
        ("python3" "-m" "pip" "install" "requests"))))
  ("{\"matchedRules\":[{\"prefixRuleMatch\":{\"matchedPrefix\":[\"python3\",\"-m\",\"pip\"],\"decision\":\"prompt\",\"justification\":\"Package installs need review\"}}],\"decision\":\"prompt\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:check-output-json
      (codex:check-policy
        (codex:requirements-exec-policy-policy
          (codex:requirements-exec-policy-parse-value
            (codex:requirements-exec-policy-to-requirements-policy
              (requirements-test-policy-toml))))
        ("rm" "-rf" "/tmp/demo"))))
  ("{\"matchedRules\":[{\"prefixRuleMatch\":{\"matchedPrefix\":[\"rm\",\"-rf\"],\"decision\":\"forbidden\"}}],\"decision\":\"forbidden\"}"))

!(assertEqualToResult
  (codex:requirements-exec-policy-parse-error-message
    (codex:requirements-exec-policy-parse-error-value
      (codex:requirements-exec-policy-to-policy
        (codex:requirements-exec-policy-toml ()))))
  ("rules prefix_rules cannot be empty"))

!(assertEqualToResult
  (codex:requirements-exec-policy-parse-error-message
    (codex:requirements-exec-policy-parse-error-value
      (codex:requirements-exec-policy-to-policy
        (codex:requirements-exec-policy-toml
          ((codex:requirements-exec-policy-prefix-rule-toml
             ()
             (codex:requirements-exec-policy-decision-prompt)))))))
  ("rules prefix_rule at index 0 has an empty pattern"))

!(assertEqualToResult
  (codex:requirements-exec-policy-parse-error-message
    (codex:requirements-exec-policy-parse-error-value
      (codex:requirements-exec-policy-to-policy
        (codex:requirements-exec-policy-toml
          ((codex:requirements-exec-policy-prefix-rule-toml
             ((codex:requirements-exec-policy-pattern-token "git"))
             (codex:requirements-exec-policy-decision-prompt)
             "   "))))))
  ("rules prefix_rule at index 0 has an empty justification"))

!(assertEqualToResult
  (codex:requirements-exec-policy-parse-error-message
    (codex:requirements-exec-policy-parse-error-value
      (codex:requirements-exec-policy-to-policy
        (codex:requirements-exec-policy-toml
          ((codex:requirements-exec-policy-prefix-rule-toml
             ((codex:requirements-exec-policy-pattern-token "git"))
             CodexAbsent))))))
  ("rules prefix_rule at index 0 is missing a decision"))

!(assertEqualToResult
  (codex:requirements-exec-policy-parse-error-message
    (codex:requirements-exec-policy-parse-error-value
      (codex:requirements-exec-policy-to-policy
        (codex:requirements-exec-policy-toml
          ((codex:requirements-exec-policy-prefix-rule-toml
             ((codex:requirements-exec-policy-pattern-token "git"))
             (codex:requirements-exec-policy-decision-allow)))))))
  ("rules prefix_rule at index 0 has decision 'allow', which is not permitted in requirements.toml: Codex merges these rules with other config and uses the most restrictive result (use 'prompt' or 'forbidden')"))

!(assertEqualToResult
  (codex:requirements-exec-policy-parse-error-message
    (codex:requirements-exec-policy-parse-error-value
      (codex:requirements-exec-policy-to-policy
        (codex:requirements-exec-policy-toml
          ((codex:requirements-exec-policy-prefix-rule-toml
             ((codex:requirements-exec-policy-pattern-token "git")
              (codex:requirements-exec-policy-pattern-token " "))
             (codex:requirements-exec-policy-decision-prompt)))))))
  ("rules prefix_rule at index 0 has an invalid pattern token at index 1: token cannot be empty"))

!(assertEqualToResult
  (codex:requirements-exec-policy-parse-error-message
    (codex:requirements-exec-policy-parse-error-value
      (codex:requirements-exec-policy-to-policy
        (codex:requirements-exec-policy-toml
          ((codex:requirements-exec-policy-prefix-rule-toml
             ((codex:requirements-exec-policy-pattern-any-of ()))
             (codex:requirements-exec-policy-decision-prompt)))))))
  ("rules prefix_rule at index 0 has an invalid pattern token at index 0: any_of cannot be empty"))

!(assertEqualToResult
  (codex:requirements-exec-policy-parse-error-message
    (codex:requirements-exec-policy-parse-error-value
      (codex:requirements-exec-policy-to-policy
        (codex:requirements-exec-policy-toml
          ((codex:requirements-exec-policy-prefix-rule-toml
             ((codex:requirements-exec-policy-pattern-any-of
                ("git" " ")))
             (codex:requirements-exec-policy-decision-prompt)))))))
  ("rules prefix_rule at index 0 has an invalid pattern token at index 0: any_of cannot include empty tokens"))

!(assertEqualToResult
  (codex:requirements-exec-policy-parse-error-message
    (codex:requirements-exec-policy-parse-error-value
      (codex:requirements-exec-policy-to-policy
        (codex:requirements-exec-policy-toml
          ((codex:requirements-exec-policy-prefix-rule-toml
             ((codex:requirements-exec-policy-pattern-token-raw
                "git"
                ("rg")))
             (codex:requirements-exec-policy-decision-prompt)))))))
  ("rules prefix_rule at index 0 has an invalid pattern token at index 0: set either token or any_of, not both"))

!(assertEqualToResult
  (codex:requirements-exec-policy-parse-error-message
    (codex:requirements-exec-policy-parse-error-value
      (codex:requirements-exec-policy-to-policy
        (codex:requirements-exec-policy-toml
          ((codex:requirements-exec-policy-prefix-rule-toml
             ((codex:requirements-exec-policy-pattern-token-raw
                CodexAbsent
                CodexAbsent))
             (codex:requirements-exec-policy-decision-prompt)))))))
  ("rules prefix_rule at index 0 has an invalid pattern token at index 0: set either token or any_of"))
