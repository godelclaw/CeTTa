; Rust-faithful code-mode execute handler planning slice.
;
; This ports deterministic behavior from:
; - openai-codex/codex-rs/core/src/tools/code_mode/execute_handler.rs
;   - CodeModeExecuteHandler payload/tool-name gate
;   - parse_exec_source error mapping
;   - execute request construction
;   - start_code_cell_trace / record_initial_response / record_ended order
;   - runtime response handling through handle_runtime_response
; - openai-codex/codex-rs/code-mode/src/runtime/mod.rs
;   - ExecuteRequest shape consumed by CodeModeService::execute
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust obtains enabled tools, stored values, and an allocated runtime cell id
;   from async session services before executing. This pure slice receives those
;   values explicitly and emits the same ExecuteRequest plus trace actions.
; - Rust calls CodeModeService::execute asynchronously. This slice consumes the
;   resulting RuntimeResponse through an explicit completion function.
; - Rust records trace side effects before producing model-visible output. This
;   slice returns those actions before runtime-response actions, preserving the
;   same order.

!(import! &self code_mode_exec_source)
!(import! &self code_mode_runtime_response)
!(import! &self function_tool)
!(import! &self list)
!(import! &self tool_name)

(= (codex:code-mode-execute-public-tool-name)
   "exec")

(= (codex:code-mode-execute-is-tool-name
      (CodexToolName $name $namespace))
   (and (== $namespace CodexAbsent)
        (== $name (codex:code-mode-execute-public-tool-name))))

(= (codex:code-mode-execute-request
      $cell-id
      $tool-call-id
      $enabled-tools
      $source
      $stored-values
      $yield-time-ms
      $max-output-tokens)
   (CodexCodeModeExecuteRequest
     $cell-id
     $tool-call-id
     $enabled-tools
     $source
     $stored-values
     $yield-time-ms
     $max-output-tokens))

(= (codex:code-mode-execute-request-cell-id
      (CodexCodeModeExecuteRequest
        $cell-id
        $tool-call-id
        $enabled-tools
        $source
        $stored-values
        $yield-time-ms
        $max-output-tokens))
   $cell-id)

(= (codex:code-mode-execute-request-tool-call-id
      (CodexCodeModeExecuteRequest
        $cell-id
        $tool-call-id
        $enabled-tools
        $source
        $stored-values
        $yield-time-ms
        $max-output-tokens))
   $tool-call-id)

(= (codex:code-mode-execute-request-enabled-tools
      (CodexCodeModeExecuteRequest
        $cell-id
        $tool-call-id
        $enabled-tools
        $source
        $stored-values
        $yield-time-ms
        $max-output-tokens))
   $enabled-tools)

(= (codex:code-mode-execute-request-source
      (CodexCodeModeExecuteRequest
        $cell-id
        $tool-call-id
        $enabled-tools
        $source
        $stored-values
        $yield-time-ms
        $max-output-tokens))
   $source)

(= (codex:code-mode-execute-request-stored-values
      (CodexCodeModeExecuteRequest
        $cell-id
        $tool-call-id
        $enabled-tools
        $source
        $stored-values
        $yield-time-ms
        $max-output-tokens))
   $stored-values)

(= (codex:code-mode-execute-request-yield-time-ms
      (CodexCodeModeExecuteRequest
        $cell-id
        $tool-call-id
        $enabled-tools
        $source
        $stored-values
        $yield-time-ms
        $max-output-tokens))
   $yield-time-ms)

(= (codex:code-mode-execute-request-max-output-tokens
      (CodexCodeModeExecuteRequest
        $cell-id
        $tool-call-id
        $enabled-tools
        $source
        $stored-values
        $yield-time-ms
        $max-output-tokens))
   $max-output-tokens)

(= (codex:code-mode-execute-action-start-trace
      $turn-sub-id
      $runtime-cell-id
      $call-id
      $source)
   (CodexCodeModeExecuteActionStartTrace
     $turn-sub-id
     $runtime-cell-id
     $call-id
     $source))

(= (codex:code-mode-execute-action-record-initial-response
      $runtime-cell-id
      $response)
   (CodexCodeModeExecuteActionRecordInitialResponse
     $runtime-cell-id
     $response))

(= (codex:code-mode-execute-action-record-ended
      $runtime-cell-id
      $response)
   (CodexCodeModeExecuteActionRecordEnded
     $runtime-cell-id
     $response))

