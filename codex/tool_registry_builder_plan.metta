; Rust-faithful ToolRegistryBuilder planning slice.
;
; This ports deterministic builder behavior from:
; - openai-codex/codex-rs/core/src/tools/spec.rs
; - openai-codex/codex-rs/core/src/tools/registry.rs
;
; Covered in this increment:
; - ToolRegistryBuilder::new
; - push_spec / push_spec_with_parallel_support
; - register_handler binding shape for the currently ported handler kinds
; - build_specs_with_discoverable_tools' transfer of ToolRegistryPlan specs and
;   handlers into a builder/registry-shaped value
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust stores Arc<dyn AnyToolHandler> values in a HashMap. This pure CeTTa
;   planning layer stores registered handler bindings as ToolName/kind pairs
;   until the async handler trait-object runtime is ported.
; - Rust HashMap iteration order is intentionally unspecified. The CeTTa plan
;   preserves registration order only so surface tests can inspect the planned
;   state deterministically. The currently ported ToolRegistryPlan path does
;   not emit duplicate handler names; duplicate overwrite warnings from
;   register_handler are not represented until CeTTa has a map helper for this
;   registry layer.
; - Runtime handler `kind()` is represented as the string used by the currently
;   ported function-tool handlers. MCP handler runtime kinds will need an
;   explicit branch when the MCP registry path is ported.

!(import! &self dynamic_tool_handler)
!(import! &self json)
!(import! &self list)
!(import! &self tool_registry_plan)

(= (codex:tool-registry-handler-binding $name $kind)
   (CodexToolRegistryHandlerBinding $name $kind))

(= (codex:tool-registry-builder-plan $specs $handler-bindings)
   (CodexToolRegistryBuilderPlan $specs $handler-bindings))

(= (codex:tool-registry $handler-bindings)
   (CodexToolRegistry $handler-bindings))

(= (codex:tool-registry-builder-build-result $specs $registry)
   (CodexToolRegistryBuilderBuildResult $specs $registry))

(= (codex:tool-registry-builder-plan-empty)
   (codex:tool-registry-builder-plan () ()))

(= (codex:tool-registry-handler-binding-name
      (CodexToolRegistryHandlerBinding $name $kind))
   $name)

(= (codex:tool-registry-handler-binding-kind
      (CodexToolRegistryHandlerBinding $name $kind))
   $kind)

(= (codex:tool-registry-handler-binding-display-name
      (CodexToolRegistryHandlerBinding $name $kind))
   (codex:tool-handler-name-display $name))

(= (codex:tool-registry-handler-binding-pair
      (CodexToolRegistryHandlerBinding $name $kind))
   ($name $kind))

(= (codex:tool-registry-handler-binding-pair-json
      (CodexToolRegistryHandlerBinding $name $kind))
   (JsonArray
     ((JsonString (codex:tool-handler-name-display $name))
      (JsonString $kind))))

(= (codex:tool-registry-builder-handler-kind-runtime-kind $kind)
   (if (== $kind (codex:tool-handler-kind-dynamic-tool))
       (codex:dynamic-tool-handler-kind)
       "function"))

(= (codex:tool-registry-handler-binding-runtime-kind
      (CodexToolRegistryHandlerBinding $name $kind))
   (codex:tool-registry-builder-handler-kind-runtime-kind $kind))

(= (codex:tool-registry-builder-plan-specs $builder)
   (unique (case (once (eval $builder))
     (((CodexToolRegistryBuilderPlan $specs $handler-bindings)
       $specs)))))

(= (codex:tool-registry-builder-plan-handler-bindings $builder)
   (unique (case (once (eval $builder))
     (((CodexToolRegistryBuilderPlan $specs $handler-bindings)
       $handler-bindings)))))

(= (codex:tool-registry-builder-build-result-specs
      (CodexToolRegistryBuilderBuildResult $specs $registry))
   $specs)

(= (codex:tool-registry-builder-build-result-registry
      (CodexToolRegistryBuilderBuildResult $specs $registry))
   $registry)

(= (codex:tool-registry-builder-plan-push-spec-with-parallel-support
      (CodexToolRegistryBuilderPlan $specs $handler-bindings)
      $spec
      $supports-parallel-tool-calls)
   (codex:tool-registry-builder-plan
     (list:reverse
       (cons-atom
         (codex:configured-tool-spec $spec $supports-parallel-tool-calls)
         (list:reverse $specs)))
     $handler-bindings))

