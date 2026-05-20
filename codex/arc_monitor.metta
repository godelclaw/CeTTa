; Rust-faithful ARC monitor request/result helper slice.
;
; This ports deterministic behavior from:
; - openai-codex/codex-rs/core/src/arc_monitor.rs
;
; Covered in this increment:
; - ArcMonitorOutcome, metadata, message, policies, request, evidence, result
; - build_arc_monitor_request message selection and fallback message
; - build_arc_monitor_messages last-tool-call / last-encrypted-reasoning rules
; - monitor_action URL/auth/action-object planning before the HTTP side effect
; - strict ArcMonitorResult JSON shape parsing and outcome fallback text rules
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust performs async HTTP with reqwest and reads process environment. CeTTa
;   represents the pre-HTTP plan as pure data with explicit env/auth inputs; the
;   actual network call remains outside this pure slice.
; - Rust pulls history and turn/session ids from Session and TurnContext. CeTTa
;   receives those values explicitly and builds the same request body.
; - Rust serde rejects unknown result fields. CeTTa mirrors that for the result
;   object by checking the accepted key set before projecting fields.

!(import! &self event_mapping)
!(import! &self json)
!(import! &self protocol)
!(import! &self str)

(= (codex:arc-monitor-timeout-secs)
   30)

(= (codex:arc-monitor-endpoint-override-env-key)
   "CODEX_ARC_MONITOR_ENDPOINT_OVERRIDE")

(= (codex:arc-monitor-token-env-key)
   "CODEX_ARC_MONITOR_TOKEN")

(= (codex:arc-monitor-no-history-message)
   "No prior conversation history is available for this ARC evaluation.")

(= (codex:arc-monitor-ask-user-fallback)
   "Additional confirmation is required before this tool call can continue.")

(= (codex:arc-monitor-steer-model-fallback)
   "Tool call was cancelled because of safety risks.")

(= (codex:arc-monitor-outcome-ok)
   (CodexArcMonitorOutcomeOk))

(= (codex:arc-monitor-outcome-steer-model $reason)
   (CodexArcMonitorOutcomeSteerModel $reason))

(= (codex:arc-monitor-outcome-ask-user $reason)
   (CodexArcMonitorOutcomeAskUser $reason))

(= (codex:arc-monitor-result-outcome-ok)
   (CodexArcMonitorResultOutcomeOk))

(= (codex:arc-monitor-result-outcome-steer-model)
   (CodexArcMonitorResultOutcomeSteerModel))

(= (codex:arc-monitor-result-outcome-ask-user)
   (CodexArcMonitorResultOutcomeAskUser))

(= (codex:arc-monitor-risk-level-low)
   (CodexArcMonitorRiskLevelLow))

(= (codex:arc-monitor-risk-level-medium)
   (CodexArcMonitorRiskLevelMedium))

(= (codex:arc-monitor-risk-level-high)
   (CodexArcMonitorRiskLevelHigh))

(= (codex:arc-monitor-risk-level-critical)
   (CodexArcMonitorRiskLevelCritical))

(= (codex:arc-monitor-metadata
      $codex-thread-id
      $codex-turn-id
      $conversation-id
      $protection-client-callsite)
   (CodexArcMonitorMetadata
     $codex-thread-id
     $codex-turn-id
     $conversation-id
     $protection-client-callsite))

(= (codex:arc-monitor-chat-message $role $content)
   (CodexArcMonitorChatMessage $role $content))

(= (codex:arc-monitor-policies $user $developer)
   (CodexArcMonitorPolicies $user $developer))

(= (codex:arc-monitor-request
      $metadata
      $messages
      $input
      $policies
      $action)
   (CodexArcMonitorRequest
     $metadata
     $messages
     $input
     $policies
     $action))

(= (codex:arc-monitor-evidence $message $why)
   (CodexArcMonitorEvidence $message $why))

(= (codex:arc-monitor-result
      $outcome
      $short-reason
      $rationale
      $risk-score
      $risk-level
      $evidence)
   (CodexArcMonitorResult
     $outcome
     $short-reason
     $rationale
     $risk-score
     $risk-level
     $evidence))

(= (codex:arc-monitor-request-plan-skip-ok)
   (CodexArcMonitorRequestPlanSkipOk))

