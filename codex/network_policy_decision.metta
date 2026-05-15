; Narrow Rust-faithful network-policy-decision slice.
;
; This ports the pure helper behavior from:
; - openai-codex/codex-rs/core/src/network_policy_decision.rs
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust relies on serde derives for `NetworkPolicyDecisionPayload`. The current
;   CeTTa slice exposes a narrow JSON parser that returns `Empty` on invalid
;   inputs instead of a typed serde error.
; - Rust carries `BlockedRequest.mode` as a typed network mode enum. The helper
;   logic here does not inspect that field, so the current CeTTa slice keeps it
;   as an opaque atom.
; - `NetworkPolicyAmendment` / `NetworkPolicyRuleAction` are already present in
;   the restarted port through the context-fragment slice; this module matches
;   those raw constructors directly so it can stay self-contained.

!(import! &self json)
!(import! &self str)

(= (codex:network-policy-decision-deny)
   (CodexNetworkPolicyDecisionDeny))

(= (codex:network-policy-decision-ask)
   (CodexNetworkPolicyDecisionAsk))

(= (codex:network-decision-source-baseline-policy)
   (CodexNetworkDecisionSourceBaselinePolicy))

(= (codex:network-decision-source-mode-guard)
   (CodexNetworkDecisionSourceModeGuard))

(= (codex:network-decision-source-proxy-state)
   (CodexNetworkDecisionSourceProxyState))

(= (codex:network-decision-source-decider)
   (CodexNetworkDecisionSourceDecider))

(= (codex:network-approval-protocol-http)
   (CodexNetworkApprovalProtocolHttp))

(= (codex:network-approval-protocol-https)
   (CodexNetworkApprovalProtocolHttps))

(= (codex:network-approval-protocol-socks5-tcp)
   (CodexNetworkApprovalProtocolSocks5Tcp))

(= (codex:network-approval-protocol-socks5-udp)
   (CodexNetworkApprovalProtocolSocks5Udp))

(= (codex:network-approval-context $host $protocol)
   (CodexNetworkApprovalContext $host $protocol))

(= (codex:network-approval-context-host
      (CodexNetworkApprovalContext $host $protocol))
   $host)

(= (codex:network-approval-context-protocol
      (CodexNetworkApprovalContext $host $protocol))
   $protocol)

(= (codex:network-policy-decision-payload
      $decision
      $source
      $protocol
      $host
      $reason
      $port)
   (CodexNetworkPolicyDecisionPayload
     $decision
     $source
     $protocol
     $host
     $reason
     $port))

(= (codex:network-policy-decision-payload-decision
      (CodexNetworkPolicyDecisionPayload
        $decision
        $source
        $protocol
        $host
        $reason
        $port))
   $decision)

(= (codex:network-policy-decision-payload-source
      (CodexNetworkPolicyDecisionPayload
        $decision
        $source
        $protocol
        $host
        $reason
        $port))
   $source)

(= (codex:network-policy-decision-payload-protocol
      (CodexNetworkPolicyDecisionPayload
        $decision
        $source
        $protocol
        $host
        $reason
        $port))
   $protocol)

(= (codex:network-policy-decision-payload-host
      (CodexNetworkPolicyDecisionPayload
        $decision
        $source
        $protocol
        $host
        $reason
        $port))
   $host)

(= (codex:network-policy-decision-payload-reason
      (CodexNetworkPolicyDecisionPayload
        $decision
        $source
        $protocol
        $host
        $reason
        $port))
   $reason)

(= (codex:network-policy-decision-payload-port
      (CodexNetworkPolicyDecisionPayload
        $decision
        $source
        $protocol
        $host
        $reason
        $port))
   $port)

(= (codex:blocked-request
      $host
      $reason
      $client
      $method
      $mode
      $protocol
      $decision
      $source
      $port
      $timestamp)
   (CodexBlockedRequest
     $host
     $reason
     $client
     $method
     $mode
     $protocol
     $decision
     $source
     $port
     $timestamp))

(= (codex:blocked-request-host
      (CodexBlockedRequest
        $host
        $reason
        $client
        $method
        $mode
        $protocol
        $decision
        $source
        $port
        $timestamp))
   $host)

(= (codex:blocked-request-reason
      (CodexBlockedRequest
        $host
        $reason
        $client
        $method
        $mode
        $protocol
        $decision
        $source
        $port
        $timestamp))
   $reason)

