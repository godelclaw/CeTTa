; Rust-faithful exec-server session registry slice.
;
; This ports deterministic session attachment behavior from:
; - openai-codex/codex-rs/exec-server/src/server/session_registry.rs
;   - DETACHED_SESSION_TTL
;   - SessionRegistry::new / Default
;   - SessionRegistry::attach
;   - SessionRegistry::expire_if_detached
;   - SessionEntry::new / attach / detach / has_active_connection /
;     is_attached_to / is_expired / is_detached_connection_expired
;   - SessionHandle::session_id / connection_id / is_session_attached /
;     detach
; - openai-codex/codex-rs/exec-server/src/server/process_handler.rs
;   - ProcessHandler::new
;   - ProcessHandler::shutdown
;   - ProcessHandler::set_notification_sender
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust generates UUIDs and uses tokio::time::Instant. This pure slice accepts
;   generated session ids, generated connection ids, and integer millisecond
;   timestamps as explicit inputs at that runtime boundary.
; - Rust stores sessions in `HashMap<String, Arc<SessionEntry>>` and stores
;   attachment behind a mutex. This slice stores entries in a list and updates
;   immutable atoms. The visible algorithm only observes exact session-id
;   lookup/removal and exact connection-id checks; HashMap iteration order is
;   not part of the contract.
; - Rust holds a live `ProcessHandler`. This slice keeps the process handler's
;   visible notification-sender and shutdown state as data so attach/resume,
;   detach, and expiry can preserve the same side-effect ordering.

!(import! &self list)
!(import! &self exec_server_rpc)

(= (codex:exec-server-session-registry-detached-session-ttl-ms)
   10000)

(= (codex:exec-server-session-registry-test-detached-session-ttl-ms)
   200)

(= (codex:exec-server-session-process-handler $notification-sender $shutdown)
   (CodexExecServerSessionProcessHandler $notification-sender $shutdown))

(= (codex:exec-server-session-process-handler-new $notifications)
   (CodexExecServerSessionProcessHandler $notifications False))

(= (codex:exec-server-session-process-handler-notification-sender
      (CodexExecServerSessionProcessHandler $notification-sender $shutdown))
   $notification-sender)

(= (codex:exec-server-session-process-handler-shutdown
      (CodexExecServerSessionProcessHandler $notification-sender $shutdown))
   $shutdown)

(= (codex:exec-server-session-process-handler-set-notification-sender
      (CodexExecServerSessionProcessHandler $notification-sender $shutdown)
      $new-notification-sender)
   (CodexExecServerSessionProcessHandler
     $new-notification-sender
     $shutdown))

(= (codex:exec-server-session-process-handler-mark-shutdown
      (CodexExecServerSessionProcessHandler $notification-sender $shutdown))
   (CodexExecServerSessionProcessHandler $notification-sender True))

(= (codex:exec-server-session-attachment-state
      $current-connection-id
      $detached-connection-id
      $detached-expires-at-ms)
   (CodexExecServerSessionAttachmentState
     $current-connection-id
     $detached-connection-id
     $detached-expires-at-ms))

(= (codex:exec-server-session-attachment-state-new $connection-id)
   (CodexExecServerSessionAttachmentState
     $connection-id
     CodexAbsent
     CodexAbsent))

(= (codex:exec-server-session-attachment-current-connection-id
      (CodexExecServerSessionAttachmentState
        $current-connection-id
        $detached-connection-id
        $detached-expires-at-ms))
   $current-connection-id)

(= (codex:exec-server-session-attachment-detached-connection-id
      (CodexExecServerSessionAttachmentState
        $current-connection-id
        $detached-connection-id
        $detached-expires-at-ms))
   $detached-connection-id)

(= (codex:exec-server-session-attachment-detached-expires-at-ms
      (CodexExecServerSessionAttachmentState
        $current-connection-id
        $detached-connection-id
        $detached-expires-at-ms))
   $detached-expires-at-ms)

(= (codex:exec-server-session-attachment-attach
      $attachment
      $connection-id)
   (CodexExecServerSessionAttachmentState
     $connection-id
     CodexAbsent
     CodexAbsent))

(= (codex:exec-server-session-attachment-detach
      (CodexExecServerSessionAttachmentState
        $current-connection-id
        $detached-connection-id
        $detached-expires-at-ms)
      $connection-id
      $now-ms)
   (if (== $current-connection-id $connection-id)
       (CodexExecServerSessionAttachmentState
         CodexAbsent
         $connection-id
         (+
           $now-ms
           (codex:exec-server-session-registry-detached-session-ttl-ms)))
       (CodexExecServerSessionAttachmentState
         $current-connection-id
         $detached-connection-id
         $detached-expires-at-ms)))

