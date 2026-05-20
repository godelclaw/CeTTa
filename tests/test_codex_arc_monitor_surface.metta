!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:arc_monitor)
!(import! &self codex:protocol)
!(import! &self codex:turn_timing)

!(assertEqual
  (codex:arc-monitor-content-items-to-text
    ((CodexInputText "first")
     (CodexInputImage "data:image/png;base64,AAA" CodexAbsent)
     (CodexOutputText "")
     (CodexOutputText "second")))
  "first\nsecond")

!(assertEqual
  (codex:arc-monitor-content-items-to-text
    ((CodexInputImage "data:image/png;base64,AAA" CodexAbsent)))
  Empty)

!(assertEqualToResult
  (codex:arc-monitor-build-messages
    ((codex:user-message "first request")
     (CodexResponseItemMessage
       "user"
       ((CodexInputText "<environment_context>\nnoise\n</environment_context>"))
       CodexAbsent)
     (codex:commentary-message "commentary")
     (codex:final-response "final response")
     (codex:user-message "latest request")
     (codex:function-call-response-item
       "old_tool"
       "{\"old\":true}"
       "call_old")
     (CodexResponseItemReasoning
       "reasoning-old"
       ()
       CodexAbsent
       "encrypted-old")
     (codex:local-shell-call-response-item
       CodexAbsent
       "shell_call"
       "completed"
       (codex:arc-monitor-local-shell-exec-action
         ("pwd")
         1000
         "/tmp"
         CodexAbsent
         CodexAbsent))
     (CodexResponseItemReasoning
       "reasoning-latest"
       ()
       CodexAbsent
       "encrypted-latest")))
  (((CodexArcMonitorChatMessage
      "user"
      (JsonArray
        ((JsonObject
           ((JsonPair "type" (JsonString "input_text"))
            (JsonPair "text" (JsonString "first request")))))))
    (CodexArcMonitorChatMessage
      "assistant"
      (JsonArray
        ((JsonObject
           ((JsonPair "type" (JsonString "output_text"))
            (JsonPair "text" (JsonString "final response")))))))
    (CodexArcMonitorChatMessage
      "user"
      (JsonArray
        ((JsonObject
           ((JsonPair "type" (JsonString "input_text"))
            (JsonPair "text" (JsonString "latest request")))))))
    (CodexArcMonitorChatMessage
      "assistant"
      (JsonArray
        ((JsonObject
           ((JsonPair "type" (JsonString "tool_call"))
            (JsonPair "tool_name" (JsonString "shell"))
            (JsonPair "action"
              (JsonObject
                ((JsonPair "type" (JsonString "exec"))
                 (JsonPair "command"
                   (JsonArray ((JsonString "pwd"))))
                 (JsonPair "timeout_ms" (JsonNumber 1000))
                 (JsonPair "working_directory" (JsonString "/tmp"))
                 (JsonPair "env" JsonNull)
                 (JsonPair "user" JsonNull)))))))))
    (CodexArcMonitorChatMessage
      "assistant"
      (JsonArray
        ((JsonObject
           ((JsonPair "type" (JsonString "encrypted_reasoning"))
            (JsonPair
              "encrypted_content"
              (JsonString "encrypted-latest"))))))))))

!(assertEqual
  (json-stringify
    (codex:arc-monitor-request-json
      (codex:arc-monitor-build-request
        "thread-1"
        "turn-1"
        ()
        (JsonObject ((JsonPair "tool" (JsonString "mcp_tool_call"))))
        "normal")))
  "{\"metadata\":{\"codex_thread_id\":\"thread-1\",\"codex_turn_id\":\"turn-1\",\"conversation_id\":\"thread-1\",\"protection_client_callsite\":\"normal\"},\"messages\":[{\"role\":\"user\",\"content\":[{\"type\":\"input_text\",\"text\":\"No prior conversation history is available for this ARC evaluation.\"}]}],\"policies\":{\"user\":null,\"developer\":null},\"action\":{\"tool\":\"mcp_tool_call\"}}")

!(assertEqual
  (codex:arc-monitor-endpoint-url
    "https://chatgpt.example////"
    CodexAbsent)
  "https://chatgpt.example/codex/safety/arc")

!(assertEqual
  (codex:arc-monitor-endpoint-url
    "https://chatgpt.example"
    "  https://override.example/arc  ")
  "https://override.example/arc")

