; Narrow Rust-faithful tool-config slice for the restarted Codex port.
;
; This ports the currently consumed subset from:
; - openai-codex/codex-rs/tools/src/tool_config.rs
;
; Covered in this increment:
; - ConfigShellToolType / ApplyPatchToolType / WindowsSandboxLevel subset
; - the ToolsConfig data shape subset currently consumed by the local registry
; - shell backend and shell type selection
; - apply_patch tool type selection
; - request_permissions / request_user_input feature gating fields
; - view_image original-detail capability wiring
; - UnifiedExecShellMode::for_session branch selection
; - builder-style `with_*` helpers used by Rust tests and callers
;
; Required slice-local deviations from Rust, documented for later audit:
; - The restarted CeTTa port does not yet have the full `Features`,
;   `ModelInfo`, `SessionSource`, `WebSearch*`, image-generation, or
;   collaboration-tool stack. This slice therefore ports only the fields and
;   constructor parameters that affect the currently executable tool subset.
; - Rust's `ToolsConfig::new()` consults `codex_utils_pty::conpty_supported()`
;   when choosing UnifiedExec on Windows. The current CeTTa slice has no
;   equivalent host probe, so the constructor follows the Rust branch structure
;   but assumes the non-ConPTY fallback question is out of scope for this
;   restart subset.
; - Rust gates `UnifiedExecShellMode::for_session()` with `cfg!(unix)`. This
;   pure CeTTa helper accepts that platform branch as an explicit boolean so
;   tests can cover both sides without changing the branch condition.

!(import! &self image_detail)
!(import! &self path)

(= (codex:config-shell-tool-type-default)
   "Default")

(= (codex:config-shell-tool-type-local)
   "Local")

(= (codex:config-shell-tool-type-unified-exec)
   "UnifiedExec")

(= (codex:config-shell-tool-type-disabled)
   "Disabled")

(= (codex:config-shell-tool-type-shell-command)
   "ShellCommand")

(= (codex:apply-patch-tool-type-freeform)
   "Freeform")

(= (codex:apply-patch-tool-type-function)
   "Function")

(= (codex:shell-command-backend-config-classic)
   "Classic")

(= (codex:shell-command-backend-config-zsh-fork)
   "ZshFork")

(= (codex:unified-exec-shell-mode-direct)
   "Direct")

(= (codex:unified-exec-shell-mode-zsh-fork
      $shell-zsh-path
      $main-execve-wrapper-exe)
   (CodexUnifiedExecShellModeZshFork
     $shell-zsh-path
     $main-execve-wrapper-exe))

(= (codex:tool-user-shell-type-zsh)
   (CodexToolUserShellTypeZsh))

(= (codex:tool-user-shell-type-bash)
   (CodexToolUserShellTypeBash))

(= (codex:tool-user-shell-type-powershell)
   (CodexToolUserShellTypePowerShell))

(= (codex:tool-user-shell-type-sh)
   (CodexToolUserShellTypeSh))

(= (codex:tool-user-shell-type-cmd)
   (CodexToolUserShellTypeCmd))

(= (codex:tool-config-sandbox-policy-danger-full-access)
   "DangerFullAccess")

(= (codex:tool-config-sandbox-policy-external-sandbox)
   "ExternalSandbox")

(= (codex:tool-config-sandbox-policy-workspace-write)
   "WorkspaceWrite")

(= (codex:tool-config-sandbox-policy-read-only)
   "ReadOnly")

(= (codex:windows-sandbox-level-disabled)
   "Disabled")

(= (codex:windows-sandbox-level-restricted-token)
   "RestrictedToken")

(= (codex:windows-sandbox-level-elevated)
   "Elevated")

(= (codex:tool-config-model-info
      $shell-type
      $apply-patch-tool-type
      $experimental-supported-tools
      $can-request-original-image-detail)
   (CodexToolConfigModelInfo
     $shell-type
     $apply-patch-tool-type
     $experimental-supported-tools
     $can-request-original-image-detail))

(= (codex:tool-config-features
      $shell-tool
      $unified-exec
      $shell-zsh-fork
      $apply-patch-freeform
      $exec-permission-approvals
      $request-permissions-tool
      $default-mode-request-user-input)
   (CodexToolConfigFeatures
     $shell-tool
     $unified-exec
     $shell-zsh-fork
     $apply-patch-freeform
     $exec-permission-approvals
     $request-permissions-tool
     $default-mode-request-user-input))

(= (codex:default-tool-config-features)
   (codex:tool-config-features
     False
     False
     False
     False
     False
     False
     False))

