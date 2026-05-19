; Rust-faithful pure network-approval data slice.
;
; This ports deterministic data shapes from:
; - openai-codex/codex-rs/core/src/tools/network_approval.rs
; - openai-codex/codex-rs/core/src/guardian.rs
;
; Covered in this increment:
; - `NetworkApprovalMode`
; - `GuardianNetworkAccessTrigger`
; - `NetworkApprovalSpec`
; - `DeferredNetworkApproval`
; - `ActiveNetworkApproval`
; - `HostApprovalKey`
; - `PendingApprovalDecision`
; - pure `NetworkApprovalService` state transitions for registration,
;   blocked-request outcome recording, begin/finish approval lifecycle, and
;   session-approved-host synchronization
; - pure `handle_inline_policy_request` branch resolution for session host
;   caches, pending approvals, hook decisions, review decisions, and
;   session-scoped allow/deny caching
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust registers/unregisters active network approvals asynchronously through
;   `Session.services.network_approval`. This pure slice models the same
;   service state as explicit immutable data passed into and returned from each
;   transition.
; - Rust represents `GuardianNetworkAccessTrigger.tty` as `Option<bool>`.
;   This port uses `CodexAbsent` for `None` and a boolean value for `Some(_)`,
;   matching the restarted CeTTa convention for optional fields.
; - Rust uses UUIDs for active network approval registration ids. This pure
;   boundary takes the registration id as an input so file-mode tests can stay
;   deterministic while preserving the same branch behavior.
; - Rust's `PendingHostApproval` waits on `Notify` when a second request joins
;   an in-flight approval. This pure boundary exposes the eventual pending
;   decision as an explicit input and returns `CodexAbsent` while that wait is
;   unresolved.
; - Rust persists network-policy amendments and emits warning events from the
;   async session. This pure boundary models the same allow/deny control-flow
;   result and session host cache effects; persistence/event side effects remain
;   outside this deterministic data slice.

!(import! &self approval)
!(import! &self list)
!(import! &self network_policy_decision)
!(import! &self str)

(= (codex:network-approval-mode-immediate)
   (CodexNetworkApprovalModeImmediate))

(= (codex:network-approval-mode-deferred)
   (CodexNetworkApprovalModeDeferred))

(= (codex:guardian-network-access-trigger
      $call-id
      $tool-name
      $command
      $cwd
      $sandbox-permissions
      $additional-permissions
      $justification
      $tty)
   (CodexGuardianNetworkAccessTrigger
     $call-id
     $tool-name
     $command
     $cwd
     $sandbox-permissions
     $additional-permissions
     $justification
     $tty))

(= (codex:guardian-network-access-trigger-call-id
      (CodexGuardianNetworkAccessTrigger
        $call-id
        $tool-name
        $command
        $cwd
        $sandbox-permissions
        $additional-permissions
        $justification
        $tty))
   $call-id)

(= (codex:guardian-network-access-trigger-tool-name
      (CodexGuardianNetworkAccessTrigger
        $call-id
        $tool-name
        $command
        $cwd
        $sandbox-permissions
        $additional-permissions
        $justification
        $tty))
   $tool-name)

(= (codex:guardian-network-access-trigger-command
      (CodexGuardianNetworkAccessTrigger
        $call-id
        $tool-name
        $command
        $cwd
        $sandbox-permissions
        $additional-permissions
        $justification
        $tty))
   $command)

(= (codex:guardian-network-access-trigger-cwd
      (CodexGuardianNetworkAccessTrigger
        $call-id
        $tool-name
        $command
        $cwd
        $sandbox-permissions
        $additional-permissions
        $justification
        $tty))
   $cwd)

(= (codex:guardian-network-access-trigger-sandbox-permissions
      (CodexGuardianNetworkAccessTrigger
        $call-id
        $tool-name
        $command
        $cwd
        $sandbox-permissions
        $additional-permissions
        $justification
        $tty))
   $sandbox-permissions)

(= (codex:guardian-network-access-trigger-additional-permissions
      (CodexGuardianNetworkAccessTrigger
        $call-id
        $tool-name
        $command
        $cwd
        $sandbox-permissions
        $additional-permissions
        $justification
        $tty))
   $additional-permissions)

(= (codex:guardian-network-access-trigger-justification
      (CodexGuardianNetworkAccessTrigger
        $call-id
        $tool-name
        $command
        $cwd
        $sandbox-permissions
        $additional-permissions
        $justification
        $tty))
   $justification)

(= (codex:guardian-network-access-trigger-tty
      (CodexGuardianNetworkAccessTrigger
        $call-id
        $tool-name
        $command
        $cwd
        $sandbox-permissions
        $additional-permissions
        $justification
        $tty))
   $tty)

(= (codex:network-approval-spec $network $mode $trigger $command)
   (CodexNetworkApprovalSpec $network $mode $trigger $command))

(= (codex:network-approval-spec-network
      (CodexNetworkApprovalSpec $network $mode $trigger $command))
   $network)

(= (codex:network-approval-spec-mode
      (CodexNetworkApprovalSpec $network $mode $trigger $command))
   $mode)

(= (codex:network-approval-spec-trigger
      (CodexNetworkApprovalSpec $network $mode $trigger $command))
   $trigger)

(= (codex:network-approval-spec-command
      (CodexNetworkApprovalSpec $network $mode $trigger $command))
   $command)

(= (codex:deferred-network-approval $registration-id)
   (CodexDeferredNetworkApproval $registration-id))

(= (codex:deferred-network-approval-registration-id
      (CodexDeferredNetworkApproval $registration-id))
   $registration-id)

(= (codex:active-network-approval $registration-id $mode)
   (CodexActiveNetworkApproval $registration-id $mode))

(= (codex:active-network-approval-registration-id
      (CodexActiveNetworkApproval $registration-id $mode))
   $registration-id)

(= (codex:active-network-approval-mode
      (CodexActiveNetworkApproval $registration-id $mode))
   $mode)

(= (codex:active-network-approval-into-deferred
      (CodexActiveNetworkApproval $registration-id $mode))
   (if (and
         (== $mode (codex:network-approval-mode-deferred))
         (not (== $registration-id CodexAbsent)))
       (codex:deferred-network-approval $registration-id)
       CodexAbsent))

