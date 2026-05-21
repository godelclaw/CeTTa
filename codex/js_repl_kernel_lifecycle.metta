; Rust-faithful js_repl kernel lifecycle and stderr-reader slice.
;
; This ports deterministic helper behavior from:
; - openai-codex/codex-rs/core/src/tools/js_repl/mod.rs
;   - `kill_kernel_child`
;   - `truncate_id_list`
;   - `read_stderr` terminal handling and per-line transition
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust locks a live `tokio::process::Child`, calls `try_wait`,
;   `start_kill`, and waits with a two-second timeout. This pure slice receives
;   those observed process outcomes while preserving the same branch order,
;   early returns, operation order, timeout duration, and warning text.
; - Rust reads stderr asynchronously until shutdown, EOF, or read error and
;   mutates a `VecDeque<String>`. This pure slice exposes the exact per-line
;   transition and the terminal EOF/read-error/shutdown outcomes. The full async
;   loop remains host-owned until CeTTa has a stable stream primitive.

!(import! &self js_repl)
!(import! &self js_repl_kernel_io)
!(import! &self js_repl_kernel_state)
!(import! &self list)
!(import! &self num_format)
!(import! &self str)

(= (codex:js-repl-stable-list ())
   CodexJsReplStableListNil)

(= (codex:js-repl-stable-list $items)
   (let $head (list:first $items)
     (let $tail (list:rest $items)
       (CodexJsReplStableListCons
         $head
         (codex:js-repl-stable-list $tail)))))

(= (codex:js-repl-stable-list-items CodexJsReplStableListNil)
   ())

(= (codex:js-repl-stable-list-items
      (CodexJsReplStableListCons $head $tail))
   (list:append
     ($head)
     (codex:js-repl-stable-list-items $tail)))

(= (codex:js-repl-stable-list-append-item
      CodexJsReplStableListNil
      $item)
   (CodexJsReplStableListCons $item CodexJsReplStableListNil))

(= (codex:js-repl-stable-list-append-item
      (CodexJsReplStableListCons $head $tail)
      $item)
   (CodexJsReplStableListCons
     $head
     (codex:js-repl-stable-list-append-item $tail $item)))

(= (codex:js-repl-kill-wait-timeout-seconds)
   2)

(= (codex:js-repl-kill-operation-inspect $pid $reason)
   (CodexJsReplKillOperationInspect $pid $reason))

(= (codex:js-repl-kill-operation-start-kill $pid $reason)
   (CodexJsReplKillOperationStartKill $pid $reason))

(= (codex:js-repl-kill-operation-wait $pid $reason $timeout-seconds)
   (CodexJsReplKillOperationWait $pid $reason $timeout-seconds))

(= (codex:js-repl-start-kill-ok)
   CodexJsReplStartKillOk)

(= (codex:js-repl-start-kill-error $message)
   (CodexJsReplStartKillError $message))

(= (codex:js-repl-kill-wait-ok)
   CodexJsReplKillWaitOk)

(= (codex:js-repl-kill-wait-error $message)
   (CodexJsReplKillWaitError $message))

(= (codex:js-repl-kill-wait-timeout)
   CodexJsReplKillWaitTimeout)

(= (codex:js-repl-kill-warning $message $pid $reason $error)
   (CodexJsReplKillWarning $message $pid $reason $error))

(= (codex:js-repl-kill-warning-inspect-message)
   "failed to inspect js_repl kernel before kill")

(= (codex:js-repl-kill-warning-start-kill-message)
   "failed to send kill signal to js_repl kernel")

(= (codex:js-repl-kill-warning-wait-error-message)
   "failed while waiting for js_repl kernel exit")

(= (codex:js-repl-kill-warning-wait-timeout-message)
   "timed out waiting for js_repl kernel to exit after kill")

(= (codex:js-repl-kill-operations $operations)
   (CodexJsReplKillOperations
     (codex:js-repl-stable-list $operations)))

(= (codex:js-repl-kill-operations-items
      (CodexJsReplKillOperations $operations))
   (codex:js-repl-stable-list-items $operations))

(= (codex:js-repl-kill-warnings $warnings)
   (CodexJsReplKillWarnings
     (codex:js-repl-stable-list $warnings)))

(= (codex:js-repl-kill-warnings-items
      (CodexJsReplKillWarnings $warnings))
   (codex:js-repl-stable-list-items $warnings))

