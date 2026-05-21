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
; - top-level exec-state transition helpers
; - kernel stderr-tail and model-facing diagnostic helpers
; - emitted-image URL validation, exec-result content item build/split, internal
;   tool predicate, and Node version parse/check/error-format helpers
; - nested tool-call response summary for message/function/custom/mcp/tool_search
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
;   syntax for timeout_ms and Node version components but does not reject values
;   above u64::MAX.
; - Rust gets serde's exact parse diagnostics for function-payload JsReplArgs.
;   This slice preserves the same accepted fields and failure classes with
;   reconstructed messages because the current CeTTa JSON helper does not
;   expose serde-style typed errors.
; - Rust's MCP `structured_content.is_some()` distinguishes an absent field
;   from a present JSON null. The current CeTTa `json-object-get` maps both to
;   `JsonNull`, so this slice scans object pairs directly for that summary
;   field. MCP summary also uses `once` at materialization boundaries where the
;   CeTTa evaluator can surface duplicate identical reductions; Rust has one
;   deterministic struct conversion there.
; - Rust mutates `VecDeque<String>` for recent stderr and returns only the
;   bounded line from `push_stderr_tail_line`. This pure slice returns
;   `CodexJsReplStderrTailPushResult` with the updated tail plus that same
;   bounded line so tests can pin the mutation boundary.
; - Rust obtains the Node version by spawning `node --version`. This pure slice
;   accepts already-observed spawn/status/stdout/stderr values at that runtime
;   boundary and preserves Rust's exact post-observation formatting and version
;   comparison branches.
; - Rust resolves Node from `CODEX_JS_REPL_NODE_PATH`, then config, then
;   `which node`, checking filesystem existence at each path boundary. This
;   pure slice receives those already-observed existence/which values and keeps
;   the Rust precedence order.
; - Some parser/runtime-boundary helpers bind intermediate results with `let`
;   where Rust would call a helper inline. This only materializes the same value
;   in CeTTa's evaluator and does not change the branch order or accepted cases.

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

(= (codex:js-repl-stderr-tail-line-limit)
   20)

(= (codex:js-repl-stderr-tail-line-max-bytes)
   512)

(= (codex:js-repl-stderr-tail-max-bytes)
   4096)

(= (codex:js-repl-stderr-tail-separator)
   " | ")

(= (codex:js-repl-exec-id-log-limit)
   8)

(= (codex:js-repl-model-diag-stderr-max-bytes)
   1024)

(= (codex:js-repl-model-diag-error-max-bytes)
   256)

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
       (let $split (codex:js-repl-split-first-line $input)
         (codex:js-repl-freeform-args-from-split $input $split))))

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

(= (codex:js-repl-top-level-exec-state-idle)
   (CodexJsReplTopLevelExecStateIdle))

(= (codex:js-repl-top-level-exec-state-fresh-kernel
      $turn-id
      $exec-id)
   (CodexJsReplTopLevelExecStateFreshKernel $turn-id $exec-id))

(= (codex:js-repl-top-level-exec-state-reused-kernel-pending
      $turn-id
      $exec-id)
   (CodexJsReplTopLevelExecStateReusedKernelPending $turn-id $exec-id))

(= (codex:js-repl-top-level-exec-state-submitted $turn-id $exec-id)
   (CodexJsReplTopLevelExecStateSubmitted $turn-id $exec-id))

(= (codex:js-repl-top-level-exec-state-registered-exec-id
      (CodexJsReplTopLevelExecStateIdle))
   CodexAbsent)

(= (codex:js-repl-top-level-exec-state-registered-exec-id
      (CodexJsReplTopLevelExecStateFreshKernel $turn-id $exec-id))
   $exec-id)

(= (codex:js-repl-top-level-exec-state-registered-exec-id
      (CodexJsReplTopLevelExecStateReusedKernelPending $turn-id $exec-id))
   $exec-id)

(= (codex:js-repl-top-level-exec-state-registered-exec-id
      (CodexJsReplTopLevelExecStateSubmitted $turn-id $exec-id))
   $exec-id)

(= (codex:js-repl-top-level-exec-state-should-reset-for-interrupt
      (CodexJsReplTopLevelExecStateIdle)
      $turn-id)
   False)

(= (codex:js-repl-top-level-exec-state-should-reset-for-interrupt
      (CodexJsReplTopLevelExecStateFreshKernel $active-turn-id $exec-id)
      $turn-id)
   (== $active-turn-id $turn-id))

(= (codex:js-repl-top-level-exec-state-should-reset-for-interrupt
      (CodexJsReplTopLevelExecStateReusedKernelPending $active-turn-id $exec-id)
      $turn-id)
   False)

(= (codex:js-repl-top-level-exec-state-should-reset-for-interrupt
      (CodexJsReplTopLevelExecStateSubmitted $active-turn-id $exec-id)
      $turn-id)
   (== $active-turn-id $turn-id))

