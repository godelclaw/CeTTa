!(register-module! ../codex)
!(import! &self codex:model_stream)

; --- response event constructors (all 14 variants, Rust order) -------------

!(assertEqualToResult
  (codex:response-event-created)
  ((CodexResponseEventCreated)))

!(assertEqualToResult
  (codex:response-event-output-item-done (TestItem))
  ((CodexResponseEventOutputItemDone (TestItem))))

!(assertEqualToResult
  (codex:response-event-output-item-added (TestItem))
  ((CodexResponseEventOutputItemAdded (TestItem))))

!(assertEqualToResult
  (codex:response-event-server-model "gpt-5.1-codex")
  ((CodexResponseEventServerModel "gpt-5.1-codex")))

!(assertEqualToResult
  (codex:response-event-model-verifications ((TestVerification)))
  ((CodexResponseEventModelVerifications ((TestVerification)))))

!(assertEqualToResult
  (codex:response-event-server-reasoning-included True)
  ((CodexResponseEventServerReasoningIncluded True)))

!(assertEqualToResult
  (codex:response-event-completed "resp-1" (TestUsage 100 20))
  ((CodexResponseEventCompleted "resp-1" (TestUsage 100 20))))

!(assertEqualToResult
  (codex:response-event-completed-response-id
    (codex:response-event-completed "resp-1" CodexAbsent))
  ("resp-1"))

!(assertEqualToResult
  (codex:response-event-completed-token-usage
    (codex:response-event-completed "resp-1" CodexAbsent))
  (CodexAbsent))

!(assertEqualToResult
  (codex:response-event-output-text-delta "hel")
  ((CodexResponseEventOutputTextDelta "hel")))

!(assertEqualToResult
  (codex:response-event-tool-call-input-delta "item-1" "call-1" "{\"cmd")
  ((CodexResponseEventToolCallInputDelta "item-1" "call-1" "{\"cmd")))

!(assertEqualToResult
  (codex:response-event-tool-call-input-delta-call-id
    (codex:response-event-tool-call-input-delta "item-1" CodexAbsent "x"))
  (CodexAbsent))

!(assertEqualToResult
  (codex:response-event-reasoning-summary-delta "think" 0)
  ((CodexResponseEventReasoningSummaryDelta "think" 0)))

!(assertEqualToResult
  (codex:response-event-reasoning-content-delta "raw" 1)
  ((CodexResponseEventReasoningContentDelta "raw" 1)))

!(assertEqualToResult
  (codex:response-event-reasoning-summary-part-added 2)
  ((CodexResponseEventReasoningSummaryPartAdded 2)))

!(assertEqualToResult
  (codex:response-event-rate-limits (TestSnapshot))
  ((CodexResponseEventRateLimits (TestSnapshot))))

!(assertEqualToResult
  (codex:response-event-models-etag "etag-1")
  ((CodexResponseEventModelsEtag "etag-1")))

; --- stream items -------------------------------------------------------------

!(assertEqualToResult
  (codex:stream-item-is-ok (codex:stream-item-ok (CodexResponseEventCreated)))
  (True))

!(assertEqualToResult
  (codex:stream-item-is-ok (codex:stream-item-err (CodexErrTimeout)))
  (False))

!(assertEqualToResult
  (codex:stream-item-event (codex:stream-item-ok (CodexResponseEventCreated)))
  ((CodexResponseEventCreated)))

!(assertEqualToResult
  (codex:stream-item-error (codex:stream-item-err (CodexErrTimeout)))
  ((CodexErrTimeout)))

; --- fixture model stream stepping ----------------------------------------------

!(assertEqualToResult
  (codex:model-stream-next
    (codex:fixture-model-stream
      ((CodexStreamItemOk (CodexResponseEventCreated))
       (CodexStreamItemOk (CodexResponseEventOutputTextDelta "x")))))
  ((CodexModelStreamNext
     (CodexStreamItemOk (CodexResponseEventCreated))
     (CodexFixtureModelStream
       ((CodexStreamItemOk (CodexResponseEventOutputTextDelta "x")))))))

!(assertEqualToResult
  (codex:model-stream-next (codex:fixture-model-stream ()))
  ((CodexModelStreamEnd)))

!(assertEqualToResult
  (codex:model-stream-ended (CodexModelStreamEnd))
  (True))

; --- fixture client session -------------------------------------------------------

; scripted Ok opening is consumed in order
!(assertEqualToResult
  (codex:turn-client-session-stream
    (codex:fixture-client-session
      ((codex:fixture-stream-opening-ok (TestStream1))
       (codex:fixture-stream-opening-err (CodexErrTimeout)))
      False)
    (TestPrompt))
  ((CodexClientStreamOk
     (TestStream1)
     (CodexFixtureClientSession
       ((CodexFixtureStreamOpeningErr (CodexErrTimeout)))
       False
       False))))

; scripted Err opening
!(assertEqualToResult
  (codex:turn-client-session-stream
    (codex:fixture-client-session
      ((codex:fixture-stream-opening-err (CodexErrTimeout)))
      False)
    (TestPrompt))
  ((CodexClientStreamErr
     (CodexErrTimeout)
     (CodexFixtureClientSession () False False))))

; exhausted script degrades to a stream error
!(assertEqualToResult
  (codex:client-stream-result-is-ok
    (codex:turn-client-session-stream
      (codex:fixture-client-session () False)
      (TestPrompt)))
  (False))

; fallback transport switches at most once
!(assertEqualToResult
  (codex:turn-client-session-try-switch-fallback-transport
    (codex:fixture-client-session () True))
  ((CodexFallbackSwitched True (CodexFixtureClientSession () True True))))

!(assertEqualToResult
  (codex:fallback-switched-switched
    (codex:turn-client-session-try-switch-fallback-transport
      (CodexFixtureClientSession () True True)))
  (False))

!(assertEqualToResult
  (codex:fallback-switched-switched
    (codex:turn-client-session-try-switch-fallback-transport
      (codex:fixture-client-session () False)))
  (False))

; reset is state-preserving for the fixture
!(assertEqualToResult
  (codex:turn-client-session-reset-websocket
    (CodexFixtureClientSession () True True))
  ((CodexFixtureClientSession () True True)))

; --- is_retryable table -------------------------------------------------------------

!(assertEqualToResult
  (codex:error-is-retryable (codex:error-stream "disconnect" 500))
  (True))

!(assertEqualToResult
  (codex:error-is-retryable (codex:error-timeout))
  (True))

!(assertEqualToResult
  (codex:error-is-retryable (codex:error-turn-aborted))
  (False))

!(assertEqualToResult
  (codex:error-is-retryable (codex:error-invalid-image-request))
  (False))

!(assertEqualToResult
  (codex:error-is-retryable (codex:error-context-window-exceeded))
  (False))

!(assertEqualToResult
  (codex:error-is-retryable (codex:error-usage-limit-reached CodexAbsent))
  (False))

!(assertEqualToResult
  (codex:error-stream-requested-delay-ms (codex:error-stream "x" 1500))
  (1500))
