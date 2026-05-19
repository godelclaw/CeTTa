; Rust-faithful pure ToolOrchestrator control-flow slice.
;
; This ports deterministic orchestration behavior from:
; - openai-codex/codex-rs/core/src/tools/orchestrator.rs
;
; Covered in this increment:
; - `ToolOrchestrator::new`
; - `OrchestratorRunResult`
; - `ToolCtx` / `ToolError` / `SandboxAttempt` data carried through the
;   orchestration boundary
; - approval decision rejection semantics
; - permission-request hook precedence inside `request_approval`
; - first-attempt sandbox selection
; - sandbox-denial retry gating and escalated-attempt construction
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust executes async approval, network-approval registration, and tool
;   runtime calls. This pure CeTTa slice receives those side-effect outcomes as
;   explicit input data, so the port can preserve the same branch semantics
;   while the async session/runtime boundary is still being ported.
; - Rust's `new_guardian_review_id()` is runtime-generated. This slice takes
;   deterministic review ids in `CodexToolOrchestratorRunInputs` for testable
;   pure evaluation.
; - Rust trait dispatch calls tool-specific overrides for
;   `wants_no_sandbox_approval` and `should_bypass_approval`. This slice models
;   those virtual results as optional tool-config fields; `CodexAbsent` selects
;   the Rust default helper behavior already ported in `tool_sandboxing`.

!(import! &self network_policy_decision)
!(import! &self sandbox_manager)
!(import! &self str)
!(import! &self tool_sandboxing)

(= (codex:tool-orchestrator-new)
   (CodexToolOrchestrator (codex:sandbox-manager-new)))

(= (codex:tool-orchestrator-sandbox-manager
      (CodexToolOrchestrator $sandbox-manager))
   $sandbox-manager)

(= (codex:tool-orchestrator-tool-config
      $exec-approval-requirement
      $sandbox-mode-for-first-attempt
      $sandbox-preference
      $escalate-on-failure
      $wants-no-sandbox-approval
      $should-bypass-approval)
   (CodexToolOrchestratorToolConfig
     $exec-approval-requirement
     $sandbox-mode-for-first-attempt
     $sandbox-preference
     $escalate-on-failure
     $wants-no-sandbox-approval
     $should-bypass-approval))

(= (codex:tool-orchestrator-tool-config-exec-approval-requirement
      (CodexToolOrchestratorToolConfig
        $exec-approval-requirement
        $sandbox-mode-for-first-attempt
        $sandbox-preference
        $escalate-on-failure
        $wants-no-sandbox-approval
        $should-bypass-approval))
   $exec-approval-requirement)

(= (codex:tool-orchestrator-tool-config-sandbox-mode-for-first-attempt
      (CodexToolOrchestratorToolConfig
        $exec-approval-requirement
        $sandbox-mode-for-first-attempt
        $sandbox-preference
        $escalate-on-failure
        $wants-no-sandbox-approval
        $should-bypass-approval))
   $sandbox-mode-for-first-attempt)

(= (codex:tool-orchestrator-tool-config-sandbox-preference
      (CodexToolOrchestratorToolConfig
        $exec-approval-requirement
        $sandbox-mode-for-first-attempt
        $sandbox-preference
        $escalate-on-failure
        $wants-no-sandbox-approval
        $should-bypass-approval))
   $sandbox-preference)

(= (codex:tool-orchestrator-tool-config-escalate-on-failure
      (CodexToolOrchestratorToolConfig
        $exec-approval-requirement
        $sandbox-mode-for-first-attempt
        $sandbox-preference
        $escalate-on-failure
        $wants-no-sandbox-approval
        $should-bypass-approval))
   $escalate-on-failure)

(= (codex:tool-orchestrator-tool-config-wants-no-sandbox-approval
      (CodexToolOrchestratorToolConfig
        $exec-approval-requirement
        $sandbox-mode-for-first-attempt
        $sandbox-preference
        $escalate-on-failure
        $wants-no-sandbox-approval
        $should-bypass-approval))
   $wants-no-sandbox-approval)

(= (codex:tool-orchestrator-tool-config-should-bypass-approval
      (CodexToolOrchestratorToolConfig
        $exec-approval-requirement
        $sandbox-mode-for-first-attempt
        $sandbox-preference
        $escalate-on-failure
        $wants-no-sandbox-approval
        $should-bypass-approval))
   $should-bypass-approval)

(= (codex:tool-orchestrator-turn-context
      $file-system-sandbox-policy
      $network-sandbox-policy
      $sandbox-policy
      $cwd
      $managed-network-active
      $strict-auto-review
      $routes-approval-to-guardian
      $host-platform
      $windows-sandbox-level
      $windows-sandbox-private-desktop
      $use-legacy-landlock
      $codex-linux-sandbox-exe)
   (CodexToolOrchestratorTurnContext
     $file-system-sandbox-policy
     $network-sandbox-policy
     $sandbox-policy
     $cwd
     $managed-network-active
     $strict-auto-review
     $routes-approval-to-guardian
     $host-platform
     $windows-sandbox-level
     $windows-sandbox-private-desktop
     $use-legacy-landlock
     $codex-linux-sandbox-exe))

