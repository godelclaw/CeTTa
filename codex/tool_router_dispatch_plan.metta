; Rust-faithful ToolRouter dispatch planning slice.
;
; This ports deterministic behavior from:
; - openai-codex/codex-rs/core/src/tools/router.rs
;   - ToolRouter configured parallel-support checks
;   - MCP server parallel-support checks
;   - dispatch_tool_call_with_code_mode_result direct-call guard
;   - ToolInvocation construction before registry.dispatch_any
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust owns an async ToolRegistry and dispatches trait-object handlers. This
;   slice stops at the pure plan boundary and emits the ToolInvocation that
;   would be sent to registry.dispatch_any, or the same FunctionCallError that
;   Rust returns before dispatch.
; - Rust stores ConfiguredToolSpec values inside ToolRouter together with the
;   live registry. The current CeTTa record keeps the configured specs,
;   parallel MCP server names, and js_repl_tools_only flag needed by the ported
;   behavior.

!(import! &self tool_name)

(= (codex:tool-router-dispatch-router
      $configured-specs
      $parallel-mcp-server-names
      $js-repl-tools-only)
   (CodexToolRouter
     $configured-specs
     $parallel-mcp-server-names
     $js-repl-tools-only))

(= (codex:tool-router-configured-specs
      (CodexToolRouter
        $configured-specs
        $parallel-mcp-server-names
        $js-repl-tools-only))
   $configured-specs)

(= (codex:tool-router-parallel-mcp-server-names
      (CodexToolRouter
        $configured-specs
        $parallel-mcp-server-names
        $js-repl-tools-only))
   $parallel-mcp-server-names)

(= (codex:tool-router-js-repl-tools-only
      (CodexToolRouter
        $configured-specs
        $parallel-mcp-server-names
        $js-repl-tools-only))
   $js-repl-tools-only)

(= (codex:tool-router-dispatch-tool-call
      $tool-name
      $call-id
      $payload)
   (CodexToolCall $tool-name $call-id $payload))

(= (codex:tool-router-dispatch-tool-call-tool-name
      (CodexToolCall $tool-name $call-id $payload))
   $tool-name)

(= (codex:tool-router-dispatch-tool-call-call-id
      (CodexToolCall $tool-name $call-id $payload))
   $call-id)

(= (codex:tool-router-dispatch-tool-call-payload
      (CodexToolCall $tool-name $call-id $payload))
   $payload)

(= (codex:tool-router-dispatch-source-direct)
   (CodexToolCallSourceDirect))

(= (codex:tool-router-dispatch-source-js-repl)
   (CodexToolCallSourceJsRepl))

(= (codex:tool-router-dispatch-source-code-mode
      $cell-id
      $runtime-tool-call-id)
   (CodexToolCallSourceCodeMode $cell-id $runtime-tool-call-id))

(= (codex:tool-router-dispatch-function-payload $arguments)
   (CodexToolPayloadFunction $arguments))

(= (codex:tool-router-dispatch-custom-payload $input)
   (CodexToolPayloadCustom $input))

(= (codex:tool-router-dispatch-tool-search-payload $query $limit)
   (CodexToolPayloadToolSearch $query $limit))

(= (codex:tool-router-dispatch-local-shell-payload $command)
   (CodexToolPayloadLocalShell $command))

(= (codex:tool-router-dispatch-local-shell-params-payload
      $command
      $workdir
      $timeout-ms
      $sandbox-permissions
      $prefix-rule
      $additional-permissions
      $justification)
   (CodexToolPayloadLocalShellParams
     $command
     $workdir
     $timeout-ms
     $sandbox-permissions
     $prefix-rule
     $additional-permissions
     $justification))

(= (codex:tool-router-dispatch-mcp-payload
      $server
      $tool
      $raw-arguments)
   (CodexToolPayloadMcp $server $tool $raw-arguments))

(= (codex:tool-router-dispatch-function-configured-spec
      $name
      $supports-parallel-tool-calls)
   (CodexConfiguredToolSpec
     (CodexToolSpecFunction
       (CodexResponsesApiTool
         $name
         CodexAbsent
         False
         CodexAbsent
         CodexAbsent
         CodexAbsent))
     $supports-parallel-tool-calls))

(= (codex:tool-router-dispatch-freeform-configured-spec
      $name
      $supports-parallel-tool-calls)
   (CodexConfiguredToolSpec
     (CodexToolSpecFreeform
       (CodexFreeformTool
         $name
         CodexAbsent
         CodexAbsent
         CodexAbsent
         CodexAbsent))
     $supports-parallel-tool-calls))

(= (codex:tool-router-list-contains () $needle)
   False)

