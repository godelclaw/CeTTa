!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:exec_server_rpc)
!(import! &self codex:exec_server_connection)
!(import! &self codex:exec_server_handler)
!(import! &self codex:exec_server_registry)
!(import! &self codex:exec_server_session_registry)
!(import! &self codex:exec_server_processor)

(= (test:processor-router)
   (codex:exec-server-registry-build-router))

(= (test:processor-state)
   (codex:exec-server-processor-runtime-state-new))

(= (test:processor-detached-state)
   (codex:exec-server-processor-runtime-state-with-handler
     (test:processor-state)
     (codex:exec-server-handler-state-with-session
       (codex:exec-server-handler-state-new)
       (codex:exec-server-handler-session-handle
         "session-1"
         "connection-1"
         False))))

(= (test:processor-request $id $method)
   (codex:exec-server-rpc-request
     (codex:exec-server-rpc-request-id-integer $id)
     $method
     CodexAbsent
     CodexAbsent))

(= (test:processor-request-event $id $method)
   (codex:exec-server-json-rpc-connection-event-message
     (codex:exec-server-rpc-message-request
       (test:processor-request $id $method))))

(= (test:processor-notification-event $method)
   (codex:exec-server-json-rpc-connection-event-message
     (codex:exec-server-rpc-message-notification
       (codex:exec-server-rpc-notification
         $method
         CodexAbsent))))

(= (test:processor-outbound-response $id)
   (codex:exec-server-rpc-server-outbound-response
     (codex:exec-server-rpc-request-id-integer $id)
     (JsonBool True)))

(= (test:processor-step
      $event
      $request-route-outcome
      $notification-route-outcome
      $send-outcome)
   (codex:exec-server-processor-step-event
     (test:processor-state)
     (test:processor-router)
     $event
     $request-route-outcome
     $notification-route-outcome
     $send-outcome))

(= (test:processor-step-default $event)
   (test:processor-step
     $event
     (codex:exec-server-processor-request-route-outcome-none)
     (codex:exec-server-processor-notification-route-outcome-ok)
     (codex:exec-server-processor-send-outcome-ok)))

(= (test:processor-send-closed-step $event)
   (test:processor-step
     $event
     (codex:exec-server-processor-request-route-outcome-none)
     (codex:exec-server-processor-notification-route-outcome-ok)
     (codex:exec-server-processor-send-outcome-closed)))

!(assertEqual
  (codex:exec-server-session-registry-session-count
    (codex:exec-server-processor-connection-processor-session-registry
      (codex:exec-server-processor-connection-processor-new
        (CodexRuntimePaths "root"))))
  0)

!(assertEqual
  (codex:exec-server-processor-connection-processor-runtime-paths
    (codex:exec-server-processor-connection-processor-new
      (CodexRuntimePaths "root")))
  (CodexRuntimePaths "root"))

!(assertEqual
  (codex:exec-server-processor-run-connection-plan-channel-capacity
    (codex:exec-server-processor-run-connection-plan
      (CodexConnectionParts "stdio")
      (CodexRuntimePaths "root")))
  128)

!(assertEqual
  (codex:exec-server-processor-run-connection-plan-runtime-state
    (codex:exec-server-processor-run-connection-plan
      (CodexConnectionParts "stdio")
      (CodexRuntimePaths "root")))
  (test:processor-state))

!(assertEqual
  (codex:exec-server-rpc-router-request-route
    (codex:exec-server-processor-run-connection-plan-router
      (codex:exec-server-processor-run-connection-plan
        (CodexConnectionParts "stdio")
        (CodexRuntimePaths "root")))
    "initialize")
  (CodexExecServerRegistryHandlerInitialize))

!(assertEqual
  (codex:exec-server-processor-step-result-outbound
    (test:processor-step-default
      (codex:exec-server-json-rpc-connection-event-malformed-message
        "bad json")))
  ((CodexExecServerRpcServerOutboundError
     (CodexExecServerRpcRequestIdInteger -1)
     (CodexExecServerRpcErrorError -32600 CodexAbsent "bad json"))))

!(assertEqual
  (codex:exec-server-processor-step-result-reason
    (test:processor-send-closed-step
      (codex:exec-server-json-rpc-connection-event-malformed-message
        "bad json")))
  (CodexExecServerProcessorBreakOutgoingClosed))

!(assertEqual
  (codex:exec-server-processor-runtime-state-connection-task-count
    (codex:exec-server-processor-step-result-state
      (test:processor-send-closed-step
        (codex:exec-server-json-rpc-connection-event-malformed-message
          "bad json"))))
  0)

!(assertEqual
  (codex:exec-server-handler-state-background-task-shutdown-cancelled
    (codex:exec-server-processor-runtime-state-handler-state
      (codex:exec-server-processor-step-result-state
        (test:processor-send-closed-step
          (codex:exec-server-json-rpc-connection-event-malformed-message
            "bad json")))))
  True)

!(assertEqual
  (codex:exec-server-processor-step-result-outbound
    (test:processor-step-default
      (test:processor-request-event 5 "missing/method")))
  ((CodexExecServerRpcServerOutboundError
     (CodexExecServerRpcRequestIdInteger 5)
     (CodexExecServerRpcErrorError
       -32601
       CodexAbsent
       "exec-server stub does not implement `missing/method` yet"))))

!(assertEqual
  (test:processor-step-default
    (test:processor-request-event 6 "initialize"))
  (CodexExecServerProcessorStepContinue
    (test:processor-state)
    ()))

