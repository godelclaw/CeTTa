; Rust-faithful pure tool-sandboxing helper slice.
;
; This ports deterministic helper shapes from:
; - openai-codex/codex-rs/core/src/tools/sandboxing.rs
;
; Covered in this increment:
; - `ApprovalCtx` data carried into runtime approval planning
; - `PermissionRequestPayload::bash`
; - `ExecApprovalRequirement::proposed_execpolicy_amendment`
; - default `Approvable` helper behavior
; - `SandboxOverride`
; - `sandbox_override_for_first_attempt`
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust stores borrowed `Session` and `TurnContext` Arcs in `ApprovalCtx`.
;   This pure CeTTa boundary carries those values opaquely until the async
;   session runtime is ported.
; - Rust's `PermissionRequestPayload` holds arbitrary serde JSON. The current
;   CeTTa helper materializes the Bash hook payload as the same JSON AST shape
;   used elsewhere in the restarted port.
; - Rust derives `Serialize` for several helper structs. This slice exposes
;   direct constructors, accessors, and narrow JSON projection only where tests
;   need to check the Rust wire shape.

!(import! &self approval)
!(import! &self json)
!(import! &self codex:hook_names)

(= (codex:approval-ctx
      $session
      $turn
      $call-id
      $guardian-review-id
      $retry-reason
      $network-approval-context)
   (CodexApprovalCtx
     $session
     $turn
     $call-id
     $guardian-review-id
     $retry-reason
     $network-approval-context))

(= (codex:approval-ctx-session
      (CodexApprovalCtx
        $session
        $turn
        $call-id
        $guardian-review-id
        $retry-reason
        $network-approval-context))
   $session)

(= (codex:approval-ctx-turn
      (CodexApprovalCtx
        $session
        $turn
        $call-id
        $guardian-review-id
        $retry-reason
        $network-approval-context))
   $turn)

(= (codex:approval-ctx-call-id
      (CodexApprovalCtx
        $session
        $turn
        $call-id
        $guardian-review-id
        $retry-reason
        $network-approval-context))
   $call-id)

(= (codex:approval-ctx-guardian-review-id
      (CodexApprovalCtx
        $session
        $turn
        $call-id
        $guardian-review-id
        $retry-reason
        $network-approval-context))
   $guardian-review-id)

(= (codex:approval-ctx-retry-reason
      (CodexApprovalCtx
        $session
        $turn
        $call-id
        $guardian-review-id
        $retry-reason
        $network-approval-context))
   $retry-reason)

(= (codex:approval-ctx-network-approval-context
      (CodexApprovalCtx
        $session
        $turn
        $call-id
        $guardian-review-id
        $retry-reason
        $network-approval-context))
   $network-approval-context)

(= (codex:sandboxable-preference-auto)
   (CodexSandboxablePreferenceAuto))

(= (codex:sandboxable-preference-require)
   (CodexSandboxablePreferenceRequire))

(= (codex:sandboxable-preference-forbid)
   (CodexSandboxablePreferenceForbid))

(= (codex:sandbox-override-no-override)
   (CodexSandboxOverrideNoOverride))

(= (codex:sandbox-override-bypass-sandbox-first-attempt)
   (CodexSandboxOverrideBypassSandboxFirstAttempt))

(= (codex:tool-sandboxing-hook-tool-name-bash)
   (codex:hook-tool-name-bash))

(= (codex:tool-sandboxing-hook-tool-name-apply-patch)
   (codex:hook-tool-name-apply-patch))

(= (codex:permission-request-payload $tool-name $tool-input)
   (CodexPermissionRequestPayload $tool-name $tool-input))

(= (codex:permission-request-payload-tool-name
      (CodexPermissionRequestPayload $tool-name $tool-input))
   $tool-name)

(= (codex:permission-request-payload-tool-input
      (CodexPermissionRequestPayload $tool-name $tool-input))
   $tool-input)

(= (codex:permission-request-payload-bash-input $command $description)
   (if (== $description CodexAbsent)
       (JsonObject
         ((JsonPair "command" (JsonString $command))))
       (JsonObject
         ((JsonPair "command" (JsonString $command))
          (JsonPair "description" (JsonString $description))))))

(= (codex:permission-request-payload-bash $command $description)
   (codex:permission-request-payload
     (codex:tool-sandboxing-hook-tool-name-bash)
     (codex:permission-request-payload-bash-input
       $command
       $description)))

(= (codex:permission-request-payload-apply-patch $patch-text)
   (codex:permission-request-payload
     (codex:tool-sandboxing-hook-tool-name-apply-patch)
     (JsonObject
       ((JsonPair "command" (JsonString $patch-text))))))

(= (codex:tool-sandboxing-hook-tool-name-json
      $hook-tool-name)
   (codex:hook-tool-name-json $hook-tool-name))

(= (codex:permission-request-payload-json
      (CodexPermissionRequestPayload $tool-name $tool-input))
   (JsonObject
     ((JsonPair "tool_name"
        (codex:tool-sandboxing-hook-tool-name-json $tool-name))
      (JsonPair "tool_input" $tool-input))))