(= (codex:js-repl-register-top-level-exec-state $state $exec-id $turn-id)
   (case $state
     (((CodexJsReplTopLevelExecStateFreshKernel
         $active-turn-id
         $active-exec-id)
       (if (== $active-turn-id $turn-id)
           (CodexJsReplTopLevelExecStateFreshKernel $turn-id $exec-id)
           (CodexJsReplTopLevelExecStateReusedKernelPending
             $turn-id
             $exec-id)))
      ($other
       (CodexJsReplTopLevelExecStateReusedKernelPending
         $turn-id
         $exec-id)))))

(= (codex:js-repl-mark-top-level-exec-submitted-state
      $state
      $target-exec-id)
   (case $state
     (((CodexJsReplTopLevelExecStateFreshKernel $turn-id $exec-id)
       (if (== $exec-id $target-exec-id)
           (CodexJsReplTopLevelExecStateSubmitted $turn-id $exec-id)
           $state))
      ((CodexJsReplTopLevelExecStateReusedKernelPending $turn-id $exec-id)
       (if (== $exec-id $target-exec-id)
           (CodexJsReplTopLevelExecStateSubmitted $turn-id $exec-id)
           $state))
      ($other $state))))

(= (codex:js-repl-clear-top-level-exec-if-matches-state
      $state
      $exec-id)
   (if (== (codex:js-repl-top-level-exec-state-registered-exec-id $state)
           $exec-id)
       (CodexJsReplTopLevelExecStateIdle)
       $state))

(= (codex:js-repl-list-contains $items $item)
   (case $items
     ((() False)
      ($entries
       (let ($head $tail) (decons-atom $entries)
         (if (== $head $item)
             True
             (codex:js-repl-list-contains $tail $item)))))))

(= (codex:js-repl-clear-top-level-exec-if-matches-any-state
      $state
      $exec-ids)
   (if (codex:js-repl-list-contains
         $exec-ids
         (codex:js-repl-top-level-exec-state-registered-exec-id $state))
       (CodexJsReplTopLevelExecStateIdle)
       $state))

(= (codex:js-repl-kernel-stream-end-shutdown)
   (CodexJsReplKernelStreamEndShutdown))

(= (codex:js-repl-kernel-stream-end-stdout-eof)
   (CodexJsReplKernelStreamEndStdoutEof))

(= (codex:js-repl-kernel-stream-end-stdout-read-error $error)
   (CodexJsReplKernelStreamEndStdoutReadError $error))

(= (codex:js-repl-kernel-stream-end-reason
      (CodexJsReplKernelStreamEndShutdown))
   "shutdown")

(= (codex:js-repl-kernel-stream-end-reason
      (CodexJsReplKernelStreamEndStdoutEof))
   "stdout_eof")

(= (codex:js-repl-kernel-stream-end-reason
      (CodexJsReplKernelStreamEndStdoutReadError $error))
   "stdout_read_error")

(= (codex:js-repl-kernel-stream-end-error $end)
   (case $end
     (((CodexJsReplKernelStreamEndStdoutReadError $error) $error)
      ($other CodexAbsent))))

(= (codex:js-repl-kernel-debug-snapshot $pid $status $stderr-tail)
   (CodexJsReplKernelDebugSnapshot $pid $status $stderr-tail))

(= (codex:js-repl-kernel-debug-snapshot-pid
      (CodexJsReplKernelDebugSnapshot $pid $status $stderr-tail))
   $pid)

(= (codex:js-repl-kernel-debug-snapshot-status
      (CodexJsReplKernelDebugSnapshot $pid $status $stderr-tail))
   $status)

(= (codex:js-repl-kernel-debug-snapshot-stderr-tail
      (CodexJsReplKernelDebugSnapshot $pid $status $stderr-tail))
   $stderr-tail)

(= (codex:js-repl-truncate-utf8-prefix-by-bytes $input $max-bytes)
   (if (<= (str-length $input) $max-bytes)
       $input
       (if (== $max-bytes 0)
           ""
           (case (codex:string-truncate-split-string $input $max-bytes 0)
             (((StrMiddleSplit $removed-chars $prefix $suffix)
               $prefix))))))

(= (codex:js-repl-format-stderr-tail $lines)
   (case $lines
     ((() "<empty>")
      ($items (str-join (codex:js-repl-stderr-tail-separator) $items)))))

(= (codex:js-repl-string-list-byte-sum $lines)
   (case $lines
     ((() 0)
      ($items
       (let ($head $tail) (decons-atom $items)
         (+ (str-length $head)
            (codex:js-repl-string-list-byte-sum $tail)))))))

(= (codex:js-repl-stderr-tail-formatted-bytes $lines)
   (case $lines
     ((() 0)
      ($items
       (+ (codex:js-repl-string-list-byte-sum $items)
          (* (str-length (codex:js-repl-stderr-tail-separator))
             (- (list:len $items) 1)))))))

(= (codex:js-repl-stderr-tail-bytes-with-candidate $lines $line)
   (case $lines
     ((() (str-length $line))
      ($items
       (+ (codex:js-repl-stderr-tail-formatted-bytes $items)
          (+ (str-length (codex:js-repl-stderr-tail-separator))
             (str-length $line)))))))

