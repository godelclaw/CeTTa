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
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust registers and unregisters active network approvals asynchronously
;   through session services. This pure slice only materializes the spec that
;   a runtime returns before that registration boundary.
; - Rust represents `GuardianNetworkAccessTrigger.tty` as `Option<bool>`.
;   This port uses `CodexAbsent` for `None` and a boolean value for `Some(_)`,
;   matching the restarted CeTTa convention for optional fields.

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
