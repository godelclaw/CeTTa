!(register-module! ../codex)
!(import! &self list)
!(import! &self str)
!(import! &self codex:output_truncation)

(= (test-output-truncation-is-string-contains $text $needle)
   (case (str-find $text $needle)
     ((Empty False)
      ($index True))))

(= (test-output-truncation-long-content)
   "this is an example of a long output that should be truncated")

(= (test-output-truncation-long-content-lines)
   "this is an example of a long output that should be truncated\nalso some other line")

(= (test-output-truncation-utf8-sample)
   "😀😀😀😀😀😀😀😀😀😀\nsecond line with text\n")

(= (test-output-truncation-chunk)
   "alpha beta gamma delta epsilon zeta eta theta iota kappa lambda mu nu xi omicron pi rho sigma tau upsilon phi chi psi omega.\n")

(= (test-output-truncation-multi-items)
   ((CodexInputText (test-output-truncation-chunk))
    (CodexInputText (test-output-truncation-chunk))
    (CodexInputImage "img:mid" "high")
    (CodexInputText
      (str-concat
        (test-output-truncation-chunk)
        (str-concat
          (test-output-truncation-chunk)
          (str-concat
            (test-output-truncation-chunk)
            (str-concat
              (test-output-truncation-chunk)
              (str-concat
                (test-output-truncation-chunk)
                (str-concat
                  (test-output-truncation-chunk)
                  (str-concat
                    (test-output-truncation-chunk)
                    (str-concat
                      (test-output-truncation-chunk)
                      (str-concat
                        (test-output-truncation-chunk)
                        (test-output-truncation-chunk)))))))))))
    (CodexInputText (test-output-truncation-chunk))
    (CodexInputText (test-output-truncation-chunk))))

!(assertEqualToResult
  (codex:output-truncation-approx-token-count "abcdef")
  (2))

!(assertEqualToResult
  (codex:output-truncation-approx-bytes-for-tokens 8)
  (32))

!(assertEqualToResult
  (codex:output-truncation-approx-tokens-from-byte-count-i64 -1)
  (0))

!(assertEqualToResult
  (codex:output-truncation-approx-tokens-from-byte-count-i64 0)
  (0))

!(assertEqualToResult
  (codex:output-truncation-approx-tokens-from-byte-count-i64 5)
  (2))

!(assertEqualToResult
  (codex:output-truncation-formatted-truncate-text
    "example output"
    (codex:output-truncation-policy-bytes 1))
  ("Total output lines: 1\n\n…13 chars truncated…t"))

!(assertEqualToResult
  (codex:output-truncation-formatted-truncate-text
    "example output"
    (codex:output-truncation-policy-tokens 1))
  ("Total output lines: 1\n\nex…3 tokens truncated…ut"))

!(assertEqualToResult
  (codex:output-truncation-formatted-truncate-text
    "example output"
    (codex:output-truncation-policy-tokens 10))
  ("example output"))

!(assertEqualToResult
  (codex:output-truncation-formatted-truncate-text
    "example output"
    (codex:output-truncation-policy-bytes 20))
  ("example output"))

!(assertEqualToResult
  (codex:output-truncation-formatted-truncate-text
    (test-output-truncation-long-content)
    (codex:output-truncation-policy-tokens 5))
  ("Total output lines: 1\n\nthis is an…10 tokens truncated… truncated"))

!(assertEqualToResult
  (codex:output-truncation-formatted-truncate-text
    (test-output-truncation-long-content)
    (codex:output-truncation-policy-bytes 30))
  ("Total output lines: 1\n\nthis is an exam…30 chars truncated…ld be truncated"))

!(assertEqualToResult
  (codex:output-truncation-formatted-truncate-text
    (test-output-truncation-long-content-lines)
    (codex:output-truncation-policy-bytes 30))
  ("Total output lines: 2\n\nthis is an exam…51 chars truncated…some other line"))

!(assertEqualToResult
  (codex:output-truncation-formatted-truncate-text
    (test-output-truncation-long-content-lines)
    (codex:output-truncation-policy-tokens 10))
  ("Total output lines: 2\n\nthis is an example o…11 tokens truncated…also some other line"))

!(assertEqualToResult
  (codex:output-truncation-truncate-text
    (test-output-truncation-utf8-sample)
    (codex:output-truncation-policy-bytes 20))
  ("😀😀…21 chars truncated…with text\n"))

