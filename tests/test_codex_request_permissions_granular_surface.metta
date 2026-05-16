!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:approval)
!(import! &self codex:request_permissions)

(= (codex-rp-root) "/home/zarclaw/repos/CeTTa")

(= (codex-rp-requested-profile)
   (codex:request-permission-profile
     (codex:request-permissions-network True)
     (codex:request-permissions-file-system
       ("docs")
       ("runtime"))))

(= (codex-rp-input-json)
   (json-stringify
     (codex:request-permissions-args-json
       (codex:request-permissions-args
         "Need docs and runtime access."
         (codex-rp-requested-profile)))))

(= (codex-rp-granted-profile)
   (codex:request-permission-profile
     CodexAbsent
     (codex:request-permissions-file-system
       ()
       ("/home/zarclaw/repos/CeTTa/runtime"))))

!(assertEqual
  (codex:is-request-permissions-approval-short-circuit?
    (codex:ask-for-approval-granular-config
      True
      False
      False
      False
      False))
  True)

!(assertEqualToResult
  (json-stringify
    (codex:request-permissions-response-json
      (codex:request-permissions-response
        CodexAbsent
        (codex:permission-grant-scope-turn)
        False)))
  ("{\"permissions\":{},\"scope\":\"turn\"}"))