(= (codex:js-repl-kill-kernel-child-plan $operations $warnings)
   (CodexJsReplKillKernelChildPlan
     (codex:js-repl-kill-operations $operations)
     (codex:js-repl-kill-warnings $warnings)))

(= (codex:js-repl-kill-kernel-child-plan-operations
      (CodexJsReplKillKernelChildPlan $operations-box $warnings-box))
   (codex:js-repl-kill-operations-items $operations-box))

(= (codex:js-repl-kill-kernel-child-plan-warnings
      (CodexJsReplKillKernelChildPlan $operations-box $warnings-box))
   (codex:js-repl-kill-warnings-items $warnings-box))

(= (codex:js-repl-kill-kernel-child-plan-operations-box
      (CodexJsReplKillKernelChildPlan $operations-box $warnings-box))
   $operations-box)

(= (codex:js-repl-kill-kernel-child-plan-warnings-box
      (CodexJsReplKillKernelChildPlan $operations-box $warnings-box))
   $warnings-box)

(= (codex:js-repl-kill-kernel-child-after-inspect
      $pid
      $reason
      $operations
      $warnings
      (CodexJsReplStartKillError $message)
      $wait-result)
   (codex:js-repl-kill-kernel-child-plan
     (list:append
       $operations
       ((codex:js-repl-kill-operation-start-kill $pid $reason)))
     (list:append
       $warnings
       ((codex:js-repl-kill-warning
          (codex:js-repl-kill-warning-start-kill-message)
          $pid
          $reason
          $message)))))

(= (codex:js-repl-kill-kernel-child-after-inspect
      $pid
      $reason
      $operations
      $warnings
      CodexJsReplStartKillOk
      $wait-result)
   (let $operations-after-kill
     (list:append
       $operations
       ((codex:js-repl-kill-operation-start-kill $pid $reason)
        (codex:js-repl-kill-operation-wait
          $pid
          $reason
          (codex:js-repl-kill-wait-timeout-seconds))))
     (case $wait-result
       ((CodexJsReplKillWaitOk
         (codex:js-repl-kill-kernel-child-plan
           $operations-after-kill
           $warnings))
        ((CodexJsReplKillWaitError $message)
         (codex:js-repl-kill-kernel-child-plan
           $operations-after-kill
           (list:append
             $warnings
             ((codex:js-repl-kill-warning
                (codex:js-repl-kill-warning-wait-error-message)
                $pid
                $reason
                $message)))))
        (CodexJsReplKillWaitTimeout
         (codex:js-repl-kill-kernel-child-plan
           $operations-after-kill
           (list:append
             $warnings
             ((codex:js-repl-kill-warning
                (codex:js-repl-kill-warning-wait-timeout-message)
                $pid
                $reason
                CodexAbsent)))))))))

(= (codex:js-repl-kill-kernel-child-plan-from-observation
      (CodexJsReplChildInspection
        $pid
        (CodexJsReplChildTryWaitExited $status))
      $reason
      $start-kill-result
      $wait-result)
   (codex:js-repl-kill-kernel-child-plan
     ((codex:js-repl-kill-operation-inspect $pid $reason))
     ()))

(= (codex:js-repl-kill-kernel-child-plan-from-observation
      (CodexJsReplChildInspection
        $pid
        CodexJsReplChildTryWaitRunning)
      $reason
      $start-kill-result
      $wait-result)
   (codex:js-repl-kill-kernel-child-after-inspect
     $pid
     $reason
     ((codex:js-repl-kill-operation-inspect $pid $reason))
     ()
     $start-kill-result
     $wait-result))

(= (codex:js-repl-kill-kernel-child-plan-from-observation
      (CodexJsReplChildInspection
        $pid
        (CodexJsReplChildTryWaitError $message))
      $reason
      $start-kill-result
      $wait-result)
   (codex:js-repl-kill-kernel-child-after-inspect
     $pid
     $reason
     ((codex:js-repl-kill-operation-inspect $pid $reason))
     ((codex:js-repl-kill-warning
        (codex:js-repl-kill-warning-inspect-message)
        $pid
        $reason
        $message))
     $start-kill-result
     $wait-result))

(= (codex:js-repl-list-take $items $count)
   (if (or (== $items ()) (<= $count 0))
       ()
       (list:append
         ((list:first $items))
         (codex:js-repl-list-take
           (list:rest $items)
           (- $count 1)))))

