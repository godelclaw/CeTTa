; Rust-faithful exec-server connection processor slice.
;
; This ports deterministic event-loop behavior from:
; - openai-codex/codex-rs/exec-server/src/server/processor.rs
;   - ConnectionProcessor::new shape
;   - run_connection setup decisions
;   - outbound task encode/send policy
;   - sequential inbound event processing
;   - malformed-message error response
;   - request route lookup / method_not_found response
;   - notification route lookup / protocol-error close behavior
;   - unexpected client response/error close behavior
;   - disconnected close behavior
;   - final handler shutdown and task cleanup
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust owns Tokio tasks, channels, Arc handlers, and async route futures. This
;   pure slice takes route outcomes and send outcomes as symbolic inputs and
;   preserves the same branch decisions, outbound messages, and shutdown state.
;   The `known-routes` helpers below execute the deterministic initialize,
;   initialized, and exec/filesystem/http precondition guards directly after
;   the typed-params decode boundary. The process route-flow helpers accept
;   symbolic async process outcomes, then preserve the Rust router/processor
;   response projection and send ordering. The filesystem route-flow helpers
;   accept symbolic async filesystem outcomes and preserve the same
;   router/processor response projection and send ordering. The HTTP
;   route-flow helper accepts symbolic request-runner/serialization/notify
;   outcomes and preserves `request_with_id` behavior: success returns no
;   processor outbound message because the handler has already sent the
;   response through its notification sink; failure is converted into a
;   processor-sent JSON-RPC error.
; - Rust logs warnings/debug messages and then breaks. This slice exposes those
;   branch reasons as data so tests can pin them; they are not public protocol
;   output.
; - Rust `encode_server_message` returns `Result<JSONRPCMessage, serde_json::Error>`.
;   The pure RPC encoder is total for represented values, so a symbolic
;   encode-error outcome is provided for the same outbound-task branch.

!(import! &self list)
!(import! &self str)
!(import! &self exec_server_rpc)
!(import! &self exec_server_connection)
!(import! &self exec_server_handler)
!(import! &self exec_server_registry)
!(import! &self exec_server_session_registry)
!(import! &self exec_server_process_protocol)
!(import! &self exec_server_file_system_protocol)

(= (codex:exec-server-processor-runtime-state
      $handler-state
      $connection-task-count
      $outbound-task-running)
   (CodexExecServerProcessorRuntimeState
     $handler-state
     $connection-task-count
     $outbound-task-running))

(= (codex:exec-server-processor-runtime-state-new)
   (CodexExecServerProcessorRuntimeState
     (codex:exec-server-handler-state-new)
     2
     True))

(= (codex:exec-server-processor-runtime-state-handler-state
      (CodexExecServerProcessorRuntimeState
        $handler-state
        $connection-task-count
        $outbound-task-running))
   $handler-state)

(= (codex:exec-server-processor-runtime-state-connection-task-count
      (CodexExecServerProcessorRuntimeState
        $handler-state
        $connection-task-count
        $outbound-task-running))
   $connection-task-count)

(= (codex:exec-server-processor-runtime-state-outbound-task-running
      (CodexExecServerProcessorRuntimeState
        $handler-state
        $connection-task-count
        $outbound-task-running))
   $outbound-task-running)

(= (codex:exec-server-processor-runtime-state-with-handler
      (CodexExecServerProcessorRuntimeState
        $handler-state
        $connection-task-count
        $outbound-task-running)
      $new-handler-state)
   (CodexExecServerProcessorRuntimeState
     $new-handler-state
     $connection-task-count
     $outbound-task-running))

(= (codex:exec-server-processor-runtime-state-finish
      (CodexExecServerProcessorRuntimeState
        $handler-state
        $connection-task-count
        $outbound-task-running))
   (CodexExecServerProcessorRuntimeState
     (codex:exec-server-handler-shutdown $handler-state)
     0
     False))

(= (codex:exec-server-processor-connection-processor
      $session-registry
      $runtime-paths)
   (CodexExecServerConnectionProcessor $session-registry $runtime-paths))

(= (codex:exec-server-processor-connection-processor-session-registry
      (CodexExecServerConnectionProcessor $session-registry $runtime-paths))
   $session-registry)

(= (codex:exec-server-processor-connection-processor-runtime-paths
      (CodexExecServerConnectionProcessor $session-registry $runtime-paths))
   $runtime-paths)

(= (codex:exec-server-processor-connection-processor-new $runtime-paths)
   (CodexExecServerConnectionProcessor
     (codex:exec-server-session-registry-new)
     $runtime-paths))

(= (codex:exec-server-processor-run-connection-plan
      $connection-parts
      $runtime-paths)
   (let $materialized-connection-parts
     (once (eval $connection-parts))
     (CodexExecServerProcessorRunConnectionPlan
       (codex:exec-server-registry-build-router)
       (codex:exec-server-connection-channel-capacity)
       (codex:exec-server-processor-runtime-state-new)
       $materialized-connection-parts
       $runtime-paths)))