(= (codex:arc-monitor-auth-env-token $token)
   (CodexArcMonitorAuthEnvToken $token))

(= (codex:arc-monitor-auth-codex-backend)
   (CodexArcMonitorAuthCodexBackend))

(= (codex:arc-monitor-request-plan-http $url $auth $body)
   (CodexArcMonitorRequestPlanHttp $url $auth $body))

(= (codex:arc-monitor-local-shell-exec-action
      $command
      $timeout-ms
      $working-directory
      $env
      $user)
   (CodexArcMonitorLocalShellExecAction
     $command
     $timeout-ms
     $working-directory
     $env
     $user))

(= (codex:arc-monitor-no-index)
   (CodexArcMonitorNoIndex))

(= (codex:arc-monitor-append-items $lhs $rhs)
   (case (once (eval $lhs))
     (($resolved-lhs
       (if (== $resolved-lhs ())
           $rhs
           (let ($head $tail) (decons-atom $resolved-lhs)
             (case (codex:arc-monitor-append-items $tail $rhs)
               (($rest
                  (cons-atom $head $rest))))))))))

(= (codex:arc-monitor-json-optional-pair $key $value)
   (case (once (eval $value))
     ((CodexAbsent ())
      ($resolved ((JsonPair $key $resolved))))))

(= (codex:arc-monitor-append-optional-pair $pairs $key $value)
   (case (once (eval $pairs))
     (($resolved-pairs
       (case (codex:arc-monitor-json-optional-pair $key $value)
         (($optional-pairs
           (codex:arc-monitor-append-items
             $resolved-pairs
             $optional-pairs))))))))

(= (codex:arc-monitor-json-optional-string $value)
   (if (== $value CodexAbsent)
       JsonNull
       (JsonString $value)))

(= (codex:arc-monitor-json-optional-number $value)
   (if (== $value CodexAbsent)
       JsonNull
       (JsonNumber $value)))

(= (codex:arc-monitor-json-optional-raw $value)
   (if (== $value CodexAbsent)
       JsonNull
       $value))

(= (codex:arc-monitor-string-list-json $items)
   (if (== $items ())
       (JsonArray ())
       (let ($head $tail) (decons-atom $items)
         (case (codex:arc-monitor-string-list-json $tail)
           (((JsonArray $rest)
             (JsonArray (cons-atom (JsonString $head) $rest))))))))

(= (codex:arc-monitor-local-shell-action-json $action)
   (case (once (eval $action))
     (((JsonObject $pairs)
       (JsonObject $pairs))
      ((CodexArcMonitorLocalShellExecAction
         $command
         $timeout-ms
         $working-directory
         $env
         $user)
       (JsonObject
         ((JsonPair "type" (JsonString "exec"))
          (JsonPair "command" (codex:arc-monitor-string-list-json $command))
          (JsonPair "timeout_ms"
            (codex:arc-monitor-json-optional-number $timeout-ms))
          (JsonPair "working_directory"
            (codex:arc-monitor-json-optional-string $working-directory))
          (JsonPair "env" (codex:arc-monitor-json-optional-raw $env))
          (JsonPair "user" (codex:arc-monitor-json-optional-string $user))))))))

(= (codex:arc-monitor-web-search-action-json $action)
   (let $resolved-action (once (eval $action))
     (codex:web-search-action-json $resolved-action)))

(= (codex:arc-monitor-chat-message-json $message)
   (case (once (eval $message))
     (((CodexArcMonitorChatMessage $role $content)
       (JsonObject
         ((JsonPair "role" (JsonString $role))
          (JsonPair "content" $content)))))))

(= (codex:arc-monitor-chat-messages-json $messages)
   (JsonArray
     (map-atom-strict
       $messages
       $message
       (codex:arc-monitor-chat-message-json $message))))

