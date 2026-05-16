; Visible apply_patch slice for the restarted Codex port.
;
; This ports the approval/execution split from:
; - openai-codex/codex-rs/core/src/apply_patch.rs
; - openai-codex/codex-rs/core/src/safety.rs
; - openai-codex/codex-rs/core/src/tools/handlers/apply_patch.rs
;
; Covered in this increment:
; - direct patch verification through the native dry-run patch surface
; - Rust-shaped `SafetyCheck` decisions
; - Rust-shaped `InternalApplyPatchInvocation` / runtime-invocation split
; - direct apply_patch execution for the current local-session assumptions
; - exec_command heredoc interception preparation for the tools slice
;
; Required slice-local deviations from Rust, documented for later audit:
; - Rust's runtime executes a parsed `ApplyPatchAction`. CeTTa's current patch
;   runtime still applies patch text, so the runtime invocation carries the
;   original verified patch text alongside the action. This is the minimum
;   extra payload needed until a parsed-action executor lands.
; - The full Rust `FileSystemSandboxPolicy` object is not available in CeTTa
;   yet. This slice models the write/read/blocked path checks as normalized
;   absolute-prefix roots, which is sufficient for the current restarted
;   safety cases.
; - The restarted tool surface does not yet expose turn/session approval
;   orchestration. Generic `NeedsApproval` invocations stay structured, while
;   the local runner only executes the auto-approved branch under the current
;   CLI assumptions.

!(import! &self approval)
!(import! &self json)
!(import! &self patch)
!(import! &self path)
!(import! &self str)
!(import! &self system)

(= (codex:patch-rejected-outside-project-reason)
   "writing outside of the project; rejected by user approval settings")

(= (codex:patch-rejected-read-only-reason)
   "writing is blocked by read-only sandbox; rejected by user approval settings")

(= (codex:patch-sandbox-danger-full-access)
   (CodexPatchSandboxPolicyDangerFullAccess))

(= (codex:patch-sandbox-external)
   (CodexPatchSandboxPolicyExternalSandbox))

(= (codex:patch-sandbox-workspace-write)
   (CodexPatchSandboxPolicyWorkspaceWrite))

(= (codex:patch-sandbox-read-only)
   (CodexPatchSandboxPolicyReadOnly))

(= (codex:patch-fs-policy $writable-roots $read-only-roots $blocked-roots)
   (CodexPatchFileSystemSandboxPolicy
     $writable-roots
     $read-only-roots
     $blocked-roots))

(= (codex:patch-fs-policy-unrestricted)
   (codex:patch-fs-policy ("/") () ()))

(= (codex:patch-fs-policy-workspace-write $cwd)
   (codex:patch-fs-policy ($cwd) () ()))

(= (codex:patch-fs-policy-writable-roots
      (CodexPatchFileSystemSandboxPolicy
        $writable-roots
        $read-only-roots
        $blocked-roots))
   $writable-roots)

(= (codex:patch-fs-policy-read-only-roots
      (CodexPatchFileSystemSandboxPolicy
        $writable-roots
        $read-only-roots
        $blocked-roots))
   $read-only-roots)

(= (codex:patch-fs-policy-blocked-roots
      (CodexPatchFileSystemSandboxPolicy
        $writable-roots
        $read-only-roots
        $blocked-roots))
   $blocked-roots)

(= (codex:patch-safety-auto-approve $sandbox-type $user-explicitly-approved)
   (CodexPatchSafetyCheckAutoApprove
     $sandbox-type
     $user-explicitly-approved))

(= (codex:patch-safety-ask-user)
   (CodexPatchSafetyCheckAskUser))

(= (codex:patch-safety-reject $reason)
   (CodexPatchSafetyCheckReject $reason))

(= (codex:patch-safety-check-type
      (CodexPatchSafetyCheckAutoApprove $sandbox-type $user-explicitly-approved))
   "auto_approve")

(= (codex:patch-safety-check-type (CodexPatchSafetyCheckAskUser))
   "ask_user")

(= (codex:patch-safety-check-type (CodexPatchSafetyCheckReject $reason))
   "reject")

