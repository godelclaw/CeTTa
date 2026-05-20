; Pure BM25 slice for the Codex port.
;
; This ports the scoring/search algorithm used by Rust Codex through
; bm25 2.3.2:
; - bm25/src/embedder.rs
; - bm25/src/scorer.rs
; - bm25/src/search.rs
;
; Covered in this increment:
; - default BM25 constants k1 = 1.2, b = 0.75, fallback avgdl = 256.0
; - corpus-fit average document length
; - BM25 term-frequency normalization
; - IDF calculation using document frequency, not occurrence count
; - relevant-document filtering, descending score sorting, and result limiting
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust's default tokenizer normalizes with deunicode, lowercases with Unicode
;   case conversion, splits with unicode_words, removes English stopwords, and
;   applies the rust-stemmers English stemmer. CeTTa does not yet provide the
;   deunicode/unicode_words/rust-stemmers libraries, so this slice ports the
;   default tokenizer order with an ASCII word-boundary splitter and the same
;   default English stopword list. The remaining tokenizer deviations are
;   Unicode normalization/case/word-boundary behavior and English stemming.
;   The scorer equations below are valid on already-equivalent token streams.
; - Rust embeds tokens with fxhash::hash32 into u32 indices. This slice keeps the
;   token string as the embedding index until an exact fxhash/UTF-8 byte boundary
;   is added. That avoids artificial collisions, so behavior differs only where
;   Rust's 32-bit hash space collides.
; - Rust gathers candidates through HashSet iteration before stable score sort,
;   making equal-score ordering hash-state dependent. CeTTa keeps input order for
;   equal scores to keep this pure boundary deterministic.

!(import! &self list)
!(import! &self str)

(= (codex:bm25-k1)
   1.2)

(= (codex:bm25-b)
   0.75)

(= (codex:bm25-fallback-avgdl)
   256.0)

(= (codex:bm25-document $id $contents)
   (CodexBm25Document $id $contents))

(= (codex:bm25-document-id (CodexBm25Document $id $contents))
   $id)

(= (codex:bm25-document-contents (CodexBm25Document $id $contents))
   $contents)

(= (codex:bm25-search-result $document $score)
   (CodexBm25SearchResult $document $score))

(= (codex:bm25-search-result-document
      (CodexBm25SearchResult $document $score))
   $document)

(= (codex:bm25-search-result-score
      (CodexBm25SearchResult $document $score))
   $score)

(= (codex:bm25-ascii-lower-char $char)
   (case $char
     (("A" "a")
      ("B" "b")
      ("C" "c")
      ("D" "d")
      ("E" "e")
      ("F" "f")
      ("G" "g")
      ("H" "h")
      ("I" "i")
      ("J" "j")
      ("K" "k")
      ("L" "l")
      ("M" "m")
      ("N" "n")
      ("O" "o")
      ("P" "p")
      ("Q" "q")
      ("R" "r")
      ("S" "s")
      ("T" "t")
      ("U" "u")
      ("V" "v")
      ("W" "w")
      ("X" "x")
      ("Y" "y")
      ("Z" "z")
      ; CeTTa reduction detail: explicit no-op ASCII cases keep recursive
      ; lowercasing stable when this module is imported beside larger Codex
      ; modules, while preserving Rust's visible ASCII lowercase behavior.
      ("a" "a")
      ("b" "b")
      ("c" "c")
      ("d" "d")
      ("e" "e")
      ("f" "f")
      ("g" "g")
      ("h" "h")
      ("i" "i")
      ("j" "j")
      ("k" "k")
      ("l" "l")
      ("m" "m")
      ("n" "n")
      ("o" "o")
      ("p" "p")
      ("q" "q")
      ("r" "r")
      ("s" "s")
      ("t" "t")
      ("u" "u")
      ("v" "v")
      ("w" "w")
      ("x" "x")
      ("y" "y")
      ("z" "z")
      ("_" "_")
      ("-" "-")
      ("/" "/")
      ("<" "<")
      (">" ">")
      (" " " ")
      ("." ".")
      ("#" "#")
      ("\n" "\n")
      ("\t" "\t")
      ("0" "0")
      ("1" "1")
      ("2" "2")
      ("3" "3")
      ("4" "4")
      ("5" "5")
      ("6" "6")
      ("7" "7")
      ("8" "8")
      ("9" "9")
      ("!" "!")
      ("\"" "\"")
      ("$" "$")
      ("%" "%")
      ("&" "&")
      ("'" "'")
      ("(" "(")
      (")" ")")
      ("*" "*")
      ("+" "+")
      ("," ",")
      (":" ":")
      (";" ";")
      ("=" "=")
      ("?" "?")
      ("@" "@")
      ("[" "[")
      ("\\" "\\")
      ("]" "]")
      ("^" "^")
      ("`" "`")
      ("{" "{")
      ("|" "|")
      ("}" "}")
      ("~" "~")
      ($other $other))))

