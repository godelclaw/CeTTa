; Rust-faithful code-mode exec source parsing slice.
;
; This ports deterministic behavior from:
; - openai-codex/codex-rs/code-mode/src/description.rs
;   - CODE_MODE_PRAGMA_PREFIX
;   - CodeModeExecPragma
;   - ParsedExecSource
;   - parse_exec_source
; - openai-codex/codex-rs/core/src/tools/code_mode/execute_handler.rs
;   - CodeModeExecuteHandler payload-kind gate before async execution
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust uses serde_json diagnostics when pragma JSON or field deserialization
;   fails. This CeTTa slice preserves the same validation order, success shape,
;   and stable high-level error prefixes while using the local JSON parser's
;   diagnostic text at the parser boundary.
; - Rust validates `usize` with fixed-width conversion before comparing to the
;   JavaScript safe integer limit. CeTTa integers are unbounded in this profile,
;   so this slice applies the same non-negative-integer and safe-integer checks
;   without a fixed-width overflow branch.

!(import! &self function_tool)
!(import! &self json)
!(import! &self str)
!(import! &self tool_name)

(= (codex:code-mode-exec-pragma-prefix)
   "// @exec:")

(= (codex:code-mode-exec-source-empty-input-message)
   "exec expects raw JavaScript source text (non-empty). Provide JS only, optionally with first-line `// @exec: {\"yield_time_ms\": 10000, \"max_output_tokens\": 1000}`.")

(= (codex:code-mode-exec-source-object-message)
   "exec pragma must be a JSON object with supported fields `yield_time_ms` and `max_output_tokens`")

(= (codex:code-mode-exec-source-valid-json-prefix)
   "exec pragma must be valid JSON with supported fields `yield_time_ms` and `max_output_tokens`: ")

(= (codex:code-mode-exec-source-fields-message)
   "exec pragma fields `yield_time_ms` and `max_output_tokens` must be non-negative safe integers")

(= (codex:code-mode-exec-source-max-js-safe-integer)
   9007199254740991)

(= (codex:code-mode-parsed-exec-source
      $code
      $yield-time-ms
      $max-output-tokens)
   (CodexCodeModeParsedExecSource
     $code
     $yield-time-ms
     $max-output-tokens))

(= (codex:code-mode-parsed-exec-source-code
      (CodexCodeModeParsedExecSource
        $code
        $yield-time-ms
        $max-output-tokens))
   $code)

(= (codex:code-mode-parsed-exec-source-yield-time-ms
      (CodexCodeModeParsedExecSource
        $code
        $yield-time-ms
        $max-output-tokens))
   $yield-time-ms)

(= (codex:code-mode-parsed-exec-source-max-output-tokens
      (CodexCodeModeParsedExecSource
        $code
        $yield-time-ms
        $max-output-tokens))
   $max-output-tokens)

(= (codex:code-mode-exec-source-parse-ok $value)
   (CodexCodeModeExecSourceParseOk $value))

(= (codex:code-mode-exec-source-parse-error $message)
   (CodexCodeModeExecSourceParseError $message))

(= (codex:code-mode-exec-source-parse-result-value
      (CodexCodeModeExecSourceParseOk $value))
   $value)

(= (codex:code-mode-exec-source-parse-result-error
      (CodexCodeModeExecSourceParseError $message))
   $message)

(= (codex:code-mode-exec-source-split-first-line
      $first-line
      $rest)
   (CodexCodeModeExecSourceSplitFirstLine $first-line $rest))

(= (codex:code-mode-exec-source-split-first-line-first
      (CodexCodeModeExecSourceSplitFirstLine $first-line $rest))
   $first-line)

(= (codex:code-mode-exec-source-split-first-line-rest
      (CodexCodeModeExecSourceSplitFirstLine $first-line $rest))
   $rest)

(= (codex:code-mode-exec-source-join-lines ())
   "")

(= (codex:code-mode-exec-source-join-lines $lines)
   (let ($head $tail) (decons-atom $lines)
     (if (== $tail ())
         $head
         (str-concat
           $head
           (str-concat
             "\n"
             (codex:code-mode-exec-source-join-lines $tail))))))

(= (codex:code-mode-exec-source-splitn2-newline $input)
   (let $lines (str-split "\n" $input)
     (let ($first-line $rest-lines) (decons-atom $lines)
       (codex:code-mode-exec-source-split-first-line
         $first-line
         (codex:code-mode-exec-source-join-lines $rest-lines)))))

(= (codex:code-mode-exec-source-is-trim-start-char $char)
   (case $char
     ((" " True)
      ("\t" True)
      ("\r" True)
      ("\n" True)
      ($other False))))

(= (codex:code-mode-exec-source-trim-start-from $text $index)
   (if (== $index (str-length $text))
       ""
       (let $ch (str-slice $text $index (+ $index 1))
         (if (codex:code-mode-exec-source-is-trim-start-char $ch)
             (codex:code-mode-exec-source-trim-start-from
               $text
               (+ $index 1))
             (str-slice $text $index (str-length $text))))))

