; Rust-faithful DynamicToolHandler planning slice.
;
; This ports deterministic behavior from:
; - openai-codex/codex-rs/core/src/tools/handlers/dynamic.rs
;
; Covered in this increment:
; - handler kind and unsupported-payload error
; - JSON argument parsing for ToolPayload::Function
; - DynamicToolCallRequest event construction
; - DynamicToolCallResponse event construction for received and cancelled
;   responses
; - DynamicToolResponse content conversion into FunctionToolOutput
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust stores a borrowed TurnContext in ToolInvocation and reads
;   `turn_context.sub_id`. This pure CeTTa plan boundary represents the turn by
;   its sub_id atom so the event-building algorithm remains visible without
;   introducing async Session/TurnContext storage yet.
; - Rust registers a oneshot sender in active turn state, awaits a response,
;   and sends events through Session. This slice emits explicit start/complete
;   plans describing those side effects; the async runtime wiring is still a
;   later porting step.

!(import! &self context)
!(import! &self dynamic_tools)
!(import! &self function_tool)
!(import! &self json)
!(import! &self protocol)
!(import! &self tool_handler_common)
!(import! &self tool_name)

(= (codex:dynamic-tool-handler-kind)
   "function")

(= (codex:dynamic-tool-handler-unsupported-payload-message)
   "dynamic tool handler received unsupported payload")

(= (codex:dynamic-tool-handler-cancelled-message)
   "dynamic tool call was cancelled before receiving a response")

(= (codex:dynamic-tool-handler-start-plan-ok $event)
   (CodexDynamicToolHandlerStartPlanOk $event))

(= (codex:dynamic-tool-handler-start-plan-error $error)
   (CodexDynamicToolHandlerStartPlanError $error))

(= (codex:dynamic-tool-handler-start-plan-event
      (CodexDynamicToolHandlerStartPlanOk $event))
   $event)

(= (codex:dynamic-tool-handler-start-plan-error-value
      (CodexDynamicToolHandlerStartPlanError $error))
   $error)

(= (codex:dynamic-tool-handler-complete-plan-ok $event $output)
   (CodexDynamicToolHandlerCompletePlanOk $event $output))

(= (codex:dynamic-tool-handler-complete-plan-error $event $error)
   (CodexDynamicToolHandlerCompletePlanError $event $error))

(= (codex:dynamic-tool-handler-complete-plan-event
      (CodexDynamicToolHandlerCompletePlanOk $event $output))
   $event)

(= (codex:dynamic-tool-handler-complete-plan-event
      (CodexDynamicToolHandlerCompletePlanError $event $error))
   $event)

(= (codex:dynamic-tool-handler-complete-plan-output
      (CodexDynamicToolHandlerCompletePlanOk $event $output))
   $output)

(= (codex:dynamic-tool-handler-complete-plan-error-value
      (CodexDynamicToolHandlerCompletePlanError $event $error))
   $error)

(= (codex:dynamic-tool-handler-parse-arguments-ok $arguments)
   (CodexDynamicToolHandlerParseArgumentsOk $arguments))

(= (codex:dynamic-tool-handler-parse-arguments-error $error)
   (CodexDynamicToolHandlerParseArgumentsError $error))

(= (codex:dynamic-tool-handler-parse-arguments $arguments)
   (case (json-parse $arguments)
     (((Error $source $message)
       (codex:dynamic-tool-handler-parse-arguments-error
         (CodexFunctionCallErrorRespondToModel
           (codex:function-arguments-parse-error-message $message))))
      ($json
       (codex:dynamic-tool-handler-parse-arguments-ok $json)))))

(= (codex:dynamic-tool-handler-output-item
      (CodexDynamicToolCallOutputContentItemInputText $text))
   (CodexInputText $text))

(= (codex:dynamic-tool-handler-output-item
      (CodexDynamicToolCallOutputContentItemInputImage $image-url))
   (CodexInputImage $image-url (codex:default-image-detail)))

(= (codex:dynamic-tool-handler-output-items $content-items)
   (map-atom-strict
     $content-items
     $item
     (codex:dynamic-tool-handler-output-item $item)))

(= (codex:dynamic-tool-handler-output-from-response
      (CodexDynamicToolResponse $content-items $success))
   (codex:function-tool-output-from-content
     (codex:dynamic-tool-handler-output-items $content-items)
     $success))

(= (codex:dynamic-tool-handler-start-plan-from-function
      $turn-id
      $call-id
      (CodexToolName $tool $namespace)
      $arguments)
   (case (codex:dynamic-tool-handler-parse-arguments $arguments)
     (((CodexDynamicToolHandlerParseArgumentsOk $json)
       (codex:dynamic-tool-handler-start-plan-ok
         (codex:dynamic-tool-call-request-event
           $call-id
           $turn-id
           $namespace
           $tool
           $json)))
      ((CodexDynamicToolHandlerParseArgumentsError $error)
       (codex:dynamic-tool-handler-start-plan-error $error)))))

(= (codex:dynamic-tool-handler-start-plan
      $turn-id
      $call-id
      $tool-name
      $payload)
   (case $payload
     (((CodexToolPayloadFunction $arguments)
       (codex:dynamic-tool-handler-start-plan-from-function
         $turn-id
         $call-id
         $tool-name
         $arguments))
      ($other
       (codex:dynamic-tool-handler-start-plan-error
         (CodexFunctionCallErrorRespondToModel
           (codex:dynamic-tool-handler-unsupported-payload-message)))))))

(= (codex:dynamic-tool-handler-complete-plan
      (CodexDynamicToolHandlerStartPlanOk
        (CodexEventDynamicToolCallRequest
          $call-id
          $turn-id
          $namespace
          $tool
          $arguments))
      (CodexDynamicToolResponse $content-items $success)
      $duration)
   (codex:dynamic-tool-handler-complete-plan-ok
     (codex:dynamic-tool-call-response-event
       $call-id
       $turn-id
       $namespace
       $tool
       $arguments
       $content-items
       $success
       CodexAbsent
       $duration)
     (codex:dynamic-tool-handler-output-from-response
       (CodexDynamicToolResponse $content-items $success))))

(= (codex:dynamic-tool-handler-complete-plan
      (CodexDynamicToolHandlerStartPlanOk
        (CodexEventDynamicToolCallRequest
          $call-id
          $turn-id
          $namespace
          $tool
          $arguments))
      CodexAbsent
      $duration)
   (codex:dynamic-tool-handler-complete-plan-error
     (codex:dynamic-tool-call-response-event
       $call-id
       $turn-id
       $namespace
       $tool
       $arguments
       ()
       False
       (codex:dynamic-tool-handler-cancelled-message)
       $duration)
     (CodexFunctionCallErrorRespondToModel
       (codex:dynamic-tool-handler-cancelled-message))))
