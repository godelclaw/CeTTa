; Visible request_user_input slice for the restarted Codex port.
;
; This ports the narrow request_user_input path from:
; - openai-codex/codex-rs/protocol/src/request_user_input.rs
; - openai-codex/codex-rs/tools/src/request_user_input_tool.rs
; - openai-codex/codex-rs/core/src/tools/handlers/request_user_input.rs
;
; Covered in this increment:
; - Rust-shaped request/response/event protocol values and JSON rendering
; - availability, description, and argument-normalization behavior
; - root-thread checks and supported-payload checks from the handler
; - deterministic local execution through canned responses or cancellation
;
; Required slice-local deviations from Rust, documented for later audit:
; - Rust wires request_user_input through the async session/event loop and waits
;   on a pending responder. The restarted CeTTa slice does not yet have that
;   session layer, so the handler context carries a canned response or a
;   cancellation marker directly.
; - Rust distinguishes full SessionSource variants. This slice reduces that to
;   the root-thread vs subagent-thread branch that the handler currently needs.
; - The restarted ResponseItem fixture layer does not yet model separate tool
;   result status fields, so fixture execution lowers both success and error
;   outcomes to text custom_tool_call_output items, matching the currently
;   visible tool-call surface.

!(import! &self json)
!(import! &self list)
!(import! &self protocol)
!(import! &self str)

(= (codex:request-user-input-tool-name)
   "request_user_input")

(= (codex:request-user-input-unsupported-payload-message)
   "request_user_input handler received unsupported payload")

(= (codex:request-user-input-root-thread-message)
   "request_user_input can only be used by the root thread")

(= (codex:request-user-input-missing-options-message)
   "request_user_input requires non-empty options for every question")

(= (codex:request-user-input-cancelled-message)
   "request_user_input was cancelled before receiving a response")

(= (codex:collaboration-mode-default)
   "Default")

(= (codex:collaboration-mode-plan)
   "Plan")

(= (codex:collaboration-mode-pair-programming)
   "Pair Programming")

(= (codex:collaboration-mode-execute)
   "Execute")

(= (codex:request-user-input-session-source-root)
   "root")

(= (codex:request-user-input-session-source-subagent)
   "subagent")

(= (codex:request-user-input-option $label $description)
   (CodexRequestUserInputQuestionOption $label $description))

(= (codex:request-user-input-question
      $id
      $header
      $question
      $is-other
      $is-secret
      $options)
   (CodexRequestUserInputQuestion
     $id
     $header
     $question
     $is-other
     $is-secret
     $options))

(= (codex:request-user-input-basic-question $id $header $question $options)
   (codex:request-user-input-question
     $id
     $header
     $question
     False
     False
     $options))

(= (codex:request-user-input-args $questions)
   (CodexRequestUserInputArgs $questions))

(= (codex:request-user-input-answer $answers)
   (CodexRequestUserInputAnswer $answers))

(= (codex:request-user-input-response-entry $id $answer)
   (CodexRequestUserInputResponseEntry $id $answer))

(= (codex:request-user-input-response $answers)
   (CodexRequestUserInputResponse $answers))

(= (codex:request-user-input-event $call-id $turn-id $questions)
   (CodexRequestUserInputEvent $call-id $turn-id $questions))

(= (codex:request-user-input-function-payload $arguments)
   (CodexRequestUserInputPayloadFunction $arguments))

(= (codex:request-user-input-unsupported-payload $payload-kind)
   (CodexRequestUserInputPayloadUnsupported $payload-kind))

(= (codex:request-user-input-response-behavior-return $response)
   (CodexRequestUserInputResponseBehaviorReturn $response))

(= (codex:request-user-input-response-behavior-cancel)
   (CodexRequestUserInputResponseBehaviorCancel))

(= (codex:request-user-input-handler-context
      $mode
      $default-mode-request-user-input
      $turn-id
      $session-source
      $response-behavior)
   (CodexRequestUserInputHandlerContext
     $mode
     $default-mode-request-user-input
     $turn-id
     $session-source
     $response-behavior))

