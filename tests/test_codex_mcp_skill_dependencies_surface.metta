!(register-module! ../codex)
!(import! &self codex:mcp_skill_dependencies)
!(import! &self codex:skill_model)

(= (codex-test-mcp-dep
      $type
      $value
      $transport
      $command
      $url)
   (CodexSkillToolDependency
     $type
     $value
     CodexAbsent
     $transport
     $command
     $url))

(= (codex-test-mcp-skill $name $dependencies)
   (codex:core-skill-metadata
     $name
     "test"
     CodexAbsent
     CodexAbsent
     $dependencies
     CodexAbsent
     (str-concat "/skills/" (str-concat $name "/SKILL.md"))
     (CodexSkillScopeUser)))

!(assertEqualToResult
  (codex:mcp-skill-dependency-prompt-id)
  ("skill_mcp_dependency_install"))

!(assertEqualToResult
  (codex:mcp-dependency-option-install)
  ("Install"))

!(assertEqualToResult
  (codex:mcp-dependency-option-skip)
  ("Continue anyway"))

!(assertEqualToResult
  (codex:format-missing-mcp-dependencies
    ((codex:mcp-server-entry
       "zeta"
       (codex:mcp-dependency-default-http-config "https://zeta.test/mcp"))
     (codex:mcp-server-entry
       "alpha"
       (codex:mcp-dependency-default-stdio-config "alpha-mcp"))))
  ("alpha, zeta"))

!(assertEqualToResult
  (codex:canonical-mcp-key
    "streamable_http"
    "  https://example.test/mcp  "
    "fallback")
  ("mcp__streamable_http__https://example.test/mcp"))

!(assertEqualToResult
  (codex:canonical-mcp-key "stdio" "   " "fallback")
  ("fallback"))

!(assertEqualToResult
  (codex:canonical-mcp-server-key
    "server-name"
    (codex:mcp-dependency-default-http-config "https://example.test/mcp"))
  ("mcp__streamable_http__https://example.test/mcp"))

!(assertEqualToResult
  (codex:canonical-mcp-server-key
    "server-name"
    (codex:mcp-dependency-default-stdio-config "npx"))
  ("mcp__stdio__npx"))

!(assertEqualToResult
  (codex:canonical-mcp-dependency-key
    (codex-test-mcp-dep
      "mcp"
      "memory"
      CodexAbsent
      CodexAbsent
      "https://memory.test/mcp"))
  ((CodexMcpDependencyOk "mcp__streamable_http__https://memory.test/mcp")))

!(assertEqualToResult
  (codex:canonical-mcp-dependency-key
    (codex-test-mcp-dep
      "mcp"
      "stdio-memory"
      "STDIO"
      "memory-server"
      CodexAbsent))
  ((CodexMcpDependencyOk "mcp__stdio__memory-server")))

!(assertEqualToResult
  (codex:canonical-mcp-dependency-key
    (codex-test-mcp-dep
      "mcp"
      "fallback-memory"
      "streamable_http"
      CodexAbsent
      "   "))
  ((CodexMcpDependencyOk "fallback-memory")))

!(assertEqualToResult
  (codex:canonical-mcp-dependency-key
    (codex-test-mcp-dep
      "mcp"
      "missing-url"
      "streamable_http"
      CodexAbsent
      CodexAbsent))
  ((CodexMcpDependencyErr "missing url for streamable_http dependency")))

!(assertEqualToResult
  (codex:canonical-mcp-dependency-key
    (codex-test-mcp-dep
      "mcp"
      "missing-command"
      "stdio"
      CodexAbsent
      CodexAbsent))
  ((CodexMcpDependencyErr "missing command for stdio dependency")))

!(assertEqualToResult
  (codex:canonical-mcp-dependency-key
    (codex-test-mcp-dep
      "mcp"
      "bad"
      "sse"
      CodexAbsent
      CodexAbsent))
  ((CodexMcpDependencyErr "unsupported transport sse")))