(= (codex:js-repl-min-number $lhs $rhs)
   (if (< $lhs $rhs) $lhs $rhs))

(= (codex:js-repl-prune-stderr-tail-for-candidate $lines $line)
   (if (== $lines ())
       ()
       (if (or
             (>= (list:len $lines)
                 (codex:js-repl-stderr-tail-line-limit))
             (> (codex:js-repl-stderr-tail-bytes-with-candidate
                  $lines
                  $line)
                (codex:js-repl-stderr-tail-max-bytes)))
           (codex:js-repl-prune-stderr-tail-for-candidate
             (list:rest $lines)
             $line)
           $lines)))

(= (codex:js-repl-stderr-tail-push-result $tail $bounded-line)
   (CodexJsReplStderrTailPushResult $tail $bounded-line))

(= (codex:js-repl-stderr-tail-push-result-tail
      (CodexJsReplStderrTailPushResult $tail $bounded-line))
   $tail)

(= (codex:js-repl-stderr-tail-push-result-bounded-line
      (CodexJsReplStderrTailPushResult $tail $bounded-line))
   $bounded-line)

(= (codex:js-repl-push-stderr-tail-line $lines $line)
   (let $max-line-bytes
     (codex:js-repl-min-number
       (codex:js-repl-stderr-tail-line-max-bytes)
       (codex:js-repl-stderr-tail-max-bytes))
     (let $bounded-line
       (codex:js-repl-truncate-utf8-prefix-by-bytes
         $line
         $max-line-bytes)
       (if (== $bounded-line "")
           (codex:js-repl-stderr-tail-push-result $lines $bounded-line)
           (codex:js-repl-stderr-tail-push-result
             (codex:js-repl-append-item
               (codex:js-repl-prune-stderr-tail-for-candidate
                 $lines
                 $bounded-line)
               $bounded-line)
             $bounded-line)))))

(= (codex:js-repl-is-kernel-status-exited $status)
   (str-starts-with? $status "exited("))

(= (codex:js-repl-ascii-lower-char $char)
   (case $char
     (("A" "a")
      ("B" "b")
      ("C" "c")
      ("D" "d")
      ("E" "e")
      ("F" "f")
      ("G" "g")
      ("H" "h")
      ("I" "i")
      ("J" "j")
      ("K" "k")
      ("L" "l")
      ("M" "m")
      ("N" "n")
      ("O" "o")
      ("P" "p")
      ("Q" "q")
      ("R" "r")
      ("S" "s")
      ("T" "t")
      ("U" "u")
      ("V" "v")
      ("W" "w")
      ("X" "x")
      ("Y" "y")
      ("Z" "z")
      ($other $other))))

(= (codex:js-repl-ascii-lower-text $text)
   (if (== $text "")
       ""
       (str-concat
         (codex:js-repl-ascii-lower-char (str-slice $text 0 1))
         (codex:js-repl-ascii-lower-text
           (str-slice $text 1 (str-length $text))))))

(= (codex:js-repl-string-contains $text $needle)
   (case (str-find $text $needle)
     ((Empty False)
      ($index True))))

(= (codex:js-repl-should-include-model-diagnostics-for-write-error
      $err-message
      $snapshot)
   (or
     (codex:js-repl-is-kernel-status-exited
       (codex:js-repl-kernel-debug-snapshot-status $snapshot))
     (codex:js-repl-string-contains
       (codex:js-repl-ascii-lower-text $err-message)
       "broken pipe")))

(= (codex:js-repl-optional-json-string $text)
   (case $text
     ((CodexAbsent JsonNull)
      ($value (JsonString $value)))))

(= (codex:js-repl-optional-json-number $number)
   (case $number
     ((CodexAbsent JsonNull)
      ($value (JsonNumber $value)))))

(= (codex:js-repl-format-model-kernel-failure-details
      $reason
      $stream-error
      (CodexJsReplKernelDebugSnapshot $pid $status $stderr-tail))
   (str-concat
     "js_repl diagnostics: "
     (json-stringify
       (JsonObject
         ((JsonPair "reason" (JsonString $reason))
          (JsonPair
            "stream_error"
            (if (== $stream-error CodexAbsent)
                JsonNull
                (JsonString
                  (codex:js-repl-truncate-utf8-prefix-by-bytes
                    $stream-error
                    (codex:js-repl-model-diag-error-max-bytes)))))
          (JsonPair "kernel_pid" (codex:js-repl-optional-json-number $pid))
          (JsonPair "kernel_status" (JsonString $status))
          (JsonPair
            "kernel_stderr_tail"
            (JsonString
              (codex:js-repl-truncate-utf8-prefix-by-bytes
                $stderr-tail
                (codex:js-repl-model-diag-stderr-max-bytes)))))))))

(= (codex:js-repl-with-model-kernel-failure-message
      $base-message
      $reason
      $stream-error
      $snapshot)
   (str-concat
     $base-message
     (str-concat
       "\n\n"
       (codex:js-repl-format-model-kernel-failure-details
         $reason
         $stream-error
         $snapshot))))

