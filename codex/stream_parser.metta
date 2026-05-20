; Rust-faithful assistant stream markup helpers.
;
; This ports the complete-string helper behavior from:
; - openai-codex/codex-rs/utils/stream-parser/src/citation.rs
; - openai-codex/codex-rs/utils/stream-parser/src/inline_hidden_tag.rs
; - openai-codex/codex-rs/utils/stream-parser/src/proposed_plan.rs
;
; Covered in this increment:
; - InlineHiddenTagParser push_str / finish semantics for literal tag specs
; - CitationStreamParser push_str / finish semantics for the citation tag
; - ProposedPlanParser push_str / finish semantics for the proposed_plan tag
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
; - Rust mutates `InlineHiddenTagParser<T>` through the `StreamTextParser`
;   trait. CeTTa returns an explicit next parser state, visible text, and
;   extracted tags. The matching, buffering, tie-breaking, and EOF auto-close
;   behavior match Rust.
; - Rust's `TaggedLineParser<T>` is generic over tag specs. CeTTa ports the
;   exact one-spec specialization used by `ProposedPlanParser`; a future generic
;   multi-tag parser should preserve the same line-buffer state machine.

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

(= (codex:inline-hidden-tag-spec $tag $open $close)
   (CodexInlineHiddenTagSpec $tag $open $close))

(= (codex:inline-hidden-tag-extracted $tag $content)
   (CodexExtractedInlineTag $tag $content))

(= (codex:inline-hidden-tag-extracted-tag
      (CodexExtractedInlineTag $tag $content))
   $tag)

(= (codex:inline-hidden-tag-extracted-content
      (CodexExtractedInlineTag $tag $content))
   $content)

(= (codex:inline-hidden-tag-parser-inactive)
   CodexInlineHiddenTagParserInactive)

(= (codex:inline-hidden-tag-parser-active $tag $close $content)
   (CodexInlineHiddenTagParserActive $tag $close $content))

(= (codex:inline-hidden-tag-parser-state $specs $pending $active)
   (CodexInlineHiddenTagParser $specs $pending $active))

(= (codex:inline-hidden-tag-parser-output $parser $visible-text $extracted)
   (CodexInlineHiddenTagParserOutput $parser $visible-text $extracted))

(= (codex:inline-hidden-tag-parser-output-parser
      (CodexInlineHiddenTagParserOutput $parser $visible-text $extracted))
   $parser)

(= (codex:inline-hidden-tag-parser-output-visible-text
      (CodexInlineHiddenTagParserOutput $parser $visible-text $extracted))
   $visible-text)

(= (codex:inline-hidden-tag-parser-output-extracted
      (CodexInlineHiddenTagParserOutput $parser $visible-text $extracted))
   $extracted)

(= (codex:inline-hidden-tag-specs-have-empty-open ())
   False)

(= (codex:inline-hidden-tag-specs-have-empty-open $specs)
   (let ($head $tail) (decons-atom $specs)
     (case $head
       (((CodexInlineHiddenTagSpec $tag $open $close)
         (if (== $open "")
             True
             (codex:inline-hidden-tag-specs-have-empty-open $tail)))))))

(= (codex:inline-hidden-tag-specs-have-empty-close ())
   False)

(= (codex:inline-hidden-tag-specs-have-empty-close $specs)
   (let ($head $tail) (decons-atom $specs)
     (case $head
       (((CodexInlineHiddenTagSpec $tag $open $close)
         (if (== $close "")
             True
             (codex:inline-hidden-tag-specs-have-empty-close $tail)))))))

