!(register-module! ../codex)
!(import! &self codex:sandbox_tags)

!(assertEqualToResult
  (codex:sandbox-type-as-metric-tag
    (codex:sandbox-type-macos-seatbelt))
  ("seatbelt"))

!(assertEqualToResult
  (codex:get-platform-sandbox
    (codex:host-platform-linux)
    False)
  ("LinuxSeccomp"))

!(assertEqualToResult
  (codex:get-platform-sandbox
    (codex:host-platform-windows)
    False)
  (CodexAbsent))

!(assertEqualToResult
  (codex:sandbox-tag
    (codex:tool-config-sandbox-policy-danger-full-access)
    (codex:windows-sandbox-level-disabled)
    (codex:host-platform-linux))
  ("none"))

!(assertEqualToResult
  (codex:sandbox-tag
    (codex:tool-config-sandbox-policy-external-sandbox)
    (codex:windows-sandbox-level-disabled)
    (codex:host-platform-linux))
  ("external"))

!(assertEqualToResult
  (codex:sandbox-tag
    (codex:tool-config-sandbox-policy-read-only)
    (codex:windows-sandbox-level-disabled)
    (codex:host-platform-linux))
  ("seccomp"))

!(assertEqualToResult
  (codex:sandbox-tag
    (codex:tool-config-sandbox-policy-read-only)
    (codex:windows-sandbox-level-elevated)
    (codex:host-platform-windows))
  ("windows_elevated"))

!(assertEqualToResult
  (codex:sandbox-tag
    (codex:tool-config-sandbox-policy-read-only)
    (codex:windows-sandbox-level-restricted-token)
    (codex:host-platform-windows))
  ("windows_sandbox"))

!(assertEqualToResult
  (codex:sandbox-tag
    (codex:tool-config-sandbox-policy-read-only)
    (codex:windows-sandbox-level-disabled)
    (codex:host-platform-other))
  ("none"))
