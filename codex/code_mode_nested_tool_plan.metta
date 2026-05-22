; Rust-faithful code-mode nested-tool planning slice.
;
; This ports deterministic helper behavior from:
; - openai-codex/codex-rs/core/src/tools/code_mode/mod.rs
;   - is_exec_tool_name
;   - call_nested_tool up to ToolCallRuntime dispatch
;   - tool_kind_for_spec
;   - tool_kind_for_name
;   - build_nested_tool_payload
;   - build_function_tool_payload / serialize_function_tool_arguments
;   - build_freeform_tool_payload
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust resolves MCP tool info through the async Session and generates a UUID
;   inside call_nested_tool. This pure slice receives the visible MCP tool-info
;   list and UUID text as explicit inputs, preserving the same selection,
;   payload construction, and `exec-{uuid}` call-id shape.
; - Rust's serde_json::to_string has a fallible error arm for JSON objects.
;   The current CeTTa JSON library exposes `json-stringify` as the available
;   serialization primitive, so this slice preserves the successful object
;   serialization and the same model-facing type errors.

!(import! &self context)
!(import! &self function_tool)
!(import! &self json)
!(import! &self str)
!(import! &self tool_name)
!(import! &self tool_router_dispatch_plan)
!(import! &self tool_router_specs_plan)
!(import! &self tool_runtime_parallel_plan)

(= (codex:code-mode-public-tool-name)
   "exec")

(= (codex:code-mode-is-exec-tool-name
      (CodexToolName $name $namespace))
   (and (== $namespace CodexAbsent)
        (== $name (codex:code-mode-public-tool-name))))

(= (codex:code-mode-nested-tool-call
      $cell-id
      $runtime-tool-call-id
      $tool-name
      $input)
   (CodexCodeModeNestedToolCall
     $cell-id
     $runtime-tool-call-id
     $tool-name
     $input))

(= (codex:code-mode-nested-tool-mcp-tool-info
      $callable-namespace
      $callable-name
      $server-name
      $tool-name)
   (CodexCodeModeNestedToolMcpToolInfo
     $callable-namespace
     $callable-name
     $server-name
     $tool-name))

(= (codex:code-mode-nested-tool-mcp-tool-info-canonical-tool-name
      (CodexCodeModeNestedToolMcpToolInfo
        $callable-namespace
        $callable-name
        $server-name
        $tool-name))
   (codex:namespaced-tool-name $callable-namespace $callable-name))

(= (codex:code-mode-nested-tool-mcp-tool-info-server-name
      (CodexCodeModeNestedToolMcpToolInfo
        $callable-namespace
        $callable-name
        $server-name
        $tool-name))
   $server-name)

(= (codex:code-mode-nested-tool-mcp-tool-info-tool-name
      (CodexCodeModeNestedToolMcpToolInfo
        $callable-namespace
        $callable-name
        $server-name
        $tool-name))
   $tool-name)

(= (codex:code-mode-tool-name-equal
      (CodexToolName $left-name $left-namespace)
      (CodexToolName $right-name $right-namespace))
   (and (== $left-name $right-name)
        (== $left-namespace $right-namespace)))

(= (codex:code-mode-resolve-mcp-tool-info
      ()
      $tool-name)
   CodexAbsent)

(= (codex:code-mode-resolve-mcp-tool-info
      $tool-infos
      $tool-name)
   (let ($head $tail) (decons-atom $tool-infos)
     (if (codex:code-mode-tool-name-equal
           (codex:code-mode-nested-tool-mcp-tool-info-canonical-tool-name
             $head)
           $tool-name)
         $head
         (codex:code-mode-resolve-mcp-tool-info
           $tail
           $tool-name))))

(= (codex:code-mode-tool-kind-function)
   CodexCodeModeToolKindFunction)

(= (codex:code-mode-tool-kind-freeform)
   CodexCodeModeToolKindFreeform)

