!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:user-message "Inspect the repo.")))
  ("{\"type\":\"message\",\"role\":\"user\",\"content\":[{\"type\":\"input_text\",\"text\":\"Inspect the repo.\"}]}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:final-response "Done.")))
  ("{\"type\":\"message\",\"role\":\"assistant\",\"content\":[{\"type\":\"output_text\",\"text\":\"Done.\"}],\"phase\":\"final_answer\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:tool-call "call_1" "exec_command" "{\"cmd\":\"pwd\"}")))
  ("{\"type\":\"custom_tool_call\",\"call_id\":\"call_1\",\"name\":\"exec_command\",\"input\":\"{\\\"cmd\\\":\\\"pwd\\\"}\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:tool-result "call_1" "ok")))
  ("{\"type\":\"custom_tool_call_output\",\"call_id\":\"call_1\",\"output\":\"ok\"}"))

!(assertEqualToResult
  (codex:message-phase
    (codex:final-response "Done."))
  ("final_answer"))

!(assertEqualToResult
  (json-stringify
    (codex:items-json
      ((codex:user-message "u")
       (codex:assistant-message "a"))))
  ("[{\"type\":\"message\",\"role\":\"user\",\"content\":[{\"type\":\"input_text\",\"text\":\"u\"}]},{\"type\":\"message\",\"role\":\"assistant\",\"content\":[{\"type\":\"output_text\",\"text\":\"a\"}]}]"))

!(assertEqualToResult
  (codex:error-event-affects-turn-status
    (codex:error-event
      "rollback failed"
      (codex:codex-error-info-thread-rollback-failed)))
  (False))

!(assertEqualToResult
  (codex:error-event-affects-turn-status
    (codex:error-event
      "cannot steer"
      (codex:codex-error-info-active-turn-not-steerable
        (codex:non-steerable-turn-kind-review))))
  (False))

!(assertEqualToResult
  (codex:error-event-affects-turn-status
    (codex:error-event
      "generic"
      (codex:codex-error-info-other)))
  (True))

!(assertEqualToResult
  (codex:error-event-affects-turn-status
    (codex:error-event "message only" CodexAbsent))
  (True))

!(assertEqualToResult
  (json-stringify
    (codex:items-json
      (codex:event-as-legacy-events
        (codex:agent-message-content-delta-event
          "thread-1"
          "turn-1"
          "item-1"
          "delta block")
        False)))
  ("[{\"type\":\"agent_message_delta\",\"delta\":\"delta block\"}]"))

!(assertEqualToResult
  (json-stringify
    (codex:items-json
      (codex:event-as-legacy-events
        (codex:plan-delta-event
          "thread-2"
          "turn-2"
          "item-2"
          "plan delta")
        False)))
  ("[]"))

!(assertEqualToResult
  (json-stringify
    (codex:items-json
      (codex:event-as-legacy-events
        (codex:reasoning-content-delta-event
          "thread-3"
          "turn-3"
          "item-3"
          "reasoning delta"
          7)
        False)))
  ("[{\"type\":\"agent_reasoning_delta\",\"delta\":\"reasoning delta\"}]"))

!(assertEqualToResult
  (json-stringify
    (codex:items-json
      (codex:event-as-legacy-events
        (codex:reasoning-raw-content-delta-event
          "thread-4"
          "turn-4"
          "item-4"
          "raw reasoning delta"
          3)
        True)))
  ("[{\"type\":\"agent_reasoning_raw_content_delta\",\"delta\":\"raw reasoning delta\"}]"))

!(assertEqualToResult
  (json-stringify
    (codex:product-json (codex:product-chatgpt)))
  ("\"chatgpt\""))

!(assertEqualToResult
  (json-stringify
    (codex:product-json (codex:product-codex)))
  ("\"codex\""))

!(assertEqualToResult
  (json-stringify
    (codex:product-json (codex:product-atlas)))
  ("\"atlas\""))

!(assertEqualToResult
  (codex:product-to-app-platform (codex:product-chatgpt))
  ("chat"))

!(assertEqualToResult
  (codex:product-to-app-platform (codex:product-codex))
  ("codex"))

!(assertEqualToResult
  (codex:product-to-app-platform (codex:product-atlas))
  ("atlas"))

!(assertEqualToResult
  (json-stringify
    (codex:product-json
      (codex:product-from-session-source-name " chatgpt ")))
  ("\"chatgpt\""))

!(assertEqualToResult
  (json-stringify
    (codex:product-json
      (codex:product-from-session-source-name "ATLAS")))
  ("\"atlas\""))

