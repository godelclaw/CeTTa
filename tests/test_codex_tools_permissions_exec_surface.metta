!(register-module! ../codex)
!(import! &self codex:approval)
!(import! &self codex:request_permissions)
!(import! &self codex:tools)

(= (codex-tools-perm-exec-state)
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

!(assertEqual
  (codex:is-string-contains
    (codex:tool-result-output-text
      (once
        (codex:run-exec-command-tool-call-with-context-state
          (codex:exec-command-context
            (codex:ask-for-approval-never)
            False)
          (codex-tools-perm-exec-state)
          "call_preapproved_exec"
          "{\"cmd\":\"printf permission-ok\",\"login\":false,\"sandbox_permissions\":\"with_additional_permissions\",\"additional_permissions\":{\"file_system\":{\"write\":[\"runtime\"]}}}")))
    "permission-ok")
  True)

!(assertEqual
  (codex:is-string-contains
    (codex:tool-result-output-text
      (once
        (codex:run-exec-command-tool-call-with-context-state
          (codex:exec-command-context
            (codex:ask-for-approval-on-request)
            False)
          (codex:empty-request-permissions-state)
          "call_disabled_exec"
          "{\"cmd\":\"printf permission-ok\",\"login\":false,\"sandbox_permissions\":\"with_additional_permissions\",\"additional_permissions\":{\"network\":{\"enabled\":true}}}")))
    "additional permissions are disabled")
  True)