(= (codex:tools-config-new-params
      $model-info
      $features
      $is-windows
      $sandbox-policy
      $windows-sandbox-level)
   (CodexToolsConfigNewParams
     $model-info
     $features
     $is-windows
     $sandbox-policy
     $windows-sandbox-level))

(= (codex:tools-config
      $shell-type
      $shell-command-backend
      $unified-exec-shell-mode
      $has-environment
      $allow-login-shell
      $apply-patch-tool-type
      $exec-permission-approvals-enabled
      $request-permissions-tool-enabled
      $default-mode-request-user-input
      $experimental-supported-tools
      $can-request-original-image-detail)
   (CodexToolsConfig
     $shell-type
     $shell-command-backend
     $unified-exec-shell-mode
     $has-environment
     $allow-login-shell
     $apply-patch-tool-type
     $exec-permission-approvals-enabled
     $request-permissions-tool-enabled
     $default-mode-request-user-input
     $experimental-supported-tools
     $can-request-original-image-detail))

(= (codex:tool-config-model-info-shell-type
      (CodexToolConfigModelInfo
        $shell-type
        $apply-patch-tool-type
        $experimental-supported-tools
        $can-request-original-image-detail))
   $shell-type)

(= (codex:tool-config-model-info-apply-patch-tool-type
      (CodexToolConfigModelInfo
        $shell-type
        $apply-patch-tool-type
        $experimental-supported-tools
        $can-request-original-image-detail))
   $apply-patch-tool-type)

(= (codex:tool-config-model-info-experimental-supported-tools
      (CodexToolConfigModelInfo
        $shell-type
        $apply-patch-tool-type
        $experimental-supported-tools
        $can-request-original-image-detail))
   $experimental-supported-tools)

(= (codex:tool-config-model-info-can-request-original-image-detail
      (CodexToolConfigModelInfo
        $shell-type
        $apply-patch-tool-type
        $experimental-supported-tools
        $can-request-original-image-detail))
   $can-request-original-image-detail)

(= (codex:tool-config-features-shell-tool
      (CodexToolConfigFeatures
        $shell-tool
        $unified-exec
        $shell-zsh-fork
        $apply-patch-freeform
        $exec-permission-approvals
        $request-permissions-tool
        $default-mode-request-user-input))
   $shell-tool)

(= (codex:tool-config-features-unified-exec
      (CodexToolConfigFeatures
        $shell-tool
        $unified-exec
        $shell-zsh-fork
        $apply-patch-freeform
        $exec-permission-approvals
        $request-permissions-tool
        $default-mode-request-user-input))
   $unified-exec)

(= (codex:tool-config-features-shell-zsh-fork
      (CodexToolConfigFeatures
        $shell-tool
        $unified-exec
        $shell-zsh-fork
        $apply-patch-freeform
        $exec-permission-approvals
        $request-permissions-tool
        $default-mode-request-user-input))
   $shell-zsh-fork)

(= (codex:tool-config-features-apply-patch-freeform
      (CodexToolConfigFeatures
        $shell-tool
        $unified-exec
        $shell-zsh-fork
        $apply-patch-freeform
        $exec-permission-approvals
        $request-permissions-tool
        $default-mode-request-user-input))
   $apply-patch-freeform)

(= (codex:tool-config-features-exec-permission-approvals
      (CodexToolConfigFeatures
        $shell-tool
        $unified-exec
        $shell-zsh-fork
        $apply-patch-freeform
        $exec-permission-approvals
        $request-permissions-tool
        $default-mode-request-user-input))
   $exec-permission-approvals)

(= (codex:tool-config-features-request-permissions-tool
      (CodexToolConfigFeatures
        $shell-tool
        $unified-exec
        $shell-zsh-fork
        $apply-patch-freeform
        $exec-permission-approvals
        $request-permissions-tool
        $default-mode-request-user-input))
   $request-permissions-tool)

(= (codex:tool-config-features-default-mode-request-user-input
      (CodexToolConfigFeatures
        $shell-tool
        $unified-exec
        $shell-zsh-fork
        $apply-patch-freeform
        $exec-permission-approvals
        $request-permissions-tool
        $default-mode-request-user-input))
   $default-mode-request-user-input)

(= (codex:tools-config-new-params-model-info
      (CodexToolsConfigNewParams
        $model-info
        $features
        $is-windows
        $sandbox-policy
        $windows-sandbox-level))
   $model-info)

(= (codex:tools-config-new-params-features
      (CodexToolsConfigNewParams
        $model-info
        $features
        $is-windows
        $sandbox-policy
        $windows-sandbox-level))
   $features)

