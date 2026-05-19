; Rust-faithful pure unified-exec prepared-process-handle slice.
;
; This ports deterministic data preparation from:
; - openai-codex/codex-rs/core/src/unified_exec/process_manager.rs
;   - PreparedProcessHandles
;   - UnifiedExecProcessManager::prepare_process_handles
;
; Covered in this increment:
; - opaque `OutputHandles` materialization
; - process wrapper carrying the already-ported process state plus output
;   handles
; - prepared handle record with the same fields Rust returns
; - pure store transition that updates `entry.last_used` and returns
;   `UnknownProcessId` for missing entries
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust clones `Arc<UnifiedExecProcess>`, `Arc<Notify>`, and a
;   `CancellationToken`, and it subscribes to session pause state while holding
;   the store lock. This pure boundary preserves those objects as opaque atoms
;   and returns an opaque pause-state subscription marker. The later async
;   runtime slice can perform the actual clone/subscribe effects at this same
;   boundary.
; - Rust obtains `Instant::now()` inside `prepare_process_handles`. This pure
;   helper accepts `$now` explicitly so tests and callers can verify the exact
;   `last_used` mutation without introducing a clock side effect here.

!(import! &self unified_exec_process_manager_state)
!(import! &self unified_exec_state)

(= (codex:unified-exec-output-handles
      $output-buffer
      $output-notify
      $output-closed
      $output-closed-notify
      $cancellation-token)
   (CodexUnifiedExecOutputHandles
     $output-buffer
     $output-notify
     $output-closed
     $output-closed-notify
     $cancellation-token))

(= (codex:unified-exec-output-handles-output-buffer
      (CodexUnifiedExecOutputHandles
        $output-buffer
        $output-notify
        $output-closed
        $output-closed-notify
        $cancellation-token))
   $output-buffer)

(= (codex:unified-exec-output-handles-output-notify
      (CodexUnifiedExecOutputHandles
        $output-buffer
        $output-notify
        $output-closed
        $output-closed-notify
        $cancellation-token))
   $output-notify)

(= (codex:unified-exec-output-handles-output-closed
      (CodexUnifiedExecOutputHandles
        $output-buffer
        $output-notify
        $output-closed
        $output-closed-notify
        $cancellation-token))
   $output-closed)

(= (codex:unified-exec-output-handles-output-closed-notify
      (CodexUnifiedExecOutputHandles
        $output-buffer
        $output-notify
        $output-closed
        $output-closed-notify
        $cancellation-token))
   $output-closed-notify)

(= (codex:unified-exec-output-handles-cancellation-token
      (CodexUnifiedExecOutputHandles
        $output-buffer
        $output-notify
        $output-closed
        $output-closed-notify
        $cancellation-token))
   $cancellation-token)

(= (codex:unified-exec-process-with-output-handles
      $state
      $output-handles)
   (CodexUnifiedExecProcessWithOutputHandles
     $state
     $output-handles))

(= (codex:unified-exec-process-with-output-handles-state
      (CodexUnifiedExecProcessWithOutputHandles
        $state
        $output-handles))
   $state)

(= (codex:unified-exec-process-output-handles
      (CodexUnifiedExecProcessWithOutputHandles
        $state
        $output-handles))
   $output-handles)

(= (codex:unified-exec-prepared-process-handles
      $process
      $output-buffer
      $output-notify
      $output-closed
      $output-closed-notify
      $cancellation-token
      $pause-state
      $hook-command
      $process-id
      $tty)
   (CodexUnifiedExecPreparedProcessHandles
     $process
     $output-buffer
     $output-notify
     $output-closed
     $output-closed-notify
     $cancellation-token
     $pause-state
     $hook-command
     $process-id
     $tty))

(= (codex:unified-exec-prepared-process-handles-process
      (CodexUnifiedExecPreparedProcessHandles
        $process
        $output-buffer
        $output-notify
        $output-closed
        $output-closed-notify
        $cancellation-token
        $pause-state
        $hook-command
        $process-id
        $tty))
   $process)

(= (codex:unified-exec-prepared-process-handles-output-buffer
      (CodexUnifiedExecPreparedProcessHandles
        $process
        $output-buffer
        $output-notify
        $output-closed
        $output-closed-notify
        $cancellation-token
        $pause-state
        $hook-command
        $process-id
        $tty))
   $output-buffer)

(= (codex:unified-exec-prepared-process-handles-output-notify
      (CodexUnifiedExecPreparedProcessHandles
        $process
        $output-buffer
        $output-notify
        $output-closed
        $output-closed-notify
        $cancellation-token
        $pause-state
        $hook-command
        $process-id
        $tty))
   $output-notify)

(= (codex:unified-exec-prepared-process-handles-output-closed
      (CodexUnifiedExecPreparedProcessHandles
        $process
        $output-buffer
        $output-notify
        $output-closed
        $output-closed-notify
        $cancellation-token
        $pause-state
        $hook-command
        $process-id
        $tty))
   $output-closed)

