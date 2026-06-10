!(register-module! ../codex)
!(import! &self codex:config_overrides)
!(import! &self codex:config_multi_agent)

; --- override-set wrapper ---
!(assertEqualToResult
  (codex:config-override-set-value (codex:config-override-set "tier"))
  ("tier"))

; --- defaults: every optional field absent, writable roots empty ---
!(assertEqualToResult
  (codex:config-overrides-default)
  ((CodexConfigOverrides
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      ())))

(= (test:sample-overrides)
   (codex:config-overrides
     "gpt-5.1-codex"
     "gpt-5.1-codex-mini"
     "/repo"
     (CodexAskForApprovalOnRequest)
     CodexAbsent
     (CodexSandboxModeWorkspaceWrite)
     CodexAbsent
     "openai"
     (codex:config-override-set CodexAbsent)
     "dev"
     CodexAbsent
     CodexAbsent
     CodexAbsent
     "/usr/bin/node"
     ("/repo/node_modules")
     CodexAbsent
     "base"
     CodexAbsent
     CodexAbsent
     CodexAbsent
     True
     False
     True
     False
     ("/tmp/scratch")))

; --- getter round-trips on a populated record ---
!(assertEqualToResult
  (codex:config-overrides-model (test:sample-overrides))
  ("gpt-5.1-codex"))

!(assertEqualToResult
  (codex:config-overrides-review-model (test:sample-overrides))
  ("gpt-5.1-codex-mini"))

!(assertEqualToResult
  (codex:config-overrides-cwd (test:sample-overrides))
  ("/repo"))

!(assertEqualToResult
  (codex:config-overrides-approval-policy (test:sample-overrides))
  ((CodexAskForApprovalOnRequest)))

!(assertEqualToResult
  (codex:config-overrides-sandbox-mode (test:sample-overrides))
  ((CodexSandboxModeWorkspaceWrite)))

!(assertEqualToResult
  (codex:config-overrides-service-tier (test:sample-overrides))
  ((CodexConfigOverrideSet CodexAbsent)))

!(assertEqualToResult
  (codex:config-overrides-config-profile (test:sample-overrides))
  ("dev"))

!(assertEqualToResult
  (codex:config-overrides-js-repl-node-path (test:sample-overrides))
  ("/usr/bin/node"))

!(assertEqualToResult
  (codex:config-overrides-js-repl-node-module-dirs (test:sample-overrides))
  (("/repo/node_modules")))

!(assertEqualToResult
  (codex:config-overrides-base-instructions (test:sample-overrides))
  ("base"))

!(assertEqualToResult
  (codex:config-overrides-include-apply-patch-tool (test:sample-overrides))
  (True))

!(assertEqualToResult
  (codex:config-overrides-show-raw-agent-reasoning (test:sample-overrides))
  (False))

!(assertEqualToResult
  (codex:config-overrides-tools-web-search-request (test:sample-overrides))
  (True))

!(assertEqualToResult
  (codex:config-overrides-ephemeral (test:sample-overrides))
  (False))

!(assertEqualToResult
  (codex:config-overrides-additional-writable-roots (test:sample-overrides))
  (("/tmp/scratch")))

!(assertEqualToResult
  (codex:config-overrides-personality (test:sample-overrides))
  (CodexAbsent))

; --- multi-agent v2 config ---
!(assertEqualToResult
  (codex:multi-agent-v2-config-default)
  ((CodexMultiAgentV2Config True CodexAbsent False)))

!(assertEqualToResult
  (codex:multi-agent-v2-config-usage-hint-enabled
    (codex:multi-agent-v2-config-default))
  (True))

!(assertEqualToResult
  (codex:multi-agent-v2-config-usage-hint-text
    (codex:multi-agent-v2-config False "use agents" True))
  ("use agents"))

!(assertEqualToResult
  (codex:multi-agent-v2-config-hide-spawn-agent-metadata
    (codex:multi-agent-v2-config False "use agents" True))
  (True))