(= (codex:tools-config-new-params-is-windows
      (CodexToolsConfigNewParams
        $model-info
        $features
        $is-windows
        $sandbox-policy
        $windows-sandbox-level))
   $is-windows)

(= (codex:tools-config-new-params-sandbox-policy
      (CodexToolsConfigNewParams
        $model-info
        $features
        $is-windows
        $sandbox-policy
        $windows-sandbox-level))
   $sandbox-policy)

(= (codex:tools-config-new-params-windows-sandbox-level
      (CodexToolsConfigNewParams
        $model-info
        $features
        $is-windows
        $sandbox-policy
        $windows-sandbox-level))
   $windows-sandbox-level)

(= (codex:tools-config-shell-type
      (CodexToolsConfig
        $shell-type
        $shell-command-backend
        $unified-exec-shell-mode
        $has-environment
        $allow-login-shell
        $apply-patch-tool-type
        $exec-permission-approvals-enabled
        $request-permissions-tool-enabled
        $default-mode-request-user-input
        $experimental-supported-tools
        $can-request-original-image-detail))
   $shell-type)

(= (codex:tools-config-shell-command-backend
      (CodexToolsConfig
        $shell-type
        $shell-command-backend
        $unified-exec-shell-mode
        $has-environment
        $allow-login-shell
        $apply-patch-tool-type
        $exec-permission-approvals-enabled
        $request-permissions-tool-enabled
        $default-mode-request-user-input
        $experimental-supported-tools
        $can-request-original-image-detail))
   $shell-command-backend)

(= (codex:tools-config-unified-exec-shell-mode
      (CodexToolsConfig
        $shell-type
        $shell-command-backend
        $unified-exec-shell-mode
        $has-environment
        $allow-login-shell
        $apply-patch-tool-type
        $exec-permission-approvals-enabled
        $request-permissions-tool-enabled
        $default-mode-request-user-input
        $experimental-supported-tools
        $can-request-original-image-detail))
   $unified-exec-shell-mode)

(= (codex:tools-config-has-environment
      (CodexToolsConfig
        $shell-type
        $shell-command-backend
        $unified-exec-shell-mode
        $has-environment
        $allow-login-shell
        $apply-patch-tool-type
        $exec-permission-approvals-enabled
        $request-permissions-tool-enabled
        $default-mode-request-user-input
        $experimental-supported-tools
        $can-request-original-image-detail))
   $has-environment)

(= (codex:tools-config-allow-login-shell
      (CodexToolsConfig
        $shell-type
        $shell-command-backend
        $unified-exec-shell-mode
        $has-environment
        $allow-login-shell
        $apply-patch-tool-type
        $exec-permission-approvals-enabled
        $request-permissions-tool-enabled
        $default-mode-request-user-input
        $experimental-supported-tools
        $can-request-original-image-detail))
   $allow-login-shell)

(= (codex:tools-config-apply-patch-tool-type
      (CodexToolsConfig
        $shell-type
        $shell-command-backend
        $unified-exec-shell-mode
        $has-environment
        $allow-login-shell
        $apply-patch-tool-type
        $exec-permission-approvals-enabled
        $request-permissions-tool-enabled
        $default-mode-request-user-input
        $experimental-supported-tools
        $can-request-original-image-detail))
   (if (== $apply-patch-tool-type CodexAbsent)
       Empty
       $apply-patch-tool-type))

(= (codex:tools-config-exec-permission-approvals-enabled
      (CodexToolsConfig
        $shell-type
        $shell-command-backend
        $unified-exec-shell-mode
        $has-environment
        $allow-login-shell
        $apply-patch-tool-type
        $exec-permission-approvals-enabled
        $request-permissions-tool-enabled
        $default-mode-request-user-input
        $experimental-supported-tools
        $can-request-original-image-detail))
   $exec-permission-approvals-enabled)

(= (codex:tools-config-request-permissions-tool-enabled
      (CodexToolsConfig
        $shell-type
        $shell-command-backend
        $unified-exec-shell-mode
        $has-environment
        $allow-login-shell
        $apply-patch-tool-type
        $exec-permission-approvals-enabled
        $request-permissions-tool-enabled
        $default-mode-request-user-input
        $experimental-supported-tools
        $can-request-original-image-detail))
   $request-permissions-tool-enabled)

(= (codex:tools-config-default-mode-request-user-input
      (CodexToolsConfig
        $shell-type
        $shell-command-backend
        $unified-exec-shell-mode
        $has-environment
        $allow-login-shell
        $apply-patch-tool-type
        $exec-permission-approvals-enabled
        $request-permissions-tool-enabled
        $default-mode-request-user-input
        $experimental-supported-tools
        $can-request-original-image-detail))
   $default-mode-request-user-input)