(= (codex:inline-hidden-tag-parser-new $specs)
   (if (== $specs ())
       (Error
         (codex:inline-hidden-tag-parser-new $specs)
         "InlineHiddenTagParser requires at least one tag spec")
       (if (codex:inline-hidden-tag-specs-have-empty-open $specs)
           (Error
             (codex:inline-hidden-tag-parser-new $specs)
             "InlineHiddenTagParser requires non-empty open delimiters")
           (if (codex:inline-hidden-tag-specs-have-empty-close $specs)
               (Error
                 (codex:inline-hidden-tag-parser-new $specs)
                 "InlineHiddenTagParser requires non-empty close delimiters")
               (codex:inline-hidden-tag-parser-state
                 $specs
                 ""
                 (codex:inline-hidden-tag-parser-inactive))))))

(= (codex:inline-hidden-tag-open-match $pos $open-len $spec-index $tag $open $close)
   (CodexInlineHiddenTagOpenMatch $pos $open-len $spec-index $tag $open $close))

(= (codex:inline-hidden-tag-open-match-is-better
      (CodexInlineHiddenTagOpenMatch $pos $open-len $spec-index $tag $open $close)
      CodexAbsent)
   True)

(= (codex:inline-hidden-tag-open-match-is-better
      (CodexInlineHiddenTagOpenMatch $pos $open-len $spec-index $tag $open $close)
      (CodexInlineHiddenTagOpenMatch $best-pos $best-open-len $best-spec-index $best-tag $best-open $best-close))
   (if (< $pos $best-pos)
       True
       (if (> $pos $best-pos)
           False
           (if (> $open-len $best-open-len)
               True
               (if (< $open-len $best-open-len)
                   False
                   (< $spec-index $best-spec-index))))))

(= (codex:inline-hidden-tag-parser-better-open-match $candidate $best)
   (if (codex:inline-hidden-tag-open-match-is-better $candidate $best)
       $candidate
       $best))

(= (codex:inline-hidden-tag-parser-find-next-open-loop $pending () $spec-index $best)
   $best)

(= (codex:inline-hidden-tag-parser-find-next-open-loop $pending $specs $spec-index $best)
   (let ($head $tail) (decons-atom $specs)
     (case $head
       (((CodexInlineHiddenTagSpec $tag $open $close)
         (case (str-find $pending $open)
           ((Empty
             (codex:inline-hidden-tag-parser-find-next-open-loop
               $pending
               $tail
               (+ $spec-index 1)
               $best))
            ($pos
             (let $candidate
               (codex:inline-hidden-tag-open-match
                 $pos
                 (str-length $open)
                 $spec-index
                 $tag
                 $open
                 $close)
               (codex:inline-hidden-tag-parser-find-next-open-loop
                 $pending
                 $tail
                 (+ $spec-index 1)
                 (codex:inline-hidden-tag-parser-better-open-match
                   $candidate
                   $best)))))))))))

(= (codex:inline-hidden-tag-parser-find-next-open $pending $specs)
   (codex:inline-hidden-tag-parser-find-next-open-loop
     $pending
     $specs
     0
     CodexAbsent))

(= (codex:stream-parser-max $lhs $rhs)
   (if (> $lhs $rhs)
       $lhs
       $rhs))

(= (codex:inline-hidden-tag-parser-max-open-prefix-suffix-len-loop $pending () $max-len)
   $max-len)

(= (codex:inline-hidden-tag-parser-max-open-prefix-suffix-len-loop $pending $specs $max-len)
   (let ($head $tail) (decons-atom $specs)
     (case $head
       (((CodexInlineHiddenTagSpec $tag $open $close)
         (codex:inline-hidden-tag-parser-max-open-prefix-suffix-len-loop
           $pending
           $tail
           (codex:stream-parser-max
             $max-len
             (codex:stream-parser-longest-suffix-prefix-len
               $pending
               $open))))))))

(= (codex:inline-hidden-tag-parser-max-open-prefix-suffix-len $pending $specs)
   (codex:inline-hidden-tag-parser-max-open-prefix-suffix-len-loop
     $pending
     $specs
     0))

(= (codex:inline-hidden-tag-parser-push-str
      (CodexInlineHiddenTagParser $specs $pending $active)
      $chunk)
   (codex:inline-hidden-tag-parser-push-loop
     (CodexInlineHiddenTagParser
       $specs
       (str-concat $pending $chunk)
       $active)
     ""
     ()))

