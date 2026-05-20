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

!(import! &self apply_patch)
!(import! &self approval)
!(import! &self json)
!(import! &self list)
!(import! &self permissions)
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
