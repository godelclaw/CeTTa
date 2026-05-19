!(register-module! ../codex)
!(import! &self codex:network_approval)
!(import! &self codex:network_policy_decision)
!(import! &self codex:permissions)
!(import! &self codex:sandbox_tags)
!(import! &self codex:tool_config)
!(import! &self codex:tool_orchestrator)
!(import! &self codex:tool_sandboxing)

(= (orchestrator)
   (codex:tool-orchestrator-new))

(= (tool-ctx)
   (codex:tool-orchestrator-tool-ctx
     Session
     Turn
     "call-1"
     "shell"))

(= (turn-context $file-system-policy $network-policy $managed $strict $guardian)
   (codex:tool-orchestrator-turn-context
     $file-system-policy
     $network-policy
     "SandboxPolicy"
     "/tmp/work"
     $managed
     $strict
     $guardian
     (codex:host-platform-linux)
     (codex:windows-sandbox-level-disabled)
     False
     False
     "/usr/lib/codex-linux-sandbox"))

(= (tool-config $requirement $override $preference $escalate)
   (codex:tool-orchestrator-tool-config
     $requirement
     $override
     $preference
     $escalate
     CodexAbsent
     CodexAbsent))

(= (approval-input $decision)
   (codex:tool-orchestrator-approval-request-input
     CodexAbsent
     (codex:permission-request-hook-decision-none)
     $decision))

(= (network-trigger)
   (codex:guardian-network-access-trigger
     "call-1"
     "shell"
     ("curl" "https://example.com")
     "/tmp/work"
     "use_default"
     CodexAbsent
     CodexAbsent
     CodexAbsent))

(= (network-service-with-call)
   (codex:network-approval-register-call
     (codex:network-approval-service-default)
     "registration-1"
     "turn-1"
     (network-trigger)
     "curl https://example.com"))

(= (inputs $initial-approval $retry-approval $first-attempt $retry-attempt)
   (codex:tool-orchestrator-run-inputs
     $initial-approval
     $retry-approval
     $first-attempt
     $retry-attempt
     "strict-review-id"
     "approval-review-id"
     "retry-review-id"
     "guardian rejected"
     "guardian timed out"))

(= (default-turn)
   (turn-context
     (codex:file-system-sandbox-policy-default)
     (codex:network-sandbox-policy-restricted)
     False
     False
     False))

(= (default-tool)
   (tool-config
     (codex:approval-skip False)
     (codex:sandbox-override-no-override)
     (codex:sandboxable-preference-auto)
     True))

!(assertEqual
  (codex:tool-orchestrator-reject-if-not-approved
    CodexAbsent
    (CodexReviewDecisionDenied)
    "guardian rejected"
    "guardian timed out")
  (codex:tool-orchestrator-approval-request-err
    (codex:tool-error-rejected "rejected by user")))

!(assertEqual
  (codex:tool-orchestrator-reject-if-not-approved
    "review-id"
    (CodexReviewDecisionAbort)
    "guardian rejected"
    "guardian timed out")
  (codex:tool-orchestrator-approval-request-err
    (codex:tool-error-rejected "guardian rejected")))

!(assertEqual
  (codex:tool-orchestrator-reject-if-not-approved
    "review-id"
    (CodexReviewDecisionTimedOut)
    "guardian rejected"
    "guardian timed out")
  (codex:tool-orchestrator-approval-request-err
    (codex:tool-error-rejected "guardian timed out")))

!(assertEqual
  (codex:tool-orchestrator-reject-if-not-approved
    CodexAbsent
    (CodexReviewDecisionNetworkPolicyAmendment
      (CodexNetworkPolicyAmendment
        (CodexNetworkPolicyRuleActionAllow)
        "example.com"))
    "guardian rejected"
    "guardian timed out")
  (codex:tool-orchestrator-approval-request-ok
    (CodexReviewDecisionNetworkPolicyAmendment
      (CodexNetworkPolicyAmendment
        (CodexNetworkPolicyRuleActionAllow)
        "example.com"))))

!(assertEqual
  (codex:tool-orchestrator-reject-if-not-approved
    CodexAbsent
    (CodexReviewDecisionNetworkPolicyAmendment
      (CodexNetworkPolicyAmendment
        (CodexNetworkPolicyRuleActionDeny)
        "example.com"))
    "guardian rejected"
    "guardian timed out")
  (codex:tool-orchestrator-approval-request-err
    (codex:tool-error-rejected "rejected by user")))

