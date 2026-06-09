!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:exec_server_rpc)

(= (test:rpc-client-call-flow-send-ok)
   (codex:exec-server-rpc-client-send-ok))

(= (test:rpc-client-call-flow-send-closed)
   (codex:exec-server-rpc-client-send-closed))

(= (test:rpc-client-call-flow-params)
   (JsonObject
     ((JsonPair "path" (JsonString "/repo/file.txt")))))

!(assertEqual
  (codex:exec-server-rpc-client-notify-flow
    "initialized"
    (codex:exec-server-rpc-serialize-outcome-ok JsonNull)
    (test:rpc-client-call-flow-send-ok))
  (CodexExecServerRpcClientNotifyResultOk
    (CodexExecServerRpcMessageNotification
      (CodexExecServerRpcNotification "initialized" JsonNull))))

!(assertEqual
  (codex:exec-server-rpc-client-notify-result-message
    (codex:exec-server-rpc-client-notify-flow
      "initialized"
      (codex:exec-server-rpc-serialize-outcome-err
        "params serialize failed")
      (test:rpc-client-call-flow-send-ok)))
  "params serialize failed")

!(assertEqual
  (codex:exec-server-rpc-client-notify-result-message
    (codex:exec-server-rpc-client-notify-flow
      "initialized"
      (codex:exec-server-rpc-serialize-outcome-ok JsonNull)
      (test:rpc-client-call-flow-send-closed)))
  "JSON-RPC transport closed")

!(assertEqual
  (codex:exec-server-rpc-client-call-dispatch-result-error
    (codex:exec-server-rpc-client-call-dispatch
      (codex:exec-server-rpc-client-state-with-disconnected
        (codex:exec-server-rpc-client-state-new)
        True)
      "fs/readFile"
      "read-label"
      (codex:exec-server-rpc-serialize-outcome-ok
        (test:rpc-client-call-flow-params))
      (test:rpc-client-call-flow-send-ok)))
  (CodexExecServerRpcCallErrorClosed))

!(assertEqual
  (codex:exec-server-rpc-client-state-next-request-id
    (codex:exec-server-rpc-client-call-dispatch-result-state
      (codex:exec-server-rpc-client-call-dispatch
        (codex:exec-server-rpc-client-state-with-disconnected
          (codex:exec-server-rpc-client-state-new)
          True)
        "fs/readFile"
        "read-label"
        (codex:exec-server-rpc-serialize-outcome-ok
          (test:rpc-client-call-flow-params))
        (test:rpc-client-call-flow-send-ok))))
  2)

!(assertEqual
  (codex:exec-server-rpc-client-state-pending-count
    (codex:exec-server-rpc-client-call-dispatch-result-state
      (codex:exec-server-rpc-client-call-dispatch
        (codex:exec-server-rpc-client-state-new)
        "fs/readFile"
        "read-label"
        (codex:exec-server-rpc-serialize-outcome-err
          "params serialize failed")
        (test:rpc-client-call-flow-send-ok))))
  0)

!(assertEqual
  (codex:exec-server-rpc-client-call-dispatch-result-error
    (codex:exec-server-rpc-client-call-dispatch
      (codex:exec-server-rpc-client-state-new)
      "fs/readFile"
      "read-label"
      (codex:exec-server-rpc-serialize-outcome-err
        "params serialize failed")
      (test:rpc-client-call-flow-send-ok)))
  (CodexExecServerRpcCallErrorJson "params serialize failed"))

!(assertEqual
  (codex:exec-server-rpc-client-state-pending-count
    (codex:exec-server-rpc-client-call-dispatch-result-state
      (codex:exec-server-rpc-client-call-dispatch
        (codex:exec-server-rpc-client-state-new)
        "fs/readFile"
        "read-label"
        (codex:exec-server-rpc-serialize-outcome-ok
          (test:rpc-client-call-flow-params))
        (test:rpc-client-call-flow-send-closed))))
  0)

!(assertEqual
  (codex:exec-server-rpc-client-call-dispatch-result-error
    (codex:exec-server-rpc-client-call-dispatch
      (codex:exec-server-rpc-client-state-new)
      "fs/readFile"
      "read-label"
      (codex:exec-server-rpc-serialize-outcome-ok
        (test:rpc-client-call-flow-params))
      (test:rpc-client-call-flow-send-closed)))
  (CodexExecServerRpcCallErrorClosed))

!(assertEqual
  (codex:exec-server-rpc-client-call-dispatch-result-message
    (codex:exec-server-rpc-client-call-dispatch
      (codex:exec-server-rpc-client-state-new)
      "fs/readFile"
      "read-label"
      (codex:exec-server-rpc-serialize-outcome-ok
        (test:rpc-client-call-flow-params))
      (test:rpc-client-call-flow-send-ok)))
  (CodexExecServerRpcMessageRequest
    (CodexExecServerRpcRequest
      (CodexExecServerRpcRequestIdInteger 1)
      "fs/readFile"
      (JsonObject
        ((JsonPair "path" (JsonString "/repo/file.txt"))))
      CodexAbsent)))

!(assertEqual
  (codex:exec-server-rpc-client-state-pending-count
    (codex:exec-server-rpc-client-call-dispatch-result-state
      (codex:exec-server-rpc-client-call-dispatch
        (codex:exec-server-rpc-client-state-new)
        "fs/readFile"
        "read-label"
        (codex:exec-server-rpc-serialize-outcome-ok
          (test:rpc-client-call-flow-params))
        (test:rpc-client-call-flow-send-ok))))
  1)

!(assertEqual
  (codex:exec-server-rpc-client-call-finish
    (codex:exec-server-rpc-err
      (codex:exec-server-rpc-call-error-server
        (codex:exec-server-rpc-internal-error "server failed")))
    (codex:exec-server-rpc-decode-outcome-ok (CodexIgnored)))
  (CodexExecServerRpcClientCallFinishErr
    (CodexExecServerRpcCallErrorServer
      (CodexExecServerRpcErrorError
        -32603
        CodexAbsent
        "server failed"))))

!(assertEqual
  (codex:exec-server-rpc-client-call-finish
    (codex:exec-server-rpc-ok (JsonObject ()))
    (codex:exec-server-rpc-decode-outcome-err
      "response decode failed"))
  (CodexExecServerRpcClientCallFinishErr
    (CodexExecServerRpcCallErrorJson
      "response decode failed")))

!(assertEqual
  (codex:exec-server-rpc-client-call-finish
    (codex:exec-server-rpc-ok
      (JsonObject ((JsonPair "ok" (JsonBool True)))))
    (codex:exec-server-rpc-decode-outcome-ok
      (CodexDecodedResponse True)))
  (CodexExecServerRpcClientCallFinishOk
    (CodexDecodedResponse True)))
