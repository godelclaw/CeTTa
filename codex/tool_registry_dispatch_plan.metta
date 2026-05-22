; Rust-faithful ToolRegistry dispatch planning slice.
;
; This ports the deterministic front of:
; - openai-codex/codex-rs/core/src/tools/registry.rs
;   - ToolRegistry::dispatch_any handler lookup
;   - unsupported_tool_call_message
;   - ToolHandler::matches_kind checks before async hooks/handler execution
;
; Covered in this increment:
; - lookup of the registered handler binding for a ToolInvocation
; - Rust-compatible unsupported-call and incompatible-payload errors
; - matches_kind behavior for the currently ported handler kinds
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust stores `Arc<dyn AnyToolHandler>` values keyed by `ToolName`. The
;   current CeTTa builder plan stores plain built-in handler names as strings
;   and dynamic handler names as `ToolName` records. The lookup below treats a
;   string binding as exactly the same absent-namespace `ToolName`, but does
;   not collapse namespaced `ToolName` values to display strings.
; - Rust continues from this point into async tracing, hooks, mutation gates,
;   and handler execution. This pure planning slice stops after the same
;   pre-dispatch errors Rust can return before those async steps.
; - The recursive binding scan materializes the current list and match boolean
;   with `once (eval ...)` because delayed list-tail arguments can otherwise
;   lose their result in the current CeTTa evaluator. This preserves Rust's
;   first matching handler-key behavior.

!(import! &self function_tool)
!(import! &self list)
!(import! &self str)
!(import! &self tool_name)
!(import! &self tool_registry_builder_plan)
!(import! &self tool_registry_plan)
!(import! &self tool_router_dispatch_plan)

(= (codex:tool-registry-dispatch-plan-ready $invocation $binding)
   (CodexToolRegistryDispatchPlanReady $invocation $binding))

(= (codex:tool-registry-dispatch-plan-error $error)
   (CodexToolRegistryDispatchPlanError $error))

(= (codex:tool-registry-dispatch-plan-ready-invocation
      (CodexToolRegistryDispatchPlanReady $invocation $binding))
   $invocation)

(= (codex:tool-registry-dispatch-plan-ready-binding
      (CodexToolRegistryDispatchPlanReady $invocation $binding))
   $binding)

(= (codex:tool-registry-dispatch-plan-error-value
      (CodexToolRegistryDispatchPlanError $error))
   $error)

(= (codex:tool-registry-dispatch-plan-registry-bindings
      (CodexToolRegistry $handler-bindings))
   $handler-bindings)

(= (codex:tool-registry-handler-name-matches-tool-name
      $handler-name
      $tool-name)
   (case $handler-name
     (((CodexToolName $handler-tool-name $handler-namespace)
       (== $handler-name $tool-name))
      ($plain-handler-name
       (case $tool-name
         (((CodexToolName $plain-name CodexAbsent)
           (== $plain-handler-name $plain-name))
          ((CodexToolName $plain-name $namespace)
           False)))))))

(= (codex:tool-registry-find-handler-binding-from
      $handler-bindings
      $tool-name)
   (let $bindings (once (eval $handler-bindings))
     (if (list:empty? $bindings)
         Empty
         (let $head (list:first $bindings)
           (let $tail (list:rest $bindings)
             (let $matches
               (once (eval
                 (codex:tool-registry-handler-name-matches-tool-name
                   (codex:tool-registry-handler-binding-name $head)
                   $tool-name)))
               (if $matches
                   $head
                   (codex:tool-registry-find-handler-binding-from
                     $tail
                     $tool-name))))))))

(= (codex:tool-registry-find-handler-binding
      $registry
      $tool-name)
   (case (once (eval $registry))
     (((CodexToolRegistry $handler-bindings)
       (codex:tool-registry-find-handler-binding-from
         $handler-bindings
         $tool-name)))))

(= (codex:tool-registry-payload-kind $payload)
   (case $payload
     (((CodexToolPayloadFunction $arguments)
       CodexToolRegistryPayloadKindFunction)
      ((CodexToolPayloadCustom $input)
       CodexToolRegistryPayloadKindCustom)
      ((CodexToolPayloadToolSearch $query $limit)
       CodexToolRegistryPayloadKindToolSearch)
      ((CodexToolPayloadLocalShell $command)
       CodexToolRegistryPayloadKindLocalShell)
      ((CodexToolPayloadLocalShellParams
          $command
          $workdir
          $timeout-ms
          $sandbox-permissions
          $prefix-rule
          $additional-permissions
          $justification)
       CodexToolRegistryPayloadKindLocalShell)
      ((CodexToolPayloadMcp $server $tool $raw-arguments)
       CodexToolRegistryPayloadKindMcp)
      ($other
       CodexToolRegistryPayloadKindUnknown))))

