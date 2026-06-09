!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:exec_server_rpc)
!(import! &self codex:exec_server_handler)
!(import! &self codex:exec_server_process_id)
!(import! &self codex:exec_server_process_protocol)
!(import! &self codex:exec_server_processor)

(= (test:processor-process-flow-session)
   (codex:exec-server-handler-session-handle
     "session-1"
     "connection-1"
     True))

(= (test:processor-process-flow-detached-session)
   (codex:exec-server-handler-session-handle
     "session-1"
     "connection-1"
     False))

(= (test:processor-process-flow-handler-state)
   (codex:exec-server-handler-string-result-state
     (codex:exec-server-handler-initialized
       (codex:exec-server-handler-result-state
         (codex:exec-server-handler-initialize
           (codex:exec-server-handler-state-new)
           (codex:exec-server-handler-attach-ok
             (test:processor-process-flow-session)))))))

(= (test:processor-process-flow-state)
   (codex:exec-server-processor-runtime-state-with-handler
     (codex:exec-server-processor-runtime-state-new)
     (test:processor-process-flow-handler-state)))

(= (test:processor-process-flow-post-detached-handler-state)
   (codex:exec-server-handler-state-with-session
     (test:processor-process-flow-handler-state)
     (test:processor-process-flow-detached-session)))

(= (test:processor-process-flow-request-id $id)
   (codex:exec-server-rpc-request-id-integer $id))

(= (test:processor-process-flow-ok $response)
   (codex:exec-server-handler-process-ok $response))

(= (test:processor-process-flow-err $message)
   (codex:exec-server-handler-process-err
     (codex:exec-server-rpc-internal-error $message)))

!(assertEqual
  (codex:exec-server-processor-step-result-outbound
    (codex:exec-server-processor-handle-exec-route-flow
      (codex:exec-server-processor-runtime-state-new)
      (test:processor-process-flow-request-id 31)
      (test:processor-process-flow-ok
        (codex:exec-server-exec-response
          (codex:exec-server-process-id-new "proc-1")))
      (codex:exec-server-processor-send-outcome-ok)))
  ((CodexExecServerRpcServerOutboundError
     (CodexExecServerRpcRequestIdInteger 31)
     (CodexExecServerRpcErrorError
       -32600
       CodexAbsent
       "client must call initialize before using exec methods"))))

!(assertEqual
  (codex:exec-server-processor-step-result-outbound
    (codex:exec-server-processor-handle-exec-route-flow
      (test:processor-process-flow-state)
      (test:processor-process-flow-request-id 32)
      (test:processor-process-flow-ok
        (codex:exec-server-exec-response
          (codex:exec-server-process-id-new "proc-1")))
      (codex:exec-server-processor-send-outcome-ok)))
  ((CodexExecServerRpcServerOutboundResponse
     (CodexExecServerRpcRequestIdInteger 32)
     (JsonObject
       ((JsonPair "processId" (JsonString "proc-1")))))))

!(assertEqual
  (codex:exec-server-processor-step-result-outbound
    (codex:exec-server-processor-handle-exec-read-route-flow
      (test:processor-process-flow-state)
      (test:processor-process-flow-request-id 33)
      (test:processor-process-flow-ok
        (codex:exec-server-read-response
          ()
          0
          False
          CodexAbsent
          False
          CodexAbsent))
      (test:processor-process-flow-handler-state)
      (codex:exec-server-processor-send-outcome-ok)))
  ((CodexExecServerRpcServerOutboundResponse
     (CodexExecServerRpcRequestIdInteger 33)
     (JsonObject
       ((JsonPair "chunks" (JsonArray ()))
        (JsonPair "nextSeq" (JsonNumber "0"))
        (JsonPair "exited" (JsonBool False))
        (JsonPair "exitCode" JsonNull)
        (JsonPair "closed" (JsonBool False))
        (JsonPair "failure" JsonNull))))))

!(assertEqual
  (codex:exec-server-processor-step-result-outbound
    (codex:exec-server-processor-handle-exec-write-route-flow
      (test:processor-process-flow-state)
      (test:processor-process-flow-request-id 34)
      (test:processor-process-flow-ok
        (codex:exec-server-write-response
          (codex:exec-server-write-status-accepted)))
      (codex:exec-server-processor-send-outcome-ok)))
  ((CodexExecServerRpcServerOutboundResponse
     (CodexExecServerRpcRequestIdInteger 34)
     (JsonObject
       ((JsonPair "status" (JsonString "accepted")))))))

!(assertEqual
  (codex:exec-server-processor-step-result-outbound
    (codex:exec-server-processor-handle-exec-terminate-route-flow
      (test:processor-process-flow-state)
      (test:processor-process-flow-request-id 35)
      (test:processor-process-flow-ok
        (codex:exec-server-terminate-response False))
      (codex:exec-server-processor-send-outcome-ok)))
  ((CodexExecServerRpcServerOutboundResponse
     (CodexExecServerRpcRequestIdInteger 35)
     (JsonObject
       ((JsonPair "running" (JsonBool False)))))))

!(assertEqual
  (codex:exec-server-processor-step-result-outbound
    (codex:exec-server-processor-handle-exec-read-route-flow
      (test:processor-process-flow-state)
      (test:processor-process-flow-request-id 36)
      (test:processor-process-flow-ok
        (codex:exec-server-read-response
          ()
          0
          False
          CodexAbsent
          False
          CodexAbsent))
      (test:processor-process-flow-post-detached-handler-state)
      (codex:exec-server-processor-send-outcome-ok)))
  ((CodexExecServerRpcServerOutboundError
     (CodexExecServerRpcRequestIdInteger 36)
     (CodexExecServerRpcErrorError
       -32600
       CodexAbsent
       "session has been resumed by another connection"))))

!(assertEqual
  (codex:exec-server-processor-runtime-state-handler-state
    (codex:exec-server-processor-step-result-state
      (codex:exec-server-processor-handle-exec-read-route-flow
        (test:processor-process-flow-state)
        (test:processor-process-flow-request-id 36)
        (test:processor-process-flow-ok
          (codex:exec-server-read-response
            ()
            0
            False
            CodexAbsent
            False
            CodexAbsent))
        (test:processor-process-flow-post-detached-handler-state)
        (codex:exec-server-processor-send-outcome-ok))))
  (test:processor-process-flow-post-detached-handler-state))

!(assertEqual
  (codex:exec-server-processor-step-result-outbound
    (codex:exec-server-processor-handle-exec-read-route-flow
      (test:processor-process-flow-state)
      (test:processor-process-flow-request-id 37)
      (test:processor-process-flow-err
        "process/read failed")
      (test:processor-process-flow-post-detached-handler-state)
      (codex:exec-server-processor-send-outcome-ok)))
  ((CodexExecServerRpcServerOutboundError
     (CodexExecServerRpcRequestIdInteger 37)
     (CodexExecServerRpcErrorError
       -32603
       CodexAbsent
       "process/read failed"))))
