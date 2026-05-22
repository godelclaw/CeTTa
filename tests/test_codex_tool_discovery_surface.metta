!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:mcp_tool_call)
!(import! &self codex:tool_discovery)
!(import! &self codex:tool_registry_plan)
!(import! &self codex:tool_search_entry)

(= (test:calendar-connector)
   (codex:discoverable-tool-connector
     (codex:discoverable-connector-info
       "connector_2128aebfecb84f64a069897515042a44"
       "Google Calendar"
       "Plan events and schedules."
       "https://chatgpt.com/apps/google-calendar/connector_2128aebfecb84f64a069897515042a44"
       False
       True)))

(= (test:gmail-connector)
   (codex:discoverable-tool-connector
     (codex:discoverable-connector-info
       "connector_68df038e0ba48191908c8434991bbac2"
       "Gmail"
       CodexAbsent
       "https://chatgpt.com/apps/gmail/connector_68df038e0ba48191908c8434991bbac2"
       False
       True)))

(= (test:slack-connector)
   (codex:discoverable-tool-connector
     (codex:discoverable-connector-info
       "slack@openai-curated"
       "Slack"
       CodexAbsent
       CodexAbsent
       False
       True)))

(= (test:github-plugin)
   (codex:discoverable-tool-plugin
     (codex:discoverable-plugin-info
       "github"
       "GitHub"
       CodexAbsent
       True
       ("github-mcp")
       ("github-app"))))

(= (test:sample-plugin)
   (codex:discoverable-tool-plugin
     (codex:discoverable-plugin-info
       "sample@openai-curated"
       "Sample Plugin"
       "Includes skills, MCP servers, and apps."
       True
       ("sample-docs")
       ("connector_calendar"))))

(= (test:accessible-calendar)
   (codex:discoverable-connector-info
     "calendar"
     "Google Calendar"
     CodexAbsent
     CodexAbsent
     True
     False))

(= (test:inaccessible-gmail)
   (codex:discoverable-connector-info
     "gmail"
     "Gmail"
     CodexAbsent
     CodexAbsent
     False
     False))

(= (test:tool-suggest-entries)
   ((codex:tool-suggest-entry
      "slack@openai-curated"
      "Slack"
      CodexAbsent
      "connector"
      False
      ()
      ())
    (codex:tool-suggest-entry
      "github"
      "GitHub"
      CodexAbsent
      "plugin"
      True
      ("github-mcp")
      ("github-app"))))

(= (test:tool-search-sources)
   ((codex:tool-search-source-info
      "Google Drive"
      "Use Google Drive as the single entrypoint for Drive, Docs, Sheets, and Slides work.")
    (codex:tool-search-source-info
      "Google Drive"
      CodexAbsent)
    (codex:tool-search-source-info
      "docs"
      CodexAbsent)))

(= (test:tool-search-source-inputs)
   ((codex:tool-search-source
      "mcp_calendar"
      "  Google Calendar  "
      "  Plan events and schedules.  ")
    (codex:tool-search-source
      "  docs  "
      CodexAbsent
      CodexAbsent)
    (codex:tool-search-source
      "  fallback-server  "
      "   "
      "ignored without a connector name")
    (codex:tool-search-source
      "   "
      CodexAbsent
      CodexAbsent)))

(= (test:event-schema)
   (JsonObject
     ((JsonPair "type" (JsonString "object"))
      (JsonPair
        "properties"
        (JsonObject
          ((JsonPair "date" (JsonObject ()))
           (JsonPair "title" (JsonObject ()))))))))

(= (test:schema-without-properties)
   (JsonObject
     ((JsonPair "type" (JsonString "object")))))

(= (test:calendar-mcp-tool)
   (codex:mcp-tool
     "create"
     "Create Event"
     "Create a calendar event."
     (test:event-schema)))

!(assertEqual
  (codex:discoverable-tool-type-connector)
  "connector")

