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

(= (codex-rp-apply-file)
   "/home/zarclaw/repos/CeTTa/runtime/codex-rp-apply.txt")

(= (codex-rp-apply-patch)
   "*** Begin Patch\n*** Update File: runtime/codex-rp-apply.txt\n@@\n-before\n+after\n*** End Patch")

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

!(fs-write-text (codex-rp-apply-file) "before\n")

!(assertEqual
  (once
    (let $parsed
      (once
        (codex:maybe-parse-apply-patch-input
          (system-cwd)
          (codex-rp-apply-patch)))
      (let $parsed-type
        (codex:maybe-apply-patch-result-type $parsed)
        (if (== $parsed-type "body")
            (let $invocation
              (once
                (codex:apply-patch-with-request-permissions-state
                  (codex-rp-turn-state False)
                  (codex:ask-for-approval-on-request)
                  (codex:patch-sandbox-workspace-write)
                  (codex-rp-apply-base-policy)
                  (codex:maybe-apply-patch-patch-text $parsed)
                  (codex:maybe-apply-patch-action $parsed)
                  False))
              (codex:run-apply-patch-with-request-permissions-invocation
                $invocation))
            Empty))))
  "Success. Updated the following files:\nM runtime/codex-rp-apply.txt\n")

!(assertEqualToResult
  (fs-read-text (codex-rp-apply-file))
  ("after\n"))
