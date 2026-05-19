!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:request_permissions)

(= (codex-rp-root) "/home/zarclaw/repos/CeTTa")

(= (codex-rp-granted-profile)
   (codex:request-permission-profile
     CodexAbsent
     (codex:request-permissions-file-system
       ()
       ("/home/zarclaw/repos/CeTTa/runtime"))))

(= (codex-rp-normalized-requested-profile)
   (codex:request-permission-profile
     (codex:request-permissions-network True)
     (codex:request-permissions-file-system
       ("/home/zarclaw/repos/CeTTa/docs")
       ("/home/zarclaw/repos/CeTTa/runtime"))))

(= (codex-rp-event)
   (codex:request-permissions-event
     "call-rp"
     "turn-rp"
     "Need docs and runtime access."
     (codex-rp-normalized-requested-profile)
     (codex-rp-root)))

(= (codex-rp-normalized-response)
   (CodexRequestPermissionsResponse
     (CodexRequestPermissionProfile
       CodexAbsent
       (CodexRequestPermissionsFileSystem
         ()
         ("/home/zarclaw/repos/CeTTa/runtime")))
     (codex:permission-grant-scope-turn)
     False))

!(assertEqual
  (once
    (eval
      (codex:record-granted-request-permissions-for-state
        (codex:empty-request-permissions-state)
        (codex-rp-normalized-response))))
  (CodexRequestPermissionsState
    CodexAbsent
    (CodexRequestPermissionProfile
      CodexAbsent
      (CodexRequestPermissionsFileSystem
        ()
        ("/home/zarclaw/repos/CeTTa/runtime")))
    False))

!(assertEqualToResult
  (json-stringify
    (JsonObject
      ((JsonPair
         "permissions"
         (codex:request-permissions-state-turn-permissions-json
           (CodexRequestPermissionsState
             CodexAbsent
             (CodexRequestPermissionProfile
               CodexAbsent
               (CodexRequestPermissionsFileSystem
                 ()
                 ("/home/zarclaw/repos/CeTTa/runtime")))
             False)))
       (JsonPair "scope" (JsonString "turn")))))
  ("{\"permissions\":{\"file_system\":{\"write\":[\"/home/zarclaw/repos/CeTTa/runtime\"]}},\"scope\":\"turn\"}"))
