; Narrow Rust-faithful tool-registry-plan slice for the restarted Codex port.
;
; This ports the current executable-tool subset from:
; - openai-codex/codex-rs/tools/src/{tool_spec.rs,tool_registry_plan.rs}
; - openai-codex/codex-rs/tools/src/{plan_tool.rs,request_user_input_tool.rs}
; - openai-codex/codex-rs/tools/src/{local_tool.rs,apply_patch_tool.rs}
;
; Covered in this increment:
; - ToolSpec / ConfiguredToolSpec / ToolHandlerSpec / ToolRegistryPlan values
; - Responses API JSON projection for function/custom/namespace tool specs
; - Rust-shaped tool specs for exec_command, write_stdin, update_plan,
;   request_user_input, request_permissions, list_dir, view_image, and
;   js_repl, js_repl_reset, tool_search, and freeform apply_patch
; - the matching narrow build_tool_registry_plan order/handler wiring for the
;   currently ported CeTTa runtime surface
;
; Required slice-local deviations from Rust, documented for later audit:
; - The restarted CeTTa port does not yet have the full Rust tool registry,
;   code-mode augmentation, MCP/dynamic tool loading, web/image-generation
;   tools, or the agent-job/collaboration registry branches. This slice only
;   exposes the tools whose handlers already exist locally.
; - Function-tool `output_schema` is preserved on the internal CeTTa record,
;   but `tool-spec-json` omits it, matching Rust `ResponsesApiTool`
;   serialization to the Responses API.
; - Rust can choose JSON or freeform apply_patch depending on model/tool
;   config. The current visible CeTTa runtime only executes the freeform
;   surface, so this slice currently builds the freeform branch only.

!(import! &self json)
!(import! &self js_repl)
!(import! &self list)
!(import! &self list_dir)
!(import! &self request_permissions)
!(import! &self request_user_input)
!(import! &self tool_config)
!(import! &self update_plan)
!(import! &self view_image)

(= (codex:tool-handler-kind-unified-exec)
   "UnifiedExec")

(= (codex:tool-handler-kind-plan)
   "Plan")

(= (codex:tool-handler-kind-request-user-input)
   "RequestUserInput")

(= (codex:tool-handler-kind-request-permissions)
   "RequestPermissions")

(= (codex:tool-handler-kind-list-dir)
   "ListDir")

(= (codex:tool-handler-kind-view-image)
   "ViewImage")

(= (codex:tool-handler-kind-apply-patch)
   "ApplyPatch")

(= (codex:tool-handler-kind-js-repl)
   "JsRepl")

(= (codex:tool-handler-kind-js-repl-reset)
   "JsReplReset")

(= (codex:responses-api-tool
      $name
      $description
      $strict
      $defer-loading
      $parameters
      $output-schema)
   (CodexResponsesApiTool
     $name
     $description
     $strict
     $defer-loading
     $parameters
     $output-schema))

(= (codex:freeform-tool
      $name
      $description
      $format-type
      $format-syntax
      $format-definition)
   (CodexFreeformTool
     $name
     $description
     $format-type
     $format-syntax
     $format-definition))

(= (codex:responses-api-namespace
      $name
      $description
      $tools)
   (CodexResponsesApiNamespace
     $name
     $description
     $tools))

(= (codex:responses-api-namespace-tool-function $tool)
   (CodexResponsesApiNamespaceToolFunction $tool))

(= (codex:tool-spec-function $tool)
   (CodexToolSpecFunction $tool))

(= (codex:tool-spec-freeform $tool)
   (CodexToolSpecFreeform $tool))

(= (codex:tool-spec-namespace $namespace)
   (CodexToolSpecNamespace $namespace))

(= (codex:tool-spec-tool-search
      $execution
      $description
      $parameters)
   (CodexToolSpecToolSearch
     $execution
     $description
     $parameters))

(= (codex:loadable-tool-spec-function $tool)
   (CodexLoadableToolSpecFunction $tool))

(= (codex:loadable-tool-spec-namespace $namespace)
   (CodexLoadableToolSpecNamespace $namespace))

(= (codex:configured-tool-spec $spec $supports-parallel-tool-calls)
   (CodexConfiguredToolSpec $spec $supports-parallel-tool-calls))

(= (codex:tool-handler-spec $name $kind)
   (CodexToolHandlerSpec $name $kind))

(= (codex:tool-registry-plan $specs $handlers)
   (CodexToolRegistryPlan $specs $handlers))

(= (codex:tool-registry-plan-empty)
   (codex:tool-registry-plan () ()))

(= (codex:tool-spec-name
      (CodexToolSpecFunction
        (CodexResponsesApiTool
          $name
          $description
          $strict
          $defer-loading
          $parameters
          $output-schema)))
   $name)

(= (codex:tool-spec-name
      (CodexToolSpecFreeform
        (CodexFreeformTool
          $name
          $description
          $format-type
          $format-syntax
          $format-definition)))
   $name)

(= (codex:tool-spec-name
      (CodexToolSpecNamespace
        (CodexResponsesApiNamespace $name $description $tools)))
   $name)

(= (codex:tool-spec-name
      (CodexToolSpecToolSearch
        $execution
        $description
        $parameters))
   "tool_search")

(= (codex:tool-spec-name (CodexToolSpecToolSearch))
   "tool_search")

(= (codex:tool-spec-function-tool (CodexToolSpecFunction $tool))
   $tool)

(= (codex:tool-spec-freeform-tool (CodexToolSpecFreeform $tool))
   $tool)

(= (codex:tool-spec-namespace-namespace
      (CodexToolSpecNamespace $namespace))
   $namespace)

