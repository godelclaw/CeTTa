; Rust-faithful js_repl run_tool_request router/payload planning slice.
;
; This ports deterministic helper behavior from:
; - openai-codex/codex-rs/core/src/tools/js_repl/mod.rs
;   - router parameter construction after the internal-tool guard
;   - requested ToolName discovery from ToolSpec values
;   - MCP/freeform/function payload selection
;   - ToolCall construction before dispatch_tool_call_with_code_mode_result
; - openai-codex/codex-rs/tools/src/code_mode.rs
;   - code_mode_name_for_tool_name
; - openai-codex/codex-rs/core/src/tools/router.rs
;   - ToolRouter::find_spec matching used by this branch
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust builds a ToolRouter from live ToolsConfig, MCP tools, and dynamic
;   tools. This pure slice records the exact ToolRouterParams values and
;   receives the resulting specs as an explicit input.
; - Rust resolves MCP tool metadata asynchronously from Session. This slice
;   receives the visible ToolInfo list as an explicit input and applies the
;   same canonical ToolName equality rule.

!(import! &self context)
!(import! &self js_repl_run_tool_common)
!(import! &self str)
!(import! &self tool_name)

(= (codex:js-repl-run-tool-router-params-mcp-tools-some $mcp-tools)
   (CodexJsReplRunToolRouterParamsMcpToolsSome $mcp-tools))

(= (codex:js-repl-run-tool-router-params
      $mcp-tools
      $dynamic-tools)
   (CodexJsReplRunToolRouterParams
     CodexAbsent
     (codex:js-repl-run-tool-router-params-mcp-tools-some $mcp-tools)
     ()
     ()
     CodexAbsent
     $dynamic-tools))

(= (codex:js-repl-run-tool-router-plan
      $tools-config
      $mcp-tools
      $dynamic-tools
      $specs)
   (CodexJsReplRunToolRouterPlan
     $tools-config
     (codex:js-repl-run-tool-router-params $mcp-tools $dynamic-tools)
     $specs))

(= (codex:js-repl-run-tool-router-plan-tools-config
      (CodexJsReplRunToolRouterPlan $tools-config $params $specs))
   $tools-config)

(= (codex:js-repl-run-tool-router-plan-params
      (CodexJsReplRunToolRouterPlan $tools-config $params $specs))
   $params)

(= (codex:js-repl-run-tool-router-plan-specs
      (CodexJsReplRunToolRouterPlan $tools-config $params $specs))
   $specs)

(= (codex:js-repl-run-tool-function-spec $name)
   (CodexToolSpecFunction
     (CodexResponsesApiTool
       $name
       CodexAbsent
       False
       CodexAbsent
       CodexAbsent
       CodexAbsent)))

(= (codex:js-repl-run-tool-freeform-spec $name)
   (CodexToolSpecFreeform
     (CodexFreeformTool
       $name
       CodexAbsent
       CodexAbsent
       CodexAbsent
       CodexAbsent)))

(= (codex:js-repl-run-tool-namespace-function $name)
   (CodexResponsesApiNamespaceToolFunction
     (CodexResponsesApiTool
       $name
       CodexAbsent
       False
       CodexAbsent
       CodexAbsent
       CodexAbsent)))

(= (codex:js-repl-run-tool-namespace-spec
      $namespace-name
      $description
      $tools)
   (CodexToolSpecNamespace
     (CodexResponsesApiNamespace $namespace-name $description $tools)))

(= (codex:js-repl-run-tool-local-shell-spec)
   (CodexToolSpecLocalShell))

(= (codex:js-repl-run-tool-image-generation-spec $output-format)
   (CodexToolSpecImageGeneration $output-format))

(= (codex:js-repl-run-tool-tool-search-spec)
   (CodexToolSpecToolSearch))

(= (codex:js-repl-run-tool-web-search-spec)
   (CodexToolSpecWebSearch))

(= (codex:js-repl-run-tool-responses-api-tool-name
      (CodexResponsesApiTool
        $name
        $description
        $strict
        $defer-loading
        $parameters
        $output-schema))
   $name)

(= (codex:js-repl-code-mode-name-for-tool-name
      (CodexToolName $name $namespace))
   (if (== $namespace CodexAbsent)
       $name
       (if (or (str-ends-with? $namespace "_")
               (str-starts-with? $name "_"))
           (str-concat $namespace $name)
           (str-concat $namespace (str-concat "_" $name)))))

