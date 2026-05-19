; Rust-faithful pure unified-exec sandbox session/orchestrator boundary slice.
;
; This ports deterministic data construction and error mapping from:
; - openai-codex/codex-rs/core/src/unified_exec/process_manager.rs
;   - UnifiedExecProcessManager::open_session_with_sandbox
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust reads `Session`, `TurnContext`, shell-environment policy, exec policy,
;   and tool config from Arc-backed runtime objects. The existing CeTTa
;   `UnifiedExecContext` keeps session and turn opaque, so this pure boundary
;   receives the exact materialized projections that Rust reads from them.
; - Rust constructs `ToolOrchestrator` and `UnifiedExecRuntime`, then awaits
;   `orchestrator.run`. This slice receives the observed orchestrator result
;   explicitly and records the runtime shell mode, preserving the branch and
;   request materialization while leaving side effects to later runtime code.
; - Rust's `#[cfg(unix)] additional_permissions_preapproved` field is carried
;   explicitly. CeTTa currently targets the Unix behavior used by the local
;   Codex process runtime.
; - Rust uses `output.aggregated_output.text`; the existing CeTTa process
;   runtime slice stores that Rust text field directly as `aggregated_output`.

!(import! &self approval)
!(import! &self unified_exec_core)
!(import! &self unified_exec_env)
!(import! &self unified_exec_process_runtime)
!(import! &self unified_exec_state)

(= (codex:unified-exec-open-session-sandbox-inputs
      $local-policy-env
      $exec-env-policy
      $explicit-env-overrides
      $conversation-id
      $approval-policy
      $sandbox-policy
      $file-system-sandbox-policy
      $exec-approval-requirement
      $orchestrator-result
      $runtime-shell-mode)
   (CodexUnifiedExecOpenSessionSandboxInputs
     $local-policy-env
     $exec-env-policy
     $explicit-env-overrides
     $conversation-id
     $approval-policy
     $sandbox-policy
     $file-system-sandbox-policy
     $exec-approval-requirement
     $orchestrator-result
     $runtime-shell-mode))

(= (codex:unified-exec-open-session-sandbox-inputs-local-policy-env
      (CodexUnifiedExecOpenSessionSandboxInputs
        $local-policy-env
        $exec-env-policy
        $explicit-env-overrides
        $conversation-id
        $approval-policy
        $sandbox-policy
        $file-system-sandbox-policy
        $exec-approval-requirement
        $orchestrator-result
        $runtime-shell-mode))
   $local-policy-env)

(= (codex:unified-exec-open-session-sandbox-inputs-exec-env-policy
      (CodexUnifiedExecOpenSessionSandboxInputs
        $local-policy-env
        $exec-env-policy
        $explicit-env-overrides
        $conversation-id
        $approval-policy
        $sandbox-policy
        $file-system-sandbox-policy
        $exec-approval-requirement
        $orchestrator-result
        $runtime-shell-mode))
   $exec-env-policy)

(= (codex:unified-exec-open-session-sandbox-inputs-explicit-env-overrides
      (CodexUnifiedExecOpenSessionSandboxInputs
        $local-policy-env
        $exec-env-policy
        $explicit-env-overrides
        $conversation-id
        $approval-policy
        $sandbox-policy
        $file-system-sandbox-policy
        $exec-approval-requirement
        $orchestrator-result
        $runtime-shell-mode))
   $explicit-env-overrides)

(= (codex:unified-exec-open-session-sandbox-inputs-conversation-id
      (CodexUnifiedExecOpenSessionSandboxInputs
        $local-policy-env
        $exec-env-policy
        $explicit-env-overrides
        $conversation-id
        $approval-policy
        $sandbox-policy
        $file-system-sandbox-policy
        $exec-approval-requirement
        $orchestrator-result
        $runtime-shell-mode))
   $conversation-id)

(= (codex:unified-exec-open-session-sandbox-inputs-approval-policy
      (CodexUnifiedExecOpenSessionSandboxInputs
        $local-policy-env
        $exec-env-policy
        $explicit-env-overrides
        $conversation-id
        $approval-policy
        $sandbox-policy
        $file-system-sandbox-policy
        $exec-approval-requirement
        $orchestrator-result
        $runtime-shell-mode))
   $approval-policy)

