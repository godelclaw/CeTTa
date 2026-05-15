; Visible update_plan slice for the restarted Codex port.
;
; This ports the narrow update_plan path from:
; - openai-codex/codex-rs/protocol/src/plan_tool.rs
; - openai-codex/codex-rs/core/src/tools/handlers/plan.rs
;
; Covered in this increment:
; - Rust-shaped StepStatus / PlanItemArg / UpdatePlanArgs values
; - JSON rendering and decoding for the update_plan argument payload
; - Plan-mode rejection and unsupported-payload handling from the handler
; - deterministic local handler output plus the emitted PlanUpdate payload
;
; Required slice-local deviations from Rust, documented for later audit:
; - Rust sends `EventMsg::PlanUpdate(UpdatePlanArgs)` through the async session
;   event loop. The restarted CeTTa slice has no session/event runtime yet, so
;   the handler result carries the emitted UpdatePlanArgs payload directly.
; - Rust's update_plan tool is a function tool. The restarted visible CeTTa
;   tool-call surface still lowers tool execution through custom tool call items,
;   so `run-update-plan-tool-call*` returns the same `Plan updated` text through
;   custom_tool_call_output items until the broader tool registry lands.
; - Rust uses serde's exact parse diagnostics. This slice preserves the same
;   failure causes and outer `failed to parse function arguments:` prefix, but
;   some inner wording is reconstructed because the current CeTTa JSON helpers
;   do not expose serde-style typed error details.

!(import! &self json)
!(import! &self protocol)
!(import! &self request_user_input)

(= (codex:update-plan-tool-name)
   "update_plan")

(= (codex:update-plan-tool-description)
   "Updates the task plan.\nProvide an optional explanation and a list of plan items, each with a step and status.\nAt most one step can be in_progress at a time.\n")

(= (codex:update-plan-updated-message)
   "Plan updated")

(= (codex:update-plan-unsupported-payload-message)
   "update_plan handler received unsupported payload")

(= (codex:update-plan-plan-mode-message)
   "update_plan is a TODO/checklist tool and is not allowed in Plan mode")

(= (codex:update-plan-step-status-pending)
   (CodexUpdatePlanStepStatusPending))

(= (codex:update-plan-step-status-in-progress)
   (CodexUpdatePlanStepStatusInProgress))

(= (codex:update-plan-step-status-completed)
   (CodexUpdatePlanStepStatusCompleted))

(= (codex:update-plan-step-status-text (CodexUpdatePlanStepStatusPending))
   "pending")

(= (codex:update-plan-step-status-text (CodexUpdatePlanStepStatusInProgress))
   "in_progress")

(= (codex:update-plan-step-status-text (CodexUpdatePlanStepStatusCompleted))
   "completed")

(= (codex:update-plan-step $step $status)
   (CodexUpdatePlanStep $step $status))

(= (codex:update-plan-step-text (CodexUpdatePlanStep $step $status))
   $step)

(= (codex:update-plan-step-status (CodexUpdatePlanStep $step $status))
   $status)

(= (codex:update-plan-args $explanation $plan)
   (CodexUpdatePlanArgs $explanation $plan))

(= (codex:update-plan-args-without-explanation $plan)
   (CodexUpdatePlanArgs CodexAbsent $plan))

(= (codex:update-plan-args-explanation
      (CodexUpdatePlanArgs $explanation $plan))
   $explanation)

(= (codex:update-plan-args-plan
      (CodexUpdatePlanArgs $explanation $plan))
   $plan)

(= (codex:update-plan-function-payload $arguments)
   (CodexUpdatePlanPayloadFunction $arguments))

(= (codex:update-plan-unsupported-payload $payload-kind)
   (CodexUpdatePlanPayloadUnsupported $payload-kind))

(= (codex:update-plan-handler-context $mode)
   (CodexUpdatePlanHandlerContext $mode))

(= (codex:default-update-plan-handler-context)
   (codex:update-plan-handler-context
     (codex:collaboration-mode-default)))

(= (codex:update-plan-handler-context-mode
      (CodexUpdatePlanHandlerContext $mode))
   $mode)

(= (codex:update-plan-handler-result-type
      (CodexUpdatePlanHandlerResultSuccess $event $output-text))
   "success")

(= (codex:update-plan-handler-result-type
      (CodexUpdatePlanHandlerResultError $message))
   "error")

