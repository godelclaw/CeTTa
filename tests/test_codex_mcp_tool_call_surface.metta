!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:mcp_tool_call)
!(import! &self codex:mcp_tool_approval_templates)
!(import! &self codex:protocol)
!(import! &self codex:request_user_input)

(= (test:mcp-option-label
      (CodexRequestUserInputQuestionOption $label $description))
   $label)

(= (test:mcp-option-labels $question)
   (let $options
     (eval (codex:request-user-input-question-options $question))
     (map-atom-strict
       $options
       $option
       (test:mcp-option-label $option))))

(= (test:mcp-metadata)
   (codex:mcp-tool-approval-metadata
     "calendar"
     "Calendar"
     "Calendar connector"
     "create_event"
     "Create a calendar event"))

(= (test:mcp-full-metadata)
   (codex:mcp-tool-approval-metadata-full
     (codex:mcp-tool-annotations False True CodexAbsent)
     "calendar"
     "Calendar"
     "Calendar connector"
     "create_event"
     "Create a calendar event"
     CodexAbsent
     (JsonObject
       ((JsonPair
          "resource_uri"
          (JsonString "connector://calendar/tools/calendar_create_event"))
        (JsonPair "contains_mcp_source" (JsonBool True))
        (JsonPair "connector_id" (JsonString "calendar"))))
     CodexAbsent))

!(assertEqualToResult
  (codex:is-mcp-tool-approval-question-id "mcp_tool_call_approval_call-1")
  (True))

!(assertEqualToResult
  (codex:is-mcp-tool-approval-question-id "mcp_tool_call_approval")
  (False))

!(assertEqualToResult
  (codex:build-mcp-tool-approval-fallback-message
    "custom_server"
    "run_action"
    CodexAbsent)
  ("Allow the custom_server MCP server to run tool \"run_action\"?"))

!(assertEqualToResult
  (codex:build-mcp-tool-approval-fallback-message
    "codex_apps"
    "run_action"
    CodexAbsent)
  ("Allow this app to run tool \"run_action\"?"))

!(assertEqualToResult
  (codex:build-mcp-tool-approval-fallback-message
    "codex_apps"
    "run_action"
    "  Calendar  ")
  ("Allow Calendar to run tool \"run_action\"?"))

!(assertEqualToResult
  (codex:request-user-input-question-text
    (codex:build-mcp-tool-approval-question
      "mcp_tool_call_approval_call-1"
      "custom_server"
      "run_action"
      CodexAbsent
      (codex:mcp-tool-approval-prompt-options False False)
      "Approve this???"))
  ("Approve this?"))

!(assertEqualToResult
  (codex:request-user-input-question-header
    (codex:build-mcp-tool-approval-question
      "mcp_tool_call_approval_call-1"
      "custom_server"
      "run_action"
      CodexAbsent
      (codex:mcp-tool-approval-prompt-options False False)
      CodexAbsent))
  ("Approve app tool call?"))

!(assertEqualToResult
  (test:mcp-option-labels
    (codex:build-mcp-tool-approval-question
      "mcp_tool_call_approval_call-1"
      "custom_server"
      "run_action"
      CodexAbsent
      (codex:mcp-tool-approval-prompt-options False False)
      CodexAbsent))
  (("Allow" "Cancel")))

!(assertEqualToResult
  (test:mcp-option-labels
    (codex:build-mcp-tool-approval-question
      "mcp_tool_call_approval_call-1"
      "custom_server"
      "run_action"
      CodexAbsent
      (codex:mcp-tool-approval-prompt-options True True)
      CodexAbsent))
  (("Allow" "Allow for this session" "Allow and don't ask me again" "Cancel")))

!(assertEqualToResult
  (codex:mcp-tool-approval-prompt-options-allow-persistent-approval
    (codex:mcp-tool-approval-prompt-options-from-keys
      (codex:mcp-tool-approval-key "server" CodexAbsent "tool")
      (codex:mcp-tool-approval-key "server" CodexAbsent "tool")
      False))
  (False))

!(assertEqualToResult
  (codex:mcp-tool-approval-prompt-options-allow-persistent-approval
    (codex:mcp-tool-approval-prompt-options-from-keys
      (codex:mcp-tool-approval-key "server" CodexAbsent "tool")
      (codex:mcp-tool-approval-key "server" CodexAbsent "tool")
      True))
  (True))

!(assertEqualToResult
  (codex:mcp-tool-approval-prompt-options-allow-session-remember
    (codex:mcp-tool-approval-prompt-options-from-keys
      CodexAbsent
      CodexAbsent
      True))
  (False))

!(assertEqualToResult
  (codex:mcp-tool-approval-question-text
    "Allow the tool?"
    "  policy needs review  ")
  ("Tool call needs your approval. Reason: policy needs review"))

!(assertEqualToResult
  (codex:arc-monitor-interrupt-message "  ")
  ("Tool call was cancelled because of safety risks."))

