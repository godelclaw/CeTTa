!(register-module! ../codex)
!(import! &self codex:message_history)

!(assertEqualToResult
  (codex:message-history-filename)
  ("history.jsonl"))

!(assertEqualToResult
  (codex:message-history-soft-cap-ratio-numerator)
  (8))

!(assertEqualToResult
  (codex:message-history-soft-cap-ratio-denominator)
  (10))

!(assertEqualToResult
  (codex:message-history-max-retries)
  (10))

!(assertEqualToResult
  (codex:message-history-retry-sleep-ms)
  (100))

!(assertEqualToResult
  (codex:message-history-trim-target-bytes 100 10)
  (80))

!(assertEqualToResult
  (codex:message-history-trim-target-bytes 3 1)
  (2))

!(assertEqualToResult
  (codex:message-history-trim-target-bytes 1 1)
  (1))

!(assertEqualToResult
  (codex:message-history-trim-target-bytes 100 120)
  (120))

!(assertEqualToResult
  (codex:message-history-limit-plan-action
    (codex:message-history-limit-plan (30 30 30) CodexAbsent))
  ("unchanged"))

!(assertEqualToResult
  (codex:message-history-limit-plan-action
    (codex:message-history-limit-plan (30 30 30) 0))
  ("unchanged"))

!(assertEqualToResult
  (codex:message-history-limit-plan-action
    (codex:message-history-limit-plan (30 30) 60))
  ("unchanged"))

!(assertEqualToResult
  (codex:message-history-limit-plan-retained-line-lengths
    (codex:message-history-limit-plan (30 30 30) 70))
  ((30)))

!(assertEqualToResult
  (codex:message-history-limit-plan-drop-count
    (codex:message-history-limit-plan (30 30 30) 70))
  (2))

!(assertEqualToResult
  (codex:message-history-limit-plan-drop-bytes
    (codex:message-history-limit-plan (30 30 30) 70))
  (60))

!(assertEqualToResult
  (codex:message-history-limit-plan-retained-bytes
    (codex:message-history-limit-plan (30 30 30) 70))
  (30))

!(assertEqualToResult
  (codex:message-history-limit-plan-retained-line-lengths
    (codex:message-history-limit-plan (30 30 5) 60))
  ((30 5)))

!(assertEqualToResult
  (codex:message-history-limit-plan-drop-count
    (codex:message-history-limit-plan (30 90) 50))
  (1))

!(assertEqualToResult
  (codex:message-history-limit-plan-retained-bytes
    (codex:message-history-limit-plan (30 90) 50))
  (90))

!(assertEqualToResult
  (codex:message-history-limit-plan-action
    (codex:message-history-limit-plan (100) 50))
  ("unchanged"))

!(assertEqualToResult
  (codex:message-history-limit-plan-retained-bytes
    (codex:message-history-limit-plan-from-current-len
      120
      ()
      50))
  (120))
