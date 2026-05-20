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
;   applies the rust-stemmers English stemmer. CeTTa does not yet provide those
;   libraries, so this slice uses ASCII lowercase plus whitespace tokenization.
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

(= (codex:bm25-tokenize $text)
   (str-split-whitespace
     (codex:bm25-ascii-lower-text $text)))

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
