; Rust-faithful turn context slice: permissions, tools, state groups.
;
; This ports the TurnContext struct fields from:
; - openai-codex/codex-rs/core/src/session/turn_context.rs
;
; Deviation (documented in turn_context.metta header): Rust's flat
; 44-field TurnContext is represented as seven field-group records to
; respect the evaluator module-size constraint; every Rust field exists
; under its exact name within its group.

(= (codex:turn-context-permissions
      $approval-policy
      $sandbox-policy
      $file-system-sandbox-policy
      $network-sandbox-policy
      $network
      $windows-sandbox-level
      $shell-environment-policy)
   (CodexTurnContextPermissions
     $approval-policy
     $sandbox-policy
     $file-system-sandbox-policy
     $network-sandbox-policy
     $network
     $windows-sandbox-level
     $shell-environment-policy))

(= (codex:turn-context-permissions-approval-policy
      (CodexTurnContextPermissions
        $approval-policy
        $sandbox-policy
        $file-system-sandbox-policy
        $network-sandbox-policy
        $network
        $windows-sandbox-level
        $shell-environment-policy))
   $approval-policy)

(= (codex:turn-context-permissions-sandbox-policy
      (CodexTurnContextPermissions
        $approval-policy
        $sandbox-policy
        $file-system-sandbox-policy
        $network-sandbox-policy
        $network
        $windows-sandbox-level
        $shell-environment-policy))
   $sandbox-policy)

(= (codex:turn-context-permissions-file-system-sandbox-policy
      (CodexTurnContextPermissions
        $approval-policy
        $sandbox-policy
        $file-system-sandbox-policy
        $network-sandbox-policy
        $network
        $windows-sandbox-level
        $shell-environment-policy))
   $file-system-sandbox-policy)

(= (codex:turn-context-permissions-network-sandbox-policy
      (CodexTurnContextPermissions
        $approval-policy
        $sandbox-policy
        $file-system-sandbox-policy
        $network-sandbox-policy
        $network
        $windows-sandbox-level
        $shell-environment-policy))
   $network-sandbox-policy)

(= (codex:turn-context-permissions-network
      (CodexTurnContextPermissions
        $approval-policy
        $sandbox-policy
        $file-system-sandbox-policy
        $network-sandbox-policy
        $network
        $windows-sandbox-level
        $shell-environment-policy))
   $network)

(= (codex:turn-context-permissions-windows-sandbox-level
      (CodexTurnContextPermissions
        $approval-policy
        $sandbox-policy
        $file-system-sandbox-policy
        $network-sandbox-policy
        $network
        $windows-sandbox-level
        $shell-environment-policy))
   $windows-sandbox-level)

(= (codex:turn-context-permissions-shell-environment-policy
      (CodexTurnContextPermissions
        $approval-policy
        $sandbox-policy
        $file-system-sandbox-policy
        $network-sandbox-policy
        $network
        $windows-sandbox-level
        $shell-environment-policy))
   $shell-environment-policy)

(= (codex:turn-context-tools
      $tools-config
      $features
      $ghost-snapshot
      $final-output-json-schema
      $codex-self-exe
      $codex-linux-sandbox-exe
      $tool-call-gate
      $truncation-policy
      $js-repl
      $dynamic-tools)
   (CodexTurnContextTools
     $tools-config
     $features
     $ghost-snapshot
     $final-output-json-schema
     $codex-self-exe
     $codex-linux-sandbox-exe
     $tool-call-gate
     $truncation-policy
     $js-repl
     $dynamic-tools))

(= (codex:turn-context-tools-tools-config
      (CodexTurnContextTools
        $tools-config
        $features
        $ghost-snapshot
        $final-output-json-schema
        $codex-self-exe
        $codex-linux-sandbox-exe
        $tool-call-gate
        $truncation-policy
        $js-repl
        $dynamic-tools))
   $tools-config)

(= (codex:turn-context-tools-features
      (CodexTurnContextTools
        $tools-config
        $features
        $ghost-snapshot
        $final-output-json-schema
        $codex-self-exe
        $codex-linux-sandbox-exe
        $tool-call-gate
        $truncation-policy
        $js-repl
        $dynamic-tools))
   $features)