(= (codex:default-request-user-input-handler-context)
   (codex:request-user-input-handler-context
     (codex:collaboration-mode-default)
     False
     "turn-local"
     (codex:request-user-input-session-source-root)
     (codex:request-user-input-response-behavior-cancel)))

(= (codex:request-user-input-args-questions
      (CodexRequestUserInputArgs $questions))
   $questions)

(= (codex:request-user-input-question-id
      (CodexRequestUserInputQuestion
        $id
        $header
        $question
        $is-other
        $is-secret
        $options))
   $id)

(= (codex:request-user-input-question-header
      (CodexRequestUserInputQuestion
        $id
        $header
        $question
        $is-other
        $is-secret
        $options))
   $header)

(= (codex:request-user-input-question-text
      (CodexRequestUserInputQuestion
        $id
        $header
        $question
        $is-other
        $is-secret
        $options))
   $question)

(= (codex:request-user-input-question-is-other
      (CodexRequestUserInputQuestion
        $id
        $header
        $question
        $is-other
        $is-secret
        $options))
   $is-other)

(= (codex:request-user-input-question-is-secret
      (CodexRequestUserInputQuestion
        $id
        $header
        $question
        $is-other
        $is-secret
        $options))
   $is-secret)

(= (codex:request-user-input-question-options
      (CodexRequestUserInputQuestion
        $id
        $header
        $question
        $is-other
        $is-secret
        $options))
   $options)

(= (codex:request-user-input-answer-values
      (CodexRequestUserInputAnswer $answers))
   $answers)

(= (codex:request-user-input-response-answers
      (CodexRequestUserInputResponse $answers))
   $answers)

(= (codex:request-user-input-response-entry-id
      (CodexRequestUserInputResponseEntry $id $answer))
   $id)

(= (codex:request-user-input-response-entry-answer
      (CodexRequestUserInputResponseEntry $id $answer))
   $answer)

(= (codex:request-user-input-event-call-id
      (CodexRequestUserInputEvent $call-id $turn-id $questions))
   $call-id)

(= (codex:request-user-input-event-turn-id
      (CodexRequestUserInputEvent $call-id $turn-id $questions))
   $turn-id)

(= (codex:request-user-input-event-questions
      (CodexRequestUserInputEvent $call-id $turn-id $questions))
   $questions)

(= (codex:request-user-input-handler-context-mode
      (CodexRequestUserInputHandlerContext
        $mode
        $default-mode-request-user-input
        $turn-id
        $session-source
        $response-behavior))
   $mode)

(= (codex:request-user-input-handler-context-default-mode-request-user-input
      (CodexRequestUserInputHandlerContext
        $mode
        $default-mode-request-user-input
        $turn-id
        $session-source
        $response-behavior))
   $default-mode-request-user-input)

(= (codex:request-user-input-handler-context-turn-id
      (CodexRequestUserInputHandlerContext
        $mode
        $default-mode-request-user-input
        $turn-id
        $session-source
        $response-behavior))
   $turn-id)

(= (codex:request-user-input-handler-context-session-source
      (CodexRequestUserInputHandlerContext
        $mode
        $default-mode-request-user-input
        $turn-id
        $session-source
        $response-behavior))
   $session-source)

(= (codex:request-user-input-handler-context-response-behavior
      (CodexRequestUserInputHandlerContext
        $mode
        $default-mode-request-user-input
        $turn-id
        $session-source
        $response-behavior))
   $response-behavior)

(= (codex:request-user-input-normalize-result-type
      (CodexRequestUserInputNormalizeOk $args))
   "ok")

(= (codex:request-user-input-normalize-result-type
      (CodexRequestUserInputNormalizeError $message))
   "error")

(= (codex:request-user-input-normalize-result-args
      (CodexRequestUserInputNormalizeOk $args))
   $args)

