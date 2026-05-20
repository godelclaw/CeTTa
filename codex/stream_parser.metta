; Rust-faithful assistant stream markup helpers.
;
; This ports the complete-string helper behavior from:
; - openai-codex/codex-rs/utils/stream-parser/src/citation.rs
; - openai-codex/codex-rs/utils/stream-parser/src/inline_hidden_tag.rs
; - openai-codex/codex-rs/utils/stream-parser/src/tagged_line_parser.rs
; - openai-codex/codex-rs/utils/stream-parser/src/proposed_plan.rs
; - openai-codex/codex-rs/utils/stream-parser/src/assistant_text.rs
; - openai-codex/codex-rs/utils/stream-parser/src/stream_text.rs
; - openai-codex/codex-rs/utils/stream-parser/src/utf8_stream.rs
;
; Covered in this increment:
; - StreamTextChunk helper surface for wrapped stream parsers
; - InlineHiddenTagParser push_str / finish semantics for literal tag specs
; - TaggedLineParser parse / finish semantics for generic tag specs
; - CitationStreamParser push_str / finish semantics for the citation tag
; - ProposedPlanParser push_str / finish semantics for the proposed_plan tag
; - AssistantTextStreamParser push_str / finish composition
; - Utf8StreamParser push_bytes / finish / into_inner semantics
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
; - Rust mutates `TaggedLineParser<T>` in place. CeTTa returns an explicit next
;   parser state with each segment batch. The tag-spec ordering, line buffering,
;   segment merging, and EOF auto-close behavior match Rust.
; - Rust's `strip_proposed_plan_blocks` reads `visible_text` from mapped
;   `ProposedPlanSegment::Normal` segments. CeTTa's one-shot helper reads the
;   same normal text directly from the tagged-line segments so the helper
;   reduces reliably when imported through stream-events surfaces.
; - Rust mutates `AssistantTextStreamParser` in place. CeTTa returns an
;   explicit next parser state together with the assistant text chunk. Citation
;   parsing, optional plan parsing, and finish flushing follow the Rust order.
; - Rust's `Utf8StreamParser<P>` mutates the wrapped parser and returns
;   `Result<StreamTextChunk<_>, Utf8StreamParserError>`. CeTTa represents raw
;   bytes as integer byte lists and returns an explicit next parser state on
;   both Ok and Err results so callers can continue from the same rolled-back
;   state Rust would leave in the mutable parser. Valid UTF-8 is decoded through
;   the CeTTa string library before being pushed into the wrapped text parser.
;   Current CeTTa strings are C strings, so embedded NUL bytes cannot be
;   represented and are reported as invalid byte sequences; non-NUL UTF-8 chunk
;   boundary, rollback, and EOF behavior match Rust.

!(import! &self list)
!(import! &self str)

(= (codex:stream-parser-string-from-utf8-bytes $bytes)
   (function
     (case (__cetta_lib_str_base64_encode "__from_utf8_bytes" $bytes)
       (($result (return $result))))))

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

(= (codex:stream-parser-list-take $items $count)
   (if (or (== $items ()) (<= $count 0))
       ()
       (let $head (list:first $items)
         (let $tail (list:rest $items)
           (let $next-count (eval (- $count 1))
             (case
               (codex:stream-parser-list-take $tail $next-count)
               (($rest
                 (cons-atom $head $rest)))))))))

(= (codex:stream-parser-list-drop $items $count)
   (if (or (== $items ()) (<= $count 0))
       $items
       (let $next-count (eval (- $count 1))
         (codex:stream-parser-list-drop
           (list:rest $items)
           $next-count))))

(= (codex:stream-text-chunk $visible-text $extracted)
   (CodexStreamTextChunk $visible-text $extracted))

(= (codex:stream-text-chunk-visible-text
      (CodexStreamTextChunk $visible-text $extracted))
   $visible-text)

(= (codex:stream-text-chunk-extracted
      (CodexStreamTextChunk $visible-text $extracted))
   $extracted)

(= (codex:stream-text-chunk-is-empty
      (CodexStreamTextChunk $visible-text $extracted))
   (and (== $visible-text "") (== $extracted ())))

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

(= (codex:tagged-line-spec $tag $open $close)
   (CodexTaggedLineSpec $tag $open $close))

(= (codex:tagged-line-parser-inactive)
   CodexTaggedLineParserInactive)

(= (codex:tagged-line-parser-active $tag)
   (CodexTaggedLineParserActive $tag))

(= (codex:tagged-line-parser-state $specs $active $detect-tag $line-buffer)
   (CodexTaggedLineParser $specs $active $detect-tag $line-buffer))

(= (codex:tagged-line-parser-new $specs)
   (codex:tagged-line-parser-state
     $specs
     (codex:tagged-line-parser-inactive)
     True
     ""))

(= (codex:tagged-line-segment-normal $text)
   (CodexTaggedLineSegmentNormal $text))

(= (codex:tagged-line-segment-start $tag)
   (CodexTaggedLineSegmentStart $tag))

(= (codex:tagged-line-segment-delta $tag $text)
   (CodexTaggedLineSegmentDelta $tag $text))

(= (codex:tagged-line-segment-end $tag)
   (CodexTaggedLineSegmentEnd $tag))

(= (codex:tagged-line-parser-output $parser $segments)
   (CodexTaggedLineParserOutput $parser $segments))

(= (codex:tagged-line-parser-output-parser
      (CodexTaggedLineParserOutput $parser $segments))
   $parser)

(= (codex:tagged-line-parser-output-segments
      (CodexTaggedLineParserOutput $parser $segments))
   $segments)

(= (codex:tagged-line-parser-match $tag)
   (CodexTaggedLineParserMatch $tag))

(= (codex:tagged-line-parser-push-nonempty-normal () $text)
   ((codex:tagged-line-segment-normal $text)))

