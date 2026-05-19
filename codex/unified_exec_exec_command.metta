; Rust-faithful pure unified-exec exec_command process-manager slice.
;
; This ports deterministic control flow from:
; - openai-codex/codex-rs/core/src/unified_exec/process_manager.rs
;   - UnifiedExecProcessManager::exec_command
;
; Covered in this increment:
; - cwd resolution from request workdir or turn cwd
; - open_session_with_sandbox result integration and release-on-open-error
; - begin event, streaming-output request, collection request, live-session
;   store request/result, release/finish side-effect requests
; - process-started-alive branch selection
; - failure-message, alive, exited, unknown, short-lived, and sandbox-check
;   result branches
; - response materialization as `ExecCommandToolOutput`
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust observes shared mutable process state after the initial yield wait
;   (`failure_message`, `refresh_process_state`, and sandbox-denial check).
;   This pure boundary receives those post-wait observations explicitly in
;   `CodexUnifiedExecExecCommandRuntimeInputs`, matching the existing
;   write_stdin slice's runtime-observation pattern.
; - Rust calls `open_session_with_sandbox` directly. That boundary is already
;   ported in unified_exec_sandbox_session.metta; this slice receives its
;   materialized result to keep the top-level exec_command flow independent of
;   duplicate imported helper results in file-mode evaluation.
; - Rust allocates `Arc<Mutex<HeadTailBuffer>>`, creates `ToolEventCtx`, emits
;   with `ToolEmitter`, starts async streaming, awaits collection, generates a
;   random chunk id, and finishes deferred network approval as side effects.
;   This slice returns the same event/request atoms and receives collection,
;   wall-time, chunk-id, and post-wait observations from the runtime boundary.
; - Rust raw output is bytes and converts with `String::from_utf8_lossy`.
;   Existing CeTTa exec-output surfaces carry text; collected output is modeled
;   as that lossy text at this boundary, as in unified_exec_write_stdin.metta.

!(import! &self context)
!(import! &self command)
!(import! &self str)
!(import! &self unified_exec_async_watcher)
!(import! &self unified_exec_core)
!(import! &self unified_exec_process_manager_state)
!(import! &self unified_exec_process_runtime)
!(import! &self unified_exec_state)

(= (codex:unified-exec-exec-command-runtime-inputs
      $turn-cwd
      $turn-id
      $started-at-ms
      $wall-time-ms
      $collected-output
      $chunk-id
      $pause-state
      $transcript
      $formatted-output
      $open-session-result
      $failure-message
      $refresh-result
      $sandbox-check-result)
   (CodexUnifiedExecExecCommandRuntimeInputs
     $turn-cwd
     $turn-id
     $started-at-ms
     $wall-time-ms
     $collected-output
     $chunk-id
     $pause-state
     $transcript
     $formatted-output
     $open-session-result
     $failure-message
     $refresh-result
     $sandbox-check-result))

(= (codex:unified-exec-exec-command-runtime-inputs-turn-cwd
      (CodexUnifiedExecExecCommandRuntimeInputs
        $turn-cwd
        $turn-id
        $started-at-ms
        $wall-time-ms
        $collected-output
        $chunk-id
        $pause-state
        $transcript
        $formatted-output
        $open-session-result
        $failure-message
        $refresh-result
        $sandbox-check-result))
   $turn-cwd)

(= (codex:unified-exec-exec-command-runtime-inputs-turn-id
      (CodexUnifiedExecExecCommandRuntimeInputs
        $turn-cwd
        $turn-id
        $started-at-ms
        $wall-time-ms
        $collected-output
        $chunk-id
        $pause-state
        $transcript
        $formatted-output
        $open-session-result
        $failure-message
        $refresh-result
        $sandbox-check-result))
   $turn-id)

(= (codex:unified-exec-exec-command-runtime-inputs-started-at-ms
      (CodexUnifiedExecExecCommandRuntimeInputs
        $turn-cwd
        $turn-id
        $started-at-ms
        $wall-time-ms
        $collected-output
        $chunk-id
        $pause-state
        $transcript
        $formatted-output
        $open-session-result
        $failure-message
        $refresh-result
        $sandbox-check-result))
   $started-at-ms)

(= (codex:unified-exec-exec-command-runtime-inputs-wall-time-ms
      (CodexUnifiedExecExecCommandRuntimeInputs
        $turn-cwd
        $turn-id
        $started-at-ms
        $wall-time-ms
        $collected-output
        $chunk-id
        $pause-state
        $transcript
        $formatted-output
        $open-session-result
        $failure-message
        $refresh-result
        $sandbox-check-result))
   $wall-time-ms)

(= (codex:unified-exec-exec-command-runtime-inputs-collected-output
      (CodexUnifiedExecExecCommandRuntimeInputs
        $turn-cwd
        $turn-id
        $started-at-ms
        $wall-time-ms
        $collected-output
        $chunk-id
        $pause-state
        $transcript
        $formatted-output
        $open-session-result
        $failure-message
        $refresh-result
        $sandbox-check-result))
   $collected-output)

(= (codex:unified-exec-exec-command-runtime-inputs-chunk-id
      (CodexUnifiedExecExecCommandRuntimeInputs
        $turn-cwd
        $turn-id
        $started-at-ms
        $wall-time-ms
        $collected-output
        $chunk-id
        $pause-state
        $transcript
        $formatted-output
        $open-session-result
        $failure-message
        $refresh-result
        $sandbox-check-result))
   $chunk-id)

