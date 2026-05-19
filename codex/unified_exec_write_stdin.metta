; Rust-faithful pure unified-exec write_stdin slice.
;
; This ports deterministic control flow from:
; - openai-codex/codex-rs/core/src/unified_exec/process_manager.rs
;   - UnifiedExecProcessManager::write_stdin
;
; Covered in this increment:
; - `prepare_process_handles` integration and `last_used` store update
; - non-TTY stdin rejection after preparation
; - write-success, write-error, process-failed, exited, alive, and unknown
;   status branches
; - response materialization as `ExecCommandToolOutput`
; - computed `yield_time_ms` used for output collection
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust performs process writes, a 100 ms post-write sleep, output collection,
;   random chunk-id generation, and reads `process.failure_message()` through
;   shared runtime state. This pure boundary receives those runtime results as
;   explicit `CodexUnifiedExecWriteStdinRuntimeInputs`, and returns the same
;   store/result branches Rust would produce from them.
; - Rust passes an absolute `Instant` deadline into
;   `collect_output_until_deadline`. This slice materializes a collection
;   request with the same handles and computed `yield_time_ms`; the later async
;   runtime can turn that duration into the concrete deadline next to the clock.
; - Rust raw output is bytes and converts with `String::from_utf8_lossy`. The
;   surrounding CeTTa exec output boundary currently carries text, so collected
;   output is represented as text here, matching existing Codex tool surfaces.

!(import! &self context)
!(import! &self str)
!(import! &self unified_exec_prepared_process)

(= (codex:unified-exec-process-manager-with-store
      (CodexUnifiedExecProcessManager
        $process-store
        $max-write-stdin-yield-time-ms)
      $new-process-store)
   (CodexUnifiedExecProcessManager
     $new-process-store
     $max-write-stdin-yield-time-ms))

(= (codex:unified-exec-process-manager-release
      $manager
      $process-id)
   (codex:unified-exec-process-manager-with-store
     $manager
     (codex:unified-exec-process-store-remove-result-store
       (codex:unified-exec-process-store-release
         (codex:unified-exec-process-manager-process-store $manager)
         $process-id))))

(= (codex:unified-exec-process-write-ok)
   CodexUnifiedExecProcessWriteOk)

(= (codex:unified-exec-process-write-err $error)
   (CodexUnifiedExecProcessWriteErr $error))

(= (codex:unified-exec-process-write-result-kind
      CodexUnifiedExecProcessWriteOk)
   ok)

(= (codex:unified-exec-process-write-result-kind
      (CodexUnifiedExecProcessWriteErr $error))
   err)

(= (codex:unified-exec-process-write-result-error
      (CodexUnifiedExecProcessWriteErr $error))
   $error)

(= (codex:unified-exec-write-stdin-runtime-inputs
      $write-result
      $collected-output
      $wall-time-ms
      $chunk-id
      $post-collection-failure-message)
   (CodexUnifiedExecWriteStdinRuntimeInputs
     $write-result
     $collected-output
     $wall-time-ms
     $chunk-id
     $post-collection-failure-message))

(= (codex:unified-exec-write-stdin-runtime-inputs-write-result
      (CodexUnifiedExecWriteStdinRuntimeInputs
        $write-result
        $collected-output
        $wall-time-ms
        $chunk-id
        $post-collection-failure-message))
   $write-result)

(= (codex:unified-exec-write-stdin-runtime-inputs-collected-output
      (CodexUnifiedExecWriteStdinRuntimeInputs
        $write-result
        $collected-output
        $wall-time-ms
        $chunk-id
        $post-collection-failure-message))
   $collected-output)

(= (codex:unified-exec-write-stdin-runtime-inputs-wall-time-ms
      (CodexUnifiedExecWriteStdinRuntimeInputs
        $write-result
        $collected-output
        $wall-time-ms
        $chunk-id
        $post-collection-failure-message))
   $wall-time-ms)