(= (codex:arc-monitor-metadata-json $metadata)
   (case (once (eval $metadata))
     (((CodexArcMonitorMetadata
         $codex-thread-id
         $codex-turn-id
         $conversation-id
         $protection-client-callsite)
       (case (codex:arc-monitor-append-optional-pair
               ((JsonPair "codex_thread_id" (JsonString $codex-thread-id))
                (JsonPair "codex_turn_id" (JsonString $codex-turn-id)))
               "conversation_id"
               (if (== $conversation-id CodexAbsent)
                   CodexAbsent
                   (JsonString $conversation-id)))
         (($with-conversation
           (case (codex:arc-monitor-append-optional-pair
                   $with-conversation
                   "protection_client_callsite"
                   (if (== $protection-client-callsite CodexAbsent)
                       CodexAbsent
                       (JsonString $protection-client-callsite)))
             (($pairs (JsonObject $pairs)))))))))))

(= (codex:arc-monitor-policies-json $policies)
   (case (once (eval $policies))
     (((CodexArcMonitorPolicies $user $developer)
       (JsonObject
         ((JsonPair "user" (codex:arc-monitor-json-optional-string $user))
          (JsonPair "developer"
            (codex:arc-monitor-json-optional-string $developer))))))))

(= (codex:arc-monitor-request-json $request)
   (case (once (eval $request))
     (((CodexArcMonitorRequest
         $metadata
         $messages
         $input
         $policies
         $action)
       (case (codex:arc-monitor-append-optional-pair
               ((JsonPair
                  "metadata"
                  (codex:arc-monitor-metadata-json $metadata)))
               "messages"
               (if (== $messages CodexAbsent)
                   CodexAbsent
                   (codex:arc-monitor-chat-messages-json $messages)))
         (($with-messages
           (case (codex:arc-monitor-append-optional-pair
                   $with-messages
                   "input"
                   $input)
             (($with-input
               (case (codex:arc-monitor-append-optional-pair
                       $with-input
                       "policies"
                       (if (== $policies CodexAbsent)
                           CodexAbsent
                           (codex:arc-monitor-policies-json $policies)))
                 (($with-policies
                   (case (codex:arc-monitor-append-items
                           $with-policies
                           ((JsonPair "action" $action)))
                     (($pairs (JsonObject $pairs)))))))))))))))))

(= (codex:arc-monitor-content-text-segments ())
   ())

(= (codex:arc-monitor-content-text-segments $items)
   (let ($head $tail) (decons-atom $items)
     (case $head
       (((CodexInputText $text)
         (if (== $text "")
             (codex:arc-monitor-content-text-segments $tail)
             (case (codex:arc-monitor-content-text-segments $tail)
               (($rest (cons-atom $text $rest))))))
        ((CodexOutputText $text)
         (if (== $text "")
             (codex:arc-monitor-content-text-segments $tail)
             (case (codex:arc-monitor-content-text-segments $tail)
               (($rest (cons-atom $text $rest))))))
        ((CodexInputImage $image-url $detail)
         (codex:arc-monitor-content-text-segments $tail))))))

(= (codex:arc-monitor-content-items-to-text $items)
   (let $segments (codex:arc-monitor-content-text-segments $items)
     (if (== $segments ())
         Empty
         (str-join "\n" $segments))))

(= (codex:arc-monitor-text-message $role $part-type $text)
   (codex:arc-monitor-chat-message
     $role
     (JsonArray
       ((JsonObject
          ((JsonPair "type" (JsonString $part-type))
           (JsonPair "text" (JsonString $text))))))))

(= (codex:arc-monitor-encrypted-reasoning-message $encrypted-content)
   (codex:arc-monitor-chat-message
     "assistant"
     (JsonArray
       ((JsonObject
          ((JsonPair "type" (JsonString "encrypted_reasoning"))
           (JsonPair "encrypted_content"
             (JsonString $encrypted-content))))))))

(= (codex:arc-monitor-tool-call-message $pairs)
   (codex:arc-monitor-chat-message
     "assistant"
     (JsonArray
       ((JsonObject
          (cons-atom
            (JsonPair "type" (JsonString "tool_call"))
            $pairs))))))

(= (codex:arc-monitor-is-final-answer-phase $phase)
   (or
     (== $phase "final_answer")
     (== $phase (CodexMessagePhaseFinalAnswer))))

(= (codex:arc-monitor-is-tool-call-item $item)
   (case (once (eval $item))
     (((CodexResponseItemLocalShellCall $id $call-id $status $action)
       True)
      ((CodexResponseItemFunctionCall $id $name $namespace $arguments $call-id)
       True)
      ((CodexResponseItemCustomToolCall $call-id $name $input)
       True)
      ((CodexResponseItemWebSearchCall $id $status $action)
       True)
      ($other False))))