(= (codex:patch-safety-check-reason (CodexPatchSafetyCheckReject $reason))
   $reason)

(= (codex:internal-apply-patch-invocation-type
      (CodexInternalApplyPatchOutput $text))
   "output")

(= (codex:internal-apply-patch-invocation-type
      (CodexInternalApplyPatchDelegateToRuntime $runtime))
   "delegate_to_runtime")

(= (codex:internal-apply-patch-output-text
      (CodexInternalApplyPatchOutput $text))
   $text)

(= (codex:internal-apply-patch-runtime
      (CodexInternalApplyPatchDelegateToRuntime $runtime))
   $runtime)

(= (codex:apply-patch-runtime-action
      (CodexApplyPatchRuntimeInvocation
        $action
        $patch-text
        $auto-approved
        $exec-approval-requirement))
   $action)

(= (codex:apply-patch-runtime-patch-text
      (CodexApplyPatchRuntimeInvocation
        $action
        $patch-text
        $auto-approved
        $exec-approval-requirement))
   $patch-text)

(= (codex:apply-patch-runtime-auto-approved
      (CodexApplyPatchRuntimeInvocation
        $action
        $patch-text
        $auto-approved
        $exec-approval-requirement))
   $auto-approved)

(= (codex:apply-patch-runtime-approval
      (CodexApplyPatchRuntimeInvocation
        $action
        $patch-text
        $auto-approved
        $exec-approval-requirement))
   $exec-approval-requirement)

(= (codex:apply-patch-action-cwd (CodexApplyPatchAction $cwd $changes))
   $cwd)

(= (codex:apply-patch-action-changes (CodexApplyPatchAction $cwd $changes))
   $changes)

(= (codex:apply-patch-change-path
      (CodexApplyPatchFileChangeAdd $path $content))
   $path)

(= (codex:apply-patch-change-path
      (CodexApplyPatchFileChangeDelete $path $content))
   $path)

(= (codex:apply-patch-change-path
      (CodexApplyPatchFileChangeUpdate $path $unified-diff $move-path $new-content))
   $path)

(= (codex:apply-patch-change-type
      (CodexApplyPatchFileChangeAdd $path $content))
   "add")

(= (codex:apply-patch-change-type
      (CodexApplyPatchFileChangeDelete $path $content))
   "delete")

(= (codex:apply-patch-change-type
      (CodexApplyPatchFileChangeUpdate $path $unified-diff $move-path $new-content))
   "update")

(= (codex:apply-patch-change-move-path
      (CodexApplyPatchFileChangeUpdate $path $unified-diff $move-path $new-content))
   $move-path)

(= (codex:apply-patch-change-has-move-path
      (CodexApplyPatchFileChangeUpdate $path $unified-diff $move-path $new-content))
   (if (== $move-path CodexAbsent)
       False
       True))

(= (codex:maybe-apply-patch-result-type
      (CodexMaybeApplyPatchBody $patch-text $action))
   "body")

(= (codex:maybe-apply-patch-result-type
      (CodexMaybeApplyPatchCorrectnessError $message))
   "correctness_error")

(= (codex:maybe-apply-patch-result-type
      (CodexMaybeApplyPatchNotApplyPatch))
   "not_apply_patch")

(= (codex:maybe-apply-patch-patch-text
      (CodexMaybeApplyPatchBody $patch-text $action))
   $patch-text)

(= (codex:maybe-apply-patch-action
      (CodexMaybeApplyPatchBody $patch-text $action))
   $action)

(= (codex:maybe-apply-patch-error
      (CodexMaybeApplyPatchCorrectnessError $message))
   $message)

(= (codex:apply-patch-intercept-result-type
      (CodexApplyPatchInterceptNotMatched))
   "not_matched")

(= (codex:apply-patch-intercept-result-type
      (CodexApplyPatchInterceptMatched $text))
   "matched")

(= (codex:apply-patch-intercept-text
      (CodexApplyPatchInterceptMatched $text))
   $text)

(= (codex:apply-patch-json-object-required-string $object $key)
   (json-string-value (json-object-get $object $key)))

