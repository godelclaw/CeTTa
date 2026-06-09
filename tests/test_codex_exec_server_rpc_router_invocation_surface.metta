!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:exec_server_rpc)

(= (test:rpc-router-invoke-request $id $method $params)
   (codex:exec-server-rpc-request
     (codex:exec-server-rpc-request-id-integer $id)
     $method
     $params
     CodexAbsent))

(= (test:rpc-router-invoke-request-id $id)
   (codex:exec-server-rpc-request-id-integer $id))

!(assertEqual
  (codex:exec-server-rpc-router-request-invoke
    (test:rpc-router-invoke-request 61 "process/start" (JsonObject ()))
    (codex:exec-server-rpc-decode-request-params-policy
      (JsonObject ())
      (codex:exec-server-rpc-decode-outcome-err "missing command")
      (codex:exec-server-rpc-decode-outcome-err "null failed"))
    (codex:exec-server-rpc-ok (CodexIgnoredHandlerResult))
    (codex:exec-server-rpc-serialize-outcome-ok
      (JsonObject ())))
  (CodexExecServerRpcRequestRouteResultSome
    (CodexExecServerRpcServerOutboundError
      (CodexExecServerRpcRequestIdInteger 61)
      (CodexExecServerRpcErrorError
        -32602
        CodexAbsent
        "missing command"))))

!(assertEqual
  (codex:exec-server-rpc-router-request-invoke
    (test:rpc-router-invoke-request 62 "process/start" (JsonObject ()))
    (codex:exec-server-rpc-ok (CodexDecodedParams))
    (codex:exec-server-rpc-err
      (codex:exec-server-rpc-internal-error
        "handler failed"))
    (codex:exec-server-rpc-serialize-outcome-ok
      (JsonObject ())))
  (CodexExecServerRpcRequestRouteResultSome
    (CodexExecServerRpcServerOutboundError
      (CodexExecServerRpcRequestIdInteger 62)
      (CodexExecServerRpcErrorError
        -32603
        CodexAbsent
        "handler failed"))))

!(assertEqual
  (codex:exec-server-rpc-router-request-invoke
    (test:rpc-router-invoke-request 63 "process/start" (JsonObject ()))
    (codex:exec-server-rpc-ok (CodexDecodedParams))
    (codex:exec-server-rpc-ok (CodexHandlerValue))
    (codex:exec-server-rpc-serialize-outcome-err
      "serialize failed"))
  (CodexExecServerRpcRequestRouteResultSome
    (CodexExecServerRpcServerOutboundError
      (CodexExecServerRpcRequestIdInteger 63)
      (CodexExecServerRpcErrorError
        -32603
        CodexAbsent
        "serialize failed"))))

!(assertEqual
  (codex:exec-server-rpc-router-request-invoke
    (test:rpc-router-invoke-request 64 "process/start" (JsonObject ()))
    (codex:exec-server-rpc-ok (CodexDecodedParams))
    (codex:exec-server-rpc-ok (CodexHandlerValue))
    (codex:exec-server-rpc-serialize-outcome-ok
      (JsonObject
        ((JsonPair "processId" (JsonString "proc-1"))))))
  (CodexExecServerRpcRequestRouteResultSome
    (CodexExecServerRpcServerOutboundResponse
      (CodexExecServerRpcRequestIdInteger 64)
      (JsonObject
        ((JsonPair "processId" (JsonString "proc-1")))))))

!(assertEqual
  (codex:exec-server-rpc-router-request-with-id-invoke
    (test:rpc-router-invoke-request 65 "http/request" (JsonObject ()))
    (codex:exec-server-rpc-decode-request-params-policy
      (JsonObject ())
      (codex:exec-server-rpc-decode-outcome-err "missing url")
      (codex:exec-server-rpc-decode-outcome-err "null failed"))
    (codex:exec-server-rpc-ok ()))
  (CodexExecServerRpcRequestRouteResultSome
    (CodexExecServerRpcServerOutboundError
      (CodexExecServerRpcRequestIdInteger 65)
      (CodexExecServerRpcErrorError -32602 CodexAbsent "missing url"))))

!(assertEqual
  (codex:exec-server-rpc-router-request-with-id-invoke
    (test:rpc-router-invoke-request 66 "http/request" (JsonObject ()))
    (codex:exec-server-rpc-ok (CodexDecodedParams))
    (codex:exec-server-rpc-err
      (codex:exec-server-rpc-internal-error
        "http failed")))
  (CodexExecServerRpcRequestRouteResultSome
    (CodexExecServerRpcServerOutboundError
      (CodexExecServerRpcRequestIdInteger 66)
      (CodexExecServerRpcErrorError -32603 CodexAbsent "http failed"))))

!(assertEqual
  (codex:exec-server-rpc-router-request-with-id-invoke
    (test:rpc-router-invoke-request 67 "http/request" (JsonObject ()))
    (codex:exec-server-rpc-ok (CodexDecodedParams))
    (codex:exec-server-rpc-ok ()))
  (CodexExecServerRpcRequestRouteResultNone))

!(assertEqual
  (codex:exec-server-rpc-router-notification-invoke
    (codex:exec-server-rpc-notification
      "initialized"
      (JsonObject ()))
    (codex:exec-server-rpc-decode-notification-params-policy
      (JsonObject ())
      (codex:exec-server-rpc-decode-outcome-err
        "expected null")
      (codex:exec-server-rpc-decode-outcome-err
        "null failed"))
    (codex:exec-server-rpc-notification-handler-ok))
  (CodexExecServerRpcNotificationRouteResultErr "expected null"))

!(assertEqual
  (codex:exec-server-rpc-router-notification-invoke
    (codex:exec-server-rpc-notification
      "initialized"
      CodexAbsent)
    (codex:exec-server-rpc-decode-outcome-ok ())
    (codex:exec-server-rpc-notification-handler-err
      "initialized before initialize"))
  (CodexExecServerRpcNotificationRouteResultErr
    "initialized before initialize"))

!(assertEqual
  (codex:exec-server-rpc-router-notification-invoke
    (codex:exec-server-rpc-notification
      "initialized"
      CodexAbsent)
    (codex:exec-server-rpc-decode-outcome-ok ())
    (codex:exec-server-rpc-notification-handler-ok))
  (CodexExecServerRpcNotificationRouteResultOk))
