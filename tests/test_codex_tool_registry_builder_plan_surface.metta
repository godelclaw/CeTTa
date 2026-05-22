!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:dynamic_tools)
!(import! &self codex:tool_config)
!(import! &self codex:tool_registry_builder_plan)
!(import! &self codex:tool_registry_plan)

(= (codex-tool-registry-builder-model)
   (codex:tool-config-model-info
     (codex:config-shell-tool-type-unified-exec)
     CodexAbsent
     ()
     False))

(= (codex-tool-registry-builder-features)
   (codex:tool-config-features
     True
     True
     False
     True
     False
     False
     False))

(= (codex-tool-registry-builder-config)
   (codex:tools-config-new
     (codex:tools-config-new-params
       (codex-tool-registry-builder-model)
       (codex-tool-registry-builder-features)
       False
       (codex:tool-config-sandbox-policy-danger-full-access)
       (codex:windows-sandbox-level-disabled))))

(= (codex-tool-registry-builder-order-schema)
   (JsonObject
     ((JsonPair "type" (JsonString "object"))
      (JsonPair
        "properties"
        (JsonObject
          ((JsonPair
             "order_id"
             (JsonObject
               ((JsonPair "type" (JsonString "string"))))))))
      (JsonPair
        "required"
        (JsonArray ((JsonString "order_id"))))
      (JsonPair "additionalProperties" (JsonBool False)))))

(= (codex-tool-registry-builder-dynamic-tools)
   ((codex:dynamic-tool-spec
      "tickets"
      "lookup_order"
      "Look up an order"
      (codex-tool-registry-builder-order-schema)
      True)
    (codex:dynamic-tool-spec
      CodexAbsent
      "run_sql"
      "Query database"
      (codex:json-schema-object ())
      False)
    (codex:dynamic-tool-spec
      "tickets"
      "create_order"
      "Create an order"
      (codex:json-schema-object ())
      False)))

(= (codex-tool-registry-builder-plan)
   (codex:build-tool-registry-builder-plan-with-dynamic-tools
     (codex-tool-registry-builder-config)
     (codex-tool-registry-builder-dynamic-tools)))

(= (codex-tool-registry-builder-manual-plan)
   (codex:tool-registry-builder-plan-register-handler
     (codex:tool-registry-builder-plan-push-spec-with-parallel-support
       (codex:tool-registry-builder-plan-empty)
       (codex:create-update-plan-tool)
       True)
     "update_plan"
     (codex:tool-handler-kind-plan)))

!(assertEqualToResult
  (unique
    (codex:tool-registry-builder-plan-spec-names
      (codex-tool-registry-builder-manual-plan)))
  (("update_plan")))

!(assertEqualToResult
  (unique
    (codex:tool-registry-builder-plan-spec-parallel-flags
      (codex-tool-registry-builder-manual-plan)))
  ((True)))

!(assertEqualToResult
  (unique
    (json-stringify
      (codex:tool-registry-builder-plan-handler-pairs-json
        (codex-tool-registry-builder-manual-plan))))
  ("[[\"update_plan\",\"Plan\"]]"))

!(assertEqualToResult
  (unique
    (codex:string-list-contains
      (codex:tool-registry-builder-plan-spec-names
        (codex-tool-registry-builder-plan))
      "tickets"))
  (True))

!(assertEqualToResult
  (unique
    (codex:string-list-contains
      (codex:tool-registry-builder-plan-spec-names
        (codex-tool-registry-builder-plan))
      "run_sql"))
  (True))

!(assertEqualToResult
  (unique
    (codex:configured-tool-spec-supports-parallel-tool-calls
      (codex:find-configured-tool-spec-by-name
        (codex:tool-registry-builder-plan-specs
          (codex-tool-registry-builder-plan))
        "tickets")))
  (False))

!(assertEqualToResult
  (unique
    (codex:tool-registry-handler-binding-kind
      (codex:find-tool-registry-handler-binding-by-display-name
        (codex:tool-registry-builder-plan-handler-bindings
          (codex-tool-registry-builder-plan))
        "ticketslookup_order")))
  ("DynamicTool"))

!(assertEqualToResult
  (unique
    (codex:tool-registry-handler-binding-kind
      (codex:find-tool-registry-handler-binding-by-display-name
        (codex:tool-registry-builder-plan-handler-bindings
          (codex-tool-registry-builder-plan))
        "ticketscreate_order")))
  ("DynamicTool"))

!(assertEqualToResult
  (unique
    (codex:tool-registry-handler-binding-kind
      (codex:find-tool-registry-handler-binding-by-display-name
        (codex:tool-registry-builder-plan-handler-bindings
          (codex-tool-registry-builder-plan))
        "run_sql")))
  ("DynamicTool"))

!(assertEqualToResult
  (unique
    (codex:tool-registry-handler-binding-runtime-kind
      (codex:find-tool-registry-handler-binding-by-display-name
        (codex:tool-registry-builder-plan-handler-bindings
          (codex-tool-registry-builder-plan))
        "ticketslookup_order")))
  ("function"))

!(assertEqualToResult
  (unique
    (json-stringify
      (codex:tool-registry-builder-plan-handler-pairs-json
        (codex-tool-registry-builder-plan))))
  ("[[\"exec_command\",\"UnifiedExec\"],[\"write_stdin\",\"UnifiedExec\"],[\"update_plan\",\"Plan\"],[\"request_user_input\",\"RequestUserInput\"],[\"apply_patch\",\"ApplyPatch\"],[\"view_image\",\"ViewImage\"],[\"ticketslookup_order\",\"DynamicTool\"],[\"run_sql\",\"DynamicTool\"],[\"ticketscreate_order\",\"DynamicTool\"]]"))

!(assertEqualToResult
  (unique
    (codex:tool-registry-builder-build-result-registry
      (codex:tool-registry-builder-plan-build
        (codex-tool-registry-builder-plan))))
  ((CodexToolRegistry
     ((CodexToolRegistryHandlerBinding "exec_command" "UnifiedExec")
      (CodexToolRegistryHandlerBinding "write_stdin" "UnifiedExec")
      (CodexToolRegistryHandlerBinding "update_plan" "Plan")
      (CodexToolRegistryHandlerBinding "request_user_input" "RequestUserInput")
      (CodexToolRegistryHandlerBinding "apply_patch" "ApplyPatch")
      (CodexToolRegistryHandlerBinding "view_image" "ViewImage")
      (CodexToolRegistryHandlerBinding
        (CodexToolName "lookup_order" "tickets")
        "DynamicTool")
      (CodexToolRegistryHandlerBinding
        (CodexToolName "run_sql" CodexAbsent)
        "DynamicTool")
      (CodexToolRegistryHandlerBinding
        (CodexToolName "create_order" "tickets")
        "DynamicTool")))))
