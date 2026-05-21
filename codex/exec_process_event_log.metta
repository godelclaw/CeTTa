; Rust-faithful exec-server process event-log slice.
;
; This ports the deterministic retained-history behavior from:
; - openai-codex/codex-rs/exec-server/src/process.rs
;   - ExecProcessEvent
;   - ExecProcessEvent::seq
;   - ExecProcessEvent::retained_len
;   - ExecProcessEventHistory
;   - ExecProcessEventLog::new
;   - ExecProcessEventLog::publish
;   - ExecProcessEventLog::subscribe replay materialization
;   - ExecProcessEventReceiver::empty replay shape
;   - ExecProcessEventReceiver::recv replay fast path
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust stores `Arc<ExecProcessEventLogInner>` with a `broadcast::Sender` for
;   live pushed events and a `StdMutex` around replay history. This pure CeTTa
;   slice returns updated immutable log atoms from `publish` and materializes
;   only the replay side of `subscribe`; the later async runtime boundary can
;   attach a live channel without changing the history eviction algorithm.
; - Rust `ProcessOutputChunk.chunk` is a byte vector wrapped in `ByteChunk`.
;   This slice uses the currently exposed CeTTa text boundary and measures
;   `str-length`, matching Rust byte counts for ASCII chunks. Arbitrary binary
;   byte preservation belongs with the shared byte-vector protocol slice.
; - Rust `Failed` has no sequence number and is synthesized by clients. This
;   slice exposes `CodexAbsent` for that `seq()` result, matching `Option::None`.

!(import! &self list)
!(import! &self str)

(= (codex:exec-output-stream-stdout)
   (CodexExecOutputStreamStdout))

(= (codex:exec-output-stream-stderr)
   (CodexExecOutputStreamStderr))

(= (codex:exec-output-stream-pty)
   (CodexExecOutputStreamPty))

(= (codex:exec-process-output-chunk $seq $stream $chunk)
   (CodexExecProcessOutputChunk $seq $stream $chunk))

(= (codex:exec-process-output-chunk-seq
      (CodexExecProcessOutputChunk $seq $stream $chunk))
   $seq)

(= (codex:exec-process-output-chunk-stream
      (CodexExecProcessOutputChunk $seq $stream $chunk))
   $stream)

(= (codex:exec-process-output-chunk-chunk
      (CodexExecProcessOutputChunk $seq $stream $chunk))
   $chunk)

(= (codex:exec-process-event-output $chunk)
   (CodexExecProcessEventOutput $chunk))

(= (codex:exec-process-event-exited $seq $exit-code)
   (CodexExecProcessEventExited $seq $exit-code))

(= (codex:exec-process-event-closed $seq)
   (CodexExecProcessEventClosed $seq))

(= (codex:exec-process-event-failed $message)
   (CodexExecProcessEventFailed $message))

(= (codex:exec-process-event-seq
      (CodexExecProcessEventOutput $chunk))
   (codex:exec-process-output-chunk-seq $chunk))

(= (codex:exec-process-event-seq
      (CodexExecProcessEventExited $seq $exit-code))
   $seq)

(= (codex:exec-process-event-seq
      (CodexExecProcessEventClosed $seq))
   $seq)

(= (codex:exec-process-event-seq
      (CodexExecProcessEventFailed $message))
   CodexAbsent)

(= (codex:exec-process-event-retained-len
      (CodexExecProcessEventOutput $chunk))
   (str-length (codex:exec-process-output-chunk-chunk $chunk)))

(= (codex:exec-process-event-retained-len
      (CodexExecProcessEventFailed $message))
   (str-length $message))

(= (codex:exec-process-event-retained-len
      (CodexExecProcessEventExited $seq $exit-code))
   0)

(= (codex:exec-process-event-retained-len
      (CodexExecProcessEventClosed $seq))
   0)

(= (codex:exec-process-event-history $events $retained-bytes)
   (CodexExecProcessEventHistory $events $retained-bytes))

(= (codex:exec-process-event-history-default)
   (CodexExecProcessEventHistory () 0))

(= (codex:exec-process-event-history-events
      (CodexExecProcessEventHistory $events $retained-bytes))
   $events)

