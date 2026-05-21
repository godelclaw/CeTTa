!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:exec_server_rpc)
!(import! &self codex:exec_server_connection)

(= (test:connection-response-message)
   (codex:exec-server-rpc-message-response
     (codex:exec-server-rpc-response
       (codex:exec-server-rpc-request-id-integer 7)
       (JsonBool True))))

(= (test:connection-request-message)
   (codex:exec-server-rpc-message-request
     (codex:exec-server-rpc-request
       (codex:exec-server-rpc-request-id-integer 9)
       "process/read"
       (JsonObject
         ((JsonPair "processId" (JsonString "proc-1"))))
       CodexAbsent)))

!(assertEqual
  (codex:exec-server-connection-channel-capacity)
  128)

!(assertEqual
  (codex:exec-server-connection-send-malformed-message CodexAbsent)
  (CodexExecServerJsonRpcConnectionEventMalformedMessage
    "malformed JSON-RPC message"))

!(assertEqual
  (codex:exec-server-connection-send-malformed-message "bad")
  (CodexExecServerJsonRpcConnectionEventMalformedMessage "bad"))

!(assertEqual
  (codex:exec-server-connection-send-disconnected-result-disconnected
    (codex:exec-server-connection-send-disconnected CodexAbsent))
  True)

!(assertEqual
  (codex:exec-server-connection-send-disconnected-result-event
    (codex:exec-server-connection-send-disconnected "closed"))
  (CodexExecServerJsonRpcConnectionEventDisconnected "closed"))

!(assertEqual
  (codex:exec-server-connection-stdio-line-event
    "stdio test"
    "   \t\n  "
    (codex:exec-server-connection-parse-err "ignored"))
  (CodexExecServerConnectionNoEvent))

!(assertEqual
  (codex:exec-server-connection-stdio-line-event
    "stdio test"
    "{\"id\":7,\"result\":true}"
    (codex:exec-server-connection-parse-ok
      (test:connection-response-message)))
  (CodexExecServerJsonRpcConnectionEventMessage
    (CodexExecServerRpcMessageResponse
      (CodexExecServerRpcResponse
        (CodexExecServerRpcRequestIdInteger 7)
        (JsonBool True)))))

!(assertEqual
  (codex:exec-server-json-rpc-connection-event-reason
    (codex:exec-server-connection-stdio-line-event
      "stdio test"
      "{bad"
      (codex:exec-server-connection-parse-err
        "expected value at line 1 column 1")))
  "failed to parse JSON-RPC message from stdio test: expected value at line 1 column 1")

!(assertEqual
  (codex:exec-server-connection-send-disconnected-result-event
    (codex:exec-server-connection-stdio-eof-event))
  (CodexExecServerJsonRpcConnectionEventDisconnected CodexAbsent))

!(assertEqual
  (codex:exec-server-json-rpc-connection-event-reason
    (codex:exec-server-connection-send-disconnected-result-event
      (codex:exec-server-connection-stdio-read-error-event
        "stdio test"
        "broken pipe")))
  "failed to read JSON-RPC message from stdio test: broken pipe")

!(assertEqual
  (codex:exec-server-connection-websocket-frame-event
    "ws peer"
    (codex:exec-server-connection-websocket-frame-text
      "{\"id\":9,\"method\":\"process/read\"}")
    (codex:exec-server-connection-parse-ok
      (test:connection-request-message)))
  (CodexExecServerJsonRpcConnectionEventMessage
    (CodexExecServerRpcMessageRequest
      (CodexExecServerRpcRequest
        (CodexExecServerRpcRequestIdInteger 9)
        "process/read"
        (JsonObject
          ((JsonPair "processId" (JsonString "proc-1"))))
        CodexAbsent))))

!(assertEqual
  (codex:exec-server-json-rpc-connection-event-reason
    (codex:exec-server-connection-websocket-frame-event
      "ws peer"
      (codex:exec-server-connection-websocket-frame-binary
        (CodexBytes "bad"))
      (codex:exec-server-connection-parse-err
        "EOF while parsing a value")))
  "failed to parse websocket JSON-RPC message from ws peer: EOF while parsing a value")

!(assertEqual
  (codex:exec-server-connection-websocket-frame-event
    "ws peer"
    (codex:exec-server-connection-websocket-frame-ping
      (CodexBytes "ping"))
    (codex:exec-server-connection-parse-err "ignored"))
  (CodexExecServerConnectionNoEvent))