(= (codex:js-repl-truncate-id-list $ids)
   (if (<= (list:len $ids) (codex:js-repl-exec-id-log-limit))
       $ids
       (list:append
         (codex:js-repl-list-take
           $ids
           (codex:js-repl-exec-id-log-limit))
         ((str-concat
            "...+"
            (codex:num-format-number-text
              (- (list:len $ids)
                 (codex:js-repl-exec-id-log-limit))))))))

(= (codex:js-repl-stderr-reader-event-line $line)
   (CodexJsReplStderrReaderEventLine $line))

(= (codex:js-repl-stderr-reader-event-eof)
   CodexJsReplStderrReaderEventEof)

(= (codex:js-repl-stderr-reader-event-read-error $message)
   (CodexJsReplStderrReaderEventReadError $message))

(= (codex:js-repl-stderr-reader-event-shutdown)
   CodexJsReplStderrReaderEventShutdown)

(= (codex:js-repl-read-stderr-end-eof)
   CodexJsReplReadStderrEndEof)

(= (codex:js-repl-read-stderr-end-read-error $message)
   (CodexJsReplReadStderrEndReadError $message))

(= (codex:js-repl-read-stderr-end-shutdown)
   CodexJsReplReadStderrEndShutdown)

(= (codex:js-repl-read-stderr-recent
      $capacity
      $lines)
   (CodexJsReplReadStderrRecent
     $capacity
     (codex:js-repl-stable-list $lines)))

(= (codex:js-repl-read-stderr-recent-from-arc
      (CodexJsReplArcMutex
        (CodexJsReplRecentStderrBuffer $capacity $lines)))
   (codex:js-repl-read-stderr-recent $capacity $lines))

(= (codex:js-repl-read-stderr-result $recent-stderr $warnings $end)
   (CodexJsReplReadStderrResult
     (codex:js-repl-read-stderr-recent-from-arc $recent-stderr)
     (codex:js-repl-read-stderr-warnings $warnings)
     $end))

(= (codex:js-repl-read-stderr-result-from-warning-box
      $recent-stderr
      $warnings
      $end)
   (CodexJsReplReadStderrResult
     (codex:js-repl-read-stderr-recent-from-arc $recent-stderr)
     $warnings
     $end))

(= (codex:js-repl-read-stderr-result-recent-stderr
      (CodexJsReplReadStderrResult
        (CodexJsReplReadStderrRecent $capacity $lines)
        $warnings-box
        $end))
   (CodexJsReplArcMutex
     (CodexJsReplRecentStderrBuffer
       $capacity
       (codex:js-repl-stable-list-items $lines))))

(= (codex:js-repl-read-stderr-result-lines
      (CodexJsReplReadStderrResult
        (CodexJsReplReadStderrRecent $capacity $lines)
        $warnings-box
        $end))
   (codex:js-repl-stable-list-items $lines))

(= (codex:js-repl-read-stderr-result-warnings
      (CodexJsReplReadStderrResult
        $recent-stderr
        (CodexJsReplReadStderrWarnings $warnings)
        $end))
   (codex:js-repl-stable-list-items $warnings))

(= (codex:js-repl-read-stderr-result-end
      (CodexJsReplReadStderrResult $recent-stderr $warnings-box $end))
   $end)

(= (codex:js-repl-read-stderr-warnings $warnings)
   (CodexJsReplReadStderrWarnings
     (codex:js-repl-stable-list $warnings)))

(= (codex:js-repl-read-stderr-warnings-items
      (CodexJsReplReadStderrWarnings $warnings))
   (codex:js-repl-stable-list-items $warnings))

(= (codex:js-repl-read-stderr-step $recent-stderr $warnings)
   (CodexJsReplReadStderrStep $recent-stderr $warnings))

(= (codex:js-repl-read-stderr-step-recent-stderr
      (CodexJsReplReadStderrStep $recent-stderr $warnings))
   $recent-stderr)

(= (codex:js-repl-read-stderr-step-warnings
      (CodexJsReplReadStderrStep $recent-stderr $warnings))
   $warnings)

(= (codex:js-repl-read-stderr-warning-line $bounded-line)
   (str-concat "js_repl stderr: " $bounded-line))

(= (codex:js-repl-read-stderr-warning-read-error $message)
   (str-concat "js_repl kernel stderr ended: " $message))