(= (codex:exec-server-processor-run-connection-plan-router
      (CodexExecServerProcessorRunConnectionPlan
        $router
        $channel-capacity
        $runtime-state
        $connection-parts
        $runtime-paths))
   $router)

(= (codex:exec-server-processor-run-connection-plan-router
      (codex:exec-server-processor-run-connection-plan
        $connection-parts
        $runtime-paths))
   (codex:exec-server-registry-build-router))

(= (codex:exec-server-processor-run-connection-plan-channel-capacity
      (CodexExecServerProcessorRunConnectionPlan
        $router
        $channel-capacity
        $runtime-state
        $connection-parts
        $runtime-paths))
   $channel-capacity)

(= (codex:exec-server-processor-run-connection-plan-channel-capacity
      (codex:exec-server-processor-run-connection-plan
        $connection-parts
        $runtime-paths))
   (codex:exec-server-connection-channel-capacity))

(= (codex:exec-server-processor-run-connection-plan-runtime-state
      (CodexExecServerProcessorRunConnectionPlan
        $router
        $channel-capacity
        $runtime-state
        $connection-parts
        $runtime-paths))
   $runtime-state)

(= (codex:exec-server-processor-run-connection-plan-runtime-state
      (codex:exec-server-processor-run-connection-plan
        $connection-parts
        $runtime-paths))
   (codex:exec-server-processor-runtime-state-new))

(= (codex:exec-server-processor-run-connection-plan-connection-parts
      (CodexExecServerProcessorRunConnectionPlan
        $router
        $channel-capacity
        $runtime-state
        $connection-parts
        $runtime-paths))
   $connection-parts)

(= (codex:exec-server-processor-run-connection-plan-connection-parts
      (codex:exec-server-processor-run-connection-plan
        $connection-parts
        $runtime-paths))
   $connection-parts)

(= (codex:exec-server-processor-run-connection-plan-runtime-paths
      (CodexExecServerProcessorRunConnectionPlan
        $router
        $channel-capacity
        $runtime-state
        $connection-parts
        $runtime-paths))
   $runtime-paths)

(= (codex:exec-server-processor-run-connection-plan-runtime-paths
      (codex:exec-server-processor-run-connection-plan
        $connection-parts
        $runtime-paths))
   $runtime-paths)

(= (codex:exec-server-processor-send-outcome-ok)
   (CodexExecServerProcessorSendOutcomeOk))

(= (codex:exec-server-processor-send-outcome-closed)
   (CodexExecServerProcessorSendOutcomeClosed))

(= (codex:exec-server-processor-request-route-outcome-none)
   (CodexExecServerProcessorRequestRouteOutcomeNone))

(= (codex:exec-server-processor-request-route-outcome-some $outbound)
   (CodexExecServerProcessorRequestRouteOutcomeSome $outbound))

(= (codex:exec-server-processor-request-route-outcome-disconnected)
   (CodexExecServerProcessorRequestRouteOutcomeDisconnected))

(= (codex:exec-server-processor-notification-route-outcome-ok)
   (CodexExecServerProcessorNotificationRouteOutcomeOk))

(= (codex:exec-server-processor-notification-route-outcome-err $message)
   (CodexExecServerProcessorNotificationRouteOutcomeErr $message))

(= (codex:exec-server-processor-notification-route-outcome-disconnected)
   (CodexExecServerProcessorNotificationRouteOutcomeDisconnected))

(= (codex:exec-server-processor-step-continue $state $outbound)
   (CodexExecServerProcessorStepContinue $state $outbound))

(= (codex:exec-server-processor-step-break $state $reason $outbound)
   (CodexExecServerProcessorStepBreak $state $reason $outbound))

(= (codex:exec-server-processor-step-result-state
      (CodexExecServerProcessorStepContinue $state $outbound))
   $state)

(= (codex:exec-server-processor-step-result-state
      (CodexExecServerProcessorStepBreak $state $reason $outbound))
   $state)

(= (codex:exec-server-processor-step-result-outbound
      (CodexExecServerProcessorStepContinue $state $outbound))
   $outbound)

(= (codex:exec-server-processor-step-result-outbound
      (CodexExecServerProcessorStepBreak $state $reason $outbound))
   $outbound)

(= (codex:exec-server-processor-step-result-reason
      (CodexExecServerProcessorStepBreak $state $reason $outbound))
   $reason)

(= (codex:exec-server-processor-finish-break
      $state
      $reason
      $outbound)
   (CodexExecServerProcessorStepBreak
     (codex:exec-server-processor-runtime-state-finish $state)
     $reason
     $outbound))

(= (codex:exec-server-processor-outgoing-send
      $state
      $outbound-message
      (CodexExecServerProcessorSendOutcomeOk))
   (CodexExecServerProcessorStepContinue
     $state
     (list:cons $outbound-message ())))

(= (codex:exec-server-processor-outgoing-send
      $state
      $outbound-message
      (CodexExecServerProcessorSendOutcomeClosed))
   (codex:exec-server-processor-finish-break
     $state
     (CodexExecServerProcessorBreakOutgoingClosed)
     ()))