(= (codex:update-plan-handler-result-event
      (CodexUpdatePlanHandlerResultSuccess $event $output-text))
   $event)

(= (codex:update-plan-handler-result-output-text
      (CodexUpdatePlanHandlerResultSuccess $event $output-text))
   $output-text)

(= (codex:update-plan-handler-result-message
      (CodexUpdatePlanHandlerResultError $message))
   $message)

(= (codex:update-plan-optional-string-json $value)
   (if (== $value CodexAbsent)
       JsonNull
       (JsonString $value)))

(= (codex:update-plan-step-json (CodexUpdatePlanStep $step $status))
   (JsonObject
     ((JsonPair "step" (JsonString $step))
      (JsonPair "status"
        (JsonString (codex:update-plan-step-status-text $status))))))

(= (codex:update-plan-steps-json $steps)
   (function
     (let $json-steps
       (eval (map-atom $steps $step (codex:update-plan-step-json $step)))
       (return (JsonArray $json-steps)))))

(= (codex:update-plan-args-json (CodexUpdatePlanArgs $explanation $plan))
   (JsonObject
     ((JsonPair "explanation" (codex:update-plan-optional-string-json $explanation))
      (JsonPair "plan" (codex:update-plan-steps-json $plan)))))

(= (codex:update-plan-event-json $event)
   (codex:update-plan-args-json $event))

(= (codex:update-plan-parse-ok $value)
   (CodexUpdatePlanParseOk $value))

(= (codex:update-plan-parse-error $message)
   (CodexUpdatePlanParseError $message))

(= (codex:update-plan-parse-result-message
      (CodexUpdatePlanParseError $message))
   $message)

(= (codex:update-plan-json-object-optional-value $object $key)
   (case (json-object-get $object $key)
     ((Empty CodexAbsent)
      (JsonNull CodexAbsent)
      ($value $value))))

(= (codex:update-plan-json-object-optional-string-result $object $key)
   (case (codex:update-plan-json-object-optional-value $object $key)
     ((CodexAbsent (codex:update-plan-parse-ok CodexAbsent))
      ((JsonString $text) (codex:update-plan-parse-ok $text))
      ($other
       (codex:update-plan-parse-error
         (format-args "invalid type for `{}`; expected string or null" ($key)))))))

(= (codex:update-plan-json-object-required-string-result $object $key)
   (case (json-object-get $object $key)
     ((Empty
       (codex:update-plan-parse-error
         (format-args "missing field `{}`" ($key))))
      (JsonNull
       (codex:update-plan-parse-error
         (format-args "missing field `{}`" ($key))))
      ((JsonString $text) (codex:update-plan-parse-ok $text))
      ($other
       (codex:update-plan-parse-error
         (format-args "invalid type for `{}`; expected string" ($key)))))))

(= (codex:update-plan-json-object-required-array-result $object $key)
   (case (json-object-get $object $key)
     ((Empty
       (codex:update-plan-parse-error
         (format-args "missing field `{}`" ($key))))
      (JsonNull
       (codex:update-plan-parse-error
         (format-args "missing field `{}`" ($key))))
      ((JsonArray $items) (codex:update-plan-parse-ok $items))
      ($other
       (codex:update-plan-parse-error
         (format-args "invalid type for `{}`; expected array" ($key)))))))

(= (codex:update-plan-step-status-from-text $text)
   (if (== $text "pending")
       (codex:update-plan-parse-ok (codex:update-plan-step-status-pending))
       (if (== $text "in_progress")
           (codex:update-plan-parse-ok
             (codex:update-plan-step-status-in-progress))
           (if (== $text "completed")
               (codex:update-plan-parse-ok
                 (codex:update-plan-step-status-completed))
               (codex:update-plan-parse-error
                 (format-args
                   "unknown variant `{}`, expected one of `pending`, `in_progress`, `completed`"
                   ($text)))))))

(= (codex:update-plan-step-from-status-result
      $step
      (CodexUpdatePlanParseOk $status))
   (codex:update-plan-parse-ok
     (codex:update-plan-step $step $status)))

(= (codex:update-plan-step-from-status-result
      $step
      (CodexUpdatePlanParseError $message))
   (codex:update-plan-parse-error $message))

