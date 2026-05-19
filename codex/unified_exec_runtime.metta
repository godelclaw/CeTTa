; Rust-faithful pure unified-exec runtime policy slice.
;
; This ports deterministic behavior from:
; - openai-codex/codex-rs/core/src/tools/runtimes/unified_exec.rs
;
; Covered in this increment:
; - `UnifiedExecRuntime::new`
; - `Sandboxable` preference and escalation behavior
; - approval-cache key construction
; - start-approval branch planning for guardian vs cached user approval
; - exec approval requirement passthrough
; - permission request payload construction
; - first-attempt sandbox override selection
; - network approval spec construction
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust `start_approval_async` awaits guardian/user/session-service futures.
;   This CeTTa slice returns an explicit approval plan with the same data and
;   branch choice; the future async session boundary must consume that plan
;   rather than changing approval semantics.
; - Rust `ToolRuntime::run` executes sandbox transforms, optional zsh-fork
;   preparation, and process-manager startup. This slice intentionally stops
;   before `run`; the existing process-manager slices already model the later
;   process/session result boundaries.
; - Rust's `UnifiedExecRequest` struct already has concrete fields. This port
;   consumes the existing `CodexUnifiedExecToolRequest` constructor emitted by
;   `unified_exec_sandbox_session.metta` to avoid a duplicate request shape.
; - The local raw-constructor accessors below intentionally avoid importing
;   `unified_exec_sandbox_session.metta`: in current file-mode evaluation,
;   combining that larger boundary with command canonicalization suppresses
;   canonicalization results. The request/ctx constructor layout is unchanged.

!(import! &self command_canonicalization)
!(import! &self network_approval)
!(import! &self tool_sandboxing)

(= (codex:unified-exec-runtime-new $manager $shell-mode)
   (CodexUnifiedExecRuntime $manager $shell-mode))

(= (codex:unified-exec-runtime-manager
      (CodexUnifiedExecRuntime $manager $shell-mode))
   $manager)

(= (codex:unified-exec-runtime-shell-mode
      (CodexUnifiedExecRuntime $manager $shell-mode))
   $shell-mode)

(= (codex:unified-exec-runtime-materialize-request $request)
   (case $request
     (((CodexUnifiedExecToolRequest
         $command
         $hook-command
         $process-id
         $cwd
         $env
         $exec-server-env-config
         $explicit-env-overrides
         $network
         $tty
         $sandbox-permissions
         $additional-permissions
         $additional-permissions-preapproved
         $justification
         $exec-approval-requirement)
       (CodexUnifiedExecToolRequest
         $command
         $hook-command
         $process-id
         $cwd
         $env
         $exec-server-env-config
         $explicit-env-overrides
         $network
         $tty
         $sandbox-permissions
         $additional-permissions
         $additional-permissions-preapproved
         $justification
         $exec-approval-requirement))
      ($other
       (once (eval $other))))))

(= (codex:unified-exec-runtime-materialize-tool-ctx $ctx)
   (case $ctx
     (((CodexUnifiedExecToolCtx $session $turn $call-id $tool-name)
       (CodexUnifiedExecToolCtx $session $turn $call-id $tool-name))
      ($other
       (once (eval $other))))))