(= (codex:exec-server-processor-handle-request
      $state
      $router
      (CodexExecServerRpcRequest $id $method $params $trace)
      $route-outcome
      $send-outcome)
   (let $route
     (collapse
       (codex:exec-server-rpc-router-request-route $router $method))
     (case $route
       ((()
         (codex:exec-server-processor-outgoing-send
           $state
           (codex:exec-server-rpc-server-outbound-error
             $id
             (codex:exec-server-rpc-method-not-found
               (format-args
                 "exec-server stub does not implement `{}` yet"
                 ($method))))
           $send-outcome))
        ((CodexAbsent)
         (codex:exec-server-processor-outgoing-send
           $state
           (codex:exec-server-rpc-server-outbound-error
             $id
             (codex:exec-server-rpc-method-not-found
               (format-args
                 "exec-server stub does not implement `{}` yet"
                 ($method))))
           $send-outcome))
        (($found-route)
         (case $route-outcome
           (((CodexExecServerProcessorRequestRouteOutcomeDisconnected)
             (codex:exec-server-processor-finish-break
               $state
               (CodexExecServerProcessorBreakRequestDisconnected)
               ()))
            ((CodexExecServerProcessorRequestRouteOutcomeNone)
             (CodexExecServerProcessorStepContinue $state ()))
            ((CodexExecServerProcessorRequestRouteOutcomeSome $outbound)
             (codex:exec-server-processor-outgoing-send
               $state
               $outbound
               $send-outcome)))))))))

(= (codex:exec-server-processor-handle-initialize-route
      $state
      (CodexExecServerRpcRequest $id $method $params $trace)
      $attach-outcome
      $send-outcome)
   (case (codex:exec-server-handler-initialize
           (codex:exec-server-processor-runtime-state-handler-state
             $state)
           $attach-outcome)
     (((CodexExecServerHandlerResultOk $handler-state $response)
       (codex:exec-server-processor-outgoing-send
         (codex:exec-server-processor-runtime-state-with-handler
           $state
           $handler-state)
         (codex:exec-server-rpc-server-outbound-response
           $id
           (codex:exec-server-initialize-response-json $response))
         $send-outcome))
      ((CodexExecServerHandlerResultErr $handler-state $error)
       (codex:exec-server-processor-outgoing-send
         (codex:exec-server-processor-runtime-state-with-handler
           $state
           $handler-state)
         (codex:exec-server-rpc-server-outbound-error
           $id
           $error)
         $send-outcome)))))

(= (codex:exec-server-processor-is-exec-request-method $method)
   (if (== $method (codex:exec-server-protocol-exec-method))
       True
       (if (== $method (codex:exec-server-protocol-exec-read-method))
           True
           (if (== $method (codex:exec-server-protocol-exec-write-method))
               True
               (== $method
                   (codex:exec-server-protocol-exec-terminate-method))))))

(= (codex:exec-server-processor-is-filesystem-request-method $method)
   (if (== $method (codex:exec-server-protocol-fs-read-file-method))
       True
       (if (== $method (codex:exec-server-protocol-fs-write-file-method))
           True
           (if (== $method (codex:exec-server-protocol-fs-create-directory-method))
               True
               (if (== $method (codex:exec-server-protocol-fs-get-metadata-method))
                   True
                   (if (== $method (codex:exec-server-protocol-fs-read-directory-method))
                       True
                       (if (== $method (codex:exec-server-protocol-fs-remove-method))
                           True
                           (== $method
                               (codex:exec-server-protocol-fs-copy-method)))))))))

(= (codex:exec-server-processor-is-http-request-method $method)
   (== $method (codex:exec-server-protocol-http-request-method)))

(= (codex:exec-server-processor-request-guard-ok $state)
   (CodexExecServerProcessorRequestGuardOk $state))

(= (codex:exec-server-processor-request-guard-err $state $error)
   (CodexExecServerProcessorRequestGuardErr $state $error))

(= (codex:exec-server-processor-request-guard
      $state
      $method)
   (if (codex:exec-server-processor-is-exec-request-method $method)
       (case (codex:exec-server-handler-exec-check
               (codex:exec-server-processor-runtime-state-handler-state
                 $state))
         (((CodexExecServerHandlerRequireResultOk $session)
           (CodexExecServerProcessorRequestGuardOk $state))
          ((CodexExecServerHandlerRequireResultErr $error)
           (CodexExecServerProcessorRequestGuardErr $state $error))))
       (if (codex:exec-server-processor-is-filesystem-request-method $method)
           (case (codex:exec-server-handler-fs-check
                   (codex:exec-server-processor-runtime-state-handler-state
                     $state))
             (((CodexExecServerHandlerRequireResultOk $session)
               (CodexExecServerProcessorRequestGuardOk $state))
              ((CodexExecServerHandlerRequireResultErr $error)
               (CodexExecServerProcessorRequestGuardErr $state $error))))
           (if (codex:exec-server-processor-is-http-request-method $method)
               (case (codex:exec-server-handler-http-check
                       (codex:exec-server-processor-runtime-state-handler-state
                         $state))
                 (((CodexExecServerHandlerRequireResultOk $session)
                   (CodexExecServerProcessorRequestGuardOk $state))
                  ((CodexExecServerHandlerRequireResultErr $error)
                   (CodexExecServerProcessorRequestGuardErr $state $error))))
               (CodexExecServerProcessorRequestGuardOk $state)))))

