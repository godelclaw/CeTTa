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

!(assertEqualToResult
  (json-stringify
    (codex:check-output-json
      (codex:check-policy-with-options
        (codex:policy-with-host-executables
          ((codex:prefix-rule
             ((codex:pattern-token "rg")
              (codex:pattern-token "--files"))
             (codex:decision-prompt)
             "host rg requires approval"))
          ((codex:host-executable "rg" ("/usr/bin/rg"))))
        ("/usr/bin/rg" "--files" ".")
        (codex:match-options True))))
  ("{\"matchedRules\":[{\"prefixRuleMatch\":{\"matchedPrefix\":[\"rg\",\"--files\"],\"decision\":\"prompt\",\"resolvedProgram\":\"/usr/bin/rg\",\"justification\":\"host rg requires approval\"}}],\"decision\":\"prompt\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:check-output-json
      (codex:check-policy-with-options
        (codex:policy
          ((codex:prefix-rule
             ((codex:pattern-token "rg"))
             (codex:decision-prompt))))
        ("/opt/tools/rg" "--files")
        (codex:match-options True))))
  ("{\"matchedRules\":[{\"prefixRuleMatch\":{\"matchedPrefix\":[\"rg\"],\"decision\":\"prompt\",\"resolvedProgram\":\"/opt/tools/rg\"}}],\"decision\":\"prompt\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:check-output-json
      (codex:check-policy-with-options
        (codex:policy-with-host-executables
          ((codex:prefix-rule
             ((codex:pattern-token "rg")
              (codex:pattern-token "--files"))
             (codex:decision-prompt)))
          ((codex:host-executable "rg" ("/usr/local/bin/rg"))))
        ("/usr/bin/rg" "--files" ".")
        (codex:match-options True))))
  ("{\"matchedRules\":[]}"))

!(assertEqualToResult
  (json-stringify
    (codex:check-output-json
      (codex:check-policy-with-options
        (codex:policy-with-host-executables
          ((codex:prefix-rule
             ((codex:pattern-token "/usr/bin/rg"))
             (codex:decision-allow))
           (codex:prefix-rule
             ((codex:pattern-token "rg"))
             (codex:decision-forbidden)))
          ((codex:host-executable "rg" ("/usr/bin/rg"))))
        ("/usr/bin/rg" "--files" ".")
        (codex:match-options True))))
  ("{\"matchedRules\":[{\"prefixRuleMatch\":{\"matchedPrefix\":[\"/usr/bin/rg\"],\"decision\":\"allow\"}}],\"decision\":\"allow\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:check-output-json
      (codex:check-policy-with-heuristics
        (codex:policy ())
        ("unknown" "--flag")
        (codex:heuristics-fallback-decision (codex:decision-prompt)))))
  ("{\"matchedRules\":[{\"heuristicsRuleMatch\":{\"command\":[\"unknown\",\"--flag\"],\"decision\":\"prompt\"}}],\"decision\":\"prompt\"}"))
