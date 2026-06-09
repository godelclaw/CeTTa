; Rust-faithful exec-server handler guard/state slice.
;
; This ports deterministic state and guard behavior from:
; - openai-codex/codex-rs/exec-server/src/server/handler.rs
;   - ExecServerHandler::new
;   - shutdown detach/cancel ordering as visible state
;   - is_session_attached
;   - initialize one-shot latch and attach failure reset
;   - initialized notification sequencing
;   - require_initialized_for / require_session_attached
;   - exec / exec_read / exec_write / terminate guard and result ordering
;   - reserve_http_body_stream / release_http_body_stream
;   - start_http_body_stream cancellation branch
;   - http_request reservation, runner/serialization/notification failure
;     release ordering, notification response shape, and body-stream startup
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust owns Arc, Mutex, AtomicBool, CancellationToken, TaskTracker, a live
;   SessionRegistry, and async process/filesystem/http handlers. This pure
;   slice represents the same visible guard state as immutable atoms. The
;   actual runtime bridges will provide the async operations later.
; - Rust `initialize` calls `SessionRegistry::attach`. This slice receives a
;   symbolic attach outcome and preserves the same latch transitions: duplicate
;   initialize fails, attach failure resets `initialize_requested`, and attach
;   success stores the returned session.
; - Rust tracks active HTTP body stream ids in a `HashSet<String>`. This slice
;   stores ids in a list and observes only exact membership/removal, matching
;   the visible duplicate-reservation behavior.
; - Rust `http_request` runs reqwest, serde_json serialization, and async
;   notification send. This slice accepts those runtime outcomes symbolically
;   and preserves the same state transitions and error/outbound values.
; - Rust process routes await the concrete Session process handler. This slice
;   accepts the process outcome symbolically. For `exec_read`, the post-read
;   state is explicit because Rust re-checks session attachment after the await;
;   that state is consulted only after a successful process read, matching the
;   Rust `?` short-circuit.

!(import! &self list)
!(import! &self str)
!(import! &self exec_server_rpc)
!(import! &self exec_server_process_protocol)
!(import! &self exec_server_http_protocol)

(= (codex:exec-server-handler-session-handle
      $session-id
      $connection-id
      $attached)
   (CodexExecServerHandlerSessionHandle
     $session-id
     $connection-id
     $attached))

(= (codex:exec-server-handler-session-handle-session-id
      (CodexExecServerHandlerSessionHandle
        $session-id
        $connection-id
        $attached))
   $session-id)

(= (codex:exec-server-handler-session-handle-connection-id
      (CodexExecServerHandlerSessionHandle
        $session-id
        $connection-id
        $attached))
   $connection-id)

(= (codex:exec-server-handler-session-handle-is-attached
      (CodexExecServerHandlerSessionHandle
        $session-id
        $connection-id
        $attached))
   $attached)

(= (codex:exec-server-handler-session-handle-detach
      (CodexExecServerHandlerSessionHandle
        $session-id
        $connection-id
        $attached))
   (CodexExecServerHandlerSessionHandle
     $session-id
     $connection-id
     False))

(= (codex:exec-server-handler-state
      $session
      $active-body-stream-ids
      $background-task-shutdown-cancelled
      $background-task-count
      $initialize-requested
      $initialized)
   (CodexExecServerHandlerState
     $session
     $active-body-stream-ids
     $background-task-shutdown-cancelled
     $background-task-count
     $initialize-requested
     $initialized))

(= (codex:exec-server-handler-state-new)
   (CodexExecServerHandlerState
     CodexAbsent
     ()
     False
     0
     False
     False))

(= (codex:exec-server-handler-state-session
      (CodexExecServerHandlerState
        $session
        $active-body-stream-ids
        $background-task-shutdown-cancelled
        $background-task-count
        $initialize-requested
        $initialized))
   $session)

(= (codex:exec-server-handler-state-active-body-stream-ids
      (CodexExecServerHandlerState
        $session
        $active-body-stream-ids
        $background-task-shutdown-cancelled
        $background-task-count
        $initialize-requested
        $initialized))
   $active-body-stream-ids)

(= (codex:exec-server-handler-state-background-task-shutdown-cancelled
      (CodexExecServerHandlerState
        $session
        $active-body-stream-ids
        $background-task-shutdown-cancelled
        $background-task-count
        $initialize-requested
        $initialized))
   $background-task-shutdown-cancelled)

