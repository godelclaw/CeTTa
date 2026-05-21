; Rust-faithful js_repl read_stdout ExecResult branch slice.
;
; This ports deterministic helper behavior from:
; - openai-codex/codex-rs/core/src/tools/js_repl/mod.rs
;   - the `KernelToHost::ExecResult { .. }` arm in `read_stdout`
;   - `ExecResultMessage`
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust awaits `wait_for_exec_tool_calls_map` before mutating pending execs,
;   contexts, top-level exec state, and nested tool-call maps. This pure slice
;   returns an explicit wait action when nested tool calls are still in flight;
;   callers re-enter with the settled map to apply the same Rust mutations.
; - Rust sends through a concrete oneshot sender and ignores send failure. This
;   slice returns a symbolic send action and preserves the same state changes.

!(import! &self js_repl)
!(import! &self js_repl_exec_tool_calls)
!(import! &self list)

(= (codex:js-repl-kernel-to-host-exec-result
      $id
      $ok
      $output
      $error)
   (CodexJsReplKernelToHostExecResult $id $ok $output $error))

(= (codex:js-repl-exec-result-message-ok $content-items)
   (CodexJsReplExecResultMessageOk $content-items))

(= (codex:js-repl-exec-result-message-err $message)
   (CodexJsReplExecResultMessageErr $message))

(= (codex:js-repl-exec-result-error-or-default $message)
   (case $message
     ((CodexAbsent "js_repl execution failed")
      ($value $value))))

(= (codex:js-repl-read-stdout-manager-kernel $top-level-exec-state)
   (CodexJsReplReadStdoutManagerKernel $top-level-exec-state))

(= (codex:js-repl-read-stdout-manager-kernel-top-level-exec-state
      (CodexJsReplReadStdoutManagerKernel $top-level-exec-state))
   $top-level-exec-state)

(= (codex:js-repl-read-stdout-manager-kernel-clear-exec-if-matches
      CodexAbsent
      $exec-id)
   CodexAbsent)

(= (codex:js-repl-read-stdout-manager-kernel-clear-exec-if-matches
      (CodexJsReplReadStdoutManagerKernel $top-level-exec-state)
      $exec-id)
   (CodexJsReplReadStdoutManagerKernel
     (codex:js-repl-clear-top-level-exec-if-matches-state
       $top-level-exec-state
       $exec-id)))

(= (codex:js-repl-pending-exec-entry $exec-id $sender)
   (CodexJsReplPendingExecEntry $exec-id $sender))

(= (codex:js-repl-pending-exec-entry-exec-id
      (CodexJsReplPendingExecEntry $exec-id $sender))
   $exec-id)

(= (codex:js-repl-pending-exec-entry-sender
      (CodexJsReplPendingExecEntry $exec-id $sender))
   $sender)

(= (codex:js-repl-read-stdout-pending-execs $entries)
   (CodexJsReplReadStdoutPendingExecs $entries))

(= (codex:js-repl-read-stdout-pending-execs-entries
      (CodexJsReplReadStdoutPendingExecs $entries))
   $entries)

(= (codex:js-repl-pending-execs-remove-missing $entries)
   (CodexJsReplPendingExecsRemoveMissing $entries))

(= (codex:js-repl-pending-execs-remove-found $sender $entries)
   (CodexJsReplPendingExecsRemoveFound $sender $entries))

(= (codex:js-repl-pending-execs-remove-result-sender
      (CodexJsReplPendingExecsRemoveMissing $entries))
   CodexAbsent)

(= (codex:js-repl-pending-execs-remove-result-sender
      (CodexJsReplPendingExecsRemoveFound $sender $entries))
   $sender)

(= (codex:js-repl-pending-execs-remove-result-entries
      (CodexJsReplPendingExecsRemoveMissing $entries))
   $entries)

(= (codex:js-repl-pending-execs-remove-result-entries
      (CodexJsReplPendingExecsRemoveFound $sender $entries))
   $entries)

(= (codex:js-repl-pending-execs-remove-entry
      ()
      $exec-id)
   (CodexJsReplPendingExecsRemoveMissing ()))

(= (codex:js-repl-pending-execs-remove-entry
      $entries
      $exec-id)
   (let $entry (list:first $entries)
     (let $tail (list:rest $entries)
       (if (== (codex:js-repl-pending-exec-entry-exec-id $entry)
               $exec-id)
           (CodexJsReplPendingExecsRemoveFound
             (codex:js-repl-pending-exec-entry-sender $entry)
             $tail)
           (case (codex:js-repl-pending-execs-remove-entry
                   $tail
                   $exec-id)
             (((CodexJsReplPendingExecsRemoveMissing $next-entries)
               (CodexJsReplPendingExecsRemoveMissing
                 (list:append ($entry) $next-entries)))
              ((CodexJsReplPendingExecsRemoveFound $sender $next-entries)
               (CodexJsReplPendingExecsRemoveFound
                 $sender
                 (list:append ($entry) $next-entries)))))))))

