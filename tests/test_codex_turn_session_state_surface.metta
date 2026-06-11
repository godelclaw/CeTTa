!(register-module! ../codex)
!(import! &self codex:turn_session_state)
!(import! &self codex:turn_effects)

; --- defaults --------------------------------------------------------------

!(assertEqualToResult
  (codex:turn-session-state-new)
  ((CodexTurnSessionState
     () () CodexAbsent CodexAbsent CodexAbsent
     False False False False False CodexAbsent)))

; --- pending input -----------------------------------------------------------

!(assertEqualToResult
  (codex:turn-session-has-pending-input (codex:turn-session-state-new))
  (False))

!(assertEqualToResult
  (codex:turn-session-has-pending-input
    (codex:turn-session-push-pending-input
      (codex:turn-session-state-new) (TestInput1)))
  (True))

; drain returns items in submission order and empties the queue
!(assertEqualToResult
  (codex:turn-session-take-pending-input
    (codex:turn-session-push-pending-input
      (codex:turn-session-push-pending-input
        (codex:turn-session-state-new) (TestInput1))
      (TestInput2)))
  ((CodexPendingInputTaken
     ((TestInput1) (TestInput2))
     (CodexTurnSessionState
       () () CodexAbsent CodexAbsent CodexAbsent
       False False False False False CodexAbsent))))

; blocked input requeues at the front (turn.rs 409)
!(assertEqualToResult
  (codex:turn-session-state-pending-input
    (codex:turn-session-prepend-pending-input
      (codex:turn-session-push-pending-input
        (codex:turn-session-state-new) (TestInput3))
      ((TestInput1) (TestInput2))))
  (((TestInput1) (TestInput2) (TestInput3))))

; --- history -------------------------------------------------------------------

!(assertEqualToResult
  (codex:turn-session-clone-history
    (codex:turn-session-record-conversation-items
      (codex:turn-session-record-conversation-items
        (codex:turn-session-state-new) ((TestItemA)))
      ((TestItemB) (TestItemC))))
  (((TestItemA) (TestItemB) (TestItemC))))

; --- token usage -----------------------------------------------------------------

; absent usage leaves state unchanged (session/mod.rs 2784: only-if-Some)
!(assertEqualToResult
  (codex:turn-session-update-token-usage-info
    (codex:turn-session-state-new) CodexAbsent 272000)
  ((CodexTurnSessionState
     () () CodexAbsent CodexAbsent CodexAbsent
     False False False False False CodexAbsent)))

; first usage seeds both total and last
!(assertEqualToResult
  (codex:turn-session-state-token-usage-info
    (codex:turn-session-update-token-usage-info
      (codex:turn-session-state-new)
      (CodexTokenUsage 100 20 30 5 130)
      272000))
  ((CodexTokenUsageInfo
     (CodexTokenUsage 100 20 30 5 130)
     (CodexTokenUsage 100 20 30 5 130)
     272000)))

; second usage accumulates the total and replaces the last
!(assertEqualToResult
  (codex:turn-session-state-token-usage-info
    (codex:turn-session-update-token-usage-info
      (codex:turn-session-update-token-usage-info
        (codex:turn-session-state-new)
        (CodexTokenUsage 100 20 30 5 130)
        272000)
      (CodexTokenUsage 50 10 20 2 70)
      272000))
  ((CodexTokenUsageInfo
     (CodexTokenUsage 150 30 50 7 200)
     (CodexTokenUsage 50 10 20 2 70)
     272000)))

; get_total_token_usage reads the LAST usage's total tokens
; (context_manager/history.rs:312; estimator contributions are 0 until
; the history-estimation lane lands)
!(assertEqualToResult
  (codex:turn-session-get-total-token-usage
    (codex:turn-session-update-token-usage-info
      (codex:turn-session-update-token-usage-info
        (codex:turn-session-state-new)
        (CodexTokenUsage 100 20 30 5 130)
        272000)
      (CodexTokenUsage 50 10 20 2 70)
      272000))
  (70))

!(assertEqualToResult
  (codex:turn-session-get-total-token-usage (codex:turn-session-state-new))
  (0))

; --- rate limits and flags ----------------------------------------------------------

!(assertEqualToResult
  (codex:turn-session-state-rate-limits
    (codex:turn-session-update-rate-limits
      (codex:turn-session-state-new) (TestSnapshot)))
  ((TestSnapshot)))

!(assertEqualToResult
  (codex:turn-session-state-total-tokens-full
    (codex:turn-session-set-total-tokens-full
      (codex:turn-session-state-new)))
  (True))

!(assertEqualToResult
  (codex:turn-session-state-server-reasoning-included
    (codex:turn-session-set-server-reasoning-included
      (codex:turn-session-state-new) True))
  (True))

!(assertEqualToResult
  (codex:turn-session-mailbox-has-pending (codex:turn-session-state-new))
  (False))

!(assertEqualToResult
  (codex:turn-session-previous-turn-settings
    (codex:turn-session-set-previous-turn-settings
      (codex:turn-session-state-new) (TestSettings)))
  ((TestSettings)))

; --- world and effects ------------------------------------------------------------

; emissions compose in the loop's staged case-collapse idiom (the spine
; convention: world values are materialized between steps, never passed
; as nested call arguments)
!(assertEqualToResult
  (case (collapse
          (codex:turn-emit-turn-item-started
            (codex:turn-world (TestState) (TestServices) ())
            (TestItem)))
    ((($world-1)
      (case (collapse (codex:turn-send-event $world-1 (TestEvent)))
        ((($world-2)
          (codex:turn-world-effects $world-2)))))))
  (((CodexTurnEffectItemStarted (TestItem))
    (CodexTurnEffectEvent (TestEvent)))))

!(assertEqualToResult
  (case (collapse
          (codex:turn-notify-stream-error
            (codex:turn-world (TestState) (TestServices) ())
            "retrying" (CodexErrTimeout)))
    ((($world-1)
      (case (collapse (codex:turn-effect-sleep $world-1 750))
        ((($world-2)
          (codex:turn-world-effects $world-2)))))))
  (((CodexTurnEffectStreamError "retrying" (CodexErrTimeout))
    (CodexTurnEffectSleep 750))))

!(assertEqualToResult
  (codex:turn-world-session-state
    (codex:turn-world-with-session-state
      (codex:turn-world (TestState) (TestServices) ())
      (TestState2)))
  ((TestState2)))

!(assertEqualToResult
  (codex:turn-services-client-session
    (codex:turn-services-with-client-session
      (codex:turn-services (H) (C) (R) (Client1) (Cancel))
      (Client2)))
  ((Client2)))