(= (codex:unified-exec-prepared-process-handles-output-closed-notify
      (CodexUnifiedExecPreparedProcessHandles
        $process
        $output-buffer
        $output-notify
        $output-closed
        $output-closed-notify
        $cancellation-token
        $pause-state
        $hook-command
        $process-id
        $tty))
   $output-closed-notify)

(= (codex:unified-exec-prepared-process-handles-cancellation-token
      (CodexUnifiedExecPreparedProcessHandles
        $process
        $output-buffer
        $output-notify
        $output-closed
        $output-closed-notify
        $cancellation-token
        $pause-state
        $hook-command
        $process-id
        $tty))
   $cancellation-token)

(= (codex:unified-exec-prepared-process-handles-pause-state
      (CodexUnifiedExecPreparedProcessHandles
        $process
        $output-buffer
        $output-notify
        $output-closed
        $output-closed-notify
        $cancellation-token
        $pause-state
        $hook-command
        $process-id
        $tty))
   $pause-state)

(= (codex:unified-exec-prepared-process-handles-hook-command
      (CodexUnifiedExecPreparedProcessHandles
        $process
        $output-buffer
        $output-notify
        $output-closed
        $output-closed-notify
        $cancellation-token
        $pause-state
        $hook-command
        $process-id
        $tty))
   $hook-command)

(= (codex:unified-exec-prepared-process-handles-process-id
      (CodexUnifiedExecPreparedProcessHandles
        $process
        $output-buffer
        $output-notify
        $output-closed
        $output-closed-notify
        $cancellation-token
        $pause-state
        $hook-command
        $process-id
        $tty))
   $process-id)

(= (codex:unified-exec-prepared-process-handles-tty
      (CodexUnifiedExecPreparedProcessHandles
        $process
        $output-buffer
        $output-notify
        $output-closed
        $output-closed-notify
        $cancellation-token
        $pause-state
        $hook-command
        $process-id
        $tty))
   $tty)

(= (codex:unified-exec-pause-state-subscription $session)
   (CodexUnifiedExecPauseStateSubscription $session))

(= (codex:unified-exec-pause-state-from-session $session)
   (if (== $session CodexAbsent)
       CodexAbsent
       (codex:unified-exec-pause-state-subscription $session)))

(= (codex:unified-exec-prepare-process-handles-ok
      $prepared
      $store)
   (CodexUnifiedExecPrepareProcessHandlesOk
     $prepared
     $store))

(= (codex:unified-exec-prepare-process-handles-err
      $error
      $store)
   (CodexUnifiedExecPrepareProcessHandlesErr
     $error
     $store))

(= (codex:unified-exec-prepare-process-handles-result-kind
      (CodexUnifiedExecPrepareProcessHandlesOk
        $prepared
        $store))
   ok)

(= (codex:unified-exec-prepare-process-handles-result-kind
      (CodexUnifiedExecPrepareProcessHandlesErr
        $error
        $store))
   err)

(= (codex:unified-exec-prepare-process-handles-result-prepared
      (CodexUnifiedExecPrepareProcessHandlesOk
        $prepared
        $store))
   $prepared)

(= (codex:unified-exec-prepare-process-handles-result-error
      (CodexUnifiedExecPrepareProcessHandlesErr
        $error
        $store))
   $error)

(= (codex:unified-exec-prepare-process-handles-result-store
      (CodexUnifiedExecPrepareProcessHandlesOk
        $prepared
        $store))
   $store)

(= (codex:unified-exec-prepare-process-handles-result-store
      (CodexUnifiedExecPrepareProcessHandlesErr
        $error
        $store))
   $store)

(= (codex:unified-exec-prepare-process-handles $store $process-id $now)
   (let $entry
     (codex:unified-exec-process-store-get-entry $store $process-id)
     (if (== $entry CodexAbsent)
         (codex:unified-exec-prepare-process-handles-err
           (codex:unified-exec-error-unknown-process-id $process-id)
           $store)
         (let $updated-entry
           (codex:unified-exec-process-entry-with-last-used $entry $now)
           (let $updated-store
             (codex:unified-exec-process-store-put-entry
               $store
               $updated-entry)
             (let $process
               (codex:unified-exec-process-entry-process $updated-entry)
               (let $output-handles
                 (codex:unified-exec-process-output-handles $process)
                 (codex:unified-exec-prepare-process-handles-ok
                   (codex:unified-exec-prepared-process-handles
                     $process
                     (codex:unified-exec-output-handles-output-buffer
                       $output-handles)
                     (codex:unified-exec-output-handles-output-notify
                       $output-handles)
                     (codex:unified-exec-output-handles-output-closed
                       $output-handles)
                     (codex:unified-exec-output-handles-output-closed-notify
                       $output-handles)
                     (codex:unified-exec-output-handles-cancellation-token
                       $output-handles)
                     (codex:unified-exec-pause-state-from-session
                       (codex:unified-exec-process-entry-session
                         $updated-entry))
                     (codex:unified-exec-process-entry-hook-command
                       $updated-entry)
                     (codex:unified-exec-process-entry-process-id
                       $updated-entry)
                     (codex:unified-exec-process-entry-tty
                       $updated-entry))
                   $updated-store))))))))
