!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:approval)
!(import! &self codex:exec_policy)

!(assertEqualToResult
  (json-stringify
    (codex:approval-requirement-json
      (codex:approval-for-command
        (codex:ask-for-approval-on-request)
        (codex:file-system-sandbox-unrestricted)
        (codex:policy ())
        ("rm" "-rf" "/tmp/codex"))))
  ("{\"type\":\"needs_approval\",\"reason\":null,\"proposed_execpolicy_amendment\":[\"rm\",\"-rf\",\"/tmp/codex\"]}"))

!(assertEqualToResult
  (json-stringify
    (codex:approval-requirement-json
      (codex:approval-for-command
        (codex:ask-for-approval-never)
        (codex:file-system-sandbox-restricted)
        (codex:policy ())
        ("rm" "-rf" "/important/data"))))
  ("{\"type\":\"forbidden\",\"reason\":\"`rm -rf /important/data` rejected: blocked by policy\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:approval-requirement-json
      (codex:approval-for-command
        (codex:ask-for-approval-never)
        (codex:file-system-sandbox-unrestricted)
        (codex:policy ())
        ("rm" "-rf" "/tmp/codex"))))
  ("{\"type\":\"skip\",\"bypass_sandbox\":false,\"proposed_execpolicy_amendment\":[\"rm\",\"-rf\",\"/tmp/codex\"]}"))

!(assertEqualToResult
  (json-stringify
    (codex:approval-requirement-json
      (codex:approval-for-command
        (codex:ask-for-approval-on-request)
        (codex:file-system-sandbox-unrestricted)
        (codex:policy
          ((codex:prefix-rule
             ((codex:pattern-token "rm"))
             (codex:decision-prompt))))
        ("rm" "-rf" "/tmp/codex"))))
  ("{\"type\":\"needs_approval\",\"reason\":\"`rm -rf /tmp/codex` requires approval by policy\",\"proposed_execpolicy_amendment\":null}"))
