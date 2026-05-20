!(register-module! ../codex)
!(import! &self codex:stream_parser)

!(assertEqual
  (codex:stream-parser-strip-citations-visible
    (codex:strip-citations
      "a<oai-mem-citation>one</oai-mem-citation>b<oai-mem-citation>two</oai-mem-citation>c"))
  "abc")

!(assertEqualToResult
  (codex:stream-parser-strip-citations-citations
    (codex:strip-citations
      "a<oai-mem-citation>one</oai-mem-citation>b<oai-mem-citation>two</oai-mem-citation>c"))
  (("one" "two")))

!(assertEqual
  (codex:stream-parser-strip-citations-visible
    (codex:strip-citations "x<oai-mem-citation>y"))
  "x")

!(assertEqualToResult
  (codex:stream-parser-strip-citations-citations
    (codex:strip-citations "x<oai-mem-citation>y"))
  (("y")))

!(assertEqual
  (codex:stream-parser-strip-citations-visible
    (codex:strip-citations
      "a<oai-mem-citation>x<oai-mem-citation>y</oai-mem-citation>z</oai-mem-citation>b"))
  "az</oai-mem-citation>b")

!(assertEqualToResult
  (codex:stream-parser-strip-citations-citations
    (codex:strip-citations
      "a<oai-mem-citation>x<oai-mem-citation>y</oai-mem-citation>z</oai-mem-citation>b"))
  (("x<oai-mem-citation>y")))

!(assertEqual
  (codex:citation-stream-parser-output-visible-text
    (codex:citation-stream-parser-collect-chunks
      ("Hello <oai-mem-"
       "citation>source A</oai-mem-"
       "citation> world")))
  "Hello  world")

!(assertEqualToResult
  (codex:citation-stream-parser-output-extracted
    (codex:citation-stream-parser-collect-chunks
      ("Hello <oai-mem-"
       "citation>source A</oai-mem-"
       "citation> world")))
  (("source A")))

!(assertEqual
  (let $first
    (codex:citation-stream-parser-push-str
      (codex:citation-stream-parser-new)
      "abc <oai-mem-")
    (codex:citation-stream-parser-output-visible-text $first))
  "abc ")

!(assertEqualToResult
  (let $first
    (codex:citation-stream-parser-push-str
      (codex:citation-stream-parser-new)
      "abc <oai-mem-")
    (codex:citation-stream-parser-output-extracted $first))
  (()))

!(assertEqual
  (let $first
    (codex:citation-stream-parser-push-str
      (codex:citation-stream-parser-new)
      "abc <oai-mem-")
    (let $second
      (codex:citation-stream-parser-push-str
        (codex:citation-stream-parser-output-parser $first)
        "citation>x</oai-mem-citation>z")
      (codex:citation-stream-parser-output-visible-text $second)))
  "z")

!(assertEqualToResult
  (let $first
    (codex:citation-stream-parser-push-str
      (codex:citation-stream-parser-new)
      "abc <oai-mem-")
    (let $second
      (codex:citation-stream-parser-push-str
        (codex:citation-stream-parser-output-parser $first)
        "citation>x</oai-mem-citation>z")
      (codex:citation-stream-parser-output-extracted $second)))
  (("x")))

!(assertEqual
  (let $first
    (codex:citation-stream-parser-push-str
      (codex:citation-stream-parser-new)
      "abc <oai-mem-")
    (let $second
      (codex:citation-stream-parser-push-str
        (codex:citation-stream-parser-output-parser $first)
        "citation>x</oai-mem-citation>z")
      (codex:citation-stream-parser-output-is-empty
        (codex:citation-stream-parser-finish
          (codex:citation-stream-parser-output-parser $second)))))
  True)

!(assertEqual
  (codex:citation-stream-parser-output-visible-text
    (codex:citation-stream-parser-collect-chunks
      ("x<oai-mem-citation>source")))
  "x")

