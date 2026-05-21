; Rust-faithful code-mode wait handler planning slice.
;
; This ports deterministic behavior from:
; - openai-codex/codex-rs/core/src/tools/code_mode/wait_handler.rs
;   - CodeModeWaitHandler payload/tool-name gate
;   - ExecWaitArgs defaults
;   - parse_arguments error wrapping
;   - live-cell ended trace decision
;   - wait result conversion through handle_runtime_response
; - openai-codex/codex-rs/code-mode/src/runtime/mod.rs
;   - DEFAULT_WAIT_YIELD_TIME_MS
;   - WaitOutcome shape and From<WaitOutcome> for RuntimeResponse
; - openai-codex/codex-rs/code-mode/src/service.rs
;   - missing_cell_response
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust performs the async CodeModeService::wait call inside the handler. This
;   pure slice emits the exact WaitRequest and then consumes an explicit
;   WaitOutcome supplied by the caller.
; - Rust records ended code-cell lifecycle events as a side effect before
;   producing model output. This slice returns a RecordEnded action before the
;   runtime-response actions, preserving the same order.
; - Rust uses serde_json's exact diagnostic strings. This slice preserves the
;   same validation order, defaults, ignored unknown fields, and stable
;   `failed to parse function arguments: ...` prefix with local diagnostics.

!(import! &self code_mode_exec_source)
!(import! &self code_mode_runtime_response)
!(import! &self function_tool)
!(import! &self json)
!(import! &self list)
!(import! &self str)
!(import! &self tool_name)

(= (codex:code-mode-wait-tool-name)
   "wait")

(= (codex:code-mode-default-wait-yield-time-ms)
   10000)

(= (codex:code-mode-wait-args
      $cell-id
      $yield-time-ms
      $max-tokens
      $terminate)
   (CodexCodeModeWaitArgs
     $cell-id
     $yield-time-ms
     $max-tokens
     $terminate))

(= (codex:code-mode-wait-args-cell-id
      (CodexCodeModeWaitArgs
        $cell-id
        $yield-time-ms
        $max-tokens
        $terminate))
   $cell-id)

(= (codex:code-mode-wait-args-yield-time-ms
      (CodexCodeModeWaitArgs
        $cell-id
        $yield-time-ms
        $max-tokens
        $terminate))
   $yield-time-ms)

(= (codex:code-mode-wait-args-max-tokens
      (CodexCodeModeWaitArgs
        $cell-id
        $yield-time-ms
        $max-tokens
        $terminate))
   $max-tokens)

(= (codex:code-mode-wait-args-terminate
      (CodexCodeModeWaitArgs
        $cell-id
        $yield-time-ms
        $max-tokens
        $terminate))
   $terminate)

(= (codex:code-mode-wait-request
      $cell-id
      $yield-time-ms
      $terminate)
   (CodexCodeModeWaitRequest $cell-id $yield-time-ms $terminate))

(= (codex:code-mode-wait-request-from-args
      (CodexCodeModeWaitArgs
        $cell-id
        $yield-time-ms
        $max-tokens
        $terminate))
   (codex:code-mode-wait-request
     $cell-id
     $yield-time-ms
     $terminate))

(= (codex:code-mode-wait-parse-ok $args)
   (CodexCodeModeWaitParseOk $args))

(= (codex:code-mode-wait-parse-error $message)
   (CodexCodeModeWaitParseError $message))

(= (codex:code-mode-wait-parse-result-value
      (CodexCodeModeWaitParseOk $args))
   $args)

(= (codex:code-mode-wait-parse-result-error
      (CodexCodeModeWaitParseError $message))
   $message)

(= (codex:code-mode-wait-field-ok $value)
   (CodexCodeModeWaitFieldOk $value))

(= (codex:code-mode-wait-field-error $message)
   (CodexCodeModeWaitFieldError $message))

(= (codex:code-mode-wait-json-field-missing)
   (CodexCodeModeWaitJsonFieldMissing))

(= (codex:code-mode-wait-json-field-value $value)
   (CodexCodeModeWaitJsonFieldValue $value))

(= (codex:code-mode-wait-json-field-from-pairs () $key)
   (codex:code-mode-wait-json-field-missing))

(= (codex:code-mode-wait-json-field-from-pairs $pairs $key)
   (let ($head $tail) (decons-atom $pairs)
     (case $head
       (((JsonPair $pair-key $value)
         (if (== $pair-key $key)
             (codex:code-mode-wait-json-field-value $value)
             (codex:code-mode-wait-json-field-from-pairs
               $tail
               $key)))))))

(= (codex:code-mode-wait-json-field
      (JsonObject $pairs)
      $key)
   (codex:code-mode-wait-json-field-from-pairs $pairs $key))

(= (codex:code-mode-wait-parse-message $message)
   (str-concat "failed to parse function arguments: " $message))

(= (codex:code-mode-wait-field-invalid-type-message $key $expected)
   (codex:code-mode-wait-parse-message
     (format-args
       "invalid type for field `{}`: expected {}"
       ($key $expected))))

