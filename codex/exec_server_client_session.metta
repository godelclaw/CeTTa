; Rust-faithful exec-server client session-state slice.
;
; This ports deterministic client-session behavior from:
; - openai-codex/codex-rs/exec-server/src/client.rs
;   - PROCESS_EVENT_CHANNEL_CAPACITY / PROCESS_EVENT_RETAINED_BYTES
;   - OrderedSessionEvents
;   - SessionState::new
;   - SessionState::note_change
;   - SessionState::publish_ordered_event
;   - SessionState::set_failure
;   - SessionState::failed_response / synthesized_failure
;   - disconnected_message
;   - is_transport_closed_error
;   - record_disconnected first-writer latch behavior
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust stores session state behind Arc, Mutex, watch channels, and a
;   BTreeMap. This pure CeTTa slice returns updated immutable atoms while
;   preserving the visible ordering, wake counter, retained-event log, and
;   failure-response algorithms.
; - Rust `OrderedSessionEvents.pending` is a `BTreeMap<u64, ExecProcessEvent>`.
;   This slice stores pending entries in a list and removes by exact sequence;
;   because the Rust algorithm only observes exact `next_seq` removals and
;   duplicate `entry(...).or_insert(...)` behavior, map iteration order is not
;   part of the visible contract.
; - Rust wake sequence counters saturate at `u64::MAX`. CeTTa's current
;   numeric comparison surface does not reliably reduce the `u64::MAX` literal,
;   so this slice names that boundary with `CodexExecServerClientU64Max` and
;   preserves exact numeric behavior below the sentinel.

!(import! &self list)
!(import! &self str)
!(import! &self exec_process_event_log)
!(import! &self exec_server_process_protocol)

(= (codex:exec-server-client-process-event-channel-capacity)
   256)

(= (codex:exec-server-client-process-event-retained-bytes)
   1048576)

(= (codex:exec-server-client-u64-max)
   (CodexExecServerClientU64Max))

(= (codex:exec-server-client-saturating-add-one-u64 $value)
   (if (== $value (codex:exec-server-client-u64-max))
       (codex:exec-server-client-u64-max)
       (+ $value 1)))

(= (codex:exec-server-client-max-u64 $left $right)
   (if (== $left (codex:exec-server-client-u64-max))
       (codex:exec-server-client-u64-max)
       (if (== $right (codex:exec-server-client-u64-max))
           (codex:exec-server-client-u64-max)
           (if (> $left $right) $left $right))))

(= (codex:exec-server-client-pending-event $seq $event)
   (CodexExecServerClientPendingEvent $seq $event))

(= (codex:exec-server-client-pending-event-seq
      (CodexExecServerClientPendingEvent $seq $event))
   $seq)

(= (codex:exec-server-client-pending-event-event
      (CodexExecServerClientPendingEvent $seq $event))
   $event)

(= (codex:exec-server-client-pending-contains-seq () $seq)
   False)

(= (codex:exec-server-client-pending-contains-seq $pending $seq)
   (if (== (codex:exec-server-client-pending-event-seq
             (list:first $pending))
           $seq)
       True
       (codex:exec-server-client-pending-contains-seq
         (list:rest $pending)
         $seq)))

(= (codex:exec-server-client-pending-insert-if-absent
      $pending
      $seq
      $event)
   (if (codex:exec-server-client-pending-contains-seq $pending $seq)
       $pending
       (list:append
         $pending
         (list:cons
           (CodexExecServerClientPendingEvent $seq $event)
           ()))))

(= (codex:exec-server-client-pending-pop-missing $pending)
   (CodexExecServerClientPendingPopMissing $pending))

(= (codex:exec-server-client-pending-pop-found $event $pending)
   (CodexExecServerClientPendingPopFound $event $pending))

(= (codex:exec-server-client-pending-pop-result-event
      (CodexExecServerClientPendingPopFound $event $pending))
   $event)

(= (codex:exec-server-client-pending-pop-result-pending
      (CodexExecServerClientPendingPopMissing $pending))
   $pending)

(= (codex:exec-server-client-pending-pop-result-pending
      (CodexExecServerClientPendingPopFound $event $pending))
   $pending)