(= (codex:loadable-tool-spec-name
      (CodexLoadableToolSpecFunction
        (CodexResponsesApiTool
          $name
          $description
          $strict
          $defer-loading
          $parameters
          $output-schema)))
   $name)

(= (codex:loadable-tool-spec-name
      (CodexLoadableToolSpecNamespace
        (CodexResponsesApiNamespace $name $description $tools)))
   $name)

(= (codex:function-tool-parameters
      (CodexResponsesApiTool
        $name
        $description
        $strict
        $defer-loading
        $parameters
        $output-schema))
   $parameters)

(= (codex:function-tool-output-schema
      (CodexResponsesApiTool
        $name
        $description
        $strict
        $defer-loading
        $parameters
        $output-schema))
   (if (== $output-schema CodexAbsent)
       Empty
       $output-schema))

(= (codex:freeform-tool-format-definition
      (CodexFreeformTool
        $name
        $description
        $format-type
        $format-syntax
        $format-definition))
   $format-definition)

(= (codex:responses-api-namespace-name
      (CodexResponsesApiNamespace $name $description $tools))
   $name)

(= (codex:responses-api-namespace-description
      (CodexResponsesApiNamespace $name $description $tools))
   $description)

(= (codex:responses-api-namespace-tools
      (CodexResponsesApiNamespace $name $description $tools))
   $tools)

(= (codex:configured-tool-spec-spec
      (CodexConfiguredToolSpec $spec $supports-parallel-tool-calls))
   $spec)

(= (codex:configured-tool-spec-name
      (CodexConfiguredToolSpec $spec $supports-parallel-tool-calls))
   (codex:tool-spec-name $spec))

(= (codex:configured-tool-spec-supports-parallel-tool-calls
      (CodexConfiguredToolSpec $spec $supports-parallel-tool-calls))
   $supports-parallel-tool-calls)

(= (codex:tool-handler-spec-name (CodexToolHandlerSpec $name $kind))
   $name)

(= (codex:tool-handler-spec-kind (CodexToolHandlerSpec $name $kind))
   $kind)

(= (codex:tool-handler-spec-pair (CodexToolHandlerSpec $name $kind))
   ($name $kind))

(= (codex:tool-registry-plan-specs $plan)
   (unique (case (once (eval $plan))
     (((CodexToolRegistryPlan $specs $handlers)
       $specs)))))

(= (codex:tool-registry-plan-handlers $plan)
   (unique (case (once (eval $plan))
     (((CodexToolRegistryPlan $specs $handlers)
       $handlers)))))

(= (codex:tool-registry-json-string-array $items)
   (function
     (let $json-items
       (eval (map-atom $items $item (JsonString $item)))
       (return (JsonArray $json-items)))))

(= (codex:json-schema-string)
   (JsonObject
     ((JsonPair "type" (JsonString "string")))))

(= (codex:json-schema-string $description)
   (JsonObject
     ((JsonPair "type" (JsonString "string"))
      (JsonPair "description" (JsonString $description)))))

(= (codex:json-schema-number)
   (JsonObject
     ((JsonPair "type" (JsonString "number")))))

(= (codex:json-schema-number $description)
   (JsonObject
     ((JsonPair "type" (JsonString "number"))
      (JsonPair "description" (JsonString $description)))))

(= (codex:json-schema-boolean)
   (JsonObject
     ((JsonPair "type" (JsonString "boolean")))))

(= (codex:json-schema-boolean $description)
   (JsonObject
     ((JsonPair "type" (JsonString "boolean"))
      (JsonPair "description" (JsonString $description)))))

(= (codex:json-schema-array $items)
   (JsonObject
     ((JsonPair "type" (JsonString "array"))
      (JsonPair "items" $items))))

(= (codex:json-schema-array $items $description)
   (JsonObject
     ((JsonPair "type" (JsonString "array"))
      (JsonPair "description" (JsonString $description))
      (JsonPair "items" $items))))

(= (codex:json-schema-object $properties)
   (JsonObject
     ((JsonPair "type" (JsonString "object"))
      (JsonPair "properties" (JsonObject $properties)))))

(= (codex:json-schema-object-with-required $properties $required)
   (JsonObject
     ((JsonPair "type" (JsonString "object"))
      (JsonPair "properties" (JsonObject $properties))
      (JsonPair "required" (codex:tool-registry-json-string-array $required)))))

(= (codex:json-schema-object-with-additional-properties
      $properties
      $additional-properties)
   (JsonObject
     ((JsonPair "type" (JsonString "object"))
      (JsonPair "properties" (JsonObject $properties))
      (JsonPair "additionalProperties" (JsonBool $additional-properties)))))

(= (codex:json-schema-object-with-required-and-additional-properties
      $properties
      $required
      $additional-properties)
   (JsonObject
     ((JsonPair "type" (JsonString "object"))
      (JsonPair "properties" (JsonObject $properties))
      (JsonPair "required" (codex:tool-registry-json-string-array $required))
      (JsonPair "additionalProperties" (JsonBool $additional-properties)))))

(= (codex:responses-api-tool-json
      (CodexResponsesApiTool
        $name
        $description
        $strict
        CodexAbsent
        $parameters
        $output-schema))
   (JsonObject
     ((JsonPair "type" (JsonString "function"))
      (JsonPair "name" (JsonString $name))
      (JsonPair "description" (JsonString $description))
      (JsonPair "strict" (JsonBool $strict))
      (JsonPair "parameters" $parameters))))

