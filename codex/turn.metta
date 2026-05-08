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

(= (codex:fixture-step-item (CodexFixtureUserStep $text))
   (codex:user-message $text))

(= (codex:fixture-step-item (CodexFixtureAssistantStep $text))
   (codex:assistant-message $text))

(= (codex:fixture-step-item (CodexFixtureCommentaryStep $text))
   (codex:commentary-message $text))

(= (codex:fixture-step-item (CodexFixtureFinalStep $text))
   (codex:final-response $text))

(= (codex:fixture-step-item (CodexFixtureToolCallStep $call_id $name $input))
   (codex:tool-call $call_id $name $input))

(= (codex:fixture-step-item (CodexFixtureToolResultStep $call_id $output))
   (codex:tool-result $call_id $output))

(= (codex:fixture-steps-items $steps)
   (function
     (let $items (eval (map-atom $steps $step (codex:fixture-step-item $step)))
       (return $items))))

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
   (codex:final-response-from-reversed-items (list:reverse $items) CodexAbsent))

(= (codex:run-fixture-turn $steps)
   (let $items (codex:fixture-steps-items $steps)
     (CodexFixtureTurnResult $items (codex:final-response-from-items $items))))

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
