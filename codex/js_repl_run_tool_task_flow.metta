; Rust-faithful js_repl RunTool spawned-task/request-flow integration slice.
;
; This ports the composition point from:
; - openai-codex/codex-rs/core/src/tools/js_repl/mod.rs
;   - the spawned task in the `KernelToHost::RunTool(req)` read_stdout arm
;   - the `tokio::select!` branch that awaits run_tool_request(ctx, req)
;
; Covered in this increment:
; - a request-flow observation at the spawned-task select boundary
; - run_tool_request flow actions emitted before finish_exec_tool_call
; - unchanged reset-cancelled and missing-context result behavior
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust stores an ExecContext in the exec_contexts map and runs an async
;   future. This pure wrapper stores the already-materialized
;   RequestFlowContext as that context and receives the dispatch observation at
;   the async boundary.

!(import! &self js_repl_run_tool_request_flow)
!(import! &self js_repl_stdout_run_tool_task)
!(import! &self list)

(= (codex:js-repl-run-tool-task-observation-run-request-flow
      $dispatch-result)
   (CodexJsReplRunToolTaskObservationRunRequestFlow $dispatch-result))

(= (codex:js-repl-run-tool-task-selected-run
      $run-tool-result
      $actions)
   (CodexJsReplRunToolTaskSelectedRun $run-tool-result $actions))

(= (codex:js-repl-run-tool-task-selected-run-result
      (CodexJsReplRunToolTaskSelectedRun $run-tool-result $actions))
   $run-tool-result)

(= (codex:js-repl-run-tool-task-selected-run-actions
      (CodexJsReplRunToolTaskSelectedRun $run-tool-result $actions))
   $actions)

(= (codex:js-repl-run-tool-task-selected-run-from-found-context
      $request
      $flow-context
      CodexJsReplRunToolTaskObservationResetCancelled)
   (case $request
     (((CodexJsReplKernelToHostRunTool $id $exec-id $tool-name $arguments)
       (codex:js-repl-run-tool-task-selected-run
         (codex:js-repl-run-tool-task-reset-result $id)
         ())))))

(= (codex:js-repl-run-tool-task-selected-run-from-found-context
      $request
      $flow-context
      (CodexJsReplRunToolTaskObservationRunCompleted $result))
   (codex:js-repl-run-tool-task-selected-run $result ()))

(= (codex:js-repl-run-tool-task-selected-run-from-found-context
      $request
      $flow-context
      (CodexJsReplRunToolTaskObservationRunRequestFlow $dispatch-result))
   (let $flow-result
     (codex:js-repl-run-tool-request-flow-step
       $request
       $flow-context
       $dispatch-result)
     (codex:js-repl-run-tool-task-selected-run
       (codex:js-repl-run-tool-request-flow-result-run-tool-result
         $flow-result)
       (codex:js-repl-run-tool-request-flow-result-actions
         $flow-result))))

(= (codex:js-repl-run-tool-task-select-run-with-request-flow
      (CodexJsReplKernelToHostRunTool $id $exec-id $tool-name $arguments)
      $exec-contexts
      $observation)
   (case (codex:js-repl-run-tool-contexts-find
           $exec-contexts
           $exec-id)
     ((CodexJsReplRunToolContextLookupMissing
       (codex:js-repl-run-tool-task-selected-run
         (codex:js-repl-run-tool-task-missing-context-result $id)
         ()))
      ((CodexJsReplRunToolContextLookupFound $flow-context)
       (codex:js-repl-run-tool-task-selected-run-from-found-context
         (CodexJsReplKernelToHostRunTool $id $exec-id $tool-name $arguments)
         $flow-context
         $observation)))))

(= (codex:js-repl-run-tool-task-step-with-request-flow
      $request
      $exec-contexts
      $exec-tool-calls
      $observation
      $stdin
      $body-write-result
      $newline-write-result
      $recent-stderr)
   (case $request
     (((CodexJsReplKernelToHostRunTool $id $exec-id $tool-name $arguments)
       (let $selected-run
         (codex:js-repl-run-tool-task-select-run-with-request-flow
           $request
           $exec-contexts
           $observation)
         (let $run-tool-result
           (codex:js-repl-run-tool-task-selected-run-result
             $selected-run)
           (case $exec-tool-calls
             (($materialized-exec-tool-calls
               (let $finish-result
                 (codex:js-repl-run-tool-task-finish-exec-tool-call-map
                   $materialized-exec-tool-calls
                   $exec-id)
                 (let $response
                   (codex:js-repl-host-to-kernel-run-tool-result
                     $run-tool-result)
                   (let $write-result
                     (codex:js-repl-write-message
                       $stdin
                       $response
                       $body-write-result
                       $newline-write-result)
                     (CodexJsReplRunToolTaskResult
                       (codex:js-repl-finish-exec-tool-call-result-map
                         $finish-result)
                       $run-tool-result
                       $response
                       $write-result
                       (list:append
                         (codex:js-repl-run-tool-task-selected-run-actions
                           $selected-run)
                         (list:append
                           (codex:js-repl-finish-exec-tool-call-result-actions
                             $finish-result)
                           ((codex:js-repl-read-stdout-run-tool-action-write-message
                              $response
                              $write-result))))
                       (codex:js-repl-run-tool-task-write-warnings
                         $write-result
                         $exec-id
                         $id
                         $tool-name
                         $recent-stderr))))))))))))))