(= (codex:js-repl-recent-stderr-with-lines $recent-stderr $lines)
   (codex:js-repl-arc-mutex
     (codex:js-repl-recent-stderr-buffer
       (codex:js-repl-recent-stderr-buffer-capacity
         (codex:js-repl-arc-mutex-value $recent-stderr))
       $lines)))

(= (codex:js-repl-read-stderr-add-warning
      $warnings
      $bounded-line)
   (if (== $bounded-line "")
       $warnings
       (case $warnings
         (((CodexJsReplReadStderrWarnings $items)
           (CodexJsReplReadStderrWarnings
             (codex:js-repl-stable-list-append-item
               $items
               (codex:js-repl-read-stderr-warning-line
                 $bounded-line))))))))

(= (codex:js-repl-read-stderr-add-read-error-warning
      $warnings
      $message)
   (case $warnings
     (((CodexJsReplReadStderrWarnings $items)
       (CodexJsReplReadStderrWarnings
         (codex:js-repl-stable-list-append-item
           $items
           (codex:js-repl-read-stderr-warning-read-error
             $message)))))))

(= (codex:js-repl-read-stderr-step-from-push-result
      $recent-stderr
      $warnings
      (CodexJsReplStderrTailPushResult $tail $bounded-line))
   (codex:js-repl-read-stderr-step-from-push-result-capacity
     (codex:js-repl-recent-stderr-buffer-capacity
       (codex:js-repl-arc-mutex-value $recent-stderr))
     $warnings
     (CodexJsReplStderrTailPushResult $tail $bounded-line)))

(= (codex:js-repl-read-stderr-step-from-push-result-capacity
      $capacity
      $warnings
      (CodexJsReplStderrTailPushResult $tail $bounded-line))
   (codex:js-repl-read-stderr-step
     (CodexJsReplArcMutex
       (CodexJsReplRecentStderrBuffer
         $capacity
         $tail))
     (codex:js-repl-read-stderr-add-warning
       $warnings
       $bounded-line)))

(= (codex:js-repl-read-stderr-apply-line
      $recent-stderr
      $warnings
      $line)
   (let $step
     (codex:js-repl-read-stderr-apply-line-state
       $recent-stderr
       (codex:js-repl-read-stderr-warnings $warnings)
       $line)
     (codex:js-repl-read-stderr-result
       (codex:js-repl-read-stderr-step-recent-stderr $step)
       (codex:js-repl-read-stderr-warnings-items
         (codex:js-repl-read-stderr-step-warnings $step))
       CodexAbsent)))

(= (codex:js-repl-read-stderr-apply-line-state
      (CodexJsReplArcMutex
        (CodexJsReplRecentStderrBuffer $capacity $lines))
      $warnings
      $line)
   (let $trimmed (str-trim $line)
     (if (== $trimmed "")
         (codex:js-repl-read-stderr-step
           (CodexJsReplArcMutex
             (CodexJsReplRecentStderrBuffer $capacity $lines))
           $warnings)
         (let $push-result
           (codex:js-repl-push-stderr-tail-line
             $lines
             $trimmed)
           (codex:js-repl-read-stderr-step-from-push-result-capacity
             $capacity
             $warnings
             $push-result)))))

(= (codex:js-repl-read-stderr-plan
      $recent-stderr
      ())
   (codex:js-repl-read-stderr-result-from-warning-box
     $recent-stderr
     (codex:js-repl-read-stderr-warnings ())
     (codex:js-repl-read-stderr-end-eof)))

(= (codex:js-repl-read-stderr-plan
      $recent-stderr
      $events)
   (let $event (list:first $events)
     (case $event
       ((CodexJsReplStderrReaderEventEof
         (codex:js-repl-read-stderr-result-from-warning-box
           $recent-stderr
           (codex:js-repl-read-stderr-warnings ())
           (codex:js-repl-read-stderr-end-eof)))
        ((CodexJsReplStderrReaderEventReadError $message)
         (codex:js-repl-read-stderr-result-from-warning-box
           $recent-stderr
           (codex:js-repl-read-stderr-add-read-error-warning
             (codex:js-repl-read-stderr-warnings ())
             $message)
           (codex:js-repl-read-stderr-end-read-error $message)))
        (CodexJsReplStderrReaderEventShutdown
         (codex:js-repl-read-stderr-result-from-warning-box
           $recent-stderr
           (codex:js-repl-read-stderr-warnings ())
           (codex:js-repl-read-stderr-end-shutdown)))))))
