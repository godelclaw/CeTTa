; Rust-faithful pure unified-exec async-watcher chunk slice.
;
; This ports deterministic behavior from:
; - openai-codex/codex-rs/core/src/unified_exec/async_watcher.rs
;   - TRAILING_OUTPUT_GRACE
;   - UNIFIED_EXEC_OUTPUT_DELTA_MAX_BYTES
;   - process_chunk
;   - split_valid_utf8_prefix
;   - split_valid_utf8_prefix_with_max
; - openai-codex/codex-rs/core/src/exec.rs
;   - MAX_EXEC_OUTPUT_DELTAS_PER_CALL
;
; Covered in this increment:
; - exact split-valid-UTF-8-prefix loop, including the Rust progress rule that
;   emits one byte if no valid prefix is found
; - process_chunk's pending-buffer append, transcript append, stdout delta
;   emission cap, and continued transcript capture after the event cap
; - start_streaming_output's cancellation/grace/receiver branch loop
; - resolve_aggregated_output
; - emit_exec_end_for_unified_exec
; - emit_failed_exec_end_for_unified_exec
; - spawn_exit_watcher's post-cancellation/post-drain branch
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust mutates `Vec<u8>` and emits protocol events with byte chunks that are
;   base64-encoded later by serde. This pure boundary represents chunks as
;   integer byte lists and returns local delta-byte event atoms; the later
;   runtime/protocol bridge can base64 materialize those same byte lists.
; - Rust writes into `Arc<Mutex<HeadTailBuffer>>` and sends through `Session`.
;   This slice carries transcript bytes and emitted events in an immutable state
;   record so the same branch behavior is testable without async effects.
; - Rust's `tokio::select!` observes cancellation, timer completion, and
;   broadcast receiver outcomes asynchronously. This port receives one
;   materialized observation per pure step and returns the corresponding loop
;   state, preserving the select guards and branch side effects.
; - Rust decodes HeadTailBuffer bytes with `String::from_utf8_lossy()` and
;   computes `formatted_output` inside ToolEmitter from the turn truncation
;   policy. These pure end-event helpers receive the already-materialized lossy
;   transcript text and formatted output at the runtime boundary while
;   preserving async_watcher's branch choices and protocol event fields.

!(import! &self command)
!(import! &self list)
!(import! &self str)

(= (codex:unified-exec-trailing-output-grace-ms)
   100)

(= (codex:unified-exec-output-delta-max-bytes)
   8192)

(= (codex:max-exec-output-deltas-per-call)
   10000)

(= (codex:unified-exec-utf8-prefix-split-none)
   CodexUnifiedExecUtf8PrefixSplitNone)

(= (codex:unified-exec-utf8-prefix-split-some
      $prefix
      $remaining)
   (CodexUnifiedExecUtf8PrefixSplitSome $prefix $remaining))

(= (codex:unified-exec-utf8-prefix-split-kind
      CodexUnifiedExecUtf8PrefixSplitNone)
   none)

(= (codex:unified-exec-utf8-prefix-split-kind
      (CodexUnifiedExecUtf8PrefixSplitSome $prefix $remaining))
   some)

(= (codex:unified-exec-utf8-prefix-split-prefix
      (CodexUnifiedExecUtf8PrefixSplitSome $prefix $remaining))
   $prefix)

(= (codex:unified-exec-utf8-prefix-split-remaining
      (CodexUnifiedExecUtf8PrefixSplitSome $prefix $remaining))
   $remaining)

(= (codex:unified-exec-byte-list-take $bytes $count)
   (if (or (== $bytes ()) (<= $count 0))
       ()
       (let $head (list:first $bytes)
         (let $tail (list:rest $bytes)
           (let $next-count (eval (- $count 1))
             (let $rest
               (eval
                 (codex:unified-exec-byte-list-take
                   $tail
                   $next-count))
               (cons-atom $head $rest)))))))

(= (codex:unified-exec-byte-list-drop $bytes $count)
   (if (or (== $bytes ()) (<= $count 0))
       $bytes
       (let $next-count (eval (- $count 1))
         (codex:unified-exec-byte-list-drop
           (list:rest $bytes)
           $next-count))))

