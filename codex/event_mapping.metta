; Narrow Rust-faithful event-mapping slice for the restarted Codex port.
;
; This ports the current visible behavior from:
; - openai-codex/codex-rs/core/src/event_mapping.rs
; - openai-codex/codex-rs/core/src/web_search.rs
;
; Covered in this increment:
; - contextual user-message detection over content-item lists
; - contextual developer-fragment detection over content-item lists
; - ResponseItem::Message -> UserMessage/AgentMessage lowering
; - ResponseItem::Reasoning -> Reasoning lowering
; - ResponseItem::WebSearchCall -> WebSearch lowering
; - ResponseItem::ImageGenerationCall -> ImageGeneration lowering
; - image-label text skipping around adjacent InputImage content items
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust generates UUIDs for fallback turn-item ids. The current CeTTa runtime
;   does not expose a UUID helper at this layer, so this slice uses stable
;   generated placeholder ids for message items when the source ResponseItem has
;   no id.
; - The restarted CeTTa protocol slice historically modeled messages without an
;   `id` field. This mapper therefore accepts both the legacy 3-field message
;   shape and a narrow 4-field message-with-id shape added for this slice.
; - Rust also lowers Plan and ContextCompaction turn items. Those ResponseItem
;   variants are not yet part of the restarted CeTTa protocol surface, so they
;   are intentionally out of scope here.

!(import! &self context_fragment)
!(import! &self protocol)
!(import! &self str)

(= (codex:trim-start-basic $text)
   (if (== $text "")
       ""
       (let $head (str-slice $text 0 1)
         (if (or (== $head " ")
                 (or (== $head "\n")
                     (or (== $head "\r")
                         (== $head "\t"))))
             (codex:trim-start-basic
               (str-slice $text 1 (str-length $text)))
             $text))))

(= (codex:is-contextual-user-message-content ())
   False)

(= (codex:is-contextual-user-message-content $message)
   (let $head (list:first $message)
     (let $tail (list:rest $message)
       (if (codex:is-contextual-user-fragment $head)
           True
           (if (== $tail ())
               False
               (codex:is-contextual-user-message-content $tail))))))

(= (codex:is-contextual-dev-fragment $item)
   (case $item
     (((CodexInputText $text)
       (let $trimmed-lower
         (codex:ascii-lower-text (codex:trim-start-basic $text))
         (or
           (str-starts-with? $trimmed-lower "<permissions instructions>")
           (or
             (str-starts-with? $trimmed-lower "<model_switch>")
             (or
               (str-starts-with? $trimmed-lower "<collaboration_mode>")
               (or
                 (str-starts-with? $trimmed-lower "<realtime_conversation>")
                 (str-starts-with? $trimmed-lower "<personality_spec>")))))))
      ($other
       False))))

(= (codex:is-contextual-dev-message-content ())
   False)

(= (codex:is-contextual-dev-message-content $message)
   (let $head (list:first $message)
     (let $tail (list:rest $message)
       (if (codex:is-contextual-dev-fragment $head)
           True
           (if (== $tail ())
               False
               (codex:is-contextual-dev-message-content $tail))))))

(= (codex:has-non-contextual-dev-message-content ())
   False)

(= (codex:has-non-contextual-dev-message-content $message)
   (let $head (list:first $message)
     (let $tail (list:rest $message)
       (if (codex:is-contextual-dev-fragment $head)
           (if (== $tail ())
               False
               (codex:has-non-contextual-dev-message-content $tail))
           True))))

(= (codex:turn-user-input-text $text)
   (CodexTurnUserInputText $text))

(= (codex:turn-user-input-image $image-url)
   (CodexTurnUserInputImage $image-url))

(= (codex:turn-user-input-text-value (CodexTurnUserInputText $text))
   $text)

(= (codex:turn-user-input-image-url (CodexTurnUserInputImage $image-url))
   $image-url)

(= (codex:turn-user-message-item $id $content)
   (CodexTurnUserMessageItem $id $content))

(= (codex:turn-user-message-item-id $item)
   (let $resolved-item (eval $item)
     (case $resolved-item
       (((CodexTurnUserMessageItem $id $content)
         $id)
        ($other
         Empty)))))

(= (codex:turn-user-message-item-content $item)
   (let $resolved-item (eval $item)
     (case $resolved-item
       (((CodexTurnUserMessageItem $id $content)
         $content)
        ($other
         Empty)))))

(= (codex:turn-agent-message-content-text $text)
   (CodexTurnAgentMessageContentText $text))

(= (codex:turn-agent-message-content-text-value
      (CodexTurnAgentMessageContentText $text))
   $text)

(= (codex:turn-agent-message-item $id $content $phase)
   (CodexTurnAgentMessageItem $id $content $phase))