(= (codex:request-user-input-normalize-result-message
      (CodexRequestUserInputNormalizeError $message))
   $message)

(= (codex:request-user-input-handler-result-type
      (CodexRequestUserInputHandlerOutput $event $output))
   "output")

(= (codex:request-user-input-handler-result-type
      (CodexRequestUserInputHandlerCancelled $event $message))
   "cancelled")

(= (codex:request-user-input-handler-result-type
      (CodexRequestUserInputHandlerError $message))
   "error")

(= (codex:request-user-input-handler-result-event
      (CodexRequestUserInputHandlerOutput $event $output))
   $event)

(= (codex:request-user-input-handler-result-event
      (CodexRequestUserInputHandlerCancelled $event $message))
   $event)

(= (codex:request-user-input-handler-result-output-text
      (CodexRequestUserInputHandlerOutput $event $output))
   $output)

(= (codex:request-user-input-handler-result-message
      (CodexRequestUserInputHandlerCancelled $event $message))
   $message)

(= (codex:request-user-input-handler-result-message
      (CodexRequestUserInputHandlerError $message))
   $message)

(= (codex:request-user-input-json-object-optional-value $object $key)
   (case (json-object-get $object $key)
     ((Empty CodexAbsent)
      (JsonNull CodexAbsent)
      ($value $value))))

(= (codex:request-user-input-json-object-required-string $object $key)
   (json-string-value (json-object-get $object $key)))

(= (codex:request-user-input-json-object-optional-bool $object $key)
   (case (codex:request-user-input-json-object-optional-value $object $key)
     ((CodexAbsent CodexAbsent)
      ((JsonBool $value) $value))))

(= (codex:request-user-input-json-object-required-array $object $key)
   (json-array-items (json-object-get $object $key)))

(= (codex:request-user-input-json-object-optional-array $object $key)
   (case (codex:request-user-input-json-object-optional-value $object $key)
     ((CodexAbsent CodexAbsent)
      ((JsonArray $items) $items))))

(= (codex:request-user-input-option-json
      (CodexRequestUserInputQuestionOption $label $description))
   (JsonObject
     ((JsonPair "label" (JsonString $label))
      (JsonPair "description" (JsonString $description)))))

(= (codex:request-user-input-options-json $options)
   (function
     (let $json-items
       (eval
         (map-atom
           $options
           $option
           (codex:request-user-input-option-json $option)))
       (return (JsonArray $json-items)))))

(= (codex:request-user-input-question-json
      (CodexRequestUserInputQuestion
        $id
        $header
        $question
        $is-other
        $is-secret
        $options))
   (if (== $options CodexAbsent)
       (JsonObject
         ((JsonPair "id" (JsonString $id))
          (JsonPair "header" (JsonString $header))
          (JsonPair "question" (JsonString $question))
          (JsonPair "isOther" (JsonBool $is-other))
          (JsonPair "isSecret" (JsonBool $is-secret))))
       (JsonObject
         ((JsonPair "id" (JsonString $id))
          (JsonPair "header" (JsonString $header))
          (JsonPair "question" (JsonString $question))
          (JsonPair "isOther" (JsonBool $is-other))
          (JsonPair "isSecret" (JsonBool $is-secret))
          (JsonPair "options" (codex:request-user-input-options-json $options))))))

(= (codex:request-user-input-questions-json $questions)
   (function
     (let $json-items
       (eval
         (map-atom
           $questions
           $question
           (codex:request-user-input-question-json $question)))
       (return (JsonArray $json-items)))))

(= (codex:request-user-input-args-json
      (CodexRequestUserInputArgs $questions))
   (JsonObject
     ((JsonPair "questions" (codex:request-user-input-questions-json $questions)))))

(= (codex:request-user-input-string-array-json $items)
   (function
     (let $json-items
       (eval (map-atom $items $item (JsonString $item)))
       (return (JsonArray $json-items)))))

(= (codex:request-user-input-answer-json
      (CodexRequestUserInputAnswer $answers))
   (JsonObject
     ((JsonPair "answers" (codex:request-user-input-string-array-json $answers)))))

