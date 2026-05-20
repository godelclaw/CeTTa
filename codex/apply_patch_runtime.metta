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
; - Rust's `AdditionalPermissionProfile` already stores canonical
;   `FileSystemPermissions` entries. The visible CeTTa request-permissions
;   surface currently stores the public legacy read/write root lists, so this
;   slice materializes those lists into the equivalent path entries at the
;   apply-patch runtime boundary before applying Rust's policy transform.
; - Rust `ToolRuntime::run` reads `ctx.turn.environment` and invokes the
;   environment filesystem asynchronously. This pure CeTTa runtime boundary
;   carries environment availability explicitly and uses the already-ported
;   local `patch-apply` primitive for the filesystem operation; the branch
;   ordering, output shaping, delta emission, and sandbox-denial classification
;   match the Rust helper. The sandbox-denial heuristic is kept local here to
;   avoid importing unrelated unified-exec constructor surfaces into protocol
;   tests; it is the same algorithm as Rust `exec::is_likely_sandbox_denied`.

!(import! &self apply_patch)
!(import! &self approval)
!(import! &self json)
!(import! &self list)
!(import! &self patch)
!(import! &self permissions)
!(import! &self protocol)
!(import! &self request_permissions)
!(import! &self str)
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

(= (codex:apply-patch-runtime-materialize-file-system-policy $policy)
   (case $policy
     (((CodexFileSystemSandboxPolicy $kind $glob-scan-max-depth $entries)
       (CodexFileSystemSandboxPolicy $kind $glob-scan-max-depth $entries))
      ($other
       (once (eval $other))))))

(= (codex:apply-patch-runtime-materialize-network-policy $policy)
   (case $policy
     (((CodexNetworkSandboxPolicyRestricted)
       (CodexNetworkSandboxPolicyRestricted))
      ((CodexNetworkSandboxPolicyEnabled)
       (CodexNetworkSandboxPolicyEnabled))
      ($other
       (once (eval $other))))))

