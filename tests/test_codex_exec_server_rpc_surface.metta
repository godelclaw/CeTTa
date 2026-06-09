!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:exec_server_rpc)

(= (test:rpc-id-1)
   (codex:exec-server-rpc-request-id-integer 1))

(= (test:rpc-id-2)
   (codex:exec-server-rpc-request-id-integer 2))

(= (test:rpc-two-call-state)
   (let $first
     (codex:exec-server-rpc-client-start-call
       (codex:exec-server-rpc-client-state-new)
       "slow-label")
     (let $second
       (codex:exec-server-rpc-client-start-call
         (codex:exec-server-rpc-call-start-result-state $first)
         "fast-label")
       (codex:exec-server-rpc-call-start-result-state $second))))

(= (test:rpc-handle-fast-first)
   (codex:exec-server-rpc-handle-server-message
     (test:rpc-two-call-state)
     (codex:exec-server-rpc-message-response
       (codex:exec-server-rpc-response
         (test:rpc-id-2)
         (JsonObject
           ((JsonPair "value" (JsonString "fast"))))))))

(= (test:rpc-handle-slow-after-fast)
   (codex:exec-server-rpc-handle-server-message
     (codex:exec-server-rpc-handle-message-result-state
       (test:rpc-handle-fast-first))
     (codex:exec-server-rpc-message-response
       (codex:exec-server-rpc-response
         (test:rpc-id-1)
         (JsonObject
           ((JsonPair "value" (JsonString "slow"))))))))

!(assertEqual
  (codex:exec-server-rpc-jsonrpc-version)
  "2.0")

!(assertEqual
  (codex:exec-server-rpc-request-id-json (test:rpc-id-1))
  (JsonNumber "1"))

!(assertEqual
  (codex:exec-server-rpc-request-id-json
    (codex:exec-server-rpc-request-id-string "abc"))
  (JsonString "abc"))

!(assertEqual
  (codex:exec-server-rpc-request-id-display
    (codex:exec-server-rpc-request-id-integer 42))
  "42")

!(assertEqual
  (codex:exec-server-rpc-invalid-request "bad request")
  (CodexExecServerRpcErrorError -32600 CodexAbsent "bad request"))

!(assertEqual
  (codex:exec-server-rpc-method-not-found "missing")
  (CodexExecServerRpcErrorError -32601 CodexAbsent "missing"))

!(assertEqual
  (codex:exec-server-rpc-invalid-params "bad params")
  (CodexExecServerRpcErrorError -32602 CodexAbsent "bad params"))

!(assertEqual
  (codex:exec-server-rpc-not-found "not found")
  (CodexExecServerRpcErrorError -32004 CodexAbsent "not found"))

!(assertEqual
  (codex:exec-server-rpc-internal-error "internal")
  (CodexExecServerRpcErrorError -32603 CodexAbsent "internal"))

!(assertEqual
  (codex:exec-server-rpc-error-error-json
    (codex:exec-server-rpc-error-error
      -32001
      (JsonObject
        ((JsonPair "kind" (JsonString "transport"))))
      "with data"))
  (JsonObject
    ((JsonPair "code" (JsonNumber "-32001"))
     (JsonPair
       "data"
       (JsonObject
         ((JsonPair "kind" (JsonString "transport")))))
     (JsonPair "message" (JsonString "with data")))))

!(assertEqual
  (codex:exec-server-rpc-message-json
    (codex:exec-server-rpc-message-request
      (codex:exec-server-rpc-request
        (test:rpc-id-1)
        "process/read"
        CodexAbsent
        CodexAbsent)))
  (JsonObject
    ((JsonPair "id" (JsonNumber "1"))
     (JsonPair "method" (JsonString "process/read")))))

!(assertEqual
  (codex:exec-server-rpc-message-json
    (codex:exec-server-rpc-message-request
      (codex:exec-server-rpc-request
        (test:rpc-id-1)
        "process/read"
        (JsonObject
          ((JsonPair "sessionId" (JsonString "s1"))))
        (JsonObject
          ((JsonPair "traceparent" (JsonString "00-abc-def-01")))))))
  (JsonObject
    ((JsonPair "id" (JsonNumber "1"))
     (JsonPair "method" (JsonString "process/read"))
     (JsonPair
       "params"
       (JsonObject
         ((JsonPair "sessionId" (JsonString "s1")))))
     (JsonPair
       "trace"
       (JsonObject
         ((JsonPair "traceparent" (JsonString "00-abc-def-01"))))))))

!(assertEqual
  (codex:exec-server-rpc-message-json
    (codex:exec-server-rpc-message-notification
      (codex:exec-server-rpc-notification "initialized" CodexAbsent)))
  (JsonObject
    ((JsonPair "method" (JsonString "initialized")))))

