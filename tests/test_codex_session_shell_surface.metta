!(register-module! ../codex)
!(import! &self codex:session_shell)
!(import! &self codex:tool_config)

!(assertEqualToResult
  (codex:shell-name
    (codex:shell-without-snapshot
      (codex:shell-type-zsh)
      "/bin/zsh"))
  ("zsh"))

!(assertEqualToResult
  (codex:shell-shell-type
    (codex:shell-without-snapshot
      (codex:shell-type-bash)
      "/bin/bash"))
  ("Bash"))

!(assertEqualToResult
  (codex:shell-shell-path
    (codex:shell-without-snapshot
      (codex:shell-type-bash)
      "/bin/bash"))
  ("/bin/bash"))

!(assertEqualToResult
  (codex:shell-shell-snapshot
    (codex:shell-without-snapshot
      (codex:shell-type-bash)
      "/bin/bash"))
  (CodexAbsent))

!(assertEqualToResult
  (codex:normalize-shell-type "pwsh")
  ("PowerShell"))

!(assertEqualToResult
  (codex:shell-derive-exec-args
    (codex:shell-without-snapshot
      (codex:shell-type-bash)
      "/bin/bash")
    "echo ok"
    True)
  (("/bin/bash" "-lc" "echo ok")))

!(assertEqualToResult
  (codex:shell-derive-exec-args
    (codex:shell-without-snapshot
      (codex:shell-type-sh)
      "/bin/sh")
    "echo ok"
    False)
  (("/bin/sh" "-c" "echo ok")))

!(assertEqualToResult
  (codex:shell-derive-exec-args
    (codex:shell-without-snapshot
      (codex:shell-type-powershell)
      "pwsh")
    "Write-Host ok"
    True)
  (("pwsh" "-Command" "Write-Host ok")))

!(assertEqualToResult
  (codex:shell-derive-exec-args
    (codex:shell-without-snapshot
      (codex:shell-type-powershell)
      "pwsh")
    "Write-Host ok"
    False)
  (("pwsh" "-NoProfile" "-Command" "Write-Host ok")))

!(assertEqualToResult
  (codex:shell-derive-exec-args
    (codex:shell-without-snapshot
      (codex:shell-type-cmd)
      "cmd")
    "echo ok"
    True)
  (("cmd" "/c" "echo ok")))

!(assertEqualToResult
  (codex:tool-user-shell-type
    (codex:shell-without-snapshot
      (codex:shell-type-zsh)
      "/bin/zsh"))
  ((CodexToolUserShellTypeZsh)))

!(assertEqualToResult
  (codex:tool-user-shell-type
    (codex:shell-without-snapshot
      (codex:shell-type-bash)
      "/bin/bash"))
  ((CodexToolUserShellTypeBash)))

!(assertEqualToResult
  (codex:tool-user-shell-type
    (codex:shell-without-snapshot
      (codex:shell-type-powershell)
      "pwsh"))
  ((CodexToolUserShellTypePowerShell)))

!(assertEqualToResult
  (codex:tool-user-shell-type
    (codex:shell-without-snapshot
      (codex:shell-type-sh)
      "/bin/sh"))
  ((CodexToolUserShellTypeSh)))

!(assertEqualToResult
  (codex:tool-user-shell-type
    (codex:shell-without-snapshot
      (codex:shell-type-cmd)
      "cmd"))
  ((CodexToolUserShellTypeCmd)))
