; Rust-faithful js_repl nested tool-call bookkeeping slice.
;
; This ports deterministic helper behavior from:
; - openai-codex/codex-rs/core/src/tools/js_repl/mod.rs
;   - `ExecToolCalls`
;   - `register_exec_tool_calls`
;   - `clear_exec_tool_calls_map`
;   - `clear_all_exec_tool_calls_map`
;   - `wait_for_exec_tool_calls_map` readiness check
;   - `begin_exec_tool_call`
;   - `record_exec_content_item`
;   - `finish_exec_tool_call`
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust stores `ExecToolCalls` in an `Arc<Mutex<HashMap<...>>>` and uses
;   concrete `Notify` and `CancellationToken` values. This pure slice receives
;   symbolic notify/cancel values and returns immutable map states plus explicit
;   cancel/notify side-effect actions in the same branch order.
; - Rust drains a `HashMap` in implementation-defined iteration order. This
;   slice stores entries in a list and emits clear-all actions in list order;
;   callers must not rely on clear-all ordering, matching Rust's visible API.

!(import! &self js_repl)
!(import! &self list)

(= (codex:js-repl-exec-tool-calls-state
      $in-flight
      $content-items
      $notify
      $cancel)
   (CodexJsReplExecToolCallsState
     $in-flight
     $content-items
     $notify
     $cancel))

(= (codex:js-repl-exec-tool-calls-default $notify $cancel)
   (codex:js-repl-exec-tool-calls-state
     0
     ()
     $notify
     $cancel))

(= (codex:js-repl-exec-tool-calls-state-in-flight
      (CodexJsReplExecToolCallsState
        $in-flight $content-items $notify $cancel))
   $in-flight)

(= (codex:js-repl-exec-tool-calls-state-content-items
      (CodexJsReplExecToolCallsState
        $in-flight $content-items $notify $cancel))
   $content-items)

(= (codex:js-repl-exec-tool-calls-state-notify
      (CodexJsReplExecToolCallsState
        $in-flight $content-items $notify $cancel))
   $notify)

(= (codex:js-repl-exec-tool-calls-state-cancel
      (CodexJsReplExecToolCallsState
        $in-flight $content-items $notify $cancel))
   $cancel)

(= (codex:js-repl-exec-tool-calls-entry $exec-id $state)
   (CodexJsReplExecToolCallsEntry $exec-id $state))

(= (codex:js-repl-exec-tool-calls-entry-exec-id
      (CodexJsReplExecToolCallsEntry $exec-id $state))
   $exec-id)

(= (codex:js-repl-exec-tool-calls-entry-state
      (CodexJsReplExecToolCallsEntry $exec-id $state))
   $state)

(= (codex:js-repl-exec-tool-calls-map $entries)
   (CodexJsReplExecToolCallsMap $entries))

(= (codex:js-repl-exec-tool-calls-map-entries
      (CodexJsReplExecToolCallsMap $entries))
   $entries)

(= (codex:js-repl-exec-tool-calls-map-empty)
   (codex:js-repl-exec-tool-calls-map ()))

(= (codex:js-repl-exec-tool-calls-lookup-missing)
   CodexJsReplExecToolCallsLookupMissing)

(= (codex:js-repl-exec-tool-calls-lookup-found $state)
   (CodexJsReplExecToolCallsLookupFound $state))

(= (codex:js-repl-exec-tool-calls-lookup-state
      CodexJsReplExecToolCallsLookupMissing)
   CodexAbsent)

(= (codex:js-repl-exec-tool-calls-lookup-state
      (CodexJsReplExecToolCallsLookupFound $state))
   $state)

(= (codex:js-repl-exec-tool-calls-find-entry
      ()
      $exec-id)
   CodexJsReplExecToolCallsLookupMissing)

(= (codex:js-repl-exec-tool-calls-find-entry
      $entries
      $exec-id)
   (let $entry (list:first $entries)
     (if (== (codex:js-repl-exec-tool-calls-entry-exec-id $entry)
             $exec-id)
         (CodexJsReplExecToolCallsLookupFound
           (codex:js-repl-exec-tool-calls-entry-state $entry))
         (codex:js-repl-exec-tool-calls-find-entry
           (list:rest $entries)
           $exec-id))))

(= (codex:js-repl-exec-tool-calls-map-find
      (CodexJsReplExecToolCallsMap $entries)
      $exec-id)
   (codex:js-repl-exec-tool-calls-find-entry
     $entries
     $exec-id))

(= (codex:js-repl-exec-tool-calls-map-find-state
      $map
      $exec-id)
   (codex:js-repl-exec-tool-calls-lookup-state
     (codex:js-repl-exec-tool-calls-map-find $map $exec-id)))

(= (codex:js-repl-exec-tool-calls-upsert-entry
      ()
      $exec-id
      $state)
   ((codex:js-repl-exec-tool-calls-entry $exec-id $state)))