!(assertEqual
  (codex:exec-server-rpc-message-json
    (codex:exec-server-rpc-message-response
      (codex:exec-server-rpc-response
        (test:rpc-id-1)
        (JsonBool True))))
  (JsonObject
    ((JsonPair "id" (JsonNumber "1"))
     (JsonPair "result" (JsonBool True)))))

!(assertEqual
  (codex:exec-server-rpc-message-json
    (codex:exec-server-rpc-message-error
      (codex:exec-server-rpc-error
        (test:rpc-id-1)
        (codex:exec-server-rpc-invalid-params "missing field"))))
  (JsonObject
    ((JsonPair
       "error"
       (JsonObject
         ((JsonPair "code" (JsonNumber "-32602"))
          (JsonPair "message" (JsonString "missing field")))))
     (JsonPair "id" (JsonNumber "1")))))

!(assertEqual
  (codex:exec-server-rpc-response-message
    (test:rpc-id-1)
    (codex:exec-server-rpc-ok (JsonString "ok")))
  (CodexExecServerRpcMessageResponse
    (CodexExecServerRpcResponse
      (CodexExecServerRpcRequestIdInteger 1)
      (JsonString "ok"))))

!(assertEqual
  (codex:exec-server-rpc-response-message
    (test:rpc-id-1)
    (codex:exec-server-rpc-err
      (codex:exec-server-rpc-method-not-found "missing")))
  (CodexExecServerRpcMessageError
    (CodexExecServerRpcError
      (CodexExecServerRpcRequestIdInteger 1)
      (CodexExecServerRpcErrorError -32601 CodexAbsent "missing"))))

!(assertEqual
  (codex:exec-server-rpc-invalid-request-message "malformed")
  (CodexExecServerRpcMessageError
    (CodexExecServerRpcError
      (CodexExecServerRpcRequestIdInteger -1)
      (CodexExecServerRpcErrorError -32600 CodexAbsent "malformed"))))

!(assertEqual
  (codex:exec-server-rpc-encode-server-message
    (codex:exec-server-rpc-server-outbound-response
      (test:rpc-id-1)
      (JsonString "ready")))
  (CodexExecServerRpcMessageResponse
    (CodexExecServerRpcResponse
      (CodexExecServerRpcRequestIdInteger 1)
      (JsonString "ready"))))

!(assertEqual
  (codex:exec-server-rpc-encode-server-message
    (codex:exec-server-rpc-server-outbound-error
      (test:rpc-id-1)
      (codex:exec-server-rpc-internal-error "closed")))
  (CodexExecServerRpcMessageError
    (CodexExecServerRpcError
      (CodexExecServerRpcRequestIdInteger 1)
      (CodexExecServerRpcErrorError -32603 CodexAbsent "closed"))))

!(assertEqual
  (codex:exec-server-rpc-encode-server-message
    (codex:exec-server-rpc-server-outbound-notification
      (codex:exec-server-rpc-notification
        "process/output"
        (JsonObject ()))))
  (CodexExecServerRpcMessageNotification
    (CodexExecServerRpcNotification
      "process/output"
      (JsonObject ()))))

!(assertEqual
  (codex:exec-server-rpc-call-start-result-request-id
    (codex:exec-server-rpc-client-start-call
      (codex:exec-server-rpc-client-state-new)
      "slow-label"))
  (CodexExecServerRpcRequestIdInteger 1))

!(assertEqual
  (codex:exec-server-rpc-client-state-next-request-id
    (test:rpc-two-call-state))
  3)

!(assertEqual
  (codex:exec-server-rpc-client-state-pending-count
    (test:rpc-two-call-state))
  2)

!(assertEqual
  (codex:exec-server-rpc-handle-message-result-label
    (test:rpc-handle-fast-first))
  "fast-label")

!(assertEqual
  (codex:exec-server-rpc-handle-message-result-result
    (test:rpc-handle-fast-first))
  (CodexExecServerRpcOk
    (JsonObject
      ((JsonPair "value" (JsonString "fast"))))))

!(assertEqual
  (codex:exec-server-rpc-client-state-pending-count
    (codex:exec-server-rpc-handle-message-result-state
      (test:rpc-handle-fast-first)))
  1)

!(assertEqual
  (codex:exec-server-rpc-handle-message-result-label
    (test:rpc-handle-slow-after-fast))
  "slow-label")

!(assertEqual
  (codex:exec-server-rpc-client-state-pending-count
    (codex:exec-server-rpc-handle-message-result-state
      (test:rpc-handle-slow-after-fast)))
  0)

!(assertEqual
  (codex:exec-server-rpc-handle-server-message
    (test:rpc-two-call-state)
    (codex:exec-server-rpc-message-response
      (codex:exec-server-rpc-response
        (codex:exec-server-rpc-request-id-integer 99)
        (JsonString "unknown"))))
  (CodexExecServerRpcHandleMessageIgnored
    (test:rpc-two-call-state)))

