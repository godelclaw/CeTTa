!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:item-type
    (codex:protocol-request-permissions-event
      "call-rp-empty"
      ""
      CodexAbsent
      (codex:protocol-request-permission-profile CodexAbsent CodexAbsent)
      CodexAbsent))
  ("request_permissions"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:protocol-request-permissions-event
        "call-rp-empty"
        ""
        CodexAbsent
        (codex:protocol-request-permission-profile CodexAbsent CodexAbsent)
        CodexAbsent)))
  ("{\"type\":\"request_permissions\",\"call_id\":\"call-rp-empty\",\"turn_id\":\"\",\"permissions\":{}}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:protocol-request-permissions-event
        "call-rp"
        "turn-rp"
        "Need docs and runtime access."
        (codex:protocol-request-permission-profile
          (codex:protocol-request-permissions-network True)
          (codex:protocol-request-permissions-file-system
            ("/repo/docs")
            ("/repo/runtime")))
        "/repo")))
  ("{\"type\":\"request_permissions\",\"call_id\":\"call-rp\",\"turn_id\":\"turn-rp\",\"reason\":\"Need docs and runtime access.\",\"permissions\":{\"network\":{\"enabled\":true},\"file_system\":{\"read\":[\"/repo/docs\"],\"write\":[\"/repo/runtime\"]}},\"cwd\":\"/repo\"}"))