(= (codex:exec-server-processor-route-outcome-after-guard
      $state
      $route-outcome
      $send-outcome)
   (case $route-outcome
     (((CodexExecServerProcessorRequestRouteOutcomeDisconnected)
       (codex:exec-server-processor-finish-break
         $state
         (CodexExecServerProcessorBreakRequestDisconnected)
         ()))
      ((CodexExecServerProcessorRequestRouteOutcomeNone)
       (CodexExecServerProcessorStepContinue $state ()))
      ((CodexExecServerProcessorRequestRouteOutcomeSome $outbound)
       (codex:exec-server-processor-outgoing-send
         $state
         $outbound
         $send-outcome)))))

(= (codex:exec-server-processor-handler-route-error
      $state
      $request-id
      $handler-state
      $error
      $send-outcome)
   (codex:exec-server-processor-outgoing-send
     (codex:exec-server-processor-runtime-state-with-handler
       $state
       $handler-state)
     (codex:exec-server-rpc-server-outbound-error $request-id $error)
     $send-outcome))

(= (codex:exec-server-processor-handler-route-response
      $state
      $request-id
      $handler-state
      $response-json
      $send-outcome)
   (codex:exec-server-processor-outgoing-send
     (codex:exec-server-processor-runtime-state-with-handler
       $state
       $handler-state)
     (codex:exec-server-rpc-server-outbound-response
       $request-id
       $response-json)
     $send-outcome))

(= (codex:exec-server-processor-handle-exec-route-result
      $state
      $request-id
      (CodexExecServerHandlerResultErr $handler-state $error)
      $send-outcome)
   (codex:exec-server-processor-handler-route-error
     $state
     $request-id
     $handler-state
     $error
     $send-outcome))

(= (codex:exec-server-processor-handle-exec-route-result
      $state
      $request-id
      (CodexExecServerHandlerResultOk $handler-state $response)
      $send-outcome)
   (codex:exec-server-processor-handler-route-response
     $state
     $request-id
     $handler-state
     (codex:exec-server-exec-response-json $response)
     $send-outcome))

(= (codex:exec-server-processor-handle-exec-read-route-result
      $state
      $request-id
      (CodexExecServerHandlerResultErr $handler-state $error)
      $send-outcome)
   (codex:exec-server-processor-handler-route-error
     $state
     $request-id
     $handler-state
     $error
     $send-outcome))

(= (codex:exec-server-processor-handle-exec-read-route-result
      $state
      $request-id
      (CodexExecServerHandlerResultOk $handler-state $response)
      $send-outcome)
   (codex:exec-server-processor-handler-route-response
     $state
     $request-id
     $handler-state
     (codex:exec-server-read-response-json $response)
     $send-outcome))

(= (codex:exec-server-processor-handle-exec-write-route-result
      $state
      $request-id
      (CodexExecServerHandlerResultErr $handler-state $error)
      $send-outcome)
   (codex:exec-server-processor-handler-route-error
     $state
     $request-id
     $handler-state
     $error
     $send-outcome))

(= (codex:exec-server-processor-handle-exec-write-route-result
      $state
      $request-id
      (CodexExecServerHandlerResultOk $handler-state $response)
      $send-outcome)
   (codex:exec-server-processor-handler-route-response
     $state
     $request-id
     $handler-state
     (codex:exec-server-write-response-json $response)
     $send-outcome))

(= (codex:exec-server-processor-handle-exec-terminate-route-result
      $state
      $request-id
      (CodexExecServerHandlerResultErr $handler-state $error)
      $send-outcome)
   (codex:exec-server-processor-handler-route-error
     $state
     $request-id
     $handler-state
     $error
     $send-outcome))

(= (codex:exec-server-processor-handle-exec-terminate-route-result
      $state
      $request-id
      (CodexExecServerHandlerResultOk $handler-state $response)
      $send-outcome)
   (codex:exec-server-processor-handler-route-response
     $state
     $request-id
     $handler-state
     (codex:exec-server-terminate-response-json $response)
     $send-outcome))

(= (codex:exec-server-processor-handle-exec-route-flow
      $state
      $request-id
      $process-outcome
      $send-outcome)
   (codex:exec-server-processor-handle-exec-route-result
     $state
     $request-id
     (codex:exec-server-handler-exec-flow
       (codex:exec-server-processor-runtime-state-handler-state
         $state)
       $process-outcome)
     $send-outcome))

(= (codex:exec-server-processor-handle-exec-read-route-flow
      $state
      $request-id
      $process-outcome
      $post-read-handler-state
      $send-outcome)
   (codex:exec-server-processor-handle-exec-read-route-result
     $state
     $request-id
     (codex:exec-server-handler-exec-read-flow
       (codex:exec-server-processor-runtime-state-handler-state
         $state)
       $process-outcome
       $post-read-handler-state)
     $send-outcome))

