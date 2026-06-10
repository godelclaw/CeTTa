; Rust-faithful model stream abstraction (core-loop spine).
;
; This ports the stream/client-session surface the turn loop consumes from:
; - openai-codex/codex-rs/core/src/client_common.rs (ResponseStream shape)
; - openai-codex/codex-rs/core/src/client.rs (ModelClientSession's three
;   calls used by session/turn.rs: stream, reset_websocket_session,
;   try_switch_fallback_transport)
;
; The stream source is swappable by construction: the loop only calls
; codex:model-stream-next and the codex:turn-client-session-* functions,
; which equation-dispatch on the implementation constructor. The fixture
; implementations below stand in until client.rs is ported; a real client
; adds new constructors plus equations without touching loop code.
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust streams are async (futures::Stream yielding
;   Option<Result<ResponseEvent>>). The CeTTa stream is a stepped value:
;   codex:model-stream-next returns the next stream item plus the advanced
;   stream, and (CodexModelStreamEnd) stands for Rust's None.
; - The fixture client session consumes scripted per-request stream
;   openings in order; an exhausted script yields a CodexErrStream so the
;   retry wrapper's budget paths stay exercisable.

!(import! &self response_event)
!(import! &self turn_error)

; --- model stream -----------------------------------------------------------

(= (codex:fixture-model-stream $stream-items)
   (CodexFixtureModelStream $stream-items))

(= (codex:model-stream-next (CodexFixtureModelStream $stream-items))
   (if (== $stream-items ())
       (CodexModelStreamEnd)
       (let ($head $tail) (decons-atom $stream-items)
         (CodexModelStreamNext $head (CodexFixtureModelStream $tail)))))

(= (codex:model-stream-next-item (CodexModelStreamNext $item $stream))
   $item)

(= (codex:model-stream-next-stream (CodexModelStreamNext $item $stream))
   $stream)

(= (codex:model-stream-ended (CodexModelStreamEnd))
   True)

(= (codex:model-stream-ended (CodexModelStreamNext $item $stream))
   False)

; --- client session ----------------------------------------------------------

; Fixture impl state: scripted stream openings (one per sampling request),
; whether a fallback transport exists, and whether it was already switched.
(= (codex:fixture-client-session $openings $fallback-available)
   (CodexFixtureClientSession $openings $fallback-available False))

(= (codex:fixture-stream-opening-ok $stream)
   (CodexFixtureStreamOpeningOk $stream))

(= (codex:fixture-stream-opening-err $err)
   (CodexFixtureStreamOpeningErr $err))

; ModelClientSession::stream -> Ok(stream) | Err(err); the session value
; advances past the consumed scripted opening either way.
(= (codex:turn-client-session-stream
      (CodexFixtureClientSession $openings $fallback-available $switched)
      $prompt)
   (if (== $openings ())
       (CodexClientStreamErr
         (CodexErrStream "fixture stream openings exhausted" CodexAbsent)
         (CodexFixtureClientSession () $fallback-available $switched))
       (let ($head $tail) (decons-atom $openings)
         (codex:turn-client-session-stream-opening
           $head
           (CodexFixtureClientSession $tail $fallback-available $switched)))))

(= (codex:turn-client-session-stream-opening
      (CodexFixtureStreamOpeningOk $stream)
      $session)
   (CodexClientStreamOk $stream $session))

(= (codex:turn-client-session-stream-opening
      (CodexFixtureStreamOpeningErr $err)
      $session)
   (CodexClientStreamErr $err $session))

(= (codex:client-stream-result-is-ok (CodexClientStreamOk $stream $session))
   True)

(= (codex:client-stream-result-is-ok (CodexClientStreamErr $err $session))
   False)

(= (codex:client-stream-result-stream (CodexClientStreamOk $stream $session))
   $stream)

(= (codex:client-stream-result-error (CodexClientStreamErr $err $session))
   $err)

(= (codex:client-stream-result-session (CodexClientStreamOk $stream $session))
   $session)

(= (codex:client-stream-result-session (CodexClientStreamErr $err $session))
   $session)

; ModelClientSession::reset_websocket_session — fixture state is unaffected.
(= (codex:turn-client-session-reset-websocket
      (CodexFixtureClientSession $openings $fallback-available $switched))
   (CodexFixtureClientSession $openings $fallback-available $switched))

; ModelClientSession::try_switch_fallback_transport — succeeds at most once
; when a fallback transport exists, exactly like Rust's one-time switch.
(= (codex:turn-client-session-try-switch-fallback-transport
      (CodexFixtureClientSession $openings $fallback-available $switched))
   (if $switched
       (CodexFallbackSwitched
         False
         (CodexFixtureClientSession $openings $fallback-available $switched))
       (if $fallback-available
           (CodexFallbackSwitched
             True
             (CodexFixtureClientSession $openings $fallback-available True))
           (CodexFallbackSwitched
             False
             (CodexFixtureClientSession
               $openings $fallback-available $switched)))))

(= (codex:fallback-switched-switched (CodexFallbackSwitched $switched $session))
   $switched)

(= (codex:fallback-switched-session (CodexFallbackSwitched $switched $session))
   $session)