!(assertEqualToResult
  (codex:citation-stream-parser-output-extracted
    (codex:citation-stream-parser-collect-chunks
      ("x<oai-mem-citation>source")))
  (("source")))

!(assertEqual
  (codex:citation-stream-parser-output-visible-text
    (codex:citation-stream-parser-collect-chunks
      ("hello <oai-mem-")))
  "hello <oai-mem-")

!(assertEqualToResult
  (codex:citation-stream-parser-output-extracted
    (codex:citation-stream-parser-collect-chunks
      ("hello <oai-mem-")))
  (()))

!(assertEqual
  (codex:inline-hidden-tag-parser-output-visible-text
    (codex:inline-hidden-tag-parser-collect-chunks
      (codex:inline-hidden-tag-parser-new
        ((codex:inline-hidden-tag-spec CodexInlineTagA "<a>" "</a>")
         (codex:inline-hidden-tag-spec CodexInlineTagB "<b>" "</b>")))
      ("1<a>x</a>2<b>y</b>3")))
  "123")

!(assertEqualToResult
  (codex:inline-hidden-tag-parser-output-extracted
    (codex:inline-hidden-tag-parser-collect-chunks
      (codex:inline-hidden-tag-parser-new
        ((codex:inline-hidden-tag-spec CodexInlineTagA "<a>" "</a>")
         (codex:inline-hidden-tag-spec CodexInlineTagB "<b>" "</b>")))
      ("1<a>x</a>2<b>y</b>3")))
  (((CodexExtractedInlineTag CodexInlineTagA "x")
    (CodexExtractedInlineTag CodexInlineTagB "y"))))

!(assertEqual
  (codex:inline-hidden-tag-parser-output-visible-text
    (codex:inline-hidden-tag-parser-collect-chunks
      (codex:inline-hidden-tag-parser-new
        ((codex:inline-hidden-tag-spec CodexInlineTagA "<é>" "</é>")))
      ("a<" "é>中</" "é>b")))
  "ab")

!(assertEqualToResult
  (codex:inline-hidden-tag-parser-output-extracted
    (codex:inline-hidden-tag-parser-collect-chunks
      (codex:inline-hidden-tag-parser-new
        ((codex:inline-hidden-tag-spec CodexInlineTagA "<é>" "</é>")))
      ("a<" "é>中</" "é>b")))
  (((CodexExtractedInlineTag CodexInlineTagA "中"))))

!(assertEqual
  (codex:inline-hidden-tag-parser-output-visible-text
    (codex:inline-hidden-tag-parser-collect-chunks
      (codex:inline-hidden-tag-parser-new
        ((codex:inline-hidden-tag-spec CodexInlineTagA "<a>" "</a>")
         (codex:inline-hidden-tag-spec CodexInlineTagB "<ab>" "</ab>")))
      ("x<ab>y</ab>z")))
  "xz")

!(assertEqualToResult
  (codex:inline-hidden-tag-parser-output-extracted
    (codex:inline-hidden-tag-parser-collect-chunks
      (codex:inline-hidden-tag-parser-new
        ((codex:inline-hidden-tag-spec CodexInlineTagA "<a>" "</a>")
         (codex:inline-hidden-tag-spec CodexInlineTagB "<ab>" "</ab>")))
      ("x<ab>y</ab>z")))
  (((CodexExtractedInlineTag CodexInlineTagB "y"))))

!(assertEqualToResult
  (codex:inline-hidden-tag-parser-new ())
  ((Error
     (codex:inline-hidden-tag-parser-new ())
     "InlineHiddenTagParser requires at least one tag spec")))

!(assertEqualToResult
  (codex:inline-hidden-tag-parser-new
    ((codex:inline-hidden-tag-spec CodexInlineTagA "" "</a>")))
  ((Error
     (codex:inline-hidden-tag-parser-new
       ((CodexInlineHiddenTagSpec CodexInlineTagA "" "</a>")))
     "InlineHiddenTagParser requires non-empty open delimiters")))

