; Rust-faithful turn session state record (core-loop spine).
;
; This ports the SessionState surface the turn loop reads and writes from:
; - openai-codex/codex-rs/core/src/state/session.rs
; - openai-codex/codex-rs/core/src/session/mod.rs (the sess.* methods used
;   by session/turn.rs)
;
; The record internals are replaced by the session.rs port later; the
; function names and shapes in turn_session_state.metta are the stable
; boundary. Field notes:
; - token-usage-info: (CodexTokenUsageInfo $total $last $context-window)
;   or CodexAbsent, mirroring Option<TokenUsageInfo>.
; - previous-turn-settings / rate-limits / connector-selection: opaque
;   values or CodexAbsent.
; - mailbox-pending / total-tokens-full and the two warning flags are
;   booleans (Rust AtomicBool flags live here; see turn_context.metta).


(= (codex:turn-session-state
      $history
      $pending-input
      $token-usage-info
      $rate-limits
      $previous-turn-settings
      $server-reasoning-included
      $mailbox-pending
      $total-tokens-full
      $server-model-warning-emitted
      $model-verification-emitted
      $connector-selection)
   (CodexTurnSessionState
     $history
     $pending-input
     $token-usage-info
     $rate-limits
     $previous-turn-settings
     $server-reasoning-included
     $mailbox-pending
     $total-tokens-full
     $server-model-warning-emitted
     $model-verification-emitted
     $connector-selection))

(= (codex:turn-session-state-new)
   (CodexTurnSessionState
     ()
     ()
     CodexAbsent
     CodexAbsent
     CodexAbsent
     False
     False
     False
     False
     False
     CodexAbsent))

(= (codex:turn-session-state-history
      (CodexTurnSessionState
        $history
        $pending-input
        $token-usage-info
        $rate-limits
        $previous-turn-settings
        $server-reasoning-included
        $mailbox-pending
        $total-tokens-full
        $server-model-warning-emitted
        $model-verification-emitted
        $connector-selection))
   $history)

(= (codex:turn-session-state-pending-input
      (CodexTurnSessionState
        $history
        $pending-input
        $token-usage-info
        $rate-limits
        $previous-turn-settings
        $server-reasoning-included
        $mailbox-pending
        $total-tokens-full
        $server-model-warning-emitted
        $model-verification-emitted
        $connector-selection))
   $pending-input)

(= (codex:turn-session-state-token-usage-info
      (CodexTurnSessionState
        $history
        $pending-input
        $token-usage-info
        $rate-limits
        $previous-turn-settings
        $server-reasoning-included
        $mailbox-pending
        $total-tokens-full
        $server-model-warning-emitted
        $model-verification-emitted
        $connector-selection))
   $token-usage-info)

(= (codex:turn-session-state-rate-limits
      (CodexTurnSessionState
        $history
        $pending-input
        $token-usage-info
        $rate-limits
        $previous-turn-settings
        $server-reasoning-included
        $mailbox-pending
        $total-tokens-full
        $server-model-warning-emitted
        $model-verification-emitted
        $connector-selection))
   $rate-limits)

(= (codex:turn-session-state-previous-turn-settings
      (CodexTurnSessionState
        $history
        $pending-input
        $token-usage-info
        $rate-limits
        $previous-turn-settings
        $server-reasoning-included
        $mailbox-pending
        $total-tokens-full
        $server-model-warning-emitted
        $model-verification-emitted
        $connector-selection))
   $previous-turn-settings)

(= (codex:turn-session-state-server-reasoning-included
      (CodexTurnSessionState
        $history
        $pending-input
        $token-usage-info
        $rate-limits
        $previous-turn-settings
        $server-reasoning-included
        $mailbox-pending
        $total-tokens-full
        $server-model-warning-emitted
        $model-verification-emitted
        $connector-selection))
   $server-reasoning-included)

(= (codex:turn-session-state-mailbox-pending
      (CodexTurnSessionState
        $history
        $pending-input
        $token-usage-info
        $rate-limits
        $previous-turn-settings
        $server-reasoning-included
        $mailbox-pending
        $total-tokens-full
        $server-model-warning-emitted
        $model-verification-emitted
        $connector-selection))
   $mailbox-pending)

(= (codex:turn-session-state-total-tokens-full
      (CodexTurnSessionState
        $history
        $pending-input
        $token-usage-info
        $rate-limits
        $previous-turn-settings
        $server-reasoning-included
        $mailbox-pending
        $total-tokens-full
        $server-model-warning-emitted
        $model-verification-emitted
        $connector-selection))
   $total-tokens-full)

(= (codex:turn-session-state-server-model-warning-emitted
      (CodexTurnSessionState
        $history
        $pending-input
        $token-usage-info
        $rate-limits
        $previous-turn-settings
        $server-reasoning-included
        $mailbox-pending
        $total-tokens-full
        $server-model-warning-emitted
        $model-verification-emitted
        $connector-selection))
   $server-model-warning-emitted)

(= (codex:turn-session-state-model-verification-emitted
      (CodexTurnSessionState
        $history
        $pending-input
        $token-usage-info
        $rate-limits
        $previous-turn-settings
        $server-reasoning-included
        $mailbox-pending
        $total-tokens-full
        $server-model-warning-emitted
        $model-verification-emitted
        $connector-selection))
   $model-verification-emitted)

(= (codex:turn-session-state-connector-selection
      (CodexTurnSessionState
        $history
        $pending-input
        $token-usage-info
        $rate-limits
        $previous-turn-settings
        $server-reasoning-included
        $mailbox-pending
        $total-tokens-full
        $server-model-warning-emitted
        $model-verification-emitted
        $connector-selection))
   $connector-selection)
