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
!(println!
  (codex:tool-name-display
    (codex:tool-name-parse-result-value
      (codex:tool-name-from-json
        (JsonObject
          ((JsonPair "name" (JsonString "create_entities"))
           (JsonPair "namespace" (JsonString "mcp__memory__"))))))))