(= (codex:unified-exec-byte-list-min $lhs $rhs)
   (if (< $lhs $rhs) $lhs $rhs))

(= (codex:unified-exec-byte-is-continuation $byte)
   (and (>= $byte 128) (<= $byte 191)))

(= (codex:unified-exec-byte-list-has-at-least $bytes $count)
   (>= (list:len $bytes) $count))

(= (codex:unified-exec-utf8-valid-2 $bytes)
   (if (not (codex:unified-exec-byte-list-has-at-least $bytes 2))
       False
       (let $b1 (list:at $bytes 0)
         (let $b2 (list:at $bytes 1)
           (and
             (and (>= $b1 194) (<= $b1 223))
             (codex:unified-exec-byte-is-continuation $b2))))))

(= (codex:unified-exec-utf8-valid-3 $bytes)
   (if (not (codex:unified-exec-byte-list-has-at-least $bytes 3))
       False
       (let $b1 (list:at $bytes 0)
         (let $b2 (list:at $bytes 1)
           (let $b3 (list:at $bytes 2)
             (if (== $b1 224)
                 (and
                   (and (>= $b2 160) (<= $b2 191))
                   (codex:unified-exec-byte-is-continuation $b3))
                 (if (and (>= $b1 225) (<= $b1 236))
                     (and
                       (codex:unified-exec-byte-is-continuation $b2)
                       (codex:unified-exec-byte-is-continuation $b3))
                     (if (== $b1 237)
                         (and
                           (and (>= $b2 128) (<= $b2 159))
                           (codex:unified-exec-byte-is-continuation $b3))
                         (and
                           (and (>= $b1 238) (<= $b1 239))
                           (and
                             (codex:unified-exec-byte-is-continuation $b2)
                             (codex:unified-exec-byte-is-continuation $b3)))))))))))

(= (codex:unified-exec-utf8-valid-4 $bytes)
   (if (not (codex:unified-exec-byte-list-has-at-least $bytes 4))
       False
       (let $b1 (list:at $bytes 0)
         (let $b2 (list:at $bytes 1)
           (let $b3 (list:at $bytes 2)
             (let $b4 (list:at $bytes 3)
               (if (== $b1 240)
                   (and
                     (and (>= $b2 144) (<= $b2 191))
                     (and
                       (codex:unified-exec-byte-is-continuation $b3)
                       (codex:unified-exec-byte-is-continuation $b4)))
                   (if (and (>= $b1 241) (<= $b1 243))
                       (and
                         (codex:unified-exec-byte-is-continuation $b2)
                         (and
                           (codex:unified-exec-byte-is-continuation $b3)
                           (codex:unified-exec-byte-is-continuation $b4)))
                       (and
                         (== $b1 244)
                         (and
                           (and (>= $b2 128) (<= $b2 143))
                           (and
                             (codex:unified-exec-byte-is-continuation $b3)
                            (codex:unified-exec-byte-is-continuation $b4))))))))))))

(= (codex:unified-exec-utf8-codepoint-length $first-byte)
   (if (<= $first-byte 127)
       1
       (if (and (>= $first-byte 194) (<= $first-byte 223))
           2
           (if (and (>= $first-byte 224) (<= $first-byte 239))
               3
               (if (and (>= $first-byte 240) (<= $first-byte 244))
                   4
                   CodexAbsent)))))

(= (codex:unified-exec-utf8-valid-first-codepoint $bytes)
   (if (== $bytes ())
       False
       (let $first-byte (list:first $bytes)
         (let $len (codex:unified-exec-utf8-codepoint-length $first-byte)
           (if (== $len CodexAbsent)
               False
               (if (== $len 1)
                   True
                   (if (== $len 2)
                       (codex:unified-exec-utf8-valid-2 $bytes)
                       (if (== $len 3)
                           (codex:unified-exec-utf8-valid-3 $bytes)
                           (codex:unified-exec-utf8-valid-4
                             $bytes)))))))))

(= (codex:unified-exec-utf8-valid-bytes $bytes)
   (if (== $bytes ())
       True
       (if (not (codex:unified-exec-utf8-valid-first-codepoint $bytes))
           False
           (let $len
             (codex:unified-exec-utf8-codepoint-length
               (list:first $bytes))
             (codex:unified-exec-utf8-valid-bytes
               (codex:unified-exec-byte-list-drop
                 $bytes
                 $len))))))