(= (codex:bm25-ascii-lower-text $text)
   (if (== $text "")
       ""
       (str-concat
         (codex:bm25-ascii-lower-char (str-slice $text 0 1))
         (codex:bm25-ascii-lower-text
           (str-slice $text 1 (str-length $text))))))

(= (codex:is-bm25-ascii-letter $char)
   (case $char
     (("a" True)
      ("b" True)
      ("c" True)
      ("d" True)
      ("e" True)
      ("f" True)
      ("g" True)
      ("h" True)
      ("i" True)
      ("j" True)
      ("k" True)
      ("l" True)
      ("m" True)
      ("n" True)
      ("o" True)
      ("p" True)
      ("q" True)
      ("r" True)
      ("s" True)
      ("t" True)
      ("u" True)
      ("v" True)
      ("w" True)
      ("x" True)
      ("y" True)
      ("z" True)
      ("A" True)
      ("B" True)
      ("C" True)
      ("D" True)
      ("E" True)
      ("F" True)
      ("G" True)
      ("H" True)
      ("I" True)
      ("J" True)
      ("K" True)
      ("L" True)
      ("M" True)
      ("N" True)
      ("O" True)
      ("P" True)
      ("Q" True)
      ("R" True)
      ("S" True)
      ("T" True)
      ("U" True)
      ("V" True)
      ("W" True)
      ("X" True)
      ("Y" True)
      ("Z" True)
      ($other False))))

(= (codex:is-bm25-ascii-digit $char)
   (case $char
     (("0" True)
      ("1" True)
      ("2" True)
      ("3" True)
      ("4" True)
      ("5" True)
      ("6" True)
      ("7" True)
      ("8" True)
      ("9" True)
      ($other False))))

(= (codex:is-bm25-decimal-point $text $index)
   (if (<= $index 0)
       False
       (let $next-index (+ $index 1)
         (if (>= $next-index (str-length $text))
             False
             (and
               (codex:is-bm25-ascii-digit
                 (str-slice $text (- $index 1) $index))
               (codex:is-bm25-ascii-digit
                 (str-slice $text $next-index (+ $next-index 1))))))))

(= (codex:is-bm25-apostrophe $text $index)
   (if (<= $index 0)
       False
       (let $next-index (+ $index 1)
         (if (>= $next-index (str-length $text))
             False
             (and
               (codex:is-bm25-ascii-letter
                 (str-slice $text (- $index 1) $index))
               (codex:is-bm25-ascii-letter
                 (str-slice $text $next-index (+ $next-index 1))))))))

(= (codex:is-bm25-token-char $text $index)
   (let $char (str-slice $text $index (+ $index 1))
     (if (codex:is-bm25-ascii-letter $char)
         True
         (if (codex:is-bm25-ascii-digit $char)
             True
             (if (== $char "'")
                 (codex:is-bm25-apostrophe $text $index)
                 (if (== $char ".")
                     (codex:is-bm25-decimal-point $text $index)
                     False))))))