(= (codex:turn-agent-message-item-id $item)
   (let $resolved-item (eval $item)
     (case $resolved-item
       (((CodexTurnAgentMessageItem $id $content $phase)
         $id)
        ($other
         Empty)))))

(= (codex:turn-agent-message-item-content $item)
   (let $resolved-item (eval $item)
     (case $resolved-item
       (((CodexTurnAgentMessageItem $id $content $phase)
         $content)
        ($other
         Empty)))))

(= (codex:turn-agent-message-item-phase $item)
   (let $resolved-item (eval $item)
     (case $resolved-item
       (((CodexTurnAgentMessageItem $id $content $phase)
         (if (== $phase CodexAbsent) Empty $phase))
        ($other
         Empty)))))

(= (codex:turn-reasoning-item $id $summary-text $raw-content)
   (CodexTurnReasoningItem $id $summary-text $raw-content))

(= (codex:turn-reasoning-item-id $item)
   (let $resolved-item (eval $item)
     (case $resolved-item
       (((CodexTurnReasoningItem $id $summary-text $raw-content)
         $id)
        ($other
         Empty)))))

(= (codex:turn-reasoning-item-summary-text $item)
   (let $resolved-item (eval $item)
     (case $resolved-item
       (((CodexTurnReasoningItem $id $summary-text $raw-content)
         $summary-text)
        ($other
         Empty)))))

(= (codex:turn-reasoning-item-raw-content $item)
   (let $resolved-item (eval $item)
     (case $resolved-item
       (((CodexTurnReasoningItem $id $summary-text $raw-content)
         $raw-content)
        ($other
         Empty)))))

(= (codex:turn-web-search-item $id $query $action)
   (CodexTurnWebSearchItem $id $query $action))

(= (codex:turn-web-search-item-id $item)
   (let $resolved-item (eval $item)
     (case $resolved-item
       (((CodexTurnWebSearchItem $id $query $action)
         $id)
        ($other
         Empty)))))

(= (codex:turn-web-search-item-query $item)
   (let $resolved-item (eval $item)
     (case $resolved-item
       (((CodexTurnWebSearchItem $id $query $action)
         $query)
        ($other
         Empty)))))

(= (codex:turn-web-search-item-action $item)
   (let $resolved-item (eval $item)
     (case $resolved-item
       (((CodexTurnWebSearchItem $id $query $action)
         $action)
        ($other
         Empty)))))

(= (codex:turn-image-generation-item
      $id
      $status
      $revised-prompt
      $result
      $saved-path)
   (CodexTurnImageGenerationItem
     $id
     $status
     $revised-prompt
     $result
     $saved-path))

(= (codex:turn-image-generation-item-id $item)
   (let $resolved-item (eval $item)
     (case $resolved-item
       (((CodexTurnImageGenerationItem
           $id
           $status
           $revised-prompt
           $result
           $saved-path)
         $id)
        ($other
         Empty)))))

(= (codex:turn-image-generation-item-status $item)
   (let $resolved-item (eval $item)
     (case $resolved-item
       (((CodexTurnImageGenerationItem
           $id
           $status
           $revised-prompt
           $result
           $saved-path)
         $status)
        ($other
         Empty)))))

(= (codex:turn-image-generation-item-revised-prompt $item)
   (let $resolved-item (eval $item)
     (case $resolved-item
       (((CodexTurnImageGenerationItem
           $id
           $status
           $revised-prompt
           $result
           $saved-path)
         (if (== $revised-prompt CodexAbsent) Empty $revised-prompt))
        ($other
         Empty)))))

(= (codex:turn-image-generation-item-result $item)
   (let $resolved-item (eval $item)
     (case $resolved-item
       (((CodexTurnImageGenerationItem
           $id
           $status
           $revised-prompt
           $result
           $saved-path)
         $result)
        ($other
         Empty)))))

(= (codex:turn-item-user-message $item)
   (CodexTurnItemUserMessage $item))

(= (codex:turn-item-hook-prompt $item)
   (CodexTurnItemHookPrompt $item))

(= (codex:turn-item-agent-message $item)
   (CodexTurnItemAgentMessage $item))

(= (codex:turn-item-reasoning $item)
   (CodexTurnItemReasoning $item))

(= (codex:turn-item-web-search $item)
   (CodexTurnItemWebSearch $item))

(= (codex:turn-item-image-generation $item)
   (CodexTurnItemImageGeneration $item))

(= (codex:turn-item-user-message-value $item)
   (let $resolved-item (eval $item)
     (case $resolved-item
       (((CodexTurnItemUserMessage $value)
         $value)
        ($other
         Empty)))))

(= (codex:turn-item-hook-prompt-value $item)
   (let $resolved-item (eval $item)
     (case $resolved-item
       (((CodexTurnItemHookPrompt $value)
         $value)
        ($other
         Empty)))))