(= (codex:tagged-line-parser-push-nonempty-normal $segments $text)
   (let ($head $tail) (decons-atom $segments)
     (if (== $tail ())
         (case $head
           (((CodexTaggedLineSegmentNormal $existing)
             ((codex:tagged-line-segment-normal
                (str-concat $existing $text))))
            ($other
             (cons-atom
               $other
               ((codex:tagged-line-segment-normal $text))))))
         (cons-atom
           $head
           (codex:tagged-line-parser-push-nonempty-normal
             $tail
             $text)))))

(= (codex:tagged-line-parser-push-normal $segments $text)
   (if (== $text "")
       $segments
       (codex:tagged-line-parser-push-nonempty-normal $segments $text)))

(= (codex:tagged-line-parser-push-nonempty-delta () $tag $text)
   ((codex:tagged-line-segment-delta $tag $text)))

(= (codex:tagged-line-parser-push-nonempty-delta $segments $tag $text)
   (let ($head $tail) (decons-atom $segments)
     (if (== $tail ())
         (case $head
           (((CodexTaggedLineSegmentDelta $existing-tag $existing)
             (if (== $existing-tag $tag)
                 ((codex:tagged-line-segment-delta
                    $tag
                    (str-concat $existing $text)))
                 (cons-atom
                   $head
                   ((codex:tagged-line-segment-delta $tag $text)))))
            ($other
             (cons-atom
               $other
               ((codex:tagged-line-segment-delta $tag $text))))))
         (cons-atom
           $head
           (codex:tagged-line-parser-push-nonempty-delta
             $tail
             $tag
             $text)))))

(= (codex:tagged-line-parser-push-delta $segments $tag $text)
   (if (== $text "")
       $segments
       (codex:tagged-line-parser-push-nonempty-delta $segments $tag $text)))

(= (codex:tagged-line-parser-push-start $segments $tag)
   (codex:stream-parser-list-append
     $segments
     ((codex:tagged-line-segment-start $tag))))

(= (codex:tagged-line-parser-push-end $segments $tag)
   (codex:stream-parser-list-append
     $segments
     ((codex:tagged-line-segment-end $tag))))

(= (codex:tagged-line-parser-push-text
      CodexTaggedLineParserInactive
      $segments
      $text)
   (codex:tagged-line-parser-push-normal $segments $text))

(= (codex:tagged-line-parser-push-text
      (CodexTaggedLineParserActive $tag)
      $segments
      $text)
   (codex:tagged-line-parser-push-delta $segments $tag $text))

(= (codex:tagged-line-parser-is-tag-prefix-loop $slug ())
   False)

(= (codex:tagged-line-parser-is-tag-prefix-loop $slug $specs)
   (let ($head $tail) (decons-atom $specs)
     (case $head
       (((CodexTaggedLineSpec $tag $open $close)
         (if (or (str-starts-with? $open $slug)
                 (str-starts-with? $close $slug))
             True
             (codex:tagged-line-parser-is-tag-prefix-loop
               $slug
               $tail)))))))

(= (codex:tagged-line-parser-is-tag-prefix $slug $specs)
   (codex:tagged-line-parser-is-tag-prefix-loop
     (str-trim $slug)
     $specs))

(= (codex:tagged-line-parser-match-open $slug ())
   CodexAbsent)

(= (codex:tagged-line-parser-match-open $slug $specs)
   (let ($head $tail) (decons-atom $specs)
     (case $head
       (((CodexTaggedLineSpec $tag $open $close)
         (if (== $open $slug)
             (codex:tagged-line-parser-match $tag)
             (codex:tagged-line-parser-match-open
               $slug
               $tail)))))))

(= (codex:tagged-line-parser-match-close $slug ())
   CodexAbsent)

(= (codex:tagged-line-parser-match-close $slug $specs)
   (let ($head $tail) (decons-atom $specs)
     (case $head
       (((CodexTaggedLineSpec $tag $open $close)
         (if (== $close $slug)
             (codex:tagged-line-parser-match $tag)
             (codex:tagged-line-parser-match-close
               $slug
               $tail)))))))

(= (codex:tagged-line-parser-finish-line
      (CodexTaggedLineParser $specs CodexTaggedLineParserInactive $detect-tag $line-buffer)
      $line-without-newline
      $segments)
   (let $line-text (str-concat $line-without-newline "\n")
     (let $slug (str-trim $line-without-newline)
       (case (codex:tagged-line-parser-match-open $slug $specs)
         (((CodexTaggedLineParserMatch $tag)
           (codex:tagged-line-parser-output
             (CodexTaggedLineParser
               $specs
               (codex:tagged-line-parser-active $tag)
               True
               "")
             (codex:tagged-line-parser-push-start $segments $tag)))
          (CodexAbsent
           (codex:tagged-line-parser-output
             (CodexTaggedLineParser
               $specs
               CodexTaggedLineParserInactive
               True
               "")
             (codex:tagged-line-parser-push-text
               CodexTaggedLineParserInactive
               $segments
               $line-text))))))))

(= (codex:tagged-line-parser-finish-line
      (CodexTaggedLineParser $specs (CodexTaggedLineParserActive $active-tag) $detect-tag $line-buffer)
      $line-without-newline
      $segments)
   (let $line-text (str-concat $line-without-newline "\n")
     (let $slug (str-trim $line-without-newline)
       (case (codex:tagged-line-parser-match-close $slug $specs)
         (((CodexTaggedLineParserMatch $close-tag)
           (if (== $active-tag $close-tag)
               (codex:tagged-line-parser-output
                 (CodexTaggedLineParser
                   $specs
                   CodexTaggedLineParserInactive
                   True
                   "")
                 (codex:tagged-line-parser-push-end $segments $active-tag))
               (codex:tagged-line-parser-output
                 (CodexTaggedLineParser
                   $specs
                   (CodexTaggedLineParserActive $active-tag)
                   True
                   "")
                 (codex:tagged-line-parser-push-text
                   (CodexTaggedLineParserActive $active-tag)
                   $segments
                   $line-text))))
          (CodexAbsent
           (codex:tagged-line-parser-output
             (CodexTaggedLineParser
               $specs
               (CodexTaggedLineParserActive $active-tag)
               True
               "")
             (codex:tagged-line-parser-push-text
               (CodexTaggedLineParserActive $active-tag)
               $segments
               $line-text))))))))

