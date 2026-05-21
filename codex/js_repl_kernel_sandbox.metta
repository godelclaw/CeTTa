; Rust-faithful js_repl start_kernel sandbox command planning slice.
;
; This ports the deterministic sandbox-command setup from:
; - openai-codex/codex-rs/core/src/tools/js_repl/mod.rs
;   - `JsReplManager::start_kernel` after env construction:
;     sandbox initial selection, `SandboxCommand` construction,
;     `SandboxTransformRequest` bundling, and `ExecOptions`.
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust calls `SandboxManager::transform` and converts the transformed request
;   into an executable `ExecRequest`. This pure slice stops at the transform
;   request and exposes the same error-message prefix for the runtime boundary.
; - Rust uses compile-time host cfg inside sandbox selection. The shared CeTTa
;   sandbox-manager port receives `host-platform` explicitly, so this slice
;   carries the same explicit projection in its turn-context boundary.

!(import! &self js_repl)
!(import! &self sandbox_manager)

(= (codex:js-repl-start-kernel-turn-context
      $cwd
      $sandbox-policy
      $file-system-sandbox-policy
      $network-sandbox-policy
      $network
      $windows-sandbox-level
      $codex-linux-sandbox-exe
      $use-legacy-landlock
      $windows-sandbox-private-desktop
      $host-platform)
   (CodexJsReplStartKernelTurnContext
     $cwd
     $sandbox-policy
     $file-system-sandbox-policy
     $network-sandbox-policy
     $network
     $windows-sandbox-level
     $codex-linux-sandbox-exe
     $use-legacy-landlock
     $windows-sandbox-private-desktop
     $host-platform))

(= (codex:js-repl-start-kernel-turn-context-cwd
      (CodexJsReplStartKernelTurnContext
        $cwd $sandbox-policy $file-system-sandbox-policy
        $network-sandbox-policy $network $windows-sandbox-level
        $codex-linux-sandbox-exe $use-legacy-landlock
        $windows-sandbox-private-desktop $host-platform))
   $cwd)

(= (codex:js-repl-start-kernel-turn-context-sandbox-policy
      (CodexJsReplStartKernelTurnContext
        $cwd $sandbox-policy $file-system-sandbox-policy
        $network-sandbox-policy $network $windows-sandbox-level
        $codex-linux-sandbox-exe $use-legacy-landlock
        $windows-sandbox-private-desktop $host-platform))
   $sandbox-policy)

(= (codex:js-repl-start-kernel-turn-context-file-system-sandbox-policy
      (CodexJsReplStartKernelTurnContext
        $cwd $sandbox-policy $file-system-sandbox-policy
        $network-sandbox-policy $network $windows-sandbox-level
        $codex-linux-sandbox-exe $use-legacy-landlock
        $windows-sandbox-private-desktop $host-platform))
   $file-system-sandbox-policy)

(= (codex:js-repl-start-kernel-turn-context-network-sandbox-policy
      (CodexJsReplStartKernelTurnContext
        $cwd $sandbox-policy $file-system-sandbox-policy
        $network-sandbox-policy $network $windows-sandbox-level
        $codex-linux-sandbox-exe $use-legacy-landlock
        $windows-sandbox-private-desktop $host-platform))
   $network-sandbox-policy)

(= (codex:js-repl-start-kernel-turn-context-network
      (CodexJsReplStartKernelTurnContext
        $cwd $sandbox-policy $file-system-sandbox-policy
        $network-sandbox-policy $network $windows-sandbox-level
        $codex-linux-sandbox-exe $use-legacy-landlock
        $windows-sandbox-private-desktop $host-platform))
   $network)

(= (codex:js-repl-start-kernel-turn-context-windows-sandbox-level
      (CodexJsReplStartKernelTurnContext
        $cwd $sandbox-policy $file-system-sandbox-policy
        $network-sandbox-policy $network $windows-sandbox-level
        $codex-linux-sandbox-exe $use-legacy-landlock
        $windows-sandbox-private-desktop $host-platform))
   $windows-sandbox-level)

(= (codex:js-repl-start-kernel-turn-context-codex-linux-sandbox-exe
      (CodexJsReplStartKernelTurnContext
        $cwd $sandbox-policy $file-system-sandbox-policy
        $network-sandbox-policy $network $windows-sandbox-level
        $codex-linux-sandbox-exe $use-legacy-landlock
        $windows-sandbox-private-desktop $host-platform))
   $codex-linux-sandbox-exe)

