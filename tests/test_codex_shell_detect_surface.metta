!(register-module! ../codex)
!(import! &self codex:shell_detect)

!(assertEqualToResult
  (codex:detect-shell-type "zsh")
  ("Zsh"))

!(assertEqualToResult
  (codex:detect-shell-type "bash")
  ("Bash"))

!(assertEqualToResult
  (codex:detect-shell-type "pwsh")
  ("PowerShell"))

!(assertEqualToResult
  (codex:detect-shell-type "powershell")
  ("PowerShell"))

!(assertEqualToResult
  (codex:detect-shell-type "fish")
  (CodexAbsent))

!(assertEqualToResult
  (codex:detect-shell-type "other")
  (CodexAbsent))

!(assertEqualToResult
  (codex:detect-shell-type "/bin/zsh")
  ("Zsh"))

!(assertEqualToResult
  (codex:detect-shell-type "/bin/bash")
  ("Bash"))

!(assertEqualToResult
  (codex:detect-shell-type "powershell.exe")
  ("PowerShell"))

!(assertEqualToResult
  (codex:detect-shell-type "pwsh.exe")
  ("PowerShell"))

!(assertEqualToResult
  (codex:detect-shell-type "/usr/local/bin/pwsh")
  ("PowerShell"))

!(assertEqualToResult
  (codex:detect-shell-type "/bin/sh")
  ("Sh"))

!(assertEqualToResult
  (codex:detect-shell-type "sh")
  ("Sh"))

!(assertEqualToResult
  (codex:detect-shell-type "cmd")
  ("Cmd"))

!(assertEqualToResult
  (codex:detect-shell-type "cmd.exe")
  ("Cmd"))

!(assertEqualToResult
  (codex:detect-shell-type "Bash")
  (CodexAbsent))

!(assertEqualToResult
  (codex:detect-shell-type "powershell.exe.bak")
  ("PowerShell"))