(= (codex:turn-context-tools-ghost-snapshot
      (CodexTurnContextTools
        $tools-config
        $features
        $ghost-snapshot
        $final-output-json-schema
        $codex-self-exe
        $codex-linux-sandbox-exe
        $tool-call-gate
        $truncation-policy
        $js-repl
        $dynamic-tools))
   $ghost-snapshot)

(= (codex:turn-context-tools-final-output-json-schema
      (CodexTurnContextTools
        $tools-config
        $features
        $ghost-snapshot
        $final-output-json-schema
        $codex-self-exe
        $codex-linux-sandbox-exe
        $tool-call-gate
        $truncation-policy
        $js-repl
        $dynamic-tools))
   $final-output-json-schema)

(= (codex:turn-context-tools-codex-self-exe
      (CodexTurnContextTools
        $tools-config
        $features
        $ghost-snapshot
        $final-output-json-schema
        $codex-self-exe
        $codex-linux-sandbox-exe
        $tool-call-gate
        $truncation-policy
        $js-repl
        $dynamic-tools))
   $codex-self-exe)

(= (codex:turn-context-tools-codex-linux-sandbox-exe
      (CodexTurnContextTools
        $tools-config
        $features
        $ghost-snapshot
        $final-output-json-schema
        $codex-self-exe
        $codex-linux-sandbox-exe
        $tool-call-gate
        $truncation-policy
        $js-repl
        $dynamic-tools))
   $codex-linux-sandbox-exe)

(= (codex:turn-context-tools-tool-call-gate
      (CodexTurnContextTools
        $tools-config
        $features
        $ghost-snapshot
        $final-output-json-schema
        $codex-self-exe
        $codex-linux-sandbox-exe
        $tool-call-gate
        $truncation-policy
        $js-repl
        $dynamic-tools))
   $tool-call-gate)

(= (codex:turn-context-tools-truncation-policy
      (CodexTurnContextTools
        $tools-config
        $features
        $ghost-snapshot
        $final-output-json-schema
        $codex-self-exe
        $codex-linux-sandbox-exe
        $tool-call-gate
        $truncation-policy
        $js-repl
        $dynamic-tools))
   $truncation-policy)

(= (codex:turn-context-tools-js-repl
      (CodexTurnContextTools
        $tools-config
        $features
        $ghost-snapshot
        $final-output-json-schema
        $codex-self-exe
        $codex-linux-sandbox-exe
        $tool-call-gate
        $truncation-policy
        $js-repl
        $dynamic-tools))
   $js-repl)

(= (codex:turn-context-tools-dynamic-tools
      (CodexTurnContextTools
        $tools-config
        $features
        $ghost-snapshot
        $final-output-json-schema
        $codex-self-exe
        $codex-linux-sandbox-exe
        $tool-call-gate
        $truncation-policy
        $js-repl
        $dynamic-tools))
   $dynamic-tools)

(= (codex:turn-context-state
      $turn-metadata-state
      $turn-skills
      $turn-timing-state
      $server-model-warning-emitted
      $model-verification-emitted)
   (CodexTurnContextState
     $turn-metadata-state
     $turn-skills
     $turn-timing-state
     $server-model-warning-emitted
     $model-verification-emitted))

(= (codex:turn-context-state-turn-metadata-state
      (CodexTurnContextState
        $turn-metadata-state
        $turn-skills
        $turn-timing-state
        $server-model-warning-emitted
        $model-verification-emitted))
   $turn-metadata-state)

(= (codex:turn-context-state-turn-skills
      (CodexTurnContextState
        $turn-metadata-state
        $turn-skills
        $turn-timing-state
        $server-model-warning-emitted
        $model-verification-emitted))
   $turn-skills)

(= (codex:turn-context-state-turn-timing-state
      (CodexTurnContextState
        $turn-metadata-state
        $turn-skills
        $turn-timing-state
        $server-model-warning-emitted
        $model-verification-emitted))
   $turn-timing-state)

(= (codex:turn-context-state-server-model-warning-emitted
      (CodexTurnContextState
        $turn-metadata-state
        $turn-skills
        $turn-timing-state
        $server-model-warning-emitted
        $model-verification-emitted))
   $server-model-warning-emitted)

(= (codex:turn-context-state-model-verification-emitted
      (CodexTurnContextState
        $turn-metadata-state
        $turn-skills
        $turn-timing-state
        $server-model-warning-emitted
        $model-verification-emitted))
   $model-verification-emitted)