(= (codex:js-repl-start-kernel-turn-context-use-legacy-landlock
      (CodexJsReplStartKernelTurnContext
        $cwd $sandbox-policy $file-system-sandbox-policy
        $network-sandbox-policy $network $windows-sandbox-level
        $codex-linux-sandbox-exe $use-legacy-landlock
        $windows-sandbox-private-desktop $host-platform))
   $use-legacy-landlock)

(= (codex:js-repl-start-kernel-turn-context-windows-sandbox-private-desktop
      (CodexJsReplStartKernelTurnContext
        $cwd $sandbox-policy $file-system-sandbox-policy
        $network-sandbox-policy $network $windows-sandbox-level
        $codex-linux-sandbox-exe $use-legacy-landlock
        $windows-sandbox-private-desktop $host-platform))
   $windows-sandbox-private-desktop)

(= (codex:js-repl-start-kernel-turn-context-host-platform
      (CodexJsReplStartKernelTurnContext
        $cwd $sandbox-policy $file-system-sandbox-policy
        $network-sandbox-policy $network $windows-sandbox-level
        $codex-linux-sandbox-exe $use-legacy-landlock
        $windows-sandbox-private-desktop $host-platform))
   $host-platform)

(= (codex:js-repl-start-kernel-managed-network-active $turn-context)
   (not
     (==
       (codex:js-repl-start-kernel-turn-context-network $turn-context)
       CodexAbsent)))

(= (codex:js-repl-sandbox-command
      $program $args $cwd $env $additional-permissions)
   (CodexJsReplSandboxCommand
     $program $args $cwd $env $additional-permissions))

(= (codex:js-repl-sandbox-command-program
      (CodexJsReplSandboxCommand
        $program $args $cwd $env $additional-permissions))
   $program)

(= (codex:js-repl-sandbox-command-args
      (CodexJsReplSandboxCommand
        $program $args $cwd $env $additional-permissions))
   $args)

(= (codex:js-repl-sandbox-command-cwd
      (CodexJsReplSandboxCommand
        $program $args $cwd $env $additional-permissions))
   $cwd)

(= (codex:js-repl-sandbox-command-env
      (CodexJsReplSandboxCommand
        $program $args $cwd $env $additional-permissions))
   $env)

(= (codex:js-repl-sandbox-command-additional-permissions
      (CodexJsReplSandboxCommand
        $program $args $cwd $env $additional-permissions))
   $additional-permissions)

(= (codex:js-repl-start-kernel-sandbox-command
      $node-path $kernel-path $cwd $env)
   (codex:js-repl-sandbox-command
     $node-path
     ("--experimental-vm-modules" $kernel-path)
     $cwd
     $env
     CodexAbsent))

(= (codex:js-repl-start-kernel-sandbox-type $turn-context)
   (codex:sandbox-manager-select-initial
     (codex:sandbox-manager-new)
     (codex:js-repl-start-kernel-turn-context-file-system-sandbox-policy
       $turn-context)
     (codex:js-repl-start-kernel-turn-context-network-sandbox-policy
       $turn-context)
     (CodexSandboxablePreferenceAuto)
     (codex:js-repl-start-kernel-turn-context-windows-sandbox-level
       $turn-context)
     (codex:js-repl-start-kernel-managed-network-active $turn-context)
     (codex:js-repl-start-kernel-turn-context-host-platform
       $turn-context)))

(= (codex:js-repl-sandbox-transform-request
      $command $policy $file-system-policy $network-policy $sandbox
      $enforce-managed-network $network $sandbox-policy-cwd
      $codex-linux-sandbox-exe $use-legacy-landlock
      $windows-sandbox-level $windows-sandbox-private-desktop)
   (CodexJsReplSandboxTransformRequest
     $command $policy $file-system-policy $network-policy $sandbox
     $enforce-managed-network $network $sandbox-policy-cwd
     $codex-linux-sandbox-exe $use-legacy-landlock
     $windows-sandbox-level $windows-sandbox-private-desktop))

(= (codex:js-repl-sandbox-transform-request-command
      (CodexJsReplSandboxTransformRequest
        $command $policy $file-system-policy $network-policy $sandbox
        $enforce-managed-network $network $sandbox-policy-cwd
        $codex-linux-sandbox-exe $use-legacy-landlock
        $windows-sandbox-level $windows-sandbox-private-desktop))
   $command)