(= (codex:bm25-tokenize-finish-current $current $tokens)
   (if (== $current "")
       $tokens
       (list:append $tokens ($current))))

(= (codex:bm25-tokenize-ascii-words-from $text $index $current $tokens)
   (if (>= $index (str-length $text))
       (codex:bm25-tokenize-finish-current $current $tokens)
       (let $char (str-slice $text $index (+ $index 1))
         (if (codex:is-bm25-token-char $text $index)
             (codex:bm25-tokenize-ascii-words-from
               $text
               (+ $index 1)
               (str-concat
                 $current
                 (codex:bm25-ascii-lower-char $char))
               $tokens)
             (case (codex:bm25-tokenize-finish-current $current $tokens)
               (($next-tokens
                  (codex:bm25-tokenize-ascii-words-from
                    $text
                    (+ $index 1)
                    ""
                    $next-tokens))))))))

(= (codex:bm25-tokenize-ascii-words $text)
   (codex:bm25-tokenize-ascii-words-from $text 0 "" ()))

(= (codex:bm25-string-contains $text $needle)
   (case (str-find $text $needle)
     ((Empty False)
      ($index True))))

(= (codex:bm25-text-needs-recursive-word-split $text)
   (or (codex:bm25-string-contains $text ".")
       (codex:bm25-string-contains $text "'")))

(= (codex:bm25-replace-with-space $text $needle)
   (str-join " " (str-split $needle $text)))

(= (codex:bm25-normalize-common-separators $text)
   (codex:bm25-replace-with-space
     (codex:bm25-replace-with-space
       (codex:bm25-replace-with-space
         (codex:bm25-replace-with-space
           (codex:bm25-replace-with-space
             (codex:bm25-replace-with-space
               (codex:bm25-replace-with-space
                 (codex:bm25-replace-with-space
                   (codex:bm25-replace-with-space
                     (codex:bm25-replace-with-space
                       (codex:bm25-replace-with-space
                         (codex:bm25-replace-with-space
                           (codex:bm25-replace-with-space
                             (codex:bm25-replace-with-space
                               (codex:bm25-replace-with-space
                                 (codex:bm25-replace-with-space
                                   (codex:bm25-replace-with-space
                                     (codex:bm25-replace-with-space
                                       (codex:bm25-replace-with-space
                                         (codex:bm25-replace-with-space
                                           (codex:bm25-replace-with-space
                                             (codex:bm25-replace-with-space
                                               (codex:bm25-replace-with-space
                                                 (codex:bm25-replace-with-space
                                                   (codex:bm25-replace-with-space
                                                     (codex:bm25-replace-with-space
                                                       (codex:bm25-replace-with-space
                                                         (codex:bm25-replace-with-space
                                                           (codex:bm25-replace-with-space
                                                             $text
                                                             ",")
                                                           "!")
                                                         "?")
                                                       ";")
                                                     ":")
                                                   "-")
                                                 "/")
                                               "\\")
                                             "\"")
                                           "(")
                                         ")")
                                       "[")
                                     "]")
                                   "{")
                                 "}")
                               "<")
                             ">")
                           "_")
                         "=")
                       "+")
                     "*")
                   "&")
                 "^")
               "%")
             "$")
           "#")
         "@")
       "~")
     "`"))

(= (codex:bm25-english-stopword-index)
   "|i|me|my|myself|we|our|ours|ourselves|you|you're|you've|you'll|you'd|your|yours|yourself|yourselves|he|him|his|himself|she|she's|her|hers|herself|it|it's|its|itself|they|them|their|theirs|themselves|what|which|who|whom|this|that|that'll|these|those|am|is|are|was|were|be|been|being|have|has|had|having|do|does|did|doing|a|an|the|and|but|if|or|because|as|until|while|of|at|by|for|with|about|against|between|into|through|during|before|after|above|below|to|from|up|down|in|out|on|off|over|under|again|further|then|once|here|there|when|where|why|how|all|any|both|each|few|more|most|other|some|such|no|nor|not|only|own|same|so|than|too|very|s|t|can|will|just|don|don't|should|should've|now|d|ll|m|o|re|ve|y|ain|aren|aren't|couldn|couldn't|didn|didn't|doesn|doesn't|hadn|hadn't|hasn|hasn't|haven|haven't|isn|isn't|ma|mightn|mightn't|mustn|mustn't|needn|needn't|shan|shan't|shouldn|shouldn't|wasn|wasn't|weren|weren't|won|won't|wouldn|wouldn't|")

