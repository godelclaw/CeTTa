!(register-module! ../codex)
!(import! &self codex:config_overrides)
!(import! &self codex:config_multi_agent)

!(println! "=== Codex config overrides demo ===")

; Default overrides: every field absent, no extra writable roots.
!(println! (codex:config-overrides-default))

; Multi-agent v2 defaults from the Rust Default impl.
!(println! (codex:multi-agent-v2-config-default))

; A populated override set as a CLI front-end would build it, checked
; through getters.
(= (demo:overrides)
   (codex:config-overrides
     "gpt-5.1-codex"
     CodexAbsent
     "/repo"
     (CodexAskForApprovalOnRequest)
     CodexAbsent
     (CodexSandboxModeWorkspaceWrite)
     CodexAbsent
     "openai"
     CodexAbsent
     "dev"
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
     ("/tmp/scratch")))

!(assertEqualToResult
  (codex:config-overrides-model (demo:overrides))
  ("gpt-5.1-codex"))

!(assertEqualToResult
  (codex:config-overrides-config-profile (demo:overrides))
  ("dev"))

!(assertEqualToResult
  (codex:config-overrides-additional-writable-roots (demo:overrides))
  (("/tmp/scratch")))

!(println! "=== demo complete ===")
