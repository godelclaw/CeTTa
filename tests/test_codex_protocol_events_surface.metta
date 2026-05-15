!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:exec-command-output-delta-event
        "call21"
        "stdout"
        "hello")))
  ("{\"type\":\"exec_command_output_delta\",\"call_id\":\"call21\",\"stream\":\"stdout\",\"chunk\":\"aGVsbG8=\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:terminal-interaction-event
        "exec-call-45"
        "45"
        "exit\n")))
  ("{\"type\":\"terminal_interaction\",\"call_id\":\"exec-call-45\",\"process_id\":\"45\",\"stdin\":\"exit\\n\"}"))

!(assertEqualToResult
  (codex:item-type
    (codex:terminal-interaction-event "exec-call-45" "45" "exit\n"))
  ("terminal_interaction"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:agent-message-delta-event "delta text")))
  ("{\"type\":\"agent_message_delta\",\"delta\":\"delta text\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:agent-reasoning-event "reasoning text")))
  ("{\"type\":\"agent_reasoning\",\"text\":\"reasoning text\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:agent-reasoning-raw-content-event "raw text")))
  ("{\"type\":\"agent_reasoning_raw_content\",\"text\":\"raw text\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:agent-reasoning-raw-content-delta-event "raw delta")))
  ("{\"type\":\"agent_reasoning_raw_content_delta\",\"delta\":\"raw delta\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:agent-reasoning-section-break-event "item-7" 2)))
  ("{\"type\":\"agent_reasoning_section_break\",\"item_id\":\"item-7\",\"summary_index\":2}"))

!(assertEqualToResult
  (codex:item-type
    (codex:agent-reasoning-delta-event "step"))
  ("agent_reasoning_delta"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:mcp-tool-call-begin-event
        "mcp-call-1"
        (codex:mcp-invocation
          "memory"
          "create_entities"
          (JsonObject
            ((JsonPair "id" (JsonNumber 1)))))
        "app://memory")))
  ("{\"type\":\"mcp_tool_call_begin\",\"call_id\":\"mcp-call-1\",\"invocation\":{\"server\":\"memory\",\"tool\":\"create_entities\",\"arguments\":{\"id\":1}},\"mcp_app_resource_uri\":\"app://memory\"}"))

!(assertEqualToResult
  (codex:item-type
    (codex:mcp-tool-call-begin-event
      "mcp-call-2"
      (codex:mcp-invocation "images" "image" (JsonObject ()))
      CodexAbsent))
  ("mcp_tool_call_begin"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:mcp-startup-update-event
        "memory"
        (codex:mcp-startup-status-failed "oauth expired"))))
  ("{\"type\":\"mcp_startup_update\",\"server\":\"memory\",\"status\":{\"state\":\"failed\",\"error\":\"oauth expired\"}}"))

!(assertEqualToResult
  (codex:item-type
    (codex:mcp-startup-complete-event
      ("memory" "images")
      ((codex:mcp-startup-failure "docs" "not logged in"))
      ("calendar")))
  ("mcp_startup_complete"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:mcp-startup-complete-event
        ("memory" "images")
        ((codex:mcp-startup-failure "docs" "not logged in"))
        ("calendar"))))
  ("{\"type\":\"mcp_startup_complete\",\"ready\":[\"memory\",\"images\"],\"failed\":[{\"server\":\"docs\",\"error\":\"not logged in\"}],\"cancelled\":[\"calendar\"]}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:thread-name-updated-event
        "thread-123"
        "Buckminster notes")))
  ("{\"type\":\"thread_name_updated\",\"thread_id\":\"thread-123\",\"thread_name\":\"Buckminster notes\"}"))