(= (codex:exec-server-client-pending-pop-seq () $seq)
   (CodexExecServerClientPendingPopMissing ()))

(= (codex:exec-server-client-pending-pop-seq $pending $seq)
   (let $head (list:first $pending)
     (let $tail (list:rest $pending)
       (if (== (codex:exec-server-client-pending-event-seq $head)
               $seq)
           (CodexExecServerClientPendingPopFound
             (codex:exec-server-client-pending-event-event $head)
             $tail)
           (case (codex:exec-server-client-pending-pop-seq
                   $tail
                   $seq)
             (((CodexExecServerClientPendingPopMissing $next-pending)
               (CodexExecServerClientPendingPopMissing
                 (list:cons $head $next-pending)))
              ((CodexExecServerClientPendingPopFound $event $next-pending)
               (CodexExecServerClientPendingPopFound
                 $event
                 (list:cons $head $next-pending)))))))))

(= (codex:exec-server-client-ordered-events
      $last-published-seq
      $pending)
   (CodexExecServerClientOrderedSessionEvents
     $last-published-seq
     $pending))

(= (codex:exec-server-client-ordered-events-default)
   (CodexExecServerClientOrderedSessionEvents 0 ()))

(= (codex:exec-server-client-ordered-events-last-published-seq
      (CodexExecServerClientOrderedSessionEvents
        $last-published-seq
        $pending))
   $last-published-seq)

(= (codex:exec-server-client-ordered-events-pending
      (CodexExecServerClientOrderedSessionEvents
        $last-published-seq
        $pending))
   $pending)

(= (codex:exec-server-client-drain-ready-result
      $last-published-seq
      $pending
      $ready)
   (CodexExecServerClientDrainReadyResult
     $last-published-seq
     $pending
     $ready))

(= (codex:exec-server-client-drain-ready-result-last-published-seq
      (CodexExecServerClientDrainReadyResult
        $last-published-seq
        $pending
        $ready))
   $last-published-seq)

(= (codex:exec-server-client-drain-ready-result-pending
      (CodexExecServerClientDrainReadyResult
        $last-published-seq
        $pending
        $ready))
   $pending)

(= (codex:exec-server-client-drain-ready-result-ready
      (CodexExecServerClientDrainReadyResult
        $last-published-seq
        $pending
        $ready))
   $ready)

(= (codex:exec-server-client-drain-ready
      $last-published-seq
      $pending
      $ready)
   (let $next-seq (+ $last-published-seq 1)
     (case (codex:exec-server-client-pending-pop-seq $pending $next-seq)
       (((CodexExecServerClientPendingPopMissing $next-pending)
         (CodexExecServerClientDrainReadyResult
           $last-published-seq
           $next-pending
           $ready))
        ((CodexExecServerClientPendingPopFound $event $next-pending)
         (codex:exec-server-client-drain-ready
           $next-seq
           $next-pending
           (list:append $ready (list:cons $event ()))))))))

(= (codex:exec-server-client-event-is-closed $event)
   (case $event
     (((CodexExecProcessEventClosed $seq) True)
      ($other False))))

(= (codex:exec-server-client-publish-ready-result
      $event-log
      $published-closed)
   (CodexExecServerClientPublishReadyResult
     $event-log
     $published-closed))

(= (codex:exec-server-client-publish-ready-result-event-log
      (CodexExecServerClientPublishReadyResult
        $event-log
        $published-closed))
   $event-log)

(= (codex:exec-server-client-publish-ready-result-published-closed
      (CodexExecServerClientPublishReadyResult
        $event-log
        $published-closed))
   $published-closed)

(= (codex:exec-server-client-publish-ready
      $event-log
      ()
      $published-closed)
   (CodexExecServerClientPublishReadyResult
     $event-log
     $published-closed))

(= (codex:exec-server-client-publish-ready
      $event-log
      $ready
      $published-closed)
   (let $event (list:first $ready)
     (codex:exec-server-client-publish-ready
       (codex:exec-process-event-log-publish $event-log $event)
       (list:rest $ready)
       (or $published-closed
           (codex:exec-server-client-event-is-closed $event)))))

