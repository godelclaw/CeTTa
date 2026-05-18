!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:turn-item-id
    (codex:turn-item-web-search
      "search-1"
      "metta reducers"
      (codex:web-search-action-find-in-page
        "https://example.com"
        "reducers")))
  ("search-1"))

!(assertEqualToResult
  (codex:item-type
    (codex:item-started-event
      "thread-1"
      "turn-1"
      (codex:turn-item-web-search
        "search-1"
        "metta reducers"
        (codex:web-search-action-find-in-page
          "https://example.com"
          "reducers"))))
  ("item_started"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:item-started-event
        "thread-1"
        "turn-1"
        (codex:turn-item-web-search
          "search-1"
          "metta reducers"
          (codex:web-search-action-find-in-page
            "https://example.com"
            "reducers")))))
  ("{\"type\":\"item_started\",\"thread_id\":\"thread-1\",\"turn_id\":\"turn-1\",\"item\":{\"type\":\"WebSearch\",\"id\":\"search-1\",\"query\":\"metta reducers\",\"action\":{\"type\":\"find_in_page\",\"url\":\"https://example.com\",\"pattern\":\"reducers\"}}}"))

!(assertEqualToResult
  (json-stringify
    (codex:items-json
      (codex:event-as-legacy-events
        (codex:item-started-event
          "thread-1"
          "turn-1"
          (codex:turn-item-web-search
            "search-1"
            "metta reducers"
            (codex:web-search-action-find-in-page
              "https://example.com"
              "reducers")))
        False)))
  ("[{\"type\":\"web_search_begin\",\"call_id\":\"search-1\"}]"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:item-completed-event
        "thread-1"
        "turn-1"
        (codex:turn-item-web-search
          "search-1"
          "metta reducers"
          (codex:web-search-action-find-in-page
            "https://example.com"
            "reducers")))))
  ("{\"type\":\"item_completed\",\"thread_id\":\"thread-1\",\"turn_id\":\"turn-1\",\"item\":{\"type\":\"WebSearch\",\"id\":\"search-1\",\"query\":\"metta reducers\",\"action\":{\"type\":\"find_in_page\",\"url\":\"https://example.com\",\"pattern\":\"reducers\"}}}"))

!(assertEqualToResult
  (json-stringify
    (codex:items-json
      (codex:event-as-legacy-events
        (codex:item-completed-event
          "thread-1"
          "turn-1"
          (codex:turn-item-web-search
            "search-1"
            "metta reducers"
            (codex:web-search-action-find-in-page
              "https://example.com"
              "reducers")))
        False)))
  ("[{\"type\":\"web_search_end\",\"call_id\":\"search-1\",\"query\":\"metta reducers\",\"action\":{\"type\":\"find_in_page\",\"url\":\"https://example.com\",\"pattern\":\"reducers\"}}]"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:item-started-event
        "thread-2"
        "turn-2"
        (codex:turn-item-image-generation
          "img-1"
          "completed"
          CodexAbsent
          "ok"
          CodexAbsent))))
  ("{\"type\":\"item_started\",\"thread_id\":\"thread-2\",\"turn_id\":\"turn-2\",\"item\":{\"type\":\"ImageGeneration\",\"id\":\"img-1\",\"status\":\"completed\",\"result\":\"ok\"}}"))

!(assertEqualToResult
  (json-stringify
    (codex:items-json
      (codex:event-as-legacy-events
        (codex:item-started-event
          "thread-2"
          "turn-2"
          (codex:turn-item-image-generation
            "img-1"
            "completed"
            CodexAbsent
            "ok"
            CodexAbsent))
        False)))
  ("[{\"type\":\"image_generation_begin\",\"call_id\":\"img-1\"}]"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:item-completed-event
        "thread-2"
        "turn-2"
        (codex:turn-item-image-generation
          "img-1"
          "completed"
          "dense terminal UI"
          "ok"
          "/tmp/img.png"))))
  ("{\"type\":\"item_completed\",\"thread_id\":\"thread-2\",\"turn_id\":\"turn-2\",\"item\":{\"type\":\"ImageGeneration\",\"id\":\"img-1\",\"status\":\"completed\",\"revised_prompt\":\"dense terminal UI\",\"result\":\"ok\",\"saved_path\":\"/tmp/img.png\"}}"))

!(assertEqualToResult
  (json-stringify
    (codex:items-json
      (codex:event-as-legacy-events
        (codex:item-completed-event
          "thread-2"
          "turn-2"
          (codex:turn-item-image-generation
            "img-1"
            "completed"
            "dense terminal UI"
            "ok"
            "/tmp/img.png"))
        False)))
  ("[{\"type\":\"image_generation_end\",\"call_id\":\"img-1\",\"status\":\"completed\",\"revised_prompt\":\"dense terminal UI\",\"result\":\"ok\",\"saved_path\":\"/tmp/img.png\"}]"))
