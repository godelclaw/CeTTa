!(register-module! ../codex)
!(import! &self codex:network_approval)
!(import! &self codex:network_policy_decision)

(= (host-key-https-443)
   (codex:host-approval-key "example.com" "https" 443))

(= (trigger)
   (codex:guardian-network-access-trigger
     "call-1"
     "shell"
     ("curl" "https://example.com")
     "/tmp"
     "use_default"
     CodexAbsent
     CodexAbsent
     CodexAbsent))

(= (service-with-one-call)
   (codex:network-approval-register-call
     (codex:network-approval-service-default)
     "registration-1"
     "turn-1"
     (trigger)
     "curl https://example.com"))

(= (inline-request)
   (CodexNetworkPolicyRequest
     (CodexNetworkProtocolHttpsConnect)
     "Example.COM"
     443))

(= (inline-turn $sandbox-policy $approval-policy $use-guardian)
   (codex:network-approval-inline-turn-context
     "turn-1"
     "/tmp"
     $sandbox-policy
     $approval-policy
     $use-guardian
     "guardian rejected"
     "guardian timed out"))

(= (reviewable-turn)
   (inline-turn
     (CodexSessionSandboxPolicyReadOnly () ())
     (codex:ask-for-approval-on-request)
     False))

(= (inline-input $turn-context $hook-decision $review-decision)
   (codex:network-approval-inline-policy-input
     $turn-context
     $hook-decision
     $review-decision
     CodexAbsent))

(= (inline-default-input $review-decision)
   (inline-input
     (reviewable-turn)
     (CodexPermissionRequestHookDecisionNone)
     $review-decision))

(= (inline-default $service $review-decision)
   (codex:network-approval-handle-inline-policy-request
     $service
     (inline-default-input $review-decision)
     (inline-request)))

!(assertEqual
  (codex:network-approval-approval-id-for-key
    (codex:host-approval-key-from-request (inline-request)))
  "network#https#example.com#443")

(= (metadata-result)
   (inline-default
     (codex:network-approval-service-default)
     (CodexReviewDecisionApproved)))

!(assertEqual
  (codex:network-approval-inline-policy-result-target
    (metadata-result))
  "https://Example.COM:443")

!(assertEqual
  (codex:network-approval-inline-policy-result-prompt-command
    (metadata-result))
  ("network-access" "https://Example.COM:443"))

!(assertEqual
  (codex:network-approval-inline-policy-result-prompt-reason
    (metadata-result))
  "Example.COM is not in the allowed_domains")

!(assertEqual
  (codex:network-approval-inline-policy-result-network-approval-context
    (metadata-result))
  (codex:network-approval-context
    "Example.COM"
    (codex:network-approval-protocol-https)))

!(assertEqual
  (codex:network-approval-inline-policy-result-hook-command
    (metadata-result))
  "network-access https://Example.COM:443")

(= (metadata-with-owner-call)
   (inline-default
     (service-with-one-call)
     (CodexReviewDecisionApproved)))

!(assertEqual
  (codex:network-approval-inline-policy-result-hook-command
    (metadata-with-owner-call))
  "curl https://example.com")

(= (approved-cache-service)
   (codex:network-approval-service-with-session-approved-hosts
     (codex:network-approval-service-default)
     ((host-key-https-443))))

!(assertEqual
  (codex:network-approval-inline-policy-result-decision
    (codex:network-approval-handle-inline-policy-request
      (approved-cache-service)
      (inline-default-input (CodexReviewDecisionDenied))
      (inline-request)))
  (codex:network-decision-allow))

(= (denied-cache-service)
   (codex:network-approval-service-with-session-denied-hosts
     (codex:network-approval-service-default)
     ((host-key-https-443))))

!(assertEqual
  (codex:network-approval-inline-policy-result-decision
    (codex:network-approval-handle-inline-policy-request
      (denied-cache-service)
      (inline-default-input (CodexReviewDecisionApproved))
      (inline-request)))
  (codex:network-decision-deny "not_allowed"))

