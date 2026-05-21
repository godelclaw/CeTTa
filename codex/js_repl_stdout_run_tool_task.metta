; Rust-faithful js_repl read_stdout RunTool spawned-task slice.
;
; This ports deterministic helper behavior from:
; - openai-codex/codex-rs/core/src/tools/js_repl/mod.rs
;   - the async task spawned by the `KernelToHost::RunTool(req)` arm in
;     `read_stdout`, excluding the nested `run_tool_request` dispatcher body
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust looks up `ExecContext`, races `reset_cancel.cancelled()` against
;   `run_tool_request`, finishes the nested call, writes the result to stdin,
;   and warns with only the stderr tail on write failure. This pure slice
;   receives the reset-vs-run observation at the async select boundary and
;   returns immutable state plus explicit actions/warnings in the same order.
; - Rust carries full `ExecContext` values. This slice stores opaque context
;   values because the wrapper only needs to distinguish Some from None; the
;   actual `run_tool_request` context consumption belongs to a later slice.

!(import! &self function_tool)
!(import! &self js_repl_exec_tool_calls)
!(import! &self js_repl_kernel_io)
!(import! &self js_repl_run_tool_common)
!(import! &self list)

(= (codex:js-repl-run-tool-exec-context-entry $exec-id $context)
   (CodexJsReplRunToolExecContextEntry $exec-id $context))

(= (codex:js-repl-run-tool-exec-context-entry-exec-id
      (CodexJsReplRunToolExecContextEntry $exec-id $context))
   $exec-id)

(= (codex:js-repl-run-tool-exec-context-entry-context
      (CodexJsReplRunToolExecContextEntry $exec-id $context))
   $context)

(= (codex:js-repl-run-tool-exec-contexts $entries)
   (CodexJsReplRunToolExecContexts $entries))

(= (codex:js-repl-run-tool-exec-contexts-entries
      (CodexJsReplRunToolExecContexts $entries))
   $entries)

(= (codex:js-repl-run-tool-context-lookup-missing)
   CodexJsReplRunToolContextLookupMissing)

(= (codex:js-repl-run-tool-context-lookup-found $context)
   (CodexJsReplRunToolContextLookupFound $context))

(= (codex:js-repl-run-tool-context-lookup-value
      CodexJsReplRunToolContextLookupMissing)
   CodexAbsent)

(= (codex:js-repl-run-tool-context-lookup-value
      (CodexJsReplRunToolContextLookupFound $context))
   $context)

(= (codex:js-repl-run-tool-find-context-entry () $exec-id)
   CodexJsReplRunToolContextLookupMissing)

(= (codex:js-repl-run-tool-find-context-entry $entries $exec-id)
   (let $entry (list:first $entries)
     (if (== (codex:js-repl-run-tool-exec-context-entry-exec-id $entry)
             $exec-id)
         (CodexJsReplRunToolContextLookupFound
           (codex:js-repl-run-tool-exec-context-entry-context $entry))
         (codex:js-repl-run-tool-find-context-entry
           (list:rest $entries)
           $exec-id))))

(= (codex:js-repl-run-tool-contexts-find
      (CodexJsReplRunToolExecContexts $entries)
      $exec-id)
   (codex:js-repl-run-tool-find-context-entry $entries $exec-id))

(= (codex:js-repl-run-tool-task-observation-reset-cancelled)
   CodexJsReplRunToolTaskObservationResetCancelled)

(= (codex:js-repl-run-tool-task-observation-run-completed $result)
   (CodexJsReplRunToolTaskObservationRunCompleted $result))

(= (codex:js-repl-run-tool-task-reset-result $tool-call-id)
   (codex:js-repl-run-tool-result
     $tool-call-id
     False
     CodexAbsent
     "js_repl execution reset"))

(= (codex:js-repl-run-tool-task-missing-context-result $tool-call-id)
   (codex:js-repl-run-tool-result
     $tool-call-id
     False
     CodexAbsent
     (codex:js-repl-run-tool-context-missing-message)))

(= (codex:js-repl-run-tool-task-context-result
      $tool-call-id
      CodexJsReplRunToolTaskObservationResetCancelled)
   (codex:js-repl-run-tool-task-reset-result $tool-call-id))

(= (codex:js-repl-run-tool-task-context-result
      $tool-call-id
      (CodexJsReplRunToolTaskObservationRunCompleted $result))
   $result)

(= (codex:js-repl-run-tool-task-select-result
      (CodexJsReplKernelToHostRunTool $id $exec-id $tool-name $arguments)
      $exec-contexts
      $observation)
   (case (codex:js-repl-run-tool-contexts-find
           $exec-contexts
           $exec-id)
     ((CodexJsReplRunToolContextLookupMissing
       (codex:js-repl-run-tool-task-missing-context-result $id))
      ((CodexJsReplRunToolContextLookupFound $context)
       (codex:js-repl-run-tool-task-context-result
         $id
         $observation)))))

