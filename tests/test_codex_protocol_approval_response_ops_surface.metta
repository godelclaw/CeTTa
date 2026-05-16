!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:op-type
    (codex:exec-approval-op
      "sub_123"
      CodexAbsent
      (codex:review-decision-approved)))
  ("exec_approval"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:exec-approval-op
        "sub_123"
        CodexAbsent
        (codex:review-decision-approved))))
  ("{\"type\":\"exec_approval\",\"id\":\"sub_123\",\"decision\":\"approved\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:exec-approval-op
        "sub_456"
        "turn_789"
        (codex:review-decision-approved-execpolicy-amendment
          (codex:exec-policy-amendment
            ("git" "status"))))))
  ("{\"type\":\"exec_approval\",\"id\":\"sub_456\",\"turn_id\":\"turn_789\",\"decision\":{\"approved_execpolicy_amendment\":{\"proposed_execpolicy_amendment\":[\"git\",\"status\"]}}}"))

!(assertEqualToResult
  (codex:op-type
    (codex:patch-approval-op
      "sub_patch"
      (codex:review-decision-denied)))
  ("patch_approval"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:patch-approval-op
        "sub_patch"
        (codex:review-decision-denied))))
  ("{\"type\":\"patch_approval\",\"id\":\"sub_patch\",\"decision\":\"denied\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:patch-approval-op
        "sub_patch_session"
        (codex:review-decision-approved-for-session))))
  ("{\"type\":\"patch_approval\",\"id\":\"sub_patch_session\",\"decision\":\"approved_for_session\"}"))