(= (codex:exec-server-client-publish-ordered-result
      $ordered-events
      $event-log
      $published-closed)
   (CodexExecServerClientPublishOrderedResult
     $ordered-events
     $event-log
     $published-closed))

(= (codex:exec-server-client-publish-ordered-result-ordered-events
      (CodexExecServerClientPublishOrderedResult
        $ordered-events
        $event-log
        $published-closed))
   $ordered-events)

(= (codex:exec-server-client-publish-ordered-result-event-log
      (CodexExecServerClientPublishOrderedResult
        $ordered-events
        $event-log
        $published-closed))
   $event-log)

(= (codex:exec-server-client-publish-ordered-result-published-closed
      (CodexExecServerClientPublishOrderedResult
        $ordered-events
        $event-log
        $published-closed))
   $published-closed)

(= (codex:exec-server-client-publish-ordered
      (CodexExecServerClientOrderedSessionEvents $last-published-seq $pending)
      $event-log
      $event)
   (case (codex:exec-process-event-seq $event)
     ((CodexAbsent
       (CodexExecServerClientPublishOrderedResult
         (CodexExecServerClientOrderedSessionEvents
           $last-published-seq
           $pending)
         (codex:exec-process-event-log-publish $event-log $event)
         False))
      ($seq
       (if (<= $seq $last-published-seq)
           (CodexExecServerClientPublishOrderedResult
             (CodexExecServerClientOrderedSessionEvents
               $last-published-seq
               $pending)
             $event-log
             False)
           (let $drained
             (codex:exec-server-client-drain-ready
               $last-published-seq
               (codex:exec-server-client-pending-insert-if-absent
                 $pending
                 $seq
                 $event)
               ())
             (let $published
               (codex:exec-server-client-publish-ready
                 $event-log
                 (codex:exec-server-client-drain-ready-result-ready $drained)
                 False)
               (CodexExecServerClientPublishOrderedResult
                 (CodexExecServerClientOrderedSessionEvents
                   (codex:exec-server-client-drain-ready-result-last-published-seq
                     $drained)
                   (codex:exec-server-client-drain-ready-result-pending
                     $drained))
                 (codex:exec-server-client-publish-ready-result-event-log
                   $published)
                 (codex:exec-server-client-publish-ready-result-published-closed
                   $published)))))))))

(= (codex:exec-server-client-session-state
      $wake-seq
      $event-log
      $ordered-events
      $failure)
   (CodexExecServerClientSessionState
     $wake-seq
     $event-log
     $ordered-events
     $failure))

(= (codex:exec-server-client-session-state-new)
   (CodexExecServerClientSessionState
     0
     (codex:exec-process-event-log-new
       (codex:exec-server-client-process-event-channel-capacity)
       (codex:exec-server-client-process-event-retained-bytes))
     (codex:exec-server-client-ordered-events-default)
     CodexAbsent))

(= (codex:exec-server-client-session-state-wake-seq
      (CodexExecServerClientSessionState
        $wake-seq
        $event-log
        $ordered-events
        $failure))
   $wake-seq)

(= (codex:exec-server-client-session-state-event-log
      (CodexExecServerClientSessionState
        $wake-seq
        $event-log
        $ordered-events
        $failure))
   $event-log)

(= (codex:exec-server-client-session-state-ordered-events
      (CodexExecServerClientSessionState
        $wake-seq
        $event-log
        $ordered-events
        $failure))
   $ordered-events)

(= (codex:exec-server-client-session-state-failure
      (CodexExecServerClientSessionState
        $wake-seq
        $event-log
        $ordered-events
        $failure))
   $failure)

(= (codex:exec-server-client-session-state-with-wake-seq
      (CodexExecServerClientSessionState
        $wake-seq
        $event-log
        $ordered-events
        $failure)
      $new-wake-seq)
   (CodexExecServerClientSessionState
     $new-wake-seq
     $event-log
     $ordered-events
     $failure))

(= (codex:exec-server-client-session-note-change $state $seq)
   (codex:exec-server-client-session-state-with-wake-seq
     $state
     (codex:exec-server-client-max-u64
       (codex:exec-server-client-session-state-wake-seq $state)
       $seq)))

(= (codex:exec-server-client-session-publish-result
      $state
      $published-closed)
   (CodexExecServerClientSessionPublishResult
     $state
     $published-closed))

