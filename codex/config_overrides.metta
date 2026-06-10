; Rust-faithful config overrides slice.
;
; This ports the ConfigOverrides struct surface from:
; - openai-codex/codex-rs/core/src/config/mod.rs (ConfigOverrides)
;
; Covered in this increment:
; - the ConfigOverrides record constructor in exact Rust field order
; - per-field getters via full-constructor destructuring
; - the default value: every optional field absent and
;   additional_writable_roots empty, matching Rust's Default derive
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust Option<T> fields are modeled with CodexAbsent for None, matching
;   the established port convention.
; - Rust's nested Option<Option<ServiceTier>> for service_tier is modeled
;   as a single slot holding CodexAbsent (outer None) or
;   (CodexConfigOverrideSet $value) where $value may itself be CodexAbsent
;   (explicit override to None).
; - Getters destructure the full constructor in the equation head instead
;   of chaining accessors (evaluator constraint; see
;   specs/codex_known_red_surfaces.md history).

(= (codex:config-override-set $value)
   (CodexConfigOverrideSet $value))

(= (codex:config-override-set-value (CodexConfigOverrideSet $value))
   $value)

(= (codex:config-overrides
      $model
      $review-model
      $cwd
      $approval-policy
      $approvals-reviewer
      $sandbox-mode
      $permission-profile
      $model-provider
      $service-tier
      $config-profile
      $codex-self-exe
      $codex-linux-sandbox-exe
      $main-execve-wrapper-exe
      $js-repl-node-path
      $js-repl-node-module-dirs
      $zsh-path
      $base-instructions
      $developer-instructions
      $personality
      $compact-prompt
      $include-apply-patch-tool
      $show-raw-agent-reasoning
      $tools-web-search-request
      $ephemeral
      $additional-writable-roots)
   (CodexConfigOverrides
     
$model     $review-model     $cwd     $approval-policy     $approvals-reviewer     $sandbox-mode     $permission-profile     $model-provider     $service-tier     $config-profile     $codex-self-exe     $codex-linux-sandbox-exe     $main-execve-wrapper-exe     $js-repl-node-path     $js-repl-node-module-dirs     $zsh-path     $base-instructions     $developer-instructions     $personality     $compact-prompt     $include-apply-patch-tool     $show-raw-agent-reasoning     $tools-web-search-request     $ephemeral     $additional-writable-roots))

(= (codex:config-overrides-default)
   (CodexConfigOverrides
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     ()))

(= (codex:config-overrides-model
      (CodexConfigOverrides
        
$model        $review-model        $cwd        $approval-policy        $approvals-reviewer        $sandbox-mode        $permission-profile        $model-provider        $service-tier        $config-profile        $codex-self-exe        $codex-linux-sandbox-exe        $main-execve-wrapper-exe        $js-repl-node-path        $js-repl-node-module-dirs        $zsh-path        $base-instructions        $developer-instructions        $personality        $compact-prompt        $include-apply-patch-tool        $show-raw-agent-reasoning        $tools-web-search-request        $ephemeral        $additional-writable-roots))
   $model)

(= (codex:config-overrides-review-model
      (CodexConfigOverrides
        
$model        $review-model        $cwd        $approval-policy        $approvals-reviewer        $sandbox-mode        $permission-profile        $model-provider        $service-tier        $config-profile        $codex-self-exe        $codex-linux-sandbox-exe        $main-execve-wrapper-exe        $js-repl-node-path        $js-repl-node-module-dirs        $zsh-path        $base-instructions        $developer-instructions        $personality        $compact-prompt        $include-apply-patch-tool        $show-raw-agent-reasoning        $tools-web-search-request        $ephemeral        $additional-writable-roots))
   $review-model)

(= (codex:config-overrides-cwd
      (CodexConfigOverrides
        
$model        $review-model        $cwd        $approval-policy        $approvals-reviewer        $sandbox-mode        $permission-profile        $model-provider        $service-tier        $config-profile        $codex-self-exe        $codex-linux-sandbox-exe        $main-execve-wrapper-exe        $js-repl-node-path        $js-repl-node-module-dirs        $zsh-path        $base-instructions        $developer-instructions        $personality        $compact-prompt        $include-apply-patch-tool        $show-raw-agent-reasoning        $tools-web-search-request        $ephemeral        $additional-writable-roots))
   $cwd)

(= (codex:config-overrides-approval-policy
      (CodexConfigOverrides
        
$model        $review-model        $cwd        $approval-policy        $approvals-reviewer        $sandbox-mode        $permission-profile        $model-provider        $service-tier        $config-profile        $codex-self-exe        $codex-linux-sandbox-exe        $main-execve-wrapper-exe        $js-repl-node-path        $js-repl-node-module-dirs        $zsh-path        $base-instructions        $developer-instructions        $personality        $compact-prompt        $include-apply-patch-tool        $show-raw-agent-reasoning        $tools-web-search-request        $ephemeral        $additional-writable-roots))
   $approval-policy)