(= (codex:js-repl-sandbox-transform-request-policy
      (CodexJsReplSandboxTransformRequest
        $command $policy $file-system-policy $network-policy $sandbox
        $enforce-managed-network $network $sandbox-policy-cwd
        $codex-linux-sandbox-exe $use-legacy-landlock
        $windows-sandbox-level $windows-sandbox-private-desktop))
   $policy)

(= (codex:js-repl-sandbox-transform-request-file-system-policy
      (CodexJsReplSandboxTransformRequest
        $command $policy $file-system-policy $network-policy $sandbox
        $enforce-managed-network $network $sandbox-policy-cwd
        $codex-linux-sandbox-exe $use-legacy-landlock
        $windows-sandbox-level $windows-sandbox-private-desktop))
   $file-system-policy)

(= (codex:js-repl-sandbox-transform-request-network-policy
      (CodexJsReplSandboxTransformRequest
        $command $policy $file-system-policy $network-policy $sandbox
        $enforce-managed-network $network $sandbox-policy-cwd
        $codex-linux-sandbox-exe $use-legacy-landlock
        $windows-sandbox-level $windows-sandbox-private-desktop))
   $network-policy)

(= (codex:js-repl-sandbox-transform-request-sandbox
      (CodexJsReplSandboxTransformRequest
        $command $policy $file-system-policy $network-policy $sandbox
        $enforce-managed-network $network $sandbox-policy-cwd
        $codex-linux-sandbox-exe $use-legacy-landlock
        $windows-sandbox-level $windows-sandbox-private-desktop))
   $sandbox)

(= (codex:js-repl-sandbox-transform-request-enforce-managed-network
      (CodexJsReplSandboxTransformRequest
        $command $policy $file-system-policy $network-policy $sandbox
        $enforce-managed-network $network $sandbox-policy-cwd
        $codex-linux-sandbox-exe $use-legacy-landlock
        $windows-sandbox-level $windows-sandbox-private-desktop))
   $enforce-managed-network)

(= (codex:js-repl-sandbox-transform-request-network
      (CodexJsReplSandboxTransformRequest
        $command $policy $file-system-policy $network-policy $sandbox
        $enforce-managed-network $network $sandbox-policy-cwd
        $codex-linux-sandbox-exe $use-legacy-landlock
        $windows-sandbox-level $windows-sandbox-private-desktop))
   $network)

(= (codex:js-repl-sandbox-transform-request-sandbox-policy-cwd
      (CodexJsReplSandboxTransformRequest
        $command $policy $file-system-policy $network-policy $sandbox
        $enforce-managed-network $network $sandbox-policy-cwd
        $codex-linux-sandbox-exe $use-legacy-landlock
        $windows-sandbox-level $windows-sandbox-private-desktop))
   $sandbox-policy-cwd)

(= (codex:js-repl-sandbox-transform-request-codex-linux-sandbox-exe
      (CodexJsReplSandboxTransformRequest
        $command $policy $file-system-policy $network-policy $sandbox
        $enforce-managed-network $network $sandbox-policy-cwd
        $codex-linux-sandbox-exe $use-legacy-landlock
        $windows-sandbox-level $windows-sandbox-private-desktop))
   $codex-linux-sandbox-exe)

(= (codex:js-repl-sandbox-transform-request-use-legacy-landlock
      (CodexJsReplSandboxTransformRequest
        $command $policy $file-system-policy $network-policy $sandbox
        $enforce-managed-network $network $sandbox-policy-cwd
        $codex-linux-sandbox-exe $use-legacy-landlock
        $windows-sandbox-level $windows-sandbox-private-desktop))
   $use-legacy-landlock)

(= (codex:js-repl-sandbox-transform-request-windows-sandbox-level
      (CodexJsReplSandboxTransformRequest
        $command $policy $file-system-policy $network-policy $sandbox
        $enforce-managed-network $network $sandbox-policy-cwd
        $codex-linux-sandbox-exe $use-legacy-landlock
        $windows-sandbox-level $windows-sandbox-private-desktop))
   $windows-sandbox-level)

(= (codex:js-repl-sandbox-transform-request-windows-sandbox-private-desktop
      (CodexJsReplSandboxTransformRequest
        $command $policy $file-system-policy $network-policy $sandbox
        $enforce-managed-network $network $sandbox-policy-cwd
        $codex-linux-sandbox-exe $use-legacy-landlock
        $windows-sandbox-level $windows-sandbox-private-desktop))
   $windows-sandbox-private-desktop)

