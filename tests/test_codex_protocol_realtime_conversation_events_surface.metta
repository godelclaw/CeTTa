!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:item-type
    (codex:realtime-conversation-started-event
      "sess_123"
      (codex:realtime-conversation-version-v1)))
  ("realtime_conversation_started"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:realtime-conversation-started-event
        "sess_123"
        (codex:realtime-conversation-version-v1))))
  ("{\"type\":\"realtime_conversation_started\",\"session_id\":\"sess_123\",\"version\":\"v1\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:realtime-conversation-started-event
        CodexAbsent
        (codex:realtime-conversation-version-v2))))
  ("{\"type\":\"realtime_conversation_started\",\"session_id\":null,\"version\":\"v2\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:realtime-conversation-closed-event CodexAbsent)))
  ("{\"type\":\"realtime_conversation_closed\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:realtime-conversation-closed-event "user_requested_stop")))
  ("{\"type\":\"realtime_conversation_closed\",\"reason\":\"user_requested_stop\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:realtime-conversation-sdp-event "offer-sdp")))
  ("{\"type\":\"realtime_conversation_sdp\",\"sdp\":\"offer-sdp\"}"))
