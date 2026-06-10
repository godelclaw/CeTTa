!(register-module! ../codex)
!(import! &self codex:model_stream)

!(println! "=== Codex model stream demo ===")

; A fixture stream as the turn loop will consume it: created, one text
; delta, the completed item, then response completion.
(= (demo:stream)
   (codex:fixture-model-stream
     ((CodexStreamItemOk (CodexResponseEventCreated))
      (CodexStreamItemOk (CodexResponseEventOutputTextDelta "Hello"))
      (CodexStreamItemOk
        (CodexResponseEventOutputItemDone (DemoAssistantMessage "Hello")))
      (CodexStreamItemOk
        (CodexResponseEventCompleted "resp-1" (DemoTokenUsage 12 3))))))

!(println! (codex:model-stream-next (demo:stream)))

; A scripted client session: first request fails with a retryable stream
; error, the second opens the fixture stream.
(= (demo:client-session)
   (codex:fixture-client-session
     ((codex:fixture-stream-opening-err
        (codex:error-stream "stream disconnected before completion" 750))
      (codex:fixture-stream-opening-ok (demo:stream)))
     True))

!(println! (codex:turn-client-session-stream (demo:client-session) (DemoPrompt)))

!(assertEqualToResult
  (codex:client-stream-result-is-ok
    (codex:turn-client-session-stream (demo:client-session) (DemoPrompt)))
  (False))

!(assertEqualToResult
  (codex:error-is-retryable
    (codex:client-stream-result-error
      (codex:turn-client-session-stream (demo:client-session) (DemoPrompt))))
  (True))

!(println! "=== demo complete ===")
