; Rust-faithful context-manager history predicate slice.
;
; This ports the pure classification helpers from:
; - openai-codex/codex-rs/core/src/context_manager/history.rs
;
; Covered in this increment:
; - is_api_message
; - is_model_generated_item
; - is_codex_generated_item
; - is_user_turn_boundary
; - user_message_positions
; - items_after_last_model_generated_item
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust's `ResponseItem::Message` has an optional id field. The restarted
;   CeTTa protocol surface has both legacy 3-field messages and narrow 4-field
;   `MessageWithId`; this slice treats both as the same Rust variant.
; - Some Rust `ResponseItem` variants are represented in CeTTa by local
;   constructor shapes introduced by adjacent pure slices before the serializer
;   exposes them. This file recognizes those shapes to preserve the Rust branch
;   table at this boundary.
; - Rust validates inter-agent instruction content by deserializing a single
;   input/output text content item into `InterAgentCommunication`. The CeTTa
;   port of that protocol predicate currently lives with the adjacent thread
;   rollout truncation slice, so this helper delegates to it rather than
;   maintaining a second parser that could drift.

!(import! &self event_mapping)
!(import! &self list)
!(import! &self protocol)
!(import! &self thread_rollout_truncation)

(= (codex:context-manager-history-is-api-message $item)
   (case $item
     (((CodexResponseItemMessage "system" $content $phase)
       False)
      ((CodexResponseItemMessage $role $content $phase)
       True)
      ((CodexResponseItemMessageWithId $id "system" $content $phase)
       False)
      ((CodexResponseItemMessageWithId $id $role $content $phase)
       True)
      ((CodexResponseItemFunctionCallOutput $call-id $output)
       True)
      ((CodexResponseItemFunctionCall $id $name $namespace $arguments $call-id)
       True)
      ((CodexResponseItemToolSearchCall
         $id
         $call-id
         $status
         $execution
         $arguments)
       True)
      ((CodexResponseItemToolSearchOutput $call-id $status $execution $tools)
       True)
      ((CodexResponseItemCustomToolCall $call-id $name $input)
       True)
      ((CodexResponseItemCustomToolCallOutput $call-id $name $output)
       True)
      ((CodexResponseItemLocalShellCall $id $call-id $status $action)
       True)
      ((CodexResponseItemReasoning $id $summary $content $encrypted-content)
       True)
      ((CodexResponseItemWebSearchCall $id $status $action)
       True)
      ((CodexResponseItemImageGenerationCall
         $id
         $status
         $revised-prompt
         $result)
       True)
      ((CodexResponseItemCompaction $encrypted-content)
       True)
      ((CodexResponseItemGhostSnapshot $ghost-commit)
       False)
      ((CodexResponseItemOther)
       False)
      ($other
       False))))

(= (codex:context-manager-history-is-model-generated-item $item)
   (case $item
     (((CodexResponseItemMessage "assistant" $content $phase)
       True)
      ((CodexResponseItemMessage $role $content $phase)
       False)
      ((CodexResponseItemMessageWithId $id "assistant" $content $phase)
       True)
      ((CodexResponseItemMessageWithId $id $role $content $phase)
       False)
      ((CodexResponseItemReasoning $id $summary $content $encrypted-content)
       True)
      ((CodexResponseItemFunctionCall $id $name $namespace $arguments $call-id)
       True)
      ((CodexResponseItemToolSearchCall
         $id
         $call-id
         $status
         $execution
         $arguments)
       True)
      ((CodexResponseItemWebSearchCall $id $status $action)
       True)
      ((CodexResponseItemImageGenerationCall
         $id
         $status
         $revised-prompt
         $result)
       True)
      ((CodexResponseItemCustomToolCall $call-id $name $input)
       True)
      ((CodexResponseItemLocalShellCall $id $call-id $status $action)
       True)
      ((CodexResponseItemCompaction $encrypted-content)
       True)
      ((CodexResponseItemFunctionCallOutput $call-id $output)
       False)
      ((CodexResponseItemToolSearchOutput $call-id $status $execution $tools)
       False)
      ((CodexResponseItemCustomToolCallOutput $call-id $name $output)
       False)
      ((CodexResponseItemGhostSnapshot $ghost-commit)
       False)
      ((CodexResponseItemOther)
       False)
      ($other
       False))))

(= (codex:is-codex-generated-item $item)
   (case $item
     (((CodexResponseItemFunctionCallOutput $call-id $output)
       True)
      ((CodexResponseItemToolSearchOutput $call-id $status $execution $tools)
       True)
      ((CodexResponseItemCustomToolCallOutput $call-id $name $output)
       True)
      ((CodexResponseItemMessage "developer" $content $phase)
       True)
      ((CodexResponseItemMessageWithId $id "developer" $content $phase)
       True)
      ($other
       False))))

(= (codex:context-manager-history-is-inter-agent-instruction-content $content)
   (codex:is-thread-rollout-inter-agent-instruction-content $content))

(= (codex:is-user-turn-boundary $item)
   (case $item
     (((CodexResponseItemMessage "user" $content $phase)
       (case (codex:is-contextual-user-message-content $content)
         ((True False)
          (False True))))
      ((CodexResponseItemMessageWithId $id "user" $content $phase)
       (case (codex:is-contextual-user-message-content $content)
         ((True False)
          (False True))))
      ((CodexResponseItemMessage "assistant" $content $phase)
       (codex:context-manager-history-is-inter-agent-instruction-content
         $content))
      ((CodexResponseItemMessageWithId $id "assistant" $content $phase)
       (codex:context-manager-history-is-inter-agent-instruction-content
         $content))
      ($other
       False))))

(= (codex:context-manager-history-user-message-positions $items)
   (codex:context-manager-history-user-message-positions-at $items 0))

(= (codex:context-manager-history-user-message-positions-at () $index)
   ())

(= (codex:context-manager-history-user-message-positions-at $items $index)
   (let $head (list:first $items)
     (let $tail (list:rest $items)
       (let $next-index (+ $index 1)
         (case
           (codex:context-manager-history-user-message-positions-at
             $tail
             $next-index)
           (($tail-positions
             (case (codex:is-user-turn-boundary $head)
               ((True
                 (list:cons $index $tail-positions))
                (False
                 $tail-positions))))))))))

(= (codex:context-manager-history-items-after-last-model-generated-item $items)
   (codex:context-manager-history-items-after-last-model-generated-item-acc
     $items
     False
     ()))

(= (codex:context-manager-history-items-after-last-model-generated-item-acc
      ()
      $seen-model-generated
      $after-last)
   $after-last)

(= (codex:context-manager-history-items-after-last-model-generated-item-acc
      $items
      $seen-model-generated
      $after-last)
   (let $head (list:first $items)
     (let $tail (list:rest $items)
       (case (codex:context-manager-history-is-model-generated-item $head)
         ((True
           (codex:context-manager-history-items-after-last-model-generated-item-acc
             $tail
             True
             ()))
          (False
           (case $seen-model-generated
             ((False
               (codex:context-manager-history-items-after-last-model-generated-item-acc
                 $tail
                 False
                 ()))
              (True
               (case (list:append $after-last ($head))
                 (($next-after-last
                   (codex:context-manager-history-items-after-last-model-generated-item-acc
                     $tail
                     True
                     $next-after-last)))))))))))))