(= (codex:network-approval-ascii-lower-char $char)
   (case $char
     (("A" "a")
      ("B" "b")
      ("C" "c")
      ("D" "d")
      ("E" "e")
      ("F" "f")
      ("G" "g")
      ("H" "h")
      ("I" "i")
      ("J" "j")
      ("K" "k")
      ("L" "l")
      ("M" "m")
      ("N" "n")
      ("O" "o")
      ("P" "p")
      ("Q" "q")
      ("R" "r")
      ("S" "s")
      ("T" "t")
      ("U" "u")
      ("V" "v")
      ("W" "w")
      ("X" "x")
      ("Y" "y")
      ("Z" "z")
      ($other $other))))

(= (codex:network-approval-ascii-lower-text $text)
   (if (== $text "")
       ""
       (str-concat
         (codex:network-approval-ascii-lower-char
           (str-slice $text 0 1))
         (codex:network-approval-ascii-lower-text
           (str-slice $text 1 (str-length $text))))))

(= (codex:network-protocol-http)
   (CodexNetworkProtocolHttp))

(= (codex:network-protocol-https-connect)
   (CodexNetworkProtocolHttpsConnect))

(= (codex:network-protocol-socks5-tcp)
   (CodexNetworkProtocolSocks5Tcp))

(= (codex:network-protocol-socks5-udp)
   (CodexNetworkProtocolSocks5Udp))

(= (codex:network-approval-protocol-from-network-protocol
      (CodexNetworkProtocolHttp))
   (codex:network-approval-protocol-http))

(= (codex:network-approval-protocol-from-network-protocol
      (codex:network-protocol-http))
   (codex:network-approval-protocol-http))

(= (codex:network-approval-protocol-from-network-protocol
      (CodexNetworkProtocolHttpsConnect))
   (codex:network-approval-protocol-https))

(= (codex:network-approval-protocol-from-network-protocol
      (codex:network-protocol-https-connect))
   (codex:network-approval-protocol-https))

(= (codex:network-approval-protocol-from-network-protocol
      (CodexNetworkProtocolSocks5Tcp))
   (codex:network-approval-protocol-socks5-tcp))

(= (codex:network-approval-protocol-from-network-protocol
      (codex:network-protocol-socks5-tcp))
   (codex:network-approval-protocol-socks5-tcp))

(= (codex:network-approval-protocol-from-network-protocol
      (CodexNetworkProtocolSocks5Udp))
   (codex:network-approval-protocol-socks5-udp))

(= (codex:network-approval-protocol-from-network-protocol
      (codex:network-protocol-socks5-udp))
   (codex:network-approval-protocol-socks5-udp))

(= (codex:network-approval-protocol-key-label
      (CodexNetworkApprovalProtocolHttp))
   "http")

(= (codex:network-approval-protocol-key-label
      (CodexNetworkApprovalProtocolHttps))
   "https")

(= (codex:network-approval-protocol-key-label
      (CodexNetworkApprovalProtocolSocks5Tcp))
   "socks5-tcp")

(= (codex:network-approval-protocol-key-label
      (CodexNetworkApprovalProtocolSocks5Udp))
   "socks5-udp")

(= (codex:network-policy-request $protocol $host $port)
   (CodexNetworkPolicyRequest $protocol $host $port))

(= (codex:network-policy-request-protocol
      (CodexNetworkPolicyRequest $protocol $host $port))
   $protocol)

(= (codex:network-policy-request-protocol
      (codex:network-policy-request $protocol $host $port))
   $protocol)

(= (codex:network-policy-request-host
      (CodexNetworkPolicyRequest $protocol $host $port))
   $host)

(= (codex:network-policy-request-host
      (codex:network-policy-request $protocol $host $port))
   $host)

(= (codex:network-policy-request-port
      (CodexNetworkPolicyRequest $protocol $host $port))
   $port)

(= (codex:network-policy-request-port
      (codex:network-policy-request $protocol $host $port))
   $port)

(= (codex:host-approval-key $host $protocol $port)
   (CodexHostApprovalKey $host $protocol $port))

(= (codex:host-approval-key-host
      (CodexHostApprovalKey $host $protocol $port))
   $host)

(= (codex:host-approval-key-protocol
      (CodexHostApprovalKey $host $protocol $port))
   $protocol)

(= (codex:host-approval-key-port
      (CodexHostApprovalKey $host $protocol $port))
   $port)

(= (codex:host-approval-key-from-request $request)
   (let $approval-protocol
     (codex:network-approval-protocol-from-network-protocol
       (codex:network-policy-request-protocol $request))
     (codex:host-approval-key
       (codex:network-approval-ascii-lower-text
         (codex:network-policy-request-host $request))
       (codex:network-approval-protocol-key-label $approval-protocol)
       (codex:network-policy-request-port $request))))

(= (codex:host-approval-key-from-request
      (codex:network-policy-request
        (codex:network-protocol-http)
        $host
        $port))
   (codex:host-approval-key
     (codex:network-approval-ascii-lower-text $host)
     "http"
     $port))

(= (codex:host-approval-key-from-request
      (codex:network-policy-request
        (codex:network-protocol-https-connect)
        $host
        $port))
   (codex:host-approval-key
     (codex:network-approval-ascii-lower-text $host)
     "https"
     $port))

(= (codex:host-approval-key-from-request
      (codex:network-policy-request
        (codex:network-protocol-socks5-tcp)
        $host
        $port))
   (codex:host-approval-key
     (codex:network-approval-ascii-lower-text $host)
     "socks5-tcp"
     $port))

(= (codex:host-approval-key-from-request
      (codex:network-policy-request
        (codex:network-protocol-socks5-udp)
        $host
        $port))
   (codex:host-approval-key
     (codex:network-approval-ascii-lower-text $host)
     "socks5-udp"
     $port))

(= (codex:pending-approval-decision-allow-once)
   (CodexPendingApprovalDecisionAllowOnce))

(= (codex:pending-approval-decision-allow-for-session)
   (CodexPendingApprovalDecisionAllowForSession))

(= (codex:pending-approval-decision-deny)
   (CodexPendingApprovalDecisionDeny))

(= (codex:network-decision-allow)
   (CodexNetworkDecisionAllow))

(= (codex:network-decision-deny $reason)
   (CodexNetworkDecisionDeny
     $reason
     (codex:network-decision-source-decider)
     (codex:network-policy-decision-deny)))

(= (codex:network-decision-ask $reason)
   (CodexNetworkDecisionDeny
     $reason
     (codex:network-decision-source-decider)
     (codex:network-policy-decision-ask)))

(= (codex:pending-approval-decision-to-network-decision
      (CodexPendingApprovalDecisionAllowOnce))
   (codex:network-decision-allow))