(= (codex:tool-orchestrator-turn-context-file-system-sandbox-policy
      (CodexToolOrchestratorTurnContext
        $file-system-sandbox-policy
        $network-sandbox-policy
        $sandbox-policy
        $cwd
        $managed-network-active
        $strict-auto-review
        $routes-approval-to-guardian
        $host-platform
        $windows-sandbox-level
        $windows-sandbox-private-desktop
        $use-legacy-landlock
        $codex-linux-sandbox-exe))
   $file-system-sandbox-policy)

(= (codex:tool-orchestrator-turn-context-network-sandbox-policy
      (CodexToolOrchestratorTurnContext
        $file-system-sandbox-policy
        $network-sandbox-policy
        $sandbox-policy
        $cwd
        $managed-network-active
        $strict-auto-review
        $routes-approval-to-guardian
        $host-platform
        $windows-sandbox-level
        $windows-sandbox-private-desktop
        $use-legacy-landlock
        $codex-linux-sandbox-exe))
   $network-sandbox-policy)

(= (codex:tool-orchestrator-turn-context-sandbox-policy
      (CodexToolOrchestratorTurnContext
        $file-system-sandbox-policy
        $network-sandbox-policy
        $sandbox-policy
        $cwd
        $managed-network-active
        $strict-auto-review
        $routes-approval-to-guardian
        $host-platform
        $windows-sandbox-level
        $windows-sandbox-private-desktop
        $use-legacy-landlock
        $codex-linux-sandbox-exe))
   $sandbox-policy)

(= (codex:tool-orchestrator-turn-context-cwd
      (CodexToolOrchestratorTurnContext
        $file-system-sandbox-policy
        $network-sandbox-policy
        $sandbox-policy
        $cwd
        $managed-network-active
        $strict-auto-review
        $routes-approval-to-guardian
        $host-platform
        $windows-sandbox-level
        $windows-sandbox-private-desktop
        $use-legacy-landlock
        $codex-linux-sandbox-exe))
   $cwd)

(= (codex:tool-orchestrator-turn-context-managed-network-active
      (CodexToolOrchestratorTurnContext
        $file-system-sandbox-policy
        $network-sandbox-policy
        $sandbox-policy
        $cwd
        $managed-network-active
        $strict-auto-review
        $routes-approval-to-guardian
        $host-platform
        $windows-sandbox-level
        $windows-sandbox-private-desktop
        $use-legacy-landlock
        $codex-linux-sandbox-exe))
   $managed-network-active)

(= (codex:tool-orchestrator-turn-context-strict-auto-review
      (CodexToolOrchestratorTurnContext
        $file-system-sandbox-policy
        $network-sandbox-policy
        $sandbox-policy
        $cwd
        $managed-network-active
        $strict-auto-review
        $routes-approval-to-guardian
        $host-platform
        $windows-sandbox-level
        $windows-sandbox-private-desktop
        $use-legacy-landlock
        $codex-linux-sandbox-exe))
   $strict-auto-review)

(= (codex:tool-orchestrator-turn-context-routes-approval-to-guardian
      (CodexToolOrchestratorTurnContext
        $file-system-sandbox-policy
        $network-sandbox-policy
        $sandbox-policy
        $cwd
        $managed-network-active
        $strict-auto-review
        $routes-approval-to-guardian
        $host-platform
        $windows-sandbox-level
        $windows-sandbox-private-desktop
        $use-legacy-landlock
        $codex-linux-sandbox-exe))
   $routes-approval-to-guardian)

(= (codex:tool-orchestrator-turn-context-host-platform
      (CodexToolOrchestratorTurnContext
        $file-system-sandbox-policy
        $network-sandbox-policy
        $sandbox-policy
        $cwd
        $managed-network-active
        $strict-auto-review
        $routes-approval-to-guardian
        $host-platform
        $windows-sandbox-level
        $windows-sandbox-private-desktop
        $use-legacy-landlock
        $codex-linux-sandbox-exe))
   $host-platform)

(= (codex:tool-orchestrator-turn-context-windows-sandbox-level
      (CodexToolOrchestratorTurnContext
        $file-system-sandbox-policy
        $network-sandbox-policy
        $sandbox-policy
        $cwd
        $managed-network-active
        $strict-auto-review
        $routes-approval-to-guardian
        $host-platform
        $windows-sandbox-level
        $windows-sandbox-private-desktop
        $use-legacy-landlock
        $codex-linux-sandbox-exe))
   $windows-sandbox-level)

(= (codex:tool-orchestrator-turn-context-windows-sandbox-private-desktop
      (CodexToolOrchestratorTurnContext
        $file-system-sandbox-policy
        $network-sandbox-policy
        $sandbox-policy
        $cwd
        $managed-network-active
        $strict-auto-review
        $routes-approval-to-guardian
        $host-platform
        $windows-sandbox-level
        $windows-sandbox-private-desktop
        $use-legacy-landlock
        $codex-linux-sandbox-exe))
   $windows-sandbox-private-desktop)