(= (codex:tagged-line-parser-process-part
      (CodexTaggedLineParser $specs $active True $line-buffer)
      $part
      True
      $segments)
   (codex:tagged-line-parser-finish-line
     (CodexTaggedLineParser $specs $active True "")
     (str-concat $line-buffer $part)
     $segments))

(= (codex:tagged-line-parser-process-part
      (CodexTaggedLineParser $specs $active True $line-buffer)
      $part
      False
      $segments)
   (let $next-buffer (str-concat $line-buffer $part)
     (let $slug (str-trim $next-buffer)
       (if (or (== $slug "")
               (codex:tagged-line-parser-is-tag-prefix $slug $specs))
           (codex:tagged-line-parser-output
             (CodexTaggedLineParser
               $specs
               $active
               True
               $next-buffer)
             $segments)
           (codex:tagged-line-parser-output
             (CodexTaggedLineParser
               $specs
               $active
               False
               "")
             (codex:tagged-line-parser-push-text
               $active
               $segments
               $next-buffer))))))

(= (codex:tagged-line-parser-process-part
      (CodexTaggedLineParser $specs $active False $line-buffer)
      $part
      True
      $segments)
   (codex:tagged-line-parser-output
     (CodexTaggedLineParser
       $specs
       $active
       True
       "")
     (codex:tagged-line-parser-push-text
       $active
       $segments
       (str-concat $part "\n"))))

(= (codex:tagged-line-parser-process-part
      (CodexTaggedLineParser $specs $active False $line-buffer)
      $part
      False
      $segments)
   (codex:tagged-line-parser-output
     (CodexTaggedLineParser
       $specs
       $active
       False
       "")
     (codex:tagged-line-parser-push-text
       $active
       $segments
       $part)))

(= (codex:tagged-line-parser-process-parts $parser () $segments)
   (codex:tagged-line-parser-output $parser $segments))

(= (codex:tagged-line-parser-process-parts $parser $parts $segments)
   (let ($head $tail) (decons-atom $parts)
     (case
       (codex:tagged-line-parser-process-part
         $parser
         $head
         (not (== $tail ()))
         $segments)
       (((CodexTaggedLineParserOutput $next-parser $next-segments)
         (codex:tagged-line-parser-process-parts
           $next-parser
           $tail
           $next-segments))))))

(= (codex:tagged-line-parser-push-str
      (CodexTaggedLineParser $specs $active $detect-tag $line-buffer)
      $chunk)
   (codex:tagged-line-parser-process-parts
     (CodexTaggedLineParser $specs $active $detect-tag $line-buffer)
     (str-split "\n" $chunk)
     ()))

(= (codex:tagged-line-parser-finish-line-buffer
      (CodexTaggedLineParser $specs $active $detect-tag $line-buffer)
      $segments)
   (if (== $line-buffer "")
       (codex:tagged-line-parser-output
         (CodexTaggedLineParser $specs $active True "")
         $segments)
       (let $slug (str-trim $line-buffer)
         (case $active
           ((CodexTaggedLineParserInactive
             (case (codex:tagged-line-parser-match-open $slug $specs)
               (((CodexTaggedLineParserMatch $tag)
                 (codex:tagged-line-parser-output
                   (CodexTaggedLineParser
                     $specs
                     (CodexTaggedLineParserActive $tag)
                     True
                     "")
                   (codex:tagged-line-parser-push-start $segments $tag)))
                (CodexAbsent
                 (codex:tagged-line-parser-output
                   (CodexTaggedLineParser
                     $specs
                     CodexTaggedLineParserInactive
                     True
                     "")
                   (codex:tagged-line-parser-push-text
                     CodexTaggedLineParserInactive
                     $segments
                     $line-buffer))))))
            ((CodexTaggedLineParserActive $active-tag)
             (case (codex:tagged-line-parser-match-close $slug $specs)
               (((CodexTaggedLineParserMatch $close-tag)
                 (if (== $active-tag $close-tag)
                     (codex:tagged-line-parser-output
                       (CodexTaggedLineParser
                         $specs
                         CodexTaggedLineParserInactive
                         True
                         "")
                       (codex:tagged-line-parser-push-end $segments $active-tag))
                     (codex:tagged-line-parser-output
                       (CodexTaggedLineParser
                         $specs
                         (CodexTaggedLineParserActive $active-tag)
                         True
                         "")
                       (codex:tagged-line-parser-push-text
                         (CodexTaggedLineParserActive $active-tag)
                         $segments
                         $line-buffer))))
                (CodexAbsent
                 (codex:tagged-line-parser-output
                   (CodexTaggedLineParser
                     $specs
                     (CodexTaggedLineParserActive $active-tag)
                     True
                     "")
                   (codex:tagged-line-parser-push-text
                     (CodexTaggedLineParserActive $active-tag)
                     $segments
                     $line-buffer)))))))))))

(= (codex:tagged-line-parser-finish $parser)
   (case
     (codex:tagged-line-parser-finish-line-buffer $parser ())
     (((CodexTaggedLineParserOutput
         (CodexTaggedLineParser $specs CodexTaggedLineParserInactive $detect-tag $line-buffer)
         $segments)
       (codex:tagged-line-parser-output
         (codex:tagged-line-parser-new $specs)
         $segments))
      ((CodexTaggedLineParserOutput
         (CodexTaggedLineParser $specs (CodexTaggedLineParserActive $tag) $detect-tag $line-buffer)
         $segments)
       (codex:tagged-line-parser-output
         (codex:tagged-line-parser-new $specs)
         (codex:tagged-line-parser-push-end $segments $tag))))))

(= (codex:tagged-line-parser-collect-chunks $parser $chunks)
   (codex:tagged-line-parser-collect-chunks-loop
     $parser
     $chunks
     ()))

