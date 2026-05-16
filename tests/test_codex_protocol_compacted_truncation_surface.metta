!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (json-stringify
    (codex:compacted-item-json
      (codex:compacted-item "compacted summary" CodexAbsent)))
  ("{\"message\":\"compacted summary\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:compacted-item-json
      (codex:compacted-item
        "compacted summary"
        ((codex:assistant-message "restored assistant")
         (codex:user-message "restored user")))))
  ("{\"message\":\"compacted summary\",\"replacement_history\":[{\"type\":\"message\",\"role\":\"assistant\",\"content\":[{\"type\":\"output_text\",\"text\":\"restored assistant\"}]},{\"type\":\"message\",\"role\":\"user\",\"content\":[{\"type\":\"input_text\",\"text\":\"restored user\"}]}]}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:compacted-item-to-response-item
        (codex:compacted-item
          "assistant replacement"
          ((codex:user-message "ignored history"))))))
  ("{\"type\":\"message\",\"role\":\"assistant\",\"content\":[{\"type\":\"output_text\",\"text\":\"assistant replacement\"}]}"))

!(assertEqualToResult
  (json-stringify
    (codex:turn-context-network-item-json
      (codex:turn-context-network-item
        ("api.example.com" "cdn.example.com")
        ("blocked.example.com"))))
  ("{\"allowed_domains\":[\"api.example.com\",\"cdn.example.com\"],\"denied_domains\":[\"blocked.example.com\"]}"))

!(assertEqualToResult
  (json-stringify
    (codex:truncation-policy-json
      (codex:truncation-policy-bytes 1536)))
  ("{\"mode\":\"bytes\",\"limit\":1536}"))

!(assertEqualToResult
  (json-stringify
    (codex:truncation-policy-json
      (codex:truncation-policy-tokens 400)))
  ("{\"mode\":\"tokens\",\"limit\":400}"))

!(assertEqualToResult
  (json-stringify
    (JsonNumber
      (codex:truncation-policy-token-budget
        (codex:truncation-policy-bytes 9))))
  ("3"))

!(assertEqualToResult
  (json-stringify
    (JsonNumber
      (codex:truncation-policy-token-budget
        (codex:truncation-policy-tokens 11))))
  ("11"))

!(assertEqualToResult
  (codex:truncation-policy-byte-budget
    (codex:truncation-policy-bytes 21))
  (21))

!(assertEqualToResult
  (codex:truncation-policy-byte-budget
    (codex:truncation-policy-tokens 11))
  (44))