(= (codex:arc-monitor-last-tool-call-index $items)
   (case (codex:arc-monitor-last-tool-call-index-internal $items)
     (((CodexArcMonitorNoIndex) CodexAbsent)
      ($index $index))))

(= (codex:arc-monitor-last-tool-call-index-internal $items)
   (codex:arc-monitor-last-tool-call-index-acc
     $items
     0
     (codex:arc-monitor-no-index)))

(= (codex:arc-monitor-last-tool-call-index-acc () $index $last)
   $last)

(= (codex:arc-monitor-last-tool-call-index-acc $items $index $last)
   (let ($head $tail) (decons-atom $items)
     (case (codex:arc-monitor-is-tool-call-item $head)
       ((True
         (codex:arc-monitor-last-tool-call-index-acc
           $tail
           (+ $index 1)
           $index))
        (False
         (codex:arc-monitor-last-tool-call-index-acc
           $tail
           (+ $index 1)
           $last))))))

(= (codex:arc-monitor-non-empty-optional-string $text)
   (if (== $text CodexAbsent)
       CodexAbsent
       (if (== (str-trim $text) "")
           CodexAbsent
           $text)))

(= (codex:arc-monitor-encrypted-reasoning-text $item)
   (case (once (eval $item))
     (((CodexResponseItemReasoning $id $summary $content $encrypted-content)
       (codex:arc-monitor-non-empty-optional-string $encrypted-content))
      ($other CodexAbsent))))

(= (codex:arc-monitor-last-encrypted-reasoning-index $items)
   (case (codex:arc-monitor-last-encrypted-reasoning-index-internal
           $items)
     (((CodexArcMonitorNoIndex) CodexAbsent)
      ($index $index))))

(= (codex:arc-monitor-last-encrypted-reasoning-index-internal $items)
   (codex:arc-monitor-last-encrypted-reasoning-index-acc
     $items
     0
     (codex:arc-monitor-no-index)))

(= (codex:arc-monitor-last-encrypted-reasoning-index-acc
      ()
      $index
      $last)
   $last)

(= (codex:arc-monitor-last-encrypted-reasoning-index-acc
      $items
      $index
      $last)
   (let ($head $tail) (decons-atom $items)
     (codex:arc-monitor-last-encrypted-reasoning-index-acc
       $tail
       (+ $index 1)
       (case (codex:arc-monitor-encrypted-reasoning-text $head)
         ((CodexAbsent $last)
          ($text $index))))))

(= (codex:arc-monitor-message-item
      $item
      $index
      $last-tool-call-index
      $last-encrypted-reasoning-index)
   (case (once (eval $item))
     (((CodexResponseItemMessage "user" $content $phase)
       (if (codex:is-contextual-user-message-content $content)
           CodexAbsent
           (case (codex:arc-monitor-content-items-to-text $content)
             ((Empty CodexAbsent)
              ($text
               (codex:arc-monitor-text-message
                 "user"
                 "input_text"
                 $text))))))
      ((CodexResponseItemMessageWithId $id "user" $content $phase)
       (if (codex:is-contextual-user-message-content $content)
           CodexAbsent
           (case (codex:arc-monitor-content-items-to-text $content)
             ((Empty CodexAbsent)
              ($text
               (codex:arc-monitor-text-message
                 "user"
                 "input_text"
                 $text))))))
      ((CodexResponseItemMessage "assistant" $content $phase)
       (if (codex:arc-monitor-is-final-answer-phase $phase)
           (case (codex:arc-monitor-content-items-to-text $content)
             ((Empty CodexAbsent)
              ($text
               (codex:arc-monitor-text-message
                 "assistant"
                 "output_text"
                 $text))))
           CodexAbsent))
      ((CodexResponseItemMessageWithId $id "assistant" $content $phase)
       (if (codex:arc-monitor-is-final-answer-phase $phase)
           (case (codex:arc-monitor-content-items-to-text $content)
             ((Empty CodexAbsent)
              ($text
               (codex:arc-monitor-text-message
                 "assistant"
                 "output_text"
                 $text))))
           CodexAbsent))
      ((CodexResponseItemReasoning $id $summary $content $encrypted-content)
       (case (codex:arc-monitor-non-empty-optional-string
               $encrypted-content)
         ((CodexAbsent CodexAbsent)
          ($text
           (if (== $index $last-encrypted-reasoning-index)
               (codex:arc-monitor-encrypted-reasoning-message $text)
               CodexAbsent)))))
      ((CodexResponseItemLocalShellCall $id $call-id $status $action)
       (if (== $index $last-tool-call-index)
           (codex:arc-monitor-tool-call-message
             ((JsonPair "tool_name" (JsonString "shell"))
              (JsonPair "action"
                (codex:arc-monitor-local-shell-action-json $action))))
           CodexAbsent))
      ((CodexResponseItemFunctionCall
         $id
         $name
         $namespace
         $arguments
         $call-id)
       (if (== $index $last-tool-call-index)
           (codex:arc-monitor-tool-call-message
             ((JsonPair "tool_name" (JsonString $name))
              (JsonPair "arguments" (JsonString $arguments))))
           CodexAbsent))
      ((CodexResponseItemCustomToolCall $call-id $name $input)
       (if (== $index $last-tool-call-index)
           (codex:arc-monitor-tool-call-message
             ((JsonPair "tool_name" (JsonString $name))
              (JsonPair "input" (JsonString $input))))
           CodexAbsent))
      ((CodexResponseItemWebSearchCall $id $status $action)
       (if (== $index $last-tool-call-index)
           (codex:arc-monitor-tool-call-message
             ((JsonPair "tool_name" (JsonString "web_search"))
              (JsonPair
                "action"
                (codex:arc-monitor-web-search-action-json $action))))
           CodexAbsent))
      ($other CodexAbsent))))

