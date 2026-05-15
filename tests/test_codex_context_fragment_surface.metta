!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:context_fragment)
!(import! &self codex:permissions_instructions)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:contextual-fragment-render
    (codex:contextual-fragment "user" "" "" "plain"))
  ("plain"))

!(assertEqualToResult
  (codex:contextual-fragment-matches-text
    (codex:contextual-fragment "user" "" "" "plain")
    "plain")
  (False))

!(assertEqualToResult
  (codex:contextual-fragment-render
    (codex:user-instructions "/tmp" "body"))
  ("# AGENTS.md instructions for /tmp\n\n<INSTRUCTIONS>\nbody\n</INSTRUCTIONS>"))

!(assertEqualToResult
  (codex:user-instructions-matches-text
    "   # agents.md instructions for /tmp\n\n<INSTRUCTIONS>\nbody\n</instructions>   ")
  (True))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:contextual-fragment-response-item
        (codex:user-instructions "/tmp" "body"))))
  ("{\"type\":\"message\",\"role\":\"user\",\"content\":[{\"type\":\"input_text\",\"text\":\"# AGENTS.md instructions for /tmp\\n\\n<INSTRUCTIONS>\\nbody\\n</INSTRUCTIONS>\"}]}"))

!(assertEqualToResult
  (codex:contextual-fragment-render
    (codex:skill-instructions
      "demo"
      "skills/demo/SKILL.md"
      "body"))
  ("<skill>\n<name>demo</name>\n<path>skills/demo/SKILL.md</path>\nbody\n</skill>"))

!(assertEqualToResult
  (codex:skill-instructions-matches-text
    "  <SKILL>\n<name>demo</name>\n<path>skills/demo/SKILL.md</path>\nbody\n</skill> ")
  (True))

!(assertEqualToResult
  (codex:contextual-fragment-render
    (codex:user-shell-command "pwd" 0 1250 "ok"))
  ("<user_shell_command>\n<command>\npwd\n</command>\n<result>\nExit code: 0\nDuration: 1.2500 seconds\nOutput:\nok\n</result>\n</user_shell_command>"))

!(assertEqualToResult
  (codex:turn-aborted-matches-text
    " \n<TURN_ABORTED>\nbody\n</turn_aborted>\n")
  (True))

!(assertEqualToResult
  (codex:contextual-fragment-render
    (codex:turn-aborted
      (codex:turn-aborted-interrupted-guidance)))
  ("<turn_aborted>\nThe user interrupted the previous turn on purpose. Any running unified exec processes may still be running in the background. If any tools/commands were aborted, they may have partially executed.\n</turn_aborted>"))

!(assertEqualToResult
  (json-stringify
    (codex:agent-status-json
      (codex:agent-status-running)))
  ("\"running\""))

!(assertEqualToResult
  (json-stringify
    (codex:agent-status-json
      (codex:agent-status-completed "done")))
  ("{\"completed\":\"done\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:agent-status-json
      (codex:agent-status-errored "boom")))
  ("{\"errored\":\"boom\"}"))

!(assertEqualToResult
  (codex:contextual-fragment-render
    (codex:subagent-notification
      "/root/child"
      (codex:agent-status-completed "done")))
  ("<subagent_notification>\n{\"agent_path\":\"/root/child\",\"status\":{\"completed\":\"done\"}}\n</subagent_notification>"))

!(assertEqualToResult
  (codex:subagent-notification-matches-text
    "<SUBAGENT_NOTIFICATION>{}</subagent_notification>")
  (True))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:contextual-fragment-response-item
        (codex:permissions-contextual-fragment
          (codex:permissions-instructions "body")))))
  ("{\"type\":\"message\",\"role\":\"developer\",\"content\":[{\"type\":\"input_text\",\"text\":\"<permissions instructions>body</permissions instructions>\"}]}"))

!(assertEqualToResult
  (codex:is-contextual-user-fragment
    (CodexInputText
      "# AGENTS.md instructions for /tmp\n\n<INSTRUCTIONS>\nbody\n</INSTRUCTIONS>"))
  (True))

!(assertEqualToResult
  (codex:is-contextual-user-fragment
    (CodexInputText
      "<skill>\n<name>demo</name>\n<path>skills/demo/SKILL.md</path>\nbody\n</skill>"))
  (True))

!(assertEqualToResult
  (codex:is-contextual-user-fragment
    (CodexInputText "<user_shell_command>\n<command>\npwd\n</command>\n<result>\nExit code: 0\nDuration: 1.2500 seconds\nOutput:\nok\n</result>\n</user_shell_command>"))
  (True))

!(assertEqualToResult
  (codex:is-contextual-user-fragment
    (CodexInputText
      "<subagent_notification>{\"agent_path\":\"/root/child\",\"status\":{\"completed\":\"done\"}}</subagent_notification>"))
  (True))

!(assertEqualToResult
  (codex:is-contextual-user-fragment
    (CodexInputText "hello"))
  (False))

!(assertEqualToResult
  (codex:is-memory-excluded-contextual-user-fragment
    (CodexInputText "# AGENTS.md instructions for /tmp\n\n<INSTRUCTIONS>\nbody\n</INSTRUCTIONS>"))
  (True))

!(assertEqualToResult
  (codex:is-memory-excluded-contextual-user-fragment
    (CodexInputText
      "<skill>\n<name>demo</name>\n<path>skills/demo/SKILL.md</path>\nbody\n</skill>"))
  (True))

!(assertEqualToResult
  (codex:is-memory-excluded-contextual-user-fragment
    (CodexInputText "<turn_aborted>\nbody\n</turn_aborted>"))
  (False))

!(assertEqualToResult
  (codex:is-memory-excluded-contextual-user-fragment
    (CodexInputText
      "<subagent_notification>{\"agent_path\":\"/root/child\",\"status\":{\"completed\":\"done\"}}</subagent_notification>"))
  (False))
