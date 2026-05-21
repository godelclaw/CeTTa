; Rust-faithful pure unified-exec process runtime-constructor slice.
;
; This ports deterministic branch and error behavior from:
; - openai-codex/codex-rs/core/src/unified_exec/process.rs
;   - UnifiedExecProcess::new
;   - UnifiedExecProcess::has_exited / exit_code / failure_message
;   - UnifiedExecProcess::signal_exit
;   - UnifiedExecProcess::check_for_sandbox_denial_with_text
;   - UnifiedExecProcess::from_spawned
;   - UnifiedExecProcess::from_exec_server_started
; - openai-codex/codex-rs/core/src/exec.rs
;   - is_likely_sandbox_denied
; - openai-codex/codex-rs/utils/output-truncation/src/lib.rs
;   - formatted_truncate_text for the sandbox-denial message
;
; Covered in this increment:
; - default managed-process construction and handle-specific state queries
; - local spawned-PTY constructor early-exit, grace-exit, and watcher branches
; - exec-server constructor grace observation branch
; - sandbox-denial error construction used by both constructors
; - local output task / exec-server output task / local exit watcher request
;   materialization at the same branch points where Rust spawns async tasks
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust creates Arc/Notify/AtomicBool/CancellationToken/watch/broadcast values
;   inside `UnifiedExecProcess::new`. This pure boundary receives those runtime
;   handles as `CodexUnifiedExecProcessRuntimeResources`, preserving field
;   placement and default state without allocating side-effectful objects here.
; - Rust combines output receivers, spawns output tasks, polls one-shot exit
;   receivers, and waits for early-exit grace periods asynchronously. This port
;   receives those observations explicitly and returns task/watch requests for
;   the future runtime layer to execute at the same branch points.
; - Rust lowercases sandbox output with Unicode `to_lowercase()`. The current
;   CeTTa string surface has byte slicing but no Unicode case-fold primitive, so
;   this slice performs deterministic ASCII lowercasing. The checked denial
;   keywords are ASCII, so Rust-visible keyword behavior is preserved for the
;   command-output strings these heuristics target.
; - Rust's SIGSYS comparison is compiled only on Unix and is meaningful for the
;   LinuxSeccomp sandbox. This pure helper takes an explicit host-platform tag
;   and uses the Linux SIGSYS shell exit code for the LinuxSeccomp branch.

!(import! &self list)
!(import! &self str)
!(import! &self str_middle)
!(import! &self sandbox_tags)
!(import! &self unified_exec_core)
!(import! &self unified_exec_open_session)
!(import! &self unified_exec_prepared_process)
!(import! &self codex:output_truncation)
!(import! &self codex:string_truncate)

(= (codex:unified-exec-early-exit-grace-period-ms)
   150)

(= (codex:unified-exec-sandbox-denial-notify-wait-ms)
   20)

(= (codex:unified-exec-linux-sigsys-exit-code)
   159)

(= (codex:unified-exec-process-handle-local
      $session
      $has-exited
      $exit-code)
   (CodexUnifiedExecProcessHandleLocal
     $session
     $has-exited
     $exit-code))

(= (codex:unified-exec-process-handle-exec-server $process)
   (CodexUnifiedExecProcessHandleExecServer $process))

(= (codex:unified-exec-process-handle-kind
      (CodexUnifiedExecProcessHandleLocal
        $session
        $has-exited
        $exit-code))
   local)

(= (codex:unified-exec-process-handle-kind
      (CodexUnifiedExecProcessHandleExecServer $process))
   exec_server)

(= (codex:unified-exec-process-handle-local-session
      (CodexUnifiedExecProcessHandleLocal
        $session
        $has-exited
        $exit-code))
   $session)

(= (codex:unified-exec-process-handle-local-has-exited
      (CodexUnifiedExecProcessHandleLocal
        $session
        $has-exited
        $exit-code))
   $has-exited)

(= (codex:unified-exec-process-handle-local-exit-code
      (CodexUnifiedExecProcessHandleLocal
        $session
        $has-exited
        $exit-code))
   $exit-code)

(= (codex:unified-exec-process-handle-exec-server-process
      (CodexUnifiedExecProcessHandleExecServer $process))
   $process)

(= (codex:unified-exec-process-runtime-resources
      $output-buffer
      $output-notify
      $output-closed
      $output-closed-notify
      $cancellation-token
      $output-drained
      $output-tx
      $state-tx
      $state-rx)
   (CodexUnifiedExecProcessRuntimeResources
     $output-buffer
     $output-notify
     $output-closed
     $output-closed-notify
     $cancellation-token
     $output-drained
     $output-tx
     $state-tx
     $state-rx))

(= (codex:unified-exec-process-runtime-resources-output-buffer
      (CodexUnifiedExecProcessRuntimeResources
        $output-buffer
        $output-notify
        $output-closed
        $output-closed-notify
        $cancellation-token
        $output-drained
        $output-tx
        $state-tx
        $state-rx))
   $output-buffer)