!(assertEqualToResult
  (codex:inline-hidden-tag-parser-new
    ((codex:inline-hidden-tag-spec CodexInlineTagA "<a>" "")))
  ((Error
     (codex:inline-hidden-tag-parser-new
       ((CodexInlineHiddenTagSpec CodexInlineTagA "<a>" "")))
     "InlineHiddenTagParser requires non-empty close delimiters")))

!(assertEqualToResult
  (codex:tagged-line-parser-output-segments
    (codex:tagged-line-parser-collect-chunks
      (codex:tagged-line-parser-new
        ((codex:tagged-line-spec CodexTaggedLineBlock "<tag>" "</tag>")))
      ("<t" "ag>\nline\n</tag>\n")))
  (((CodexTaggedLineSegmentStart CodexTaggedLineBlock)
    (CodexTaggedLineSegmentDelta CodexTaggedLineBlock "line\n")
    (CodexTaggedLineSegmentEnd CodexTaggedLineBlock))))

!(assertEqualToResult
  (codex:tagged-line-parser-output-segments
    (codex:tagged-line-parser-collect-chunks
      (codex:tagged-line-parser-new
        ((codex:tagged-line-spec CodexTaggedLineBlock "<tag>" "</tag>")))
      ("<tag> extra\n")))
  (((CodexTaggedLineSegmentNormal "<tag> extra\n"))))

!(assertEqualToResult
  (codex:tagged-line-parser-output-segments
    (codex:tagged-line-parser-collect-chunks
      (codex:tagged-line-parser-new
        ((codex:tagged-line-spec CodexTaggedLineA "<a>" "</a>")
         (codex:tagged-line-spec CodexTaggedLineB "<b>" "</b>")))
      ("<a>\nA\n</a>\n<b>\nB\n</b>\n")))
  (((CodexTaggedLineSegmentStart CodexTaggedLineA)
    (CodexTaggedLineSegmentDelta CodexTaggedLineA "A\n")
    (CodexTaggedLineSegmentEnd CodexTaggedLineA)
    (CodexTaggedLineSegmentStart CodexTaggedLineB)
    (CodexTaggedLineSegmentDelta CodexTaggedLineB "B\n")
    (CodexTaggedLineSegmentEnd CodexTaggedLineB))))

!(assertEqualToResult
  (codex:tagged-line-parser-output-segments
    (codex:tagged-line-parser-collect-chunks
      (codex:tagged-line-parser-new
        ((codex:tagged-line-spec CodexTaggedLineA "<a>" "</a>")
         (codex:tagged-line-spec CodexTaggedLineB "<b>" "</b>")))
      ("<a>\n</b>\n</a>\n")))
  (((CodexTaggedLineSegmentStart CodexTaggedLineA)
    (CodexTaggedLineSegmentDelta CodexTaggedLineA "</b>\n")
    (CodexTaggedLineSegmentEnd CodexTaggedLineA))))

!(assertEqualToResult
  (codex:tagged-line-parser-output-segments
    (codex:tagged-line-parser-collect-chunks
      (codex:tagged-line-parser-new
        ((codex:tagged-line-spec CodexTaggedLineBlock "<tag>" "</tag>")))
      ("plain text\nnext\n")))
  (((CodexTaggedLineSegmentNormal "plain text\nnext\n"))))

!(assertEqual
  (codex:proposed-plan-parser-output-visible-text
    (codex:proposed-plan-parser-collect-chunks
      ("Intro text\n<prop"
       "osed_plan>\n- step 1\n"
       "</proposed_plan>\nOutro")))
  "Intro text\nOutro")

!(assertEqualToResult
  (codex:proposed-plan-parser-output-segments
    (codex:proposed-plan-parser-collect-chunks
      ("Intro text\n<prop"
       "osed_plan>\n- step 1\n"
       "</proposed_plan>\nOutro")))
  (((CodexProposedPlanSegmentNormal "Intro text\n")
    CodexProposedPlanSegmentStart
    (CodexProposedPlanSegmentDelta "- step 1\n")
    CodexProposedPlanSegmentEnd
    (CodexProposedPlanSegmentNormal "Outro"))))

