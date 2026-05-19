!(register-module! ../codex)
!(import! &self codex:network_approval)
!(import! &self codex:network_policy_decision)

(= (host-key-http-443)
   (codex:host-approval-key "example.com" "http" 443))

(= (host-key-https-443)
   (codex:host-approval-key "example.com" "https" 443))

(= (host-key-https-8443)
   (codex:host-approval-key "example.com" "https" 8443))

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

(= (spec $mode)
   (codex:network-approval-spec
     NetworkProxy
     $mode
     (trigger)
     "curl https://example.com"))

(= (service-with-one-call)
   (codex:network-approval-register-call
     (codex:network-approval-service-default)
     "registration-1"
     "turn-1"
     (trigger)
     "curl https://example.com"))

(= (denied-blocked-request)
   (codex:blocked-request
     "example.com"
     "not_allowed"
     CodexAbsent
     CodexAbsent
     CodexAbsent
     "http"
     "deny"
     "decider"
     80
     "ts"))

!(assertEqual
  (codex:network-approval-protocol-key-label
    (codex:network-approval-protocol-https))
  "https")

!(assertEqual
  (codex:host-approval-key-from-request
    (CodexNetworkPolicyRequest
      (CodexNetworkProtocolHttpsConnect)
      "Example.COM"
      443))
  (host-key-https-443))

!(assertEqual
  (codex:pending-approval-decision-to-network-decision
    (codex:pending-approval-decision-allow-once))
  (codex:network-decision-allow))

!(assertEqual
  (codex:pending-approval-decision-to-network-decision
    (codex:pending-approval-decision-allow-for-session))
  (codex:network-decision-allow))

!(assertEqual
  (codex:pending-approval-decision-to-network-decision
    (codex:pending-approval-decision-deny))
  (codex:network-decision-deny "not_allowed"))

!(assertEqual
  (codex:allows-network-approval-flow
    (codex:ask-for-approval-never))
  False)

!(assertEqual
  (codex:allows-network-approval-flow
    (codex:ask-for-approval-on-request))
  True)

!(assertEqual
  (codex:sandbox-policy-allows-network-approval-flow
    (CodexSessionSandboxPolicyReadOnly () ()))
  True)

!(assertEqual
  (codex:sandbox-policy-allows-network-approval-flow
    (CodexSessionSandboxPolicyWorkspaceWrite () () False False))
  True)

!(assertEqual
  (codex:sandbox-policy-allows-network-approval-flow
    (CodexSessionSandboxPolicyDangerFullAccess))
  False)

(= (first-pending)
   (codex:network-approval-get-or-create-pending-approval
     (codex:network-approval-service-default)
     (host-key-http-443)))

!(assertEqual
  (codex:network-approval-get-or-create-pending-result-is-owner
    (first-pending))
  True)

(= (second-pending)
   (codex:network-approval-get-or-create-pending-approval
     (codex:network-approval-get-or-create-pending-result-service
       (first-pending))
     (host-key-http-443)))

!(assertEqual
  (codex:network-approval-get-or-create-pending-result-is-owner
    (second-pending))
  False)

!(assertEqual
  (codex:network-approval-service-pending-host-approvals
    (codex:network-approval-get-or-create-pending-result-service
      (second-pending)))
  ((CodexHostApprovalKey "example.com" "http" 443)))

(= (different-port-pending)
   (codex:network-approval-get-or-create-pending-approval
     (codex:network-approval-get-or-create-pending-result-service
       (first-pending))
     (host-key-https-8443)))

!(assertEqual
  (codex:network-approval-get-or-create-pending-result-is-owner
    (different-port-pending))
  True)

!(assertEqual
  (codex:network-approval-service-pending-host-approvals
    (codex:network-approval-get-or-create-pending-result-service
      (different-port-pending)))
  ((CodexHostApprovalKey "example.com" "http" 443)
   (CodexHostApprovalKey "example.com" "https" 8443)))

(= (source-approved)
   (codex:network-approval-service-with-session-approved-hosts
     (codex:network-approval-service-default)
     ((host-key-http-443) (host-key-https-443))))

(= (target-approved)
   (codex:network-approval-service-with-session-approved-hosts
     (codex:network-approval-service-default)
     ((host-key-https-8443))))

!(assertEqual
  (codex:network-approval-service-session-approved-hosts
    (codex:network-approval-sync-session-approved-hosts-to
      (source-approved)
      (target-approved)))
  ((CodexHostApprovalKey "example.com" "http" 443)
   (CodexHostApprovalKey "example.com" "https" 443)))

!(assertEqual
  (codex:network-approval-resolve-single-active-call
    (service-with-one-call))
  (codex:network-approval-active-call
    "registration-1"
    "turn-1"
    (trigger)
    "curl https://example.com"))

!(assertEqual
  (codex:network-approval-active-call-trigger
    (codex:network-approval-resolve-single-active-call
      (service-with-one-call)))
  (trigger))