(= (codex:unified-exec-exec-command-runtime-inputs-pause-state
      (CodexUnifiedExecExecCommandRuntimeInputs
        $turn-cwd
        $turn-id
        $started-at-ms
        $wall-time-ms
        $collected-output
        $chunk-id
        $pause-state
        $transcript
        $formatted-output
        $open-session-result
        $failure-message
        $refresh-result
        $sandbox-check-result))
   $pause-state)

(= (codex:unified-exec-exec-command-runtime-inputs-transcript
      (CodexUnifiedExecExecCommandRuntimeInputs
        $turn-cwd
        $turn-id
        $started-at-ms
        $wall-time-ms
        $collected-output
        $chunk-id
        $pause-state
        $transcript
        $formatted-output
        $open-session-result
        $failure-message
        $refresh-result
        $sandbox-check-result))
   $transcript)

(= (codex:unified-exec-exec-command-runtime-inputs-formatted-output
      (CodexUnifiedExecExecCommandRuntimeInputs
        $turn-cwd
        $turn-id
        $started-at-ms
        $wall-time-ms
        $collected-output
        $chunk-id
        $pause-state
        $transcript
        $formatted-output
        $open-session-result
        $failure-message
        $refresh-result
        $sandbox-check-result))
   $formatted-output)

(= (codex:unified-exec-exec-command-runtime-inputs-open-session-result
      (CodexUnifiedExecExecCommandRuntimeInputs
        $turn-cwd
        $turn-id
        $started-at-ms
        $wall-time-ms
        $collected-output
        $chunk-id
        $pause-state
        $transcript
        $formatted-output
        $open-session-result
        $failure-message
        $refresh-result
        $sandbox-check-result))
   $open-session-result)

(= (codex:unified-exec-exec-command-runtime-inputs-failure-message
      (CodexUnifiedExecExecCommandRuntimeInputs
        $turn-cwd
        $turn-id
        $started-at-ms
        $wall-time-ms
        $collected-output
        $chunk-id
        $pause-state
        $transcript
        $formatted-output
        $open-session-result
        $failure-message
        $refresh-result
        $sandbox-check-result))
   $failure-message)

(= (codex:unified-exec-exec-command-runtime-inputs-refresh-result
      (CodexUnifiedExecExecCommandRuntimeInputs
        $turn-cwd
        $turn-id
        $started-at-ms
        $wall-time-ms
        $collected-output
        $chunk-id
        $pause-state
        $transcript
        $formatted-output
        $open-session-result
        $failure-message
        $refresh-result
        $sandbox-check-result))
   $refresh-result)

(= (codex:unified-exec-exec-command-runtime-inputs-sandbox-check-result
      (CodexUnifiedExecExecCommandRuntimeInputs
        $turn-cwd
        $turn-id
        $started-at-ms
        $wall-time-ms
        $collected-output
        $chunk-id
        $pause-state
        $transcript
        $formatted-output
        $open-session-result
        $failure-message
        $refresh-result
        $sandbox-check-result))
   $sandbox-check-result)

(= (codex:unified-exec-exec-command-open-session-result-kind
      (CodexUnifiedExecOpenSessionWithSandboxResultOk
        $process
        $deferred-network-approval
        $tool-request
        $tool-ctx
        $approval-request
        $runtime-shell-mode))
   ok)

(= (codex:unified-exec-exec-command-open-session-result-kind
      (CodexUnifiedExecOpenSessionWithSandboxResultErr
        $error
        $tool-request
        $tool-ctx
        $approval-request
        $runtime-shell-mode))
   err)

(= (codex:unified-exec-exec-command-open-session-result-process
      (CodexUnifiedExecOpenSessionWithSandboxResultOk
        $process
        $deferred-network-approval
        $tool-request
        $tool-ctx
        $approval-request
        $runtime-shell-mode))
   $process)

(= (codex:unified-exec-exec-command-open-session-result-deferred-network-approval
      (CodexUnifiedExecOpenSessionWithSandboxResultOk
        $process
        $deferred-network-approval
        $tool-request
        $tool-ctx
        $approval-request
        $runtime-shell-mode))
   $deferred-network-approval)

(= (codex:unified-exec-exec-command-open-session-result-error
      (CodexUnifiedExecOpenSessionWithSandboxResultErr
        $error
        $tool-request
        $tool-ctx
        $approval-request
        $runtime-shell-mode))
   $error)

(= (codex:unified-exec-exec-command-streaming-output-request
      $process
      $context
      $transcript)
   (CodexUnifiedExecExecCommandStreamingOutputRequest
     $process
     $context
     $transcript))

(= (codex:unified-exec-exec-command-streaming-output-request-process
      (CodexUnifiedExecExecCommandStreamingOutputRequest
        $process
        $context
        $transcript))
   $process)

(= (codex:unified-exec-exec-command-streaming-output-request-context
      (CodexUnifiedExecExecCommandStreamingOutputRequest
        $process
        $context
        $transcript))
   $context)

(= (codex:unified-exec-exec-command-streaming-output-request-transcript
      (CodexUnifiedExecExecCommandStreamingOutputRequest
        $process
        $context
        $transcript))
   $transcript)

