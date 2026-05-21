; Rust-faithful code-mode runtime response handling slice.
;
; This ports deterministic behavior from:
; - openai-codex/codex-rs/core/src/tools/code_mode/mod.rs
;   - handle_runtime_response
;   - sanitize_runtime_image_detail
;   - format_script_status
;   - prepend_script_status
;   - truncate_code_mode_result
; - openai-codex/codex-rs/core/src/unified_exec/mod.rs
;   - resolve_max_tokens / DEFAULT_MAX_OUTPUT_TOKENS
; - openai-codex/codex-rs/code-mode/src/runtime/mod.rs
;   - RuntimeResponse shape used by the core handler
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust mutates CodeModeService stored values for RuntimeResponse::Result.
;   This pure slice returns an explicit ReplaceStoredValues action beside the
;   FunctionToolOutput so callers can perform the same side effect.
; - Rust takes `started_at: Instant` and computes elapsed time internally. This
;   slice receives already-computed elapsed seconds and applies the same
;   one-decimal header formatting.

!(import! &self code_mode_response_adapter)
!(import! &self image_detail)
!(import! &self list)
!(import! &self codex:output_truncation)
!(import! &self str)

; Module-boundary note: importing the broader context/protocol surface into
; this pure slice currently collapses the content-item truncation helper in the
; CeTTa evaluator. These local helpers are direct ports of the same Rust-visible
; constants/constructors, avoiding any behavioral deviation.
(= (codex:code-mode-default-max-output-tokens)
   10000)

(= (codex:code-mode-strip-trailing-dot-zero $text)
   (if (str-ends-with? $text ".0")
       (str-slice $text 0 (- (str-length $text) 2))
       $text))

(= (codex:code-mode-number-text $value)
   (codex:code-mode-strip-trailing-dot-zero
     (format-args "{}" ($value))))

(= (codex:code-mode-one-decimal-seconds-text $secs)
   (let $tenths
     (trunc-math (round-math (* $secs 10)))
     (let $whole (trunc-math (/ $tenths 10))
       (let $fraction (% $tenths 10)
         (str-concat
           (codex:code-mode-number-text $whole)
           (str-concat
             "."
             (codex:code-mode-number-text $fraction)))))))

(= (codex:code-mode-runtime-response-yielded
      $cell-id
      $content-items)
   (CodexCodeModeRuntimeResponseYielded $cell-id $content-items))

(= (codex:code-mode-runtime-response-terminated
      $cell-id
      $content-items)
   (CodexCodeModeRuntimeResponseTerminated $cell-id $content-items))

(= (codex:code-mode-runtime-response-result
      $cell-id
      $content-items
      $stored-values
      $error-text)
   (CodexCodeModeRuntimeResponseResult
     $cell-id
     $content-items
     $stored-values
     $error-text))

(= (codex:code-mode-runtime-response-cell-id
      (CodexCodeModeRuntimeResponseYielded $cell-id $content-items))
   $cell-id)

(= (codex:code-mode-runtime-response-cell-id
      (CodexCodeModeRuntimeResponseTerminated $cell-id $content-items))
   $cell-id)

(= (codex:code-mode-runtime-response-cell-id
      (CodexCodeModeRuntimeResponseResult
        $cell-id
        $content-items
        $stored-values
        $error-text))
   $cell-id)

(= (codex:code-mode-format-script-status
      (CodexCodeModeRuntimeResponseYielded $cell-id $content-items))
   (str-concat "Script running with cell ID " $cell-id))

(= (codex:code-mode-format-script-status
      (CodexCodeModeRuntimeResponseTerminated $cell-id $content-items))
   "Script terminated")

(= (codex:code-mode-format-script-status
      (CodexCodeModeRuntimeResponseResult
        $cell-id
        $content-items
        $stored-values
        $error-text))
   (if (== $error-text CodexAbsent)
       "Script completed"
       "Script failed"))

(= (codex:code-mode-runtime-response-header
      $status
      $elapsed-secs)
   (str-concat
     $status
     (str-concat
       "\nWall time "
       (str-concat
         (codex:code-mode-one-decimal-seconds-text
           $elapsed-secs)
         " seconds\nOutput:\n"))))

(= (codex:code-mode-prepend-script-status
      $content-items
      $status
      $elapsed-secs)
   (list:cons
     (CodexInputText
       (codex:code-mode-runtime-response-header
         $status
         $elapsed-secs))
     $content-items))

(= (codex:code-mode-runtime-all-text-items ())
   True)

(= (codex:code-mode-runtime-all-text-items $items)
   (let ($head $tail) (decons-atom $items)
     (case $head
       (((CodexInputText $text)
         (codex:code-mode-runtime-all-text-items $tail))
        ($other
         False)))))

(= (codex:code-mode-runtime-resolve-max-output-tokens $max-output-tokens)
   (if (== $max-output-tokens CodexAbsent)
       (codex:code-mode-default-max-output-tokens)
       $max-output-tokens))