(= (codex:tools-config-experimental-supported-tools
      (CodexToolsConfig
        $shell-type
        $shell-command-backend
        $unified-exec-shell-mode
        $has-environment
        $allow-login-shell
        $apply-patch-tool-type
        $exec-permission-approvals-enabled
        $request-permissions-tool-enabled
        $default-mode-request-user-input
        $experimental-supported-tools
        $can-request-original-image-detail))
   $experimental-supported-tools)

(= (codex:tools-config-can-request-original-image-detail
      (CodexToolsConfig
        $shell-type
        $shell-command-backend
        $unified-exec-shell-mode
        $has-environment
        $allow-login-shell
        $apply-patch-tool-type
        $exec-permission-approvals-enabled
        $request-permissions-tool-enabled
        $default-mode-request-user-input
        $experimental-supported-tools
        $can-request-original-image-detail))
   $can-request-original-image-detail)

(= (codex:tools-config-with-has-environment
      (CodexToolsConfig
        $shell-type
        $shell-command-backend
        $unified-exec-shell-mode
        $has-environment
        $allow-login-shell
        $apply-patch-tool-type
        $exec-permission-approvals-enabled
        $request-permissions-tool-enabled
        $default-mode-request-user-input
        $experimental-supported-tools
        $can-request-original-image-detail)
      $next-has-environment)
   (codex:tools-config
     $shell-type
     $shell-command-backend
     $unified-exec-shell-mode
     $next-has-environment
     $allow-login-shell
     $apply-patch-tool-type
     $exec-permission-approvals-enabled
     $request-permissions-tool-enabled
     $default-mode-request-user-input
     $experimental-supported-tools
     $can-request-original-image-detail))

(= (codex:tools-config-with-allow-login-shell
      (CodexToolsConfig
        $shell-type
        $shell-command-backend
        $unified-exec-shell-mode
        $has-environment
        $allow-login-shell
        $apply-patch-tool-type
        $exec-permission-approvals-enabled
        $request-permissions-tool-enabled
        $default-mode-request-user-input
        $experimental-supported-tools
        $can-request-original-image-detail)
      $next-allow-login-shell)
   (codex:tools-config
     $shell-type
     $shell-command-backend
     $unified-exec-shell-mode
     $has-environment
     $next-allow-login-shell
     $apply-patch-tool-type
     $exec-permission-approvals-enabled
     $request-permissions-tool-enabled
     $default-mode-request-user-input
     $experimental-supported-tools
     $can-request-original-image-detail))

(= (codex:unified-exec-shell-mode-for-session
      $is-unix
      $shell-command-backend
      $user-shell-type
      $shell-zsh-path
      $main-execve-wrapper-exe)
   (if (and
         $is-unix
         (and
           (==
             $shell-command-backend
             (codex:shell-command-backend-config-zsh-fork))
           (and
             (== $user-shell-type (codex:tool-user-shell-type-zsh))
             (and
               (not (== $shell-zsh-path CodexAbsent))
               (and
                 (not (== $main-execve-wrapper-exe CodexAbsent))
                 (and
                   (path-is-absolute? $shell-zsh-path)
                   (path-is-absolute? $main-execve-wrapper-exe)))))))
       (codex:unified-exec-shell-mode-zsh-fork
         (path-normalize $shell-zsh-path)
         (path-normalize $main-execve-wrapper-exe))
       (codex:unified-exec-shell-mode-direct)))

(= (codex:tools-config-with-unified-exec-shell-mode
      (CodexToolsConfig
        $shell-type
        $shell-command-backend
        $unified-exec-shell-mode
        $has-environment
        $allow-login-shell
        $apply-patch-tool-type
        $exec-permission-approvals-enabled
        $request-permissions-tool-enabled
        $default-mode-request-user-input
        $experimental-supported-tools
        $can-request-original-image-detail)
      $next-unified-exec-shell-mode)
   (codex:tools-config
     $shell-type
     $shell-command-backend
     $next-unified-exec-shell-mode
     $has-environment
     $allow-login-shell
     $apply-patch-tool-type
     $exec-permission-approvals-enabled
     $request-permissions-tool-enabled
     $default-mode-request-user-input
     $experimental-supported-tools
     $can-request-original-image-detail))