(= (codex:unified-exec-exec-command-collection-request
      $output-buffer
      $output-notify
      $output-closed
      $output-closed-notify
      $cancellation-token
      $pause-state
      $deadline-ms
      $yield-time-ms)
   (CodexUnifiedExecExecCommandCollectionRequest
     $output-buffer
     $output-notify
     $output-closed
     $output-closed-notify
     $cancellation-token
     $pause-state
     $deadline-ms
     $yield-time-ms))

(= (codex:unified-exec-exec-command-collection-request-output-buffer
      (CodexUnifiedExecExecCommandCollectionRequest
        $output-buffer
        $output-notify
        $output-closed
        $output-closed-notify
        $cancellation-token
        $pause-state
        $deadline-ms
        $yield-time-ms))
   $output-buffer)

(= (codex:unified-exec-exec-command-collection-request-pause-state
      (CodexUnifiedExecExecCommandCollectionRequest
        $output-buffer
        $output-notify
        $output-closed
        $output-closed-notify
        $cancellation-token
        $pause-state
        $deadline-ms
        $yield-time-ms))
   $pause-state)

(= (codex:unified-exec-exec-command-collection-request-deadline-ms
      (CodexUnifiedExecExecCommandCollectionRequest
        $output-buffer
        $output-notify
        $output-closed
        $output-closed-notify
        $cancellation-token
        $pause-state
        $deadline-ms
        $yield-time-ms))
   $deadline-ms)

(= (codex:unified-exec-exec-command-collection-request-yield-time-ms
      (CodexUnifiedExecExecCommandCollectionRequest
        $output-buffer
        $output-notify
        $output-closed
        $output-closed-notify
        $cancellation-token
        $pause-state
        $deadline-ms
        $yield-time-ms))
   $yield-time-ms)

(= (codex:unified-exec-deferred-network-approval $registration-id)
   (CodexUnifiedExecDeferredNetworkApproval $registration-id))

(= (codex:unified-exec-deferred-network-approval-registration-id
      (CodexUnifiedExecDeferredNetworkApproval $registration-id))
   $registration-id)

(= (codex:unified-exec-deferred-network-approval-registration-id
      CodexAbsent)
   CodexAbsent)

(= (codex:unified-exec-exec-command-finish-deferred-network-approval-request
      $session
      $deferred-network-approval)
   (CodexUnifiedExecExecCommandFinishDeferredNetworkApprovalRequest
     $session
     $deferred-network-approval))

(= (codex:unified-exec-exec-command-finish-deferred-network-approval-request-session
      (CodexUnifiedExecExecCommandFinishDeferredNetworkApprovalRequest
        $session
        $deferred-network-approval))
   $session)

(= (codex:unified-exec-exec-command-finish-deferred-network-approval-request-approval
      (CodexUnifiedExecExecCommandFinishDeferredNetworkApprovalRequest
        $session
        $deferred-network-approval))
   $deferred-network-approval)

(= (codex:unified-exec-exec-command-release-result
      $manager
      $removed-entry)
   (CodexUnifiedExecExecCommandReleaseResult
     $manager
     $removed-entry))

(= (codex:unified-exec-exec-command-release-result-manager
      (CodexUnifiedExecExecCommandReleaseResult
        $manager
        $removed-entry))
   $manager)

(= (codex:unified-exec-exec-command-release-result-removed-entry
      (CodexUnifiedExecExecCommandReleaseResult
        $manager
        $removed-entry))
   $removed-entry)

(= (codex:unified-exec-exec-command-lifecycle
      $cwd
      $open-session-result
      $begin-event
      $stream-request
      $process-started-alive
      $store-result
      $collection-request
      $refresh-result
      $release-result
      $end-event
      $finish-deferred-request
      $sandbox-check-result)
   (CodexUnifiedExecExecCommandLifecycle
     $cwd
     $open-session-result
     $begin-event
     $stream-request
     $process-started-alive
     $store-result
     $collection-request
     $refresh-result
     $release-result
     $end-event
     $finish-deferred-request
     $sandbox-check-result))

(= (codex:unified-exec-exec-command-lifecycle-cwd
      (CodexUnifiedExecExecCommandLifecycle
        $cwd
        $open-session-result
        $begin-event
        $stream-request
        $process-started-alive
        $store-result
        $collection-request
        $refresh-result
        $release-result
        $end-event
        $finish-deferred-request
        $sandbox-check-result))
   $cwd)

(= (codex:unified-exec-exec-command-lifecycle-open-session-result
      (CodexUnifiedExecExecCommandLifecycle
        $cwd
        $open-session-result
        $begin-event
        $stream-request
        $process-started-alive
        $store-result
        $collection-request
        $refresh-result
        $release-result
        $end-event
        $finish-deferred-request
        $sandbox-check-result))
   $open-session-result)

(= (codex:unified-exec-exec-command-lifecycle-begin-event
      (CodexUnifiedExecExecCommandLifecycle
        $cwd
        $open-session-result
        $begin-event
        $stream-request
        $process-started-alive
        $store-result
        $collection-request
        $refresh-result
        $release-result
        $end-event
        $finish-deferred-request
        $sandbox-check-result))
   $begin-event)