(= (codex:tool-orchestrator-turn-context-use-legacy-landlock
      (CodexToolOrchestratorTurnContext
        $file-system-sandbox-policy
        $network-sandbox-policy
        $sandbox-policy
        $cwd
        $managed-network-active
        $strict-auto-review
        $routes-approval-to-guardian
        $host-platform
        $windows-sandbox-level
        $windows-sandbox-private-desktop
        $use-legacy-landlock
        $codex-linux-sandbox-exe))
   $use-legacy-landlock)

(= (codex:tool-orchestrator-turn-context-codex-linux-sandbox-exe
      (CodexToolOrchestratorTurnContext
        $file-system-sandbox-policy
        $network-sandbox-policy
        $sandbox-policy
        $cwd
        $managed-network-active
        $strict-auto-review
        $routes-approval-to-guardian
        $host-platform
        $windows-sandbox-level
        $windows-sandbox-private-desktop
        $use-legacy-landlock
        $codex-linux-sandbox-exe))
   $codex-linux-sandbox-exe)

(= (codex:tool-orchestrator-tool-ctx
      $session
      $turn
      $call-id
      $tool-name)
   (CodexToolOrchestratorToolCtx
     $session
     $turn
     $call-id
     $tool-name))

(= (codex:tool-orchestrator-tool-ctx-call-id
      (CodexToolOrchestratorToolCtx
        $session
        $turn
        $call-id
        $tool-name))
   $call-id)

(= (codex:tool-orchestrator-tool-ctx-tool-name
      (CodexToolOrchestratorToolCtx
        $session
        $turn
        $call-id
        $tool-name))
   $tool-name)

(= (codex:sandbox-attempt
      $sandbox
      $policy
      $file-system-policy
      $network-policy
      $enforce-managed-network
      $manager
      $sandbox-cwd
      $codex-linux-sandbox-exe
      $use-legacy-landlock
      $windows-sandbox-level
      $windows-sandbox-private-desktop)
   (CodexSandboxAttempt
     $sandbox
     $policy
     $file-system-policy
     $network-policy
     $enforce-managed-network
     $manager
     $sandbox-cwd
     $codex-linux-sandbox-exe
     $use-legacy-landlock
     $windows-sandbox-level
     $windows-sandbox-private-desktop))

(= (codex:sandbox-attempt-sandbox
      (CodexSandboxAttempt
        $sandbox
        $policy
        $file-system-policy
        $network-policy
        $enforce-managed-network
        $manager
        $sandbox-cwd
        $codex-linux-sandbox-exe
        $use-legacy-landlock
        $windows-sandbox-level
        $windows-sandbox-private-desktop))
   $sandbox)

(= (codex:sandbox-attempt-codex-linux-sandbox-exe
      (CodexSandboxAttempt
        $sandbox
        $policy
        $file-system-policy
        $network-policy
        $enforce-managed-network
        $manager
        $sandbox-cwd
        $codex-linux-sandbox-exe
        $use-legacy-landlock
        $windows-sandbox-level
        $windows-sandbox-private-desktop))
   $codex-linux-sandbox-exe)

(= (codex:orchestrator-run-result $output $deferred-network-approval)
   (CodexOrchestratorRunResult $output $deferred-network-approval))

(= (codex:tool-error-rejected $message)
   (CodexToolErrorRejected $message))

(= (codex:tool-error-sandbox-denied
      $output
      $network-policy-decision)
   (CodexToolErrorSandboxDenied
     $output
     $network-policy-decision))

(= (codex:tool-error-other $debug)
   (CodexToolErrorOther $debug))

(= (codex:tool-orchestrator-attempt-ok
      $output
      $deferred-network-approval)
   (CodexToolOrchestratorAttemptOk
     $output
     $deferred-network-approval))

(= (codex:tool-orchestrator-attempt-err $tool-error)
   (CodexToolOrchestratorAttemptErr $tool-error))

(= (codex:tool-orchestrator-run-ok $result)
   (CodexToolOrchestratorRunOk $result))

(= (codex:tool-orchestrator-run-err $tool-error)
   (CodexToolOrchestratorRunErr $tool-error))

(= (codex:permission-request-hook-decision-none)
   (CodexPermissionRequestHookDecisionNone))

(= (codex:permission-request-hook-decision-allow)
   (CodexPermissionRequestHookDecisionAllow))

(= (codex:permission-request-hook-decision-deny $message)
   (CodexPermissionRequestHookDecisionDeny $message))

(= (codex:tool-orchestrator-approval-request-input
      $permission-request-payload
      $hook-decision
      $async-decision)
   (CodexToolOrchestratorApprovalRequestInput
     $permission-request-payload
     $hook-decision
     $async-decision))

(= (codex:tool-orchestrator-approval-request-ok $decision)
   (CodexToolOrchestratorApprovalRequestOk $decision))

(= (codex:tool-orchestrator-approval-request-err $tool-error)
   (CodexToolOrchestratorApprovalRequestErr $tool-error))

