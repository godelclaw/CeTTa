!(register-module! ../codex)
!(import! &self codex:session_prefix)
!(import! &self codex:context_fragment)

!(assertEqualToResult
  (codex:format-subagent-notification-message
    "worker"
    (codex:agent-status-running))
  ("<subagent_notification>\n{\"agent_path\":\"worker\",\"status\":\"running\"}\n</subagent_notification>"))

!(assertEqualToResult
  (codex:format-subagent-context-line "worker" "Plato")
  ("- worker: Plato"))

!(assertEqualToResult
  (codex:format-subagent-context-line "worker" "")
  ("- worker"))

!(assertEqualToResult
  (codex:format-subagent-context-line "worker" CodexAbsent)
  ("- worker"))