(= (codex:decode-apply-patch-input $input)
   (let $trimmed (str-trim $input)
     (if (str-starts-with? $trimmed "*** Begin Patch")
         $trimmed
         (if (str-starts-with? $trimmed "{")
             (codex:apply-patch-json-object-required-string
               (json-parse $trimmed)
               "input")
             $trimmed))))

(= (codex:patch-change-to-codex
      (PatchActionAdd $path $content))
   (CodexApplyPatchFileChangeAdd $path $content))

(= (codex:patch-change-to-codex
      (PatchActionDelete $path $content))
   (CodexApplyPatchFileChangeDelete $path $content))

(= (codex:patch-change-to-codex
      (PatchActionUpdate $path $unified-diff $move-path $new-content))
   (CodexApplyPatchFileChangeUpdate
     $path
     $unified-diff
     (if (== $move-path PatchNoMove)
         CodexAbsent
         $move-path)
     $new-content))

(= (codex:patch-changes-to-codex ())
   ())

; CeTTa's evaluator may leave recursive list-builder arguments suspended inside
; cons-atom/outer constructors. Materialize the converted head/tail first so
; the visible PatchAction change list matches the Rust slice exactly.
(= (codex:patch-changes-to-codex $changes)
   (let ($head $tail) (decons-atom $changes)
     (let $converted-head
       (codex:patch-change-to-codex $head)
       (let $converted-tail
         (codex:patch-changes-to-codex $tail)
         (cons-atom
           $converted-head
           $converted-tail)))))

(= (codex:patch-action-to-codex-action (PatchAction $cwd $changes))
   (let $converted-changes
     (codex:patch-changes-to-codex $changes)
     (CodexApplyPatchAction $cwd $converted-changes)))

(= (codex:maybe-parse-apply-patch-input $cwd $input)
   (let $patch-text (codex:decode-apply-patch-input $input)
     (let $inspection (patch-inspect $cwd $patch-text)
       (if (patch-inspect-ok? $inspection)
           (CodexMaybeApplyPatchBody
             $patch-text
             (codex:patch-action-to-codex-action
               (patch-inspect-action $inspection)))
           (CodexMaybeApplyPatchCorrectnessError
             (patch-inspect-error $inspection))))))

(= (codex:maybe-parse-apply-patch-shell-command $cwd $command)
   (let $inspection (patch-inspect-shell-command $cwd $command)
     (if (patch-shell-inspect-matched? $inspection)
         (let $result (patch-shell-inspect-result $inspection)
           (if (patch-inspect-ok? $result)
               (CodexMaybeApplyPatchBody
                 (patch-shell-inspect-patch-text $inspection)
                 (codex:patch-action-to-codex-action
                   (patch-inspect-action $result)))
               (CodexMaybeApplyPatchCorrectnessError
                 (patch-inspect-error $result))))
         (CodexMaybeApplyPatchNotApplyPatch))))

(= (codex:is-approval-policy-unless-trusted $approval-policy)
   (== $approval-policy (codex:ask-for-approval-unless-trusted)))

(= (codex:is-approval-policy-on-failure $approval-policy)
   (== $approval-policy (codex:ask-for-approval-on-failure)))

(= (codex:is-approval-policy-never $approval-policy)
   (== $approval-policy (codex:ask-for-approval-never)))

(= (codex:is-rejects-sandbox-approval $approval-policy)
   (if (codex:is-approval-policy-never $approval-policy)
       True
       (case $approval-policy
         (((CodexAskForApprovalGranular False) True)
          ((CodexAskForApprovalGranular True) False)
          ((CodexAskForApprovalGranularConfig
             False
             $rules
             $skill-approval
             $request-permissions
             $mcp-elicitations)
           True)
          ((CodexAskForApprovalGranularConfig
             True
             $rules
             $skill-approval
             $request-permissions
             $mcp-elicitations)
           False)
          ($other False)))))

(= (codex:patch-sandbox-policy-rejection-reason
      (CodexPatchSandboxPolicyReadOnly))
   (codex:patch-rejected-read-only-reason))

(= (codex:patch-sandbox-policy-rejection-reason
      (CodexPatchSandboxPolicyWorkspaceWrite))
   (codex:patch-rejected-outside-project-reason))