(= (codex:tool-orchestrator-run-inputs
      $initial-approval-input
      $retry-approval-input
      $first-attempt
      $retry-attempt
      $strict-guardian-review-id
      $approval-guardian-review-id
      $retry-guardian-review-id
      $guardian-rejection-message
      $guardian-timeout-message)
   (CodexToolOrchestratorRunInputs
     $initial-approval-input
     $retry-approval-input
     $first-attempt
     $retry-attempt
     $strict-guardian-review-id
     $approval-guardian-review-id
     $retry-guardian-review-id
     $guardian-rejection-message
     $guardian-timeout-message))

(= (codex:tool-orchestrator-run-inputs-initial-approval-input
      (CodexToolOrchestratorRunInputs
        $initial-approval-input
        $retry-approval-input
        $first-attempt
        $retry-attempt
        $strict-guardian-review-id
        $approval-guardian-review-id
        $retry-guardian-review-id
        $guardian-rejection-message
        $guardian-timeout-message))
   $initial-approval-input)

(= (codex:tool-orchestrator-run-inputs-retry-approval-input
      (CodexToolOrchestratorRunInputs
        $initial-approval-input
        $retry-approval-input
        $first-attempt
        $retry-attempt
        $strict-guardian-review-id
        $approval-guardian-review-id
        $retry-guardian-review-id
        $guardian-rejection-message
        $guardian-timeout-message))
   $retry-approval-input)

(= (codex:tool-orchestrator-run-inputs-first-attempt
      (CodexToolOrchestratorRunInputs
        $initial-approval-input
        $retry-approval-input
        $first-attempt
        $retry-attempt
        $strict-guardian-review-id
        $approval-guardian-review-id
        $retry-guardian-review-id
        $guardian-rejection-message
        $guardian-timeout-message))
   $first-attempt)

(= (codex:tool-orchestrator-run-inputs-retry-attempt
      (CodexToolOrchestratorRunInputs
        $initial-approval-input
        $retry-approval-input
        $first-attempt
        $retry-attempt
        $strict-guardian-review-id
        $approval-guardian-review-id
        $retry-guardian-review-id
        $guardian-rejection-message
        $guardian-timeout-message))
   $retry-attempt)

(= (codex:tool-orchestrator-run-inputs-strict-guardian-review-id
      (CodexToolOrchestratorRunInputs
        $initial-approval-input
        $retry-approval-input
        $first-attempt
        $retry-attempt
        $strict-guardian-review-id
        $approval-guardian-review-id
        $retry-guardian-review-id
        $guardian-rejection-message
        $guardian-timeout-message))
   $strict-guardian-review-id)

(= (codex:tool-orchestrator-run-inputs-approval-guardian-review-id
      (CodexToolOrchestratorRunInputs
        $initial-approval-input
        $retry-approval-input
        $first-attempt
        $retry-attempt
        $strict-guardian-review-id
        $approval-guardian-review-id
        $retry-guardian-review-id
        $guardian-rejection-message
        $guardian-timeout-message))
   $approval-guardian-review-id)

(= (codex:tool-orchestrator-run-inputs-retry-guardian-review-id
      (CodexToolOrchestratorRunInputs
        $initial-approval-input
        $retry-approval-input
        $first-attempt
        $retry-attempt
        $strict-guardian-review-id
        $approval-guardian-review-id
        $retry-guardian-review-id
        $guardian-rejection-message
        $guardian-timeout-message))
   $retry-guardian-review-id)

(= (codex:tool-orchestrator-run-inputs-guardian-rejection-message
      (CodexToolOrchestratorRunInputs
        $initial-approval-input
        $retry-approval-input
        $first-attempt
        $retry-attempt
        $strict-guardian-review-id
        $approval-guardian-review-id
        $retry-guardian-review-id
        $guardian-rejection-message
        $guardian-timeout-message))
   $guardian-rejection-message)

(= (codex:tool-orchestrator-run-inputs-guardian-timeout-message
      (CodexToolOrchestratorRunInputs
        $initial-approval-input
        $retry-approval-input
        $first-attempt
        $retry-attempt
        $strict-guardian-review-id
        $approval-guardian-review-id
        $retry-guardian-review-id
        $guardian-rejection-message
        $guardian-timeout-message))
   $guardian-timeout-message)

(= (codex:tool-orchestrator-use-guardian $turn-context)
   (or
     (codex:tool-orchestrator-turn-context-routes-approval-to-guardian
       $turn-context)
     (codex:tool-orchestrator-turn-context-strict-auto-review
       $turn-context)))

(= (codex:tool-orchestrator-guardian-review-id
      $use-guardian
      $review-id)
   (if $use-guardian $review-id CodexAbsent))

(= (codex:tool-orchestrator-effective-approval-requirement
      $tool-config
      $approval-policy
      $file-system-sandbox-policy)
   (let $tool-requirement
     (codex:tool-orchestrator-tool-config-exec-approval-requirement
       $tool-config)
     (if (== $tool-requirement CodexAbsent)
         (codex:default-exec-approval-requirement
           $approval-policy
           $file-system-sandbox-policy)
         $tool-requirement)))

