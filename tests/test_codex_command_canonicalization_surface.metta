!(register-module! ../codex)
!(import! &self codex:command_canonicalization)

!(assertEqualToResult
  (codex:canonicalize-command-for-approval
    ("/bin/bash" "-lc" "cargo test -p codex-core"))
  (("cargo" "test" "-p" "codex-core")))

!(assertEqualToResult
  (codex:canonicalize-command-for-approval
    ("bash" "-lc" "cargo   test   -p codex-core"))
  (("cargo" "test" "-p" "codex-core")))

!(assertEqualToResult
  (codex:canonicalize-command-for-approval
    ("/bin/zsh" "-lc" "python3 <<'PY'\nprint('hello')\nPY"))
  (("__codex_shell_script__" "-lc" "python3 <<'PY'\nprint('hello')\nPY")))

!(assertEqualToResult
  (codex:canonicalize-command-for-approval
    ("zsh" "-lc" "python3 <<'PY'\nprint('hello')\nPY"))
  (("__codex_shell_script__" "-lc" "python3 <<'PY'\nprint('hello')\nPY")))

!(assertEqualToResult
  (codex:canonicalize-command-for-approval
    ("powershell.exe" "-NoProfile" "-Command" "Write-Host hi"))
  (("__codex_powershell_script__" "Write-Host hi")))

!(assertEqualToResult
  (codex:canonicalize-command-for-approval
    ("powershell" "-Command" "Write-Host hi"))
  (("__codex_powershell_script__" "Write-Host hi")))

!(assertEqualToResult
  (codex:canonicalize-command-for-approval
    ("pwsh" "-NoLogo" "-NoProfile" "-c" "Get-ChildItem | Select-String foo"))
  (("__codex_powershell_script__" "Get-ChildItem | Select-String foo")))

!(assertEqualToResult
  (codex:canonicalize-command-for-approval
    ("powershell" "-BadFlag" "-Command" "Write-Host hi"))
  (("powershell" "-BadFlag" "-Command" "Write-Host hi")))

!(assertEqualToResult
  (codex:canonicalize-command-for-approval
    ("bash.exe" "-lc" "cargo test"))
  (("cargo" "test")))

!(assertEqualToResult
  (codex:canonicalize-command-for-approval
    ("PowerShell.exe" "-Command" "Write-Host hi"))
  (("PowerShell.exe" "-Command" "Write-Host hi")))

!(assertEqualToResult
  (codex:canonicalize-command-for-approval
    ("cargo" "fmt"))
  (("cargo" "fmt")))

!(assertEqualToResult
  (codex:prefix-powershell-script-with-utf8
    ("pwsh" "-NoProfile" "-Command" "Write-Output ok"))
  (("pwsh" "-NoProfile" "-Command" "[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;\nWrite-Output ok")))

!(assertEqualToResult
  (codex:prefix-powershell-script-with-utf8
    ("pwsh" "-Command" "  [Console]::OutputEncoding=[System.Text.Encoding]::UTF8;\nWrite-Output ok"))
  (("pwsh" "-Command" "  [Console]::OutputEncoding=[System.Text.Encoding]::UTF8;\nWrite-Output ok")))

!(assertEqualToResult
  (codex:prefix-powershell-script-with-utf8
    ("bash" "-lc" "Write-Output ok"))
  (("bash" "-lc" "Write-Output ok")))

!(assertEqualToResult
  (codex:prefix-powershell-script-with-utf8
    ("pwsh" "-Command" "Write-Output ok" "-extra"))
  (("pwsh" "-Command" "Write-Output ok" "[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;\nWrite-Output ok")))