(= (codex:responses-api-tool-json
      (CodexResponsesApiTool
        $name
        $description
        $strict
        True
        $parameters
        $output-schema))
   (JsonObject
     ((JsonPair "type" (JsonString "function"))
      (JsonPair "name" (JsonString $name))
      (JsonPair "description" (JsonString $description))
      (JsonPair "strict" (JsonBool $strict))
      (JsonPair "defer_loading" (JsonBool True))
      (JsonPair "parameters" $parameters))))

(= (codex:responses-api-tool-json
      (CodexResponsesApiTool
        $name
        $description
        $strict
        False
        $parameters
        $output-schema))
   (JsonObject
     ((JsonPair "type" (JsonString "function"))
      (JsonPair "name" (JsonString $name))
      (JsonPair "description" (JsonString $description))
      (JsonPair "strict" (JsonBool $strict))
      (JsonPair "defer_loading" (JsonBool False))
      (JsonPair "parameters" $parameters))))

(= (codex:responses-api-namespace-tool-json
      (CodexResponsesApiNamespaceToolFunction $tool))
   (codex:responses-api-tool-json $tool))

(= (codex:responses-api-namespace-tool-json-items $tools)
   (function
     (let $json-items
       (eval
         (map-atom
           $tools
           $tool
           (codex:responses-api-namespace-tool-json $tool)))
       (return $json-items))))

(= (codex:responses-api-namespace-json
      (CodexResponsesApiNamespace $name $description $tools))
   (JsonObject
     ((JsonPair "type" (JsonString "namespace"))
      (JsonPair "name" (JsonString $name))
      (JsonPair "description" (JsonString $description))
      (JsonPair
        "tools"
        (JsonArray
          (codex:responses-api-namespace-tool-json-items $tools))))))

(= (codex:loadable-tool-spec-json
      (CodexLoadableToolSpecFunction $tool))
   (codex:responses-api-tool-json $tool))

(= (codex:loadable-tool-spec-json
      (CodexLoadableToolSpecNamespace $namespace))
   (codex:responses-api-namespace-json $namespace))

(= (codex:tool-spec-json
      (CodexToolSpecFunction
        (CodexResponsesApiTool
          $name
          $description
          $strict
          CodexAbsent
          $parameters
          $output-schema)))
   (JsonObject
     ((JsonPair "type" (JsonString "function"))
      (JsonPair "name" (JsonString $name))
      (JsonPair "description" (JsonString $description))
      (JsonPair "strict" (JsonBool $strict))
      (JsonPair "parameters" $parameters))))

(= (codex:tool-spec-json
      (CodexToolSpecFunction
        (CodexResponsesApiTool
          $name
          $description
          $strict
          True
          $parameters
          $output-schema)))
   (JsonObject
     ((JsonPair "type" (JsonString "function"))
      (JsonPair "name" (JsonString $name))
      (JsonPair "description" (JsonString $description))
      (JsonPair "strict" (JsonBool $strict))
      (JsonPair "defer_loading" (JsonBool True))
      (JsonPair "parameters" $parameters))))

(= (codex:tool-spec-json
      (CodexToolSpecFunction
        (CodexResponsesApiTool
          $name
          $description
          $strict
          False
          $parameters
          $output-schema)))
   (JsonObject
     ((JsonPair "type" (JsonString "function"))
      (JsonPair "name" (JsonString $name))
      (JsonPair "description" (JsonString $description))
      (JsonPair "strict" (JsonBool $strict))
      (JsonPair "defer_loading" (JsonBool False))
      (JsonPair "parameters" $parameters))))

(= (codex:tool-spec-json
      (CodexToolSpecFreeform
        (CodexFreeformTool
          $name
          $description
          $format-type
          $format-syntax
          $format-definition)))
   (JsonObject
     ((JsonPair "type" (JsonString "custom"))
      (JsonPair "name" (JsonString $name))
      (JsonPair "description" (JsonString $description))
      (JsonPair "format"
        (JsonObject
          ((JsonPair "type" (JsonString $format-type))
           (JsonPair "syntax" (JsonString $format-syntax))
           (JsonPair "definition" (JsonString $format-definition))))))))

(= (codex:tool-spec-json
      (CodexToolSpecNamespace $namespace))
   (codex:responses-api-namespace-json $namespace))

(= (codex:tool-spec-json
      (CodexToolSpecToolSearch
        $execution
        $description
        $parameters))
   (JsonObject
     ((JsonPair "type" (JsonString "tool_search"))
      (JsonPair "execution" (JsonString $execution))
      (JsonPair "description" (JsonString $description))
      (JsonPair "parameters" $parameters))))

(= (codex:tool-spec-json-items $specs)
   (function
     (let $json-items
       (eval (map-atom $specs $spec (codex:tool-spec-json $spec)))
       (return $json-items))))

(= (codex:configured-tool-spec-json-items $specs)
   (function
     (let $json-items
       (eval
         (map-atom
           $specs
           $spec
           (codex:tool-spec-json (codex:configured-tool-spec-spec $spec))))
       (return $json-items))))

(= (codex:create-tools-json-for-responses-api $specs)
   (JsonArray (codex:tool-spec-json-items $specs)))

(= (codex:tool-registry-plan-tools-json $plan)
   (unique (case (once (eval $plan))
     (((CodexToolRegistryPlan $specs $handlers)
       (JsonArray (codex:configured-tool-spec-json-items $specs)))))))

(= (codex:configured-tool-spec-names $specs)
   (function
     (let $names
       (eval (map-atom $specs $spec (codex:configured-tool-spec-name $spec)))
       (return $names))))

(= (codex:configured-tool-spec-parallel-flags $specs)
   (function
     (let $flags
       (eval
         (map-atom
           $specs
           $spec
           (codex:configured-tool-spec-supports-parallel-tool-calls $spec)))
       (return $flags))))