!(assertEqualToResult
  (codex:output-truncation-formatted-truncate-text-content-items-with-policy
    ((CodexInputText "alpha")
     (CodexInputText "")
     (CodexInputText "beta"))
    (codex:output-truncation-policy-bytes 32))
  ((CodexOutputTruncationContentItemsResult
     ((CodexInputText "alpha")
      (CodexInputText "")
      (CodexInputText "beta"))
     CodexAbsent)))

!(assertEqualToResult
  (codex:output-truncation-formatted-truncate-text-content-items-with-policy
    ((CodexInputText "")
     (CodexInputText "abc"))
    (codex:output-truncation-policy-bytes 0))
  ((CodexOutputTruncationContentItemsResult
     ((CodexInputText "Total output lines: 1\n\n…3 chars truncated…"))
     1)))

!(assertEqualToResult
  (codex:output-truncation-formatted-truncate-text-content-items-with-policy
    ((CodexInputText "abcd")
     (CodexInputImage "img:one" "high")
     (CodexInputText "efgh")
     (CodexInputText "ijkl")
     (CodexInputImage "img:two" "high"))
    (codex:output-truncation-policy-bytes 8))
  ((CodexOutputTruncationContentItemsResult
     ((CodexInputText "Total output lines: 3\n\nabcd…6 chars truncated…ijkl")
      (CodexInputImage "img:one" "high")
      (CodexInputImage "img:two" "high"))
     4)))

!(assertEqualToResult
  (codex:output-truncation-formatted-truncate-text-content-items-with-policy
    ((CodexInputText "abcdefgh")
     (CodexInputText "ijklmnop"))
    (codex:output-truncation-policy-tokens 2))
  ((CodexOutputTruncationContentItemsResult
     ((CodexInputText "Total output lines: 2\n\nabcd…3 tokens truncated…mnop"))
     5)))

!(assertEqualToResult
  (codex:output-truncation-formatted-truncate-text-content-items-with-policy
    ((CodexInputImage "img:only" "high"))
    (codex:output-truncation-policy-bytes 0))
  ((CodexOutputTruncationContentItemsResult
     ((CodexInputImage "img:only" "high"))
     CodexAbsent)))

!(assertEqualToResult
  (list:len
    (codex:output-truncation-truncate-function-output-items-with-policy
      (test-output-truncation-multi-items)
      (codex:output-truncation-policy-tokens
        (* (codex:output-truncation-approx-token-count
             (test-output-truncation-chunk))
           3))))
  (5))

!(assertEqualToResult
  (==
    (case
      (list:at
        (codex:output-truncation-truncate-function-output-items-with-policy
          (test-output-truncation-multi-items)
          (codex:output-truncation-policy-tokens
            (* (codex:output-truncation-approx-token-count
                 (test-output-truncation-chunk))
               3)))
        0)
      (((CodexInputText $text) $text)))
    (test-output-truncation-chunk))
  (True))

!(assertEqualToResult
  (==
    (case
      (list:at
        (codex:output-truncation-truncate-function-output-items-with-policy
          (test-output-truncation-multi-items)
          (codex:output-truncation-policy-tokens
            (* (codex:output-truncation-approx-token-count
                 (test-output-truncation-chunk))
               3)))
        1)
      (((CodexInputText $text) $text)))
    (test-output-truncation-chunk))
  (True))

!(assertEqualToResult
  (list:at
    (codex:output-truncation-truncate-function-output-items-with-policy
      (test-output-truncation-multi-items)
      (codex:output-truncation-policy-tokens
        (* (codex:output-truncation-approx-token-count
             (test-output-truncation-chunk))
           3)))
    2)
  ((CodexInputImage "img:mid" "high")))

!(assertEqualToResult
  (test-output-truncation-is-string-contains
    (case
      (list:at
        (codex:output-truncation-truncate-function-output-items-with-policy
          (test-output-truncation-multi-items)
          (codex:output-truncation-policy-tokens
            (* (codex:output-truncation-approx-token-count
                 (test-output-truncation-chunk))
               3)))
        3)
      (((CodexInputText $text) $text)))
    "tokens truncated")
  (True))

!(assertEqualToResult
  (test-output-truncation-is-string-contains
    (case
      (list:at
        (codex:output-truncation-truncate-function-output-items-with-policy
          (test-output-truncation-multi-items)
          (codex:output-truncation-policy-tokens
            (* (codex:output-truncation-approx-token-count
                 (test-output-truncation-chunk))
               3)))
        4)
      (((CodexInputText $text) $text)))
    "omitted 2 text items")
  (True))
