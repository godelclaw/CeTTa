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
    ("cargo" "fmt"))
  (("cargo" "fmt")))
