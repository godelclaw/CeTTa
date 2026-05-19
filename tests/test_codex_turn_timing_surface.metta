!(register-module! ../codex)
!(import! &self codex:turn_timing)

!(assertEqual
  (codex:response-item-records-turn-ttft
    (codex:function-call-response-item "shell" "{}" "call-1"))
  True)

!(assertEqual
  (codex:response-item-records-turn-ttft
    (codex:tool-call "call-2" "custom" "echo hi"))
  True)

!(assertEqual
  (codex:response-item-records-turn-ttft
    (codex:assistant-message "hello"))
  True)

!(assertEqual
  (codex:response-item-records-turn-ttft
    (codex:assistant-message ""))
  False)

!(assertEqual
  (codex:response-item-records-turn-ttft
    (codex:user-message "hello"))
  False)

!(assertEqual
  (codex:response-item-records-turn-ttft
    (codex:function-tool-result
      "call-1"
      (codex:function-call-output-text "ok")))
  False)

!(assertEqual
  (codex:response-item-records-turn-ttft
    (codex:reasoning-response-item
      "reasoning-1"
      ((codex:reasoning-summary-text "Summarized step"))
      CodexAbsent))
  True)

!(assertEqual
  (codex:response-item-records-turn-ttft
    (codex:reasoning-response-item
      "reasoning-2"
      ()
      ((codex:reasoning-content-reasoning-text "")
       (codex:reasoning-content-text "final thought"))))
  True)

!(assertEqual
  (codex:response-item-records-turn-ttft
    (codex:reasoning-response-item "reasoning-empty" () CodexAbsent))
  False)

!(assertEqual
  (codex:response-item-records-turn-ttft
    (codex:local-shell-call-response-item
      CodexAbsent
      "call-shell"
      "completed"
      "echo hi"))
  True)

!(assertEqual
  (codex:response-item-records-turn-ttft
    (CodexResponseItemToolSearchCall
      CodexAbsent
      "call-search"
      "completed"
      "client"
      (JsonObject ())))
  True)

!(assertEqual
  (codex:response-item-records-turn-ttft
    (codex:web-search-call-response-item
      "ws-1"
      "completed"
      (codex:web-search-action-search "weather" ())))
  True)

!(assertEqual
  (codex:response-item-records-turn-ttft
    (codex:image-generation-call-response-item
      "ig-1"
      "completed"
      CodexAbsent
      "Zm9v"))
  True)

!(assertEqual
  (codex:response-item-records-turn-ttft
    (codex:ghost-snapshot-response-item "ghost-commit"))
  True)

!(assertEqual
  (codex:response-item-records-turn-ttft
    (codex:compaction-response-item "encrypted"))
  True)

!(assertEqual
  (codex:response-item-records-turn-ttft
    (codex:tool-search-output "call-search" "completed" "client" ()))
  False)

!(assertEqual
  (codex:response-item-records-turn-ttft
    (codex:response-item-other))
  False)

!(assertEqual
  (codex:response-event-records-turn-ttft
    (codex:response-event-output-text-delta "hi"))
  True)

!(assertEqual
  (codex:response-event-records-turn-ttft
    (codex:response-event-reasoning-summary-delta "step" 0))
  True)

!(assertEqual
  (codex:response-event-records-turn-ttft
    (codex:response-event-reasoning-content-delta "detail" 0))
  True)

!(assertEqual
  (codex:response-event-records-turn-ttft
    (codex:response-event-output-item-added
      (codex:function-tool-result
        "call-1"
        (codex:function-call-output-text "ok"))))
  False)

!(assertEqual
  (codex:response-event-records-turn-ttft
    (codex:response-event-output-item-done
      (codex:tool-call "call-2" "custom" "echo hi")))
  True)

!(assertEqual
  (codex:response-event-records-turn-ttft
    (codex:response-event-created))
  False)

!(assertEqual
  (codex:response-event-records-turn-ttft
    (codex:response-event-tool-call-input-delta
      "item-1"
      CodexAbsent
      "{}"))
  False)

!(assertEqual
  (codex:response-event-records-turn-ttft
    (codex:response-event-completed "resp-1" CodexAbsent))
  False)
