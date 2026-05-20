!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:mcp_tool_approval_templates)

(= (test:mcp-approval-calendar-template)
   (codex:consequential-tool-message-template
     "calendar"
     "codex_apps"
     "create_event"
     "Allow {connector_name} to create an event?"
     ((codex:consequential-tool-template-param
        "calendar_id"
        "Calendar")
      (codex:consequential-tool-template-param
        "title"
        "Title"))))

(= (test:mcp-approval-github-template)
   (codex:consequential-tool-message-template
     "github"
     "codex_apps"
     "add_comment"
     "Allow GitHub to add a comment to a pull request?"
     ()))

(= (test:mcp-approval-templates)
   ((test:mcp-approval-calendar-template)
    (test:mcp-approval-github-template)))

(= (test:mcp-approval-tool-params)
   (JsonObject
     ((JsonPair "title" (JsonString "Roadmap review"))
      (JsonPair "calendar_id" (JsonString "primary"))
      (JsonPair "timezone" (JsonString "UTC")))))

(= (test:mcp-approval-rendered)
   (codex:render-mcp-tool-approval-template-from-templates
     (test:mcp-approval-templates)
     "codex_apps"
     "calendar"
     "Calendar"
     " create_event "
     (test:mcp-approval-tool-params)))

(= (test:mcp-approval-display-names $rendered)
   (let $display-params
     (eval
       (codex:rendered-mcp-tool-approval-template-tool-params-display
         $rendered))
     (map-atom-strict
       $display-params
       $param
       (codex:rendered-mcp-tool-approval-param-display-name $param))))

(= (test:mcp-approval-display-param-names $rendered)
   (let $display-params
     (eval
       (codex:rendered-mcp-tool-approval-template-tool-params-display
         $rendered))
     (map-atom-strict
       $display-params
       $param
       (codex:rendered-mcp-tool-approval-param-name $param))))

!(assertEqualToResult
  (codex:rendered-mcp-tool-approval-template-question
    (test:mcp-approval-rendered))
  ("Allow Calendar to create an event?"))

!(assertEqualToResult
  (codex:rendered-mcp-tool-approval-template-elicitation-message
    (test:mcp-approval-rendered))
  ("Allow Calendar to create an event?"))

!(assertEqualToResult
  (json-stringify
    (codex:rendered-mcp-tool-approval-template-tool-params
      (test:mcp-approval-rendered)))
  ("{\"title\":\"Roadmap review\",\"calendar_id\":\"primary\",\"timezone\":\"UTC\"}"))

!(assertEqualToResult
  (test:mcp-approval-display-param-names (test:mcp-approval-rendered))
  (("calendar_id" "title" "timezone")))

!(assertEqualToResult
  (test:mcp-approval-display-names (test:mcp-approval-rendered))
  (("Calendar" "Title" "timezone")))

!(assertEqualToResult
  (codex:render-mcp-tool-approval-template-from-templates
    (test:mcp-approval-templates)
    "codex_apps"
    "calendar"
    "Calendar"
    "delete_event"
    (JsonObject ()))
  (Empty))

!(assertEqualToResult
  (codex:render-mcp-tool-approval-template-from-templates
    ((codex:consequential-tool-message-template
       "calendar"
       "codex_apps"
       "create_event"
       "Allow {connector_name} to create an event?"
       ((codex:consequential-tool-template-param
          "calendar_id"
          "timezone"))))
    "codex_apps"
    "calendar"
    "Calendar"
    "create_event"
    (JsonObject
      ((JsonPair "calendar_id" (JsonString "primary"))
       (JsonPair "timezone" (JsonString "UTC")))))
  (Empty))

!(assertEqualToResult
  (codex:rendered-mcp-tool-approval-template-question
    (codex:render-mcp-tool-approval-template-from-templates
      (test:mcp-approval-templates)
      "codex_apps"
      "github"
      CodexAbsent
      "add_comment"
      (JsonObject ())))
  ("Allow GitHub to add a comment to a pull request?"))

!(assertEqualToResult
  (codex:render-mcp-tool-approval-template-from-templates
    (test:mcp-approval-templates)
    "codex_apps"
    "calendar"
    CodexAbsent
    "create_event"
    (JsonObject ()))
  (Empty))

!(assertEqualToResult
  (codex:render-mcp-tool-approval-template-from-templates
    (test:mcp-approval-templates)
    "codex_apps"
    "calendar"
    "Calendar"
    "create_event"
    (JsonString "not an object"))
  (Empty))

!(assertEqualToResult
  (codex:rendered-mcp-tool-approval-template-tool-params-display
    (codex:render-mcp-tool-approval-template-from-templates
      (test:mcp-approval-templates)
      "codex_apps"
      "calendar"
      "Calendar"
      "create_event"
      CodexAbsent))
  (()))

!(assertEqualToResult
  (codex:rendered-mcp-tool-approval-template-tool-params
    (codex:render-mcp-tool-approval-template-from-templates
      (test:mcp-approval-templates)
      "codex_apps"
      "calendar"
      "Calendar"
      "create_event"
      CodexAbsent))
  (CodexAbsent))

!(assertEqualToResult
  (codex:load-consequential-tool-message-templates-from-json
    (json-parse
      "{\"schema_version\":4,\"templates\":[{\"source_tool_index\":0,\"connector_id\":\"calendar\",\"server_name\":\"codex_apps\",\"tool_title\":\"create_event\",\"template_params\":[{\"name\":\"calendar_id\",\"label\":\"Calendar\"}],\"template\":\"Allow {connector_name} to create an event?\"}]}"))
  (((CodexConsequentialToolMessageTemplate
      "calendar"
      "codex_apps"
      "create_event"
      "Allow {connector_name} to create an event?"
      ((CodexConsequentialToolTemplateParam "calendar_id" "Calendar"))))))

!(assertEqualToResult
  (codex:load-consequential-tool-message-templates-from-json
    (json-parse "{\"schema_version\":3,\"templates\":[]}"))
  (Empty))