(= (codex:code-mode-tool-kind-result-ok $kind)
   (CodexCodeModeToolKindResultOk $kind))

(= (codex:code-mode-tool-kind-result-error $message)
   (CodexCodeModeToolKindResultError $message))

(= (codex:code-mode-tool-kind-for-spec
      (CodexToolSpecFreeform $tool))
   (codex:code-mode-tool-kind-freeform))

(= (codex:code-mode-tool-kind-for-spec
      (CodexToolSpecFunction $tool))
   (codex:code-mode-tool-kind-function))

(= (codex:code-mode-tool-kind-for-spec
      (CodexToolSpecNamespace $namespace))
   (codex:code-mode-tool-kind-function))

(= (codex:code-mode-tool-kind-for-spec
      (CodexToolSpecToolSearch))
   (codex:code-mode-tool-kind-function))

(= (codex:code-mode-tool-kind-for-spec
      (CodexToolSpecToolSearch
        $execution
        $description
        $parameters))
   (codex:code-mode-tool-kind-function))

(= (codex:code-mode-tool-kind-for-spec
      (CodexToolSpecLocalShell))
   (codex:code-mode-tool-kind-function))

(= (codex:code-mode-tool-kind-for-spec
      (CodexToolSpecImageGeneration $output-format))
   (codex:code-mode-tool-kind-function))

(= (codex:code-mode-tool-kind-for-spec
      (CodexToolSpecWebSearch))
   (codex:code-mode-tool-kind-function))

(= (codex:code-mode-tool-kind-for-name
      CodexAbsent
      $tool-name)
   (codex:code-mode-tool-kind-result-error
     (format-args
       "tool `{}` is not enabled in exec"
       ((codex:tool-name-display $tool-name)))))

(= (codex:code-mode-tool-kind-for-name
      (CodexToolSpecFunction $tool)
      $tool-name)
   (codex:code-mode-tool-kind-result-ok
     (codex:code-mode-tool-kind-for-spec
       (CodexToolSpecFunction $tool))))

(= (codex:code-mode-tool-kind-for-name
      (CodexToolSpecFreeform $tool)
      $tool-name)
   (codex:code-mode-tool-kind-result-ok
     (codex:code-mode-tool-kind-for-spec
       (CodexToolSpecFreeform $tool))))

(= (codex:code-mode-tool-kind-for-name
      (CodexToolSpecNamespace $namespace)
      $tool-name)
   (codex:code-mode-tool-kind-result-ok
     (codex:code-mode-tool-kind-for-spec
       (CodexToolSpecNamespace $namespace))))

(= (codex:code-mode-tool-kind-for-name
      (CodexToolSpecToolSearch)
      $tool-name)
   (codex:code-mode-tool-kind-result-ok
     (codex:code-mode-tool-kind-for-spec
       (CodexToolSpecToolSearch))))

(= (codex:code-mode-tool-kind-for-name
      (CodexToolSpecToolSearch $execution $description $parameters)
      $tool-name)
   (codex:code-mode-tool-kind-result-ok
     (codex:code-mode-tool-kind-for-spec
       (CodexToolSpecToolSearch
         $execution
         $description
         $parameters))))

(= (codex:code-mode-tool-kind-for-name
      (CodexToolSpecLocalShell)
      $tool-name)
   (codex:code-mode-tool-kind-result-ok
     (codex:code-mode-tool-kind-for-spec
       (CodexToolSpecLocalShell))))

(= (codex:code-mode-tool-kind-for-name
      (CodexToolSpecImageGeneration $output-format)
      $tool-name)
   (codex:code-mode-tool-kind-result-ok
     (codex:code-mode-tool-kind-for-spec
       (CodexToolSpecImageGeneration $output-format))))

(= (codex:code-mode-tool-kind-for-name
      (CodexToolSpecWebSearch)
      $tool-name)
   (codex:code-mode-tool-kind-result-ok
     (codex:code-mode-tool-kind-for-spec
       (CodexToolSpecWebSearch))))