(= (codex:is-bm25-english-stopword $token)
   (let $needle (str-concat "|" (str-concat $token "|"))
     (case (str-find (codex:bm25-english-stopword-index) $needle)
       ((Empty False)
        ($index True)))))

(= (codex:bm25-remove-english-stopwords $tokens)
   (filter-atom
     $tokens
     $token
     (if (codex:is-bm25-english-stopword $token) False True)))

(= (codex:bm25-tokenize $text)
   (if (codex:bm25-text-needs-recursive-word-split $text)
       (codex:bm25-remove-english-stopwords
         (codex:bm25-tokenize-ascii-words $text))
       (codex:bm25-remove-english-stopwords
         (str-split-whitespace
           (codex:bm25-normalize-common-separators
             (codex:bm25-ascii-lower-text $text))))))

(= (codex:bm25-document-token-record $document)
   (CodexBm25DocumentTokens
     $document
     (codex:bm25-tokenize (codex:bm25-document-contents $document))))

(= (codex:bm25-document-token-record-document
      (CodexBm25DocumentTokens $document $tokens))
   $document)

(= (codex:bm25-document-token-record-tokens
      (CodexBm25DocumentTokens $document $tokens))
   $tokens)

(= (codex:bm25-document-token-records $documents)
   (map-atom-strict
     $documents
     $document
     (codex:bm25-document-token-record $document)))

(= (codex:bm25-token-count $tokens $token)
   (let $matches
     (filter-atom
       $tokens
       $candidate
       (== $candidate $token))
     (size-atom $matches)))

(= (codex:bm25-document-frequency $records $token)
   (let $matches
     (filter-atom
       $records
       $record
       (> (codex:bm25-token-count
            (codex:bm25-document-token-record-tokens $record)
            $token)
          0))
     (size-atom $matches)))

(= (codex:bm25-token-list-length-sum () $acc)
   $acc)

(= (codex:bm25-token-list-length-sum $records $acc)
   (let ($record $tail) (decons-atom $records)
     (let $record-tokens (codex:bm25-document-token-record-tokens $record)
       (case
         (codex:bm25-token-list-length-sum
           $tail
           (+ $acc (size-atom $record-tokens)))
         (($sum $sum))))))

(= (codex:bm25-average-document-length $records)
   (let $document-count (size-atom $records)
     (if (== $document-count 0)
         (codex:bm25-fallback-avgdl)
         (/ (codex:bm25-token-list-length-sum $records 0)
            $document-count))))

(= (codex:bm25-effective-avgdl $avgdl)
   (if (<= $avgdl 0.0)
       (codex:bm25-fallback-avgdl)
       $avgdl))

(= (codex:bm25-document-token-value $tokens $token $avgdl)
   (let $token-frequency (codex:bm25-token-count $tokens $token)
     (if (== $token-frequency 0)
         0.0
         (let $effective-avgdl (codex:bm25-effective-avgdl $avgdl)
           (let $numerator
             (* $token-frequency (+ (codex:bm25-k1) 1.0))
             (let $denominator
               (+ $token-frequency
                  (* (codex:bm25-k1)
                     (+ (- 1.0 (codex:bm25-b))
                        (* (codex:bm25-b)
                           (/ (size-atom $tokens)
                              $effective-avgdl)))))
               (/ $numerator $denominator)))))))

(= (codex:bm25-idf $document-count $document-frequency)
   (let $numerator (+ (- $document-count $document-frequency) 0.5)
     (let $denominator (+ $document-frequency 0.5)
       (log-math EXP (+ 1.0 (/ $numerator $denominator))))))

