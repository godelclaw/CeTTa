!(register-module! ../codex)
!(import! &self codex:protocol)
!(import! &self codex:web_search)

!(assertEqual
  (codex:web-search-action-detail
    (codex:web-search-action-search "weather" ("fallback")))
  "weather")

!(assertEqual
  (codex:web-search-action-detail
    (codex:web-search-action-search "" ("first" "second")))
  "first ...")

!(assertEqual
  (codex:web-search-action-detail
    (codex:web-search-action-search CodexAbsent ("first")))
  "first")

!(assertEqual
  (codex:web-search-action-detail
    (codex:web-search-action-search CodexAbsent ("" "second")))
  "")

!(assertEqual
  (codex:web-search-action-detail
    (codex:web-search-action-search CodexAbsent CodexAbsent))
  "")

!(assertEqual
  (codex:web-search-action-detail
    (codex:web-search-action-open-page "https://example.com"))
  "https://example.com")

!(assertEqual
  (codex:web-search-action-detail
    (codex:web-search-action-open-page CodexAbsent))
  "")

!(assertEqual
  (codex:web-search-action-detail
    (codex:web-search-action-find-in-page "https://example.com" "needle"))
  "'needle' in https://example.com")

!(assertEqual
  (codex:web-search-action-detail
    (codex:web-search-action-find-in-page CodexAbsent "needle"))
  "'needle'")

!(assertEqual
  (codex:web-search-action-detail
    (codex:web-search-action-find-in-page "https://example.com" CodexAbsent))
  "https://example.com")

!(assertEqual
  (codex:web-search-detail CodexAbsent "fallback query")
  "fallback query")

!(assertEqual
  (codex:web-search-detail
    (codex:web-search-action-other)
    "fallback query")
  "fallback query")