!(assertEqual
  (codex:discoverable-tool-action-install)
  "install")

!(assertEqualToResult
  (unique
    (codex:tool-suggest-args-tool-id
      (codex:tool-suggest-args
        "connector"
        "install"
        "calendar"
        "Plan events")))
  ("calendar"))

!(assertEqualToResult
  (unique
    (codex:tool-suggest-args-suggest-reason
      (codex:tool-suggest-args
        "connector"
        "install"
        "calendar"
        "Plan events")))
  ("Plan events"))

!(assertEqualToResult
  (unique
    (codex:collect-tool-suggest-entries
      ((test:slack-connector) (test:github-plugin))))
  (((CodexToolSuggestEntry
      "slack@openai-curated"
      "Slack"
      CodexAbsent
      "connector"
      False
      ()
      ())
    (CodexToolSuggestEntry
      "github"
      "GitHub"
      CodexAbsent
      "plugin"
      True
      ("github-mcp")
      ("github-app")))))

!(assertEqualToResult
  (unique
    (codex:filter-tool-suggest-discoverable-tools-for-client
      ((test:calendar-connector) (test:sample-plugin))
      (codex:tool-discovery-tui-client-name)))
  (((CodexDiscoverableToolConnector
      (CodexDiscoverableConnectorInfo
        "connector_2128aebfecb84f64a069897515042a44"
        "Google Calendar"
        "Plan events and schedules."
        "https://chatgpt.com/apps/google-calendar/connector_2128aebfecb84f64a069897515042a44"
        False
        True)))))

!(assertEqualToResult
  (unique
    (codex:filter-tool-suggest-discoverable-tools-for-client
      ((test:calendar-connector) (test:sample-plugin))
      CodexAbsent))
  (((CodexDiscoverableToolConnector
      (CodexDiscoverableConnectorInfo
        "connector_2128aebfecb84f64a069897515042a44"
        "Google Calendar"
        "Plan events and schedules."
        "https://chatgpt.com/apps/google-calendar/connector_2128aebfecb84f64a069897515042a44"
        False
        True))
    (CodexDiscoverableToolPlugin
      (CodexDiscoverablePluginInfo
        "sample@openai-curated"
        "Sample Plugin"
        "Includes skills, MCP servers, and apps."
        True
        ("sample-docs")
        ("connector_calendar"))))))

!(assertEqualToResult
  (unique
    (codex:format-discoverable-tools (test:tool-suggest-entries)))
  ("- GitHub (id: `github`, type: plugin, action: install): skills; MCP servers: github-mcp; app connectors: github-app\n- Slack (id: `slack@openai-curated`, type: connector, action: install): No description provided."))

!(assertEqualToResult
  (unique
    (json-stringify
      (json-object-get
        (json-object-get
          (json-object-get
            (codex:tool-spec-json
              (codex:create-tool-suggest-tool (test:tool-suggest-entries)))
            "parameters")
          "properties")
        "tool_id")))
  ("{\"type\":\"string\",\"description\":\"Connector or plugin id to suggest. Must be one of: slack@openai-curated, github.\"}"))

