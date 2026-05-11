!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:approval)
!(import! &self codex:protocol)
!(import! &self codex:request_permissions)
!(import! &self codex:tools)

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
  (let $result
    (codex:handle-request-permissions-payload
      (codex-rp-context)
      (codex:empty-request-permissions-state)
      "call-rp"
      (codex:request-permissions-function-payload
        (codex-rp-input-json)))
    (json-stringify
      (codex:request-permissions-event-json
        (codex:request-permissions-handler-result-event $result))))
  ("{\"call_id\":\"call-rp\",\"turn_id\":\"turn-rp\",\"reason\":\"Need docs and runtime access.\",\"permissions\":{\"network\":{\"enabled\":true},\"file_system\":{\"read\":[\"/home/zarclaw/repos/CeTTa/docs\"],\"write\":[\"/home/zarclaw/repos/CeTTa/runtime\"]}},\"cwd\":\"/home/zarclaw/repos/CeTTa\"}"))

!(assertEqualToResult
  (let $result
    (codex:handle-request-permissions-payload
      (codex-rp-context)
      (codex:empty-request-permissions-state)
      "call-rp"
      (codex:request-permissions-function-payload
        (codex-rp-input-json)))
    (codex:request-permissions-handler-result-output-text $result))
  ("{\"permissions\":{\"file_system\":{\"write\":[\"/home/zarclaw/repos/CeTTa/runtime\"]}},\"scope\":\"turn\"}"))

!(assertEqualToResult
  (let $result
    (codex:handle-request-permissions-payload
      (codex-rp-context)
      (codex:empty-request-permissions-state)
      "call-rp"
      (codex:request-permissions-function-payload
        (codex-rp-input-json)))
    (let $state (codex:request-permissions-handler-result-state $result)
      (json-stringify
        (codex:request-permission-profile-json
          (codex:request-permissions-state-turn-permissions $state)))))
  ("{\"file_system\":{\"write\":[\"/home/zarclaw/repos/CeTTa/runtime\"]}}"))

!(assertEqualToResult
  (codex:request-permissions-handler-result-message
    (codex:handle-request-permissions-payload
      (codex-rp-context)
      (codex:empty-request-permissions-state)
      "call-rp"
      (codex:request-permissions-unsupported-payload "custom")))
  ("request_permissions handler received unsupported payload"))

!(assertEqualToResult
  (codex:request-permissions-handler-result-message
    (codex:handle-request-permissions-payload
      (codex:request-permissions-handler-context
        (codex:ask-for-approval-on-request)
        "turn-rp"
        (codex-rp-root)
        (codex:request-permissions-response-behavior-cancel))
      (codex:empty-request-permissions-state)
      "call-rp"
      (codex:request-permissions-function-payload
        (codex-rp-input-json))))
  ("request_permissions was cancelled before receiving a response"))

!(assertEqualToResult
  (codex:tool-result-output-text
    (codex:run-tool-call-item
      (codex:tool-call
        "call-rp-default"
        "request_permissions"
        (codex-rp-input-json))))
  ("{\"permissions\":{},\"scope\":\"turn\"}"))

!(assertEqualToResult
  (let $result
    (codex:run-request-permissions-tool-call-with-context-state
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
      (codex-rp-input-json))
    (codex:tool-result-output-text
      (codex:request-permissions-tool-call-result-item $result)))
  ("{\"permissions\":{},\"scope\":\"turn\"}"))

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
