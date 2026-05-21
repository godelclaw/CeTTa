; Narrow Rust-faithful ThreadId parse/display slice.
;
; This ports deterministic behavior from:
; - openai-codex/codex-rs/protocol/src/thread_id.rs
; - uuid 1.20.0 parser forms used by Uuid::parse_str
;
; Covered in this increment:
; - ThreadId::from_string accepted UUID forms
; - Display/Serialize canonical hyphenated lowercase text
; - uuid::Error Debug strings needed by multi-agent invalid-id messages
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust stores a `uuid::Uuid` inside `ThreadId`; this CeTTa slice represents
;   ThreadId values by their canonical display string because the surrounding
;   protocol port already carries thread ids as strings.
; - Rust `ThreadId::new` uses Uuid::now_v7(). CeTTa has no UUID generation API
;   at this layer, so this slice only covers deterministic parsing/display.
; - UUID canonicalization reuses the already-ported uuid 1.20.0 parser-form
;   helper from `installation_id`. Error diagnostics are reconstructed for the
;   ASCII tool-input cases used by Codex; non-ASCII byte offsets remain a future
;   shared UUID-library concern.

!(import! &self installation_id)
!(import! &self str)

(= (codex:thread-id-ok $thread-id)
   (CodexThreadIdOk $thread-id))

(= (codex:thread-id-err $debug-error)
   (CodexThreadIdErr $debug-error))

(= (codex:thread-id-result-type (CodexThreadIdOk $thread-id))
   "ok")

(= (codex:thread-id-result-type (CodexThreadIdErr $debug-error))
   "err")

(= (codex:thread-id-result-value (CodexThreadIdOk $thread-id))
   $thread-id)

(= (codex:thread-id-result-error (CodexThreadIdErr $debug-error))
   $debug-error)

(= (codex:thread-id-parse-subject $text)
   (let $len (str-length $text)
     (if (and
           (== $len 38)
           (and
             (== (str-slice $text 0 1) "{")
             (== (str-slice $text 37 38) "}")))
         (CodexThreadIdParseSubject (str-slice $text 1 37) 1 False)
         (if (and
               (== $len 45)
               (str-starts-with? $text "urn:uuid:"))
             (CodexThreadIdParseSubject (str-slice $text 9 45) 9 False)
             (CodexThreadIdParseSubject $text 0 True)))))

(= (codex:thread-id-is-error-scan-char $char)
   (if (== $char "-")
       True
       (codex:installation-id-is-ascii-hex-char $char)))

(= (codex:thread-id-first-invalid-char-from $text $offset $index)
   (if (== $index (str-length $text))
       CodexAbsent
       (let $char (str-slice $text $index (+ $index 1))
         (if (codex:thread-id-is-error-scan-char $char)
             (codex:thread-id-first-invalid-char-from
               $text
               $offset
               (+ $index 1))
             (CodexThreadIdInvalidChar
               $char
               (+ (+ $offset $index) 1))))))

(= (codex:thread-id-hyphen-count-from $text $index)
   (if (== $index (str-length $text))
       0
       (let $tail-count
         (codex:thread-id-hyphen-count-from $text (+ $index 1))
         (if (== (str-slice $text $index (+ $index 1)) "-")
             (+ 1 $tail-count)
             $tail-count))))

(= (codex:thread-id-hyphen-index-at $text $target-count $index $seen)
   (if (== $index (str-length $text))
       CodexAbsent
       (if (== (str-slice $text $index (+ $index 1)) "-")
           (if (== $seen $target-count)
               $index
               (codex:thread-id-hyphen-index-at
                 $text
                 $target-count
                 (+ $index 1)
                 (+ $seen 1)))
           (codex:thread-id-hyphen-index-at
             $text
             $target-count
             (+ $index 1)
             $seen))))

(= (codex:thread-id-parse-char-debug $char $index)
   (str-concat
     "Error(ParseChar { character: '"
     (str-concat
       $char
       (str-concat
         "', index: "
         (str-concat (format-args "{}" ($index)) " })")))))

(= (codex:thread-id-parse-simple-length-debug $len)
   (str-concat
     "Error(ParseSimpleLength { len: "
     (str-concat (format-args "{}" ($len)) " })")))

(= (codex:thread-id-parse-group-count-debug $count)
   (str-concat
     "Error(ParseGroupCount { count: "
     (str-concat (format-args "{}" ($count)) " })")))

(= (codex:thread-id-parse-group-length-debug $group $len $index)
   (str-concat
     "Error(ParseGroupLength { group: "
     (str-concat
       (format-args "{}" ($group))
       (str-concat
         ", len: "
         (str-concat
           (format-args "{}" ($len))
           (str-concat
             ", index: "
             (str-concat (format-args "{}" ($index)) " })")))))))

(= (codex:thread-id-parse-group-length-check
      $text
      $offset
      $group
      $block-start
      $expected-hyphen-index)
   (let $hyphen-index
     (codex:thread-id-hyphen-index-at $text $group 0 0)
     (if (== $hyphen-index $expected-hyphen-index)
         CodexAbsent
         (codex:thread-id-parse-group-length-debug
           $group
           (- $hyphen-index $block-start)
           (+ $offset (+ $block-start 1))))))

(= (codex:thread-id-parse-group-length-debug-for $text $offset)
   (let $group-0
     (codex:thread-id-parse-group-length-check $text $offset 0 0 8)
     (if (not (== $group-0 CodexAbsent))
         $group-0
         (let $group-1
           (codex:thread-id-parse-group-length-check $text $offset 1 9 13)
           (if (not (== $group-1 CodexAbsent))
               $group-1
               (let $group-2
                 (codex:thread-id-parse-group-length-check
                   $text
                   $offset
                   2
                   14
                   18)
                 (if (not (== $group-2 CodexAbsent))
                     $group-2
                     (let $group-3
                       (codex:thread-id-parse-group-length-check
                         $text
                         $offset
                         3
                         19
                         23)
                       (if (not (== $group-3 CodexAbsent))
                           $group-3
                           (codex:thread-id-parse-group-length-debug
                             4
                             (- (str-length $text) 24)
                             (+ $offset 25)))))))))))

(= (codex:thread-id-parse-error-debug-from-subject
      (CodexThreadIdParseSubject $text $offset $simple)
      $original-len)
   (case (codex:thread-id-first-invalid-char-from $text $offset 0)
     (((CodexThreadIdInvalidChar $char $index)
       (codex:thread-id-parse-char-debug $char $index))
      (CodexAbsent
       (let $hyphen-count (codex:thread-id-hyphen-count-from $text 0)
         (if (and (== $hyphen-count 0) $simple)
             (codex:thread-id-parse-simple-length-debug $original-len)
             (if (not (== $hyphen-count 4))
                 (codex:thread-id-parse-group-count-debug (+ $hyphen-count 1))
                 (codex:thread-id-parse-group-length-debug-for
                   $text
                   $offset))))))))

(= (codex:thread-id-parse-error-debug $text)
   (codex:thread-id-parse-error-debug-from-subject
     (codex:thread-id-parse-subject $text)
     (str-length $text)))

(= (codex:thread-id-from-string $text)
   (case (codex:installation-id-canonicalize-uuid $text)
     ((CodexAbsent
       (codex:thread-id-err (codex:thread-id-parse-error-debug $text)))
      ($uuid
       (codex:thread-id-ok $uuid)))))