!(assertEqualToResult
  (unique
    (json-stringify
      (json-object-get
        (codex:tool-spec-json
          (codex:create-tool-suggest-tool (test:tool-suggest-entries)))
        "description")))
  ("\"# Tool suggestion discovery\\n\\nSuggests a missing connector in an installed plugin, or in narrower cases a not installed but discoverable plugin, when the user clearly wants a capability that is not currently available in the active `tools` list.\\n\\nUse this ONLY when:\\n- You've already tried to find a matching available tool for the user's request but couldn't find a good match. This includes `tool_search` (if available) and other means.\\n- For connectors/apps that are not installed but needed for an installed plugin, suggest to install them if the task requirements match precisely.\\n- For plugins that are not installed but discoverable, only suggest discoverable and installable plugins when the user's intent very explicitly and unambiguously matches that plugin itself. Do not suggest a plugin just because one of its connectors or capabilities seems relevant.\\n\\nTool suggestions should only use the discoverable tools listed here. DO NOT explore or recommend tools that are not on this list.\\n\\nDiscoverable tools:\\n- GitHub (id: `github`, type: plugin, action: install): skills; MCP servers: github-mcp; app connectors: github-app\\n- Slack (id: `slack@openai-curated`, type: connector, action: install): No description provided.\\n\\nWorkflow:\\n\\n1. Ensure all possible means have been exhausted to find an existing available tool but none of them matches the request intent.\\n2. Match the user's request against the discoverable tools list above. Apply the stricter explicit-and-unambiguous rule for *discoverable tools* like plugin install suggestions; *missing tools* like connector install suggestions continue to use the normal clear-fit standard.\\n3. If one tool clearly fits, call `tool_suggest` with:\\n   - `tool_type`: `connector` or `plugin`\\n   - `action_type`: `install` or `enable`\\n   - `tool_id`: exact id from the discoverable tools list above\\n   - `suggest_reason`: concise one-line user-facing reason this tool can help with the current request\\n4. After the suggestion flow completes:\\n   - if the user finished the install or enable flow, continue by searching again or using the newly available tool\\n   - if the user did not finish, continue without that tool, and don't suggest that tool again unless the user explicitly asks for it.\""))

!(assertEqualToResult
  (unique
    (json-stringify
      (json-object-get
        (json-object-get
          (codex:tool-spec-json
            (codex:create-tool-suggest-tool (test:tool-suggest-entries)))
          "parameters")
        "required")))
  ("[\"tool_type\",\"action_type\",\"tool_id\",\"suggest_reason\"]"))

!(assertEqualToResult
  (unique
    (codex:collect-tool-search-source-infos
      (test:tool-search-source-inputs)))
  (((CodexToolSearchSourceInfo
      "Google Calendar"
      "Plan events and schedules.")
    (CodexToolSearchSourceInfo
      "docs"
      CodexAbsent)
    (CodexToolSearchSourceInfo
      "fallback-server"
      CodexAbsent))))

!(assertEqualToResult
  (unique
    (json-stringify
      (codex:tool-spec-json
        (codex:create-tool-search-tool
          (test:tool-search-sources)
          (codex:tool-search-default-limit)))))
  ("{\"type\":\"tool_search\",\"execution\":\"client\",\"description\":\"# Tool discovery\\n\\nSearches over deferred tool metadata with BM25 and exposes matching tools for the next model call.\\n\\nYou have access to tools from the following sources:\\n- Google Drive: Use Google Drive as the single entrypoint for Drive, Docs, Sheets, and Slides work.\\n- docs\\nSome of the tools may not have been provided to you upfront, and you should use this tool (`tool_search`) to search for the required tools. For MCP tool discovery, always use `tool_search` instead of `list_mcp_resources` or `list_mcp_resource_templates`.\",\"parameters\":{\"type\":\"object\",\"properties\":{\"limit\":{\"type\":\"number\",\"description\":\"Maximum number of tools to return (defaults to 8).\"},\"query\":{\"type\":\"string\",\"description\":\"Search query for deferred tools.\"}},\"required\":[\"query\"],\"additionalProperties\":false}}"))

!(assertEqualToResult
  (unique
    (json-stringify
      (json-object-get
        (codex:tool-spec-json
          (codex:create-tool-search-tool () 8))
        "description")))
  ("\"# Tool discovery\\n\\nSearches over deferred tool metadata with BM25 and exposes matching tools for the next model call.\\n\\nYou have access to tools from the following sources:\\nNone currently enabled.\\nSome of the tools may not have been provided to you upfront, and you should use this tool (`tool_search`) to search for the required tools. For MCP tool discovery, always use `tool_search` instead of `list_mcp_resources` or `list_mcp_resource_templates`.\""))

