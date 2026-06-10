; Rust-faithful response event vocabulary (core-loop spine).
;
; This ports the ResponseEvent enum from:
; - openai-codex/codex-rs/codex-api/src/common.rs (ResponseEvent, 14
;   variants in declaration order)
; plus the stream-item wrapper mirroring the Rust stream's
; Option<Result<ResponseEvent>> shape: (CodexStreamItemOk $event) /
; (CodexStreamItemErr $err), with list end standing for Rust's None.
;
; Required slice-local deviations from Rust, documented for audit:
; - Option fields (Completed.token_usage, ToolCallInputDelta.call_id) use
;   CodexAbsent for None per the established port convention.

(= (codex:response-event-created)
   (CodexResponseEventCreated))

(= (codex:response-event-output-item-done
      $item)
   (CodexResponseEventOutputItemDone
     $item))

(= (codex:response-event-output-item-done-item
      (CodexResponseEventOutputItemDone
        $item))
   $item)

(= (codex:response-event-output-item-added
      $item)
   (CodexResponseEventOutputItemAdded
     $item))

(= (codex:response-event-output-item-added-item
      (CodexResponseEventOutputItemAdded
        $item))
   $item)

(= (codex:response-event-server-model
      $model)
   (CodexResponseEventServerModel
     $model))

(= (codex:response-event-server-model-model
      (CodexResponseEventServerModel
        $model))
   $model)

(= (codex:response-event-model-verifications
      $verifications)
   (CodexResponseEventModelVerifications
     $verifications))

(= (codex:response-event-model-verifications-verifications
      (CodexResponseEventModelVerifications
        $verifications))
   $verifications)

(= (codex:response-event-server-reasoning-included
      $included)
   (CodexResponseEventServerReasoningIncluded
     $included))

(= (codex:response-event-server-reasoning-included-included
      (CodexResponseEventServerReasoningIncluded
        $included))
   $included)

(= (codex:response-event-completed
      $response-id
      $token-usage)
   (CodexResponseEventCompleted
     $response-id
     $token-usage))

(= (codex:response-event-completed-response-id
      (CodexResponseEventCompleted
        $response-id
        $token-usage))
   $response-id)

(= (codex:response-event-completed-token-usage
      (CodexResponseEventCompleted
        $response-id
        $token-usage))
   $token-usage)

(= (codex:response-event-output-text-delta
      $delta)
   (CodexResponseEventOutputTextDelta
     $delta))

(= (codex:response-event-output-text-delta-delta
      (CodexResponseEventOutputTextDelta
        $delta))
   $delta)

(= (codex:response-event-tool-call-input-delta
      $item-id
      $call-id
      $delta)
   (CodexResponseEventToolCallInputDelta
     $item-id
     $call-id
     $delta))

(= (codex:response-event-tool-call-input-delta-item-id
      (CodexResponseEventToolCallInputDelta
        $item-id
        $call-id
        $delta))
   $item-id)

(= (codex:response-event-tool-call-input-delta-call-id
      (CodexResponseEventToolCallInputDelta
        $item-id
        $call-id
        $delta))
   $call-id)

(= (codex:response-event-tool-call-input-delta-delta
      (CodexResponseEventToolCallInputDelta
        $item-id
        $call-id
        $delta))
   $delta)

(= (codex:response-event-reasoning-summary-delta
      $delta
      $summary-index)
   (CodexResponseEventReasoningSummaryDelta
     $delta
     $summary-index))

(= (codex:response-event-reasoning-summary-delta-delta
      (CodexResponseEventReasoningSummaryDelta
        $delta
        $summary-index))
   $delta)

(= (codex:response-event-reasoning-summary-delta-summary-index
      (CodexResponseEventReasoningSummaryDelta
        $delta
        $summary-index))
   $summary-index)

(= (codex:response-event-reasoning-content-delta
      $delta
      $content-index)
   (CodexResponseEventReasoningContentDelta
     $delta
     $content-index))

(= (codex:response-event-reasoning-content-delta-delta
      (CodexResponseEventReasoningContentDelta
        $delta
        $content-index))
   $delta)

(= (codex:response-event-reasoning-content-delta-content-index
      (CodexResponseEventReasoningContentDelta
        $delta
        $content-index))
   $content-index)

(= (codex:response-event-reasoning-summary-part-added
      $summary-index)
   (CodexResponseEventReasoningSummaryPartAdded
     $summary-index))

(= (codex:response-event-reasoning-summary-part-added-summary-index
      (CodexResponseEventReasoningSummaryPartAdded
        $summary-index))
   $summary-index)

(= (codex:response-event-rate-limits
      $snapshot)
   (CodexResponseEventRateLimits
     $snapshot))

(= (codex:response-event-rate-limits-snapshot
      (CodexResponseEventRateLimits
        $snapshot))
   $snapshot)

(= (codex:response-event-models-etag
      $etag)
   (CodexResponseEventModelsEtag
     $etag))

(= (codex:response-event-models-etag-etag
      (CodexResponseEventModelsEtag
        $etag))
   $etag)

; --- stream items -----------------------------------------------------------

(= (codex:stream-item-ok $event)
   (CodexStreamItemOk $event))

(= (codex:stream-item-err $err)
   (CodexStreamItemErr $err))

(= (codex:stream-item-is-ok (CodexStreamItemOk $event))
   True)

(= (codex:stream-item-is-ok (CodexStreamItemErr $err))
   False)

(= (codex:stream-item-event (CodexStreamItemOk $event))
   $event)

(= (codex:stream-item-error (CodexStreamItemErr $err))
   $err)