(= (codex:request-user-input-response-answer-pairs $entries)
   (function
     (let $pairs
       (eval
         (map-atom
           $entries
           $entry
           (JsonPair
             (codex:request-user-input-response-entry-id $entry)
             (codex:request-user-input-answer-json
               (codex:request-user-input-response-entry-answer $entry)))))
       (return $pairs))))

(= (codex:request-user-input-response-json
      (CodexRequestUserInputResponse $entries))
   (let $pairs (codex:request-user-input-response-answer-pairs $entries)
     (JsonObject
       ((JsonPair "answers" (JsonObject $pairs))))))

(= (codex:request-user-input-event-json
      (CodexRequestUserInputEvent $call-id $turn-id $questions))
   (JsonObject
     ((JsonPair "call_id" (JsonString $call-id))
      (JsonPair "turn_id" (JsonString $turn-id))
      (JsonPair "questions" (codex:request-user-input-questions-json $questions)))))

(= (codex:request-user-input-option-from-json $json)
   (codex:request-user-input-option
     (codex:request-user-input-json-object-required-string $json "label")
     (codex:request-user-input-json-object-required-string $json "description")))

(= (codex:request-user-input-options-from-json-items $items)
   (function
     (let $options
       (eval
         (map-atom
           $items
           $item
           (codex:request-user-input-option-from-json $item)))
       (return $options))))

(= (codex:request-user-input-options-from-optional-json CodexAbsent)
   CodexAbsent)

(= (codex:request-user-input-options-from-optional-json $items)
   (codex:request-user-input-options-from-json-items $items))

(= (codex:request-user-input-default-bool CodexAbsent)
   False)

(= (codex:request-user-input-default-bool $value)
   $value)

(= (codex:request-user-input-question-from-json $json)
   (codex:request-user-input-question
     (codex:request-user-input-json-object-required-string $json "id")
     (codex:request-user-input-json-object-required-string $json "header")
     (codex:request-user-input-json-object-required-string $json "question")
     (codex:request-user-input-default-bool
       (codex:request-user-input-json-object-optional-bool $json "isOther"))
     (codex:request-user-input-default-bool
       (codex:request-user-input-json-object-optional-bool $json "isSecret"))
     (codex:request-user-input-options-from-optional-json
       (codex:request-user-input-json-object-optional-array $json "options"))))

(= (codex:request-user-input-questions-from-json-items $items)
   (function
     (let $questions
       (eval
         (map-atom
           $items
           $item
           (codex:request-user-input-question-from-json $item)))
       (return $questions))))

(= (codex:parse-request-user-input-args $input)
   (let $json (json-parse $input)
     (codex:request-user-input-args
       (codex:request-user-input-questions-from-json-items
         (codex:request-user-input-json-object-required-array
           $json
           "questions")))))

(= (codex:is-request-user-input-available $mode $default-mode-request-user-input)
   (if (== $mode (codex:collaboration-mode-plan))
       True
       (if (== $mode (codex:collaboration-mode-default))
           $default-mode-request-user-input
           False)))

(= (codex:request-user-input-unavailable-message $mode $default-mode-request-user-input)
   (if (codex:is-request-user-input-available
         $mode
         $default-mode-request-user-input)
       Empty
       (str-concat
         "request_user_input is unavailable in "
         (str-concat $mode " mode"))))

(= (codex:request-user-input-tool-description False)
   "Request user input for one to three short questions and wait for the response. This tool is only available in Plan mode.")

(= (codex:request-user-input-tool-description True)
   "Request user input for one to three short questions and wait for the response. This tool is only available in Default or Plan mode.")

(= (codex:is-request-user-input-question-missing-options $question)
   (let $options (codex:request-user-input-question-options $question)
     (if (== $options CodexAbsent)
         True
         (== (list:len $options) 0))))

(= (codex:is-request-user-input-question-list-missing-options ())
   False)

