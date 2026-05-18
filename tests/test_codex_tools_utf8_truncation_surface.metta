!(register-module! ../codex)
!(import! &self codex:tools)

(= (codex-tools-utf8-truncation-sample)
   "😀😀😀😀😀😀😀😀😀😀\nsecond line with text\n")

!(assertEqual
  (codex:truncate-middle-with-token-budget
    (codex-tools-utf8-truncation-sample)
    8)
  "😀😀😀😀…8 tokens truncated… line with text\n")

!(assertEqual
  (codex:format-truncated-output
    (codex-tools-utf8-truncation-sample)
    8)
  "Total output lines: 2\n\n😀😀😀😀…8 tokens truncated… line with text\n")
