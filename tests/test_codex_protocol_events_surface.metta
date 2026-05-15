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