(= (codex:exec-server-client-session-publish-result-state
      (CodexExecServerClientSessionPublishResult
        $state
        $published-closed))
   $state)

(= (codex:exec-server-client-session-publish-result-published-closed
      (CodexExecServerClientSessionPublishResult
        $state
        $published-closed))
   $published-closed)

(= (codex:exec-server-client-session-publish-ordered-event
      (CodexExecServerClientSessionState
        $wake-seq
        $event-log
        $ordered-events
        $failure)
      $event)
   (let $published
     (codex:exec-server-client-publish-ordered
       $ordered-events
       $event-log
       $event)
     (CodexExecServerClientSessionPublishResult
       (CodexExecServerClientSessionState
         $wake-seq
         (codex:exec-server-client-publish-ordered-result-event-log
           $published)
         (codex:exec-server-client-publish-ordered-result-ordered-events
           $published)
         $failure)
       (codex:exec-server-client-publish-ordered-result-published-closed
         $published))))

(= (codex:exec-server-client-session-set-failure $state $message)
   (let $wake-seq
     (codex:exec-server-client-saturating-add-one-u64
       (codex:exec-server-client-session-state-wake-seq $state))
     (if (== (codex:exec-server-client-session-state-failure $state)
             CodexAbsent)
         (codex:exec-server-client-session-publish-result-state
           (codex:exec-server-client-session-publish-ordered-event
             (CodexExecServerClientSessionState
               $wake-seq
               (codex:exec-server-client-session-state-event-log $state)
               (codex:exec-server-client-session-state-ordered-events $state)
               $message)
             (codex:exec-process-event-failed $message)))
         (CodexExecServerClientSessionState
           $wake-seq
           (codex:exec-server-client-session-state-event-log $state)
           (codex:exec-server-client-session-state-ordered-events $state)
           (codex:exec-server-client-session-state-failure $state)))))

(= (codex:exec-server-client-session-synthesized-failure
      $state
      $message)
   (codex:exec-server-read-response
     ()
     (codex:exec-server-client-saturating-add-one-u64
       (codex:exec-server-client-session-state-wake-seq $state))
     True
     CodexAbsent
     True
     $message))

(= (codex:exec-server-client-session-failed-response $state)
   (if (== (codex:exec-server-client-session-state-failure $state)
           CodexAbsent)
       CodexAbsent
       (codex:exec-server-client-session-synthesized-failure
         $state
         (codex:exec-server-client-session-state-failure $state))))

(= (codex:exec-server-client-disconnected-message $reason)
   (if (== $reason CodexAbsent)
       "exec-server transport disconnected"
       (str-concat "exec-server transport disconnected: " $reason)))

(= (codex:exec-server-client-error-closed)
   (CodexExecServerClientErrorClosed))

(= (codex:exec-server-client-error-disconnected $message)
   (CodexExecServerClientErrorDisconnected $message))

(= (codex:exec-server-client-error-server $code $message)
   (CodexExecServerClientErrorServer $code $message))

(= (codex:exec-server-client-error-other $message)
   (CodexExecServerClientErrorOther $message))

(= (codex:exec-server-client-is-transport-closed-error $error)
   (case $error
     (((CodexExecServerClientErrorClosed) True)
      ((CodexExecServerClientErrorDisconnected $message) True)
      ((CodexExecServerClientErrorServer -32000 "JSON-RPC transport closed")
       True)
      ($other False))))

(= (codex:exec-server-client-record-disconnected-result
      $latch
      $message)
   (CodexExecServerClientRecordDisconnectedResult $latch $message))

(= (codex:exec-server-client-record-disconnected-result-latch
      (CodexExecServerClientRecordDisconnectedResult $latch $message))
   $latch)

(= (codex:exec-server-client-record-disconnected-result-message
      (CodexExecServerClientRecordDisconnectedResult $latch $message))
   $message)

(= (codex:exec-server-client-record-disconnected
      $existing
      $message)
   (if (== $existing CodexAbsent)
       (CodexExecServerClientRecordDisconnectedResult $message $message)
       (CodexExecServerClientRecordDisconnectedResult $existing $existing)))