(= (codex:turn-item-agent-message-value $item)
   (let $resolved-item (eval $item)
     (case $resolved-item
       (((CodexTurnItemAgentMessage $value)
         $value)
        ($other
         Empty)))))

(= (codex:turn-item-reasoning-value $item)
   (let $resolved-item (eval $item)
     (case $resolved-item
       (((CodexTurnItemReasoning $value)
         $value)
        ($other
         Empty)))))

(= (codex:turn-item-web-search-value $item)
   (let $resolved-item (eval $item)
     (case $resolved-item
       (((CodexTurnItemWebSearch $value)
         $value)
        ($other
         Empty)))))

(= (codex:turn-item-image-generation-value $item)
   (let $resolved-item (eval $item)
     (case $resolved-item
       (((CodexTurnItemImageGeneration $value)
         $value)
        ($other
         Empty)))))

(= (codex:generated-turn-item-id $kind)
   (str-concat "generated-" $kind))

(= (codex:is-input-image-content-item $item)
   (case $item
     (((CodexInputImage $image-url $detail)
       True)
      ($other
       False))))

(= (codex:parse-user-message-content () $previous-item)
   ())

(= (codex:parse-user-message-content $items $previous-item)
   (let $head (list:first $items)
     (let $tail (list:rest $items)
       (case $head
         (((CodexInputText $text)
           (let $next-item
             (if (== $tail ())
                 CodexAbsent
                 (list:first $tail))
             (if (or
                   (and
                     (or
                       (codex:is-local-image-open-tag-text $text)
                       (codex:is-image-open-tag-text $text))
                     (codex:is-input-image-content-item $next-item))
                   (and
                     (codex:is-input-image-content-item $previous-item)
                     (or
                       (codex:is-local-image-close-tag-text $text)
                       (codex:is-image-close-tag-text $text))))
                 (case (codex:parse-user-message-content $tail $head)
                   (($parsed-tail
                      $parsed-tail)))
                 (case (codex:parse-user-message-content $tail $head)
                   (($parsed-tail
                      (cons-atom
                        (CodexTurnUserInputText $text)
                        $parsed-tail)))))))
          ((CodexInputImage $image-url $detail)
           (case (codex:parse-user-message-content $tail $head)
             (($parsed-tail
                (cons-atom
                  (CodexTurnUserInputImage $image-url)
                  $parsed-tail)))))
          ((CodexOutputText $text)
           (case (codex:parse-user-message-content $tail $head)
             (($parsed-tail
                $parsed-tail))))
          ($other
            (case (codex:parse-user-message-content $tail $head)
              (($parsed-tail
                 $parsed-tail)))))))))

(= (codex:parse-user-message $message)
   (if (codex:is-contextual-user-message-content $message)
       Empty
       (CodexTurnUserMessageItem
         (codex:generated-turn-item-id "user-message")
         (codex:parse-user-message-content $message CodexAbsent))))

(= (codex:parse-agent-message-content ())
   ())

(= (codex:parse-agent-message-content $items)
   (let $head (list:first $items)
     (let $tail (list:rest $items)
       (case $head
         (((CodexInputText $text)
           (case (codex:parse-agent-message-content $tail)
             (($parsed-tail
                (cons-atom
                  (codex:turn-agent-message-content-text $text)
                  $parsed-tail)))))
          ((CodexOutputText $text)
           (case (codex:parse-agent-message-content $tail)
             (($parsed-tail
                (cons-atom
                  (codex:turn-agent-message-content-text $text)
                  $parsed-tail)))))
          ($other
            (case (codex:parse-agent-message-content $tail)
              (($parsed-tail
                 $parsed-tail)))))))))

(= (codex:optional-id-or-generated $id $kind)
   (if (== $id CodexAbsent)
       (codex:generated-turn-item-id $kind)
       $id))

(= (codex:parse-agent-message $id $message $phase)
   (codex:turn-agent-message-item
     (codex:optional-id-or-generated $id "agent-message")
     (codex:parse-agent-message-content $message)
     $phase))

(= (codex:parse-reasoning-summary-text ())
   ())

(= (codex:parse-reasoning-summary-text $summary)
   (let $head (list:first $summary)
     (let $tail (list:rest $summary)
       (let $resolved-head (eval $head)
         (case $resolved-head
           (((CodexReasoningItemSummaryText $text)
             (case (codex:parse-reasoning-summary-text $tail)
               (($parsed-tail
                  (cons-atom
                    $text
                    $parsed-tail)))))
            ($other
              (case (codex:parse-reasoning-summary-text $tail)
                (($parsed-tail
                   $parsed-tail))))))))))

(= (codex:parse-reasoning-raw-content CodexAbsent)
   ())