(= (codex:exec-server-handler-state-background-task-count
      (CodexExecServerHandlerState
        $session
        $active-body-stream-ids
        $background-task-shutdown-cancelled
        $background-task-count
        $initialize-requested
        $initialized))
   $background-task-count)

(= (codex:exec-server-handler-state-initialize-requested
      (CodexExecServerHandlerState
        $session
        $active-body-stream-ids
        $background-task-shutdown-cancelled
        $background-task-count
        $initialize-requested
        $initialized))
   $initialize-requested)

(= (codex:exec-server-handler-state-initialized
      (CodexExecServerHandlerState
        $session
        $active-body-stream-ids
        $background-task-shutdown-cancelled
        $background-task-count
        $initialize-requested
        $initialized))
   $initialized)

(= (codex:exec-server-handler-state-with-session
      (CodexExecServerHandlerState
        $session
        $active-body-stream-ids
        $background-task-shutdown-cancelled
        $background-task-count
        $initialize-requested
        $initialized)
      $new-session)
   (CodexExecServerHandlerState
     $new-session
     $active-body-stream-ids
     $background-task-shutdown-cancelled
     $background-task-count
     $initialize-requested
     $initialized))

(= (codex:exec-server-handler-state-with-initialize-requested
      (CodexExecServerHandlerState
        $session
        $active-body-stream-ids
        $background-task-shutdown-cancelled
        $background-task-count
        $initialize-requested
        $initialized)
      $new-initialize-requested)
   (CodexExecServerHandlerState
     $session
     $active-body-stream-ids
     $background-task-shutdown-cancelled
     $background-task-count
     $new-initialize-requested
     $initialized))

(= (codex:exec-server-handler-state-with-initialized
      (CodexExecServerHandlerState
        $session
        $active-body-stream-ids
        $background-task-shutdown-cancelled
        $background-task-count
        $initialize-requested
        $initialized)
      $new-initialized)
   (CodexExecServerHandlerState
     $session
     $active-body-stream-ids
     $background-task-shutdown-cancelled
     $background-task-count
     $initialize-requested
     $new-initialized))

(= (codex:exec-server-handler-state-with-active-body-stream-ids
      (CodexExecServerHandlerState
        $session
        $active-body-stream-ids
        $background-task-shutdown-cancelled
        $background-task-count
        $initialize-requested
        $initialized)
      $new-active-body-stream-ids)
   (CodexExecServerHandlerState
     $session
     $new-active-body-stream-ids
     $background-task-shutdown-cancelled
     $background-task-count
     $initialize-requested
     $initialized))

(= (codex:exec-server-handler-state-with-background
      (CodexExecServerHandlerState
        $session
        $active-body-stream-ids
        $background-task-shutdown-cancelled
        $background-task-count
        $initialize-requested
        $initialized)
      $new-background-task-shutdown-cancelled
      $new-background-task-count)
   (CodexExecServerHandlerState
     $session
     $active-body-stream-ids
     $new-background-task-shutdown-cancelled
     $new-background-task-count
     $initialize-requested
     $initialized))

(= (codex:exec-server-handler-is-session-attached $state)
   (case (codex:exec-server-handler-state-session $state)
     ((CodexAbsent True)
      ((CodexExecServerHandlerSessionHandle
         $session-id
         $connection-id
         $attached)
       $attached))))

(= (codex:exec-server-handler-result-ok $state $value)
   (CodexExecServerHandlerResultOk $state $value))

(= (codex:exec-server-handler-result-err $state $error)
   (CodexExecServerHandlerResultErr $state $error))

(= (codex:exec-server-handler-result-state
      (CodexExecServerHandlerResultOk $state $value))
   $state)

(= (codex:exec-server-handler-result-state
      (CodexExecServerHandlerResultErr $state $error))
   $state)

(= (codex:exec-server-handler-result-value
      (CodexExecServerHandlerResultOk $state $value))
   $value)

(= (codex:exec-server-handler-result-error
      (CodexExecServerHandlerResultErr $state $error))
   $error)

(= (codex:exec-server-handler-string-result-ok $state)
   (CodexExecServerHandlerStringResultOk $state))

