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
