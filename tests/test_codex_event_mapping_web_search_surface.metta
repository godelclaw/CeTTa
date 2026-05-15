!(register-module! ../codex)
!(import! &self codex:event_mapping)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:turn-web-search-item-query
    (codex:turn-item-web-search-value
      (codex:parse-turn-item
        (codex:web-search-call-response-item
          "ws_1"
          "completed"
          (codex:web-search-action-search "weather" CodexAbsent)))))
  ("weather"))

!(assertEqualToResult
  (codex:turn-web-search-item-query
    (codex:turn-item-web-search-value
      (codex:parse-turn-item
        (codex:web-search-call-response-item
          "ws_open"
          "completed"
          (codex:web-search-action-open-page "https://example.com")))))
  ("https://example.com"))

!(assertEqualToResult
  (codex:turn-web-search-item-query
    (codex:turn-item-web-search-value
      (codex:parse-turn-item
        (codex:web-search-call-response-item
          "ws_find"
          "completed"
          (codex:web-search-action-find-in-page
            "https://example.com"
            "needle")))))
  ("'needle' in https://example.com"))

!(assertEqualToResult
  (codex:turn-web-search-item-action
    (codex:turn-item-web-search-value
      (codex:parse-turn-item
        (codex:web-search-call-response-item
          "ws_partial"
          "in_progress"
          CodexAbsent))))
  ((CodexWebSearchActionOther)))
