!(register-module! ../codex)
!(import! &self codex:mcp)
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

!(assertEqualToResult
  (codex:filter-prompted-mcp-dependencies
    ((codex:mcp-server-entry
       "memory"
       (codex:mcp-dependency-default-http-config "https://memory.test/mcp"))
     (codex:mcp-server-entry
       "docs"
       (codex:mcp-dependency-default-stdio-config "docs-server"))
     (codex:mcp-server-entry
       "empty-command"
       (codex:mcp-dependency-default-stdio-config "   ")))
    ("mcp__streamable_http__https://memory.test/mcp"
     "empty-command"))
  (((CodexMcpServerEntry
      "docs"
      (CodexMcpServerConfig
        (CodexMcpServerTransportStdio
          "docs-server"
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
  (codex:filter-prompted-mcp-dependencies
    ((CodexMcpServerEntry
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
         ())))
    ())
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
        ())))))

!(assertEqualToResult
  (codex:mcp-dependency-install-merge-state-updated
    (codex:mcp-dependency-install-merge-plan
      ((CodexMcpServerEntry
         "zeta"
         (CodexMcpServerConfig
           (CodexMcpServerTransportStreamableHttp
             "https://zeta.test/mcp"
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
           ())))
      ((CodexMcpServerEntry
         "alpha"
         (CodexMcpServerConfig
           (CodexMcpServerTransportStdio
             "alpha-server"
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
           ()))
       (CodexMcpServerEntry
         "zeta"
         (CodexMcpServerConfig
           (CodexMcpServerTransportStreamableHttp
             "https://replacement.test/mcp"
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
           ())))))
  (True))

!(assertEqualToResult
  (codex:mcp-server-entry-names
    (codex:mcp-dependency-install-merge-state-servers
      (codex:mcp-dependency-install-merge-plan
        ((CodexMcpServerEntry
           "zeta"
           (CodexMcpServerConfig
             (CodexMcpServerTransportStreamableHttp
               "https://zeta.test/mcp"
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
             ())))
        ((CodexMcpServerEntry
           "alpha"
           (CodexMcpServerConfig
             (CodexMcpServerTransportStdio
               "alpha-server"
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
             ()))))))
  (("alpha" "zeta")))

!(assertEqualToResult
  (codex:mcp-dependency-install-ready-added
    (codex:maybe-install-mcp-dependencies-plan
      True
      "/home/user/.codex"
      ((codex-test-mcp-skill
         "install"
         (CodexSkillDependencies
           ((codex-test-mcp-dep
              "mcp"
              "memory"
              CodexAbsent
              CodexAbsent
              "https://memory.test/mcp")))))
      ()
      (codex:mcp-dependency-load-global-servers-ok
        ((CodexMcpServerEntry
           "zeta"
           (CodexMcpServerConfig
             (CodexMcpServerTransportStreamableHttp
               "https://zeta.test/mcp"
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
             ()))))))
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
        ())))))

!(assertEqualToResult
  (codex:mcp-dependency-persist-servers-op-codex-home
    (codex:mcp-dependency-install-ready-persist-op
      (codex:maybe-install-mcp-dependencies-plan
        True
        "/home/user/.codex"
        ((codex-test-mcp-skill
           "install"
           (CodexSkillDependencies
             ((codex-test-mcp-dep
                "mcp"
                "memory"
                CodexAbsent
                CodexAbsent
                "https://memory.test/mcp")))))
        ()
        (codex:mcp-dependency-load-global-servers-ok ()))))
  ("/home/user/.codex"))

!(assertEqualToResult
  (codex:maybe-install-mcp-dependencies-plan
    False
    "/home/user/.codex"
    ((codex-test-mcp-skill
       "install"
       (CodexSkillDependencies
         ((codex-test-mcp-dep
            "mcp"
            "memory"
            CodexAbsent
            CodexAbsent
            "https://memory.test/mcp")))))
    ()
    (codex:mcp-dependency-load-global-servers-ok ()))
  ((CodexMcpDependencyInstallSkip "disabled_or_no_skills")))

!(assertEqualToResult
  (codex:maybe-install-mcp-dependencies-plan
    True
    "/home/user/.codex"
    ((codex-test-mcp-skill
       "install"
       (CodexSkillDependencies
         ((codex-test-mcp-dep
            "mcp"
            "memory"
            CodexAbsent
            CodexAbsent
            "https://memory.test/mcp")))))
    ()
    (codex:mcp-dependency-load-global-servers-error "read failed"))
  ((CodexMcpDependencyInstallLoadError "read failed")))

!(assertEqualToResult
  (codex:mcp-dependency-install-question
    ((codex:mcp-server-entry
       "zeta"
       (codex:mcp-dependency-default-http-config "https://zeta.test/mcp"))
     (codex:mcp-server-entry
       "alpha"
       (codex:mcp-dependency-default-stdio-config "alpha-mcp"))))
  ((CodexRequestUserInputQuestion
     "skill_mcp_dependency_install"
     "Install MCP servers?"
     "The following MCP servers are required by the selected skills but are not installed yet: alpha, zeta. Install them now?"
     False
     False
     ((CodexRequestUserInputQuestionOption
        "Install"
        "Install and enable the missing MCP servers in your global config.")
      (CodexRequestUserInputQuestionOption
        "Continue anyway"
        "Skip installation for now and do not show again for these MCP servers in this session.")))))

!(assertEqualToResult
  (codex:mcp-dependency-install-answer-selected
    (CodexRequestUserInputResponse
      ((CodexRequestUserInputResponseEntry
         "skill_mcp_dependency_install"
         (CodexRequestUserInputAnswer ("Install"))))))
  (True))

!(assertEqualToResult
  (codex:mcp-dependency-install-answer-selected
    (CodexRequestUserInputResponse
      ((CodexRequestUserInputResponseEntry
         "skill_mcp_dependency_install"
         (CodexRequestUserInputAnswer ("Continue anyway"))))))
  (False))

!(assertEqualToResult
  (codex:should-install-mcp-dependencies-plan
    "never"
    (CodexApprovalSandboxPolicyDangerFullAccess)
    "turn-1"
    ((codex:mcp-server-entry
       "memory"
       (codex:mcp-dependency-default-http-config "https://memory.test/mcp")))
    CodexAbsent)
  ((CodexMcpDependencyShouldInstallPlan True CodexAbsent ())))

!(assertEqualToResult
  (codex:should-install-mcp-dependencies-plan
    "on_request"
    (CodexApprovalSandboxPolicyReadOnly)
    "turn-2"
    ((codex:mcp-server-entry
       "memory"
       (codex:mcp-dependency-default-http-config "https://memory.test/mcp")))
    (CodexRequestUserInputResponse
      ((CodexRequestUserInputResponseEntry
         "skill_mcp_dependency_install"
         (CodexRequestUserInputAnswer ("Install"))))))
  ((CodexMcpDependencyShouldInstallPlan
     True
     (CodexRequestUserInputEvent
       "mcp-deps-turn-2"
       "turn-2"
       ((CodexRequestUserInputQuestion
          "skill_mcp_dependency_install"
          "Install MCP servers?"
          "The following MCP servers are required by the selected skills but are not installed yet: memory. Install them now?"
          False
          False
          ((CodexRequestUserInputQuestionOption
             "Install"
             "Install and enable the missing MCP servers in your global config.")
           (CodexRequestUserInputQuestionOption
             "Continue anyway"
             "Skip installation for now and do not show again for these MCP servers in this session.")))))
     ("mcp__streamable_http__https://memory.test/mcp"))))

!(assertEqualToResult
  (codex:mcp-dependency-oauth-login-plan
    ((codex:mcp-server-entry
       "memory"
       (codex:mcp-server-config
         (codex:mcp-server-transport-streamable-http
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
         ("configured-scope")
         "https://resource.test"
         ())))
    ((codex:mcp-dependency-oauth-support-entry
       "memory"
       (codex:mcp-oauth-login-support-supported
         (codex:mcp-oauth-login-config
           "https://memory.test/mcp"
           (("Authorization" "Bearer token"))
           (("X-Token" "TOKEN_ENV"))
           ("discovered-scope")))))
    "file"
    4321
    "https://callback.test/cb")
  (((CodexMcpDependencyOAuthNotifyOp
      "Authenticating MCP memory... Follow instructions in your browser if prompted.")
     (CodexMcpDependencyOAuthLoginAttemptOp
      "memory"
      "https://memory.test/mcp"
      "file"
      (("Authorization" "Bearer token"))
      (("X-Token" "TOKEN_ENV"))
      ("configured-scope")
      "https://resource.test"
      4321
      "https://callback.test/cb"))))

!(assertEqualToResult
  (codex:mcp-dependency-oauth-login-plan
    ((codex:mcp-server-entry
       "memory"
       (codex:mcp-dependency-default-http-config "https://memory.test/mcp")))
    ((codex:mcp-dependency-oauth-support-entry
       "memory"
       (codex:mcp-oauth-login-support-supported
         (codex:mcp-oauth-login-config
           "https://memory.test/mcp"
           CodexAbsent
           CodexAbsent
           ("discovered-scope")))))
    "file"
    CodexAbsent
    CodexAbsent)
  (((CodexMcpDependencyOAuthNotifyOp
      "Authenticating MCP memory... Follow instructions in your browser if prompted.")
     (CodexMcpDependencyOAuthLoginAttemptOp
      "memory"
      "https://memory.test/mcp"
      "file"
      CodexAbsent
      CodexAbsent
      ("discovered-scope")
      CodexAbsent
      CodexAbsent
      CodexAbsent))))

!(assertEqualToResult
  (codex:mcp-dependency-oauth-login-plan
    ((codex:mcp-server-entry
       "stdio"
       (codex:mcp-dependency-default-stdio-config "stdio-server"))
     (codex:mcp-server-entry
       "unknown"
       (codex:mcp-dependency-default-http-config "https://unknown.test/mcp")))
    ((codex:mcp-dependency-oauth-support-entry
       "stdio"
       (codex:mcp-oauth-login-support-unsupported))
     (codex:mcp-dependency-oauth-support-entry
       "unknown"
       (codex:mcp-oauth-login-support-unknown "discovery failed")))
    "file"
    CodexAbsent
    CodexAbsent)
  (((CodexMcpDependencyOAuthWarnOp
      "MCP server may or may not require login for dependency unknown: discovery failed"))))

!(assertEqualToResult
  (codex:mcp-dependency-oauth-first-attempt-result-plan
    "memory"
    (codex:mcp-oauth-login-config
      "https://memory.test/mcp"
      (("Authorization" "Bearer token"))
      (("X-Token" "TOKEN_ENV"))
      ("discovered-scope"))
    (codex:mcp-dependency-default-http-config "https://memory.test/mcp")
    "file"
    CodexAbsent
    CodexAbsent
    (codex:resolved-mcp-oauth-scopes
      ("discovered-scope")
      (codex:mcp-oauth-scopes-source-discovered))
    (codex:mcp-dependency-oauth-login-err
      (codex:mcp-oauth-provider-error
        "invalid_scope"
        "scope rejected")))
  (((CodexMcpDependencyOAuthNotifyOp
      "Retrying MCP memory authentication without scopes after provider rejection.")
     (CodexMcpDependencyOAuthLoginAttemptOp
      "memory"
      "https://memory.test/mcp"
      "file"
      (("Authorization" "Bearer token"))
      (("X-Token" "TOKEN_ENV"))
      ()
      CodexAbsent
      CodexAbsent
      CodexAbsent))))

!(assertEqualToResult
  (codex:mcp-dependency-oauth-first-attempt-result-plan
    "memory"
    (codex:mcp-oauth-login-config
      "https://memory.test/mcp"
      CodexAbsent
      CodexAbsent
      CodexAbsent)
    (codex:mcp-dependency-default-http-config "https://memory.test/mcp")
    "file"
    CodexAbsent
    CodexAbsent
    (codex:resolved-mcp-oauth-scopes
      ("configured-scope")
      (codex:mcp-oauth-scopes-source-configured))
    (codex:mcp-dependency-oauth-login-err
      (codex:mcp-oauth-provider-error
        "invalid_scope"
        "scope rejected")))
  (((CodexMcpDependencyOAuthWarnOp
      "failed to login to MCP dependency memory: OAuth provider returned `invalid_scope`: scope rejected"))))

!(assertEqualToResult
  (codex:mcp-dependency-oauth-first-attempt-result-plan
    "memory"
    (codex:mcp-oauth-login-config
      "https://memory.test/mcp"
      CodexAbsent
      CodexAbsent
      CodexAbsent)
    (codex:mcp-dependency-default-http-config "https://memory.test/mcp")
    "file"
    CodexAbsent
    CodexAbsent
    (codex:resolved-mcp-oauth-scopes
      ("discovered-scope")
      (codex:mcp-oauth-scopes-source-discovered))
    (codex:mcp-dependency-oauth-login-err
      "timed out waiting for OAuth callback"))
  (((CodexMcpDependencyOAuthWarnOp
      "failed to login to MCP dependency memory: timed out waiting for OAuth callback"))))

!(assertEqualToResult
  (codex:mcp-dependency-oauth-first-attempt-result-plan
    "memory"
    (codex:mcp-oauth-login-config
      "https://memory.test/mcp"
      CodexAbsent
      CodexAbsent
      CodexAbsent)
    (codex:mcp-dependency-default-http-config "https://memory.test/mcp")
    "file"
    CodexAbsent
    CodexAbsent
    (codex:resolved-mcp-oauth-scopes
      ()
      (codex:mcp-oauth-scopes-source-empty))
    (codex:mcp-dependency-oauth-login-ok))
  (()))

!(assertEqualToResult
  (codex:mcp-dependency-oauth-retry-result-plan
    "memory"
    (codex:mcp-dependency-oauth-login-err
      (codex:mcp-oauth-provider-error
        CodexAbsent
        "retry rejected")))
  (((CodexMcpDependencyOAuthWarnOp
      "failed to login to MCP dependency memory: OAuth error: retry rejected"))))