(= (codex:js-repl-run-tool-tool-name-equal
      (CodexToolName $left-name $left-namespace)
      (CodexToolName $right-name $right-namespace))
   (and (== $left-name $right-name)
        (== $left-namespace $right-namespace)))

(= (codex:js-repl-run-tool-requested-tool-name-from-namespace-tool
      $namespace-name
      $tool
      $requested-name)
   (case $tool
     (((CodexResponsesApiNamespaceToolFunction $function-tool)
       (let $tool-name
         (codex:namespaced-tool-name
           $namespace-name
           (codex:js-repl-run-tool-responses-api-tool-name
             $function-tool))
         (let $code-mode-name
           (codex:js-repl-code-mode-name-for-tool-name $tool-name)
           (if (or (== $code-mode-name $requested-name)
                   (== (codex:tool-name-display $tool-name) $requested-name))
               $tool-name
               CodexAbsent)))))))

(= (codex:js-repl-run-tool-requested-tool-name-from-namespace-tools
      $namespace-name
      ()
      $requested-name)
   CodexAbsent)

(= (codex:js-repl-run-tool-requested-tool-name-from-namespace-tools
      $namespace-name
      $tools
      $requested-name)
   (let ($head $tail) (decons-atom $tools)
     (case (codex:js-repl-run-tool-requested-tool-name-from-namespace-tool
             $namespace-name
             $head
             $requested-name)
       ((CodexAbsent
         (codex:js-repl-run-tool-requested-tool-name-from-namespace-tools
           $namespace-name
           $tail
           $requested-name))
        ((CodexToolName $name $namespace)
         (CodexToolName $name $namespace))))))

(= (codex:js-repl-run-tool-requested-tool-name-from-spec
      $spec
      $requested-name)
   (case $spec
     (((CodexToolSpecFunction $tool)
       (if (== (codex:js-repl-run-tool-responses-api-tool-name $tool)
               $requested-name)
           (codex:plain-tool-name $requested-name)
           CodexAbsent))
      ((CodexToolSpecFreeform
         (CodexFreeformTool
           $name
           $description
           $format-type
           $format-syntax
           $format-definition))
       (if (== $name $requested-name)
           (codex:plain-tool-name $requested-name)
           CodexAbsent))
      ((CodexToolSpecNamespace
         (CodexResponsesApiNamespace $namespace-name $description $tools))
       (codex:js-repl-run-tool-requested-tool-name-from-namespace-tools
         $namespace-name
         $tools
         $requested-name))
      ((CodexToolSpecLocalShell) CodexAbsent)
      ((CodexToolSpecImageGeneration $output-format) CodexAbsent)
      ((CodexToolSpecToolSearch) CodexAbsent)
      ((CodexToolSpecToolSearch $execution $description $parameters)
       CodexAbsent)
      ((CodexToolSpecWebSearch) CodexAbsent))))

(= (codex:js-repl-run-tool-requested-tool-name-from-specs
      ()
      $requested-name)
   (codex:plain-tool-name $requested-name))

(= (codex:js-repl-run-tool-requested-tool-name-from-specs
      $specs
      $requested-name)
   (let ($head $tail) (decons-atom $specs)
     (case (codex:js-repl-run-tool-requested-tool-name-from-spec
             $head
             $requested-name)
       ((CodexAbsent
         (codex:js-repl-run-tool-requested-tool-name-from-specs
           $tail
           $requested-name))
        ((CodexToolName $name $namespace)
         (CodexToolName $name $namespace))))))

(= (codex:js-repl-run-tool-router-find-namespace-function
      $namespace-name
      ()
      (CodexToolName $name $namespace))
   CodexAbsent)

(= (codex:js-repl-run-tool-router-find-namespace-function
      $namespace-name
      $tools
      (CodexToolName $name $namespace))
   (if (not (== $namespace $namespace-name))
       CodexAbsent
       (let ($head $tail) (decons-atom $tools)
         (case $head
           (((CodexResponsesApiNamespaceToolFunction $function-tool)
             (if (== (codex:js-repl-run-tool-responses-api-tool-name
                       $function-tool)
                     $name)
                 (CodexToolSpecFunction $function-tool)
                 (codex:js-repl-run-tool-router-find-namespace-function
                   $namespace-name
                   $tail
                   (CodexToolName $name $namespace)))))))))