(= (codex:unified-exec-runtime-materialize-approval-ctx $ctx)
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

(= (codex:unified-exec-runtime-request-command
      (CodexUnifiedExecToolRequest
        $command
        $hook-command
        $process-id
        $cwd
        $env
        $exec-server-env-config
        $explicit-env-overrides
        $network
        $tty
        $sandbox-permissions
        $additional-permissions
        $additional-permissions-preapproved
        $justification
        $exec-approval-requirement))
   $command)

(= (codex:unified-exec-runtime-request-hook-command
      (CodexUnifiedExecToolRequest
        $command
        $hook-command
        $process-id
        $cwd
        $env
        $exec-server-env-config
        $explicit-env-overrides
        $network
        $tty
        $sandbox-permissions
        $additional-permissions
        $additional-permissions-preapproved
        $justification
        $exec-approval-requirement))
   $hook-command)

(= (codex:unified-exec-runtime-request-cwd
      (CodexUnifiedExecToolRequest
        $command
        $hook-command
        $process-id
        $cwd
        $env
        $exec-server-env-config
        $explicit-env-overrides
        $network
        $tty
        $sandbox-permissions
        $additional-permissions
        $additional-permissions-preapproved
        $justification
        $exec-approval-requirement))
   $cwd)

(= (codex:unified-exec-runtime-request-network
      (CodexUnifiedExecToolRequest
        $command
        $hook-command
        $process-id
        $cwd
        $env
        $exec-server-env-config
        $explicit-env-overrides
        $network
        $tty
        $sandbox-permissions
        $additional-permissions
        $additional-permissions-preapproved
        $justification
        $exec-approval-requirement))
   $network)

(= (codex:unified-exec-runtime-request-tty
      (CodexUnifiedExecToolRequest
        $command
        $hook-command
        $process-id
        $cwd
        $env
        $exec-server-env-config
        $explicit-env-overrides
        $network
        $tty
        $sandbox-permissions
        $additional-permissions
        $additional-permissions-preapproved
        $justification
        $exec-approval-requirement))
   $tty)

(= (codex:unified-exec-runtime-request-sandbox-permissions
      (CodexUnifiedExecToolRequest
        $command
        $hook-command
        $process-id
        $cwd
        $env
        $exec-server-env-config
        $explicit-env-overrides
        $network
        $tty
        $sandbox-permissions
        $additional-permissions
        $additional-permissions-preapproved
        $justification
        $exec-approval-requirement))
   $sandbox-permissions)

(= (codex:unified-exec-runtime-request-additional-permissions
      (CodexUnifiedExecToolRequest
        $command
        $hook-command
        $process-id
        $cwd
        $env
        $exec-server-env-config
        $explicit-env-overrides
        $network
        $tty
        $sandbox-permissions
        $additional-permissions
        $additional-permissions-preapproved
        $justification
        $exec-approval-requirement))
   $additional-permissions)

(= (codex:unified-exec-runtime-request-justification
      (CodexUnifiedExecToolRequest
        $command
        $hook-command
        $process-id
        $cwd
        $env
        $exec-server-env-config
        $explicit-env-overrides
        $network
        $tty
        $sandbox-permissions
        $additional-permissions
        $additional-permissions-preapproved
        $justification
        $exec-approval-requirement))
   $justification)

(= (codex:unified-exec-runtime-request-exec-approval-requirement
      (CodexUnifiedExecToolRequest
        $command
        $hook-command
        $process-id
        $cwd
        $env
        $exec-server-env-config
        $explicit-env-overrides
        $network
        $tty
        $sandbox-permissions
        $additional-permissions
        $additional-permissions-preapproved
        $justification
        $exec-approval-requirement))
   $exec-approval-requirement)

(= (codex:unified-exec-runtime-tool-ctx-call-id
      (CodexUnifiedExecToolCtx $session $turn $call-id $tool-name))
   $call-id)

(= (codex:unified-exec-runtime-tool-ctx-tool-name
      (CodexUnifiedExecToolCtx $session $turn $call-id $tool-name))
   $tool-name)

(= (codex:unified-exec-runtime-sandbox-preference $runtime)
   (codex:sandboxable-preference-auto))

(= (codex:unified-exec-runtime-escalate-on-failure $runtime)
   True)

(= (codex:unified-exec-approval-key
      $command
      $cwd
      $tty
      $sandbox-permissions
      $additional-permissions)
   (CodexUnifiedExecApprovalKey
     $command
     $cwd
     $tty
     $sandbox-permissions
     $additional-permissions))

(= (codex:unified-exec-approval-key-command
      (CodexUnifiedExecApprovalKey
        $command
        $cwd
        $tty
        $sandbox-permissions
        $additional-permissions))
   $command)

(= (codex:unified-exec-approval-key-cwd
      (CodexUnifiedExecApprovalKey
        $command
        $cwd
        $tty
        $sandbox-permissions
        $additional-permissions))
   $cwd)

(= (codex:unified-exec-approval-key-tty
      (CodexUnifiedExecApprovalKey
        $command
        $cwd
        $tty
        $sandbox-permissions
        $additional-permissions))
   $tty)

(= (codex:unified-exec-approval-key-sandbox-permissions
      (CodexUnifiedExecApprovalKey
        $command
        $cwd
        $tty
        $sandbox-permissions
        $additional-permissions))
   $sandbox-permissions)

(= (codex:unified-exec-approval-key-additional-permissions
      (CodexUnifiedExecApprovalKey
        $command
        $cwd
        $tty
        $sandbox-permissions
        $additional-permissions))
   $additional-permissions)

(= (codex:unified-exec-runtime-approval-keys $runtime $request)
   (let $req (codex:unified-exec-runtime-materialize-request $request)
     ((CodexUnifiedExecApprovalKey
        (once
          (eval
            (codex:canonicalize-command-for-approval
              (codex:unified-exec-runtime-request-command $req))))
        (codex:unified-exec-runtime-request-cwd $req)
        (codex:unified-exec-runtime-request-tty $req)
        (codex:unified-exec-runtime-request-sandbox-permissions $req)
        (codex:unified-exec-runtime-request-additional-permissions $req)))))

(= (codex:unified-exec-runtime-exec-approval-requirement
      $runtime
      $request)
   (let $req (codex:unified-exec-runtime-materialize-request $request)
     (codex:unified-exec-runtime-request-exec-approval-requirement $req)))

(= (codex:unified-exec-runtime-permission-request-payload
      $runtime
      $request)
   (let $req (codex:unified-exec-runtime-materialize-request $request)
     (codex:permission-request-payload-bash
       (codex:unified-exec-runtime-request-hook-command $req)
       (codex:unified-exec-runtime-request-justification $req))))

(= (codex:unified-exec-runtime-sandbox-mode-for-first-attempt
      $runtime
      $request)
   (let $req (codex:unified-exec-runtime-materialize-request $request)
     (codex:sandbox-override-for-first-attempt
       (codex:unified-exec-runtime-request-sandbox-permissions $req)
       (codex:unified-exec-runtime-request-exec-approval-requirement $req))))

(= (codex:guardian-approval-request-unified-exec-command
      $id
      $command
      $cwd
      $sandbox-permissions
      $additional-permissions
      $justification
      $tty)
   (CodexGuardianApprovalRequestUnifiedExecCommand
     $id
     $command
     $cwd
     $sandbox-permissions
     $additional-permissions
     $justification
     $tty))

(= (codex:unified-exec-runtime-approval-plan-guardian
      $session
      $turn
      $guardian-review-id
      $request
      $retry-reason)
   (CodexUnifiedExecRuntimeApprovalPlanGuardian
     $session
     $turn
     $guardian-review-id
     $request
     $retry-reason))

(= (codex:unified-exec-runtime-approval-plan-cached
      $tool-name
      $session
      $turn
      $call-id
      $keys
      $command
      $cwd
      $reason
      $network-approval-context
      $proposed-execpolicy-amendment
      $additional-permissions
      $available-decisions)
   (CodexUnifiedExecRuntimeApprovalPlanCached
     $tool-name
     $session
     $turn
     $call-id
     $keys
     $command
     $cwd
     $reason
     $network-approval-context
     $proposed-execpolicy-amendment
     $additional-permissions
     $available-decisions))

(= (codex:unified-exec-runtime-approval-plan-kind
      (CodexUnifiedExecRuntimeApprovalPlanGuardian
        $session
        $turn
        $guardian-review-id
        $request
        $retry-reason))
   guardian)

(= (codex:unified-exec-runtime-approval-plan-kind
      (CodexUnifiedExecRuntimeApprovalPlanCached
        $tool-name
        $session
        $turn
        $call-id
        $keys
        $command
        $cwd
        $reason
        $network-approval-context
        $proposed-execpolicy-amendment
        $additional-permissions
        $available-decisions))
   cached)

(= (codex:unified-exec-runtime-approval-plan-guardian-request
      (CodexUnifiedExecRuntimeApprovalPlanGuardian
        $session
        $turn
        $guardian-review-id
        $request
        $retry-reason))
   $request)

(= (codex:unified-exec-runtime-approval-plan-guardian-review-id
      (CodexUnifiedExecRuntimeApprovalPlanGuardian
        $session
        $turn
        $guardian-review-id
        $request
        $retry-reason))
   $guardian-review-id)

(= (codex:unified-exec-runtime-approval-plan-guardian-retry-reason
      (CodexUnifiedExecRuntimeApprovalPlanGuardian
        $session
        $turn
        $guardian-review-id
        $request
        $retry-reason))
   $retry-reason)

(= (codex:unified-exec-runtime-approval-plan-cached-tool-name
      (CodexUnifiedExecRuntimeApprovalPlanCached
        $tool-name
        $session
        $turn
        $call-id
        $keys
        $command
        $cwd
        $reason
        $network-approval-context
        $proposed-execpolicy-amendment
        $additional-permissions
        $available-decisions))
   $tool-name)

(= (codex:unified-exec-runtime-approval-plan-cached-keys
      (CodexUnifiedExecRuntimeApprovalPlanCached
        $tool-name
        $session
        $turn
        $call-id
        $keys
        $command
        $cwd
        $reason
        $network-approval-context
        $proposed-execpolicy-amendment
        $additional-permissions
        $available-decisions))
   $keys)

(= (codex:unified-exec-runtime-approval-plan-cached-reason
      (CodexUnifiedExecRuntimeApprovalPlanCached
        $tool-name
        $session
        $turn
        $call-id
        $keys
        $command
        $cwd
        $reason
        $network-approval-context
        $proposed-execpolicy-amendment
        $additional-permissions
        $available-decisions))
   $reason)

(= (codex:unified-exec-runtime-approval-plan-cached-proposed-execpolicy-amendment
      (CodexUnifiedExecRuntimeApprovalPlanCached
        $tool-name
        $session
        $turn
        $call-id
        $keys
        $command
        $cwd
        $reason
        $network-approval-context
        $proposed-execpolicy-amendment
        $additional-permissions
        $available-decisions))
   $proposed-execpolicy-amendment)

(= (codex:unified-exec-runtime-approval-plan-cached-network-approval-context
      (CodexUnifiedExecRuntimeApprovalPlanCached
        $tool-name
        $session
        $turn
        $call-id
        $keys
        $command
        $cwd
        $reason
        $network-approval-context
        $proposed-execpolicy-amendment
        $additional-permissions
        $available-decisions))
   $network-approval-context)

(= (codex:unified-exec-runtime-approval-plan-cached-available-decisions
      (CodexUnifiedExecRuntimeApprovalPlanCached
        $tool-name
        $session
        $turn
        $call-id
        $keys
        $command
        $cwd
        $reason
        $network-approval-context
        $proposed-execpolicy-amendment
        $additional-permissions
        $available-decisions))
   $available-decisions)

(= (codex:unified-exec-runtime-approval-reason
      $retry-reason
      $justification)
   (if (== $retry-reason CodexAbsent)
       $justification
       $retry-reason))

(= (codex:unified-exec-runtime-start-approval-plan
      $runtime
      $request
      $ctx)
   (let $req (codex:unified-exec-runtime-materialize-request $request)
     (let $approval-ctx
       (codex:unified-exec-runtime-materialize-approval-ctx $ctx)
       (let $guardian-review-id
         (codex:approval-ctx-guardian-review-id $approval-ctx)
     (if (== $guardian-review-id CodexAbsent)
         (codex:unified-exec-runtime-approval-plan-cached
           "unified_exec"
           (codex:approval-ctx-session $approval-ctx)
           (codex:approval-ctx-turn $approval-ctx)
           (codex:approval-ctx-call-id $approval-ctx)
           (codex:unified-exec-runtime-approval-keys $runtime $req)
           (codex:unified-exec-runtime-request-command $req)
           (codex:unified-exec-runtime-request-cwd $req)
           (codex:unified-exec-runtime-approval-reason
             (codex:approval-ctx-retry-reason $approval-ctx)
             (codex:unified-exec-runtime-request-justification $req))
           (codex:approval-ctx-network-approval-context $approval-ctx)
           (codex:exec-approval-requirement-proposed-execpolicy-amendment
             (codex:unified-exec-runtime-request-exec-approval-requirement
               $req))
           (codex:unified-exec-runtime-request-additional-permissions $req)
           CodexAbsent)
         (codex:unified-exec-runtime-approval-plan-guardian
           (codex:approval-ctx-session $approval-ctx)
           (codex:approval-ctx-turn $approval-ctx)
           $guardian-review-id
           (codex:guardian-approval-request-unified-exec-command
             (codex:approval-ctx-call-id $approval-ctx)
             (codex:unified-exec-runtime-request-command $req)
             (codex:unified-exec-runtime-request-cwd $req)
             (codex:unified-exec-runtime-request-sandbox-permissions $req)
             (codex:unified-exec-runtime-request-additional-permissions $req)
             (codex:unified-exec-runtime-request-justification $req)
             (codex:unified-exec-runtime-request-tty $req))
           (codex:approval-ctx-retry-reason $approval-ctx)))))))

(= (codex:unified-exec-runtime-network-approval-spec
      $runtime
      $request
      $ctx)
   (let $req (codex:unified-exec-runtime-materialize-request $request)
     (let $tool-ctx (codex:unified-exec-runtime-materialize-tool-ctx $ctx)
       (let $network (codex:unified-exec-runtime-request-network $req)
         (if (== $network CodexAbsent)
             CodexAbsent
             (codex:network-approval-spec
               $network
               (codex:network-approval-mode-deferred)
               (codex:guardian-network-access-trigger
                 (codex:unified-exec-runtime-tool-ctx-call-id $tool-ctx)
                 (codex:unified-exec-runtime-tool-ctx-tool-name $tool-ctx)
                 (codex:unified-exec-runtime-request-command $req)
                 (codex:unified-exec-runtime-request-cwd $req)
                 (codex:unified-exec-runtime-request-sandbox-permissions $req)
                 (codex:unified-exec-runtime-request-additional-permissions $req)
                 (codex:unified-exec-runtime-request-justification $req)
                 (codex:unified-exec-runtime-request-tty $req))
               (codex:unified-exec-runtime-request-hook-command $req)))))))