(= (codex:tool-orchestrator-tool-wants-no-sandbox-approval
      $tool-config
      $approval-policy)
   (let $tool-result
     (codex:tool-orchestrator-tool-config-wants-no-sandbox-approval
       $tool-config)
     (if (== $tool-result CodexAbsent)
         (codex:approvable-wants-no-sandbox-approval $approval-policy)
         $tool-result)))

(= (codex:tool-orchestrator-tool-should-bypass-approval
      $tool-config
      $approval-policy
      $already-approved)
   (let $tool-result
     (codex:tool-orchestrator-tool-config-should-bypass-approval
       $tool-config)
     (if (== $tool-result CodexAbsent)
         (codex:approvable-should-bypass-approval
           $approval-policy
           $already-approved)
         $tool-result)))

(= (codex:tool-orchestrator-request-approval
      $evaluate-permission-request-hooks
      (CodexToolOrchestratorApprovalRequestInput
        $permission-request-payload
        (CodexPermissionRequestHookDecisionAllow)
        $async-decision))
   (if (and
         $evaluate-permission-request-hooks
         (not (== $permission-request-payload CodexAbsent)))
       (codex:tool-orchestrator-approval-request-ok
         (CodexReviewDecisionApproved))
       (codex:tool-orchestrator-approval-request-ok
         $async-decision)))

(= (codex:tool-orchestrator-request-approval
      $evaluate-permission-request-hooks
      (CodexToolOrchestratorApprovalRequestInput
        $permission-request-payload
        (CodexPermissionRequestHookDecisionDeny $message)
        $async-decision))
   (if (and
         $evaluate-permission-request-hooks
         (not (== $permission-request-payload CodexAbsent)))
       (codex:tool-orchestrator-approval-request-err
         (codex:tool-error-rejected $message))
       (codex:tool-orchestrator-approval-request-ok
         $async-decision)))

(= (codex:tool-orchestrator-request-approval
      $evaluate-permission-request-hooks
      (CodexToolOrchestratorApprovalRequestInput
        $permission-request-payload
        (CodexPermissionRequestHookDecisionNone)
        $async-decision))
   (codex:tool-orchestrator-approval-request-ok $async-decision))

(= (codex:tool-orchestrator-reject-if-not-approved
      $guardian-review-id
      (CodexReviewDecisionApproved)
      $guardian-rejection-message
      $guardian-timeout-message)
   (codex:tool-orchestrator-approval-request-ok
     (CodexReviewDecisionApproved)))

(= (codex:tool-orchestrator-reject-if-not-approved
      $guardian-review-id
      (CodexReviewDecisionApprovedExecpolicyAmendment $amendment)
      $guardian-rejection-message
      $guardian-timeout-message)
   (codex:tool-orchestrator-approval-request-ok
     (CodexReviewDecisionApprovedExecpolicyAmendment $amendment)))

(= (codex:tool-orchestrator-reject-if-not-approved
      $guardian-review-id
      (CodexReviewDecisionApprovedForSession)
      $guardian-rejection-message
      $guardian-timeout-message)
   (codex:tool-orchestrator-approval-request-ok
     (CodexReviewDecisionApprovedForSession)))

(= (codex:tool-orchestrator-reject-if-not-approved
      $guardian-review-id
      (CodexReviewDecisionNetworkPolicyAmendment
        (CodexNetworkPolicyAmendment
          (CodexNetworkPolicyRuleActionAllow)
          $host))
      $guardian-rejection-message
      $guardian-timeout-message)
   (codex:tool-orchestrator-approval-request-ok
     (CodexReviewDecisionNetworkPolicyAmendment
       (CodexNetworkPolicyAmendment
         (CodexNetworkPolicyRuleActionAllow)
         $host))))

(= (codex:tool-orchestrator-reject-if-not-approved
      $guardian-review-id
      (CodexReviewDecisionNetworkPolicyAmendment
        (CodexNetworkPolicyAmendment
          (CodexNetworkPolicyRuleActionDeny)
          $host))
      $guardian-rejection-message
      $guardian-timeout-message)
   (codex:tool-orchestrator-approval-request-err
     (codex:tool-error-rejected "rejected by user")))

(= (codex:tool-orchestrator-reject-if-not-approved
      $guardian-review-id
      (CodexReviewDecisionDenied)
      $guardian-rejection-message
      $guardian-timeout-message)
   (codex:tool-orchestrator-approval-request-err
     (codex:tool-error-rejected
       (if (== $guardian-review-id CodexAbsent)
           "rejected by user"
           $guardian-rejection-message))))

(= (codex:tool-orchestrator-reject-if-not-approved
      $guardian-review-id
      (CodexReviewDecisionAbort)
      $guardian-rejection-message
      $guardian-timeout-message)
   (codex:tool-orchestrator-approval-request-err
     (codex:tool-error-rejected
       (if (== $guardian-review-id CodexAbsent)
           "rejected by user"
           $guardian-rejection-message))))

(= (codex:tool-orchestrator-reject-if-not-approved
      $guardian-review-id
      (CodexReviewDecisionTimedOut)
      $guardian-rejection-message
      $guardian-timeout-message)
   (codex:tool-orchestrator-approval-request-err
     (codex:tool-error-rejected $guardian-timeout-message)))