(= (codex:arc-monitor-build-messages $items)
   (case (codex:arc-monitor-last-tool-call-index-internal $items)
     (($last-tool-call-index
       (case (codex:arc-monitor-last-encrypted-reasoning-index-internal
               $items)
         (($last-encrypted-reasoning-index
           (codex:arc-monitor-build-messages-acc
             $items
             0
             $last-tool-call-index
             $last-encrypted-reasoning-index))))))))

(= (codex:arc-monitor-build-messages-acc
      ()
      $index
      $last-tool-call-index
      $last-encrypted-reasoning-index)
   ())

(= (codex:arc-monitor-build-messages-acc
      $items
      $index
      $last-tool-call-index
      $last-encrypted-reasoning-index)
   (let ($head $tail) (decons-atom $items)
     (case (codex:arc-monitor-message-item
             $head
             $index
             $last-tool-call-index
             $last-encrypted-reasoning-index)
       ((CodexAbsent
         (codex:arc-monitor-build-messages-acc
           $tail
           (+ $index 1)
           $last-tool-call-index
           $last-encrypted-reasoning-index))
        ($message
           (case (codex:arc-monitor-build-messages-acc
                 $tail
                 (+ $index 1)
                 $last-tool-call-index
                 $last-encrypted-reasoning-index)
          (($rest (cons-atom $message $rest)))))))))

(= (codex:arc-monitor-messages-or-fallback $messages)
   (if (== $messages ())
       ((codex:arc-monitor-text-message
          "user"
          "input_text"
          (codex:arc-monitor-no-history-message)))
       $messages))

(= (codex:arc-monitor-build-request
      $codex-thread-id
      $codex-turn-id
      $history
      $action
      $protection-client-callsite)
   (case (codex:arc-monitor-build-messages $history)
     (($messages
       (codex:arc-monitor-request
         (codex:arc-monitor-metadata
           $codex-thread-id
           $codex-turn-id
           $codex-thread-id
           $protection-client-callsite)
         (codex:arc-monitor-messages-or-fallback $messages)
         CodexAbsent
         (codex:arc-monitor-policies CodexAbsent CodexAbsent)
         $action)))))

(= (codex:arc-monitor-trim-end-slashes $text)
   (if (== (str-length $text) 0)
       ""
       (if (str-ends-with? $text "/")
           (codex:arc-monitor-trim-end-slashes
             (str-slice $text 0 (- (str-length $text) 1)))
           $text)))

