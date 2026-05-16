!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:op-type
    (codex:inter-agent-communication-op
      (codex:inter-agent-communication
        (codex:agent-path "/root/alpha")
        (codex:agent-path "/root/beta")
        ()
        "Sync complete."
        False)))
  ("inter_agent_communication"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:inter-agent-communication-op
        (codex:inter-agent-communication
          (codex:agent-path "/root/alpha")
          (codex:agent-path "/root/beta")
          ()
          "Sync complete."
          False))))
  ("{\"type\":\"inter_agent_communication\",\"communication\":{\"author\":\"/root/alpha\",\"recipient\":\"/root/beta\",\"other_recipients\":[],\"content\":\"Sync complete.\",\"trigger_turn\":false}}"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:inter-agent-communication-op
        (codex:inter-agent-communication
          (codex:agent-path "/root/reviewer")
          (codex:agent-path "/root/author")
          ((codex:agent-path "/morpheus")
           (codex:agent-path "/root/observer"))
          "Please verify the final patch."
          True))))
  ("{\"type\":\"inter_agent_communication\",\"communication\":{\"author\":\"/root/reviewer\",\"recipient\":\"/root/author\",\"other_recipients\":[\"/morpheus\",\"/root/observer\"],\"content\":\"Please verify the final patch.\",\"trigger_turn\":true}}"))