(= (pending-service)
   (codex:network-approval-service-with-pending-host-approvals
     (codex:network-approval-service-default)
     ((host-key-https-443))))

(= (pending-join-allow)
   (codex:network-approval-handle-inline-policy-request
     (pending-service)
     (codex:network-approval-inline-policy-input
       (reviewable-turn)
       (CodexPermissionRequestHookDecisionNone)
       (CodexReviewDecisionDenied)
       (codex:pending-approval-decision-allow-for-session))
     (inline-request)))

!(assertEqual
  (codex:network-approval-inline-policy-result-decision
    (pending-join-allow))
  (codex:network-decision-allow))

!(assertEqual
  (codex:network-approval-service-pending-host-approvals
    (codex:network-approval-inline-policy-result-service
      (pending-join-allow)))
  ((CodexHostApprovalKey "example.com" "https" 443)))

(= (pending-join-unresolved)
   (codex:network-approval-handle-inline-policy-request
     (pending-service)
     (codex:network-approval-inline-policy-input
       (reviewable-turn)
       (CodexPermissionRequestHookDecisionNone)
       (CodexReviewDecisionDenied)
       CodexAbsent)
     (inline-request)))

!(assertEqual
  (codex:network-approval-inline-policy-result-decision
    (pending-join-unresolved))
  CodexAbsent)

(= (no-turn-denied)
   (codex:network-approval-handle-inline-policy-request
     (service-with-one-call)
     (codex:network-approval-inline-policy-input
       CodexAbsent
       (CodexPermissionRequestHookDecisionNone)
       (CodexReviewDecisionApproved)
       CodexAbsent)
     (inline-request)))

!(assertEqual
  (codex:network-approval-inline-policy-result-decision
    (no-turn-denied))
  (codex:network-decision-deny "not_allowed"))

!(assertEqual
  (codex:network-approval-call-outcomes-get
    (codex:network-approval-service-call-outcomes
      (codex:network-approval-inline-policy-result-service
        (no-turn-denied)))
    "registration-1")
  (codex:network-approval-outcome-denied-by-policy
    "Network access to \"https://Example.COM:443\" was blocked by policy."))

(= (sandbox-flow-denied)
   (codex:network-approval-handle-inline-policy-request
     (service-with-one-call)
     (inline-input
       (inline-turn
         (CodexSessionSandboxPolicyDangerFullAccess)
         (codex:ask-for-approval-on-request)
         False)
       (CodexPermissionRequestHookDecisionNone)
       (CodexReviewDecisionApproved))
     (inline-request)))

!(assertEqual
  (codex:network-approval-inline-policy-result-decision
    (sandbox-flow-denied))
  (codex:network-decision-deny "not_allowed"))

(= (approval-flow-denied)
   (codex:network-approval-handle-inline-policy-request
     (service-with-one-call)
     (inline-input
       (inline-turn
         (CodexSessionSandboxPolicyReadOnly () ())
         (codex:ask-for-approval-never)
         False)
       (CodexPermissionRequestHookDecisionNone)
       (CodexReviewDecisionApproved))
     (inline-request)))

!(assertEqual
  (codex:network-approval-inline-policy-result-decision
    (approval-flow-denied))
  (codex:network-decision-deny "not_allowed"))

(= (hook-allow)
   (codex:network-approval-handle-inline-policy-request
     (service-with-one-call)
     (inline-input
       (reviewable-turn)
       (CodexPermissionRequestHookDecisionAllow)
       (CodexReviewDecisionDenied))
     (inline-request)))

!(assertEqual
  (codex:network-approval-inline-policy-result-resolved-pending-decision
    (hook-allow))
  (codex:pending-approval-decision-allow-once))

!(assertEqual
  (codex:network-approval-service-pending-host-approvals
    (codex:network-approval-inline-policy-result-service
      (hook-allow)))
  ())