(= (codex:exec-process-event-history-retained-bytes
      (CodexExecProcessEventHistory $events $retained-bytes))
   $retained-bytes)

(= (codex:exec-process-event-log
      $history
      $event-capacity
      $byte-capacity)
   (CodexExecProcessEventLog $history $event-capacity $byte-capacity))

(= (codex:exec-process-event-log-new $event-capacity $byte-capacity)
   (CodexExecProcessEventLog
     (codex:exec-process-event-history-default)
     $event-capacity
     $byte-capacity))

(= (codex:exec-process-event-log-history
      (CodexExecProcessEventLog
        $history
        $event-capacity
        $byte-capacity))
   $history)

(= (codex:exec-process-event-log-event-capacity
      (CodexExecProcessEventLog
        $history
        $event-capacity
        $byte-capacity))
   $event-capacity)

(= (codex:exec-process-event-log-byte-capacity
      (CodexExecProcessEventLog
        $history
        $event-capacity
        $byte-capacity))
   $byte-capacity)

(= (codex:exec-process-event-saturating-sub $value $amount)
   (if (< $value $amount)
       0
       (- $value $amount)))

(= (codex:exec-process-event-history-should-evict
      $events
      $retained-bytes
      $event-capacity
      $byte-capacity)
   (or
     (> (list:len $events) $event-capacity)
     (> $retained-bytes $byte-capacity)))

(= (codex:exec-process-event-history-trim
      $events
      $retained-bytes
      $event-capacity
      $byte-capacity)
   (if (list:empty? $events)
       (CodexExecProcessEventHistory () $retained-bytes)
       (if (codex:exec-process-event-history-should-evict
             $events
             $retained-bytes
             $event-capacity
             $byte-capacity)
           (let $evicted (list:first $events)
             (codex:exec-process-event-history-trim
               (list:rest $events)
               (codex:exec-process-event-saturating-sub
                 $retained-bytes
                 (codex:exec-process-event-retained-len $evicted))
               $event-capacity
               $byte-capacity))
           (CodexExecProcessEventHistory $events $retained-bytes))))

(= (codex:exec-process-event-log-publish
      (CodexExecProcessEventLog
        (CodexExecProcessEventHistory $events $retained-bytes)
        $event-capacity
        $byte-capacity)
      $event)
   (let $history
     (codex:exec-process-event-history-trim
       (list:append $events ($event))
       (+ $retained-bytes (codex:exec-process-event-retained-len $event))
       $event-capacity
       $byte-capacity)
     (CodexExecProcessEventLog
       $history
       $event-capacity
       $byte-capacity)))

(= (codex:exec-process-event-receiver $replay)
   (CodexExecProcessEventReceiver $replay))

(= (codex:exec-process-event-receiver-empty)
   (CodexExecProcessEventReceiver ()))

(= (codex:exec-process-event-receiver-replay
      (CodexExecProcessEventReceiver $replay))
   $replay)

(= (codex:exec-process-event-recv-ok $event $receiver)
   (CodexExecProcessEventRecvOk $event $receiver))

(= (codex:exec-process-event-recv-live-pending $receiver)
   (CodexExecProcessEventRecvLivePending $receiver))

(= (codex:exec-process-event-recv-result-event
      (CodexExecProcessEventRecvOk $event $receiver))
   $event)

(= (codex:exec-process-event-recv-result-receiver
      (CodexExecProcessEventRecvOk $event $receiver))
   $receiver)

(= (codex:exec-process-event-recv-result-receiver
      (CodexExecProcessEventRecvLivePending $receiver))
   $receiver)

(= (codex:exec-process-event-receiver-recv
      (CodexExecProcessEventReceiver $replay))
   (if (list:empty? $replay)
       (CodexExecProcessEventRecvLivePending
         (CodexExecProcessEventReceiver ()))
       (CodexExecProcessEventRecvOk
         (list:first $replay)
         (CodexExecProcessEventReceiver (list:rest $replay)))))

(= (codex:exec-process-event-log-subscribe
      (CodexExecProcessEventLog
        (CodexExecProcessEventHistory $events $retained-bytes)
        $event-capacity
        $byte-capacity))
   (CodexExecProcessEventReceiver $events))