!(assertEqual
  (codex:proposed-plan-parser-output-visible-text
    (codex:proposed-plan-parser-collect-chunks
      ("  <proposed_plan> extra\n")))
  "  <proposed_plan> extra\n")

!(assertEqualToResult
  (codex:proposed-plan-parser-output-segments
    (codex:proposed-plan-parser-collect-chunks
      ("  <proposed_plan> extra\n")))
  (((CodexProposedPlanSegmentNormal "  <proposed_plan> extra\n"))))

!(assertEqual
  (codex:proposed-plan-parser-output-visible-text
    (codex:proposed-plan-parser-collect-chunks
      ("<proposed_plan>\n- step 1\n")))
  "")

!(assertEqualToResult
  (codex:proposed-plan-parser-output-segments
    (codex:proposed-plan-parser-collect-chunks
      ("<proposed_plan>\n- step 1\n")))
  ((CodexProposedPlanSegmentStart
    (CodexProposedPlanSegmentDelta "- step 1\n")
    CodexProposedPlanSegmentEnd)))

!(assertEqual
  (codex:proposed-plan-parser-output-visible-text
    (codex:proposed-plan-parser-collect-chunks
      ("hello <prop")))
  "hello <prop")

!(assertEqualToResult
  (codex:proposed-plan-parser-output-segments
    (codex:proposed-plan-parser-collect-chunks
      ("hello <prop")))
  (((CodexProposedPlanSegmentNormal "hello <prop"))))

!(assertEqual
  (codex:strip-proposed-plan-blocks
    "before\n<proposed_plan>\n- step\n</proposed_plan>\nafter")
  "before\nafter")

!(assertEqual
  (codex:extract-proposed-plan-text
    "before\n<proposed_plan>\n- step\n</proposed_plan>\nafter")
  "- step\n")

!(assertEqual
  (codex:strip-proposed-plan-blocks
    "  <proposed_plan> extra\n")
  "  <proposed_plan> extra\n")

!(assertEqual
  (codex:extract-proposed-plan-text
    "no plan here")
  CodexAbsent)

!(assertEqual
  (codex:strip-proposed-plan-blocks
    "<proposed_plan>\n- step 1\n")
  "")

!(assertEqual
  (codex:extract-proposed-plan-text
    "<proposed_plan>\n- step 1\n")
  "- step 1\n")

!(assertEqual
  (let $parser
    (codex:assistant-text-stream-parser-new False)
    (let $seeded
      (codex:assistant-text-stream-parser-push-str
        $parser
        "hello <oai-mem-citation>doc")
      (codex:assistant-text-stream-parser-output-visible-text $seeded)))
  "hello ")

!(assertEqualToResult
  (let $parser
    (codex:assistant-text-stream-parser-new False)
    (let $seeded
      (codex:assistant-text-stream-parser-push-str
        $parser
        "hello <oai-mem-citation>doc")
      (codex:assistant-text-stream-parser-output-citations $seeded)))
  (()))

!(assertEqual
  (let $parser
    (codex:assistant-text-stream-parser-new False)
    (let $seeded
      (codex:assistant-text-stream-parser-push-str
        $parser
        "hello <oai-mem-citation>doc")
      (let $parsed
        (codex:assistant-text-stream-parser-push-str
          (codex:assistant-text-stream-parser-output-parser $seeded)
          "1</oai-mem-citation> world")
        (codex:assistant-text-stream-parser-output-visible-text $parsed))))
  " world")

!(assertEqualToResult
  (let $parser
    (codex:assistant-text-stream-parser-new False)
    (let $seeded
      (codex:assistant-text-stream-parser-push-str
        $parser
        "hello <oai-mem-citation>doc")
      (let $parsed
        (codex:assistant-text-stream-parser-push-str
          (codex:assistant-text-stream-parser-output-parser $seeded)
          "1</oai-mem-citation> world")
        (codex:assistant-text-stream-parser-output-citations $parsed))))
  (("doc1")))