(= (codex:js-repl-validation-ok)
   (CodexJsReplValidationOk))

(= (codex:js-repl-validation-error $message)
   (CodexJsReplValidationError $message))

(= (codex:js-repl-validation-error-message
      (CodexJsReplValidationError $message))
   $message)

(= (codex:js-repl-split-once-result $left $right)
   (CodexJsReplSplitOnceResult $left $right))

(= (codex:js-repl-split-once-result-left
      (CodexJsReplSplitOnceResult $left $right))
   $left)

(= (codex:js-repl-split-once-result-right
      (CodexJsReplSplitOnceResult $left $right))
   $right)

(= (codex:js-repl-split-once $delimiter $text)
   (let $parts (str-split $delimiter $text)
     (if (== (list:len $parts) 1)
         CodexAbsent
         (codex:js-repl-split-once-result
           (list:first $parts)
           (str-join $delimiter (list:rest $parts))))))

(= (codex:js-repl-emitted-image-url-media-type $image-url)
   (case (codex:js-repl-split-once "," $image-url)
     ((CodexAbsent CodexAbsent)
      ((CodexJsReplSplitOnceResult $header $payload)
       (let $after-scheme (str-slice $header 5 (str-length $header))
         (let $media-type
           (list:first (str-split ";" $after-scheme))
           (if (== $media-type "")
               CodexAbsent
               $media-type)))))))

(= (codex:js-repl-emitted-image-media-type-supported $media-type)
   (let $lower (codex:js-repl-ascii-lower-text $media-type)
     (or
       (== $lower "image/png")
       (or
         (== $lower "image/jpeg")
         (or
           (== $lower "image/webp")
           (== $lower "image/gif"))))))

(= (codex:js-repl-validate-emitted-image-url $image-url)
   (if (or
         (< (str-length $image-url) 5)
         (not
           (==
             (codex:js-repl-ascii-lower-text
               (str-slice $image-url 0 5))
             "data:")))
       (codex:js-repl-validation-error
         "codex.emitImage only accepts data URLs")
       (case (codex:js-repl-emitted-image-url-media-type $image-url)
         ((CodexAbsent
           (codex:js-repl-validation-error
             "codex.emitImage expected a valid image data URL"))
          ($media-type
           (if (codex:js-repl-emitted-image-media-type-supported
                 $media-type)
               (codex:js-repl-validation-ok)
               (codex:js-repl-validation-error
                 "codex.emitImage only supports image/png, image/jpeg, image/webp, or image/gif")))))))

(= (codex:js-repl-build-exec-result-content-items $output $content-items)
   (cons-atom (CodexInputText $output) $content-items))

(= (codex:js-repl-exec-result-content-split $output $content-items)
   (CodexJsReplExecResultContentSplit $output $content-items))

(= (codex:js-repl-exec-result-content-split-output
      (CodexJsReplExecResultContentSplit $output $content-items))
   $output)

(= (codex:js-repl-exec-result-content-split-content-items
      (CodexJsReplExecResultContentSplit $output $content-items))
   $content-items)

(= (codex:js-repl-split-exec-result-content-items $content-items)
   (case $content-items
     ((() (codex:js-repl-exec-result-content-split "" ()))
      ($items
       (let ($head $tail) (decons-atom $items)
         (case $head
           (((CodexInputText $text)
            (codex:js-repl-exec-result-content-split $text $tail))
           ($other
             (codex:js-repl-exec-result-content-split "" $content-items)))))))))

(= (codex:is-js-repl-internal-tool $name)
   (or (== $name (codex:js-repl-tool-name))
       (== $name (codex:js-repl-reset-tool-name))))

(= (codex:js-repl-node-version $major $minor $patch)
   (CodexJsReplNodeVersion $major $minor $patch))

(= (codex:js-repl-node-version-major
      (CodexJsReplNodeVersion $major $minor $patch))
   $major)

(= (codex:js-repl-node-version-minor
      (CodexJsReplNodeVersion $major $minor $patch))
   $minor)

(= (codex:js-repl-node-version-patch
      (CodexJsReplNodeVersion $major $minor $patch))
   $patch)

(= (codex:js-repl-node-version-display
      (CodexJsReplNodeVersion $major $minor $patch))
   (str-concat
     (format-args "{}" ($major))
     (str-concat
       "."
       (str-concat
         (format-args "{}" ($minor))
         (str-concat "." (format-args "{}" ($patch)))))))

(= (codex:js-repl-node-version-parse-ok $version)
   (CodexJsReplNodeVersionParseOk $version))

(= (codex:js-repl-node-version-parse-error $message)
   (CodexJsReplNodeVersionParseError $message))

(= (codex:js-repl-node-version-parse-result-value
      (CodexJsReplNodeVersionParseOk $version))
   $version)

(= (codex:js-repl-node-version-parse-result-error
      (CodexJsReplNodeVersionParseError $message))
   $message)

(= (codex:js-repl-trim-start-v $text)
   (if (str-starts-with? $text "v")
       (codex:js-repl-trim-start-v
         (str-slice $text 1 (str-length $text)))
       $text))

