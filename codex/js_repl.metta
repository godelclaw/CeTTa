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
; - ToolHandler kind/matches_kind and feature/payload guard behavior
; - function-payload JsReplArgs decoding before the async runtime boundary
; - js_repl exec begin/end event payload construction
; - nested tool-call response summary for message/function/custom/tool_search
;   responses plus handler errors
; - small exec-output aggregation helper used by js_repl events
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust executes parsed JavaScript through a persistent Node kernel stored on
;   the turn context. This slice ports the pure pre-runtime parser, metadata,
;   handler guard logic, and exec event payloads; kernel process management
;   remains a later runtime increment. The handler result therefore carries a
;   `CodexJsReplExecPlan` at the exact Rust handoff point where `manager()`
;   would be awaited.
; - Rust parses timeout_ms as u64. CeTTa integers are not currently bounded to
;   Rust integer widths, so this slice validates the same non-empty decimal
;   syntax but does not reject values above u64::MAX.
; - Rust gets serde's exact parse diagnostics for function-payload JsReplArgs.
;   This slice preserves the same accepted fields and failure classes with
;   reconstructed messages because the current CeTTa JSON helper does not
;   expose serde-style typed errors.

!(import! &self json)
!(import! &self list)
!(import! &self str)
!(import! &self codex:string_truncate)

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

(= (codex:js-repl-tool-response-text-preview-max-bytes)
   512)

(= (codex:js-repl-empty-input-message)
   "js_repl expects raw JavaScript tool input (non-empty). Provide JS source text, optionally with first-line `// codex-js-repl: ...`.")

(= (codex:js-repl-common-wrapped-source-message)
   "js_repl is a freeform tool and expects raw JavaScript source. Resend plain JS only (optional first line `// codex-js-repl: ...`); do not send JSON (`{\"code\":...}`), quoted code, or markdown fences.")

(= (codex:js-repl-markdown-fence-message)
   "js_repl expects raw JavaScript source, not markdown code fences. Resend plain JS only (optional first line `// codex-js-repl: ...`).")

(= (codex:js-repl-freeform-grammar)
   "\nstart: pragma_source | plain_source\n\npragma_source: PRAGMA_LINE NEWLINE js_source\nplain_source: PLAIN_JS_SOURCE\n\njs_source: JS_SOURCE\n\nPRAGMA_LINE: /[ \\t]*\\/\\/ codex-js-repl:[^\\r\\n]*/\nNEWLINE: /\\r?\\n/\nPLAIN_JS_SOURCE: /(?:\\s*)(?:[^\\s{\\\"`]|`[^`]|``[^`])[\\s\\S]*/\nJS_SOURCE: /(?:\\s*)(?:[^\\s{\\\"`]|`[^`]|``[^`])[\\s\\S]*/\n")

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

(= (codex:js-repl-function-args-error $message)
   (codex:js-repl-parse-error
     (str-concat "failed to parse function arguments: " $message)))

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

(= (codex:is-js-repl-function-args-known-key $key)
   (or (== $key "code") (== $key "timeout_ms")))

(= (codex:js-repl-function-args-first-unknown-key ())
   CodexAbsent)

(= (codex:js-repl-function-args-first-unknown-key $pairs)
   (let ($head $tail) (decons-atom $pairs)
     (case $head
       (((JsonPair $key $value)
         (if (codex:is-js-repl-function-args-known-key $key)
             (codex:js-repl-function-args-first-unknown-key $tail)
             $key))))))

(= (codex:js-repl-function-args-code-result $object)
   (case (json-object-get $object "code")
     ((Empty
       (codex:js-repl-function-args-error "missing field `code`"))
      ; CeTTa's JSON getter currently reaches this branch for an absent key in
      ; the loaded surface, so keep Rust's missing-field class for that case.
      (JsonNull
       (codex:js-repl-function-args-error
         "missing field `code`"))
      ((JsonString $code)
       (codex:js-repl-parse-ok $code))
      ($other
       (codex:js-repl-function-args-error
         "invalid type for `code`; expected string")))))

