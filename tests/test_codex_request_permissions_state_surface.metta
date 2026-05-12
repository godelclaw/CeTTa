!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:approval)
!(import! &self codex:protocol)
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

!(assertEqualToResult
  (case
    (codex:request-permissions-state-turn-permissions
      (codex:request-permissions-handler-result-state
        (codex:request-permissions-handler-response-result
          (codex:empty-request-permissions-state)
          (codex-rp-normalized-requested-profile)
          (codex-rp-root)
          (codex-rp-event)
          (codex:request-permissions-response-behavior-return
            (codex:request-permissions-response
              (codex-rp-granted-profile)
              (codex:permission-grant-scope-turn)
              False)))))
    (((CodexRequestPermissionProfile $network $file-system)
      (json-stringify
        (codex:request-permission-profile-json
          (CodexRequestPermissionProfile $network $file-system))))))
  ("{\"file_system\":{\"write\":[\"/home/zarclaw/repos/CeTTa/runtime\"]}}"))