!(assertEqualToResult
  (codex:arc-monitor-interrupt-message "  risky write  ")
  ("Tool call was cancelled because of safety risks: risky write"))

!(assertEqualToResult
  (codex:mcp-tool-approval-callsite-mode
    (codex:app-tool-approval-approve))
  ("mcp_tool_call__always_allow"))

!(assertEqualToResult
  (codex:session-mcp-tool-approval-key
    (codex:mcp-invocation "custom_server" "run_action" CodexAbsent)
    CodexAbsent
    (codex:app-tool-approval-auto))
  ((CodexMcpToolApprovalKey "custom_server" CodexAbsent "run_action")))

!(assertEqualToResult
  (codex:session-mcp-tool-approval-key
    (codex:mcp-invocation "custom_server" "run_action" CodexAbsent)
    CodexAbsent
    (codex:app-tool-approval-prompt))
  (Empty))

!(assertEqualToResult
  (codex:session-mcp-tool-approval-key
    (codex:mcp-invocation "codex_apps" "create_event" CodexAbsent)
    CodexAbsent
    (codex:app-tool-approval-auto))
  (Empty))

!(assertEqualToResult
  (codex:session-mcp-tool-approval-key
    (codex:mcp-invocation "codex_apps" "create_event" CodexAbsent)
    (test:mcp-metadata)
    (codex:app-tool-approval-auto))
  ((CodexMcpToolApprovalKey "codex_apps" "calendar" "create_event")))

!(assertEqualToResult
  (codex:persistent-mcp-tool-approval-key
    (codex:mcp-invocation "codex_apps" "create_event" CodexAbsent)
    (test:mcp-metadata)
    (codex:app-tool-approval-auto))
  ((CodexMcpToolApprovalKey "codex_apps" "calendar" "create_event")))

!(assertEqualToResult
  (codex:build-mcp-tool-approval-display-params
    (JsonObject
      ((JsonPair "zeta" (JsonString "last"))
       (JsonPair "alpha" (JsonNumber 1)))))
  (((CodexRenderedMcpToolApprovalParam "alpha" (JsonNumber 1) "alpha")
    (CodexRenderedMcpToolApprovalParam "zeta" (JsonString "last") "zeta"))))

!(assertEqualToResult
  (codex:build-mcp-tool-approval-display-params (JsonString "nope"))
  (Empty))

!(assertEqualToResult
  (json-stringify
    (codex:build-mcp-tool-call-request-meta-from-current-meta
      (JsonObject
        ((JsonPair "session_id" (JsonString "session-a"))
         (JsonPair "turn_id" (JsonString "turn-a"))))
      "custom_server"
      CodexAbsent))
  ("{\"x-codex-turn-metadata\":{\"session_id\":\"session-a\",\"turn_id\":\"turn-a\"}}"))

!(assertEqualToResult
  (json-stringify
    (codex:build-mcp-tool-call-request-meta-from-current-meta
      (JsonObject
        ((JsonPair "session_id" (JsonString "session-a"))
         (JsonPair "turn_id" (JsonString "turn-a"))))
      "codex_apps"
      (test:mcp-full-metadata)))
  ("{\"x-codex-turn-metadata\":{\"session_id\":\"session-a\",\"turn_id\":\"turn-a\"},\"_codex_apps\":{\"resource_uri\":\"connector://calendar/tools/calendar_create_event\",\"contains_mcp_source\":true,\"connector_id\":\"calendar\"}}"))

!(assertEqualToResult
  (codex:build-mcp-tool-call-request-meta-from-current-meta
    CodexAbsent
    "custom_server"
    CodexAbsent)
  (Empty))

!(assertEqualToResult
  (json-stringify
    (codex:with-mcp-tool-call-thread-id-meta
      (JsonObject
        ((JsonPair "source" (JsonString "test-client"))
         (JsonPair "threadId" (JsonString "stale-thread"))))
      "thread-live"))
  ("{\"source\":\"test-client\",\"threadId\":\"thread-live\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:with-mcp-tool-call-thread-id-meta
      CodexAbsent
      "thread-live"))
  ("{\"threadId\":\"thread-live\"}"))

!(assertEqualToResult
  (codex:with-mcp-tool-call-thread-id-meta
    (JsonString "invalid-meta")
    "thread-live")
  ((JsonString "invalid-meta")))

!(assertEqualToResult
  (case
    (codex:build-guardian-mcp-tool-review-request
      "call-1"
      (codex:mcp-invocation
        "mcp_server"
        "browser_navigate"
        (JsonObject
          ((JsonPair "url" (JsonString "https://example.com")))))
      (codex:mcp-tool-approval-metadata-full
        (codex:mcp-tool-annotations False True CodexAbsent)
        CodexAbsent
        "Playwright"
        CodexAbsent
        "Navigate"
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent))
    (($request
      (case
        (codex:guardian-approval-request-mcp-tool-call-json $request)
        (($json (json-stringify $json)))))))
  ("{\"tool\":\"mcp_tool_call\",\"server\":\"mcp_server\",\"tool_name\":\"browser_navigate\",\"arguments\":{\"url\":\"https://example.com\"},\"connector_name\":\"Playwright\",\"tool_title\":\"Navigate\",\"annotations\":{\"destructive_hint\":true,\"read_only_hint\":false}}"))