(= (codex:unified-exec-split-valid-utf8-prefix $buffer)
   (codex:unified-exec-split-valid-utf8-prefix-with-max
     $buffer
     (codex:unified-exec-output-delta-max-bytes)))

(= (codex:unified-exec-split-valid-utf8-prefix-with-max
      $buffer
      $max-bytes)
   (if (== $buffer ())
       (codex:unified-exec-utf8-prefix-split-none)
       (let $max-len
         (codex:unified-exec-byte-list-min
           (list:len $buffer)
           $max-bytes)
         (codex:unified-exec-split-valid-utf8-prefix-loop
           $buffer
           $max-len
           $max-len))))

(= (codex:unified-exec-split-valid-utf8-prefix-progress
      $buffer)
   (codex:unified-exec-utf8-prefix-split-some
     (codex:unified-exec-byte-list-take $buffer 1)
     (codex:unified-exec-byte-list-drop $buffer 1)))

(= (codex:unified-exec-split-valid-utf8-prefix-loop
      $buffer
      $max-len
      $split)
   (if (<= $split 0)
       (codex:unified-exec-split-valid-utf8-prefix-progress
         $buffer)
       (let $prefix
         (codex:unified-exec-byte-list-take $buffer $split)
         (if (codex:unified-exec-utf8-valid-bytes $prefix)
             (codex:unified-exec-utf8-prefix-split-some
               $prefix
               (codex:unified-exec-byte-list-drop
                 $buffer
                 $split))
             (if (> (eval (- $max-len $split)) 4)
                 (codex:unified-exec-split-valid-utf8-prefix-progress
                   $buffer)
                 (let $next-split (eval (- $split 1))
                   (codex:unified-exec-split-valid-utf8-prefix-loop
                     $buffer
                     $max-len
                     $next-split)))))))

(= (codex:unified-exec-output-delta-bytes-event
      $call-id
      $stream
      $chunk)
   (CodexUnifiedExecOutputDeltaBytesEvent
     $call-id
     $stream
     $chunk))

(= (codex:unified-exec-output-delta-bytes-event-call-id
      (CodexUnifiedExecOutputDeltaBytesEvent
        $call-id
        $stream
        $chunk))
   $call-id)

(= (codex:unified-exec-output-delta-bytes-event-stream
      (CodexUnifiedExecOutputDeltaBytesEvent
        $call-id
        $stream
        $chunk))
   $stream)

(= (codex:unified-exec-output-delta-bytes-event-chunk
      (CodexUnifiedExecOutputDeltaBytesEvent
        $call-id
        $stream
        $chunk))
   $chunk)

(= (codex:unified-exec-async-watcher-chunk-state
      $pending
      $transcript
      $emitted-deltas
      $events)
   (CodexUnifiedExecAsyncWatcherChunkState
     $pending
     $transcript
     $emitted-deltas
     $events))

(= (codex:unified-exec-async-watcher-chunk-state-pending
      (CodexUnifiedExecAsyncWatcherChunkState
        $pending
        $transcript
        $emitted-deltas
        $events))
   $pending)

(= (codex:unified-exec-async-watcher-chunk-state-transcript
      (CodexUnifiedExecAsyncWatcherChunkState
        $pending
        $transcript
        $emitted-deltas
        $events))
   $transcript)

(= (codex:unified-exec-async-watcher-chunk-state-emitted-deltas
      (CodexUnifiedExecAsyncWatcherChunkState
        $pending
        $transcript
        $emitted-deltas
        $events))
   $emitted-deltas)

(= (codex:unified-exec-async-watcher-chunk-state-events
      (CodexUnifiedExecAsyncWatcherChunkState
        $pending
        $transcript
        $emitted-deltas
        $events))
   $events)

(= (codex:unified-exec-process-chunk $state $call-id $chunk)
   (codex:unified-exec-process-chunk-with-limits
     $state
     $call-id
     $chunk
     (codex:max-exec-output-deltas-per-call)
     (codex:unified-exec-output-delta-max-bytes)))

