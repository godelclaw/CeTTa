; Rust-faithful pure turn-timing predicate slice.
;
; This ports the deterministic predicate behavior from:
; - openai-codex/codex-rs/core/src/turn_timing.rs
;
; Covered in this increment:
; - response_event_records_turn_ttft
; - response_item_records_turn_ttft
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust's `TurnTimingState` owns async mutex-protected clocks and telemetry
;   recording. This slice ports the pure predicate boundary that decides whether
;   a response event or item is allowed to record time-to-first-token; the
;   runtime state/metric layer belongs with a later async/session port.
; - Rust's `ResponseEvent` enum lives in codex-api. CeTTa does not yet expose
;   that enum in the protocol surface, so this file introduces local event
;   constructors with the same variant names and branch semantics used by
;   `response_event_records_turn_ttft`.
; - The current CeTTa protocol serializer has not yet exposed Rust
;   `ResponseItem::LocalShellCall`, `GhostSnapshot`, `Compaction`, or `Other`.
;   This predicate still recognizes local constructor shapes for those variants
;   so the Rust response-item branch table is preserved at this boundary.

!(import! &self stream_events_utils)
!(import! &self protocol)

(= (codex:response-event-created)
   (CodexResponseEventCreated))

(= (codex:response-event-output-item-done $item)
   (CodexResponseEventOutputItemDone $item))

(= (codex:response-event-output-item-added $item)
   (CodexResponseEventOutputItemAdded $item))

(= (codex:response-event-server-model $model)
   (CodexResponseEventServerModel $model))

(= (codex:response-event-model-verifications $verifications)
   (CodexResponseEventModelVerifications $verifications))

(= (codex:response-event-server-reasoning-included $included)
   (CodexResponseEventServerReasoningIncluded $included))

(= (codex:response-event-completed $response-id $token-usage)
   (CodexResponseEventCompleted $response-id $token-usage))

(= (codex:response-event-output-text-delta $delta)
   (CodexResponseEventOutputTextDelta $delta))

(= (codex:response-event-tool-call-input-delta $item-id $call-id $delta)
   (CodexResponseEventToolCallInputDelta $item-id $call-id $delta))

(= (codex:response-event-reasoning-summary-delta $delta $summary-index)
   (CodexResponseEventReasoningSummaryDelta $delta $summary-index))

(= (codex:response-event-reasoning-content-delta $delta $content-index)
   (CodexResponseEventReasoningContentDelta $delta $content-index))

(= (codex:response-event-reasoning-summary-part-added $summary-index)
   (CodexResponseEventReasoningSummaryPartAdded $summary-index))

(= (codex:response-event-rate-limits $snapshot)
   (CodexResponseEventRateLimits $snapshot))

(= (codex:response-event-models-etag $etag)
   (CodexResponseEventModelsEtag $etag))

(= (codex:local-shell-call-response-item $id $call-id $status $action)
   (CodexResponseItemLocalShellCall $id $call-id $status $action))

(= (codex:ghost-snapshot-response-item $ghost-commit)
   (CodexResponseItemGhostSnapshot $ghost-commit))

(= (codex:compaction-response-item $encrypted-content)
   (CodexResponseItemCompaction $encrypted-content))

(= (codex:response-item-other)
   (CodexResponseItemOther))

(= (codex:response-event-records-turn-ttft $event)
   (case (once (eval $event))
     (((CodexResponseEventOutputItemDone $item)
       (codex:response-item-records-turn-ttft $item))
      ((CodexResponseEventOutputItemAdded $item)
       (codex:response-item-records-turn-ttft $item))
      ((CodexResponseEventOutputTextDelta $delta)
       True)
      ((CodexResponseEventReasoningSummaryDelta $delta $summary-index)
       True)
      ((CodexResponseEventReasoningContentDelta $delta $content-index)
       True)
      ((CodexResponseEventCreated)
       False)
      ((CodexResponseEventServerModel $model)
       False)
      ((CodexResponseEventModelVerifications $verifications)
       False)
      ((CodexResponseEventServerReasoningIncluded $included)
       False)
      ((CodexResponseEventToolCallInputDelta $item-id $call-id $delta)
       False)
      ((CodexResponseEventCompleted $response-id $token-usage)
       False)
      ((CodexResponseEventReasoningSummaryPartAdded $summary-index)
       False)
      ((CodexResponseEventRateLimits $snapshot)
       False)
      ((CodexResponseEventModelsEtag $etag)
       False)
      ($other False))))

(= (codex:response-item-records-turn-ttft $item)
   (case (once (eval $item))
     (((CodexResponseItemMessage $role $content $phase)
       (case (codex:raw-assistant-output-text-from-item $item)
         ((CodexAbsent False)
          ("" False)
          ($text True))))
      ((CodexResponseItemMessageWithId $id $role $content $phase)
       (case (codex:raw-assistant-output-text-from-item $item)
         ((CodexAbsent False)
          ("" False)
          ($text True))))
      ((CodexResponseItemReasoning $id $summary $content $encrypted-content)
       (codex:reasoning-item-records-turn-ttft $summary $content))
      ((CodexResponseItemLocalShellCall $id $call-id $status $action)
       True)
      ((CodexResponseItemFunctionCall $id $name $namespace $arguments $call-id)
       True)
      ((CodexResponseItemCustomToolCall $call-id $name $input)
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
      ((CodexResponseItemGhostSnapshot $ghost-commit)
       True)
      ((CodexResponseItemCompaction $encrypted-content)
       True)
      ((CodexResponseItemFunctionCallOutput $call-id $output)
       False)
      ((CodexResponseItemCustomToolCallOutput $call-id $name $output)
       False)
      ((CodexResponseItemToolSearchOutput $call-id $status $execution $tools)
       False)
      ((CodexResponseItemOther)
       False)
      ($other False))))

(= (codex:reasoning-item-records-turn-ttft $summary $content)
   (case (codex:reasoning-summary-records-turn-ttft $summary)
     ((True True)
      (False
       (codex:reasoning-content-option-records-turn-ttft $content)))))

(= (codex:reasoning-summary-records-turn-ttft ())
   False)

(= (codex:reasoning-summary-records-turn-ttft $summary)
   (let $head (car-atom $summary)
     (let $tail (cdr-atom $summary)
       (case $head
         (((CodexReasoningItemSummaryText $text)
           (if (== $text "")
               (codex:reasoning-summary-records-turn-ttft $tail)
               True))
          ($other
           (codex:reasoning-summary-records-turn-ttft $tail)))))))

(= (codex:reasoning-content-option-records-turn-ttft CodexAbsent)
   False)

(= (codex:reasoning-content-option-records-turn-ttft $content)
   (codex:reasoning-content-records-turn-ttft $content))

(= (codex:reasoning-content-records-turn-ttft ())
   False)

(= (codex:reasoning-content-records-turn-ttft $content)
   (let $head (car-atom $content)
     (let $tail (cdr-atom $content)
       (case $head
         (((CodexReasoningItemContentReasoningText $text)
           (if (== $text "")
               (codex:reasoning-content-records-turn-ttft $tail)
               True))
          ((CodexReasoningItemContentText $text)
           (if (== $text "")
               (codex:reasoning-content-records-turn-ttft $tail)
               True))
          ($other
           (codex:reasoning-content-records-turn-ttft $tail)))))))
