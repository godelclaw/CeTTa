; Rust-faithful pure ApplyPatchRuntime helper slice.
;
; This ports deterministic helper behavior from:
; - openai-codex/codex-rs/core/src/tools/runtimes/apply_patch.rs
;
; Covered in this increment:
; - `ApplyPatchRuntime::new`
; - `Sandboxable` preference and escalation behavior
; - `Approvable` approval keys, approval requirement override, and
;   permission-request payload
; - apply-patch guardian review request construction
; - start-approval branch planning for guardian, preapproved, retry, and cached
;   user approvals
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust's `GuardianApprovalRequest::ApplyPatch` is a core-internal enum. This
;   pure CeTTa boundary models the same fields and exposes a JSON projection
;   matching Rust's guardian action serialization for surface tests.
; - Rust stores raw patch text on `ApplyPatchAction`. The restarted CeTTa
;   action carries parsed changes only, so the runtime request keeps patch text
;   beside the action until the parsed-action executor stores it directly.
; - Rust `start_approval_async` awaits guardian/user/session-service futures.
;   This CeTTa slice returns an explicit approval plan with the same data and
;   branch choice; the future async session boundary must consume that plan
;   rather than changing approval semantics.

!(import! &self apply_patch)
!(import! &self approval)
!(import! &self json)
!(import! &self protocol)
!(import! &self request_permissions)
!(import! &self tool_sandboxing)

(= (codex:apply-patch-runtime-new)
   (CodexApplyPatchRuntime))

(= (codex:apply-patch-runtime-materialize-request $request)
   (let $resolved-request (once (eval $request))
     (case $resolved-request
       (((CodexApplyPatchRuntimeRequest
            $action
            $patch-text
            $file-paths
            $changes
            $auto-approved
            $exec-approval-requirement
            $additional-permissions
            $permissions-preapproved)
         (CodexApplyPatchRuntimeRequest
           $action
           $patch-text
           $file-paths
           $changes
           $auto-approved
           $exec-approval-requirement
           $additional-permissions
           $permissions-preapproved))))))

