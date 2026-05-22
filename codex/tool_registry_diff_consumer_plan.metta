; Rust-faithful ToolRegistry diff-consumer planning slice.
;
; This ports deterministic delegation from:
; - openai-codex/codex-rs/core/src/tools/registry.rs
;   - ToolRegistry::create_diff_consumer
;   - ToolHandler::create_diff_consumer default of None
; - openai-codex/codex-rs/core/src/tools/handlers/apply_patch.rs
;   - ApplyPatchHandler::create_diff_consumer
;
; Covered in this increment:
; - registry handler lookup by ToolName before creating a diff consumer
; - ApplyPatchHandler returning an ApplyPatchArgumentDiffConsumer
; - default handler behavior returning no consumer for current non-apply-patch
;   handler kinds
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust returns `Option<Box<dyn ToolArgumentDiffConsumer>>`. This pure CeTTa
;   slice uses `CodexAbsent` for `None` and a tagged
;   `CodexToolArgumentDiffConsumerApplyPatch` value for the currently ported
;   concrete consumer.
; - Rust passes `TurnContext` into `consume_diff`, and the apply_patch consumer
;   reads the ApplyPatchStreamingEvents feature plus `Instant::now()`. The
;   existing CeTTa apply_patch consumer takes the feature flag and timestamp as
;   explicit inputs; this wrapper preserves the registry/trait dispatch layer
;   while keeping those pure parameters explicit.

!(import! &self apply_patch)
!(import! &self tool_registry_builder_plan)
!(import! &self tool_registry_dispatch_plan)
!(import! &self tool_registry_plan)

(= (codex:tool-argument-diff-consumer-apply-patch $consumer)
   (CodexToolArgumentDiffConsumerApplyPatch $consumer))

(= (codex:tool-argument-diff-consumer-kind
      (CodexToolArgumentDiffConsumerApplyPatch $consumer))
   "ApplyPatch")

(= (codex:tool-argument-diff-consumer-apply-patch-state
      (CodexToolArgumentDiffConsumerApplyPatch $consumer))
   $consumer)

(= (codex:tool-argument-diff-consumer-result
      $consumer
      $event)
   (CodexToolArgumentDiffConsumerResult $consumer $event))

(= (codex:tool-argument-diff-consumer-result-consumer
      (CodexToolArgumentDiffConsumerResult $consumer $event))
   $consumer)

(= (codex:tool-argument-diff-consumer-result-event
      (CodexToolArgumentDiffConsumerResult $consumer $event))
   $event)

(= (codex:tool-registry-handler-kind-create-diff-consumer $kind)
   (let $is-apply-patch
     (once (eval (== $kind (codex:tool-handler-kind-apply-patch))))
     (if $is-apply-patch
         (codex:tool-argument-diff-consumer-apply-patch
           (codex:apply-patch-argument-diff-consumer-new))
         CodexAbsent)))

(= (codex:tool-registry-handler-binding-create-diff-consumer
      (CodexToolRegistryHandlerBinding $name $kind))
   (codex:tool-registry-handler-kind-create-diff-consumer $kind))

(= (codex:tool-registry-create-diff-consumer $registry $tool-name)
   (case (codex:tool-registry-find-handler-binding $registry $tool-name)
     ((Empty CodexAbsent)
      ($binding
       (codex:tool-registry-handler-binding-create-diff-consumer
         $binding)))))

(= (codex:tool-argument-diff-consumer-consume-diff-at
      $feature-enabled
      (CodexToolArgumentDiffConsumerApplyPatch $consumer)
      $call-id
      $diff
      $now-ms)
   (let $result
     (codex:apply-patch-argument-diff-consumer-consume-diff-at
       $feature-enabled
       $consumer
       $call-id
       $diff
       $now-ms)
     (codex:tool-argument-diff-consumer-result
       (codex:tool-argument-diff-consumer-apply-patch
         (codex:apply-patch-argument-diff-consumer-result-consumer
           $result))
       (codex:apply-patch-argument-diff-consumer-result-event
         $result))))

(= (codex:tool-argument-diff-consumer-flush-on-complete-at
      (CodexToolArgumentDiffConsumerApplyPatch $consumer)
      $now-ms)
   (let $result
     (codex:apply-patch-argument-diff-consumer-flush-on-complete-at
       $consumer
       $now-ms)
     (codex:tool-argument-diff-consumer-result
       (codex:tool-argument-diff-consumer-apply-patch
         (codex:apply-patch-argument-diff-consumer-result-consumer
           $result))
       (codex:apply-patch-argument-diff-consumer-result-event
         $result))))