(= (blocked-outcome-service)
   (codex:network-approval-record-blocked-request
     (service-with-one-call)
     (denied-blocked-request)))

!(assertEqual
  (codex:network-approval-call-outcomes-get
    (codex:network-approval-service-call-outcomes
      (blocked-outcome-service))
    "registration-1")
  (codex:network-approval-outcome-denied-by-policy
    "Network access to \"example.com\" was blocked: domain is not on the allowlist for the current sandbox mode."))

!(assertEqual
  (codex:network-approval-call-outcomes-get
    (codex:network-approval-service-call-outcomes
      (codex:network-approval-record-blocked-request
        (codex:network-approval-record-call-outcome
          (service-with-one-call)
          "registration-1"
          (codex:network-approval-outcome-denied-by-user))
        (denied-blocked-request)))
    "registration-1")
  (codex:network-approval-outcome-denied-by-user))

!(assertEqual
  (codex:network-approval-service-call-outcomes
    (codex:network-approval-record-blocked-request
      (codex:network-approval-register-call
        (service-with-one-call)
        "registration-2"
        "turn-1"
        (trigger)
        "curl https://example.com")
      (denied-blocked-request)))
  ())

(= (begin-immediate)
   (codex:begin-network-approval
     (codex:network-approval-service-default)
     "turn-1"
     True
     (spec (codex:network-approval-mode-immediate))
     "registration-1"))

!(assertEqual
  (codex:network-approval-begin-result-active
    (begin-immediate))
  (codex:active-network-approval
    "registration-1"
    (codex:network-approval-mode-immediate)))

!(assertEqual
  (codex:network-approval-service-active-calls
    (codex:network-approval-begin-result-service
      (begin-immediate)))
  ((CodexNetworkApprovalActiveCall
     "registration-1"
     "turn-1"
     (CodexGuardianNetworkAccessTrigger
       "call-1"
       "shell"
       ("curl" "https://example.com")
       "/tmp"
       "use_default"
       CodexAbsent
       CodexAbsent
       CodexAbsent)
     "curl https://example.com")))

!(assertEqual
  (codex:network-approval-begin-result-active
    (codex:begin-network-approval
      (codex:network-approval-service-default)
      "turn-1"
      False
      (spec (codex:network-approval-mode-immediate))
      "registration-1"))
  CodexAbsent)

!(assertEqual
  (codex:network-approval-begin-result-active
    (codex:begin-network-approval
      (codex:network-approval-service-default)
      "turn-1"
      True
      (codex:network-approval-spec
        CodexAbsent
        (codex:network-approval-mode-immediate)
        (trigger)
        "curl https://example.com")
      "registration-1"))
  CodexAbsent)

!(assertEqual
  (codex:active-network-approval-into-deferred
    (codex:active-network-approval
      "registration-1"
      (codex:network-approval-mode-deferred)))
  (codex:deferred-network-approval "registration-1"))

!(assertEqual
  (codex:active-network-approval-into-deferred
    (codex:active-network-approval
      "registration-1"
      (codex:network-approval-mode-immediate)))
  CodexAbsent)

(= (finish-ok)
   (codex:finish-immediate-network-approval
     (service-with-one-call)
     (codex:active-network-approval
       "registration-1"
       (codex:network-approval-mode-immediate))))

!(assertEqual
  (codex:network-approval-finish-immediate-result-outcome
    (finish-ok))
  (codex:network-approval-finish-immediate-ok))

!(assertEqual
  (codex:network-approval-service-active-calls
    (codex:network-approval-finish-immediate-result-service
      (finish-ok)))
  ())

(= (finish-user-denied)
   (codex:finish-immediate-network-approval
     (codex:network-approval-record-call-outcome
       (service-with-one-call)
       "registration-1"
       (codex:network-approval-outcome-denied-by-user))
     (codex:active-network-approval
       "registration-1"
       (codex:network-approval-mode-immediate))))

!(assertEqual
  (codex:network-approval-finish-immediate-result-outcome
    (finish-user-denied))
  (codex:network-approval-finish-immediate-err
    (CodexToolErrorRejected "rejected by user")))

(= (finish-policy-denied)
   (codex:finish-immediate-network-approval
     (codex:network-approval-record-call-outcome
       (service-with-one-call)
       "registration-1"
       (codex:network-approval-outcome-denied-by-policy "blocked"))
     (codex:active-network-approval
       "registration-1"
       (codex:network-approval-mode-immediate))))

!(assertEqual
  (codex:network-approval-finish-immediate-result-outcome
    (finish-policy-denied))
  (codex:network-approval-finish-immediate-err
    (CodexToolErrorRejected "blocked")))

!(assertEqual
  (codex:network-approval-service-active-calls
    (codex:finish-deferred-network-approval
      (service-with-one-call)
      (codex:deferred-network-approval "registration-1")))
  ())
