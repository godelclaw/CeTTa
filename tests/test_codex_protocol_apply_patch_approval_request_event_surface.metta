!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:apply-patch-approval-request-event
        "patch-call-2"
        "turn-2"
        ((codex:file-change-map-entry
           "a"
           (codex:file-change-update
             "u"
             CodexAbsent)))
        "r"
        "/g")))
  ("{\"type\":\"apply_patch_approval_request\",\"call_id\":\"patch-call-2\",\"turn_id\":\"turn-2\",\"changes\":{\"a\":{\"type\":\"update\",\"unified_diff\":\"u\",\"move_path\":null}},\"reason\":\"r\",\"grant_root\":\"/g\"}"))
