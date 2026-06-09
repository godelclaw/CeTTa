!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:exec_server_rpc)
!(import! &self codex:exec_server_connection)

(= (test:rpc-reader-loop-two-call-state)
   (let $first
     (codex:exec-server-rpc-client-start-call
       (codex:exec-server-rpc-client-state-new)
       "slow-label")
     (let $second
       (codex:exec-server-rpc-client-start-call
         (codex:exec-server-rpc-call-start-result-state $first)
         "fast-label")
       (codex:exec-server-rpc-call-start-result-state $second))))

!(assertEqual
  (codex:exec-server-rpc-reader-step-result-client-event
    (codex:exec-server-rpc-reader-step-event
      (test:rpc-reader-loop-two-call-state)
      (codex:exec-server-json-rpc-connection-event-message
        (codex:exec-server-rpc-message-response
          (codex:exec-server-rpc-response
            (codex:exec-server-rpc-request-id-integer 2)
            (JsonString "fast"))))))
  CodexAbsent)

!(assertEqual
  (codex:exec-server-rpc-client-state-pending-count
    (codex:exec-server-rpc-reader-step-result-state
      (codex:exec-server-rpc-reader-step-event
        (test:rpc-reader-loop-two-call-state)
        (codex:exec-server-json-rpc-connection-event-message
          (codex:exec-server-rpc-message-response
            (codex:exec-server-rpc-response
              (codex:exec-server-rpc-request-id-integer 2)
              (JsonString "fast")))))))
  1)

!(assertEqual
  (codex:exec-server-rpc-reader-step-result-client-event
    (codex:exec-server-rpc-reader-step-event
      (test:rpc-reader-loop-two-call-state)
      (codex:exec-server-json-rpc-connection-event-message
        (codex:exec-server-rpc-message-notification
          (codex:exec-server-rpc-notification
            "process/output"
            (JsonObject ()))))))
  (CodexExecServerRpcClientEventNotification
    (CodexExecServerRpcNotification "process/output" (JsonObject ()))))

!(assertEqual
  (codex:exec-server-rpc-reader-step-result-client-event
    (codex:exec-server-rpc-reader-step-event
      (test:rpc-reader-loop-two-call-state)
      (codex:exec-server-json-rpc-connection-event-message
        (codex:exec-server-rpc-message-request
          (codex:exec-server-rpc-request
            (codex:exec-server-rpc-request-id-integer 9)
            "unexpected"
            CodexAbsent
            CodexAbsent)))))
  (CodexExecServerRpcClientEventDisconnected CodexAbsent))

!(assertEqual
  (codex:exec-server-rpc-reader-step-result-closed-labels
    (codex:exec-server-rpc-reader-step-event
      (test:rpc-reader-loop-two-call-state)
      (codex:exec-server-json-rpc-connection-event-message
        (codex:exec-server-rpc-message-request
          (codex:exec-server-rpc-request
            (codex:exec-server-rpc-request-id-integer 9)
            "unexpected"
            CodexAbsent
            CodexAbsent)))))
  ("slow-label" "fast-label"))

!(assertEqual
  (codex:exec-server-rpc-reader-step-result-reason
    (codex:exec-server-rpc-reader-step-event
      (test:rpc-reader-loop-two-call-state)
      (codex:exec-server-json-rpc-connection-event-message
        (codex:exec-server-rpc-message-request
          (codex:exec-server-rpc-request
            (codex:exec-server-rpc-request-id-integer 9)
            "unexpected"
            CodexAbsent
            CodexAbsent)))))
  "unexpected JSON-RPC request from remote server: unexpected")

!(assertEqual
  (codex:exec-server-rpc-reader-step-result-client-event
    (codex:exec-server-rpc-reader-step-event
      (test:rpc-reader-loop-two-call-state)
      (codex:exec-server-json-rpc-connection-event-malformed-message
        "bad json")))
  (CodexExecServerRpcClientEventDisconnected CodexAbsent))

!(assertEqual
  (codex:exec-server-rpc-reader-step-result-closed-labels
    (codex:exec-server-rpc-reader-step-event
      (test:rpc-reader-loop-two-call-state)
      (codex:exec-server-json-rpc-connection-event-malformed-message
        "bad json")))
  ("slow-label" "fast-label"))

!(assertEqual
  (codex:exec-server-rpc-reader-step-result-client-event
    (codex:exec-server-rpc-reader-step-event
      (test:rpc-reader-loop-two-call-state)
      (codex:exec-server-json-rpc-connection-event-disconnected
        "transport closed")))
  (CodexExecServerRpcClientEventDisconnected "transport closed"))

!(assertEqual
  (codex:exec-server-rpc-client-state-disconnected
    (codex:exec-server-rpc-reader-step-result-state
      (codex:exec-server-rpc-reader-step-event
        (test:rpc-reader-loop-two-call-state)
        (codex:exec-server-json-rpc-connection-event-disconnected
          "transport closed"))))
  True)

!(assertEqual
  (codex:exec-server-rpc-reader-step-result-client-event
    (codex:exec-server-rpc-reader-eof
      (test:rpc-reader-loop-two-call-state)))
  (CodexExecServerRpcClientEventDisconnected CodexAbsent))

!(assertEqual
  (codex:exec-server-rpc-reader-step-result-closed-labels
    (codex:exec-server-rpc-reader-eof
      (test:rpc-reader-loop-two-call-state)))
  ("slow-label" "fast-label"))