(= (codex:apply-patch-runtime-materialize-sandbox-attempt $attempt)
   (case $attempt
     (((CodexSandboxAttempt
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
      ($other
       (once (eval $other))))))

(= (codex:apply-patch-runtime-attempt-sandbox
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

(= (codex:apply-patch-runtime-attempt-policy
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
   $policy)

(= (codex:apply-patch-runtime-attempt-file-system-policy
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
   $file-system-policy)

(= (codex:apply-patch-runtime-attempt-network-policy
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
   $network-policy)

(= (codex:apply-patch-runtime-attempt-sandbox-cwd
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
   $sandbox-cwd)

(= (codex:apply-patch-runtime-attempt-use-legacy-landlock
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
   $use-legacy-landlock)

(= (codex:apply-patch-runtime-attempt-windows-sandbox-level
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
   $windows-sandbox-level)

(= (codex:apply-patch-runtime-attempt-windows-sandbox-private-desktop
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
   $windows-sandbox-private-desktop)

(= (codex:apply-patch-runtime-sandbox-enforcement-managed)
   (CodexApplyPatchRuntimeSandboxEnforcementManaged))

(= (codex:apply-patch-runtime-sandbox-enforcement-disabled)
   (CodexApplyPatchRuntimeSandboxEnforcementDisabled))

(= (codex:apply-patch-runtime-sandbox-enforcement-external)
   (CodexApplyPatchRuntimeSandboxEnforcementExternal))

(= (codex:apply-patch-runtime-materialize-legacy-sandbox-policy $policy)
   (case $policy
     (((CodexSessionSandboxPolicyDangerFullAccess)
       (CodexSessionSandboxPolicyDangerFullAccess))
      ((CodexSessionSandboxPolicyExternalSandbox $network-access)
       (CodexSessionSandboxPolicyExternalSandbox $network-access))
      ((CodexSessionSandboxPolicyReadOnly $access $network-access)
       (CodexSessionSandboxPolicyReadOnly $access $network-access))
      ((CodexSessionSandboxPolicyWorkspaceWrite
         $writable-roots
         $read-only-access
         $network-access
         $exclude-tmpdir-env-var
         $exclude-slash-tmp)
       (CodexSessionSandboxPolicyWorkspaceWrite
         $writable-roots
         $read-only-access
         $network-access
         $exclude-tmpdir-env-var
         $exclude-slash-tmp))
      ($other
       (once (eval $other))))))

(= (codex:apply-patch-runtime-sandbox-enforcement-from-legacy-policy $policy)
   (let $resolved-policy
     (codex:apply-patch-runtime-materialize-legacy-sandbox-policy $policy)
     (case $resolved-policy
       (((CodexSessionSandboxPolicyDangerFullAccess)
         (CodexApplyPatchRuntimeSandboxEnforcementDisabled))
        ((CodexSessionSandboxPolicyExternalSandbox $network-access)
         (CodexApplyPatchRuntimeSandboxEnforcementExternal))
        ((CodexSessionSandboxPolicyReadOnly $access $network-access)
         (CodexApplyPatchRuntimeSandboxEnforcementManaged))
        ((CodexSessionSandboxPolicyWorkspaceWrite
           $writable-roots
           $read-only-access
           $network-access
           $exclude-tmpdir-env-var
           $exclude-slash-tmp)
         (CodexApplyPatchRuntimeSandboxEnforcementManaged))
        ($other
         (if (== $other "DangerFullAccess")
             (CodexApplyPatchRuntimeSandboxEnforcementDisabled)
             (if (== $other "ExternalSandbox")
                 (CodexApplyPatchRuntimeSandboxEnforcementExternal)
                 (CodexApplyPatchRuntimeSandboxEnforcementManaged))))))))

(= (codex:apply-patch-runtime-managed-file-system-permissions-restricted
      $entries
      $glob-scan-max-depth)
   (CodexApplyPatchRuntimeManagedFileSystemPermissionsRestricted
     $entries
     $glob-scan-max-depth))

(= (codex:apply-patch-runtime-managed-file-system-permissions-unrestricted)
   (CodexApplyPatchRuntimeManagedFileSystemPermissionsUnrestricted))

(= (codex:apply-patch-runtime-managed-file-system-permissions-from-sandbox-policy
      $file-system-policy)
   (let $policy
     (codex:apply-patch-runtime-materialize-file-system-policy
       $file-system-policy)
     (let $kind (codex:file-system-sandbox-policy-kind $policy)
       (if (== $kind (CodexFileSystemSandboxKindUnrestricted))
           (CodexApplyPatchRuntimeManagedFileSystemPermissionsUnrestricted)
           (CodexApplyPatchRuntimeManagedFileSystemPermissionsRestricted
             (codex:file-system-sandbox-policy-entries $policy)
             (codex:file-system-sandbox-policy-glob-scan-max-depth $policy))))))

(= (codex:apply-patch-runtime-permission-profile-managed
      $file-system
      $network)
   (CodexApplyPatchRuntimePermissionProfileManaged $file-system $network))

(= (codex:apply-patch-runtime-permission-profile-disabled)
   (CodexApplyPatchRuntimePermissionProfileDisabled))

(= (codex:apply-patch-runtime-permission-profile-external $network)
   (CodexApplyPatchRuntimePermissionProfileExternal $network))

(= (codex:apply-patch-runtime-permission-profile-from-runtime-permissions-with-enforcement
      $enforcement
      $file-system-policy
      $network-policy)
   (let $policy
     (codex:apply-patch-runtime-materialize-file-system-policy
       $file-system-policy)
     (let $network
       (codex:apply-patch-runtime-materialize-network-policy $network-policy)
       (let $kind (codex:file-system-sandbox-policy-kind $policy)
         (if (== $kind (CodexFileSystemSandboxKindExternalSandbox))
             (CodexApplyPatchRuntimePermissionProfileExternal $network)
             (if (and
                   (and
                     (== $kind (CodexFileSystemSandboxKindUnrestricted))
                     (== $enforcement
                         (CodexApplyPatchRuntimeSandboxEnforcementDisabled)))
                   (codex:network-sandbox-policy-is-enabled $network))
                 (CodexApplyPatchRuntimePermissionProfileDisabled)
                 (CodexApplyPatchRuntimePermissionProfileManaged
                   (codex:apply-patch-runtime-managed-file-system-permissions-from-sandbox-policy
                     $policy)
                   $network)))))))

(= (codex:apply-patch-runtime-permission-profile-from-runtime-permissions
      $file-system-policy
      $network-policy)
   (let $policy
     (codex:apply-patch-runtime-materialize-file-system-policy
       $file-system-policy)
     (let $kind (codex:file-system-sandbox-policy-kind $policy)
       (codex:apply-patch-runtime-permission-profile-from-runtime-permissions-with-enforcement
         (if (== $kind (CodexFileSystemSandboxKindExternalSandbox))
             (CodexApplyPatchRuntimeSandboxEnforcementExternal)
             (CodexApplyPatchRuntimeSandboxEnforcementManaged))
         $policy
         $network-policy))))

(= (codex:apply-patch-runtime-file-system-sandbox-context
      $permissions
      $cwd
      $windows-sandbox-level
      $windows-sandbox-private-desktop
      $use-legacy-landlock)
   (CodexApplyPatchRuntimeFileSystemSandboxContext
     $permissions
     $cwd
     $windows-sandbox-level
     $windows-sandbox-private-desktop
     $use-legacy-landlock))

(= (codex:apply-patch-runtime-file-system-sandbox-context-permissions
      (CodexApplyPatchRuntimeFileSystemSandboxContext
        $permissions
        $cwd
        $windows-sandbox-level
        $windows-sandbox-private-desktop
        $use-legacy-landlock))
   $permissions)

(= (codex:apply-patch-runtime-file-system-sandbox-context-cwd
      (CodexApplyPatchRuntimeFileSystemSandboxContext
        $permissions
        $cwd
        $windows-sandbox-level
        $windows-sandbox-private-desktop
        $use-legacy-landlock))
   $cwd)

(= (codex:apply-patch-runtime-file-system-sandbox-context-windows-sandbox-level
      (CodexApplyPatchRuntimeFileSystemSandboxContext
        $permissions
        $cwd
        $windows-sandbox-level
        $windows-sandbox-private-desktop
        $use-legacy-landlock))
   $windows-sandbox-level)

(= (codex:apply-patch-runtime-file-system-sandbox-context-windows-sandbox-private-desktop
      (CodexApplyPatchRuntimeFileSystemSandboxContext
        $permissions
        $cwd
        $windows-sandbox-level
        $windows-sandbox-private-desktop
        $use-legacy-landlock))
   $windows-sandbox-private-desktop)

(= (codex:apply-patch-runtime-file-system-sandbox-context-use-legacy-landlock
      (CodexApplyPatchRuntimeFileSystemSandboxContext
        $permissions
        $cwd
        $windows-sandbox-level
        $windows-sandbox-private-desktop
        $use-legacy-landlock))
   $use-legacy-landlock)

(= (codex:apply-patch-runtime-entry-list-contains $entry ())
   False)

(= (codex:apply-patch-runtime-entry-list-contains $entry $entries)
   (let ($head $tail) (decons-atom $entries)
     (if (== $entry $head)
         True
         (codex:apply-patch-runtime-entry-list-contains $entry $tail))))

(= (codex:apply-patch-runtime-append-unique-entry $entries $entry)
   (if (codex:apply-patch-runtime-entry-list-contains $entry $entries)
       $entries
       (list:append $entries ($entry))))

(= (codex:apply-patch-runtime-merge-additional-entries $entries ())
   $entries)

(= (codex:apply-patch-runtime-merge-additional-entries
      $entries
      $additional-entries)
   (let ($head $tail) (decons-atom $additional-entries)
     (codex:apply-patch-runtime-merge-additional-entries
       (codex:apply-patch-runtime-append-unique-entry $entries $head)
       $tail)))

(= (codex:apply-patch-runtime-permission-roots-to-entries
      ()
      $access)
   ())

(= (codex:apply-patch-runtime-permission-roots-to-entries
      $roots
      $access)
   (let ($head $tail) (decons-atom $roots)
     (cons-atom
       (CodexFileSystemSandboxEntry
         (CodexFileSystemPathPath $head)
         $access)
       (codex:apply-patch-runtime-permission-roots-to-entries
         $tail
         $access))))

(= (codex:apply-patch-runtime-additional-file-system-entries CodexAbsent)
   ())

(= (codex:apply-patch-runtime-additional-file-system-entries
      (CodexRequestPermissionsFileSystem $read $write))
   (list:append
     (codex:apply-patch-runtime-permission-roots-to-entries
       $read
       (CodexFileSystemAccessModeRead))
     (codex:apply-patch-runtime-permission-roots-to-entries
       $write
       (CodexFileSystemAccessModeWrite))))

(= (codex:apply-patch-runtime-additional-file-system-empty? CodexAbsent)
   True)

(= (codex:apply-patch-runtime-additional-file-system-empty?
      (CodexRequestPermissionsFileSystem $read $write))
   (and
     (== (list:len $read) 0)
     (== (list:len $write) 0)))

(= (codex:apply-patch-runtime-merge-file-system-policy-with-additional-permissions
      $file-system-policy
      $file-system-permissions)
   (let $policy
     (codex:apply-patch-runtime-materialize-file-system-policy
       $file-system-policy)
     (let $kind (codex:file-system-sandbox-policy-kind $policy)
       (if (== $kind (CodexFileSystemSandboxKindRestricted))
           (CodexFileSystemSandboxPolicy
             $kind
             (codex:file-system-sandbox-policy-glob-scan-max-depth $policy)
             (codex:apply-patch-runtime-merge-additional-entries
               (codex:file-system-sandbox-policy-entries $policy)
               (codex:apply-patch-runtime-additional-file-system-entries
                 $file-system-permissions)))
           $policy))))

(= (codex:apply-patch-runtime-effective-file-system-sandbox-policy
      $file-system-policy
      $additional-permissions)
   (case (codex:request-permissions-materialize $additional-permissions)
     ((CodexAbsent
       (codex:apply-patch-runtime-materialize-file-system-policy
         $file-system-policy))
      ((CodexRequestPermissionProfile $network $file-system)
       (if (codex:apply-patch-runtime-additional-file-system-empty?
             $file-system)
           (codex:apply-patch-runtime-materialize-file-system-policy
             $file-system-policy)
           (codex:apply-patch-runtime-merge-file-system-policy-with-additional-permissions
             $file-system-policy
             $file-system))))))

(= (codex:apply-patch-runtime-additional-network-enabled? CodexAbsent)
   False)

(= (codex:apply-patch-runtime-additional-network-enabled?
      (CodexRequestPermissionsNetwork True))
   True)

(= (codex:apply-patch-runtime-additional-network-enabled?
      (CodexRequestPermissionsNetwork False))
   False)

(= (codex:apply-patch-runtime-additional-network-enabled?
      (CodexRequestPermissionsNetwork CodexAbsent))
   False)

(= (codex:apply-patch-runtime-effective-network-sandbox-policy
      $network-policy
      $additional-permissions)
   (let $network
     (codex:apply-patch-runtime-materialize-network-policy $network-policy)
     (case (codex:request-permissions-materialize $additional-permissions)
       ((CodexAbsent
         $network)
        ((CodexRequestPermissionProfile $additional-network $file-system)
         (if (or
               (codex:network-sandbox-policy-is-enabled $network)
               (codex:apply-patch-runtime-additional-network-enabled?
                 $additional-network))
             (CodexNetworkSandboxPolicyEnabled)
             (CodexNetworkSandboxPolicyRestricted)))))))

(= (codex:apply-patch-runtime-file-system-sandbox-context-for-attempt
      $runtime
      $request
      $attempt)
   (let $req (codex:apply-patch-runtime-materialize-request $request)
     (let $resolved-attempt
       (codex:apply-patch-runtime-materialize-sandbox-attempt $attempt)
       (if (== (codex:apply-patch-runtime-attempt-sandbox $resolved-attempt)
               "None")
           CodexAbsent
           (let $file-system-policy
             (codex:apply-patch-runtime-effective-file-system-sandbox-policy
               (codex:apply-patch-runtime-attempt-file-system-policy
                 $resolved-attempt)
               (codex:apply-patch-runtime-request-additional-permissions
                 $req))
             (let $network-policy
               (codex:apply-patch-runtime-effective-network-sandbox-policy
                 (codex:apply-patch-runtime-attempt-network-policy
                   $resolved-attempt)
                 (codex:apply-patch-runtime-request-additional-permissions
                   $req))
               (CodexApplyPatchRuntimeFileSystemSandboxContext
                 (codex:apply-patch-runtime-permission-profile-from-runtime-permissions-with-enforcement
                   (codex:apply-patch-runtime-sandbox-enforcement-from-legacy-policy
                     (codex:apply-patch-runtime-attempt-policy
                       $resolved-attempt))
                   $file-system-policy
                   $network-policy)
                 (codex:apply-patch-runtime-attempt-sandbox-cwd
                   $resolved-attempt)
                 (codex:apply-patch-runtime-attempt-windows-sandbox-level
                   $resolved-attempt)
                 (codex:apply-patch-runtime-attempt-windows-sandbox-private-desktop
                   $resolved-attempt)
                 (codex:apply-patch-runtime-attempt-use-legacy-landlock
                   $resolved-attempt))))))))

(= (codex:apply-patch-runtime-run-context
      $call-id
      $host-platform
      $environment-available
      $duration)
   (CodexApplyPatchRuntimeRunContext
     $call-id
     $host-platform
     $environment-available
     $duration))

(= (codex:apply-patch-runtime-run-context-call-id
      (CodexApplyPatchRuntimeRunContext
        $call-id
        $host-platform
        $environment-available
        $duration))
   $call-id)

(= (codex:apply-patch-runtime-run-context-host-platform
      (CodexApplyPatchRuntimeRunContext
        $call-id
        $host-platform
        $environment-available
        $duration))
   $host-platform)

(= (codex:apply-patch-runtime-run-context-environment-available
      (CodexApplyPatchRuntimeRunContext
        $call-id
        $host-platform
        $environment-available
        $duration))
   $environment-available)

(= (codex:apply-patch-runtime-run-context-duration
      (CodexApplyPatchRuntimeRunContext
        $call-id
        $host-platform
        $environment-available
        $duration))
   $duration)

(= (codex:apply-patch-runtime-output-delta-event
      $call-id
      $stream
      $chunk)
   (if (== $chunk "")
       ()
       ((codex:exec-command-output-delta-event $call-id $stream $chunk))))

(= (codex:apply-patch-runtime-output-delta-events
      $call-id
      $stdout
      $stderr)
   (list:append
     (codex:apply-patch-runtime-output-delta-event
       $call-id
       "stdout"
       $stdout)
     (codex:apply-patch-runtime-output-delta-event
       $call-id
       "stderr"
       $stderr)))

(= (codex:apply-patch-runtime-exec-tool-call-output
      $exit-code
      $stdout
      $stderr
      $duration)
   (CodexApplyPatchRuntimeExecToolCallOutput
     $exit-code
     $stdout
     $stderr
     (str-concat $stdout $stderr)
     $duration
     False))

(= (codex:apply-patch-runtime-exec-tool-call-output-exit-code
      (CodexApplyPatchRuntimeExecToolCallOutput
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration
        $timed-out))
   $exit-code)

(= (codex:apply-patch-runtime-exec-tool-call-output-stdout
      (CodexApplyPatchRuntimeExecToolCallOutput
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration
        $timed-out))
   $stdout)

(= (codex:apply-patch-runtime-exec-tool-call-output-stderr
      (CodexApplyPatchRuntimeExecToolCallOutput
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration
        $timed-out))
   $stderr)

(= (codex:apply-patch-runtime-exec-tool-call-output-aggregated-output
      (CodexApplyPatchRuntimeExecToolCallOutput
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration
        $timed-out))
   $aggregated-output)

(= (codex:apply-patch-runtime-ascii-lower-char $char)
   (if (== $char "A")
       "a"
       (if (== $char "B")
           "b"
           (if (== $char "C")
               "c"
               (if (== $char "D")
                   "d"
                   (if (== $char "E")
                       "e"
                       (if (== $char "F")
                           "f"
                           (if (== $char "G")
                               "g"
                               (if (== $char "H")
                                   "h"
                                   (if (== $char "I")
                                       "i"
                                       (if (== $char "J")
                                           "j"
                                           (if (== $char "K")
                                               "k"
                                               (if (== $char "L")
                                                   "l"
                                                   (if (== $char "M")
                                                       "m"
                                                       (if (== $char "N")
                                                           "n"
                                                           (if (== $char "O")
                                                               "o"
                                                               (if (== $char "P")
                                                                   "p"
                                                                   (if (== $char "Q")
                                                                       "q"
                                                                       (if (== $char "R")
                                                                           "r"
                                                                           (if (== $char "S")
                                                                               "s"
                                                                               (if (== $char "T")
                                                                                   "t"
                                                                                   (if (== $char "U")
                                                                                       "u"
                                                                                       (if (== $char "V")
                                                                                           "v"
                                                                                           (if (== $char "W")
                                                                                               "w"
                                                                                               (if (== $char "X")
                                                                                                   "x"
                                                                                                   (if (== $char "Y")
                                                                                                       "y"
                                                                                                       (if (== $char "Z")
                                                                                                           "z"
                                                                                                           $char)))))))))))))))))))))))))))

(= (codex:apply-patch-runtime-ascii-lower $text)
   (codex:apply-patch-runtime-ascii-lower-from
     $text
     0
     ""))

(= (codex:apply-patch-runtime-ascii-lower-from
      $text
      $index
      $out)
   (if (>= $index (eval (str-length $text)))
       $out
       (let $char
         (eval (str-slice $text $index (+ $index 1)))
         (codex:apply-patch-runtime-ascii-lower-from
           $text
           (+ $index 1)
           (str-concat
             $out
             (codex:apply-patch-runtime-ascii-lower-char
               $char))))))

(= (codex:apply-patch-runtime-text-contains $text $needle)
   (> (list:len (eval (str-split $needle $text))) 1))

(= (codex:apply-patch-runtime-sandbox-denied-keywords)
   ("operation not permitted"
    "permission denied"
    "read-only file system"
    "seccomp"
    "sandbox"
    "landlock"
    "failed to write file"))

(= (codex:apply-patch-runtime-text-has-sandbox-keyword
      $text
      $keywords)
   (let $lower-results
     (collapse (codex:apply-patch-runtime-ascii-lower $text))
     (let $keyword-results (collapse $keywords)
       (codex:apply-patch-runtime-text-has-sandbox-keyword-resolved
         (list:first $lower-results)
         (list:first $keyword-results)))))

(= (codex:apply-patch-runtime-text-has-sandbox-keyword-resolved
      $lower
      ())
   False)

(= (codex:apply-patch-runtime-text-has-sandbox-keyword-resolved
      $lower
      $keywords)
   (let ($head $tail) (decons-atom $keywords)
     (if (codex:apply-patch-runtime-text-contains $lower $head)
         True
         (codex:apply-patch-runtime-text-has-sandbox-keyword-resolved
           $lower
           $tail))))

(= (codex:apply-patch-runtime-output-has-sandbox-keyword $output)
   (let $resolved-output (list:first (collapse $output))
     (let $keywords
       (codex:apply-patch-runtime-sandbox-denied-keywords)
       (case
         (collapse
           (codex:apply-patch-runtime-text-has-sandbox-keyword
             (codex:apply-patch-runtime-exec-tool-call-output-stderr
               $resolved-output)
             $keywords))
         (((True)
           True)
          ((False)
           (case
             (collapse
               (codex:apply-patch-runtime-text-has-sandbox-keyword
                 (codex:apply-patch-runtime-exec-tool-call-output-stdout
                   $resolved-output)
                 $keywords))
             (((True)
               True)
              ((False)
               (codex:apply-patch-runtime-text-has-sandbox-keyword
                 (codex:apply-patch-runtime-exec-tool-call-output-aggregated-output
                   $resolved-output)
                 $keywords))))))))))

(= (codex:apply-patch-runtime-quick-reject-exit-code $exit-code)
   (or
     (== $exit-code 2)
     (or
       (== $exit-code 126)
       (== $exit-code 127))))

(= (codex:apply-patch-runtime-linux-sigsys-exit-code)
   159)

(= (codex:apply-patch-runtime-is-likely-sandbox-denied
      $sandbox-type
      $output
      $host-platform)
   (let $resolved-output (list:first (collapse $output))
     (let $exit-code
       (codex:apply-patch-runtime-exec-tool-call-output-exit-code
         $resolved-output)
       (case
         (collapse
           (or
             (== $sandbox-type "None")
             (== $exit-code 0)))
         (((True)
           False)
          ((False)
           (case
             (collapse
               (codex:apply-patch-runtime-output-has-sandbox-keyword
                 $resolved-output))
             (((True)
               True)
              ((False)
               (case
                 (collapse
                   (codex:apply-patch-runtime-quick-reject-exit-code
                     $exit-code))
                 (((True)
                   False)
                  ((False)
                   (and
                     (== $host-platform "linux")
                     (and
                       (== $sandbox-type "LinuxSeccomp")
                       (== $exit-code
                           (codex:apply-patch-runtime-linux-sigsys-exit-code))))))))))))))))

(= (codex:apply-patch-runtime-run-ok $output $events)
   (CodexApplyPatchRuntimeRunOk $output $events))

(= (codex:apply-patch-runtime-run-err $error $events)
   (CodexApplyPatchRuntimeRunErr $error $events))

(= (codex:apply-patch-runtime-tool-error-rejected $message)
   (CodexApplyPatchRuntimeToolErrorRejected $message))

(= (codex:apply-patch-runtime-tool-error-sandbox-denied
      $output
      $network-policy-decision)
   (CodexApplyPatchRuntimeToolErrorSandboxDenied
     $output
     $network-policy-decision))

(= (codex:apply-patch-runtime-run-result-kind
      (CodexApplyPatchRuntimeRunOk $output $events))
   ok)

(= (codex:apply-patch-runtime-run-result-kind
      (CodexApplyPatchRuntimeRunErr $error $events))
   err)

(= (codex:apply-patch-runtime-run-result-output
      (CodexApplyPatchRuntimeRunOk $output $events))
   $output)

(= (codex:apply-patch-runtime-run-result-error
      (CodexApplyPatchRuntimeRunErr $error $events))
   $error)

(= (codex:apply-patch-runtime-run-result-events
      (CodexApplyPatchRuntimeRunOk $output $events))
   $events)

(= (codex:apply-patch-runtime-run-result-events
      (CodexApplyPatchRuntimeRunErr $error $events))
   $events)

(= (codex:apply-patch-runtime-tool-error-kind
      (CodexApplyPatchRuntimeToolErrorRejected $message))
   rejected)

(= (codex:apply-patch-runtime-tool-error-kind
      (CodexApplyPatchRuntimeToolErrorSandboxDenied
        $output
        $network-policy-decision))
   sandbox_denied)

(= (codex:apply-patch-runtime-tool-error-message
      (CodexApplyPatchRuntimeToolErrorRejected $message))
   $message)

(= (codex:apply-patch-runtime-tool-error-output
      (CodexApplyPatchRuntimeToolErrorSandboxDenied
        $output
        $network-policy-decision))
   $output)

(= (codex:apply-patch-runtime-tool-error-network-policy-decision
      (CodexApplyPatchRuntimeToolErrorSandboxDenied
        $output
        $network-policy-decision))
   $network-policy-decision)

(= (codex:apply-patch-runtime-finish-patch-result
      $sandbox-type
      $host-platform
      $call-id
      $duration
      $patch-result)
   (let $stdout (patch-result-stdout $patch-result)
     (let $stderr (patch-result-stderr $patch-result)
       (let $ok (patch-result-ok? $patch-result)
         (let $output
           (codex:apply-patch-runtime-exec-tool-call-output
             (if $ok 0 1)
             $stdout
             $stderr
             $duration)
           (let $events
             (codex:apply-patch-runtime-output-delta-events
               $call-id
               $stdout
               $stderr)
             (if (and
                   (not $ok)
                   (codex:apply-patch-runtime-is-likely-sandbox-denied
                     $sandbox-type
                     $output
                     $host-platform))
                 (CodexApplyPatchRuntimeRunErr
                   (CodexApplyPatchRuntimeToolErrorSandboxDenied
                     $output
                     CodexAbsent)
                   $events)
                 (CodexApplyPatchRuntimeRunOk $output $events))))))))

(= (codex:apply-patch-runtime-run
      $runtime
      $request
      $attempt
      $ctx)
   (let $resolved-ctx $ctx
     (if (not
           (codex:apply-patch-runtime-run-context-environment-available
             $resolved-ctx))
         (CodexApplyPatchRuntimeRunErr
           (CodexApplyPatchRuntimeToolErrorRejected
             "apply_patch is unavailable in this session")
           ())
         (let $req (codex:apply-patch-runtime-materialize-request $request)
           (let $resolved-attempt
             (codex:apply-patch-runtime-materialize-sandbox-attempt $attempt)
             (let $patch-result
               (patch-apply
                 (codex:apply-patch-action-cwd
                   (codex:apply-patch-runtime-request-action $req))
                 (codex:apply-patch-runtime-request-patch-text $req))
               (codex:apply-patch-runtime-finish-patch-result
                 (codex:apply-patch-runtime-attempt-sandbox
                   $resolved-attempt)
                 (codex:apply-patch-runtime-run-context-host-platform
                   $resolved-ctx)
                 (codex:apply-patch-runtime-run-context-call-id
                   $resolved-ctx)
                 (codex:apply-patch-runtime-run-context-duration
                   $resolved-ctx)
                 $patch-result)))))))