(= (codex:js-repl-run-tool-router-find-spec-match
      $spec
      (CodexToolName $name $namespace))
   (case $spec
     (((CodexToolSpecFunction $tool)
       (if (and (== $namespace CodexAbsent)
                (== (codex:js-repl-run-tool-responses-api-tool-name $tool)
                    $name))
           $spec
           CodexAbsent))
      ((CodexToolSpecFreeform
         (CodexFreeformTool
           $tool-name
           $description
           $format-type
           $format-syntax
           $format-definition))
       (if (and (== $namespace CodexAbsent)
                (== $tool-name $name))
           $spec
           CodexAbsent))
      ((CodexToolSpecNamespace
         (CodexResponsesApiNamespace $namespace-name $description $tools))
       (codex:js-repl-run-tool-router-find-namespace-function
         $namespace-name
         $tools
         (CodexToolName $name $namespace)))
      ((CodexToolSpecLocalShell) CodexAbsent)
      ((CodexToolSpecImageGeneration $output-format) CodexAbsent)
      ((CodexToolSpecToolSearch) CodexAbsent)
      ((CodexToolSpecToolSearch $execution $description $parameters)
       CodexAbsent)
      ((CodexToolSpecWebSearch) CodexAbsent))))

(= (codex:js-repl-run-tool-router-find-spec () $tool-name)
   CodexAbsent)

(= (codex:js-repl-run-tool-router-find-spec $specs $tool-name)
   (let ($head $tail) (decons-atom $specs)
     (case (codex:js-repl-run-tool-router-find-spec-match $head $tool-name)
       ((CodexAbsent
         (codex:js-repl-run-tool-router-find-spec $tail $tool-name))
        ((CodexToolSpecFunction $tool)
         (CodexToolSpecFunction $tool))
        ((CodexToolSpecFreeform $tool)
         (CodexToolSpecFreeform $tool))))))

(= (codex:js-repl-run-tool-mcp-tool-info
      $callable-namespace
      $callable-name
      $server-name
      $tool-name)
   (CodexJsReplRunToolMcpToolInfo
     $callable-namespace
     $callable-name
     $server-name
     $tool-name))

(= (codex:js-repl-run-tool-mcp-tool-info-canonical-tool-name
      (CodexJsReplRunToolMcpToolInfo
        $callable-namespace
        $callable-name
        $server-name
        $tool-name))
   (codex:namespaced-tool-name $callable-namespace $callable-name))

(= (codex:js-repl-run-tool-mcp-tool-info-server-name
      (CodexJsReplRunToolMcpToolInfo
        $callable-namespace
        $callable-name
        $server-name
        $tool-name))
   $server-name)

(= (codex:js-repl-run-tool-mcp-tool-info-tool-name
      (CodexJsReplRunToolMcpToolInfo
        $callable-namespace
        $callable-name
        $server-name
        $tool-name))
   $tool-name)

(= (codex:js-repl-run-tool-resolve-mcp-tool-info
      ()
      $tool-name)
   CodexAbsent)

(= (codex:js-repl-run-tool-resolve-mcp-tool-info
      $tool-infos
      $tool-name)
   (let ($head $tail) (decons-atom $tool-infos)
     (if (codex:js-repl-run-tool-tool-name-equal
           (codex:js-repl-run-tool-mcp-tool-info-canonical-tool-name
             $head)
           $tool-name)
         $head
         (codex:js-repl-run-tool-resolve-mcp-tool-info
           $tail
           $tool-name))))

(= (codex:js-repl-run-tool-tool-call-selection
      $tool-call-name
      $payload
      $payload-kind)
   (CodexJsReplRunToolToolCallSelection
     $tool-call-name
     $payload
     $payload-kind))

(= (codex:js-repl-run-tool-tool-call-selection-tool-call-name
      (CodexJsReplRunToolToolCallSelection
        $tool-call-name
        $payload
        $payload-kind))
   $tool-call-name)

(= (codex:js-repl-run-tool-tool-call-selection-payload
      (CodexJsReplRunToolToolCallSelection
        $tool-call-name
        $payload
        $payload-kind))
   $payload)

(= (codex:js-repl-run-tool-tool-call-selection-payload-kind
      (CodexJsReplRunToolToolCallSelection
        $tool-call-name
        $payload
        $payload-kind))
   $payload-kind)

(= (codex:js-repl-run-tool-payload-kind-mcp)
   CodexJsReplRunToolPayloadKindMcp)

(= (codex:js-repl-run-tool-payload-kind-custom)
   CodexJsReplRunToolPayloadKindCustom)