(= (codex:unified-exec-process-runtime-resources-output-notify
      (CodexUnifiedExecProcessRuntimeResources
        $output-buffer
        $output-notify
        $output-closed
        $output-closed-notify
        $cancellation-token
        $output-drained
        $output-tx
        $state-tx
        $state-rx))
   $output-notify)

(= (codex:unified-exec-process-runtime-resources-output-closed
      (CodexUnifiedExecProcessRuntimeResources
        $output-buffer
        $output-notify
        $output-closed
        $output-closed-notify
        $cancellation-token
        $output-drained
        $output-tx
        $state-tx
        $state-rx))
   $output-closed)

(= (codex:unified-exec-process-runtime-resources-output-closed-notify
      (CodexUnifiedExecProcessRuntimeResources
        $output-buffer
        $output-notify
        $output-closed
        $output-closed-notify
        $cancellation-token
        $output-drained
        $output-tx
        $state-tx
        $state-rx))
   $output-closed-notify)

(= (codex:unified-exec-process-runtime-resources-cancellation-token
      (CodexUnifiedExecProcessRuntimeResources
        $output-buffer
        $output-notify
        $output-closed
        $output-closed-notify
        $cancellation-token
        $output-drained
        $output-tx
        $state-tx
        $state-rx))
   $cancellation-token)

(= (codex:unified-exec-process-runtime-resources-output-drained
      (CodexUnifiedExecProcessRuntimeResources
        $output-buffer
        $output-notify
        $output-closed
        $output-closed-notify
        $cancellation-token
        $output-drained
        $output-tx
        $state-tx
        $state-rx))
   $output-drained)

(= (codex:unified-exec-process-runtime-resources-output-tx
      (CodexUnifiedExecProcessRuntimeResources
        $output-buffer
        $output-notify
        $output-closed
        $output-closed-notify
        $cancellation-token
        $output-drained
        $output-tx
        $state-tx
        $state-rx))
   $output-tx)

(= (codex:unified-exec-process-runtime-resources-state-tx
      (CodexUnifiedExecProcessRuntimeResources
        $output-buffer
        $output-notify
        $output-closed
        $output-closed-notify
        $cancellation-token
        $output-drained
        $output-tx
        $state-tx
        $state-rx))
   $state-tx)

(= (codex:unified-exec-process-runtime-resources-state-rx
      (CodexUnifiedExecProcessRuntimeResources
        $output-buffer
        $output-notify
        $output-closed
        $output-closed-notify
        $cancellation-token
        $output-drained
        $output-tx
        $state-tx
        $state-rx))
   $state-rx)

(= (codex:unified-exec-process-output-handles-from-resources $resources)
   (codex:unified-exec-output-handles
     (codex:unified-exec-process-runtime-resources-output-buffer
       $resources)
     (codex:unified-exec-process-runtime-resources-output-notify
       $resources)
     (codex:unified-exec-process-runtime-resources-output-closed
       $resources)
     (codex:unified-exec-process-runtime-resources-output-closed-notify
       $resources)
     (codex:unified-exec-process-runtime-resources-cancellation-token
       $resources)))

(= (codex:unified-exec-managed-process
      $process-handle
      $output-handles
      $output-task
      $output-drained
      $state
      $sandbox-type
      $spawn-lifecycle
      $exit-watcher
      $cancellation-cancelled)
   (CodexUnifiedExecManagedProcess
     $process-handle
     $output-handles
     $output-task
     $output-drained
     $state
     $sandbox-type
     $spawn-lifecycle
     $exit-watcher
     $cancellation-cancelled))

(= (codex:unified-exec-managed-process-handle
      (CodexUnifiedExecManagedProcess
        $process-handle
        $output-handles
        $output-task
        $output-drained
        $state
        $sandbox-type
        $spawn-lifecycle
        $exit-watcher
        $cancellation-cancelled))
   $process-handle)

(= (codex:unified-exec-managed-process-output-handles
      (CodexUnifiedExecManagedProcess
        $process-handle
        $output-handles
        $output-task
        $output-drained
        $state
        $sandbox-type
        $spawn-lifecycle
        $exit-watcher
        $cancellation-cancelled))
   $output-handles)

(= (codex:unified-exec-managed-process-output-task
      (CodexUnifiedExecManagedProcess
        $process-handle
        $output-handles
        $output-task
        $output-drained
        $state
        $sandbox-type
        $spawn-lifecycle
        $exit-watcher
        $cancellation-cancelled))
   $output-task)

(= (codex:unified-exec-managed-process-output-drained
      (CodexUnifiedExecManagedProcess
        $process-handle
        $output-handles
        $output-task
        $output-drained
        $state
        $sandbox-type
        $spawn-lifecycle
        $exit-watcher
        $cancellation-cancelled))
   $output-drained)

(= (codex:unified-exec-managed-process-state
      (CodexUnifiedExecManagedProcess
        $process-handle
        $output-handles
        $output-task
        $output-drained
        $state
        $sandbox-type
        $spawn-lifecycle
        $exit-watcher
        $cancellation-cancelled))
   $state)

