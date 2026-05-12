!(register-module! ../codex)
!(import! &self json)
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

!(assertEqual
  (once
    (codex:exec-effective-additional-permissions-sandbox-permissions
      (codex:resolve-effective-exec-command-permissions
        (codex-tools-perm-state)
        (codex:sandbox-permissions-use-default)
        (codex:request-permission-profile
          CodexAbsent
          (codex:request-permissions-file-system
            ()
            ("/home/zarclaw/repos/CeTTa/runtime")))
        "/home/zarclaw/repos/CeTTa")))
  "with_additional_permissions")

!(assertEqual
  (once
    (json-stringify
      (codex:request-permission-profile-json
        (codex:exec-effective-additional-permissions-additional-permissions
          (codex:resolve-effective-exec-command-permissions
            (codex-tools-perm-state)
            (codex:sandbox-permissions-use-default)
            (codex:request-permission-profile
              CodexAbsent
              (codex:request-permissions-file-system
                ()
                ("/home/zarclaw/repos/CeTTa/runtime")))
            "/home/zarclaw/repos/CeTTa")))))
  "{\"file_system\":{\"write\":[\"/home/zarclaw/repos/CeTTa/runtime\"]}}")

!(assertEqual
  (once
    (codex:exec-effective-additional-permissions-permissions-preapproved
      (codex:resolve-effective-exec-command-permissions
        (codex-tools-perm-state)
        (codex:sandbox-permissions-use-default)
        (codex:request-permission-profile
          CodexAbsent
          (codex:request-permissions-file-system
            ()
            ("/home/zarclaw/repos/CeTTa/runtime")))
        "/home/zarclaw/repos/CeTTa")))
  True)