(= (hook-deny)
   (codex:network-approval-handle-inline-policy-request
     (service-with-one-call)
     (inline-input
       (reviewable-turn)
       (CodexPermissionRequestHookDecisionDeny "hook blocked")
       (CodexReviewDecisionApproved))
     (inline-request)))

!(assertEqual
  (codex:network-approval-inline-policy-result-decision
    (hook-deny))
  (codex:network-decision-deny "not_allowed"))

!(assertEqual
  (codex:network-approval-call-outcomes-get
    (codex:network-approval-service-call-outcomes
      (codex:network-approval-inline-policy-result-service
        (hook-deny)))
    "registration-1")
  (codex:network-approval-outcome-denied-by-policy "hook blocked"))

(= (approved-for-session)
   (inline-default
     (service-with-one-call)
     (CodexReviewDecisionApprovedForSession)))

!(assertEqual
  (codex:network-approval-inline-policy-result-decision
    (approved-for-session))
  (codex:network-decision-allow))

!(assertEqual
  (codex:network-approval-service-session-approved-hosts
    (codex:network-approval-inline-policy-result-service
      (approved-for-session)))
  ((CodexHostApprovalKey "example.com" "https" 443)))

(= (network-amendment-allow)
   (inline-default
     (service-with-one-call)
     (CodexReviewDecisionNetworkPolicyAmendment
       (CodexNetworkPolicyAmendment
         (CodexNetworkPolicyRuleActionAllow)
         "Example.COM"))))

!(assertEqual
  (codex:network-approval-service-session-approved-hosts
    (codex:network-approval-inline-policy-result-service
      (network-amendment-allow)))
  ((CodexHostApprovalKey "example.com" "https" 443)))

(= (network-amendment-deny)
   (inline-default
     (service-with-one-call)
     (CodexReviewDecisionNetworkPolicyAmendment
       (CodexNetworkPolicyAmendment
         (CodexNetworkPolicyRuleActionDeny)
         "Example.COM"))))

!(assertEqual
  (codex:network-approval-inline-policy-result-decision
    (network-amendment-deny))
  (codex:network-decision-deny "not_allowed"))

!(assertEqual
  (codex:network-approval-service-session-denied-hosts
    (codex:network-approval-inline-policy-result-service
      (network-amendment-deny)))
  ((CodexHostApprovalKey "example.com" "https" 443)))

!(assertEqual
  (codex:network-approval-call-outcomes-get
    (codex:network-approval-service-call-outcomes
      (codex:network-approval-inline-policy-result-service
        (network-amendment-deny)))
    "registration-1")
  (codex:network-approval-outcome-denied-by-user))

(= (review-denied-user)
   (inline-default
     (service-with-one-call)
     (CodexReviewDecisionDenied)))

!(assertEqual
  (codex:network-approval-call-outcomes-get
    (codex:network-approval-service-call-outcomes
      (codex:network-approval-inline-policy-result-service
        (review-denied-user)))
    "registration-1")
  (codex:network-approval-outcome-denied-by-user))

(= (review-denied-guardian)
   (codex:network-approval-handle-inline-policy-request
     (service-with-one-call)
     (inline-input
       (inline-turn
         (CodexSessionSandboxPolicyReadOnly () ())
         (codex:ask-for-approval-on-request)
         True)
       (CodexPermissionRequestHookDecisionNone)
       (CodexReviewDecisionAbort))
     (inline-request)))

!(assertEqual
  (codex:network-approval-call-outcomes-get
    (codex:network-approval-service-call-outcomes
      (codex:network-approval-inline-policy-result-service
        (review-denied-guardian)))
    "registration-1")
  (codex:network-approval-outcome-denied-by-policy
    "guardian rejected"))

(= (review-timed-out)
   (inline-default
     (service-with-one-call)
     (CodexReviewDecisionTimedOut)))

!(assertEqual
  (codex:network-approval-call-outcomes-get
    (codex:network-approval-service-call-outcomes
      (codex:network-approval-inline-policy-result-service
        (review-timed-out)))
    "registration-1")
  (codex:network-approval-outcome-denied-by-policy
    "guardian timed out"))
