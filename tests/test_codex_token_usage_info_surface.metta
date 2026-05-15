!(register-module! ../codex)
!(import! &self codex:token_usage_info)

!(assertEqualToResult
  (codex:default-token-usage-info)
  ((CodexTokenUsageInfo
     (CodexTokenUsage 0 0 0 0 0)
     (CodexTokenUsage 0 0 0 0 0)
     CodexAbsent)))

!(assertEqualToResult
  (codex:token-usage-info-new-or-append CodexAbsent CodexAbsent CodexAbsent)
  (CodexAbsent))

!(assertEqualToResult
  (codex:token-usage-info-new-or-append
    CodexAbsent
    (codex:token-usage 1 2 3 4 5)
    CodexAbsent)
  ((CodexTokenUsageInfo
     (CodexTokenUsage 1 2 3 4 5)
     (CodexTokenUsage 1 2 3 4 5)
     CodexAbsent)))

!(assertEqualToResult
  (codex:token-usage-info-append-last-usage
    (codex:token-usage-info
      (codex:token-usage 10 20 30 40 50)
      (codex:token-usage 1 2 3 4 5)
      CodexAbsent)
    (codex:token-usage 7 8 9 10 11))
  ((CodexTokenUsageInfo
     (CodexTokenUsage 17 28 39 50 61)
     (CodexTokenUsage 7 8 9 10 11)
     CodexAbsent)))

!(assertEqualToResult
  (codex:token-usage-info-new-or-append
    (codex:token-usage-info
      (codex:token-usage 10 20 30 40 50)
      (codex:token-usage 1 2 3 4 5)
      CodexAbsent)
    CodexAbsent
    8192)
  ((CodexTokenUsageInfo
     (CodexTokenUsage 10 20 30 40 50)
     (CodexTokenUsage 1 2 3 4 5)
     8192)))

!(assertEqualToResult
  (codex:token-usage-info-fill-to-context-window
    (codex:token-usage-info
      (codex:token-usage 0 0 0 0 5000)
      (codex:token-usage 0 0 0 0 123)
      CodexAbsent)
    7000)
  ((CodexTokenUsageInfo
     (CodexTokenUsage 0 0 0 0 7000)
     (CodexTokenUsage 0 0 0 0 2000)
     7000)))

!(assertEqualToResult
  (codex:token-usage-info-fill-to-context-window
    (codex:token-usage-info
      (codex:token-usage 0 0 0 0 9000)
      (codex:token-usage 0 0 0 0 123)
      CodexAbsent)
    7000)
  ((CodexTokenUsageInfo
     (CodexTokenUsage 0 0 0 0 7000)
     (CodexTokenUsage 0 0 0 0 0)
     7000)))

!(assertEqualToResult
  (codex:full-token-usage-context-window 32000)
  ((CodexTokenUsageInfo
     (CodexTokenUsage 0 0 0 0 32000)
     (CodexTokenUsage 0 0 0 0 32000)
     32000)))

!(assertEqualToResult
  (codex:token-count-event-info
    (codex:token-count-event
      (codex:token-usage-info
        (codex:token-usage 1 2 3 4 5)
        (codex:token-usage 1 2 3 4 5)
        4096)
      CodexAbsent))
  ((CodexTokenUsageInfo
     (CodexTokenUsage 1 2 3 4 5)
     (CodexTokenUsage 1 2 3 4 5)
     4096)))
