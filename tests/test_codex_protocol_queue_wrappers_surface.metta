!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (json-stringify
    (codex:w3c-trace-context-json
      (codex:w3c-trace-context
        "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"
        CodexAbsent)))
  ("{\"traceparent\":\"00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:submission-json
      (codex:submission
        "sub_1"
        (codex:realtime-conversation-start-op
          (codex:conversation-start-params
            (codex:realtime-output-modality-audio)
            "be helpful"
            "conv_1"
            CodexAbsent
            CodexAbsent))
        CodexAbsent)))
  ("{\"id\":\"sub_1\",\"op\":{\"type\":\"realtime_conversation_start\",\"output_modality\":\"audio\",\"prompt\":\"be helpful\",\"session_id\":\"conv_1\"}}"))

!(assertEqualToResult
  (json-stringify
    (codex:submission-json
      (codex:submission
        "sub_2"
        (codex:realtime-conversation-list-voices-op)
        (codex:w3c-trace-context
          "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"
          "rojo=00f067aa0ba902b7"))))
  ("{\"id\":\"sub_2\",\"op\":{\"type\":\"realtime_conversation_list_voices\"},\"trace\":{\"traceparent\":\"00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01\",\"tracestate\":\"rojo=00f067aa0ba902b7\"}}"))

!(assertEqualToResult
  (json-stringify
    (codex:event-envelope-json
      (codex:event-envelope
        "sub_1"
        (codex:realtime-conversation-closed-event "user_requested_stop"))))
  ("{\"id\":\"sub_1\",\"msg\":{\"type\":\"realtime_conversation_closed\",\"reason\":\"user_requested_stop\"}}"))
