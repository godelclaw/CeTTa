!(register-module! ../codex)
!(import! &self str)
!(import! &self codex:context_fragment)

(= (codex-aci-contains-text $text $needle)
   (if (== (str-find $text $needle) Empty)
       False
       True))

!(assertEqualToResult
  (codex-aci-contains-text
    (codex:contextual-fragment-render
      (codex:available-skills-instructions
        ("- `imagegen`: Generate or edit raster images. (file: /tmp/imagegen/SKILL.md)"
         "- `openai-docs`: Use official OpenAI docs. (file: /tmp/openai-docs/SKILL.md)")))
    "<skills_instructions>")
  (True))

!(assertEqualToResult
  (codex-aci-contains-text
    (codex:contextual-fragment-render
      (codex:available-skills-instructions
        ("- `imagegen`: Generate or edit raster images. (file: /tmp/imagegen/SKILL.md)"
         "- `openai-docs`: Use official OpenAI docs. (file: /tmp/openai-docs/SKILL.md)")))
    "### Available skills")
  (True))

!(assertEqualToResult
  (codex-aci-contains-text
    (codex:contextual-fragment-render
      (codex:available-skills-instructions
        ("- `imagegen`: Generate or edit raster images. (file: /tmp/imagegen/SKILL.md)"
         "- `openai-docs`: Use official OpenAI docs. (file: /tmp/openai-docs/SKILL.md)")))
    "- `imagegen`: Generate or edit raster images. (file: /tmp/imagegen/SKILL.md)")
  (True))

!(assertEqualToResult
  (codex-aci-contains-text
    (codex:contextual-fragment-render
      (codex:available-skills-instructions
        ("- `imagegen`: Generate or edit raster images. (file: /tmp/imagegen/SKILL.md)"
         "- `openai-docs`: Use official OpenAI docs. (file: /tmp/openai-docs/SKILL.md)")))
    "How to use a skill (progressive disclosure)")
  (True))

!(assertEqualToResult
  (codex:available-skills-skill-lines
    (codex:available-skills
      ("- `imagegen`: Generate or edit raster images. (file: /tmp/imagegen/SKILL.md)"
       "- `openai-docs`: Use official OpenAI docs. (file: /tmp/openai-docs/SKILL.md)")))
  (("- `imagegen`: Generate or edit raster images. (file: /tmp/imagegen/SKILL.md)"
    "- `openai-docs`: Use official OpenAI docs. (file: /tmp/openai-docs/SKILL.md)")))

!(assertEqualToResult
  (codex:available-skills-instructions-matches-text
    " <SKILLS_INSTRUCTIONS>\nbody\n</skills_instructions> ")
  (True))

!(assertEqualToResult
  (codex:contextual-fragment-role
    (codex:available-skills-instructions
      ("- `imagegen`: Generate or edit raster images. (file: /tmp/imagegen/SKILL.md)")))
  ("developer"))

!(assertEqualToResult
  (codex:plugin-capability-summary-config-name
    (codex:plugin-capability-summary
      "local_tools"
      "Local Tools"
      "Filesystem and shell helpers"
      True
      ("fs")
      ((codex:app-connector-id "jira"))))
  ("local_tools"))

!(assertEqualToResult
  (codex:app-connector-id-text
    (codex:app-connector-id "jira"))
  ("jira"))

!(assertEqualToResult
  (codex:contextual-fragment-render
    (codex:available-plugins-instructions-from-plugins
      ((codex:plugin-capability-summary
         "local_tools"
         "Local Tools"
         "Filesystem and shell helpers"
         True
         ("fs" "shell")
         ((codex:app-connector-id "jira")))
       (codex:plugin-capability-summary
         "docs"
         "Docs"
         CodexAbsent
         False
         ()
         ()))))
  ("<plugins_instructions>\n## Plugins\nA plugin is a local bundle of skills, MCP servers, and apps. Below is the list of plugins that are enabled and available in this session.\n### Available plugins\n- `Local Tools`: Filesystem and shell helpers\n- `Docs`\n### How to use plugins\n- Discovery: The list above is the plugins available in this session.\n- Skill naming: If a plugin contributes skills, those skill entries are prefixed with `plugin_name:` in the Skills list.\n- Trigger rules: If the user explicitly names a plugin, prefer capabilities associated with that plugin for that turn.\n- Relationship to capabilities: Plugins are not invoked directly. Use their underlying skills, MCP tools, and app tools to help solve the task.\n- Preference: When a relevant plugin is available, prefer using capabilities associated with that plugin over standalone capabilities that provide similar functionality.\n- Missing/blocked: If the user requests a plugin that is not listed above, or the plugin does not have relevant callable capabilities for the task, say so briefly and continue with the best fallback.\n</plugins_instructions>"))

!(assertEqualToResult
  (codex:available-plugins-instructions-from-plugins ())
  (Empty))

!(assertEqualToResult
  (codex:available-plugins-instructions-matches-text
    " <PLUGINS_INSTRUCTIONS>\nbody\n</plugins_instructions> ")
  (True))

!(assertEqualToResult
  (codex:contextual-fragment-role
    (codex:available-plugins-instructions
      ((codex:plugin-capability-summary
         "local_tools"
         "Local Tools"
         "Filesystem and shell helpers"
         True
         ("fs")
         ((codex:app-connector-id "jira"))))))
  ("developer"))
