!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:tool_name)

!(assertEqual
  (codex:plain-tool-name "exec_command")
  (CodexToolName "exec_command" CodexAbsent))

!(assertEqual
  (codex:namespaced-tool-name "mcp__memory__" "create_entities")
  (CodexToolName "create_entities" "mcp__memory__"))

!(assertEqual
  (codex:tool-name-display
    (codex:plain-tool-name "exec_command"))
  "exec_command")

!(assertEqual
  (codex:tool-name-display
    (codex:namespaced-tool-name "mcp__memory__" "create_entities"))
  "mcp__memory__create_entities")

!(assertEqualToResult
  (json-stringify
    (codex:tool-name-json
      (codex:plain-tool-name "exec_command")))
  ("{\"name\":\"exec_command\",\"namespace\":null}"))

!(assertEqualToResult
  (json-stringify
    (codex:tool-name-json
      (codex:namespaced-tool-name
        "mcp__memory__"
        "create_entities")))
  ("{\"name\":\"create_entities\",\"namespace\":\"mcp__memory__\"}"))
