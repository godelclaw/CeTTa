!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

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
