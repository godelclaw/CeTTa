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

(= (test:mcp-event-jsons $events)
   (map-atom-strict
     $events
     $event
     (codex:item-json $event)))

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

(= (test:mcp-image-call-tool-result)
   (codex:mcp-call-tool-result
     ((JsonObject
        ((JsonPair "type" (JsonString "image"))
         (JsonPair "data" (JsonString "Zm9v"))
         (JsonPair "mimeType" (JsonString "image/png"))))
      (JsonObject
        ((JsonPair "type" (JsonString "text"))
         (JsonPair "text" (JsonString "hello")))))
     CodexAbsent
     False
     CodexAbsent))

(= (test:mcp-image-full-call-tool-result)
   (codex:mcp-call-tool-result
     ((JsonObject
        ((JsonPair "type" (JsonString "image"))
         (JsonPair "data" (JsonString "Zm9v"))
         (JsonPair "mimeType" (JsonString "image/png")))))
     (JsonObject ((JsonPair "x" (JsonNumber 1))))
     False
     (JsonObject ((JsonPair "k" (JsonString "v"))))))

!(assertEqualToResult
  (codex:get-mcp-app-resource-uri
    (JsonObject
      ((JsonPair
         "ui"
         (JsonObject
           ((JsonPair
              "resourceUri"
              (JsonString "ui://widget/nested.html"))))))))
  ("ui://widget/nested.html"))

!(assertEqualToResult
  (codex:get-mcp-app-resource-uri
    (JsonObject
      ((JsonPair
         "ui/resourceUri"
         (JsonString "ui://widget/flat.html")))))
  ("ui://widget/flat.html"))

!(assertEqualToResult
  (codex:get-mcp-app-resource-uri
    (JsonObject
      ((JsonPair
         "openai/outputTemplate"
         (JsonString "ui://widget/output-template.html")))))
  ("ui://widget/output-template.html"))

!(assertEqualToResult
  (codex:get-mcp-app-resource-uri
    (JsonObject
      ((JsonPair
         "ui"
         (JsonObject
           ((JsonPair
              "resourceUri"
              (JsonString "ui://widget/nested.html")))))
       (JsonPair
         "ui/resourceUri"
         (JsonString "ui://widget/flat.html"))
       (JsonPair
         "openai/outputTemplate"
         (JsonString "ui://widget/output-template.html")))))
  ("ui://widget/nested.html"))

!(assertEqualToResult
  (codex:get-mcp-app-resource-uri
    (JsonObject
      ((JsonPair
         "ui"
         (JsonObject
           ((JsonPair "resourceUri" (JsonNumber 7))))))))
  (Empty))

!(assertEqualToResult
  (codex:declared-openai-file-input-param-names
    (JsonObject
      ((JsonPair
         "openai/fileParams"
         (JsonArray
           ((JsonString "file")
            (JsonString "")
            (JsonNumber 7)
            (JsonString "input_file")
            (JsonString "attachments")))))))
  (("file" "input_file" "attachments")))

!(assertEqualToResult
  (codex:declared-openai-file-input-param-names
    (JsonObject
      ((JsonPair "other" (JsonString "value")))))
  (()))

!(assertEqualToResult
  (codex:mcp-tool-approval-metadata-mcp-app-resource-uri
    (codex:mcp-tool-approval-metadata-full
      CodexAbsent
      "calendar"
      "Calendar"
      CodexAbsent
      "create_event"
      CodexAbsent
      "ui://widget/calendar.html"
      CodexAbsent
      ("file")))
  ("ui://widget/calendar.html"))

!(assertEqualToResult
  (codex:mcp-tool-approval-metadata-openai-file-input-params
    (codex:mcp-tool-approval-metadata-full
      CodexAbsent
      "calendar"
      "Calendar"
      CodexAbsent
      "create_event"
      CodexAbsent
      "ui://widget/calendar.html"
      CodexAbsent
      ("file" "attachments")))
  (("file" "attachments")))