(= (codex:unified-exec-managed-process-sandbox-type
      (CodexUnifiedExecManagedProcess
        $process-handle
        $output-handles
        $output-task
        $output-drained
        $state
        $sandbox-type
        $spawn-lifecycle
        $exit-watcher
        $cancellation-cancelled))
   $sandbox-type)

(= (codex:unified-exec-managed-process-spawn-lifecycle
      (CodexUnifiedExecManagedProcess
        $process-handle
        $output-handles
        $output-task
        $output-drained
        $state
        $sandbox-type
        $spawn-lifecycle
        $exit-watcher
        $cancellation-cancelled))
   $spawn-lifecycle)

(= (codex:unified-exec-managed-process-exit-watcher
      (CodexUnifiedExecManagedProcess
        $process-handle
        $output-handles
        $output-task
        $output-drained
        $state
        $sandbox-type
        $spawn-lifecycle
        $exit-watcher
        $cancellation-cancelled))
   $exit-watcher)

(= (codex:unified-exec-managed-process-cancellation-cancelled
      (CodexUnifiedExecManagedProcess
        $process-handle
        $output-handles
        $output-task
        $output-drained
        $state
        $sandbox-type
        $spawn-lifecycle
        $exit-watcher
        $cancellation-cancelled))
   $cancellation-cancelled)

(= (codex:unified-exec-managed-process-with-state
      (CodexUnifiedExecManagedProcess
        $process-handle
        $output-handles
        $output-task
        $output-drained
        $state
        $sandbox-type
        $spawn-lifecycle
        $exit-watcher
        $cancellation-cancelled)
      $new-state)
   (CodexUnifiedExecManagedProcess
     $process-handle
     $output-handles
     $output-task
     $output-drained
     $new-state
     $sandbox-type
     $spawn-lifecycle
     $exit-watcher
     $cancellation-cancelled))

(= (codex:unified-exec-managed-process-with-output-task
      (CodexUnifiedExecManagedProcess
        $process-handle
        $output-handles
        $output-task
        $output-drained
        $state
        $sandbox-type
        $spawn-lifecycle
        $exit-watcher
        $cancellation-cancelled)
      $new-output-task)
   (CodexUnifiedExecManagedProcess
     $process-handle
     $output-handles
     $new-output-task
     $output-drained
     $state
     $sandbox-type
     $spawn-lifecycle
     $exit-watcher
     $cancellation-cancelled))

(= (codex:unified-exec-managed-process-with-exit-watcher
      (CodexUnifiedExecManagedProcess
        $process-handle
        $output-handles
        $output-task
        $output-drained
        $state
        $sandbox-type
        $spawn-lifecycle
        $exit-watcher
        $cancellation-cancelled)
      $new-exit-watcher)
   (CodexUnifiedExecManagedProcess
     $process-handle
     $output-handles
     $output-task
     $output-drained
     $state
     $sandbox-type
     $spawn-lifecycle
     $new-exit-watcher
     $cancellation-cancelled))

(= (codex:unified-exec-managed-process-with-cancellation-cancelled
      (CodexUnifiedExecManagedProcess
        $process-handle
        $output-handles
        $output-task
        $output-drained
        $state
        $sandbox-type
        $spawn-lifecycle
        $exit-watcher
        $cancellation-cancelled)
      $new-cancellation-cancelled)
   (CodexUnifiedExecManagedProcess
     $process-handle
     $output-handles
     $output-task
     $output-drained
     $state
     $sandbox-type
     $spawn-lifecycle
     $exit-watcher
     $new-cancellation-cancelled))

(= (codex:unified-exec-process-new
      $process-handle
      $sandbox-type
      $spawn-lifecycle
      $resources)
   (codex:unified-exec-managed-process
     $process-handle
     (codex:unified-exec-process-output-handles-from-resources
       $resources)
     CodexAbsent
     (codex:unified-exec-process-runtime-resources-output-drained
       $resources)
     (codex:unified-exec-process-state-default)
     $sandbox-type
     $spawn-lifecycle
     CodexAbsent
     False))

(= (codex:unified-exec-process-has-exited $process)
   (let $state
     (codex:unified-exec-managed-process-state $process)
     (let $handle
       (codex:unified-exec-managed-process-handle $process)
       (if (== (codex:unified-exec-process-handle-kind $handle) local)
           (or
             (codex:unified-exec-process-state-has-exited $state)
             (codex:unified-exec-process-handle-local-has-exited
               $handle))
           (codex:unified-exec-process-state-has-exited $state)))))

(= (codex:unified-exec-process-exit-code $process)
   (let $state
     (codex:unified-exec-managed-process-state $process)
     (let $state-exit-code
       (codex:unified-exec-process-state-exit-code $state)
       (if (not (== $state-exit-code CodexAbsent))
           $state-exit-code
           (let $handle
             (codex:unified-exec-managed-process-handle $process)
             (if (== (codex:unified-exec-process-handle-kind $handle)
                     local)
                 (codex:unified-exec-process-handle-local-exit-code
                   $handle)
                 CodexAbsent))))))

