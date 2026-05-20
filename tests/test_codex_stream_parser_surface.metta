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