(= (codex:tool-handler-spec-pairs $handlers)
   (function
     (let $pairs
       (eval (map-atom $handlers $handler (codex:tool-handler-spec-pair $handler)))
       (return $pairs))))

(= (codex:json-bool-array $items)
   (function
     (let $json-items
       (eval (map-atom $items $item (JsonBool $item)))
       (return (JsonArray $json-items)))))

(= (codex:tool-handler-spec-pair-json (CodexToolHandlerSpec $name $kind))
   (JsonArray
     ((JsonString $name)
      (JsonString $kind))))

(= (codex:tool-handler-spec-pairs-json $handlers)
   (function
     (let $json-items
       (eval
         (map-atom $handlers $handler (codex:tool-handler-spec-pair-json $handler)))
       (return (JsonArray $json-items)))))

(= (codex:tool-registry-plan-spec-names $plan)
   (unique (case (once (eval $plan))
     (((CodexToolRegistryPlan $specs $handlers)
       (codex:configured-tool-spec-names $specs))))))

(= (codex:tool-registry-plan-spec-names-json $plan)
   (unique (case (once (eval $plan))
     (((CodexToolRegistryPlan $specs $handlers)
       (codex:tool-registry-json-string-array
         (codex:configured-tool-spec-names $specs)))))))

(= (codex:tool-registry-plan-spec-parallel-flags $plan)
   (unique (case (once (eval $plan))
     (((CodexToolRegistryPlan $specs $handlers)
       (codex:configured-tool-spec-parallel-flags $specs))))))

(= (codex:tool-registry-plan-spec-parallel-flags-json $plan)
   (unique (case (once (eval $plan))
     (((CodexToolRegistryPlan $specs $handlers)
       (codex:json-bool-array
         (codex:configured-tool-spec-parallel-flags $specs)))))))

(= (codex:tool-registry-plan-handler-pairs $plan)
   (unique (case (once (eval $plan))
     (((CodexToolRegistryPlan $specs $handlers)
       (codex:tool-handler-spec-pairs $handlers))))))

(= (codex:tool-registry-plan-handler-pairs-json $plan)
   (unique (case (once (eval $plan))
     (((CodexToolRegistryPlan $specs $handlers)
       (codex:tool-handler-spec-pairs-json $handlers))))))

(= (codex:find-configured-tool-spec-by-name () $name)
   Empty)

(= (codex:find-configured-tool-spec-by-name $specs $name)
   (let ($head $tail) (decons-atom $specs)
     (if (== (codex:configured-tool-spec-name $head) $name)
         $head
         (codex:find-configured-tool-spec-by-name $tail $name))))

(= (codex:unified-exec-output-schema)
   (codex:json-schema-object-with-required-and-additional-properties
     ((JsonPair "chunk_id"
        (codex:json-schema-string
          "Chunk identifier included when the response reports one."))
      (JsonPair "wall_time_seconds"
        (codex:json-schema-number
          "Elapsed wall time spent waiting for output in seconds."))
      (JsonPair "exit_code"
        (codex:json-schema-number
          "Process exit code when the command finished during this call."))
      (JsonPair "session_id"
        (codex:json-schema-number
          "Session identifier to pass to write_stdin when the process is still running."))
      (JsonPair "original_token_count"
        (codex:json-schema-number
          "Approximate token count before output truncation."))
      (JsonPair "output"
        (codex:json-schema-string
          "Command output text, possibly truncated.")))
     ("wall_time_seconds" "output")
     False))

(= (codex:permission-profile-schema)
   (codex:json-schema-object-with-additional-properties
     ((JsonPair "file_system" (codex:file-system-permissions-schema))
      (JsonPair "network" (codex:network-permissions-schema)))
     False))

(= (codex:network-permissions-schema)
   (codex:json-schema-object-with-additional-properties
     ((JsonPair "enabled"
        (codex:json-schema-boolean
          "Set to true to request network access.")))
     False))

(= (codex:file-system-permissions-schema)
   (codex:json-schema-object-with-additional-properties
     ((JsonPair "read"
        (codex:json-schema-array
          (codex:json-schema-string)
          "Absolute paths to grant read access to."))
      (JsonPair "write"
        (codex:json-schema-array
          (codex:json-schema-string)
          "Absolute paths to grant write access to.")))
     False))

(= (codex:update-plan-item-schema)
   (codex:json-schema-object-with-required-and-additional-properties
     ((JsonPair "step" (codex:json-schema-string))
      (JsonPair "status"
        (codex:json-schema-string
          "One of: pending, in_progress, completed")))
     ("step" "status")
     False))

(= (codex:update-plan-tool-parameters-schema)
   (codex:json-schema-object-with-required-and-additional-properties
     ((JsonPair "explanation" (codex:json-schema-string))
      (JsonPair "plan"
        (codex:json-schema-array
          (codex:update-plan-item-schema)
          "The list of steps")))
     ("plan")
     False))

(= (codex:request-user-input-option-schema)
   (codex:json-schema-object-with-required-and-additional-properties
     ((JsonPair "description"
        (codex:json-schema-string
          "One short sentence explaining impact/tradeoff if selected."))
      (JsonPair "label"
        (codex:json-schema-string
          "User-facing label (1-5 words).")))
     ("label" "description")
     False))

(= (codex:request-user-input-question-schema)
   (codex:json-schema-object-with-required-and-additional-properties
     ((JsonPair "header"
        (codex:json-schema-string
          "Short header label shown in the UI (12 or fewer chars)."))
      (JsonPair "id"
        (codex:json-schema-string
          "Stable identifier for mapping answers (snake_case)."))
      (JsonPair "options"
        (codex:json-schema-array
          (codex:request-user-input-option-schema)
          "Provide 2-3 mutually exclusive choices. Put the recommended option first and suffix its label with \"(Recommended)\". Do not include an \"Other\" option in this list; the client will add a free-form \"Other\" option automatically."))
      (JsonPair "question"
        (codex:json-schema-string
          "Single-sentence prompt shown to the user.")))
     ("id" "header" "question" "options")
     False))

