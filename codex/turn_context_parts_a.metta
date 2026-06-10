; Rust-faithful turn context slice: identity, model, environment, instructions groups.
;
; This ports the TurnContext struct fields from:
; - openai-codex/codex-rs/core/src/session/turn_context.rs
;
; Deviation (documented in turn_context.metta header): Rust's flat
; 44-field TurnContext is represented as seven field-group records to
; respect the evaluator module-size constraint; every Rust field exists
; under its exact name within its group.

(= (codex:turn-context-identity
      $sub-id
      $trace-id
      $realtime-active
      $session-source)
   (CodexTurnContextIdentity
     $sub-id
     $trace-id
     $realtime-active
     $session-source))

(= (codex:turn-context-identity-sub-id
      (CodexTurnContextIdentity
        $sub-id
        $trace-id
        $realtime-active
        $session-source))
   $sub-id)

(= (codex:turn-context-identity-trace-id
      (CodexTurnContextIdentity
        $sub-id
        $trace-id
        $realtime-active
        $session-source))
   $trace-id)

(= (codex:turn-context-identity-realtime-active
      (CodexTurnContextIdentity
        $sub-id
        $trace-id
        $realtime-active
        $session-source))
   $realtime-active)

(= (codex:turn-context-identity-session-source
      (CodexTurnContextIdentity
        $sub-id
        $trace-id
        $realtime-active
        $session-source))
   $session-source)

(= (codex:turn-context-model
      $config
      $auth-manager
      $model-info
      $session-telemetry
      $provider
      $reasoning-effort
      $reasoning-summary)
   (CodexTurnContextModel
     $config
     $auth-manager
     $model-info
     $session-telemetry
     $provider
     $reasoning-effort
     $reasoning-summary))

(= (codex:turn-context-model-config
      (CodexTurnContextModel
        $config
        $auth-manager
        $model-info
        $session-telemetry
        $provider
        $reasoning-effort
        $reasoning-summary))
   $config)

(= (codex:turn-context-model-auth-manager
      (CodexTurnContextModel
        $config
        $auth-manager
        $model-info
        $session-telemetry
        $provider
        $reasoning-effort
        $reasoning-summary))
   $auth-manager)

(= (codex:turn-context-model-model-info
      (CodexTurnContextModel
        $config
        $auth-manager
        $model-info
        $session-telemetry
        $provider
        $reasoning-effort
        $reasoning-summary))
   $model-info)

(= (codex:turn-context-model-session-telemetry
      (CodexTurnContextModel
        $config
        $auth-manager
        $model-info
        $session-telemetry
        $provider
        $reasoning-effort
        $reasoning-summary))
   $session-telemetry)

(= (codex:turn-context-model-provider
      (CodexTurnContextModel
        $config
        $auth-manager
        $model-info
        $session-telemetry
        $provider
        $reasoning-effort
        $reasoning-summary))
   $provider)

(= (codex:turn-context-model-reasoning-effort
      (CodexTurnContextModel
        $config
        $auth-manager
        $model-info
        $session-telemetry
        $provider
        $reasoning-effort
        $reasoning-summary))
   $reasoning-effort)

(= (codex:turn-context-model-reasoning-summary
      (CodexTurnContextModel
        $config
        $auth-manager
        $model-info
        $session-telemetry
        $provider
        $reasoning-effort
        $reasoning-summary))
   $reasoning-summary)

(= (codex:turn-context-environment
      $environment
      $environments
      $cwd
      $current-date
      $timezone
      $app-server-client-name)
   (CodexTurnContextEnvironment
     $environment
     $environments
     $cwd
     $current-date
     $timezone
     $app-server-client-name))

(= (codex:turn-context-environment-environment
      (CodexTurnContextEnvironment
        $environment
        $environments
        $cwd
        $current-date
        $timezone
        $app-server-client-name))
   $environment)

(= (codex:turn-context-environment-environments
      (CodexTurnContextEnvironment
        $environment
        $environments
        $cwd
        $current-date
        $timezone
        $app-server-client-name))
   $environments)

(= (codex:turn-context-environment-cwd
      (CodexTurnContextEnvironment
        $environment
        $environments
        $cwd
        $current-date
        $timezone
        $app-server-client-name))
   $cwd)

(= (codex:turn-context-environment-current-date
      (CodexTurnContextEnvironment
        $environment
        $environments
        $cwd
        $current-date
        $timezone
        $app-server-client-name))
   $current-date)

(= (codex:turn-context-environment-timezone
      (CodexTurnContextEnvironment
        $environment
        $environments
        $cwd
        $current-date
        $timezone
        $app-server-client-name))
   $timezone)

(= (codex:turn-context-environment-app-server-client-name
      (CodexTurnContextEnvironment
        $environment
        $environments
        $cwd
        $current-date
        $timezone
        $app-server-client-name))
   $app-server-client-name)

(= (codex:turn-context-instructions
      $developer-instructions
      $compact-prompt
      $user-instructions
      $collaboration-mode
      $personality)
   (CodexTurnContextInstructions
     $developer-instructions
     $compact-prompt
     $user-instructions
     $collaboration-mode
     $personality))

(= (codex:turn-context-instructions-developer-instructions
      (CodexTurnContextInstructions
        $developer-instructions
        $compact-prompt
        $user-instructions
        $collaboration-mode
        $personality))
   $developer-instructions)

(= (codex:turn-context-instructions-compact-prompt
      (CodexTurnContextInstructions
        $developer-instructions
        $compact-prompt
        $user-instructions
        $collaboration-mode
        $personality))
   $compact-prompt)

(= (codex:turn-context-instructions-user-instructions
      (CodexTurnContextInstructions
        $developer-instructions
        $compact-prompt
        $user-instructions
        $collaboration-mode
        $personality))
   $user-instructions)

(= (codex:turn-context-instructions-collaboration-mode
      (CodexTurnContextInstructions
        $developer-instructions
        $compact-prompt
        $user-instructions
        $collaboration-mode
        $personality))
   $collaboration-mode)

(= (codex:turn-context-instructions-personality
      (CodexTurnContextInstructions
        $developer-instructions
        $compact-prompt
        $user-instructions
        $collaboration-mode
        $personality))
   $personality)