(= (codex:js-repl-function-args-timeout-result $object)
   (case (json-object-get $object "timeout_ms")
     ((Empty (codex:js-repl-parse-ok CodexAbsent))
      (JsonNull (codex:js-repl-parse-ok CodexAbsent))
      ((JsonNumber $value)
       (let $number-text (format-args "{}" ($value))
         (if (codex:is-js-repl-decimal-string $number-text)
           (codex:js-repl-parse-ok
             (codex:js-repl-decimal-string-to-number $number-text))
           (codex:js-repl-function-args-error
             "invalid type for `timeout_ms`; expected integer or null"))))
      ($other
       (codex:js-repl-function-args-error
         "invalid type for `timeout_ms`; expected integer or null")))))

(= (codex:js-repl-function-args-from-object (JsonObject $pairs))
   (case (codex:js-repl-function-args-first-unknown-key $pairs)
     ((CodexAbsent
       (case (codex:js-repl-function-args-code-result (JsonObject $pairs))
         (((CodexJsReplParseError $message)
           (codex:js-repl-parse-error $message))
          ((CodexJsReplParseOk $code)
           (case (codex:js-repl-function-args-timeout-result
                   (JsonObject $pairs))
             (((CodexJsReplParseError $message)
               (codex:js-repl-parse-error $message))
              ((CodexJsReplParseOk $timeout-ms)
               (codex:js-repl-parse-ok
                 (codex:js-repl-args $code $timeout-ms)))))))))
      ($unknown
       (codex:js-repl-function-args-error
         (format-args
           "unknown field `{}`, expected `code` or `timeout_ms`"
           ($unknown)))))))

(= (codex:parse-js-repl-function-args $arguments)
   (case (json-parse $arguments)
     (((JsonObject $pairs)
       (codex:js-repl-function-args-from-object (JsonObject $pairs)))
      ((Error $source $message)
       (codex:js-repl-function-args-error $message))
      ($other
       (codex:js-repl-function-args-error
         "invalid type: expected object")))))

(= (codex:js-repl-handler-kind)
   "function")

(= (codex:js-repl-reset-handler-kind)
   "function")

(= (codex:js-repl-handler-matches-kind $payload)
   (case $payload
     (((CodexToolPayloadFunction $arguments) True)
      ((CodexToolPayloadCustom $input) True)
      ($other False))))

(= (codex:js-repl-handler-ok $value)
   (CodexJsReplHandlerOk $value))

(= (codex:js-repl-handler-err $error)
   (CodexJsReplHandlerErr $error))

(= (codex:js-repl-handler-result-value
      (CodexJsReplHandlerOk $value))
   $value)

(= (codex:js-repl-handler-result-error
      (CodexJsReplHandlerErr $error))
   $error)

(= (codex:js-repl-exec-plan $args)
   (CodexJsReplExecPlan $args))

(= (codex:js-repl-exec-plan-args (CodexJsReplExecPlan $args))
   $args)

(= (codex:js-repl-handler-parse-payload $payload)
   (case $payload
     (((CodexToolPayloadFunction $arguments)
       (codex:parse-js-repl-function-args $arguments))
      ((CodexToolPayloadCustom $input)
       (codex:parse-js-repl-freeform-args $input))
      ($other
       (codex:js-repl-parse-error
         (codex:js-repl-unsupported-payload-message))))))

(= (codex:run-js-repl-handler $js-repl-feature-enabled $payload)
   (if (== $js-repl-feature-enabled False)
       (codex:js-repl-handler-err
         (CodexFunctionCallErrorRespondToModel
           (codex:js-repl-disabled-message)))
       (case (codex:js-repl-handler-parse-payload $payload)
         (((CodexJsReplParseError $message)
           (codex:js-repl-handler-err
             (CodexFunctionCallErrorRespondToModel $message)))
          ((CodexJsReplParseOk $args)
           (codex:js-repl-handler-ok
             (codex:js-repl-exec-plan $args)))))))

(= (codex:run-js-repl-reset-handler $js-repl-feature-enabled)
   (if (== $js-repl-feature-enabled False)
       (codex:js-repl-handler-err
         (CodexFunctionCallErrorRespondToModel
           (codex:js-repl-disabled-message)))
       (codex:js-repl-handler-ok
         (CodexToolOutputFunction
           ((CodexInputText (codex:js-repl-reset-output-text)))
           True
           CodexAbsent))))

(= (codex:js-repl-tool-call-payload-kind-message-content)
   (CodexJsReplToolCallPayloadKindMessageContent))

(= (codex:js-repl-tool-call-payload-kind-function-text)
   (CodexJsReplToolCallPayloadKindFunctionText))