(= (codex:tools-config-with-unified-exec-shell-mode-for-session
      $config
      $is-unix
      $user-shell-type
      $shell-zsh-path
      $main-execve-wrapper-exe)
   (codex:tools-config-with-unified-exec-shell-mode
     $config
     (codex:unified-exec-shell-mode-for-session
       $is-unix
       (codex:tools-config-shell-command-backend $config)
       $user-shell-type
       $shell-zsh-path
       $main-execve-wrapper-exe)))

(= (codex:is-unrestricted-tool-config-sandbox-policy $policy)
   (if (== $policy (codex:tool-config-sandbox-policy-danger-full-access))
       True
       (if (== $policy (codex:tool-config-sandbox-policy-external-sandbox))
           True
           False)))

(= (codex:unified-exec-allowed-in-environment
      $is-windows
      $sandbox-policy
      $windows-sandbox-level)
   (not
     (and
       $is-windows
       (and
         (not (== $windows-sandbox-level (codex:windows-sandbox-level-disabled)))
         (not (codex:is-unrestricted-tool-config-sandbox-policy $sandbox-policy))))))

(= (codex:resolved-shell-command-backend $features)
   (if (and
         (codex:tool-config-features-shell-tool $features)
         (codex:tool-config-features-shell-zsh-fork $features))
       (codex:shell-command-backend-config-zsh-fork)
       (codex:shell-command-backend-config-classic)))

(= (codex:resolved-tools-config-shell-type $params)
   (let $features (codex:tools-config-new-params-features $params)
     (let $model-info (codex:tools-config-new-params-model-info $params)
       (if (not (codex:tool-config-features-shell-tool $features))
           (codex:config-shell-tool-type-disabled)
           (if (codex:tool-config-features-shell-zsh-fork $features)
               (codex:config-shell-tool-type-shell-command)
               (if (and
                     (codex:tool-config-features-unified-exec $features)
                     (codex:unified-exec-allowed-in-environment
                       (codex:tools-config-new-params-is-windows $params)
                       (codex:tools-config-new-params-sandbox-policy $params)
                       (codex:tools-config-new-params-windows-sandbox-level $params)))
                   (codex:config-shell-tool-type-unified-exec)
                   (if (and
                         (==
                           (codex:tool-config-model-info-shell-type $model-info)
                           (codex:config-shell-tool-type-unified-exec))
                         (not
                           (codex:unified-exec-allowed-in-environment
                             (codex:tools-config-new-params-is-windows $params)
                             (codex:tools-config-new-params-sandbox-policy $params)
                             (codex:tools-config-new-params-windows-sandbox-level $params))))
                       (codex:config-shell-tool-type-shell-command)
                       (codex:tool-config-model-info-shell-type $model-info))))))))

(= (codex:resolved-tools-config-apply-patch-tool-type $params)
   (let $model-apply-patch-tool-type
     (codex:tool-config-model-info-apply-patch-tool-type
       (codex:tools-config-new-params-model-info $params))
     (if (== $model-apply-patch-tool-type CodexAbsent)
         (if
           (codex:tool-config-features-apply-patch-freeform
             (codex:tools-config-new-params-features $params))
           (codex:apply-patch-tool-type-freeform)
           CodexAbsent)
         $model-apply-patch-tool-type)))

(= (codex:tools-config-new
      (CodexToolsConfigNewParams
        $model-info
        $features
        $is-windows
        $sandbox-policy
        $windows-sandbox-level))
   (codex:tools-config
     (codex:resolved-tools-config-shell-type
       (codex:tools-config-new-params
         $model-info
         $features
         $is-windows
         $sandbox-policy
         $windows-sandbox-level))
     (codex:resolved-shell-command-backend $features)
     (codex:unified-exec-shell-mode-direct)
     True
     True
     (codex:resolved-tools-config-apply-patch-tool-type
       (codex:tools-config-new-params
         $model-info
         $features
         $is-windows
         $sandbox-policy
         $windows-sandbox-level))
     (codex:tool-config-features-exec-permission-approvals $features)
     (codex:tool-config-features-request-permissions-tool $features)
     (codex:tool-config-features-default-mode-request-user-input $features)
     (codex:tool-config-model-info-experimental-supported-tools $model-info)
     (codex:can-request-original-image-detail $model-info)))

(= (codex:default-tools-config)
   (codex:tools-config-new
     (codex:tools-config-new-params
       (codex:tool-config-model-info
         (codex:config-shell-tool-type-unified-exec)
         CodexAbsent
         ()
         False)
       (codex:tool-config-features
         True
         True
         False
         True
         False
         False
         False)
       False
       (codex:tool-config-sandbox-policy-danger-full-access)
       (codex:windows-sandbox-level-disabled))))