(= (codex:js-repl-read-stdout-pending-execs-remove
      (CodexJsReplReadStdoutPendingExecs $entries)
      $exec-id)
   (case (codex:js-repl-pending-execs-remove-entry $entries $exec-id)
     (((CodexJsReplPendingExecsRemoveMissing $next-entries)
       (CodexJsReplPendingExecsRemoveMissing
         (CodexJsReplReadStdoutPendingExecs $next-entries)))
      ((CodexJsReplPendingExecsRemoveFound $sender $next-entries)
       (CodexJsReplPendingExecsRemoveFound
         $sender
         (CodexJsReplReadStdoutPendingExecs $next-entries))))))

(= (codex:js-repl-exec-context-entry $exec-id $context)
   (CodexJsReplExecContextEntry $exec-id $context))

(= (codex:js-repl-exec-context-entry-exec-id
      (CodexJsReplExecContextEntry $exec-id $context))
   $exec-id)

(= (codex:js-repl-read-stdout-exec-contexts $entries)
   (CodexJsReplReadStdoutExecContexts $entries))

(= (codex:js-repl-read-stdout-exec-contexts-entries
      (CodexJsReplReadStdoutExecContexts $entries))
   $entries)

(= (codex:js-repl-exec-contexts-remove-entry
      ()
      $exec-id)
   ())

(= (codex:js-repl-exec-contexts-remove-entry
      $entries
      $exec-id)
   (let $entry (list:first $entries)
     (let $tail (list:rest $entries)
       (if (== (codex:js-repl-exec-context-entry-exec-id $entry)
               $exec-id)
           $tail
           (list:append
             ($entry)
             (codex:js-repl-exec-contexts-remove-entry
               $tail
               $exec-id))))))

(= (codex:js-repl-read-stdout-exec-contexts-remove
      (CodexJsReplReadStdoutExecContexts $entries)
      $exec-id)
   (CodexJsReplReadStdoutExecContexts
     (codex:js-repl-exec-contexts-remove-entry
       $entries
       $exec-id)))

(= (codex:js-repl-read-stdout-exec-result-content-items $exec-tool-calls $exec-id)
   (case (codex:js-repl-exec-tool-calls-map-find-state
           $exec-tool-calls
           $exec-id)
     ((CodexAbsent ())
      ((CodexJsReplExecToolCallsState
         $in-flight $content-items $notify $cancel)
       $content-items))))

(= (codex:js-repl-read-stdout-exec-result-message
      True
      $output
      $error
      $content-items)
   (codex:js-repl-exec-result-message-ok
     (codex:js-repl-build-exec-result-content-items
       $output
       $content-items)))

(= (codex:js-repl-read-stdout-exec-result-message
      False
      $output
      $error
      $content-items)
   (codex:js-repl-exec-result-message-err
     (codex:js-repl-exec-result-error-or-default $error)))

(= (codex:js-repl-read-stdout-action-wait-for-exec-tool-calls
      $exec-id
      $wait-result)
   (CodexJsReplReadStdoutActionWaitForExecToolCalls
     $exec-id
     $wait-result))

(= (codex:js-repl-read-stdout-action-send-exec-result
      $sender
      $message)
   (CodexJsReplReadStdoutActionSendExecResult $sender $message))

(= (codex:js-repl-read-stdout-exec-result-status-waiting)
   CodexJsReplReadStdoutExecResultStatusWaiting)

(= (codex:js-repl-read-stdout-exec-result-status-applied)
   CodexJsReplReadStdoutExecResultStatusApplied)

(= (codex:js-repl-read-stdout-exec-result-step-result
      $status
      $manager-kernel
      $pending-execs
      $exec-contexts
      $exec-tool-calls
      $actions)
   (CodexJsReplReadStdoutExecResultStepResult
     $status
     $manager-kernel
     $pending-execs
     $exec-contexts
     $exec-tool-calls
     $actions))

(= (codex:js-repl-read-stdout-exec-result-step-result-status
      (CodexJsReplReadStdoutExecResultStepResult
        $status $manager-kernel $pending-execs $exec-contexts
        $exec-tool-calls $actions))
   $status)

