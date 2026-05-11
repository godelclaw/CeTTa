!(register-module! ../codex)
!(import! &self fs)
!(import! &self json)
!(import! &self codex:apply_patch)
!(import! &self codex:protocol)
!(import! &self codex:tools)

(= (codex-apply-test-cwd) "/home/zarclaw/repos/CeTTa")

!(fs-write-text "/home/zarclaw/repos/CeTTa/runtime/codex-apply-direct.txt" "before\n")

!(assertEqualToResult
  (codex:is-string-contains
    (codex:tool-result-output-text
      (codex:run-tool-call-item
        (codex:tool-call
          "call_apply_direct"
          "apply_patch"
          "*** Begin Patch\n*** Update File: runtime/codex-apply-direct.txt\n@@\n-before\n+after\n*** End Patch")))
    "Success. Updated the following files:")
  (True))

!(assertEqualToResult
  (fs-read-text "/home/zarclaw/repos/CeTTa/runtime/codex-apply-direct.txt")
  ("after\n"))

!(fs-write-text "/home/zarclaw/repos/CeTTa/runtime/codex-apply-shell.txt" "shell-before\n")

!(assertEqualToResult
  (codex:is-string-contains
    (codex:tool-result-output-text
      (codex:run-tool-call-item
        (codex:tool-call
          "call_apply_shell"
          "exec_command"
          "{\"cmd\":\"cd runtime && apply_patch <<'PATCH'\\n*** Begin Patch\\n*** Update File: codex-apply-shell.txt\\n@@\\n-shell-before\\n+shell-after\\n*** End Patch\\nPATCH\",\"login\":false,\"yield_time_ms\":1000}")))
    "Success. Updated the following files:")
  (True))

!(assertEqualToResult
  (fs-read-text "/home/zarclaw/repos/CeTTa/runtime/codex-apply-shell.txt")
  ("shell-after\n"))
