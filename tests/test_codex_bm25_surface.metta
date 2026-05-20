!(register-module! ../codex)
!(import! &self codex:bm25)

!(assertEqualToResult
  (codex:bm25-tokenize "Bacon Sandwich")
  (("bacon" "sandwich")))

!(assertEqualToResult
  (codex:bm25-average-document-length
    ((CodexBm25DocumentTokens
       (CodexBm25Document 0 "a b")
       ("a" "b"))
     (CodexBm25DocumentTokens
       (CodexBm25Document 1 "a b c d")
       ("a" "b" "c" "d"))))
  (3))

!(assertEqualToResult
  (> (codex:bm25-idf 2 1)
     (codex:bm25-idf 2 2))
  (True))

!(assertEqualToResult
  (> (codex:bm25-document-token-value
       ("bacon" "sandwich")
       "bacon"
       3.0)
     (codex:bm25-document-token-value
       ("bacon" "sandwich" "menu" "item")
       "bacon"
       3.0))
  (True))

!(assertEqual
  (codex:bm25-search-document-ids
    ((CodexBm25Document 0 "bacon sandwich menu item")
     (CodexBm25Document 1 "bacon sandwich")
     (CodexBm25Document 2 "avocado toast"))
    "bacon sandwich"
    CodexAbsent)
  (1 0))

!(assertEqual
  (codex:bm25-search-document-ids
    ((CodexBm25Document 0 "bacon sandwich menu item")
     (CodexBm25Document 1 "bacon sandwich")
     (CodexBm25Document 2 "avocado toast"))
    "bacon sandwich"
    1)
  (1))

!(assertEqual
  (codex:bm25-search-document-ids
    ((CodexBm25Document 0 "computer use")
     (CodexBm25Document 1 "computer use"))
    "computer"
    CodexAbsent)
  (0 1))

!(assertEqual
  (codex:bm25-search-document-ids
    ((CodexBm25Document 0 "bacon sandwich")
     (CodexBm25Document 1 "avocado toast"))
    "unrelated"
    CodexAbsent)
  ())
