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

(= (codex-rp-normalized-requested-profile)
   (codex:request-permission-profile
     (codex:request-permissions-network True)
     (codex:request-permissions-file-system
       ("/home/zarclaw/repos/CeTTa/docs")
       ("/home/zarclaw/repos/CeTTa/runtime"))))

(= (codex-rp-context)
   (codex:request-permissions-handler-context
     (codex:ask-for-approval-on-request)
     "turn-rp"
     (codex-rp-root)
     (codex:request-permissions-response-behavior-return
       (codex:request-permissions-response
         (codex-rp-granted-profile)
         (codex:permission-grant-scope-turn)
         False))))

(= (codex-rp-event)
   (codex:request-permissions-event
     "call-rp"
     "turn-rp"
     "Need docs and runtime access."
     (codex-rp-normalized-requested-profile)
     (codex-rp-root)))

!(assertEqualToResult
  (codex:request-permissions-tool-description)
  ("Request additional filesystem or network permissions from the user and wait for the client to grant a subset of the requested permission profile. Granted permissions apply automatically to later shell-like commands in the current turn, or for the rest of the session if the client approves them at session scope."))

!(assertEqual
  (once
    (let $result
      (codex:normalize-request-permissions-args
        (codex-rp-root)
        (codex:request-permissions-args-without-reason
          (codex:request-permission-profile CodexAbsent CodexAbsent)))
      (codex:request-permissions-normalize-result-message $result)))
  "request_permissions requires at least one permission")

!(assertEqualToResult
  (json-stringify
    (codex:request-permissions-event-json
      (codex-rp-event)))
  ("{\"call_id\":\"call-rp\",\"turn_id\":\"turn-rp\",\"reason\":\"Need docs and runtime access.\",\"permissions\":{\"network\":{\"enabled\":true},\"file_system\":{\"read\":[\"/home/zarclaw/repos/CeTTa/docs\"],\"write\":[\"/home/zarclaw/repos/CeTTa/runtime\"]}},\"cwd\":\"/home/zarclaw/repos/CeTTa\"}"))

!(assertEqualToResult
  (codex:tool-result-output-text
    (once
      (codex:run-request-permissions-tool-call
        "call-rp-default"
        (codex-rp-input-json))))
  ("{\"permissions\":{},\"scope\":\"turn\"}"))

!(assertEqualToResult
  (codex:request-permissions-handler-result-message
    (codex:handle-request-permissions-payload
      (codex-rp-context)
      (codex:empty-request-permissions-state)
      "call-rp"
      (codex:request-permissions-unsupported-payload "custom")))
  ("request_permissions handler received unsupported payload"))

!(assertEqualToResult
  (json-stringify
    (codex:request-permissions-response-json
      (codex:normalize-request-permissions-response
        (codex:request-permission-profile
          (codex:request-permissions-network True)
          CodexAbsent)
        (codex:request-permissions-response
          (codex:request-permission-profile
            (codex:request-permissions-network True)
            CodexAbsent)
          (codex:permission-grant-scope-session)
          True)
        (codex-rp-root))))
  ("{\"permissions\":{},\"scope\":\"turn\"}"))
