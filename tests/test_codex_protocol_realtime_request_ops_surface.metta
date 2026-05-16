!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:op-type
    (codex:realtime-conversation-start-op
      (codex:conversation-start-params
        (codex:realtime-output-modality-audio)
        "be helpful"
        "conv_1"
        CodexAbsent
        CodexAbsent)))
  ("realtime_conversation_start"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:realtime-conversation-start-op
        (codex:conversation-start-params
          (codex:realtime-output-modality-audio)
          "be helpful"
          "conv_1"
          CodexAbsent
          CodexAbsent))))
  ("{\"type\":\"realtime_conversation_start\",\"output_modality\":\"audio\",\"prompt\":\"be helpful\",\"session_id\":\"conv_1\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:realtime-conversation-start-op
        (codex:conversation-start-params
          (codex:realtime-output-modality-audio)
          CodexAbsent
          CodexAbsent
          CodexAbsent
          CodexAbsent))))
  ("{\"type\":\"realtime_conversation_start\",\"output_modality\":\"audio\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:realtime-conversation-start-op
        (codex:conversation-start-params
          (codex:realtime-output-modality-audio)
          JsonNull
          CodexAbsent
          CodexAbsent
          CodexAbsent))))
  ("{\"type\":\"realtime_conversation_start\",\"output_modality\":\"audio\",\"prompt\":null}"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:realtime-conversation-start-op
        (codex:conversation-start-params
          (codex:realtime-output-modality-audio)
          "be helpful"
          "conv_1"
          (codex:conversation-start-transport-webrtc "offer-sdp")
          (codex:realtime-voice-cove)))))
  ("{\"type\":\"realtime_conversation_start\",\"output_modality\":\"audio\",\"prompt\":\"be helpful\",\"session_id\":\"conv_1\",\"transport\":{\"type\":\"webrtc\",\"sdp\":\"offer-sdp\"},\"voice\":\"cove\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:realtime-conversation-start-op
        (codex:conversation-start-params
          (codex:realtime-output-modality-text)
          CodexAbsent
          CodexAbsent
          (codex:conversation-start-transport-websocket)
          CodexAbsent))))
  ("{\"type\":\"realtime_conversation_start\",\"output_modality\":\"text\",\"transport\":{\"type\":\"websocket\"}}"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:realtime-conversation-audio-op
        (codex:conversation-audio-params
          (codex:realtime-audio-frame
            "AQID"
            24000
            1
            480
            CodexAbsent)))))
  ("{\"type\":\"realtime_conversation_audio\",\"frame\":{\"data\":\"AQID\",\"sample_rate\":24000,\"num_channels\":1,\"samples_per_channel\":480}}"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:realtime-conversation-text-op
        (codex:conversation-text-params "hello"))))
  ("{\"type\":\"realtime_conversation_text\",\"text\":\"hello\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:realtime-conversation-close-op)))
  ("{\"type\":\"realtime_conversation_close\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:realtime-conversation-list-voices-op)))
  ("{\"type\":\"realtime_conversation_list_voices\"}"))
