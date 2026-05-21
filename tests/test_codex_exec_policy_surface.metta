!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:exec_policy)
!(import! &self codex:requirements_exec_policy)

!(assertEqualToResult
  (codex:child-uses-parent-exec-policy
    (codex:exec-policy-config-summary
      ("/etc/codex" "/home/z/.codex" "/repo/.codex")
      False
      "required")
    (codex:exec-policy-config-summary
      ("/etc/codex" "/home/z/.codex" "/repo/.codex")
      False
      "required"))
  (True))

!(assertEqualToResult
  (codex:child-uses-parent-exec-policy
    (codex:exec-policy-config-summary
      ("/etc/codex" "/home/z/.codex" "/repo/.codex")
      False
      "required")
    (codex:exec-policy-config-summary
      ("/home/z/.codex" "/etc/codex" "/repo/.codex")
      False
      "required"))
  (False))

!(assertEqualToResult
  (codex:child-uses-parent-exec-policy
    (codex:exec-policy-config-summary
      ("/etc/codex" "/home/z/.codex" "/repo/.codex")
      False
      "required")
    (codex:exec-policy-config-summary
      ("/etc/codex" "/home/z/.codex")
      False
      "required"))
  (False))

!(assertEqualToResult
  (codex:child-uses-parent-exec-policy
    (codex:exec-policy-config-summary
      ("/etc/codex" "/home/z/.codex" "/repo/.codex")
      False
      "required")
    (codex:exec-policy-config-summary
      ("/etc/codex" "/home/z/.codex" "/repo/.codex")
      True
      "required"))
  (False))

!(assertEqualToResult
  (codex:child-uses-parent-exec-policy
    (codex:exec-policy-config-summary
      ("/etc/codex" "/home/z/.codex" "/repo/.codex")
      False
      "required")
    (codex:exec-policy-config-summary
      ("/etc/codex" "/home/z/.codex" "/repo/.codex")
      False
      CodexAbsent))
  (False))

!(assertEqual
  (codex:exec-policy-parse-starlark-line-from-message
    "/tmp/default.rules:7:11: starlark error: unexpected token")
  (codex:exec-policy-source-location "/tmp/default.rules" 7))

!(assertEqual
  (codex:exec-policy-parse-starlark-line-from-message
    "/tmp/default.rules:0:11: starlark error: unexpected token")
  CodexAbsent)

!(assertEqual
  (codex:exec-policy-message-for-display
    (codex:exec-policy-parse-source-error
      "note\n  error: expected list\nhelp"
      CodexAbsent))
  "  error: expected list")

!(assertEqual
  (codex:exec-policy-message-for-display
    (codex:exec-policy-parse-source-error
      "/tmp/default.rules:7:11: starlark error: unexpected token"
      CodexAbsent))
  "unexpected token")

!(assertEqual
  (codex:format-exec-policy-error-with-source
    (codex:exec-policy-error-parse-policy
      "configured-path.rules"
      (codex:exec-policy-parse-source-error
        "/tmp/default.rules:7:11: starlark error: unexpected token"
        CodexAbsent)))
  "/tmp/default.rules:7: unexpected token (problem is on or around line 7)")

!(assertEqual
  (codex:format-exec-policy-error-with-source
    (codex:exec-policy-error-parse-policy
      "configured-path.rules"
      (codex:exec-policy-parse-source-error
        "/tmp/default.rules:7:11: starlark error: unexpected token"
        (codex:exec-policy-source-location "/structured.rules" 4))))
  "/structured.rules:4: unexpected token (problem is on or around line 4)")

!(assertEqual
  (codex:format-exec-policy-error-with-source
    (codex:exec-policy-error-parse-policy
      "configured-path.rules"
      (codex:exec-policy-parse-source-error
        "/tmp/default.rules:7:11: starlark error: unexpected token"
        (codex:exec-policy-source-location "/structured.rules" 1))))
  "/tmp/default.rules:7: unexpected token (problem is on or around line 7)")

!(assertEqual
  (codex:format-exec-policy-error-with-source
    (codex:exec-policy-error-parse-policy
      "configured-path.rules"
      (codex:exec-policy-parse-source-error
        "plain parser failure"
        CodexAbsent)))
  "configured-path.rules: plain parser failure")

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

!(assertEqualToResult
  (codex:parse-network-rule-protocol "https_connect")
  ((CodexExecPolicyNetworkRuleProtocolOk
     (CodexExecPolicyNetworkRuleProtocolHttps))))

!(assertEqualToResult
  (codex:network-rule-protocol-policy-string
    (codex:network-rule-protocol-socks5-udp))
  ("socks5_udp"))