(= (codex:tool-orchestrator-approval-check-result
      $guardian-review-id
      $decision
      $inputs)
   (codex:tool-orchestrator-reject-if-not-approved
     $guardian-review-id
     $decision
     (codex:tool-orchestrator-run-inputs-guardian-rejection-message
       $inputs)
     (codex:tool-orchestrator-run-inputs-guardian-timeout-message
       $inputs)))

(= (codex:tool-orchestrator-approval-stage-ok $already-approved)
   (CodexToolOrchestratorApprovalStageOk $already-approved))

(= (codex:tool-orchestrator-approval-stage-err $tool-error)
   (CodexToolOrchestratorApprovalStageErr $tool-error))

(= (codex:tool-orchestrator-approval-stage
      $tool-config
      $turn-context
      (CodexExecApprovalRequirementSkip $bypass-sandbox $amendment)
      $inputs)
   (if (codex:tool-orchestrator-turn-context-strict-auto-review
         $turn-context)
       (let $approval-outcome
         (codex:tool-orchestrator-request-approval
           False
           (codex:tool-orchestrator-run-inputs-initial-approval-input
             $inputs))
         (case $approval-outcome
           (((CodexToolOrchestratorApprovalRequestOk $decision)
             (case
               (codex:tool-orchestrator-approval-check-result
                 (codex:tool-orchestrator-run-inputs-strict-guardian-review-id
                   $inputs)
                 $decision
                 $inputs)
               (((CodexToolOrchestratorApprovalRequestOk $approved-decision)
                 (codex:tool-orchestrator-approval-stage-ok True))
                ((CodexToolOrchestratorApprovalRequestErr $tool-error)
                 (codex:tool-orchestrator-approval-stage-err
                   $tool-error)))))
            ((CodexToolOrchestratorApprovalRequestErr $tool-error)
             (codex:tool-orchestrator-approval-stage-err $tool-error)))))
       (codex:tool-orchestrator-approval-stage-ok False)))

(= (codex:tool-orchestrator-approval-stage
      $tool-config
      $turn-context
      (CodexExecApprovalRequirementForbidden $reason)
      $inputs)
   (codex:tool-orchestrator-approval-stage-err
     (codex:tool-error-rejected $reason)))

(= (codex:tool-orchestrator-approval-stage
      $tool-config
      $turn-context
      (CodexExecApprovalRequirementNeedsApproval $reason $amendment)
      $inputs)
   (let $guardian-review-id
     (codex:tool-orchestrator-guardian-review-id
       (codex:tool-orchestrator-use-guardian $turn-context)
       (codex:tool-orchestrator-run-inputs-approval-guardian-review-id
         $inputs))
     (let $approval-outcome
       (codex:tool-orchestrator-request-approval
         (not
           (codex:tool-orchestrator-turn-context-strict-auto-review
             $turn-context))
         (codex:tool-orchestrator-run-inputs-initial-approval-input
           $inputs))
       (case $approval-outcome
         (((CodexToolOrchestratorApprovalRequestOk $decision)
           (case
             (codex:tool-orchestrator-approval-check-result
               $guardian-review-id
               $decision
               $inputs)
             (((CodexToolOrchestratorApprovalRequestOk $approved-decision)
               (codex:tool-orchestrator-approval-stage-ok True))
              ((CodexToolOrchestratorApprovalRequestErr $tool-error)
               (codex:tool-orchestrator-approval-stage-err
                 $tool-error)))))
          ((CodexToolOrchestratorApprovalRequestErr $tool-error)
           (codex:tool-orchestrator-approval-stage-err $tool-error)))))))

(= (codex:tool-orchestrator-initial-sandbox
      (CodexToolOrchestrator $sandbox-manager)
      $tool-config
      $turn-context)
   (if (==
         (codex:tool-orchestrator-tool-config-sandbox-mode-for-first-attempt
           $tool-config)
         (codex:sandbox-override-bypass-sandbox-first-attempt))
       (codex:sandbox-type-none)
       (codex:sandbox-manager-select-initial
         $sandbox-manager
         (codex:tool-orchestrator-turn-context-file-system-sandbox-policy
           $turn-context)
         (codex:tool-orchestrator-turn-context-network-sandbox-policy
           $turn-context)
         (codex:tool-orchestrator-tool-config-sandbox-preference
           $tool-config)
         (codex:tool-orchestrator-turn-context-windows-sandbox-level
           $turn-context)
         (codex:tool-orchestrator-turn-context-managed-network-active
           $turn-context)
         (codex:tool-orchestrator-turn-context-host-platform
           $turn-context))))

