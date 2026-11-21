; Cross-dialect contract test for terminal protocol primitives in (library host_io):
; - CPR decoding in buffer:input-event (whole, 1-byte-at-a-time split, prefix
;   collision with CSI 1;5D / 1;5C, trailing text, invalid/private rejection,
;   paste-mode isolation)
; - terminal:cpr-request and terminal:cpr-parse
; - terminal:sync (DEC mode 2026 synchronized output bracket)
; - terminal:hyperlink (OSC 8 with C0/DEL/C1 injection sanitization)
; - terminal:clipboard (OSC 52 RFC 4648 base64)
; - terminal:commit (atomic sync-bracketed erase, autowrap-on ?7h commit, redraw)
!(import! &self (library host_io))
!(import! &self (library system))
!(import! &self (library str))

(= (tp:check $name $ok)
   (if $ok True
     (let $_ (println! (TERM_PROTO_FAIL $name)) (system:exit 1))))

(= (tp:feed-list $buf $xs)
   (if (== $xs ()) True
     (let $ch (car-atom $xs)
       (let $rest (cdr-atom $xs)
         (let $_ (buffer:append $buf $ch)
           (let $ev (buffer:input-event $buf "wait")
             (if (== $rest ()) $ev
               (let $_2 (tp:check split-cpr-pending (== $ev HostPending))
                 (tp:feed-list $buf $rest)))))))))

