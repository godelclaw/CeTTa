; Rust-faithful ToolCallRuntime parallel-planning slice.
;
; This ports deterministic behavior from:
; - openai-codex/codex-rs/core/src/tools/parallel.rs
;   - ToolCallRuntime state shape
;   - handle_tool_call outer success/fatal/error mapping
;   - handle_tool_call_with_source parallel lock decision
;   - failure_response
;   - aborted_response
;   - abort_message
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust spawns a Tokio task, races cancellation with handler dispatch, and
;   uses an RwLock guard to serialize non-parallel tools. This pure CeTTa slice
;   emits the same dispatch plan, lock mode, abort output, and response mapping
;   data instead of performing async scheduling side effects.
; - Rust's ResponseInputItem::FunctionCallOutput and
;   CustomToolCallOutput carry FunctionCallOutputPayload.success = Some(false)
;   for failure_response. The current CeTTa protocol response body constructors
;   model text/content-items only, matching the existing protocol/context
;   surface until success metadata is ported.

!(import! &self context)
!(import! &self function_tool)
!(import! &self str)
!(import! &self tool_router_dispatch_plan)

(= (codex:tool-call-runtime
      $router
      $session
      $turn-context
      $tracker)
   (CodexToolCallRuntime
     $router
     $session
     $turn-context
     $tracker
     (CodexToolCallRuntimeParallelExecutionLock)))

(= (codex:tool-call-runtime-router
      (CodexToolCallRuntime
        $router
        $session
        $turn-context
        $tracker
        $parallel-execution))
   $router)

(= (codex:tool-call-runtime-session
      (CodexToolCallRuntime
        $router
        $session
        $turn-context
        $tracker
        $parallel-execution))
   $session)

(= (codex:tool-call-runtime-turn-context
      (CodexToolCallRuntime
        $router
        $session
        $turn-context
        $tracker
        $parallel-execution))
   $turn-context)

(= (codex:tool-call-runtime-tracker
      (CodexToolCallRuntime
        $router
        $session
        $turn-context
        $tracker
        $parallel-execution))
   $tracker)

(= (codex:tool-call-runtime-parallel-execution
      (CodexToolCallRuntime
        $router
        $session
        $turn-context
        $tracker
        $parallel-execution))
   $parallel-execution)

(= (codex:tool-call-runtime-lock-read)
   CodexToolCallRuntimeLockRead)

(= (codex:tool-call-runtime-lock-write)
   CodexToolCallRuntimeLockWrite)

(= (codex:tool-call-runtime-lock-mode $supports-parallel)
   (if $supports-parallel
       (codex:tool-call-runtime-lock-read)
       (codex:tool-call-runtime-lock-write)))

(= (codex:tool-call-runtime-dispatch-plan
      $supports-parallel
      $lock-mode
      $router-dispatch-plan)
   (CodexToolCallRuntimeDispatchPlan
     $supports-parallel
     $lock-mode
     $router-dispatch-plan))

(= (codex:tool-call-runtime-dispatch-plan-supports-parallel
      (CodexToolCallRuntimeDispatchPlan
        $supports-parallel
        $lock-mode
        $router-dispatch-plan))
   $supports-parallel)

(= (codex:tool-call-runtime-dispatch-plan-lock-mode
      (CodexToolCallRuntimeDispatchPlan
        $supports-parallel
        $lock-mode
        $router-dispatch-plan))
   $lock-mode)

(= (codex:tool-call-runtime-dispatch-plan-router-dispatch-plan
      (CodexToolCallRuntimeDispatchPlan
        $supports-parallel
        $lock-mode
        $router-dispatch-plan))
   $router-dispatch-plan)

(= (codex:tool-call-runtime-handle-tool-call-with-source-plan
      (CodexToolCallRuntime
        $router
        $session
        $turn-context
        $tracker
        $parallel-execution)
      $call
      $source
      $cancellation-token)
   (let $supports-parallel
     (codex:tool-router-tool-supports-parallel $router $call)
     (codex:tool-call-runtime-dispatch-plan
       $supports-parallel
       (codex:tool-call-runtime-lock-mode $supports-parallel)
       (codex:tool-router-dispatch-tool-call-with-code-mode-result-plan
         $router
         $session
         $turn-context
         $cancellation-token
         $tracker
         $call
         $source))))

