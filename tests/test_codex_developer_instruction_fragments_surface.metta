!(register-module! ../codex)
!(import! &self json)
!(import! &self str)
!(import! &self codex:context_fragment)
!(import! &self codex:protocol)
!(import! &self codex:request_user_input)

(= (codex-dif-contains-text $text $needle)
   (if (== (str-find $text $needle) Empty)
       False
       True))

!(assertEqualToResult
  (codex:apps-mcp-server-name)
  ("codex_apps"))

!(assertEqualToResult
  (codex:app-info-is-accessible
    (codex:app-info "calendar" "Calendar" True False))
  (True))

!(assertEqualToResult
  (codex:app-info-is-enabled
    (codex:app-info "calendar" "Calendar" True False))
  (False))

!(assertEqualToResult
  (codex-dif-contains-text
    (codex:contextual-fragment-render
      (codex:apps-instructions-from-connectors
        ((codex:app-info "calendar" "Calendar" False True)
         (codex:app-info "drive" "Drive" True True))))
    "<apps_instructions>")
  (True))

!(assertEqualToResult
  (codex-dif-contains-text
    (codex:contextual-fragment-render
      (codex:apps-instructions-from-connectors
        ((codex:app-info "calendar" "Calendar" False True)
         (codex:app-info "drive" "Drive" True True))))
    "`[$app-name](app://{connector_id})`")
  (True))

!(assertEqualToResult
  (codex-dif-contains-text
    (codex:contextual-fragment-render
      (codex:apps-instructions-from-connectors
        ((codex:app-info "calendar" "Calendar" False True)
         (codex:app-info "drive" "Drive" True True))))
    "`codex_apps` MCP")
  (True))

!(assertEqualToResult
  (codex-dif-contains-text
    (codex:contextual-fragment-render
      (codex:apps-instructions-from-connectors
        ((codex:app-info "calendar" "Calendar" False True)
         (codex:app-info "drive" "Drive" True True))))
    "Do not additionally call list_mcp_resources or list_mcp_resource_templates for apps.")
  (True))

!(assertEqualToResult
  (codex:apps-instructions-from-connectors
    ((codex:app-info "calendar" "Calendar" False True)
     (codex:app-info "drive" "Drive" True False)))
  (Empty))

!(assertEqualToResult
  (codex:apps-instructions-matches-text
    " <APPS_INSTRUCTIONS>\nbody\n</apps_instructions> ")
  (True))

!(assertEqualToResult
  (codex:contextual-fragment-role
    (codex:apps-instructions))
  ("developer"))

!(assertEqualToResult
  (codex:contextual-fragment-render
    (codex:plugin-instructions
      "Use the plugin's underlying tools."))
  ("Use the plugin's underlying tools."))

!(assertEqualToResult
  (codex:plugin-instructions-matches-text
    "Use the plugin's underlying tools.")
  (False))

!(assertEqualToResult
  (codex:contextual-fragment-role
    (codex:plugin-instructions
      "Use the plugin's underlying tools."))
  ("developer"))

!(assertEqualToResult
  (codex:settings-developer-instructions
    (codex:settings "gpt-5.4" CodexAbsent "collab instructions"))
  ("collab instructions"))

!(assertEqualToResult
  (codex:collaboration-mode-kind
    (codex:collaboration-mode
      (codex:collaboration-mode-default)
      (codex:settings "gpt-5.4" CodexAbsent "collab instructions")))
  ("Default"))

!(assertEqualToResult
  (codex:contextual-fragment-render
    (codex:collaboration-mode-instructions-from-collaboration-mode
      (codex:collaboration-mode
        (codex:collaboration-mode-plan)
        (codex:settings "gpt-5.4" CodexAbsent "Plan mode instructions."))))
  ("<collaboration_mode>Plan mode instructions.</collaboration_mode>"))

!(assertEqualToResult
  (codex:collaboration-mode-instructions-from-collaboration-mode
    (codex:collaboration-mode
      (codex:collaboration-mode-default)
      (codex:settings "gpt-5.4" CodexAbsent "")))
  (Empty))

!(assertEqualToResult
  (codex:collaboration-mode-instructions-from-collaboration-mode
    (codex:collaboration-mode
      (codex:collaboration-mode-default)
      (codex:settings "gpt-5.4" CodexAbsent CodexAbsent)))
  (Empty))

!(assertEqualToResult
  (codex:collaboration-mode-instructions-matches-text
    "<COLLABORATION_MODE>body</collaboration_mode>")
  (True))