(= (codex:js-repl-normalize-node-version-delimiters $text)
   (str-join
     "."
     (str-split
       "+"
       (str-join "." (str-split "-" $text)))))

(= (codex:js-repl-node-version-parse-int-error-text $text)
   (if (== $text "")
       "cannot parse integer from empty string"
       "invalid digit found in string"))

(= (codex:js-repl-node-version-parse-component $label $text)
   (if (codex:is-js-repl-decimal-string $text)
       (codex:js-repl-node-version-parse-ok
         (codex:js-repl-decimal-string-to-number $text))
       (codex:js-repl-node-version-parse-error
         (str-concat
           "invalid "
           (str-concat
             $label
             (str-concat
               " version: "
               (codex:js-repl-node-version-parse-int-error-text
                 $text)))))))

(= (codex:js-repl-node-version-parse-patch
      $major
      $minor
      $parts)
   (case (codex:js-repl-node-version-parse-component
           "patch"
           (list:at $parts 2))
     (((CodexJsReplNodeVersionParseError $message)
       (codex:js-repl-node-version-parse-error $message))
      ((CodexJsReplNodeVersionParseOk $patch)
       (codex:js-repl-node-version-parse-ok
         (codex:js-repl-node-version $major $minor $patch))))))

(= (codex:js-repl-node-version-parse-minor-after-major
      $major
      $parts)
   (if (< (list:len $parts) 3)
       (codex:js-repl-node-version-parse-error "missing patch version")
       (case (codex:js-repl-node-version-parse-component
               "minor"
               (list:at $parts 1))
         (((CodexJsReplNodeVersionParseError $message)
           (codex:js-repl-node-version-parse-error $message))
          ((CodexJsReplNodeVersionParseOk $minor)
           (codex:js-repl-node-version-parse-patch
             $major
             $minor
             $parts))))))

(= (codex:js-repl-node-version-parse-parts $parts)
   (if (== (list:len $parts) 0)
       (codex:js-repl-node-version-parse-error "missing major version")
       (case (codex:js-repl-node-version-parse-component
               "major"
               (list:at $parts 0))
         (((CodexJsReplNodeVersionParseError $message)
           (codex:js-repl-node-version-parse-error $message))
          ((CodexJsReplNodeVersionParseOk $major)
           (if (< (list:len $parts) 2)
               (codex:js-repl-node-version-parse-error
                 "missing minor version")
               (codex:js-repl-node-version-parse-minor-after-major
                 $major
                 $parts)))))))

(= (codex:js-repl-node-version-parse $input)
   (let $trimmed (codex:js-repl-trim-start-v (str-trim $input))
     (let $normalized
       (codex:js-repl-normalize-node-version-delimiters $trimmed)
       (codex:js-repl-node-version-parse-parts
         (str-split "." $normalized)))))

(= (codex:js-repl-node-version-less-than
      (CodexJsReplNodeVersion $lhs-major $lhs-minor $lhs-patch)
      (CodexJsReplNodeVersion $rhs-major $rhs-minor $rhs-patch))
   (if (< $lhs-major $rhs-major)
       True
       (if (> $lhs-major $rhs-major)
           False
           (if (< $lhs-minor $rhs-minor)
               True
               (if (> $lhs-minor $rhs-minor)
                   False
                   (< $lhs-patch $rhs-patch))))))

(= (codex:js-repl-node-version-at-least $found $required)
   (not (codex:js-repl-node-version-less-than $found $required)))

(= (codex:js-repl-node-version-check-ok)
   (CodexJsReplNodeVersionCheckOk))

(= (codex:js-repl-node-version-check-error $message)
   (CodexJsReplNodeVersionCheckError $message))

(= (codex:js-repl-node-version-check-error-message
      (CodexJsReplNodeVersionCheckError $message))
   $message)

; Mirrors `JS_REPL_MIN_NODE_VERSION = include_str!(../../../../node-version.txt)`.
(= (codex:js-repl-required-node-version-text)
   "22.22.0")

(= (codex:js-repl-required-node-version)
   (codex:js-repl-node-version-parse
     (codex:js-repl-required-node-version-text)))

(= (codex:js-repl-read-node-version-execute-error-message $error)
   (str-concat "failed to execute Node: " $error))

(= (codex:js-repl-read-node-version-status-details $stdout $stderr)
   (let $stdout-trimmed (str-trim $stdout)
     (let $stderr-trimmed (str-trim $stderr)
       (let $stdout-details
         (if (== $stdout-trimmed "")
             ""
             (str-concat " stdout: " $stdout-trimmed))
         (let $stderr-details
           (if (== $stderr-trimmed "")
               ""
               (str-concat " stderr: " $stderr-trimmed))
           (let $details (str-concat $stdout-details $stderr-details)
             (if (== $details "")
                 ""
                 (str-concat " (" (str-concat $details ")")))))))))