(= (codex:tool-router-list-contains $items $needle)
   (let ($head $tail) (decons-atom $items)
     (if (== $head $needle)
         True
         (codex:tool-router-list-contains $tail $needle))))

(= (codex:tool-router-configured-tool-spec-supports-parallel
      (CodexConfiguredToolSpec $spec $supports-parallel-tool-calls)
      (CodexToolName $name $namespace))
   (if (or (not $supports-parallel-tool-calls)
           (not (== $namespace CodexAbsent)))
       False
       (case $spec
         (((CodexToolSpecFunction
             (CodexResponsesApiTool
               $tool-name
               $description
               $strict
               $defer-loading
               $parameters
               $output-schema))
           (== $tool-name $name))
          ((CodexToolSpecFreeform
             (CodexFreeformTool
               $tool-name
               $description
               $format-type
               $format-syntax
               $format-definition))
           (== $tool-name $name))
          ((CodexToolSpecNamespace $namespace-spec)
           False)
          ((CodexToolSpecToolSearch)
           False)
          ((CodexToolSpecToolSearch $execution $description $parameters)
           False)
          ((CodexToolSpecLocalShell)
           False)
          ((CodexToolSpecImageGeneration $output-format)
           False)
          ((CodexToolSpecWebSearch)
           False)))))

(= (codex:tool-router-configured-tool-supports-parallel-from
      ()
      $tool-name)
   False)

(= (codex:tool-router-configured-tool-supports-parallel-from
      $configured-specs
      $tool-name)
   (let ($head $tail) (decons-atom $configured-specs)
     (if (codex:tool-router-configured-tool-spec-supports-parallel
           $head
           $tool-name)
         True
         (codex:tool-router-configured-tool-supports-parallel-from
           $tail
           $tool-name))))

(= (codex:tool-router-configured-tool-supports-parallel
      (CodexToolRouter
        $configured-specs
        $parallel-mcp-server-names
        $js-repl-tools-only)
      $tool-name)
   (codex:tool-router-configured-tool-supports-parallel-from
     $configured-specs
     $tool-name))

(= (codex:tool-router-tool-supports-parallel
      (CodexToolRouter
        $configured-specs
        $parallel-mcp-server-names
        $js-repl-tools-only)
      (CodexToolCall
        $tool-name
        $call-id
        (CodexToolPayloadMcp $server $tool $raw-arguments)))
   (codex:tool-router-list-contains
     $parallel-mcp-server-names
     $server))

(= (codex:tool-router-tool-supports-parallel
      (CodexToolRouter
        $configured-specs
        $parallel-mcp-server-names
        $js-repl-tools-only)
      (CodexToolCall
        $tool-name
        $call-id
        (CodexToolPayloadFunction $arguments)))
   (codex:tool-router-configured-tool-supports-parallel-from
     $configured-specs
     $tool-name))

(= (codex:tool-router-tool-supports-parallel
      (CodexToolRouter
        $configured-specs
        $parallel-mcp-server-names
        $js-repl-tools-only)
      (CodexToolCall
        $tool-name
        $call-id
        (CodexToolPayloadCustom $input)))
   (codex:tool-router-configured-tool-supports-parallel-from
     $configured-specs
     $tool-name))

(= (codex:tool-router-tool-supports-parallel
      (CodexToolRouter
        $configured-specs
        $parallel-mcp-server-names
        $js-repl-tools-only)
      (CodexToolCall
        $tool-name
        $call-id
        (CodexToolPayloadToolSearch $query $limit)))
   (codex:tool-router-configured-tool-supports-parallel-from
     $configured-specs
     $tool-name))

(= (codex:tool-router-tool-supports-parallel
      (CodexToolRouter
        $configured-specs
        $parallel-mcp-server-names
        $js-repl-tools-only)
      (CodexToolCall
        $tool-name
        $call-id
        (CodexToolPayloadLocalShell $command)))
   (codex:tool-router-configured-tool-supports-parallel-from
     $configured-specs
     $tool-name))

(= (codex:tool-router-tool-supports-parallel
      (CodexToolRouter
        $configured-specs
        $parallel-mcp-server-names
        $js-repl-tools-only)
      (CodexToolCall
        $tool-name
        $call-id
        (CodexToolPayloadLocalShellParams
          $command
          $workdir
          $timeout-ms
          $sandbox-permissions
          $prefix-rule
          $additional-permissions
          $justification)))
   (codex:tool-router-configured-tool-supports-parallel-from
     $configured-specs
     $tool-name))

(= (codex:tool-router-direct-js-repl-call
      (CodexToolName $name $namespace))
   (and (== $namespace CodexAbsent)
        (or (== $name "js_repl")
            (== $name "js_repl_reset"))))