!(assertEqualToResult
  (codex:item-type
    (codex:thread-name-updated-event
      "thread-456"
      CodexAbsent))
  ("thread_name_updated"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:thread-rolled-back-event 3)))
  ("{\"type\":\"thread_rolled_back\",\"num_turns\":3}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:warning-event "network unstable")))
  ("{\"type\":\"warning\",\"message\":\"network unstable\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:guardian-warning-event "approval reviewer timeout")))
  ("{\"type\":\"guardian_warning\",\"message\":\"approval reviewer timeout\"}"))

!(assertEqualToResult
  (codex:item-type
    (codex:model-reroute-event
      "gpt-5"
      "gpt-5-safe"
      (codex:model-reroute-reason-high-risk-cyber-activity)))
  ("model_reroute"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:model-reroute-event
        "gpt-5"
        "gpt-5-safe"
        (codex:model-reroute-reason-high-risk-cyber-activity))))
  ("{\"type\":\"model_reroute\",\"from_model\":\"gpt-5\",\"to_model\":\"gpt-5-safe\",\"reason\":\"high_risk_cyber_activity\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:context-compacted-event)))
  ("{\"type\":\"context_compacted\"}"))

!(assertEqualToResult
  (codex:item-type
    (codex:model-verification-event
      ((codex:model-verification-trusted-access-for-cyber))))
  ("model_verification"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:model-verification-event
        ((codex:model-verification-trusted-access-for-cyber)))))
  ("{\"type\":\"model_verification\",\"verifications\":[\"trusted_access_for_cyber\"]}"))

!(assertEqualToResult
  (codex:item-type
    (codex:turn-started-event
      "turn-8"
      1712345600
      400000
      (codex:mode-kind-default)))
  ("task_started"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:turn-started-event
        "turn-8"
        1712345600
        400000
        (codex:mode-kind-default))))
  ("{\"type\":\"task_started\",\"turn_id\":\"turn-8\",\"started_at\":1712345600,\"model_context_window\":400000,\"collaboration_mode_kind\":\"default\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:turn-started-event
        "turn-11"
        CodexAbsent
        CodexAbsent
        (codex:mode-kind-plan))))
  ("{\"type\":\"task_started\",\"turn_id\":\"turn-11\",\"model_context_window\":null,\"collaboration_mode_kind\":\"plan\"}"))

!(assertEqualToResult
  (codex:item-type
    (codex:turn-complete-event
      "turn-9"
      "final answer"
      1712345678
      240
      80))
  ("task_complete"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:turn-complete-event
        "turn-9"
        "final answer"
        1712345678
        240
        80)))
  ("{\"type\":\"task_complete\",\"turn_id\":\"turn-9\",\"last_agent_message\":\"final answer\",\"completed_at\":1712345678,\"duration_ms\":240,\"time_to_first_token_ms\":80}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:stream-info-event "retrying model stream")))
  ("{\"type\":\"stream_info\",\"message\":\"retrying model stream\"}"))

!(assertEqualToResult
  (codex:item-type
    (codex:undo-started-event CodexAbsent))
  ("undo_started"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:undo-started-event "rolling back last turn")))
  ("{\"type\":\"undo_started\",\"message\":\"rolling back last turn\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:undo-completed-event True "rollback applied")))
  ("{\"type\":\"undo_completed\",\"success\":true,\"message\":\"rollback applied\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:web-search-begin-event "search-17")))
  ("{\"type\":\"web_search_begin\",\"call_id\":\"search-17\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:web-search-end-event
        "search-17"
        "buckminster fuller"
        (codex:web-search-action-find-in-page
          "https://example.com"
          "geodesic"))))
  ("{\"type\":\"web_search_end\",\"call_id\":\"search-17\",\"query\":\"buckminster fuller\",\"action\":{\"type\":\"find_in_page\",\"url\":\"https://example.com\",\"pattern\":\"geodesic\"}}"))

!(assertEqualToResult
  (codex:item-type
    (codex:image-generation-begin-event "img-22"))
  ("image_generation_begin"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:image-generation-end-event
        "img-22"
        "completed"
        "blueprint night skyline"
        "ok"
        "/tmp/out.png")))
  ("{\"type\":\"image_generation_end\",\"call_id\":\"img-22\",\"status\":\"completed\",\"revised_prompt\":\"blueprint night skyline\",\"result\":\"ok\",\"saved_path\":\"/tmp/out.png\"}"))
