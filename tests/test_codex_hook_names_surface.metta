!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:hook_names)

!(assertEqual
  (codex:hook-tool-name-new "mcp__memory__create_entities")
  (CodexHookToolName "mcp__memory__create_entities" ()))

!(assertEqual
  (codex:hook-tool-name-bash)
  (CodexHookToolName "Bash" ()))

!(assertEqual
  (codex:hook-tool-name-apply-patch)
  (CodexHookToolName "apply_patch" ("Write" "Edit")))

!(assertEqual
  (codex:hook-tool-name-name
    (codex:hook-tool-name-apply-patch))
  "apply_patch")

!(assertEqual
  (codex:hook-tool-name-matcher-aliases
    (codex:hook-tool-name-apply-patch))
  ("Write" "Edit"))

!(assertEqualToResult
  (json-stringify
    (codex:hook-tool-name-json
      (codex:hook-tool-name-bash)))
  ("{\"name\":\"Bash\",\"matcher_aliases\":[]}"))

!(assertEqualToResult
  (json-stringify
    (codex:hook-tool-name-json
      (codex:hook-tool-name-apply-patch)))
  ("{\"name\":\"apply_patch\",\"matcher_aliases\":[\"Write\",\"Edit\"]}"))
