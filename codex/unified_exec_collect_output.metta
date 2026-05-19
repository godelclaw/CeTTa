; Rust-faithful pure unified-exec output collection slice.
;
; This ports deterministic loop behavior from:
; - openai-codex/codex-rs/core/src/unified_exec/process_manager.rs
;   - collect_output_until_deadline
;   - extend_deadlines_while_paused
;   - wait_for_pause_change select arm semantics
;
; Covered in this increment:
; - drain chunks before waiting
; - initial and per-iteration cancellation checks
; - closed-output early break after exit signal
; - normal deadline wait, exit-notified wait, output-notified wait, and
;   pause-change wakeups
; - post-exit close wait with the Rust 50 ms cap
; - pause extension for both the main deadline and an active post-exit deadline
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust waits on `tokio::select!` over Notify, CancellationToken, sleep, and
;   optional pause-state futures. This pure boundary consumes an explicit list
;   of observation steps. Each step records the current time, output-buffer
;   contents at lock time, cancellation/closed flags, pause observation, and
;   selected wait outcome. The state transitions match the Rust branches.
; - Rust returns `Vec<u8>`. Existing CeTTa unified-exec output surfaces carry
;   text chunks, so this slice returns both the collected chunk list and the
;   joined text. Arbitrary binary-byte preservation belongs with a later byte
;   vector runtime boundary.
; - Rust would continue waiting if no scripted event arrives. This pure helper
;   returns `script_exhausted` when the supplied observation list ends, making
;   tests finite without weakening the ported branch behavior.

!(import! &self list)
!(import! &self str)
!(import! &self unified_exec_head_tail_buffer)

(= (codex:unified-exec-post-exit-close-wait-cap-ms)
   50)

(= (codex:unified-exec-collect-wait-output-notified)
   output_notified)

(= (codex:unified-exec-collect-wait-exit-notified)
   exit_notified)

(= (codex:unified-exec-collect-wait-output-closed-notified)
   output_closed_notified)

(= (codex:unified-exec-collect-wait-timeout)
   timeout)

(= (codex:unified-exec-collect-wait-pause-changed)
   pause_changed)

(= (codex:unified-exec-collect-pause-state
      $is-paused
      $paused-for-ms)
   (CodexUnifiedExecCollectPauseState
     $is-paused
     $paused-for-ms))

(= (codex:unified-exec-collect-pause-state-is-paused
      (CodexUnifiedExecCollectPauseState
        $is-paused
        $paused-for-ms))
   $is-paused)

(= (codex:unified-exec-collect-pause-state-paused-for-ms
      (CodexUnifiedExecCollectPauseState
        $is-paused
        $paused-for-ms))
   $paused-for-ms)

(= (codex:unified-exec-collect-step
      $now-ms
      $pause-state
      $output-buffer
      $cancellation-cancelled
      $output-closed
      $wait-outcome)
   (CodexUnifiedExecCollectStep
     $now-ms
     $pause-state
     $output-buffer
     $cancellation-cancelled
     $output-closed
     $wait-outcome))

(= (codex:unified-exec-collect-step-now-ms
      (CodexUnifiedExecCollectStep
        $now-ms
        $pause-state
        $output-buffer
        $cancellation-cancelled
        $output-closed
        $wait-outcome))
   $now-ms)

(= (codex:unified-exec-collect-step-pause-state
      (CodexUnifiedExecCollectStep
        $now-ms
        $pause-state
        $output-buffer
        $cancellation-cancelled
        $output-closed
        $wait-outcome))
   $pause-state)

(= (codex:unified-exec-collect-step-output-buffer
      (CodexUnifiedExecCollectStep
        $now-ms
        $pause-state
        $output-buffer
        $cancellation-cancelled
        $output-closed
        $wait-outcome))
   $output-buffer)

(= (codex:unified-exec-collect-step-cancellation-cancelled
      (CodexUnifiedExecCollectStep
        $now-ms
        $pause-state
        $output-buffer
        $cancellation-cancelled
        $output-closed
        $wait-outcome))
   $cancellation-cancelled)