(= (codex:unified-exec-process-failure-message $process)
   (codex:unified-exec-process-state-failure-message
     (codex:unified-exec-managed-process-state $process)))

(= (codex:unified-exec-process-signal-exit
      $process
      $exit-code)
   (codex:unified-exec-managed-process-with-cancellation-cancelled
     (codex:unified-exec-managed-process-with-state
       $process
       (codex:unified-exec-process-state-exited
         (codex:unified-exec-managed-process-state $process)
         $exit-code))
     True))

(= (codex:unified-exec-combined-output-receiver
      $stdout-rx
      $stderr-rx)
   (CodexUnifiedExecCombinedOutputReceiver $stdout-rx $stderr-rx))

(= (codex:unified-exec-local-output-task-request
      $output-rx
      $output-handles
      $output-tx)
   (CodexUnifiedExecLocalOutputTaskRequest
     $output-rx
     $output-handles
     $output-tx))

(= (codex:unified-exec-local-output-task-request-kind
      (CodexUnifiedExecLocalOutputTaskRequest
        $output-rx
        $output-handles
        $output-tx))
   local_output_task)

(= (codex:unified-exec-exec-server-output-task-request
      $started
      $output-handles
      $output-tx
      $state-tx)
   (CodexUnifiedExecExecServerOutputTaskRequest
     $started
     $output-handles
     $output-tx
     $state-tx))

(= (codex:unified-exec-exec-server-output-task-request-kind
      (CodexUnifiedExecExecServerOutputTaskRequest
        $started
        $output-handles
        $output-tx
        $state-tx))
   exec_server_output_task)

(= (codex:unified-exec-local-exit-watcher-request
      $exit-rx
      $state-tx
      $cancellation-token)
   (CodexUnifiedExecLocalExitWatcherRequest
     $exit-rx
     $state-tx
     $cancellation-token))

(= (codex:unified-exec-local-exit-watcher-request-kind
      (CodexUnifiedExecLocalExitWatcherRequest
        $exit-rx
        $state-tx
        $cancellation-token))
   local_exit_watcher)

(= (codex:unified-exec-local-exit-poll-ok $exit-code)
   (CodexUnifiedExecLocalExitPollOk $exit-code))

(= (codex:unified-exec-local-exit-poll-closed)
   CodexUnifiedExecLocalExitPollClosed)

(= (codex:unified-exec-local-exit-poll-empty)
   CodexUnifiedExecLocalExitPollEmpty)

(= (codex:unified-exec-local-exit-poll-kind
      (CodexUnifiedExecLocalExitPollOk $exit-code))
   ok)

(= (codex:unified-exec-local-exit-poll-kind
      CodexUnifiedExecLocalExitPollClosed)
   closed)

(= (codex:unified-exec-local-exit-poll-kind
      CodexUnifiedExecLocalExitPollEmpty)
   empty)

(= (codex:unified-exec-local-exit-poll-exit-code
      (CodexUnifiedExecLocalExitPollOk $exit-code))
   $exit-code)

(= (codex:unified-exec-local-exit-grace-ok $exit-code)
   (CodexUnifiedExecLocalExitGraceOk $exit-code))

(= (codex:unified-exec-local-exit-grace-closed)
   CodexUnifiedExecLocalExitGraceClosed)

(= (codex:unified-exec-local-exit-grace-timeout)
   CodexUnifiedExecLocalExitGraceTimeout)

(= (codex:unified-exec-local-exit-grace-kind
      (CodexUnifiedExecLocalExitGraceOk $exit-code))
   ok)

(= (codex:unified-exec-local-exit-grace-kind
      CodexUnifiedExecLocalExitGraceClosed)
   closed)

(= (codex:unified-exec-local-exit-grace-kind
      CodexUnifiedExecLocalExitGraceTimeout)
   timeout)

(= (codex:unified-exec-local-exit-grace-exit-code
      (CodexUnifiedExecLocalExitGraceOk $exit-code))
   $exit-code)

(= (codex:unified-exec-spawned-pty
      $session
      $stdout-rx
      $stderr-rx
      $exit-rx
      $exit-poll-result
      $grace-exit-result
      $sandbox-snapshot-text)
   (CodexUnifiedExecSpawnedPty
     $session
     $stdout-rx
     $stderr-rx
     $exit-rx
     $exit-poll-result
     $grace-exit-result
     $sandbox-snapshot-text))

(= (codex:unified-exec-spawned-pty-session
      (CodexUnifiedExecSpawnedPty
        $session
        $stdout-rx
        $stderr-rx
        $exit-rx
        $exit-poll-result
        $grace-exit-result
        $sandbox-snapshot-text))
   $session)

(= (codex:unified-exec-spawned-pty-stdout-rx
      (CodexUnifiedExecSpawnedPty
        $session
        $stdout-rx
        $stderr-rx
        $exit-rx
        $exit-poll-result
        $grace-exit-result
        $sandbox-snapshot-text))
   $stdout-rx)

