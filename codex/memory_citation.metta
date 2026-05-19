; Rust-faithful memory citation parser slice.
;
; This ports the pure parser behavior from:
; - openai-codex/codex-rs/core/src/memories/citations.rs
; - openai-codex/codex-rs/protocol/src/memory_citation.rs
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust validates rollout ids by constructing `ThreadId` through the `uuid`
;   crate. Until CeTTa has a UUID parser library, this slice accepts canonical
;   hyphenated UUID text only, which is the format emitted by Rust `ThreadId`.

!(import! &self list)
!(import! &self protocol)
!(import! &self str)

(= (codex:memory-citation-none)
   CodexAbsent)

(= (codex:memory-citation-some $citation)
   $citation)

(= (codex:memory-citation-split-first $text $needle)
   (case (str-find $text $needle)
     ((Empty CodexAbsent)
      ($index
       (CodexMemoryCitationSplit
         (str-slice $text 0 $index)
         (str-slice
           $text
           (+ $index (str-length $needle))
           (str-length $text)))))))

(= (codex:memory-citation-split-last $text $needle)
   (let $parts (str-split $needle $text)
     (if (< (list:len $parts) 2)
         CodexAbsent
         (CodexMemoryCitationSplit
           (str-join $needle (codex:memory-citation-parts-init $parts))
           (codex:memory-citation-parts-last $parts)))))

(= (codex:memory-citation-parts-last $parts)
   (if (== (list:len $parts) 1)
       (list:first $parts)
       (codex:memory-citation-parts-last (list:rest $parts))))

(= (codex:memory-citation-parts-init $parts)
   (if (== (list:len $parts) 1)
       ()
       (let $head (list:first $parts)
         (let $tail (list:rest $parts)
           (case (codex:memory-citation-parts-init $tail)
             (($rest (cons-atom $head $rest))))))))

(= (codex:memory-citation-split-left
      (CodexMemoryCitationSplit $left $right))
   $left)

(= (codex:memory-citation-split-right
      (CodexMemoryCitationSplit $left $right))
   $right)

(= (codex:memory-citation-strip-suffix $text $suffix)
   (if (str-ends-with? $text $suffix)
       (str-slice $text 0 (- (str-length $text) (str-length $suffix)))
       CodexAbsent))

(= (codex:memory-citation-decimal-digit-value "0")
   0)

(= (codex:memory-citation-decimal-digit-value "1")
   1)

(= (codex:memory-citation-decimal-digit-value "2")
   2)

(= (codex:memory-citation-decimal-digit-value "3")
   3)

(= (codex:memory-citation-decimal-digit-value "4")
   4)

(= (codex:memory-citation-decimal-digit-value "5")
   5)

(= (codex:memory-citation-decimal-digit-value "6")
   6)

(= (codex:memory-citation-decimal-digit-value "7")
   7)

(= (codex:memory-citation-decimal-digit-value "8")
   8)

(= (codex:memory-citation-decimal-digit-value "9")
   9)