!(assertEqualToResult
  (case
    (codex:build-mcp-tool-approval-elicitation-request
      "thread-1"
      "turn-1"
      (codex:mcp-tool-approval-elicitation-request
        "codex_apps"
        (codex:mcp-tool-approval-metadata
          "calendar"
          "Calendar"
          "Manage events and schedules."
          "Create Event"
          "Create a calendar event.")
        (JsonObject
          ((JsonPair "calendar_id" (JsonString "primary"))
           (JsonPair "title" (JsonString "Roadmap review"))))
        ((codex:rendered-mcp-tool-approval-param
           "calendar_id"
           (JsonString "primary")
           "Calendar")
         (codex:rendered-mcp-tool-approval-param
           "title"
           (JsonString "Roadmap review")
           "Title"))
        (codex:build-mcp-tool-approval-question
          "q"
          "codex_apps"
          "create_event"
          "Calendar"
          (codex:mcp-tool-approval-prompt-options True True)
          "Allow Calendar to create an event?")
        "Allow Calendar to create an event?"
        (codex:mcp-tool-approval-prompt-options True True)))
    (($request
      (json-stringify
        (codex:mcp-server-elicitation-request-json $request)))))
  ("{\"threadId\":\"thread-1\",\"turnId\":\"turn-1\",\"serverName\":\"codex_apps\",\"mode\":\"form\",\"_meta\":{\"codex_approval_kind\":\"mcp_tool_call\",\"persist\":[\"session\",\"always\"],\"tool_title\":\"Create Event\",\"tool_description\":\"Create a calendar event.\",\"source\":\"connector\",\"connector_id\":\"calendar\",\"connector_name\":\"Calendar\",\"connector_description\":\"Manage events and schedules.\",\"tool_params\":{\"calendar_id\":\"primary\",\"title\":\"Roadmap review\"},\"tool_params_display\":[{\"name\":\"calendar_id\",\"value\":\"primary\",\"display_name\":\"Calendar\"},{\"name\":\"title\",\"value\":\"Roadmap review\",\"display_name\":\"Title\"}]},\"message\":\"Allow Calendar to create an event?\",\"requestedSchema\":{\"type\":\"object\",\"properties\":{}}}"))

!(assertEqualToResult
  (case
    (codex:build-mcp-tool-approval-elicitation-request
      "thread-2"
      "turn-2"
      (codex:mcp-tool-approval-elicitation-request
        "custom_server"
        CodexAbsent
        CodexAbsent
        CodexAbsent
        (codex:build-mcp-tool-approval-question
          "q"
          "custom_server"
          "run_action"
          CodexAbsent
          (codex:mcp-tool-approval-prompt-options False False)
          CodexAbsent)
        CodexAbsent
        (codex:mcp-tool-approval-prompt-options False False)))
    (((CodexMcpServerElicitationRequestParams
        $thread-id
        $turn-id
        $server-name
        (CodexMcpServerElicitationRequestForm
          $meta
          $message
          $schema))
      $message)))
  ("Allow the custom_server MCP server to run tool \"run_action\"?"))

!(assertEqualToResult
  (codex:is-mcp-tool-approval-question-id "mcp_tool_call_approval_call-1")
  (True))

!(assertEqualToResult
  (case
    (codex:sanitize-mcp-tool-result-for-model
      False
      (codex:mcp-tool-call-result-ok (test:mcp-image-call-tool-result)))
    (((CodexMcpToolCallResultOk $result)
      (case
        (codex:mcp-call-tool-result-json $result)
        (($json (json-stringify $json)))))))
  ("{\"content\":[{\"type\":\"text\",\"text\":\"<image content omitted because you do not support image input>\"},{\"type\":\"text\",\"text\":\"hello\"}],\"isError\":false}"))

!(assertEqualToResult
  (case
    (codex:sanitize-mcp-tool-result-for-model
      True
      (codex:mcp-tool-call-result-ok (test:mcp-image-full-call-tool-result)))
    (((CodexMcpToolCallResultOk $result)
      (case
        (codex:mcp-call-tool-result-json $result)
        (($json (json-stringify $json)))))))
  ("{\"content\":[{\"type\":\"image\",\"data\":\"Zm9v\",\"mimeType\":\"image/png\"}],\"structuredContent\":{\"x\":1},\"isError\":false,\"_meta\":{\"k\":\"v\"}}"))

!(assertEqualToResult
  (codex:sanitize-mcp-tool-result-for-model
    False
    (codex:mcp-tool-call-result-err "tool call failed"))
  ((CodexMcpToolCallResultErr "tool call failed")))