(= (codex:pending-approval-decision-to-network-decision
      (CodexPendingApprovalDecisionAllowForSession))
   (codex:network-decision-allow))

(= (codex:pending-approval-decision-to-network-decision
      (CodexPendingApprovalDecisionDeny))
   (codex:network-decision-deny "not_allowed"))

(= (codex:network-approval-outcome-denied-by-user)
   (CodexNetworkApprovalOutcomeDeniedByUser))

(= (codex:network-approval-outcome-denied-by-policy $message)
   (CodexNetworkApprovalOutcomeDeniedByPolicy $message))

(= (codex:allows-network-approval-flow $approval-policy)
   (not (== $approval-policy (codex:ask-for-approval-never))))

(= (codex:sandbox-policy-allows-network-approval-flow
      $sandbox-policy)
   (case $sandbox-policy
     (((CodexSessionSandboxPolicyReadOnly $access $network-access)
       True)
      ((CodexSessionSandboxPolicyWorkspaceWrite
         $writable-roots
         $network-access
         $exclude-tmpdir-env-var
         $exclude-slash-tmp)
       True)
      ($other False))))

(= (codex:network-approval-service
      $active-calls
      $call-outcomes
      $pending-host-approvals
      $session-approved-hosts
      $session-denied-hosts)
   (CodexNetworkApprovalService
     $active-calls
     $call-outcomes
     $pending-host-approvals
     $session-approved-hosts
     $session-denied-hosts))

(= (codex:network-approval-service-default)
   (codex:network-approval-service () () () () ()))

(= (codex:network-approval-service-active-calls
      (CodexNetworkApprovalService
        $active-calls
        $call-outcomes
        $pending-host-approvals
        $session-approved-hosts
        $session-denied-hosts))
   $active-calls)

(= (codex:network-approval-service-call-outcomes
      (CodexNetworkApprovalService
        $active-calls
        $call-outcomes
        $pending-host-approvals
        $session-approved-hosts
        $session-denied-hosts))
   $call-outcomes)

(= (codex:network-approval-service-pending-host-approvals
      (CodexNetworkApprovalService
        $active-calls
        $call-outcomes
        $pending-host-approvals
        $session-approved-hosts
        $session-denied-hosts))
   $pending-host-approvals)

(= (codex:network-approval-service-session-approved-hosts
      (CodexNetworkApprovalService
        $active-calls
        $call-outcomes
        $pending-host-approvals
        $session-approved-hosts
        $session-denied-hosts))
   $session-approved-hosts)

(= (codex:network-approval-service-session-denied-hosts
      (CodexNetworkApprovalService
        $active-calls
        $call-outcomes
        $pending-host-approvals
        $session-approved-hosts
        $session-denied-hosts))
   $session-denied-hosts)

(= (codex:network-approval-active-call
      $registration-id
      $turn-id
      $trigger
      $command)
   (CodexNetworkApprovalActiveCall
     $registration-id
     $turn-id
     $trigger
     $command))

(= (codex:network-approval-active-call-registration-id
      (CodexNetworkApprovalActiveCall
        $registration-id
        $turn-id
        $trigger
        $command))
   $registration-id)

(= (codex:network-approval-active-call-turn-id
      (CodexNetworkApprovalActiveCall
        $registration-id
        $turn-id
        $trigger
        $command))
   $turn-id)

(= (codex:network-approval-active-call-trigger
      (CodexNetworkApprovalActiveCall
        $registration-id
        $turn-id
        $trigger
        $command))
   $trigger)

(= (codex:network-approval-active-call-command
      (CodexNetworkApprovalActiveCall
        $registration-id
        $turn-id
        $trigger
        $command))
   $command)

(= (codex:network-approval-list-contains $items $item)
   (case $items
     ((() False)
      ($_ (let ($head $tail) (decons-atom $items)
            (if (== $head $item)
                True
                (codex:network-approval-list-contains $tail $item)))))))

(= (codex:network-approval-list-remove $items $item)
   (case $items
     ((() ())
      ($_ (let ($head $tail) (decons-atom $items)
            (let $rest
              (codex:network-approval-list-remove $tail $item)
              (if (== $head $item)
                  $rest
                  (list:cons $head $rest))))))))

(= (codex:network-approval-list-insert-set $items $item)
   (if (codex:network-approval-list-contains $items $item)
       $items
       (list:append $items ($item))))

(= (codex:network-approval-active-call-list-remove
      ()
      $registration-id)
   ())

(= (codex:network-approval-active-call-list-remove
      $calls
      $registration-id)
   (let ($head $tail) (decons-atom $calls)
     (let $rest
       (codex:network-approval-active-call-list-remove
         $tail
         $registration-id)
       (if (==
             (codex:network-approval-active-call-registration-id $head)
             $registration-id)
           $rest
           (list:cons $head $rest)))))

(= (codex:network-approval-call-outcome-pair
      $registration-id
      $outcome)
   (CodexNetworkApprovalCallOutcomePair
     $registration-id
     $outcome))

(= (codex:network-approval-call-outcome-pair-registration-id
      (CodexNetworkApprovalCallOutcomePair $registration-id $outcome))
   $registration-id)

(= (codex:network-approval-call-outcome-pair-outcome
      (CodexNetworkApprovalCallOutcomePair $registration-id $outcome))
   $outcome)

(= (codex:network-approval-call-outcomes-get
      ()
      $registration-id)
   CodexAbsent)

(= (codex:network-approval-call-outcomes-get
      $outcomes
      $registration-id)
   (let ($head $tail) (decons-atom $outcomes)
     (if (==
           (codex:network-approval-call-outcome-pair-registration-id
             $head)
           $registration-id)
         (codex:network-approval-call-outcome-pair-outcome $head)
         (codex:network-approval-call-outcomes-get
           $tail
           $registration-id))))

(= (codex:network-approval-call-outcomes-remove
      ()
      $registration-id)
   ())

(= (codex:network-approval-call-outcomes-remove
      $outcomes
      $registration-id)
   (let ($head $tail) (decons-atom $outcomes)
     (let $rest
       (codex:network-approval-call-outcomes-remove
         $tail
         $registration-id)
       (if (==
             (codex:network-approval-call-outcome-pair-registration-id
               $head)
             $registration-id)
           $rest
           (list:cons $head $rest)))))

(= (codex:network-approval-call-outcomes-insert
      $outcomes
      $registration-id
      $outcome)
   (list:append
     (codex:network-approval-call-outcomes-remove
       $outcomes
       $registration-id)
     ((codex:network-approval-call-outcome-pair
        $registration-id
        $outcome))))