(= (codex:unified-exec-write-stdin-runtime-inputs-chunk-id
      (CodexUnifiedExecWriteStdinRuntimeInputs
        $write-result
        $collected-output
        $wall-time-ms
        $chunk-id
        $post-collection-failure-message))
   $chunk-id)

(= (codex:unified-exec-write-stdin-runtime-inputs-failure-message
      (CodexUnifiedExecWriteStdinRuntimeInputs
        $write-result
        $collected-output
        $wall-time-ms
        $chunk-id
        $post-collection-failure-message))
   $post-collection-failure-message)

(= (codex:unified-exec-write-stdin-collection-request
      $output-buffer
      $output-notify
      $output-closed
      $output-closed-notify
      $cancellation-token
      $pause-state
      $yield-time-ms)
   (CodexUnifiedExecWriteStdinCollectionRequest
     $output-buffer
     $output-notify
     $output-closed
     $output-closed-notify
     $cancellation-token
     $pause-state
     $yield-time-ms))

(= (codex:unified-exec-write-stdin-collection-request-output-buffer
      (CodexUnifiedExecWriteStdinCollectionRequest
        $output-buffer
        $output-notify
        $output-closed
        $output-closed-notify
        $cancellation-token
        $pause-state
        $yield-time-ms))
   $output-buffer)

(= (codex:unified-exec-write-stdin-collection-request-output-notify
      (CodexUnifiedExecWriteStdinCollectionRequest
        $output-buffer
        $output-notify
        $output-closed
        $output-closed-notify
        $cancellation-token
        $pause-state
        $yield-time-ms))
   $output-notify)

(= (codex:unified-exec-write-stdin-collection-request-output-closed
      (CodexUnifiedExecWriteStdinCollectionRequest
        $output-buffer
        $output-notify
        $output-closed
        $output-closed-notify
        $cancellation-token
        $pause-state
        $yield-time-ms))
   $output-closed)

(= (codex:unified-exec-write-stdin-collection-request-output-closed-notify
      (CodexUnifiedExecWriteStdinCollectionRequest
        $output-buffer
        $output-notify
        $output-closed
        $output-closed-notify
        $cancellation-token
        $pause-state
        $yield-time-ms))
   $output-closed-notify)

(= (codex:unified-exec-write-stdin-collection-request-cancellation-token
      (CodexUnifiedExecWriteStdinCollectionRequest
        $output-buffer
        $output-notify
        $output-closed
        $output-closed-notify
        $cancellation-token
        $pause-state
        $yield-time-ms))
   $cancellation-token)

(= (codex:unified-exec-write-stdin-collection-request-pause-state
      (CodexUnifiedExecWriteStdinCollectionRequest
        $output-buffer
        $output-notify
        $output-closed
        $output-closed-notify
        $cancellation-token
        $pause-state
        $yield-time-ms))
   $pause-state)

(= (codex:unified-exec-write-stdin-collection-request-yield-time-ms
      (CodexUnifiedExecWriteStdinCollectionRequest
        $output-buffer
        $output-notify
        $output-closed
        $output-closed-notify
        $cancellation-token
        $pause-state
        $yield-time-ms))
   $yield-time-ms)

(= (codex:unified-exec-write-stdin-result-ok
      $output
      $manager
      $post-write-sleep-ms
      $collection-request)
   (CodexUnifiedExecWriteStdinResultOk
     $output
     $manager
     $post-write-sleep-ms
     $collection-request))

(= (codex:unified-exec-write-stdin-result-err
      $error
      $manager
      $post-write-sleep-ms
      $collection-request)
   (CodexUnifiedExecWriteStdinResultErr
     $error
     $manager
     $post-write-sleep-ms
     $collection-request))

(= (codex:unified-exec-write-stdin-result-kind
      (CodexUnifiedExecWriteStdinResultOk
        $output
        $manager
        $post-write-sleep-ms
        $collection-request))
   ok)

(= (codex:unified-exec-write-stdin-result-kind
      (CodexUnifiedExecWriteStdinResultErr
        $error
        $manager
        $post-write-sleep-ms
        $collection-request))
   err)

