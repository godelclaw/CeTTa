!(register-module! ../codex)
!(import! &self fs)
!(import! &self json)
!(import! &self process)
!(import! &self codex:exec_policy)
!(import! &self codex:exec_policy_amend)

(= (exec-policy-amend-root)
   "/home/zarclaw/repos/CeTTa/runtime/codex-exec-policy-amend")

(= (exec-policy-amend-policy-path)
   "/home/zarclaw/repos/CeTTa/runtime/codex-exec-policy-amend/rules/default.rules")

(= (exec-policy-update-home)
   "/home/zarclaw/repos/CeTTa/runtime/codex-exec-policy-update")

!(assertEqualToResult
  (process-result-exit-code
    (process-run-shell
      "rm -rf /home/zarclaw/repos/CeTTa/runtime/codex-exec-policy-amend && mkdir -p /home/zarclaw/repos/CeTTa/runtime/codex-exec-policy-amend"))
  (0))

!(assertEqualToResult
  (codex:exec-policy-amend-value
    (codex:exec-policy-amend-format-allow-prefix-rule
      ("echo" "Hello, world!")))
  ("prefix_rule(pattern=[\"echo\", \"Hello, world!\"], decision=\"allow\")"))

!(assertEqualToResult
  (codex:exec-policy-amend-value
    (codex:exec-policy-amend-format-allow-prefix-rule
      ("printf" "a\"b")))
  ("prefix_rule(pattern=[\"printf\", \"a\\\"b\"], decision=\"allow\")"))

!(assertEqualToResult
  (codex:exec-policy-amend-error-message
    (codex:exec-policy-amend-error-value
      (codex:exec-policy-amend-format-allow-prefix-rule ())))
  ("prefix rule requires at least one token"))

!(assertEqualToResult
  (codex:exec-policy-amend-value
    (codex:exec-policy-amend-format-network-rule
      "Api.GitHub.com"
      (codex:network-rule-protocol-https)
      (codex:decision-allow)
      "Allow https_connect access to api.github.com"))
  ("network_rule(host=\"api.github.com\", protocol=\"https\", decision=\"allow\", justification=\"Allow https_connect access to api.github.com\")"))

!(assertEqualToResult
  (codex:exec-policy-amend-value
    (codex:exec-policy-amend-format-network-rule
      "bad.example"
      (codex:network-rule-protocol-http)
      (codex:decision-forbidden)))
  ("network_rule(host=\"bad.example\", protocol=\"http\", decision=\"deny\")"))

!(assertEqualToResult
  (codex:exec-policy-amend-error-message
    (codex:exec-policy-amend-error-value
      (codex:exec-policy-amend-format-network-rule
        "*.example.com"
        (codex:network-rule-protocol-https)
        (codex:decision-allow))))
  ("invalid network rule: invalid rule: network_rule host must be a specific host; wildcards are not allowed"))

!(assertEqualToResult
  (codex:exec-policy-amend-error-message
    (codex:exec-policy-amend-error-value
      (codex:exec-policy-amend-format-network-rule
        "api.github.com"
        (codex:network-rule-protocol-https)
        (codex:decision-allow)
        "   ")))
  ("invalid network rule: justification cannot be empty"))

!(assertEqualToResult
  (codex:exec-policy-amend-append-line-to-contents
    "prefix_rule(pattern=[\"ls\"], decision=\"allow\")\n"
    "prefix_rule(pattern=[\"echo\", \"Hello, world!\"], decision=\"allow\")")
  ("prefix_rule(pattern=[\"ls\"], decision=\"allow\")\nprefix_rule(pattern=[\"echo\", \"Hello, world!\"], decision=\"allow\")\n"))

!(assertEqualToResult
  (codex:exec-policy-amend-append-line-to-contents
    "prefix_rule(pattern=[\"ls\"], decision=\"allow\")"
    "prefix_rule(pattern=[\"echo\", \"Hello, world!\"], decision=\"allow\")")
  ("prefix_rule(pattern=[\"ls\"], decision=\"allow\")\nprefix_rule(pattern=[\"echo\", \"Hello, world!\"], decision=\"allow\")\n"))