(= (codex:tool-orchestrator-build-initial-attempt
      $orchestrator
      $tool-config
      $turn-context)
   (codex:sandbox-attempt
     (codex:tool-orchestrator-initial-sandbox
       $orchestrator
       $tool-config
       $turn-context)
     (codex:tool-orchestrator-turn-context-sandbox-policy
       $turn-context)
     (codex:tool-orchestrator-turn-context-file-system-sandbox-policy
       $turn-context)
     (codex:tool-orchestrator-turn-context-network-sandbox-policy
       $turn-context)
     (codex:tool-orchestrator-turn-context-managed-network-active
       $turn-context)
     (codex:tool-orchestrator-sandbox-manager $orchestrator)
     (codex:tool-orchestrator-turn-context-cwd $turn-context)
     (codex:tool-orchestrator-turn-context-codex-linux-sandbox-exe
       $turn-context)
     (codex:tool-orchestrator-turn-context-use-legacy-landlock
       $turn-context)
     (codex:tool-orchestrator-turn-context-windows-sandbox-level
       $turn-context)
     (codex:tool-orchestrator-turn-context-windows-sandbox-private-desktop
       $turn-context)))

(= (codex:tool-orchestrator-build-escalated-attempt
      $orchestrator
      $turn-context)
   (codex:sandbox-attempt
     (codex:sandbox-type-none)
     (codex:tool-orchestrator-turn-context-sandbox-policy
       $turn-context)
     (codex:tool-orchestrator-turn-context-file-system-sandbox-policy
       $turn-context)
     (codex:tool-orchestrator-turn-context-network-sandbox-policy
       $turn-context)
     (codex:tool-orchestrator-turn-context-managed-network-active
       $turn-context)
     (codex:tool-orchestrator-sandbox-manager $orchestrator)
     (codex:tool-orchestrator-turn-context-cwd $turn-context)
     CodexAbsent
     (codex:tool-orchestrator-turn-context-use-legacy-landlock
       $turn-context)
     (codex:tool-orchestrator-turn-context-windows-sandbox-level
       $turn-context)
     (codex:tool-orchestrator-turn-context-windows-sandbox-private-desktop
       $turn-context)))

(= (codex:tool-orchestrator-network-approval-context
      $managed-network-active
      $network-policy-decision)
   (if (or
         (not $managed-network-active)
         (== $network-policy-decision CodexAbsent))
       CodexAbsent
       (let $context
         (codex:network-approval-context-from-payload
           $network-policy-decision)
         (if (== $context Empty) CodexAbsent $context))))

(= (codex:tool-orchestrator-network-retry-reason
      (CodexNetworkApprovalContext $host $protocol))
   (str-concat
     (str-concat "Network access to \"" $host)
     "\" is blocked by policy."))

(= (codex:tool-orchestrator-build-denial-reason-from-output $output)
   "command failed; retry without sandbox?")

(= (codex:tool-orchestrator-retry-reason
      CodexAbsent
      $output)
   (codex:tool-orchestrator-build-denial-reason-from-output $output))

(= (codex:tool-orchestrator-retry-reason
      (CodexNetworkApprovalContext $host $protocol)
      $output)
   (codex:tool-orchestrator-network-retry-reason
     (CodexNetworkApprovalContext $host $protocol)))

(= (codex:tool-orchestrator-allow-on-request-network-prompt
      $approval-policy
      $file-system-sandbox-policy
      $network-approval-context)
   (if (and
         (not (== $network-approval-context CodexAbsent))
         (== $approval-policy (codex:ask-for-approval-on-request)))
       (==
         (codex:approval-requirement-type
           (codex:default-exec-approval-requirement
             $approval-policy
             $file-system-sandbox-policy))
         "needs_approval")
       False))

(= (codex:tool-orchestrator-return-original-sandbox-denial
      $output
      $network-policy-decision)
   (codex:tool-orchestrator-run-err
     (codex:tool-error-sandbox-denied
       $output
       $network-policy-decision)))

(= (codex:tool-orchestrator-finish-retry-attempt $retry-attempt)
   (case $retry-attempt
     (((CodexToolOrchestratorAttemptOk
         $output
         $deferred-network-approval)
       (codex:tool-orchestrator-run-ok
         (codex:orchestrator-run-result
           $output
           $deferred-network-approval)))
      ((CodexToolOrchestratorAttemptErr
         (CodexToolErrorRejected $message))
       (codex:tool-orchestrator-run-err
         (codex:tool-error-rejected $message)))
      ((CodexToolOrchestratorAttemptErr
         (CodexToolErrorSandboxDenied
           $output
           $network-policy-decision))
       (codex:tool-orchestrator-run-err
         (codex:tool-error-sandbox-denied
           $output
           $network-policy-decision)))
      ((CodexToolOrchestratorAttemptErr
         (CodexToolErrorOther $debug))
       (codex:tool-orchestrator-run-err
         (codex:tool-error-other $debug))))))

