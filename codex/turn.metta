; Deterministic fixture-turn slice for the restarted Codex port.
;
; This first turn layer stays read-only and scripted: it consumes canned fixture
; steps, lowers them to Codex protocol items, and computes the turn's
; `final_response` using the same precedence as openai-codex's Python SDK:
; prefer the last explicit final-answer assistant message, otherwise the last
; phase-less assistant message, otherwise no final response.

!(import! &self json)
!(import! &self list)
!(import! &self protocol)
!(import! &self request_user_input)

(= (codex:fixture-user-step $text)
   (CodexFixtureUserStep $text))

(= (codex:fixture-assistant-step $text)
   (CodexFixtureAssistantStep $text))

(= (codex:fixture-commentary-step $text)
   (CodexFixtureCommentaryStep $text))

(= (codex:fixture-final-step $text)
   (CodexFixtureFinalStep $text))

(= (codex:fixture-tool-call-step $call_id $name $input)
   (CodexFixtureToolCallStep $call_id $name $input))

(= (codex:fixture-tool-result-step $call_id $output)
   (CodexFixtureToolResultStep $call_id $output))

(= (codex:fixture-request-user-input-step $call_id $input $context)
   (CodexFixtureRequestUserInputStep $call_id $input $context))

(= (codex:fixture-step-items (CodexFixtureUserStep $text))
   ((codex:user-message $text)))

(= (codex:fixture-step-items (CodexFixtureAssistantStep $text))
   ((codex:assistant-message $text)))

(= (codex:fixture-step-items (CodexFixtureCommentaryStep $text))
   ((codex:commentary-message $text)))

(= (codex:fixture-step-items (CodexFixtureFinalStep $text))
   ((codex:final-response $text)))

(= (codex:fixture-step-items
      (CodexFixtureToolCallStep $call_id $name $input))
   ((codex:tool-call $call_id $name $input)))

(= (codex:fixture-step-items (CodexFixtureToolResultStep $call_id $output))
   ((codex:tool-result $call_id $output)))

(= (codex:fixture-step-items
      (CodexFixtureRequestUserInputStep $call_id $input $context))
   ((codex:tool-call $call_id "request_user_input" $input)
    (codex:run-request-user-input-tool-call-with-context
      $context
      $call_id
      $input)))

(= (codex:fixture-append-items () $rhs)
   $rhs)

; CeTTa reduction note: after importing the large protocol surface, recursive
; `let ... (eval ...)` list materialization can collapse to no result. This
; local append keeps Rust's item ordering while forcing the recursive tail with
; `case`, which remains stable under the evaluator.
(= (codex:fixture-append-items $lhs $rhs)
   (let ($head $tail) (decons-atom $lhs)
     (case (codex:fixture-append-items $tail $rhs)
       (($rest
          (cons-atom $head $rest))))))

(= (codex:fixture-steps-items ())
   ())

(= (codex:fixture-steps-items $steps)
   (let ($head $tail) (decons-atom $steps)
     (let $head-items (eval (codex:fixture-step-items $head))
       (case (codex:fixture-steps-items $tail)
         (($tail-items
            (codex:fixture-append-items $head-items $tail-items)))))))

(= (codex:final-response-candidate $item)
   (case $item
     (((CodexResponseItemMessage "assistant" ((CodexOutputText $text)) "final_answer")
       (CodexExplicitFinal $text))
      ((CodexResponseItemMessage "assistant" ((CodexOutputText $text)) CodexAbsent)
       (CodexUnknownAssistant $text))
      ($other CodexNoFinal))))

(= (codex:final-response-from-reversed-items () $fallback)
   $fallback)

(= (codex:final-response-from-reversed-items $items $fallback)
   (let $item (list:first $items)
     (let $rest (list:rest $items)
       (case (codex:final-response-candidate $item)
         (((CodexExplicitFinal $text) $text)
          ((CodexUnknownAssistant $text)
           (if (== $fallback CodexAbsent)
               (codex:final-response-from-reversed-items $rest $text)
               (codex:final-response-from-reversed-items $rest $fallback)))
          (CodexNoFinal
           (codex:final-response-from-reversed-items $rest $fallback)))))))

(= (codex:final-response-from-items $items)
   (codex:final-response-from-items-acc
     $items
     CodexAbsent
     CodexAbsent))

(= (codex:final-response-from-items-acc () $explicit-final $unknown-assistant)
   (if (== $explicit-final CodexAbsent)
       $unknown-assistant
       $explicit-final))

(= (codex:final-response-from-items-acc $items $explicit-final $unknown-assistant)
   (let $item (list:first $items)
     (let $rest (list:rest $items)
       (case (codex:final-response-candidate $item)
         (((CodexExplicitFinal $text)
           (codex:final-response-from-items-acc
             $rest
             $text
             $unknown-assistant))
          ((CodexUnknownAssistant $text)
           (codex:final-response-from-items-acc
             $rest
             $explicit-final
             $text))
          (CodexNoFinal
           (codex:final-response-from-items-acc
             $rest
             $explicit-final
             $unknown-assistant)))))))

(= (codex:run-fixture-turn $steps)
   (case (codex:fixture-steps-items $steps)
     (($items
       (case (codex:final-response-from-items $items)
         (($final-response
           (CodexFixtureTurnResult $items $final-response))))))))

(= (codex:fixture-turn-items (CodexFixtureTurnResult $items $final_response))
   $items)

(= (codex:fixture-turn-final-response (CodexFixtureTurnResult $items $final_response))
   (if (== $final_response CodexAbsent) Empty $final_response))

(= (codex:fixture-turn-final-response-json $final_response)
   (if (== $final_response CodexAbsent) JsonNull (JsonString $final_response)))

(= (codex:fixture-turn-json (CodexFixtureTurnResult $items $final_response))
   (JsonObject
     ((JsonPair "items" (codex:items-json $items))
      (JsonPair "final_response"
        (codex:fixture-turn-final-response-json $final_response)))))