(= (codex:config-overrides-approvals-reviewer
      (CodexConfigOverrides
        
$model        $review-model        $cwd        $approval-policy        $approvals-reviewer        $sandbox-mode        $permission-profile        $model-provider        $service-tier        $config-profile        $codex-self-exe        $codex-linux-sandbox-exe        $main-execve-wrapper-exe        $js-repl-node-path        $js-repl-node-module-dirs        $zsh-path        $base-instructions        $developer-instructions        $personality        $compact-prompt        $include-apply-patch-tool        $show-raw-agent-reasoning        $tools-web-search-request        $ephemeral        $additional-writable-roots))
   $approvals-reviewer)

(= (codex:config-overrides-sandbox-mode
      (CodexConfigOverrides
        
$model        $review-model        $cwd        $approval-policy        $approvals-reviewer        $sandbox-mode        $permission-profile        $model-provider        $service-tier        $config-profile        $codex-self-exe        $codex-linux-sandbox-exe        $main-execve-wrapper-exe        $js-repl-node-path        $js-repl-node-module-dirs        $zsh-path        $base-instructions        $developer-instructions        $personality        $compact-prompt        $include-apply-patch-tool        $show-raw-agent-reasoning        $tools-web-search-request        $ephemeral        $additional-writable-roots))
   $sandbox-mode)

(= (codex:config-overrides-permission-profile
      (CodexConfigOverrides
        
$model        $review-model        $cwd        $approval-policy        $approvals-reviewer        $sandbox-mode        $permission-profile        $model-provider        $service-tier        $config-profile        $codex-self-exe        $codex-linux-sandbox-exe        $main-execve-wrapper-exe        $js-repl-node-path        $js-repl-node-module-dirs        $zsh-path        $base-instructions        $developer-instructions        $personality        $compact-prompt        $include-apply-patch-tool        $show-raw-agent-reasoning        $tools-web-search-request        $ephemeral        $additional-writable-roots))
   $permission-profile)

(= (codex:config-overrides-model-provider
      (CodexConfigOverrides
        
$model        $review-model        $cwd        $approval-policy        $approvals-reviewer        $sandbox-mode        $permission-profile        $model-provider        $service-tier        $config-profile        $codex-self-exe        $codex-linux-sandbox-exe        $main-execve-wrapper-exe        $js-repl-node-path        $js-repl-node-module-dirs        $zsh-path        $base-instructions        $developer-instructions        $personality        $compact-prompt        $include-apply-patch-tool        $show-raw-agent-reasoning        $tools-web-search-request        $ephemeral        $additional-writable-roots))
   $model-provider)

(= (codex:config-overrides-service-tier
      (CodexConfigOverrides
        
$model        $review-model        $cwd        $approval-policy        $approvals-reviewer        $sandbox-mode        $permission-profile        $model-provider        $service-tier        $config-profile        $codex-self-exe        $codex-linux-sandbox-exe        $main-execve-wrapper-exe        $js-repl-node-path        $js-repl-node-module-dirs        $zsh-path        $base-instructions        $developer-instructions        $personality        $compact-prompt        $include-apply-patch-tool        $show-raw-agent-reasoning        $tools-web-search-request        $ephemeral        $additional-writable-roots))
   $service-tier)

(= (codex:config-overrides-config-profile
      (CodexConfigOverrides
        
$model        $review-model        $cwd        $approval-policy        $approvals-reviewer        $sandbox-mode        $permission-profile        $model-provider        $service-tier        $config-profile        $codex-self-exe        $codex-linux-sandbox-exe        $main-execve-wrapper-exe        $js-repl-node-path        $js-repl-node-module-dirs        $zsh-path        $base-instructions        $developer-instructions        $personality        $compact-prompt        $include-apply-patch-tool        $show-raw-agent-reasoning        $tools-web-search-request        $ephemeral        $additional-writable-roots))
   $config-profile)

(= (codex:config-overrides-codex-self-exe
      (CodexConfigOverrides
        
$model        $review-model        $cwd        $approval-policy        $approvals-reviewer        $sandbox-mode        $permission-profile        $model-provider        $service-tier        $config-profile        $codex-self-exe        $codex-linux-sandbox-exe        $main-execve-wrapper-exe        $js-repl-node-path        $js-repl-node-module-dirs        $zsh-path        $base-instructions        $developer-instructions        $personality        $compact-prompt        $include-apply-patch-tool        $show-raw-agent-reasoning        $tools-web-search-request        $ephemeral        $additional-writable-roots))
   $codex-self-exe)