(= (codex:tagged-line-parser-collect-chunks-loop $parser () $segments)
   (case (codex:tagged-line-parser-finish $parser)
     (((CodexTaggedLineParserOutput $next-parser $tail-segments)
       (codex:tagged-line-parser-output
         $next-parser
         (codex:stream-parser-list-append
           $segments
           $tail-segments))))))

(= (codex:tagged-line-parser-collect-chunks-loop $parser $chunks $segments)
   (let ($head $tail) (decons-atom $chunks)
     (case (codex:tagged-line-parser-push-str $parser $head)
       (((CodexTaggedLineParserOutput $next-parser $next-segments)
         (codex:tagged-line-parser-collect-chunks-loop
           $next-parser
           $tail
           (codex:stream-parser-list-append
             $segments
             $next-segments)))))))

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

(= (codex:proposed-plan-parser-tag)
   CodexProposedPlanParserTagProposedPlan)

(= (codex:proposed-plan-parser-specs)
   ((codex:tagged-line-spec
      (codex:proposed-plan-parser-tag)
      (codex:stream-parser-plan-open-tag)
      (codex:stream-parser-plan-close-tag))))

(= (codex:proposed-plan-parser-state $tagged-line-parser)
   (CodexProposedPlanParser $tagged-line-parser))

(= (codex:proposed-plan-parser-new)
   (codex:proposed-plan-parser-state
     (codex:tagged-line-parser-new
       (codex:proposed-plan-parser-specs))))

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

(= (codex:proposed-plan-parser-map-segment
      (CodexTaggedLineSegmentNormal $text))
   (codex:proposed-plan-segment-normal $text))

(= (codex:proposed-plan-parser-map-segment
      (CodexTaggedLineSegmentStart CodexProposedPlanParserTagProposedPlan))
   (codex:proposed-plan-segment-start))

(= (codex:proposed-plan-parser-map-segment
      (CodexTaggedLineSegmentDelta CodexProposedPlanParserTagProposedPlan $text))
   (codex:proposed-plan-segment-delta $text))

(= (codex:proposed-plan-parser-map-segment
      (CodexTaggedLineSegmentEnd CodexProposedPlanParserTagProposedPlan))
   (codex:proposed-plan-segment-end))

(= (codex:proposed-plan-parser-map-segments
      $parser
      ()
      $visible-text
      $segments)
   (codex:proposed-plan-parser-output $parser $visible-text $segments))

(= (codex:proposed-plan-parser-map-segments
      $parser
      $tagged-segments
      $visible-text
      $segments)
   (let ($head $tail) (decons-atom $tagged-segments)
     (case (codex:proposed-plan-parser-map-segment $head)
       (((CodexProposedPlanSegmentNormal $text)
         (codex:proposed-plan-parser-map-segments
           $parser
           $tail
           (str-concat $visible-text $text)
           (codex:stream-parser-list-append
             $segments
             ((codex:proposed-plan-segment-normal $text)))))
        ($mapped
         (codex:proposed-plan-parser-map-segments
           $parser
           $tail
           $visible-text
           (codex:stream-parser-list-append $segments ($mapped))))))))

(= (codex:proposed-plan-parser-map-tagged-output
      (CodexTaggedLineParserOutput $tagged-parser $tagged-segments))
   (codex:proposed-plan-parser-map-segments
     (codex:proposed-plan-parser-state $tagged-parser)
     $tagged-segments
     ""
     ()))

(= (codex:proposed-plan-parser-push-str
      (CodexProposedPlanParser $tagged-parser)
      $chunk)
   (codex:proposed-plan-parser-map-tagged-output
     (codex:tagged-line-parser-push-str $tagged-parser $chunk)))

(= (codex:proposed-plan-parser-finish
      (CodexProposedPlanParser $tagged-parser))
   (codex:proposed-plan-parser-map-tagged-output
     (codex:tagged-line-parser-finish $tagged-parser)))

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

(= (codex:stream-parser-visible-from-tagged-plan-segments () $visible-text)
   $visible-text)

(= (codex:stream-parser-visible-from-tagged-plan-segments $segments $visible-text)
   (let ($head $tail) (decons-atom $segments)
     (case $head
       (((CodexTaggedLineSegmentNormal $text)
         (codex:stream-parser-visible-from-tagged-plan-segments
           $tail
           (str-concat $visible-text $text)))
        ($other
         (codex:stream-parser-visible-from-tagged-plan-segments
           $tail
           $visible-text))))))

(= (codex:strip-proposed-plan-blocks $text)
   (case
     (codex:tagged-line-parser-collect-chunks
       (codex:tagged-line-parser-new
         (codex:proposed-plan-parser-specs))
       ($text))
     (((CodexTaggedLineParserOutput $parser $segments)
       (codex:stream-parser-visible-from-tagged-plan-segments $segments "")))))

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

(= (codex:assistant-text-chunk $visible-text $citations $plan-segments)
   (CodexAssistantTextChunk $visible-text $citations $plan-segments))

(= (codex:assistant-text-chunk-visible-text
      (CodexAssistantTextChunk $visible-text $citations $plan-segments))
   $visible-text)

(= (codex:assistant-text-chunk-citations
      (CodexAssistantTextChunk $visible-text $citations $plan-segments))
   $citations)

(= (codex:assistant-text-chunk-plan-segments
      (CodexAssistantTextChunk $visible-text $citations $plan-segments))
   $plan-segments)

(= (codex:assistant-text-chunk-is-empty
      (CodexAssistantTextChunk $visible-text $citations $plan-segments))
   (and (== $visible-text "")
        (and (== $citations ())
             (== $plan-segments ()))))

(= (codex:assistant-text-stream-parser-state
      $plan-mode
      $citation-parser
      $plan-parser)
   (CodexAssistantTextStreamParser $plan-mode $citation-parser $plan-parser))

(= (codex:assistant-text-stream-parser-new $plan-mode)
   (codex:assistant-text-stream-parser-state
     $plan-mode
     (codex:citation-stream-parser-new)
     (codex:proposed-plan-parser-new)))