(= (codex:code-mode-execute-invocation-plan
      $parsed-source
      $request
      $actions)
   (CodexCodeModeExecuteInvocationPlan
     $parsed-source
     $request
     $actions))

(= (codex:code-mode-execute-invocation-plan-parsed-source
      (CodexCodeModeExecuteInvocationPlan
        $parsed-source
        $request
        $actions))
   $parsed-source)

(= (codex:code-mode-execute-invocation-plan-request
      (CodexCodeModeExecuteInvocationPlan
        $parsed-source
        $request
        $actions))
   $request)

(= (codex:code-mode-execute-invocation-plan-actions
      (CodexCodeModeExecuteInvocationPlan
        $parsed-source
        $request
        $actions))
   $actions)

(= (codex:code-mode-execute-error-message)
   "exec expects raw JavaScript source text")

(= (codex:plan-code-mode-execute-invocation
      (CodexToolName $name $namespace)
      $payload
      $call-id
      $turn-sub-id
      $enabled-tools
      $stored-values
      $runtime-cell-id)
   (if (codex:code-mode-execute-is-tool-name
         (CodexToolName $name $namespace))
       (case $payload
         (((CodexToolPayloadCustom $input)
           (case (codex:parse-code-mode-exec-source $input)
             (((CodexCodeModeExecSourceParseOk $parsed-source)
               (let $source
                 (codex:code-mode-parsed-exec-source-code
                   $parsed-source)
                 (codex:code-mode-execute-invocation-plan
                   $parsed-source
                   (codex:code-mode-execute-request
                     $runtime-cell-id
                     $call-id
                     $enabled-tools
                     $source
                     $stored-values
                     (codex:code-mode-parsed-exec-source-yield-time-ms
                       $parsed-source)
                     (codex:code-mode-parsed-exec-source-max-output-tokens
                       $parsed-source))
                   ((codex:code-mode-execute-action-start-trace
                      $turn-sub-id
                      $runtime-cell-id
                      $call-id
                      $source)))))
              ((CodexCodeModeExecSourceParseError $message)
               (codex:function-call-error-respond-to-model $message)))))
          ($other
           (codex:function-call-error-respond-to-model
             (codex:code-mode-execute-error-message)))))
       (codex:function-call-error-respond-to-model
         (codex:code-mode-execute-error-message))))

(= (codex:code-mode-execute-runtime-response-is-yielded $response)
   (case $response
     (((CodexCodeModeRuntimeResponseYielded $cell-id $content-items)
       True)
      ($other False))))

(= (codex:code-mode-execute-ended-actions
      $runtime-cell-id
      $response)
   (if (codex:code-mode-execute-runtime-response-is-yielded $response)
       ()
       ((codex:code-mode-execute-action-record-ended
          $runtime-cell-id
          $response))))

(= (codex:code-mode-execute-completion-plan
      $tool-output
      $actions)
   (CodexCodeModeExecuteCompletionPlan $tool-output $actions))

(= (codex:code-mode-execute-completion-plan-output
      (CodexCodeModeExecuteCompletionPlan $tool-output $actions))
   $tool-output)

(= (codex:code-mode-execute-completion-plan-actions
      (CodexCodeModeExecuteCompletionPlan $tool-output $actions))
   $actions)

(= (codex:complete-code-mode-execute-response
      $invocation-plan
      $response
      $elapsed-secs
      $can-request-original-image-detail)
   (let $parsed-source
     (codex:code-mode-execute-invocation-plan-parsed-source
       $invocation-plan)
     (let $request
       (codex:code-mode-execute-invocation-plan-request
         $invocation-plan)
       (let $runtime-plan
         (codex:handle-code-mode-runtime-response
           $response
           $can-request-original-image-detail
           (codex:code-mode-parsed-exec-source-max-output-tokens
             $parsed-source)
           $elapsed-secs)
         (let $runtime-cell-id
           (codex:code-mode-execute-request-cell-id $request)
           (codex:code-mode-execute-completion-plan
             (codex:code-mode-runtime-response-plan-output
               $runtime-plan)
             (list:append
               ((codex:code-mode-execute-action-record-initial-response
                  $runtime-cell-id
                  $response))
               (list:append
                 (codex:code-mode-execute-ended-actions
                   $runtime-cell-id
                   $response)
                 (codex:code-mode-runtime-response-plan-actions
                   $runtime-plan)))))))))