(= (codex:js-repl-run-tool-payload-kind-function)
   CodexJsReplRunToolPayloadKindFunction)

(= (codex:js-repl-run-tool-select-tool-call-payload
      $requested-tool-name
      $specs
      $mcp-tool-infos
      $arguments)
   (case (codex:js-repl-run-tool-resolve-mcp-tool-info
           $mcp-tool-infos
           $requested-tool-name)
     ((CodexAbsent
       (case (codex:js-repl-run-tool-router-find-spec
               $specs
               $requested-tool-name)
         (((CodexToolSpecFreeform $tool)
           (codex:js-repl-run-tool-tool-call-selection
             $requested-tool-name
             (codex:custom-payload $arguments)
             (codex:js-repl-run-tool-payload-kind-custom)))
          (CodexAbsent
           (codex:js-repl-run-tool-tool-call-selection
             $requested-tool-name
             (codex:function-payload $arguments)
             (codex:js-repl-run-tool-payload-kind-function)))
          ((CodexToolSpecFunction $tool)
           (codex:js-repl-run-tool-tool-call-selection
             $requested-tool-name
             (codex:function-payload $arguments)
             (codex:js-repl-run-tool-payload-kind-function))))))
      ((CodexJsReplRunToolMcpToolInfo
         $callable-namespace
         $callable-name
         $server-name
         $mcp-tool-name)
       (codex:js-repl-run-tool-tool-call-selection
         (codex:js-repl-run-tool-mcp-tool-info-canonical-tool-name
           (CodexJsReplRunToolMcpToolInfo
             $callable-namespace
             $callable-name
             $server-name
             $mcp-tool-name))
         (codex:mcp-payload
           (codex:js-repl-run-tool-mcp-tool-info-server-name
             (CodexJsReplRunToolMcpToolInfo
               $callable-namespace
               $callable-name
               $server-name
               $mcp-tool-name))
           (codex:js-repl-run-tool-mcp-tool-info-tool-name
             (CodexJsReplRunToolMcpToolInfo
               $callable-namespace
               $callable-name
               $server-name
               $mcp-tool-name))
           $arguments)
         (codex:js-repl-run-tool-payload-kind-mcp))))))

(= (codex:js-repl-run-tool-tool-call $tool-name $call-id $payload)
   (CodexToolCall $tool-name $call-id $payload))

(= (codex:js-repl-run-tool-tool-call-tool-name
      (CodexToolCall $tool-name $call-id $payload))
   $tool-name)

(= (codex:js-repl-run-tool-tool-call-call-id
      (CodexToolCall $tool-name $call-id $payload))
   $call-id)

(= (codex:js-repl-run-tool-tool-call-payload
      (CodexToolCall $tool-name $call-id $payload))
   $payload)

(= (codex:js-repl-run-tool-dispatch-plan
      $requested-tool-name
      $tool-call
      $source)
   (CodexJsReplRunToolDispatchPlan
     $requested-tool-name
     $tool-call
     $source))

(= (codex:js-repl-run-tool-dispatch-plan-requested-tool-name
      (CodexJsReplRunToolDispatchPlan
        $requested-tool-name
        $tool-call
        $source))
   $requested-tool-name)

(= (codex:js-repl-run-tool-dispatch-plan-tool-call
      (CodexJsReplRunToolDispatchPlan
        $requested-tool-name
        $tool-call
        $source))
   $tool-call)

(= (codex:js-repl-run-tool-dispatch-plan-source
      (CodexJsReplRunToolDispatchPlan
        $requested-tool-name
        $tool-call
        $source))
   $source)

(= (codex:js-repl-run-tool-request-dispatch-plan
      $request
      $specs
      $mcp-tool-infos)
   (case $request
     (((CodexJsReplKernelToHostRunTool $id $exec-id $tool-name $arguments)
       (let $requested-tool-name
         (codex:js-repl-run-tool-requested-tool-name-from-specs
           $specs
           $tool-name)
         (let $selection
           (codex:js-repl-run-tool-select-tool-call-payload
             $requested-tool-name
             $specs
             $mcp-tool-infos
             $arguments)
           (codex:js-repl-run-tool-dispatch-plan
             $requested-tool-name
             (codex:js-repl-run-tool-tool-call
               (codex:js-repl-run-tool-tool-call-selection-tool-call-name
                 $selection)
               $id
               (codex:js-repl-run-tool-tool-call-selection-payload
                 $selection))
             (CodexToolCallSourceJsRepl))))))))
