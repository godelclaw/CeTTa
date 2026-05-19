!(register-module! /home/zarclaw/repos/CeTTa/codex)
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
