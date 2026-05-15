!(register-module! ../codex)
!(import! &self codex:context_fragment)

!(assertEqualToResult
  (codex:contextual-fragment-render
    (codex:available-skills-instructions-from-available-skills
      (codex:available-skills
        ("- `imagegen`: Generate or edit raster images. (file: /tmp/imagegen/SKILL.md)"
         "- `openai-docs`: Use official OpenAI docs. (file: /tmp/openai-docs/SKILL.md)"))))
  ("<skills_instructions>\n## Skills\nA skill is a set of local instructions to follow that is stored in a `SKILL.md` file. Below is the list of skills that can be used. Each entry includes a name, description, and file path so you can open the source for full instructions when using a specific skill.\n### Available skills\n- `imagegen`: Generate or edit raster images. (file: /tmp/imagegen/SKILL.md)\n- `openai-docs`: Use official OpenAI docs. (file: /tmp/openai-docs/SKILL.md)\n### How to use skills\n- Discovery: The list above is the skills available in this session (name + description + file path). Skill bodies live on disk at the listed paths.\n- Trigger rules: If the user names a skill (with `$SkillName` or plain text) OR the task clearly matches a skill's description shown above, you must use that skill for that turn. Multiple mentions mean use them all. Do not carry skills across turns unless re-mentioned.\n- Missing/blocked: If a named skill isn't in the list or the path can't be read, say so briefly and continue with the best fallback.\n- How to use a skill (progressive disclosure):\n  1) After deciding to use a skill, open its `SKILL.md`. Read only enough to follow the workflow.\n  2) When `SKILL.md` references relative paths (e.g., `scripts/foo.py`), resolve them relative to the skill directory listed above first, and only consider other paths if needed.\n  3) If `SKILL.md` points to extra folders such as `references/`, load only the specific files needed for the request; don't bulk-load everything.\n  4) If `scripts/` exist, prefer running or patching them instead of retyping large code blocks.\n  5) If `assets/` or templates exist, reuse them instead of recreating from scratch.\n- Coordination and sequencing:\n  - If multiple skills apply, choose the minimal set that covers the request and state the order you'll use them.\n  - Announce which skill(s) you're using and why (one short line). If you skip an obvious skill, say why.\n- Context hygiene:\n  - Keep context small: summarize long sections instead of pasting them; only load extra files when needed.\n  - Avoid deep reference-chasing: prefer opening only files directly linked from `SKILL.md` unless you're blocked.\n  - When variants exist (frameworks, providers, domains), pick only the relevant reference file(s) and note that choice.\n- Safety and fallback: If a skill can't be applied cleanly (missing files, unclear instructions), state the issue, pick the next-best approach, and continue.\n</skills_instructions>"))

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
