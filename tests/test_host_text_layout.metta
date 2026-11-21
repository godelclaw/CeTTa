; Cross-dialect contract test for Unicode 16.0 UAX #29/#11 grapheme width,
; terminal:graphemes, text:wrap, text:render-spans, and markdown:parse
; in (library host_io).
!(import! &self (library host_io))
!(import! &self (library system))
!(import! &self (library str))

(= (tl:check $name $ok)
   (if $ok True
     (let $_ (println! (TEXT_LAYOUT_FAIL $name)) (system:exit 1))))

(= (tl:run)
   (let $esc (str:byte-slice (terminal:cpr-request) 0 1)
   ;; 1. UAX #29/#11 grapheme-aware terminal:cells
   (let $_1 (tl:check cells-ascii-cjk (== (terminal:cells "a雪") 3))
   (let $_2 (tl:check cells-combining-mark (== (terminal:cells "é") 1))
   (let $_3 (tl:check cells-zwj-family (== (terminal:cells "👨‍👩‍👧‍👦") 2))
   (let $_4 (tl:check cells-flag-cz (== (terminal:cells "🇨🇿") 2))
   (let $_5 (tl:check cells-vs16-heart (== (terminal:cells "❤️") 2))
   (let $_6 (tl:check cells-vs15-heart (== (terminal:cells "❤︎") 1))
   (let $_7 (tl:check cells-skin-tone (== (terminal:cells "👍🏽") 2))
   (let $_8 (tl:check cells-keycap (== (terminal:cells "1️⃣") 2))

   ;; 2. terminal:graphemes (exact clusters, byte offsets, widths)
   (let $gs (terminal:graphemes "a👨‍👩‍👧‍👦🇨🇿")
   (let $_9 (tl:check graphemes-count (== (size-atom $gs) 3))
   (let $_10 (tl:check graphemes-first (== (index-atom $gs 0) (HostGrapheme "a" 0 1 1)))
   (let $_11 (tl:check graphemes-second (== (index-atom $gs 1) (HostGrapheme "👨‍👩‍👧‍👦" 1 26 2)))
   (let $_12 (tl:check graphemes-third (== (index-atom $gs 2) (HostGrapheme "🇨🇿" 26 34 2)))

   ;; 3. Grapheme-safe terminal:clip (never splits inside a grapheme cluster)
   (let $_13 (tl:check clip-fits-zwj-with-ellipsis (== (terminal:clip "a👨‍👩‍👧‍👦bc" 4) "a👨‍👩‍👧‍👦…"))
   (let $_14 (tl:check clip-never-splits-zwj (== (terminal:clip "a👨‍👩‍👧‍👦b" 3) "a…"))
   (let $_15 (tl:check clip-never-splits-combining (== (terminal:clip "éx" 2) "éx"))
   (let $_16 (tl:check clip-exact-zero (== (terminal:clip "hello" 0) ""))

   ;; 4. text:wrap: word mode with indent and hanging indent + exact byte offsets
   (let $w1 (text:wrap "alpha beta gamma delta" 12 "  " "    " "word" "…")
   (let $_17 (tl:check wrap-word-rows
               (== $w1 ((TextRow "  alpha beta" 0 10 12)
                        (TextRow "    gamma" 11 16 9)
                        (TextRow "    delta" 17 22 9))))

   ;; 5. text:wrap: fold mode across wide chars and ZWJ emoji
   (let $w2 (text:wrap "a👨‍👩‍👧‍👦雪b" 4 "" "" "fold" "…")
   (let $_18 (tl:check wrap-fold-emoji
               (== $w2 ((TextRow "a👨‍👩‍👧‍👦" 0 26 3)
                        (TextRow "雪b" 26 30 3))))

   ;; 6. text:wrap: none mode (copy-safe logical lines, never inserts wrap breaks)
   (let $w3 (text:wrap "very-long-command --with-many-flags=1234567890\nsecond-line" 10 "" "  " "none" "…")
   (let $_19 (tl:check wrap-none-logical
               (== $w3 ((TextRow "very-long-command --with-many-flags=1234567890" 0 46 46)
                        (TextRow "second-line" 47 58 11))))

   ;; 7. text:wrap: crop mode with ellipsis
   (let $w4 (text:wrap "hello world wide" 8 "> " "" "crop" "…")
   (let $_20 (tl:check wrap-crop-ellipsis
               (== $w4 ((TextRow "> hello…" 0 5 8))))

   ;; 8. text:wrap: CJK natural wrapping in word mode
   (let $w5 (text:wrap "雪雪雪雪" 5 "" "" "word" "…")
   (let $_21 (tl:check wrap-word-cjk
               (== $w5 ((TextRow "雪雪" 0 6 4)
                        (TextRow "雪雪" 6 12 4))))

   ;; 9. text:render-spans: ansi16 SGR + OSC 8 + no-color suppression
   (let $spans ((TextSpan "ERR" ("bold") "red" none "")
                (TextSpan ": " () none none "")
                (TextSpan "doc" ("underline") "cyan" none "https://example.org"))
   (let $ansi (text:render-spans $spans "ansi16")
   (let $plain (text:render-spans $spans "no-color")
   (let $_22 (tl:check spans-ansi-bold-red (not (== (str:find $ansi (str:concat $esc "[1;31mERR")) (TextNotFound (str:concat $esc "[1;31mERR")))))
   (let $_23 (tl:check spans-ansi-reset (not (== (str:find $ansi (str:concat $esc "[0m: ")) (TextNotFound (str:concat $esc "[0m: ")))))
   (let $_24 (tl:check spans-ansi-osc8 (not (== (str:find $ansi (str:concat $esc "]8;;https://example.org")) (TextNotFound (str:concat $esc "]8;;https://example.org")))))
   (let $_25 (tl:check spans-no-color-no-sgr (== (str:find $plain (str:concat $esc "[")) (TextNotFound (str:concat $esc "["))))
   (let $_26 (tl:check spans-no-color-keeps-text (== (terminal:clean $plain) "ERR: doc"))

   ;; 10. markdown:parse: headings, emphasis, strong, snake_case preservation,
   ;;     code spans, links, verbatim fenced code blocks, lists, blockquotes, rules
   (let $md-src "# Title\n\nHello *em* and **strong** with `code_span` and foo_bar_baz and [site](https://a.b \"T\").\n\n```sh\necho \"raw *not em*\"\n  indent\n```\n\n- one\n- two\n\n> quoted\n\n---\n"
   (let $doc (markdown:parse $md-src)
   (let $_27 (tl:check md-is-document
               (case $doc (((MdDocument $blocks) (== (size-atom $blocks) 6)) ($other False))))
   (let (MdDocument $blocks) $doc
   (let $_28 (tl:check md-heading (== (index-atom $blocks 0) (MdHeading 1 ((MdText "Title")))))
   (let $_29 (tl:check md-paragraph-inlines
               (== (index-atom $blocks 1)
                   (MdParagraph ((MdText "Hello ")
                                 (MdEmph ((MdText "em")))
                                 (MdText " and ")
                                 (MdStrong ((MdText "strong")))
                                 (MdText " with ")
                                 (MdCode "code_span")
                                 (MdText " and foo_bar_baz and ")
                                 (MdLink "https://a.b" "T" ((MdText "site")))
                                 (MdText ".")))))
   (let $_30 (tl:check md-fenced-code-verbatim
               (== (index-atom $blocks 2)
                   (MdCodeBlock "sh" "echo \"raw *not em*\"\n  indent\n")))
   (let $_31 (tl:check md-bullet-list
               (== (index-atom $blocks 3)
                   (MdList unordered 1 ((MdItem ((MdParagraph ((MdText "one")))))
                                        (MdItem ((MdParagraph ((MdText "two")))))))))
   (let $_32 (tl:check md-blockquote
               (== (index-atom $blocks 4)
                   (MdBlockQuote ((MdParagraph ((MdText "quoted")))))))
   (let $_33 (tl:check md-thematic-break
               (== (index-atom $blocks 5) (MdThematicBreak)))

   ;; 11. Additional CommonMark constructs: Setext heading, indented code block,
   ;;     ordered list start=3, backslash escape, hard break, autolink
   (let $md2 (markdown:parse "Subhead\n-------\n\n    raw_indent()\n\n3. alpha\\*star  \n   next <https://x.y>\n")
   (let $_34 (tl:check md2-exact
               (== $md2
                   (MdDocument ((MdHeading 2 ((MdText "Subhead")))
                                (MdCodeBlock "" "raw_indent()\n")
                                (MdList ordered 3 ((MdItem ((MdParagraph ((MdText "alpha*star") (MdHardBreak) (MdText "next ") (MdLink "https://x.y" "" ((MdText "https://x.y")))))))))))))

   True)))))))))))))))))))))))))))))))))))))))))))))))))

!(let $ans (collapse (tl:run))
   (if (== $ans (True)) (println! HOST_TEXT_LAYOUT_OK) (system:exit 1)))