(= (codex:blocked-request-decision
      (CodexBlockedRequest
        $host
        $reason
        $client
        $method
        $mode
        $protocol
        $decision
        $source
        $port
        $timestamp))
   $decision)

(= (codex:execpolicy-decision-allow)
   (CodexExecPolicyDecisionAllow))

(= (codex:execpolicy-decision-prompt)
   (CodexExecPolicyDecisionPrompt))

(= (codex:execpolicy-decision-forbidden)
   (CodexExecPolicyDecisionForbidden))

(= (codex:execpolicy-network-rule-protocol-http)
   (CodexExecPolicyNetworkRuleProtocolHttp))

(= (codex:execpolicy-network-rule-protocol-https)
   (CodexExecPolicyNetworkRuleProtocolHttps))

(= (codex:execpolicy-network-rule-protocol-socks5-tcp)
   (CodexExecPolicyNetworkRuleProtocolSocks5Tcp))

(= (codex:execpolicy-network-rule-protocol-socks5-udp)
   (CodexExecPolicyNetworkRuleProtocolSocks5Udp))

(= (codex:execpolicy-network-rule-amendment
      $protocol
      $decision
      $justification)
   (CodexExecPolicyNetworkRuleAmendment
     $protocol
     $decision
     $justification))

(= (codex:execpolicy-network-rule-amendment-protocol
      (CodexExecPolicyNetworkRuleAmendment
        $protocol
        $decision
        $justification))
   $protocol)

(= (codex:execpolicy-network-rule-amendment-decision
      (CodexExecPolicyNetworkRuleAmendment
        $protocol
        $decision
        $justification))
   $decision)

(= (codex:execpolicy-network-rule-amendment-justification
      (CodexExecPolicyNetworkRuleAmendment
        $protocol
        $decision
        $justification))
   $justification)

(= (codex:network-policy-decision-json-object-optional-value $object $key)
   (case (json-object-get $object $key)
     ((Empty CodexAbsent)
      (JsonNull CodexAbsent)
      ($value $value))))

(= (codex:network-policy-decision-json-object-optional-string $object $key)
   (case (codex:network-policy-decision-json-object-optional-value $object $key)
     ((CodexAbsent CodexAbsent)
      ((JsonString $text) $text))))

(= (codex:network-policy-decision-json-object-optional-int $object $key)
   (case (codex:network-policy-decision-json-object-optional-value $object $key)
     ((CodexAbsent CodexAbsent)
      ((JsonNumber $text)
       (codex:network-policy-decision-decimal-string-to-number $text)))))

(= (codex:network-policy-decision-decimal-digit-value $digit)
   (case $digit
     (("0" 0)
      ("1" 1)
      ("2" 2)
      ("3" 3)
      ("4" 4)
      ("5" 5)
      ("6" 6)
      ("7" 7)
      ("8" 8)
      ("9" 9))))

(= (codex:network-policy-decision-decimal-string-to-number $text)
   (if (== $text "")
       0
       (codex:network-policy-decision-decimal-string-to-number-from
         $text
         0
         0)))

(= (codex:network-policy-decision-decimal-string-to-number-from
      $text
      $index
      $acc)
   (if (>= $index (str-length $text))
       $acc
       (let $digit
         (codex:network-policy-decision-decimal-digit-value
           (str-slice $text $index (+ $index 1)))
         (codex:network-policy-decision-decimal-string-to-number-from
           $text
           (+ $index 1)
           (+ (* $acc 10) $digit)))))

(= (codex:parse-network-policy-decision-text $text)
   (case $text
     (("deny" (codex:network-policy-decision-deny))
      ("ask" (codex:network-policy-decision-ask))
      ($other Empty))))

(= (codex:parse-network-decision-source-text $text)
   (case $text
     (("baseline_policy" (codex:network-decision-source-baseline-policy))
      ("mode_guard" (codex:network-decision-source-mode-guard))
      ("proxy_state" (codex:network-decision-source-proxy-state))
      ("decider" (codex:network-decision-source-decider))
      ($other Empty))))

