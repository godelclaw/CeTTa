!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:op-type
    (codex:request-permissions-response-op
      "call_123"
      (codex:protocol-request-permissions-response
        (codex:protocol-request-permission-profile
          (codex:protocol-request-permissions-network True)
          CodexAbsent)
        (codex:protocol-permission-grant-scope-turn)
        False)))
  ("request_permissions_response"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:request-permissions-response-op
        "call_123"
        (codex:protocol-request-permissions-response
          (codex:protocol-request-permission-profile
            (codex:protocol-request-permissions-network True)
            CodexAbsent)
          (codex:protocol-permission-grant-scope-turn)
          False))))
  ("{\"type\":\"request_permissions_response\",\"id\":\"call_123\",\"response\":{\"permissions\":{\"network\":{\"enabled\":true}},\"scope\":\"turn\"}}"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:request-permissions-response-op
        "call_456"
        (codex:protocol-request-permissions-response
          (codex:protocol-request-permission-profile
            (codex:protocol-request-permissions-network True)
            (codex:protocol-request-permissions-file-system
              ("/repo/read")
              ("/repo/write")))
          (codex:protocol-permission-grant-scope-session)
          True))))
  ("{\"type\":\"request_permissions_response\",\"id\":\"call_456\",\"response\":{\"permissions\":{\"network\":{\"enabled\":true},\"file_system\":{\"read\":[\"/repo/read\"],\"write\":[\"/repo/write\"]}},\"scope\":\"session\",\"strict_auto_review\":true}}"))