(= (codex:assistant-text-stream-parser-output $parser $chunk)
   (CodexAssistantTextStreamParserOutput $parser $chunk))

(= (codex:assistant-text-stream-parser-output-parser
      (CodexAssistantTextStreamParserOutput $parser $chunk))
   $parser)

(= (codex:assistant-text-stream-parser-output-chunk
      (CodexAssistantTextStreamParserOutput $parser $chunk))
   $chunk)

(= (codex:assistant-text-stream-parser-output-visible-text $output)
   (codex:assistant-text-chunk-visible-text
     (codex:assistant-text-stream-parser-output-chunk $output)))

(= (codex:assistant-text-stream-parser-output-citations $output)
   (codex:assistant-text-chunk-citations
     (codex:assistant-text-stream-parser-output-chunk $output)))

(= (codex:assistant-text-stream-parser-output-plan-segments $output)
   (codex:assistant-text-chunk-plan-segments
     (codex:assistant-text-stream-parser-output-chunk $output)))

(= (codex:assistant-text-stream-parser-output-is-empty $output)
   (codex:assistant-text-chunk-is-empty
     (codex:assistant-text-stream-parser-output-chunk $output)))

(= (codex:assistant-text-stream-parser-parse-visible-text
      (CodexAssistantTextStreamParser False $citation-parser $plan-parser)
      $visible-text
      $citations)
   (codex:assistant-text-stream-parser-output
     (CodexAssistantTextStreamParser False $citation-parser $plan-parser)
     (codex:assistant-text-chunk $visible-text $citations ())))

(= (codex:assistant-text-stream-parser-parse-visible-text
      (CodexAssistantTextStreamParser True $citation-parser $plan-parser)
      $visible-text
      $citations)
   (case (codex:proposed-plan-parser-push-str $plan-parser $visible-text)
     (((CodexProposedPlanParserOutput $next-plan-parser $next-visible $plan-segments)
       (codex:assistant-text-stream-parser-output
         (CodexAssistantTextStreamParser True $citation-parser $next-plan-parser)
         (codex:assistant-text-chunk
           $next-visible
           $citations
           $plan-segments))))))

(= (codex:assistant-text-stream-parser-push-str
      (CodexAssistantTextStreamParser $plan-mode $citation-parser $plan-parser)
      $chunk)
   (case (codex:citation-stream-parser-push-str $citation-parser $chunk)
     (((CodexCitationStreamParserOutput $next-citation-parser $visible-text $citations)
       (codex:assistant-text-stream-parser-parse-visible-text
         (CodexAssistantTextStreamParser
           $plan-mode
           $next-citation-parser
           $plan-parser)
         $visible-text
         $citations)))))

(= (codex:assistant-text-stream-parser-append-plan-tail
      (CodexAssistantTextChunk $visible-text $citations $plan-segments)
      $tail-visible
      $tail-plan-segments)
   (codex:assistant-text-chunk
     (str-concat $visible-text $tail-visible)
     $citations
     (codex:stream-parser-list-append
       $plan-segments
       $tail-plan-segments)))

(= (codex:assistant-text-stream-parser-finish-after-visible
      (CodexAssistantTextStreamParser False $citation-parser $plan-parser)
      $chunk)
   (codex:assistant-text-stream-parser-output
     (CodexAssistantTextStreamParser False $citation-parser $plan-parser)
     $chunk))

(= (codex:assistant-text-stream-parser-finish-after-visible
      (CodexAssistantTextStreamParser True $citation-parser $plan-parser)
      $chunk)
   (case (codex:proposed-plan-parser-finish $plan-parser)
     (((CodexProposedPlanParserOutput $next-plan-parser $tail-visible $tail-plan-segments)
       (codex:assistant-text-stream-parser-output
         (CodexAssistantTextStreamParser True $citation-parser $next-plan-parser)
         (codex:assistant-text-stream-parser-append-plan-tail
           $chunk
           $tail-visible
           $tail-plan-segments))))))

(= (codex:assistant-text-stream-parser-finish
      (CodexAssistantTextStreamParser $plan-mode $citation-parser $plan-parser))
   (case (codex:citation-stream-parser-finish $citation-parser)
     (((CodexCitationStreamParserOutput $next-citation-parser $visible-text $citations)
       (case
         (codex:assistant-text-stream-parser-parse-visible-text
           (CodexAssistantTextStreamParser
             $plan-mode
             $next-citation-parser
             $plan-parser)
           $visible-text
           $citations)
         (((CodexAssistantTextStreamParserOutput
             $after-visible-parser
             $chunk)
           (codex:assistant-text-stream-parser-finish-after-visible
             $after-visible-parser
             $chunk))))))))

(= (codex:stream-text-parser-output $parser $chunk)
   (CodexStreamTextParserOutput $parser $chunk))

(= (codex:stream-text-parser-output-parser
      (CodexStreamTextParserOutput $parser $chunk))
   $parser)

(= (codex:stream-text-parser-output-chunk
      (CodexStreamTextParserOutput $parser $chunk))
   $chunk)

(= (codex:stream-text-parser-push-str
      (CodexInlineHiddenTagParser $specs $pending $active)
      $text)
   (case
     (codex:inline-hidden-tag-parser-push-str
       (CodexInlineHiddenTagParser $specs $pending $active)
       $text)
     (((CodexInlineHiddenTagParserOutput $next-parser $visible-text $extracted)
       (codex:stream-text-parser-output
         $next-parser
         (codex:stream-text-chunk $visible-text $extracted))))))

(= (codex:stream-text-parser-finish
      (CodexInlineHiddenTagParser $specs $pending $active))
   (case
     (codex:inline-hidden-tag-parser-finish
       (CodexInlineHiddenTagParser $specs $pending $active))
     (((CodexInlineHiddenTagParserOutput $next-parser $visible-text $extracted)
       (codex:stream-text-parser-output
         $next-parser
         (codex:stream-text-chunk $visible-text $extracted))))))