!(assertEqual
  (let $parser
    (codex:assistant-text-stream-parser-new False)
    (let $seeded
      (codex:assistant-text-stream-parser-push-str
        $parser
        "hello <oai-mem-citation>doc")
      (let $parsed
        (codex:assistant-text-stream-parser-push-str
          (codex:assistant-text-stream-parser-output-parser $seeded)
          "1</oai-mem-citation> world")
        (codex:assistant-text-stream-parser-output-is-empty
          (codex:assistant-text-stream-parser-finish
            (codex:assistant-text-stream-parser-output-parser $parsed))))))
  True)

!(assertEqual
  (let $parser
    (codex:assistant-text-stream-parser-new True)
    (let $seeded
      (codex:assistant-text-stream-parser-push-str
        $parser
        "Intro\n<proposed")
      (codex:assistant-text-stream-parser-output-visible-text $seeded)))
  "Intro\n")

!(assertEqualToResult
  (let $parser
    (codex:assistant-text-stream-parser-new True)
    (let $seeded
      (codex:assistant-text-stream-parser-push-str
        $parser
        "Intro\n<proposed")
      (codex:assistant-text-stream-parser-output-plan-segments $seeded)))
  (((CodexProposedPlanSegmentNormal "Intro\n"))))

!(assertEqual
  (let $parser
    (codex:assistant-text-stream-parser-new True)
    (let $seeded
      (codex:assistant-text-stream-parser-push-str
        $parser
        "Intro\n<proposed")
      (let $parsed
        (codex:assistant-text-stream-parser-push-str
          (codex:assistant-text-stream-parser-output-parser $seeded)
          "_plan>\n- step <oai-mem-citation>doc</oai-mem-citation>\n")
        (codex:assistant-text-stream-parser-output-visible-text $parsed))))
  "")

!(assertEqualToResult
  (let $parser
    (codex:assistant-text-stream-parser-new True)
    (let $seeded
      (codex:assistant-text-stream-parser-push-str
        $parser
        "Intro\n<proposed")
      (let $parsed
        (codex:assistant-text-stream-parser-push-str
          (codex:assistant-text-stream-parser-output-parser $seeded)
          "_plan>\n- step <oai-mem-citation>doc</oai-mem-citation>\n")
        (codex:assistant-text-stream-parser-output-citations $parsed))))
  (("doc")))

!(assertEqualToResult
  (let $parser
    (codex:assistant-text-stream-parser-new True)
    (let $seeded
      (codex:assistant-text-stream-parser-push-str
        $parser
        "Intro\n<proposed")
      (let $parsed
        (codex:assistant-text-stream-parser-push-str
          (codex:assistant-text-stream-parser-output-parser $seeded)
          "_plan>\n- step <oai-mem-citation>doc</oai-mem-citation>\n")
        (codex:assistant-text-stream-parser-output-plan-segments $parsed))))
  ((CodexProposedPlanSegmentStart
    (CodexProposedPlanSegmentDelta "- step \n"))))

!(assertEqual
  (let $parser
    (codex:assistant-text-stream-parser-new True)
    (let $seeded
      (codex:assistant-text-stream-parser-push-str
        $parser
        "Intro\n<proposed")
      (let $parsed
        (codex:assistant-text-stream-parser-push-str
          (codex:assistant-text-stream-parser-output-parser $seeded)
          "_plan>\n- step <oai-mem-citation>doc</oai-mem-citation>\n")
        (let $tail
          (codex:assistant-text-stream-parser-push-str
            (codex:assistant-text-stream-parser-output-parser $parsed)
            "</proposed_plan>\nOutro")
          (codex:assistant-text-stream-parser-output-visible-text $tail)))))
  "Outro")

