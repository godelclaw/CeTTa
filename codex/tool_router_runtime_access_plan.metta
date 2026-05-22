; Rust-faithful ToolRouter/ToolCallRuntime access planning slice.
;
; This ports deterministic delegation from:
; - openai-codex/codex-rs/core/src/tools/router.rs
;   - ToolRouter::find_spec
;   - ToolRouter::create_diff_consumer
; - openai-codex/codex-rs/core/src/tools/parallel.rs
;   - ToolCallRuntime::find_spec
;   - ToolCallRuntime::create_diff_consumer
;
; Covered in this increment:
; - router find_spec delegation to the already ported configured-spec search
; - router create_diff_consumer delegation to the already ported registry
; - runtime forwarding of both helper calls through its router/registry view
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust `ToolRouter` owns its `ToolRegistry`, and `ToolCallRuntime` owns an
;   `Arc<ToolRouter>`. The existing CeTTa router planning records split
;   dispatch-router data and registry data into separate pure values. This
;   slice carries them side by side until the full `ToolRouter::from_config`
;   object is ported as one value.

!(import! &self tool_registry_builder_plan)
!(import! &self tool_registry_diff_consumer_plan)
!(import! &self tool_router_dispatch_plan)
!(import! &self tool_router_specs_plan)
!(import! &self tool_runtime_parallel_plan)

(= (codex:tool-router-runtime-access-router
      $dispatch-router
      $registry)
   (CodexToolRouterRuntimeAccessRouter $dispatch-router $registry))

(= (codex:tool-router-runtime-access-router-dispatch-router
      (CodexToolRouterRuntimeAccessRouter $dispatch-router $registry))
   $dispatch-router)

(= (codex:tool-router-runtime-access-router-registry
      (CodexToolRouterRuntimeAccessRouter $dispatch-router $registry))
   $registry)

(= (codex:tool-router-runtime-access-find-spec
      (CodexToolRouterRuntimeAccessRouter $dispatch-router $registry)
      $tool-name)
   (codex:tool-router-find-spec-from-configured
     (codex:tool-router-configured-specs $dispatch-router)
     $tool-name))

(= (codex:tool-router-runtime-access-create-diff-consumer
      (CodexToolRouterRuntimeAccessRouter $dispatch-router $registry)
      $tool-name)
   (codex:tool-registry-create-diff-consumer $registry $tool-name))

(= (codex:tool-call-runtime-access
      $runtime
      $registry)
   (CodexToolCallRuntimeAccess $runtime $registry))

(= (codex:tool-call-runtime-access-runtime
      (CodexToolCallRuntimeAccess $runtime $registry))
   $runtime)

(= (codex:tool-call-runtime-access-registry
      (CodexToolCallRuntimeAccess $runtime $registry))
   $registry)

(= (codex:tool-call-runtime-access-router
      (CodexToolCallRuntimeAccess $runtime $registry))
   (codex:tool-router-runtime-access-router
     (codex:tool-call-runtime-router $runtime)
     $registry))

(= (codex:tool-call-runtime-access-find-spec
      $runtime-access
      $tool-name)
   (codex:tool-router-runtime-access-find-spec
     (codex:tool-call-runtime-access-router $runtime-access)
     $tool-name))

(= (codex:tool-call-runtime-access-create-diff-consumer
      $runtime-access
      $tool-name)
   (codex:tool-router-runtime-access-create-diff-consumer
     (codex:tool-call-runtime-access-router $runtime-access)
     $tool-name))
