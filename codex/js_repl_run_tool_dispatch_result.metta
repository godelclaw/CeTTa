; Rust-faithful js_repl run_tool_request dispatch-result slice.
;
; This ports deterministic helper behavior from:
; - openai-codex/codex-rs/core/src/tools/js_repl/mod.rs
;   - the match on dispatch_tool_call_with_code_mode_result
;   - successful AnyToolResult::into_response handling
;   - serde_json::to_value success/error handling
;   - dispatch FunctionCallError handling
; - openai-codex/codex-rs/core/src/tools/registry.rs
;   - AnyToolResult::into_response
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust owns a boxed ToolOutput trait object. This pure slice stores the
;   already-ported concrete ToolOutput atom inside an AnyToolResult-shaped atom.
; - Rust's serde_json encoder is fallible. CeTTa's supported response atoms
;   serialize through pure `item-json`; an explicit serialization-failure output
;   models Rust's error arm at that boundary.

!(import! &self context)
!(import! &self js_repl_run_tool_request)
!(import! &self protocol)

(= (codex:js-repl-run-tool-any-tool-result
      $call-id
      $payload
      $tool-output
      $post-tool-use-payload)
   (CodexJsReplRunToolAnyToolResult
     $call-id
     $payload
     $tool-output
     $post-tool-use-payload))

(= (codex:js-repl-run-tool-any-tool-result-call-id
      (CodexJsReplRunToolAnyToolResult
        $call-id
        $payload
        $tool-output
        $post-tool-use-payload))
   $call-id)

(= (codex:js-repl-run-tool-any-tool-result-payload
      (CodexJsReplRunToolAnyToolResult
        $call-id
        $payload
        $tool-output
        $post-tool-use-payload))
   $payload)

(= (codex:js-repl-run-tool-any-tool-result-tool-output
      (CodexJsReplRunToolAnyToolResult
        $call-id
        $payload
        $tool-output
        $post-tool-use-payload))
   $tool-output)

(= (codex:js-repl-run-tool-tool-output-serialization-failure
      $serde-error)
   (CodexJsReplRunToolToolOutputSerializationFailure $serde-error))

(= (codex:js-repl-run-tool-unserializable-response $serde-error)
   (CodexJsReplRunToolUnserializableResponse $serde-error))

(= (codex:js-repl-run-tool-any-tool-result-into-response
      (CodexJsReplRunToolAnyToolResult
        $call-id
        $payload
        (CodexJsReplRunToolToolOutputSerializationFailure $serde-error)
        $post-tool-use-payload))
   (codex:js-repl-run-tool-unserializable-response $serde-error))

(= (codex:js-repl-run-tool-any-tool-result-into-response
      (CodexJsReplRunToolAnyToolResult
        $call-id
        $payload
        $tool-output
        $post-tool-use-payload))
   (once
     (codex:tool-output-to-response-item
       $tool-output
       $call-id
       $payload)))

(= (codex:js-repl-run-tool-response-json-ok $json)
   (CodexJsReplRunToolResponseJsonOk $json))

(= (codex:js-repl-run-tool-response-json-error $error)
   (CodexJsReplRunToolResponseJsonError $error))

(= (codex:js-repl-run-tool-response-to-json
      (CodexJsReplRunToolUnserializableResponse $serde-error))
   (codex:js-repl-run-tool-response-json-error
     (format-args "failed to serialize tool output: {}" ($serde-error))))

(= (codex:js-repl-run-tool-response-to-json
      (CodexResponseItemFunctionCallOutput $call-id $output))
   (codex:js-repl-run-tool-response-json-ok
     (codex:item-json
       (CodexResponseItemFunctionCallOutput $call-id $output))))

(= (codex:js-repl-run-tool-response-to-json
      (CodexResponseItemCustomToolCallOutput $call-id $name $output))
   (codex:js-repl-run-tool-response-json-ok
     (codex:item-json
       (CodexResponseItemCustomToolCallOutput $call-id $name $output))))

(= (codex:js-repl-run-tool-response-to-json
      (CodexResponseItemMcpToolCallOutput $call-id $output))
   (codex:js-repl-run-tool-response-json-ok
     (codex:item-json
       (CodexResponseItemMcpToolCallOutput $call-id $output))))

(= (codex:js-repl-run-tool-response-to-json
      (CodexResponseItemToolSearchOutput $call-id $status $execution $tools))
   (codex:js-repl-run-tool-response-json-ok
     (codex:item-json
       (CodexResponseItemToolSearchOutput
         $call-id
         $status
         $execution
         $tools))))

(= (codex:js-repl-run-tool-dispatch-ok $any-tool-result)
   (CodexJsReplRunToolDispatchOk $any-tool-result))

(= (codex:js-repl-run-tool-dispatch-error $error)
   (CodexJsReplRunToolDispatchError $error))

(= (codex:js-repl-run-tool-dispatch-result-step-result
      $run-tool-result
      $actions)
   (CodexJsReplRunToolDispatchResultStepResult
     $run-tool-result
     $actions))

(= (codex:js-repl-run-tool-dispatch-result-step-result-run-tool-result
      (CodexJsReplRunToolDispatchResultStepResult
        $run-tool-result
        $actions))
   $run-tool-result)

(= (codex:js-repl-run-tool-dispatch-result-step-result-actions
      (CodexJsReplRunToolDispatchResultStepResult
        $run-tool-result
        $actions))
   $actions)

(= (codex:js-repl-run-tool-dispatch-result-success-step
      $request
      $response
      $json)
   (case $request
     (((CodexJsReplKernelToHostRunTool $id $exec-id $tool-name $arguments)
       (let $summary
         (codex:js-repl-summarize-tool-call-response $response)
         (codex:js-repl-run-tool-dispatch-result-step-result
           (codex:js-repl-run-tool-result
             $id
             True
             $json
             CodexAbsent)
           ((codex:js-repl-run-tool-request-action-log-tool-call-response
              $request
              True
              $summary
              $json
              CodexAbsent))))))))

(= (codex:js-repl-run-tool-dispatch-result-error-step
      $request
      $error)
   (case $request
     (((CodexJsReplKernelToHostRunTool $id $exec-id $tool-name $arguments)
       (let $summary
         (codex:js-repl-summarize-tool-call-error $error)
         (codex:js-repl-run-tool-dispatch-result-step-result
           (codex:js-repl-run-tool-result
             $id
             False
             CodexAbsent
             $error)
           ((codex:js-repl-run-tool-request-action-log-tool-call-response
              $request
              False
              $summary
              CodexAbsent
              $error))))))))

(= (codex:js-repl-run-tool-dispatch-result-ok-step
      $request
      $any-tool-result)
   (let $response
     (codex:js-repl-run-tool-any-tool-result-into-response
       $any-tool-result)
     (case (codex:js-repl-run-tool-response-to-json $response)
       (((CodexJsReplRunToolResponseJsonOk $json)
         (codex:js-repl-run-tool-dispatch-result-success-step
           $request
           $response
           $json))
        ((CodexJsReplRunToolResponseJsonError $error)
         (codex:js-repl-run-tool-dispatch-result-error-step
           $request
           $error))))))

(= (codex:js-repl-run-tool-dispatch-result-step
      $request
      $dispatch-result)
   (case $dispatch-result
     (((CodexJsReplRunToolDispatchOk $any-tool-result)
       (codex:js-repl-run-tool-dispatch-result-ok-step
         $request
         $any-tool-result))
      ((CodexJsReplRunToolDispatchError $error)
       (codex:js-repl-run-tool-dispatch-result-error-step
         $request
         $error)))))