(= (codex:unified-exec-write-stdin-result-output
      (CodexUnifiedExecWriteStdinResultOk
        $output
        $manager
        $post-write-sleep-ms
        $collection-request))
   $output)

(= (codex:unified-exec-write-stdin-result-error
      (CodexUnifiedExecWriteStdinResultErr
        $error
        $manager
        $post-write-sleep-ms
        $collection-request))
   $error)

(= (codex:unified-exec-write-stdin-result-manager
      (CodexUnifiedExecWriteStdinResultOk
        $output
        $manager
        $post-write-sleep-ms
        $collection-request))
   $manager)

(= (codex:unified-exec-write-stdin-result-manager
      (CodexUnifiedExecWriteStdinResultErr
        $error
        $manager
        $post-write-sleep-ms
        $collection-request))
   $manager)

(= (codex:unified-exec-write-stdin-result-post-write-sleep-ms
      (CodexUnifiedExecWriteStdinResultOk
        $output
        $manager
        $post-write-sleep-ms
        $collection-request))
   $post-write-sleep-ms)

(= (codex:unified-exec-write-stdin-result-post-write-sleep-ms
      (CodexUnifiedExecWriteStdinResultErr
        $error
        $manager
        $post-write-sleep-ms
        $collection-request))
   $post-write-sleep-ms)

(= (codex:unified-exec-write-stdin-result-collection-request
      (CodexUnifiedExecWriteStdinResultOk
        $output
        $manager
        $post-write-sleep-ms
        $collection-request))
   $collection-request)

(= (codex:unified-exec-write-stdin-result-collection-request
      (CodexUnifiedExecWriteStdinResultErr
        $error
        $manager
        $post-write-sleep-ms
        $collection-request))
   $collection-request)

