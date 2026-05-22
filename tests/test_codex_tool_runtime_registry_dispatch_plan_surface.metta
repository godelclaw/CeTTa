!(register-module! ../codex)
!(import! &self codex:tool_registry_builder_plan)
!(import! &self codex:tool_router_dispatch_plan)
!(import! &self codex:tool_router_runtime_access_plan)
!(import! &self codex:tool_runtime_registry_dispatch_plan)

(= (test:tool-runtime-registry-router $js-repl-tools-only)
   (codex:tool-router-dispatch-router
     ((codex:tool-router-dispatch-function-configured-spec
        "exec_command"
        True)
      (codex:tool-router-dispatch-freeform-configured-spec
        "apply_patch"
        True)
      (codex:tool-router-dispatch-function-configured-spec
        "serial_tool"
        False))
     ()
     $js-repl-tools-only))

(= (test:tool-runtime-registry-runtime $js-repl-tools-only)
   (codex:tool-call-runtime
     (test:tool-runtime-registry-router $js-repl-tools-only)
     test-session
     test-turn-context
     test-tracker))

(= (test:tool-runtime-registry-registry)
   (codex:tool-registry
     ((codex:tool-registry-handler-binding
        "exec_command"
        (codex:tool-handler-kind-unified-exec))
      (codex:tool-registry-handler-binding
        "apply_patch"
        (codex:tool-handler-kind-apply-patch)))))

(= (test:tool-runtime-registry-access $js-repl-tools-only)
   (codex:tool-call-runtime-access
     (test:tool-runtime-registry-runtime $js-repl-tools-only)
     (test:tool-runtime-registry-registry)))

(= (test:tool-runtime-registry-function-call $name $call-id)
   (codex:tool-router-dispatch-tool-call
     (codex:plain-tool-name $name)
     $call-id
     (codex:tool-router-dispatch-function-payload "{\"x\":1}")))

(= (test:tool-runtime-registry-custom-call $name $call-id)
   (codex:tool-router-dispatch-tool-call
     (codex:plain-tool-name $name)
     $call-id
     (codex:tool-router-dispatch-custom-payload "*** Begin Patch\n*** End Patch\n")))

(= (test:tool-runtime-registry-plan $js-repl-tools-only $call)
   (codex:tool-call-runtime-registry-dispatch-plan
     (test:tool-runtime-registry-access $js-repl-tools-only)
     $call
     (codex:tool-router-dispatch-source-direct)
     test-cancellation-token))

!(assertEqualToResult
  (codex:tool-call-runtime-dispatch-plan-lock-mode
    (codex:tool-call-runtime-registry-dispatch-runtime-plan
      (test:tool-runtime-registry-plan
        False
        (test:tool-runtime-registry-function-call
          "exec_command"
          "call-ready"))))
  (CodexToolCallRuntimeLockRead))

!(assertEqualToResult
  (codex:tool-registry-handler-binding-kind
    (codex:tool-registry-dispatch-plan-ready-binding
      (codex:tool-call-runtime-registry-dispatch-ready-plan
        (test:tool-runtime-registry-plan
          False
          (test:tool-runtime-registry-function-call
            "exec_command"
            "call-ready")))))
  ("UnifiedExec"))

!(assertEqualToResult
  (codex:tool-registry-handler-binding-kind
    (codex:tool-registry-dispatch-plan-ready-binding
      (codex:tool-call-runtime-registry-dispatch-ready-plan
        (test:tool-runtime-registry-plan
          False
          (test:tool-runtime-registry-custom-call
            "apply_patch"
            "call-patch")))))
  ("ApplyPatch"))

!(assertEqualToResult
  (codex:tool-call-runtime-dispatch-plan-lock-mode
    (codex:tool-call-runtime-registry-dispatch-runtime-plan
      (test:tool-runtime-registry-plan
        False
        (test:tool-runtime-registry-function-call
          "serial_tool"
          "call-missing"))))
  (CodexToolCallRuntimeLockWrite))

!(assertEqualToResult
  (codex:tool-call-runtime-registry-dispatch-error-value
    (test:tool-runtime-registry-plan
      False
      (test:tool-runtime-registry-function-call
        "serial_tool"
        "call-missing")))
  ((CodexFunctionCallErrorRespondToModel
     "unsupported call: serial_tool")))

!(assertEqualToResult
  (codex:tool-call-runtime-registry-dispatch-error-value
    (test:tool-runtime-registry-plan
      False
      (test:tool-runtime-registry-custom-call
        "exec_command"
        "call-bad-payload")))
  ((CodexFunctionCallErrorFatal
     "tool exec_command invoked with incompatible payload")))

!(assertEqualToResult
  (codex:tool-call-runtime-registry-dispatch-error-value
    (test:tool-runtime-registry-plan
      True
      (test:tool-runtime-registry-function-call
        "exec_command"
        "call-direct-disabled")))
  ((CodexFunctionCallErrorRespondToModel
     "direct tool calls are disabled; use js_repl and codex.tool(...) instead")))
