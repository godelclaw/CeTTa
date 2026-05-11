!(register-module! ../codex)
!(import! &self fs)
!(import! &self codex:apply_patch)

(= (codex-apply-test-cwd) "/home/zarclaw/repos/CeTTa")

!(fs-write-text "/home/zarclaw/repos/CeTTa/runtime/codex-apply-shell.txt" "shell-before\n")

!(assertEqual
  (once
    (codex:apply-patch-intercept-text
      (codex:run-apply-patch-shell-command-local
        (codex-apply-test-cwd)
        "cd runtime && apply_patch <<'PATCH'\n*** Begin Patch\n*** Update File: codex-apply-shell.txt\n@@\n-shell-before\n+shell-after\n*** End Patch\nPATCH")))
  "Success. Updated the following files:\nM codex-apply-shell.txt\n")

!(assertEqualToResult
  (fs-read-text "/home/zarclaw/repos/CeTTa/runtime/codex-apply-shell.txt")
  ("shell-after\n"))