(= (codex:memory-citation-is-decimal-digit $text)
   (case $text
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

(= (codex:memory-citation-parse-u32 $text)
   (let $trimmed (str-trim $text)
     (if (== $trimmed "")
         CodexAbsent
         (codex:memory-citation-parse-u32-from $trimmed 0 0))))

(= (codex:memory-citation-parse-u32-from $text $index $acc)
   (if (== $index (str-length $text))
       $acc
       (let $char (str-slice $text $index (+ $index 1))
         (if (codex:memory-citation-is-decimal-digit $char)
             (let $next
               (+ (* $acc 10)
                  (codex:memory-citation-decimal-digit-value $char))
               (if (> $next 4294967295)
                   CodexAbsent
                   (codex:memory-citation-parse-u32-from
                     $text
                     (+ $index 1)
                     $next)))
             CodexAbsent))))

(= (codex:parse-memory-citation-entry $line)
   (let $line (str-trim $line)
     (if (== $line "")
         CodexAbsent
         (case (codex:memory-citation-split-last $line "|note=[")
           ((CodexAbsent CodexAbsent)
            ((CodexMemoryCitationSplit $location $raw-note)
             (case (codex:memory-citation-strip-suffix $raw-note "]")
               ((CodexAbsent CodexAbsent)
                ($note
                 (case (codex:memory-citation-split-last $location ":")
                   ((CodexAbsent CodexAbsent)
                    ((CodexMemoryCitationSplit $path $line-range)
                     (case (codex:memory-citation-split-first $line-range "-")
                       ((CodexAbsent CodexAbsent)
                        ((CodexMemoryCitationSplit $line-start-text $line-end-text)
                         (case (codex:memory-citation-parse-u32 $line-start-text)
                           ((CodexAbsent CodexAbsent)
                            ($line-start
                             (case (codex:memory-citation-parse-u32 $line-end-text)
                               ((CodexAbsent CodexAbsent)
                                ($line-end
                                 (codex:memory-citation-entry
                                   (str-trim $path)
                                   $line-start
                                   $line-end
                                   (str-trim $note)))))))))))))))))))))))

(= (codex:memory-citation-lines $text)
   (let $parts (str-split "\n" $text)
     (if (str-ends-with? $text "\n")
         (codex:memory-citation-drop-last $parts)
         $parts)))

(= (codex:memory-citation-drop-last $items)
   (if (or (== $items ()) (== (list:len $items) 1))
       ()
       (let ($head $tail) (decons-atom $items)
         (case (codex:memory-citation-drop-last $tail)
           (($rest (cons-atom $head $rest)))))))

(= (codex:memory-citation-entries-from-lines ())
   ())

(= (codex:memory-citation-entries-from-lines $lines)
   (let ($head $tail) (decons-atom $lines)
     (let $entry (codex:parse-memory-citation-entry $head)
       (if (== $entry CodexAbsent)
           (case (codex:memory-citation-entries-from-lines $tail)
             (($entries $entries)))
           (case (codex:memory-citation-entries-from-lines $tail)
             (($entries (cons-atom $entry $entries))))))))

(= (codex:extract-memory-citation-block $text $open $close)
   (case (codex:memory-citation-split-first $text $open)
     ((CodexAbsent CodexAbsent)
      ((CodexMemoryCitationSplit $before $after-open)
       (case (codex:memory-citation-split-first $after-open $close)
         ((CodexAbsent CodexAbsent)
          ((CodexMemoryCitationSplit $body $after-close) $body)))))))

(= (codex:extract-memory-citation-ids-block $text)
   (case
     (codex:extract-memory-citation-block
       $text
       "<rollout_ids>"
       "</rollout_ids>")
     ((CodexAbsent
       (codex:extract-memory-citation-block
         $text
         "<thread_ids>"
         "</thread_ids>"))
      ($ids-block $ids-block))))

(= (codex:memory-citation-string-list-contains $items $needle)
   (if (== $items ())
       False
       (if (== (list:first $items) $needle)
           True
           (codex:memory-citation-string-list-contains
             (list:rest $items)
             $needle))))

(= (codex:memory-citation-unique-nonempty-trimmed-lines $text)
   (codex:memory-citation-unique-nonempty-trimmed-lines-loop
     (codex:memory-citation-lines $text)
     ()))

(= (codex:memory-citation-unique-nonempty-trimmed-lines-loop () $seen)
   ())

(= (codex:memory-citation-unique-nonempty-trimmed-lines-loop $lines $seen)
   (let $head (str-trim (list:first $lines))
     (let $tail (list:rest $lines)
       (if (== $head "")
           (case
             (codex:memory-citation-unique-nonempty-trimmed-lines-loop
               $tail
               $seen)
             (($rest $rest)))
           (if (codex:memory-citation-string-list-contains $seen $head)
               (case
                 (codex:memory-citation-unique-nonempty-trimmed-lines-loop
                   $tail
                   $seen)
                 (($rest $rest)))
               (case
                 (codex:memory-citation-unique-nonempty-trimmed-lines-loop
                   $tail
                   (cons-atom $head $seen))
                 (($rest (cons-atom $head $rest)))))))))

(= (codex:parse-memory-citation-one $citation)
   (let $entries-block
     (codex:extract-memory-citation-block
       $citation
       "<citation_entries>"
       "</citation_entries>")
     (let $entries
       (if (== $entries-block CodexAbsent)
           ()
           (codex:memory-citation-entries-from-lines
             (codex:memory-citation-lines $entries-block)))
       (let $ids-block (codex:extract-memory-citation-ids-block $citation)
         (let $rollout-ids
           (if (== $ids-block CodexAbsent)
               ()
               (codex:memory-citation-unique-nonempty-trimmed-lines $ids-block))
           (CodexParsedMemoryCitationParts $entries $rollout-ids))))))

(= (codex:memory-citation-append () $rhs)
   $rhs)

(= (codex:memory-citation-append $lhs $rhs)
   (let ($head $tail) (decons-atom $lhs)
     (case (codex:memory-citation-append $tail $rhs)
       (($rest (cons-atom $head $rest))))))

(= (codex:memory-citation-add-unique-rollout-ids () $seen)
   ())

(= (codex:memory-citation-add-unique-rollout-ids $ids $seen)
   (let $head (list:first $ids)
     (let $tail (list:rest $ids)
       (if (codex:memory-citation-string-list-contains $seen $head)
           (codex:memory-citation-add-unique-rollout-ids $tail $seen)
           (case
             (codex:memory-citation-add-unique-rollout-ids
               $tail
               (cons-atom $head $seen))
             (($rest (cons-atom $head $rest))))))))

(= (codex:parse-memory-citation-loop () $entries $rollout-ids)
   (if (and (== $entries ()) (== $rollout-ids ()))
       CodexAbsent
       (codex:memory-citation $entries $rollout-ids)))

(= (codex:parse-memory-citation-loop $citations $entries $rollout-ids)
   (let $head (list:first $citations)
     (let $tail (list:rest $citations)
       (case (codex:parse-memory-citation-one $head)
         (((CodexParsedMemoryCitationParts $head-entries $head-rollout-ids)
           (case (codex:memory-citation-append $entries $head-entries)
             (($next-entries
               (case
                 (codex:memory-citation-add-unique-rollout-ids
                   $head-rollout-ids
                   $rollout-ids)
                 (($new-rollout-ids
                   (case
                     (codex:memory-citation-append
                       $rollout-ids
                       $new-rollout-ids)
                     (($next-rollout-ids
                       (codex:parse-memory-citation-loop
                         $tail
                         $next-entries
                         $next-rollout-ids))))))))))))))))

(= (codex:parse-memory-citation $citations)
   (codex:parse-memory-citation-loop $citations () ()))

(= (codex:memory-citation-is-hex-char $char)
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
      ("a" True)
      ("b" True)
      ("c" True)
      ("d" True)
      ("e" True)
      ("f" True)
      ("A" True)
      ("B" True)
      ("C" True)
      ("D" True)
      ("E" True)
      ("F" True)
      ($other False))))