(= (codex:parse-reasoning-raw-content ())
   ())

(= (codex:parse-reasoning-raw-content $content)
   (let $head (list:first $content)
     (let $tail (list:rest $content)
       (let $resolved-head (eval $head)
         (case $resolved-head
           (((CodexReasoningItemContentReasoningText $text)
             (case (codex:parse-reasoning-raw-content $tail)
               (($parsed-tail
                  (cons-atom
                    $text
                    $parsed-tail)))))
            ((CodexReasoningItemContentText $text)
             (case (codex:parse-reasoning-raw-content $tail)
               (($parsed-tail
                  (cons-atom
                    $text
                    $parsed-tail)))))
            ($other
              (case (codex:parse-reasoning-raw-content $tail)
                (($parsed-tail
                   $parsed-tail))))))))))

(= (codex:web-search-search-action-detail $query $queries)
   (if (== $query CodexAbsent)
       (if (== $queries CodexAbsent)
           ""
           (if (== $queries ())
               ""
               (let $first (list:first $queries)
                 (let $tail (list:rest $queries)
                   (if (and (!= $first "")
                            (!= $tail ()))
                       (str-concat $first " ...")
                       $first)))))
       (if (== $query "")
           (codex:web-search-search-action-detail CodexAbsent $queries)
           $query)))

(= (codex:web-search-action-detail
      (CodexWebSearchActionSearch $query $queries))
   (codex:web-search-search-action-detail $query $queries))

(= (codex:web-search-action-detail
      (CodexWebSearchActionOpenPage $url))
   (if (== $url CodexAbsent) "" $url))

(= (codex:web-search-action-detail
      (CodexWebSearchActionFindInPage $url $pattern))
   (if (== $pattern CodexAbsent)
       (if (== $url CodexAbsent) "" $url)
       (if (== $url CodexAbsent)
           (format-args "'{}'" ($pattern))
           (format-args "'{}' in {}" ($pattern $url)))))

(= (codex:web-search-action-detail
      (CodexWebSearchActionOther))
   "")

; CeTTa-specific reduction forcing: the imported hook-prompt parser must be
; evaluated eagerly here so this helper preserves Rust's
; `parse_visible_hook_prompt_message(...).or_else(parse_user_message(...))`
; behavior when nested inside `parse-turn-item`.
(= (codex:parse-user-turn-item $id $content)
   (let $hook-prompt-item
     (eval (codex:parse-visible-hook-prompt-message $id $content))
     (if (== $hook-prompt-item Empty)
         (let $user-message (codex:parse-user-message $content)
           (if (== $user-message Empty)
               Empty
               (codex:turn-item-user-message $user-message)))
         (codex:turn-item-hook-prompt $hook-prompt-item))))

(= (codex:parse-turn-item $item)
   (let $resolved-item (eval $item)
     (codex:parse-turn-item-resolved $resolved-item)))

(= (codex:parse-turn-item-resolved $item)
   (case $item
     (((CodexResponseItemMessage "user" $content $phase)
       (codex:parse-user-turn-item CodexAbsent $content))
      ((CodexResponseItemMessageWithId $id "user" $content $phase)
       (codex:parse-user-turn-item $id $content))
      ((CodexResponseItemMessage "assistant" $content $phase)
       (codex:turn-item-agent-message
         (codex:parse-agent-message CodexAbsent $content $phase)))
      ((CodexResponseItemMessageWithId $id "assistant" $content $phase)
       (codex:turn-item-agent-message
         (codex:parse-agent-message $id $content $phase)))
      ((CodexResponseItemMessage "system" $content $phase)
       Empty)
      ((CodexResponseItemMessageWithId $id "system" $content $phase)
       Empty)
      ((CodexResponseItemMessage $role $content $phase)
       Empty)
      ((CodexResponseItemMessageWithId $id $role $content $phase)
       Empty)
      ((CodexResponseItemReasoning $id $summary $content $encrypted-content)
       (codex:turn-item-reasoning
         (codex:turn-reasoning-item
           $id
           (codex:parse-reasoning-summary-text $summary)
           (codex:parse-reasoning-raw-content $content))))
      ((CodexResponseItemWebSearchCall $id $status $action)
       (let $effective-action
         (if (== $action CodexAbsent)
             (codex:web-search-action-other)
             (eval $action))
         (codex:turn-item-web-search
           (codex:turn-web-search-item
             (if (== $id CodexAbsent) "" $id)
             (codex:web-search-action-detail $effective-action)
             $effective-action))))
      ((CodexResponseItemImageGenerationCall
         $id
         $status
         $revised-prompt
         $result)
       (codex:turn-item-image-generation
         (codex:turn-image-generation-item
           $id
           $status
           $revised-prompt
           $result
           CodexAbsent)))
      ($other
       Empty))))