(= (codex:stream-text-parser-push-str
      (CodexCitationStreamParser $pending $active)
      $text)
   (case
     (codex:citation-stream-parser-push-str
       (CodexCitationStreamParser $pending $active)
       $text)
     (((CodexCitationStreamParserOutput $next-parser $visible-text $extracted)
       (codex:stream-text-parser-output
         $next-parser
         (codex:stream-text-chunk $visible-text $extracted))))))

(= (codex:stream-text-parser-finish
      (CodexCitationStreamParser $pending $active))
   (case
     (codex:citation-stream-parser-finish
       (CodexCitationStreamParser $pending $active))
     (((CodexCitationStreamParserOutput $next-parser $visible-text $extracted)
       (codex:stream-text-parser-output
         $next-parser
         (codex:stream-text-chunk $visible-text $extracted))))))

(= (codex:stream-text-parser-push-str
      (CodexProposedPlanParser $tagged-line-parser)
      $text)
   (case
     (codex:proposed-plan-parser-push-str
       (CodexProposedPlanParser $tagged-line-parser)
       $text)
     (((CodexProposedPlanParserOutput $next-parser $visible-text $extracted)
       (codex:stream-text-parser-output
         $next-parser
         (codex:stream-text-chunk $visible-text $extracted))))))

(= (codex:stream-text-parser-finish
      (CodexProposedPlanParser $tagged-line-parser))
   (case
     (codex:proposed-plan-parser-finish
       (CodexProposedPlanParser $tagged-line-parser))
     (((CodexProposedPlanParserOutput $next-parser $visible-text $extracted)
       (codex:stream-text-parser-output
         $next-parser
         (codex:stream-text-chunk $visible-text $extracted))))))

(= (codex:utf8-byte-is-continuation $byte)
   (and (>= $byte 128) (<= $byte 191)))

(= (codex:utf8-byte-list-has-at-least $bytes $count)
   (>= (list:len $bytes) $count))

(= (codex:utf8-codepoint-valid $len)
   (CodexUtf8CodepointValid $len))

(= (codex:utf8-codepoint-invalid $error-len)
   (CodexUtf8CodepointInvalid $error-len))

(= (codex:utf8-codepoint-incomplete)
   CodexUtf8CodepointIncomplete)

(= (codex:utf8-codepoint-status-2 $bytes)
   (if (not (codex:utf8-byte-list-has-at-least $bytes 2))
       (codex:utf8-codepoint-incomplete)
       (let $b2 (list:at $bytes 1)
         (if (codex:utf8-byte-is-continuation $b2)
             (codex:utf8-codepoint-valid 2)
             (codex:utf8-codepoint-invalid 1)))))

(= (codex:utf8-codepoint-status-e0 $bytes)
   (if (not (codex:utf8-byte-list-has-at-least $bytes 2))
       (codex:utf8-codepoint-incomplete)
       (let $b2 (list:at $bytes 1)
         (if (not (and (>= $b2 160) (<= $b2 191)))
             (codex:utf8-codepoint-invalid 1)
             (if (not (codex:utf8-byte-list-has-at-least $bytes 3))
                 (codex:utf8-codepoint-incomplete)
                 (let $b3 (list:at $bytes 2)
                   (if (codex:utf8-byte-is-continuation $b3)
                       (codex:utf8-codepoint-valid 3)
                       (codex:utf8-codepoint-invalid 1))))))))

(= (codex:utf8-codepoint-status-3-cont $bytes)
   (if (not (codex:utf8-byte-list-has-at-least $bytes 2))
       (codex:utf8-codepoint-incomplete)
       (let $b2 (list:at $bytes 1)
         (if (not (codex:utf8-byte-is-continuation $b2))
             (codex:utf8-codepoint-invalid 1)
             (if (not (codex:utf8-byte-list-has-at-least $bytes 3))
                 (codex:utf8-codepoint-incomplete)
                 (let $b3 (list:at $bytes 2)
                   (if (codex:utf8-byte-is-continuation $b3)
                       (codex:utf8-codepoint-valid 3)
                       (codex:utf8-codepoint-invalid 1))))))))

(= (codex:utf8-codepoint-status-ed $bytes)
   (if (not (codex:utf8-byte-list-has-at-least $bytes 2))
       (codex:utf8-codepoint-incomplete)
       (let $b2 (list:at $bytes 1)
         (if (not (and (>= $b2 128) (<= $b2 159)))
             (codex:utf8-codepoint-invalid 1)
             (if (not (codex:utf8-byte-list-has-at-least $bytes 3))
                 (codex:utf8-codepoint-incomplete)
                 (let $b3 (list:at $bytes 2)
                   (if (codex:utf8-byte-is-continuation $b3)
                       (codex:utf8-codepoint-valid 3)
                       (codex:utf8-codepoint-invalid 1))))))))

(= (codex:utf8-codepoint-status-f0 $bytes)
   (if (not (codex:utf8-byte-list-has-at-least $bytes 2))
       (codex:utf8-codepoint-incomplete)
       (let $b2 (list:at $bytes 1)
         (if (not (and (>= $b2 144) (<= $b2 191)))
             (codex:utf8-codepoint-invalid 1)
             (codex:utf8-codepoint-status-4-tail $bytes)))))

(= (codex:utf8-codepoint-status-4-cont $bytes)
   (if (not (codex:utf8-byte-list-has-at-least $bytes 2))
       (codex:utf8-codepoint-incomplete)
       (let $b2 (list:at $bytes 1)
         (if (not (codex:utf8-byte-is-continuation $b2))
             (codex:utf8-codepoint-invalid 1)
             (codex:utf8-codepoint-status-4-tail $bytes)))))

(= (codex:utf8-codepoint-status-f4 $bytes)
   (if (not (codex:utf8-byte-list-has-at-least $bytes 2))
       (codex:utf8-codepoint-incomplete)
       (let $b2 (list:at $bytes 1)
         (if (not (and (>= $b2 128) (<= $b2 143)))
             (codex:utf8-codepoint-invalid 1)
             (codex:utf8-codepoint-status-4-tail $bytes)))))