(= (codex:bm25-score-query-tokens
      $records
      $document-count
      $document-tokens
      $query-tokens
      $avgdl
      $acc)
   (if (== $query-tokens ())
       $acc
       (let ($token $tail) (decons-atom $query-tokens)
         (let $document-frequency
           (codex:bm25-document-frequency $records $token)
           (let $token-idf
             (codex:bm25-idf $document-count $document-frequency)
             (let $token-value
               (codex:bm25-document-token-value
                 $document-tokens
                 $token
                 $avgdl)
               (codex:bm25-score-query-tokens
                 $records
                 $document-count
                 $document-tokens
                 $tail
                 $avgdl
                 (+ $acc (* $token-idf $token-value)))))))))

(= (codex:bm25-score-record $records $record $query-tokens $avgdl)
   (codex:bm25-score-query-tokens
     $records
     (size-atom $records)
     (codex:bm25-document-token-record-tokens $record)
     $query-tokens
     $avgdl
     0.0))

(= (codex:bm25-record-search-result $records $query-tokens $avgdl $record)
   (case (codex:bm25-score-record $records $record $query-tokens $avgdl)
     (($score
        (codex:bm25-search-result
          (codex:bm25-document-token-record-document $record)
          $score)))))

(= (codex:bm25-insert-search-result-desc $item $sorted)
   (if (== $sorted ())
       ($item)
       (let $head (list:first $sorted)
         (let $tail (list:rest $sorted)
           (let $item-score (codex:bm25-search-result-score $item)
             (let $head-score (codex:bm25-search-result-score $head)
               (if (>= $item-score $head-score)
                   (cons-atom $item $sorted)
                   (let $inserted-tail
                     (eval
                       (codex:bm25-insert-search-result-desc
                         $item
                         $tail))
                     (cons-atom $head $inserted-tail)))))))))

(= (codex:bm25-sort-search-results-desc $items)
   (if (== $items ())
       ()
       (let $head (list:first $items)
         (let $tail (list:rest $items)
           (let $sorted-tail
             (eval (codex:bm25-sort-search-results-desc $tail))
             (codex:bm25-insert-search-result-desc
               $head
               $sorted-tail))))))

(= (codex:bm25-resolve-limit $limit)
   (case $limit
     ((CodexAbsent 9223372036854775807)
      ($real-limit $real-limit))))

(= (codex:bm25-search-documents $documents $query $limit)
   (let $query-tokens (codex:bm25-tokenize $query)
     (if (== $query-tokens ())
         ()
         (let $records (codex:bm25-document-token-records $documents)
           (let $avgdl (codex:bm25-average-document-length $records)
             (let $scored
               (map-atom-strict
                 $records
                 $record
                 (codex:bm25-record-search-result
                   $records
                   $query-tokens
                   $avgdl
                   $record))
               (let $matches
                 (filter-atom
                   $scored
                   $result
                   (> (codex:bm25-search-result-score $result) 0.0))
                 (let $sorted
                   (eval (codex:bm25-sort-search-results-desc $matches))
                   (codex:bm25-take
                     $sorted
                     (codex:bm25-resolve-limit $limit))))))))))

(= (codex:bm25-take $items $limit)
   (if (<= $limit 0)
       ()
       (let $item-count (size-atom $items)
         (if (== $item-count 0)
             ()
             (let $take-count
               (if (< $limit $item-count)
                   $limit
                   $item-count)
               (let $range (range-atom $take-count)
                 (map-atom-strict
                   $range
                   $index
                   (index-atom $items $index))))))))

(= (codex:bm25-search-result-document-id $result)
   (codex:bm25-document-id
     (codex:bm25-search-result-document $result)))

(= (codex:bm25-search-document-ids $documents $query $limit)
   (case (codex:bm25-search-documents $documents $query $limit)
     (($results
        (map-atom-strict
          $results
          $result
          (codex:bm25-search-result-document-id $result))))))