(= (codex:exec-approval-requirement-proposed-execpolicy-amendment
      (CodexExecApprovalRequirementSkip $bypass-sandbox $amendment))
   $amendment)

(= (codex:exec-approval-requirement-proposed-execpolicy-amendment
      (CodexExecApprovalRequirementNeedsApproval $reason $amendment))
   $amendment)

(= (codex:exec-approval-requirement-proposed-execpolicy-amendment
      (CodexExecApprovalRequirementForbidden $reason))
   CodexAbsent)

(= (codex:tool-sandboxing-file-system-policy-restricted
      (CodexFileSystemSandboxPolicy
        (CodexFileSystemSandboxKindRestricted)
        $glob-scan-max-depth
        $entries))
   True)

(= (codex:tool-sandboxing-file-system-policy-restricted
      (CodexFileSystemSandboxPolicy
        (CodexFileSystemSandboxKindUnrestricted)
        $glob-scan-max-depth
        $entries))
   False)

(= (codex:tool-sandboxing-file-system-policy-restricted
      (CodexFileSystemSandboxPolicy
        (CodexFileSystemSandboxKindExternalSandbox)
        $glob-scan-max-depth
        $entries))
   False)

(= (codex:tool-sandboxing-approval-policy-granular-sandbox-approval
      $approval-policy)
   (case $approval-policy
     (((CodexAskForApprovalGranular $sandbox-approval)
       $sandbox-approval)
      ((CodexAskForApprovalGranularConfig
         $sandbox-approval
         $rules
         $skill-approval
         $request-permissions
         $mcp-elicitations)
       $sandbox-approval)
      ($other CodexAbsent))))

(= (codex:tool-sandboxing-needs-default-approval
      $approval-policy
      $file-system-sandbox-policy)
   (if (== $approval-policy (codex:ask-for-approval-never))
       False
       (if (== $approval-policy (codex:ask-for-approval-on-failure))
           False
           (if (== $approval-policy (codex:ask-for-approval-on-request))
               (codex:tool-sandboxing-file-system-policy-restricted
                 $file-system-sandbox-policy)
               (if (== $approval-policy
                       (codex:ask-for-approval-unless-trusted))
                   True
                   (if (== (codex:tool-sandboxing-approval-policy-granular-sandbox-approval
                             $approval-policy)
                           CodexAbsent)
                       False
                       (codex:tool-sandboxing-file-system-policy-restricted
                         $file-system-sandbox-policy)))))))

(= (codex:default-exec-approval-requirement
      $approval-policy
      $file-system-sandbox-policy)
   (let $needs-approval
     (codex:tool-sandboxing-needs-default-approval
       $approval-policy
       $file-system-sandbox-policy)
     (let $granular-sandbox-approval
       (codex:tool-sandboxing-approval-policy-granular-sandbox-approval
         $approval-policy)
       (if (and
             $needs-approval
             (== $granular-sandbox-approval False))
           (codex:approval-forbidden
             "approval policy disallowed sandbox approval prompt")
           (if $needs-approval
               (codex:approval-needs-approval CodexAbsent)
               (codex:approval-skip False))))))

(= (codex:approvable-should-bypass-approval
      $approval-policy
      $already-approved)
   (if $already-approved
       True
       (== $approval-policy (codex:ask-for-approval-never))))

(= (codex:approvable-wants-no-sandbox-approval
      $approval-policy)
   (if (== $approval-policy (codex:ask-for-approval-on-failure))
       True
       (if (== $approval-policy (codex:ask-for-approval-unless-trusted))
           True
           (if (== $approval-policy (codex:ask-for-approval-never))
               False
               (if (== $approval-policy (codex:ask-for-approval-on-request))
                   False
                   (let $granular-sandbox-approval
                     (codex:tool-sandboxing-approval-policy-granular-sandbox-approval
                       $approval-policy)
                     (if (== $granular-sandbox-approval CodexAbsent)
                         False
                         $granular-sandbox-approval)))))))

(= (codex:is-tool-sandboxing-sandbox-permissions-require-escalated
      $sandbox-permissions)
   (== $sandbox-permissions "require_escalated"))

(= (codex:exec-approval-requirement-bypass-sandbox
      (CodexExecApprovalRequirementSkip True $amendment))
   True)

(= (codex:exec-approval-requirement-bypass-sandbox
      (CodexExecApprovalRequirementSkip False $amendment))
   False)

(= (codex:exec-approval-requirement-bypass-sandbox
      (CodexExecApprovalRequirementNeedsApproval $reason $amendment))
   False)

(= (codex:exec-approval-requirement-bypass-sandbox
      (CodexExecApprovalRequirementForbidden $reason))
   False)

(= (codex:sandbox-override-for-first-attempt
      $sandbox-permissions
      $exec-approval-requirement)
   (if (or
         (codex:is-tool-sandboxing-sandbox-permissions-require-escalated
           $sandbox-permissions)
         (codex:exec-approval-requirement-bypass-sandbox
           $exec-approval-requirement))
       (codex:sandbox-override-bypass-sandbox-first-attempt)
       (codex:sandbox-override-no-override)))
