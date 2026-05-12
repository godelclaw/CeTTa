!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:approval)
!(import! &self codex:protocol)
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
  (once
    (case
      (codex:handle-request-permissions-payload
        (codex:request-permissions-handler-context
          (codex:ask-for-approval-granular-config
            True
            False
            False
            False
            False)
          "turn-rp"
          (codex-rp-root)
          (codex:request-permissions-response-behavior-return
            (codex:request-permissions-response
              (codex-rp-granted-profile)
              (codex:permission-grant-scope-turn)
              False)))
        (codex:empty-request-permissions-state)
        "call-rp-granular"
        (codex:request-permissions-function-payload
          (codex-rp-input-json)))
      (((CodexRequestPermissionsHandlerOutput $event $output $next-state)
        $output))))
  "{\"permissions\":{},\"scope\":\"turn\"}")