(= (codex:exec-server-handler-string-result-err $state $message)
   (CodexExecServerHandlerStringResultErr $state $message))

(= (codex:exec-server-handler-string-result-state
      (CodexExecServerHandlerStringResultOk $state))
   $state)

(= (codex:exec-server-handler-string-result-state
      (CodexExecServerHandlerStringResultErr $state $message))
   $state)

(= (codex:exec-server-handler-string-result-message
      (CodexExecServerHandlerStringResultErr $state $message))
   $message)

(= (codex:exec-server-handler-require-result-ok $session)
   (CodexExecServerHandlerRequireResultOk $session))

(= (codex:exec-server-handler-require-result-err $error)
   (CodexExecServerHandlerRequireResultErr $error))

(= (codex:exec-server-handler-require-result-session
      (CodexExecServerHandlerRequireResultOk $session))
   $session)

(= (codex:exec-server-handler-require-result-error
      (CodexExecServerHandlerRequireResultErr $error))
   $error)

(= (codex:exec-server-handler-require-session-attached $state)
   (case (codex:exec-server-handler-state-session $state)
     ((CodexAbsent
       (CodexExecServerHandlerRequireResultErr
         (codex:exec-server-rpc-invalid-request
           "client must call initialize before using methods")))
      ((CodexExecServerHandlerSessionHandle
         $session-id
         $connection-id
         True)
       (CodexExecServerHandlerRequireResultOk
         (CodexExecServerHandlerSessionHandle
           $session-id
           $connection-id
           True)))
      ((CodexExecServerHandlerSessionHandle
         $session-id
         $connection-id
         False)
       (CodexExecServerHandlerRequireResultErr
         (codex:exec-server-rpc-invalid-request
           "session has been resumed by another connection"))))))

(= (codex:exec-server-handler-require-initialized-for
      $state
      $method-family)
   (if (not
         (codex:exec-server-handler-state-initialize-requested
           $state))
       (CodexExecServerHandlerRequireResultErr
         (codex:exec-server-rpc-invalid-request
           (format-args
             "client must call initialize before using {} methods"
             ($method-family))))
       (case (codex:exec-server-handler-require-session-attached $state)
         (((CodexExecServerHandlerRequireResultErr $error)
           (CodexExecServerHandlerRequireResultErr $error))
          ((CodexExecServerHandlerRequireResultOk $session)
           (if (not (codex:exec-server-handler-state-initialized $state))
               (CodexExecServerHandlerRequireResultErr
                 (codex:exec-server-rpc-invalid-request
                   (format-args
                     "client must send initialized before using {} methods"
                     ($method-family))))
               (CodexExecServerHandlerRequireResultOk $session)))))))

(= (codex:exec-server-handler-attach-ok $session)
   (CodexExecServerHandlerAttachOk $session))

(= (codex:exec-server-handler-attach-err $error)
   (CodexExecServerHandlerAttachErr $error))

(= (codex:exec-server-handler-initialize $state $attach-outcome)
   (if (codex:exec-server-handler-state-initialize-requested $state)
       (CodexExecServerHandlerResultErr
         $state
         (codex:exec-server-rpc-invalid-request
           "initialize may only be sent once per connection"))
       (case $attach-outcome
         (((CodexExecServerHandlerAttachOk $session)
           (let $next-state
             (codex:exec-server-handler-state-with-session
               (codex:exec-server-handler-state-with-initialize-requested
                 $state
                 True)
               $session)
             (CodexExecServerHandlerResultOk
               $next-state
               (codex:exec-server-initialize-response
                 (codex:exec-server-handler-session-handle-session-id
                   $session)))))
          ((CodexExecServerHandlerAttachErr $error)
           (CodexExecServerHandlerResultErr
             (codex:exec-server-handler-state-with-initialize-requested
               $state
               False)
             $error))))))

(= (codex:exec-server-handler-initialized $state)
   (if (not
         (codex:exec-server-handler-state-initialize-requested
           $state))
       (CodexExecServerHandlerStringResultErr
         $state
         "received `initialized` notification before `initialize`")
       (case (codex:exec-server-handler-require-session-attached $state)
         (((CodexExecServerHandlerRequireResultErr $error)
           (CodexExecServerHandlerStringResultErr
             $state
             (codex:exec-server-rpc-error-error-message $error)))
          ((CodexExecServerHandlerRequireResultOk $session)
           (CodexExecServerHandlerStringResultOk
             (codex:exec-server-handler-state-with-initialized
               $state
               True)))))))

