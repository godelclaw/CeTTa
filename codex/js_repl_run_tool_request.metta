; Rust-faithful js_repl run_tool_request guard slice.
;
; This ports deterministic helper behavior from:
; - openai-codex/codex-rs/core/src/tools/js_repl/mod.rs
;   - the initial `is_js_repl_internal_tool` branch in `run_tool_request`
;   - the associated `summarize_tool_call_error` and `log_tool_call_response`
;     effects for that branch
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust logs through tracing `info!` and optional `trace!` calls. This pure
;   slice returns a symbolic log action that carries the same request identity,
;   ok flag, summary, optional response JSON, and optional error string.
; - Rust continues into router construction for non-internal tools. This guard
;   slice returns an explicit continue status with no result so the later router
;   slice can attach without changing the branch order.

!(import! &self js_repl_kernel_io)
!(import! &self js_repl_run_tool_common)

(= (codex:js-repl-run-tool-request-internal-error)
   "js_repl cannot invoke itself")

(= (codex:js-repl-run-tool-request-status-rejected-internal)
   CodexJsReplRunToolRequestStatusRejectedInternal)

(= (codex:js-repl-run-tool-request-status-continue)
   CodexJsReplRunToolRequestStatusContinue)

(= (codex:js-repl-run-tool-request-log-message)
   "js_repl nested tool call completed")

(= (codex:js-repl-run-tool-request-action-log-tool-call-response
      $request
      $ok
      $summary
      $response
      $error)
   (case $request
     (((CodexJsReplKernelToHostRunTool $id $exec-id $tool-name $arguments)
       (CodexJsReplRunToolRequestActionLogToolCallResponse
         (codex:js-repl-run-tool-request-log-message)
         $exec-id
         $id
         $tool-name
         $ok
         $summary
         $response
         $error)))))

(= (codex:js-repl-run-tool-request-step-result
      $status
      $run-tool-result
      $actions)
   (CodexJsReplRunToolRequestStepResult
     $status
     $run-tool-result
     $actions))

(= (codex:js-repl-run-tool-request-step-result-status
      (CodexJsReplRunToolRequestStepResult
        $status $run-tool-result $actions))
   $status)

(= (codex:js-repl-run-tool-request-step-result-run-tool-result
      (CodexJsReplRunToolRequestStepResult
        $status $run-tool-result $actions))
   $run-tool-result)

(= (codex:js-repl-run-tool-request-step-result-actions
      (CodexJsReplRunToolRequestStepResult
        $status $run-tool-result $actions))
   $actions)

(= (codex:js-repl-run-tool-request-internal-reject-step
      (CodexJsReplKernelToHostRunTool $id $exec-id $tool-name $arguments))
   (let $error (codex:js-repl-run-tool-request-internal-error)
     (let $summary (codex:js-repl-summarize-tool-call-error $error)
       (CodexJsReplRunToolRequestStepResult
         CodexJsReplRunToolRequestStatusRejectedInternal
         (codex:js-repl-run-tool-result
           $id
           False
           CodexAbsent
           $error)
         ((codex:js-repl-run-tool-request-action-log-tool-call-response
            (CodexJsReplKernelToHostRunTool $id $exec-id $tool-name $arguments)
            False
            $summary
            CodexAbsent
            $error))))))

(= (codex:js-repl-run-tool-request-continue-step)
   (CodexJsReplRunToolRequestStepResult
     CodexJsReplRunToolRequestStatusContinue
     CodexAbsent
     ()))

(= (codex:js-repl-run-tool-request-guard-step $request)
   (case $request
     (((CodexJsReplKernelToHostRunTool $id $exec-id $tool-name $arguments)
       (if (codex:is-js-repl-internal-tool $tool-name)
           (codex:js-repl-run-tool-request-internal-reject-step
             $request)
           (codex:js-repl-run-tool-request-continue-step))))))
