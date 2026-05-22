!(register-module! ../codex)
!(import! &self codex:tool_registry_builder_plan)
!(import! &self codex:tool_registry_dispatch_plan)
!(import! &self codex:tool_router_dispatch_plan)

(= (test:tool-registry-dispatch-registry)
   (codex:tool-registry
     ((codex:tool-registry-handler-binding
        "exec_command"
        (codex:tool-handler-kind-unified-exec))
      (codex:tool-registry-handler-binding
        "apply_patch"
        (codex:tool-handler-kind-apply-patch))
      (codex:tool-registry-handler-binding
        (codex:namespaced-tool-name "tickets" "lookup_order")
        (codex:tool-handler-kind-dynamic-tool)))))

(= (test:tool-registry-dispatch-invocation $tool-name $payload)
   (codex:tool-router-tool-invocation
     test-session
     test-turn
     test-cancellation-token
     test-tracker
     "call-1"
     $tool-name
     (codex:tool-router-dispatch-source-direct)
     $payload))

(= (test:tool-registry-dispatch-plan $tool-name $payload)
   (codex:tool-registry-dispatch-any-plan
     (test:tool-registry-dispatch-registry)
     (test:tool-registry-dispatch-invocation $tool-name $payload)))

!(assertEqualToResult
  (unique
    (codex:tool-registry-handler-binding-kind
      (codex:tool-registry-dispatch-plan-ready-binding
        (test:tool-registry-dispatch-plan
          (codex:plain-tool-name "exec_command")
          (codex:tool-router-dispatch-function-payload "{\"cmd\":\"pwd\"}")))))
  ("UnifiedExec"))

!(assertEqualToResult
  (unique
    (codex:tool-registry-dispatch-plan-error-value
      (test:tool-registry-dispatch-plan
        (codex:plain-tool-name "exec_command")
        (codex:tool-router-dispatch-custom-payload "pwd"))))
  ((CodexFunctionCallErrorFatal
     "tool exec_command invoked with incompatible payload")))

!(assertEqualToResult
  (unique
    (codex:tool-registry-handler-binding-kind
      (codex:tool-registry-dispatch-plan-ready-binding
        (test:tool-registry-dispatch-plan
          (codex:plain-tool-name "apply_patch")
          (codex:tool-router-dispatch-custom-payload "*** Begin Patch")))))
  ("ApplyPatch"))

!(assertEqualToResult
  (unique
    (codex:tool-registry-handler-binding-kind
      (codex:tool-registry-dispatch-plan-ready-binding
        (test:tool-registry-dispatch-plan
          (codex:namespaced-tool-name "tickets" "lookup_order")
          (codex:tool-router-dispatch-function-payload
            "{\"order_id\":\"A-1\"}")))))
  ("DynamicTool"))

!(assertEqualToResult
  (unique
    (codex:tool-registry-handler-binding-kind
      (codex:tool-registry-dispatch-plan-ready-binding
        (test:tool-registry-dispatch-plan
          (codex:namespaced-tool-name "tickets" "lookup_order")
          (codex:tool-router-dispatch-tool-search-payload "A-1" 3)))))
  ("DynamicTool"))

!(assertEqualToResult
  (unique
    (codex:tool-registry-dispatch-plan-error-value
      (test:tool-registry-dispatch-plan
        (codex:namespaced-tool-name "tickets" "lookup_order")
        (codex:tool-router-dispatch-custom-payload "{\"order_id\":\"A-1\"}"))))
  ((CodexFunctionCallErrorFatal
     "tool ticketslookup_order invoked with incompatible payload")))

!(assertEqualToResult
  (unique
    (codex:tool-registry-dispatch-plan-error-value
      (test:tool-registry-dispatch-plan
        (codex:plain-tool-name "missing")
        (codex:tool-router-dispatch-function-payload "{}"))))
  ((CodexFunctionCallErrorRespondToModel "unsupported call: missing")))

!(assertEqualToResult
  (unique
    (codex:tool-registry-dispatch-plan-error-value
      (test:tool-registry-dispatch-plan
        (codex:namespaced-tool-name "tickets" "missing_order")
        (codex:tool-router-dispatch-custom-payload "{}"))))
  ((CodexFunctionCallErrorRespondToModel
     "unsupported custom tool call: ticketsmissing_order")))