(= (codex:tool-registry-payload-is-function $payload)
   (== (codex:tool-registry-payload-kind $payload)
       CodexToolRegistryPayloadKindFunction))

(= (codex:tool-registry-payload-is-custom $payload)
   (== (codex:tool-registry-payload-kind $payload)
       CodexToolRegistryPayloadKindCustom))

(= (codex:tool-registry-payload-is-tool-search $payload)
   (== (codex:tool-registry-payload-kind $payload)
       CodexToolRegistryPayloadKindToolSearch))

(= (codex:tool-registry-payload-is-mcp $payload)
   (== (codex:tool-registry-payload-kind $payload)
       CodexToolRegistryPayloadKindMcp))

(= (codex:tool-registry-default-function-handler-matches-payload $payload)
   (or (codex:tool-registry-payload-is-function $payload)
       (codex:tool-registry-payload-is-tool-search $payload)))

(= (codex:tool-registry-function-only-handler-matches-payload $payload)
   (codex:tool-registry-payload-is-function $payload))

(= (codex:tool-registry-custom-function-handler-matches-payload $payload)
   (or (codex:tool-registry-payload-is-function $payload)
       (codex:tool-registry-payload-is-custom $payload)))

(= (codex:tool-registry-mcp-handler-matches-payload $payload)
   (codex:tool-registry-payload-is-mcp $payload))

(= (codex:tool-registry-default-function-handler-kind $kind)
   (or (== $kind (codex:tool-handler-kind-plan))
       (or (== $kind (codex:tool-handler-kind-request-user-input))
           (or (== $kind (codex:tool-handler-kind-request-permissions))
               (or (== $kind (codex:tool-handler-kind-list-dir))
                   (or (== $kind (codex:tool-handler-kind-view-image))
                       (or (== $kind (codex:tool-handler-kind-js-repl-reset))
                           (== $kind
                               (codex:tool-handler-kind-dynamic-tool)))))))))

(= (codex:tool-registry-handler-kind-matches-payload $kind $payload)
   (if (== $kind (codex:tool-handler-kind-unified-exec))
       (codex:tool-registry-function-only-handler-matches-payload $payload)
       (if (== $kind (codex:tool-handler-kind-apply-patch))
           (codex:tool-registry-custom-function-handler-matches-payload $payload)
           (if (== $kind (codex:tool-handler-kind-js-repl))
               (codex:tool-registry-custom-function-handler-matches-payload
                 $payload)
               (if (codex:tool-registry-default-function-handler-kind $kind)
                   (codex:tool-registry-default-function-handler-matches-payload
                     $payload)
                   False)))))

(= (codex:tool-registry-handler-binding-matches-payload
      (CodexToolRegistryHandlerBinding $name $kind)
      $payload)
   (codex:tool-registry-handler-kind-matches-payload $kind $payload))

(= (codex:tool-registry-unsupported-tool-call-message $payload $tool-name)
   (if (codex:tool-registry-payload-is-custom $payload)
       (str-concat
         "unsupported custom tool call: "
         (codex:tool-name-display $tool-name))
       (str-concat
         "unsupported call: "
         (codex:tool-name-display $tool-name))))

(= (codex:tool-registry-incompatible-payload-message $tool-name)
   (str-concat
     "tool "
     (str-concat
       (codex:tool-name-display $tool-name)
       " invoked with incompatible payload")))

(= (codex:tool-registry-dispatch-any-plan $registry $invocation)
   (let $tool-name
     (codex:tool-router-tool-invocation-tool-name $invocation)
     (let $payload
       (codex:tool-router-tool-invocation-payload $invocation)
       (case (codex:tool-registry-find-handler-binding $registry $tool-name)
         ((Empty
           (codex:tool-registry-dispatch-plan-error
             (codex:function-call-error-respond-to-model
               (codex:tool-registry-unsupported-tool-call-message
                 $payload
                 $tool-name))))
          ($binding
           (if (codex:tool-registry-handler-binding-matches-payload
                 $binding
                 $payload)
               (codex:tool-registry-dispatch-plan-ready
                 $invocation
                 $binding)
               (codex:tool-registry-dispatch-plan-error
                 (codex:function-call-error-fatal
                   (codex:tool-registry-incompatible-payload-message
                     $tool-name))))))))))