(= (codex:unified-exec-open-session-sandbox-inputs-sandbox-policy
      (CodexUnifiedExecOpenSessionSandboxInputs
        $local-policy-env
        $exec-env-policy
        $explicit-env-overrides
        $conversation-id
        $approval-policy
        $sandbox-policy
        $file-system-sandbox-policy
        $exec-approval-requirement
        $orchestrator-result
        $runtime-shell-mode))
   $sandbox-policy)

(= (codex:unified-exec-open-session-sandbox-inputs-file-system-sandbox-policy
      (CodexUnifiedExecOpenSessionSandboxInputs
        $local-policy-env
        $exec-env-policy
        $explicit-env-overrides
        $conversation-id
        $approval-policy
        $sandbox-policy
        $file-system-sandbox-policy
        $exec-approval-requirement
        $orchestrator-result
        $runtime-shell-mode))
   $file-system-sandbox-policy)

(= (codex:unified-exec-open-session-sandbox-inputs-exec-approval-requirement
      (CodexUnifiedExecOpenSessionSandboxInputs
        $local-policy-env
        $exec-env-policy
        $explicit-env-overrides
        $conversation-id
        $approval-policy
        $sandbox-policy
        $file-system-sandbox-policy
        $exec-approval-requirement
        $orchestrator-result
        $runtime-shell-mode))
   $exec-approval-requirement)

(= (codex:unified-exec-open-session-sandbox-inputs-orchestrator-result
      (CodexUnifiedExecOpenSessionSandboxInputs
        $local-policy-env
        $exec-env-policy
        $explicit-env-overrides
        $conversation-id
        $approval-policy
        $sandbox-policy
        $file-system-sandbox-policy
        $exec-approval-requirement
        $orchestrator-result
        $runtime-shell-mode))
   $orchestrator-result)

(= (codex:unified-exec-open-session-sandbox-inputs-runtime-shell-mode
      (CodexUnifiedExecOpenSessionSandboxInputs
        $local-policy-env
        $exec-env-policy
        $explicit-env-overrides
        $conversation-id
        $approval-policy
        $sandbox-policy
        $file-system-sandbox-policy
        $exec-approval-requirement
        $orchestrator-result
        $runtime-shell-mode))
   $runtime-shell-mode)

(= (codex:unified-exec-exec-approval-request
      $command
      $approval-policy
      $sandbox-policy
      $file-system-sandbox-policy
      $sandbox-permissions
      $prefix-rule)
   (CodexUnifiedExecExecApprovalRequest
     $command
     $approval-policy
     $sandbox-policy
     $file-system-sandbox-policy
     $sandbox-permissions
     $prefix-rule))

(= (codex:unified-exec-exec-approval-request-command
      (CodexUnifiedExecExecApprovalRequest
        $command
        $approval-policy
        $sandbox-policy
        $file-system-sandbox-policy
        $sandbox-permissions
        $prefix-rule))
   $command)

(= (codex:unified-exec-exec-approval-request-approval-policy
      (CodexUnifiedExecExecApprovalRequest
        $command
        $approval-policy
        $sandbox-policy
        $file-system-sandbox-policy
        $sandbox-permissions
        $prefix-rule))
   $approval-policy)

(= (codex:unified-exec-exec-approval-request-sandbox-policy
      (CodexUnifiedExecExecApprovalRequest
        $command
        $approval-policy
        $sandbox-policy
        $file-system-sandbox-policy
        $sandbox-permissions
        $prefix-rule))
   $sandbox-policy)

(= (codex:unified-exec-exec-approval-request-file-system-sandbox-policy
      (CodexUnifiedExecExecApprovalRequest
        $command
        $approval-policy
        $sandbox-policy
        $file-system-sandbox-policy
        $sandbox-permissions
        $prefix-rule))
   $file-system-sandbox-policy)

(= (codex:unified-exec-exec-approval-request-sandbox-permissions
      (CodexUnifiedExecExecApprovalRequest
        $command
        $approval-policy
        $sandbox-policy
        $file-system-sandbox-policy
        $sandbox-permissions
        $prefix-rule))
   $sandbox-permissions)

(= (codex:unified-exec-exec-approval-request-prefix-rule
      (CodexUnifiedExecExecApprovalRequest
        $command
        $approval-policy
        $sandbox-policy
        $file-system-sandbox-policy
        $sandbox-permissions
        $prefix-rule))
   $prefix-rule)