(= (codex:is-request-user-input-question-list-missing-options $questions)
   (let ($head $tail) (decons-atom $questions)
     (if (codex:is-request-user-input-question-missing-options $head)
         True
         (codex:is-request-user-input-question-list-missing-options $tail))))

(= (codex:normalize-request-user-input-question
      (CodexRequestUserInputQuestion
        $id
        $header
        $question
        $is-other
        $is-secret
        $options))
   (CodexRequestUserInputQuestion
     $id
     $header
     $question
     True
     $is-secret
     $options))

(= (codex:normalize-request-user-input-questions $questions)
   (function
     (let $normalized
       (eval
         (map-atom
           $questions
           $question
           (codex:normalize-request-user-input-question $question)))
       (return $normalized))))

(= (codex:normalize-request-user-input-args
      (CodexRequestUserInputArgs $questions))
   (if (codex:is-request-user-input-question-list-missing-options $questions)
       (CodexRequestUserInputNormalizeError
         (codex:request-user-input-missing-options-message))
       (CodexRequestUserInputNormalizeOk
         (CodexRequestUserInputArgs
           (codex:normalize-request-user-input-questions $questions)))))

(= (codex:request-user-input-handler-response-result
      $event
      (CodexRequestUserInputResponseBehaviorReturn $response))
   (CodexRequestUserInputHandlerOutput
     $event
     (json-stringify (codex:request-user-input-response-json $response))))

(= (codex:request-user-input-handler-response-result
      $event
      (CodexRequestUserInputResponseBehaviorCancel))
   (CodexRequestUserInputHandlerCancelled
     $event
     (codex:request-user-input-cancelled-message)))

(= (codex:handle-request-user-input-function $context $call-id $arguments)
   (if (==
         (codex:request-user-input-handler-context-session-source $context)
         (codex:request-user-input-session-source-subagent))
       (CodexRequestUserInputHandlerError
         (codex:request-user-input-root-thread-message))
       (let $availability-message
         (codex:request-user-input-unavailable-message
           (codex:request-user-input-handler-context-mode $context)
           (codex:request-user-input-handler-context-default-mode-request-user-input
             $context))
         (if (== $availability-message Empty)
             (let $parsed-args (codex:parse-request-user-input-args $arguments)
               (case (codex:normalize-request-user-input-args $parsed-args)
                 (((CodexRequestUserInputNormalizeError $message)
                   (CodexRequestUserInputHandlerError $message))
                 ((CodexRequestUserInputNormalizeOk $args)
                   (let $event
                     (CodexRequestUserInputEvent
                       $call-id
                       (codex:request-user-input-handler-context-turn-id $context)
                       (codex:request-user-input-args-questions $args))
                     (codex:request-user-input-handler-response-result
                       $event
                       (codex:request-user-input-handler-context-response-behavior
                         $context)))))))
             (CodexRequestUserInputHandlerError $availability-message)))))

(= (codex:handle-request-user-input-payload $context $call-id $payload)
   (case $payload
     (((CodexRequestUserInputPayloadFunction $arguments)
       (codex:handle-request-user-input-function $context $call-id $arguments))
      ($other
       (CodexRequestUserInputHandlerError
         (codex:request-user-input-unsupported-payload-message))))))

(= (codex:run-request-user-input-tool-call-with-context $context $call-id $input)
   (case
     (codex:handle-request-user-input-payload
       $context
       $call-id
       (codex:request-user-input-function-payload $input))
     (((CodexRequestUserInputHandlerOutput $event $output)
       (codex:tool-result $call-id $output))
      ((CodexRequestUserInputHandlerCancelled $event $message)
       (codex:tool-result $call-id $message))
      ((CodexRequestUserInputHandlerError $message)
       (codex:tool-result $call-id $message)))))

(= (codex:run-request-user-input-tool-call $call-id $input)
   (codex:run-request-user-input-tool-call-with-context
     (codex:default-request-user-input-handler-context)
     $call-id
     $input))
