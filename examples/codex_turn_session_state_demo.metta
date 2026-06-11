!(register-module! ../codex)
!(import! &self codex:turn_session_state)
!(import! &self codex:turn_effects)

!(println! "=== Codex turn session state demo ===")

; A session accumulating a turn: user prompt recorded, usage updated.
(= (demo:state-after-sampling)
   (codex:turn-session-update-token-usage-info
     (codex:turn-session-record-conversation-items
       (codex:turn-session-state-new)
       ((DemoUserMessage "Summarize the repo")
        (DemoAssistantMessage "It is a MeTTa runtime.")))
     (CodexTokenUsage 1200 300 80 10 1290)
     272000))

!(println! (codex:turn-session-clone-history (demo:state-after-sampling)))
!(println! (codex:turn-session-get-total-token-usage (demo:state-after-sampling)))

!(assertEqualToResult
  (codex:turn-session-get-total-token-usage (demo:state-after-sampling))
  (1290))

; The world threads state, services, and an ordered effect log.
!(println!
  (case (collapse
          (codex:turn-emit-turn-item-started
            (codex:turn-world (demo:state-after-sampling) (DemoServices) ())
            (DemoTurnItem)))
    ((($world)
      (codex:turn-world-effects $world)))))

!(assertEqualToResult
  (case (collapse
          (codex:turn-emit-turn-item-started
            (codex:turn-world (DemoState) (DemoServices) ())
            (DemoTurnItem)))
    ((($world)
      (codex:turn-world-effects $world))))
  (((CodexTurnEffectItemStarted (DemoTurnItem)))))

!(println! "=== demo complete ===")