(= (codex:utf8-codepoint-status-4-tail $bytes)
   (if (not (codex:utf8-byte-list-has-at-least $bytes 3))
       (codex:utf8-codepoint-incomplete)
       (let $b3 (list:at $bytes 2)
         (if (not (codex:utf8-byte-is-continuation $b3))
             (codex:utf8-codepoint-invalid 1)
             (if (not (codex:utf8-byte-list-has-at-least $bytes 4))
                 (codex:utf8-codepoint-incomplete)
                 (let $b4 (list:at $bytes 3)
                   (if (codex:utf8-byte-is-continuation $b4)
                       (codex:utf8-codepoint-valid 4)
                       (codex:utf8-codepoint-invalid 1))))))))

(= (codex:utf8-codepoint-status $bytes)
   (if (== $bytes ())
       (codex:utf8-codepoint-incomplete)
       (let $b1 (list:first $bytes)
         (if (== $b1 0)
             (codex:utf8-codepoint-invalid 1)
             (if (<= $b1 127)
                 (codex:utf8-codepoint-valid 1)
                 (if (and (>= $b1 194) (<= $b1 223))
                     (codex:utf8-codepoint-status-2 $bytes)
                     (if (== $b1 224)
                         (codex:utf8-codepoint-status-e0 $bytes)
                         (if (and (>= $b1 225) (<= $b1 236))
                             (codex:utf8-codepoint-status-3-cont $bytes)
                             (if (== $b1 237)
                                 (codex:utf8-codepoint-status-ed $bytes)
                                 (if (and (>= $b1 238) (<= $b1 239))
                                     (codex:utf8-codepoint-status-3-cont $bytes)
                                     (if (== $b1 240)
                                         (codex:utf8-codepoint-status-f0 $bytes)
                                         (if (and (>= $b1 241) (<= $b1 243))
                                             (codex:utf8-codepoint-status-4-cont $bytes)
                                             (if (== $b1 244)
                                                 (codex:utf8-codepoint-status-f4 $bytes)
                                                 (codex:utf8-codepoint-invalid 1))))))))))))))

(= (codex:utf8-scan-ok)
   CodexUtf8ScanOk)

(= (codex:utf8-scan-invalid $valid-up-to $error-len)
   (CodexUtf8ScanInvalid $valid-up-to $error-len))

(= (codex:utf8-scan-incomplete $valid-up-to)
   (CodexUtf8ScanIncomplete $valid-up-to))

(= (codex:utf8-scan-bytes $bytes)
   (codex:utf8-scan-bytes-from $bytes 0))

(= (codex:utf8-scan-bytes-from $bytes $offset)
   (if (== $bytes ())
       (codex:utf8-scan-ok)
       (case (codex:utf8-codepoint-status $bytes)
         (((CodexUtf8CodepointValid $len)
           (let $next-offset (eval (+ $offset $len))
             (codex:utf8-scan-bytes-from
               (codex:stream-parser-list-drop $bytes $len)
               $next-offset)))
          ((CodexUtf8CodepointInvalid $error-len)
           (codex:utf8-scan-invalid $offset $error-len))
          (CodexUtf8CodepointIncomplete
           (codex:utf8-scan-incomplete $offset))))))

(= (codex:utf8-stream-parser-error-invalid-utf8
      $valid-up-to
      $error-len)
   (CodexUtf8StreamParserErrorInvalidUtf8 $valid-up-to $error-len))

(= (codex:utf8-stream-parser-error-incomplete-utf8-at-eof)
   CodexUtf8StreamParserErrorIncompleteUtf8AtEof)

(= (codex:utf8-stream-parser-state $inner $pending-utf8)
   (CodexUtf8StreamParser $inner $pending-utf8))

(= (codex:utf8-stream-parser-new $inner)
   (codex:utf8-stream-parser-state $inner ()))

(= (codex:utf8-stream-parser-output-ok $parser $chunk)
   (CodexUtf8StreamParserOutputOk $parser $chunk))

(= (codex:utf8-stream-parser-output-err $parser $error)
   (CodexUtf8StreamParserOutputErr $parser $error))

(= (codex:utf8-stream-parser-output-kind
      (CodexUtf8StreamParserOutputOk $parser $chunk))
   ok)

(= (codex:utf8-stream-parser-output-kind
      (CodexUtf8StreamParserOutputErr $parser $error))
   err)

(= (codex:utf8-stream-parser-output-parser
      (CodexUtf8StreamParserOutputOk $parser $chunk))
   $parser)

(= (codex:utf8-stream-parser-output-parser
      (CodexUtf8StreamParserOutputErr $parser $error))
   $parser)

(= (codex:utf8-stream-parser-output-chunk
      (CodexUtf8StreamParserOutputOk $parser $chunk))
   $chunk)

(= (codex:utf8-stream-parser-output-error
      (CodexUtf8StreamParserOutputErr $parser $error))
   $error)

(= (codex:utf8-stream-parser-output-visible-text $output)
   (codex:stream-text-chunk-visible-text
     (codex:utf8-stream-parser-output-chunk $output)))

(= (codex:utf8-stream-parser-output-extracted $output)
   (codex:stream-text-chunk-extracted
     (codex:utf8-stream-parser-output-chunk $output)))

(= (codex:utf8-stream-parser-output-is-empty $output)
   (codex:stream-text-chunk-is-empty
     (codex:utf8-stream-parser-output-chunk $output)))

(= (codex:utf8-stream-parser-push-text
      (CodexUtf8StreamParser $inner $pending-utf8)
      $text
      $next-pending)
   (case (codex:stream-text-parser-push-str $inner $text)
     (((CodexStreamTextParserOutput $next-inner $chunk)
       (codex:utf8-stream-parser-output-ok
         (CodexUtf8StreamParser $next-inner $next-pending)
         $chunk)))))