(= (codex:code-mode-wait-required-string $object $key)
   (case (codex:code-mode-wait-json-field $object $key)
     (((CodexCodeModeWaitJsonFieldMissing)
       (codex:code-mode-wait-field-error
         (codex:code-mode-wait-parse-message
           (format-args "missing field `{}`" ($key)))))
      ((CodexCodeModeWaitJsonFieldValue (JsonString $text))
       (codex:code-mode-wait-field-ok $text))
      ($other
       (codex:code-mode-wait-field-error
         (codex:code-mode-wait-field-invalid-type-message
           $key
           "string"))))))

(= (codex:code-mode-wait-non-negative-integer
      $field-name
      $number-text)
   (let $text (format-args "{}" ($number-text))
     (if (codex:code-mode-exec-source-is-decimal-string $text)
         (codex:code-mode-wait-field-ok
           (codex:code-mode-exec-source-decimal-string-to-number
             $text))
         (codex:code-mode-wait-field-error
           (codex:code-mode-wait-parse-message
             (format-args
               "field `{}` must be a non-negative integer"
               ($field-name)))))))

(= (codex:code-mode-wait-optional-int-default
      $object
      $field-name
      $default)
   (case (codex:code-mode-wait-json-field $object $field-name)
     (((CodexCodeModeWaitJsonFieldMissing)
       (codex:code-mode-wait-field-ok $default))
      ((CodexCodeModeWaitJsonFieldValue (JsonNumber $number-text))
       (codex:code-mode-wait-non-negative-integer
         $field-name
         $number-text))
      ($other
       (codex:code-mode-wait-field-error
         (codex:code-mode-wait-field-invalid-type-message
           $field-name
           "non-negative integer"))))))

(= (codex:code-mode-wait-optional-int
      $object
      $field-name)
   (case (codex:code-mode-wait-json-field $object $field-name)
     (((CodexCodeModeWaitJsonFieldMissing)
       (codex:code-mode-wait-field-ok CodexAbsent))
      ((CodexCodeModeWaitJsonFieldValue JsonNull)
       (codex:code-mode-wait-field-ok CodexAbsent))
      ((CodexCodeModeWaitJsonFieldValue (JsonNumber $number-text))
       (codex:code-mode-wait-non-negative-integer
         $field-name
         $number-text))
      ($other
       (codex:code-mode-wait-field-error
         (codex:code-mode-wait-field-invalid-type-message
           $field-name
           "non-negative integer or null"))))))

(= (codex:code-mode-wait-optional-bool-default
      $object
      $field-name
      $default)
   (case (codex:code-mode-wait-json-field $object $field-name)
     (((CodexCodeModeWaitJsonFieldMissing)
       (codex:code-mode-wait-field-ok $default))
      ((CodexCodeModeWaitJsonFieldValue (JsonBool $value))
       (codex:code-mode-wait-field-ok $value))
      ($other
       (codex:code-mode-wait-field-error
         (codex:code-mode-wait-field-invalid-type-message
           $field-name
           "bool"))))))

(= (codex:code-mode-wait-args-from-values
      $object
      $cell-id
      $yield-time-ms
      $max-tokens)
   (case (codex:code-mode-wait-optional-bool-default
           $object
           "terminate"
           False)
     (((CodexCodeModeWaitFieldOk $terminate)
       (codex:code-mode-wait-parse-ok
         (codex:code-mode-wait-args
           $cell-id
           $yield-time-ms
           $max-tokens
           $terminate)))
      ((CodexCodeModeWaitFieldError $message)
       (codex:code-mode-wait-parse-error $message)))))

(= (codex:code-mode-wait-args-from-yield
      $object
      $cell-id
      $yield-time-ms)
   (case (codex:code-mode-wait-optional-int
           $object
           "max_tokens")
     (((CodexCodeModeWaitFieldOk $max-tokens)
       (codex:code-mode-wait-args-from-values
         $object
         $cell-id
         $yield-time-ms
         $max-tokens))
      ((CodexCodeModeWaitFieldError $message)
       (codex:code-mode-wait-parse-error $message)))))

(= (codex:code-mode-wait-args-from-cell-id
      $object
      $cell-id)
   (case (codex:code-mode-wait-optional-int-default
           $object
           "yield_time_ms"
           (codex:code-mode-default-wait-yield-time-ms))
     (((CodexCodeModeWaitFieldOk $yield-time-ms)
       (codex:code-mode-wait-args-from-yield
         $object
         $cell-id
         $yield-time-ms))
      ((CodexCodeModeWaitFieldError $message)
       (codex:code-mode-wait-parse-error $message)))))

(= (codex:code-mode-wait-args-from-json-object
      (JsonObject $pairs))
   (let $object (JsonObject $pairs)
     (case (codex:code-mode-wait-required-string
             $object
             "cell_id")
       (((CodexCodeModeWaitFieldOk $cell-id)
         (codex:code-mode-wait-args-from-cell-id
           $object
           $cell-id))
        ((CodexCodeModeWaitFieldError $message)
         (codex:code-mode-wait-parse-error $message))))))

