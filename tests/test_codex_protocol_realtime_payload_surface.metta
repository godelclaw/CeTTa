!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (json-stringify
    (codex:realtime-event-json
      (codex:realtime-event-session-updated
        "sess_123"
        "backend prompt")))
  ("{\"SessionUpdated\":{\"session_id\":\"sess_123\",\"instructions\":\"backend prompt\"}}"))

!(assertEqualToResult
  (json-stringify
    (codex:realtime-event-json
      (codex:realtime-event-input-audio-speech-started
        (codex:realtime-input-audio-speech-started CodexAbsent))))
  ("{\"InputAudioSpeechStarted\":{\"item_id\":null}}"))

!(assertEqualToResult
  (json-stringify
    (codex:realtime-event-json
      (codex:realtime-event-input-transcript-delta
        (codex:realtime-transcript-delta "hello "))))
  ("{\"InputTranscriptDelta\":{\"delta\":\"hello \"}}"))

!(assertEqualToResult
  (json-stringify
    (codex:realtime-event-json
      (codex:realtime-event-output-transcript-done
        (codex:realtime-transcript-done "done text"))))
  ("{\"OutputTranscriptDone\":{\"text\":\"done text\"}}"))

!(assertEqualToResult
  (json-stringify
    (codex:realtime-event-json
      (codex:realtime-event-response-created
        (codex:realtime-response-created CodexAbsent))))
  ("{\"ResponseCreated\":{\"response_id\":null}}"))

!(assertEqualToResult
  (json-stringify
    (codex:realtime-event-json
      (codex:realtime-event-conversation-item-added
        (JsonObject
          ((JsonPair "type" (JsonString "message"))
           (JsonPair "seq" (JsonNumber 7)))))))
  ("{\"ConversationItemAdded\":{\"type\":\"message\",\"seq\":7}}"))

!(assertEqualToResult
  (json-stringify
    (codex:realtime-event-json
      (codex:realtime-event-conversation-item-done
        "item_123")))
  ("{\"ConversationItemDone\":{\"item_id\":\"item_123\"}}"))

!(assertEqualToResult
  (json-stringify
    (codex:realtime-event-json
      (codex:realtime-event-handoff-requested
        (codex:realtime-handoff-requested
          "handoff_123"
          "item_123"
          "delegate this"
          ((codex:realtime-transcript-entry "user" "delegate this"))))))
  ("{\"HandoffRequested\":{\"handoff_id\":\"handoff_123\",\"item_id\":\"item_123\",\"input_transcript\":\"delegate this\",\"active_transcript\":[{\"role\":\"user\",\"text\":\"delegate this\"}]}}"))

!(assertEqualToResult
  (json-stringify
    (codex:realtime-event-json
      (codex:realtime-event-noop-requested
        (codex:realtime-noop-requested
          "call_123"
          "item_123"))))
  ("{\"NoopRequested\":{\"call_id\":\"call_123\",\"item_id\":\"item_123\"}}"))

!(assertEqualToResult
  (json-stringify
    (codex:realtime-event-json
      (codex:realtime-event-error "boom")))
  ("{\"Error\":\"boom\"}"))

!(assertEqualToResult
  (codex:item-type
    (codex:realtime-conversation-realtime-event
      (codex:realtime-event-input-transcript-delta
        (codex:realtime-transcript-delta "hello "))))
  ("realtime_conversation_realtime"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:realtime-conversation-realtime-event
        (codex:realtime-event-input-transcript-delta
          (codex:realtime-transcript-delta "hello ")))))
  ("{\"type\":\"realtime_conversation_realtime\",\"payload\":{\"InputTranscriptDelta\":{\"delta\":\"hello \"}}}"))