(= (codex:js-repl-start-kernel-transform-request
      $node-path $kernel-path $env $turn-context)
   (let $cwd
     (codex:js-repl-start-kernel-turn-context-cwd $turn-context)
     (codex:js-repl-sandbox-transform-request
       (codex:js-repl-start-kernel-sandbox-command
         $node-path $kernel-path $cwd $env)
       (codex:js-repl-start-kernel-turn-context-sandbox-policy
         $turn-context)
       (codex:js-repl-start-kernel-turn-context-file-system-sandbox-policy
         $turn-context)
       (codex:js-repl-start-kernel-turn-context-network-sandbox-policy
         $turn-context)
       (codex:js-repl-start-kernel-sandbox-type $turn-context)
       (codex:js-repl-start-kernel-managed-network-active $turn-context)
       CodexAbsent
       $cwd
       (codex:js-repl-start-kernel-turn-context-codex-linux-sandbox-exe
         $turn-context)
       (codex:js-repl-start-kernel-turn-context-use-legacy-landlock
         $turn-context)
       (codex:js-repl-start-kernel-turn-context-windows-sandbox-level
         $turn-context)
       (codex:js-repl-start-kernel-turn-context-windows-sandbox-private-desktop
         $turn-context))))

(= (codex:js-repl-exec-expiration-default-timeout)
   (CodexJsReplExecExpirationDefaultTimeout))

(= (codex:js-repl-exec-capture-policy-shell-tool)
   (CodexJsReplExecCapturePolicyShellTool))

(= (codex:js-repl-exec-options $expiration $capture-policy)
   (CodexJsReplExecOptions $expiration $capture-policy))

(= (codex:js-repl-exec-options-expiration
      (CodexJsReplExecOptions $expiration $capture-policy))
   $expiration)

(= (codex:js-repl-exec-options-capture-policy
      (CodexJsReplExecOptions $expiration $capture-policy))
   $capture-policy)

(= (codex:js-repl-start-kernel-exec-options)
   (codex:js-repl-exec-options
     (codex:js-repl-exec-expiration-default-timeout)
     (codex:js-repl-exec-capture-policy-shell-tool)))

(= (codex:js-repl-start-kernel-transform-plan
      $transform-request $exec-options $windows-sandbox-policy-cwd)
   (CodexJsReplStartKernelTransformPlan
     $transform-request $exec-options $windows-sandbox-policy-cwd))

(= (codex:js-repl-start-kernel-transform-plan-request
      (CodexJsReplStartKernelTransformPlan
        $transform-request $exec-options $windows-sandbox-policy-cwd))
   $transform-request)

(= (codex:js-repl-start-kernel-transform-plan-exec-options
      (CodexJsReplStartKernelTransformPlan
        $transform-request $exec-options $windows-sandbox-policy-cwd))
   $exec-options)

(= (codex:js-repl-start-kernel-transform-plan-windows-sandbox-policy-cwd
      (CodexJsReplStartKernelTransformPlan
        $transform-request $exec-options $windows-sandbox-policy-cwd))
   $windows-sandbox-policy-cwd)

(= (codex:js-repl-start-kernel-plan-ok $plan)
   (CodexJsReplStartKernelPlanOk $plan))

(= (codex:js-repl-start-kernel-plan-error $message)
   (CodexJsReplStartKernelPlanError $message))

(= (codex:js-repl-start-kernel-plan-value
      (CodexJsReplStartKernelPlanOk $plan))
   $plan)

(= (codex:js-repl-start-kernel-plan-error-message
      (CodexJsReplStartKernelPlanError $message))
   $message)

(= (codex:js-repl-start-kernel-transform-error-message $message)
   (str-concat "failed to configure sandbox for js_repl: " $message))

(= (codex:js-repl-start-kernel-plan
      $node-path $kernel-path $env-result $turn-context)
   (case $env-result
     (((CodexJsReplStartKernelEnvError $message)
       (codex:js-repl-start-kernel-plan-error $message))
      ((CodexJsReplStartKernelEnvOk $env)
       (codex:js-repl-start-kernel-plan-ok
         (codex:js-repl-start-kernel-transform-plan
           (codex:js-repl-start-kernel-transform-request
             $node-path $kernel-path $env $turn-context)
           (codex:js-repl-start-kernel-exec-options)
           (codex:js-repl-start-kernel-turn-context-cwd
             $turn-context)))))))
