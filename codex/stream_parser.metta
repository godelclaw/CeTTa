; Rust-faithful one-shot assistant stream markup helpers.
;
; This ports the complete-string helper behavior from:
; - openai-codex/codex-rs/utils/stream-parser/src/citation.rs
; - openai-codex/codex-rs/utils/stream-parser/src/proposed_plan.rs
;
; Covered in this increment:
; - strip_citations
; - strip_proposed_plan_blocks
; - extract_proposed_plan_text
;
; Required slice-local deviation from Rust, documented for audit:
; - Rust implements stateful parsers for chunked streaming and defines these
;   one-shot helpers by feeding a full string through that parser. This CeTTa
;   slice ports the same observable full-string helper semantics directly.
;   Stateful chunk parser records are intentionally left for a later runtime
;   stream-parser slice.

!(import! &self list)
!(import! &self str)

(= (codex:stream-parser-citation-open-tag)
   "<oai-mem-citation>")

(= (codex:stream-parser-citation-close-tag)
   "</oai-mem-citation>")

(= (codex:stream-parser-plan-open-tag)
   "<proposed_plan>")

(= (codex:stream-parser-plan-close-tag)
   "</proposed_plan>")

(= (codex:stream-parser-strip-citations-result $visible $citations)
   (CodexStreamParserStripCitationsResult $visible $citations))

(= (codex:stream-parser-strip-citations-visible
      (CodexStreamParserStripCitationsResult $visible $citations))
   $visible)

(= (codex:stream-parser-strip-citations-citations
      (CodexStreamParserStripCitationsResult $visible $citations))
   $citations)

(= (codex:stream-parser-split-result $left $right)
   (CodexStreamParserSplitResult $left $right))

(= (codex:stream-parser-split-first $text $needle)
   (let $parts (str-split $needle $text)
     (if (== (list:len $parts) 1)
         CodexAbsent
         (codex:stream-parser-split-result
           (list:first $parts)
           (str-join $needle (list:rest $parts))))))

(= (codex:stream-parser-list-append () $rhs)
   $rhs)

(= (codex:stream-parser-list-append $lhs $rhs)
   (let ($head $tail) (decons-atom $lhs)
     (case (codex:stream-parser-list-append $tail $rhs)
       (($rest
         (cons-atom $head $rest))))))

(= (codex:stream-parser-strip-citations-loop $text $visible $citations)
   (case
     (codex:stream-parser-split-first
       $text
       (codex:stream-parser-citation-open-tag))
     ((CodexAbsent
       (codex:stream-parser-strip-citations-result
         (str-concat $visible $text)
         $citations))
      ((CodexStreamParserSplitResult $before-open $after-open)
       (case
         (codex:stream-parser-split-first
           $after-open
           (codex:stream-parser-citation-close-tag))
         ((CodexAbsent
           (codex:stream-parser-strip-citations-result
             (str-concat $visible $before-open)
             (codex:stream-parser-list-append
               $citations
               ($after-open))))
          ((CodexStreamParserSplitResult $citation $after-close)
           (codex:stream-parser-strip-citations-loop
             $after-close
             (str-concat $visible $before-open)
             (codex:stream-parser-list-append
               $citations
               ($citation))))))))))

(= (codex:strip-citations $text)
   (codex:stream-parser-strip-citations-loop $text "" ()))

(= (codex:stream-parser-line-text $part $has-newline)
   (if $has-newline
       (str-concat $part "\n")
       $part))

(= (codex:stream-parser-plan-slug $part)
   (str-trim $part))

(= (codex:stream-parser-strip-plan-parts () $drop-final-empty $in-plan)
   "")

(= (codex:stream-parser-strip-plan-parts $parts $drop-final-empty $in-plan)
   (let ($head $tail) (decons-atom $parts)
     (if (and (== $tail ()) (and $drop-final-empty (== $head "")))
         ""
         (let $slug (codex:stream-parser-plan-slug $head)
           (let $has-newline (not (== $tail ()))
             (let $line-text
               (codex:stream-parser-line-text $head $has-newline)
               (if (and (not $in-plan)
                        (== $slug (codex:stream-parser-plan-open-tag)))
                   (codex:stream-parser-strip-plan-parts $tail $drop-final-empty True)
                   (if (and $in-plan
                            (== $slug (codex:stream-parser-plan-close-tag)))
                       (codex:stream-parser-strip-plan-parts $tail $drop-final-empty False)
                       (if $in-plan
                           (codex:stream-parser-strip-plan-parts
                             $tail
                             $drop-final-empty
                             True)
                           (str-concat
                             $line-text
                             (codex:stream-parser-strip-plan-parts
                               $tail
                               $drop-final-empty
                               False)))))))))))

(= (codex:strip-proposed-plan-blocks $text)
   (codex:stream-parser-strip-plan-parts
     (str-split "\n" $text)
     (str-ends-with? $text "\n")
     False))

(= (codex:stream-parser-plan-extract-result $saw-plan $in-plan $plan-text)
   (CodexStreamParserPlanExtractResult $saw-plan $in-plan $plan-text))

(= (codex:stream-parser-extract-plan-parts () $drop-final-empty $saw-plan $in-plan $plan-text)
   (codex:stream-parser-plan-extract-result $saw-plan $in-plan $plan-text))

(= (codex:stream-parser-extract-plan-parts $parts $drop-final-empty $saw-plan $in-plan $plan-text)
   (let ($head $tail) (decons-atom $parts)
     (if (and (== $tail ()) (and $drop-final-empty (== $head "")))
         (codex:stream-parser-plan-extract-result $saw-plan $in-plan $plan-text)
         (let $slug (codex:stream-parser-plan-slug $head)
           (let $has-newline (not (== $tail ()))
             (let $line-text
               (codex:stream-parser-line-text $head $has-newline)
               (if (and (not $in-plan)
                        (== $slug (codex:stream-parser-plan-open-tag)))
                   (codex:stream-parser-extract-plan-parts
                     $tail
                     $drop-final-empty
                     True
                     True
                     "")
                   (if (and $in-plan
                            (== $slug (codex:stream-parser-plan-close-tag)))
                       (codex:stream-parser-extract-plan-parts
                         $tail
                         $drop-final-empty
                         $saw-plan
                         False
                         $plan-text)
                       (if $in-plan
                           (codex:stream-parser-extract-plan-parts
                             $tail
                             $drop-final-empty
                             $saw-plan
                             True
                             (str-concat $plan-text $line-text))
                           (codex:stream-parser-extract-plan-parts
                             $tail
                             $drop-final-empty
                             $saw-plan
                             False
                             $plan-text))))))))))

(= (codex:extract-proposed-plan-text $text)
   (case
     (codex:stream-parser-extract-plan-parts
       (str-split "\n" $text)
       (str-ends-with? $text "\n")
       False
       False
       "")
     (((CodexStreamParserPlanExtractResult True $in-plan $plan-text)
       $plan-text)
      ((CodexStreamParserPlanExtractResult False $in-plan $plan-text)
       CodexAbsent))))
