; Rust-faithful turn world and effects (core-loop spine).
;
; This ports the emission half of the Session surface used by
; session/turn.rs: send_event, emit_turn_item_started/completed,
; notify_stream_error, plus the world record that threads session state,
; injected services, and the ordered effect log through the loop.
;
; The exactness contract (specs plan): each Rust sess.* call site maps to
; one named function here or in turn_session_state.metta, invoked at the
; same position in the same branch. The future session.rs port replaces
; the effect-log append with real dispatch without changing callers.
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust emits events through async channels; the CeTTa world appends
;   (CodexTurnEffect* ...) terms to an ordered log.
; - tokio::time::sleep in the retry wrapper becomes a logged
;   (CodexTurnEffectSleep $delay-ms) effect.
; - error_or_panic (debug-panic in Rust) becomes a logged warning effect
;   with cfg!(debug_assertions) taken as false.

; --- services ----------------------------------------------------------------

; Injected boundaries: hooks provider, compact runner, router builder,
; client session, cancellation probe. Defaults land with their slices;
; constructors live here so the world shape is stable from slice 2 on.
(= (codex:turn-services
      $hooks-provider
      $compact-runner
      $router-builder
      $client-session
      $cancellation)
   (CodexTurnServices
     $hooks-provider
     $compact-runner
     $router-builder
     $client-session
     $cancellation))

(= (codex:turn-services-hooks-provider
      (CodexTurnServices $hooks $compact $router $client $cancellation))
   $hooks)

(= (codex:turn-services-compact-runner
      (CodexTurnServices $hooks $compact $router $client $cancellation))
   $compact)

(= (codex:turn-services-router-builder
      (CodexTurnServices $hooks $compact $router $client $cancellation))
   $router)

(= (codex:turn-services-client-session
      (CodexTurnServices $hooks $compact $router $client $cancellation))
   $client)

(= (codex:turn-services-cancellation
      (CodexTurnServices $hooks $compact $router $client $cancellation))
   $cancellation)

(= (codex:turn-services-with-client-session
      (CodexTurnServices $hooks $compact $router $client $cancellation)
      $new-client)
   (CodexTurnServices $hooks $compact $router $new-client $cancellation))

; --- world ---------------------------------------------------------------------

(= (codex:turn-world $session-state $services $effects)
   (CodexTurnWorld $session-state $services $effects))

(= (codex:turn-world-session-state
      (CodexTurnWorld $session-state $services $effects))
   $session-state)

(= (codex:turn-world-services
      (CodexTurnWorld $session-state $services $effects))
   $services)

(= (codex:turn-world-effects
      (CodexTurnWorld $session-state $services $effects))
   $effects)

(= (codex:turn-world-with-session-state
      (CodexTurnWorld $session-state $services $effects)
      $new-state)
   (CodexTurnWorld $new-state $services $effects))

(= (codex:turn-world-with-services
      (CodexTurnWorld $session-state $services $effects)
      $new-services)
   (CodexTurnWorld $session-state $new-services $effects))

; --- effect log -----------------------------------------------------------------

; Local snoc: effects append at the tail to preserve emission order
; without lib list helpers (import-weight evaluator constraint; see
; turn_session_state.metta's local append note).
(= (codex:turn-effects-snoc $effects $effect)
   (if (== $effects ())
       ($effect)
       (let ($head $tail) (decons-atom $effects)
         (case (collapse (codex:turn-effects-snoc $tail $effect))
           ((($rest)
             (cons-atom $head $rest)))))))

(= (codex:turn-world-append-effect
      (CodexTurnWorld $session-state $services $effects)
      $effect)
   (case (collapse (codex:turn-effects-snoc $effects $effect))
     ((($appended)
       (CodexTurnWorld $session-state $services $appended)))))

; --- emission functions (one per Rust call site family) --------------------------

; sess.send_event(turn_context, event)
(= (codex:turn-send-event $world $event)
   (case (collapse $world)
     ((($w)
       (codex:turn-world-append-effect $w (CodexTurnEffectEvent $event))))))

; sess.emit_turn_item_started(turn_context, item)
(= (codex:turn-emit-turn-item-started $world $item)
   (case (collapse $world)
     ((($w)
       (codex:turn-world-append-effect
         $w
         (CodexTurnEffectItemStarted $item))))))

; sess.emit_turn_item_completed(turn_context, item)
(= (codex:turn-emit-turn-item-completed $world $item)
   (case (collapse $world)
     ((($w)
       (codex:turn-world-append-effect
         $w
         (CodexTurnEffectItemCompleted $item))))))

; sess.notify_stream_error(turn_context, message, error)
(= (codex:turn-notify-stream-error $world $message $error)
   (case (collapse $world)
     ((($w)
       (codex:turn-world-append-effect
         $w
         (CodexTurnEffectStreamError $message $error))))))

; tokio::time::sleep(delay) in run_sampling_request
(= (codex:turn-effect-sleep $world $delay-ms)
   (case (collapse $world)
     ((($w)
       (codex:turn-world-append-effect
         $w
         (CodexTurnEffectSleep $delay-ms))))))

; error_or_panic: warning in release builds
(= (codex:turn-error-or-panic $world $message)
   (case (collapse $world)
     ((($w)
       (codex:turn-world-append-effect
         $w
         (CodexTurnEffectWarning $message))))))

; --- world-level session transitions ----------------------------------------------

; Convenience lift: apply a session-state transition inside the world.
(= (codex:turn-world-map-session $world $new-state)
   (codex:turn-world-with-session-state $world $new-state))