!(assertEqual
  (codex:tool-orchestrator-request-approval
    True
    (codex:tool-orchestrator-approval-request-input
      PermissionPayload
      (codex:permission-request-hook-decision-allow)
      (CodexReviewDecisionDenied)))
  (codex:tool-orchestrator-approval-request-ok
    (CodexReviewDecisionApproved)))

!(assertEqual
  (codex:tool-orchestrator-request-approval
    True
    (codex:tool-orchestrator-approval-request-input
      PermissionPayload
      (codex:permission-request-hook-decision-deny
        "blocked by hook")
      (CodexReviewDecisionApproved)))
  (codex:tool-orchestrator-approval-request-err
    (codex:tool-error-rejected "blocked by hook")))

!(assertEqual
  (codex:tool-orchestrator-request-approval
    False
    (codex:tool-orchestrator-approval-request-input
      PermissionPayload
      (codex:permission-request-hook-decision-allow)
      (CodexReviewDecisionDenied)))
  (codex:tool-orchestrator-approval-request-ok
    (CodexReviewDecisionDenied)))

!(assertEqual
  (codex:sandbox-attempt-sandbox
    (codex:tool-orchestrator-build-initial-attempt
      (orchestrator)
      (default-tool)
      (default-turn)))
  (codex:sandbox-type-linux-seccomp))

!(assertEqual
  (codex:sandbox-attempt-sandbox
    (codex:tool-orchestrator-build-initial-attempt
      (orchestrator)
      (tool-config
        (codex:approval-skip False)
        (codex:sandbox-override-bypass-sandbox-first-attempt)
        (codex:sandboxable-preference-auto)
        True)
      (default-turn)))
  (codex:sandbox-type-none))

!(assertEqual
  (codex:sandbox-attempt-codex-linux-sandbox-exe
    (codex:tool-orchestrator-build-escalated-attempt
      (orchestrator)
      (default-turn)))
  CodexAbsent)

!(assertEqual
  (codex:tool-orchestrator-run-attempt-finalize
    (codex:network-approval-service-default)
    (codex:tool-orchestrator-attempt-ok "out-1" DeferredIgnored)
    CodexAbsent)
  (codex:tool-orchestrator-run-attempt-finalize-result
    (codex:tool-orchestrator-attempt-ok "out-1" CodexAbsent)
    (codex:network-approval-service-default)))

(= (attempt-immediate-denied)
   (codex:tool-orchestrator-run-attempt-finalize
     (codex:network-approval-record-call-outcome
       (network-service-with-call)
       "registration-1"
       (codex:network-approval-outcome-denied-by-policy
         "network blocked"))
     (codex:tool-orchestrator-attempt-ok "out-1" CodexAbsent)
     (codex:active-network-approval
       "registration-1"
       (codex:network-approval-mode-immediate))))

!(assertEqual
  (codex:tool-orchestrator-run-attempt-finalize-result-attempt
    (attempt-immediate-denied))
  (codex:tool-orchestrator-attempt-err
    (CodexToolErrorRejected "network blocked")))

!(assertEqual
  (codex:network-approval-service-active-calls
    (codex:tool-orchestrator-run-attempt-finalize-result-service
      (attempt-immediate-denied)))
  ())

!(assertEqual
  (codex:tool-orchestrator-run-attempt-finalize
    (network-service-with-call)
    (codex:tool-orchestrator-attempt-err
      (codex:tool-error-other "runtime failed"))
    (codex:active-network-approval
      "registration-1"
      (codex:network-approval-mode-immediate)))
  (codex:tool-orchestrator-run-attempt-finalize-result
    (codex:tool-orchestrator-attempt-err
      (codex:tool-error-other "runtime failed"))
    (codex:network-approval-service-default)))

!(assertEqual
  (codex:tool-orchestrator-run-attempt-finalize
    (network-service-with-call)
    (codex:tool-orchestrator-attempt-ok "out-1" CodexAbsent)
    (codex:active-network-approval
      "registration-1"
      (codex:network-approval-mode-deferred)))
  (codex:tool-orchestrator-run-attempt-finalize-result
    (codex:tool-orchestrator-attempt-ok
      "out-1"
      (codex:deferred-network-approval "registration-1"))
    (network-service-with-call)))