!(assertEqual
  (codex:exec-server-rpc-handle-message-result-result
    (codex:exec-server-rpc-handle-server-message
      (test:rpc-two-call-state)
      (codex:exec-server-rpc-message-error
        (codex:exec-server-rpc-error
          (test:rpc-id-1)
          (codex:exec-server-rpc-internal-error "failed")))))
  (CodexExecServerRpcErr
    (CodexExecServerRpcCallErrorServer
      (CodexExecServerRpcErrorError -32603 CodexAbsent "failed"))))

!(assertEqual
  (codex:exec-server-rpc-handle-message-result-event
    (codex:exec-server-rpc-handle-server-message
      (test:rpc-two-call-state)
      (codex:exec-server-rpc-message-notification
        (codex:exec-server-rpc-notification
          "process/output"
          (JsonObject ())))))
  (CodexExecServerRpcClientEventNotification
    (CodexExecServerRpcNotification
      "process/output"
      (JsonObject ()))))

!(assertEqual
  (codex:exec-server-rpc-handle-message-result-message
    (codex:exec-server-rpc-handle-server-message
      (test:rpc-two-call-state)
      (codex:exec-server-rpc-message-request
        (codex:exec-server-rpc-request
          (test:rpc-id-1)
          "unexpected"
          CodexAbsent
          CodexAbsent))))
  "unexpected JSON-RPC request from remote server: unexpected")

!(assertEqual
  (codex:exec-server-rpc-client-start-call
    (codex:exec-server-rpc-client-state-with-disconnected
      (codex:exec-server-rpc-client-state-new)
      True)
    "blocked")
  (CodexExecServerRpcCallStartClosed
    (CodexExecServerRpcClientState 2 () True)))

!(assertEqual
  (codex:exec-server-rpc-drain-pending-result-closed-labels
    (codex:exec-server-rpc-drain-pending
      (test:rpc-two-call-state)))
  ("slow-label" "fast-label"))

!(assertEqual
  (codex:exec-server-rpc-client-state-pending-count
    (codex:exec-server-rpc-drain-pending-result-state
      (codex:exec-server-rpc-drain-pending
        (test:rpc-two-call-state))))
  0)

!(assertEqual
  (codex:exec-server-rpc-decode-params-policy
    (JsonObject ((JsonPair "n" (JsonNumber "1"))))
    (codex:exec-server-rpc-decode-outcome-ok "primary")
    (codex:exec-server-rpc-decode-outcome-ok "null"))
  (CodexExecServerRpcDecodeOutcomeOk "primary"))

!(assertEqual
  (codex:exec-server-rpc-decode-params-policy
    (JsonObject ())
    (codex:exec-server-rpc-decode-outcome-err "primary failed")
    (codex:exec-server-rpc-decode-outcome-ok "null decoded"))
  (CodexExecServerRpcDecodeOutcomeOk "null decoded"))

!(assertEqual
  (codex:exec-server-rpc-decode-params-policy
    (JsonObject ())
    (codex:exec-server-rpc-decode-outcome-err "primary failed")
    (codex:exec-server-rpc-decode-outcome-err "null failed"))
  (CodexExecServerRpcDecodeOutcomeErr "primary failed"))

!(assertEqual
  (codex:exec-server-rpc-decode-params-policy
    (JsonObject ((JsonPair "n" (JsonNumber "1"))))
    (codex:exec-server-rpc-decode-outcome-err "primary failed")
    (codex:exec-server-rpc-decode-outcome-ok "null decoded"))
  (CodexExecServerRpcDecodeOutcomeErr "primary failed"))

!(assertEqual
  (codex:exec-server-rpc-decode-request-params-policy
    (JsonObject ((JsonPair "n" (JsonNumber "1"))))
    (codex:exec-server-rpc-decode-outcome-err "missing field n")
    (codex:exec-server-rpc-decode-outcome-ok "null decoded"))
  (CodexExecServerRpcErr
    (CodexExecServerRpcErrorError -32602 CodexAbsent "missing field n")))

!(assertEqual
  (codex:exec-server-rpc-router-request-route
    (codex:exec-server-rpc-router-request
      (codex:exec-server-rpc-router-new)
      "process/start"
      "handler-a")
    "process/start")
  "handler-a")

!(assertEqual
  (codex:exec-server-rpc-router-request-route
    (codex:exec-server-rpc-router-request
      (codex:exec-server-rpc-router-request
        (codex:exec-server-rpc-router-new)
        "process/start"
        "handler-a")
      "process/start"
      "handler-b")
    "process/start")
  "handler-b")

!(assertEqual
  (codex:exec-server-rpc-router-notification-route
    (codex:exec-server-rpc-router-notification
      (codex:exec-server-rpc-router-new)
      "initialized"
      "notification-handler")
    "unknown")
  CodexAbsent)