!(assertEqualToResult
  (codex:product-from-session-source-name "atlas-dev")
  (CodexAbsent))

!(assertEqualToResult
  (codex:product-matches-product-restriction
    (codex:product-chatgpt)
    ((codex:product-chatgpt)))
  (True))

!(assertEqualToResult
  (codex:product-matches-product-restriction
    (codex:product-chatgpt)
    ((codex:product-codex)))
  (False))

!(assertEqualToResult
  (codex:product-matches-product-restriction
    (codex:product-atlas)
    ())
  (True))

!(assertEqualToResult
  (json-stringify
    (codex:session-approval-policy-json
      (codex:session-approval-policy-granular
        (codex:session-approval-policy-granular-config
          True
          False
          True
          False
          True))))
  ("{\"granular\":{\"sandbox_approval\":true,\"rules\":false,\"skill_approval\":true,\"request_permissions\":false,\"mcp_elicitations\":true}}"))

!(assertEqualToResult
  (json-stringify
    (codex:session-permission-profile-external-json
      (codex:session-network-sandbox-policy-enabled)))
  ("{\"type\":\"external\",\"network\":\"enabled\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-policy-amendment-json
      (codex:exec-policy-amendment ("git" "status"))))
  ("[\"git\",\"status\"]"))

!(assertEqualToResult
  (json-stringify
    (codex:review-decision-json
      (codex:review-decision-approved)))
  ("\"approved\""))

!(assertEqualToResult
  (json-stringify
    (codex:review-decision-json
      (codex:review-decision-approved-execpolicy-amendment
        (codex:exec-policy-amendment ("git" "status")))))
  ("{\"approved_execpolicy_amendment\":{\"proposed_execpolicy_amendment\":[\"git\",\"status\"]}}"))

!(assertEqualToResult
  (json-stringify
    (codex:review-decision-json
      (codex:review-decision-approved-for-session)))
  ("\"approved_for_session\""))

!(assertEqualToResult
  (json-stringify
    (codex:review-decision-json
      (codex:review-decision-network-policy-amendment
        (CodexNetworkPolicyAmendment
          (CodexNetworkPolicyRuleActionAllow)
          "api.example.com"))))
  ("{\"network_policy_amendment\":{\"network_policy_amendment\":{\"host\":\"api.example.com\",\"action\":\"allow\"}}}"))

!(assertEqualToResult
  (json-stringify
    (codex:review-decision-json
      (codex:review-decision-denied)))
  ("\"denied\""))

!(assertEqualToResult
  (json-stringify
    (codex:review-decision-json
      (codex:review-decision-timed-out)))
  ("\"timed_out\""))

!(assertEqualToResult
  (json-stringify
    (codex:review-decision-json
      (codex:review-decision-abort)))
  ("\"abort\""))

!(assertEqualToResult
  (json-stringify
    (codex:review-decisions-json
      ((codex:review-decision-approved)
       (codex:review-decision-abort))))
  ("[\"approved\",\"abort\"]"))

!(assertEqualToResult
  (codex:review-decision-opaque-string
    (codex:review-decision-approved))
  ("approved"))

!(assertEqualToResult
  (codex:review-decision-opaque-string
    (codex:review-decision-approved-execpolicy-amendment
      (codex:exec-policy-amendment ("git" "status"))))
  ("approved_with_amendment"))

!(assertEqualToResult
  (codex:review-decision-opaque-string
    (codex:review-decision-approved-for-session))
  ("approved_for_session"))

!(assertEqualToResult
  (codex:review-decision-opaque-string
    (codex:review-decision-network-policy-amendment
      (CodexNetworkPolicyAmendment
        (CodexNetworkPolicyRuleActionAllow)
        "api.example.com")))
  ("approved_with_network_policy_allow"))

!(assertEqualToResult
  (codex:review-decision-opaque-string
    (codex:review-decision-network-policy-amendment
      (CodexNetworkPolicyAmendment
        (CodexNetworkPolicyRuleActionDeny)
        "blocked.example.com")))
  ("denied_with_network_policy_deny"))

!(assertEqualToResult
  (codex:review-decision-opaque-string
    (codex:review-decision-denied))
  ("denied"))

!(assertEqualToResult
  (codex:review-decision-opaque-string
    (codex:review-decision-timed-out))
  ("timed_out"))

!(assertEqualToResult
  (codex:review-decision-opaque-string
    (codex:review-decision-abort))
  ("abort"))
