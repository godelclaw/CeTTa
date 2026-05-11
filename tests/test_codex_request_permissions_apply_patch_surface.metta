!(register-module! ../codex)
!(import! &self fs)
!(import! &self json)
!(import! &self codex:apply_patch)
!(import! &self codex:approval)
!(import! &self codex:request_permissions)

(= (codex-rp-apply-root) "/home/zarclaw/repos/CeTTa")

(= (codex-rp-apply-base-policy)
   (codex:patch-fs-policy
     ("/home/zarclaw/repos/CeTTa/src")
     ()
     ()))

(= (codex-rp-apply-request-input)
   "{\"permissions\":{\"file_system\":{\"write\":[\"runtime\"]}}}")

(= (codex-rp-apply-file)
   "/home/zarclaw/repos/CeTTa/runtime/codex-rp-apply.txt")

(= (codex-rp-strict-file)
   "/home/zarclaw/repos/CeTTa/runtime/codex-rp-strict.txt")

(= (codex-rp-apply-patch)
   "*** Begin Patch\n*** Update File: runtime/codex-rp-apply.txt\n@@\n-before\n+after\n*** End Patch")

(= (codex-rp-strict-patch)
   "*** Begin Patch\n*** Update File: runtime/codex-rp-strict.txt\n@@\n-before\n+after-strict\n*** End Patch")

(= (codex-rp-turn-context $strict-auto-review)
   (codex:request-permissions-handler-context
     (codex:ask-for-approval-on-request)
     "turn-rp"
     (codex-rp-apply-root)
     (codex:request-permissions-response-behavior-return
       (codex:request-permissions-response
         (codex:request-permission-profile
           CodexAbsent
           (codex:request-permissions-file-system
             ()
             ("/home/zarclaw/repos/CeTTa/runtime")))
         (codex:permission-grant-scope-turn)
         $strict-auto-review))))

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

!(assertEqualToResult
  (once
    (let $parsed
      (codex:maybe-parse-apply-patch-input
        (codex-rp-apply-root)
        (codex-rp-apply-patch))
      (json-stringify
        (codex:internal-apply-patch-invocation-json
          (codex:apply-patch-with-request-permissions-state
            (codex-rp-turn-state False)
            (codex:ask-for-approval-on-request)
            (codex:patch-sandbox-workspace-write)
            (codex-rp-apply-base-policy)
            (codex:maybe-apply-patch-patch-text $parsed)
            (codex:maybe-apply-patch-action $parsed)
            False)))))
  ("{\"type\":\"delegate_to_runtime\",\"runtime\":{\"auto_approved\":true,\"exec_approval_requirement\":{\"type\":\"skip\",\"bypass_sandbox\":false,\"proposed_execpolicy_amendment\":null}}}"))

!(assertEqualToResult
  (once
    (codex:run-apply-patch-with-request-permissions-state
      (codex-rp-turn-state False)
      (codex:ask-for-approval-on-request)
      (codex:patch-sandbox-workspace-write)
      (codex-rp-apply-base-policy)
      (codex-rp-apply-patch)
      False))
  ("Success. Updated the following files:\nM runtime/codex-rp-apply.txt\n"))

!(assertEqualToResult
  (fs-read-text (codex-rp-apply-file))
  ("after\n"))

!(fs-write-text (codex-rp-strict-file) "before\n")

!(assertEqualToResult
  (once
    (let $parsed
      (codex:maybe-parse-apply-patch-input
        (codex-rp-apply-root)
        (codex-rp-strict-patch))
      (json-stringify
        (codex:internal-apply-patch-invocation-json
          (codex:apply-patch-with-request-permissions-state
            (codex-rp-turn-state True)
            (codex:ask-for-approval-on-request)
            (codex:patch-sandbox-workspace-write)
            (codex-rp-apply-base-policy)
            (codex:maybe-apply-patch-patch-text $parsed)
            (codex:maybe-apply-patch-action $parsed)
            False)))))
  ("{\"type\":\"delegate_to_runtime\",\"runtime\":{\"auto_approved\":false,\"exec_approval_requirement\":{\"type\":\"needs_approval\",\"reason\":null,\"proposed_execpolicy_amendment\":null}}}"))

!(assertEqualToResult
  (once
    (codex:run-apply-patch-with-request-permissions-state
      (codex-rp-turn-state True)
      (codex:ask-for-approval-on-request)
      (codex:patch-sandbox-workspace-write)
      (codex-rp-apply-base-policy)
      (codex-rp-strict-patch)
      False))
  ("apply_patch requires approval before execution"))

!(assertEqualToResult
  (fs-read-text (codex-rp-strict-file))
  ("before\n"))
