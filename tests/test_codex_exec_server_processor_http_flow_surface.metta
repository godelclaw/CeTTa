!(register-module! ../codex)
!(import! &self codex:exec_server_rpc)
!(import! &self codex:exec_server_process_protocol)
!(import! &self codex:exec_server_http_protocol)
!(import! &self codex:exec_server_handler)
!(import! &self codex:exec_server_processor)

(= (test:processor-http-flow-session)
   (codex:exec-server-handler-session-handle
     "session-1"
     "connection-1"
     True))

(= (test:processor-http-flow-handler-state)
   (codex:exec-server-handler-string-result-state
     (codex:exec-server-handler-initialized
       (codex:exec-server-handler-result-state
         (codex:exec-server-handler-initialize
           (codex:exec-server-handler-state-new)
           (codex:exec-server-handler-attach-ok
             (test:processor-http-flow-session)))))))

(= (test:processor-http-flow-state)
   (codex:exec-server-processor-runtime-state-with-handler
     (codex:exec-server-processor-runtime-state-new)
     (test:processor-http-flow-handler-state)))

(= (test:processor-http-flow-request-id $id)
   (codex:exec-server-rpc-request-id-integer $id))

(= (test:processor-http-flow-params $request-id $stream-response)
   (codex:exec-server-http-request-params
     "GET"
     "https://example.test/"
     ()
     CodexAbsent
     CodexAbsent
     $request-id
     $stream-response))

(= (test:processor-http-flow-response)
   (codex:exec-server-http-request-response
     200
     ((codex:exec-server-http-header "content-type" "text/plain"))
     (codex:exec-server-byte-chunk "ok")))

(= (test:processor-http-flow-runner-ok-buffered)
   (codex:exec-server-handler-http-runner-ok
     (test:processor-http-flow-response)
     CodexAbsent))

(= (test:processor-http-flow-runner-ok-stream $request-id)
   (codex:exec-server-handler-http-runner-ok
     (test:processor-http-flow-response)
     (codex:exec-server-handler-pending-http-body-stream $request-id)))

!(assertEqual
  (codex:exec-server-processor-step-result-outbound
    (codex:exec-server-processor-handle-http-request-route-flow
      (codex:exec-server-processor-runtime-state-new)
      (test:processor-http-flow-request-id 51)
      (test:processor-http-flow-params "body-1" False)
      (test:processor-http-flow-runner-ok-buffered)
      (codex:exec-server-handler-http-serialize-ok)
      (codex:exec-server-handler-http-notify-ok)
      (codex:exec-server-processor-send-outcome-ok)))
  ((CodexExecServerRpcServerOutboundError
     (CodexExecServerRpcRequestIdInteger 51)
     (CodexExecServerRpcErrorError
       -32600
       CodexAbsent
       "client must call initialize before using http methods"))))

!(assertEqual
  (codex:exec-server-processor-step-result-outbound
    (codex:exec-server-processor-handle-http-request-route-flow
      (test:processor-http-flow-state)
      (test:processor-http-flow-request-id 52)
      (test:processor-http-flow-params "body-2" False)
      (test:processor-http-flow-runner-ok-buffered)
      (codex:exec-server-handler-http-serialize-ok)
      (codex:exec-server-handler-http-notify-ok)
      (codex:exec-server-processor-send-outcome-closed)))
  ())

!(assertEqual
  (codex:exec-server-processor-runtime-state-connection-task-count
    (codex:exec-server-processor-step-result-state
      (codex:exec-server-processor-handle-http-request-route-flow
        (test:processor-http-flow-state)
        (test:processor-http-flow-request-id 52)
        (test:processor-http-flow-params "body-2" False)
        (test:processor-http-flow-runner-ok-buffered)
        (codex:exec-server-handler-http-serialize-ok)
        (codex:exec-server-handler-http-notify-ok)
        (codex:exec-server-processor-send-outcome-closed))))
  2)

!(assertEqual
  (codex:exec-server-handler-state-active-body-stream-ids
    (codex:exec-server-processor-runtime-state-handler-state
      (codex:exec-server-processor-step-result-state
        (codex:exec-server-processor-handle-http-request-route-flow
          (test:processor-http-flow-state)
          (test:processor-http-flow-request-id 53)
          (test:processor-http-flow-params "body-3" True)
          (test:processor-http-flow-runner-ok-stream "body-3")
          (codex:exec-server-handler-http-serialize-ok)
          (codex:exec-server-handler-http-notify-ok)
          (codex:exec-server-processor-send-outcome-ok)))))
  ("body-3"))

!(assertEqual
  (codex:exec-server-handler-state-background-task-count
    (codex:exec-server-processor-runtime-state-handler-state
      (codex:exec-server-processor-step-result-state
        (codex:exec-server-processor-handle-http-request-route-flow
          (test:processor-http-flow-state)
          (test:processor-http-flow-request-id 53)
          (test:processor-http-flow-params "body-3" True)
          (test:processor-http-flow-runner-ok-stream "body-3")
          (codex:exec-server-handler-http-serialize-ok)
          (codex:exec-server-handler-http-notify-ok)
          (codex:exec-server-processor-send-outcome-ok)))))
  1)

!(assertEqual
  (codex:exec-server-processor-step-result-outbound
    (codex:exec-server-processor-handle-http-request-route-flow
      (test:processor-http-flow-state)
      (test:processor-http-flow-request-id 54)
      (test:processor-http-flow-params "body-4" True)
      (codex:exec-server-handler-http-runner-err
        (codex:exec-server-rpc-internal-error
          "http/request failed: boom"))
      (codex:exec-server-handler-http-serialize-ok)
      (codex:exec-server-handler-http-notify-ok)
      (codex:exec-server-processor-send-outcome-ok)))
  ((CodexExecServerRpcServerOutboundError
     (CodexExecServerRpcRequestIdInteger 54)
     (CodexExecServerRpcErrorError
       -32603
       CodexAbsent
       "http/request failed: boom"))))