!(assertEqualToResult
  (unique
    (codex:tool-search-result-source-namespace-description
      (codex:tool-search-result-source
        "calendar"
        "mcp__calendar__"
        "create_event"
        test-tool
        "Google Calendar"
        "  Manage calendar events.  ")))
  ("Manage calendar events."))

!(assertEqualToResult
  (unique
    (codex:tool-search-result-source-namespace-description
      (codex:tool-search-result-source
        "calendar"
        "mcp__calendar__"
        "create_event"
        test-tool
        "  Google Calendar  "
        CodexAbsent)))
  ("Tools for working with Google Calendar."))

!(assertEqualToResult
  (unique
    (codex:tool-search-result-source-namespace-description
      (codex:tool-search-result-source
        "memory"
        "mcp__memory__"
        "read_graph"
        test-tool
        CodexAbsent
        CodexAbsent)))
  ("Tools in the mcp__memory__ namespace."))

!(assertEqualToResult
  (unique
    (json-stringify
      (codex:loadable-tool-spec-json
        (codex:tool-search-result-source-to-loadable-tool-spec
          (codex:tool-search-result-source
            "calendar"
            "mcp__calendar__"
            "create_event"
            (test:calendar-mcp-tool)
            "Google Calendar"
            "  Manage calendar events.  ")))))
  ("{\"type\":\"namespace\",\"name\":\"mcp__calendar__\",\"description\":\"Manage calendar events.\",\"tools\":[{\"type\":\"function\",\"name\":\"create_event\",\"description\":\"Create a calendar event.\",\"strict\":false,\"defer_loading\":true,\"parameters\":{\"type\":\"object\",\"properties\":{\"date\":{},\"title\":{}}}}]}"))

!(assertEqualToResult
  (unique
    (json-stringify
      (codex:function-tool-parameters
        (codex:mcp-tool-to-deferred-responses-api-tool
          "read_graph"
          (codex:mcp-tool
            "read_graph"
            CodexAbsent
            CodexAbsent
            (test:schema-without-properties))))))
  ("{\"type\":\"object\",\"properties\":{}}"))

!(assertEqualToResult
  (unique
    (json-stringify
      (codex:responses-api-tool-json
        (codex:mcp-tool-to-deferred-responses-api-tool
          "read_graph"
          (codex:mcp-tool
            "read_graph"
            CodexAbsent
            CodexAbsent
            (test:schema-without-properties))))))
  ("{\"type\":\"function\",\"name\":\"read_graph\",\"description\":\"\",\"strict\":false,\"defer_loading\":true,\"parameters\":{\"type\":\"object\",\"properties\":{}}}"))

!(assertEqualToResult
  (unique
    (json-stringify
      (codex:tool-suggest-meta-json
        (codex:build-tool-suggestion-meta
          "connector"
          "install"
          "Find and reference emails from your inbox"
          "connector_68df038e0ba48191908c8434991bbac2"
          "Gmail"
          "https://chatgpt.com/apps/gmail/connector_68df038e0ba48191908c8434991bbac2"))))
  ("{\"codex_approval_kind\":\"tool_suggestion\",\"tool_type\":\"connector\",\"suggest_type\":\"install\",\"suggest_reason\":\"Find and reference emails from your inbox\",\"tool_id\":\"connector_68df038e0ba48191908c8434991bbac2\",\"tool_name\":\"Gmail\",\"install_url\":\"https://chatgpt.com/apps/gmail/connector_68df038e0ba48191908c8434991bbac2\"}"))

!(assertEqualToResult
  (unique
    (json-stringify
      (codex:tool-suggest-meta-json
        (codex:build-tool-suggestion-meta
          "plugin"
          "install"
          "Use the sample plugin's skills and MCP server"
          "sample@openai-curated"
          "Sample Plugin"
          CodexAbsent))))
  ("{\"codex_approval_kind\":\"tool_suggestion\",\"tool_type\":\"plugin\",\"suggest_type\":\"install\",\"suggest_reason\":\"Use the sample plugin's skills and MCP server\",\"tool_id\":\"sample@openai-curated\",\"tool_name\":\"Sample Plugin\"}"))