(= (codex:inline-hidden-tag-parser-push-loop
      (CodexInlineHiddenTagParser
        $specs
        $pending
        CodexInlineHiddenTagParserInactive)
      $visible-text
      $extracted)
   (case (codex:inline-hidden-tag-parser-find-next-open $pending $specs)
     ((CodexAbsent
       (let $keep
         (codex:inline-hidden-tag-parser-max-open-prefix-suffix-len
           $pending
           $specs)
         (let $take (- (str-length $pending) $keep)
           (codex:inline-hidden-tag-parser-output
             (CodexInlineHiddenTagParser
               $specs
               (str-slice $pending $take (str-length $pending))
               CodexInlineHiddenTagParserInactive)
             (str-concat
               $visible-text
               (str-slice $pending 0 $take))
             $extracted))))
      ((CodexInlineHiddenTagOpenMatch $open-index $open-len $spec-index $tag $open $close)
       (let $open-end (+ $open-index $open-len)
         (codex:inline-hidden-tag-parser-push-loop
           (CodexInlineHiddenTagParser
             $specs
             (str-slice $pending $open-end (str-length $pending))
             (codex:inline-hidden-tag-parser-active $tag $close ""))
           (str-concat
             $visible-text
             (str-slice $pending 0 $open-index))
           $extracted))))))

(= (codex:inline-hidden-tag-parser-push-loop
      (CodexInlineHiddenTagParser
        $specs
        $pending
        (CodexInlineHiddenTagParserActive $tag $close $content))
      $visible-text
      $extracted)
   (case (str-find $pending $close)
     ((Empty
       (let $keep
         (codex:stream-parser-longest-suffix-prefix-len $pending $close)
         (let $take (- (str-length $pending) $keep)
           (codex:inline-hidden-tag-parser-output
             (CodexInlineHiddenTagParser
               $specs
               (str-slice $pending $take (str-length $pending))
               (codex:inline-hidden-tag-parser-active
                 $tag
                 $close
                 (str-concat
                   $content
                   (str-slice $pending 0 $take))))
             $visible-text
             $extracted))))
      ($close-index
       (let $close-end (+ $close-index (str-length $close))
         (codex:inline-hidden-tag-parser-push-loop
           (CodexInlineHiddenTagParser
             $specs
             (str-slice $pending $close-end (str-length $pending))
             CodexInlineHiddenTagParserInactive)
           $visible-text
           (codex:stream-parser-list-append
             $extracted
             ((codex:inline-hidden-tag-extracted
                $tag
                (str-concat
                  $content
                  (str-slice $pending 0 $close-index)))))))))))

(= (codex:inline-hidden-tag-parser-finish
      (CodexInlineHiddenTagParser
        $specs
        $pending
        CodexInlineHiddenTagParserInactive))
   (codex:inline-hidden-tag-parser-output
     (CodexInlineHiddenTagParser
       $specs
       ""
       CodexInlineHiddenTagParserInactive)
     $pending
     ()))

(= (codex:inline-hidden-tag-parser-finish
      (CodexInlineHiddenTagParser
        $specs
        $pending
        (CodexInlineHiddenTagParserActive $tag $close $content)))
   (codex:inline-hidden-tag-parser-output
     (CodexInlineHiddenTagParser
       $specs
       ""
       CodexInlineHiddenTagParserInactive)
     ""
     ((codex:inline-hidden-tag-extracted
        $tag
        (str-concat $content $pending)))))

(= (codex:inline-hidden-tag-parser-collect-chunks $parser $chunks)
   (codex:inline-hidden-tag-parser-collect-chunks-loop
     $parser
     $chunks
     ""
     ()))