(= (codex:js-repl-read-node-version-status-error-message
      $status
      $stdout
      $stderr)
   (str-concat
     "failed to read Node version (status "
     (str-concat
       $status
       (str-concat
         ")"
         (codex:js-repl-read-node-version-status-details
           $stdout
           $stderr)))))

(= (codex:js-repl-read-node-version-parse-output $stdout)
   (let $trimmed (str-trim $stdout)
     (case (codex:js-repl-node-version-parse $trimmed)
       (((CodexJsReplNodeVersionParseOk $version)
         (codex:js-repl-node-version-parse-ok $version))
        ((CodexJsReplNodeVersionParseError $message)
         (codex:js-repl-node-version-parse-error
           (str-concat
             "failed to parse Node version output `"
             (str-concat
               $trimmed
               (str-concat "`: " $message)))))))))

(= (codex:js-repl-node-version-too-old-message
      $node-path
      $found
      $required)
   (str-concat
     "Node runtime too old for js_repl (resolved "
     (str-concat
       $node-path
       (str-concat
         "): found v"
         (str-concat
           (codex:js-repl-node-version-display $found)
           (str-concat
             ", requires >= v"
             (str-concat
               (codex:js-repl-node-version-display $required)
               ". Install/update Node or set js_repl_node_path to a newer runtime.")))))))

(= (codex:js-repl-ensure-node-version $node-path $found $required)
   (if (codex:js-repl-node-version-less-than $found $required)
       (codex:js-repl-node-version-check-error
         (codex:js-repl-node-version-too-old-message
           $node-path
           $found
           $required))
       (codex:js-repl-node-version-check-ok)))

(= (codex:js-repl-resolve-compatible-node-ok $node-path)
   (CodexJsReplResolveCompatibleNodeOk $node-path))

(= (codex:js-repl-resolve-compatible-node-error $message)
   (CodexJsReplResolveCompatibleNodeError $message))

(= (codex:js-repl-resolve-compatible-node-error-message
      (CodexJsReplResolveCompatibleNodeError $message))
   $message)

(= (codex:js-repl-node-runtime-not-found-message)
   "Node runtime not found; install Node or set CODEX_JS_REPL_NODE_PATH")

(= (codex:js-repl-resolve-node-from-env
      $env-path
      $env-exists
      $fallback)
   (case $env-path
     ((CodexAbsent $fallback)
      ($path
       (if $env-exists
           $path
           $fallback)))))

(= (codex:js-repl-resolve-node-from-config
      $config-path
      $config-exists
      $fallback)
   (case $config-path
     ((CodexAbsent $fallback)
      ($path
       (if $config-exists
           $path
           $fallback)))))

(= (codex:js-repl-resolve-node
      $env-path
      $env-exists
      $config-path
      $config-exists
      $which-node-path)
   (codex:js-repl-resolve-node-from-env
     $env-path
     $env-exists
     (codex:js-repl-resolve-node-from-config
       $config-path
       $config-exists
       $which-node-path)))

(= (codex:js-repl-resolve-compatible-node
      $resolved-node-path
      $version-check)
   (case $resolved-node-path
     ((CodexAbsent
       (codex:js-repl-resolve-compatible-node-error
         (codex:js-repl-node-runtime-not-found-message)))
      ($node-path
       (case $version-check
         (((CodexJsReplNodeVersionCheckOk)
           (codex:js-repl-resolve-compatible-node-ok $node-path))
          ((CodexJsReplNodeVersionCheckError $message)
           (codex:js-repl-resolve-compatible-node-error $message))))))))

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

(= (codex:js-repl-tool-call-payload-kind-mcp-result)
   (CodexJsReplToolCallPayloadKindMcpResult))

(= (codex:js-repl-tool-call-payload-kind-mcp-error-result)
   (CodexJsReplToolCallPayloadKindMcpErrorResult))

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

(= (codex:js-repl-tool-call-response-summary-structured-content-present
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
   $structured-content-present)

(= (codex:js-repl-tool-call-response-summary-result-is-error
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
   $result-is-error)

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

(= (codex:js-repl-count-matching-items $items $predicate)
   (case $items
     ((() 0)
      ($entries
       (let ($head $tail) (decons-atom $entries)
         (let $tail-count
           (codex:js-repl-count-matching-items $tail $predicate)
           (case $predicate
             ((FunctionOutputText
               (if (codex:is-js-repl-function-output-text-item $head)
                   (+ $tail-count 1)
                   $tail-count))
              (MessageText
               (if (codex:is-js-repl-message-text-item $head)
                   (+ $tail-count 1)
                   $tail-count))))))))))

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

(= (codex:js-repl-content-text-segments $items $mode)
   (case $items
     ((() ())
      ($entries
       (let ($head $tail) (decons-atom $entries)
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
                 (cons-atom $segment $tail-segments)))))))))

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

(= (codex:js-repl-summary-with-mcp-metadata
      (CodexJsReplToolCallResponseSummary
        $response-type
        $payload-kind
        $payload-text-preview
        $payload-text-length
        $payload-item-count
        $text-item-count
        $image-item-count
        $structured-content-present
        $result-is-error)
      $mcp-content-count
      $mcp-structured-content-present
      $mcp-result-is-error)
   (codex:js-repl-tool-call-response-summary
     $response-type
     $payload-kind
     $payload-text-preview
     $payload-text-length
     $mcp-content-count
     $text-item-count
     $image-item-count
     $mcp-structured-content-present
     $mcp-result-is-error))