!(assertEqualToResult
  (codex:exec-policy-amend-append-line-to-contents
    "prefix_rule(pattern=[\"ls\"], decision=\"allow\")\n"
    "prefix_rule(pattern=[\"ls\"], decision=\"allow\")")
  ("prefix_rule(pattern=[\"ls\"], decision=\"allow\")\n"))

!(assertEqualToResult
  (codex:blocking-append-allow-prefix-rule
    (exec-policy-amend-policy-path)
    ("curl"))
  ((CodexExecPolicyAmendOk ())))

!(assertEqualToResult
  (codex:blocking-append-network-rule
    (exec-policy-amend-policy-path)
    "api.github.com"
    (codex:network-rule-protocol-https)
    (codex:decision-allow)
    "Allow https_connect access to api.github.com")
  ((CodexExecPolicyAmendOk ())))

!(assertEqualToResult
  (codex:blocking-append-allow-prefix-rule
    (exec-policy-amend-policy-path)
    ("curl"))
  ((CodexExecPolicyAmendOk ())))

!(assertEqualToResult
  (fs-read-text (exec-policy-amend-policy-path))
  ("prefix_rule(pattern=[\"curl\"], decision=\"allow\")\nnetwork_rule(host=\"api.github.com\", protocol=\"https\", decision=\"allow\", justification=\"Allow https_connect access to api.github.com\")\n"))

!(assertEqualToResult
  (process-result-exit-code
    (process-run-shell
      "rm -rf /home/zarclaw/repos/CeTTa/runtime/codex-exec-policy-update && mkdir -p /home/zarclaw/repos/CeTTa/runtime/codex-exec-policy-update"))
  (0))

!(assertEqualToResult
  (json-stringify
    (codex:check-output-json
      (codex:check-policy
        (codex:exec-policy-update-value
          (codex:append-amendment-and-update
            (exec-policy-update-home)
            (codex:policy ())
            (CodexExecPolicyAmendment ("echo" "hello"))))
        ("echo" "hello" "world"))))
  ("{\"matchedRules\":[{\"prefixRuleMatch\":{\"matchedPrefix\":[\"echo\",\"hello\"],\"decision\":\"allow\"}}],\"decision\":\"allow\"}"))

!(assertEqualToResult
  (fs-read-text (codex:default-policy-path (exec-policy-update-home)))
  ("prefix_rule(pattern=[\"echo\", \"hello\"], decision=\"allow\")\n"))

!(assertEqual
  (codex:exec-policy-update-already-allowed
    (codex:policy
      ((codex:prefix-rule
         ((codex:pattern-token "echo")
          (codex:pattern-token "hello"))
         (codex:decision-allow))))
    ("echo" "hello" "world"))
  True)

!(assertEqualToResult
  (codex:exec-policy-update-error-value
    (codex:append-amendment-and-update
      (exec-policy-update-home)
      (codex:policy ())
      (CodexExecPolicyAmendment ())))
  ((CodexExecPolicyUpdateErrorAppendRule
     "/home/zarclaw/repos/CeTTa/runtime/codex-exec-policy-update/rules/default.rules"
     (CodexExecPolicyAmendErrorEmptyPrefix))))

!(assertEqualToResult
  (json-stringify
    (codex:compiled-network-domains-json
      (codex:compiled-network-domains
        (codex:exec-policy-update-value
          (codex:append-network-rule-and-update
            (exec-policy-update-home)
            (codex:policy ())
            "Api.GitHub.com"
            (codex:network-rule-protocol-https)
            (codex:decision-allow)
            "Allow https_connect access to api.github.com")))))
  ("{\"allowed\":[\"api.github.com\"],\"denied\":[]}"))

!(assertEqualToResult
  (fs-read-text (codex:default-policy-path (exec-policy-update-home)))
  ("prefix_rule(pattern=[\"echo\", \"hello\"], decision=\"allow\")\nnetwork_rule(host=\"api.github.com\", protocol=\"https\", decision=\"allow\", justification=\"Allow https_connect access to api.github.com\")\n"))