(= (codex:exec-server-processor-handle-exec-write-route-flow
      $state
      $request-id
      $process-outcome
      $send-outcome)
   (codex:exec-server-processor-handle-exec-write-route-result
     $state
     $request-id
     (codex:exec-server-handler-exec-write-flow
       (codex:exec-server-processor-runtime-state-handler-state
         $state)
       $process-outcome)
     $send-outcome))

(= (codex:exec-server-processor-handle-exec-terminate-route-flow
      $state
      $request-id
      $process-outcome
      $send-outcome)
   (codex:exec-server-processor-handle-exec-terminate-route-result
     $state
     $request-id
     (codex:exec-server-handler-terminate-flow
       (codex:exec-server-processor-runtime-state-handler-state
         $state)
       $process-outcome)
     $send-outcome))

(= (codex:exec-server-processor-handle-fs-read-file-route-result
      $state
      $request-id
      (CodexExecServerHandlerResultErr $handler-state $error)
      $send-outcome)
   (codex:exec-server-processor-handler-route-error
     $state
     $request-id
     $handler-state
     $error
     $send-outcome))

(= (codex:exec-server-processor-handle-fs-read-file-route-result
      $state
      $request-id
      (CodexExecServerHandlerResultOk $handler-state $response)
      $send-outcome)
   (codex:exec-server-processor-handler-route-response
     $state
     $request-id
     $handler-state
     (codex:exec-server-fs-read-file-response-json $response)
     $send-outcome))

(= (codex:exec-server-processor-handle-fs-write-file-route-result
      $state
      $request-id
      (CodexExecServerHandlerResultErr $handler-state $error)
      $send-outcome)
   (codex:exec-server-processor-handler-route-error
     $state
     $request-id
     $handler-state
     $error
     $send-outcome))

(= (codex:exec-server-processor-handle-fs-write-file-route-result
      $state
      $request-id
      (CodexExecServerHandlerResultOk $handler-state $response)
      $send-outcome)
   (codex:exec-server-processor-handler-route-response
     $state
     $request-id
     $handler-state
     (codex:exec-server-fs-write-file-response-json $response)
     $send-outcome))

(= (codex:exec-server-processor-handle-fs-create-directory-route-result
      $state
      $request-id
      (CodexExecServerHandlerResultErr $handler-state $error)
      $send-outcome)
   (codex:exec-server-processor-handler-route-error
     $state
     $request-id
     $handler-state
     $error
     $send-outcome))

(= (codex:exec-server-processor-handle-fs-create-directory-route-result
      $state
      $request-id
      (CodexExecServerHandlerResultOk $handler-state $response)
      $send-outcome)
   (codex:exec-server-processor-handler-route-response
     $state
     $request-id
     $handler-state
     (codex:exec-server-fs-create-directory-response-json $response)
     $send-outcome))

(= (codex:exec-server-processor-handle-fs-get-metadata-route-result
      $state
      $request-id
      (CodexExecServerHandlerResultErr $handler-state $error)
      $send-outcome)
   (codex:exec-server-processor-handler-route-error
     $state
     $request-id
     $handler-state
     $error
     $send-outcome))

(= (codex:exec-server-processor-handle-fs-get-metadata-route-result
      $state
      $request-id
      (CodexExecServerHandlerResultOk $handler-state $response)
      $send-outcome)
   (codex:exec-server-processor-handler-route-response
     $state
     $request-id
     $handler-state
     (codex:exec-server-fs-get-metadata-response-json $response)
     $send-outcome))

(= (codex:exec-server-processor-handle-fs-read-directory-route-result
      $state
      $request-id
      (CodexExecServerHandlerResultErr $handler-state $error)
      $send-outcome)
   (codex:exec-server-processor-handler-route-error
     $state
     $request-id
     $handler-state
     $error
     $send-outcome))

(= (codex:exec-server-processor-handle-fs-read-directory-route-result
      $state
      $request-id
      (CodexExecServerHandlerResultOk $handler-state $response)
      $send-outcome)
   (codex:exec-server-processor-handler-route-response
     $state
     $request-id
     $handler-state
     (codex:exec-server-fs-read-directory-response-json $response)
     $send-outcome))

(= (codex:exec-server-processor-handle-fs-remove-route-result
      $state
      $request-id
      (CodexExecServerHandlerResultErr $handler-state $error)
      $send-outcome)
   (codex:exec-server-processor-handler-route-error
     $state
     $request-id
     $handler-state
     $error
     $send-outcome))

(= (codex:exec-server-processor-handle-fs-remove-route-result
      $state
      $request-id
      (CodexExecServerHandlerResultOk $handler-state $response)
      $send-outcome)
   (codex:exec-server-processor-handler-route-response
     $state
     $request-id
     $handler-state
     (codex:exec-server-fs-remove-response-json $response)
     $send-outcome))

(= (codex:exec-server-processor-handle-fs-copy-route-result
      $state
      $request-id
      (CodexExecServerHandlerResultErr $handler-state $error)
      $send-outcome)
   (codex:exec-server-processor-handler-route-error
     $state
     $request-id
     $handler-state
     $error
     $send-outcome))