(= (codex:inline-hidden-tag-parser-collect-chunks-loop $parser () $visible-text $extracted)
   (case (codex:inline-hidden-tag-parser-finish $parser)
     (((CodexInlineHiddenTagParserOutput $next-parser $tail-visible $tail-extracted)
       (codex:inline-hidden-tag-parser-output
         $next-parser
         (str-concat $visible-text $tail-visible)
         (codex:stream-parser-list-append
           $extracted
           $tail-extracted))))))

(= (codex:inline-hidden-tag-parser-collect-chunks-loop $parser $chunks $visible-text $extracted)
   (let ($head $tail) (decons-atom $chunks)
     (case (codex:inline-hidden-tag-parser-push-str $parser $head)
       (((CodexInlineHiddenTagParserOutput $next-parser $next-visible $next-extracted)
         (codex:inline-hidden-tag-parser-collect-chunks-loop
           $next-parser
           $tail
           (str-concat $visible-text $next-visible)
           (codex:stream-parser-list-append
             $extracted
             $next-extracted)))))))

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

(= (codex:proposed-plan-parser-inactive)
   CodexProposedPlanParserInactive)

(= (codex:proposed-plan-parser-active)
   CodexProposedPlanParserActive)

(= (codex:proposed-plan-parser-state $active $detect-tag $line-buffer)
   (CodexProposedPlanParser $active $detect-tag $line-buffer))

(= (codex:proposed-plan-parser-new)
   (codex:proposed-plan-parser-state
     (codex:proposed-plan-parser-inactive)
     True
     ""))

(= (codex:proposed-plan-segment-normal $text)
   (CodexProposedPlanSegmentNormal $text))

(= (codex:proposed-plan-segment-start)
   CodexProposedPlanSegmentStart)

(= (codex:proposed-plan-segment-delta $text)
   (CodexProposedPlanSegmentDelta $text))

(= (codex:proposed-plan-segment-end)
   CodexProposedPlanSegmentEnd)

(= (codex:proposed-plan-parser-output $parser $visible-text $segments)
   (CodexProposedPlanParserOutput
     $parser
     $visible-text
     $segments))

(= (codex:proposed-plan-parser-output-parser
      (CodexProposedPlanParserOutput $parser $visible-text $segments))
   $parser)

(= (codex:proposed-plan-parser-output-visible-text
      (CodexProposedPlanParserOutput $parser $visible-text $segments))
   $visible-text)

(= (codex:proposed-plan-parser-output-segments
      (CodexProposedPlanParserOutput $parser $visible-text $segments))
   $segments)

(= (codex:proposed-plan-parser-push-nonempty-normal () $text)
   ((codex:proposed-plan-segment-normal $text)))

(= (codex:proposed-plan-parser-push-nonempty-normal $segments $text)
   (let ($head $tail) (decons-atom $segments)
     (if (== $tail ())
         (case $head
           (((CodexProposedPlanSegmentNormal $existing)
             ((codex:proposed-plan-segment-normal
                (str-concat $existing $text))))
            ($other
             (cons-atom
               $other
               ((codex:proposed-plan-segment-normal $text))))))
         (cons-atom
           $head
           (codex:proposed-plan-parser-push-nonempty-normal
             $tail
             $text)))))

(= (codex:proposed-plan-parser-push-normal $segments $text)
   (if (== $text "")
       $segments
       (codex:proposed-plan-parser-push-nonempty-normal $segments $text)))

(= (codex:proposed-plan-parser-push-nonempty-delta () $text)
   ((codex:proposed-plan-segment-delta $text)))

(= (codex:proposed-plan-parser-push-nonempty-delta $segments $text)
   (let ($head $tail) (decons-atom $segments)
     (if (== $tail ())
         (case $head
           (((CodexProposedPlanSegmentDelta $existing)
             ((codex:proposed-plan-segment-delta
                (str-concat $existing $text))))
            ($other
             (cons-atom
               $other
               ((codex:proposed-plan-segment-delta $text))))))
         (cons-atom
           $head
           (codex:proposed-plan-parser-push-nonempty-delta
             $tail
             $text)))))