(= (codex:js-repl-append-items $lhs $rhs)
   (case $lhs
     ((() $rhs)
      ($items
       (let ($head $tail) (decons-atom $items)
         (case (codex:js-repl-append-items $tail $rhs)
           (($rest
              (cons-atom $head $rest)))))))))

(= (codex:js-repl-append-item $items $item)
   (codex:js-repl-append-items $items ($item)))

(= (codex:js-repl-append-optional-json-value-pair $pairs $key $value)
   (case $value
     ((CodexAbsent $pairs)
      ($present (codex:js-repl-append-item
                  $pairs
                  (JsonPair $key $present))))))

(= (codex:js-repl-json-object-optional-value $object $key)
   (case (json-object-get $object $key)
     ((Empty CodexAbsent)
      (JsonNull CodexAbsent)
      ($value $value))))

(= (codex:js-repl-json-object-pairs-have-key () $key)
   False)

(= (codex:js-repl-json-object-pairs-have-key $pairs $key)
   (let ($head $tail) (decons-atom $pairs)
     (case $head
       (((JsonPair $candidate $value)
         (if (== $candidate $key)
             True
             (codex:js-repl-json-object-pairs-have-key $tail $key)))))))

(= (codex:js-repl-json-object-field-present (JsonObject $pairs) $key)
   (codex:js-repl-json-object-pairs-have-key $pairs $key))

(= (codex:js-repl-json-object-optional-string $object $key)
   (case (codex:js-repl-json-object-optional-value $object $key)
     ((CodexAbsent CodexAbsent)
      ((JsonString $text) $text))))

(= (codex:js-repl-json-object-optional-bool $object $key)
   (case (codex:js-repl-json-object-optional-value $object $key)
     ((CodexAbsent CodexAbsent)
      ((JsonBool $value) $value))))

(= (codex:js-repl-json-object-optional-object $object $key)
   (case (codex:js-repl-json-object-optional-value $object $key)
     ((CodexAbsent CodexAbsent)
      ((JsonObject $pairs) (JsonObject $pairs)))))

(= (codex:js-repl-json-object-optional-array $object $key)
   (case (codex:js-repl-json-object-optional-value $object $key)
     ((CodexAbsent CodexAbsent)
      ((JsonArray $items) $items))))

(= (codex:js-repl-mcp-image-detail-meta-key)
   "codex/imageDetail")

(= (codex:js-repl-default-image-detail)
   "high")

(= (codex:js-repl-mcp-call-tool-result-json
      (CodexMcpCallToolResult
        $content
        $structured-content
        $is-error
        $meta))
   (let $pairs-1
     ((JsonPair "content" (JsonArray $content)))
     (let $pairs-2
       (codex:js-repl-append-optional-json-value-pair
         $pairs-1
         "structuredContent"
         $structured-content)
       (let $pairs-3
         (codex:js-repl-append-optional-json-value-pair
           $pairs-2
           "isError"
           (if (== $is-error CodexAbsent)
               CodexAbsent
               (JsonBool $is-error)))
         (JsonObject
           (codex:js-repl-append-optional-json-value-pair
             $pairs-3
             "_meta"
             $meta))))))

(= (codex:js-repl-mcp-result-json $output)
   (case (once (eval $output))
     (((CodexMcpCallToolResult
         $content
         $structured-content
         $is-error
         $meta)
       (codex:js-repl-mcp-call-tool-result-json
         (CodexMcpCallToolResult
           $content
           $structured-content
           $is-error
           $meta)))
      ($json $json))))

(= (codex:js-repl-mcp-result-success $result)
   (case (codex:js-repl-json-object-optional-bool $result "isError")
     ((True False)
      ($_ True))))

(= (codex:js-repl-mcp-result-structured-content-present $result)
   (codex:js-repl-json-object-field-present $result "structuredContent"))

(= (codex:js-repl-mcp-result-is-error $result)
   (not (codex:js-repl-mcp-result-success $result)))

(= (codex:is-js-repl-function-output-image-item $item)
   (case $item
     (((CodexInputImage $image-url $detail) True)
      ($other False))))

(= (codex:js-repl-mcp-content-image-url $data $mime-type)
   (if (str-starts-with? $data "data:")
       $data
       (str-concat
         "data:"
         (str-concat
           $mime-type
           (str-concat ";base64," $data)))))

(= (codex:js-repl-mcp-content-image-mime-type $object)
   (case (codex:js-repl-json-object-optional-string $object "mimeType")
     ((CodexAbsent
       (case (codex:js-repl-json-object-optional-string $object "mime_type")
         ((CodexAbsent "application/octet-stream")
          ($mime-type-alt $mime-type-alt))))
      ($mime-type-main $mime-type-main))))