(= (codex:tool-orchestrator-handle-retry-approval
      $orchestrator
      $tool-config
      $turn-context
      $approval-policy
      $inputs
      $network-approval-context)
   (let $retry-approval-outcome
     (codex:tool-orchestrator-request-approval
       (not
         (codex:tool-orchestrator-turn-context-strict-auto-review
           $turn-context))
       (codex:tool-orchestrator-run-inputs-retry-approval-input
         $inputs))
     (case $retry-approval-outcome
       (((CodexToolOrchestratorApprovalRequestOk $decision)
         (let $guardian-review-id
           (codex:tool-orchestrator-guardian-review-id
             (codex:tool-orchestrator-use-guardian $turn-context)
             (codex:tool-orchestrator-run-inputs-retry-guardian-review-id
               $inputs))
           (case
             (codex:tool-orchestrator-approval-check-result
               $guardian-review-id
               $decision
               $inputs)
             (((CodexToolOrchestratorApprovalRequestOk $approved-decision)
               (codex:tool-orchestrator-finish-retry-attempt
                 (codex:tool-orchestrator-run-inputs-retry-attempt
                   $inputs)))
              ((CodexToolOrchestratorApprovalRequestErr $tool-error)
               (codex:tool-orchestrator-run-err $tool-error))))))
        ((CodexToolOrchestratorApprovalRequestErr $tool-error)
         (codex:tool-orchestrator-run-err $tool-error))))))

(= (codex:tool-orchestrator-handle-sandbox-denial
      $orchestrator
      $tool-config
      $turn-context
      $approval-policy
      $inputs
      $already-approved
      $output
      $network-policy-decision)
   (let $network-approval-context
     (codex:tool-orchestrator-network-approval-context
       (codex:tool-orchestrator-turn-context-managed-network-active
         $turn-context)
       $network-policy-decision)
     (if (and
           (not (== $network-policy-decision CodexAbsent))
           (== $network-approval-context CodexAbsent))
         (codex:tool-orchestrator-return-original-sandbox-denial
           $output
           $network-policy-decision)
         (if (not
               (codex:tool-orchestrator-tool-config-escalate-on-failure
                 $tool-config))
             (codex:tool-orchestrator-return-original-sandbox-denial
               $output
               $network-policy-decision)
             (if (and
                   (not
                     (codex:tool-orchestrator-tool-wants-no-sandbox-approval
                       $tool-config
                       $approval-policy))
                   (not
                     (codex:tool-orchestrator-allow-on-request-network-prompt
                       $approval-policy
                       (codex:tool-orchestrator-turn-context-file-system-sandbox-policy
                         $turn-context)
                       $network-approval-context)))
                 (codex:tool-orchestrator-return-original-sandbox-denial
                   $output
                   $network-policy-decision)
                 (let $bypass-retry-approval
                   (and
                     (not
                       (codex:tool-orchestrator-turn-context-strict-auto-review
                         $turn-context))
                     (and
                       (codex:tool-orchestrator-tool-should-bypass-approval
                         $tool-config
                         $approval-policy
                         $already-approved)
                       (== $network-approval-context CodexAbsent)))
                   (if $bypass-retry-approval
                       (codex:tool-orchestrator-finish-retry-attempt
                         (codex:tool-orchestrator-run-inputs-retry-attempt
                           $inputs))
                       (codex:tool-orchestrator-handle-retry-approval
                         $orchestrator
                         $tool-config
                         $turn-context
                         $approval-policy
                         $inputs
                         $network-approval-context))))))))

(= (codex:tool-orchestrator-run-after-approval
      $orchestrator
      $tool-config
      $turn-context
      $approval-policy
      $inputs
      $already-approved)
   (case (codex:tool-orchestrator-run-inputs-first-attempt $inputs)
     (((CodexToolOrchestratorAttemptOk
         $output
         $deferred-network-approval)
       (codex:tool-orchestrator-run-ok
         (codex:orchestrator-run-result
           $output
           $deferred-network-approval)))
      ((CodexToolOrchestratorAttemptErr
         (CodexToolErrorSandboxDenied
           $output
           $network-policy-decision))
       (codex:tool-orchestrator-handle-sandbox-denial
         $orchestrator
         $tool-config
         $turn-context
         $approval-policy
         $inputs
         $already-approved
         $output
         $network-policy-decision))
      ((CodexToolOrchestratorAttemptErr
         (CodexToolErrorRejected $message))
       (codex:tool-orchestrator-run-err
         (codex:tool-error-rejected $message)))
      ((CodexToolOrchestratorAttemptErr
         (CodexToolErrorOther $debug))
       (codex:tool-orchestrator-run-err
         (codex:tool-error-other $debug))))))

(= (codex:tool-orchestrator-run
      $orchestrator
      $tool-config
      $tool-ctx
      $turn-context
      $approval-policy
      $inputs)
   (let $requirement
     (codex:tool-orchestrator-effective-approval-requirement
       $tool-config
       $approval-policy
       (codex:tool-orchestrator-turn-context-file-system-sandbox-policy
         $turn-context))
     (case
       (codex:tool-orchestrator-approval-stage
         $tool-config
         $turn-context
         $requirement
         $inputs)
       (((CodexToolOrchestratorApprovalStageOk $already-approved)
         (codex:tool-orchestrator-run-after-approval
           $orchestrator
           $tool-config
           $turn-context
           $approval-policy
           $inputs
           $already-approved))
        ((CodexToolOrchestratorApprovalStageErr $tool-error)
         (codex:tool-orchestrator-run-err $tool-error))))))