(= (codex:tool-call-runtime-any-tool-result
      $call-id
      $payload
      $tool-output
      $post-tool-use-payload)
   (CodexAnyToolResult
     $call-id
     $payload
     $tool-output
     $post-tool-use-payload))

(= (codex:tool-call-runtime-any-tool-result-call-id
      (CodexAnyToolResult
        $call-id
        $payload
        $tool-output
        $post-tool-use-payload))
   $call-id)

(= (codex:tool-call-runtime-any-tool-result-payload
      (CodexAnyToolResult
        $call-id
        $payload
        $tool-output
        $post-tool-use-payload))
   $payload)

(= (codex:tool-call-runtime-any-tool-result-tool-output
      (CodexAnyToolResult
        $call-id
        $payload
        $tool-output
        $post-tool-use-payload))
   $tool-output)

(= (codex:tool-call-runtime-any-tool-result-post-tool-use-payload
      (CodexAnyToolResult
        $call-id
        $payload
        $tool-output
        $post-tool-use-payload))
   $post-tool-use-payload)

(= (codex:tool-call-runtime-any-tool-result-into-response
      (CodexAnyToolResult
        $call-id
        $payload
        $tool-output
        $post-tool-use-payload))
   (once
     (codex:tool-output-to-response-item
       $tool-output
       $call-id
       $payload)))

(= (codex:tool-call-runtime-dispatch-ok $any-tool-result)
   (CodexToolCallRuntimeDispatchOk $any-tool-result))

(= (codex:tool-call-runtime-dispatch-error $error)
   (CodexToolCallRuntimeDispatchError $error))

(= (codex:tool-call-runtime-handle-result-ok $response-input-item)
   (CodexToolCallRuntimeHandleResultOk $response-input-item))

(= (codex:tool-call-runtime-handle-result-fatal $message)
   (CodexToolCallRuntimeHandleResultFatal $message))

(= (codex:tool-call-runtime-handle-result-response
      (CodexToolCallRuntimeHandleResultOk $response-input-item))
   $response-input-item)

(= (codex:tool-call-runtime-handle-result-fatal-message
      (CodexToolCallRuntimeHandleResultFatal $message))
   $message)

(= (codex:tool-call-runtime-handle-tool-call-dispatch-result
      $call
      (CodexToolCallRuntimeDispatchOk $any-tool-result))
   (codex:tool-call-runtime-handle-result-ok
     (codex:tool-call-runtime-any-tool-result-into-response
       $any-tool-result)))

(= (codex:tool-call-runtime-handle-tool-call-dispatch-result
      $call
      (CodexToolCallRuntimeDispatchError
        (CodexFunctionCallErrorFatal $message)))
   (codex:tool-call-runtime-handle-result-fatal $message))

(= (codex:tool-call-runtime-handle-tool-call-dispatch-result
      $call
      (CodexToolCallRuntimeDispatchError
        (CodexFunctionCallErrorRespondToModel $message)))
   (codex:tool-call-runtime-handle-result-ok
     (codex:tool-call-runtime-failure-response
       $call
       (CodexFunctionCallErrorRespondToModel $message))))

(= (codex:tool-call-runtime-handle-tool-call-dispatch-result
      $call
      (CodexToolCallRuntimeDispatchError
        (CodexFunctionCallErrorMissingLocalShellCallId)))
   (codex:tool-call-runtime-handle-result-ok
     (codex:tool-call-runtime-failure-response
       $call
       (CodexFunctionCallErrorMissingLocalShellCallId))))

(= (codex:tool-call-runtime-failure-response
      (CodexToolCall
        $tool-name
        $call-id
        (CodexToolPayloadToolSearch $query $limit))
      $error)
   (CodexResponseItemToolSearchOutput
     $call-id
     "completed"
     "client"
     ()))