(= (codex:network-approval-register-call
      $service
      $registration-id
      $turn-id
      $trigger
      $command)
   (codex:network-approval-service
     (list:append
       (codex:network-approval-service-active-calls $service)
       ((codex:network-approval-active-call
          $registration-id
          $turn-id
          $trigger
          $command)))
     (codex:network-approval-service-call-outcomes $service)
     (codex:network-approval-service-pending-host-approvals $service)
     (codex:network-approval-service-session-approved-hosts $service)
     (codex:network-approval-service-session-denied-hosts $service)))

(= (codex:network-approval-unregister-call
      $service
      $registration-id)
   (codex:network-approval-service
     (codex:network-approval-active-call-list-remove
       (codex:network-approval-service-active-calls $service)
       $registration-id)
     (codex:network-approval-call-outcomes-remove
       (codex:network-approval-service-call-outcomes $service)
       $registration-id)
     (codex:network-approval-service-pending-host-approvals $service)
     (codex:network-approval-service-session-approved-hosts $service)
     (codex:network-approval-service-session-denied-hosts $service)))

(= (codex:network-approval-resolve-single-active-call
      $service)
   (let $calls
     (codex:network-approval-service-active-calls $service)
     (if (== (list:len $calls) 1)
         (list:at $calls 0)
         CodexAbsent)))

(= (codex:network-approval-record-call-outcome
      $service
      $registration-id
      $outcome)
   (let $current
     (codex:network-approval-call-outcomes-get
       (codex:network-approval-service-call-outcomes $service)
       $registration-id)
     (if (== $current (codex:network-approval-outcome-denied-by-user))
         $service
         (codex:network-approval-service
           (codex:network-approval-service-active-calls $service)
           (codex:network-approval-call-outcomes-insert
             (codex:network-approval-service-call-outcomes $service)
             $registration-id
             $outcome)
           (codex:network-approval-service-pending-host-approvals $service)
           (codex:network-approval-service-session-approved-hosts $service)
           (codex:network-approval-service-session-denied-hosts $service)))))

(= (codex:network-approval-record-outcome-for-single-active-call
      $service
      $outcome)
   (let $owner-call
     (codex:network-approval-resolve-single-active-call $service)
     (if (== $owner-call CodexAbsent)
         $service
         (codex:network-approval-record-call-outcome
           $service
           (codex:network-approval-active-call-registration-id
             $owner-call)
           $outcome))))

(= (codex:network-approval-take-call-outcome-result
      $outcome
      $service)
   (CodexNetworkApprovalTakeCallOutcomeResult $outcome $service))

(= (codex:network-approval-take-call-outcome-result-outcome
      (CodexNetworkApprovalTakeCallOutcomeResult $outcome $service))
   $outcome)

(= (codex:network-approval-take-call-outcome-result-service
      (CodexNetworkApprovalTakeCallOutcomeResult $outcome $service))
   $service)

(= (codex:network-approval-take-call-outcome
      $service
      $registration-id)
   (codex:network-approval-take-call-outcome-result
     (codex:network-approval-call-outcomes-get
       (codex:network-approval-service-call-outcomes $service)
       $registration-id)
     (codex:network-approval-service
       (codex:network-approval-service-active-calls $service)
       (codex:network-approval-call-outcomes-remove
         (codex:network-approval-service-call-outcomes $service)
         $registration-id)
       (codex:network-approval-service-pending-host-approvals $service)
       (codex:network-approval-service-session-approved-hosts $service)
       (codex:network-approval-service-session-denied-hosts $service))))

(= (codex:network-approval-record-blocked-request
      $service
      $blocked-request)
   (let $message
     (codex:denied-network-policy-message $blocked-request)
     (if (== $message Empty)
         $service
         (codex:network-approval-record-outcome-for-single-active-call
           $service
           (codex:network-approval-outcome-denied-by-policy
             $message)))))

(= (codex:network-approval-get-or-create-pending-result
      $pending
      $is-owner
      $service)
   (CodexNetworkApprovalGetOrCreatePendingResult
     $pending
     $is-owner
     $service))

(= (codex:network-approval-get-or-create-pending-result-pending
      (CodexNetworkApprovalGetOrCreatePendingResult
        $pending
        $is-owner
        $service))
   $pending)

(= (codex:network-approval-get-or-create-pending-result-is-owner
      (CodexNetworkApprovalGetOrCreatePendingResult
        $pending
        $is-owner
        $service))
   $is-owner)

(= (codex:network-approval-get-or-create-pending-result-service
      (CodexNetworkApprovalGetOrCreatePendingResult
        $pending
        $is-owner
        $service))
   $service)

(= (codex:network-approval-get-or-create-pending-approval
      $service
      $key)
   (if (codex:network-approval-list-contains
         (codex:network-approval-service-pending-host-approvals
           $service)
         $key)
       (codex:network-approval-get-or-create-pending-result
         $key
         False
         $service)
       (codex:network-approval-get-or-create-pending-result
         $key
         True
         (codex:network-approval-service
           (codex:network-approval-service-active-calls $service)
           (codex:network-approval-service-call-outcomes $service)
           (list:append
             (codex:network-approval-service-pending-host-approvals
               $service)
             ($key))
           (codex:network-approval-service-session-approved-hosts
             $service)
           (codex:network-approval-service-session-denied-hosts
             $service)))))

(= (codex:network-approval-service-with-session-approved-hosts
      $service
      $approved-hosts)
   (codex:network-approval-service
     (codex:network-approval-service-active-calls $service)
     (codex:network-approval-service-call-outcomes $service)
     (codex:network-approval-service-pending-host-approvals $service)
     $approved-hosts
     (codex:network-approval-service-session-denied-hosts $service)))

(= (codex:network-approval-service-with-session-denied-hosts
      $service
      $denied-hosts)
   (codex:network-approval-service
     (codex:network-approval-service-active-calls $service)
     (codex:network-approval-service-call-outcomes $service)
     (codex:network-approval-service-pending-host-approvals $service)
     (codex:network-approval-service-session-approved-hosts $service)
     $denied-hosts))

(= (codex:network-approval-service-with-pending-host-approvals
      $service
      $pending-host-approvals)
   (codex:network-approval-service
     (codex:network-approval-service-active-calls $service)
     (codex:network-approval-service-call-outcomes $service)
     $pending-host-approvals
     (codex:network-approval-service-session-approved-hosts $service)
     (codex:network-approval-service-session-denied-hosts $service)))

