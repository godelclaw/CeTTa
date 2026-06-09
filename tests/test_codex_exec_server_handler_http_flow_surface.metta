!(register-module! ../codex)
!(import! &self codex:exec_server_rpc)
!(import! &self codex:exec_server_process_protocol)
!(import! &self codex:exec_server_http_protocol)
!(import! &self codex:exec_server_handler)

(= (test:handler-http-flow-session)
   (codex:exec-server-handler-session-handle
     "session-1"
     "connection-1"
     True))

(= (test:handler-http-flow-initialized-state)
   (codex:exec-server-handler-string-result-state
     (codex:exec-server-handler-initialized
       (codex:exec-server-handler-result-state
         (codex:exec-server-handler-initialize
           (codex:exec-server-handler-state-new)
           (codex:exec-server-handler-attach-ok
             (test:handler-http-flow-session)))))))

(= (test:handler-http-flow-request-id)
   (codex:exec-server-rpc-request-id-integer 41))

(= (test:handler-http-flow-params $request-id $stream-response)
   (codex:exec-server-http-request-params
     "GET"
     "https://example.test/"
     ()
     CodexAbsent
     CodexAbsent
     $request-id
     $stream-response))

(= (test:handler-http-flow-response)
   (codex:exec-server-http-request-response
     200
     ((codex:exec-server-http-header "content-type" "text/plain"))
     (codex:exec-server-byte-chunk "ok")))

(= (test:handler-http-flow-runner-ok-buffered)
   (codex:exec-server-handler-http-runner-ok
     (test:handler-http-flow-response)
     CodexAbsent))

(= (test:handler-http-flow-runner-ok-stream $request-id)
   (codex:exec-server-handler-http-runner-ok
     (test:handler-http-flow-response)
     (codex:exec-server-handler-pending-http-body-stream $request-id)))

(= (test:handler-http-flow-ok-buffered)
   (codex:exec-server-handler-http-request-flow
     (test:handler-http-flow-initialized-state)
     (test:handler-http-flow-request-id)
     (test:handler-http-flow-params "body-flow" False)
     (test:handler-http-flow-runner-ok-buffered)
     (codex:exec-server-handler-http-serialize-ok)
     (codex:exec-server-handler-http-notify-ok)))

(= (test:handler-http-flow-runner-error)
   (codex:exec-server-handler-http-request-flow
     (test:handler-http-flow-initialized-state)
     (test:handler-http-flow-request-id)
     (test:handler-http-flow-params "body-flow" True)
     (codex:exec-server-handler-http-runner-err
       (codex:exec-server-rpc-internal-error
         "http/request failed: boom"))
     (codex:exec-server-handler-http-serialize-ok)
     (codex:exec-server-handler-http-notify-ok)))

(= (test:handler-http-flow-serialize-error)
   (codex:exec-server-handler-http-request-flow
     (test:handler-http-flow-initialized-state)
     (test:handler-http-flow-request-id)
     (test:handler-http-flow-params "body-flow" True)
     (test:handler-http-flow-runner-ok-stream "body-flow")
     (codex:exec-server-handler-http-serialize-err "json boom")
     (codex:exec-server-handler-http-notify-ok)))

(= (test:handler-http-flow-notify-error)
   (codex:exec-server-handler-http-request-flow
     (test:handler-http-flow-initialized-state)
     (test:handler-http-flow-request-id)
     (test:handler-http-flow-params "body-flow" True)
     (test:handler-http-flow-runner-ok-stream "body-flow")
     (codex:exec-server-handler-http-serialize-ok)
     (codex:exec-server-handler-http-notify-err
       (codex:exec-server-rpc-internal-error
         "RPC connection closed while sending notification"))))

(= (test:handler-http-flow-ok-stream)
   (codex:exec-server-handler-http-request-flow
     (test:handler-http-flow-initialized-state)
     (test:handler-http-flow-request-id)
     (test:handler-http-flow-params "body-flow" True)
     (test:handler-http-flow-runner-ok-stream "body-flow")
     (codex:exec-server-handler-http-serialize-ok)
     (codex:exec-server-handler-http-notify-ok)))

!(assertEqual
  (codex:exec-server-handler-result-error
    (codex:exec-server-handler-http-request-flow
      (codex:exec-server-handler-state-new)
      (test:handler-http-flow-request-id)
      (test:handler-http-flow-params "body-flow" True)
      (test:handler-http-flow-runner-ok-stream "body-flow")
      (codex:exec-server-handler-http-serialize-ok)
      (codex:exec-server-handler-http-notify-ok)))
  (CodexExecServerRpcErrorError
    -32600
    CodexAbsent
    "client must call initialize before using http methods"))

!(assertEqual
  (codex:exec-server-handler-http-request-completed-outbound-response
    (codex:exec-server-handler-result-value
      (test:handler-http-flow-ok-buffered)))
  (CodexExecServerRpcServerOutboundResponse
    (CodexExecServerRpcRequestIdInteger 41)
    (codex:exec-server-http-request-response-json
      (test:handler-http-flow-response))))

!(assertEqual
  (codex:exec-server-handler-http-request-completed-body-stream-action
    (codex:exec-server-handler-result-value
      (test:handler-http-flow-ok-buffered)))
  CodexAbsent)

!(assertEqual
  (codex:exec-server-handler-state-active-body-stream-ids
    (codex:exec-server-handler-result-state
      (test:handler-http-flow-runner-error)))
  ())

!(assertEqual
  (codex:exec-server-handler-result-error
    (test:handler-http-flow-runner-error))
  (CodexExecServerRpcErrorError
    -32603
    CodexAbsent
    "http/request failed: boom"))

!(assertEqual
  (codex:exec-server-handler-state-active-body-stream-ids
    (codex:exec-server-handler-result-state
      (test:handler-http-flow-serialize-error)))
  ())

!(assertEqual
  (codex:exec-server-handler-result-error
    (test:handler-http-flow-serialize-error))
  (CodexExecServerRpcErrorError -32603 CodexAbsent "json boom"))

!(assertEqual
  (codex:exec-server-handler-state-active-body-stream-ids
    (codex:exec-server-handler-result-state
      (test:handler-http-flow-notify-error)))
  ())

!(assertEqual
  (codex:exec-server-handler-result-error
    (test:handler-http-flow-notify-error))
  (CodexExecServerRpcErrorError
    -32603
    CodexAbsent
    "RPC connection closed while sending notification"))

!(assertEqual
  (codex:exec-server-handler-http-request-completed-body-stream-action
    (codex:exec-server-handler-result-value
      (test:handler-http-flow-ok-stream)))
  (CodexExecServerHandlerBodyStreamStarted))

!(assertEqual
  (codex:exec-server-handler-state-active-body-stream-ids
    (codex:exec-server-handler-result-state
      (test:handler-http-flow-ok-stream)))
  ("body-flow"))

!(assertEqual
  (codex:exec-server-handler-state-background-task-count
    (codex:exec-server-handler-result-state
      (test:handler-http-flow-ok-stream)))
  1)
