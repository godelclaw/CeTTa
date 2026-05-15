; Narrow Rust-faithful sandbox-tags slice for the restarted Codex port.
;
; This ports:
; - openai-codex/codex-rs/core/src/sandbox_tags.rs
; - the narrow `SandboxType::as_metric_tag()` / `get_platform_sandbox()`
;   helper surface it depends on
;
; Required slice-local deviation from Rust, documented for later audit:
; - Rust uses `cfg!(target_os = ...)` inside `get_platform_sandbox()`. The
;   current CeTTa restart surface has no compile-target reflection primitive,
;   so callers pass an explicit host-platform tag (`macos`, `linux`,
;   `windows`, or `other`) into this helper layer. For a given platform tag,
;   the visible branch behavior matches the Rust code.

!(import! &self tool_config)

(= (codex:host-platform-macos)
   "macos")

(= (codex:host-platform-linux)
   "linux")

(= (codex:host-platform-windows)
   "windows")

(= (codex:host-platform-other)
   "other")

(= (codex:sandbox-type-none)
   "None")

(= (codex:sandbox-type-macos-seatbelt)
   "MacosSeatbelt")

(= (codex:sandbox-type-linux-seccomp)
   "LinuxSeccomp")

(= (codex:sandbox-type-windows-restricted-token)
   "WindowsRestrictedToken")

(= (codex:sandbox-type-as-metric-tag $sandbox-type)
   (if (== $sandbox-type (codex:sandbox-type-none))
       "none"
       (if (== $sandbox-type (codex:sandbox-type-macos-seatbelt))
           "seatbelt"
           (if (== $sandbox-type (codex:sandbox-type-linux-seccomp))
               "seccomp"
               (if (== $sandbox-type (codex:sandbox-type-windows-restricted-token))
                   "windows_sandbox"
                   "none")))))

(= (codex:get-platform-sandbox $host-platform $windows-sandbox-enabled)
   (if (== $host-platform (codex:host-platform-macos))
       (codex:sandbox-type-macos-seatbelt)
       (if (== $host-platform (codex:host-platform-linux))
           (codex:sandbox-type-linux-seccomp)
           (if (== $host-platform (codex:host-platform-windows))
               (if $windows-sandbox-enabled
                   (codex:sandbox-type-windows-restricted-token)
                   CodexAbsent)
               CodexAbsent))))

(= (codex:sandbox-tag $policy $windows-sandbox-level $host-platform)
   (if (== $policy (codex:tool-config-sandbox-policy-danger-full-access))
       "none"
       (if (== $policy (codex:tool-config-sandbox-policy-external-sandbox))
           "external"
           (if (and
                 (== $host-platform (codex:host-platform-windows))
                 (== $windows-sandbox-level (codex:windows-sandbox-level-elevated)))
               "windows_elevated"
               (let $platform-sandbox
                 (codex:get-platform-sandbox
                   $host-platform
                   (not (== $windows-sandbox-level
                             (codex:windows-sandbox-level-disabled))))
                 (if (== $platform-sandbox CodexAbsent)
                     "none"
                     (codex:sandbox-type-as-metric-tag $platform-sandbox)))))))