(= (codex:request-user-input-tool-parameters-schema)
   (codex:json-schema-object-with-required-and-additional-properties
     ((JsonPair "questions"
        (codex:json-schema-array
          (codex:request-user-input-question-schema)
          "Questions to show the user. Prefer 1 and do not exceed 3")))
     ("questions")
     False))

(= (codex:list-dir-tool-parameters-schema)
   (codex:json-schema-object-with-required-and-additional-properties
     ((JsonPair "dir_path"
        (codex:json-schema-string
          "Absolute path to the directory to list."))
      (JsonPair "offset"
        (codex:json-schema-number
          "The entry number to start listing from. Must be 1 or greater."))
      (JsonPair "limit"
        (codex:json-schema-number
          "The maximum number of entries to return."))
      (JsonPair "depth"
        (codex:json-schema-number
          "The maximum directory depth to traverse. Must be 1 or greater.")))
     ("dir_path")
     False))

(= (codex:view-image-detail-property-description)
   "Optional detail override. The only supported value is `original`; omit this field for default resized behavior. Use `original` to preserve the file's original resolution instead of resizing to fit. This is important when high-fidelity image perception or precise localization is needed, especially for CUA agents.")

(= (codex:view-image-tool-parameters-schema False)
   (codex:json-schema-object-with-required-and-additional-properties
     ((JsonPair "path"
        (codex:json-schema-string
          "Local filesystem path to an image file")))
     ("path")
     False))

(= (codex:view-image-tool-parameters-schema True)
   (codex:json-schema-object-with-required-and-additional-properties
     ((JsonPair "detail"
        (codex:json-schema-string
          (codex:view-image-detail-property-description)))
      (JsonPair "path"
        (codex:json-schema-string
          "Local filesystem path to an image file")))
     ("path")
     False))

(= (codex:view-image-output-schema)
   (JsonObject
     ((JsonPair "type" (JsonString "object"))
      (JsonPair "properties"
        (JsonObject
          ((JsonPair "image_url"
             (JsonObject
               ((JsonPair "type" (JsonString "string"))
                (JsonPair "description"
                  (JsonString "Data URL for the loaded image.")))))
           (JsonPair "detail"
             (JsonObject
               ((JsonPair "type"
                  (JsonArray
                    ((JsonString "string")
                     (JsonString "null"))))
                (JsonPair "description"
                  (JsonString
                    "Image detail hint returned by view_image. Returns `original` when original resolution is preserved, otherwise `null`."))))))))
      (JsonPair "required"
        (JsonArray
          ((JsonString "image_url")
           (JsonString "detail"))))
      (JsonPair "additionalProperties" (JsonBool False)))))

(= (codex:request-permissions-tool-parameters-schema)
   (codex:json-schema-object-with-required-and-additional-properties
     ((JsonPair "permissions" (codex:permission-profile-schema))
      (JsonPair "reason"
        (codex:json-schema-string
          "Optional short explanation for why additional permissions are needed.")))
     ("permissions")
     False))

(= (codex:sandbox-permissions-description False)
   "Sandbox permissions for the command. Set to \"require_escalated\" to request running without sandbox restrictions; defaults to \"use_default\".")

(= (codex:sandbox-permissions-description True)
   "Sandbox permissions for the command. Use \"with_additional_permissions\" to request additional sandboxed filesystem or network permissions (preferred), or \"require_escalated\" to request running without sandbox restrictions; defaults to \"use_default\".")

(= (codex:exec-command-justification-description)
   "Only set if sandbox_permissions is \\\"require_escalated\\\".\n                    Request approval from the user to run this command outside the sandbox.\n                    Phrased as a simple question that summarizes the purpose of the\n                    command as it relates to the task at hand - e.g. 'Do you want to\n                    fetch and pull the latest version of this git branch?'")

(= (codex:exec-command-prefix-rule-description)
   "Only specify when sandbox_permissions is `require_escalated`.\n                        Suggest a prefix command pattern that will allow you to fulfill similar requests from the user in the future.\n                        Should be a short but reasonable prefix, e.g. [\\\"git\\\", \\\"pull\\\"] or [\\\"uv\\\", \\\"run\\\"] or [\\\"pytest\\\"].")

(= (codex:exec-command-properties True True)
   ((JsonPair "additional_permissions" (codex:permission-profile-schema))
    (JsonPair "cmd"
      (codex:json-schema-string "Shell command to execute."))
    (JsonPair "justification"
      (codex:json-schema-string
        (codex:exec-command-justification-description)))
    (JsonPair "login"
      (codex:json-schema-boolean
        "Whether to run the shell with -l/-i semantics. Defaults to true."))
    (JsonPair "max_output_tokens"
      (codex:json-schema-number
        "Maximum number of tokens to return. Excess output will be truncated."))
    (JsonPair "prefix_rule"
      (codex:json-schema-array
        (codex:json-schema-string)
        (codex:exec-command-prefix-rule-description)))
    (JsonPair "sandbox_permissions"
      (codex:json-schema-string
        (codex:sandbox-permissions-description True)))
    (JsonPair "shell"
      (codex:json-schema-string
        "Shell binary to launch. Defaults to the user's default shell."))
    (JsonPair "tty"
      (codex:json-schema-boolean
        "Whether to allocate a TTY for the command. Defaults to false (plain pipes); set to true to open a PTY and access TTY process."))
    (JsonPair "workdir"
      (codex:json-schema-string
        "Optional working directory to run the command in; defaults to the turn cwd."))
    (JsonPair "yield_time_ms"
      (codex:json-schema-number
        "How long to wait (in milliseconds) for output before yielding."))))