(= (codex:proposed-plan-parser-push-delta $segments $text)
   (if (== $text "")
       $segments
       (codex:proposed-plan-parser-push-nonempty-delta $segments $text)))

(= (codex:proposed-plan-parser-push-start $segments)
   (codex:stream-parser-list-append
     $segments
     ((codex:proposed-plan-segment-start))))

(= (codex:proposed-plan-parser-push-end $segments)
   (codex:stream-parser-list-append
     $segments
     ((codex:proposed-plan-segment-end))))

(= (codex:proposed-plan-parser-push-text
      CodexProposedPlanParserInactive
      $visible-text
      $segments
      $text)
   (codex:proposed-plan-parser-output
     (codex:proposed-plan-parser-new)
     (str-concat $visible-text $text)
     (codex:proposed-plan-parser-push-normal $segments $text)))

(= (codex:proposed-plan-parser-push-text
      CodexProposedPlanParserActive
      $visible-text
      $segments
      $text)
   (codex:proposed-plan-parser-output
     (codex:proposed-plan-parser-new)
     $visible-text
     (codex:proposed-plan-parser-push-delta $segments $text)))

(= (codex:proposed-plan-parser-is-tag-prefix $slug)
   (let $trimmed (str-trim $slug)
     (or (str-starts-with? (codex:stream-parser-plan-open-tag) $trimmed)
         (str-starts-with? (codex:stream-parser-plan-close-tag) $trimmed))))

(= (codex:proposed-plan-parser-finish-line
      (CodexProposedPlanParser CodexProposedPlanParserInactive $detect-tag $line-buffer)
      $line-without-newline
      $visible-text
      $segments)
   (let $line-text (str-concat $line-without-newline "\n")
     (let $slug (codex:stream-parser-plan-slug $line-without-newline)
       (if (== $slug (codex:stream-parser-plan-open-tag))
           (codex:proposed-plan-parser-output
             (CodexProposedPlanParser
               CodexProposedPlanParserActive
               True
               "")
             $visible-text
             (codex:proposed-plan-parser-push-start $segments))
           (case
             (codex:proposed-plan-parser-push-text
               CodexProposedPlanParserInactive
               $visible-text
               $segments
               $line-text)
             (((CodexProposedPlanParserOutput $ignored-parser $next-visible $next-segments)
               (codex:proposed-plan-parser-output
                 (CodexProposedPlanParser
                   CodexProposedPlanParserInactive
                   True
                   "")
                 $next-visible
                 $next-segments))))))))

(= (codex:proposed-plan-parser-finish-line
      (CodexProposedPlanParser CodexProposedPlanParserActive $detect-tag $line-buffer)
      $line-without-newline
      $visible-text
      $segments)
   (let $line-text (str-concat $line-without-newline "\n")
     (let $slug (codex:stream-parser-plan-slug $line-without-newline)
       (if (== $slug (codex:stream-parser-plan-close-tag))
           (codex:proposed-plan-parser-output
             (CodexProposedPlanParser
               CodexProposedPlanParserInactive
               True
               "")
             $visible-text
             (codex:proposed-plan-parser-push-end $segments))
           (case
             (codex:proposed-plan-parser-push-text
               CodexProposedPlanParserActive
               $visible-text
               $segments
               $line-text)
             (((CodexProposedPlanParserOutput $ignored-parser $next-visible $next-segments)
               (codex:proposed-plan-parser-output
                 (CodexProposedPlanParser
                   CodexProposedPlanParserActive
                   True
                   "")
                 $next-visible
                 $next-segments))))))))

(= (codex:proposed-plan-parser-process-part
      (CodexProposedPlanParser $active True $line-buffer)
      $part
      True
      $visible-text
      $segments)
   (codex:proposed-plan-parser-finish-line
     (CodexProposedPlanParser
       $active
       True
       "")
     (str-concat $line-buffer $part)
     $visible-text
     $segments))