(= (codex:arc-monitor-non-empty-env-value $value)
   (if (== $value CodexAbsent)
       CodexAbsent
       (let $trimmed (str-trim $value)
         (if (== $trimmed "") CodexAbsent $trimmed))))

(= (codex:arc-monitor-endpoint-url $chatgpt-base-url $endpoint-override)
   (case (codex:arc-monitor-non-empty-env-value $endpoint-override)
     ((CodexAbsent
       (str-concat
         (codex:arc-monitor-trim-end-slashes $chatgpt-base-url)
         "/codex/safety/arc"))
      ($override
       $override))))

(= (codex:arc-monitor-auth-plan $env-token $has-codex-backend-auth)
   (case (codex:arc-monitor-non-empty-env-value $env-token)
     ((CodexAbsent
       (if $has-codex-backend-auth
           (codex:arc-monitor-auth-codex-backend)
           CodexAbsent))
      ($token
       (codex:arc-monitor-auth-env-token $token)))))

(= (codex:arc-monitor-request-plan
      $env-token
      $has-codex-backend-auth
      $chatgpt-base-url
      $endpoint-override
      $action
      $codex-thread-id
      $codex-turn-id
      $history
      $protection-client-callsite)
   (case (codex:arc-monitor-auth-plan
           $env-token
           $has-codex-backend-auth)
     ((CodexAbsent (codex:arc-monitor-request-plan-skip-ok))
      ($auth
       (case $action
         (((JsonObject $pairs)
           (codex:arc-monitor-request-plan-http
             (codex:arc-monitor-endpoint-url
               $chatgpt-base-url
               $endpoint-override)
             $auth
             (codex:arc-monitor-build-request
               $codex-thread-id
               $codex-turn-id
               $history
               (JsonObject $pairs)
               $protection-client-callsite)))
          ($other
           (codex:arc-monitor-request-plan-skip-ok))))))))

(= (codex:arc-monitor-string-member $needle ())
   False)

(= (codex:arc-monitor-string-member $needle $items)
   (let ($head $tail) (decons-atom $items)
     (if (== $needle $head)
         True
         (codex:arc-monitor-string-member $needle $tail))))

(= (codex:arc-monitor-json-object-has-only-keys () $allowed)
   True)

(= (codex:arc-monitor-json-object-has-only-keys $pairs $allowed)
   (let ($head $tail) (decons-atom $pairs)
     (case $head
       (((JsonPair $key $value)
         (case (codex:arc-monitor-string-member $key $allowed)
           ((True
             (codex:arc-monitor-json-object-has-only-keys
               $tail
               $allowed))
            (False False))))))))

(= (codex:arc-monitor-result-outcome-from-string $value)
   (case $value
      (("ok" (codex:arc-monitor-result-outcome-ok))
      ("steer-model" (codex:arc-monitor-result-outcome-steer-model))
      ("ask-user" (codex:arc-monitor-result-outcome-ask-user))
      ($other CodexAbsent))))

(= (codex:arc-monitor-risk-level-from-string $value)
   (case $value
     (("low" (codex:arc-monitor-risk-level-low))
      ("medium" (codex:arc-monitor-risk-level-medium))
      ("high" (codex:arc-monitor-risk-level-high))
      ("critical" (codex:arc-monitor-risk-level-critical))
      ($other CodexAbsent))))

(= (codex:arc-monitor-is-u8 $value)
   (and (>= $value 0) (<= $value 255)))

(= (codex:arc-monitor-evidence-from-json $value)
   (case $value
     (((JsonObject $pairs)
       (case (codex:arc-monitor-json-object-has-only-keys
               $pairs
               ("message" "why"))
         ((True
           (case ((json-object-get (JsonObject $pairs) "message")
                  (json-object-get (JsonObject $pairs) "why"))
             ((((JsonString $message) (JsonString $why))
               (codex:arc-monitor-evidence $message $why))
              ($other CodexAbsent))))
          (False CodexAbsent))))
      ($other CodexAbsent))))

(= (codex:arc-monitor-evidence-list-from-json-items ())
   ())

(= (codex:arc-monitor-evidence-list-from-json-items $items)
   (let ($head $tail) (decons-atom $items)
     (case (codex:arc-monitor-evidence-from-json $head)
       ((CodexAbsent CodexAbsent)
        ($evidence
         (case (codex:arc-monitor-evidence-list-from-json-items $tail)
           ((CodexAbsent CodexAbsent)
            ($rest (cons-atom $evidence $rest)))))))))

