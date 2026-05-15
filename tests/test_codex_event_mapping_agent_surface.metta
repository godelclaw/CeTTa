!(register-module! ../codex)
!(import! &self codex:event_mapping)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:turn-agent-message-item-content
    (codex:turn-item-agent-message-value
      (codex:parse-turn-item
        (codex:response-message
          CodexAbsent
          "assistant"
          ((CodexInputText
             "author: /root\nrecipient: /root/worker\nother_recipients: []\nContent: continue"))
          CodexAbsent))))
  (((CodexTurnAgentMessageContentText
      "author: /root\nrecipient: /root/worker\nother_recipients: []\nContent: continue"))))

!(assertEqualToResult
  (codex:turn-agent-message-item-content
    (codex:turn-item-agent-message-value
      (codex:parse-turn-item
        (codex:response-message
          "msg-1"
          "assistant"
          ((CodexOutputText "Hello from Codex"))
          CodexAbsent))))
  (((CodexTurnAgentMessageContentText "Hello from Codex"))))