(= (codex:tool-router-dispatch-direct-call-disabled-message)
   "direct tool calls are disabled; use js_repl and codex.tool(...) instead")

(= (codex:tool-router-dispatch-gate-accepted)
   (CodexToolRouterDispatchGateAccepted))

(= (codex:tool-router-dispatch-gate-rejected $error)
   (CodexToolRouterDispatchGateRejected $error))

(= (codex:tool-router-dispatch-direct-gate
      $js-repl-tools-only
      $tool-name
      (CodexToolCallSourceDirect))
   (if (and $js-repl-tools-only
            (not (codex:tool-router-direct-js-repl-call $tool-name)))
       (codex:tool-router-dispatch-gate-rejected
         (CodexFunctionCallErrorRespondToModel
           (codex:tool-router-dispatch-direct-call-disabled-message)))
       (codex:tool-router-dispatch-gate-accepted)))

(= (codex:tool-router-dispatch-direct-gate
      $js-repl-tools-only
      $tool-name
      (CodexToolCallSourceJsRepl))
   (codex:tool-router-dispatch-gate-accepted))

(= (codex:tool-router-dispatch-direct-gate
      $js-repl-tools-only
      $tool-name
      (CodexToolCallSourceCodeMode $cell-id $runtime-tool-call-id))
   (codex:tool-router-dispatch-gate-accepted))

(= (codex:tool-router-tool-invocation
      $session
      $turn
      $cancellation-token
      $tracker
      $call-id
      $tool-name
      $source
      $payload)
   (CodexToolInvocation
     $session
     $turn
     $cancellation-token
     $tracker
     $call-id
     $tool-name
     $source
     $payload))

(= (codex:tool-router-tool-invocation-session
      (CodexToolInvocation
        $session
        $turn
        $cancellation-token
        $tracker
        $call-id
        $tool-name
        $source
        $payload))
   $session)

(= (codex:tool-router-tool-invocation-turn
      (CodexToolInvocation
        $session
        $turn
        $cancellation-token
        $tracker
        $call-id
        $tool-name
        $source
        $payload))
   $turn)

(= (codex:tool-router-tool-invocation-cancellation-token
      (CodexToolInvocation
        $session
        $turn
        $cancellation-token
        $tracker
        $call-id
        $tool-name
        $source
        $payload))
   $cancellation-token)

(= (codex:tool-router-tool-invocation-tracker
      (CodexToolInvocation
        $session
        $turn
        $cancellation-token
        $tracker
        $call-id
        $tool-name
        $source
        $payload))
   $tracker)

(= (codex:tool-router-tool-invocation-call-id
      (CodexToolInvocation
        $session
        $turn
        $cancellation-token
        $tracker
        $call-id
        $tool-name
        $source
        $payload))
   $call-id)

(= (codex:tool-router-tool-invocation-tool-name
      (CodexToolInvocation
        $session
        $turn
        $cancellation-token
        $tracker
        $call-id
        $tool-name
        $source
        $payload))
   $tool-name)

(= (codex:tool-router-tool-invocation-source
      (CodexToolInvocation
        $session
        $turn
        $cancellation-token
        $tracker
        $call-id
        $tool-name
        $source
        $payload))
   $source)

(= (codex:tool-router-tool-invocation-payload
      (CodexToolInvocation
        $session
        $turn
        $cancellation-token
        $tracker
        $call-id
        $tool-name
        $source
        $payload))
   $payload)

(= (codex:tool-router-dispatch-plan-ok $invocation)
   (CodexToolRouterDispatchPlanOk $invocation))

(= (codex:tool-router-dispatch-plan-rejected $error)
   (CodexToolRouterDispatchPlanRejected $error))

(= (codex:tool-router-dispatch-plan-invocation
      (CodexToolRouterDispatchPlanOk $invocation))
   $invocation)

(= (codex:tool-router-dispatch-plan-error
      (CodexToolRouterDispatchPlanRejected $error))
   $error)

(= (codex:tool-router-dispatch-tool-call-with-code-mode-result-plan
      (CodexToolRouter
        $configured-specs
        $parallel-mcp-server-names
        $js-repl-tools-only)
      $session
      $turn
      $cancellation-token
      $tracker
      (CodexToolCall $tool-name $call-id $payload)
      $source)
   (case (codex:tool-router-dispatch-direct-gate
           $js-repl-tools-only
           $tool-name
           $source)
     (((CodexToolRouterDispatchGateAccepted)
       (codex:tool-router-dispatch-plan-ok
         (codex:tool-router-tool-invocation
           $session
           $turn
           $cancellation-token
           $tracker
           $call-id
           $tool-name
           $source
           $payload)))
      ((CodexToolRouterDispatchGateRejected $error)
       (codex:tool-router-dispatch-plan-rejected $error)))))