(= (codex:parse-code-mode-wait-arguments $arguments)
   (case (json-parse $arguments)
     (((JsonObject $pairs)
       (codex:code-mode-wait-args-from-json-object
         (JsonObject $pairs)))
      ((Error $source $message)
       (codex:code-mode-wait-parse-error
         (codex:code-mode-wait-parse-message $message)))
      ($other
       (codex:code-mode-wait-parse-error
         (codex:code-mode-wait-parse-message
           "expected JSON object"))))))

(= (codex:code-mode-wait-invocation-plan
      $request
      $max-tokens)
   (CodexCodeModeWaitInvocationPlan $request $max-tokens))

(= (codex:code-mode-wait-invocation-plan-request
      (CodexCodeModeWaitInvocationPlan $request $max-tokens))
   $request)

(= (codex:code-mode-wait-invocation-plan-max-tokens
      (CodexCodeModeWaitInvocationPlan $request $max-tokens))
   $max-tokens)

(= (codex:plan-code-mode-wait-invocation
      (CodexToolName $name $namespace)
      $payload)
   (if (and (== $namespace CodexAbsent)
            (== $name (codex:code-mode-wait-tool-name)))
       (case $payload
         (((CodexToolPayloadFunction $arguments)
           (case (codex:parse-code-mode-wait-arguments $arguments)
             (((CodexCodeModeWaitParseOk $args)
               (codex:code-mode-wait-invocation-plan
                 (codex:code-mode-wait-request-from-args $args)
                 (codex:code-mode-wait-args-max-tokens $args)))
              ((CodexCodeModeWaitParseError $message)
               (codex:function-call-error-respond-to-model $message)))))
          ($other
           (codex:function-call-error-respond-to-model
             "wait expects JSON arguments"))))
       (codex:function-call-error-respond-to-model
         "wait expects JSON arguments")))

(= (codex:code-mode-wait-outcome-live-cell $response)
   (CodexCodeModeWaitOutcomeLiveCell $response))

(= (codex:code-mode-wait-outcome-missing-cell $response)
   (CodexCodeModeWaitOutcomeMissingCell $response))

(= (codex:code-mode-wait-outcome-runtime-response
      (CodexCodeModeWaitOutcomeLiveCell $response))
   $response)

(= (codex:code-mode-wait-outcome-runtime-response
      (CodexCodeModeWaitOutcomeMissingCell $response))
   $response)

(= (codex:code-mode-wait-missing-cell-response $cell-id)
   (codex:code-mode-runtime-response-result
     $cell-id
     ()
     ()
     (format-args "exec cell {} not found" ($cell-id))))

(= (codex:code-mode-wait-runtime-response-is-yielded $response)
   (case $response
     (((CodexCodeModeRuntimeResponseYielded $cell-id $content-items)
       True)
      ($other False))))

(= (codex:code-mode-wait-record-ended-action
      $turn-sub-id
      $cell-id
      $response)
   (CodexCodeModeWaitActionRecordEnded
     $turn-sub-id
     $cell-id
     $response))

(= (codex:code-mode-wait-ended-trace-actions
      $turn-sub-id
      (CodexCodeModeWaitOutcomeLiveCell $response))
   (if (codex:code-mode-wait-runtime-response-is-yielded $response)
       ()
       ((codex:code-mode-wait-record-ended-action
          $turn-sub-id
          (codex:code-mode-runtime-response-cell-id $response)
          $response))))

(= (codex:code-mode-wait-ended-trace-actions
      $turn-sub-id
      (CodexCodeModeWaitOutcomeMissingCell $response))
   ())

(= (codex:code-mode-wait-completion-plan
      $tool-output
      $actions)
   (CodexCodeModeWaitCompletionPlan $tool-output $actions))

(= (codex:code-mode-wait-completion-plan-output
      (CodexCodeModeWaitCompletionPlan $tool-output $actions))
   $tool-output)

(= (codex:code-mode-wait-completion-plan-actions
      (CodexCodeModeWaitCompletionPlan $tool-output $actions))
   $actions)

(= (codex:complete-code-mode-wait-response
      $args
      $outcome
      $turn-sub-id
      $can-request-original-image-detail
      $elapsed-secs)
   (let $response
     (codex:code-mode-wait-outcome-runtime-response $outcome)
     (let $runtime-plan
       (codex:handle-code-mode-runtime-response
         $response
         $can-request-original-image-detail
         (codex:code-mode-wait-args-max-tokens $args)
         $elapsed-secs)
       (codex:code-mode-wait-completion-plan
         (codex:code-mode-runtime-response-plan-output
           $runtime-plan)
         (list:append
           (codex:code-mode-wait-ended-trace-actions
             $turn-sub-id
             $outcome)
           (codex:code-mode-runtime-response-plan-actions
             $runtime-plan))))))