(= (codex:unified-exec-exec-command-lifecycle-stream-request
      (CodexUnifiedExecExecCommandLifecycle
        $cwd
        $open-session-result
        $begin-event
        $stream-request
        $process-started-alive
        $store-result
        $collection-request
        $refresh-result
        $release-result
        $end-event
        $finish-deferred-request
        $sandbox-check-result))
   $stream-request)

(= (codex:unified-exec-exec-command-lifecycle-process-started-alive
      (CodexUnifiedExecExecCommandLifecycle
        $cwd
        $open-session-result
        $begin-event
        $stream-request
        $process-started-alive
        $store-result
        $collection-request
        $refresh-result
        $release-result
        $end-event
        $finish-deferred-request
        $sandbox-check-result))
   $process-started-alive)

(= (codex:unified-exec-exec-command-lifecycle-store-result
      (CodexUnifiedExecExecCommandLifecycle
        $cwd
        $open-session-result
        $begin-event
        $stream-request
        $process-started-alive
        $store-result
        $collection-request
        $refresh-result
        $release-result
        $end-event
        $finish-deferred-request
        $sandbox-check-result))
   $store-result)

(= (codex:unified-exec-exec-command-lifecycle-collection-request
      (CodexUnifiedExecExecCommandLifecycle
        $cwd
        $open-session-result
        $begin-event
        $stream-request
        $process-started-alive
        $store-result
        $collection-request
        $refresh-result
        $release-result
        $end-event
        $finish-deferred-request
        $sandbox-check-result))
   $collection-request)

(= (codex:unified-exec-exec-command-lifecycle-refresh-result
      (CodexUnifiedExecExecCommandLifecycle
        $cwd
        $open-session-result
        $begin-event
        $stream-request
        $process-started-alive
        $store-result
        $collection-request
        $refresh-result
        $release-result
        $end-event
        $finish-deferred-request
        $sandbox-check-result))
   $refresh-result)

(= (codex:unified-exec-exec-command-lifecycle-release-result
      (CodexUnifiedExecExecCommandLifecycle
        $cwd
        $open-session-result
        $begin-event
        $stream-request
        $process-started-alive
        $store-result
        $collection-request
        $refresh-result
        $release-result
        $end-event
        $finish-deferred-request
        $sandbox-check-result))
   $release-result)

(= (codex:unified-exec-exec-command-lifecycle-end-event
      (CodexUnifiedExecExecCommandLifecycle
        $cwd
        $open-session-result
        $begin-event
        $stream-request
        $process-started-alive
        $store-result
        $collection-request
        $refresh-result
        $release-result
        $end-event
        $finish-deferred-request
        $sandbox-check-result))
   $end-event)

(= (codex:unified-exec-exec-command-lifecycle-finish-deferred-request
      (CodexUnifiedExecExecCommandLifecycle
        $cwd
        $open-session-result
        $begin-event
        $stream-request
        $process-started-alive
        $store-result
        $collection-request
        $refresh-result
        $release-result
        $end-event
        $finish-deferred-request
        $sandbox-check-result))
   $finish-deferred-request)

(= (codex:unified-exec-exec-command-lifecycle-sandbox-check-result
      (CodexUnifiedExecExecCommandLifecycle
        $cwd
        $open-session-result
        $begin-event
        $stream-request
        $process-started-alive
        $store-result
        $collection-request
        $refresh-result
        $release-result
        $end-event
        $finish-deferred-request
        $sandbox-check-result))
   $sandbox-check-result)

(= (codex:unified-exec-exec-command-result-ok
      $output
      $manager
      $lifecycle)
   (CodexUnifiedExecExecCommandResultOk
     $output
     $manager
     $lifecycle))

(= (codex:unified-exec-exec-command-result-err
      $error
      $manager
      $lifecycle)
   (CodexUnifiedExecExecCommandResultErr
     $error
     $manager
     $lifecycle))

(= (codex:unified-exec-exec-command-result-kind
      (CodexUnifiedExecExecCommandResultOk
        $output
        $manager
        $lifecycle))
   ok)

(= (codex:unified-exec-exec-command-result-kind
      (CodexUnifiedExecExecCommandResultErr
        $error
        $manager
        $lifecycle))
   err)

(= (codex:unified-exec-exec-command-result-output
      (CodexUnifiedExecExecCommandResultOk
        $output
        $manager
        $lifecycle))
   $output)

(= (codex:unified-exec-exec-command-result-error
      (CodexUnifiedExecExecCommandResultErr
        $error
        $manager
        $lifecycle))
   $error)

(= (codex:unified-exec-exec-command-result-manager
      (CodexUnifiedExecExecCommandResultOk
        $output
        $manager
        $lifecycle))
   $manager)

(= (codex:unified-exec-exec-command-result-manager
      (CodexUnifiedExecExecCommandResultErr
        $error
        $manager
        $lifecycle))
   $manager)

(= (codex:unified-exec-exec-command-result-lifecycle
      (CodexUnifiedExecExecCommandResultOk
        $output
        $manager
        $lifecycle))
   $lifecycle)

(= (codex:unified-exec-exec-command-result-lifecycle
      (CodexUnifiedExecExecCommandResultErr
        $error
        $manager
        $lifecycle))
   $lifecycle)