(= (codex:unified-exec-spawned-pty-stderr-rx
      (CodexUnifiedExecSpawnedPty
        $session
        $stdout-rx
        $stderr-rx
        $exit-rx
        $exit-poll-result
        $grace-exit-result
        $sandbox-snapshot-text))
   $stderr-rx)

(= (codex:unified-exec-spawned-pty-exit-rx
      (CodexUnifiedExecSpawnedPty
        $session
        $stdout-rx
        $stderr-rx
        $exit-rx
        $exit-poll-result
        $grace-exit-result
        $sandbox-snapshot-text))
   $exit-rx)

(= (codex:unified-exec-spawned-pty-exit-poll-result
      (CodexUnifiedExecSpawnedPty
        $session
        $stdout-rx
        $stderr-rx
        $exit-rx
        $exit-poll-result
        $grace-exit-result
        $sandbox-snapshot-text))
   $exit-poll-result)

(= (codex:unified-exec-spawned-pty-grace-exit-result
      (CodexUnifiedExecSpawnedPty
        $session
        $stdout-rx
        $stderr-rx
        $exit-rx
        $exit-poll-result
        $grace-exit-result
        $sandbox-snapshot-text))
   $grace-exit-result)

(= (codex:unified-exec-spawned-pty-sandbox-snapshot-text
      (CodexUnifiedExecSpawnedPty
        $session
        $stdout-rx
        $stderr-rx
        $exit-rx
        $exit-poll-result
        $grace-exit-result
        $sandbox-snapshot-text))
   $sandbox-snapshot-text)

(= (codex:unified-exec-exec-server-grace-timeout)
   CodexUnifiedExecExecServerGraceTimeout)

(= (codex:unified-exec-exec-server-grace-state $state)
   (CodexUnifiedExecExecServerGraceState $state))

(= (codex:unified-exec-exec-server-grace-channel-closed)
   CodexUnifiedExecExecServerGraceChannelClosed)

(= (codex:unified-exec-exec-server-grace-kind
      CodexUnifiedExecExecServerGraceTimeout)
   timeout)

(= (codex:unified-exec-exec-server-grace-kind
      (CodexUnifiedExecExecServerGraceState $state))
   state)

(= (codex:unified-exec-exec-server-grace-kind
      CodexUnifiedExecExecServerGraceChannelClosed)
   channel_closed)

(= (codex:unified-exec-exec-server-grace-state-value
      (CodexUnifiedExecExecServerGraceState $state))
   $state)

(= (codex:unified-exec-started-exec-process
      $process
      $grace-observation
      $sandbox-snapshot-text)
   (CodexUnifiedExecStartedExecProcess
     $process
     $grace-observation
     $sandbox-snapshot-text))

(= (codex:unified-exec-started-exec-process-process
      (CodexUnifiedExecStartedExecProcess
        $process
        $grace-observation
        $sandbox-snapshot-text))
   $process)

(= (codex:unified-exec-started-exec-process-grace-observation
      (CodexUnifiedExecStartedExecProcess
        $process
        $grace-observation
        $sandbox-snapshot-text))
   $grace-observation)

(= (codex:unified-exec-started-exec-process-sandbox-snapshot-text
      (CodexUnifiedExecStartedExecProcess
        $process
        $grace-observation
        $sandbox-snapshot-text))
   $sandbox-snapshot-text)

(= (codex:unified-exec-process-constructor-ok $process)
   (CodexUnifiedExecProcessConstructorOk $process))

(= (codex:unified-exec-process-constructor-err $error)
   (CodexUnifiedExecProcessConstructorErr $error))

(= (codex:unified-exec-process-constructor-result-kind
      (CodexUnifiedExecProcessConstructorOk $process))
   ok)

(= (codex:unified-exec-process-constructor-result-kind
      (CodexUnifiedExecProcessConstructorErr $error))
   err)

(= (codex:unified-exec-process-constructor-result-process
      (CodexUnifiedExecProcessConstructorOk $process))
   $process)

(= (codex:unified-exec-process-constructor-result-error
      (CodexUnifiedExecProcessConstructorErr $error))
   $error)

(= (codex:unified-exec-process-check-ok)
   CodexUnifiedExecProcessCheckOk)

(= (codex:unified-exec-process-check-err $error)
   (CodexUnifiedExecProcessCheckErr $error))

(= (codex:unified-exec-process-check-result-kind
      CodexUnifiedExecProcessCheckOk)
   ok)

(= (codex:unified-exec-process-check-result-kind
      (CodexUnifiedExecProcessCheckErr $error))
   err)

(= (codex:unified-exec-process-check-result-error
      (CodexUnifiedExecProcessCheckErr $error))
   $error)

(= (codex:unified-exec-process-exec-tool-call-output
      $exit-code
      $stdout
      $stderr
      $aggregated-output
      $duration
      $timed-out)
   (CodexUnifiedExecProcessExecToolCallOutput
     $exit-code
     $stdout
     $stderr
     $aggregated-output
     $duration
     $timed-out))