(= (codex:patch-sandbox-policy-rejection-reason
      (CodexPatchSandboxPolicyDangerFullAccess))
   (codex:patch-rejected-outside-project-reason))

(= (codex:patch-sandbox-policy-rejection-reason
      (CodexPatchSandboxPolicyExternalSandbox))
   (codex:patch-rejected-outside-project-reason))

(= (codex:is-danger-or-external-patch-sandbox? $sandbox-policy)
   (if (== $sandbox-policy (codex:patch-sandbox-danger-full-access))
       True
       (if (== $sandbox-policy (codex:patch-sandbox-external))
           True
           False)))

; CeTTa's path builtins in this profile do not reduce reliably when given
; symbolic string values (for example list/accessor-derived paths). The current
; restarted apply_patch slice only needs already-normalized Unix-style absolute
; roots plus relative patch paths from patch-inspect, so use string-based path
; normalization here to preserve the Rust-visible behavior for that surface.
(= (codex:trim-trailing-slash-unless-root $text)
   (if (== $text "/")
       "/"
       (if (str-ends-with? $text "/")
           (codex:trim-trailing-slash-unless-root
             (str-slice $text 0 (- (str-length $text) 1)))
           $text)))

(= (codex:is-unix-absolute-path $path)
   (str-starts-with? $path "/"))

(= (codex:normalized-policy-path $cwd $path)
   (let $resolved-cwd $cwd
     (let $resolved-path $path
       (if (codex:is-unix-absolute-path $resolved-path)
           (codex:trim-trailing-slash-unless-root $resolved-path)
           (str-concat
             (str-concat
               (codex:trim-trailing-slash-unless-root $resolved-cwd)
               "/")
             $resolved-path)))))

(= (codex:is-path-within-root $path $root)
   (let $norm-path (codex:trim-trailing-slash-unless-root $path)
     (let $norm-root (codex:trim-trailing-slash-unless-root $root)
       (if (== $norm-root "/")
           True
           (if (== $norm-path $norm-root)
               True
               (str-starts-with?
                 $norm-path
                 (str-concat $norm-root "/")))))))

(= (codex:is-path-within-any-root $path $roots)
   (let $resolved-roots (eval $roots)
     (if (== $resolved-roots ())
         False
         (let $head (list:first $resolved-roots)
           (let $tail (list:rest $resolved-roots)
             (if (codex:is-path-within-root $path $head)
                 True
                 (case
                   (codex:is-path-within-any-root $path $tail)
                   ((True True)
                    (False False)))))))))

(= (codex:fs-policy-can-write-path-with-cwd
      $file-system-sandbox-policy
      $path
      $cwd)
   (let $writable-roots
     (codex:patch-fs-policy-writable-roots $file-system-sandbox-policy)
     (let $read-only-roots
       (codex:patch-fs-policy-read-only-roots $file-system-sandbox-policy)
       (let $blocked-roots
         (codex:patch-fs-policy-blocked-roots $file-system-sandbox-policy)
         (let $abs-path (codex:normalized-policy-path $cwd $path)
           (if (codex:is-path-within-any-root $abs-path $blocked-roots)
               False
               (if (codex:is-path-within-any-root $abs-path $read-only-roots)
                   False
                   (codex:is-path-within-any-root
                     $abs-path
                     $writable-roots))))))))

(= (codex:is-apply-patch-change-writable?
      $change
      $file-system-sandbox-policy
      $cwd)
   (let $change-type (codex:apply-patch-change-type $change)
     (let $path (codex:apply-patch-change-path $change)
       (if (== $change-type "update")
           (case
             (codex:fs-policy-can-write-path-with-cwd
               $file-system-sandbox-policy
               $path
               $cwd)
             ((True
               (case
                 (codex:apply-patch-change-has-move-path $change)
                 ((True
                   (case
                     (codex:fs-policy-can-write-path-with-cwd
                       $file-system-sandbox-policy
                       (codex:apply-patch-change-move-path $change)
                       $cwd)
                     ((True True)
                      (False False))))
                  (False True))))
              (False False)))
           (case
             (codex:fs-policy-can-write-path-with-cwd
               $file-system-sandbox-policy
               $path
               $cwd)
             ((True True)
              (False False)))))))

