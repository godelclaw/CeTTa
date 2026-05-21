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

!(assertEqual
  (codex:tool-name-from-json
    (JsonObject
      ((JsonPair "name" (JsonString "exec_command")))))
  (CodexToolNameParseOk
    (CodexToolName "exec_command" CodexAbsent)))

!(assertEqual
  (codex:tool-name-from-json
    (JsonObject
      ((JsonPair "name" (JsonString "exec_command"))
       (JsonPair "namespace" JsonNull))))
  (CodexToolNameParseOk
    (CodexToolName "exec_command" CodexAbsent)))

!(assertEqualToResult
  (case (json-parse
          "{\"name\":\"create_entities\",\"namespace\":\"mcp__memory__\",\"ignored\":true}")
    (($json
      (codex:tool-name-from-json $json))))
  ((CodexToolNameParseOk
     (CodexToolName "create_entities" "mcp__memory__"))))

!(assertEqual
  (codex:tool-name-parse-result-value
    (codex:tool-name-from-json
      (JsonObject
        ((JsonPair "name" (JsonString "read_file"))
         (JsonPair "namespace" (JsonString "mcp__fs__"))))))
  (CodexToolName "read_file" "mcp__fs__"))

!(assertEqual
  (codex:tool-name-parse-result-error
    (codex:tool-name-from-json
      (JsonObject
        ((JsonPair "namespace" (JsonString "mcp__fs__"))))))
  "missing field `name`")

!(assertEqual
  (codex:tool-name-parse-result-error
    (codex:tool-name-from-json
      (JsonObject
        ((JsonPair "name" (JsonString "read_file"))
         (JsonPair "namespace" (JsonBool True))))))
  "invalid type for field `namespace`: expected string or null")