(= (codex:arc-monitor-evidence-list-from-json $value)
   (case $value
     (((JsonArray $items)
       (codex:arc-monitor-evidence-list-from-json-items $items))
      ($other CodexAbsent))))

(= (codex:arc-monitor-result-from-json-components
      $outcome-raw
      $short-reason
      $rationale
      $risk-score
      $risk-level-raw
      $evidence-raw)
   (case (codex:arc-monitor-result-outcome-from-string $outcome-raw)
     ((CodexAbsent CodexAbsent)
      ($outcome
       (case (codex:arc-monitor-risk-level-from-string $risk-level-raw)
         ((CodexAbsent CodexAbsent)
          ($risk-level
           (case (codex:arc-monitor-evidence-list-from-json $evidence-raw)
             ((CodexAbsent CodexAbsent)
              ($evidence
               (case (codex:arc-monitor-is-u8 $risk-score)
                 ((True
                   (codex:arc-monitor-result
                     $outcome
                     $short-reason
                     $rationale
                     $risk-score
                     $risk-level
                     $evidence))
                  (False CodexAbsent)))))))))))))

(= (codex:arc-monitor-result-from-json-object $object)
   (case (json-object-get $object "outcome")
     (((JsonString $outcome-raw)
       (case (json-object-get $object "short_reason")
         (((JsonString $short-reason)
           (case (json-object-get $object "rationale")
             (((JsonString $rationale)
               (case (json-object-get $object "risk_score")
                 (((JsonNumber $risk-score)
                   (case (json-object-get $object "risk_level")
                     (((JsonString $risk-level-raw)
                       (case (json-object-get $object "evidence")
                         (($evidence-raw
                           (codex:arc-monitor-result-from-json-components
                             $outcome-raw
                             $short-reason
                             $rationale
                             $risk-score
                             $risk-level-raw
                             $evidence-raw))))))))
                  ($other CodexAbsent))))
              ($other CodexAbsent))))
          ($other CodexAbsent))))
      ($other CodexAbsent))))

(= (codex:arc-monitor-result-from-json $value)
   (case $value
     (((JsonObject $pairs)
       (case (codex:arc-monitor-json-object-has-only-keys
               $pairs
               ("outcome"
                "short_reason"
                "rationale"
                "risk_score"
                "risk_level"
                "evidence"))
         ((True
           (codex:arc-monitor-result-from-json-object (JsonObject $pairs)))
          (False CodexAbsent))))
      ($other CodexAbsent))))

(= (codex:arc-monitor-outcome-from-result
      (CodexArcMonitorResult
        $outcome
        $short-reason
        $rationale
        $risk-score
        $risk-level
        $evidence))
   (let $trimmed-short-reason (str-trim $short-reason)
     (let $trimmed-rationale (str-trim $rationale)
       (case $outcome
         (((CodexArcMonitorResultOutcomeOk)
           (codex:arc-monitor-outcome-ok))
          ((CodexArcMonitorResultOutcomeAskUser)
           (if (not (== $trimmed-short-reason ""))
               (codex:arc-monitor-outcome-ask-user
                 $trimmed-short-reason)
               (if (not (== $trimmed-rationale ""))
                   (codex:arc-monitor-outcome-ask-user
                     $trimmed-rationale)
                   (codex:arc-monitor-outcome-ask-user
                     (codex:arc-monitor-ask-user-fallback)))))
          ((CodexArcMonitorResultOutcomeSteerModel)
           (if (not (== $trimmed-rationale ""))
               (codex:arc-monitor-outcome-steer-model
                 $trimmed-rationale)
               (if (not (== $trimmed-short-reason ""))
                   (codex:arc-monitor-outcome-steer-model
                     $trimmed-short-reason)
                   (codex:arc-monitor-outcome-steer-model
                     (codex:arc-monitor-steer-model-fallback))))))))))

(= (codex:arc-monitor-outcome-from-json $value)
   (case (codex:arc-monitor-result-from-json $value)
     ((CodexAbsent (codex:arc-monitor-outcome-ok))
      ($result
       (codex:arc-monitor-outcome-from-result $result)))))
