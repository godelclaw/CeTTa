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