(= (codex:exec-server-session-entry
      $session-id
      $process
      $attachment)
   (CodexExecServerSessionEntry $session-id $process $attachment))

(= (codex:exec-server-session-entry-new
      $session-id
      $notifications
      $connection-id)
   (CodexExecServerSessionEntry
     $session-id
     (codex:exec-server-session-process-handler-new $notifications)
     (codex:exec-server-session-attachment-state-new $connection-id)))

(= (codex:exec-server-session-entry-session-id
      (CodexExecServerSessionEntry $session-id $process $attachment))
   $session-id)

(= (codex:exec-server-session-entry-process
      (CodexExecServerSessionEntry $session-id $process $attachment))
   $process)

(= (codex:exec-server-session-entry-attachment
      (CodexExecServerSessionEntry $session-id $process $attachment))
   $attachment)

(= (codex:exec-server-session-entry-attach
      (CodexExecServerSessionEntry $session-id $process $attachment)
      $connection-id
      $notifications)
   (CodexExecServerSessionEntry
     $session-id
     (codex:exec-server-session-process-handler-set-notification-sender
       $process
       $notifications)
     (codex:exec-server-session-attachment-attach
       $attachment
       $connection-id)))

(= (codex:exec-server-session-entry-detach
      (CodexExecServerSessionEntry $session-id $process $attachment)
      $connection-id
      $now-ms)
   (let $next-attachment
     (codex:exec-server-session-attachment-detach
       $attachment
       $connection-id
       $now-ms)
     (if (== $next-attachment $attachment)
         (CodexExecServerSessionEntry $session-id $process $attachment)
         (CodexExecServerSessionEntry
           $session-id
           (codex:exec-server-session-process-handler-set-notification-sender
             $process
             CodexAbsent)
           $next-attachment))))

(= (codex:exec-server-session-entry-mark-shutdown
      (CodexExecServerSessionEntry $session-id $process $attachment))
   (CodexExecServerSessionEntry
     $session-id
     (codex:exec-server-session-process-handler-mark-shutdown $process)
     $attachment))

(= (codex:exec-server-session-entry-has-active-connection $entry)
   (not
     (==
       (codex:exec-server-session-attachment-current-connection-id
         (codex:exec-server-session-entry-attachment $entry))
       CodexAbsent)))

(= (codex:exec-server-session-entry-is-attached-to
      $entry
      $connection-id)
   (==
     (codex:exec-server-session-attachment-current-connection-id
       (codex:exec-server-session-entry-attachment $entry))
     $connection-id))

(= (codex:exec-server-session-entry-is-expired $entry $now-ms)
   (let $expires
     (codex:exec-server-session-attachment-detached-expires-at-ms
       (codex:exec-server-session-entry-attachment $entry))
     (if (== $expires CodexAbsent)
         False
         (>= $now-ms $expires))))

(= (codex:exec-server-session-entry-is-detached-connection-expired
      $entry
      $connection-id
      $now-ms)
   (let $attachment
     (codex:exec-server-session-entry-attachment $entry)
     (and
       (and
         (==
           (codex:exec-server-session-attachment-current-connection-id
             $attachment)
           CodexAbsent)
         (==
           (codex:exec-server-session-attachment-detached-connection-id
             $attachment)
           $connection-id))
       (let $expires
         (codex:exec-server-session-attachment-detached-expires-at-ms
           $attachment)
         (if (== $expires CodexAbsent)
             False
             (>= $now-ms $expires))))))

(= (codex:exec-server-session-handle $session-id $connection-id)
   (CodexExecServerSessionHandle $session-id $connection-id))

(= (codex:exec-server-session-handle-session-id
      (CodexExecServerSessionHandle $session-id $connection-id))
   $session-id)

(= (codex:exec-server-session-handle-connection-id
      (CodexExecServerSessionHandle $session-id $connection-id))
   $connection-id)

(= (codex:exec-server-session-registry $sessions)
   (CodexExecServerSessionRegistry $sessions))

(= (codex:exec-server-session-registry-new)
   (CodexExecServerSessionRegistry ()))

(= (codex:exec-server-session-registry-sessions
      (CodexExecServerSessionRegistry $sessions))
   $sessions)

(= (codex:exec-server-session-registry-session-count $registry)
   (list:len
     (codex:exec-server-session-registry-sessions $registry)))

(= (codex:exec-server-session-registry-lookup-missing $sessions)
   (CodexExecServerSessionRegistryLookupMissing $sessions))

(= (codex:exec-server-session-registry-lookup-found $entry $sessions)
   (CodexExecServerSessionRegistryLookupFound $entry $sessions))