!(assertEqual
  (codex:tool-orchestrator-run-attempt-finalize
    (network-service-with-call)
    (codex:tool-orchestrator-attempt-err
      (codex:tool-error-other "runtime failed"))
    (codex:active-network-approval
      "registration-1"
      (codex:network-approval-mode-deferred)))
  (codex:tool-orchestrator-run-attempt-finalize-result
    (codex:tool-orchestrator-attempt-err
      (codex:tool-error-other "runtime failed"))
    (codex:network-approval-service-default)))

!(assertEqual
  (codex:tool-orchestrator-run
    (orchestrator)
    (default-tool)
    (tool-ctx)
    (default-turn)
    (codex:ask-for-approval-on-failure)
    (inputs
      (approval-input (CodexReviewDecisionDenied))
      (approval-input (CodexReviewDecisionApproved))
      (codex:tool-orchestrator-attempt-ok "out-1" CodexAbsent)
      (codex:tool-orchestrator-attempt-ok "retry-out" CodexAbsent)))
  (codex:tool-orchestrator-run-ok
    (codex:orchestrator-run-result "out-1" CodexAbsent)))

!(assertEqual
  (codex:tool-orchestrator-run
    (orchestrator)
    (tool-config
      (codex:approval-forbidden "blocked by policy")
      (codex:sandbox-override-no-override)
      (codex:sandboxable-preference-auto)
      True)
    (tool-ctx)
    (default-turn)
    (codex:ask-for-approval-on-failure)
    (inputs
      (approval-input (CodexReviewDecisionApproved))
      (approval-input (CodexReviewDecisionApproved))
      (codex:tool-orchestrator-attempt-ok "out-1" CodexAbsent)
      (codex:tool-orchestrator-attempt-ok "retry-out" CodexAbsent)))
  (codex:tool-orchestrator-run-err
    (codex:tool-error-rejected "blocked by policy")))

!(assertEqual
  (codex:tool-orchestrator-run
    (orchestrator)
    (tool-config
      (codex:approval-needs-approval "need approval")
      (codex:sandbox-override-no-override)
      (codex:sandboxable-preference-auto)
      True)
    (tool-ctx)
    (default-turn)
    (codex:ask-for-approval-on-request)
    (inputs
      (approval-input (CodexReviewDecisionDenied))
      (approval-input (CodexReviewDecisionApproved))
      (codex:tool-orchestrator-attempt-ok "out-1" CodexAbsent)
      (codex:tool-orchestrator-attempt-ok "retry-out" CodexAbsent)))
  (codex:tool-orchestrator-run-err
    (codex:tool-error-rejected "rejected by user")))

!(assertEqual
  (codex:tool-orchestrator-run
    (orchestrator)
    (default-tool)
    (tool-ctx)
    (default-turn)
    (codex:ask-for-approval-on-failure)
    (inputs
      (approval-input (CodexReviewDecisionApproved))
      (approval-input (CodexReviewDecisionApproved))
      (codex:tool-orchestrator-attempt-err
        (codex:tool-error-sandbox-denied
          "sandbox-output"
          CodexAbsent))
      (codex:tool-orchestrator-attempt-ok "retry-out" DeferredNet)))
  (codex:tool-orchestrator-run-ok
    (codex:orchestrator-run-result "retry-out" DeferredNet)))

!(assertEqual
  (codex:tool-orchestrator-run
    (orchestrator)
    (tool-config
      (codex:approval-needs-approval "need approval")
      (codex:sandbox-override-no-override)
      (codex:sandboxable-preference-auto)
      True)
    (tool-ctx)
    (default-turn)
    (codex:ask-for-approval-on-failure)
    (inputs
      (approval-input (CodexReviewDecisionApproved))
      (approval-input (CodexReviewDecisionDenied))
      (codex:tool-orchestrator-attempt-err
        (codex:tool-error-sandbox-denied
          "sandbox-output"
          CodexAbsent))
      (codex:tool-orchestrator-attempt-ok "cached-retry-out" CodexAbsent)))
  (codex:tool-orchestrator-run-ok
    (codex:orchestrator-run-result "cached-retry-out" CodexAbsent)))

