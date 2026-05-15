!(register-module! ../codex)
!(import! &self codex:agent_path)

!(assertEqual
  (codex:agent-path-as-str (codex:agent-path-root))
  "/root")

!(assertEqual
  (codex:agent-path-name (codex:agent-path-root))
  "root")

!(assertEqual
  (codex:is-agent-path-root (codex:agent-path-root))
  True)

!(assertEqual
  (codex:agent-path-as-str (codex:agent-path-morpheus))
  "/morpheus")

!(assertEqual
  (codex:agent-path-name (codex:agent-path-morpheus))
  "morpheus")

!(assertEqual
  (codex:is-agent-path-root (codex:agent-path-morpheus))
  False)

!(assertEqual
  (codex:agent-path-join (codex:agent-path-root) "researcher")
  (CodexAgentPathOk (CodexAgentPath "/root/researcher")))

!(assertEqual
  (codex:agent-path-name (CodexAgentPath "/root/researcher"))
  "researcher")

!(assertEqual
  (codex:agent-path-resolve
    (CodexAgentPath "/root/researcher")
    "worker")
  (CodexAgentPathOk (CodexAgentPath "/root/researcher/worker")))

!(assertEqual
  (codex:agent-path-resolve
    (CodexAgentPath "/root/researcher")
    "/root/other")
  (CodexAgentPathOk (CodexAgentPath "/root/other")))

!(assertEqual
  (codex:agent-path-join (codex:agent-path-root) "BadName")
  (CodexAgentPathErr
    "agent_name must use only lowercase letters, digits, and underscores"))

!(assertEqual
  (codex:agent-path-from-string "/not-root")
  (CodexAgentPathErr
    "absolute agent paths must start with `/root` or be `/morpheus`"))

!(assertEqual
  (codex:agent-path-resolve (codex:agent-path-root) "../sibling")
  (CodexAgentPathErr "agent_name `..` is reserved"))

!(assertEqual
  (codex:agent-path-resolve (codex:agent-path-root) "")
  (CodexAgentPathErr "agent path must not be empty"))