(= (codex:unified-exec-collect-step-output-closed
      (CodexUnifiedExecCollectStep
        $now-ms
        $pause-state
        $output-buffer
        $cancellation-cancelled
        $output-closed
        $wait-outcome))
   $output-closed)

(= (codex:unified-exec-collect-step-wait-outcome
      (CodexUnifiedExecCollectStep
        $now-ms
        $pause-state
        $output-buffer
        $cancellation-cancelled
        $output-closed
        $wait-outcome))
   $wait-outcome)

(= (codex:unified-exec-collect-state
      $collected-chunks
      $exit-signal-received
      $deadline-ms
      $post-exit-deadline-ms)
   (CodexUnifiedExecCollectState
     $collected-chunks
     $exit-signal-received
     $deadline-ms
     $post-exit-deadline-ms))

(= (codex:unified-exec-collect-state-collected-chunks
      (CodexUnifiedExecCollectState
        $collected-chunks
        $exit-signal-received
        $deadline-ms
        $post-exit-deadline-ms))
   $collected-chunks)

(= (codex:unified-exec-collect-state-exit-signal-received
      (CodexUnifiedExecCollectState
        $collected-chunks
        $exit-signal-received
        $deadline-ms
        $post-exit-deadline-ms))
   $exit-signal-received)

(= (codex:unified-exec-collect-state-deadline-ms
      (CodexUnifiedExecCollectState
        $collected-chunks
        $exit-signal-received
        $deadline-ms
        $post-exit-deadline-ms))
   $deadline-ms)

(= (codex:unified-exec-collect-state-post-exit-deadline-ms
      (CodexUnifiedExecCollectState
        $collected-chunks
        $exit-signal-received
        $deadline-ms
        $post-exit-deadline-ms))
   $post-exit-deadline-ms)

(= (codex:unified-exec-collect-state-with-collected-chunks
      (CodexUnifiedExecCollectState
        $collected-chunks
        $exit-signal-received
        $deadline-ms
        $post-exit-deadline-ms)
      $new-collected-chunks)
   (CodexUnifiedExecCollectState
     $new-collected-chunks
     $exit-signal-received
     $deadline-ms
     $post-exit-deadline-ms))

(= (codex:unified-exec-collect-state-with-exit-signal-received
      (CodexUnifiedExecCollectState
        $collected-chunks
        $exit-signal-received
        $deadline-ms
        $post-exit-deadline-ms)
      $new-exit-signal-received)
   (CodexUnifiedExecCollectState
     $collected-chunks
     $new-exit-signal-received
     $deadline-ms
     $post-exit-deadline-ms))

(= (codex:unified-exec-collect-state-with-post-exit-deadline-ms
      (CodexUnifiedExecCollectState
        $collected-chunks
        $exit-signal-received
        $deadline-ms
        $post-exit-deadline-ms)
      $new-post-exit-deadline-ms)
   (CodexUnifiedExecCollectState
     $collected-chunks
     $exit-signal-received
     $deadline-ms
     $new-post-exit-deadline-ms))

(= (codex:unified-exec-collect-result
      $collected-chunks
      $collected-text
      $state
      $reason)
   (CodexUnifiedExecCollectResult
     $collected-chunks
     $collected-text
     $state
     $reason))

(= (codex:unified-exec-collect-result-collected-chunks
      (CodexUnifiedExecCollectResult
        $collected-chunks
        $collected-text
        $state
        $reason))
   $collected-chunks)

(= (codex:unified-exec-collect-result-collected-text
      (CodexUnifiedExecCollectResult
        $collected-chunks
        $collected-text
        $state
        $reason))
   $collected-text)

(= (codex:unified-exec-collect-result-state
      (CodexUnifiedExecCollectResult
        $collected-chunks
        $collected-text
        $state
        $reason))
   $state)

(= (codex:unified-exec-collect-result-reason
      (CodexUnifiedExecCollectResult
        $collected-chunks
        $collected-text
        $state
        $reason))
   $reason)