(= (codex:network-approval-sync-session-approved-hosts-to
      $source
      $target)
   (codex:network-approval-service-with-session-approved-hosts
     $target
     (codex:network-approval-service-session-approved-hosts $source)))

(= (codex:network-approval-begin-result $active $service)
   (CodexNetworkApprovalBeginResult $active $service))

(= (codex:network-approval-begin-result-active
      (CodexNetworkApprovalBeginResult $active $service))
   $active)

(= (codex:network-approval-begin-result-service
      (CodexNetworkApprovalBeginResult $active $service))
   $service)

(= (codex:begin-network-approval
      $service
      $turn-id
      $managed-network-active
      CodexAbsent
      $registration-id)
   (codex:network-approval-begin-result CodexAbsent $service))

(= (codex:begin-network-approval
      $service
      $turn-id
      $managed-network-active
      (CodexNetworkApprovalSpec $network $mode $trigger $command)
      $registration-id)
   (if (or
         (not $managed-network-active)
         (== $network CodexAbsent))
       (codex:network-approval-begin-result CodexAbsent $service)
       (codex:network-approval-begin-result
         (codex:active-network-approval $registration-id $mode)
         (codex:network-approval-register-call
           $service
           $registration-id
           $turn-id
           $trigger
           $command))))

(= (codex:network-approval-finish-immediate-ok)
   (CodexNetworkApprovalFinishImmediateOk))

(= (codex:network-approval-finish-immediate-err $tool-error)
   (CodexNetworkApprovalFinishImmediateErr $tool-error))

(= (codex:network-approval-finish-immediate-result
      $outcome
      $service)
   (CodexNetworkApprovalFinishImmediateResult $outcome $service))

(= (codex:network-approval-finish-immediate-result-outcome
      (CodexNetworkApprovalFinishImmediateResult $outcome $service))
   $outcome)

(= (codex:network-approval-finish-immediate-result-service
      (CodexNetworkApprovalFinishImmediateResult $outcome $service))
   $service)

(= (codex:network-approval-outcome-to-finish-immediate
      CodexAbsent)
   (codex:network-approval-finish-immediate-ok))

(= (codex:network-approval-outcome-to-finish-immediate
      (CodexNetworkApprovalOutcomeDeniedByUser))
   (codex:network-approval-finish-immediate-err
     (CodexToolErrorRejected "rejected by user")))

(= (codex:network-approval-outcome-to-finish-immediate
      (CodexNetworkApprovalOutcomeDeniedByPolicy $message))
   (codex:network-approval-finish-immediate-err
     (CodexToolErrorRejected $message)))

(= (codex:finish-immediate-network-approval
      $service
      (CodexActiveNetworkApproval CodexAbsent $mode))
   (codex:network-approval-finish-immediate-result
     (codex:network-approval-finish-immediate-ok)
     $service))

(= (codex:finish-immediate-network-approval
      $service
      (CodexActiveNetworkApproval $registration-id $mode))
   (let $take-result
     (codex:network-approval-take-call-outcome
       $service
       $registration-id)
     (let $service-after-take
       (codex:network-approval-take-call-outcome-result-service
         $take-result)
       (codex:network-approval-finish-immediate-result
         (codex:network-approval-outcome-to-finish-immediate
           (codex:network-approval-take-call-outcome-result-outcome
             $take-result))
         (codex:network-approval-unregister-call
           $service-after-take
           $registration-id)))))

(= (codex:finish-deferred-network-approval
      $service
      CodexAbsent)
   $service)

(= (codex:finish-deferred-network-approval
      $service
      (CodexDeferredNetworkApproval $registration-id))
   (codex:network-approval-unregister-call
     $service
     $registration-id))

(= (codex:network-approval-format-network-target
      $protocol-label
      $host
      $port)
   (format-args "{}://{}:{}" ($protocol-label $host $port)))

(= (codex:network-approval-approval-id-for-key $key)
   (case (once (eval $key))
     (((CodexHostApprovalKey $host $protocol $port)
       (format-args "network#{}#{}#{}" ($protocol $host $port))))))

(= (codex:network-approval-policy-denial-message $target)
   (format-args
     "Network access to \"{}\" was blocked by policy."
     ($target)))

(= (codex:network-approval-prompt-reason $host)
   (format-args "{} is not in the allowed_domains" ($host)))

(= (codex:network-approval-prompt-command $target)
   ("network-access" $target))

(= (codex:network-approval-hook-subcommand $target)
   (format-args "network-access {}" ($target)))

(= (codex:network-approval-hook-command
      CodexAbsent
      $target)
   (codex:network-approval-hook-subcommand $target))

(= (codex:network-approval-hook-command
      (CodexNetworkApprovalActiveCall
        $registration-id
        $turn-id
        $trigger
        $command)
      $target)
   $command)

(= (codex:network-approval-inline-turn-context
      $turn-id
      $cwd
      $sandbox-policy
      $approval-policy
      $routes-approval-to-guardian
      $guardian-rejection-message
      $guardian-timeout-message)
   (CodexNetworkApprovalInlineTurnContext
     $turn-id
     $cwd
     $sandbox-policy
     $approval-policy
     $routes-approval-to-guardian
     $guardian-rejection-message
     $guardian-timeout-message))

(= (codex:network-approval-inline-turn-context-turn-id
      (CodexNetworkApprovalInlineTurnContext
        $turn-id
        $cwd
        $sandbox-policy
        $approval-policy
        $routes-approval-to-guardian
        $guardian-rejection-message
        $guardian-timeout-message))
   $turn-id)

(= (codex:network-approval-inline-turn-context-cwd
      (CodexNetworkApprovalInlineTurnContext
        $turn-id
        $cwd
        $sandbox-policy
        $approval-policy
        $routes-approval-to-guardian
        $guardian-rejection-message
        $guardian-timeout-message))
   $cwd)

(= (codex:network-approval-inline-turn-context-sandbox-policy
      (CodexNetworkApprovalInlineTurnContext
        $turn-id
        $cwd
        $sandbox-policy
        $approval-policy
        $routes-approval-to-guardian
        $guardian-rejection-message
        $guardian-timeout-message))
   $sandbox-policy)

(= (codex:network-approval-inline-turn-context-approval-policy
      (CodexNetworkApprovalInlineTurnContext
        $turn-id
        $cwd
        $sandbox-policy
        $approval-policy
        $routes-approval-to-guardian
        $guardian-rejection-message
        $guardian-timeout-message))
   $approval-policy)