(= (codex:unified-exec-exec-output-event-call-id
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
   $event-call-id)

(= (codex:unified-exec-exec-output-chunk-id
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
   $chunk-id)

(= (codex:unified-exec-exec-output-wall-time-ms
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
   $wall-time-ms)

(= (codex:unified-exec-exec-output-raw-output
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
   $raw-output)

(= (codex:unified-exec-exec-output-max-output-tokens
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
   $max-output-tokens)

(= (codex:unified-exec-exec-output-process-id
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

(= (codex:unified-exec-exec-output-exit-code
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

(= (codex:unified-exec-exec-output-original-token-count
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

(= (codex:unified-exec-exec-output-hook-command
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
   $hook-command)

(= (codex:unified-exec-approx-token-count $text)
   (codex:unified-exec-approx-token-count-from
     (str-length $text)
     0))

(= (codex:unified-exec-approx-token-count-from $remaining-bytes $acc)
   (if (<= $remaining-bytes 0)
       $acc
       (codex:unified-exec-approx-token-count-from
         (- $remaining-bytes 4)
         (+ $acc 1))))

(= (codex:unified-exec-write-stdin-output
      $event-call-id
      $chunk-id
      $wall-time-ms
      $raw-output
      $max-output-tokens
      $process-id
      $exit-code
      $hook-command)
   (codex:exec-command-tool-output
     $event-call-id
     $chunk-id
     $wall-time-ms
     $raw-output
     $max-output-tokens
     $process-id
     $exit-code
     (codex:unified-exec-approx-token-count $raw-output)
     $hook-command))

(= (codex:unified-exec-write-stdin-collection-request-from-prepared
      $manager
      $request
      $prepared)
   (codex:unified-exec-write-stdin-collection-request
     (codex:unified-exec-prepared-process-handles-output-buffer
       $prepared)
     (codex:unified-exec-prepared-process-handles-output-notify
       $prepared)
     (codex:unified-exec-prepared-process-handles-output-closed
       $prepared)
     (codex:unified-exec-prepared-process-handles-output-closed-notify
       $prepared)
     (codex:unified-exec-prepared-process-handles-cancellation-token
       $prepared)
     (codex:unified-exec-prepared-process-handles-pause-state
       $prepared)
     (codex:unified-exec-write-stdin-yield-time-ms
       $manager
       $request)))

(= (codex:unified-exec-write-stdin-after-collect
      $manager
      $request
      $prepared
      $status-after-write
      $runtime-inputs
      $post-write-sleep-ms)
   (let $collection-request
     (codex:unified-exec-write-stdin-collection-request-from-prepared
       $manager
       $request
       $prepared)
     (let $failure-message
       (codex:unified-exec-write-stdin-runtime-inputs-failure-message
         $runtime-inputs)
       (if (== $failure-message CodexAbsent)
           (codex:unified-exec-write-stdin-after-collect-no-failure
             $manager
             $request
             $prepared
             $status-after-write
             $runtime-inputs
             $post-write-sleep-ms
             $collection-request)
           (codex:unified-exec-write-stdin-result-err
             (codex:unified-exec-error-process-failed
               $failure-message)
             (codex:unified-exec-process-manager-release
               $manager
               (codex:unified-exec-write-stdin-request-process-id
                 $request))
             $post-write-sleep-ms
             $collection-request)))))

(= (codex:unified-exec-write-stdin-after-collect-no-failure
      $manager
      $request
      $prepared
      $status-after-write
      $runtime-inputs
      $post-write-sleep-ms
      $collection-request)
   (if (== $status-after-write CodexAbsent)
       (let $refresh
         (codex:unified-exec-refresh-process-state
           (codex:unified-exec-process-manager-process-store
             $manager)
           (codex:unified-exec-write-stdin-request-process-id
             $request))
         (codex:unified-exec-write-stdin-from-status
           (codex:unified-exec-process-manager-with-store
             $manager
             (codex:unified-exec-refresh-process-state-result-store
               $refresh))
           $request
           $prepared
           (codex:unified-exec-refresh-process-state-result-status
             $refresh)
           $runtime-inputs
           $post-write-sleep-ms
           $collection-request))
       (codex:unified-exec-write-stdin-from-status
         $manager
         $request
         $prepared
         $status-after-write
         $runtime-inputs
         $post-write-sleep-ms
         $collection-request)))

(= (codex:unified-exec-write-stdin-from-status
      $manager
      $request
      $prepared
      $status
      $runtime-inputs
      $post-write-sleep-ms
      $collection-request)
   (let $status-kind
     (codex:unified-exec-process-status-kind $status)
     (if (== $status-kind alive)
         (codex:unified-exec-write-stdin-result-ok
           (codex:unified-exec-write-stdin-output
             (codex:unified-exec-process-status-call-id $status)
             (codex:unified-exec-write-stdin-runtime-inputs-chunk-id
               $runtime-inputs)
             (codex:unified-exec-write-stdin-runtime-inputs-wall-time-ms
               $runtime-inputs)
             (codex:unified-exec-write-stdin-runtime-inputs-collected-output
               $runtime-inputs)
             (codex:unified-exec-write-stdin-request-max-output-tokens
               $request)
             (codex:unified-exec-process-status-process-id $status)
             (codex:unified-exec-process-status-exit-code $status)
             (codex:unified-exec-prepared-process-handles-hook-command
               $prepared))
           $manager
           $post-write-sleep-ms
           $collection-request)
         (if (== $status-kind exited)
             (let $entry
               (codex:unified-exec-process-status-entry $status)
               (codex:unified-exec-write-stdin-result-ok
                 (codex:unified-exec-write-stdin-output
                   (codex:unified-exec-process-entry-call-id $entry)
                   (codex:unified-exec-write-stdin-runtime-inputs-chunk-id
                     $runtime-inputs)
                   (codex:unified-exec-write-stdin-runtime-inputs-wall-time-ms
                     $runtime-inputs)
                   (codex:unified-exec-write-stdin-runtime-inputs-collected-output
                     $runtime-inputs)
                   (codex:unified-exec-write-stdin-request-max-output-tokens
                     $request)
                   CodexAbsent
                   (codex:unified-exec-process-status-exit-code
                     $status)
                   (codex:unified-exec-prepared-process-handles-hook-command
                     $prepared))
                 $manager
                 $post-write-sleep-ms
                 $collection-request))
             (codex:unified-exec-write-stdin-result-err
               (codex:unified-exec-error-unknown-process-id
                 (codex:unified-exec-write-stdin-request-process-id
                   $request))
               $manager
               $post-write-sleep-ms
               $collection-request)))))

(= (codex:unified-exec-write-stdin-after-write-error
      $manager
      $request
      $prepared
      $runtime-inputs
      $write-error)
   (let $refresh
     (codex:unified-exec-refresh-process-state
       (codex:unified-exec-process-manager-process-store
         $manager)
       (codex:unified-exec-write-stdin-request-process-id
         $request))
     (let $refreshed-manager
       (codex:unified-exec-process-manager-with-store
         $manager
         (codex:unified-exec-refresh-process-state-result-store
           $refresh))
       (let $status
         (codex:unified-exec-refresh-process-state-result-status
           $refresh)
         (if (== (codex:unified-exec-process-status-kind $status)
                 exited)
             (codex:unified-exec-write-stdin-after-collect
               $refreshed-manager
               $request
               $prepared
               $status
               $runtime-inputs
               CodexAbsent)
             (if (== (codex:unified-exec-error-kind $write-error)
                     process_failed)
                 (codex:unified-exec-write-stdin-result-err
                   $write-error
                   (codex:unified-exec-process-manager-release
                     $refreshed-manager
                     (codex:unified-exec-write-stdin-request-process-id
                       $request))
                   CodexAbsent
                   CodexAbsent)
                 (codex:unified-exec-write-stdin-result-err
                   $write-error
                   $refreshed-manager
                   CodexAbsent
                   CodexAbsent)))))))

(= (codex:unified-exec-write-stdin-after-prepare-ok
      $manager
      $request
      $prepared
      $runtime-inputs)
   (let $input
     (codex:unified-exec-write-stdin-request-input $request)
     (if (== $input "")
         (codex:unified-exec-write-stdin-after-collect
           $manager
           $request
           $prepared
           CodexAbsent
           $runtime-inputs
           CodexAbsent)
         (if (codex:unified-exec-prepared-process-handles-tty
               $prepared)
             (let $write-result
               (codex:unified-exec-write-stdin-runtime-inputs-write-result
                 $runtime-inputs)
               (if (== (codex:unified-exec-process-write-result-kind
                         $write-result)
                       ok)
                   (codex:unified-exec-write-stdin-after-collect
                     $manager
                     $request
                     $prepared
                     CodexAbsent
                     $runtime-inputs
                     100)
                   (codex:unified-exec-write-stdin-after-write-error
                     $manager
                     $request
                     $prepared
                     $runtime-inputs
                     (codex:unified-exec-process-write-result-error
                       $write-result))))
             (codex:unified-exec-write-stdin-result-err
               (codex:unified-exec-error-stdin-closed)
               $manager
               CodexAbsent
               CodexAbsent)))))

(= (codex:unified-exec-write-stdin
      $manager
      $request
      $now
      $runtime-inputs)
   (let $prepare-result
     (codex:unified-exec-prepare-process-handles
       (codex:unified-exec-process-manager-process-store
         $manager)
       (codex:unified-exec-write-stdin-request-process-id
         $request)
       $now)
     (let $prepared-manager
       (codex:unified-exec-process-manager-with-store
         $manager
         (codex:unified-exec-prepare-process-handles-result-store
           $prepare-result))
       (if (== (codex:unified-exec-prepare-process-handles-result-kind
                 $prepare-result)
               ok)
           (codex:unified-exec-write-stdin-after-prepare-ok
             $prepared-manager
             $request
             (codex:unified-exec-prepare-process-handles-result-prepared
               $prepare-result)
             $runtime-inputs)
           (codex:unified-exec-write-stdin-result-err
             (codex:unified-exec-prepare-process-handles-result-error
               $prepare-result)
             $prepared-manager
             CodexAbsent
             CodexAbsent)))))