(= (codex:exec-command-properties True False)
   ((JsonPair "cmd"
      (codex:json-schema-string "Shell command to execute."))
    (JsonPair "justification"
      (codex:json-schema-string
        (codex:exec-command-justification-description)))
    (JsonPair "login"
      (codex:json-schema-boolean
        "Whether to run the shell with -l/-i semantics. Defaults to true."))
    (JsonPair "max_output_tokens"
      (codex:json-schema-number
        "Maximum number of tokens to return. Excess output will be truncated."))
    (JsonPair "prefix_rule"
      (codex:json-schema-array
        (codex:json-schema-string)
        (codex:exec-command-prefix-rule-description)))
    (JsonPair "sandbox_permissions"
      (codex:json-schema-string
        (codex:sandbox-permissions-description False)))
    (JsonPair "shell"
      (codex:json-schema-string
        "Shell binary to launch. Defaults to the user's default shell."))
    (JsonPair "tty"
      (codex:json-schema-boolean
        "Whether to allocate a TTY for the command. Defaults to false (plain pipes); set to true to open a PTY and access TTY process."))
    (JsonPair "workdir"
      (codex:json-schema-string
        "Optional working directory to run the command in; defaults to the turn cwd."))
    (JsonPair "yield_time_ms"
      (codex:json-schema-number
        "How long to wait (in milliseconds) for output before yielding."))))

(= (codex:exec-command-properties False True)
   ((JsonPair "additional_permissions" (codex:permission-profile-schema))
    (JsonPair "cmd"
      (codex:json-schema-string "Shell command to execute."))
    (JsonPair "justification"
      (codex:json-schema-string
        (codex:exec-command-justification-description)))
    (JsonPair "max_output_tokens"
      (codex:json-schema-number
        "Maximum number of tokens to return. Excess output will be truncated."))
    (JsonPair "prefix_rule"
      (codex:json-schema-array
        (codex:json-schema-string)
        (codex:exec-command-prefix-rule-description)))
    (JsonPair "sandbox_permissions"
      (codex:json-schema-string
        (codex:sandbox-permissions-description True)))
    (JsonPair "shell"
      (codex:json-schema-string
        "Shell binary to launch. Defaults to the user's default shell."))
    (JsonPair "tty"
      (codex:json-schema-boolean
        "Whether to allocate a TTY for the command. Defaults to false (plain pipes); set to true to open a PTY and access TTY process."))
    (JsonPair "workdir"
      (codex:json-schema-string
        "Optional working directory to run the command in; defaults to the turn cwd."))
    (JsonPair "yield_time_ms"
      (codex:json-schema-number
        "How long to wait (in milliseconds) for output before yielding."))))

(= (codex:exec-command-properties False False)
   ((JsonPair "cmd"
      (codex:json-schema-string "Shell command to execute."))
    (JsonPair "justification"
      (codex:json-schema-string
        (codex:exec-command-justification-description)))
    (JsonPair "max_output_tokens"
      (codex:json-schema-number
        "Maximum number of tokens to return. Excess output will be truncated."))
    (JsonPair "prefix_rule"
      (codex:json-schema-array
        (codex:json-schema-string)
        (codex:exec-command-prefix-rule-description)))
    (JsonPair "sandbox_permissions"
      (codex:json-schema-string
        (codex:sandbox-permissions-description False)))
    (JsonPair "shell"
      (codex:json-schema-string
        "Shell binary to launch. Defaults to the user's default shell."))
    (JsonPair "tty"
      (codex:json-schema-boolean
        "Whether to allocate a TTY for the command. Defaults to false (plain pipes); set to true to open a PTY and access TTY process."))
    (JsonPair "workdir"
      (codex:json-schema-string
        "Optional working directory to run the command in; defaults to the turn cwd."))
    (JsonPair "yield_time_ms"
      (codex:json-schema-number
        "How long to wait (in milliseconds) for output before yielding."))))

(= (codex:write-stdin-properties)
   ((JsonPair "chars"
      (codex:json-schema-string
        "Bytes to write to stdin (may be empty to poll)."))
    (JsonPair "max_output_tokens"
      (codex:json-schema-number
        "Maximum number of tokens to return. Excess output will be truncated."))
    (JsonPair "session_id"
      (codex:json-schema-number
        "Identifier of the running unified exec session."))
    (JsonPair "yield_time_ms"
      (codex:json-schema-number
        "How long to wait (in milliseconds) for output before yielding."))))

(= (codex:apply-patch-freeform-description)
   "Use the `apply_patch` tool to edit files. This is a FREEFORM tool, so do not wrap the patch in JSON.")

(= (codex:apply-patch-freeform-grammar)
   "start: begin_patch hunk+ end_patch\nbegin_patch: \"*** Begin Patch\" LF\nend_patch: \"*** End Patch\" LF?\n\nhunk: add_hunk | delete_hunk | update_hunk\nadd_hunk: \"*** Add File: \" filename LF add_line+\ndelete_hunk: \"*** Delete File: \" filename LF\nupdate_hunk: \"*** Update File: \" filename LF change_move? change?\n\nfilename: /(.+)/\nadd_line: \"+\" /(.*)/ LF -> line\n\nchange_move: \"*** Move to: \" filename LF\nchange: (change_context | change_line)+ eof_line?\nchange_context: (\"@@\" | \"@@ \" /(.+)/) LF\nchange_line: (\"+\" | \"-\" | \" \") /(.*)/ LF\neof_line: \"*** End of File\" LF\n\n%import common.LF\n")

