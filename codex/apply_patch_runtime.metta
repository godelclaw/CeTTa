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
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust's `GuardianApprovalRequest::ApplyPatch` is a core-internal enum. This
;   pure CeTTa boundary models the same fields and exposes a JSON projection
;   matching Rust's guardian action serialization for surface tests.
; - Rust stores raw patch text on `ApplyPatchAction`. The restarted CeTTa
;   action carries parsed changes only, so the runtime request keeps patch text
;   beside the action until the parsed-action executor stores it directly.

!(import! &self apply_patch)
!(import! &self approval)
!(import! &self json)
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