(= (codex:unified-exec-process-exec-tool-call-output-exit-code
      (CodexUnifiedExecProcessExecToolCallOutput
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration
        $timed-out))
   $exit-code)

(= (codex:unified-exec-process-exec-tool-call-output-stdout
      (CodexUnifiedExecProcessExecToolCallOutput
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration
        $timed-out))
   $stdout)

(= (codex:unified-exec-process-exec-tool-call-output-stderr
      (CodexUnifiedExecProcessExecToolCallOutput
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration
        $timed-out))
   $stderr)

(= (codex:unified-exec-process-exec-tool-call-output-aggregated-output
      (CodexUnifiedExecProcessExecToolCallOutput
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration
        $timed-out))
   $aggregated-output)

(= (codex:unified-exec-process-ascii-lower-char $char)
   (if (== $char "A")
       "a"
       (if (== $char "B")
           "b"
           (if (== $char "C")
               "c"
               (if (== $char "D")
                   "d"
                   (if (== $char "E")
                       "e"
                       (if (== $char "F")
                           "f"
                           (if (== $char "G")
                               "g"
                               (if (== $char "H")
                                   "h"
                                   (if (== $char "I")
                                       "i"
                                       (if (== $char "J")
                                           "j"
                                           (if (== $char "K")
                                               "k"
                                               (if (== $char "L")
                                                   "l"
                                                   (if (== $char "M")
                                                       "m"
                                                       (if (== $char "N")
                                                           "n"
                                                           (if (== $char "O")
                                                               "o"
                                                               (if (== $char "P")
                                                                   "p"
                                                                   (if (== $char "Q")
                                                                       "q"
                                                                       (if (== $char "R")
                                                                           "r"
                                                                           (if (== $char "S")
                                                                               "s"
                                                                               (if (== $char "T")
                                                                                   "t"
                                                                                   (if (== $char "U")
                                                                                       "u"
                                                                                       (if (== $char "V")
                                                                                           "v"
                                                                                           (if (== $char "W")
                                                                                               "w"
                                                                                               (if (== $char "X")
                                                                                                   "x"
                                                                                                   (if (== $char "Y")
                                                                                                       "y"
                                                                                                       (if (== $char "Z")
                                                                                                           "z"
                                                                                                          $char)))))))))))))))))))))))))))

(= (codex:unified-exec-process-ascii-lower $text)
   (codex:unified-exec-process-ascii-lower-from
     $text
     0
     ""))

(= (codex:unified-exec-process-ascii-lower-from
      $text
      $index
      $out)
   (if (>= $index (eval (str-length $text)))
       $out
       (let $char
         (eval (str-slice $text $index (+ $index 1)))
         (codex:unified-exec-process-ascii-lower-from
           $text
           (+ $index 1)
           (str-concat
             $out
             (codex:unified-exec-process-ascii-lower-char
               $char))))))

(= (codex:unified-exec-process-text-contains $text $needle)
   (> (list:len (eval (str-split $needle $text))) 1))

(= (codex:unified-exec-process-sandbox-denied-keywords)
   ("operation not permitted"
    "permission denied"
    "read-only file system"
    "seccomp"
    "sandbox"
    "landlock"
    "failed to write file"))

(= (codex:unified-exec-process-text-has-sandbox-keyword
      $text
      $keywords)
   (if (== $keywords ())
       False
       (let $lower
         (codex:unified-exec-process-ascii-lower $text)
         (let $head (list:first $keywords)
           (let $tail (list:rest $keywords)
             (if (codex:unified-exec-process-text-contains
                   $lower
                   $head)
                 True
                 (codex:unified-exec-process-text-has-sandbox-keyword
                   $text
                   $tail)))))))

(= (codex:unified-exec-process-output-has-sandbox-keyword $output)
   (let $keywords
     (codex:unified-exec-process-sandbox-denied-keywords)
     (or
       (codex:unified-exec-process-text-has-sandbox-keyword
         (codex:unified-exec-process-exec-tool-call-output-stderr
           $output)
         $keywords)
       (or
         (codex:unified-exec-process-text-has-sandbox-keyword
           (codex:unified-exec-process-exec-tool-call-output-stdout
             $output)
           $keywords)
         (codex:unified-exec-process-text-has-sandbox-keyword
           (codex:unified-exec-process-exec-tool-call-output-aggregated-output
             $output)
           $keywords)))))

(= (codex:unified-exec-process-quick-reject-exit-code $exit-code)
   (or
     (== $exit-code 2)
     (or
       (== $exit-code 126)
       (== $exit-code 127))))

