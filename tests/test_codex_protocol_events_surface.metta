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