(= (codex:js-repl-mcp-content-image-detail $object)
   (let $detail
     (case (codex:js-repl-json-object-optional-object $object "_meta")
       ((CodexAbsent CodexAbsent)
        ($meta
         (codex:js-repl-json-object-optional-string
           $meta
           (codex:js-repl-mcp-image-detail-meta-key)))))
     (case $detail
       (("auto" "auto")
        ("low" "low")
        ("high" "high")
        ("original" "original")
        ($_
         (codex:js-repl-default-image-detail))))))

(= (codex:js-repl-mcp-content-image-item-or-text $object)
   (case (codex:js-repl-json-object-optional-string $object "data")
     ((CodexAbsent
       (CodexInputText (json-stringify $object)))
      ($data
       (CodexInputImage
         (codex:js-repl-mcp-content-image-url
           $data
           (codex:js-repl-mcp-content-image-mime-type $object))
         (codex:js-repl-mcp-content-image-detail $object))))))

(= (codex:js-repl-mcp-content-item-to-function-output-item $content)
   (case $content
     (((JsonObject $pairs)
       (let $object (JsonObject $pairs)
         (case (codex:js-repl-json-object-optional-string $object "type")
           (("text"
             (case (codex:js-repl-json-object-optional-string $object "text")
               ((CodexAbsent
                 (CodexInputText (json-stringify $object)))
                ($text
                 (CodexInputText $text)))))
            ("image"
             (codex:js-repl-mcp-content-image-item-or-text $object))
            ($_
             (CodexInputText (json-stringify $object)))))))
      ($other
       (CodexInputText (json-stringify $other))))))

(= (codex:js-repl-convert-mcp-content-to-items ())
   CodexAbsent)

(= (codex:js-repl-convert-mcp-content-to-items $content)
   (codex:js-repl-convert-mcp-content-to-items-acc $content False ()))

(= (codex:js-repl-convert-mcp-content-to-items-acc () False $acc)
   CodexAbsent)

(= (codex:js-repl-convert-mcp-content-to-items-acc () True $acc)
   $acc)

(= (codex:js-repl-convert-mcp-content-to-items-acc $content $saw-image $acc)
   (let ($head $tail) (decons-atom $content)
     (let $converted
       (codex:js-repl-mcp-content-item-to-function-output-item $head)
       (codex:js-repl-convert-mcp-content-to-items-acc
         $tail
         (if (codex:is-js-repl-function-output-image-item $converted)
             True
             $saw-image)
         (codex:js-repl-append-item $acc $converted)))))

(= (codex:js-repl-mcp-call-tool-result-content-fallback-output $result)
   (case (codex:js-repl-json-object-optional-array $result "content")
     ((CodexAbsent
       (CodexFunctionCallOutputText
         (json-stringify (JsonArray ()))))
      ($content
       (case (codex:js-repl-convert-mcp-content-to-items $content)
         ((CodexAbsent
           (CodexFunctionCallOutputText
             (json-stringify (JsonArray $content))))
          ($items
           (CodexFunctionCallOutputContentItems $items))))))))

(= (codex:js-repl-mcp-call-tool-result-as-function-call-output $result)
   (case (codex:js-repl-json-object-optional-value
           $result
           "structuredContent")
     ((CodexAbsent
       (codex:js-repl-mcp-call-tool-result-content-fallback-output $result))
      ($structured-content
       (CodexFunctionCallOutputText
         (json-stringify $structured-content))))))

(= (codex:js-repl-mcp-result-content-count $result)
   (case (codex:js-repl-json-object-optional-array $result "content")
     ((CodexAbsent 0)
      ($content (list:len $content)))))

(= (codex:js-repl-summarize-tool-call-response $response)
   (case $response
     (((CodexResponseItemMessage $role $content $phase)
       (codex:js-repl-summarize-message-payload $content))
      ((CodexResponseItemMessageWithId $id $role $content $phase)
       (codex:js-repl-summarize-message-payload $content))
      ((CodexResponseItemFunctionCallOutput $call-id $output)
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
      ((CodexResponseItemCustomToolCallOutput $call-id $name $output)
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
      ((CodexResponseItemMcpToolCallOutput $call-id $output)
       (let $result (once (codex:js-repl-mcp-result-json $output))
         (let $function-output
           (once
             (codex:js-repl-mcp-call-tool-result-as-function-call-output
               $result))
           (let $summary
             (once
               (codex:js-repl-summarize-function-output-payload
                 "mcp_tool_call_output"
                 (if (codex:js-repl-mcp-result-success $result)
                     (codex:js-repl-tool-call-payload-kind-mcp-result)
                     (codex:js-repl-tool-call-payload-kind-mcp-error-result))
                 $function-output))
             (codex:js-repl-summary-with-mcp-metadata
               $summary
               (codex:js-repl-mcp-result-content-count $result)
               (codex:js-repl-mcp-result-structured-content-present $result)
               (codex:js-repl-mcp-result-is-error $result))))))
      ((CodexResponseItemToolSearchOutput $call-id $status $execution $tools)
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
           CodexAbsent))))))

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