(= (codex:js-repl-tool-call-payload-kind-function-content-items)
   (CodexJsReplToolCallPayloadKindFunctionContentItems))

(= (codex:js-repl-tool-call-payload-kind-custom-text)
   (CodexJsReplToolCallPayloadKindCustomText))

(= (codex:js-repl-tool-call-payload-kind-custom-content-items)
   (CodexJsReplToolCallPayloadKindCustomContentItems))

(= (codex:js-repl-tool-call-payload-kind-error)
   (CodexJsReplToolCallPayloadKindError))

(= (codex:js-repl-tool-call-response-summary
      $response-type
      $payload-kind
      $payload-text-preview
      $payload-text-length
      $payload-item-count
      $text-item-count
      $image-item-count
      $structured-content-present
      $result-is-error)
   (CodexJsReplToolCallResponseSummary
     $response-type
     $payload-kind
     $payload-text-preview
     $payload-text-length
     $payload-item-count
     $text-item-count
     $image-item-count
     $structured-content-present
     $result-is-error))

(= (codex:js-repl-tool-call-response-summary-response-type
      (CodexJsReplToolCallResponseSummary
        $response-type
        $payload-kind
        $payload-text-preview
        $payload-text-length
        $payload-item-count
        $text-item-count
        $image-item-count
        $structured-content-present
        $result-is-error))
   $response-type)

(= (codex:js-repl-tool-call-response-summary-payload-kind
      (CodexJsReplToolCallResponseSummary
        $response-type
        $payload-kind
        $payload-text-preview
        $payload-text-length
        $payload-item-count
        $text-item-count
        $image-item-count
        $structured-content-present
        $result-is-error))
   $payload-kind)

(= (codex:js-repl-tool-call-response-summary-payload-text-preview
      (CodexJsReplToolCallResponseSummary
        $response-type
        $payload-kind
        $payload-text-preview
        $payload-text-length
        $payload-item-count
        $text-item-count
        $image-item-count
        $structured-content-present
        $result-is-error))
   $payload-text-preview)

(= (codex:js-repl-tool-call-response-summary-payload-text-length
      (CodexJsReplToolCallResponseSummary
        $response-type
        $payload-kind
        $payload-text-preview
        $payload-text-length
        $payload-item-count
        $text-item-count
        $image-item-count
        $structured-content-present
        $result-is-error))
   $payload-text-length)

(= (codex:js-repl-tool-call-response-summary-payload-item-count
      (CodexJsReplToolCallResponseSummary
        $response-type
        $payload-kind
        $payload-text-preview
        $payload-text-length
        $payload-item-count
        $text-item-count
        $image-item-count
        $structured-content-present
        $result-is-error))
   $payload-item-count)

(= (codex:js-repl-tool-call-response-summary-text-item-count
      (CodexJsReplToolCallResponseSummary
        $response-type
        $payload-kind
        $payload-text-preview
        $payload-text-length
        $payload-item-count
        $text-item-count
        $image-item-count
        $structured-content-present
        $result-is-error))
   $text-item-count)

(= (codex:js-repl-tool-call-response-summary-image-item-count
      (CodexJsReplToolCallResponseSummary
        $response-type
        $payload-kind
        $payload-text-preview
        $payload-text-length
        $payload-item-count
        $text-item-count
        $image-item-count
        $structured-content-present
        $result-is-error))
   $image-item-count)

(= (codex:js-repl-preview-text $text)
   (if (== $text "")
       CodexAbsent
       (if (> (str-length $text)
              (codex:js-repl-tool-response-text-preview-max-bytes))
           (codex:string-truncate-middle-chars
             $text
             (codex:js-repl-tool-response-text-preview-max-bytes))
           $text)))

(= (codex:js-repl-summarize-text-payload
      $response-type
      $payload-kind
      $text)
   (codex:js-repl-tool-call-response-summary
     $response-type
     $payload-kind
     (codex:js-repl-preview-text $text)
     (str-length $text)
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent))

(= (codex:is-js-repl-function-output-text-item $item)
   (case $item
     (((CodexInputText $text) True)
      ($other False))))

(= (codex:is-js-repl-message-text-item $item)
   (case $item
     (((CodexInputText $text) True)
      ((CodexOutputText $text) True)
      ($other False))))

(= (codex:js-repl-count-matching-items () $predicate)
   0)

