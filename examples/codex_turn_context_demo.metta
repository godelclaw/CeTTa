!(register-module! ../codex)
!(import! &self codex:turn_context)

!(println! "=== Codex turn_context demo ===")

; A turn environment and its protocol selection.
!(println!
  (codex:turn-environment-selection
    (codex:turn-environment "env-prod" (DemoEnvironment) "/repo")))

; Effective context window: 272k window at 95 percent.
!(println!
  (codex:turn-context-model-context-window-value 272000 95))

; Model switching keeps a supported effort and falls back to the
; midpoint of the supported levels otherwise.
!(println!
  (codex:turn-context-select-reasoning-effort high (low medium high)
    CodexAbsent))
!(println!
  (codex:turn-context-select-reasoning-effort xhigh (low medium high)
    CodexAbsent))

!(assertEqualToResult
  (codex:turn-context-select-reasoning-effort xhigh (low medium high)
    CodexAbsent)
  (medium))

; Model-relative paths resolve against the session cwd.
!(assertEqualToResult
  (codex:turn-context-resolve-path "/repo" "src/main.rs")
  ("/repo/src/main.rs"))

!(println! "=== demo complete ===")