(= (codex:unified-exec-process-is-likely-sandbox-denied
      $sandbox-type
      $output
      $host-platform)
   (let $exit-code
     (codex:unified-exec-process-exec-tool-call-output-exit-code
       $output)
     (if (or
           (== $sandbox-type (codex:sandbox-type-none))
           (== $exit-code 0))
         False
         (if (codex:unified-exec-process-output-has-sandbox-keyword
               $output)
             True
             (if (codex:unified-exec-process-quick-reject-exit-code
                   $exit-code)
                 False
                 (and
                   (== $host-platform (codex:host-platform-linux))
                   (and
                     (== $sandbox-type
                         (codex:sandbox-type-linux-seccomp))
                     (== $exit-code
                         (codex:unified-exec-linux-sigsys-exit-code)))))))))

(= (codex:unified-exec-process-strip-trailing-dot-zero $text)
   (if (str-ends-with? $text ".0")
       (str-slice $text 0 (- (str-length $text) 2))
       $text))

(= (codex:unified-exec-process-number-text $value)
   (codex:unified-exec-process-strip-trailing-dot-zero
     (format-args "{}" ($value))))

(= (codex:unified-exec-process-approx-bytes-for-tokens $tokens)
   (codex:output-truncation-approx-bytes-for-tokens $tokens))

(= (codex:unified-exec-process-approx-tokens-from-byte-count $bytes)
   (codex:output-truncation-approx-tokens-from-byte-count $bytes))

(= (codex:unified-exec-process-count-lines $text)
   (codex:output-truncation-count-lines $text))

(= (codex:unified-exec-process-token-truncation-marker $removed-bytes)
   (codex:string-truncate-format-truncation-marker
     True
     (codex:unified-exec-process-approx-tokens-from-byte-count
       $removed-bytes)))

(= (codex:unified-exec-process-truncate-middle-with-token-budget
      $text
      $max-tokens)
   (let $policy
     (codex:output-truncation-policy-tokens $max-tokens)
     (codex:output-truncation-truncate-text $text $policy)))

(= (codex:unified-exec-process-truncate-middle-with-token-budget-bytes
      $text
      $max-bytes)
   (codex:string-truncate-with-byte-estimate $text $max-bytes True))

(= (codex:unified-exec-process-formatted-truncate-text
      $text
      $max-tokens)
   (let $policy
     (codex:output-truncation-policy-tokens $max-tokens)
     (codex:output-truncation-formatted-truncate-text $text $policy)))

(= (codex:unified-exec-process-exit-code-or-default $exit-code)
   (if (== $exit-code CodexAbsent)
       -1
       $exit-code))

(= (codex:unified-exec-process-sandbox-denial-output
      $exit-code
      $text)
   (codex:unified-exec-process-exec-tool-call-output
     $exit-code
     ""
     $text
     $text
     CodexAbsent
     False))

(= (codex:unified-exec-process-sandbox-denial-message
      $text
      $exit-code)
   (let $snippet
     (codex:unified-exec-process-formatted-truncate-text
       $text
       (codex:unified-exec-output-max-tokens))
     (if (== $snippet "")
         (format-args
           "Process exited with code {}"
           ($exit-code))
         $snippet)))

(= (codex:unified-exec-process-check-for-sandbox-denial-with-text
      $process
      $text
      $host-platform)
   (let $sandbox-type
     (codex:unified-exec-managed-process-sandbox-type
       $process)
     (if (or
           (== $sandbox-type (codex:sandbox-type-none))
           (not (codex:unified-exec-process-has-exited $process)))
         (codex:unified-exec-process-check-ok)
         (let $exit-code
           (codex:unified-exec-process-exit-code-or-default
             (codex:unified-exec-process-exit-code $process))
           (let $output
             (codex:unified-exec-process-sandbox-denial-output
               $exit-code
               $text)
             (if (codex:unified-exec-process-is-likely-sandbox-denied
                   $sandbox-type
                   $output
                   $host-platform)
                 (codex:unified-exec-process-check-err
                   (codex:unified-exec-error-sandbox-denied
                     (codex:unified-exec-process-sandbox-denial-message
                       $text
                       $exit-code)
                     $output))
                 (codex:unified-exec-process-check-ok)))))))

(= (codex:unified-exec-process-after-exit-and-check
      $process
      $exit-code
      $sandbox-snapshot-text
      $host-platform)
   (let $exited-process
     (codex:unified-exec-process-signal-exit
       $process
       $exit-code)
     (let $check
       (codex:unified-exec-process-check-for-sandbox-denial-with-text
         $exited-process
         $sandbox-snapshot-text
         $host-platform)
       (if (== (codex:unified-exec-process-check-result-kind
                 $check)
               ok)
           (codex:unified-exec-process-constructor-ok
             $exited-process)
           (codex:unified-exec-process-constructor-err
             (codex:unified-exec-process-check-result-error
               $check))))))