(= (codex:proposed-plan-parser-process-part
      (CodexProposedPlanParser $active True $line-buffer)
      $part
      False
      $visible-text
      $segments)
   (let $next-buffer (str-concat $line-buffer $part)
     (let $slug (codex:stream-parser-plan-slug $next-buffer)
       (if (or (== $slug "")
               (codex:proposed-plan-parser-is-tag-prefix $slug))
           (codex:proposed-plan-parser-output
             (CodexProposedPlanParser
               $active
               True
               $next-buffer)
             $visible-text
             $segments)
           (case
             (codex:proposed-plan-parser-push-text
               $active
               $visible-text
               $segments
               $next-buffer)
             (((CodexProposedPlanParserOutput $ignored-parser $next-visible $next-segments)
               (codex:proposed-plan-parser-output
                 (CodexProposedPlanParser
                   $active
                   False
                   "")
                 $next-visible
                 $next-segments))))))))

(= (codex:proposed-plan-parser-process-part
      (CodexProposedPlanParser $active False $line-buffer)
      $part
      True
      $visible-text
      $segments)
   (case
     (codex:proposed-plan-parser-push-text
       $active
       $visible-text
       $segments
       (str-concat $part "\n"))
     (((CodexProposedPlanParserOutput $ignored-parser $next-visible $next-segments)
       (codex:proposed-plan-parser-output
         (CodexProposedPlanParser
           $active
           True
           "")
         $next-visible
         $next-segments)))))

(= (codex:proposed-plan-parser-process-part
      (CodexProposedPlanParser $active False $line-buffer)
      $part
      False
      $visible-text
      $segments)
   (case
     (codex:proposed-plan-parser-push-text
       $active
       $visible-text
       $segments
       $part)
     (((CodexProposedPlanParserOutput $ignored-parser $next-visible $next-segments)
       (codex:proposed-plan-parser-output
         (CodexProposedPlanParser
           $active
           False
           "")
         $next-visible
         $next-segments)))))

(= (codex:proposed-plan-parser-process-parts $parser () $visible-text $segments)
   (codex:proposed-plan-parser-output $parser $visible-text $segments))

(= (codex:proposed-plan-parser-process-parts $parser $parts $visible-text $segments)
   (let ($head $tail) (decons-atom $parts)
     (case
       (codex:proposed-plan-parser-process-part
         $parser
         $head
         (not (== $tail ()))
         $visible-text
         $segments)
       (((CodexProposedPlanParserOutput $next-parser $next-visible $next-segments)
         (codex:proposed-plan-parser-process-parts
           $next-parser
           $tail
           $next-visible
           $next-segments))))))

(= (codex:proposed-plan-parser-push-str
      (CodexProposedPlanParser $active $detect-tag $line-buffer)
      $chunk)
   (codex:proposed-plan-parser-process-parts
     (CodexProposedPlanParser $active $detect-tag $line-buffer)
     (str-split "\n" $chunk)
     ""
     ()))

(= (codex:proposed-plan-parser-finish-line-buffer
      (CodexProposedPlanParser $active $detect-tag $line-buffer)
      $visible-text
      $segments)
   (if (== $line-buffer "")
       (codex:proposed-plan-parser-output
         (CodexProposedPlanParser $active True "")
         $visible-text
         $segments)
       (let $slug (codex:stream-parser-plan-slug $line-buffer)
         (if (and (== $active CodexProposedPlanParserInactive)
                  (== $slug (codex:stream-parser-plan-open-tag)))
             (codex:proposed-plan-parser-output
               (CodexProposedPlanParser
                 CodexProposedPlanParserActive
                 True
                 "")
               $visible-text
               (codex:proposed-plan-parser-push-start $segments))
             (if (and (== $active CodexProposedPlanParserActive)
                      (== $slug (codex:stream-parser-plan-close-tag)))
                 (codex:proposed-plan-parser-output
                   (CodexProposedPlanParser
                     CodexProposedPlanParserInactive
                     True
                     "")
                   $visible-text
                   (codex:proposed-plan-parser-push-end $segments))
                 (case
                   (codex:proposed-plan-parser-push-text
                     $active
                     $visible-text
                     $segments
                     $line-buffer)
                   (((CodexProposedPlanParserOutput $ignored-parser $next-visible $next-segments)
                     (codex:proposed-plan-parser-output
                       (CodexProposedPlanParser
                         $active
                         True
                         "")
                       $next-visible
                       $next-segments)))))))))

