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
  (codex:session-granular-approval-config-allows-sandbox-approval
    (codex:session-approval-policy-granular-config
      True
      False
      True
      False
      True))
  (True))

!(assertEqualToResult
  (codex:session-granular-approval-config-allows-rules-approval
    (codex:session-approval-policy-granular-config
      True
      False
      True
      False
      True))
  (False))

!(assertEqualToResult
  (codex:session-granular-approval-config-allows-skill-approval
    (codex:session-approval-policy-granular-config
      True
      False
      True
      False
      True))
  (True))

!(assertEqualToResult
  (codex:session-granular-approval-config-allows-request-permissions
    (codex:session-approval-policy-granular-config
      True
      False
      True
      False
      True))
  (False))

!(assertEqualToResult
  (codex:session-granular-approval-config-allows-mcp-elicitations
    (codex:session-approval-policy-granular-config
      True
      False
      True
      False
      True))
  (True))

!(assertEqualToResult
  (codex:session-network-access-is-enabled
    (codex:session-network-access-enabled))
  (True))

!(assertEqualToResult
  (codex:session-network-access-is-enabled
    (codex:session-network-access-restricted))
  (False))

!(assertEqualToResult
  (codex:session-read-only-access-has-full-disk-read-access
    (codex:session-read-only-access-full))
  (True))

!(assertEqualToResult
  (codex:session-read-only-access-has-full-disk-read-access
    (codex:session-read-only-access-restricted
      True
      ("/repo")))
  (False))

!(assertEqualToResult
  (codex:session-read-only-access-include-platform-defaults
    (codex:session-read-only-access-full))
  (False))

!(assertEqualToResult
  (codex:session-read-only-access-include-platform-defaults
    (codex:session-read-only-access-restricted
      True
      ("/repo")))
  (True))

!(assertEqualToResult
  (codex:session-sandbox-policy-has-full-disk-read-access
    (codex:session-sandbox-policy-danger-full-access))
  (True))

!(assertEqualToResult
  (codex:session-sandbox-policy-has-full-disk-write-access
    (codex:session-sandbox-policy-danger-full-access))
  (True))

!(assertEqualToResult
  (codex:session-sandbox-policy-has-full-network-access
    (codex:session-sandbox-policy-danger-full-access))
  (True))

!(assertEqualToResult
  (codex:session-sandbox-policy-include-platform-defaults
    (codex:session-sandbox-policy-danger-full-access))
  (False))

!(assertEqualToResult
  (codex:session-sandbox-policy-has-full-disk-read-access
    (codex:session-sandbox-policy-external-sandbox
      (codex:session-network-access-enabled)))
  (True))

!(assertEqualToResult
  (codex:session-sandbox-policy-has-full-disk-write-access
    (codex:session-sandbox-policy-external-sandbox
      (codex:session-network-access-restricted)))
  (True))

!(assertEqualToResult
  (codex:session-sandbox-policy-has-full-network-access
    (codex:session-sandbox-policy-external-sandbox
      (codex:session-network-access-restricted)))
  (False))

!(assertEqualToResult
  (codex:session-sandbox-policy-has-full-network-access
    (codex:session-sandbox-policy-external-sandbox
      (codex:session-network-access-enabled)))
  (True))

!(assertEqualToResult
  (codex:session-sandbox-policy-has-full-disk-read-access
    (codex:session-sandbox-policy-read-only
      (codex:session-read-only-access-restricted
        True
        ("/repo"))
      False))
  (False))

!(assertEqualToResult
  (codex:session-sandbox-policy-has-full-disk-write-access
    (codex:session-sandbox-policy-read-only
      (codex:session-read-only-access-full)
      True))
  (False))

!(assertEqualToResult
  (codex:session-sandbox-policy-has-full-network-access
    (codex:session-sandbox-policy-read-only
      (codex:session-read-only-access-full)
      True))
  (True))

!(assertEqualToResult
  (codex:session-sandbox-policy-include-platform-defaults
    (codex:session-sandbox-policy-read-only
      (codex:session-read-only-access-restricted
        True
        ("/repo"))
      False))
  (True))

!(assertEqualToResult
  (codex:session-sandbox-policy-has-full-disk-read-access
    (codex:session-sandbox-policy-workspace-write
      ()
      (codex:session-read-only-access-full)
      False
      False
      False))
  (True))

!(assertEqualToResult
  (codex:session-sandbox-policy-has-full-disk-write-access
    (codex:session-sandbox-policy-workspace-write
      ()
      (codex:session-read-only-access-full)
      False
      False
      False))
  (False))

!(assertEqualToResult
  (codex:session-sandbox-policy-has-full-network-access
    (codex:session-sandbox-policy-workspace-write
      ()
      (codex:session-read-only-access-restricted
        False
        ("/repo"))
      True
      False
      False))
  (True))

!(assertEqualToResult
  (codex:session-sandbox-policy-include-platform-defaults
    (codex:session-sandbox-policy-workspace-write
      ()
      (codex:session-read-only-access-restricted
        False
        ("/repo"))
      True
      False
      False))
  (False))

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

!(assertEqualToResult
  (json-stringify
    (codex:file-change-json
      (codex:file-change-add "new file contents\n")))
  ("{\"type\":\"add\",\"content\":\"new file contents\\n\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:file-change-json
      (codex:file-change-delete "old file contents\n")))
  ("{\"type\":\"delete\",\"content\":\"old file contents\\n\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:file-change-json
      (codex:file-change-update
        "@@ -1 +1 @@\n-old\n+new\n"
        CodexAbsent)))
  ("{\"type\":\"update\",\"unified_diff\":\"@@ -1 +1 @@\\n-old\\n+new\\n\",\"move_path\":null}"))

!(assertEqualToResult
  (json-stringify
    (codex:file-change-json
      (codex:file-change-update
        "@@ -1 +1 @@\n-old\n+new\n"
        "src/new_name.rs")))
  ("{\"type\":\"update\",\"unified_diff\":\"@@ -1 +1 @@\\n-old\\n+new\\n\",\"move_path\":\"src/new_name.rs\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:file-changes-json
      ((codex:file-change-add "a")
       (codex:file-change-delete "b"))))
  ("[{\"type\":\"add\",\"content\":\"a\"},{\"type\":\"delete\",\"content\":\"b\"}]"))

!(assertEqualToResult
  (json-stringify
    (codex:chunk-json
      (codex:chunk
        7
        ("-stale line" "-older line")
        ("+fresh line"))))
  ("{\"orig_index\":7,\"deleted_lines\":[\"-stale line\",\"-older line\"],\"inserted_lines\":[\"+fresh line\"]}"))

!(assertEqualToResult
  (json-stringify
    (codex:chunks-json
      ((codex:chunk 1 () ("+intro"))
       (codex:chunk 3 ("-outdated") ("+current")))))
  ("[{\"orig_index\":1,\"deleted_lines\":[],\"inserted_lines\":[\"+intro\"]},{\"orig_index\":3,\"deleted_lines\":[\"-outdated\"],\"inserted_lines\":[\"+current\"]}]"))
