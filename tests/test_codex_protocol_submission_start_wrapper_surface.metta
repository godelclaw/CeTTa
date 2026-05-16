!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

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