(= (codex:exec-server-processor-handle-fs-copy-route-result
      $state
      $request-id
      (CodexExecServerHandlerResultOk $handler-state $response)
      $send-outcome)
   (codex:exec-server-processor-handler-route-response
     $state
     $request-id
     $handler-state
     (codex:exec-server-fs-copy-response-json $response)
     $send-outcome))

(= (codex:exec-server-processor-handle-fs-read-file-route-flow
      $state
      $request-id
      $file-system-outcome
      $send-outcome)
   (codex:exec-server-processor-handle-fs-read-file-route-result
     $state
     $request-id
     (codex:exec-server-handler-fs-read-file-flow
       (codex:exec-server-processor-runtime-state-handler-state
         $state)
       $file-system-outcome)
     $send-outcome))

(= (codex:exec-server-processor-handle-fs-write-file-route-flow
      $state
      $request-id
      $file-system-outcome
      $send-outcome)
   (codex:exec-server-processor-handle-fs-write-file-route-result
     $state
     $request-id
     (codex:exec-server-handler-fs-write-file-flow
       (codex:exec-server-processor-runtime-state-handler-state
         $state)
       $file-system-outcome)
     $send-outcome))

(= (codex:exec-server-processor-handle-fs-create-directory-route-flow
      $state
      $request-id
      $file-system-outcome
      $send-outcome)
   (codex:exec-server-processor-handle-fs-create-directory-route-result
     $state
     $request-id
     (codex:exec-server-handler-fs-create-directory-flow
       (codex:exec-server-processor-runtime-state-handler-state
         $state)
       $file-system-outcome)
     $send-outcome))

(= (codex:exec-server-processor-handle-fs-get-metadata-route-flow
      $state
      $request-id
      $file-system-outcome
      $send-outcome)
   (codex:exec-server-processor-handle-fs-get-metadata-route-result
     $state
     $request-id
     (codex:exec-server-handler-fs-get-metadata-flow
       (codex:exec-server-processor-runtime-state-handler-state
         $state)
       $file-system-outcome)
     $send-outcome))

(= (codex:exec-server-processor-handle-fs-read-directory-route-flow
      $state
      $request-id
      $file-system-outcome
      $send-outcome)
   (codex:exec-server-processor-handle-fs-read-directory-route-result
     $state
     $request-id
     (codex:exec-server-handler-fs-read-directory-flow
       (codex:exec-server-processor-runtime-state-handler-state
         $state)
       $file-system-outcome)
     $send-outcome))

(= (codex:exec-server-processor-handle-fs-remove-route-flow
      $state
      $request-id
      $file-system-outcome
      $send-outcome)
   (codex:exec-server-processor-handle-fs-remove-route-result
     $state
     $request-id
     (codex:exec-server-handler-fs-remove-flow
       (codex:exec-server-processor-runtime-state-handler-state
         $state)
       $file-system-outcome)
     $send-outcome))

(= (codex:exec-server-processor-handle-fs-copy-route-flow
      $state
      $request-id
      $file-system-outcome
      $send-outcome)
   (codex:exec-server-processor-handle-fs-copy-route-result
     $state
     $request-id
     (codex:exec-server-handler-fs-copy-flow
       (codex:exec-server-processor-runtime-state-handler-state
         $state)
       $file-system-outcome)
     $send-outcome))

(= (codex:exec-server-processor-handle-http-request-route-result
      $state
      $request-id
      (CodexExecServerHandlerResultErr $handler-state $error)
      $send-outcome)
   (codex:exec-server-processor-handler-route-error
     $state
     $request-id
     $handler-state
     $error
     $send-outcome))

(= (codex:exec-server-processor-handle-http-request-route-result
      $state
      $request-id
      (CodexExecServerHandlerResultOk $handler-state $completed)
      $send-outcome)
   (CodexExecServerProcessorStepContinue
     (codex:exec-server-processor-runtime-state-with-handler
       $state
       $handler-state)
     ()))

(= (codex:exec-server-processor-handle-http-request-route-flow
      $state
      $request-id
      $params
      $runner-outcome
      $serialize-outcome
      $notify-outcome
      $send-outcome)
   (codex:exec-server-processor-handle-http-request-route-result
     $state
     $request-id
     (codex:exec-server-handler-http-request-flow
       (codex:exec-server-processor-runtime-state-handler-state
         $state)
       $request-id
       $params
       $runner-outcome
       $serialize-outcome
       $notify-outcome)
     $send-outcome))