(= (codex:js-repl-exec-tool-calls-upsert-entry
      $entries
      $exec-id
      $state)
   (let $entry (list:first $entries)
     (let $tail (list:rest $entries)
       (if (== (codex:js-repl-exec-tool-calls-entry-exec-id $entry)
               $exec-id)
           (list:append
             ((codex:js-repl-exec-tool-calls-entry $exec-id $state))
             $tail)
           (list:append
             ($entry)
             (codex:js-repl-exec-tool-calls-upsert-entry
               $tail
               $exec-id
               $state))))))

(= (codex:js-repl-exec-tool-calls-map-upsert
      (CodexJsReplExecToolCallsMap $entries)
      $exec-id
      $state)
   (CodexJsReplExecToolCallsMap
     (codex:js-repl-exec-tool-calls-upsert-entry
       $entries
       $exec-id
       $state)))

(= (codex:js-repl-register-exec-tool-calls-map
      $map
      $exec-id
      $notify
      $cancel)
   (codex:js-repl-exec-tool-calls-map-upsert
     $map
     $exec-id
     (codex:js-repl-exec-tool-calls-default $notify $cancel)))

(= (codex:js-repl-exec-tool-calls-remove-missing $entries)
   (CodexJsReplExecToolCallsRemoveMissing $entries))

(= (codex:js-repl-exec-tool-calls-remove-found $state $entries)
   (CodexJsReplExecToolCallsRemoveFound $state $entries))

(= (codex:js-repl-exec-tool-calls-remove-result-entries
      (CodexJsReplExecToolCallsRemoveMissing $entries))
   $entries)

(= (codex:js-repl-exec-tool-calls-remove-result-entries
      (CodexJsReplExecToolCallsRemoveFound $state $entries))
   $entries)

(= (codex:js-repl-exec-tool-calls-remove-result-state
      (CodexJsReplExecToolCallsRemoveMissing $entries))
   CodexAbsent)

(= (codex:js-repl-exec-tool-calls-remove-result-state
      (CodexJsReplExecToolCallsRemoveFound $state $entries))
   $state)

(= (codex:js-repl-exec-tool-calls-remove-entry
      ()
      $exec-id)
   (CodexJsReplExecToolCallsRemoveMissing ()))

(= (codex:js-repl-exec-tool-calls-remove-entry
      $entries
      $exec-id)
   (let $entry (list:first $entries)
     (let $tail (list:rest $entries)
       (if (== (codex:js-repl-exec-tool-calls-entry-exec-id $entry)
               $exec-id)
           (CodexJsReplExecToolCallsRemoveFound
             (codex:js-repl-exec-tool-calls-entry-state $entry)
             $tail)
           (case (codex:js-repl-exec-tool-calls-remove-entry
                   $tail
                   $exec-id)
             (((CodexJsReplExecToolCallsRemoveMissing $next-entries)
               (CodexJsReplExecToolCallsRemoveMissing
                 (list:append ($entry) $next-entries)))
              ((CodexJsReplExecToolCallsRemoveFound $state $next-entries)
               (CodexJsReplExecToolCallsRemoveFound
                 $state
                 (list:append ($entry) $next-entries)))))))))

(= (codex:js-repl-exec-tool-call-action-cancel $cancel)
   (CodexJsReplExecToolCallActionCancel $cancel))

(= (codex:js-repl-exec-tool-call-action-notify-waiters $notify)
   (CodexJsReplExecToolCallActionNotifyWaiters $notify))

(= (codex:js-repl-exec-tool-calls-clear-actions $state)
   ((codex:js-repl-exec-tool-call-action-cancel
      (codex:js-repl-exec-tool-calls-state-cancel $state))
    (codex:js-repl-exec-tool-call-action-notify-waiters
      (codex:js-repl-exec-tool-calls-state-notify $state))))

(= (codex:js-repl-clear-exec-tool-calls-result $map $actions)
   (CodexJsReplClearExecToolCallsResult $map $actions))

(= (codex:js-repl-clear-exec-tool-calls-result-map
      (CodexJsReplClearExecToolCallsResult $map $actions))
   $map)

(= (codex:js-repl-clear-exec-tool-calls-result-actions
      (CodexJsReplClearExecToolCallsResult $map $actions))
   $actions)

(= (codex:js-repl-clear-exec-tool-calls-map
      (CodexJsReplExecToolCallsMap $entries)
      $exec-id)
   (case (codex:js-repl-exec-tool-calls-remove-entry
           $entries
           $exec-id)
     (((CodexJsReplExecToolCallsRemoveMissing $next-entries)
       (CodexJsReplClearExecToolCallsResult
         (CodexJsReplExecToolCallsMap $next-entries)
         ()))
      ((CodexJsReplExecToolCallsRemoveFound $state $next-entries)
       (CodexJsReplClearExecToolCallsResult
         (CodexJsReplExecToolCallsMap $next-entries)
         (codex:js-repl-exec-tool-calls-clear-actions $state))))))