(= (codex:unified-exec-process-chunk-with-limits
      $state
      $call-id
      $chunk
      $max-deltas
      $max-delta-bytes)
   (let $pending
     (eval
       (list:append
         (codex:unified-exec-async-watcher-chunk-state-pending
           $state)
         $chunk))
     (codex:unified-exec-process-chunk-pending-loop
       (codex:unified-exec-async-watcher-chunk-state
         $pending
         (codex:unified-exec-async-watcher-chunk-state-transcript
           $state)
         (codex:unified-exec-async-watcher-chunk-state-emitted-deltas
           $state)
         (codex:unified-exec-async-watcher-chunk-state-events
           $state))
       $call-id
       $max-deltas
       $max-delta-bytes)))

(= (codex:unified-exec-process-chunk-pending-loop
      $state
      $call-id
      $max-deltas
      $max-delta-bytes)
   (let $pending
     (codex:unified-exec-async-watcher-chunk-state-pending
       $state)
     (if (== $pending ())
         $state
         (let $split
           (codex:unified-exec-split-valid-utf8-prefix-with-max
             $pending
             $max-delta-bytes)
           (if (== (codex:unified-exec-utf8-prefix-split-kind
                     $split)
                   none)
               $state
               (codex:unified-exec-process-chunk-prefix
                 $state
                 $call-id
                 $max-deltas
                 $max-delta-bytes
                 (codex:unified-exec-utf8-prefix-split-prefix
                   $split)
                 (codex:unified-exec-utf8-prefix-split-remaining
                   $split)))))))

(= (codex:unified-exec-process-chunk-prefix
      $state
      $call-id
      $max-deltas
      $max-delta-bytes
      $prefix
      $remaining)
   (let $transcript
     (eval
       (list:append
         (codex:unified-exec-async-watcher-chunk-state-transcript
           $state)
         $prefix))
     (let $emitted-deltas
       (codex:unified-exec-async-watcher-chunk-state-emitted-deltas
         $state)
       (if (>= $emitted-deltas $max-deltas)
           (codex:unified-exec-process-chunk-pending-loop
             (codex:unified-exec-async-watcher-chunk-state
               $remaining
               $transcript
               $emitted-deltas
               (codex:unified-exec-async-watcher-chunk-state-events
                 $state))
             $call-id
             $max-deltas
             $max-delta-bytes)
           (let $events
             (eval
               (list:append
                 (codex:unified-exec-async-watcher-chunk-state-events
                   $state)
                 ((codex:unified-exec-output-delta-bytes-event
                    $call-id
                    stdout
                    $prefix))))
             (codex:unified-exec-process-chunk-pending-loop
               (codex:unified-exec-async-watcher-chunk-state
                 $remaining
                 $transcript
                 (+ $emitted-deltas 1)
                 $events)
               $call-id
               $max-deltas
               $max-delta-bytes))))))

(= (codex:unified-exec-stream-grace-sleep-none)
   CodexUnifiedExecStreamGraceSleepNone)

(= (codex:unified-exec-stream-grace-sleep-deadline-ms
      $deadline-ms)
   (CodexUnifiedExecStreamGraceSleepDeadlineMs $deadline-ms))

(= (codex:unified-exec-stream-grace-sleep-kind
      CodexUnifiedExecStreamGraceSleepNone)
   none)

(= (codex:unified-exec-stream-grace-sleep-kind
      (CodexUnifiedExecStreamGraceSleepDeadlineMs $deadline-ms))
   active)

(= (codex:unified-exec-stream-grace-sleep-deadline-value-ms
      (CodexUnifiedExecStreamGraceSleepDeadlineMs $deadline-ms))
   $deadline-ms)

(= (codex:unified-exec-stream-loop-state
      $chunk-state
      $grace-sleep
      $is-output-drained-notified
      $is-running)
   (CodexUnifiedExecStreamLoopState
     $chunk-state
     $grace-sleep
     $is-output-drained-notified
     $is-running))

(= (codex:unified-exec-stream-loop-state-chunk-state
      (CodexUnifiedExecStreamLoopState
        $chunk-state
        $grace-sleep
        $is-output-drained-notified
        $is-running))
   $chunk-state)

(= (codex:unified-exec-stream-loop-state-grace-sleep
      (CodexUnifiedExecStreamLoopState
        $chunk-state
        $grace-sleep
        $is-output-drained-notified
        $is-running))
   $grace-sleep)