(= (codex:js-repl-count-matching-items $items $predicate)
   (let ($head $tail) (decons-atom $items)
     (let $tail-count (codex:js-repl-count-matching-items $tail $predicate)
       (case $predicate
         ((FunctionOutputText
           (if (codex:is-js-repl-function-output-text-item $head)
               (+ $tail-count 1)
               $tail-count))
          (MessageText
           (if (codex:is-js-repl-message-text-item $head)
               (+ $tail-count 1)
               $tail-count)))))))

(= (codex:js-repl-text-segment-from-function-output-item $item)
   (case $item
     (((CodexInputText $text)
       (if (== (str-trim $text) "") CodexAbsent $text))
      ($other CodexAbsent))))

(= (codex:js-repl-text-segment-from-message-item $item)
   (case $item
     (((CodexInputText $text)
       (if (== (str-trim $text) "") CodexAbsent $text))
      ((CodexOutputText $text)
       (if (== (str-trim $text) "") CodexAbsent $text))
      ($other CodexAbsent))))

(= (codex:js-repl-content-text-segments () $mode)
   ())

(= (codex:js-repl-content-text-segments $items $mode)
   (let ($head $tail) (decons-atom $items)
     (let $segment
       (case $mode
         ((FunctionOutput
           (codex:js-repl-text-segment-from-function-output-item $head))
          (Message
           (codex:js-repl-text-segment-from-message-item $head))))
       (let $tail-segments
         (codex:js-repl-content-text-segments $tail $mode)
         (if (== $segment CodexAbsent)
             $tail-segments
             (cons-atom $segment $tail-segments))))))

(= (codex:js-repl-content-text $items $mode)
   (let $segments (codex:js-repl-content-text-segments $items $mode)
     (if (== $segments ())
         CodexAbsent
         (str-join "\n" $segments))))

(= (codex:js-repl-summarize-function-output-payload
      $response-type
      $payload-kind
      (CodexFunctionCallOutputText $text))
   (codex:js-repl-tool-call-response-summary
     $response-type
     $payload-kind
     (codex:js-repl-preview-text $text)
     (str-length $text)
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent))

(= (codex:js-repl-summarize-function-output-payload
      $response-type
      $payload-kind
      (CodexFunctionCallOutputContentItems $items))
   (let $payload-text (codex:js-repl-content-text $items FunctionOutput)
     (let $text-count
       (codex:js-repl-count-matching-items $items FunctionOutputText)
       (codex:js-repl-tool-call-response-summary
         $response-type
         $payload-kind
         (if (== $payload-text CodexAbsent)
             CodexAbsent
             (codex:js-repl-preview-text $payload-text))
         (if (== $payload-text CodexAbsent)
             CodexAbsent
             (str-length $payload-text))
         (list:len $items)
         $text-count
         (- (list:len $items) $text-count)
         CodexAbsent
         CodexAbsent))))

(= (codex:js-repl-summarize-message-payload $content)
   (let $payload-text (codex:js-repl-content-text $content Message)
     (let $text-count
       (codex:js-repl-count-matching-items $content MessageText)
       (codex:js-repl-tool-call-response-summary
         "message"
         (codex:js-repl-tool-call-payload-kind-message-content)
         (if (== $payload-text CodexAbsent)
             CodexAbsent
             (codex:js-repl-preview-text $payload-text))
         (if (== $payload-text CodexAbsent)
             CodexAbsent
             (str-length $payload-text))
         (list:len $content)
         $text-count
         (- (list:len $content) $text-count)
         CodexAbsent
         CodexAbsent))))

(= (codex:js-repl-summarize-tool-call-response
      (CodexResponseItemMessage $role $content $phase))
   (codex:js-repl-summarize-message-payload $content))

(= (codex:js-repl-summarize-tool-call-response
      (CodexResponseItemMessageWithId $id $role $content $phase))
   (codex:js-repl-summarize-message-payload $content))

(= (codex:js-repl-summarize-tool-call-response
      (CodexResponseItemFunctionCallOutput $call-id $output))
   (case $output
     (((CodexFunctionCallOutputContentItems $items)
       (codex:js-repl-summarize-function-output-payload
         "function_call_output"
         (codex:js-repl-tool-call-payload-kind-function-content-items)
         $output))
      ($other
       (codex:js-repl-summarize-function-output-payload
         "function_call_output"
         (codex:js-repl-tool-call-payload-kind-function-text)
         $output)))))

