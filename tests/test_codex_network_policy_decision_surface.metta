!(register-module! ../codex)
!(import! &self codex:network_policy_decision)

!(assertEqual
  (codex:network-approval-context-from-payload
    (codex:network-policy-decision-payload
      (codex:network-policy-decision-deny)
      (codex:network-decision-source-decider)
      (codex:network-approval-protocol-https)
      "example.com"
      "not_allowed"
      443))
  Empty)

!(assertEqual
  (codex:network-approval-context-from-payload
    (codex:network-policy-decision-payload
      (codex:network-policy-decision-ask)
      (codex:network-decision-source-decider)
      (codex:network-approval-protocol-http)
      "example.com"
      "not_allowed"
      80))
  (CodexNetworkApprovalContext
    "example.com"
    (CodexNetworkApprovalProtocolHttp)))

!(assertEqual
  (codex:network-approval-context-from-payload
    (codex:network-policy-decision-payload
      (codex:network-policy-decision-ask)
      (codex:network-decision-source-decider)
      (codex:network-approval-protocol-socks5-tcp)
      "example.com"
      "not_allowed"
      443))
  (CodexNetworkApprovalContext
    "example.com"
    (CodexNetworkApprovalProtocolSocks5Tcp)))

!(assertEqual
  (codex:network-approval-context-from-payload
    (codex:network-policy-decision-payload
      (codex:network-policy-decision-ask)
      (codex:network-decision-source-decider)
      (codex:network-approval-protocol-socks5-udp)
      "example.com"
      "not_allowed"
      443))
  (CodexNetworkApprovalContext
    "example.com"
    (CodexNetworkApprovalProtocolSocks5Udp)))

!(assertEqual
  (codex:network-policy-decision-payload-protocol
    (codex:parse-network-policy-decision-payload-json
      "{\"decision\":\"ask\",\"source\":\"decider\",\"protocol\":\"https_connect\",\"host\":\"example.com\",\"reason\":\"not_allowed\",\"port\":443}"))
  (CodexNetworkApprovalProtocolHttps))

!(assertEqual
  (codex:network-policy-decision-payload-protocol
    (codex:parse-network-policy-decision-payload-json
      "{\"decision\":\"ask\",\"source\":\"decider\",\"protocol\":\"http-connect\",\"host\":\"example.com\",\"reason\":\"not_allowed\",\"port\":443}"))
  (CodexNetworkApprovalProtocolHttps))

!(assertEqual
  (codex:execpolicy-network-rule-amendment-from-network-policy-amendment
    (CodexNetworkPolicyAmendment
      (CodexNetworkPolicyRuleActionDeny)
      "example.com")
    (codex:network-approval-context
      "example.com"
      (codex:network-approval-protocol-socks5-udp))
    "example.com")
  (CodexExecPolicyNetworkRuleAmendment
    (CodexExecPolicyNetworkRuleProtocolSocks5Udp)
    (CodexExecPolicyDecisionForbidden)
    "Deny socks5_udp access to example.com"))

!(assertEqual
  (codex:denied-network-policy-message
    (codex:blocked-request
      "example.com"
      "not_allowed"
      CodexAbsent
      "GET"
      CodexAbsent
      "http"
      "ask"
      "decider"
      80
      0))
  Empty)

!(assertEqual
  (codex:denied-network-policy-message
    (codex:blocked-request
      "example.com"
      "denied"
      CodexAbsent
      "GET"
      CodexAbsent
      "http"
      "deny"
      "baseline_policy"
      80
      0))
  "Network access to \"example.com\" was blocked: domain is explicitly denied by policy and cannot be approved from this prompt.")