(= (codex:code-mode-serialize-arguments-ok $arguments)
   (CodexCodeModeSerializeArgumentsOk $arguments))

(= (codex:code-mode-serialize-arguments-error $message)
   (CodexCodeModeSerializeArgumentsError $message))

(= (codex:code-mode-serialize-function-tool-arguments
      $tool-name
      $input)
   (case $input
     ((CodexAbsent
       (codex:code-mode-serialize-arguments-ok "{}"))
      ((JsonObject $pairs)
       (codex:code-mode-serialize-arguments-ok
         (json-stringify (JsonObject $pairs))))
      ($other
       (codex:code-mode-serialize-arguments-error
         (format-args
           "tool `{}` expects a JSON object for arguments"
           ((codex:tool-name-display $tool-name))))))))

(= (codex:code-mode-build-payload-ok $payload)
   (CodexCodeModeBuildPayloadOk $payload))

(= (codex:code-mode-build-payload-error $message)
   (CodexCodeModeBuildPayloadError $message))

(= (codex:code-mode-build-function-tool-payload
      $tool-name
      $input)
   (case (codex:code-mode-serialize-function-tool-arguments
           $tool-name
           $input)
     (((CodexCodeModeSerializeArgumentsOk $arguments)
       (codex:code-mode-build-payload-ok
         (codex:function-payload $arguments)))
      ((CodexCodeModeSerializeArgumentsError $message)
       (codex:code-mode-build-payload-error $message)))))

(= (codex:code-mode-build-freeform-tool-payload
      $tool-name
      $input)
   (case $input
     (((JsonString $text)
       (codex:code-mode-build-payload-ok
         (codex:custom-payload $text)))
      ($other
       (codex:code-mode-build-payload-error
         (format-args
           "tool `{}` expects a string input"
           ((codex:tool-name-display $tool-name))))))))

(= (codex:code-mode-build-nested-tool-payload
      $spec
      $tool-name
      $input)
   (case (codex:code-mode-tool-kind-for-name $spec $tool-name)
     (((CodexCodeModeToolKindResultError $message)
       (codex:code-mode-build-payload-error $message))
      ((CodexCodeModeToolKindResultOk CodexCodeModeToolKindFunction)
       (codex:code-mode-build-function-tool-payload
         $tool-name
         $input))
      ((CodexCodeModeToolKindResultOk CodexCodeModeToolKindFreeform)
       (codex:code-mode-build-freeform-tool-payload
         $tool-name
         $input)))))

(= (codex:code-mode-nested-tool-selection-ok
      $tool-call-name
      $payload
      $payload-kind)
   (CodexCodeModeNestedToolSelectionOk
     $tool-call-name
     $payload
     $payload-kind))

(= (codex:code-mode-nested-tool-selection-error $message)
   (CodexCodeModeNestedToolSelectionError $message))

(= (codex:code-mode-nested-tool-payload-kind-mcp)
   CodexCodeModeNestedToolPayloadKindMcp)

(= (codex:code-mode-nested-tool-payload-kind-custom)
   CodexCodeModeNestedToolPayloadKindCustom)

(= (codex:code-mode-nested-tool-payload-kind-function)
   CodexCodeModeNestedToolPayloadKindFunction)

(= (codex:code-mode-nested-tool-payload-kind-for-payload
      (CodexToolPayloadMcp $server $tool $raw-arguments))
   (codex:code-mode-nested-tool-payload-kind-mcp))

(= (codex:code-mode-nested-tool-payload-kind-for-payload
      (CodexToolPayloadCustom $input))
   (codex:code-mode-nested-tool-payload-kind-custom))

(= (codex:code-mode-nested-tool-payload-kind-for-payload
      (CodexToolPayloadFunction $arguments))
   (codex:code-mode-nested-tool-payload-kind-function))

(= (codex:code-mode-nested-tool-selection-tool-call-name
      (CodexCodeModeNestedToolSelectionOk
        $tool-call-name
        $payload
        $payload-kind))
   $tool-call-name)