(= (codex:is-write-patch-constrained-to-writable-paths
      $action
      $file-system-sandbox-policy
      $cwd)
   (let $action-cwd (codex:apply-patch-action-cwd $action)
     (let $changes (codex:apply-patch-action-changes $action)
       (if (== $changes ())
           True
           (let $head (list:first $changes)
             (let $tail (list:rest $changes)
               (case
                 (codex:is-apply-patch-change-writable?
                   $head
                   $file-system-sandbox-policy
                   $cwd)
                 ((True
                   (case
                     (codex:is-write-patch-constrained-to-writable-paths
                       (CodexApplyPatchAction $action-cwd $tail)
                       $file-system-sandbox-policy
                       $cwd)
                     ((True True)
                      (False False))))
                  (False False)))))))))

(= (codex:is-apply-patch-action-empty? $action)
   (if (== (codex:apply-patch-action-changes $action) ())
       True
       False))

(= (codex:assess-patch-safety
      $action
      $approval-policy
      $sandbox-policy
      $file-system-sandbox-policy
      $cwd
      $has-platform-sandbox)
   (if (codex:is-apply-patch-action-empty? $action)
       (codex:patch-safety-reject "empty patch")
       (if (codex:is-approval-policy-unless-trusted $approval-policy)
           (codex:patch-safety-ask-user)
           (if (or
                 (codex:is-write-patch-constrained-to-writable-paths
                   $action
                   $file-system-sandbox-policy
                   $cwd)
                 (codex:is-approval-policy-on-failure $approval-policy))
               (if (codex:is-danger-or-external-patch-sandbox? $sandbox-policy)
                   (codex:patch-safety-auto-approve "none" False)
                   (if $has-platform-sandbox
                       (codex:patch-safety-auto-approve "platform" False)
                       (if (codex:is-rejects-sandbox-approval $approval-policy)
                           (codex:patch-safety-reject
                             (codex:patch-sandbox-policy-rejection-reason
                               $sandbox-policy))
                           (codex:patch-safety-ask-user))))
               (if (codex:is-rejects-sandbox-approval $approval-policy)
                   (codex:patch-safety-reject
                     (codex:patch-sandbox-policy-rejection-reason
                       $sandbox-policy))
                   (codex:patch-safety-ask-user))))))

(= (codex:apply-patch
      $approval-policy
      $sandbox-policy
      $file-system-sandbox-policy
      $patch-text
      $action
      $has-platform-sandbox)
   (case (codex:assess-patch-safety
           $action
           $approval-policy
           $sandbox-policy
           $file-system-sandbox-policy
           (codex:apply-patch-action-cwd $action)
           $has-platform-sandbox)
     (((CodexPatchSafetyCheckAutoApprove
         $sandbox-type
         $user-explicitly-approved)
       (CodexInternalApplyPatchDelegateToRuntime
         (CodexApplyPatchRuntimeInvocation
           $action
           $patch-text
           (not $user-explicitly-approved)
           (codex:approval-skip False))))
      ((CodexPatchSafetyCheckAskUser)
       (CodexInternalApplyPatchDelegateToRuntime
         (CodexApplyPatchRuntimeInvocation
           $action
           $patch-text
           False
           (codex:approval-needs-approval CodexAbsent))))
      ((CodexPatchSafetyCheckReject $reason)
       (CodexInternalApplyPatchOutput
         (str-concat "patch rejected: " $reason))))))

; Rust delegates `NeedsApproval` to the runtime/orchestrator. That slice is
; not present yet, so the visible executor only applies the already-approved
; branch and returns a deterministic placeholder for pending approval.
(= (codex:execute-apply-patch-runtime
      (CodexApplyPatchRuntimeInvocation
        $action
        $patch-text
        $auto-approved
        (CodexExecApprovalRequirementSkip $bypass-sandbox $amendment)))
   (let $result
     (patch-apply (codex:apply-patch-action-cwd $action) $patch-text)
     (if (patch-result-ok? $result)
         (patch-result-stdout $result)
         (patch-result-stderr $result))))