(= (codex:exec-server-handler-exec-check $state)
   (codex:exec-server-handler-require-initialized-for $state "exec"))

(= (codex:exec-server-handler-fs-check $state)
   (codex:exec-server-handler-require-initialized-for
     $state
     "filesystem"))

(= (codex:exec-server-handler-http-check $state)
   (codex:exec-server-handler-require-initialized-for $state "http"))

(= (codex:exec-server-handler-process-ok $response)
   (CodexExecServerHandlerProcessOk $response))

(= (codex:exec-server-handler-process-err $error)
   (CodexExecServerHandlerProcessErr $error))

(= (codex:exec-server-handler-process-flow-after-check
      $state
      (CodexExecServerHandlerRequireResultErr $error)
      $process-outcome)
   (CodexExecServerHandlerResultErr $state $error))

(= (codex:exec-server-handler-process-flow-after-check
      $state
      (CodexExecServerHandlerRequireResultOk $session)
      (CodexExecServerHandlerProcessErr $error))
   (CodexExecServerHandlerResultErr $state $error))

(= (codex:exec-server-handler-process-flow-after-check
      $state
      (CodexExecServerHandlerRequireResultOk $session)
      (CodexExecServerHandlerProcessOk $response))
   (CodexExecServerHandlerResultOk $state $response))

(= (codex:exec-server-handler-exec-flow $state $process-outcome)
   (codex:exec-server-handler-process-flow-after-check
     $state
     (codex:exec-server-handler-exec-check $state)
     $process-outcome))

(= (codex:exec-server-handler-exec-write-flow $state $process-outcome)
   (codex:exec-server-handler-process-flow-after-check
     $state
     (codex:exec-server-handler-exec-check $state)
     $process-outcome))

(= (codex:exec-server-handler-terminate-flow $state $process-outcome)
   (codex:exec-server-handler-process-flow-after-check
     $state
     (codex:exec-server-handler-exec-check $state)
     $process-outcome))

(= (codex:exec-server-handler-exec-read-flow-after-check
      $state
      (CodexExecServerHandlerRequireResultErr $error)
      $process-outcome
      $post-read-state)
   (CodexExecServerHandlerResultErr $state $error))

(= (codex:exec-server-handler-exec-read-flow-after-check
      $state
      (CodexExecServerHandlerRequireResultOk $session)
      (CodexExecServerHandlerProcessErr $error)
      $post-read-state)
   (CodexExecServerHandlerResultErr $state $error))

(= (codex:exec-server-handler-exec-read-flow-after-check
      $state
      (CodexExecServerHandlerRequireResultOk $session)
      (CodexExecServerHandlerProcessOk $response)
      $post-read-state)
   (case (codex:exec-server-handler-require-session-attached
           $post-read-state)
     (((CodexExecServerHandlerRequireResultErr $error)
       (CodexExecServerHandlerResultErr $post-read-state $error))
      ((CodexExecServerHandlerRequireResultOk $post-read-session)
       (CodexExecServerHandlerResultOk $post-read-state $response)))))

(= (codex:exec-server-handler-exec-read-flow
      $state
      $process-outcome
      $post-read-state)
   (codex:exec-server-handler-exec-read-flow-after-check
     $state
     (codex:exec-server-handler-exec-check $state)
     $process-outcome
     $post-read-state))

(= (codex:exec-server-handler-body-stream-id-contains
      ()
      $request-id)
   False)

(= (codex:exec-server-handler-body-stream-id-contains
      $request-ids
      $request-id)
   (if (== (list:first $request-ids) $request-id)
       True
       (codex:exec-server-handler-body-stream-id-contains
         (list:rest $request-ids)
         $request-id)))

(= (codex:exec-server-handler-body-stream-id-remove
      ()
      $request-id)
   ())

(= (codex:exec-server-handler-body-stream-id-remove
      $request-ids
      $request-id)
   (let $head (list:first $request-ids)
     (let $tail (list:rest $request-ids)
       (if (== $head $request-id)
           $tail
           (list:cons
             $head
             (codex:exec-server-handler-body-stream-id-remove
               $tail
               $request-id))))))