(= (codex:unified-exec-collect-state-to-result $state $reason)
   (codex:unified-exec-collect-result
     (codex:unified-exec-collect-state-collected-chunks $state)
     (str-join
       ""
       (codex:unified-exec-collect-state-collected-chunks $state))
     $state
     $reason))

(= (codex:unified-exec-collect-saturating-duration-ms
      $deadline-ms
      $now-ms)
   (if (> $deadline-ms $now-ms)
       (- $deadline-ms $now-ms)
       0))

(= (codex:unified-exec-collect-min-ms $lhs $rhs)
   (if (< $lhs $rhs)
       $lhs
       $rhs))

(= (codex:unified-exec-collect-merge-exit-signal
      $exit-signal-received
      $cancellation-cancelled)
   (if $exit-signal-received
       True
       $cancellation-cancelled))

(= (codex:unified-exec-collect-extend-deadlines-while-paused
      $state
      $pause-state)
   (if (== $pause-state CodexAbsent)
       $state
       (if (codex:unified-exec-collect-pause-state-is-paused
             $pause-state)
           (let $paused-for-ms
             (codex:unified-exec-collect-pause-state-paused-for-ms
               $pause-state)
             (CodexUnifiedExecCollectState
               (codex:unified-exec-collect-state-collected-chunks
                 $state)
               (codex:unified-exec-collect-state-exit-signal-received
                 $state)
               (+ (codex:unified-exec-collect-state-deadline-ms
                    $state)
                  $paused-for-ms)
               (let $post-exit-deadline-ms
                 (codex:unified-exec-collect-state-post-exit-deadline-ms
                   $state)
                 (if (== $post-exit-deadline-ms CodexAbsent)
                     CodexAbsent
                     (+ $post-exit-deadline-ms $paused-for-ms)))))
           $state)))

(= (codex:unified-exec-collect-output-until-deadline
      $initial-cancellation-cancelled
      $deadline-ms
      $steps)
   (codex:unified-exec-collect-output-from-state
     (codex:unified-exec-collect-state
       ()
       $initial-cancellation-cancelled
       $deadline-ms
       CodexAbsent)
     $steps))

(= (codex:unified-exec-collect-output-from-state $state ())
   (codex:unified-exec-collect-state-to-result
     $state
     script_exhausted))

(= (codex:unified-exec-collect-output-from-state $state $steps)
   (let $step (list:first $steps)
     (let $tail (list:rest $steps)
       (let $state-after-pause
         (codex:unified-exec-collect-extend-deadlines-while-paused
           $state
           (codex:unified-exec-collect-step-pause-state $step))
         (let $drained
           (codex:head-tail-buffer-drain-chunks
             (codex:unified-exec-collect-step-output-buffer $step))
           (let $chunks
             (codex:head-tail-buffer-drain-result-chunks $drained)
             (if (== $chunks ())
                 (codex:unified-exec-collect-handle-empty-drain
                   $state-after-pause
                   $step
                   $tail)
                 (codex:unified-exec-collect-handle-drained-chunks
                   $state-after-pause
                   $step
                   $tail
                   $chunks))))))))

(= (codex:unified-exec-collect-handle-drained-chunks
      $state
      $step
      $tail
      $chunks)
   (let $collected-chunks
     (list:append
       (codex:unified-exec-collect-state-collected-chunks $state)
       $chunks)
     (let $exit-signal-received
       (codex:unified-exec-collect-merge-exit-signal
         (codex:unified-exec-collect-state-exit-signal-received
           $state)
         (codex:unified-exec-collect-step-cancellation-cancelled
           $step))
       (let $next-state
         (codex:unified-exec-collect-state
           $collected-chunks
           $exit-signal-received
           (codex:unified-exec-collect-state-deadline-ms $state)
           (codex:unified-exec-collect-state-post-exit-deadline-ms
             $state))
         (if (>= (codex:unified-exec-collect-step-now-ms $step)
                 (codex:unified-exec-collect-state-deadline-ms
                   $next-state))
             (codex:unified-exec-collect-state-to-result
               $next-state
               deadline_elapsed_after_drain)
             (codex:unified-exec-collect-output-from-state
               $next-state
               $tail))))))

