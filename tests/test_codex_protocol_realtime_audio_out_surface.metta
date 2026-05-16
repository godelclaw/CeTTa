!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (json-stringify
    (codex:realtime-event-json
      (codex:realtime-event-audio-out
        (codex:realtime-audio-frame
          "AAA="
          48000
          1
          960
          CodexAbsent))))
  ("{\"AudioOut\":{\"data\":\"AAA=\",\"sample_rate\":48000,\"num_channels\":1,\"samples_per_channel\":960}}"))

!(assertEqualToResult
  (json-stringify
    (codex:realtime-event-json
      (codex:realtime-event-audio-out
        (codex:realtime-audio-frame
          "AQID"
          24000
          2
          CodexAbsent
          "item_123"))))
  ("{\"AudioOut\":{\"data\":\"AQID\",\"sample_rate\":24000,\"num_channels\":2,\"item_id\":\"item_123\"}}"))