(= (codex:code-mode-exec-source-trim-start $text)
   (codex:code-mode-exec-source-trim-start-from $text 0))

(= (codex:code-mode-exec-source-strip-pragma-prefix $line)
   (let $trimmed (codex:code-mode-exec-source-trim-start $line)
     (if (str-starts-with?
           $trimmed
           (codex:code-mode-exec-pragma-prefix))
         (str-slice
           $trimmed
           (str-length (codex:code-mode-exec-pragma-prefix))
           (str-length $trimmed))
         CodexAbsent)))

(= (codex:code-mode-exec-source-is-known-pragma-key $key)
   (or (== $key "yield_time_ms")
       (== $key "max_output_tokens")))

(= (codex:code-mode-exec-source-first-unknown-key ())
   CodexAbsent)

(= (codex:code-mode-exec-source-first-unknown-key $pairs)
   (let ($head $tail) (decons-atom $pairs)
     (case $head
       (((JsonPair $key $value)
         (if (codex:code-mode-exec-source-is-known-pragma-key $key)
             (codex:code-mode-exec-source-first-unknown-key $tail)
             $key))))))

(= (codex:code-mode-exec-source-int-result-ok $value)
   (CodexCodeModeExecSourceIntResultOk $value))

(= (codex:code-mode-exec-source-int-result-error $message)
   (CodexCodeModeExecSourceIntResultError $message))

(= (codex:code-mode-exec-source-decimal-digit-value "0")
   0)

(= (codex:code-mode-exec-source-decimal-digit-value "1")
   1)

(= (codex:code-mode-exec-source-decimal-digit-value "2")
   2)

(= (codex:code-mode-exec-source-decimal-digit-value "3")
   3)

(= (codex:code-mode-exec-source-decimal-digit-value "4")
   4)

(= (codex:code-mode-exec-source-decimal-digit-value "5")
   5)

(= (codex:code-mode-exec-source-decimal-digit-value "6")
   6)

(= (codex:code-mode-exec-source-decimal-digit-value "7")
   7)

(= (codex:code-mode-exec-source-decimal-digit-value "8")
   8)

(= (codex:code-mode-exec-source-decimal-digit-value "9")
   9)