!(assertEqualToResult
  (case
    (codex:prepare-arc-request-action
      (codex:mcp-invocation
        "codex_apps"
        "browser_navigate"
        (JsonObject
          ((JsonPair "url" (JsonString "https://example.com")))))
      (codex:mcp-tool-approval-metadata-full
        CodexAbsent
        CodexAbsent
        "Playwright"
        CodexAbsent
        "Navigate"
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent))
    (($json (json-stringify $json))))
  ("{\"tool\":\"mcp_tool_call\",\"server\":\"codex_apps\",\"tool_name\":\"browser_navigate\",\"arguments\":{\"url\":\"https://example.com\"},\"connector_name\":\"Playwright\",\"tool_title\":\"Navigate\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:build-mcp-tool-approval-elicitation-meta
      "custom_server"
      CodexAbsent
      CodexAbsent
      CodexAbsent
      (codex:mcp-tool-approval-prompt-options False False)))
  ("{\"codex_approval_kind\":\"mcp_tool_call\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:build-mcp-tool-approval-elicitation-meta
      "custom_server"
      (codex:mcp-tool-approval-metadata
        CodexAbsent
        CodexAbsent
        CodexAbsent
        "run_action"
        "Run an action")
      (JsonObject ((JsonPair "target" (JsonString "repo"))))
      ((codex:rendered-mcp-tool-approval-param
         "target"
         (JsonString "repo")
         "target"))
      (codex:mcp-tool-approval-prompt-options True True)))
  ("{\"codex_approval_kind\":\"mcp_tool_call\",\"persist\":[\"session\",\"always\"],\"tool_title\":\"run_action\",\"tool_description\":\"Run an action\",\"tool_params\":{\"target\":\"repo\"},\"tool_params_display\":[{\"name\":\"target\",\"value\":\"repo\",\"display_name\":\"target\"}]}"))

!(assertEqualToResult
  (json-stringify
    (codex:build-mcp-tool-approval-elicitation-meta
      "codex_apps"
      (test:mcp-metadata)
      CodexAbsent
      CodexAbsent
      (codex:mcp-tool-approval-prompt-options False True)))
  ("{\"codex_approval_kind\":\"mcp_tool_call\",\"persist\":\"always\",\"tool_title\":\"create_event\",\"tool_description\":\"Create a calendar event\",\"source\":\"connector\",\"connector_id\":\"calendar\",\"connector_name\":\"Calendar\",\"connector_description\":\"Calendar connector\"}"))

!(assertEqualToResult
  (codex:requires-mcp-tool-approval CodexAbsent)
  (True))

!(assertEqualToResult
  (codex:requires-mcp-tool-approval
    (codex:mcp-tool-annotations True CodexAbsent CodexAbsent))
  (False))

!(assertEqualToResult
  (codex:requires-mcp-tool-approval
    (codex:mcp-tool-annotations True True False))
  (True))

!(assertEqualToResult
  (codex:requires-mcp-tool-approval
    (codex:mcp-tool-annotations False False True))
  (True))

!(assertEqualToResult
  (codex:requires-mcp-tool-approval
    (codex:mcp-tool-annotations CodexAbsent False False))
  (False))

!(assertEqualToResult
  (codex:mcp-tool-approval-decision-from-guardian
    (codex:review-decision-approved)
    "guardian rejected"
    "guardian timed out")
  ((CodexMcpToolApprovalDecisionAccept)))

!(assertEqualToResult
  (codex:mcp-tool-approval-decision-from-guardian
    (codex:review-decision-approved-for-session)
    "guardian rejected"
    "guardian timed out")
  ((CodexMcpToolApprovalDecisionAcceptForSession)))

!(assertEqualToResult
  (codex:mcp-tool-approval-decision-from-guardian
    (codex:review-decision-denied)
    "guardian rejected"
    "guardian timed out")
  ((CodexMcpToolApprovalDecisionDecline "guardian rejected")))

!(assertEqualToResult
  (codex:mcp-tool-approval-decision-from-guardian
    (codex:review-decision-timed-out)
    "guardian rejected"
    "guardian timed out")
  ((CodexMcpToolApprovalDecisionDecline "guardian timed out")))

!(assertEqualToResult
  (codex:mcp-tool-approval-decision-from-guardian
    (codex:review-decision-abort)
    "guardian rejected"
    "guardian timed out")
  ((CodexMcpToolApprovalDecisionDecline CodexAbsent)))