(= (codex:network-approval-inline-turn-context-routes-approval-to-guardian
      (CodexNetworkApprovalInlineTurnContext
        $turn-id
        $cwd
        $sandbox-policy
        $approval-policy
        $routes-approval-to-guardian
        $guardian-rejection-message
        $guardian-timeout-message))
   $routes-approval-to-guardian)

(= (codex:network-approval-inline-turn-context-guardian-rejection-message
      (CodexNetworkApprovalInlineTurnContext
        $turn-id
        $cwd
        $sandbox-policy
        $approval-policy
        $routes-approval-to-guardian
        $guardian-rejection-message
        $guardian-timeout-message))
   $guardian-rejection-message)

(= (codex:network-approval-inline-turn-context-guardian-timeout-message
      (CodexNetworkApprovalInlineTurnContext
        $turn-id
        $cwd
        $sandbox-policy
        $approval-policy
        $routes-approval-to-guardian
        $guardian-rejection-message
        $guardian-timeout-message))
   $guardian-timeout-message)

(= (codex:network-approval-inline-policy-input
      $turn-context
      $permission-request-hook-decision
      $approval-decision
      $existing-pending-decision)
   (CodexNetworkApprovalInlinePolicyInput
     $turn-context
     $permission-request-hook-decision
     $approval-decision
     $existing-pending-decision))

(= (codex:network-approval-inline-policy-input-turn-context
      (CodexNetworkApprovalInlinePolicyInput
        $turn-context
        $permission-request-hook-decision
        $approval-decision
        $existing-pending-decision))
   $turn-context)

(= (codex:network-approval-inline-policy-input-hook-decision
      (CodexNetworkApprovalInlinePolicyInput
        $turn-context
        $permission-request-hook-decision
        $approval-decision
        $existing-pending-decision))
   $permission-request-hook-decision)

(= (codex:network-approval-inline-policy-input-approval-decision
      (CodexNetworkApprovalInlinePolicyInput
        $turn-context
        $permission-request-hook-decision
        $approval-decision
        $existing-pending-decision))
   $approval-decision)

(= (codex:network-approval-inline-policy-input-existing-pending-decision
      (CodexNetworkApprovalInlinePolicyInput
        $turn-context
        $permission-request-hook-decision
        $approval-decision
        $existing-pending-decision))
   $existing-pending-decision)

(= (codex:network-approval-inline-policy-result
      $network-decision
      $resolved-pending-decision
      $service
      $approval-id
      $target
      $prompt-command
      $prompt-reason
      $network-approval-context
      $hook-command
      $hook-subcommand)
   (CodexNetworkApprovalInlinePolicyResult
     $network-decision
     $resolved-pending-decision
     $service
     $approval-id
     $target
     $prompt-command
     $prompt-reason
     $network-approval-context
     $hook-command
     $hook-subcommand))

(= (codex:network-approval-inline-policy-result-decision
      (CodexNetworkApprovalInlinePolicyResult
        $network-decision
        $resolved-pending-decision
        $service
        $approval-id
        $target
        $prompt-command
        $prompt-reason
        $network-approval-context
        $hook-command
        $hook-subcommand))
   $network-decision)

(= (codex:network-approval-inline-policy-result-resolved-pending-decision
      (CodexNetworkApprovalInlinePolicyResult
        $network-decision
        $resolved-pending-decision
        $service
        $approval-id
        $target
        $prompt-command
        $prompt-reason
        $network-approval-context
        $hook-command
        $hook-subcommand))
   $resolved-pending-decision)

(= (codex:network-approval-inline-policy-result-service
      (CodexNetworkApprovalInlinePolicyResult
        $network-decision
        $resolved-pending-decision
        $service
        $approval-id
        $target
        $prompt-command
        $prompt-reason
        $network-approval-context
        $hook-command
        $hook-subcommand))
   $service)

(= (codex:network-approval-inline-policy-result-approval-id
      (CodexNetworkApprovalInlinePolicyResult
        $network-decision
        $resolved-pending-decision
        $service
        $approval-id
        $target
        $prompt-command
        $prompt-reason
        $network-approval-context
        $hook-command
        $hook-subcommand))
   $approval-id)

(= (codex:network-approval-inline-policy-result-target
      (CodexNetworkApprovalInlinePolicyResult
        $network-decision
        $resolved-pending-decision
        $service
        $approval-id
        $target
        $prompt-command
        $prompt-reason
        $network-approval-context
        $hook-command
        $hook-subcommand))
   $target)

(= (codex:network-approval-inline-policy-result-prompt-command
      (CodexNetworkApprovalInlinePolicyResult
        $network-decision
        $resolved-pending-decision
        $service
        $approval-id
        $target
        $prompt-command
        $prompt-reason
        $network-approval-context
        $hook-command
        $hook-subcommand))
   $prompt-command)

(= (codex:network-approval-inline-policy-result-prompt-reason
      (CodexNetworkApprovalInlinePolicyResult
        $network-decision
        $resolved-pending-decision
        $service
        $approval-id
        $target
        $prompt-command
        $prompt-reason
        $network-approval-context
        $hook-command
        $hook-subcommand))
   $prompt-reason)

(= (codex:network-approval-inline-policy-result-network-approval-context
      (CodexNetworkApprovalInlinePolicyResult
        $network-decision
        $resolved-pending-decision
        $service
        $approval-id
        $target
        $prompt-command
        $prompt-reason
        $network-approval-context
        $hook-command
        $hook-subcommand))
   $network-approval-context)

(= (codex:network-approval-inline-policy-result-hook-command
      (CodexNetworkApprovalInlinePolicyResult
        $network-decision
        $resolved-pending-decision
        $service
        $approval-id
        $target
        $prompt-command
        $prompt-reason
        $network-approval-context
        $hook-command
        $hook-subcommand))
   $hook-command)

(= (codex:network-approval-inline-policy-result-hook-subcommand
      (CodexNetworkApprovalInlinePolicyResult
        $network-decision
        $resolved-pending-decision
        $service
        $approval-id
        $target
        $prompt-command
        $prompt-reason
        $network-approval-context
        $hook-command
        $hook-subcommand))
   $hook-subcommand)

(= (codex:network-approval-remove-pending-host-approval
      $service
      $key)
   (codex:network-approval-service-with-pending-host-approvals
     $service
     (codex:network-approval-list-remove
       (codex:network-approval-service-pending-host-approvals
         $service)
       $key)))

