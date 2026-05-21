; Narrow Rust-faithful js_repl slice.
;
; This ports the pure visible surface from:
; - openai-codex/codex-rs/tools/src/js_repl_tool.rs
; - openai-codex/codex-rs/core/src/tools/handlers/js_repl.rs
; - openai-codex/codex-rs/core/src/tools/js_repl/mod.rs
;
; Covered in this increment:
; - js_repl and js_repl_reset tool metadata
; - freeform grammar exposed to the Responses API
; - parse_freeform_args pragma handling
; - reject_json_or_quoted_source malformed-input guard
; - small exec-output aggregation helper used by js_repl events
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust executes parsed JavaScript through a persistent Node kernel stored on
;   the turn context. This slice only ports the pure pre-runtime parser and
;   metadata; kernel process management remains a later runtime increment.
; - Rust parses timeout_ms as u64. CeTTa integers are not currently bounded to
;   Rust integer widths, so this slice validates the same non-empty decimal
;   syntax but does not reject values above u64::MAX.

!(import! &self json)
!(import! &self list)
!(import! &self str)

(= (codex:js-repl-tool-name)
   "js_repl")

(= (codex:js-repl-reset-tool-name)
   "js_repl_reset")

(= (codex:js-repl-pragma-prefix)
   "// codex-js-repl:")

(= (codex:js-repl-tool-description)
   "Runs JavaScript in a persistent Node kernel with top-level await. This is a freeform tool: send raw JavaScript source text, optionally with a first-line pragma like `// codex-js-repl: timeout_ms=15000`; do not send JSON/quotes/markdown fences.")

(= (codex:js-repl-reset-tool-description)
   "Restarts the js_repl kernel for this run and clears persisted top-level bindings.")

(= (codex:js-repl-disabled-message)
   "js_repl is disabled by feature flag")

(= (codex:js-repl-unsupported-payload-message)
   "js_repl expects custom or function payload")

(= (codex:js-repl-reset-output-text)
   "js_repl kernel reset")

(= (codex:js-repl-empty-input-message)
   "js_repl expects raw JavaScript tool input (non-empty). Provide JS source text, optionally with first-line `// codex-js-repl: ...`.")

(= (codex:js-repl-common-wrapped-source-message)
   "js_repl is a freeform tool and expects raw JavaScript source. Resend plain JS only (optional first line `// codex-js-repl: ...`); do not send JSON (`{\"code\":...}`), quoted code, or markdown fences.")

(= (codex:js-repl-markdown-fence-message)
   "js_repl expects raw JavaScript source, not markdown code fences. Resend plain JS only (optional first line `// codex-js-repl: ...`).")

(= (codex:js-repl-freeform-grammar)
   "\nstart: pragma_source | plain_source\n\npragma_source: PRAGMA_LINE NEWLINE js_source\nplain_source: PLAIN_JS_SOURCE\n\njs_source: JS_SOURCE\n\nPRAGMA_LINE: /[ \\t]*// codex-js-repl:[^\\r\\n]*/\nNEWLINE: /\\r?\\n/\nPLAIN_JS_SOURCE: /(?:\\s*)(?:[^\\s{\\\"`]|`[^`]|``[^`])[\\s\\S]*/\nJS_SOURCE: /(?:\\s*)(?:[^\\s{\\\"`]|`[^`]|``[^`])[\\s\\S]*/\n")

(= (codex:js-repl-tool-json)
   (JsonObject
     ((JsonPair "type" (JsonString "custom"))
      (JsonPair "name" (JsonString (codex:js-repl-tool-name)))
      (JsonPair "description" (JsonString (codex:js-repl-tool-description)))
      (JsonPair "format"
        (JsonObject
          ((JsonPair "type" (JsonString "grammar"))
           (JsonPair "syntax" (JsonString "lark"))
           (JsonPair "definition" (JsonString (codex:js-repl-freeform-grammar)))))))))

(= (codex:js-repl-reset-tool-json)
   (JsonObject
     ((JsonPair "type" (JsonString "function"))
      (JsonPair "name" (JsonString (codex:js-repl-reset-tool-name)))
      (JsonPair "description" (JsonString (codex:js-repl-reset-tool-description)))
      (JsonPair "strict" (JsonBool False))
      (JsonPair "parameters"
        (JsonObject
          ((JsonPair "type" (JsonString "object"))
           (JsonPair "properties" (JsonObject ()))
           (JsonPair "additionalProperties" (JsonBool False))))))))

(= (codex:js-repl-args $code $timeout-ms)
   (CodexJsReplArgs $code $timeout-ms))

(= (codex:js-repl-args-code (CodexJsReplArgs $code $timeout-ms))
   $code)

(= (codex:js-repl-args-timeout-ms (CodexJsReplArgs $code $timeout-ms))
   $timeout-ms)

(= (codex:js-repl-parse-ok $value)
   (CodexJsReplParseOk $value))

(= (codex:js-repl-parse-error $message)
   (CodexJsReplParseError $message))