!(assertEqual
  (codex:exec-server-connection-websocket-frame-event
    "ws peer"
    (codex:exec-server-connection-websocket-frame-pong
      (CodexBytes "pong"))
    (codex:exec-server-connection-parse-err "ignored"))
  (CodexExecServerConnectionNoEvent))

!(assertEqual
  (codex:exec-server-connection-websocket-frame-event
    "ws peer"
    (codex:exec-server-connection-websocket-frame-other "frame")
    (codex:exec-server-connection-parse-err "ignored"))
  (CodexExecServerConnectionNoEvent))

!(assertEqual
  (codex:exec-server-connection-send-disconnected-result-event
    (codex:exec-server-connection-websocket-frame-event
      "ws peer"
      (codex:exec-server-connection-websocket-frame-close)
      (codex:exec-server-connection-parse-err "ignored")))
  (CodexExecServerJsonRpcConnectionEventDisconnected CodexAbsent))

!(assertEqual
  (codex:exec-server-connection-send-disconnected-result-event
    (codex:exec-server-connection-websocket-frame-event
      "ws peer"
      (codex:exec-server-connection-websocket-frame-none)
      (codex:exec-server-connection-parse-err "ignored")))
  (CodexExecServerJsonRpcConnectionEventDisconnected CodexAbsent))

!(assertEqual
  (codex:exec-server-json-rpc-connection-event-reason
    (codex:exec-server-connection-send-disconnected-result-event
      (codex:exec-server-connection-websocket-frame-event
        "ws peer"
        (codex:exec-server-connection-websocket-frame-error
          "connection reset")
        (codex:exec-server-connection-parse-err "ignored"))))
  "failed to read websocket JSON-RPC message from ws peer: connection reset")

!(assertEqualToResult
  (codex:exec-server-connection-serialize-jsonrpc-message
    (test:connection-response-message))
  ("{\"id\":7,\"result\":true}"))

!(assertEqualToResult
  (codex:exec-server-connection-serialize-jsonrpc-line-message
    (test:connection-response-message))
  ("{\"id\":7,\"result\":true}\n"))

!(assertEqualToResult
  (codex:exec-server-connection-serialize-jsonrpc-message
    (test:connection-request-message))
  ("{\"id\":9,\"method\":\"process/read\",\"params\":{\"processId\":\"proc-1\"}}"))

!(assertEqual
  (codex:exec-server-connection-stdio-writer-event
    "stdio test"
    (codex:exec-server-connection-writer-outcome-ok))
  (CodexExecServerConnectionNoEvent))

!(assertEqual
  (codex:exec-server-json-rpc-connection-event-reason
    (codex:exec-server-connection-send-disconnected-result-event
      (codex:exec-server-connection-stdio-writer-event
        "stdio test"
        (codex:exec-server-connection-writer-outcome-err
          "broken pipe"))))
  "failed to write JSON-RPC message to stdio test: broken pipe")

!(assertEqual
  (codex:exec-server-json-rpc-connection-event-reason
    (codex:exec-server-connection-send-disconnected-result-event
      (codex:exec-server-connection-websocket-serialize-event
        "ws peer"
        (codex:exec-server-connection-writer-outcome-err
          "unsupported value"))))
  "failed to serialize JSON-RPC message for ws peer: unsupported value")

!(assertEqual
  (codex:exec-server-json-rpc-connection-event-reason
    (codex:exec-server-connection-send-disconnected-result-event
      (codex:exec-server-connection-websocket-writer-event
        "ws peer"
        (codex:exec-server-connection-writer-outcome-err
          "closed"))))
  "failed to write websocket JSON-RPC message to ws peer: closed")

!(assertEqual
  (codex:exec-server-json-rpc-connection-state-disconnected
    (codex:exec-server-json-rpc-connection-from-stdio-state
      "stdio test"))
  False)

!(assertEqual
  (codex:exec-server-json-rpc-connection-state-task-count
    (codex:exec-server-json-rpc-connection-from-websocket-state
      "ws peer"))
  2)

!(assertEqual
  (codex:exec-server-json-rpc-connection-into-parts
    (codex:exec-server-json-rpc-connection-from-websocket-state
      "ws peer"))
  (CodexExecServerJsonRpcConnectionParts () () False 2))
