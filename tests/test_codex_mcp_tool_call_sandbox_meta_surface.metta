!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:mcp_tool_call)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:augment-mcp-tool-request-meta-with-sandbox-state
    True
    CodexAbsent
    (JsonObject
      ((JsonPair "type" (JsonString "managed"))
       (JsonPair
         "file_system"
         (JsonObject
           ((JsonPair "type" (JsonString "unrestricted")))))
       (JsonPair "network" (JsonString "enabled"))))
    (codex:session-sandbox-policy-danger-full-access)
    CodexAbsent
    "/repo"
    False)
  ((JsonObject
     ((JsonPair
        "codex/sandbox-state-meta"
        (JsonObject
          ((JsonPair
             "permissionProfile"
             (JsonObject
               ((JsonPair "type" (JsonString "managed"))
                (JsonPair
                  "file_system"
                  (JsonObject
                    ((JsonPair "type" (JsonString "unrestricted")))))
                (JsonPair "network" (JsonString "enabled")))))
           (JsonPair
             "sandboxPolicy"
             (JsonObject
               ((JsonPair "type" (JsonString "danger-full-access")))))
           (JsonPair "codexLinuxSandboxExe" JsonNull)
           (JsonPair "sandboxCwd" (JsonString "/repo"))
           (JsonPair "useLegacyLandlock" (JsonBool False)))))))))

!(assertEqualToResult
  (codex:augment-mcp-tool-request-meta-with-sandbox-state
    True
    (JsonObject
      ((JsonPair "source" (JsonString "client"))
       (JsonPair
         "codex/sandbox-state-meta"
         (JsonObject ((JsonPair "stale" (JsonBool True)))))))
    (JsonObject
      ((JsonPair "type" (JsonString "managed"))
       (JsonPair
         "file_system"
         (JsonObject
           ((JsonPair "type" (JsonString "unrestricted")))))
       (JsonPair "network" (JsonString "enabled"))))
    (codex:session-sandbox-policy-danger-full-access)
    "/usr/bin/codex-linux-sandbox"
    "/work"
    True)
  ((JsonObject
     ((JsonPair "source" (JsonString "client"))
      (JsonPair
        "codex/sandbox-state-meta"
        (JsonObject
          ((JsonPair
             "permissionProfile"
             (JsonObject
               ((JsonPair "type" (JsonString "managed"))
                (JsonPair
                  "file_system"
                  (JsonObject
                    ((JsonPair "type" (JsonString "unrestricted")))))
                (JsonPair "network" (JsonString "enabled")))))
           (JsonPair
             "sandboxPolicy"
             (JsonObject
               ((JsonPair "type" (JsonString "danger-full-access")))))
           (JsonPair
             "codexLinuxSandboxExe"
             (JsonString "/usr/bin/codex-linux-sandbox"))
           (JsonPair "sandboxCwd" (JsonString "/work"))
           (JsonPair "useLegacyLandlock" (JsonBool True)))))))))

!(assertEqualToResult
  (codex:augment-mcp-tool-request-meta-with-sandbox-state
    True
    (JsonString "invalid-meta")
    (JsonObject
      ((JsonPair "type" (JsonString "managed"))
       (JsonPair
         "file_system"
         (JsonObject
           ((JsonPair "type" (JsonString "unrestricted")))))
       (JsonPair "network" (JsonString "enabled"))))
    (codex:session-sandbox-policy-danger-full-access)
    CodexAbsent
    "/repo"
    False)
  ((JsonString "invalid-meta")))

!(assertEqualToResult
  (codex:augment-mcp-tool-request-meta-with-sandbox-state
    False
    (JsonObject ((JsonPair "source" (JsonString "client"))))
    (JsonObject
      ((JsonPair "type" (JsonString "managed"))
       (JsonPair
         "file_system"
         (JsonObject
           ((JsonPair "type" (JsonString "unrestricted")))))
       (JsonPair "network" (JsonString "enabled"))))
    (codex:session-sandbox-policy-danger-full-access)
    CodexAbsent
    "/repo"
    False)
  ((JsonObject ((JsonPair "source" (JsonString "client"))))))