(= (codex:config-overrides-codex-linux-sandbox-exe
      (CodexConfigOverrides
        
$model        $review-model        $cwd        $approval-policy        $approvals-reviewer        $sandbox-mode        $permission-profile        $model-provider        $service-tier        $config-profile        $codex-self-exe        $codex-linux-sandbox-exe        $main-execve-wrapper-exe        $js-repl-node-path        $js-repl-node-module-dirs        $zsh-path        $base-instructions        $developer-instructions        $personality        $compact-prompt        $include-apply-patch-tool        $show-raw-agent-reasoning        $tools-web-search-request        $ephemeral        $additional-writable-roots))
   $codex-linux-sandbox-exe)

(= (codex:config-overrides-main-execve-wrapper-exe
      (CodexConfigOverrides
        
$model        $review-model        $cwd        $approval-policy        $approvals-reviewer        $sandbox-mode        $permission-profile        $model-provider        $service-tier        $config-profile        $codex-self-exe        $codex-linux-sandbox-exe        $main-execve-wrapper-exe        $js-repl-node-path        $js-repl-node-module-dirs        $zsh-path        $base-instructions        $developer-instructions        $personality        $compact-prompt        $include-apply-patch-tool        $show-raw-agent-reasoning        $tools-web-search-request        $ephemeral        $additional-writable-roots))
   $main-execve-wrapper-exe)

(= (codex:config-overrides-js-repl-node-path
      (CodexConfigOverrides
        
$model        $review-model        $cwd        $approval-policy        $approvals-reviewer        $sandbox-mode        $permission-profile        $model-provider        $service-tier        $config-profile        $codex-self-exe        $codex-linux-sandbox-exe        $main-execve-wrapper-exe        $js-repl-node-path        $js-repl-node-module-dirs        $zsh-path        $base-instructions        $developer-instructions        $personality        $compact-prompt        $include-apply-patch-tool        $show-raw-agent-reasoning        $tools-web-search-request        $ephemeral        $additional-writable-roots))
   $js-repl-node-path)

(= (codex:config-overrides-js-repl-node-module-dirs
      (CodexConfigOverrides
        
$model        $review-model        $cwd        $approval-policy        $approvals-reviewer        $sandbox-mode        $permission-profile        $model-provider        $service-tier        $config-profile        $codex-self-exe        $codex-linux-sandbox-exe        $main-execve-wrapper-exe        $js-repl-node-path        $js-repl-node-module-dirs        $zsh-path        $base-instructions        $developer-instructions        $personality        $compact-prompt        $include-apply-patch-tool        $show-raw-agent-reasoning        $tools-web-search-request        $ephemeral        $additional-writable-roots))
   $js-repl-node-module-dirs)

(= (codex:config-overrides-zsh-path
      (CodexConfigOverrides
        
$model        $review-model        $cwd        $approval-policy        $approvals-reviewer        $sandbox-mode        $permission-profile        $model-provider        $service-tier        $config-profile        $codex-self-exe        $codex-linux-sandbox-exe        $main-execve-wrapper-exe        $js-repl-node-path        $js-repl-node-module-dirs        $zsh-path        $base-instructions        $developer-instructions        $personality        $compact-prompt        $include-apply-patch-tool        $show-raw-agent-reasoning        $tools-web-search-request        $ephemeral        $additional-writable-roots))
   $zsh-path)

(= (codex:config-overrides-base-instructions
      (CodexConfigOverrides
        
$model        $review-model        $cwd        $approval-policy        $approvals-reviewer        $sandbox-mode        $permission-profile        $model-provider        $service-tier        $config-profile        $codex-self-exe        $codex-linux-sandbox-exe        $main-execve-wrapper-exe        $js-repl-node-path        $js-repl-node-module-dirs        $zsh-path        $base-instructions        $developer-instructions        $personality        $compact-prompt        $include-apply-patch-tool        $show-raw-agent-reasoning        $tools-web-search-request        $ephemeral        $additional-writable-roots))
   $base-instructions)

(= (codex:config-overrides-developer-instructions
      (CodexConfigOverrides
        
$model        $review-model        $cwd        $approval-policy        $approvals-reviewer        $sandbox-mode        $permission-profile        $model-provider        $service-tier        $config-profile        $codex-self-exe        $codex-linux-sandbox-exe        $main-execve-wrapper-exe        $js-repl-node-path        $js-repl-node-module-dirs        $zsh-path        $base-instructions        $developer-instructions        $personality        $compact-prompt        $include-apply-patch-tool        $show-raw-agent-reasoning        $tools-web-search-request        $ephemeral        $additional-writable-roots))
   $developer-instructions)

