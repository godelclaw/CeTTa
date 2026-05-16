!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:op-type
    (codex:refresh-mcp-servers-op
      (codex:mcp-server-refresh-config
        (JsonObject
          ((JsonPair "primary" (JsonString "stdio"))))
        (JsonString "memory"))))
  ("refresh_mcp_servers"))

!(assertEqualToResult
  (json-stringify
    (codex:mcp-server-refresh-config-json
      (codex:mcp-server-refresh-config
        (JsonObject
          ((JsonPair "primary" (JsonString "stdio"))
           (JsonPair
             "backup"
             (JsonObject
               ((JsonPair "transport" (JsonString "http"))
                (JsonPair "url" (JsonString "https://example.test/mcp")))))))
        (JsonObject
          ((JsonPair "mode" (JsonString "keychain"))
           (JsonPair "profile" (JsonString "default")))))))
  ("{\"mcp_servers\":{\"primary\":\"stdio\",\"backup\":{\"transport\":\"http\",\"url\":\"https://example.test/mcp\"}},\"mcp_oauth_credentials_store_mode\":{\"mode\":\"keychain\",\"profile\":\"default\"}}"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:refresh-mcp-servers-op
        (codex:mcp-server-refresh-config
          (JsonObject
            ((JsonPair "workspace" (JsonBool True))))
          (JsonString "ephemeral")))))
  ("{\"type\":\"refresh_mcp_servers\",\"config\":{\"mcp_servers\":{\"workspace\":true},\"mcp_oauth_credentials_store_mode\":\"ephemeral\"}}"))