(= (codex:unified-exec-stream-loop-state-is-output-drained-notified
      (CodexUnifiedExecStreamLoopState
        $chunk-state
        $grace-sleep
        $is-output-drained-notified
        $is-running))
   $is-output-drained-notified)

(= (codex:unified-exec-stream-loop-state-is-running
      (CodexUnifiedExecStreamLoopState
        $chunk-state
        $grace-sleep
        $is-output-drained-notified
        $is-running))
   $is-running)

(= (codex:unified-exec-stream-loop-state-initial)
   (codex:unified-exec-stream-loop-state
     (codex:unified-exec-async-watcher-chunk-state () () 0 ())
     (codex:unified-exec-stream-grace-sleep-none)
     False
     True))

(= (codex:unified-exec-stream-observation-exit-cancelled
      $now-ms)
   (CodexUnifiedExecStreamObservationExitCancelled $now-ms))

(= (codex:unified-exec-stream-observation-grace-elapsed)
   CodexUnifiedExecStreamObservationGraceElapsed)

(= (codex:unified-exec-stream-observation-recv-ok $chunk)
   (CodexUnifiedExecStreamObservationRecvOk $chunk))

(= (codex:unified-exec-stream-observation-recv-lagged
      $skipped-count)
   (CodexUnifiedExecStreamObservationRecvLagged $skipped-count))

(= (codex:unified-exec-stream-observation-recv-closed)
   CodexUnifiedExecStreamObservationRecvClosed)

(= (codex:unified-exec-stream-observation-kind
      (CodexUnifiedExecStreamObservationExitCancelled $now-ms))
   exit_cancelled)

(= (codex:unified-exec-stream-observation-kind
      CodexUnifiedExecStreamObservationGraceElapsed)
   grace_elapsed)

(= (codex:unified-exec-stream-observation-kind
      (CodexUnifiedExecStreamObservationRecvOk $chunk))
   recv_ok)

(= (codex:unified-exec-stream-observation-kind
      (CodexUnifiedExecStreamObservationRecvLagged $skipped-count))
   recv_lagged)

(= (codex:unified-exec-stream-observation-kind
      CodexUnifiedExecStreamObservationRecvClosed)
   recv_closed)

(= (codex:unified-exec-stream-observation-exit-cancelled-now-ms
      (CodexUnifiedExecStreamObservationExitCancelled $now-ms))
   $now-ms)

(= (codex:unified-exec-stream-observation-recv-ok-chunk
      (CodexUnifiedExecStreamObservationRecvOk $chunk))
   $chunk)

(= (codex:unified-exec-stream-loop-state-with-grace-sleep
      (CodexUnifiedExecStreamLoopState
        $chunk-state
        $grace-sleep
        $is-output-drained-notified
        $is-running)
      $new-grace-sleep)
   (CodexUnifiedExecStreamLoopState
     $chunk-state
     $new-grace-sleep
     $is-output-drained-notified
     $is-running))

(= (codex:unified-exec-stream-loop-state-with-chunk-state
      (CodexUnifiedExecStreamLoopState
        $chunk-state
        $grace-sleep
        $is-output-drained-notified
        $is-running)
      $new-chunk-state)
   (CodexUnifiedExecStreamLoopState
     $new-chunk-state
     $grace-sleep
     $is-output-drained-notified
     $is-running))

(= (codex:unified-exec-stream-loop-state-break
      (CodexUnifiedExecStreamLoopState
        $chunk-state
        $grace-sleep
        $is-output-drained-notified
        $is-running))
   (CodexUnifiedExecStreamLoopState
     $chunk-state
     $grace-sleep
     True
     False))

(= (codex:unified-exec-start-streaming-output-step
      $state
      $call-id
      $observation)
   (codex:unified-exec-start-streaming-output-step-with-limits
     $state
     $call-id
     $observation
     (codex:max-exec-output-deltas-per-call)
     (codex:unified-exec-output-delta-max-bytes)))