(= (codex:parse-network-approval-protocol-text $text)
   (case $text
     (("http" (codex:network-approval-protocol-http))
      ("https" (codex:network-approval-protocol-https))
      ("https_connect" (codex:network-approval-protocol-https))
      ("http-connect" (codex:network-approval-protocol-https))
      ("socks5_tcp" (codex:network-approval-protocol-socks5-tcp))
      ("socks5_udp" (codex:network-approval-protocol-socks5-udp))
      ($other Empty))))

(= (codex:parse-network-policy-decision-payload-json $text)
   (case (json-parse $text)
     (((JsonObject $pairs)
       (codex:parse-network-policy-decision-payload-object
         (JsonObject $pairs)))
      ($other
       Empty))))

(= (codex:parse-network-policy-decision-payload-object $object)
   (let $decision
     (codex:parse-network-policy-decision-text
       (json-string-value (json-object-get $object "decision")))
     (if (== $decision Empty)
         Empty
         (let $source
           (codex:parse-network-decision-source-text
             (json-string-value (json-object-get $object "source")))
           (if (== $source Empty)
               Empty
               (let $protocol
                 (case (codex:network-policy-decision-json-object-optional-string
                         $object
                         "protocol")
                   ((CodexAbsent CodexAbsent)
                    ($text
                     (codex:parse-network-approval-protocol-text $text))))
                 (if (== $protocol Empty)
                     Empty
                     (codex:network-policy-decision-payload
                       $decision
                       $source
                       $protocol
                       (codex:network-policy-decision-json-object-optional-string
                         $object
                         "host")
                       (codex:network-policy-decision-json-object-optional-string
                         $object
                         "reason")
                       (codex:network-policy-decision-json-object-optional-int
                         $object
                         "port")))))))))

(= (codex:is-ask-from-decider-network-policy-decision-payload $payload)
   (case $payload
     (((CodexNetworkPolicyDecisionPayload
         (CodexNetworkPolicyDecisionAsk)
         (CodexNetworkDecisionSourceDecider)
         $protocol
         $host
         $reason
         $port)
       True)
      ($other False))))

(= (codex:network-approval-context-from-payload $payload)
   (case $payload
     (((CodexNetworkPolicyDecisionPayload
         (CodexNetworkPolicyDecisionAsk)
         (CodexNetworkDecisionSourceDecider)
         $protocol
         $host
         $reason
         $port)
       (if (== $protocol CodexAbsent)
           Empty
           (if (== $host CodexAbsent)
               Empty
               (let $trimmed-host (str-trim $host)
                 (if (== $trimmed-host "")
                     Empty
                     (codex:network-approval-context
                       $trimmed-host
                       $protocol))))))
      ($other Empty))))

(= (codex:parse-blocked-request-decision $decision)
   (if (== $decision CodexAbsent)
       Empty
       (codex:parse-network-policy-decision-text $decision)))

(= (codex:denied-network-policy-message
      (CodexBlockedRequest
        $host
        $reason
        $client
        $method
        $mode
        $protocol
        $decision
        $source
        $port
        $timestamp))
   (if (== (codex:parse-blocked-request-decision $decision)
           (codex:network-policy-decision-deny))
       (let $trimmed-host (str-trim $host)
         (if (== $trimmed-host "")
             "Network access was blocked by policy."
             (let $detail
               (case $reason
                 (("denied"
                   "domain is explicitly denied by policy and cannot be approved from this prompt")
                  ("not_allowed"
                   "domain is not on the allowlist for the current sandbox mode")
                  ("not_allowed_local"
                   "local/private network addresses are blocked by the sandbox policy")
                  ("method_not_allowed"
                   "request method is blocked by the current network mode")
                  ("proxy_disabled"
                   "network proxy is disabled")
                  ($other
                   "request is blocked by network policy")))
               (format-args
                 "Network access to \"{}\" was blocked: {}."
                 ($trimmed-host $detail)))))
       Empty))

(= (codex:network-approval-protocol-label
      (CodexNetworkApprovalProtocolHttp))
   "http")

(= (codex:network-approval-protocol-label
      (CodexNetworkApprovalProtocolHttps))
   "https_connect")

(= (codex:network-approval-protocol-label
      (CodexNetworkApprovalProtocolSocks5Tcp))
   "socks5_tcp")

(= (codex:network-approval-protocol-label
      (CodexNetworkApprovalProtocolSocks5Udp))
   "socks5_udp")