(= (codex:memory-citation-is-thread-id $text)
   ; CeTTa evaluation accommodation: ids often reach this Rust `ThreadId::new`
   ; port through list projections, so force the projected atom before string
   ; validation. This does not change the accepted wire shape.
   (case (once (eval $text))
     (($materialized-text
       (if (== (str-length $materialized-text) 36)
           (codex:memory-citation-is-thread-id-segments $materialized-text)
           False)))))

(= (codex:memory-citation-is-thread-id-segments $text)
   (if (== (str-slice $text 8 9) "-")
       (if (== (str-slice $text 13 14) "-")
           (if (== (str-slice $text 18 19) "-")
               (if (== (str-slice $text 23 24) "-")
                   (codex:memory-citation-is-thread-id-hex $text)
                   False)
               False)
           False)
       False))

(= (codex:memory-citation-is-hex-at $text $index)
   (codex:memory-citation-is-hex-char
     (str-slice $text $index (+ $index 1))))

(= (codex:memory-citation-is-hex-pair $text $left $right)
   (and
     (codex:memory-citation-is-hex-at $text $left)
     (codex:memory-citation-is-hex-at $text $right)))

(= (codex:memory-citation-is-hex-quad $text $a $b $c $d)
   (and
     (codex:memory-citation-is-hex-pair $text $a $b)
     (codex:memory-citation-is-hex-pair $text $c $d)))

(= (codex:memory-citation-is-thread-id-hex $text)
   (and
     (codex:memory-citation-is-hex-quad $text 0 1 2 3)
     (and
       (codex:memory-citation-is-hex-quad $text 4 5 6 7)
       (and
         (codex:memory-citation-is-hex-quad $text 9 10 11 12)
         (and
           (codex:memory-citation-is-hex-quad $text 14 15 16 17)
           (and
             (codex:memory-citation-is-hex-quad $text 19 20 21 22)
             (and
               (codex:memory-citation-is-hex-quad $text 24 25 26 27)
               (and
                 (codex:memory-citation-is-hex-quad $text 28 29 30 31)
                 (codex:memory-citation-is-hex-quad
                   $text
                   32
                   33
                   34
                   35)))))))))

(= (codex:thread-ids-from-memory-citation
      (CodexMemoryCitation $entries $rollout-ids))
   (codex:memory-citation-filter-thread-ids $rollout-ids))

(= (codex:memory-citation-filter-thread-ids ())
   ())

(= (codex:memory-citation-filter-thread-ids $rollout-ids)
   (let $head (list:first $rollout-ids)
     (let $tail (list:rest $rollout-ids)
       (if (codex:memory-citation-is-thread-id $head)
           (case (codex:memory-citation-filter-thread-ids $tail)
             (($rest (cons-atom $head $rest))))
           (case (codex:memory-citation-filter-thread-ids $tail)
             (($rest $rest)))))))
