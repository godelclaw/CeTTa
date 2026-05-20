!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:config_key_aliases)

(= (codex-config-key-aliases-parse-json $text)
   (case (eval (json-parse $text))
     (($value $value))))

(= (codex-config-key-aliases-test-json $text)
   (json-stringify
     (codex:normalized-with-key-aliases
       (codex-config-key-aliases-parse-json $text))))

!(assertEqual
  (codex-config-key-aliases-test-json "\"unchanged\"")
  "\"unchanged\"")

!(assertEqual
  (codex-config-key-aliases-test-json
    "{\"model\":\"gpt-5.2\",\"memories\":{\"no_memories_if_mcp_or_web_search\":true,\"retention\":\"short\"}}")
  "{\"model\":\"gpt-5.2\",\"memories\":{\"retention\":\"short\",\"disable_on_external_context\":true}}")

!(assertEqual
  (codex-config-key-aliases-test-json
    "{\"memories\":{\"no_memories_if_mcp_or_web_search\":true,\"disable_on_external_context\":false,\"retention\":\"short\"}}")
  "{\"memories\":{\"disable_on_external_context\":false,\"retention\":\"short\"}}")

!(assertEqual
  (codex-config-key-aliases-test-json
    "{\"profiles\":{\"memories\":{\"no_memories_if_mcp_or_web_search\":true}}}")
  "{\"profiles\":{\"memories\":{\"no_memories_if_mcp_or_web_search\":true}}}")

!(assertEqual
  (codex-config-key-aliases-test-json
    "{\"memories\":[{\"no_memories_if_mcp_or_web_search\":true},{\"disable_on_external_context\":false,\"no_memories_if_mcp_or_web_search\":true}]}")
  "{\"memories\":[{\"disable_on_external_context\":true},{\"disable_on_external_context\":false}]}")

!(assertEqual
  (json-stringify
    (JsonObject
      (codex:normalize-key-aliases
        ("memories")
        ((JsonPair "no_memories_if_mcp_or_web_search" (JsonBool True))))))
  "{\"disable_on_external_context\":true}")