(= (codex:exec-server-processor-handle-known-request
      $state
      $router
      (CodexExecServerRpcRequest $id $method $params $trace)
      $initialize-attach-outcome
      $route-outcome
      $send-outcome)
   (if (== $method (codex:exec-server-protocol-initialize-method))
       (codex:exec-server-processor-handle-initialize-route
         $state
         (CodexExecServerRpcRequest $id $method $params $trace)
         $initialize-attach-outcome
         $send-outcome)
       (let $route
         (codex:exec-server-rpc-router-request-route $router $method)
         (if (== $route CodexAbsent)
             (codex:exec-server-processor-handle-request
               $state
               $router
               (CodexExecServerRpcRequest $id $method $params $trace)
               $route-outcome
               $send-outcome)
             (case (codex:exec-server-processor-request-guard
                     $state
                     $method)
               (((CodexExecServerProcessorRequestGuardOk $guard-state)
                 (codex:exec-server-processor-route-outcome-after-guard
                   $guard-state
                   $route-outcome
                   $send-outcome))
                ((CodexExecServerProcessorRequestGuardErr $guard-state $error)
                 (codex:exec-server-processor-outgoing-send
                   $guard-state
                   (codex:exec-server-rpc-server-outbound-error
                     $id
                     $error)
                   $send-outcome))))))))

(= (codex:exec-server-processor-handle-notification
      $state
      $router
      (CodexExecServerRpcNotification $method $params)
      $route-outcome)
   (let $route
     (codex:exec-server-rpc-router-notification-route $router $method)
     (if (== $route CodexAbsent)
       (codex:exec-server-processor-finish-break
         $state
         (format-args
           "closing exec-server connection after unexpected notification: {}"
           ($method))
         ())
       (case $route-outcome
         (((CodexExecServerProcessorNotificationRouteOutcomeDisconnected)
           (codex:exec-server-processor-finish-break
             $state
             (CodexExecServerProcessorBreakNotificationDisconnected)
             ()))
          ((CodexExecServerProcessorNotificationRouteOutcomeOk)
           (CodexExecServerProcessorStepContinue $state ()))
          ((CodexExecServerProcessorNotificationRouteOutcomeErr $message)
           (codex:exec-server-processor-finish-break
             $state
             (format-args
               "closing exec-server connection after protocol error: {}"
               ($message))
             ())))))))

(= (codex:exec-server-processor-handle-initialized-route
      $state
      (CodexExecServerRpcNotification $method $params))
   (case (codex:exec-server-handler-initialized
           (codex:exec-server-processor-runtime-state-handler-state
             $state))
     (((CodexExecServerHandlerStringResultOk $handler-state)
       (CodexExecServerProcessorStepContinue
         (codex:exec-server-processor-runtime-state-with-handler
           $state
           $handler-state)
         ()))
      ((CodexExecServerHandlerStringResultErr $handler-state $message)
       (codex:exec-server-processor-finish-break
         (codex:exec-server-processor-runtime-state-with-handler
           $state
           $handler-state)
         (format-args
           "closing exec-server connection after protocol error: {}"
           ($message))
         ())))))

(= (codex:exec-server-processor-handle-known-notification
      $state
      $router
      (CodexExecServerRpcNotification $method $params)
      $route-outcome)
   (if (== $method (codex:exec-server-protocol-initialized-method))
       (codex:exec-server-processor-handle-initialized-route
         $state
         (CodexExecServerRpcNotification $method $params))
       (codex:exec-server-processor-handle-notification
         $state
         $router
         (CodexExecServerRpcNotification $method $params)
         $route-outcome)))

(= (codex:exec-server-processor-handle-message
      $state
      $router
      $message
      $request-route-outcome
      $notification-route-outcome
      $send-outcome)
   (case $message
     (((CodexExecServerRpcMessageRequest $request)
       (codex:exec-server-processor-handle-request
         $state
         $router
         $request
         $request-route-outcome
         $send-outcome))
      ((CodexExecServerRpcMessageNotification $notification)
       (codex:exec-server-processor-handle-notification
         $state
         $router
         $notification
         $notification-route-outcome))
      ((CodexExecServerRpcMessageResponse
         (CodexExecServerRpcResponse $id $result))
       (codex:exec-server-processor-finish-break
         $state
         (str-concat
           "closing exec-server connection after unexpected client response: "
           (codex:exec-server-rpc-request-id-display $id))
         ()))
      ((CodexExecServerRpcMessageError
         (CodexExecServerRpcError $id $error))
       (codex:exec-server-processor-finish-break
         $state
         (str-concat
           "closing exec-server connection after unexpected client error: "
           (codex:exec-server-rpc-request-id-display $id))
         ())))))

(= (codex:exec-server-processor-handle-known-message
      $state
      $router
      $message
      $initialize-attach-outcome
      $request-route-outcome
      $notification-route-outcome
      $send-outcome)
   (case $message
     (((CodexExecServerRpcMessageRequest $request)
       (codex:exec-server-processor-handle-known-request
         $state
         $router
         $request
         $initialize-attach-outcome
         $request-route-outcome
         $send-outcome))
      ((CodexExecServerRpcMessageNotification $notification)
       (codex:exec-server-processor-handle-known-notification
         $state
         $router
         $notification
         $notification-route-outcome))
      ((CodexExecServerRpcMessageResponse $response)
       (codex:exec-server-processor-handle-message
         $state
         $router
         $message
         $request-route-outcome
         $notification-route-outcome
         $send-outcome))
      ((CodexExecServerRpcMessageError $error)
       (codex:exec-server-processor-handle-message
         $state
         $router
         $message
         $request-route-outcome
         $notification-route-outcome
         $send-outcome)))))