(= (codex:execpolicy-network-rule-amendment-from-network-policy-amendment
      (CodexNetworkPolicyAmendment
        (CodexNetworkPolicyRuleActionAllow)
        $amendment-host)
      (CodexNetworkApprovalContext $context-host (CodexNetworkApprovalProtocolHttp))
      $host)
   (codex:execpolicy-network-rule-amendment
     (codex:execpolicy-network-rule-protocol-http)
     (codex:execpolicy-decision-allow)
     (format-args "Allow http access to {}" ($host))))

(= (codex:execpolicy-network-rule-amendment-from-network-policy-amendment
      (CodexNetworkPolicyAmendment
        (CodexNetworkPolicyRuleActionDeny)
        $amendment-host)
      (CodexNetworkApprovalContext $context-host (CodexNetworkApprovalProtocolHttp))
      $host)
   (codex:execpolicy-network-rule-amendment
     (codex:execpolicy-network-rule-protocol-http)
     (codex:execpolicy-decision-forbidden)
     (format-args "Deny http access to {}" ($host))))

(= (codex:execpolicy-network-rule-amendment-from-network-policy-amendment
      (CodexNetworkPolicyAmendment
        (CodexNetworkPolicyRuleActionAllow)
        $amendment-host)
      (CodexNetworkApprovalContext $context-host (CodexNetworkApprovalProtocolHttps))
      $host)
   (codex:execpolicy-network-rule-amendment
     (codex:execpolicy-network-rule-protocol-https)
     (codex:execpolicy-decision-allow)
     (format-args "Allow https_connect access to {}" ($host))))

(= (codex:execpolicy-network-rule-amendment-from-network-policy-amendment
      (CodexNetworkPolicyAmendment
        (CodexNetworkPolicyRuleActionDeny)
        $amendment-host)
      (CodexNetworkApprovalContext $context-host (CodexNetworkApprovalProtocolHttps))
      $host)
   (codex:execpolicy-network-rule-amendment
     (codex:execpolicy-network-rule-protocol-https)
     (codex:execpolicy-decision-forbidden)
     (format-args "Deny https_connect access to {}" ($host))))

(= (codex:execpolicy-network-rule-amendment-from-network-policy-amendment
      (CodexNetworkPolicyAmendment
        (CodexNetworkPolicyRuleActionAllow)
        $amendment-host)
      (CodexNetworkApprovalContext $context-host (CodexNetworkApprovalProtocolSocks5Tcp))
      $host)
   (codex:execpolicy-network-rule-amendment
     (codex:execpolicy-network-rule-protocol-socks5-tcp)
     (codex:execpolicy-decision-allow)
     (format-args "Allow socks5_tcp access to {}" ($host))))

(= (codex:execpolicy-network-rule-amendment-from-network-policy-amendment
      (CodexNetworkPolicyAmendment
        (CodexNetworkPolicyRuleActionDeny)
        $amendment-host)
      (CodexNetworkApprovalContext $context-host (CodexNetworkApprovalProtocolSocks5Tcp))
      $host)
   (codex:execpolicy-network-rule-amendment
     (codex:execpolicy-network-rule-protocol-socks5-tcp)
     (codex:execpolicy-decision-forbidden)
     (format-args "Deny socks5_tcp access to {}" ($host))))

(= (codex:execpolicy-network-rule-amendment-from-network-policy-amendment
      (CodexNetworkPolicyAmendment
        (CodexNetworkPolicyRuleActionAllow)
        $amendment-host)
      (CodexNetworkApprovalContext $context-host (CodexNetworkApprovalProtocolSocks5Udp))
      $host)
   (codex:execpolicy-network-rule-amendment
     (codex:execpolicy-network-rule-protocol-socks5-udp)
     (codex:execpolicy-decision-allow)
     (format-args "Allow socks5_udp access to {}" ($host))))

(= (codex:execpolicy-network-rule-amendment-from-network-policy-amendment
      (CodexNetworkPolicyAmendment
        (CodexNetworkPolicyRuleActionDeny)
        $amendment-host)
      (CodexNetworkApprovalContext $context-host (CodexNetworkApprovalProtocolSocks5Udp))
      $host)
   (codex:execpolicy-network-rule-amendment
     (codex:execpolicy-network-rule-protocol-socks5-udp)
     (codex:execpolicy-decision-forbidden)
     (format-args "Deny socks5_udp access to {}" ($host))))