(= (codex:network-approval-cache-session-allow
      $service
      $key)
   (codex:network-approval-service
     (codex:network-approval-service-active-calls $service)
     (codex:network-approval-service-call-outcomes $service)
     (codex:network-approval-service-pending-host-approvals $service)
     (codex:network-approval-list-insert-set
       (codex:network-approval-service-session-approved-hosts
         $service)
       $key)
     (codex:network-approval-list-remove
       (codex:network-approval-service-session-denied-hosts
         $service)
       $key)))

(= (codex:network-approval-cache-session-deny
      $service
      $key)
   (codex:network-approval-service
     (codex:network-approval-service-active-calls $service)
     (codex:network-approval-service-call-outcomes $service)
     (codex:network-approval-service-pending-host-approvals $service)
     (codex:network-approval-list-remove
       (codex:network-approval-service-session-approved-hosts
         $service)
       $key)
     (codex:network-approval-list-insert-set
       (codex:network-approval-service-session-denied-hosts
         $service)
       $key)))

(= (codex:network-approval-record-owner-call-outcome
      $service
      CodexAbsent
      $outcome)
   $service)

(= (codex:network-approval-record-owner-call-outcome
      $service
      (CodexNetworkApprovalActiveCall
        $registration-id
        $turn-id
        $trigger
        $command)
      $outcome)
   (codex:network-approval-record-call-outcome
     $service
     $registration-id
     $outcome))

(= (codex:network-approval-apply-resolved-pending-decision
      $service
      $key
      $resolved
      $cache-session-deny)
   (let $cache-applied
     (if (== $resolved (codex:pending-approval-decision-allow-for-session))
         (codex:network-approval-cache-session-allow $service $key)
         (if $cache-session-deny
             (codex:network-approval-cache-session-deny $service $key)
             $service))
     (codex:network-approval-remove-pending-host-approval
       $cache-applied
       $key)))

(= (codex:network-approval-inline-metadata-result
      $network-decision
      $resolved-pending-decision
      $service
      $key
      $request
      $approval-protocol
      $owner-call)
   (let $target
     (codex:network-approval-format-network-target
       (codex:host-approval-key-protocol $key)
       (codex:network-policy-request-host $request)
       (codex:host-approval-key-port $key))
     (codex:network-approval-inline-policy-result
       $network-decision
       $resolved-pending-decision
       $service
       (codex:network-approval-approval-id-for-key $key)
       $target
       (codex:network-approval-prompt-command $target)
       (codex:network-approval-prompt-reason
         (codex:network-policy-request-host $request))
       (codex:network-approval-context
         (codex:network-policy-request-host $request)
         $approval-protocol)
       (codex:network-approval-hook-command $owner-call $target)
       (codex:network-approval-hook-subcommand $target))))

(= (codex:network-approval-inline-hard-deny
      $service
      $key
      $request
      $approval-protocol
      $owner-call
      $policy-denial-message)
   (codex:network-approval-inline-metadata-result
     (codex:network-decision-deny "not_allowed")
     (codex:pending-approval-decision-deny)
     (codex:network-approval-remove-pending-host-approval
       (codex:network-approval-record-outcome-for-single-active-call
         $service
         (codex:network-approval-outcome-denied-by-policy
           $policy-denial-message))
       $key)
     $key
     $request
     $approval-protocol
     $owner-call))

(= (codex:network-approval-inline-finish-reviewed
      $service
      $key
      $request
      $approval-protocol
      $owner-call
      $resolved
      $cache-session-deny)
   (codex:network-approval-inline-metadata-result
     (codex:pending-approval-decision-to-network-decision $resolved)
     $resolved
     (codex:network-approval-apply-resolved-pending-decision
       $service
       $key
       $resolved
       $cache-session-deny)
     $key
     $request
     $approval-protocol
     $owner-call))

(= (codex:network-approval-inline-resolve-review-decision
      $service
      $key
      $request
      $approval-protocol
      $owner-call
      $routes-approval-to-guardian
      $guardian-rejection-message
      $guardian-timeout-message
      (CodexReviewDecisionApproved))
   (codex:network-approval-inline-finish-reviewed
     $service
     $key
     $request
     $approval-protocol
     $owner-call
     (codex:pending-approval-decision-allow-once)
     False))

(= (codex:network-approval-inline-resolve-review-decision
      $service
      $key
      $request
      $approval-protocol
      $owner-call
      $routes-approval-to-guardian
      $guardian-rejection-message
      $guardian-timeout-message
      (CodexReviewDecisionApprovedExecpolicyAmendment $amendment))
   (codex:network-approval-inline-finish-reviewed
     $service
     $key
     $request
     $approval-protocol
     $owner-call
     (codex:pending-approval-decision-allow-once)
     False))

(= (codex:network-approval-inline-resolve-review-decision
      $service
      $key
      $request
      $approval-protocol
      $owner-call
      $routes-approval-to-guardian
      $guardian-rejection-message
      $guardian-timeout-message
      (CodexReviewDecisionApprovedForSession))
   (codex:network-approval-inline-finish-reviewed
     $service
     $key
     $request
     $approval-protocol
     $owner-call
     (codex:pending-approval-decision-allow-for-session)
     False))

(= (codex:network-approval-inline-resolve-review-decision
      $service
      $key
      $request
      $approval-protocol
      $owner-call
      $routes-approval-to-guardian
      $guardian-rejection-message
      $guardian-timeout-message
      (CodexReviewDecisionNetworkPolicyAmendment
        (CodexNetworkPolicyAmendment
          (CodexNetworkPolicyRuleActionAllow)
          $host)))
   (codex:network-approval-inline-finish-reviewed
     $service
     $key
     $request
     $approval-protocol
     $owner-call
     (codex:pending-approval-decision-allow-for-session)
     False))

(= (codex:network-approval-inline-resolve-review-decision
      $service
      $key
      $request
      $approval-protocol
      $owner-call
      $routes-approval-to-guardian
      $guardian-rejection-message
      $guardian-timeout-message
      (CodexReviewDecisionNetworkPolicyAmendment
        (CodexNetworkPolicyAmendment
          (CodexNetworkPolicyRuleActionDeny)
          $host)))
   (codex:network-approval-inline-finish-reviewed
     (codex:network-approval-record-owner-call-outcome
       $service
       $owner-call
       (codex:network-approval-outcome-denied-by-user))
     $key
     $request
     $approval-protocol
     $owner-call
     (codex:pending-approval-decision-deny)
     True))

