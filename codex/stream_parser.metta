; Rust-faithful assistant stream markup helpers.
;
; This ports the complete-string helper behavior from:
; - openai-codex/codex-rs/utils/stream-parser/src/citation.rs
; - openai-codex/codex-rs/utils/stream-parser/src/inline_hidden_tag.rs
; - openai-codex/codex-rs/utils/stream-parser/src/proposed_plan.rs
;
; Covered in this increment:
; - CitationStreamParser push_str / finish semantics for the citation tag
; - strip_citations
; - strip_proposed_plan_blocks
; - extract_proposed_plan_text
;
; Required slice-local deviation from Rust, documented for audit:
; - Rust mutates `CitationStreamParser` through the `StreamTextParser` trait.
;   CeTTa returns an explicit next parser state together with the visible text
;   and extracted citation chunk. The state transitions and chunk outputs match
;   Rust's citation parser.
; - Rust defines `strip_citations` by feeding the full string through
;   `CitationStreamParser`. CeTTa keeps the equivalent complete-string loop for
;   this one-shot helper because using the explicit state-returning chunk API
;   under `eval`-heavy stream-events surfaces currently changes reducer search
;   behavior. The visible/citation outputs match Rust and the stateful parser is
;   exposed separately above.
; - Rust's `InlineHiddenTagParser<T>` is generic over any non-empty spec list and
;   breaks same-offset opener ties by longest delimiter and then spec order.
;   This increment ports the exact one-spec specialization used by
;   `CitationStreamParser`; the generic multi-spec parser remains future work.
; - Proposed-plan helpers remain complete-string line parsers in this slice.
;   Rust also has a stateful proposed-plan streaming parser that should be
;   ported in a later stream-parser increment.

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

(= (codex:stream-parser-min $lhs $rhs)
   (if (< $lhs $rhs)
       $lhs
       $rhs))

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

(= (codex:stream-parser-longest-suffix-prefix-len $text $needle)
   (codex:stream-parser-longest-suffix-prefix-len-loop
     $text
     $needle
     (codex:stream-parser-min
       (str-length $text)
       (- (str-length $needle) 1))))

(= (codex:stream-parser-longest-suffix-prefix-len-loop $text $needle $candidate)
   (if (<= $candidate 0)
       0
       (let $prefix (str-slice $needle 0 $candidate)
         (if (str-ends-with? $text $prefix)
             $candidate
             (codex:stream-parser-longest-suffix-prefix-len-loop
               $text
               $needle
               (- $candidate 1))))))

(= (codex:citation-stream-parser-inactive)
   CodexCitationStreamParserInactive)

(= (codex:citation-stream-parser-active $content)
   (CodexCitationStreamParserActive $content))

(= (codex:citation-stream-parser-state $pending $active)
   (CodexCitationStreamParser $pending $active))

(= (codex:citation-stream-parser-new)
   (codex:citation-stream-parser-state
     ""
     (codex:citation-stream-parser-inactive)))

(= (codex:citation-stream-parser-output $parser $visible-text $extracted)
   (CodexCitationStreamParserOutput
     $parser
     $visible-text
     $extracted))

(= (codex:citation-stream-parser-output-parser
      (CodexCitationStreamParserOutput $parser $visible-text $extracted))
   $parser)

(= (codex:citation-stream-parser-output-visible-text
      (CodexCitationStreamParserOutput $parser $visible-text $extracted))
   $visible-text)

(= (codex:citation-stream-parser-output-extracted
      (CodexCitationStreamParserOutput $parser $visible-text $extracted))
   $extracted)

(= (codex:citation-stream-parser-output-is-empty
      (CodexCitationStreamParserOutput $parser $visible-text $extracted))
   (and (== $visible-text "") (== $extracted ())))

(= (codex:citation-stream-parser-push-str
      (CodexCitationStreamParser $pending $active)
      $chunk)
   (codex:citation-stream-parser-push-loop
     (CodexCitationStreamParser
       (str-concat $pending $chunk)
       $active)
     ""
     ()))