!(assertEqualToResult
  (unique
    (case
      (codex:build-tool-suggestion-elicitation-request
        "codex-apps"
        "thread-1"
        "turn-1"
        (codex:tool-suggest-args
          "connector"
          "install"
          "connector_2128aebfecb84f64a069897515042a44"
          "Plan and reference events from your calendar")
        "Plan and reference events from your calendar"
        (test:calendar-connector))
      (($request
        (json-stringify
          (codex:mcp-server-elicitation-request-json $request))))))
  ("{\"threadId\":\"thread-1\",\"turnId\":\"turn-1\",\"serverName\":\"codex-apps\",\"mode\":\"form\",\"_meta\":{\"codex_approval_kind\":\"tool_suggestion\",\"tool_type\":\"connector\",\"suggest_type\":\"install\",\"suggest_reason\":\"Plan and reference events from your calendar\",\"tool_id\":\"connector_2128aebfecb84f64a069897515042a44\",\"tool_name\":\"Google Calendar\",\"install_url\":\"https://chatgpt.com/apps/google-calendar/connector_2128aebfecb84f64a069897515042a44\"},\"message\":\"Plan and reference events from your calendar\",\"requestedSchema\":{\"type\":\"object\",\"properties\":{}}}"))

!(assertEqualToResult
  (unique
    (case
      (codex:build-tool-suggestion-elicitation-request
        "codex-apps"
        "thread-1"
        "turn-1"
        (codex:tool-suggest-args
          "plugin"
          "install"
          "sample@openai-curated"
          "Use the sample plugin's skills and MCP server")
        "Use the sample plugin's skills and MCP server"
        (test:sample-plugin))
      (($request
        (json-stringify
          (codex:mcp-server-elicitation-request-json $request))))))
  ("{\"threadId\":\"thread-1\",\"turnId\":\"turn-1\",\"serverName\":\"codex-apps\",\"mode\":\"form\",\"_meta\":{\"codex_approval_kind\":\"tool_suggestion\",\"tool_type\":\"plugin\",\"suggest_type\":\"install\",\"suggest_reason\":\"Use the sample plugin's skills and MCP server\",\"tool_id\":\"sample@openai-curated\",\"tool_name\":\"Sample Plugin\"},\"message\":\"Use the sample plugin's skills and MCP server\",\"requestedSchema\":{\"type\":\"object\",\"properties\":{}}}"))

!(assertEqualToResult
  (unique
    (codex:verified-connector-suggestion-completed
      "calendar"
      ((test:accessible-calendar) (test:inaccessible-gmail))))
  (True))

!(assertEqualToResult
  (unique
    (codex:verified-connector-suggestion-completed
      "gmail"
      ((test:accessible-calendar) (test:inaccessible-gmail))))
  (False))

!(assertEqualToResult
  (unique
    (codex:all-suggested-connectors-picked-up
      ("calendar")
      ((test:accessible-calendar) (test:inaccessible-gmail))))
  (True))

!(assertEqualToResult
  (unique
    (codex:all-suggested-connectors-picked-up
      ("calendar" "gmail")
      ((test:accessible-calendar) (test:inaccessible-gmail))))
  (False))

!(assertEqualToResult
  (unique
    (json-stringify
      (codex:tool-suggest-result-json
        (codex:tool-suggest-result
          True
          False
          "connector"
          "install"
          "calendar"
          "Google Calendar"
          "Plan events"))))
  ("{\"completed\":true,\"user_confirmed\":false,\"tool_type\":\"connector\",\"action_type\":\"install\",\"tool_id\":\"calendar\",\"tool_name\":\"Google Calendar\",\"suggest_reason\":\"Plan events\"}"))
