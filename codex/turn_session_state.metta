; Rust-faithful turn session transitions (core-loop spine).
;
; This ports the exact sess.* call surface used by session/turn.rs and
; tasks/regular.rs, one named function per Rust method, as pure
; transitions over CodexTurnSessionState:
; - has_pending_input / get_pending_input / prepend pending input
; - record_conversation_items (history append)
; - get_total_token_usage (context_manager/history.rs:312-330 formula)
; - update_token_usage_info (session/mod.rs:2784-2792 state half)
; - update_rate_limits (set_rate_limits state half)
; - set_total_tokens_full, set_server_reasoning_included,
;   previous-turn-settings get/set, mailbox-has-pending
;
; Required slice-local deviations from Rust, documented for audit:
; - estimate_item_token_count (context_manager estimation) is not yet
;   ported; codex:turn-session-estimate-item-tokens defaults to 0 per
;   item, so the get_total_token_usage FORMULA is exact while estimated
;   contributions await the history-estimation lane. The
;   non-last-reasoning estimate branch is kept for the same reason.
; - merge_rate_limit_fields is not yet ported; update-rate-limits stores
;   the latest snapshot (merge lands with the rate-limit lane).
; - Event emission halves of the Rust methods (send_token_count_event,
;   turn-item events) live in turn_effects.metta at the world level.

!(import! &self context_manager_history)
!(import! &self list)
!(import! &self token_usage)
!(import! &self turn_session_state_record)
!(import! &self turn_session_state_update)

; Local append: lib list:append loses results under this module's import
; weight (same evaluator behavior that gave turn.metta its own
; fixture-append-items; see tests/repro_evaluator_materialization.metta).
(= (codex:turn-session-append $left $right)
   (if (== $left ())
       $right
       (let ($head $tail) (decons-atom $left)
         (case (collapse (codex:turn-session-append $tail $right))
           ((($rest)
             (cons-atom $head $rest)))))))

; --- pending input -----------------------------------------------------------

(= (codex:turn-session-has-pending-input $state)
   (if (== (codex:turn-session-state-pending-input $state) ())
       False
       True))

; Rust get_pending_input drains the queue and returns the drained items.
(= (codex:turn-session-take-pending-input $state)
   (case (collapse (codex:turn-session-state-pending-input $state))
     ((($items)
       (CodexPendingInputTaken
         $items
         (codex:turn-session-state-with-pending-input $state ()))))))

(= (codex:pending-input-taken-items (CodexPendingInputTaken $items $state))
   $items)

(= (codex:pending-input-taken-state (CodexPendingInputTaken $items $state))
   $state)

(= (codex:turn-session-push-pending-input $state $item)
   (case (collapse (codex:turn-session-state-pending-input $state))
     ((($pending)
       (case (collapse (codex:turn-session-append $pending ($item)))
         ((($queue)
           (codex:turn-session-state-with-pending-input $state $queue))))))))

; Rust requeues blocked pending input at the FRONT (turn.rs 409).
(= (codex:turn-session-prepend-pending-input $state $items)
   (case (collapse (codex:turn-session-state-pending-input $state))
     ((($pending)
       (case (collapse (codex:turn-session-append $items $pending))
         ((($queue)
           (codex:turn-session-state-with-pending-input $state $queue))))))))

; --- history -------------------------------------------------------------------

(= (codex:turn-session-record-conversation-items $state $items)
   (case (collapse (codex:turn-session-state-history $state))
     ((($current)
       (case (collapse (codex:turn-session-append $current $items))
         ((($history)
           (codex:turn-session-state-with-history $state $history))))))))

(= (codex:turn-session-clone-history $state)
   (codex:turn-session-state-history $state))

; --- token usage ------------------------------------------------------------------

(= (codex:token-usage-info $total $last $model-context-window)
   (CodexTokenUsageInfo $total $last $model-context-window))

(= (codex:token-usage-info-total
      (CodexTokenUsageInfo $total $last $model-context-window))
   $total)

