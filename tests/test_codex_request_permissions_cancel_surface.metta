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

!(assertEqualToResult
  (codex:request-permissions-cancelled-message)
  ("request_permissions was cancelled before receiving a response"))
