!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:tool_sandboxing)

!(assertEqual
  (codex:sandbox-override-for-first-attempt
    "use_default"
    (codex:approval-skip False))
  (codex:sandbox-override-no-override))

!(assertEqual
  (codex:sandbox-override-for-first-attempt
    "require_escalated"
    (codex:approval-needs-approval "policy"))
  (codex:sandbox-override-bypass-sandbox-first-attempt))

!(assertEqual
  (codex:sandbox-override-for-first-attempt
    "use_default"
    (codex:approval-skip True))
  (codex:sandbox-override-bypass-sandbox-first-attempt))

!(assertEqual
  (codex:exec-approval-requirement-proposed-execpolicy-amendment
    (codex:approval-needs-approval
      CodexAbsent
      (CodexExecPolicyAmendment ("git" "status"))))
  (CodexExecPolicyAmendment ("git" "status")))

!(assertEqual
  (codex:exec-approval-requirement-proposed-execpolicy-amendment
    (codex:approval-forbidden "blocked"))
  CodexAbsent)

!(assertEqualToResult
  (json-stringify
    (codex:permission-request-payload-json
      (codex:permission-request-payload-bash
        "printf hi"
        CodexAbsent)))
  ("{\"tool_name\":{\"name\":\"Bash\",\"matcher_aliases\":[]},\"tool_input\":{\"command\":\"printf hi\"}}"))

!(assertEqualToResult
  (json-stringify
    (codex:permission-request-payload-json
      (codex:permission-request-payload-bash
        "printf hi"
        "need network")))
  ("{\"tool_name\":{\"name\":\"Bash\",\"matcher_aliases\":[]},\"tool_input\":{\"command\":\"printf hi\",\"description\":\"need network\"}}"))