(= (codex:code-mode-truncate-result-text-only
      $items
      $policy)
   (codex:output-truncation-content-items-result-items
     (codex:output-truncation-formatted-truncate-text-content-items-with-policy
       $items
       $policy)))

(= (codex:code-mode-truncate-runtime-result
      $items
      $max-output-tokens)
   (let $policy
     (codex:output-truncation-policy-tokens
       (codex:code-mode-runtime-resolve-max-output-tokens
         $max-output-tokens))
     (if (codex:code-mode-runtime-all-text-items $items)
         (codex:code-mode-truncate-result-text-only $items $policy)
         (codex:output-truncation-truncate-function-output-items-with-policy
           $items
           $policy))))

(= (codex:code-mode-runtime-action-replace-stored-values
      $stored-values)
   (CodexCodeModeRuntimeActionReplaceStoredValues $stored-values))

(= (codex:code-mode-runtime-response-plan
      $tool-output
      $actions)
   (CodexCodeModeRuntimeResponsePlan $tool-output $actions))

(= (codex:code-mode-runtime-response-plan-output
      (CodexCodeModeRuntimeResponsePlan $tool-output $actions))
   $tool-output)

(= (codex:code-mode-runtime-response-plan-actions
      (CodexCodeModeRuntimeResponsePlan $tool-output $actions))
   $actions)

(= (codex:code-mode-runtime-sanitize-items
      $can-request-original-image-detail
      $items)
   (codex:sanitize-original-image-detail-items
     $can-request-original-image-detail
     $items))

(= (codex:code-mode-runtime-content-items
      $can-request-original-image-detail
      $code-mode-content-items)
   (codex:code-mode-runtime-sanitize-items
     $can-request-original-image-detail
     (codex:into-function-call-output-content-items
       $code-mode-content-items)))

(= (codex:code-mode-runtime-result-content-items
      $items
      $error-text)
   (if (== $error-text CodexAbsent)
       $items
       (list:append
         $items
         ((CodexInputText
            (str-concat "Script error:\n" $error-text))))))

(= (codex:code-mode-runtime-result-success $error-text)
   (== $error-text CodexAbsent))

(= (codex:handle-code-mode-runtime-response
      (CodexCodeModeRuntimeResponseYielded $cell-id $content-items)
      $can-request-original-image-detail
      $max-output-tokens
      $elapsed-secs)
   (let $response
     (CodexCodeModeRuntimeResponseYielded $cell-id $content-items)
     (let $items
       (codex:code-mode-runtime-content-items
         $can-request-original-image-detail
         $content-items)
       (let $truncated
         (codex:code-mode-truncate-runtime-result
           $items
           $max-output-tokens)
         (codex:code-mode-runtime-response-plan
           (CodexToolOutputFunction
             (codex:code-mode-prepend-script-status
               $truncated
               (codex:code-mode-format-script-status $response)
               $elapsed-secs)
             True
             CodexAbsent)
           ())))))

(= (codex:handle-code-mode-runtime-response
      (CodexCodeModeRuntimeResponseTerminated $cell-id $content-items)
      $can-request-original-image-detail
      $max-output-tokens
      $elapsed-secs)
   (let $response
     (CodexCodeModeRuntimeResponseTerminated $cell-id $content-items)
     (let $items
       (codex:code-mode-runtime-content-items
         $can-request-original-image-detail
         $content-items)
       (let $truncated
         (codex:code-mode-truncate-runtime-result
           $items
           $max-output-tokens)
         (codex:code-mode-runtime-response-plan
           (CodexToolOutputFunction
             (codex:code-mode-prepend-script-status
               $truncated
               (codex:code-mode-format-script-status $response)
               $elapsed-secs)
             True
             CodexAbsent)
           ())))))

(= (codex:handle-code-mode-runtime-response
      (CodexCodeModeRuntimeResponseResult
        $cell-id
        $content-items
        $stored-values
        $error-text)
      $can-request-original-image-detail
      $max-output-tokens
      $elapsed-secs)
   (let $response
     (CodexCodeModeRuntimeResponseResult
       $cell-id
       $content-items
       $stored-values
       $error-text)
     (let $items
       (codex:code-mode-runtime-result-content-items
         (codex:code-mode-runtime-content-items
           $can-request-original-image-detail
           $content-items)
         $error-text)
       (let $truncated
         (codex:code-mode-truncate-runtime-result
           $items
           $max-output-tokens)
         (codex:code-mode-runtime-response-plan
           (CodexToolOutputFunction
             (codex:code-mode-prepend-script-status
               $truncated
               (codex:code-mode-format-script-status $response)
               $elapsed-secs)
             (codex:code-mode-runtime-result-success $error-text)
             CodexAbsent)
           ((codex:code-mode-runtime-action-replace-stored-values
              $stored-values)))))))