(= (codex:js-repl-parse-result-value (CodexJsReplParseOk $value))
   $value)

(= (codex:js-repl-parse-result-error (CodexJsReplParseError $message))
   $message)

(= (codex:js-repl-split-first-line-result $first-line $rest)
   (CodexJsReplSplitFirstLine $first-line $rest))

(= (codex:js-repl-join-lines ())
   "")

(= (codex:js-repl-join-lines $lines)
   (let ($head $tail) (decons-atom $lines)
     (if (list:empty? $tail)
         $head
         (str-concat
           $head
           (str-concat "\n" (codex:js-repl-join-lines $tail))))))

(= (codex:js-repl-split-first-line $input)
   (let $lines (str-split "\n" $input)
     (let ($first-line $rest-lines) (decons-atom $lines)
       (codex:js-repl-split-first-line-result
         $first-line
         (codex:js-repl-join-lines $rest-lines)))))

(= (codex:js-repl-is-trim-start-char $char)
   (case $char
     ((" " True)
      ("\t" True)
      ("\r" True)
      ("\n" True)
      ($other False))))

(= (codex:js-repl-trim-start-from $text $index)
   (if (== $index (str-length $text))
       ""
       (let $ch (str-slice $text $index (+ $index 1))
         (if (codex:js-repl-is-trim-start-char $ch)
             (codex:js-repl-trim-start-from $text (+ $index 1))
             (str-slice $text $index (str-length $text))))))

(= (codex:js-repl-trim-start $text)
   (codex:js-repl-trim-start-from $text 0))

(= (codex:js-repl-strip-pragma-prefix $line)
   (let $trimmed (codex:js-repl-trim-start $line)
     (if (str-starts-with? $trimmed (codex:js-repl-pragma-prefix))
         (str-slice
           $trimmed
           (str-length (codex:js-repl-pragma-prefix))
           (str-length $trimmed))
         CodexAbsent)))

(= (codex:js-repl-decimal-digit-value "0")
   0)

(= (codex:js-repl-decimal-digit-value "1")
   1)

(= (codex:js-repl-decimal-digit-value "2")
   2)

(= (codex:js-repl-decimal-digit-value "3")
   3)

(= (codex:js-repl-decimal-digit-value "4")
   4)

(= (codex:js-repl-decimal-digit-value "5")
   5)

(= (codex:js-repl-decimal-digit-value "6")
   6)

(= (codex:js-repl-decimal-digit-value "7")
   7)

(= (codex:js-repl-decimal-digit-value "8")
   8)

(= (codex:js-repl-decimal-digit-value "9")
   9)

(= (codex:is-js-repl-decimal-digit $digit)
   (case $digit
     (("0" True)
      ("1" True)
      ("2" True)
      ("3" True)
      ("4" True)
      ("5" True)
      ("6" True)
      ("7" True)
      ("8" True)
      ("9" True)
      ($other False))))

(= (codex:is-js-repl-decimal-string $text)
   (if (== $text "")
       False
       (codex:is-js-repl-decimal-string-from $text 0)))

(= (codex:is-js-repl-decimal-string-from $text $index)
   (if (== $index (str-length $text))
       True
       (let $digit (str-slice $text $index (+ $index 1))
         (if (codex:is-js-repl-decimal-digit $digit)
             (codex:is-js-repl-decimal-string-from $text (+ $index 1))
             False))))

(= (codex:js-repl-decimal-string-to-number $text)
   (codex:js-repl-decimal-string-to-number-from $text 0 0))

(= (codex:js-repl-decimal-string-to-number-from $text $index $acc)
   (if (== $index (str-length $text))
       $acc
       (let $digit-char (str-slice $text $index (+ $index 1))
         (codex:js-repl-decimal-string-to-number-from
           $text
           (+ $index 1)
           (+ (* $acc 10) (codex:js-repl-decimal-digit-value $digit-char))))))

(= (codex:js-repl-key-value $key $value)
   (CodexJsReplKeyValue $key $value))

(= (codex:js-repl-split-once-equals $token)
   (let $parts (str-split "=" $token)
     (if (== (list:len $parts) 1)
         (codex:js-repl-parse-error
           (format-args
             "js_repl pragma expects space-separated key=value pairs (supported keys: timeout_ms); got `{}`"
             ($token)))
         (codex:js-repl-parse-ok
           (codex:js-repl-key-value
             (list:first $parts)
             (str-join "=" (list:rest $parts)))))))

(= (codex:js-repl-parse-timeout-ms $value)
   (if (codex:is-js-repl-decimal-string $value)
       (codex:js-repl-parse-ok
         (codex:js-repl-decimal-string-to-number $value))
       (codex:js-repl-parse-error
         (format-args
           "js_repl pragma timeout_ms must be an integer; got `{}`"
           ($value)))))

(= (codex:js-repl-parse-timeout-token $value $existing-timeout)
   (if (== $existing-timeout CodexAbsent)
       (codex:js-repl-parse-timeout-ms $value)
       (codex:js-repl-parse-error
         "js_repl pragma specifies timeout_ms more than once")))