(= (codex:exec-server-session-registry-lookup-result-entry
      (CodexExecServerSessionRegistryLookupFound $entry $sessions))
   $entry)

(= (codex:exec-server-session-registry-lookup-result-sessions
      (CodexExecServerSessionRegistryLookupMissing $sessions))
   $sessions)

(= (codex:exec-server-session-registry-lookup-result-sessions
      (CodexExecServerSessionRegistryLookupFound $entry $sessions))
   $sessions)

(= (codex:exec-server-session-registry-lookup-session
      ()
      $session-id)
   (CodexExecServerSessionRegistryLookupMissing ()))

(= (codex:exec-server-session-registry-lookup-session
      $sessions
      $session-id)
   (let $head (list:first $sessions)
     (let $tail (list:rest $sessions)
       (if (== (codex:exec-server-session-entry-session-id $head)
               $session-id)
           (CodexExecServerSessionRegistryLookupFound $head $tail)
           (case (codex:exec-server-session-registry-lookup-session
                   $tail
                   $session-id)
             (((CodexExecServerSessionRegistryLookupMissing $next-sessions)
               (CodexExecServerSessionRegistryLookupMissing
                 (list:cons $head $next-sessions)))
              ((CodexExecServerSessionRegistryLookupFound $entry $next-sessions)
               (CodexExecServerSessionRegistryLookupFound
                 $entry
                 (list:cons $head $next-sessions)))))))))

(= (codex:exec-server-session-registry-upsert
      $sessions
      $entry)
   (list:append
     $sessions
     (list:cons $entry ())))

(= (codex:exec-server-session-registry-attach-ok $registry $handle)
   (CodexExecServerSessionRegistryAttachOk $registry $handle))

(= (codex:exec-server-session-registry-attach-err $registry $error)
   (CodexExecServerSessionRegistryAttachErr $registry $error))

(= (codex:exec-server-session-registry-attach-result-registry
      (CodexExecServerSessionRegistryAttachOk $registry $handle))
   $registry)

(= (codex:exec-server-session-registry-attach-result-registry
      (CodexExecServerSessionRegistryAttachErr $registry $error))
   $registry)

(= (codex:exec-server-session-registry-attach-result-handle
      (CodexExecServerSessionRegistryAttachOk $registry $handle))
   $handle)

(= (codex:exec-server-session-registry-attach-result-error
      (CodexExecServerSessionRegistryAttachErr $registry $error))
   $error)

(= (codex:exec-server-session-registry-unknown-session-error
      $session-id)
   (codex:exec-server-rpc-invalid-request
     (format-args "unknown session id {}" ($session-id))))

(= (codex:exec-server-session-registry-already-attached-error
      $session-id)
   (codex:exec-server-rpc-invalid-request
     (format-args
       "session {} is already attached to another connection"
       ($session-id))))

(= (codex:exec-server-session-registry-attach-new
      $registry
      $notifications
      $generated-session-id
      $generated-connection-id)
   (let $entry
     (codex:exec-server-session-entry-new
       $generated-session-id
       $notifications
       $generated-connection-id)
     (CodexExecServerSessionRegistryAttachOk
       (CodexExecServerSessionRegistry
         (codex:exec-server-session-registry-upsert
           (codex:exec-server-session-registry-sessions $registry)
           $entry))
       (CodexExecServerSessionHandle
         $generated-session-id
         $generated-connection-id))))

(= (codex:exec-server-session-registry-attach-resume
      (CodexExecServerSessionRegistry $sessions)
      $session-id
      $notifications
      $generated-connection-id
      $now-ms)
   (case (codex:exec-server-session-registry-lookup-session
           $sessions
           $session-id)
     (((CodexExecServerSessionRegistryLookupMissing $same-sessions)
       (CodexExecServerSessionRegistryAttachErr
         (CodexExecServerSessionRegistry $same-sessions)
         (codex:exec-server-session-registry-unknown-session-error
           $session-id)))
      ((CodexExecServerSessionRegistryLookupFound $entry $remaining-sessions)
       (if (codex:exec-server-session-entry-is-expired $entry $now-ms)
           (CodexExecServerSessionRegistryAttachErr
             (CodexExecServerSessionRegistry $remaining-sessions)
             (codex:exec-server-session-registry-unknown-session-error
               $session-id))
           (if (codex:exec-server-session-entry-has-active-connection
                 $entry)
               (CodexExecServerSessionRegistryAttachErr
                 (CodexExecServerSessionRegistry
                   (codex:exec-server-session-registry-upsert
                     $remaining-sessions
                     $entry))
                 (codex:exec-server-session-registry-already-attached-error
                   $session-id))
               (let $attached-entry
                 (codex:exec-server-session-entry-attach
                   $entry
                   $generated-connection-id
                   $notifications)
                 (CodexExecServerSessionRegistryAttachOk
                   (CodexExecServerSessionRegistry
                     (codex:exec-server-session-registry-upsert
                       $remaining-sessions
                       $attached-entry))
                   (CodexExecServerSessionHandle
                     $session-id
                     $generated-connection-id)))))))))