(= (tp:run)
   (let $esc (terminal:cpr-request)
     (let $esc1 (str:byte-slice $esc 0 1)
     (let $_1 (tp:check cpr-request-bytes (== $esc (str:concat $esc1 "[6n")))
     (let $buf (buffer:new 4096 bytes)
     ;; 1. Whole CPR sequence + trailing text
     (let $cpr1 (str:concat $esc1 "[12;34Rabc")
     (let $_2 (buffer:append $buf $cpr1)
     (let $ev1 (buffer:input-event $buf "wait")
     (let $_3 (tp:check cpr-whole (== $ev1 (HostInput "cursor-position" "12;34")))
     (let $ev2 (buffer:input-event $buf "wait")
     (let $_4 (tp:check cpr-trailing-text (== $ev2 (HostInput "text" "abc")))

     ;; 2. Byte-by-byte split CPR colliding with CSI 1;5D / CSI 1;5C prefix
     (let $ev3 (tp:feed-list $buf ($esc1 "[" "1" ";" "5" "R"))
     (let $_5 (tp:check cpr-split-prefix-collision (== $ev3 (HostInput "cursor-position" "1;5")))

     ;; 3. Existing CSI 1;5D (word-left) still decodes unchanged
     (let $_6 (buffer:append $buf (str:concat $esc1 "[1;5D"))
     (let $ev4 (buffer:input-event $buf "wait")
     (let $_7 (tp:check csi-word-left-preserved (== $ev4 (HostInput "word-left" "")))

     ;; 4. Invalid/private CPR rejected as unknown (never misparsed as cursor-position)
     (let $_8 (buffer:append $buf (str:concat $esc1 "[0;5R"))
     (let $ev5 (buffer:input-event $buf "wait")
     (let $_9 (tp:check cpr-zero-rejected (== $ev5 (HostInput "unknown" "")))
     (let $_10 (buffer:append $buf (str:concat $esc1 "[?12;34R"))
     (let $ev6 (buffer:input-event $buf "wait")
     (let $_11 (tp:check cpr-private-rejected (== $ev6 (HostInput "unknown" "")))

     ;; 5. Bracketed paste never decodes CPR as control event
     (let $pseq (str:concat $esc1 (str:concat "[200~" (str:concat $esc1 (str:concat "[9;8R" (str:concat $esc1 "[201~")))))
     (let $_12 (buffer:append $buf $pseq)
     (let $p1 (buffer:input-event $buf "wait")
     (let $p2 (buffer:input-event $buf "wait")
     (let $p3 (buffer:input-event $buf "wait")
     (let $_13 (tp:check paste-start-ok (== $p1 (HostInput "paste-start" "")))
     (let $_14 (tp:check paste-keeps-cpr-literal (== $p2 (HostInput "paste" (str:concat $esc1 "[9;8R"))))
     (let $_15 (tp:check paste-end-ok (== $p3 (HostInput "paste-end" "")))

     ;; 6. terminal:cpr-parse (payload and raw CSI forms + invalid rejection)
     (let $_16 (tp:check cpr-parse-payload (== (terminal:cpr-parse "24;80") (HostCursor 24 80)))
     (let $_17 (tp:check cpr-parse-raw (== (terminal:cpr-parse (str:concat $esc1 "[7;15R")) (HostCursor 7 15)))
     (let $_18 (tp:check cpr-parse-invalid
                 (case (terminal:cpr-parse "0;10") (((HostFailure "cpr-parse" $_c1 $_m1) True) ($other False))))

     ;; 7. terminal:sync (DEC mode 2026)
     (let $synced (terminal:sync "FRAME")
     (let $_19 (tp:check sync-open (str:starts-with $synced (str:concat $esc1 "[?2026hFRAME")))
     (let $_20 (tp:check sync-close (str:ends-with $synced (str:concat $esc1 "[?2026l")))

     ;; 8. terminal:hyperlink (OSC 8 + C0/ESC injection stripping + empty URL passthrough)
     (let $link (terminal:hyperlink "https://example.org/a" "click")
     (let $expected-link (str:concat $esc1 (str:concat "]8;;https://example.org/a" (str:concat $esc1 (str:concat "\\click" (str:concat $esc1 (str:concat "]8;;" (str:concat $esc1 "\\")))))))
     (let $_21 (tp:check osc8-basic (== $link $expected-link))
     (let $bad-url (str:concat "https://ok" (str:concat $esc1 "]52;c;AAAA"))
     (let $safe-link (terminal:hyperlink $bad-url "lbl")
     (let $_22 (tp:check osc8-strips-esc-injection (== (str:find $safe-link (str:concat $esc1 "]52")) (TextNotFound (str:concat $esc1 "]52"))))
     (let $_23 (tp:check osc8-empty-url (== (terminal:hyperlink "" "plain") "plain"))

     ;; 9. terminal:clipboard (OSC 52 base64 RFC 4648 vectors: "", "f", "fo", "foo", "Hello!")
     (let $cb0 (terminal:clipboard "")
     (let $cb1 (terminal:clipboard "f")
     (let $cb2 (terminal:clipboard "fo")
     (let $cb3 (terminal:clipboard "foo")
     (let $cb4 (terminal:clipboard "Hello!")
     (let $_24 (tp:check osc52-empty (== $cb0 (str:concat $esc1 (str:concat "]52;c;" (str:concat $esc1 "\\")))))
     (let $_25 (tp:check osc52-f (== $cb1 (str:concat $esc1 (str:concat "]52;c;Zg==" (str:concat $esc1 "\\")))))
     (let $_26 (tp:check osc52-fo (== $cb2 (str:concat $esc1 (str:concat "]52;c;Zm8=" (str:concat $esc1 "\\")))))
     (let $_27 (tp:check osc52-foo (== $cb3 (str:concat $esc1 (str:concat "]52;c;Zm9v" (str:concat $esc1 "\\")))))
     (let $_28 (tp:check osc52-hello (== $cb4 (str:concat $esc1 (str:concat "]52;c;SGVsbG8h" (str:concat $esc1 "\\")))))

     ;; 10. terminal:commit (atomic sync bracket + hide cursor + erase + ?7h + lines + redraw + show cursor)
     (let $c0 (terminal:commit 0 ("line-one" "line-two") "PROMPT> ")
     (let $expect0 (str:join "" ($esc1 "[?2026h" $esc1 "[?25l\r" $esc1 "[2K" $esc1 "[1C" $esc1 "[J\r" $esc1 "[?7hline-one\r\nline-two\r\nPROMPT> " $esc1 "[?25h" $esc1 "[?2026l"))
     (let $_29 (tp:check commit-up0-exact (== $c0 $expect0))
     (let $c3 (terminal:commit 3 ("cmd --long") "LIVE")
     (let $_30 (tp:check commit-up3-moves-up (not (== (str:find $c3 (str:concat $esc1 "[3A")) (TextNotFound (str:concat $esc1 "[3A")))))
     (let $_31 (tp:check commit-up3-enables-autowrap (not (== (str:find $c3 (str:concat $esc1 "[?7hcmd --long\r\nLIVE")) (TextNotFound (str:concat $esc1 "[?7hcmd --long\r\nLIVE")))))
     (let $_32 (tp:check commit-bad-line-rejected
                 (case (terminal:commit 0 (123) "") (((HostFailure "terminal-commit" $_c2 $_m2) True) ($other False))))

     (let $_close (host:close $buf) True)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))

!(let $ans (collapse (tp:run))
   (if (== $ans (True)) (println! HOST_TERMINAL_PROTOCOL_OK) (system:exit 1)))
