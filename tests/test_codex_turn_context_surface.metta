!(register-module! ../codex)
!(import! &self codex:turn_context)

; --- TurnSkillsContext ----------------------------------------------------

!(assertEqualToResult
  (codex:turn-skills-context-new (TestSkillOutcome))
  ((CodexTurnSkillsContext (TestSkillOutcome) ())))

!(assertEqualToResult
  (codex:turn-skills-context-outcome
    (codex:turn-skills-context (TestSkillOutcome) ("seen-skill")))
  ((TestSkillOutcome)))

!(assertEqualToResult
  (codex:turn-skills-context-implicit-invocation-seen-skills
    (codex:turn-skills-context (TestSkillOutcome) ("seen-skill")))
  (("seen-skill")))

; --- TurnEnvironment and selection -----------------------------------------

!(assertEqualToResult
  (codex:turn-environment-selection
    (codex:turn-environment "env-1" (TestEnvironment) "/repo"))
  ((CodexTurnEnvironmentSelection "env-1" "/repo")))

!(assertEqualToResult
  (codex:turn-environment-cwd
    (codex:turn-environment "env-1" (TestEnvironment) "/repo"))
  ("/repo"))

!(assertEqualToResult
  (codex:turn-environment-selection-environment-id
    (CodexTurnEnvironmentSelection "env-1" "/repo"))
  ("env-1"))

; --- TurnContext groups -------------------------------------------------------

(= (test:turn-context)
   (codex:turn-context
     (codex:turn-context-identity "sub-1" "trace-1" False (TestSource))
     (codex:turn-context-model
       (TestConfig) CodexAbsent (TestModelInfo) (TestTelemetry)
       (TestProvider) medium auto)
     (codex:turn-context-environment
       CodexAbsent () "/repo" "2026-06-10" "Europe/Prague" CodexAbsent)
     (codex:turn-context-instructions
       CodexAbsent CodexAbsent "be careful" (TestCollaborationMode)
       CodexAbsent)
     (codex:turn-context-permissions
       (TestApprovalPolicy) (TestSandboxPolicy) (TestFsPolicy)
       (TestNetPolicy) CodexAbsent (TestWinLevel) (TestShellEnvPolicy))
     (codex:turn-context-tools
       (TestToolsConfig) (TestFeatures) (TestGhost) CodexAbsent
       CodexAbsent CodexAbsent (TestGate) (TestTruncation) (TestJsRepl)
       ())
     (codex:turn-context-state
       (TestMetadataState) (codex:turn-skills-context-new (TestOutcome))
       (TestTimingState) False False)))

!(assertEqualToResult
  (codex:turn-context-identity-sub-id
    (codex:turn-context-identity-group (test:turn-context)))
  ("sub-1"))

!(assertEqualToResult
  (codex:turn-context-environment-cwd
    (codex:turn-context-environment-group (test:turn-context)))
  ("/repo"))

!(assertEqualToResult
  (codex:turn-context-instructions-user-instructions
    (codex:turn-context-instructions-group (test:turn-context)))
  ("be careful"))

!(assertEqualToResult
  (codex:turn-context-permissions-approval-policy
    (codex:turn-context-permissions-group (test:turn-context)))
  ((TestApprovalPolicy)))

!(assertEqualToResult
  (codex:turn-context-tools-truncation-policy
    (codex:turn-context-tools-group (test:turn-context)))
  ((TestTruncation)))

!(assertEqualToResult
  (codex:turn-context-state-server-model-warning-emitted
    (codex:turn-context-state-group (test:turn-context)))
  (False))

; --- model_context_window ------------------------------------------------------

!(assertEqualToResult
  (codex:turn-context-model-context-window-value 272000 95)
  (258400))

!(assertEqualToResult
  (codex:turn-context-model-context-window-value CodexAbsent 95)
  (CodexAbsent))

; --- reasoning-level midpoint selection ------------------------------------------

!(assertEqualToResult
  (codex:turn-context-midpoint-reasoning-level (low medium high) CodexAbsent)
  (medium))

!(assertEqualToResult
  (codex:turn-context-midpoint-reasoning-level
    (low medium high xhigh) CodexAbsent)
  (medium))

!(assertEqualToResult
  (codex:turn-context-midpoint-reasoning-level () medium)
  (medium))

!(assertEqualToResult
  (codex:turn-context-select-reasoning-effort high (low medium high)
    CodexAbsent)
  (high))

!(assertEqualToResult
  (codex:turn-context-select-reasoning-effort xhigh (low medium high)
    CodexAbsent)
  (medium))

!(assertEqualToResult
  (codex:turn-context-select-reasoning-effort CodexAbsent (low high)
    CodexAbsent)
  (low))

; --- resolve_path -------------------------------------------------------------------

!(assertEqualToResult
  (codex:turn-context-resolve-path "/repo" CodexAbsent)
  ("/repo"))

!(assertEqualToResult
  (codex:turn-context-resolve-path "/repo" "sub/f.txt")
  ("/repo/sub/f.txt"))

!(assertEqualToResult
  (codex:turn-context-resolve-path "/repo" "/abs/p.txt")
  ("/abs/p.txt"))