(= (codex:create-update-plan-tool)
   (codex:tool-spec-function
     (codex:responses-api-tool
       (codex:update-plan-tool-name)
       (codex:update-plan-tool-description)
       False
       CodexAbsent
       (codex:update-plan-tool-parameters-schema)
       CodexAbsent)))

(= (codex:create-request-user-input-tool $description)
   (codex:tool-spec-function
     (codex:responses-api-tool
       (codex:request-user-input-tool-name)
       $description
       False
       CodexAbsent
       (codex:request-user-input-tool-parameters-schema)
       CodexAbsent)))

(= (codex:create-request-permissions-tool $description)
   (codex:tool-spec-function
     (codex:responses-api-tool
       (codex:request-permissions-tool-name)
       $description
       False
       CodexAbsent
       (codex:request-permissions-tool-parameters-schema)
       CodexAbsent)))

(= (codex:create-list-dir-tool)
   (codex:tool-spec-function
     (codex:responses-api-tool
       (codex:list-dir-tool-name)
       (codex:list-dir-tool-description)
       False
       CodexAbsent
       (codex:list-dir-tool-parameters-schema)
       CodexAbsent)))

(= (codex:create-view-image-tool $can-request-original-image-detail)
   (codex:tool-spec-function
     (codex:responses-api-tool
       (codex:view-image-tool-name)
       (codex:view-image-tool-description)
       False
       CodexAbsent
       (codex:view-image-tool-parameters-schema
         $can-request-original-image-detail)
       (codex:view-image-output-schema))))

(= (codex:create-js-repl-tool)
   (codex:tool-spec-freeform
     (codex:freeform-tool
       (codex:js-repl-tool-name)
       (codex:js-repl-tool-description)
       "grammar"
       "lark"
       (codex:js-repl-freeform-grammar))))

(= (codex:create-js-repl-reset-tool)
   (codex:tool-spec-function
     (codex:responses-api-tool
       (codex:js-repl-reset-tool-name)
       (codex:js-repl-reset-tool-description)
       False
       CodexAbsent
       (codex:json-schema-object-with-additional-properties
         ()
         False)
       CodexAbsent)))

(= (codex:create-exec-command-tool
      $allow-login-shell
      $exec-permission-approvals-enabled)
   (codex:tool-spec-function
     (codex:responses-api-tool
       "exec_command"
       "Runs a command in a PTY, returning output or a session ID for ongoing interaction."
       False
       CodexAbsent
       (codex:json-schema-object-with-required-and-additional-properties
         (codex:exec-command-properties
           $allow-login-shell
           $exec-permission-approvals-enabled)
         ("cmd")
         False)
       (codex:unified-exec-output-schema))))

(= (codex:create-write-stdin-tool)
   (codex:tool-spec-function
     (codex:responses-api-tool
       "write_stdin"
       "Writes characters to an existing unified exec session and returns recent output."
       False
       CodexAbsent
       (codex:json-schema-object-with-required-and-additional-properties
         (codex:write-stdin-properties)
         ("session_id")
         False)
       (codex:unified-exec-output-schema))))

(= (codex:create-apply-patch-freeform-tool)
   (codex:tool-spec-freeform
     (codex:freeform-tool
       "apply_patch"
       (codex:apply-patch-freeform-description)
       "grammar"
       "lark"
       (codex:apply-patch-freeform-grammar))))

; CeTTa reduction accommodation: recursive append drops case-bound handler
; lists in this registry builder. These append-one clauses preserve Rust's
; push order for the currently ported fixed tool surface.
(= (codex:tool-registry-plan-append-one () $item)
   ($item))

(= (codex:tool-registry-plan-append-one ($a0) $item)
   ($a0 $item))

(= (codex:tool-registry-plan-append-one ($a0 $a1) $item)
   ($a0 $a1 $item))

(= (codex:tool-registry-plan-append-one ($a0 $a1 $a2) $item)
   ($a0 $a1 $a2 $item))

(= (codex:tool-registry-plan-append-one ($a0 $a1 $a2 $a3) $item)
   ($a0 $a1 $a2 $a3 $item))

(= (codex:tool-registry-plan-append-one ($a0 $a1 $a2 $a3 $a4) $item)
   ($a0 $a1 $a2 $a3 $a4 $item))

(= (codex:tool-registry-plan-append-one ($a0 $a1 $a2 $a3 $a4 $a5) $item)
   ($a0 $a1 $a2 $a3 $a4 $a5 $item))

(= (codex:tool-registry-plan-append-one ($a0 $a1 $a2 $a3 $a4 $a5 $a6) $item)
   ($a0 $a1 $a2 $a3 $a4 $a5 $a6 $item))

(= (codex:tool-registry-plan-append-one
      ($a0 $a1 $a2 $a3 $a4 $a5 $a6 $a7)
      $item)
   ($a0 $a1 $a2 $a3 $a4 $a5 $a6 $a7 $item))

(= (codex:tool-registry-plan-append-one
      ($a0 $a1 $a2 $a3 $a4 $a5 $a6 $a7 $a8)
      $item)
   ($a0 $a1 $a2 $a3 $a4 $a5 $a6 $a7 $a8 $item))

(= (codex:tool-registry-plan-append-one
      ($a0 $a1 $a2 $a3 $a4 $a5 $a6 $a7 $a8 $a9)
      $item)
   ($a0 $a1 $a2 $a3 $a4 $a5 $a6 $a7 $a8 $a9 $item))