(= (codex:code-mode-exec-source-is-decimal-digit $digit)
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

(= (codex:code-mode-exec-source-is-decimal-string $text)
   (if (== $text "")
       False
       (codex:code-mode-exec-source-is-decimal-string-from
         $text
         0)))

(= (codex:code-mode-exec-source-is-decimal-string-from
      $text
      $index)
   (if (== $index (str-length $text))
       True
       (let $digit (str-slice $text $index (+ $index 1))
         (if (codex:code-mode-exec-source-is-decimal-digit $digit)
             (codex:code-mode-exec-source-is-decimal-string-from
               $text
               (+ $index 1))
             False))))

(= (codex:code-mode-exec-source-decimal-string-to-number $text)
   (codex:code-mode-exec-source-decimal-string-to-number-from
     $text
     0
     0))

(= (codex:code-mode-exec-source-decimal-string-to-number-from
      $text
      $index
      $acc)
   (if (== $index (str-length $text))
       $acc
       (let $digit-char (str-slice $text $index (+ $index 1))
         (codex:code-mode-exec-source-decimal-string-to-number-from
           $text
           (+ $index 1)
           (+ (* $acc 10)
              (codex:code-mode-exec-source-decimal-digit-value
                $digit-char))))))

(= (codex:code-mode-exec-source-safe-integer
      $field-name
      $number-text)
   (if (codex:code-mode-exec-source-is-decimal-string $number-text)
       (let $value
         (codex:code-mode-exec-source-decimal-string-to-number
           $number-text)
         (if (> $value (codex:code-mode-exec-source-max-js-safe-integer))
             (codex:code-mode-exec-source-int-result-error
               (format-args
                 "exec pragma field `{}` must be a non-negative safe integer"
                 ($field-name)))
             (codex:code-mode-exec-source-int-result-ok $value)))
       (codex:code-mode-exec-source-int-result-error
         (codex:code-mode-exec-source-fields-message))))

(= (codex:code-mode-exec-source-optional-safe-integer
      $object
      $field-name)
   (case (json-object-get $object $field-name)
     ((Empty
       (codex:code-mode-exec-source-int-result-ok CodexAbsent))
      (JsonNull
       (codex:code-mode-exec-source-int-result-ok CodexAbsent))
      ((JsonNumber $number-text)
       (codex:code-mode-exec-source-safe-integer
         $field-name
         $number-text))
      ($other
       (codex:code-mode-exec-source-int-result-error
         (codex:code-mode-exec-source-fields-message))))))

(= (codex:code-mode-exec-source-pragma-values
      $rest
      $object
      $yield-time-ms)
   (case (codex:code-mode-exec-source-optional-safe-integer
           $object
           "max_output_tokens")
     (((CodexCodeModeExecSourceIntResultOk $max-output-tokens)
       (codex:code-mode-exec-source-parse-ok
         (codex:code-mode-parsed-exec-source
           $rest
           $yield-time-ms
           $max-output-tokens)))
      ((CodexCodeModeExecSourceIntResultError $message)
       (codex:code-mode-exec-source-parse-error $message)))))

(= (codex:code-mode-exec-source-parse-pragma-object
      $rest
      (JsonObject $pairs))
   (case (codex:code-mode-exec-source-first-unknown-key $pairs)
     ((CodexAbsent
       (let $object (JsonObject $pairs)
         (case (codex:code-mode-exec-source-optional-safe-integer
                 $object
                 "yield_time_ms")
           (((CodexCodeModeExecSourceIntResultOk $yield-time-ms)
             (codex:code-mode-exec-source-pragma-values
               $rest
               $object
               $yield-time-ms))
            ((CodexCodeModeExecSourceIntResultError $message)
             (codex:code-mode-exec-source-parse-error $message))))))
      ($unknown
       (codex:code-mode-exec-source-parse-error
         (format-args
           "exec pragma only supports `yield_time_ms` and `max_output_tokens`; got `{}`"
           ($unknown)))))))

(= (codex:code-mode-exec-source-parse-directive
      $rest
      $directive)
   (let $trimmed-directive (str-trim $directive)
     (if (== $trimmed-directive "")
         (codex:code-mode-exec-source-parse-error
           (codex:code-mode-exec-source-object-message))
         (case (json-parse $trimmed-directive)
           (((JsonObject $pairs)
             (codex:code-mode-exec-source-parse-pragma-object
               $rest
               (JsonObject $pairs)))
            ((Error $source $message)
             (codex:code-mode-exec-source-parse-error
               (str-concat
                 (codex:code-mode-exec-source-valid-json-prefix)
                 $message)))
            ($other
             (codex:code-mode-exec-source-parse-error
               (codex:code-mode-exec-source-object-message))))))))

(= (codex:code-mode-exec-source-from-split
      $input
      (CodexCodeModeExecSourceSplitFirstLine $first-line $rest))
   (case (codex:code-mode-exec-source-strip-pragma-prefix
           $first-line)
     ((CodexAbsent
       (codex:code-mode-exec-source-parse-ok
         (codex:code-mode-parsed-exec-source
           $input
           CodexAbsent
           CodexAbsent)))
      ($pragma
       (if (== (str-trim $rest) "")
           (codex:code-mode-exec-source-parse-error
             "exec pragma must be followed by JavaScript source on subsequent lines")
           (codex:code-mode-exec-source-parse-directive
             $rest
             $pragma))))))

(= (codex:parse-code-mode-exec-source $input)
   (if (== (str-trim $input) "")
       (codex:code-mode-exec-source-parse-error
         (codex:code-mode-exec-source-empty-input-message))
       (codex:code-mode-exec-source-from-split
         $input
         (codex:code-mode-exec-source-splitn2-newline $input))))

(= (codex:code-mode-execute-handler-kind)
   "function")

(= (codex:code-mode-execute-handler-matches-kind $payload)
   (case $payload
     (((CodexToolPayloadCustom $input) True)
      ($other False))))

(= (codex:code-mode-execute-handler-ok $value)
   (CodexCodeModeExecuteHandlerOk $value))

(= (codex:code-mode-execute-handler-err $error)
   (CodexCodeModeExecuteHandlerErr $error))

(= (codex:code-mode-execute-handler-result-value
      (CodexCodeModeExecuteHandlerOk $value))
   $value)

(= (codex:code-mode-execute-handler-result-error
      (CodexCodeModeExecuteHandlerErr $error))
   $error)

(= (codex:code-mode-execute-plan
      $call-id
      $parsed-source)
   (CodexCodeModeExecutePlan $call-id $parsed-source))

(= (codex:code-mode-execute-plan-call-id
      (CodexCodeModeExecutePlan $call-id $parsed-source))
   $call-id)

(= (codex:code-mode-execute-plan-parsed-source
      (CodexCodeModeExecutePlan $call-id $parsed-source))
   $parsed-source)

(= (codex:code-mode-execute-handler-plan
      $call-id
      $tool-name
      $payload)
   (case $payload
     (((CodexToolPayloadCustom $input)
       (if (and (== (codex:tool-name-namespace $tool-name) CodexAbsent)
                (== (codex:tool-name-name $tool-name) "exec"))
           (case (codex:parse-code-mode-exec-source $input)
             (((CodexCodeModeExecSourceParseOk $parsed-source)
               (codex:code-mode-execute-handler-ok
                 (codex:code-mode-execute-plan
                   $call-id
                   $parsed-source)))
              ((CodexCodeModeExecSourceParseError $message)
               (codex:code-mode-execute-handler-err
                 (codex:function-call-error-respond-to-model
                   $message)))))
           (codex:code-mode-execute-handler-err
             (codex:function-call-error-respond-to-model
               "exec expects raw JavaScript source text"))))
      ($other
       (codex:code-mode-execute-handler-err
         (codex:function-call-error-respond-to-model
           "exec expects raw JavaScript source text"))))))
