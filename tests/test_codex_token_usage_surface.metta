!(register-module! ../codex)
!(import! &self codex:token_usage)

!(assertEqualToResult
  (codex:baseline-tokens)
  (12000))

!(assertEqualToResult
  (codex:is-zero-token-usage? (codex:default-token-usage))
  (True))

!(assertEqualToResult
  (codex:token-usage-cached-input
    (codex:token-usage 10 -5 0 0 0))
  (0))

!(assertEqualToResult
  (codex:token-usage-cached-input
    (codex:token-usage 10 3 0 0 0))
  (3))

!(assertEqualToResult
  (codex:token-usage-non-cached-input
    (codex:token-usage 10 3 0 0 0))
  (7))

!(assertEqualToResult
  (codex:token-usage-non-cached-input
    (codex:token-usage 2 5 0 0 0))
  (0))

!(assertEqualToResult
  (codex:token-usage-blended-total
    (codex:token-usage 10 3 8 0 0))
  (15))

!(assertEqualToResult
  (codex:token-usage-tokens-in-context-window
    (codex:token-usage 0 0 0 0 123))
  (123))

!(assertEqualToResult
  (codex:token-usage-percent-of-context-window-remaining
    (codex:token-usage 0 0 0 0 12000)
    20000)
  (100))

!(assertEqualToResult
  (codex:token-usage-percent-of-context-window-remaining
    (codex:token-usage 0 0 0 0 16000)
    20000)
  (50))

!(assertEqualToResult
  (codex:token-usage-percent-of-context-window-remaining
    (codex:token-usage 0 0 0 0 99999)
    10000)
  (0))

!(assertEqualToResult
  (codex:token-usage-add
    (codex:token-usage 1 2 3 4 5)
    (codex:token-usage 10 20 30 40 50))
  ((CodexTokenUsage 11 22 33 44 55)))

!(assertEqualToResult
  (codex:render-final-output
    (codex:final-output-from-token-usage
      (codex:token-usage 1200 200 345 40 0)))
  ("Token usage: total=1,345 input=1,000 (+ 200 cached) output=345 (reasoning 40)"))

!(assertEqualToResult
  (codex:render-final-output
    (codex:final-output-from-token-usage
      (codex:token-usage 1200 0 345 0 0)))
  ("Token usage: total=1,545 input=1,200 output=345"))