(= (codex:tool-registry-plan-append-one
      ($a0 $a1 $a2 $a3 $a4 $a5 $a6 $a7 $a8 $a9 $a10)
      $item)
   ($a0 $a1 $a2 $a3 $a4 $a5 $a6 $a7 $a8 $a9 $a10 $item))

(= (codex:tool-registry-plan-append-one
      ($a0 $a1 $a2 $a3 $a4 $a5 $a6 $a7 $a8 $a9 $a10 $a11)
      $item)
   ($a0 $a1 $a2 $a3 $a4 $a5 $a6 $a7 $a8 $a9 $a10 $a11 $item))

(= (codex:tool-registry-plan-add-entry
      $plan
      $spec
      $supports-parallel-tool-calls
      $name
      $kind)
   (case (once (eval $plan))
     (((CodexToolRegistryPlan $specs $handlers)
       (codex:tool-registry-plan
         (codex:tool-registry-plan-append-one
           $specs
           (codex:configured-tool-spec $spec $supports-parallel-tool-calls))
         (codex:tool-registry-plan-append-one
           $handlers
           (codex:tool-handler-spec $name $kind)))))))

(= (codex:string-list-contains $values $needle)
   (case (unique (eval $values))
     (($materialized-values
       (codex:string-list-contains-materialized
         $materialized-values
         $needle)))))

(= (codex:string-list-contains-materialized $values $needle)
   (if (list:empty? $values)
       False
       (if (== (list:first $values) $needle)
           True
           (codex:string-list-contains-materialized
             (list:rest $values)
             $needle))))

(= (codex:build-tool-registry-plan $config)
   (unique
   (let $config-value (once (eval $config))
   (let $plan0 (codex:tool-registry-plan-empty)
     ; CeTTa reduction accommodation: materialize each accumulated plan before
     ; passing it to the next append, matching Rust's mutable plan builder.
     (let $plan1
       (once (eval (if (codex:tools-config-has-environment $config-value)
           (if (==
                 (codex:tools-config-shell-type $config-value)
                 (codex:config-shell-tool-type-unified-exec))
               (let $exec-plan
                 (once (eval
                   (codex:tool-registry-plan-add-entry
                     $plan0
                     (codex:create-exec-command-tool
                       (codex:tools-config-allow-login-shell $config-value)
                       (codex:tools-config-exec-permission-approvals-enabled $config-value))
                     True
                     "exec_command"
                     (codex:tool-handler-kind-unified-exec))))
                 (codex:tool-registry-plan-add-entry
                   $exec-plan
                   (codex:create-write-stdin-tool)
                   False
                   "write_stdin"
                   (codex:tool-handler-kind-unified-exec)))
               $plan0)
           $plan0)))
       (let $plan2
         (once (eval (codex:tool-registry-plan-add-entry
           $plan1
           (codex:create-update-plan-tool)
           False
           "update_plan"
           (codex:tool-handler-kind-plan))))
         (let $plan3
           (once (eval (if (and
                 (codex:tools-config-has-environment $config-value)
                 (codex:tools-config-js-repl-enabled $config-value))
               (let $js-repl-plan
                 (once (eval
                   (codex:tool-registry-plan-add-entry
                     $plan2
                     (codex:create-js-repl-tool)
                     False
                     (codex:js-repl-tool-name)
                     (codex:tool-handler-kind-js-repl))))
                 (codex:tool-registry-plan-add-entry
                   $js-repl-plan
                   (codex:create-js-repl-reset-tool)
                   False
                   (codex:js-repl-reset-tool-name)
                   (codex:tool-handler-kind-js-repl-reset)))
               $plan2)))
           (let $plan4
             (once (eval (codex:tool-registry-plan-add-entry
               $plan3
               (codex:create-request-user-input-tool
                 (codex:request-user-input-tool-description
                   (codex:tools-config-default-mode-request-user-input $config-value)))
               False
               "request_user_input"
               (codex:tool-handler-kind-request-user-input))))
             (let $plan5
               (once (eval (if (codex:tools-config-request-permissions-tool-enabled $config-value)
                 (codex:tool-registry-plan-add-entry
                   $plan4
                   (codex:create-request-permissions-tool
                     (codex:request-permissions-tool-description))
                   False
                   "request_permissions"
                   (codex:tool-handler-kind-request-permissions))
                 $plan4)))
             (let $plan6
               (once (eval (if (and
                     (codex:tools-config-has-environment $config-value)
                     (==
                       (codex:tools-config-apply-patch-tool-type $config-value)
                       (codex:apply-patch-tool-type-freeform)))
                   (codex:tool-registry-plan-add-entry
                     $plan5
                     (codex:create-apply-patch-freeform-tool)
                     False
                     "apply_patch"
                     (codex:tool-handler-kind-apply-patch))
                   $plan5)))
               (let $plan7
                 (once (eval (if (and
                       (codex:tools-config-has-environment $config-value)
                       (codex:string-list-contains
                         (codex:tools-config-experimental-supported-tools $config-value)
                         "list_dir"))
                     (codex:tool-registry-plan-add-entry
                       $plan6
                       (codex:create-list-dir-tool)
                       True
                       "list_dir"
                       (codex:tool-handler-kind-list-dir))
                     $plan6)))
                 (let $plan8
                   (once (eval (if (codex:tools-config-has-environment $config-value)
                       (codex:tool-registry-plan-add-entry
                         $plan7
                         (codex:create-view-image-tool
                           (codex:tools-config-can-request-original-image-detail
                             $config-value))
                         True
                         "view_image"
                         (codex:tool-handler-kind-view-image))
                       $plan7)))
                  $plan8))))))))))))
