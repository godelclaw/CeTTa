!(register-module! ../codex)
!(import! &self codex:exec_server_rpc)
!(import! &self codex:exec_server_connection)
!(import! &self codex:exec_server_handler)
!(import! &self codex:exec_server_processor)
!(import! &self codex:exec_server_process_protocol)

(= (test:known-routes-router $method)
   (codex:exec-server-rpc-router-request
     (codex:exec-server-rpc-router-new)
     $method
     (CodexTestKnownRoutesHandler)))

(= (test:known-routes-state)
   (codex:exec-server-processor-runtime-state-new))

(= (test:known-routes-attach-ok)
   (codex:exec-server-handler-attach-ok
     (codex:exec-server-handler-session-handle
       "session-real"
       "connection-real"
       True)))

(= (test:known-routes-request-event $id $method)
   (codex:exec-server-json-rpc-connection-event-message
     (codex:exec-server-rpc-message-request
       (codex:exec-server-rpc-request
         (codex:exec-server-rpc-request-id-integer $id)
         $method
         CodexAbsent
         CodexAbsent))))

(= (test:known-routes-outbound-response $id)
   (codex:exec-server-rpc-server-outbound-response
     (codex:exec-server-rpc-request-id-integer $id)
     (JsonBool True)))

(= (test:known-routes-step
      $state
      $id
      $method
      $request-route-outcome)
   (codex:exec-server-processor-step-event-known-routes
     $state
     (test:known-routes-router $method)
     (test:known-routes-request-event $id $method)
     (test:known-routes-attach-ok)
     $request-route-outcome
     (codex:exec-server-processor-notification-route-outcome-ok)
     (codex:exec-server-processor-send-outcome-ok)))

(= (test:known-routes-initialize-step)
   (test:known-routes-step
     (test:known-routes-state)
     15
     (codex:exec-server-protocol-initialize-method)
     (codex:exec-server-processor-request-route-outcome-none)))

(= (test:known-routes-after-initialize-state)
   (codex:exec-server-processor-step-result-state
     (test:known-routes-initialize-step)))

(= (test:known-routes-after-initialized-state)
   (codex:exec-server-processor-step-result-state
     (codex:exec-server-processor-step-event-known-routes
       (test:known-routes-after-initialize-state)
       (codex:exec-server-rpc-router-new)
       (codex:exec-server-json-rpc-connection-event-message
         (codex:exec-server-rpc-message-notification
           (codex:exec-server-rpc-notification
             (codex:exec-server-protocol-initialized-method)
             CodexAbsent)))
       (test:known-routes-attach-ok)
       (codex:exec-server-processor-request-route-outcome-none)
       (codex:exec-server-processor-notification-route-outcome-ok)
       (codex:exec-server-processor-send-outcome-ok))))

!(assertEqual
  (codex:exec-server-processor-step-result-outbound
    (test:known-routes-step
      (test:known-routes-state)
      17
      (codex:exec-server-protocol-exec-method)
      (codex:exec-server-processor-request-route-outcome-none)))
  ((CodexExecServerRpcServerOutboundError
     (CodexExecServerRpcRequestIdInteger 17)
     (CodexExecServerRpcErrorError
       -32600
       CodexAbsent
       "client must call initialize before using exec methods"))))

!(assertEqual
  (codex:exec-server-processor-step-result-outbound
    (test:known-routes-step
      (test:known-routes-after-initialize-state)
      18
      (codex:exec-server-protocol-exec-read-method)
      (codex:exec-server-processor-request-route-outcome-none)))
  ((CodexExecServerRpcServerOutboundError
     (CodexExecServerRpcRequestIdInteger 18)
     (CodexExecServerRpcErrorError
       -32600
       CodexAbsent
       "client must send initialized before using exec methods"))))

!(assertEqual
  (codex:exec-server-processor-step-result-outbound
    (test:known-routes-step
      (test:known-routes-state)
      19
      (codex:exec-server-protocol-fs-read-file-method)
      (codex:exec-server-processor-request-route-outcome-none)))
  ((CodexExecServerRpcServerOutboundError
     (CodexExecServerRpcRequestIdInteger 19)
     (CodexExecServerRpcErrorError
       -32600
       CodexAbsent
       "client must call initialize before using filesystem methods"))))

!(assertEqual
  (codex:exec-server-processor-step-result-outbound
    (test:known-routes-step
      (test:known-routes-state)
      20
      (codex:exec-server-protocol-http-request-method)
      (codex:exec-server-processor-request-route-outcome-none)))
  ((CodexExecServerRpcServerOutboundError
     (CodexExecServerRpcRequestIdInteger 20)
     (CodexExecServerRpcErrorError
       -32600
       CodexAbsent
       "client must call initialize before using http methods"))))

!(assertEqual
  (codex:exec-server-processor-step-result-outbound
    (test:known-routes-step
      (test:known-routes-after-initialized-state)
      21
      (codex:exec-server-protocol-exec-method)
      (codex:exec-server-processor-request-route-outcome-some
        (test:known-routes-outbound-response 21))))
  ((CodexExecServerRpcServerOutboundResponse
     (CodexExecServerRpcRequestIdInteger 21)
     (JsonBool True))))
