!(register-module! /home/zarclaw/repos/CeTTa/codex)
!(import! &self json)
!(import! &self codex:command)
!(import! &self codex:exec_policy)
!(import! &self codex:approval)

!(assertEqual
  (once
    (eval
      (codex:approval-requirement-type
        (codex:approval-for-command
          (codex:ask-for-approval-unless-trusted)
          (codex:file-system-sandbox-restricted)
          (codex:policy ())
          ("rg" "-n" "TODO" "src")))))
  "skip")

!(assertEqual
  (once
    (eval
      (codex:approval-for-command
        (codex:ask-for-approval-unless-trusted)
        (codex:file-system-sandbox-restricted)
        (codex:policy ())
        ("npm" "install"))))
  (CodexExecApprovalRequirementNeedsApproval
    CodexAbsent
    (CodexExecPolicyAmendment ("npm" "install"))))

!(assertEqual
  (once
    (eval
      (codex:approval-for-command
        (codex:ask-for-approval-unless-trusted)
        (codex:file-system-sandbox-restricted)
        (codex:policy ())
        ("rg" "-n" "TODO" "src"))))
  (CodexExecApprovalRequirementSkip
    False
    (CodexExecPolicyAmendment ("rg" "-n" "TODO" "src"))))

!(assertEqualToResult
  (json-stringify
    (codex:approval-requirement-json
      (codex:approval-for-command-with-prefix-rule
        (codex:ask-for-approval-unless-trusted)
        (codex:file-system-sandbox-restricted)
        (codex:policy ())
        ("npm" "install")
        ("npm"))))
  ("{\"type\":\"needs_approval\",\"reason\":null,\"proposed_execpolicy_amendment\":[\"npm\"]}"))

!(assertEqualToResult
  (json-stringify
    (codex:approval-requirement-json
      (CodexExecApprovalRequirementNeedsApproval
        CodexAbsent
        (CodexExecPolicyAmendment ("npm" "install")))))
  ("{\"type\":\"needs_approval\",\"reason\":null,\"proposed_execpolicy_amendment\":[\"npm\",\"install\"]}"))