(= (codex:network-approval-inline-resolve-review-decision
      $service
      $key
      $request
      $approval-protocol
      $owner-call
      $routes-approval-to-guardian
      $guardian-rejection-message
      $guardian-timeout-message
      (CodexReviewDecisionDenied))
   (codex:network-approval-inline-finish-reviewed
     (codex:network-approval-record-owner-call-outcome
       $service
       $owner-call
       (if $routes-approval-to-guardian
           (codex:network-approval-outcome-denied-by-policy
             $guardian-rejection-message)
           (codex:network-approval-outcome-denied-by-user)))
     $key
     $request
     $approval-protocol
     $owner-call
     (codex:pending-approval-decision-deny)
     False))

(= (codex:network-approval-inline-resolve-review-decision
      $service
      $key
      $request
      $approval-protocol
      $owner-call
      $routes-approval-to-guardian
      $guardian-rejection-message
      $guardian-timeout-message
      (CodexReviewDecisionAbort))
   (codex:network-approval-inline-resolve-review-decision
     $service
     $key
     $request
     $approval-protocol
     $owner-call
     $routes-approval-to-guardian
     $guardian-rejection-message
     $guardian-timeout-message
     (CodexReviewDecisionDenied)))

(= (codex:network-approval-inline-resolve-review-decision
      $service
      $key
      $request
      $approval-protocol
      $owner-call
      $routes-approval-to-guardian
      $guardian-rejection-message
      $guardian-timeout-message
      (CodexReviewDecisionTimedOut))
   (codex:network-approval-inline-finish-reviewed
     (codex:network-approval-record-owner-call-outcome
       $service
       $owner-call
       (codex:network-approval-outcome-denied-by-policy
         $guardian-timeout-message))
     $key
     $request
     $approval-protocol
     $owner-call
     (codex:pending-approval-decision-deny)
     False))

(= (codex:network-approval-inline-owner-request
      $service
      $key
      $request
      $approval-protocol
      $owner-call
      (CodexNetworkApprovalInlinePolicyInput
        CodexAbsent
        $permission-request-hook-decision
        $approval-decision
        $existing-pending-decision))
   (let $target
     (codex:network-approval-format-network-target
       (codex:host-approval-key-protocol $key)
       (codex:network-policy-request-host $request)
       (codex:host-approval-key-port $key))
     (codex:network-approval-inline-hard-deny
       $service
       $key
       $request
       $approval-protocol
       $owner-call
       (codex:network-approval-policy-denial-message $target))))

(= (codex:network-approval-inline-owner-request
      $service
      $key
      $request
      $approval-protocol
      $owner-call
      (CodexNetworkApprovalInlinePolicyInput
        (CodexNetworkApprovalInlineTurnContext
          $turn-id
          $cwd
          $sandbox-policy
          $approval-policy
          $routes-approval-to-guardian
          $guardian-rejection-message
          $guardian-timeout-message)
        $permission-request-hook-decision
        $approval-decision
        $existing-pending-decision))
   (let $target
     (codex:network-approval-format-network-target
       (codex:host-approval-key-protocol $key)
       (codex:network-policy-request-host $request)
       (codex:host-approval-key-port $key))
     (let $policy-denial-message
       (codex:network-approval-policy-denial-message $target)
       (if (not
             (codex:sandbox-policy-allows-network-approval-flow
               $sandbox-policy))
           (codex:network-approval-inline-hard-deny
             $service
             $key
             $request
             $approval-protocol
             $owner-call
             $policy-denial-message)
           (if (not (codex:allows-network-approval-flow $approval-policy))
               (codex:network-approval-inline-hard-deny
                 $service
                 $key
                 $request
                 $approval-protocol
                 $owner-call
                 $policy-denial-message)
               (case $permission-request-hook-decision
                 (((CodexPermissionRequestHookDecisionAllow)
                   (codex:network-approval-inline-finish-reviewed
                     $service
                     $key
                     $request
                     $approval-protocol
                     $owner-call
                     (codex:pending-approval-decision-allow-once)
                     False))
                  ((CodexPermissionRequestHookDecisionDeny $message)
                   (codex:network-approval-inline-finish-reviewed
                     (codex:network-approval-record-owner-call-outcome
                       $service
                       $owner-call
                       (codex:network-approval-outcome-denied-by-policy
                         $message))
                     $key
                     $request
                     $approval-protocol
                     $owner-call
                     (codex:pending-approval-decision-deny)
                     False))
                  ((CodexPermissionRequestHookDecisionNone)
                   (codex:network-approval-inline-resolve-review-decision
                     $service
                     $key
                     $request
                     $approval-protocol
                     $owner-call
                     $routes-approval-to-guardian
                     $guardian-rejection-message
                     $guardian-timeout-message
                     $approval-decision)))))))))

(= (codex:network-approval-handle-inline-policy-request
      $service
      $input
      $request)
   (let $approval-protocol
     (codex:network-approval-protocol-from-network-protocol
       (codex:network-policy-request-protocol $request))
     (let $key
       (once (eval (codex:host-approval-key-from-request $request)))
       (let $owner-call
         (codex:network-approval-resolve-single-active-call $service)
         (if (codex:network-approval-list-contains
               (codex:network-approval-service-session-denied-hosts
                 $service)
               $key)
             (codex:network-approval-inline-metadata-result
               (codex:network-decision-deny "not_allowed")
               CodexAbsent
               $service
               $key
               $request
               $approval-protocol
               $owner-call)
             (if (codex:network-approval-list-contains
                   (codex:network-approval-service-session-approved-hosts
                     $service)
                   $key)
                 (codex:network-approval-inline-metadata-result
                   (codex:network-decision-allow)
                   CodexAbsent
                   $service
                   $key
                   $request
                   $approval-protocol
                   $owner-call)
                 (let $pending-result
                   (codex:network-approval-get-or-create-pending-approval
                     $service
                     $key)
                   (if (not
                         (codex:network-approval-get-or-create-pending-result-is-owner
                           $pending-result))
                       (let $existing-pending-decision
                         (codex:network-approval-inline-policy-input-existing-pending-decision
                           $input)
                         (codex:network-approval-inline-metadata-result
                           (if (== $existing-pending-decision CodexAbsent)
                               CodexAbsent
                               (codex:pending-approval-decision-to-network-decision
                                 $existing-pending-decision))
                           $existing-pending-decision
                           (codex:network-approval-get-or-create-pending-result-service
                             $pending-result)
                           $key
                           $request
                           $approval-protocol
                           $owner-call))
                       (codex:network-approval-inline-owner-request
                         (codex:network-approval-get-or-create-pending-result-service
                           $pending-result)
                         $key
                         $request
                         $approval-protocol
                         $owner-call
                         $input)))))))))
