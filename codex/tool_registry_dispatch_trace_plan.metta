; Rust-faithful ToolRegistry dispatch trace planning slice.
;
; This ports the deterministic trace lifecycle edges from:
; - openai-codex/codex-rs/core/src/tools/registry.rs
;   - ToolRegistry::dispatch_any calls to ToolDispatchTrace::start
;   - record_failed for unsupported/incompatible pre-handler errors
;   - record_completed for a completed AnyToolResult
; - openai-codex/codex-rs/core/src/tools/tool_dispatch_trace.rs
;   - ToolInvocation -> ToolDispatchInvocation projection
;   - disabled traces for js_repl and public code-mode exec boundaries
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust reads `session.conversation_id` and `turn.sub_id` from live shared
;   objects inside ToolInvocation. Current CeTTa planning records carry opaque
;   session/turn atoms, so this slice receives the thread and turn ids explicitly
;   while preserving the same ToolInvocation field projection.
; - Rust writes trace events through a rollout TraceWriter side effect. This pure
;   CeTTa slice returns the same start/end event payload decisions as data.

!(import! &self context)
!(import! &self function_tool)
!(import! &self tool_dispatch_trace)
!(import! &self tool_registry_dispatch_plan)
!(import! &self tool_router_dispatch_plan)
!(import! &self tool_runtime_parallel_plan)

(= (codex:tool-registry-dispatch-trace-disabled)
   (CodexToolRegistryDispatchTraceDisabled))

(= (codex:tool-registry-dispatch-trace-enabled
      $trace-invocation
      $start-event)
   (CodexToolRegistryDispatchTraceEnabled
     $trace-invocation
     $start-event))

(= (codex:tool-registry-dispatch-trace-state-invocation
      (CodexToolRegistryDispatchTraceEnabled
        $trace-invocation
        $start-event))
   $trace-invocation)

(= (codex:tool-registry-dispatch-trace-state-start-event
      (CodexToolRegistryDispatchTraceEnabled
        $trace-invocation
        $start-event))
   $start-event)

(= (codex:tool-registry-dispatch-trace-state-start-event
      (CodexToolRegistryDispatchTraceDisabled))
   CodexAbsent)

(= (codex:tool-registry-dispatch-trace-input
      $thread-id
      $codex-turn-id
      $invocation)
   (codex:tool-dispatch-invocation-input
     $thread-id
     $codex-turn-id
     (codex:tool-router-tool-invocation-call-id $invocation)
     (codex:tool-router-tool-invocation-tool-name $invocation)
     (codex:tool-router-tool-invocation-source $invocation)
     (codex:tool-router-tool-invocation-payload $invocation)))

(= (codex:tool-registry-dispatch-trace-start
      $thread-id
      $codex-turn-id
      $invocation)
   (case
     (codex:tool-dispatch-invocation-from-input
       (codex:tool-registry-dispatch-trace-input
         $thread-id
         $codex-turn-id
         $invocation))
     ((CodexAbsent
       (codex:tool-registry-dispatch-trace-disabled))
      ($trace-invocation
       (let $start-event
         (codex:tool-dispatch-start-trace $trace-invocation)
         (if (== $start-event CodexAbsent)
             (codex:tool-registry-dispatch-trace-disabled)
             (codex:tool-registry-dispatch-trace-enabled
               $trace-invocation
               $start-event)))))))

(= (codex:tool-registry-dispatch-trace-record-failed
      (CodexToolRegistryDispatchTraceDisabled)
      $error)
   CodexAbsent)

(= (codex:tool-registry-dispatch-trace-record-failed
      (CodexToolRegistryDispatchTraceEnabled
        $trace-invocation
        $start-event)
      $error)
   (codex:tool-dispatch-record-failed
     True
     (codex:function-call-error-display $error)))

(= (codex:tool-registry-dispatch-trace-record-completed
      (CodexToolRegistryDispatchTraceDisabled)
      $invocation
      $any-tool-result)
   CodexAbsent)

(= (codex:tool-registry-dispatch-trace-record-completed
      (CodexToolRegistryDispatchTraceEnabled
        $trace-invocation
        $start-event)
      $invocation
      $any-tool-result)
   (codex:tool-dispatch-record-completed
     True
     (codex:tool-router-tool-invocation-source $invocation)
     (codex:tool-call-runtime-any-tool-result-call-id $any-tool-result)
     (codex:tool-call-runtime-any-tool-result-payload $any-tool-result)
     (codex:tool-call-runtime-any-tool-result-tool-output $any-tool-result)))

(= (codex:tool-registry-dispatch-trace-plan
      $dispatch-plan
      $trace-state
      $end-event)
   (CodexToolRegistryDispatchTracePlan
     $dispatch-plan
     $trace-state
     $end-event))

(= (codex:tool-registry-dispatch-trace-plan-dispatch-plan
      (CodexToolRegistryDispatchTracePlan
        $dispatch-plan
        $trace-state
        $end-event))
   $dispatch-plan)

(= (codex:tool-registry-dispatch-trace-plan-trace-state
      (CodexToolRegistryDispatchTracePlan
        $dispatch-plan
        $trace-state
        $end-event))
   $trace-state)

(= (codex:tool-registry-dispatch-trace-plan-start-event
      (CodexToolRegistryDispatchTracePlan
        $dispatch-plan
        $trace-state
        $end-event))
   (codex:tool-registry-dispatch-trace-state-start-event $trace-state))

(= (codex:tool-registry-dispatch-trace-plan-end-event
      (CodexToolRegistryDispatchTracePlan
        $dispatch-plan
        $trace-state
        $end-event))
   $end-event)

(= (codex:tool-registry-dispatch-any-trace-plan
      $thread-id
      $codex-turn-id
      $registry
      $invocation)
   (let $trace-state
     (codex:tool-registry-dispatch-trace-start
       $thread-id
       $codex-turn-id
       $invocation)
     (let $dispatch-plan
       (codex:tool-registry-dispatch-any-plan
         $registry
         $invocation)
       (case $dispatch-plan
         (((CodexToolRegistryDispatchPlanReady
             $ready-invocation
             $binding)
           (codex:tool-registry-dispatch-trace-plan
             $dispatch-plan
             $trace-state
             CodexAbsent))
          ((CodexToolRegistryDispatchPlanError $error)
           (codex:tool-registry-dispatch-trace-plan
             $dispatch-plan
             $trace-state
             (codex:tool-registry-dispatch-trace-record-failed
               $trace-state
               $error))))))))