(= (codex:exec-server-session-registry-attach
      $registry
      $resume-session-id
      $notifications
      $generated-session-id
      $generated-connection-id
      $now-ms)
   (if (== $resume-session-id CodexAbsent)
       (codex:exec-server-session-registry-attach-new
         $registry
         $notifications
         $generated-session-id
         $generated-connection-id)
       (codex:exec-server-session-registry-attach-resume
         $registry
         $resume-session-id
         $notifications
         $generated-connection-id
         $now-ms)))

(= (codex:exec-server-session-registry-detach-result
      $registry
      $detached)
   (CodexExecServerSessionRegistryDetachResult $registry $detached))

(= (codex:exec-server-session-registry-detach-result-registry
      (CodexExecServerSessionRegistryDetachResult $registry $detached))
   $registry)

(= (codex:exec-server-session-registry-detach-result-detached
      (CodexExecServerSessionRegistryDetachResult $registry $detached))
   $detached)

(= (codex:exec-server-session-registry-detach
      (CodexExecServerSessionRegistry $sessions)
      (CodexExecServerSessionHandle $session-id $connection-id)
      $now-ms)
   (case (codex:exec-server-session-registry-lookup-session
           $sessions
           $session-id)
     (((CodexExecServerSessionRegistryLookupMissing $same-sessions)
       (CodexExecServerSessionRegistryDetachResult
         (CodexExecServerSessionRegistry $same-sessions)
         False))
      ((CodexExecServerSessionRegistryLookupFound $entry $remaining-sessions)
       (if (codex:exec-server-session-entry-is-attached-to
             $entry
             $connection-id)
           (let $detached-entry
             (codex:exec-server-session-entry-detach
               $entry
               $connection-id
               $now-ms)
             (CodexExecServerSessionRegistryDetachResult
               (CodexExecServerSessionRegistry
                 (codex:exec-server-session-registry-upsert
                   $remaining-sessions
                   $detached-entry))
               True))
           (CodexExecServerSessionRegistryDetachResult
             (CodexExecServerSessionRegistry
               (codex:exec-server-session-registry-upsert
                 $remaining-sessions
                 $entry))
             False))))))

(= (codex:exec-server-session-registry-expire-result
      $registry
      $removed)
   (CodexExecServerSessionRegistryExpireResult $registry $removed))

(= (codex:exec-server-session-registry-expire-result-registry
      (CodexExecServerSessionRegistryExpireResult $registry $removed))
   $registry)

(= (codex:exec-server-session-registry-expire-result-removed
      (CodexExecServerSessionRegistryExpireResult $registry $removed))
   $removed)

(= (codex:exec-server-session-registry-expire-if-detached
      (CodexExecServerSessionRegistry $sessions)
      $session-id
      $connection-id
      $now-ms)
   (case (codex:exec-server-session-registry-lookup-session
           $sessions
           $session-id)
     (((CodexExecServerSessionRegistryLookupMissing $same-sessions)
       (CodexExecServerSessionRegistryExpireResult
         (CodexExecServerSessionRegistry $same-sessions)
         False))
      ((CodexExecServerSessionRegistryLookupFound $entry $remaining-sessions)
       (if (codex:exec-server-session-entry-is-detached-connection-expired
             $entry
             $connection-id
             $now-ms)
           (CodexExecServerSessionRegistryExpireResult
             (CodexExecServerSessionRegistry $remaining-sessions)
             True)
           (CodexExecServerSessionRegistryExpireResult
             (CodexExecServerSessionRegistry
               (codex:exec-server-session-registry-upsert
                 $remaining-sessions
                 $entry))
             False))))))

(= (codex:exec-server-session-registry-handle-is-session-attached
      (CodexExecServerSessionRegistry $sessions)
      (CodexExecServerSessionHandle $session-id $connection-id))
   (case (codex:exec-server-session-registry-lookup-session
           $sessions
           $session-id)
     (((CodexExecServerSessionRegistryLookupMissing $same-sessions)
       False)
      ((CodexExecServerSessionRegistryLookupFound $entry $remaining-sessions)
       (codex:exec-server-session-entry-is-attached-to
         $entry
         $connection-id)))))