(= (codex:tool-call-runtime-failure-response
      (CodexToolCall
        $tool-name
        $call-id
        (CodexToolPayloadCustom $input))
      $error)
   (CodexResponseItemCustomToolCallOutput
     $call-id
     CodexAbsent
     (CodexFunctionCallOutputText
       (codex:function-call-error-display $error))))

(= (codex:tool-call-runtime-failure-response
      (CodexToolCall
        $tool-name
        $call-id
        (CodexToolPayloadMcp $server $tool $raw-arguments))
      $error)
   (CodexResponseItemFunctionCallOutput
     $call-id
     (CodexFunctionCallOutputText
       (codex:function-call-error-display $error))))

(= (codex:tool-call-runtime-failure-response
      (CodexToolCall
        $tool-name
        $call-id
        (CodexToolPayloadFunction $arguments))
      $error)
   (CodexResponseItemFunctionCallOutput
     $call-id
     (CodexFunctionCallOutputText
       (codex:function-call-error-display $error))))

(= (codex:tool-call-runtime-failure-response
      (CodexToolCall
        $tool-name
        $call-id
        (CodexToolPayloadLocalShell $command))
      $error)
   (CodexResponseItemFunctionCallOutput
     $call-id
     (CodexFunctionCallOutputText
       (codex:function-call-error-display $error))))

(= (codex:tool-call-runtime-failure-response
      (CodexToolCall
        $tool-name
        $call-id
        (CodexToolPayloadLocalShellParams
          $command
          $workdir
          $timeout-ms
          $sandbox-permissions
          $prefix-rule
          $additional-permissions
          $justification))
      $error)
   (CodexResponseItemFunctionCallOutput
     $call-id
     (CodexFunctionCallOutputText
       (codex:function-call-error-display $error))))

(= (codex:tool-call-runtime-strip-trailing-dot-zero $text)
   (if (str-ends-with? $text ".0")
       (str-slice $text 0 (- (str-length $text) 2))
       $text))

(= (codex:tool-call-runtime-number-text $value)
   (codex:tool-call-runtime-strip-trailing-dot-zero
     (format-args "{}" ($value))))

(= (codex:tool-call-runtime-one-decimal-seconds-text $secs)
   (let $tenths
     (trunc-math (round-math (* $secs 10)))
     (let $whole (trunc-math (/ $tenths 10))
       (let $fraction (% $tenths 10)
         (str-concat
           (codex:tool-call-runtime-number-text $whole)
           (str-concat
             "."
             (codex:tool-call-runtime-number-text $fraction)))))))

(= (codex:tool-call-runtime-min-abort-seconds $secs)
   (if (< $secs 0.1)
       0.1
       $secs))

(= (codex:tool-call-runtime-shell-like-tool-name
      (CodexToolName $name $namespace))
   (and (== $namespace CodexAbsent)
        (or (== $name "shell")
            (or (== $name "container.exec")
                (or (== $name "local_shell")
                    (or (== $name "shell_command")
                        (== $name "unified_exec")))))))

(= (codex:tool-call-runtime-abort-message
      (CodexToolCall $tool-name $call-id $payload)
      $secs)
   (let $secs-text
     (codex:tool-call-runtime-one-decimal-seconds-text $secs)
     (if (codex:tool-call-runtime-shell-like-tool-name $tool-name)
         (str-concat
           "Wall time: "
           (str-concat
             $secs-text
             " seconds\naborted by user"))
         (str-concat
           "aborted by user after "
           (str-concat $secs-text "s")))))

(= (codex:tool-call-runtime-aborted-response
      (CodexToolCall $tool-name $call-id $payload)
      $secs)
   (codex:tool-call-runtime-any-tool-result
     $call-id
     $payload
     (CodexToolOutputAborted
       (codex:tool-call-runtime-abort-message
         (CodexToolCall $tool-name $call-id $payload)
         $secs))
     CodexAbsent))

(= (codex:tool-call-runtime-cancelled-response
      $call
      $elapsed-secs)
   (codex:tool-call-runtime-aborted-response
     $call
     (codex:tool-call-runtime-min-abort-seconds $elapsed-secs)))