!(assertEqualToResult
  (codex:parse-network-rule-decision "deny")
  ("forbidden"))

!(assertEqualToResult
  (codex:normalize-network-rule-host " Api.GitHub.com.:443 ")
  ((CodexExecPolicyNetworkRuleHostOk "api.github.com")))

!(assertEqualToResult
  (codex:normalize-network-rule-host "[2001:DB8::1]:443")
  ((CodexExecPolicyNetworkRuleHostOk "2001:db8::1")))

!(assertEqualToResult
  (codex:normalize-network-rule-host "https://api.github.com")
  ((CodexExecPolicyNetworkRuleHostError
     "network_rule host must be a hostname or IP literal (without scheme or path)")))

!(assertEqualToResult
  (codex:normalize-network-rule-host "*.example.com")
  ((CodexExecPolicyNetworkRuleHostError
     "network_rule host must be a specific host; wildcards are not allowed")))

!(assertEqualToResult
  (codex:normalize-network-rule-host "[::1]suffix")
  ((CodexExecPolicyNetworkRuleHostError
     "network_rule host contains an unsupported suffix: [::1]suffix")))

!(assertEqualToResult
  (codex:network-rule
    "Api.GitHub.com"
    (codex:network-rule-protocol-https)
    (codex:decision-allow)
    "Allow API")
  ((CodexExecPolicyNetworkRule
     "api.github.com"
     (CodexExecPolicyNetworkRuleProtocolHttps)
     "allow"
     "Allow API")))

!(assertEqualToResult
  (json-stringify
    (codex:compiled-network-domains-json
      (codex:compiled-network-domains
        (codex:policy-with-network-rules
          ()
          ((codex:network-rule
             "api.github.com"
             (codex:network-rule-protocol-https)
             (codex:decision-allow))
           (codex:network-rule
             "bad.example"
             (codex:network-rule-protocol-http)
             (codex:decision-forbidden))
           (codex:network-rule
             "prompt.example"
             (codex:network-rule-protocol-http)
             (codex:decision-prompt))
           (codex:network-rule
             "api.github.com"
             (codex:network-rule-protocol-https)
             (codex:decision-forbidden))
           (codex:network-rule
             "bad.example"
             (codex:network-rule-protocol-http)
             (codex:decision-allow)))))))
  ("{\"allowed\":[\"bad.example\"],\"denied\":[\"api.github.com\"]}"))

!(assertEqualToResult
  (codex:policy-allowed-prefixes
    (codex:policy
      ((codex:prefix-rule
         ((codex:pattern-token "z")))
       (codex:prefix-rule
         ((codex:pattern-token "a")))
       (codex:prefix-rule
         ((codex:pattern-token "a")))
       (codex:prefix-rule
         ((codex:pattern-any-of ("sh" "bash"))
          (codex:pattern-any-of ("-c" "-lc"))))
       (codex:prefix-rule
         ((codex:pattern-token "git"))
         (codex:decision-prompt)))))
  ((("a") ("bash" "[-c|-lc]") ("sh" "[-c|-lc]") ("z"))))

!(assertEqualToResult
  (codex:policy-add-prefix-rule
    (codex:policy ())
    ()
    (codex:decision-forbidden))
  ((CodexExecPolicyRuleError "prefix cannot be empty")))

!(assertEqualToResult
  (json-stringify
    (codex:check-output-json
      (codex:check-policy
        (codex:policy-add-prefix-rule
          (codex:policy ())
          ("rm")
          (codex:decision-forbidden))
        ("rm" "-rf" "/tmp/demo"))))
  ("{\"matchedRules\":[{\"prefixRuleMatch\":{\"matchedPrefix\":[\"rm\"],\"decision\":\"forbidden\"}}],\"decision\":\"forbidden\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:check-output-json
      (codex:check-policy-with-options
        (codex:set-host-executable-paths
          (codex:set-host-executable-paths
            (codex:policy
              ((codex:prefix-rule
                 ((codex:pattern-token "rg"))
                 (codex:decision-prompt))))
            "rg"
            ("/usr/local/bin/rg"))
          "rg"
          ("/usr/bin/rg"))
        ("/usr/local/bin/rg" "--files")
        (codex:match-options True))))
  ("{\"matchedRules\":[]}"))