(= (codex:unified-exec-process-from-spawned
      $spawned
      $sandbox-type
      $spawn-lifecycle
      $resources
      $host-platform)
   (let $process-handle
     (codex:unified-exec-process-handle-local
       (codex:unified-exec-spawned-pty-session $spawned)
       False
       CodexAbsent)
     (let $managed
       (codex:unified-exec-process-new
         $process-handle
         $sandbox-type
         $spawn-lifecycle
         $resources)
       (let $output-rx
         (codex:unified-exec-combined-output-receiver
           (codex:unified-exec-spawned-pty-stdout-rx $spawned)
           (codex:unified-exec-spawned-pty-stderr-rx $spawned))
         (let $managed-with-task
           (codex:unified-exec-managed-process-with-output-task
             $managed
             (codex:unified-exec-local-output-task-request
               $output-rx
               (codex:unified-exec-managed-process-output-handles
                 $managed)
               (codex:unified-exec-process-runtime-resources-output-tx
                 $resources)))
           (codex:unified-exec-process-from-spawned-after-poll
             $managed-with-task
             $spawned
             $resources
             $host-platform))))))

(= (codex:unified-exec-process-from-spawned-after-poll
      $process
      $spawned
      $resources
      $host-platform)
   (let $poll
     (codex:unified-exec-spawned-pty-exit-poll-result
       $spawned)
     (let $poll-kind
       (codex:unified-exec-local-exit-poll-kind $poll)
       (if (== $poll-kind ok)
           (codex:unified-exec-process-after-exit-and-check
             $process
             (codex:unified-exec-local-exit-poll-exit-code
               $poll)
             (codex:unified-exec-spawned-pty-sandbox-snapshot-text
               $spawned)
             $host-platform)
           (if (== $poll-kind closed)
               (codex:unified-exec-process-after-exit-and-check
                 $process
                 CodexAbsent
                 (codex:unified-exec-spawned-pty-sandbox-snapshot-text
                   $spawned)
                 $host-platform)
               (codex:unified-exec-process-from-spawned-after-grace
                 $process
                 $spawned
                 $resources
                 $host-platform))))))

(= (codex:unified-exec-process-from-spawned-after-grace
      $process
      $spawned
      $resources
      $host-platform)
   (let $grace
     (codex:unified-exec-spawned-pty-grace-exit-result
       $spawned)
     (let $grace-kind
       (codex:unified-exec-local-exit-grace-kind $grace)
       (if (== $grace-kind ok)
           (codex:unified-exec-process-after-exit-and-check
             $process
             (codex:unified-exec-local-exit-grace-exit-code
               $grace)
             (codex:unified-exec-spawned-pty-sandbox-snapshot-text
               $spawned)
             $host-platform)
           (if (== $grace-kind closed)
               (codex:unified-exec-process-after-exit-and-check
                 $process
                 CodexAbsent
                 (codex:unified-exec-spawned-pty-sandbox-snapshot-text
                   $spawned)
                 $host-platform)
               (codex:unified-exec-process-constructor-ok
                 (codex:unified-exec-managed-process-with-exit-watcher
                   $process
                   (codex:unified-exec-local-exit-watcher-request
                     (codex:unified-exec-spawned-pty-exit-rx
                       $spawned)
                     (codex:unified-exec-process-runtime-resources-state-tx
                       $resources)
                     (codex:unified-exec-process-runtime-resources-cancellation-token
                       $resources)))))))))

(= (codex:unified-exec-process-from-exec-server-started
      $started
      $sandbox-type
      $resources
      $host-platform)
   (let $process-handle
     (codex:unified-exec-process-handle-exec-server
       (codex:unified-exec-started-exec-process-process
         $started))
     (let $managed
       (codex:unified-exec-process-new
         $process-handle
         $sandbox-type
         CodexAbsent
         $resources)
       (let $managed-with-task
         (codex:unified-exec-managed-process-with-output-task
           $managed
           (codex:unified-exec-exec-server-output-task-request
             $started
             (codex:unified-exec-managed-process-output-handles
               $managed)
             (codex:unified-exec-process-runtime-resources-output-tx
               $resources)
             (codex:unified-exec-process-runtime-resources-state-tx
               $resources)))
         (codex:unified-exec-process-from-exec-server-observed
           $managed-with-task
           $started
           $host-platform)))))

(= (codex:unified-exec-process-from-exec-server-observed
      $process
      $started
      $host-platform)
   (let $observation
     (codex:unified-exec-started-exec-process-grace-observation
       $started)
     (let $kind
       (codex:unified-exec-exec-server-grace-kind
         $observation)
       (if (== $kind timeout)
           (codex:unified-exec-process-constructor-ok
             $process)
           (let $observed-process
             (if (== $kind state)
                 (codex:unified-exec-managed-process-with-state
                   $process
                   (codex:unified-exec-exec-server-grace-state-value
                     $observation))
                 $process)
             (let $check
               (codex:unified-exec-process-check-for-sandbox-denial-with-text
                 $observed-process
                 (codex:unified-exec-started-exec-process-sandbox-snapshot-text
                   $started)
                 $host-platform)
               (if (== (codex:unified-exec-process-check-result-kind
                         $check)
                       ok)
                   (codex:unified-exec-process-constructor-ok
                     $observed-process)
                   (codex:unified-exec-process-constructor-err
                     (codex:unified-exec-process-check-result-error
                       $check)))))))))