(= (codex:unified-exec-exec-command-cwd
      $request
      $runtime-inputs)
   (let $workdir
     (codex:unified-exec-exec-command-request-workdir $request)
     (if (== $workdir CodexAbsent)
         (codex:unified-exec-exec-command-runtime-inputs-turn-cwd
           $runtime-inputs)
         $workdir)))

(= (codex:unified-exec-exec-command-process-manager-with-store
      (CodexUnifiedExecProcessManager
        $process-store
        $max-write-stdin-yield-time-ms)
      $new-process-store)
   (CodexUnifiedExecProcessManager
     $new-process-store
     $max-write-stdin-yield-time-ms))

(= (codex:unified-exec-exec-command-release-manager
      $manager
      $process-id)
   (let $release
     (codex:unified-exec-process-store-release
       (codex:unified-exec-process-manager-process-store
         $manager)
       $process-id)
     (codex:unified-exec-exec-command-release-result
       (codex:unified-exec-exec-command-process-manager-with-store
         $manager
         (codex:unified-exec-process-store-remove-result-store
           $release))
       (codex:unified-exec-process-store-remove-result-removed
         $release))))

(= (codex:unified-exec-exec-command-approx-token-count $text)
   (codex:unified-exec-exec-command-approx-token-count-from
     (str-length $text)
     0))

(= (codex:unified-exec-exec-command-approx-token-count-from
      $remaining-bytes
      $acc)
   (if (<= $remaining-bytes 0)
       $acc
       (codex:unified-exec-exec-command-approx-token-count-from
         (- $remaining-bytes 4)
         (+ $acc 1))))

(= (codex:unified-exec-exec-command-output
      $request
      $context
      $runtime-inputs
      $response-process-id
      $exit-code)
   (codex:exec-command-tool-output
     (codex:unified-exec-context-call-id $context)
     (codex:unified-exec-exec-command-runtime-inputs-chunk-id
       $runtime-inputs)
     (codex:unified-exec-exec-command-runtime-inputs-wall-time-ms
       $runtime-inputs)
     (codex:unified-exec-exec-command-runtime-inputs-collected-output
       $runtime-inputs)
     (codex:unified-exec-exec-command-request-max-output-tokens
       $request)
     $response-process-id
     $exit-code
     (codex:unified-exec-exec-command-approx-token-count
       (codex:unified-exec-exec-command-runtime-inputs-collected-output
         $runtime-inputs))
     (codex:unified-exec-exec-command-request-hook-command
       $request)))

(= (codex:unified-exec-exec-command-output-process-id
      (CodexToolOutputExecCommand
        $event-call-id
        $chunk-id
        $wall-time-ms
        $raw-output
        $max-output-tokens
        $process-id
        $exit-code
        $original-token-count
        $hook-command))
   $process-id)

(= (codex:unified-exec-exec-command-output-exit-code
      (CodexToolOutputExecCommand
        $event-call-id
        $chunk-id
        $wall-time-ms
        $raw-output
        $max-output-tokens
        $process-id
        $exit-code
        $original-token-count
        $hook-command))
   $exit-code)

(= (codex:unified-exec-exec-command-output-original-token-count
      (CodexToolOutputExecCommand
        $event-call-id
        $chunk-id
        $wall-time-ms
        $raw-output
        $max-output-tokens
        $process-id
        $exit-code
        $original-token-count
        $hook-command))
   $original-token-count)

(= (codex:unified-exec-exec-command-begin-event
      $request
      $context
      $runtime-inputs
      $cwd)
   (CodexEventExecCommandBegin
     (codex:unified-exec-context-call-id $context)
     (format-args
       "{}"
       ((codex:unified-exec-exec-command-request-process-id
          $request)))
     (codex:unified-exec-exec-command-runtime-inputs-turn-id
       $runtime-inputs)
     (codex:unified-exec-exec-command-request-command $request)
     $cwd
     (codex:parse-command
       (codex:unified-exec-exec-command-request-command
         $request))
     (CodexExecCommandSourceUnifiedExecStartup)
     CodexAbsent))

(= (codex:unified-exec-exec-command-collection-request-from-process
      $process
      $request
      $runtime-inputs)
   (let $yield-time-ms
     (codex:unified-exec-clamp-yield-time
       (codex:unified-exec-exec-command-request-yield-time-ms
         $request))
     (let $handles
       (codex:unified-exec-managed-process-output-handles
         $process)
       (codex:unified-exec-exec-command-collection-request
         (codex:unified-exec-output-handles-output-buffer
           $handles)
         (codex:unified-exec-output-handles-output-notify
           $handles)
         (codex:unified-exec-output-handles-output-closed
           $handles)
         (codex:unified-exec-output-handles-output-closed-notify
           $handles)
         (codex:unified-exec-output-handles-cancellation-token
           $handles)
         (codex:unified-exec-exec-command-runtime-inputs-pause-state
           $runtime-inputs)
         (+ (codex:unified-exec-exec-command-runtime-inputs-started-at-ms
              $runtime-inputs)
            $yield-time-ms)
         $yield-time-ms))))

(= (codex:unified-exec-exec-command-process-started-alive $process)
   (and
     (not (codex:unified-exec-process-has-exited $process))
     (== (codex:unified-exec-process-exit-code $process)
         CodexAbsent)))

