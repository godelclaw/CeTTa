; Rust-faithful ToolCallRuntime-to-ToolRegistry pre-handler dispatch slice.
;
; This ports the deterministic composition from:
; - openai-codex/codex-rs/core/src/tools/parallel.rs
;   - ToolCallRuntime::handle_tool_call_with_source up to the router future
; - openai-codex/codex-rs/core/src/tools/router.rs
;   - dispatch_tool_call_with_code_mode_result pre-dispatch checks
; - openai-codex/codex-rs/core/src/tools/registry.rs
;   - ToolRegistry::dispatch_any pre-handler lookup / payload compatibility
;
; Covered in this increment:
; - parallel support and lock-mode plan
; - router direct-call gating and ToolInvocation construction
; - registry unsupported-call and incompatible-payload errors
; - ready state immediately before async handler execution
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust acquires the async RwLock guard and awaits the router/registry future.
;   This pure CeTTa slice emits the lock mode and deterministic pre-handler
;   dispatch result instead of performing scheduling or handler side effects.
; - Rust enters `handler.handle(...)` after these checks. The `Ready` result
;   here is the precise boundary before that async trait-object call.

!(import! &self function_tool)
!(import! &self tool_registry_dispatch_plan)
!(import! &self tool_router_dispatch_plan)
!(import! &self tool_router_runtime_access_plan)
!(import! &self tool_runtime_parallel_plan)

(= (codex:tool-call-runtime-registry-dispatch-ready
      $runtime-plan
      $registry-ready-plan)
   (CodexToolCallRuntimeRegistryDispatchReady
     $runtime-plan
     $registry-ready-plan))

(= (codex:tool-call-runtime-registry-dispatch-error
      $runtime-plan
      $error)
   (CodexToolCallRuntimeRegistryDispatchError $runtime-plan $error))

(= (codex:tool-call-runtime-registry-dispatch-runtime-plan
      (CodexToolCallRuntimeRegistryDispatchReady
        $runtime-plan
        $registry-ready-plan))
   $runtime-plan)

(= (codex:tool-call-runtime-registry-dispatch-runtime-plan
      (CodexToolCallRuntimeRegistryDispatchError $runtime-plan $error))
   $runtime-plan)

(= (codex:tool-call-runtime-registry-dispatch-ready-plan
      (CodexToolCallRuntimeRegistryDispatchReady
        $runtime-plan
        $registry-ready-plan))
   $registry-ready-plan)

(= (codex:tool-call-runtime-registry-dispatch-error-value
      (CodexToolCallRuntimeRegistryDispatchError $runtime-plan $error))
   $error)

(= (codex:tool-call-runtime-registry-dispatch-plan
      $runtime-access
      $call
      $source
      $cancellation-token)
   (let $runtime-plan
     (codex:tool-call-runtime-handle-tool-call-with-source-plan
       (codex:tool-call-runtime-access-runtime $runtime-access)
       $call
       $source
       $cancellation-token)
     (let $router-dispatch-plan
       (codex:tool-call-runtime-dispatch-plan-router-dispatch-plan
         $runtime-plan)
       (case $router-dispatch-plan
         (((CodexToolRouterDispatchPlanRejected $error)
           (codex:tool-call-runtime-registry-dispatch-error
             $runtime-plan
             $error))
          ((CodexToolRouterDispatchPlanOk $invocation)
           (case
             (codex:tool-registry-dispatch-any-plan
               (codex:tool-call-runtime-access-registry $runtime-access)
               $invocation)
             (((CodexToolRegistryDispatchPlanReady
                 $ready-invocation
                 $binding)
               (codex:tool-call-runtime-registry-dispatch-ready
                 $runtime-plan
                 (codex:tool-registry-dispatch-plan-ready
                   $ready-invocation
                   $binding)))
              ((CodexToolRegistryDispatchPlanError $error)
               (codex:tool-call-runtime-registry-dispatch-error
                 $runtime-plan
                 $error))))))))))