(= (codex:exec-server-handler-reserve-http-body-stream
      $state
      $request-id)
   (if (codex:exec-server-handler-body-stream-id-contains
         (codex:exec-server-handler-state-active-body-stream-ids
           $state)
         $request-id)
       (CodexExecServerHandlerResultErr
         $state
         (codex:exec-server-rpc-invalid-params
           (format-args
             "http/request streamResponse requestId `{}` is already active"
             ($request-id))))
       (CodexExecServerHandlerResultOk
         (codex:exec-server-handler-state-with-active-body-stream-ids
           $state
           (list:append
             (codex:exec-server-handler-state-active-body-stream-ids
               $state)
             (list:cons $request-id ())))
         ())))

(= (codex:exec-server-handler-release-http-body-stream
      $state
      $request-id)
   (codex:exec-server-handler-state-with-active-body-stream-ids
     $state
     (codex:exec-server-handler-body-stream-id-remove
       (codex:exec-server-handler-state-active-body-stream-ids $state)
       $request-id)))

(= (codex:exec-server-handler-http-request-reserve
      $state
      $params)
   (case (codex:exec-server-handler-http-check $state)
     (((CodexExecServerHandlerRequireResultErr $error)
       (CodexExecServerHandlerResultErr $state $error))
      ((CodexExecServerHandlerRequireResultOk $session)
       (if (codex:exec-server-http-request-params-stream-response
             $params)
           (codex:exec-server-handler-reserve-http-body-stream
             $state
             (codex:exec-server-http-request-params-request-id $params))
           (CodexExecServerHandlerResultOk $state ()))))))

(= (codex:exec-server-handler-pending-http-body-stream $request-id)
   (CodexExecServerHandlerPendingHttpBodyStream $request-id))

(= (codex:exec-server-handler-pending-http-body-stream-request-id
      (CodexExecServerHandlerPendingHttpBodyStream $request-id))
   $request-id)

(= (codex:exec-server-handler-body-stream-started)
   (CodexExecServerHandlerBodyStreamStarted))

(= (codex:exec-server-handler-body-stream-released)
   (CodexExecServerHandlerBodyStreamReleased))

(= (codex:exec-server-handler-start-http-body-stream
      $state
      $pending-stream)
   (let $request-id
     (codex:exec-server-handler-pending-http-body-stream-request-id
       $pending-stream)
     (if (codex:exec-server-handler-state-background-task-shutdown-cancelled
           $state)
         (CodexExecServerHandlerResultOk
           (codex:exec-server-handler-release-http-body-stream
             $state
             $request-id)
           (CodexExecServerHandlerBodyStreamReleased))
         (CodexExecServerHandlerResultOk
           (codex:exec-server-handler-state-with-background
             $state
             False
             (+
               (codex:exec-server-handler-state-background-task-count
                 $state)
               1))
         (CodexExecServerHandlerBodyStreamStarted)))))

(= (codex:exec-server-handler-http-runner-ok
      $response
      $pending-stream)
   (CodexExecServerHandlerHttpRunnerOk $response $pending-stream))

(= (codex:exec-server-handler-http-runner-err $error)
   (CodexExecServerHandlerHttpRunnerErr $error))

(= (codex:exec-server-handler-http-serialize-ok)
   (CodexExecServerHandlerHttpSerializeOk))

(= (codex:exec-server-handler-http-serialize-err $message)
   (CodexExecServerHandlerHttpSerializeErr $message))

(= (codex:exec-server-handler-http-notify-ok)
   (CodexExecServerHandlerHttpNotifyOk))

(= (codex:exec-server-handler-http-notify-err $error)
   (CodexExecServerHandlerHttpNotifyErr $error))

(= (codex:exec-server-handler-http-request-completed
      $outbound-response
      $body-stream-action)
   (CodexExecServerHandlerHttpRequestCompleted
     $outbound-response
     $body-stream-action))

(= (codex:exec-server-handler-http-request-completed-outbound-response
      (CodexExecServerHandlerHttpRequestCompleted
        $outbound-response
        $body-stream-action))
   $outbound-response)

(= (codex:exec-server-handler-http-request-completed-body-stream-action
      (CodexExecServerHandlerHttpRequestCompleted
        $outbound-response
        $body-stream-action))
   $body-stream-action)