(= (codex:execute-apply-patch-runtime
      (CodexApplyPatchRuntimeInvocation
        $action
        $patch-text
        $auto-approved
        (CodexExecApprovalRequirementNeedsApproval $reason $amendment)))
   "apply_patch requires approval before execution")

(= (codex:local-apply-patch-approval-policy)
   (codex:ask-for-approval-never))

(= (codex:local-apply-patch-sandbox-policy)
   (codex:patch-sandbox-danger-full-access))

(= (codex:local-apply-patch-file-system-sandbox-policy)
   (codex:patch-fs-policy-unrestricted))

(= (codex:local-apply-patch-has-platform-sandbox)
   False)

(= (codex:apply-patch-local $patch-text $action)
   (codex:apply-patch
     (codex:local-apply-patch-approval-policy)
     (codex:local-apply-patch-sandbox-policy)
     (codex:local-apply-patch-file-system-sandbox-policy)
     $patch-text
     $action
     (codex:local-apply-patch-has-platform-sandbox)))

(= (codex:run-apply-patch-local $input)
   (case (codex:maybe-parse-apply-patch-input (system-cwd) $input)
     (((CodexMaybeApplyPatchBody $patch-text $action)
       (case (codex:apply-patch-local $patch-text $action)
         (((CodexInternalApplyPatchOutput $text) $text)
          ((CodexInternalApplyPatchDelegateToRuntime $runtime)
           (codex:execute-apply-patch-runtime $runtime)))))
      ((CodexMaybeApplyPatchCorrectnessError $message)
       (str-concat "apply_patch verification failed: " $message)))))

(= (codex:run-apply-patch-shell-command-local $cwd $command)
   (case (codex:maybe-parse-apply-patch-shell-command $cwd $command)
     (((CodexMaybeApplyPatchNotApplyPatch)
       (CodexApplyPatchInterceptNotMatched))
      ((CodexMaybeApplyPatchCorrectnessError $message)
       (CodexApplyPatchInterceptMatched
         (str-concat "apply_patch verification failed: " $message)))
      ((CodexMaybeApplyPatchBody $patch-text $action)
       (case (codex:apply-patch-local $patch-text $action)
         (((CodexInternalApplyPatchOutput $text)
           (CodexApplyPatchInterceptMatched $text))
          ((CodexInternalApplyPatchDelegateToRuntime $runtime)
           (CodexApplyPatchInterceptMatched
             (codex:execute-apply-patch-runtime $runtime)))))))))

(= (codex:patch-safety-check-json
      (CodexPatchSafetyCheckAutoApprove $sandbox-type $user-explicitly-approved))
   (JsonObject
     ((JsonPair "type" (JsonString "auto_approve"))
      (JsonPair "sandbox_type" (JsonString $sandbox-type))
      (JsonPair "user_explicitly_approved" (JsonBool $user-explicitly-approved)))))

(= (codex:patch-safety-check-json (CodexPatchSafetyCheckAskUser))
   (JsonObject
     ((JsonPair "type" (JsonString "ask_user")))))

(= (codex:patch-safety-check-json (CodexPatchSafetyCheckReject $reason))
   (JsonObject
     ((JsonPair "type" (JsonString "reject"))
      (JsonPair "reason" (JsonString $reason)))))

(= (codex:apply-patch-runtime-invocation-json
      (CodexApplyPatchRuntimeInvocation
        $action
        $patch-text
        $auto-approved
        $exec-approval-requirement))
   (JsonObject
     ((JsonPair "auto_approved" (JsonBool $auto-approved))
      (JsonPair "exec_approval_requirement"
        (codex:approval-requirement-json $exec-approval-requirement)))))

(= (codex:internal-apply-patch-invocation-json
      (CodexInternalApplyPatchOutput $text))
   (JsonObject
     ((JsonPair "type" (JsonString "output"))
      (JsonPair "text" (JsonString $text)))))

(= (codex:internal-apply-patch-invocation-json
      (CodexInternalApplyPatchDelegateToRuntime $runtime))
   (JsonObject
     ((JsonPair "type" (JsonString "delegate_to_runtime"))
      (JsonPair "runtime"
        (codex:apply-patch-runtime-invocation-json $runtime)))))
