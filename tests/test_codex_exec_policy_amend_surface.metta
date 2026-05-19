!(register-module! ../codex)
!(import! &self fs)
!(import! &self process)
!(import! &self codex:exec_policy)
!(import! &self codex:exec_policy_amend)

(= (exec-policy-amend-root)
   "/home/zarclaw/repos/CeTTa/runtime/codex-exec-policy-amend")

(= (exec-policy-amend-policy-path)
   "/home/zarclaw/repos/CeTTa/runtime/codex-exec-policy-amend/rules/default.rules")

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