(= (codex:unified-exec-exec-command-network-approval-id
      $deferred-network-approval)
   (codex:unified-exec-deferred-network-approval-registration-id
     $deferred-network-approval))

(= (codex:unified-exec-exec-command-store-if-alive
      $manager
      $process
      $request
      $context
      $runtime-inputs
      $cwd
      $deferred-network-approval
      True)
   (let $store-result
     (codex:unified-exec-store-process
       (codex:unified-exec-process-manager-process-store
         $manager)
       $process
       $context
       (codex:unified-exec-exec-command-request-command $request)
       (codex:unified-exec-exec-command-request-hook-command
         $request)
       $cwd
       (codex:unified-exec-exec-command-runtime-inputs-started-at-ms
         $runtime-inputs)
       (codex:unified-exec-exec-command-request-process-id
         $request)
       (codex:unified-exec-exec-command-request-tty $request)
       (codex:unified-exec-exec-command-network-approval-id
         $deferred-network-approval)
       (codex:unified-exec-exec-command-runtime-inputs-transcript
         $runtime-inputs))
     (CodexUnifiedExecExecCommandStoreDecision
       (codex:unified-exec-exec-command-process-manager-with-store
         $manager
         (codex:unified-exec-store-process-result-store
           $store-result))
       $store-result)))

(= (codex:unified-exec-exec-command-store-if-alive
      $manager
      $process
      $request
      $context
      $runtime-inputs
      $cwd
      $deferred-network-approval
      False)
   (CodexUnifiedExecExecCommandStoreDecision
     $manager
     CodexAbsent))

(= (codex:unified-exec-exec-command-store-decision-manager
      (CodexUnifiedExecExecCommandStoreDecision
        $manager
        $store-result))
   $manager)

(= (codex:unified-exec-exec-command-store-decision-store-result
      (CodexUnifiedExecExecCommandStoreDecision
        $manager
        $store-result))
   $store-result)

(= (codex:unified-exec-exec-command-finish-request
      $context
      $deferred-network-approval)
   (codex:unified-exec-exec-command-finish-deferred-network-approval-request
     (codex:unified-exec-context-session $context)
     $deferred-network-approval))

(= (codex:unified-exec-exec-command-lifecycle-base
      $cwd
      $open-session-result
      $begin-event
      $stream-request
      $process-started-alive
      $store-result
      $collection-request)
   (codex:unified-exec-exec-command-lifecycle
     $cwd
     $open-session-result
     $begin-event
     $stream-request
     $process-started-alive
     $store-result
     $collection-request
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent))

(= (codex:unified-exec-exec-command-lifecycle-with-refresh
      (CodexUnifiedExecExecCommandLifecycle
        $cwd
        $open-session-result
        $begin-event
        $stream-request
        $process-started-alive
        $store-result
        $collection-request
        $refresh-result
        $release-result
        $end-event
        $finish-deferred-request
        $sandbox-check-result)
      $new-refresh-result)
   (codex:unified-exec-exec-command-lifecycle
     $cwd
     $open-session-result
     $begin-event
     $stream-request
     $process-started-alive
     $store-result
     $collection-request
     $new-refresh-result
     $release-result
     $end-event
     $finish-deferred-request
     $sandbox-check-result))

(= (codex:unified-exec-exec-command-lifecycle-with-release
      (CodexUnifiedExecExecCommandLifecycle
        $cwd
        $open-session-result
        $begin-event
        $stream-request
        $process-started-alive
        $store-result
        $collection-request
        $refresh-result
        $release-result
        $end-event
        $finish-deferred-request
        $sandbox-check-result)
      $new-release-result)
   (codex:unified-exec-exec-command-lifecycle
     $cwd
     $open-session-result
     $begin-event
     $stream-request
     $process-started-alive
     $store-result
     $collection-request
     $refresh-result
     $new-release-result
     $end-event
     $finish-deferred-request
     $sandbox-check-result))

(= (codex:unified-exec-exec-command-lifecycle-with-end-and-finish
      (CodexUnifiedExecExecCommandLifecycle
        $cwd
        $open-session-result
        $begin-event
        $stream-request
        $process-started-alive
        $store-result
        $collection-request
        $refresh-result
        $release-result
        $end-event
        $finish-deferred-request
        $sandbox-check-result)
      $new-end-event
      $new-finish-deferred-request)
   (codex:unified-exec-exec-command-lifecycle
     $cwd
     $open-session-result
     $begin-event
     $stream-request
     $process-started-alive
     $store-result
     $collection-request
     $refresh-result
     $release-result
     $new-end-event
     $new-finish-deferred-request
     $sandbox-check-result))

(= (codex:unified-exec-exec-command-lifecycle-with-sandbox-check
      (CodexUnifiedExecExecCommandLifecycle
        $cwd
        $open-session-result
        $begin-event
        $stream-request
        $process-started-alive
        $store-result
        $collection-request
        $refresh-result
        $release-result
        $end-event
        $finish-deferred-request
        $sandbox-check-result)
      $new-sandbox-check-result)
   (codex:unified-exec-exec-command-lifecycle
     $cwd
     $open-session-result
     $begin-event
     $stream-request
     $process-started-alive
     $store-result
     $collection-request
     $refresh-result
     $release-result
     $end-event
     $finish-deferred-request
     $new-sandbox-check-result))

