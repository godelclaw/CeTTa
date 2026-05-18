!(register-module! ../codex)
!(import! &self json)
!(import! &self list)
!(import! &self codex:protocol)

(= (exec-approval-execpolicy-default-decisions)
   (codex:exec-approval-request-default-available-decisions
     CodexAbsent
     (codex:exec-policy-amendment ("git" "status"))
     CodexAbsent
     CodexAbsent))

(= (exec-approval-network-default-decisions)
   (codex:exec-approval-request-default-available-decisions
     (codex:network-approval-context
       "api.example.test"
       (codex:network-approval-protocol-https))
     CodexAbsent
     ((codex:network-policy-amendment
        (codex:network-policy-rule-action-deny)
        "blocked.example.test")
      (codex:network-policy-amendment
        (codex:network-policy-rule-action-allow)
        "api.example.test"))
     CodexAbsent))

!(assertEqualToResult
  (codex:item-type
    (codex:exec-approval-request-event
      "c"
      CodexAbsent
      ""
      ("echo" "hi")
      "/r"
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      ((CodexParsedCommandUnknown "echo"))))
  ("exec_approval_request"))

!(assertEqualToResult
  (codex:exec-approval-request-effective-approval-id
    (codex:exec-approval-request-event
      "c"
      CodexAbsent
      ""
      ("echo")
      "/r"
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      ()))
  ("c"))

!(assertEqualToResult
  (codex:exec-approval-request-effective-approval-id
    (codex:exec-approval-request-event
      "c"
      "approval-1"
      ""
      ("echo")
      "/r"
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      ()))
  ("approval-1"))

!(assertEqualToResult
  (codex:review-decision-opaque-string
    (list:first
      (list:rest (exec-approval-execpolicy-default-decisions))))
  ("approved_with_amendment"))

!(assertEqualToResult
  (codex:review-decision-opaque-string
    (list:first
      (list:rest
        (list:rest (exec-approval-network-default-decisions)))))
  ("approved_with_network_policy_allow"))

!(assertEqualToResult
  (json-stringify
    (codex:review-decisions-json
      (codex:exec-approval-request-effective-available-decisions
        (codex:exec-approval-request-event
          "c"
          CodexAbsent
          ""
          ("echo")
          "/r"
          CodexAbsent
          CodexAbsent
          CodexAbsent
          CodexAbsent
          CodexAbsent
          ((codex:review-decision-denied))
          ()))))
  ("[\"denied\"]"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:exec-approval-request-event
        "c"
        CodexAbsent
        ""
        ("echo" "hi")
        "/r"
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        ((CodexParsedCommandUnknown "echo")))))
  ("{\"type\":\"exec_approval_request\",\"call_id\":\"c\",\"turn_id\":\"\",\"command\":[\"echo\",\"hi\"],\"cwd\":\"/r\",\"parsed_cmd\":[{\"type\":\"unknown\",\"cmd\":\"echo\"}]}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:exec-approval-request-event
        "c2"
        "a2"
        "t"
        ("x")
        "/"
        "r"
        (codex:network-approval-context
          "h"
          (codex:network-approval-protocol-http))
        (codex:exec-policy-amendment ("x"))
        ((codex:network-policy-amendment
           (codex:network-policy-rule-action-allow)
           "h"))
        (codex:protocol-request-permission-profile
          (codex:protocol-request-permissions-network True)
          CodexAbsent)
        ((codex:review-decision-denied))
        ((CodexParsedCommandUnknown "x")))))
  ("{\"type\":\"exec_approval_request\",\"call_id\":\"c2\",\"approval_id\":\"a2\",\"turn_id\":\"t\",\"command\":[\"x\"],\"cwd\":\"/\",\"reason\":\"r\",\"network_approval_context\":{\"host\":\"h\",\"protocol\":\"http\"},\"proposed_execpolicy_amendment\":[\"x\"],\"proposed_network_policy_amendments\":[{\"host\":\"h\",\"action\":\"allow\"}],\"additional_permissions\":{\"network\":{\"enabled\":true}},\"available_decisions\":[\"denied\"],\"parsed_cmd\":[{\"type\":\"unknown\",\"cmd\":\"x\"}]}"))