(= (codex:unified-exec-open-session-approval-sandbox-permissions
      $request)
   (if (== (codex:unified-exec-exec-command-request-additional-permissions-preapproved
             $request)
           True)
       (codex:approval-sandbox-permissions-use-default)
       (codex:unified-exec-exec-command-request-sandbox-permissions
         $request)))

(= (codex:unified-exec-tool-request
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

(= (codex:unified-exec-tool-request-command
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

(= (codex:unified-exec-tool-request-hook-command
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

(= (codex:unified-exec-tool-request-process-id
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
   $process-id)

(= (codex:unified-exec-tool-request-cwd
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

(= (codex:unified-exec-tool-request-env
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
   $env)

(= (codex:unified-exec-tool-request-exec-server-env-config
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
   $exec-server-env-config)

(= (codex:unified-exec-tool-request-explicit-env-overrides
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
   $explicit-env-overrides)

(= (codex:unified-exec-tool-request-network
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

(= (codex:unified-exec-tool-request-tty
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

(= (codex:unified-exec-tool-request-sandbox-permissions
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

(= (codex:unified-exec-tool-request-additional-permissions
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

(= (codex:unified-exec-tool-request-additional-permissions-preapproved
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
   $additional-permissions-preapproved)

(= (codex:unified-exec-tool-request-justification
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

(= (codex:unified-exec-tool-request-exec-approval-requirement
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

(= (codex:unified-exec-tool-ctx
      $session
      $turn
      $call-id
      $tool-name)
   (CodexUnifiedExecToolCtx
     $session
     $turn
     $call-id
     $tool-name))

(= (codex:unified-exec-tool-ctx-session
      (CodexUnifiedExecToolCtx $session $turn $call-id $tool-name))
   $session)

(= (codex:unified-exec-tool-ctx-turn
      (CodexUnifiedExecToolCtx $session $turn $call-id $tool-name))
   $turn)

(= (codex:unified-exec-tool-ctx-call-id
      (CodexUnifiedExecToolCtx $session $turn $call-id $tool-name))
   $call-id)

(= (codex:unified-exec-tool-ctx-tool-name
      (CodexUnifiedExecToolCtx $session $turn $call-id $tool-name))
   $tool-name)

(= (codex:unified-exec-orchestrator-run-ok
      $output
      $deferred-network-approval)
   (CodexUnifiedExecOrchestratorRunOk
     $output
     $deferred-network-approval))

(= (codex:unified-exec-orchestrator-run-sandbox-denied $output)
   (CodexUnifiedExecOrchestratorRunSandboxDenied $output))

(= (codex:unified-exec-orchestrator-run-err $debug)
   (CodexUnifiedExecOrchestratorRunErr $debug))

(= (codex:unified-exec-orchestrator-run-kind
      (CodexUnifiedExecOrchestratorRunOk
        $output
        $deferred-network-approval))
   ok)

(= (codex:unified-exec-orchestrator-run-kind
      (CodexUnifiedExecOrchestratorRunSandboxDenied $output))
   sandbox_denied)

(= (codex:unified-exec-orchestrator-run-kind
      (CodexUnifiedExecOrchestratorRunErr $debug))
   err)

(= (codex:unified-exec-orchestrator-run-output
      (CodexUnifiedExecOrchestratorRunOk
        $output
        $deferred-network-approval))
   $output)

(= (codex:unified-exec-orchestrator-run-output
      (CodexUnifiedExecOrchestratorRunSandboxDenied $output))
   $output)

(= (codex:unified-exec-orchestrator-run-deferred-network-approval
      (CodexUnifiedExecOrchestratorRunOk
        $output
        $deferred-network-approval))
   $deferred-network-approval)

(= (codex:unified-exec-orchestrator-run-debug
      (CodexUnifiedExecOrchestratorRunErr $debug))
   $debug)

(= (codex:unified-exec-open-session-with-sandbox-result-ok
      $process
      $deferred-network-approval
      $tool-request
      $tool-ctx
      $approval-request
      $runtime-shell-mode)
   (CodexUnifiedExecOpenSessionWithSandboxResultOk
     $process
     $deferred-network-approval
     $tool-request
     $tool-ctx
     $approval-request
     $runtime-shell-mode))

(= (codex:unified-exec-open-session-with-sandbox-result-err
      $error
      $tool-request
      $tool-ctx
      $approval-request
      $runtime-shell-mode)
   (CodexUnifiedExecOpenSessionWithSandboxResultErr
     $error
     $tool-request
     $tool-ctx
     $approval-request
     $runtime-shell-mode))

(= (codex:unified-exec-open-session-with-sandbox-result-kind
      (CodexUnifiedExecOpenSessionWithSandboxResultOk
        $process
        $deferred-network-approval
        $tool-request
        $tool-ctx
        $approval-request
        $runtime-shell-mode))
   ok)

(= (codex:unified-exec-open-session-with-sandbox-result-kind
      (CodexUnifiedExecOpenSessionWithSandboxResultErr
        $error
        $tool-request
        $tool-ctx
        $approval-request
        $runtime-shell-mode))
   err)

(= (codex:unified-exec-open-session-with-sandbox-result-process
      (CodexUnifiedExecOpenSessionWithSandboxResultOk
        $process
        $deferred-network-approval
        $tool-request
        $tool-ctx
        $approval-request
        $runtime-shell-mode))
   $process)

(= (codex:unified-exec-open-session-with-sandbox-result-deferred-network-approval
      (CodexUnifiedExecOpenSessionWithSandboxResultOk
        $process
        $deferred-network-approval
        $tool-request
        $tool-ctx
        $approval-request
        $runtime-shell-mode))
   $deferred-network-approval)

(= (codex:unified-exec-open-session-with-sandbox-result-error
      (CodexUnifiedExecOpenSessionWithSandboxResultErr
        $error
        $tool-request
        $tool-ctx
        $approval-request
        $runtime-shell-mode))
   $error)

(= (codex:unified-exec-open-session-with-sandbox-result-tool-request
      (CodexUnifiedExecOpenSessionWithSandboxResultOk
        $process
        $deferred-network-approval
        $tool-request
        $tool-ctx
        $approval-request
        $runtime-shell-mode))
   $tool-request)

(= (codex:unified-exec-open-session-with-sandbox-result-tool-request
      (CodexUnifiedExecOpenSessionWithSandboxResultErr
        $error
        $tool-request
        $tool-ctx
        $approval-request
        $runtime-shell-mode))
   $tool-request)

(= (codex:unified-exec-open-session-with-sandbox-result-tool-ctx
      (CodexUnifiedExecOpenSessionWithSandboxResultOk
        $process
        $deferred-network-approval
        $tool-request
        $tool-ctx
        $approval-request
        $runtime-shell-mode))
   $tool-ctx)

(= (codex:unified-exec-open-session-with-sandbox-result-tool-ctx
      (CodexUnifiedExecOpenSessionWithSandboxResultErr
        $error
        $tool-request
        $tool-ctx
        $approval-request
        $runtime-shell-mode))
   $tool-ctx)

(= (codex:unified-exec-open-session-with-sandbox-result-approval-request
      (CodexUnifiedExecOpenSessionWithSandboxResultOk
        $process
        $deferred-network-approval
        $tool-request
        $tool-ctx
        $approval-request
        $runtime-shell-mode))
   $approval-request)

(= (codex:unified-exec-open-session-with-sandbox-result-approval-request
      (CodexUnifiedExecOpenSessionWithSandboxResultErr
        $error
        $tool-request
        $tool-ctx
        $approval-request
        $runtime-shell-mode))
   $approval-request)

(= (codex:unified-exec-open-session-with-sandbox-result-runtime-shell-mode
      (CodexUnifiedExecOpenSessionWithSandboxResultOk
        $process
        $deferred-network-approval
        $tool-request
        $tool-ctx
        $approval-request
        $runtime-shell-mode))
   $runtime-shell-mode)

(= (codex:unified-exec-open-session-with-sandbox-result-runtime-shell-mode
      (CodexUnifiedExecOpenSessionWithSandboxResultErr
        $error
        $tool-request
        $tool-ctx
        $approval-request
        $runtime-shell-mode))
   $runtime-shell-mode)

(= (codex:unified-exec-open-session-with-sandbox-denial-message
      $output)
   (let $aggregated-output
     (codex:unified-exec-process-exec-tool-call-output-aggregated-output
       $output)
     (if (== $aggregated-output "")
         (format-args
           "Process exited with code {}"
           ((codex:unified-exec-process-exec-tool-call-output-exit-code
              $output)))
         $aggregated-output)))

(= (codex:unified-exec-open-session-with-sandbox-from-orchestrator
      $tool-request
      $tool-ctx
      $approval-request
      $runtime-shell-mode
      (CodexUnifiedExecOrchestratorRunOk
        $output
        $deferred-network-approval))
   (codex:unified-exec-open-session-with-sandbox-result-ok
     $output
     $deferred-network-approval
     $tool-request
     $tool-ctx
     $approval-request
     $runtime-shell-mode))

(= (codex:unified-exec-open-session-with-sandbox-from-orchestrator
      $tool-request
      $tool-ctx
      $approval-request
      $runtime-shell-mode
      (CodexUnifiedExecOrchestratorRunSandboxDenied $output))
   (codex:unified-exec-open-session-with-sandbox-result-err
     (codex:unified-exec-error-sandbox-denied
       (codex:unified-exec-open-session-with-sandbox-denial-message
         $output)
       $output)
     $tool-request
     $tool-ctx
     $approval-request
     $runtime-shell-mode))

(= (codex:unified-exec-open-session-with-sandbox-from-orchestrator
      $tool-request
      $tool-ctx
      $approval-request
      $runtime-shell-mode
      (CodexUnifiedExecOrchestratorRunErr $debug))
   (codex:unified-exec-open-session-with-sandbox-result-err
     (codex:unified-exec-error-create-process $debug)
     $tool-request
     $tool-ctx
     $approval-request
     $runtime-shell-mode))

(= (codex:unified-exec-open-session-with-sandbox
      $request
      $cwd
      $context
      $inputs)
   (let $local-policy-env
     (codex:unified-exec-open-session-sandbox-inputs-local-policy-env
       $inputs)
     (let $env
       (codex:unified-exec-apply-env-defaults
         (codex:unified-exec-env-insert
           $local-policy-env
           "CODEX_THREAD_ID"
           (codex:unified-exec-open-session-sandbox-inputs-conversation-id
             $inputs)))
       (let $exec-server-env-config
         (codex:unified-exec-server-env-config
           (codex:unified-exec-open-session-sandbox-inputs-exec-env-policy
             $inputs)
           $local-policy-env)
         (let $approval-request
           (codex:unified-exec-exec-approval-request
             (codex:unified-exec-exec-command-request-command $request)
             (codex:unified-exec-open-session-sandbox-inputs-approval-policy
               $inputs)
             (codex:unified-exec-open-session-sandbox-inputs-sandbox-policy
               $inputs)
             (codex:unified-exec-open-session-sandbox-inputs-file-system-sandbox-policy
               $inputs)
             (codex:unified-exec-open-session-approval-sandbox-permissions
               $request)
             (codex:unified-exec-exec-command-request-prefix-rule
               $request))
           (let $tool-request
             (codex:unified-exec-tool-request
               (codex:unified-exec-exec-command-request-command $request)
               (codex:unified-exec-exec-command-request-hook-command
                 $request)
               (codex:unified-exec-exec-command-request-process-id
                 $request)
               $cwd
               $env
               $exec-server-env-config
               (codex:unified-exec-open-session-sandbox-inputs-explicit-env-overrides
                 $inputs)
               (codex:unified-exec-exec-command-request-network $request)
               (codex:unified-exec-exec-command-request-tty $request)
               (codex:unified-exec-exec-command-request-sandbox-permissions
                 $request)
               (codex:unified-exec-exec-command-request-additional-permissions
                 $request)
               (codex:unified-exec-exec-command-request-additional-permissions-preapproved
                 $request)
               (codex:unified-exec-exec-command-request-justification
                 $request)
               (codex:unified-exec-open-session-sandbox-inputs-exec-approval-requirement
                 $inputs))
             (let $tool-ctx
               (codex:unified-exec-tool-ctx
                 (codex:unified-exec-context-session $context)
                 (codex:unified-exec-context-turn $context)
                 (codex:unified-exec-context-call-id $context)
                 "exec_command")
               (codex:unified-exec-open-session-with-sandbox-from-orchestrator
                 $tool-request
                 $tool-ctx
                 $approval-request
                 (codex:unified-exec-open-session-sandbox-inputs-runtime-shell-mode
                   $inputs)
                 (codex:unified-exec-open-session-sandbox-inputs-orchestrator-result
                   $inputs)))))))))