(= (codex:unified-exec-exec-command-after-open-error
      $manager
      $request
      $cwd
      $open-session-result)
   (let $release
     (codex:unified-exec-exec-command-release-manager
       $manager
       (codex:unified-exec-exec-command-request-process-id
         $request))
     (codex:unified-exec-exec-command-result-err
       (codex:unified-exec-exec-command-open-session-result-error
         $open-session-result)
       (codex:unified-exec-exec-command-release-result-manager
         $release)
       (codex:unified-exec-exec-command-lifecycle
         $cwd
         $open-session-result
         CodexAbsent
         CodexAbsent
         False
         CodexAbsent
         CodexAbsent
         CodexAbsent
         $release
         CodexAbsent
         CodexAbsent
         CodexAbsent))))

(= (codex:unified-exec-exec-command-after-failure
      $manager
      $request
      $context
      $runtime-inputs
      $deferred-network-approval
      $lifecycle
      $failure-message)
   (let $release
     (codex:unified-exec-exec-command-release-manager
       $manager
       (codex:unified-exec-exec-command-request-process-id
         $request))
     (let $finish
       (codex:unified-exec-exec-command-finish-request
         $context
         $deferred-network-approval)
       (let $failed-event
         (if (codex:unified-exec-exec-command-lifecycle-process-started-alive
               $lifecycle)
             CodexAbsent
             (codex:unified-exec-emit-failed-exec-end-for-unified-exec
               (codex:unified-exec-context-call-id $context)
               (codex:unified-exec-exec-command-runtime-inputs-turn-id
                 $runtime-inputs)
               (codex:unified-exec-exec-command-request-command $request)
               (codex:unified-exec-exec-command-lifecycle-cwd
                 $lifecycle)
               (format-args
                 "{}"
                 ((codex:unified-exec-exec-command-request-process-id
                    $request)))
               (codex:unified-exec-exec-command-runtime-inputs-transcript
                 $runtime-inputs)
               $failure-message
               (codex:unified-exec-exec-command-runtime-inputs-wall-time-ms
                 $runtime-inputs)
               (codex:unified-exec-exec-command-runtime-inputs-formatted-output
                 $runtime-inputs)))
         (codex:unified-exec-exec-command-result-err
           (codex:unified-exec-error-process-failed
             $failure-message)
           (codex:unified-exec-exec-command-release-result-manager
             $release)
           (codex:unified-exec-exec-command-lifecycle-with-release
             (codex:unified-exec-exec-command-lifecycle-with-end-and-finish
               $lifecycle
               $failed-event
               $finish)
             $release))))))

(= (codex:unified-exec-exec-command-after-started-alive
      $manager
      $request
      $context
      $runtime-inputs
      $lifecycle)
   (let $refresh-result
     (codex:unified-exec-exec-command-runtime-inputs-refresh-result
       $runtime-inputs)
     (let $refreshed-manager
       (codex:unified-exec-exec-command-process-manager-with-store
         $manager
         (codex:unified-exec-refresh-process-state-result-store
           $refresh-result))
       (let $status
         (codex:unified-exec-refresh-process-state-result-status
           $refresh-result)
         (let $lifecycle-with-refresh
           (codex:unified-exec-exec-command-lifecycle-with-refresh
             $lifecycle
             $refresh-result)
           (if (== (codex:unified-exec-process-status-kind $status)
                   alive)
               (codex:unified-exec-exec-command-result-ok
                 (codex:unified-exec-exec-command-output
                   $request
                   $context
                   $runtime-inputs
                   (codex:unified-exec-process-status-process-id
                     $status)
                   (codex:unified-exec-process-status-exit-code
                     $status))
                 $refreshed-manager
                 $lifecycle-with-refresh)
               (if (== (codex:unified-exec-process-status-kind $status)
                       exited)
                   (codex:unified-exec-exec-command-after-sandbox-check
                     $refreshed-manager
                     $request
                     $context
                     $runtime-inputs
                     $lifecycle-with-refresh
                     CodexAbsent
                     (codex:unified-exec-process-status-exit-code
                       $status))
                   (codex:unified-exec-exec-command-result-err
                     (codex:unified-exec-error-unknown-process-id
                       (codex:unified-exec-exec-command-request-process-id
                         $request))
                     $refreshed-manager
                     $lifecycle-with-refresh))))))))

(= (codex:unified-exec-exec-command-after-sandbox-check
      $manager
      $request
      $context
      $runtime-inputs
      $lifecycle
      $response-process-id
      $exit-code)
   (let $check
     (codex:unified-exec-exec-command-runtime-inputs-sandbox-check-result
       $runtime-inputs)
     (let $checked-lifecycle
       (codex:unified-exec-exec-command-lifecycle-with-sandbox-check
         $lifecycle
         $check)
       (if (== (codex:unified-exec-process-check-result-kind $check)
               ok)
           (codex:unified-exec-exec-command-result-ok
             (codex:unified-exec-exec-command-output
               $request
               $context
               $runtime-inputs
               $response-process-id
               $exit-code)
             $manager
             $checked-lifecycle)
           (codex:unified-exec-exec-command-result-err
             (codex:unified-exec-process-check-result-error
               $check)
             $manager
             $checked-lifecycle)))))