(= (codex:parse-update-plan-step-object $object)
   (case (codex:update-plan-json-object-required-string-result $object "step")
     (((CodexUpdatePlanParseError $message)
       (codex:update-plan-parse-error $message))
      ((CodexUpdatePlanParseOk $step)
       (case (codex:update-plan-json-object-required-string-result $object "status")
         (((CodexUpdatePlanParseError $message)
           (codex:update-plan-parse-error $message))
          ((CodexUpdatePlanParseOk $status-text)
           (codex:update-plan-step-from-status-result
             $step
             (codex:update-plan-step-status-from-text $status-text)))))))))

(= (codex:parse-update-plan-step $json)
   (case $json
     (((JsonObject $pairs)
       (codex:parse-update-plan-step-object (JsonObject $pairs)))
      ($other
       (codex:update-plan-parse-error
         "invalid plan item; expected object")))))

(= (codex:parse-update-plan-steps ())
   (codex:update-plan-parse-ok ()))

(= (codex:update-plan-prepend-step-result
      $step
      (CodexUpdatePlanParseOk $tail-steps))
   (codex:update-plan-parse-ok
     (cons-atom $step $tail-steps)))

(= (codex:update-plan-prepend-step-result
      $step
      (CodexUpdatePlanParseError $message))
   (codex:update-plan-parse-error $message))

(= (codex:parse-update-plan-steps $items)
   (let ($head $tail) (decons-atom $items)
     (case (codex:parse-update-plan-step $head)
       (((CodexUpdatePlanParseError $message)
         (codex:update-plan-parse-error $message))
        ((CodexUpdatePlanParseOk $step)
         (codex:update-plan-prepend-step-result
           $step
           (codex:parse-update-plan-steps $tail)))))))

(= (codex:update-plan-build-args-result
      $explanation
      (CodexUpdatePlanParseOk $plan))
   (codex:update-plan-parse-ok
     (codex:update-plan-args $explanation $plan)))

(= (codex:update-plan-build-args-result
      $explanation
      (CodexUpdatePlanParseError $message))
   (codex:update-plan-parse-error $message))

(= (codex:parse-update-plan-args-object $object)
   (case (codex:update-plan-json-object-optional-string-result
           $object
           "explanation")
     (((CodexUpdatePlanParseError $message)
       (codex:update-plan-parse-error $message))
      ((CodexUpdatePlanParseOk $explanation)
       (case (codex:update-plan-json-object-required-array-result $object "plan")
         (((CodexUpdatePlanParseError $message)
           (codex:update-plan-parse-error $message))
          ((CodexUpdatePlanParseOk $plan-items)
           (codex:update-plan-build-args-result
             $explanation
             (codex:parse-update-plan-steps $plan-items)))))))))

(= (codex:parse-update-plan-args $input)
   (case (json-parse $input)
     (((JsonObject $pairs)
       (codex:parse-update-plan-args-object (JsonObject $pairs)))
      ($other
       (codex:update-plan-parse-error
         "invalid type: expected object")))))

(= (codex:handle-update-plan-function $context $arguments)
   (if (==
         (codex:update-plan-handler-context-mode $context)
         (codex:collaboration-mode-plan))
       (CodexUpdatePlanHandlerResultError
         (codex:update-plan-plan-mode-message))
       (case (codex:parse-update-plan-args $arguments)
         (((CodexUpdatePlanParseOk $args)
           (CodexUpdatePlanHandlerResultSuccess
             $args
             (codex:update-plan-updated-message)))
          ((CodexUpdatePlanParseError $message)
           (CodexUpdatePlanHandlerResultError
             (str-concat
               "failed to parse function arguments: "
               $message)))))))

(= (codex:handle-update-plan-payload $context $call-id $payload)
   (case $payload
     (((CodexUpdatePlanPayloadFunction $arguments)
       (codex:handle-update-plan-function $context $arguments))
      ((CodexUpdatePlanPayloadUnsupported $payload-kind)
       (CodexUpdatePlanHandlerResultError
         (codex:update-plan-unsupported-payload-message))))))

(= (codex:run-update-plan-tool-call-with-context $context $call-id $input)
   (case
     (codex:handle-update-plan-payload
       $context
       $call-id
       (codex:update-plan-function-payload $input))
     (((CodexUpdatePlanHandlerResultSuccess $event $output-text)
       (codex:tool-result $call-id $output-text))
      ((CodexUpdatePlanHandlerResultError $message)
       (codex:tool-result $call-id $message)))))

(= (codex:run-update-plan-tool-call $call-id $input)
   (codex:run-update-plan-tool-call-with-context
     (codex:default-update-plan-handler-context)
     $call-id
     $input))