(= (codex:js-repl-read-stdout-exec-result-step-result-manager-kernel
      (CodexJsReplReadStdoutExecResultStepResult
        $status $manager-kernel $pending-execs $exec-contexts
        $exec-tool-calls $actions))
   $manager-kernel)

(= (codex:js-repl-read-stdout-exec-result-step-result-pending-execs
      (CodexJsReplReadStdoutExecResultStepResult
        $status $manager-kernel $pending-execs $exec-contexts
        $exec-tool-calls $actions))
   $pending-execs)

(= (codex:js-repl-read-stdout-exec-result-step-result-exec-contexts
      (CodexJsReplReadStdoutExecResultStepResult
        $status $manager-kernel $pending-execs $exec-contexts
        $exec-tool-calls $actions))
   $exec-contexts)

(= (codex:js-repl-read-stdout-exec-result-step-result-exec-tool-calls
      (CodexJsReplReadStdoutExecResultStepResult
        $status $manager-kernel $pending-execs $exec-contexts
        $exec-tool-calls $actions))
   $exec-tool-calls)

(= (codex:js-repl-read-stdout-exec-result-step-result-actions
      (CodexJsReplReadStdoutExecResultStepResult
        $status $manager-kernel $pending-execs $exec-contexts
        $exec-tool-calls $actions))
   $actions)

(= (codex:js-repl-read-stdout-exec-result-send-actions
      $sender
      $message)
   (case $sender
     ((CodexAbsent ())
      ($value
       ((codex:js-repl-read-stdout-action-send-exec-result
          $value
          $message))))))

(= (codex:js-repl-read-stdout-exec-result-clear-manager
      $manager-kernel
      $exec-id
      $sender)
   (case $sender
     ((CodexAbsent $manager-kernel)
      ($value
       (codex:js-repl-read-stdout-manager-kernel-clear-exec-if-matches
         $manager-kernel
         $exec-id)))))

(= (codex:js-repl-read-stdout-exec-result-step-after-wait
      (CodexJsReplKernelToHostExecResult $id $ok $output $error)
      $manager-kernel
      $pending-execs
      $exec-contexts
      $exec-tool-calls
      $wait-action)
   (let $content-items
     (codex:js-repl-read-stdout-exec-result-content-items
       $exec-tool-calls
       $id)
     (let $pending-remove
       (codex:js-repl-read-stdout-pending-execs-remove
         $pending-execs
         $id)
       (let $sender
         (codex:js-repl-pending-execs-remove-result-sender
           $pending-remove)
         (let $message
           (codex:js-repl-read-stdout-exec-result-message
             $ok
             $output
             $error
             $content-items)
           (let $clear-result
             (codex:js-repl-clear-exec-tool-calls-map
               $exec-tool-calls
               $id)
             (CodexJsReplReadStdoutExecResultStepResult
               CodexJsReplReadStdoutExecResultStatusApplied
               (codex:js-repl-read-stdout-exec-result-clear-manager
                 $manager-kernel
                 $id
                 $sender)
               (codex:js-repl-pending-execs-remove-result-entries
                 $pending-remove)
               (codex:js-repl-read-stdout-exec-contexts-remove
                 $exec-contexts
                 $id)
               (codex:js-repl-clear-exec-tool-calls-result-map
                 $clear-result)
               (list:append
                 ($wait-action)
                 (list:append
                   (codex:js-repl-read-stdout-exec-result-send-actions
                     $sender
                     $message)
                   (codex:js-repl-clear-exec-tool-calls-result-actions
                     $clear-result))))))))))

(= (codex:js-repl-read-stdout-exec-result-step
      $message
      $manager-kernel
      $pending-execs
      $exec-contexts
      $exec-tool-calls)
   (case $message
     (((CodexJsReplKernelToHostExecResult $id $ok $output $error)
       (let $wait-result
         (codex:js-repl-wait-for-exec-tool-calls-map-step
           $exec-tool-calls
           $id)
         (let $wait-action
           (codex:js-repl-read-stdout-action-wait-for-exec-tool-calls
             $id
             $wait-result)
           (case $wait-result
             (((CodexJsReplWaitExecToolCallsWait $notify)
               (CodexJsReplReadStdoutExecResultStepResult
                 CodexJsReplReadStdoutExecResultStatusWaiting
                 $manager-kernel
                 $pending-execs
                 $exec-contexts
                 $exec-tool-calls
                 ($wait-action)))
              (CodexJsReplWaitExecToolCallsComplete
               (codex:js-repl-read-stdout-exec-result-step-after-wait
                 $message
                 $manager-kernel
                 $pending-execs
                 $exec-contexts
                 $exec-tool-calls
                 $wait-action))))))))))
