!(register-module! ../codex)
!(import! &self fs)
!(import! &self codex:apply_patch)

!(fs-write-text "/home/zarclaw/repos/CeTTa/runtime/codex-apply-direct.txt" "before\n")

!(assertEqual
  (once
    (codex:run-apply-patch-local
      "*** Begin Patch\n*** Update File: runtime/codex-apply-direct.txt\n@@\n-before\n+after\n*** End Patch"))
  "Success. Updated the following files:\nM runtime/codex-apply-direct.txt\n")

!(assertEqualToResult
  (fs-read-text "/home/zarclaw/repos/CeTTa/runtime/codex-apply-direct.txt")
  ("after\n"))