(= (codex:js-repl-parse-pragma-token
      (CodexJsReplKeyValue $key $value)
      $existing-timeout)
   (if (== $key "timeout_ms")
       (codex:js-repl-parse-timeout-token $value $existing-timeout)
       (codex:js-repl-parse-error
         (format-args
           "js_repl pragma only supports timeout_ms; got `{}`"
           ($key)))))

(= (codex:js-repl-parse-pragma-tokens () $timeout-ms)
   (codex:js-repl-parse-ok $timeout-ms))

(= (codex:js-repl-parse-pragma-tokens $tokens $timeout-ms)
   (let ($token $tail) (decons-atom $tokens)
     (case (codex:js-repl-split-once-equals $token)
       (((CodexJsReplParseError $message)
         (codex:js-repl-parse-error $message))
        ((CodexJsReplParseOk $key-value)
         (case (codex:js-repl-parse-pragma-token
                 $key-value
                 $timeout-ms)
           (((CodexJsReplParseError $message)
             (codex:js-repl-parse-error $message))
            ((CodexJsReplParseOk $new-timeout-ms)
             (codex:js-repl-parse-pragma-tokens
               $tail
               $new-timeout-ms)))))))))

(= (codex:js-repl-parse-pragma-directive $directive)
   (let $trimmed (str-trim $directive)
     (if (== $trimmed "")
         (codex:js-repl-parse-ok CodexAbsent)
         (codex:js-repl-parse-pragma-tokens
           (str-split-whitespace $trimmed)
           CodexAbsent))))

(= (codex:js-repl-reject-json-or-quoted-source $code)
   (let $trimmed (str-trim $code)
     (if (str-starts-with? $trimmed "```")
         (codex:js-repl-parse-error (codex:js-repl-markdown-fence-message))
         (case (json-parse $trimmed)
           (((JsonObject $pairs)
             (codex:js-repl-parse-error
               (codex:js-repl-common-wrapped-source-message)))
            ((JsonString $text)
             (codex:js-repl-parse-error
               (codex:js-repl-common-wrapped-source-message)))
            ((Error $source $message)
             (codex:js-repl-parse-ok CodexAbsent))
            ($other
             (codex:js-repl-parse-ok CodexAbsent)))))))

(= (codex:js-repl-freeform-args-from-reject-result
      $code
      $timeout-ms
      (CodexJsReplParseOk $ignored))
   (codex:js-repl-parse-ok
     (codex:js-repl-args $code $timeout-ms)))

(= (codex:js-repl-freeform-args-from-reject-result
      $code
      $timeout-ms
      (CodexJsReplParseError $message))
   (codex:js-repl-parse-error $message))

(= (codex:js-repl-freeform-args-from-pragma-result
      $rest
      (CodexJsReplParseOk $timeout-ms))
   (if (== (str-trim $rest) "")
       (codex:js-repl-parse-error
         "js_repl pragma must be followed by JavaScript source on subsequent lines")
       (codex:js-repl-freeform-args-from-reject-result
         $rest
         $timeout-ms
         (codex:js-repl-reject-json-or-quoted-source $rest))))

(= (codex:js-repl-freeform-args-from-pragma-result
      $rest
      (CodexJsReplParseError $message))
   (codex:js-repl-parse-error $message))

(= (codex:js-repl-freeform-args-from-split
      $input
      (CodexJsReplSplitFirstLine $first-line $rest))
   (case (codex:js-repl-strip-pragma-prefix $first-line)
     ((CodexAbsent
       (codex:js-repl-freeform-args-from-reject-result
         $input
         CodexAbsent
         (codex:js-repl-reject-json-or-quoted-source $input)))
      ($pragma
       (codex:js-repl-freeform-args-from-pragma-result
         $rest
         (codex:js-repl-parse-pragma-directive $pragma))))))

(= (codex:parse-js-repl-freeform-args $input)
   (if (== (str-trim $input) "")
       (codex:js-repl-parse-error (codex:js-repl-empty-input-message))
       (codex:js-repl-freeform-args-from-split
         $input
         (codex:js-repl-split-first-line $input))))

(= (codex:js-repl-join-outputs $stdout $stderr)
   (if (== $stdout "")
       $stderr
       (if (== $stderr "")
           $stdout
           (str-concat $stdout (str-concat "\n" $stderr)))))

(= (codex:js-repl-exec-output
      $exit-code
      $stdout
      $stderr
      $aggregated-output
      $duration-ms
      $timed-out)
   (CodexJsReplExecOutput
     $exit-code
     $stdout
     $stderr
     $aggregated-output
     $duration-ms
     $timed-out))

(= (codex:build-js-repl-exec-output $output $error $duration-ms)
   (if (== $error CodexAbsent)
       (codex:js-repl-exec-output
         0
         $output
         ""
         (codex:js-repl-join-outputs $output "")
         $duration-ms
         False)
       (codex:js-repl-exec-output
         1
         $output
         $error
         (codex:js-repl-join-outputs $output $error)
         $duration-ms
         False)))