(= (codex:js-repl-exec-tool-calls-clear-all-actions ())
   ())

(= (codex:js-repl-exec-tool-calls-clear-all-actions $entries)
   (let $state
     (codex:js-repl-exec-tool-calls-entry-state
       (list:first $entries))
     (list:append
       (codex:js-repl-exec-tool-calls-clear-actions $state)
       (codex:js-repl-exec-tool-calls-clear-all-actions
         (list:rest $entries)))))

(= (codex:js-repl-clear-all-exec-tool-calls-map
      (CodexJsReplExecToolCallsMap $entries))
   (CodexJsReplClearExecToolCallsResult
     (CodexJsReplExecToolCallsMap ())
     (codex:js-repl-exec-tool-calls-clear-all-actions $entries)))

(= (codex:js-repl-begin-exec-tool-call-result $map $cancel)
   (CodexJsReplBeginExecToolCallResult $map $cancel))

(= (codex:js-repl-begin-exec-tool-call-result-map
      (CodexJsReplBeginExecToolCallResult $map $cancel))
   $map)

(= (codex:js-repl-begin-exec-tool-call-result-cancel
      (CodexJsReplBeginExecToolCallResult $map $cancel))
   $cancel)

(= (codex:js-repl-begin-exec-tool-call-map $map $exec-id)
   (case (codex:js-repl-exec-tool-calls-map-find $map $exec-id)
     ((CodexJsReplExecToolCallsLookupMissing
       (CodexJsReplBeginExecToolCallResult $map CodexAbsent))
      ((CodexJsReplExecToolCallsLookupFound
         (CodexJsReplExecToolCallsState
           $in-flight $content-items $notify $cancel))
       (CodexJsReplBeginExecToolCallResult
         (codex:js-repl-exec-tool-calls-map-upsert
           $map
           $exec-id
           (CodexJsReplExecToolCallsState
             (+ $in-flight 1)
             $content-items
             $notify
             $cancel))
         $cancel)))))

(= (codex:js-repl-record-exec-content-item-map $map $exec-id $content-item)
   (case (codex:js-repl-exec-tool-calls-map-find $map $exec-id)
     ((CodexJsReplExecToolCallsLookupMissing
       $map)
      ((CodexJsReplExecToolCallsLookupFound
         (CodexJsReplExecToolCallsState
           $in-flight $content-items $notify $cancel))
       (codex:js-repl-exec-tool-calls-map-upsert
         $map
         $exec-id
         (CodexJsReplExecToolCallsState
           $in-flight
           (list:append $content-items ($content-item))
           $notify
           $cancel))))))

(= (codex:js-repl-finish-exec-tool-call-result $map $actions)
   (CodexJsReplFinishExecToolCallResult $map $actions))

(= (codex:js-repl-finish-exec-tool-call-result-map
      (CodexJsReplFinishExecToolCallResult $map $actions))
   $map)

(= (codex:js-repl-finish-exec-tool-call-result-actions
      (CodexJsReplFinishExecToolCallResult $map $actions))
   $actions)

(= (codex:js-repl-finish-exec-tool-call-map $map $exec-id)
   (case (codex:js-repl-exec-tool-calls-map-find $map $exec-id)
     ((CodexJsReplExecToolCallsLookupMissing
       (CodexJsReplFinishExecToolCallResult $map ()))
      ((CodexJsReplExecToolCallsLookupFound
         (CodexJsReplExecToolCallsState
           $in-flight $content-items $notify $cancel))
       (if (== $in-flight 0)
           (CodexJsReplFinishExecToolCallResult $map ())
           (let $next-in-flight (- $in-flight 1)
             (CodexJsReplFinishExecToolCallResult
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
                   ()))))))))

(= (codex:js-repl-wait-exec-tool-calls-complete)
   CodexJsReplWaitExecToolCallsComplete)

(= (codex:js-repl-wait-exec-tool-calls-wait $notify)
   (CodexJsReplWaitExecToolCallsWait $notify))

(= (codex:js-repl-wait-for-exec-tool-calls-map-step $map $exec-id)
   (case (codex:js-repl-exec-tool-calls-map-find $map $exec-id)
     ((CodexJsReplExecToolCallsLookupMissing
       CodexJsReplWaitExecToolCallsComplete)
      ((CodexJsReplExecToolCallsLookupFound
         (CodexJsReplExecToolCallsState
           $in-flight $content-items $notify $cancel))
       (if (> $in-flight 0)
           (CodexJsReplWaitExecToolCallsWait $notify)
           CodexJsReplWaitExecToolCallsComplete)))))