(= (codex:code-mode-nested-tool-selection-payload
      (CodexCodeModeNestedToolSelectionOk
        $tool-call-name
        $payload
        $payload-kind))
   $payload)

(= (codex:code-mode-nested-tool-selection-payload-kind
      (CodexCodeModeNestedToolSelectionOk
        $tool-call-name
        $payload
        $payload-kind))
   $payload-kind)

(= (codex:code-mode-nested-tool-selection-error-message
      (CodexCodeModeNestedToolSelectionError $message))
   $message)

(= (codex:code-mode-select-mcp-tool-call
      (CodexCodeModeNestedToolMcpToolInfo
        $callable-namespace
        $callable-name
        $server-name
        $mcp-tool-name)
      $requested-tool-name
      $input)
   (case (codex:code-mode-serialize-function-tool-arguments
           $requested-tool-name
           $input)
     (((CodexCodeModeSerializeArgumentsOk $raw-arguments)
       (let $info
         (CodexCodeModeNestedToolMcpToolInfo
           $callable-namespace
           $callable-name
           $server-name
           $mcp-tool-name)
         (codex:code-mode-nested-tool-selection-ok
           (codex:code-mode-nested-tool-mcp-tool-info-canonical-tool-name
             $info)
           (codex:mcp-payload
             (codex:code-mode-nested-tool-mcp-tool-info-server-name
               $info)
             (codex:code-mode-nested-tool-mcp-tool-info-tool-name
               $info)
             $raw-arguments)
           (codex:code-mode-nested-tool-payload-kind-mcp))))
      ((CodexCodeModeSerializeArgumentsError $message)
       (codex:code-mode-nested-tool-selection-error $message)))))

(= (codex:code-mode-select-local-tool-call
      $runtime
      $requested-tool-name
      $input)
   (let $router (codex:tool-call-runtime-router $runtime)
     (let $spec
       (codex:tool-router-find-spec-from-configured
         (codex:tool-router-configured-specs $router)
         $requested-tool-name)
       (case (codex:code-mode-build-nested-tool-payload
               $spec
               $requested-tool-name
               $input)
         (((CodexCodeModeBuildPayloadOk $payload)
           (codex:code-mode-nested-tool-selection-ok
             $requested-tool-name
             $payload
             (codex:code-mode-nested-tool-payload-kind-for-payload
               $payload)))
          ((CodexCodeModeBuildPayloadError $message)
           (codex:code-mode-nested-tool-selection-error $message)))))))

(= (codex:code-mode-select-nested-tool-call
      $runtime
      $mcp-tool-infos
      $requested-tool-name
      $input)
   (case (codex:code-mode-resolve-mcp-tool-info
           $mcp-tool-infos
           $requested-tool-name)
     ((CodexAbsent
       (codex:code-mode-select-local-tool-call
         $runtime
         $requested-tool-name
         $input))
      ((CodexCodeModeNestedToolMcpToolInfo
         $callable-namespace
         $callable-name
         $server-name
         $mcp-tool-name)
       (codex:code-mode-select-mcp-tool-call
         (CodexCodeModeNestedToolMcpToolInfo
           $callable-namespace
           $callable-name
           $server-name
           $mcp-tool-name)
         $requested-tool-name
         $input)))))

(= (codex:code-mode-nested-tool-call-id $uuid-text)
   (str-concat
     (codex:code-mode-public-tool-name)
     (str-concat "-" $uuid-text)))

(= (codex:code-mode-nested-tool-plan-ok
      $requested-tool-name
      $tool-call
      $source)
   (CodexCodeModeNestedToolPlanOk
     $requested-tool-name
     $tool-call
     $source))

(= (codex:code-mode-nested-tool-plan-error $error)
   (CodexCodeModeNestedToolPlanError $error))