(= (codex:tool-registry-builder-plan-push-spec $builder $spec)
   (codex:tool-registry-builder-plan-push-spec-with-parallel-support
     $builder
     $spec
     False))

(= (codex:tool-registry-builder-plan-register-handler
      (CodexToolRegistryBuilderPlan $specs $handler-bindings)
      $name
      $kind)
   (let $new-binding
     (CodexToolRegistryHandlerBinding $name $kind)
     (codex:tool-registry-builder-plan
       $specs
       (list:reverse
         (cons-atom $new-binding (list:reverse $handler-bindings))))))

(= (codex:tool-registry-handler-binding-from-handler-spec
      (CodexToolHandlerSpec $name $kind))
   (codex:tool-registry-handler-binding $name $kind))

(= (codex:tool-registry-handler-bindings-from-handler-specs $handlers)
   (map-atom-strict
     $handlers
     $handler
     (codex:tool-registry-handler-binding-from-handler-spec $handler)))

(= (codex:tool-registry-builder-plan-from-registry-plan $plan)
   (case (once (eval $plan))
     (((CodexToolRegistryPlan $specs $handlers)
       (codex:tool-registry-builder-plan
         $specs
         (codex:tool-registry-handler-bindings-from-handler-specs
           $handlers))))))

(= (codex:build-tool-registry-builder-plan-with-dynamic-tools
      $config
      $dynamic-tools)
   (codex:tool-registry-builder-plan-from-registry-plan
     (codex:build-tool-registry-plan-with-dynamic-tools
       $config
       $dynamic-tools)))

(= (codex:build-tool-registry-builder-plan $config)
   (codex:build-tool-registry-builder-plan-with-dynamic-tools $config ()))

(= (codex:tool-registry-builder-plan-build
      (CodexToolRegistryBuilderPlan $specs $handler-bindings))
   (codex:tool-registry-builder-build-result
     $specs
     (codex:tool-registry $handler-bindings)))

(= (codex:tool-registry-handler-binding-display-names $handler-bindings)
   (map-atom-strict
     $handler-bindings
     $binding
     (codex:tool-registry-handler-binding-display-name $binding)))

(= (codex:tool-registry-handler-binding-pairs $handler-bindings)
   (map-atom-strict
     $handler-bindings
     $binding
     (codex:tool-registry-handler-binding-pair $binding)))

(= (codex:tool-registry-handler-binding-pairs-json $handler-bindings)
   (JsonArray
     (map-atom-strict
       $handler-bindings
       $binding
       (codex:tool-registry-handler-binding-pair-json $binding))))

(= (codex:tool-registry-handler-binding-runtime-kinds $handler-bindings)
   (map-atom-strict
     $handler-bindings
     $binding
     (codex:tool-registry-handler-binding-runtime-kind $binding)))

(= (codex:tool-registry-builder-plan-spec-names $builder)
   (codex:configured-tool-spec-names
     (codex:tool-registry-builder-plan-specs $builder)))

(= (codex:tool-registry-builder-plan-spec-parallel-flags $builder)
   (codex:configured-tool-spec-parallel-flags
     (codex:tool-registry-builder-plan-specs $builder)))

(= (codex:tool-registry-builder-plan-handler-display-names $builder)
   (codex:tool-registry-handler-binding-display-names
     (codex:tool-registry-builder-plan-handler-bindings $builder)))

(= (codex:tool-registry-builder-plan-handler-pairs $builder)
   (codex:tool-registry-handler-binding-pairs
     (codex:tool-registry-builder-plan-handler-bindings $builder)))

(= (codex:tool-registry-builder-plan-handler-pairs-json $builder)
   (codex:tool-registry-handler-binding-pairs-json
     (codex:tool-registry-builder-plan-handler-bindings $builder)))

(= (codex:tool-registry-builder-plan-handler-runtime-kinds $builder)
   (codex:tool-registry-handler-binding-runtime-kinds
     (codex:tool-registry-builder-plan-handler-bindings $builder)))

(= (codex:find-tool-registry-handler-binding-by-display-name
      ()
      $display-name)
   Empty)

(= (codex:find-tool-registry-handler-binding-by-display-name
      $handler-bindings
      $display-name)
   (unique
     (let ($head $tail) (decons-atom $handler-bindings)
       (if (==
             (codex:tool-registry-handler-binding-display-name $head)
             $display-name)
           $head
           (codex:find-tool-registry-handler-binding-by-display-name
             $tail
             $display-name)))))