(= (codex:config-overrides-personality
      (CodexConfigOverrides
        
$model        $review-model        $cwd        $approval-policy        $approvals-reviewer        $sandbox-mode        $permission-profile        $model-provider        $service-tier        $config-profile        $codex-self-exe        $codex-linux-sandbox-exe        $main-execve-wrapper-exe        $js-repl-node-path        $js-repl-node-module-dirs        $zsh-path        $base-instructions        $developer-instructions        $personality        $compact-prompt        $include-apply-patch-tool        $show-raw-agent-reasoning        $tools-web-search-request        $ephemeral        $additional-writable-roots))
   $personality)

(= (codex:config-overrides-compact-prompt
      (CodexConfigOverrides
        
$model        $review-model        $cwd        $approval-policy        $approvals-reviewer        $sandbox-mode        $permission-profile        $model-provider        $service-tier        $config-profile        $codex-self-exe        $codex-linux-sandbox-exe        $main-execve-wrapper-exe        $js-repl-node-path        $js-repl-node-module-dirs        $zsh-path        $base-instructions        $developer-instructions        $personality        $compact-prompt        $include-apply-patch-tool        $show-raw-agent-reasoning        $tools-web-search-request        $ephemeral        $additional-writable-roots))
   $compact-prompt)

(= (codex:config-overrides-include-apply-patch-tool
      (CodexConfigOverrides
        
$model        $review-model        $cwd        $approval-policy        $approvals-reviewer        $sandbox-mode        $permission-profile        $model-provider        $service-tier        $config-profile        $codex-self-exe        $codex-linux-sandbox-exe        $main-execve-wrapper-exe        $js-repl-node-path        $js-repl-node-module-dirs        $zsh-path        $base-instructions        $developer-instructions        $personality        $compact-prompt        $include-apply-patch-tool        $show-raw-agent-reasoning        $tools-web-search-request        $ephemeral        $additional-writable-roots))
   $include-apply-patch-tool)

(= (codex:config-overrides-show-raw-agent-reasoning
      (CodexConfigOverrides
        
$model        $review-model        $cwd        $approval-policy        $approvals-reviewer        $sandbox-mode        $permission-profile        $model-provider        $service-tier        $config-profile        $codex-self-exe        $codex-linux-sandbox-exe        $main-execve-wrapper-exe        $js-repl-node-path        $js-repl-node-module-dirs        $zsh-path        $base-instructions        $developer-instructions        $personality        $compact-prompt        $include-apply-patch-tool        $show-raw-agent-reasoning        $tools-web-search-request        $ephemeral        $additional-writable-roots))
   $show-raw-agent-reasoning)

(= (codex:config-overrides-tools-web-search-request
      (CodexConfigOverrides
        
$model        $review-model        $cwd        $approval-policy        $approvals-reviewer        $sandbox-mode        $permission-profile        $model-provider        $service-tier        $config-profile        $codex-self-exe        $codex-linux-sandbox-exe        $main-execve-wrapper-exe        $js-repl-node-path        $js-repl-node-module-dirs        $zsh-path        $base-instructions        $developer-instructions        $personality        $compact-prompt        $include-apply-patch-tool        $show-raw-agent-reasoning        $tools-web-search-request        $ephemeral        $additional-writable-roots))
   $tools-web-search-request)

(= (codex:config-overrides-ephemeral
      (CodexConfigOverrides
        
$model        $review-model        $cwd        $approval-policy        $approvals-reviewer        $sandbox-mode        $permission-profile        $model-provider        $service-tier        $config-profile        $codex-self-exe        $codex-linux-sandbox-exe        $main-execve-wrapper-exe        $js-repl-node-path        $js-repl-node-module-dirs        $zsh-path        $base-instructions        $developer-instructions        $personality        $compact-prompt        $include-apply-patch-tool        $show-raw-agent-reasoning        $tools-web-search-request        $ephemeral        $additional-writable-roots))
   $ephemeral)

(= (codex:config-overrides-additional-writable-roots
      (CodexConfigOverrides
        
$model        $review-model        $cwd        $approval-policy        $approvals-reviewer        $sandbox-mode        $permission-profile        $model-provider        $service-tier        $config-profile        $codex-self-exe        $codex-linux-sandbox-exe        $main-execve-wrapper-exe        $js-repl-node-path        $js-repl-node-module-dirs        $zsh-path        $base-instructions        $developer-instructions        $personality        $compact-prompt        $include-apply-patch-tool        $show-raw-agent-reasoning        $tools-web-search-request        $ephemeral        $additional-writable-roots))
   $additional-writable-roots)
