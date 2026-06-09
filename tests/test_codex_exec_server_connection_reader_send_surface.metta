!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:exec_server_rpc)
!(import! &self codex:exec_server_connection)

(= (test:connection-reader-message)
   (codex:exec-server-rpc-message-response
     (codex:exec-server-rpc-response
       (codex:exec-server-rpc-request-id-integer 7)
       (JsonBool True))))

!(assertEqual
  (codex:exec-server-connection-reader-step-result-event
    (codex:exec-server-connection-stdio-line-step
      "stdio test"
      "{\"id\":7,\"result\":true}"
      (codex:exec-server-connection-parse-ok
        (test:connection-reader-message))
      (codex:exec-server-connection-incoming-send-ok)))
  (CodexExecServerJsonRpcConnectionEventMessage
    (CodexExecServerRpcMessageResponse
      (CodexExecServerRpcResponse
        (CodexExecServerRpcRequestIdInteger 7)
        (JsonBool True)))))

!(assertEqual
  (codex:exec-server-connection-reader-step-result-reason
    (codex:exec-server-connection-stdio-line-step
      "stdio test"
      "{\"id\":7,\"result\":true}"
      (codex:exec-server-connection-parse-ok
        (test:connection-reader-message))
      (codex:exec-server-connection-incoming-send-closed)))
  (CodexExecServerConnectionReaderBreakIncomingClosed))

!(assertEqual
  (codex:exec-server-connection-reader-step-result-event
    (codex:exec-server-connection-stdio-line-step
      "stdio test"
      "{bad"
      (codex:exec-server-connection-parse-err
        "expected value at line 1 column 1")
      (codex:exec-server-connection-incoming-send-closed)))
  (CodexExecServerJsonRpcConnectionEventMalformedMessage
    "failed to parse JSON-RPC message from stdio test: expected value at line 1 column 1"))

!(assertEqual
  (codex:exec-server-connection-reader-step-result-event
    (codex:exec-server-connection-stdio-line-step
      "stdio test"
      "  \t "
      (codex:exec-server-connection-parse-ok
        (test:connection-reader-message))
      (codex:exec-server-connection-incoming-send-closed)))
  (CodexExecServerConnectionNoEvent))

!(assertEqual
  (codex:exec-server-connection-reader-step-result-reason
    (codex:exec-server-connection-websocket-frame-step
      "ws peer"
      (codex:exec-server-connection-websocket-frame-text
        "{\"id\":7,\"result\":true}")
      (codex:exec-server-connection-parse-ok
        (test:connection-reader-message))
      (codex:exec-server-connection-incoming-send-closed)))
  (CodexExecServerConnectionReaderBreakIncomingClosed))

!(assertEqual
  (codex:exec-server-connection-reader-step-result-event
    (codex:exec-server-connection-websocket-frame-step
      "ws peer"
      (codex:exec-server-connection-websocket-frame-binary
        (CodexBytes "bad"))
      (codex:exec-server-connection-parse-err
        "EOF while parsing a value")
      (codex:exec-server-connection-incoming-send-closed)))
  (CodexExecServerJsonRpcConnectionEventMalformedMessage
    "failed to parse websocket JSON-RPC message from ws peer: EOF while parsing a value"))

!(assertEqual
  (codex:exec-server-connection-reader-step-result-event
    (codex:exec-server-connection-websocket-frame-step
      "ws peer"
      (codex:exec-server-connection-websocket-frame-close)
      (codex:exec-server-connection-parse-err "ignored")
      (codex:exec-server-connection-incoming-send-closed)))
  (CodexExecServerJsonRpcConnectionEventDisconnected CodexAbsent))

!(assertEqual
  (codex:exec-server-connection-reader-step-result-event
    (codex:exec-server-connection-websocket-frame-step
      "ws peer"
      (codex:exec-server-connection-websocket-frame-ping
        (CodexBytes "ping"))
      (codex:exec-server-connection-parse-err "ignored")
      (codex:exec-server-connection-incoming-send-closed)))
  (CodexExecServerConnectionNoEvent))