!(assertEqualToResult
  (let $parser
    (codex:assistant-text-stream-parser-new True)
    (let $seeded
      (codex:assistant-text-stream-parser-push-str
        $parser
        "Intro\n<proposed")
      (let $parsed
        (codex:assistant-text-stream-parser-push-str
          (codex:assistant-text-stream-parser-output-parser $seeded)
          "_plan>\n- step <oai-mem-citation>doc</oai-mem-citation>\n")
        (let $tail
          (codex:assistant-text-stream-parser-push-str
            (codex:assistant-text-stream-parser-output-parser $parsed)
            "</proposed_plan>\nOutro")
          (codex:assistant-text-stream-parser-output-plan-segments $tail)))))
  ((CodexProposedPlanSegmentEnd
    (CodexProposedPlanSegmentNormal "Outro"))))

!(assertEqual
  (let $parser
    (codex:assistant-text-stream-parser-new True)
    (let $seeded
      (codex:assistant-text-stream-parser-push-str
        $parser
        "Intro\n<proposed")
      (let $parsed
        (codex:assistant-text-stream-parser-push-str
          (codex:assistant-text-stream-parser-output-parser $seeded)
          "_plan>\n- step <oai-mem-citation>doc</oai-mem-citation>\n")
        (let $tail
          (codex:assistant-text-stream-parser-push-str
            (codex:assistant-text-stream-parser-output-parser $parsed)
            "</proposed_plan>\nOutro")
          (codex:assistant-text-stream-parser-output-is-empty
            (codex:assistant-text-stream-parser-finish
              (codex:assistant-text-stream-parser-output-parser $tail)))))))
  True)

(= (test:utf8-stream-parser-collect-ok $parser $chunks $visible-text $extracted)
   (if (== $chunks ())
       (case (codex:utf8-stream-parser-finish $parser)
         (((CodexUtf8StreamParserOutputOk $next-parser $chunk)
           (codex:stream-text-chunk
             (str-concat
               $visible-text
               (codex:stream-text-chunk-visible-text $chunk))
             (codex:stream-parser-list-append
               $extracted
               (codex:stream-text-chunk-extracted $chunk))))
          ((CodexUtf8StreamParserOutputErr $next-parser $error)
           (CodexTestUtf8CollectError $error))))
       (let $bytes (list:first $chunks)
         (case (codex:utf8-stream-parser-push-bytes $parser $bytes)
           (((CodexUtf8StreamParserOutputOk $next-parser $chunk)
             (test:utf8-stream-parser-collect-ok
               $next-parser
               (list:rest $chunks)
               (str-concat
                 $visible-text
                 (codex:stream-text-chunk-visible-text $chunk))
               (codex:stream-parser-list-append
                 $extracted
                 (codex:stream-text-chunk-extracted $chunk))))
            ((CodexUtf8StreamParserOutputErr $next-parser $error)
             (CodexTestUtf8CollectError $error)))))))

(= (test:utf8-citation-collect $chunks)
   (test:utf8-stream-parser-collect-ok
     (codex:utf8-stream-parser-new
       (codex:citation-stream-parser-new))
     $chunks
     ""
     ()))

!(assertEqual
  (codex:stream-text-chunk-visible-text
    (test:utf8-citation-collect
      ((65 195)
       (169 60 111 97 105 45 109 101 109 45 99 105 116 97 116 105 111 110 62 228)
       (184 173 60 47 111 97 105 45 109 101 109 45 99 105 116 97 116 105 111 110 62 90))))
  "AéZ")

!(assertEqualToResult
  (codex:stream-text-chunk-extracted
    (test:utf8-citation-collect
      ((65 195)
       (169 60 111 97 105 45 109 101 109 45 99 105 116 97 116 105 111 110 62 228)
       (184 173 60 47 111 97 105 45 109 101 109 45 99 105 116 97 116 105 111 110 62 90))))
  (("中")))

!(assertEqual
  (let $parser
    (codex:utf8-stream-parser-new
      (codex:citation-stream-parser-new))
    (let $first
      (codex:utf8-stream-parser-push-bytes $parser (195))
      (codex:utf8-stream-parser-output-is-empty $first)))
  True)