(= (codex:utf8-stream-parser-push-bytes
      (CodexUtf8StreamParser $inner $pending-utf8)
      $chunk)
   (let $old-len (list:len $pending-utf8)
     (let $next-bytes
       (codex:stream-parser-list-append $pending-utf8 $chunk)
       (case (codex:utf8-scan-bytes $next-bytes)
         ((CodexUtf8ScanOk
           (codex:utf8-stream-parser-push-text
             (CodexUtf8StreamParser $inner $pending-utf8)
             (codex:stream-parser-string-from-utf8-bytes $next-bytes)
             ()))
          ((CodexUtf8ScanInvalid $valid-up-to $error-len)
           (codex:utf8-stream-parser-output-err
             (CodexUtf8StreamParser
               $inner
               (codex:stream-parser-list-take $next-bytes $old-len))
             (codex:utf8-stream-parser-error-invalid-utf8
               $valid-up-to
               $error-len)))
          ((CodexUtf8ScanIncomplete $valid-up-to)
           (if (== $valid-up-to 0)
               (codex:utf8-stream-parser-output-ok
                 (CodexUtf8StreamParser $inner $next-bytes)
                 (codex:stream-text-chunk "" ()))
               (let $valid-prefix
                 (codex:stream-parser-list-take $next-bytes $valid-up-to)
                 (codex:utf8-stream-parser-push-text
                   (CodexUtf8StreamParser $inner $pending-utf8)
                   (codex:stream-parser-string-from-utf8-bytes $valid-prefix)
                   (codex:stream-parser-list-drop
                     $next-bytes
                     $valid-up-to))))))))))

(= (codex:utf8-stream-parser-append-chunk
      (CodexStreamTextChunk $visible-text $extracted)
      (CodexStreamTextChunk $tail-visible-text $tail-extracted))
   (codex:stream-text-chunk
     (str-concat $visible-text $tail-visible-text)
     (codex:stream-parser-list-append $extracted $tail-extracted)))

(= (codex:utf8-stream-parser-finish-inner
      (CodexUtf8StreamParser $inner $pending-utf8)
      $chunk)
   (case (codex:stream-text-parser-finish $inner)
     (((CodexStreamTextParserOutput $next-inner $tail)
       (codex:utf8-stream-parser-output-ok
         (CodexUtf8StreamParser $next-inner ())
         (codex:utf8-stream-parser-append-chunk
           $chunk
           $tail))))))

(= (codex:utf8-stream-parser-finish-pending-ok
      (CodexUtf8StreamParser $inner $pending-utf8))
   (if (== $pending-utf8 ())
       (codex:utf8-stream-parser-finish-inner
         (CodexUtf8StreamParser $inner ())
         (codex:stream-text-chunk "" ()))
       (case
         (codex:stream-text-parser-push-str
           $inner
           (codex:stream-parser-string-from-utf8-bytes $pending-utf8))
         (((CodexStreamTextParserOutput $next-inner $chunk)
           (codex:utf8-stream-parser-finish-inner
             (CodexUtf8StreamParser $next-inner ())
             $chunk))))))

(= (codex:utf8-stream-parser-finish
      (CodexUtf8StreamParser $inner $pending-utf8))
   (if (== $pending-utf8 ())
       (codex:utf8-stream-parser-finish-pending-ok
         (CodexUtf8StreamParser $inner $pending-utf8))
       (case (codex:utf8-scan-bytes $pending-utf8)
         ((CodexUtf8ScanOk
           (codex:utf8-stream-parser-finish-pending-ok
             (CodexUtf8StreamParser $inner $pending-utf8)))
          ((CodexUtf8ScanInvalid $valid-up-to $error-len)
           (codex:utf8-stream-parser-output-err
             (CodexUtf8StreamParser $inner $pending-utf8)
             (codex:utf8-stream-parser-error-invalid-utf8
               $valid-up-to
               $error-len)))
          ((CodexUtf8ScanIncomplete $valid-up-to)
           (codex:utf8-stream-parser-output-err
             (CodexUtf8StreamParser $inner $pending-utf8)
             (codex:utf8-stream-parser-error-incomplete-utf8-at-eof)))))))

(= (codex:utf8-stream-parser-into-inner-output-ok $inner)
   (CodexUtf8StreamParserIntoInnerOutputOk $inner))

(= (codex:utf8-stream-parser-into-inner-output-err $error)
   (CodexUtf8StreamParserIntoInnerOutputErr $error))

(= (codex:utf8-stream-parser-into-inner-output-kind
      (CodexUtf8StreamParserIntoInnerOutputOk $inner))
   ok)

(= (codex:utf8-stream-parser-into-inner-output-kind
      (CodexUtf8StreamParserIntoInnerOutputErr $error))
   err)

(= (codex:utf8-stream-parser-into-inner-output-inner
      (CodexUtf8StreamParserIntoInnerOutputOk $inner))
   $inner)

(= (codex:utf8-stream-parser-into-inner-output-error
      (CodexUtf8StreamParserIntoInnerOutputErr $error))
   $error)

(= (codex:utf8-stream-parser-into-inner
      (CodexUtf8StreamParser $inner $pending-utf8))
   (if (== $pending-utf8 ())
       (codex:utf8-stream-parser-into-inner-output-ok $inner)
       (case (codex:utf8-scan-bytes $pending-utf8)
         ((CodexUtf8ScanOk
           (codex:utf8-stream-parser-into-inner-output-ok $inner))
          ((CodexUtf8ScanInvalid $valid-up-to $error-len)
           (codex:utf8-stream-parser-into-inner-output-err
             (codex:utf8-stream-parser-error-invalid-utf8
               $valid-up-to
               $error-len)))
          ((CodexUtf8ScanIncomplete $valid-up-to)
           (codex:utf8-stream-parser-into-inner-output-err
             (codex:utf8-stream-parser-error-incomplete-utf8-at-eof)))))))

(= (codex:utf8-stream-parser-into-inner-lossy
      (CodexUtf8StreamParser $inner $pending-utf8))
   $inner)