(= (codex:token-usage-info-last
      (CodexTokenUsageInfo $total $last $model-context-window))
   $last)

(= (codex:token-usage-info-model-context-window
      (CodexTokenUsageInfo $total $last $model-context-window))
   $model-context-window)

; Deviation: per-item estimator defaults to 0 until the history
; estimation lane lands; the surrounding formula is exact.
(= (codex:turn-session-estimate-item-tokens $item)
   0)

(= (codex:turn-session-estimate-items-tokens $items)
   (if (== $items ())
       0
       (let ($head $tail) (decons-atom $items)
         (case (collapse (codex:turn-session-estimate-item-tokens $head))
           ((($head-tokens)
             (+ $head-tokens
                (codex:turn-session-estimate-items-tokens $tail))))))))

; context_manager/history.rs get_total_token_usage: last total tokens,
; plus estimated items after the last model-generated item, plus the
; non-last reasoning estimate when the server did not include reasoning.
(= (codex:turn-session-last-total-tokens $state)
   (case (collapse (codex:turn-session-state-token-usage-info $state))
     ((($info)
       (if (== $info CodexAbsent)
           0
           (codex:token-usage-total-tokens
             (codex:token-usage-info-last $info)))))))

(= (codex:turn-session-get-total-token-usage $state)
   (case (collapse (codex:turn-session-last-total-tokens $state))
     ((($last-tokens)
       (case (collapse
               (codex:turn-session-estimate-items-tokens
                 (codex:context-manager-history-items-after-last-model-generated-item
                   (codex:turn-session-state-history $state))))
         ((($after-tokens)
           (if (codex:turn-session-state-server-reasoning-included $state)
               (+ $last-tokens $after-tokens)
               (+ (+ $last-tokens
                     (codex:turn-session-non-last-reasoning-tokens $state))
                  $after-tokens)))))))))

; Deviation: with the estimator at 0 this contributes 0; the branch is
; kept so the history-estimation lane only replaces the estimator.
(= (codex:turn-session-non-last-reasoning-tokens $state)
   0)

; session/mod.rs update_token_usage_info, state half: only when usage is
; present; total accumulates, last replaces, window from the turn context.
(= (codex:turn-session-update-token-usage-info
      $state $token-usage $model-context-window)
   (if (== $token-usage CodexAbsent)
       $state
       (case (collapse (codex:turn-session-state-token-usage-info $state))
         ((($info)
           (case (collapse
                   (codex:turn-session-merged-token-usage-info
                     $info $token-usage $model-context-window))
             ((($merged)
               (codex:turn-session-state-with-token-usage-info
                 $state $merged)))))))))

(= (codex:turn-session-merged-token-usage-info
      CodexAbsent $token-usage $model-context-window)
   (CodexTokenUsageInfo $token-usage $token-usage $model-context-window))

(= (codex:turn-session-merged-token-usage-info
      (CodexTokenUsageInfo $total $last $window)
      $token-usage
      $model-context-window)
   (case (collapse (codex:token-usage-add $total $token-usage))
     ((($new-total)
       (CodexTokenUsageInfo $new-total $token-usage $model-context-window)))))

; --- rate limits / flags --------------------------------------------------------

(= (codex:turn-session-update-rate-limits $state $snapshot)
   (codex:turn-session-state-with-rate-limits $state $snapshot))

(= (codex:turn-session-set-total-tokens-full $state)
   (codex:turn-session-state-with-total-tokens-full $state True))

(= (codex:turn-session-set-server-reasoning-included $state $included)
   (codex:turn-session-state-with-server-reasoning-included
     $state $included))

(= (codex:turn-session-mailbox-has-pending $state)
   (codex:turn-session-state-mailbox-pending $state))

(= (codex:turn-session-previous-turn-settings $state)
   (codex:turn-session-state-previous-turn-settings $state))

(= (codex:turn-session-set-previous-turn-settings $state $settings)
   (codex:turn-session-state-with-previous-turn-settings $state $settings))