!(assertEqualToResult
  (json-stringify
    (codex:check-output-json
      (codex:check-policy-with-options
        (codex:set-host-executable-paths
          (codex:set-host-executable-paths
            (codex:policy
              ((codex:prefix-rule
                 ((codex:pattern-token "rg"))
                 (codex:decision-prompt))))
            "rg"
            ("/usr/local/bin/rg"))
          "rg"
          ("/usr/bin/rg"))
        ("/usr/bin/rg" "--files")
        (codex:match-options True))))
  ("{\"matchedRules\":[{\"prefixRuleMatch\":{\"matchedPrefix\":[\"rg\"],\"decision\":\"prompt\",\"resolvedProgram\":\"/usr/bin/rg\"}}],\"decision\":\"prompt\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:check-output-json
      (codex:check-policy
        (codex:policy-merge-overlay
          (codex:policy
            ((codex:prefix-rule
               ((codex:pattern-token "git"))
               (codex:decision-allow))))
          (codex:policy
            ((codex:prefix-rule
               ((codex:pattern-token "git")
                (codex:pattern-token "commit"))
               (codex:decision-forbidden)))))
        ("git" "commit" "-m" "hi"))))
  ("{\"matchedRules\":[{\"prefixRuleMatch\":{\"matchedPrefix\":[\"git\"],\"decision\":\"allow\"}},{\"prefixRuleMatch\":{\"matchedPrefix\":[\"git\",\"commit\"],\"decision\":\"forbidden\"}}],\"decision\":\"forbidden\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:check-output-json
      (codex:check-policy-with-options
        (codex:policy-merge-overlay
          (codex:policy-with-host-executables
            ((codex:prefix-rule
               ((codex:pattern-token "git"))
               (codex:decision-allow)))
            ((codex:host-executable "git" ("/usr/bin/git"))))
          (codex:policy-with-host-executables
            ((codex:prefix-rule
               ((codex:pattern-token "git")
                (codex:pattern-token "commit"))
               (codex:decision-forbidden)))
            ((codex:host-executable "git" ("/opt/git")))))
        ("/usr/bin/git" "commit")
        (codex:match-options True))))
  ("{\"matchedRules\":[]}"))

!(assertEqualToResult
  (json-stringify
    (codex:check-output-json
      (codex:check-policy-with-options
        (codex:policy-merge-overlay
          (codex:policy-with-host-executables
            ((codex:prefix-rule
               ((codex:pattern-token "git"))
               (codex:decision-allow)))
            ((codex:host-executable "git" ("/usr/bin/git"))))
          (codex:policy-with-host-executables
            ((codex:prefix-rule
               ((codex:pattern-token "git")
                (codex:pattern-token "commit"))
               (codex:decision-forbidden)))
            ((codex:host-executable "git" ("/opt/git")))))
        ("/opt/git" "commit")
        (codex:match-options True))))
  ("{\"matchedRules\":[{\"prefixRuleMatch\":{\"matchedPrefix\":[\"git\"],\"decision\":\"allow\",\"resolvedProgram\":\"/opt/git\"}},{\"prefixRuleMatch\":{\"matchedPrefix\":[\"git\",\"commit\"],\"decision\":\"forbidden\",\"resolvedProgram\":\"/opt/git\"}}],\"decision\":\"forbidden\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:compiled-network-domains-json
      (codex:compiled-network-domains
        (codex:policy-merge-overlay
          (codex:policy-with-network-rules
            ()
            ((codex:network-rule
               "api.github.com"
               (codex:network-rule-protocol-https)
               (codex:decision-allow))))
          (codex:policy-with-network-rules
            ()
            ((codex:network-rule
               "api.github.com"
               (codex:network-rule-protocol-https)
               (codex:decision-forbidden))))))))
  ("{\"allowed\":[],\"denied\":[\"api.github.com\"]}"))