!(assertEqual
  (codex:tool-orchestrator-run
    (orchestrator)
    (default-tool)
    (tool-ctx)
    (default-turn)
    (codex:ask-for-approval-never)
    (inputs
      (approval-input (CodexReviewDecisionApproved))
      (approval-input (CodexReviewDecisionApproved))
      (codex:tool-orchestrator-attempt-err
        (codex:tool-error-sandbox-denied
          "sandbox-output"
          CodexAbsent))
      (codex:tool-orchestrator-attempt-ok "retry-out" CodexAbsent)))
  (codex:tool-orchestrator-run-err
    (codex:tool-error-sandbox-denied
      "sandbox-output"
      CodexAbsent)))

!(assertEqual
  (codex:tool-orchestrator-run
    (orchestrator)
    (tool-config
      (codex:approval-skip False)
      (codex:sandbox-override-no-override)
      (codex:sandboxable-preference-auto)
      False)
    (tool-ctx)
    (default-turn)
    (codex:ask-for-approval-on-failure)
    (inputs
      (approval-input (CodexReviewDecisionApproved))
      (approval-input (CodexReviewDecisionApproved))
      (codex:tool-orchestrator-attempt-err
        (codex:tool-error-sandbox-denied
          "sandbox-output"
          CodexAbsent))
      (codex:tool-orchestrator-attempt-ok "retry-out" CodexAbsent)))
  (codex:tool-orchestrator-run-err
    (codex:tool-error-sandbox-denied
      "sandbox-output"
      CodexAbsent)))

!(assertEqual
  (codex:tool-orchestrator-network-retry-reason
    (codex:network-approval-context
      "example.com"
      (codex:network-approval-protocol-https)))
  "Network access to \"example.com\" is blocked by policy.")

!(assertEqual
  (codex:tool-orchestrator-run
    (orchestrator)
    (default-tool)
    (tool-ctx)
    (turn-context
      (codex:file-system-sandbox-policy-default)
      (codex:network-sandbox-policy-restricted)
      True
      False
      False)
    (codex:ask-for-approval-on-request)
    (inputs
      (approval-input (CodexReviewDecisionApproved))
      (approval-input
        (CodexReviewDecisionNetworkPolicyAmendment
          (CodexNetworkPolicyAmendment
            (CodexNetworkPolicyRuleActionAllow)
            "example.com")))
      (codex:tool-orchestrator-attempt-err
        (codex:tool-error-sandbox-denied
          "sandbox-output"
          (codex:network-policy-decision-payload
            (codex:network-policy-decision-ask)
            (codex:network-decision-source-decider)
            (codex:network-approval-protocol-https)
            "example.com"
            "not_allowed"
            443)))
      (codex:tool-orchestrator-attempt-ok "network-retry-out" CodexAbsent)))
  (codex:tool-orchestrator-run-ok
    (codex:orchestrator-run-result "network-retry-out" CodexAbsent)))

!(assertEqual
  (codex:tool-orchestrator-run
    (orchestrator)
    (default-tool)
    (tool-ctx)
    (turn-context
      (codex:file-system-sandbox-policy-default)
      (codex:network-sandbox-policy-restricted)
      True
      False
      False)
    (codex:ask-for-approval-on-request)
    (inputs
      (approval-input (CodexReviewDecisionApproved))
      (approval-input (CodexReviewDecisionApproved))
      (codex:tool-orchestrator-attempt-err
        (codex:tool-error-sandbox-denied
          "sandbox-output"
          (codex:network-policy-decision-payload
            (codex:network-policy-decision-deny)
            (codex:network-decision-source-decider)
            (codex:network-approval-protocol-https)
            "example.com"
            "denied"
            443)))
      (codex:tool-orchestrator-attempt-ok "network-retry-out" CodexAbsent)))
  (codex:tool-orchestrator-run-err
    (codex:tool-error-sandbox-denied
      "sandbox-output"
      (codex:network-policy-decision-payload
        (codex:network-policy-decision-deny)
        (codex:network-decision-source-decider)
        (codex:network-approval-protocol-https)
        "example.com"
        "denied"
        443))))