!(assertEqualToResult
  (codex:mcp-dependency-to-server-config
    (codex-test-mcp-dep
      "mcp"
      "memory"
      CodexAbsent
      CodexAbsent
      "https://memory.test/mcp"))
  ((CodexMcpDependencyOk
     (CodexMcpServerConfig
       (CodexMcpServerTransportStreamableHttp
         "https://memory.test/mcp"
         CodexAbsent
         CodexAbsent
         CodexAbsent)
       CodexAbsent
       True
       False
       False
       CodexAbsent
       CodexAbsent
       CodexAbsent
       CodexAbsent
       CodexAbsent
       CodexAbsent
       CodexAbsent
       CodexAbsent
       ()))))

!(assertEqualToResult
  (codex:mcp-dependency-to-server-config
    (codex-test-mcp-dep
      "mcp"
      "stdio-memory"
      "stdio"
      "memory-server"
      CodexAbsent))
  ((CodexMcpDependencyOk
     (CodexMcpServerConfig
       (CodexMcpServerTransportStdio
         "memory-server"
         ()
         CodexAbsent
         ()
         CodexAbsent)
       CodexAbsent
       True
       False
       False
       CodexAbsent
       CodexAbsent
       CodexAbsent
       CodexAbsent
       CodexAbsent
       CodexAbsent
       CodexAbsent
       CodexAbsent
       ()))))

!(assertEqualToResult
  (codex:collect-missing-mcp-dependencies
    ((codex-test-mcp-skill
       "first"
       (CodexSkillDependencies
         ((codex-test-mcp-dep
            "mcp"
            "already-installed"
            CodexAbsent
            CodexAbsent
            "https://installed.test/mcp")
          (codex-test-mcp-dep
            "MCP"
            "memory"
            CodexAbsent
            CodexAbsent
            "https://memory.test/mcp")
          (codex-test-mcp-dep
            "mcp"
            "memory-duplicate"
            "streamable_http"
            CodexAbsent
            "https://memory.test/mcp")
          (codex-test-mcp-dep
            "env_var"
            "API_KEY"
            CodexAbsent
            CodexAbsent
            CodexAbsent))))
     (codex-test-mcp-skill
       "second"
       (CodexSkillDependencies
         ((codex-test-mcp-dep
            "mcp"
            "stdio-memory"
            "stdio"
            "memory-server"
            CodexAbsent)
          (codex-test-mcp-dep
            "mcp"
            "invalid-http"
            "streamable_http"
            CodexAbsent
            CodexAbsent)))))
    ((codex:mcp-server-entry
       "installed"
       (codex:mcp-dependency-default-http-config "https://installed.test/mcp"))))
  (((CodexMcpServerEntry
      "memory"
      (CodexMcpServerConfig
        (CodexMcpServerTransportStreamableHttp
          "https://memory.test/mcp"
          CodexAbsent
          CodexAbsent
          CodexAbsent)
        CodexAbsent
        True
        False
        False
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        ()))
     (CodexMcpServerEntry
      "stdio-memory"
      (CodexMcpServerConfig
        (CodexMcpServerTransportStdio
          "memory-server"
          ()
          CodexAbsent
          ()
          CodexAbsent)
        CodexAbsent
        True
        False
        False
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        ())))))

!(assertEqualToResult
  (codex:format-missing-mcp-dependencies
    (codex:collect-missing-mcp-dependencies
      ((codex-test-mcp-skill
         "format"
         (CodexSkillDependencies
           ((codex-test-mcp-dep
              "mcp"
              "zeta"
              "stdio"
              "zeta-server"
              CodexAbsent)
            (codex-test-mcp-dep
              "mcp"
              "alpha"
              CodexAbsent
              CodexAbsent
              "https://alpha.test/mcp")))))
      ()))
  ("alpha, zeta"))