!(assertEqualToResult
  (json-stringify
    (codex:check-output-json
      (codex:check-policy-multiple
        (codex:exec-policy-load-value
          (codex:load-exec-policy-from-config-stack
            (codex:exec-policy-load-config-stack
              ((codex:exec-policy-load-layer
                 (codex:exec-policy-layer-source-user)
                 (codex:policy
                   ((codex:prefix-rule
                      ((codex:pattern-token "rm"))
                      (codex:decision-forbidden)))))
               (codex:exec-policy-load-layer
                 (codex:exec-policy-layer-source-project)
                 (codex:policy
                   ((codex:prefix-rule
                      ((codex:pattern-token "ls"))
                      (codex:decision-prompt))))))
              False
              CodexAbsent)))
        (("rm" "-rf" "/tmp/demo")
         ("ls" "-la")))))
  ("{\"matchedRules\":[{\"prefixRuleMatch\":{\"matchedPrefix\":[\"rm\"],\"decision\":\"forbidden\"}},{\"prefixRuleMatch\":{\"matchedPrefix\":[\"ls\"],\"decision\":\"prompt\"}}],\"decision\":\"forbidden\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:check-output-json
      (codex:check-policy
        (codex:exec-policy-load-value
          (codex:load-exec-policy-from-config-stack
            (codex:exec-policy-load-config-stack
              ((codex:exec-policy-load-layer
                 (codex:exec-policy-layer-source-system)
                 (codex:policy
                   ((codex:prefix-rule
                      ((codex:pattern-token "curl"))
                      (codex:decision-allow)))))
               (codex:exec-policy-load-layer
                 (codex:exec-policy-layer-source-user)
                 (codex:policy
                   ((codex:prefix-rule
                      ((codex:pattern-token "curl"))
                      (codex:decision-forbidden)))))
               (codex:exec-policy-load-layer
                 (codex:exec-policy-layer-source-project)
                 (codex:policy
                   ((codex:prefix-rule
                      ((codex:pattern-token "ls"))
                      (codex:decision-forbidden))))
                 False))
              True
              CodexAbsent)))
        ("curl" "https://example.com"))))
  ("{\"matchedRules\":[{\"prefixRuleMatch\":{\"matchedPrefix\":[\"curl\"],\"decision\":\"allow\"}}],\"decision\":\"allow\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:compiled-network-domains-json
      (codex:compiled-network-domains
        (codex:exec-policy-load-value
          (codex:load-exec-policy-from-config-stack
            (codex:exec-policy-load-config-stack
              ((codex:exec-policy-load-layer
                 (codex:exec-policy-layer-source-system)
                 (codex:policy-with-host-executables
                   ((codex:prefix-rule
                      ((codex:pattern-token "git"))
                      (codex:decision-allow)))
                   ((codex:host-executable "git" ("/usr/bin/git"))))))
              False
              (codex:requirements-exec-policy
                (codex:policy-with-network-rules
                  ()
                  ((codex:network-rule
                     "blocked.example.com"
                     (codex:network-rule-protocol-https)
                     (codex:decision-forbidden)))))))))))
  ("{\"allowed\":[],\"denied\":[\"blocked.example.com\"]}"))

!(assertEqualToResult
  (json-stringify
    (codex:check-output-json
      (codex:check-policy-with-options
        (codex:exec-policy-load-value
          (codex:load-exec-policy-from-config-stack
            (codex:exec-policy-load-config-stack
              ((codex:exec-policy-load-layer
                 (codex:exec-policy-layer-source-system)
                 (codex:policy-with-host-executables
                   ((codex:prefix-rule
                      ((codex:pattern-token "git"))
                      (codex:decision-allow)))
                   ((codex:host-executable "git" ("/usr/bin/git"))))))
              False
              (codex:requirements-exec-policy
                (codex:policy-with-network-rules
                  ()
                  ((codex:network-rule
                     "blocked.example.com"
                     (codex:network-rule-protocol-https)
                     (codex:decision-forbidden))))))))
        ("/usr/bin/git" "status")
        (codex:match-options True))))
  ("{\"matchedRules\":[{\"prefixRuleMatch\":{\"matchedPrefix\":[\"git\"],\"decision\":\"allow\",\"resolvedProgram\":\"/usr/bin/git\"}}],\"decision\":\"allow\"}"))

!(assertEqual
  (codex:exec-policy-load-with-warning-warning
    (codex:load-exec-policy-with-warning-from-result
      (codex:exec-policy-load-error
        (codex:exec-policy-error-parse-policy
          "broken.rules"
          (codex:exec-policy-parse-source-error
            "plain parser failure"
            CodexAbsent)))))
  (codex:exec-policy-error-parse-policy
    "broken.rules"
    (codex:exec-policy-parse-source-error
      "plain parser failure"
      CodexAbsent)))

!(assertEqualToResult
  (json-stringify
    (codex:check-output-json
      (codex:check-policy
        (codex:exec-policy-load-with-warning-policy
          (codex:load-exec-policy-with-warning-from-result
            (codex:exec-policy-load-error
              (codex:exec-policy-error-parse-policy
                "broken.rules"
                (codex:exec-policy-parse-source-error
                  "plain parser failure"
                  CodexAbsent)))))
        ("rm" "-rf" "/tmp/demo"))))
  ("{\"matchedRules\":[]}"))

!(assertEqual
  (codex:load-exec-policy-with-warning-from-result
    (codex:exec-policy-load-error
      (codex:exec-policy-error-read-file "deny.rules" "permission denied")))
  (codex:exec-policy-load-error
    (codex:exec-policy-error-read-file "deny.rules" "permission denied")))