(= (codex:exec-server-handler-release-pending-http-body-stream
      $state
      CodexAbsent)
   $state)

(= (codex:exec-server-handler-release-pending-http-body-stream
      $state
      (CodexExecServerHandlerPendingHttpBodyStream $request-id))
   (codex:exec-server-handler-release-http-body-stream
     $state
     $request-id))

(= (codex:exec-server-handler-release-request-http-body-stream-if-needed
      $state
      $params)
   (if (codex:exec-server-http-request-params-stream-response $params)
       (codex:exec-server-handler-release-http-body-stream
         $state
         (codex:exec-server-http-request-params-request-id $params))
       $state))

(= (codex:exec-server-handler-http-request-flow-after-runner-ok
      $state
      $request-id
      $response
      $pending-stream
      (CodexExecServerHandlerHttpSerializeErr $message)
      $notify-outcome)
   (CodexExecServerHandlerResultErr
     (codex:exec-server-handler-release-pending-http-body-stream
       $state
       $pending-stream)
     (codex:exec-server-rpc-internal-error $message)))

(= (codex:exec-server-handler-http-request-flow-after-runner-ok
      $state
      $request-id
      $response
      $pending-stream
      (CodexExecServerHandlerHttpSerializeOk)
      (CodexExecServerHandlerHttpNotifyErr $error))
   (CodexExecServerHandlerResultErr
     (codex:exec-server-handler-release-pending-http-body-stream
       $state
       $pending-stream)
     $error))

(= (codex:exec-server-handler-http-request-flow-after-runner-ok
      $state
      $request-id
      $response
      CodexAbsent
      (CodexExecServerHandlerHttpSerializeOk)
      (CodexExecServerHandlerHttpNotifyOk))
   (CodexExecServerHandlerResultOk
     $state
     (CodexExecServerHandlerHttpRequestCompleted
       (codex:exec-server-rpc-server-outbound-response
         $request-id
         (codex:exec-server-http-request-response-json $response))
       CodexAbsent)))

(= (codex:exec-server-handler-http-request-flow-after-runner-ok
      $state
      $request-id
      $response
      (CodexExecServerHandlerPendingHttpBodyStream $pending-request-id)
      (CodexExecServerHandlerHttpSerializeOk)
      (CodexExecServerHandlerHttpNotifyOk))
   (let $started
     (codex:exec-server-handler-start-http-body-stream
       $state
       (CodexExecServerHandlerPendingHttpBodyStream $pending-request-id))
     (CodexExecServerHandlerResultOk
       (codex:exec-server-handler-result-state $started)
       (CodexExecServerHandlerHttpRequestCompleted
         (codex:exec-server-rpc-server-outbound-response
           $request-id
           (codex:exec-server-http-request-response-json $response))
         (codex:exec-server-handler-result-value $started)))))

(= (codex:exec-server-handler-http-request-flow
      $state
      $request-id
      $params
      $runner-outcome
      $serialize-outcome
      $notify-outcome)
   (case (codex:exec-server-handler-http-request-reserve $state $params)
     (((CodexExecServerHandlerResultErr $reserve-state $error)
       (CodexExecServerHandlerResultErr $reserve-state $error))
      ((CodexExecServerHandlerResultOk $reserved-state $value)
       (case $runner-outcome
         (((CodexExecServerHandlerHttpRunnerErr $error)
           (CodexExecServerHandlerResultErr
             (codex:exec-server-handler-release-request-http-body-stream-if-needed
               $reserved-state
               $params)
             $error))
          ((CodexExecServerHandlerHttpRunnerOk $response $pending-stream)
           (codex:exec-server-handler-http-request-flow-after-runner-ok
             $reserved-state
             $request-id
             $response
             $pending-stream
             $serialize-outcome
             $notify-outcome))))))))

(= (codex:exec-server-handler-shutdown $state)
   (let $session (codex:exec-server-handler-state-session $state)
     (codex:exec-server-handler-state-with-session
       (codex:exec-server-handler-state-with-background
         $state
         True
         0)
       (case $session
         ((CodexAbsent CodexAbsent)
          ((CodexExecServerHandlerSessionHandle
             $session-id
             $connection-id
             $attached)
           (CodexExecServerHandlerSessionHandle
             $session-id
             $connection-id
             False)))))))
