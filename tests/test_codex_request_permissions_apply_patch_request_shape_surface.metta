!(register-module! ../codex)
!(import! &self fs)
!(import! &self json)
!(import! &self codex:apply_patch)
!(import! &self codex:approval)
!(import! &self codex:request_permissions)

(= (codex-rp-request-root) "/home/zarclaw/repos/CeTTa")

(= (codex-rp-request-base-policy)
   (codex:patch-fs-policy
     ("/home/zarclaw/repos/CeTTa/src")
     ()
     ()))

(= (codex-rp-request-runtime-policy)
   (codex:patch-fs-policy
     ("/home/zarclaw/repos/CeTTa/runtime")
     ()
     ()))

(= (codex-rp-request-patch)
   "*** Begin Patch\n*** Update File: runtime/codex-rp-request.txt\n@@\n-before\n+after\n*** End Patch")

(= (codex-rp-request-turn-state $strict-auto-review)
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

(= (codex-rp-request-json $strict-auto-review)
   (let $parsed
     (codex:maybe-parse-apply-patch-input
       (codex-rp-request-root)
       (codex-rp-request-patch))
     (let $invocation
       (once
         (codex:apply-patch-with-request-permissions-state
           (codex-rp-request-turn-state $strict-auto-review)
           (codex:ask-for-approval-on-request)
           (codex:patch-sandbox-workspace-write)
           (codex-rp-request-base-policy)
           (codex:maybe-apply-patch-patch-text $parsed)
           (codex:maybe-apply-patch-action $parsed)
           False))
       (json-stringify
         (codex:apply-patch-runtime-request-json
           (codex:request-permissions-apply-patch-runtime-request
             (codex-rp-request-turn-state $strict-auto-review)
             (codex-rp-request-base-policy)
             (codex:internal-apply-patch-runtime $invocation)))))))

(= (codex-rp-request-json-without-grant)
   (let $parsed
     (codex:maybe-parse-apply-patch-input
       (codex-rp-request-root)
       (codex-rp-request-patch))
     (let $invocation
       (once
         (codex:apply-patch-with-request-permissions-state
           (codex:empty-request-permissions-state)
           (codex:ask-for-approval-on-request)
           (codex:patch-sandbox-workspace-write)
           (codex-rp-request-runtime-policy)
           (codex:maybe-apply-patch-patch-text $parsed)
           (codex:maybe-apply-patch-action $parsed)
           False))
       (json-stringify
         (codex:apply-patch-runtime-request-json
           (codex:request-permissions-apply-patch-runtime-request
             (codex:empty-request-permissions-state)
             (codex-rp-request-runtime-policy)
             (codex:internal-apply-patch-runtime $invocation)))))))

!(fs-write-text
  "/home/zarclaw/repos/CeTTa/runtime/codex-rp-request.txt"
  "before\n")

!(assertEqual
  (once (codex-rp-request-json False))
  "{\"action\":{\"cwd\":\"/home/zarclaw/repos/CeTTa\",\"patch\":\"*** Begin Patch\\n*** Update File: runtime/codex-rp-request.txt\\n@@\\n-before\\n+after\\n*** End Patch\"},\"file_paths\":[\"/home/zarclaw/repos/CeTTa/runtime/codex-rp-request.txt\"],\"changes\":{\"runtime/codex-rp-request.txt\":{\"type\":\"update\",\"unified_diff\":\"@@\\n-before\\n+after\\n\",\"move_path\":null}},\"auto_approved\":true,\"exec_approval_requirement\":{\"type\":\"skip\",\"bypass_sandbox\":false,\"proposed_execpolicy_amendment\":null},\"additional_permissions\":{\"file_system\":{\"write\":[\"/home/zarclaw/repos/CeTTa/runtime\"]}},\"permissions_preapproved\":true}")

!(assertEqual
  (once (codex-rp-request-json True))
  "{\"action\":{\"cwd\":\"/home/zarclaw/repos/CeTTa\",\"patch\":\"*** Begin Patch\\n*** Update File: runtime/codex-rp-request.txt\\n@@\\n-before\\n+after\\n*** End Patch\"},\"file_paths\":[\"/home/zarclaw/repos/CeTTa/runtime/codex-rp-request.txt\"],\"changes\":{\"runtime/codex-rp-request.txt\":{\"type\":\"update\",\"unified_diff\":\"@@\\n-before\\n+after\\n\",\"move_path\":null}},\"auto_approved\":false,\"exec_approval_requirement\":{\"type\":\"needs_approval\",\"reason\":null,\"proposed_execpolicy_amendment\":null},\"additional_permissions\":{\"file_system\":{\"write\":[\"/home/zarclaw/repos/CeTTa/runtime\"]}},\"permissions_preapproved\":true}")

!(assertEqual
  (once (codex-rp-request-json-without-grant))
  "{\"action\":{\"cwd\":\"/home/zarclaw/repos/CeTTa\",\"patch\":\"*** Begin Patch\\n*** Update File: runtime/codex-rp-request.txt\\n@@\\n-before\\n+after\\n*** End Patch\"},\"file_paths\":[\"/home/zarclaw/repos/CeTTa/runtime/codex-rp-request.txt\"],\"changes\":{\"runtime/codex-rp-request.txt\":{\"type\":\"update\",\"unified_diff\":\"@@\\n-before\\n+after\\n\",\"move_path\":null}},\"auto_approved\":false,\"exec_approval_requirement\":{\"type\":\"needs_approval\",\"reason\":null,\"proposed_execpolicy_amendment\":null},\"additional_permissions\":null,\"permissions_preapproved\":false}")
