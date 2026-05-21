; Rust-faithful js_repl read_stdout RunTool start slice.
;
; This ports deterministic helper behavior from:
; - openai-codex/codex-rs/core/src/tools/js_repl/mod.rs
;   - the `KernelToHost::RunTool(req)` arm in `read_stdout` up to the
;     `tokio::spawn` boundary
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust mutates `ExecToolCalls` behind an `Arc<Mutex<HashMap<...>>>`, writes
;   immediate missing-context responses to kernel stdin, and spawns an async
;   task for accepted nested tool calls. This pure slice returns immutable
;   state plus explicit write/spawn actions at the same branch boundary.
; - Rust clones stdin, exec contexts, exec tool calls, and recent stderr into
;   the spawned task. This slice records the spawned request and reset-cancel
;   token as a task plan; task body execution is a later runtime slice.

!(import! &self function_tool)
!(import! &self js_repl_exec_tool_calls)
!(import! &self js_repl_kernel_io)

(= (codex:js-repl-kernel-to-host-run-tool
      $id
      $exec-id
      $tool-name
      $arguments)
   (CodexJsReplKernelToHostRunTool $id $exec-id $tool-name $arguments))

(= (codex:js-repl-run-tool-context-missing-message)
   "js_repl exec context not found")

(= (codex:js-repl-read-stdout-run-tool-warning-message)
   "failed to reply to kernel run_tool request")

(= (codex:js-repl-read-stdout-run-tool-status-replied-missing-context)
   CodexJsReplReadStdoutRunToolStatusRepliedMissingContext)

(= (codex:js-repl-read-stdout-run-tool-status-spawned)
   CodexJsReplReadStdoutRunToolStatusSpawned)

(= (codex:js-repl-read-stdout-run-tool-missing-context-response $tool-call-id)
   (codex:js-repl-host-to-kernel-run-tool-result
     (codex:js-repl-run-tool-result
       $tool-call-id
       False
       CodexAbsent
       (codex:js-repl-run-tool-context-missing-message))))

(= (codex:js-repl-read-stdout-run-tool-action-write-message
      $message
      $write-result)
   (CodexJsReplReadStdoutRunToolActionWriteMessage
     $message
     $write-result))

(= (codex:js-repl-read-stdout-run-tool-action-spawn-task
      $request
      $reset-cancel)
   (CodexJsReplReadStdoutRunToolActionSpawnTask
     $request
     $reset-cancel))

(= (codex:js-repl-read-stdout-run-tool-warning-write-failed
      $exec-id
      $tool-call-id
      $error
      $snapshot)
   (CodexJsReplReadStdoutRunToolWarningWriteFailed
     (codex:js-repl-read-stdout-run-tool-warning-message)
     $exec-id
     $tool-call-id
     $error
     $snapshot))

(= (codex:js-repl-read-stdout-run-tool-write-warnings
      (CodexJsReplWriteMessageOk $writes)
      $exec-id
      $tool-call-id
      $child-inspection
      $recent-stderr)
   ())

(= (codex:js-repl-read-stdout-run-tool-write-warnings
      (CodexJsReplWriteMessageError $error $writes)
      $exec-id
      $tool-call-id
      $child-inspection
      $recent-stderr)
   ((codex:js-repl-read-stdout-run-tool-warning-write-failed
      $exec-id
      $tool-call-id
      (codex:function-call-error-display $error)
      (codex:js-repl-kernel-debug-snapshot-from-inspection
        $child-inspection
        $recent-stderr))))

(= (codex:js-repl-read-stdout-run-tool-step-result
      $status
      $exec-tool-calls
      $response
      $write-result
      $actions
      $warnings)
   (CodexJsReplReadStdoutRunToolStepResult
     $status
     $exec-tool-calls
     $response
     $write-result
     $actions
     $warnings))

(= (codex:js-repl-read-stdout-run-tool-step-result-status
      (CodexJsReplReadStdoutRunToolStepResult
        $status $exec-tool-calls $response $write-result
        $actions $warnings))
   $status)

(= (codex:js-repl-read-stdout-run-tool-step-result-exec-tool-calls
      (CodexJsReplReadStdoutRunToolStepResult
        $status $exec-tool-calls $response $write-result
        $actions $warnings))
   $exec-tool-calls)

(= (codex:js-repl-read-stdout-run-tool-step-result-response
      (CodexJsReplReadStdoutRunToolStepResult
        $status $exec-tool-calls $response $write-result
        $actions $warnings))
   $response)

(= (codex:js-repl-read-stdout-run-tool-step-result-write-result
      (CodexJsReplReadStdoutRunToolStepResult
        $status $exec-tool-calls $response $write-result
        $actions $warnings))
   $write-result)

(= (codex:js-repl-read-stdout-run-tool-step-result-actions
      (CodexJsReplReadStdoutRunToolStepResult
        $status $exec-tool-calls $response $write-result
        $actions $warnings))
   $actions)

(= (codex:js-repl-read-stdout-run-tool-step-result-warnings
      (CodexJsReplReadStdoutRunToolStepResult
        $status $exec-tool-calls $response $write-result
        $actions $warnings))
   $warnings)

(= (codex:js-repl-read-stdout-run-tool-missing-context-step
      (CodexJsReplKernelToHostRunTool $id $exec-id $tool-name $arguments)
      $exec-tool-calls
      $stdin
      $body-write-result
      $newline-write-result
      $child-inspection
      $recent-stderr)
   (let $response
     (codex:js-repl-read-stdout-run-tool-missing-context-response $id)
     (let $write-result
       (codex:js-repl-write-message
         $stdin
         $response
         $body-write-result
         $newline-write-result)
       (CodexJsReplReadStdoutRunToolStepResult
         CodexJsReplReadStdoutRunToolStatusRepliedMissingContext
         $exec-tool-calls
         $response
         $write-result
         ((codex:js-repl-read-stdout-run-tool-action-write-message
            $response
            $write-result))
         (codex:js-repl-read-stdout-run-tool-write-warnings
           $write-result
           $exec-id
           $id
           $child-inspection
           $recent-stderr)))))

(= (codex:js-repl-read-stdout-run-tool-spawn-step
      $request
      $begun-exec-tool-calls
      $reset-cancel)
   (CodexJsReplReadStdoutRunToolStepResult
     CodexJsReplReadStdoutRunToolStatusSpawned
     $begun-exec-tool-calls
     CodexAbsent
     CodexAbsent
     ((codex:js-repl-read-stdout-run-tool-action-spawn-task
        $request
        $reset-cancel))
     ()))

(= (codex:js-repl-read-stdout-run-tool-step
      $request
      $exec-tool-calls
      $stdin
      $body-write-result
      $newline-write-result
      $child-inspection
      $recent-stderr)
   (case $request
     (((CodexJsReplKernelToHostRunTool $id $exec-id $tool-name $arguments)
       (let $begin-result
         (codex:js-repl-begin-exec-tool-call-map
           $exec-tool-calls
           $exec-id)
         (case (codex:js-repl-begin-exec-tool-call-result-cancel
                 $begin-result)
           ((CodexAbsent
             (codex:js-repl-read-stdout-run-tool-missing-context-step
               $request
               $exec-tool-calls
               $stdin
               $body-write-result
               $newline-write-result
               $child-inspection
               $recent-stderr))
            ($reset-cancel
             (codex:js-repl-read-stdout-run-tool-spawn-step
               $request
               (codex:js-repl-begin-exec-tool-call-result-map
                 $begin-result)
               $reset-cancel)))))))))
