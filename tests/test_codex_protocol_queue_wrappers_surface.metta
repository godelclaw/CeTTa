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
    (codex:event-envelope-json
      (codex:event-envelope
        "sub_1"
        (codex:realtime-conversation-closed-event "user_requested_stop"))))
  ("{\"id\":\"sub_1\",\"msg\":{\"type\":\"realtime_conversation_closed\",\"reason\":\"user_requested_stop\"}}"))
