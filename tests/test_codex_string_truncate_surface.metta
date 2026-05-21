!(register-module! ../codex)
!(import! &self codex:string_truncate)

(= (codex-string-truncate-utf8-sample)
   "😀😀😀😀😀😀😀😀😀😀\nsecond line with text\n")

!(assertEqualToResult
  (codex:string-truncate-approx-bytes-per-token)
  (4))

!(assertEqualToResult
  (codex:string-truncate-approx-token-count "abcdef")
  (2))

!(assertEqualToResult
  (codex:string-truncate-approx-bytes-for-tokens 8)
  (32))

!(assertEqualToResult
  (codex:string-truncate-approx-tokens-from-byte-count 31)
  (8))

!(assertEqualToResult
  (codex:string-truncate-split-budget 5)
  ((CodexStringTruncateSplitBudget 2 3)))

!(assertEqualToResult
  (codex:string-truncate-split-string "hello world" 5 5)
  ((StrMiddleSplit 1 "hello" "world")))

!(assertEqualToResult
  (codex:string-truncate-split-string "" 4 4)
  ((StrMiddleSplit 0 "" "")))

!(assertEqualToResult
  (codex:string-truncate-split-string "abc" 0 0)
  ((StrMiddleSplit 3 "" "")))

!(assertEqualToResult
  (codex:string-truncate-split-string "abcdef" 3 0)
  ((StrMiddleSplit 3 "abc" "")))

!(assertEqualToResult
  (codex:string-truncate-split-string "abcdef" 0 3)
  ((StrMiddleSplit 3 "" "def")))

!(assertEqualToResult
  (codex:string-truncate-split-string "abcdef" 4 4)
  ((StrMiddleSplit 0 "abcd" "ef")))

!(assertEqualToResult
  (codex:string-truncate-split-string "😀abc😀" 5 5)
  ((StrMiddleSplit 1 "😀a" "c😀")))

!(assertEqualToResult
  (codex:string-truncate-split-string "😀😀😀😀😀" 1 1)
  ((StrMiddleSplit 5 "" "")))

!(assertEqualToResult
  (codex:string-truncate-split-string "😀😀😀😀😀" 7 7)
  ((StrMiddleSplit 3 "😀" "😀")))

!(assertEqualToResult
  (codex:string-truncate-split-string "😀😀😀😀😀" 8 8)
  ((StrMiddleSplit 1 "😀😀" "😀😀")))

!(assertEqualToResult
  (codex:string-truncate-middle-with-token-budget "short output" 100)
  ((CodexStringTruncateResult "short output" CodexAbsent)))

!(assertEqualToResult
  (codex:string-truncate-middle-with-token-budget "abcdef" 0)
  ((CodexStringTruncateResult "…2 tokens truncated…" 2)))

!(assertEqualToResult
  (codex:string-truncate-middle-with-token-budget
    (codex-string-truncate-utf8-sample)
    8)
  ((CodexStringTruncateResult
     "😀😀😀😀…8 tokens truncated… line with text\n"
     16)))

!(assertEqualToResult
  (codex:string-truncate-middle-with-token-budget-text
    (codex-string-truncate-utf8-sample)
    8)
  ("😀😀😀😀…8 tokens truncated… line with text\n"))

!(assertEqualToResult
  (codex:string-truncate-middle-chars
    (codex-string-truncate-utf8-sample)
    20)
  ("😀😀…21 chars truncated…with text\n"))

!(assertEqualToResult
  (codex:string-truncate-middle-chars "abcdef" 0)
  ("…6 chars truncated…"))

!(assertEqualToResult
  (codex:string-truncate-result-text
    (codex:string-truncate-result "text" 3))
  ("text"))

!(assertEqualToResult
  (codex:string-truncate-result-original-token-count
    (codex:string-truncate-result "text" 3))
  (3))