(= (codex:exec-server-processor-step-event-attached
      $state)
   (codex:exec-server-handler-is-session-attached
     (codex:exec-server-processor-runtime-state-handler-state
       $state)))

(= (codex:exec-server-processor-step-event
      $state
      $router
      (CodexExecServerJsonRpcConnectionEventMalformedMessage $reason)
      $request-route-outcome
      $notification-route-outcome
      $send-outcome)
   (if (not
         (codex:exec-server-processor-step-event-attached $state))
       (codex:exec-server-processor-finish-break
         $state
         "exec-server connection evicted after session resume"
         ())
       (codex:exec-server-processor-outgoing-send
         $state
         (codex:exec-server-rpc-server-outbound-error
           (codex:exec-server-rpc-request-id-integer -1)
           (codex:exec-server-rpc-invalid-request $reason))
         $send-outcome)))

(= (codex:exec-server-processor-step-event
      $state
      $router
      (CodexExecServerJsonRpcConnectionEventMessage $message)
      $request-route-outcome
      $notification-route-outcome
      $send-outcome)
   (if (not
         (codex:exec-server-processor-step-event-attached $state))
       (codex:exec-server-processor-finish-break
         $state
         "exec-server connection evicted after session resume"
         ())
       (codex:exec-server-processor-handle-message
         $state
         $router
         $message
         $request-route-outcome
         $notification-route-outcome
         $send-outcome)))

(= (codex:exec-server-processor-step-event
      $state
      $router
      (CodexExecServerJsonRpcConnectionEventDisconnected $reason)
      $request-route-outcome
      $notification-route-outcome
      $send-outcome)
   (if (not
         (codex:exec-server-processor-step-event-attached $state))
       (codex:exec-server-processor-finish-break
         $state
         "exec-server connection evicted after session resume"
         ())
       (codex:exec-server-processor-finish-break
         $state
         (CodexExecServerProcessorBreakDisconnected $reason)
         ())))

(= (codex:exec-server-processor-step-event-known-routes
      $state
      $router
      $event
      $initialize-attach-outcome
      $request-route-outcome
      $notification-route-outcome
      $send-outcome)
   (if (not
         (codex:exec-server-handler-is-session-attached
           (codex:exec-server-processor-runtime-state-handler-state
             $state)))
       (codex:exec-server-processor-finish-break
         $state
         "exec-server connection evicted after session resume"
         ())
       (case $event
         (((CodexExecServerJsonRpcConnectionEventMalformedMessage $reason)
           (codex:exec-server-processor-outgoing-send
             $state
             (codex:exec-server-rpc-server-outbound-error
               (codex:exec-server-rpc-request-id-integer -1)
               (codex:exec-server-rpc-invalid-request $reason))
             $send-outcome))
          ((CodexExecServerJsonRpcConnectionEventMessage $message)
           (codex:exec-server-processor-handle-known-message
             $state
             $router
             $message
             $initialize-attach-outcome
             $request-route-outcome
             $notification-route-outcome
             $send-outcome))
          ((CodexExecServerJsonRpcConnectionEventDisconnected $reason)
           (codex:exec-server-processor-finish-break
             $state
             (CodexExecServerProcessorBreakDisconnected $reason)
             ()))))))

(= (codex:exec-server-processor-encode-outbound-ok $json-message)
   (CodexExecServerProcessorEncodeOutboundOk $json-message))

(= (codex:exec-server-processor-encode-outbound-err $message)
   (CodexExecServerProcessorEncodeOutboundErr $message))

(= (codex:exec-server-processor-outbound-task-step
      $outbound-message
      (CodexExecServerProcessorEncodeOutboundOk $json-message)
      (CodexExecServerProcessorSendOutcomeOk))
   (CodexExecServerProcessorOutboundTaskContinue $json-message))

(= (codex:exec-server-processor-outbound-task-result-message
      (CodexExecServerProcessorOutboundTaskContinue $json-message))
   $json-message)

(= (codex:exec-server-processor-outbound-task-result-reason
      (CodexExecServerProcessorOutboundTaskBreak $reason))
   $reason)

(= (codex:exec-server-processor-outbound-task-step
      $outbound-message
      (CodexExecServerProcessorEncodeOutboundOk $json-message)
      (CodexExecServerProcessorSendOutcomeClosed))
   (CodexExecServerProcessorOutboundTaskBreak
     (CodexExecServerProcessorBreakJsonOutgoingClosed)))

(= (codex:exec-server-processor-outbound-task-step
      $outbound-message
      (CodexExecServerProcessorEncodeOutboundErr $message)
      $send-outcome)
   (CodexExecServerProcessorOutboundTaskBreak
     (format-args
       "failed to serialize exec-server outbound message: {}"
       ($message))))

(= (codex:exec-server-processor-encode-outbound-message $outbound-message)
   (CodexExecServerProcessorEncodeOutboundOk
     (codex:exec-server-rpc-encode-server-message $outbound-message)))