!(assertEqualToResult
  (case
    (codex:notify-mcp-tool-call-skip-plan
      "call-skip"
      (codex:mcp-invocation
        "memory"
        "read_graph"
        (JsonObject ((JsonPair "id" (JsonNumber 1)))))
      "app://memory"
      "not approved"
      False)
    (((CodexMcpToolCallSkipPlan $events $result)
      (json-stringify (JsonArray (test:mcp-event-jsons $events))))))
  ("[{\"type\":\"mcp_tool_call_begin\",\"call_id\":\"call-skip\",\"invocation\":{\"server\":\"memory\",\"tool\":\"read_graph\",\"arguments\":{\"id\":1}},\"mcp_app_resource_uri\":\"app://memory\"},{\"type\":\"mcp_tool_call_end\",\"call_id\":\"call-skip\",\"invocation\":{\"server\":\"memory\",\"tool\":\"read_graph\",\"arguments\":{\"id\":1}},\"mcp_app_resource_uri\":\"app://memory\",\"duration\":{\"secs\":0,\"nanos\":0},\"result\":{\"Err\":\"not approved\"}}]"))

!(assertEqualToResult
  (case
    (codex:notify-mcp-tool-call-skip-plan
      "call-skip-started"
      (codex:mcp-invocation
        "memory"
        "read_graph"
        CodexAbsent)
      CodexAbsent
      "cancelled"
      True)
    (((CodexMcpToolCallSkipPlan $events $result)
      (json-stringify (JsonArray (test:mcp-event-jsons $events))))))
  ("[{\"type\":\"mcp_tool_call_end\",\"call_id\":\"call-skip-started\",\"invocation\":{\"server\":\"memory\",\"tool\":\"read_graph\",\"arguments\":null},\"duration\":{\"secs\":0,\"nanos\":0},\"result\":{\"Err\":\"cancelled\"}}]"))

!(assertEqualToResult
  (codex:mcp-tool-call-skip-plan-result
    (codex:notify-mcp-tool-call-skip-plan
      "call-skip-started"
      (codex:mcp-invocation
        "memory"
        "read_graph"
        CodexAbsent)
      CodexAbsent
      "cancelled"
      True))
  ((CodexMcpToolCallResultErr "cancelled")))

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
  (codex:custom-mcp-tool-approval-mode
    ((codex:mcp-tool-approval-server-entry
       "docs"
       (codex:mcp-tool-approval-server-config
         (codex:app-tool-approval-approve)
         ((codex:mcp-tool-approval-tool-entry
            "search"
            (codex:mcp-tool-approval-tool-config
              (codex:app-tool-approval-prompt)))))))
    "docs"
    "read")
  ((CodexAppToolApprovalApprove)))

!(assertEqualToResult
  (codex:custom-mcp-tool-approval-mode
    ((codex:mcp-tool-approval-server-entry
       "docs"
       (codex:mcp-tool-approval-server-config
         (codex:app-tool-approval-approve)
         ((codex:mcp-tool-approval-tool-entry
            "search"
            (codex:mcp-tool-approval-tool-config
              (codex:app-tool-approval-prompt)))))))
    "docs"
    "search")
  ((CodexAppToolApprovalPrompt)))

!(assertEqualToResult
  (codex:custom-mcp-tool-approval-mode
    ((codex:mcp-tool-approval-server-entry
       "docs"
       (codex:mcp-tool-approval-server-config
         (codex:app-tool-approval-prompt)
         ((codex:mcp-tool-approval-tool-entry
            "search"
            (codex:mcp-tool-approval-tool-config CodexAbsent))))))
    "docs"
    "search")
  ((CodexAppToolApprovalPrompt)))

!(assertEqualToResult
  (codex:custom-mcp-tool-approval-mode
    ((codex:mcp-tool-approval-server-entry
       "docs"
       (codex:mcp-tool-approval-server-config
         CodexAbsent
         ((codex:mcp-tool-approval-tool-entry
            "search"
            (codex:mcp-tool-approval-tool-config
              (codex:app-tool-approval-approve)))))))
    "docs"
    "search")
  ((CodexAppToolApprovalApprove)))

!(assertEqualToResult
  (codex:custom-mcp-tool-approval-mode
    ((codex:mcp-tool-approval-server-entry
       "docs"
       (codex:mcp-tool-approval-server-config
         (codex:app-tool-approval-approve)
         ())))
    "unknown"
    "search")
  ((CodexAppToolApprovalAuto)))

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