(= (codex:citation-stream-parser-push-loop
      (CodexCitationStreamParser
        $pending
        CodexCitationStreamParserInactive)
      $visible-text
      $extracted)
   (case (str-find $pending (codex:stream-parser-citation-open-tag))
     ((Empty
       (let $keep
         (codex:stream-parser-longest-suffix-prefix-len
           $pending
           (codex:stream-parser-citation-open-tag))
         (let $take (- (str-length $pending) $keep)
           (codex:citation-stream-parser-output
             (CodexCitationStreamParser
               (str-slice $pending $take (str-length $pending))
               CodexCitationStreamParserInactive)
             (str-concat
               $visible-text
               (str-slice $pending 0 $take))
             $extracted))))
      ($open-index
       (let $open-end
         (+ $open-index
            (str-length (codex:stream-parser-citation-open-tag)))
         (codex:citation-stream-parser-push-loop
           (CodexCitationStreamParser
             (str-slice $pending $open-end (str-length $pending))
             (codex:citation-stream-parser-active ""))
           (str-concat
             $visible-text
             (str-slice $pending 0 $open-index))
           $extracted))))))

(= (codex:citation-stream-parser-push-loop
      (CodexCitationStreamParser
        $pending
        (CodexCitationStreamParserActive $content))
      $visible-text
      $extracted)
   (case (str-find $pending (codex:stream-parser-citation-close-tag))
     ((Empty
       (let $keep
         (codex:stream-parser-longest-suffix-prefix-len
           $pending
           (codex:stream-parser-citation-close-tag))
         (let $take (- (str-length $pending) $keep)
           (codex:citation-stream-parser-output
             (CodexCitationStreamParser
               (str-slice $pending $take (str-length $pending))
               (codex:citation-stream-parser-active
                 (str-concat
                   $content
                   (str-slice $pending 0 $take))))
             $visible-text
             $extracted))))
      ($close-index
       (let $close-end
         (+ $close-index
            (str-length (codex:stream-parser-citation-close-tag)))
         (codex:citation-stream-parser-push-loop
           (CodexCitationStreamParser
             (str-slice $pending $close-end (str-length $pending))
             CodexCitationStreamParserInactive)
           $visible-text
           (codex:stream-parser-list-append
             $extracted
             ((str-concat
                $content
                (str-slice $pending 0 $close-index))))))))))

(= (codex:citation-stream-parser-finish
      (CodexCitationStreamParser
        $pending
        CodexCitationStreamParserInactive))
   (codex:citation-stream-parser-output
     (codex:citation-stream-parser-new)
     $pending
     ()))

(= (codex:citation-stream-parser-finish
      (CodexCitationStreamParser
        $pending
        (CodexCitationStreamParserActive $content)))
   (codex:citation-stream-parser-output
     (codex:citation-stream-parser-new)
     ""
     ((str-concat $content $pending))))

(= (codex:citation-stream-parser-collect-chunks $chunks)
   (codex:citation-stream-parser-collect-chunks-loop
     (codex:citation-stream-parser-new)
     $chunks
     ""
     ()))

(= (codex:citation-stream-parser-collect-chunks-loop $parser () $visible-text $extracted)
   (case (codex:citation-stream-parser-finish $parser)
     (((CodexCitationStreamParserOutput $next-parser $tail-visible $tail-extracted)
       (codex:citation-stream-parser-output
         $next-parser
         (str-concat $visible-text $tail-visible)
         (codex:stream-parser-list-append
           $extracted
           $tail-extracted))))))

(= (codex:citation-stream-parser-collect-chunks-loop $parser $chunks $visible-text $extracted)
   (let ($head $tail) (decons-atom $chunks)
     (case (codex:citation-stream-parser-push-str $parser $head)
       (((CodexCitationStreamParserOutput $next-parser $next-visible $next-extracted)
         (codex:citation-stream-parser-collect-chunks-loop
           $next-parser
           $tail
           (str-concat $visible-text $next-visible)
           (codex:stream-parser-list-append
             $extracted
             $next-extracted)))))))

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
