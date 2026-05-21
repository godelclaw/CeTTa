; Rust-faithful js_repl run_tool_request control-flow slice.
;
; This ports the enclosing branch order from:
; - openai-codex/codex-rs/core/src/tools/js_repl/mod.rs
;   - run_tool_request
;
; Covered in this increment:
; - internal js_repl/js_repl_reset rejection short-circuits before router build
; - non-internal requests construct ToolRouterParams/router-visible specs
; - non-internal requests construct the nested ToolCall dispatch plan
; - dispatch results are reduced through the same success/error/log mapping as
;   Rust's match on dispatch_tool_call_with_code_mode_result
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust obtains ToolsConfig, MCP tools, dynamic tools, and resolved ToolInfo
;   from ExecContext/Session and awaits dispatch. This pure slice receives those
;   observations explicitly while preserving the control-flow order and returned
;   RunToolResult/log effects.

!(import! &self js_repl_run_tool_dispatch_result)
!(import! &self js_repl_run_tool_request)
!(import! &self js_repl_run_tool_router_plan)

(= (codex:js-repl-run-tool-request-flow-status-rejected-internal)
   CodexJsReplRunToolRequestFlowStatusRejectedInternal)

(= (codex:js-repl-run-tool-request-flow-status-dispatched)
   CodexJsReplRunToolRequestFlowStatusDispatched)

(= (codex:js-repl-run-tool-request-flow-context
      $tools-config
      $mcp-tools
      $dynamic-tools
      $specs
      $mcp-tool-infos)
   (CodexJsReplRunToolRequestFlowContext
     $tools-config
     $mcp-tools
     $dynamic-tools
     $specs
     $mcp-tool-infos))

(= (codex:js-repl-run-tool-request-flow-context-tools-config
      (CodexJsReplRunToolRequestFlowContext
        $tools-config
        $mcp-tools
        $dynamic-tools
        $specs
        $mcp-tool-infos))
   $tools-config)

(= (codex:js-repl-run-tool-request-flow-context-mcp-tools
      (CodexJsReplRunToolRequestFlowContext
        $tools-config
        $mcp-tools
        $dynamic-tools
        $specs
        $mcp-tool-infos))
   $mcp-tools)

(= (codex:js-repl-run-tool-request-flow-context-dynamic-tools
      (CodexJsReplRunToolRequestFlowContext
        $tools-config
        $mcp-tools
        $dynamic-tools
        $specs
        $mcp-tool-infos))
   $dynamic-tools)

(= (codex:js-repl-run-tool-request-flow-context-specs
      (CodexJsReplRunToolRequestFlowContext
        $tools-config
        $mcp-tools
        $dynamic-tools
        $specs
        $mcp-tool-infos))
   $specs)

(= (codex:js-repl-run-tool-request-flow-context-mcp-tool-infos
      (CodexJsReplRunToolRequestFlowContext
        $tools-config
        $mcp-tools
        $dynamic-tools
        $specs
        $mcp-tool-infos))
   $mcp-tool-infos)

(= (codex:js-repl-run-tool-request-flow-result
      $status
      $guard-step
      $router-plan
      $dispatch-plan
      $run-tool-result
      $actions)
   (CodexJsReplRunToolRequestFlowResult
     $status
     $guard-step
     $router-plan
     $dispatch-plan
     $run-tool-result
     $actions))

(= (codex:js-repl-run-tool-request-flow-result-status
      (CodexJsReplRunToolRequestFlowResult
        $status
        $guard-step
        $router-plan
        $dispatch-plan
        $run-tool-result
        $actions))
   $status)

(= (codex:js-repl-run-tool-request-flow-result-guard-step
      (CodexJsReplRunToolRequestFlowResult
        $status
        $guard-step
        $router-plan
        $dispatch-plan
        $run-tool-result
        $actions))
   $guard-step)

(= (codex:js-repl-run-tool-request-flow-result-router-plan
      (CodexJsReplRunToolRequestFlowResult
        $status
        $guard-step
        $router-plan
        $dispatch-plan
        $run-tool-result
        $actions))
   $router-plan)

(= (codex:js-repl-run-tool-request-flow-result-dispatch-plan
      (CodexJsReplRunToolRequestFlowResult
        $status
        $guard-step
        $router-plan
        $dispatch-plan
        $run-tool-result
        $actions))
   $dispatch-plan)

(= (codex:js-repl-run-tool-request-flow-result-run-tool-result
      (CodexJsReplRunToolRequestFlowResult
        $status
        $guard-step
        $router-plan
        $dispatch-plan
        $run-tool-result
        $actions))
   $run-tool-result)

(= (codex:js-repl-run-tool-request-flow-result-actions
      (CodexJsReplRunToolRequestFlowResult
        $status
        $guard-step
        $router-plan
        $dispatch-plan
        $run-tool-result
        $actions))
   $actions)

(= (codex:js-repl-run-tool-request-flow-internal-result
      $guard-step)
   (case $guard-step
     (((CodexJsReplRunToolRequestStepResult
         CodexJsReplRunToolRequestStatusRejectedInternal
         $run-tool-result
         $actions)
       (codex:js-repl-run-tool-request-flow-result
         (codex:js-repl-run-tool-request-flow-status-rejected-internal)
         $guard-step
         CodexAbsent
         CodexAbsent
         $run-tool-result
         $actions)))))

(= (codex:js-repl-run-tool-request-flow-dispatched-result
      $request
      $guard-step
      (CodexJsReplRunToolRequestFlowContext
        $tools-config
        $mcp-tools
        $dynamic-tools
        $specs
        $mcp-tool-infos)
      $dispatch-result)
   (let $router-plan
     (codex:js-repl-run-tool-router-plan
       $tools-config
       $mcp-tools
       $dynamic-tools
       $specs)
     (let $dispatch-plan
       (codex:js-repl-run-tool-request-dispatch-plan
         $request
         $specs
         $mcp-tool-infos)
       (let $dispatch-step
         (codex:js-repl-run-tool-dispatch-result-step
           $request
           $dispatch-result)
         (codex:js-repl-run-tool-request-flow-result
           (codex:js-repl-run-tool-request-flow-status-dispatched)
           $guard-step
           $router-plan
           $dispatch-plan
           (codex:js-repl-run-tool-dispatch-result-step-result-run-tool-result
             $dispatch-step)
           (codex:js-repl-run-tool-dispatch-result-step-result-actions
             $dispatch-step))))))

(= (codex:js-repl-run-tool-request-flow-step
      $request
      $context
      $dispatch-result)
   (let $guard-step
     (codex:js-repl-run-tool-request-guard-step $request)
     (case $guard-step
       (((CodexJsReplRunToolRequestStepResult
           CodexJsReplRunToolRequestStatusRejectedInternal
           $run-tool-result
           $actions)
         (codex:js-repl-run-tool-request-flow-internal-result
           $guard-step))
        ((CodexJsReplRunToolRequestStepResult
           CodexJsReplRunToolRequestStatusContinue
           CodexAbsent
           ())
         (codex:js-repl-run-tool-request-flow-dispatched-result
           $request
           $guard-step
           $context
           $dispatch-result))))))