(= (codex:js-repl-run-tool-task-warning-write-failed
      $exec-id
      $tool-call-id
      $tool-name
      $error
      $stderr-tail)
   (CodexJsReplRunToolTaskWarningWriteFailed
     (codex:js-repl-read-stdout-run-tool-warning-message)
     $exec-id
     $tool-call-id
     $tool-name
     $error
     $stderr-tail))

(= (codex:js-repl-run-tool-task-write-warnings
      (CodexJsReplWriteMessageOk $writes)
      $exec-id
      $tool-call-id
      $tool-name
      $recent-stderr)
   ())

(= (codex:js-repl-run-tool-task-write-warnings
      (CodexJsReplWriteMessageError $error $writes)
      $exec-id
      $tool-call-id
      $tool-name
      $recent-stderr)
   ((codex:js-repl-run-tool-task-warning-write-failed
      $exec-id
      $tool-call-id
      $tool-name
      (codex:function-call-error-display $error)
      (codex:js-repl-kernel-stderr-tail-snapshot $recent-stderr))))

(= (codex:js-repl-run-tool-task-finish-exec-tool-call-from-lookup
      $map
      $exec-id
      CodexJsReplExecToolCallsLookupMissing)
   (codex:js-repl-finish-exec-tool-call-result $map ()))

(= (codex:js-repl-run-tool-task-finish-exec-tool-call-from-lookup
      $map
      $exec-id
      (CodexJsReplExecToolCallsLookupFound
        (CodexJsReplExecToolCallsState
          $in-flight $content-items $notify $cancel)))
   (if (== $in-flight 0)
       (codex:js-repl-finish-exec-tool-call-result $map ())
       (let $next-in-flight (- $in-flight 1)
         (codex:js-repl-finish-exec-tool-call-result
           (codex:js-repl-exec-tool-calls-map-upsert
             $map
             $exec-id
             (CodexJsReplExecToolCallsState
               $next-in-flight
               $content-items
               $notify
               $cancel))
           (if (== $next-in-flight 0)
               ((codex:js-repl-exec-tool-call-action-notify-waiters
                  $notify))
               ())))))

(= (codex:js-repl-run-tool-task-finish-exec-tool-call-map $map $exec-id)
   (let $lookup
     (codex:js-repl-exec-tool-calls-map-find $map $exec-id)
     (case $lookup
       ((CodexJsReplExecToolCallsLookupMissing
         (codex:js-repl-run-tool-task-finish-exec-tool-call-from-lookup
           $map
           $exec-id
           CodexJsReplExecToolCallsLookupMissing))
        ((CodexJsReplExecToolCallsLookupFound $state)
         (codex:js-repl-run-tool-task-finish-exec-tool-call-from-lookup
           $map
           $exec-id
           (CodexJsReplExecToolCallsLookupFound $state)))))))

(= (codex:js-repl-run-tool-task-result
      $exec-tool-calls
      $run-tool-result
      $response
      $write-result
      $actions
      $warnings)
   (CodexJsReplRunToolTaskResult
     $exec-tool-calls
     $run-tool-result
     $response
     $write-result
     $actions
     $warnings))

(= (codex:js-repl-run-tool-task-result-exec-tool-calls
      $result)
   (case $result
     (((CodexJsReplRunToolTaskResult
         $exec-tool-calls $run-tool-result $response $write-result
         $actions $warnings)
       $exec-tool-calls))))

(= (codex:js-repl-run-tool-task-result-run-tool-result
      $result)
   (case $result
     (((CodexJsReplRunToolTaskResult
         $exec-tool-calls $run-tool-result $response $write-result
         $actions $warnings)
       $run-tool-result))))

(= (codex:js-repl-run-tool-task-result-response
      $result)
   (case $result
     (((CodexJsReplRunToolTaskResult
         $exec-tool-calls $run-tool-result $response $write-result
         $actions $warnings)
       $response))))

(= (codex:js-repl-run-tool-task-result-write-result
      $result)
   (case $result
     (((CodexJsReplRunToolTaskResult
         $exec-tool-calls $run-tool-result $response $write-result
         $actions $warnings)
       $write-result))))

(= (codex:js-repl-run-tool-task-result-actions
      $result)
   (case $result
     (((CodexJsReplRunToolTaskResult
         $exec-tool-calls $run-tool-result $response $write-result
         $actions $warnings)
       $actions))))

(= (codex:js-repl-run-tool-task-result-warnings
      $result)
   (case $result
     (((CodexJsReplRunToolTaskResult
         $exec-tool-calls $run-tool-result $response $write-result
         $actions $warnings)
       $warnings))))

(= (codex:js-repl-run-tool-task-step
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
       (let $run-tool-result
         (codex:js-repl-run-tool-task-select-result
           $request
           $exec-contexts
           $observation)
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
                       (codex:js-repl-finish-exec-tool-call-result-actions
                         $finish-result)
                       ((codex:js-repl-read-stdout-run-tool-action-write-message
                          $response
                          $write-result)))
                     (codex:js-repl-run-tool-task-write-warnings
                       $write-result
                       $exec-id
                       $id
                       $tool-name
                       $recent-stderr)))))))))))))
