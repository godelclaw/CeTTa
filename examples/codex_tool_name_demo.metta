!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:tool_name)

!(println! "=== Codex tool name demo ===")
!(println!
  (json-stringify
    (codex:tool-name-json
      (codex:plain-tool-name "exec_command"))))
!(println!
  (json-stringify
    (codex:tool-name-json
      (codex:namespaced-tool-name
        "mcp__memory__"
        "create_entities"))))
