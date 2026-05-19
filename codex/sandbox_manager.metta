; Rust-faithful pure sandbox-manager selection slice.
;
; This ports deterministic sandbox selection behavior from:
; - openai-codex/codex-rs/sandboxing/src/manager.rs
; - openai-codex/codex-rs/sandboxing/src/policy_transforms.rs
;   - `should_require_platform_sandbox`
;
; Covered in this increment:
; - `SandboxManager::new`
; - `SandboxManager::select_initial`
; - `should_require_platform_sandbox`
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust's `get_platform_sandbox()` uses compile-time target cfg. The existing
;   CeTTa sandbox tag slice already ports this as an explicit host-platform
;   argument, so `select_initial` carries the same explicit platform argument.
; - This slice only ports selection. `SandboxManager::transform` is a separate
;   command/materialization boundary and is intentionally not approximated here.

!(import! &self permissions)
!(import! &self sandbox_tags)
!(import! &self tool_config)
!(import! &self tool_sandboxing)

(= (codex:sandbox-manager-new)
   (CodexSandboxManager))

(= (codex:sandbox-manager-windows-sandbox-enabled
      $windows-sandbox-level)
   (not (== $windows-sandbox-level
            (codex:windows-sandbox-level-disabled))))

(= (codex:sandbox-manager-platform-sandbox-or-none
      $host-platform
      $windows-sandbox-level)
   (let $platform-sandbox
     (codex:get-platform-sandbox
       $host-platform
       (codex:sandbox-manager-windows-sandbox-enabled
         $windows-sandbox-level))
     (if (== $platform-sandbox CodexAbsent)
         (codex:sandbox-type-none)
         $platform-sandbox)))

(= (codex:should-require-platform-sandbox
      $file-system-policy
      $network-policy
      $has-managed-network-requirements)
   (if $has-managed-network-requirements
       True
       (if (not (codex:network-sandbox-policy-is-enabled $network-policy))
           (not
             (==
               (codex:file-system-sandbox-policy-kind $file-system-policy)
               (CodexFileSystemSandboxKindExternalSandbox)))
           (if (==
                 (codex:file-system-sandbox-policy-kind $file-system-policy)
                 (CodexFileSystemSandboxKindRestricted))
               (not
                 (codex:file-system-sandbox-policy-has-full-disk-write-access
                   $file-system-policy))
               False))))

(= (codex:sandbox-manager-select-initial
      (CodexSandboxManager)
      $file-system-policy
      $network-policy
      (CodexSandboxablePreferenceForbid)
      $windows-sandbox-level
      $has-managed-network-requirements
      $host-platform)
   (codex:sandbox-type-none))

(= (codex:sandbox-manager-select-initial
      (CodexSandboxManager)
      $file-system-policy
      $network-policy
      (CodexSandboxablePreferenceRequire)
      $windows-sandbox-level
      $has-managed-network-requirements
      $host-platform)
   (codex:sandbox-manager-platform-sandbox-or-none
     $host-platform
     $windows-sandbox-level))

(= (codex:sandbox-manager-select-initial
      (CodexSandboxManager)
      $file-system-policy
      $network-policy
      (CodexSandboxablePreferenceAuto)
      $windows-sandbox-level
      $has-managed-network-requirements
      $host-platform)
   (if (codex:should-require-platform-sandbox
         $file-system-policy
         $network-policy
         $has-managed-network-requirements)
       (codex:sandbox-manager-platform-sandbox-or-none
         $host-platform
         $windows-sandbox-level)
       (codex:sandbox-type-none)))