(= (codex:proposed-plan-parser-finish $parser)
   (case
     (codex:proposed-plan-parser-finish-line-buffer $parser "" ())
     (((CodexProposedPlanParserOutput
         (CodexProposedPlanParser CodexProposedPlanParserInactive $detect-tag $line-buffer)
         $visible-text
         $segments)
       (codex:proposed-plan-parser-output
         (codex:proposed-plan-parser-new)
         $visible-text
         $segments))
      ((CodexProposedPlanParserOutput
         (CodexProposedPlanParser CodexProposedPlanParserActive $detect-tag $line-buffer)
         $visible-text
         $segments)
       (codex:proposed-plan-parser-output
         (codex:proposed-plan-parser-new)
         $visible-text
         (codex:proposed-plan-parser-push-end $segments))))))

(= (codex:proposed-plan-parser-collect-chunks $chunks)
   (codex:proposed-plan-parser-collect-chunks-loop
     (codex:proposed-plan-parser-new)
     $chunks
     ""
     ()))

(= (codex:proposed-plan-parser-collect-chunks-loop $parser () $visible-text $segments)
   (case (codex:proposed-plan-parser-finish $parser)
     (((CodexProposedPlanParserOutput $next-parser $tail-visible $tail-segments)
       (codex:proposed-plan-parser-output
         $next-parser
         (str-concat $visible-text $tail-visible)
         (codex:stream-parser-list-append
           $segments
           $tail-segments))))))

(= (codex:proposed-plan-parser-collect-chunks-loop $parser $chunks $visible-text $segments)
   (let ($head $tail) (decons-atom $chunks)
     (case (codex:proposed-plan-parser-push-str $parser $head)
       (((CodexProposedPlanParserOutput $next-parser $next-visible $next-segments)
         (codex:proposed-plan-parser-collect-chunks-loop
           $next-parser
           $tail
           (str-concat $visible-text $next-visible)
           (codex:stream-parser-list-append
             $segments
             $next-segments)))))))

(= (codex:strip-proposed-plan-blocks $text)
   (codex:proposed-plan-parser-output-visible-text
     (codex:proposed-plan-parser-collect-chunks ($text))))

(= (codex:stream-parser-extract-plan-segments () $saw-plan $plan-text)
   (if $saw-plan $plan-text CodexAbsent))

(= (codex:stream-parser-extract-plan-segments $segments $saw-plan $plan-text)
   (let ($head $tail) (decons-atom $segments)
     (case $head
       ((CodexProposedPlanSegmentStart
         (codex:stream-parser-extract-plan-segments $tail True ""))
        ((CodexProposedPlanSegmentDelta $delta)
         (codex:stream-parser-extract-plan-segments
           $tail
           $saw-plan
           (str-concat $plan-text $delta)))
        (CodexProposedPlanSegmentEnd
         (codex:stream-parser-extract-plan-segments
           $tail
           $saw-plan
           $plan-text))
        ((CodexProposedPlanSegmentNormal $normal)
         (codex:stream-parser-extract-plan-segments
           $tail
           $saw-plan
           $plan-text))))))

(= (codex:extract-proposed-plan-text $text)
   (codex:stream-parser-extract-plan-segments
     (codex:proposed-plan-parser-output-segments
       (codex:proposed-plan-parser-collect-chunks ($text)))
     False
     ""))
