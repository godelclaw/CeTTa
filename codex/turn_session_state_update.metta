; Rust-faithful turn session state record: field updaters.
;
; Split from turn_session_state_record.metta to respect the evaluator
; module-size constraint (see that module's header for field notes).


(= (codex:turn-session-state-with-history
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
        $connector-selection)
      $new-value)
   (CodexTurnSessionState
     
$new-value     $pending-input     $token-usage-info     $rate-limits     $previous-turn-settings     $server-reasoning-included     $mailbox-pending     $total-tokens-full     $server-model-warning-emitted     $model-verification-emitted     $connector-selection))

(= (codex:turn-session-state-with-pending-input
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
        $connector-selection)
      $new-value)
   (CodexTurnSessionState
     
$history     $new-value     $token-usage-info     $rate-limits     $previous-turn-settings     $server-reasoning-included     $mailbox-pending     $total-tokens-full     $server-model-warning-emitted     $model-verification-emitted     $connector-selection))

(= (codex:turn-session-state-with-token-usage-info
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
        $connector-selection)
      $new-value)
   (CodexTurnSessionState
     
$history     $pending-input     $new-value     $rate-limits     $previous-turn-settings     $server-reasoning-included     $mailbox-pending     $total-tokens-full     $server-model-warning-emitted     $model-verification-emitted     $connector-selection))

(= (codex:turn-session-state-with-rate-limits
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
        $connector-selection)
      $new-value)
   (CodexTurnSessionState
     
$history     $pending-input     $token-usage-info     $new-value     $previous-turn-settings     $server-reasoning-included     $mailbox-pending     $total-tokens-full     $server-model-warning-emitted     $model-verification-emitted     $connector-selection))

(= (codex:turn-session-state-with-previous-turn-settings
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
        $connector-selection)
      $new-value)
   (CodexTurnSessionState
     
$history     $pending-input     $token-usage-info     $rate-limits     $new-value     $server-reasoning-included     $mailbox-pending     $total-tokens-full     $server-model-warning-emitted     $model-verification-emitted     $connector-selection))

(= (codex:turn-session-state-with-server-reasoning-included
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
        $connector-selection)
      $new-value)
   (CodexTurnSessionState
     
$history     $pending-input     $token-usage-info     $rate-limits     $previous-turn-settings     $new-value     $mailbox-pending     $total-tokens-full     $server-model-warning-emitted     $model-verification-emitted     $connector-selection))

(= (codex:turn-session-state-with-mailbox-pending
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
        $connector-selection)
      $new-value)
   (CodexTurnSessionState
     
$history     $pending-input     $token-usage-info     $rate-limits     $previous-turn-settings     $server-reasoning-included     $new-value     $total-tokens-full     $server-model-warning-emitted     $model-verification-emitted     $connector-selection))

(= (codex:turn-session-state-with-total-tokens-full
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
        $connector-selection)
      $new-value)
   (CodexTurnSessionState
     
$history     $pending-input     $token-usage-info     $rate-limits     $previous-turn-settings     $server-reasoning-included     $mailbox-pending     $new-value     $server-model-warning-emitted     $model-verification-emitted     $connector-selection))

(= (codex:turn-session-state-with-server-model-warning-emitted
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
        $connector-selection)
      $new-value)
   (CodexTurnSessionState
     
$history     $pending-input     $token-usage-info     $rate-limits     $previous-turn-settings     $server-reasoning-included     $mailbox-pending     $total-tokens-full     $new-value     $model-verification-emitted     $connector-selection))

(= (codex:turn-session-state-with-model-verification-emitted
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
        $connector-selection)
      $new-value)
   (CodexTurnSessionState
     
$history     $pending-input     $token-usage-info     $rate-limits     $previous-turn-settings     $server-reasoning-included     $mailbox-pending     $total-tokens-full     $server-model-warning-emitted     $new-value     $connector-selection))

(= (codex:turn-session-state-with-connector-selection
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
        $connector-selection)
      $new-value)
   (CodexTurnSessionState
     
$history     $pending-input     $token-usage-info     $rate-limits     $previous-turn-settings     $server-reasoning-included     $mailbox-pending     $total-tokens-full     $server-model-warning-emitted     $model-verification-emitted     $new-value))