!(assertEqualToResult
  (codex:arc-monitor-request-plan
    " override-token "
    True
    "https://chatgpt.example/"
    CodexAbsent
    (JsonObject ((JsonPair "tool" (JsonString "mcp_tool_call"))))
    "thread-1"
    "turn-1"
    ((codex:user-message "please run the tool"))
    "normal")
  ((CodexArcMonitorRequestPlanHttp
     "https://chatgpt.example/codex/safety/arc"
     (CodexArcMonitorAuthEnvToken "override-token")
     (CodexArcMonitorRequest
       (CodexArcMonitorMetadata
         "thread-1"
         "turn-1"
         "thread-1"
         "normal")
       ((CodexArcMonitorChatMessage
          "user"
          (JsonArray
            ((JsonObject
               ((JsonPair "type" (JsonString "input_text"))
                (JsonPair "text"
                  (JsonString "please run the tool"))))))))
       CodexAbsent
       (CodexArcMonitorPolicies CodexAbsent CodexAbsent)
       (JsonObject
         ((JsonPair "tool" (JsonString "mcp_tool_call"))))))))

!(assertEqual
  (codex:arc-monitor-request-plan
    CodexAbsent
    False
    "https://chatgpt.example"
    CodexAbsent
    (JsonObject ((JsonPair "tool" (JsonString "mcp_tool_call"))))
    "thread-1"
    "turn-1"
    ()
    "normal")
  (codex:arc-monitor-request-plan-skip-ok))

!(assertEqual
  (codex:arc-monitor-request-plan
    "token"
    True
    "https://chatgpt.example"
    CodexAbsent
    (JsonArray ())
    "thread-1"
    "turn-1"
    ()
    "normal")
  (codex:arc-monitor-request-plan-skip-ok))

!(assertEqual
  (codex:arc-monitor-outcome-from-result
    (codex:arc-monitor-result
      (codex:arc-monitor-result-outcome-ask-user)
      " needs confirmation "
      "tool call needs additional review"
      42
      (codex:arc-monitor-risk-level-medium)
      ((codex:arc-monitor-evidence
         "browser_navigate"
         "tool call needs additional review"))))
  (codex:arc-monitor-outcome-ask-user "needs confirmation"))

!(assertEqual
  (codex:arc-monitor-outcome-from-result
    (codex:arc-monitor-result
      (codex:arc-monitor-result-outcome-steer-model)
      "needs approval"
      " high-risk action "
      96
      (codex:arc-monitor-risk-level-critical)
      ()))
  (codex:arc-monitor-outcome-steer-model "high-risk action"))

!(assertEqual
  (codex:arc-monitor-outcome-from-result
    (codex:arc-monitor-result
      (codex:arc-monitor-result-outcome-ask-user)
      " "
      ""
      1
      (codex:arc-monitor-risk-level-low)
      ()))
  (codex:arc-monitor-outcome-ask-user
    (codex:arc-monitor-ask-user-fallback)))

!(assertEqual
  (codex:arc-monitor-outcome-from-result
    (codex:arc-monitor-result
      (codex:arc-monitor-result-outcome-steer-model)
      " "
      ""
      1
      (codex:arc-monitor-risk-level-low)
      ()))
  (codex:arc-monitor-outcome-steer-model
    (codex:arc-monitor-steer-model-fallback)))

!(assertEqual
  (codex:arc-monitor-outcome-from-json
    (JsonObject
      ((JsonPair "outcome" (JsonString "steer-model"))
       (JsonPair "short_reason" (JsonString "needs approval"))
       (JsonPair "rationale" (JsonString "high-risk action"))
       (JsonPair "risk_score" (JsonNumber 96))
       (JsonPair "risk_level" (JsonString "critical"))
       (JsonPair "evidence"
         (JsonArray
           ((JsonObject
              ((JsonPair "message" (JsonString "browser_navigate"))
               (JsonPair "why" (JsonString "high-risk action"))))))))))
  (codex:arc-monitor-outcome-steer-model "high-risk action"))

!(assertEqual
  (codex:arc-monitor-result-from-json
    (JsonObject
      ((JsonPair "outcome" (JsonString "steer-model"))
       (JsonPair "reason" (JsonString "legacy high-risk action"))
       (JsonPair "monitorRequestId" (JsonString "arc_456")))))
  CodexAbsent)

!(assertEqual
  (codex:arc-monitor-outcome-from-json
    (JsonObject
      ((JsonPair "outcome" (JsonString "steer-model"))
       (JsonPair "reason" (JsonString "legacy high-risk action"))
       (JsonPair "monitorRequestId" (JsonString "arc_456")))))
  (codex:arc-monitor-outcome-ok))

!(assertEqual
  (codex:arc-monitor-result-from-json
    (JsonObject
      ((JsonPair "outcome" (JsonString "ok"))
       (JsonPair "short_reason" (JsonString ""))
       (JsonPair "rationale" (JsonString ""))
       (JsonPair "risk_score" (JsonNumber 256))
       (JsonPair "risk_level" (JsonString "low"))
       (JsonPair "evidence" (JsonArray ())))))
  CodexAbsent)