(= (codex:js-repl-summarize-tool-call-response
      (CodexResponseItemCustomToolCallOutput $call-id $name $output))
   (case $output
     (((CodexFunctionCallOutputContentItems $items)
       (codex:js-repl-summarize-function-output-payload
         "custom_tool_call_output"
         (codex:js-repl-tool-call-payload-kind-custom-content-items)
         $output))
      ($other
       (codex:js-repl-summarize-function-output-payload
         "custom_tool_call_output"
         (codex:js-repl-tool-call-payload-kind-custom-text)
         $output)))))

(= (codex:js-repl-summarize-tool-call-response
      (CodexResponseItemToolSearchOutput $call-id $status $execution $tools))
   (let $payload-text (json-stringify (JsonArray $tools))
     (codex:js-repl-tool-call-response-summary
       "tool_search_output"
       (codex:js-repl-tool-call-payload-kind-function-text)
       $payload-text
       (str-length $payload-text)
       (list:len $tools)
       CodexAbsent
       CodexAbsent
       CodexAbsent
       CodexAbsent)))

(= (codex:js-repl-summarize-tool-call-error $error)
   (codex:js-repl-summarize-text-payload
     CodexAbsent
     (codex:js-repl-tool-call-payload-kind-error)
     $error))

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

(= (codex:js-repl-exec-output-exit-code
      (CodexJsReplExecOutput
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $timed-out))
   $exit-code)

(= (codex:js-repl-exec-output-stdout
      (CodexJsReplExecOutput
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $timed-out))
   $stdout)

(= (codex:js-repl-exec-output-stderr
      (CodexJsReplExecOutput
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $timed-out))
   $stderr)

(= (codex:js-repl-exec-output-aggregated-output
      (CodexJsReplExecOutput
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $timed-out))
   $aggregated-output)

(= (codex:js-repl-exec-output-duration-ms
      (CodexJsReplExecOutput
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $timed-out))
   $duration-ms)

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

(= (codex:js-repl-floor-div $numerator $denominator)
   (let $remainder (% $numerator $denominator)
     (/ (- $numerator $remainder) $denominator)))

(= (codex:js-repl-duration-from-ms $duration-ms)
   (let $secs (codex:js-repl-floor-div $duration-ms 1000)
     (let $ms-remainder (% $duration-ms 1000)
       (CodexDuration $secs (* $ms-remainder 1000000)))))

(= (codex:js-repl-exec-command)
   ("js_repl"))

(= (codex:js-repl-parsed-command)
   ((CodexParsedCommandUnknown "js_repl")))

(= (codex:emit-js-repl-exec-begin-event $call-id $turn-id $cwd)
   (CodexEventExecCommandBegin
     $call-id
     CodexAbsent
     $turn-id
     (codex:js-repl-exec-command)
     $cwd
     (codex:js-repl-parsed-command)
     (CodexExecCommandSourceAgent)
     CodexAbsent))

(= (codex:js-repl-exec-status-for-exit-code $exit-code)
   (if (== $exit-code 0)
       (CodexExecCommandStatusCompleted)
       (CodexExecCommandStatusFailed)))

(= (codex:emit-js-repl-exec-end-event
      $call-id
      $turn-id
      $cwd
      $output
      $error
      $duration-ms)
   (let $exec-output
     (codex:build-js-repl-exec-output $output $error $duration-ms)
     (let $exit-code
       (codex:js-repl-exec-output-exit-code $exec-output)
       (let $stdout (codex:js-repl-exec-output-stdout $exec-output)
         (let $stderr (codex:js-repl-exec-output-stderr $exec-output)
           (let $aggregated-output
             (codex:js-repl-exec-output-aggregated-output $exec-output)
             (CodexEventExecCommandEnd
               $call-id
               CodexAbsent
               $turn-id
               (codex:js-repl-exec-command)
               $cwd
               (codex:js-repl-parsed-command)
               (CodexExecCommandSourceAgent)
               CodexAbsent
               $stdout
               $stderr
               $aggregated-output
               $exit-code
               (codex:js-repl-duration-from-ms
                 (codex:js-repl-exec-output-duration-ms $exec-output))
               $aggregated-output
               (codex:js-repl-exec-status-for-exit-code $exit-code))))))))
