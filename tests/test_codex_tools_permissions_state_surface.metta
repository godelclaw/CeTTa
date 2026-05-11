!(register-module! ../codex)
!(import! &self codex:approval)
!(import! &self codex:request_permissions)
!(import! &self codex:tools)

(= (codex-tools-perm-state)
   (codex:record-granted-request-permissions-for-state
     (codex:empty-request-permissions-state)
     (codex:request-permissions-response
       (codex:request-permission-profile
         CodexAbsent
         (codex:request-permissions-file-system
           ()
           ("/home/zarclaw/repos/CeTTa/runtime")))
       (codex:permission-grant-scope-turn)
       False)))

!(assertEqualToResult
  (once
    (codex:exec-command-permission-plan-json-with-context-state
      (codex:exec-command-context
        (codex:ask-for-approval-never)
        False)
      (codex-tools-perm-state)
      "{\"cmd\":\"printf ok\",\"login\":false}"))
  ("{\"type\":\"ok\",\"sandbox_permissions\":\"with_additional_permissions\",\"additional_permissions\":{\"file_system\":{\"write\":[\"/home/zarclaw/repos/CeTTa/runtime\"]}},\"permissions_preapproved\":true}"))
