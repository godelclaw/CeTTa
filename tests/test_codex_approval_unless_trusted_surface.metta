!(register-module! /home/zarclaw/repos/CeTTa/codex)
!(import! &self json)
!(import! &self codex:command)
!(import! &self codex:exec_policy)
!(import! &self codex:approval)

!(assertEqual
  (once
    (case
      (codex:approval-for-command
        (codex:ask-for-approval-unless-trusted)
        (codex:file-system-sandbox-restricted)
        (codex:policy ())
        ("rg" "-n" "TODO" "src"))
      (((CodexExecApprovalRequirementSkip
          $bypass-sandbox
          $proposed-execpolicy-amendment)
        "skip")
       ((CodexExecApprovalRequirementNeedsApproval $reason $amendment)
        "needs_approval")
       ((CodexExecApprovalRequirementForbidden $reason)
        "forbidden"))))
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

!(assertEqual
  (once
    (eval
      (codex:approval-for-command-with-prefix-rule
        (codex:ask-for-approval-unless-trusted)
        (codex:file-system-sandbox-restricted)
        (codex:policy ())
        ("npm" "install")
        ("npm"))))
  (CodexExecApprovalRequirementNeedsApproval
    CodexAbsent
    (CodexExecPolicyAmendment ("npm"))))

!(assertEqualToResult
  (json-stringify
    (codex:approval-requirement-json
      (CodexExecApprovalRequirementNeedsApproval
        CodexAbsent
        (CodexExecPolicyAmendment ("npm" "install")))))
  ("{\"type\":\"needs_approval\",\"reason\":null,\"proposed_execpolicy_amendment\":[\"npm\",\"install\"]}"))