(= (codex:unified-exec-start-streaming-output-step-with-limits
      $state
      $call-id
      $observation
      $max-deltas
      $max-delta-bytes)
   (if (not (codex:unified-exec-stream-loop-state-is-running
              $state))
       $state
       (let $kind
         (codex:unified-exec-stream-observation-kind $observation)
         (if (== $kind exit_cancelled)
             (codex:unified-exec-start-streaming-output-on-exit-cancelled
               $state
               (codex:unified-exec-stream-observation-exit-cancelled-now-ms
                 $observation))
             (if (== $kind grace_elapsed)
                 (codex:unified-exec-start-streaming-output-on-grace-elapsed
                   $state)
                 (if (== $kind recv_ok)
                     (codex:unified-exec-stream-loop-state-with-chunk-state
                       $state
                       (codex:unified-exec-process-chunk-with-limits
                         (codex:unified-exec-stream-loop-state-chunk-state
                           $state)
                         $call-id
                         (codex:unified-exec-stream-observation-recv-ok-chunk
                           $observation)
                         $max-deltas
                         $max-delta-bytes))
                     (if (== $kind recv_lagged)
                         $state
                         (codex:unified-exec-stream-loop-state-break
                           $state))))))))

(= (codex:unified-exec-start-streaming-output-on-exit-cancelled
      $state
      $now-ms)
   (let $grace-sleep
     (codex:unified-exec-stream-loop-state-grace-sleep
       $state)
     (if (== (codex:unified-exec-stream-grace-sleep-kind
               $grace-sleep)
             none)
         (codex:unified-exec-stream-loop-state-with-grace-sleep
           $state
           (codex:unified-exec-stream-grace-sleep-deadline-ms
             (+ $now-ms
                (codex:unified-exec-trailing-output-grace-ms))))
         $state)))

(= (codex:unified-exec-start-streaming-output-on-grace-elapsed
      $state)
   (let $grace-sleep
     (codex:unified-exec-stream-loop-state-grace-sleep
       $state)
     (if (== (codex:unified-exec-stream-grace-sleep-kind
               $grace-sleep)
             active)
         (codex:unified-exec-stream-loop-state-break $state)
         $state)))

(= (codex:unified-exec-async-watcher-transcript
      $retained-bytes
      $text)
   (CodexUnifiedExecAsyncWatcherTranscript $retained-bytes $text))

(= (codex:unified-exec-async-watcher-transcript-retained-bytes
      (CodexUnifiedExecAsyncWatcherTranscript
        $retained-bytes
        $text))
   $retained-bytes)

(= (codex:unified-exec-async-watcher-transcript-text
      (CodexUnifiedExecAsyncWatcherTranscript
        $retained-bytes
        $text))
   $text)

(= (codex:unified-exec-async-watcher-transcript-from-state
      $state
      $materialized-text)
   (codex:unified-exec-async-watcher-transcript
     (list:len
       (codex:unified-exec-async-watcher-chunk-state-transcript
         $state))
     $materialized-text))

(= (codex:unified-exec-resolve-aggregated-output
      $transcript
      $fallback)
   (if (== (codex:unified-exec-async-watcher-transcript-retained-bytes
             $transcript)
           0)
       $fallback
       (codex:unified-exec-async-watcher-transcript-text
         $transcript)))

(= (codex:unified-exec-exec-command-status-for-exit-code
      $exit-code)
   (if (== $exit-code 0)
       (CodexExecCommandStatusCompleted)
       (CodexExecCommandStatusFailed)))

(= (codex:unified-exec-exit-code-or-default $exit-code)
   (if (== $exit-code CodexAbsent)
       -1
       $exit-code))

(= (codex:unified-exec-failed-aggregated-output
      $stdout
      $message)
   (if (== $stdout "")
       $message
       (str-concat $stdout (str-concat "\n" $message))))

(= (codex:unified-exec-emit-exec-end-for-unified-exec
      $call-id
      $turn-id
      $command
      $cwd
      $process-id
      $transcript
      $fallback-output
      $exit-code
      $duration
      $formatted-output)
   (codex:unified-exec-emit-exec-end-for-unified-exec-with-parsed
     $call-id
     $turn-id
     $command
     $cwd
     (codex:parse-command $command)
     $process-id
     $transcript
     $fallback-output
     $exit-code
     $duration
     $formatted-output))

