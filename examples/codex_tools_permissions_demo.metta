!(register-module! ../codex)
!(import! &self codex:approval)
!(import! &self codex:request_permissions)
!(import! &self codex:tools)

(= (codex-tools-demo-state)
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

!(println! "=== Codex tools permissions demo ===")

!(println!
  (once
    (codex:exec-command-permission-plan-json-with-context-state
      (codex:exec-command-context
        (codex:ask-for-approval-never)
        False)
      (codex-tools-demo-state)
      "{\"cmd\":\"printf demo\",\"login\":false}")))

!(println!
  (once
    (codex:exec-command-run-text
      (codex:run-exec-command-with-context-state
        (codex:exec-command-context
          (codex:ask-for-approval-never)
          False)
        (codex-tools-demo-state)
        "call_demo_permissions"
        "{\"cmd\":\"printf codex-tools-permissions-demo\",\"login\":false,\"sandbox_permissions\":\"with_additional_permissions\",\"additional_permissions\":{\"file_system\":{\"write\":[\"runtime\"]}}}"))))