(= (codex:code-mode-nested-tool-plan-tool-call
      (CodexCodeModeNestedToolPlanOk
        $requested-tool-name
        $tool-call
        $source))
   $tool-call)

(= (codex:code-mode-nested-tool-plan-source
      (CodexCodeModeNestedToolPlanOk
        $requested-tool-name
        $tool-call
        $source))
   $source)

(= (codex:code-mode-nested-tool-plan-error-value
      (CodexCodeModeNestedToolPlanError $error))
   $error)

(= (codex:code-mode-nested-tool-call-plan
      $runtime
      $mcp-tool-infos
      (CodexCodeModeNestedToolCall
        $cell-id
        $runtime-tool-call-id
        $tool-name
        $input)
      $uuid-text)
   (if (codex:code-mode-is-exec-tool-name $tool-name)
       (codex:code-mode-nested-tool-plan-error
         (codex:function-call-error-respond-to-model
           "exec cannot invoke itself"))
       (case (codex:code-mode-select-nested-tool-call
               $runtime
               $mcp-tool-infos
               $tool-name
               $input)
         (((CodexCodeModeNestedToolSelectionOk
             $tool-call-name
             $payload
             $payload-kind)
           (codex:code-mode-nested-tool-plan-ok
             $tool-name
             (codex:tool-router-dispatch-tool-call
               $tool-call-name
               (codex:code-mode-nested-tool-call-id $uuid-text)
               $payload)
             (codex:tool-router-dispatch-source-code-mode
               $cell-id
               $runtime-tool-call-id)))
          ((CodexCodeModeNestedToolSelectionError $message)
           (codex:code-mode-nested-tool-plan-error
             (codex:function-call-error-respond-to-model
               $message)))))))

(= (codex:code-mode-nested-tool-runtime-plan-ok
      $call-plan
      $dispatch-plan)
   (CodexCodeModeNestedToolRuntimePlanOk $call-plan $dispatch-plan))

(= (codex:code-mode-nested-tool-runtime-plan-error $error)
   (CodexCodeModeNestedToolRuntimePlanError $error))

(= (codex:code-mode-nested-tool-runtime-plan-dispatch-plan
      (CodexCodeModeNestedToolRuntimePlanOk $call-plan $dispatch-plan))
   $dispatch-plan)

(= (codex:code-mode-nested-tool-runtime-plan
      $runtime
      $mcp-tool-infos
      $invocation
      $uuid-text
      $cancellation-token)
   (case (codex:code-mode-nested-tool-call-plan
           $runtime
           $mcp-tool-infos
           $invocation
           $uuid-text)
     (((CodexCodeModeNestedToolPlanOk
         $requested-tool-name
         $tool-call
         $source)
       (let $call-plan
         (CodexCodeModeNestedToolPlanOk
           $requested-tool-name
           $tool-call
           $source)
         (codex:code-mode-nested-tool-runtime-plan-ok
           $call-plan
           (codex:tool-call-runtime-handle-tool-call-with-source-plan
             $runtime
             $tool-call
             $source
             $cancellation-token))))
      ((CodexCodeModeNestedToolPlanError $error)
       (codex:code-mode-nested-tool-runtime-plan-error $error)))))

(= (codex:code-mode-nested-tool-result-ok $json)
   (CodexCodeModeNestedToolResultOk $json))

(= (codex:code-mode-nested-tool-result-error $error)
   (CodexCodeModeNestedToolResultError $error))

(= (codex:code-mode-nested-tool-dispatch-result
      (CodexToolCallRuntimeDispatchOk $any-tool-result))
   (codex:code-mode-nested-tool-result-ok
     (codex:tool-output-code-mode-result
       (codex:tool-call-runtime-any-tool-result-tool-output
         $any-tool-result)
       (codex:tool-call-runtime-any-tool-result-payload
         $any-tool-result))))

(= (codex:code-mode-nested-tool-dispatch-result
      (CodexToolCallRuntimeDispatchError $error))
   (codex:code-mode-nested-tool-result-error $error))