(= (codex:unified-exec-emit-exec-end-for-unified-exec-with-parsed
      $call-id
      $turn-id
      $command
      $cwd
      $parsed-cmd
      $process-id
      $transcript
      $fallback-output
      $exit-code
      $duration
      $formatted-output)
   (let $aggregated-output
     (codex:unified-exec-resolve-aggregated-output
       $transcript
       $fallback-output)
     (CodexEventExecCommandEnd
       $call-id
       $process-id
       $turn-id
       $command
       $cwd
       $parsed-cmd
       (CodexExecCommandSourceUnifiedExecStartup)
       CodexAbsent
       $aggregated-output
       ""
       $aggregated-output
       $exit-code
       $duration
       $formatted-output
       (codex:unified-exec-exec-command-status-for-exit-code
         $exit-code))))

(= (codex:unified-exec-emit-failed-exec-end-for-unified-exec
      $call-id
      $turn-id
      $command
      $cwd
      $process-id
      $transcript
      $message
      $duration
      $formatted-output)
   (codex:unified-exec-emit-failed-exec-end-for-unified-exec-with-parsed
     $call-id
     $turn-id
     $command
     $cwd
     (codex:parse-command $command)
     $process-id
     $transcript
     $message
     $duration
     $formatted-output))

(= (codex:unified-exec-emit-failed-exec-end-for-unified-exec-with-parsed
      $call-id
      $turn-id
      $command
      $cwd
      $parsed-cmd
      $process-id
      $transcript
      $message
      $duration
      $formatted-output)
   (let $stdout
     (codex:unified-exec-resolve-aggregated-output
       $transcript
       "")
     (let $aggregated-output
       (codex:unified-exec-failed-aggregated-output
         $stdout
         $message)
       (CodexEventExecCommandEnd
         $call-id
         $process-id
         $turn-id
         $command
         $cwd
         $parsed-cmd
         (CodexExecCommandSourceUnifiedExecStartup)
         CodexAbsent
         $stdout
         $message
         $aggregated-output
         -1
         $duration
         $formatted-output
         (CodexExecCommandStatusFailed)))))

(= (codex:unified-exec-async-watcher-process-snapshot
      $failure-message
      $exit-code)
   (CodexUnifiedExecAsyncWatcherProcessSnapshot
     $failure-message
     $exit-code))

(= (codex:unified-exec-async-watcher-process-snapshot-failure-message
      (CodexUnifiedExecAsyncWatcherProcessSnapshot
        $failure-message
        $exit-code))
   $failure-message)

(= (codex:unified-exec-async-watcher-process-snapshot-exit-code
      (CodexUnifiedExecAsyncWatcherProcessSnapshot
        $failure-message
        $exit-code))
   $exit-code)

(= (codex:unified-exec-spawn-exit-watcher-finished-event
      $process-snapshot
      $call-id
      $turn-id
      $command
      $cwd
      $process-id
      $transcript
      $duration
      $formatted-output)
   (codex:unified-exec-spawn-exit-watcher-finished-event-with-parsed
     $process-snapshot
     $call-id
     $turn-id
     $command
     $cwd
     (codex:parse-command $command)
     $process-id
     $transcript
     $duration
     $formatted-output))

(= (codex:unified-exec-spawn-exit-watcher-finished-event-with-parsed
      $process-snapshot
      $call-id
      $turn-id
      $command
      $cwd
      $parsed-cmd
      $process-id
      $transcript
      $duration
      $formatted-output)
   (let $failure-message
     (codex:unified-exec-async-watcher-process-snapshot-failure-message
       $process-snapshot)
     (if (== $failure-message CodexAbsent)
         (codex:unified-exec-emit-exec-end-for-unified-exec-with-parsed
           $call-id
           $turn-id
           $command
           $cwd
           $parsed-cmd
           $process-id
           $transcript
           ""
           (codex:unified-exec-exit-code-or-default
             (codex:unified-exec-async-watcher-process-snapshot-exit-code
               $process-snapshot))
           $duration
           $formatted-output)
         (codex:unified-exec-emit-failed-exec-end-for-unified-exec-with-parsed
           $call-id
           $turn-id
           $command
           $cwd
           $parsed-cmd
           $process-id
           $transcript
           $failure-message
           $duration
           $formatted-output))))
