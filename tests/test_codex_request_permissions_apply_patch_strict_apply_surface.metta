!(register-module! ../codex)
!(import! &self fs)
!(import! &self codex:apply_patch)
!(import! &self codex:approval)
!(import! &self codex:request_permissions)

(= (codex-rp-apply-base-policy)
   (codex:patch-fs-policy
     ("/home/zarclaw/repos/CeTTa/src")
     ()
     ()))

(= (codex-rp-strict-file)
   "/home/zarclaw/repos/CeTTa/runtime/codex-rp-strict.txt")

(= (codex-rp-strict-patch)
   "*** Begin Patch\n*** Update File: runtime/codex-rp-strict.txt\n@@\n-before\n+after-strict\n*** End Patch")

(= (codex-rp-turn-state $strict-auto-review)
   (codex:record-granted-request-permissions-for-state
     (codex:empty-request-permissions-state)
     (codex:request-permissions-response
       (codex:request-permission-profile
         CodexAbsent
         (codex:request-permissions-file-system
           ()
           ("/home/zarclaw/repos/CeTTa/runtime")))
       (codex:permission-grant-scope-turn)
       $strict-auto-review)))

!(fs-write-text (codex-rp-strict-file) "before\n")

!(assertEqual
  (once
    (codex:run-apply-patch-with-request-permissions-state
      (codex-rp-turn-state True)
      (codex:ask-for-approval-on-request)
      (codex:patch-sandbox-workspace-write)
      (codex-rp-apply-base-policy)
      (codex-rp-strict-patch)
      False))
  "apply_patch requires approval before execution")

!(assertEqualToResult
  (fs-read-text (codex-rp-strict-file))
  ("before\n"))