(= (codex:unified-exec-exec-command-after-short-lived
      $manager
      $process
      $request
      $context
      $runtime-inputs
      $deferred-network-approval
      $lifecycle)
   (let $exit-code
     (codex:unified-exec-process-exit-code $process)
     (let $exit
       (codex:unified-exec-exit-code-or-default $exit-code)
       (let $end-event
         (codex:unified-exec-emit-exec-end-for-unified-exec
           (codex:unified-exec-context-call-id $context)
           (codex:unified-exec-exec-command-runtime-inputs-turn-id
             $runtime-inputs)
           (codex:unified-exec-exec-command-request-command $request)
           (codex:unified-exec-exec-command-lifecycle-cwd $lifecycle)
           (format-args
             "{}"
             ((codex:unified-exec-exec-command-request-process-id
                $request)))
           (codex:unified-exec-exec-command-runtime-inputs-transcript
             $runtime-inputs)
           (codex:unified-exec-exec-command-runtime-inputs-collected-output
             $runtime-inputs)
           $exit
           (codex:unified-exec-exec-command-runtime-inputs-wall-time-ms
             $runtime-inputs)
           (codex:unified-exec-exec-command-runtime-inputs-formatted-output
             $runtime-inputs))
         (let $release
           (codex:unified-exec-exec-command-release-manager
             $manager
             (codex:unified-exec-exec-command-request-process-id
               $request))
           (let $finish
             (codex:unified-exec-exec-command-finish-request
               $context
               $deferred-network-approval)
             (codex:unified-exec-exec-command-after-sandbox-check
               (codex:unified-exec-exec-command-release-result-manager
                 $release)
               $request
               $context
               $runtime-inputs
               (codex:unified-exec-exec-command-lifecycle-with-release
                 (codex:unified-exec-exec-command-lifecycle-with-end-and-finish
                   $lifecycle
                   $end-event
                   $finish)
                 $release)
               CodexAbsent
               $exit-code)))))))

(= (codex:unified-exec-exec-command-after-collection
      $manager
      $process
      $request
      $context
      $runtime-inputs
      $deferred-network-approval
      $lifecycle)
   (let $failure-message
     (codex:unified-exec-exec-command-runtime-inputs-failure-message
       $runtime-inputs)
     (if (== $failure-message CodexAbsent)
         (if (codex:unified-exec-exec-command-lifecycle-process-started-alive
               $lifecycle)
             (codex:unified-exec-exec-command-after-started-alive
               $manager
               $request
               $context
               $runtime-inputs
               $lifecycle)
             (codex:unified-exec-exec-command-after-short-lived
               $manager
               $process
               $request
               $context
               $runtime-inputs
               $deferred-network-approval
               $lifecycle))
         (codex:unified-exec-exec-command-after-failure
           $manager
           $request
           $context
           $runtime-inputs
           $deferred-network-approval
           $lifecycle
           $failure-message))))

(= (codex:unified-exec-exec-command-after-open-ok
      $manager
      $request
      $context
      $runtime-inputs
      $cwd
      $open-session-result)
   (let $process
     (codex:unified-exec-exec-command-open-session-result-process
       $open-session-result)
     (let $deferred-network-approval
       (codex:unified-exec-exec-command-open-session-result-deferred-network-approval
         $open-session-result)
       (let $begin-event
         (codex:unified-exec-exec-command-begin-event
           $request
           $context
           $runtime-inputs
           $cwd)
         (let $stream-request
           (codex:unified-exec-exec-command-streaming-output-request
             $process
             $context
             (codex:unified-exec-exec-command-runtime-inputs-transcript
               $runtime-inputs))
           (let $started-alive
             (codex:unified-exec-exec-command-process-started-alive
               $process)
             (let $store-decision
               (codex:unified-exec-exec-command-store-if-alive
                 $manager
                 $process
                 $request
                 $context
                 $runtime-inputs
                 $cwd
                 $deferred-network-approval
                 $started-alive)
               (let $collection-request
                 (codex:unified-exec-exec-command-collection-request-from-process
                   $process
                   $request
                   $runtime-inputs)
                 (codex:unified-exec-exec-command-after-collection
                   (codex:unified-exec-exec-command-store-decision-manager
                     $store-decision)
                   $process
                   $request
                   $context
                   $runtime-inputs
                   $deferred-network-approval
                   (codex:unified-exec-exec-command-lifecycle-base
                     $cwd
                     $open-session-result
                     $begin-event
                     $stream-request
                     $started-alive
                     (codex:unified-exec-exec-command-store-decision-store-result
                       $store-decision)
                     $collection-request))))))))))

(= (codex:unified-exec-exec-command
      $manager
      $request
      $context
      $runtime-inputs)
   (let $cwd
     (codex:unified-exec-exec-command-cwd
       $request
       $runtime-inputs)
     (let $open-session-result
       (codex:unified-exec-exec-command-runtime-inputs-open-session-result
         $runtime-inputs)
       (if (== (codex:unified-exec-exec-command-open-session-result-kind
                 $open-session-result)
               ok)
           (codex:unified-exec-exec-command-after-open-ok
             $manager
             $request
             $context
             $runtime-inputs
             $cwd
             $open-session-result)
           (codex:unified-exec-exec-command-after-open-error
             $manager
             $request
             $cwd
             $open-session-result)))))