!(assertEqual
  (let $parser
    (codex:utf8-stream-parser-new
      (codex:citation-stream-parser-new))
    (let $first
      (codex:utf8-stream-parser-push-bytes $parser (195))
      (let $err
        (codex:utf8-stream-parser-push-bytes
          (codex:utf8-stream-parser-output-parser $first)
          (40))
        (codex:utf8-stream-parser-output-error $err))))
  (CodexUtf8StreamParserErrorInvalidUtf8 0 1))

!(assertEqual
  (let $parser
    (codex:utf8-stream-parser-new
      (codex:citation-stream-parser-new))
    (let $first
      (codex:utf8-stream-parser-push-bytes $parser (195))
      (let $err
        (codex:utf8-stream-parser-push-bytes
          (codex:utf8-stream-parser-output-parser $first)
          (40))
        (let $second
          (codex:utf8-stream-parser-push-bytes
            (codex:utf8-stream-parser-output-parser $err)
            (169 120))
          (codex:utf8-stream-parser-output-visible-text $second)))))
  "éx")

!(assertEqual
  (let $parser
    (codex:utf8-stream-parser-new
      (codex:citation-stream-parser-new))
    (let $err
      (codex:utf8-stream-parser-push-bytes $parser (111 107 255))
      (codex:utf8-stream-parser-output-error $err)))
  (CodexUtf8StreamParserErrorInvalidUtf8 2 1))

!(assertEqual
  (let $parser
    (codex:utf8-stream-parser-new
      (codex:citation-stream-parser-new))
    (let $err
      (codex:utf8-stream-parser-push-bytes $parser (111 107 255))
      (let $next
        (codex:utf8-stream-parser-push-bytes
          (codex:utf8-stream-parser-output-parser $err)
          (33))
        (codex:utf8-stream-parser-output-visible-text $next))))
  "!")

!(assertEqual
  (let $parser
    (codex:utf8-stream-parser-new
      (codex:citation-stream-parser-new))
    (let $out
      (codex:utf8-stream-parser-push-bytes $parser (226 130))
      (codex:utf8-stream-parser-output-is-empty $out)))
  True)

!(assertEqual
  (let $parser
    (codex:utf8-stream-parser-new
      (codex:citation-stream-parser-new))
    (let $out
      (codex:utf8-stream-parser-push-bytes $parser (226 130))
      (let $err
        (codex:utf8-stream-parser-finish
          (codex:utf8-stream-parser-output-parser $out))
        (codex:utf8-stream-parser-output-error $err))))
  CodexUtf8StreamParserErrorIncompleteUtf8AtEof)

!(assertEqual
  (let $parser
    (codex:utf8-stream-parser-new
      (codex:citation-stream-parser-new))
    (let $out
      (codex:utf8-stream-parser-push-bytes $parser (195))
      (let $inner
        (codex:utf8-stream-parser-into-inner
          (codex:utf8-stream-parser-output-parser $out))
        (codex:utf8-stream-parser-into-inner-output-error $inner))))
  CodexUtf8StreamParserErrorIncompleteUtf8AtEof)

!(assertEqual
  (let $parser
    (codex:utf8-stream-parser-new
      (codex:citation-stream-parser-new))
    (let $out
      (codex:utf8-stream-parser-push-bytes $parser (195))
      (let $inner
        (codex:utf8-stream-parser-into-inner-lossy
          (codex:utf8-stream-parser-output-parser $out))
        (let $tail
          (codex:stream-text-parser-finish $inner)
          (codex:stream-text-chunk-is-empty
            (codex:stream-text-parser-output-chunk $tail))))))
  True)

!(assertEqual
  (let $parser
    (codex:utf8-stream-parser-new
      (codex:citation-stream-parser-new))
    (let $err
      (codex:utf8-stream-parser-push-bytes $parser (0))
      (codex:utf8-stream-parser-output-error $err)))
  (CodexUtf8StreamParserErrorInvalidUtf8 0 1))