!(assertEqual
  (test:processor-step
    (test:processor-request-event 7 "initialize")
    (codex:exec-server-processor-request-route-outcome-some
      (test:processor-outbound-response 7))
    (codex:exec-server-processor-notification-route-outcome-ok)
    (codex:exec-server-processor-send-outcome-ok))
  (CodexExecServerProcessorStepContinue
    (test:processor-state)
    ((CodexExecServerRpcServerOutboundResponse
       (CodexExecServerRpcRequestIdInteger 7)
       (JsonBool True)))))

!(assertEqual
  (codex:exec-server-processor-step-result-reason
    (test:processor-step
      (test:processor-request-event 8 "initialize")
      (codex:exec-server-processor-request-route-outcome-disconnected)
      (codex:exec-server-processor-notification-route-outcome-ok)
      (codex:exec-server-processor-send-outcome-ok)))
  (CodexExecServerProcessorBreakRequestDisconnected))

!(assertEqual
  (test:processor-step-default
    (test:processor-notification-event "initialized"))
  (CodexExecServerProcessorStepContinue
    (test:processor-state)
    ()))

!(assertEqual
  (codex:exec-server-processor-step-result-reason
    (test:processor-step
      (test:processor-notification-event "initialized")
      (codex:exec-server-processor-request-route-outcome-none)
      (codex:exec-server-processor-notification-route-outcome-err "boom")
      (codex:exec-server-processor-send-outcome-ok)))
  "closing exec-server connection after protocol error: boom")

!(assertEqual
  (codex:exec-server-processor-step-result-reason
    (test:processor-step-default
      (test:processor-notification-event "surprise")))
  "closing exec-server connection after unexpected notification: surprise")

!(assertEqual
  (codex:exec-server-processor-step-result-reason
    (test:processor-step
      (test:processor-notification-event "initialized")
      (codex:exec-server-processor-request-route-outcome-none)
      (codex:exec-server-processor-notification-route-outcome-disconnected)
      (codex:exec-server-processor-send-outcome-ok)))
  (CodexExecServerProcessorBreakNotificationDisconnected))

!(assertEqual
  (codex:exec-server-processor-step-result-reason
    (test:processor-step-default
      (codex:exec-server-json-rpc-connection-event-message
        (codex:exec-server-rpc-message-response
          (codex:exec-server-rpc-response
            (codex:exec-server-rpc-request-id-integer 9)
            (JsonBool True))))))
  "closing exec-server connection after unexpected client response: 9")

!(assertEqual
  (codex:exec-server-processor-step-result-reason
    (test:processor-step-default
      (codex:exec-server-json-rpc-connection-event-message
        (codex:exec-server-rpc-message-error
          (codex:exec-server-rpc-error
            (codex:exec-server-rpc-request-id-integer 10)
            (codex:exec-server-rpc-invalid-request "bad"))))))
  "closing exec-server connection after unexpected client error: 10")

!(assertEqual
  (codex:exec-server-processor-step-result-reason
    (test:processor-step-default
      (codex:exec-server-json-rpc-connection-event-disconnected
        "reader ended")))
  (CodexExecServerProcessorBreakDisconnected "reader ended"))

!(assertEqual
  (codex:exec-server-processor-step-result-reason
    (codex:exec-server-processor-step-event
      (test:processor-detached-state)
      (test:processor-router)
      (codex:exec-server-json-rpc-connection-event-malformed-message
        "ignored")
      (codex:exec-server-processor-request-route-outcome-none)
      (codex:exec-server-processor-notification-route-outcome-ok)
      (codex:exec-server-processor-send-outcome-ok)))
  "exec-server connection evicted after session resume")

!(assertEqual
  (codex:exec-server-processor-step-result-outbound
    (codex:exec-server-processor-step-event
      (test:processor-detached-state)
      (test:processor-router)
      (codex:exec-server-json-rpc-connection-event-malformed-message
        "ignored")
      (codex:exec-server-processor-request-route-outcome-none)
      (codex:exec-server-processor-notification-route-outcome-ok)
      (codex:exec-server-processor-send-outcome-ok)))
  ())

!(assertEqual
  (codex:exec-server-processor-encode-outbound-message
    (test:processor-outbound-response 11))
  (CodexExecServerProcessorEncodeOutboundOk
    (CodexExecServerRpcMessageResponse
      (CodexExecServerRpcResponse
        (CodexExecServerRpcRequestIdInteger 11)
        (JsonBool True)))))

!(assertEqual
  (codex:exec-server-processor-outbound-task-step
    (test:processor-outbound-response 12)
    (codex:exec-server-processor-encode-outbound-message
      (test:processor-outbound-response 12))
    (codex:exec-server-processor-send-outcome-ok))
  (CodexExecServerProcessorOutboundTaskContinue
    (CodexExecServerRpcMessageResponse
      (CodexExecServerRpcResponse
        (CodexExecServerRpcRequestIdInteger 12)
        (JsonBool True)))))

!(assertEqual
  (codex:exec-server-processor-outbound-task-result-reason
    (codex:exec-server-processor-outbound-task-step
      (test:processor-outbound-response 13)
      (codex:exec-server-processor-encode-outbound-message
        (test:processor-outbound-response 13))
      (codex:exec-server-processor-send-outcome-closed)))
  (CodexExecServerProcessorBreakJsonOutgoingClosed))

!(assertEqual
  (codex:exec-server-processor-outbound-task-result-reason
    (codex:exec-server-processor-outbound-task-step
      (test:processor-outbound-response 14)
      (codex:exec-server-processor-encode-outbound-err "bad")
      (codex:exec-server-processor-send-outcome-ok)))
  "failed to serialize exec-server outbound message: bad")