(= (codex:apply-patch-runtime-materialize-approval-ctx $ctx)
   (case $ctx
     (((CodexApprovalCtx
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
      ($other
       (once (eval $other))))))

(= (codex:apply-patch-runtime-sandbox-preference $runtime)
   (codex:sandboxable-preference-auto))

(= (codex:apply-patch-runtime-escalate-on-failure $runtime)
   True)

(= (codex:apply-patch-runtime-approval-keys $runtime $request)
   (codex:apply-patch-runtime-request-file-paths
     (codex:apply-patch-runtime-materialize-request $request)))

(= (codex:apply-patch-runtime-exec-approval-requirement $runtime $request)
   (codex:apply-patch-runtime-request-approval
     (codex:apply-patch-runtime-materialize-request $request)))

(= (codex:apply-patch-runtime-wants-no-sandbox-approval
      $runtime
      $approval-policy)
   (if (== $approval-policy (codex:ask-for-approval-never))
       False
       (if (== $approval-policy (codex:ask-for-approval-on-failure))
           True
           (if (== $approval-policy (codex:ask-for-approval-on-request))
               True
               (if (== $approval-policy
                       (codex:ask-for-approval-unless-trusted))
                   True
                   (let $granular-sandbox-approval
                     (codex:tool-sandboxing-approval-policy-granular-sandbox-approval
                       $approval-policy)
                     (if (== $granular-sandbox-approval CodexAbsent)
                         False
                         $granular-sandbox-approval)))))))

(= (codex:apply-patch-runtime-permission-request-payload $runtime $request)
   (codex:permission-request-payload-apply-patch
     (codex:apply-patch-runtime-request-patch-text
       (codex:apply-patch-runtime-materialize-request $request))))

(= (codex:guardian-approval-request-apply-patch
      $id
      $cwd
      $files
      $patch)
   (CodexGuardianApprovalRequestApplyPatch $id $cwd $files $patch))

(= (codex:guardian-approval-request-apply-patch-id
      (CodexGuardianApprovalRequestApplyPatch $id $cwd $files $patch))
   $id)

(= (codex:guardian-approval-request-apply-patch-cwd
      (CodexGuardianApprovalRequestApplyPatch $id $cwd $files $patch))
   $cwd)

(= (codex:guardian-approval-request-apply-patch-files
      (CodexGuardianApprovalRequestApplyPatch $id $cwd $files $patch))
   $files)

(= (codex:guardian-approval-request-apply-patch-patch
      (CodexGuardianApprovalRequestApplyPatch $id $cwd $files $patch))
   $patch)

(= (codex:guardian-approval-request-apply-patch-json
      (CodexGuardianApprovalRequestApplyPatch $id $cwd $files $patch))
   (JsonObject
     ((JsonPair "tool" (JsonString "apply_patch"))
      (JsonPair "cwd" (JsonString $cwd))
      (JsonPair "files" (codex:request-permissions-string-array-json $files))
      (JsonPair "patch" (JsonString $patch)))))

(= (codex:apply-patch-runtime-build-guardian-review-request
      $runtime
      $request
      $call-id)
   (let $req (codex:apply-patch-runtime-materialize-request $request)
     (CodexGuardianApprovalRequestApplyPatch
       $call-id
       (codex:apply-patch-action-cwd
         (codex:apply-patch-runtime-request-action $req))
       (codex:apply-patch-runtime-request-file-paths $req)
       (codex:apply-patch-runtime-request-patch-text $req))))

(= (codex:apply-patch-runtime-approval-plan-guardian
      $session
      $turn
      $guardian-review-id
      $request
      $retry-reason)
   (CodexApplyPatchRuntimeApprovalPlanGuardian
     $session
     $turn
     $guardian-review-id
     $request
     $retry-reason))

(= (codex:apply-patch-runtime-approval-plan-preapproved $decision)
   (CodexApplyPatchRuntimeApprovalPlanPreapproved $decision))

(= (codex:apply-patch-runtime-approval-plan-direct-patch-approval
      $session
      $turn
      $call-id
      $changes
      $reason
      $grant-root)
   (CodexApplyPatchRuntimeApprovalPlanDirectPatchApproval
     $session
     $turn
     $call-id
     $changes
     $reason
     $grant-root))

(= (codex:apply-patch-runtime-approval-plan-cached
      $tool-name
      $session
      $turn
      $call-id
      $keys
      $changes
      $reason
      $grant-root)
   (CodexApplyPatchRuntimeApprovalPlanCached
     $tool-name
     $session
     $turn
     $call-id
     $keys
     $changes
     $reason
     $grant-root))

(= (codex:apply-patch-runtime-approval-plan-kind
      (CodexApplyPatchRuntimeApprovalPlanGuardian
        $session
        $turn
        $guardian-review-id
        $request
        $retry-reason))
   guardian)

(= (codex:apply-patch-runtime-approval-plan-kind
      (CodexApplyPatchRuntimeApprovalPlanPreapproved $decision))
   preapproved)

(= (codex:apply-patch-runtime-approval-plan-kind
      (CodexApplyPatchRuntimeApprovalPlanDirectPatchApproval
        $session
        $turn
        $call-id
        $changes
        $reason
        $grant-root))
   direct_patch_approval)

(= (codex:apply-patch-runtime-approval-plan-kind
      (CodexApplyPatchRuntimeApprovalPlanCached
        $tool-name
        $session
        $turn
        $call-id
        $keys
        $changes
        $reason
        $grant-root))
   cached)

(= (codex:apply-patch-runtime-approval-plan-guardian-review-id
      (CodexApplyPatchRuntimeApprovalPlanGuardian
        $session
        $turn
        $guardian-review-id
        $request
        $retry-reason))
   $guardian-review-id)

(= (codex:apply-patch-runtime-approval-plan-guardian-request
      (CodexApplyPatchRuntimeApprovalPlanGuardian
        $session
        $turn
        $guardian-review-id
        $request
        $retry-reason))
   $request)

(= (codex:apply-patch-runtime-approval-plan-guardian-retry-reason
      (CodexApplyPatchRuntimeApprovalPlanGuardian
        $session
        $turn
        $guardian-review-id
        $request
        $retry-reason))
   $retry-reason)

(= (codex:apply-patch-runtime-approval-plan-preapproved-decision
      (CodexApplyPatchRuntimeApprovalPlanPreapproved $decision))
   $decision)

(= (codex:apply-patch-runtime-approval-plan-direct-call-id
      (CodexApplyPatchRuntimeApprovalPlanDirectPatchApproval
        $session
        $turn
        $call-id
        $changes
        $reason
        $grant-root))
   $call-id)

(= (codex:apply-patch-runtime-approval-plan-direct-reason
      (CodexApplyPatchRuntimeApprovalPlanDirectPatchApproval
        $session
        $turn
        $call-id
        $changes
        $reason
        $grant-root))
   $reason)

(= (codex:apply-patch-runtime-approval-plan-direct-grant-root
      (CodexApplyPatchRuntimeApprovalPlanDirectPatchApproval
        $session
        $turn
        $call-id
        $changes
        $reason
        $grant-root))
   $grant-root)

(= (codex:apply-patch-runtime-approval-plan-cached-tool-name
      (CodexApplyPatchRuntimeApprovalPlanCached
        $tool-name
        $session
        $turn
        $call-id
        $keys
        $changes
        $reason
        $grant-root))
   $tool-name)

(= (codex:apply-patch-runtime-approval-plan-cached-keys
      (CodexApplyPatchRuntimeApprovalPlanCached
        $tool-name
        $session
        $turn
        $call-id
        $keys
        $changes
        $reason
        $grant-root))
   $keys)

(= (codex:apply-patch-runtime-approval-plan-cached-reason
      (CodexApplyPatchRuntimeApprovalPlanCached
        $tool-name
        $session
        $turn
        $call-id
        $keys
        $changes
        $reason
        $grant-root))
   $reason)

(= (codex:apply-patch-runtime-approval-plan-cached-grant-root
      (CodexApplyPatchRuntimeApprovalPlanCached
        $tool-name
        $session
        $turn
        $call-id
        $keys
        $changes
        $reason
        $grant-root))
   $grant-root)

(= (codex:apply-patch-runtime-start-approval-plan
      $runtime
      $request
      $ctx)
   (let $req (codex:apply-patch-runtime-materialize-request $request)
     (let $approval-ctx
       (codex:apply-patch-runtime-materialize-approval-ctx $ctx)
       (let $guardian-review-id
         (codex:approval-ctx-guardian-review-id $approval-ctx)
         (let $retry-reason
           (codex:approval-ctx-retry-reason $approval-ctx)
           (if (not (== $guardian-review-id CodexAbsent))
               (codex:apply-patch-runtime-approval-plan-guardian
                 (codex:approval-ctx-session $approval-ctx)
                 (codex:approval-ctx-turn $approval-ctx)
                 $guardian-review-id
                 (codex:apply-patch-runtime-build-guardian-review-request
                   $runtime
                   $req
                   (codex:approval-ctx-call-id $approval-ctx))
                 $retry-reason)
               (if (and
                     (codex:apply-patch-runtime-request-permissions-preapproved
                       $req)
                     (== $retry-reason CodexAbsent))
                   (codex:apply-patch-runtime-approval-plan-preapproved
                     (codex:review-decision-approved))
                   (if (not (== $retry-reason CodexAbsent))
                       (codex:apply-patch-runtime-approval-plan-direct-patch-approval
                         (codex:approval-ctx-session $approval-ctx)
                         (codex:approval-ctx-turn $approval-ctx)
                         (codex:approval-ctx-call-id $approval-ctx)
                         (codex:apply-patch-runtime-request-changes $req)
                         $retry-reason
                         CodexAbsent)
                       (codex:apply-patch-runtime-approval-plan-cached
                         "apply_patch"
                         (codex:approval-ctx-session $approval-ctx)
                         (codex:approval-ctx-turn $approval-ctx)
                         (codex:approval-ctx-call-id $approval-ctx)
                         (codex:apply-patch-runtime-approval-keys
                           $runtime
                           $req)
                         (codex:apply-patch-runtime-request-changes $req)
                         CodexAbsent
                         CodexAbsent)))))))))