(= (codex:unified-exec-collect-handle-empty-drain
      $state
      $step
      $tail)
   (let $exit-signal-received
     (codex:unified-exec-collect-merge-exit-signal
       (codex:unified-exec-collect-state-exit-signal-received
         $state)
       (codex:unified-exec-collect-step-cancellation-cancelled
         $step))
     (let $next-state
       (codex:unified-exec-collect-state-with-exit-signal-received
         $state
         $exit-signal-received)
       (if (and $exit-signal-received
                (codex:unified-exec-collect-step-output-closed $step))
           (codex:unified-exec-collect-state-to-result
             $next-state
             exit_signal_and_output_closed)
           (let $remaining-ms
             (codex:unified-exec-collect-saturating-duration-ms
               (codex:unified-exec-collect-state-deadline-ms
                 $next-state)
               (codex:unified-exec-collect-step-now-ms $step))
             (if (== $remaining-ms 0)
                 (codex:unified-exec-collect-state-to-result
                   $next-state
                   deadline_elapsed)
                 (if $exit-signal-received
                     (codex:unified-exec-collect-handle-empty-after-exit
                       $next-state
                       $step
                       $tail
                       $remaining-ms)
                     (codex:unified-exec-collect-handle-empty-before-exit
                       $next-state
                       $step
                       $tail))))))))

(= (codex:unified-exec-collect-post-exit-deadline-for-step
      $state
      $step
      $remaining-ms)
   (let $post-exit-deadline-ms
     (codex:unified-exec-collect-state-post-exit-deadline-ms $state)
     (if (== $post-exit-deadline-ms CodexAbsent)
         (+ (codex:unified-exec-collect-step-now-ms $step)
            (codex:unified-exec-collect-min-ms
              $remaining-ms
              (codex:unified-exec-post-exit-close-wait-cap-ms)))
         $post-exit-deadline-ms)))

(= (codex:unified-exec-collect-handle-empty-after-exit
      $state
      $step
      $tail
      $remaining-ms)
   (let $post-exit-deadline-ms
     (codex:unified-exec-collect-post-exit-deadline-for-step
       $state
       $step
       $remaining-ms)
     (let $state-with-post-exit-deadline
       (codex:unified-exec-collect-state-with-post-exit-deadline-ms
         $state
         $post-exit-deadline-ms)
       (let $close-wait-remaining-ms
         (codex:unified-exec-collect-saturating-duration-ms
           $post-exit-deadline-ms
           (codex:unified-exec-collect-step-now-ms $step))
         (if (== $close-wait-remaining-ms 0)
             (codex:unified-exec-collect-state-to-result
               $state-with-post-exit-deadline
               post_exit_close_wait_elapsed)
             (let $wait-outcome
               (codex:unified-exec-collect-step-wait-outcome $step)
               (if (== $wait-outcome
                       (codex:unified-exec-collect-wait-timeout))
                   (codex:unified-exec-collect-state-to-result
                     $state-with-post-exit-deadline
                     post_exit_close_wait_timeout)
                   (codex:unified-exec-collect-output-from-state
                     $state-with-post-exit-deadline
                     $tail))))))))

(= (codex:unified-exec-collect-handle-empty-before-exit
      $state
      $step
      $tail)
   (let $wait-outcome
     (codex:unified-exec-collect-step-wait-outcome $step)
     (if (== $wait-outcome
             (codex:unified-exec-collect-wait-timeout))
         (codex:unified-exec-collect-state-to-result
           $state
           wait_timeout)
         (if (== $wait-outcome
                 (codex:unified-exec-collect-wait-exit-notified))
             (codex:unified-exec-collect-output-from-state
               (codex:unified-exec-collect-state-with-exit-signal-received
                 $state
                 True)
               $tail)
             (codex:unified-exec-collect-output-from-state
               $state
               $tail)))))
