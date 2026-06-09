!(register-module! ../codex)
!(import! &self codex:exec_server_rpc)
!(import! &self codex:exec_server_handler)

(= (test:handler-process-flow-session)
   (codex:exec-server-handler-session-handle
     "session-1"
     "connection-1"
     True))

(= (test:handler-process-flow-detached-session)
   (codex:exec-server-handler-session-handle
     "session-1"
     "connection-1"
     False))

(= (test:handler-process-flow-initialized-state)
   (codex:exec-server-handler-string-result-state
     (codex:exec-server-handler-initialized
       (codex:exec-server-handler-result-state
         (codex:exec-server-handler-initialize
           (codex:exec-server-handler-state-new)
           (codex:exec-server-handler-attach-ok
             (test:handler-process-flow-session)))))))

(= (test:handler-process-flow-post-detached-state)
   (codex:exec-server-handler-state-with-session
     (test:handler-process-flow-initialized-state)
     (test:handler-process-flow-detached-session)))

!(assertEqual
  (codex:exec-server-handler-result-error
    (codex:exec-server-handler-exec-flow
      (codex:exec-server-handler-state-new)
      (codex:exec-server-handler-process-ok
        (CodexTestExecResponse))))
  (CodexExecServerRpcErrorError
    -32600
    CodexAbsent
    "client must call initialize before using exec methods"))

!(assertEqual
  (codex:exec-server-handler-result-value
    (codex:exec-server-handler-exec-flow
      (test:handler-process-flow-initialized-state)
      (codex:exec-server-handler-process-ok
        (CodexTestExecResponse))))
  (CodexTestExecResponse))

!(assertEqual
  (codex:exec-server-handler-result-error
    (codex:exec-server-handler-exec-write-flow
      (test:handler-process-flow-initialized-state)
      (codex:exec-server-handler-process-err
        (codex:exec-server-rpc-internal-error
          "process/write failed"))))
  (CodexExecServerRpcErrorError
    -32603
    CodexAbsent
    "process/write failed"))

!(assertEqual
  (codex:exec-server-handler-result-value
    (codex:exec-server-handler-terminate-flow
      (test:handler-process-flow-initialized-state)
      (codex:exec-server-handler-process-ok
        (CodexTestTerminateResponse False))))
  (CodexTestTerminateResponse False))

!(assertEqual
  (codex:exec-server-handler-result-value
    (codex:exec-server-handler-exec-read-flow
      (test:handler-process-flow-initialized-state)
      (codex:exec-server-handler-process-ok
        (CodexTestReadResponse))
      (test:handler-process-flow-initialized-state)))
  (CodexTestReadResponse))

!(assertEqual
  (codex:exec-server-handler-result-error
    (codex:exec-server-handler-exec-read-flow
      (test:handler-process-flow-initialized-state)
      (codex:exec-server-handler-process-ok
        (CodexTestReadResponse))
      (test:handler-process-flow-post-detached-state)))
  (CodexExecServerRpcErrorError
    -32600
    CodexAbsent
    "session has been resumed by another connection"))

!(assertEqual
  (codex:exec-server-handler-result-state
    (codex:exec-server-handler-exec-read-flow
      (test:handler-process-flow-initialized-state)
      (codex:exec-server-handler-process-ok
        (CodexTestReadResponse))
      (test:handler-process-flow-post-detached-state)))
  (test:handler-process-flow-post-detached-state))

!(assertEqual
  (codex:exec-server-handler-result-error
    (codex:exec-server-handler-exec-read-flow
      (test:handler-process-flow-initialized-state)
      (codex:exec-server-handler-process-err
        (codex:exec-server-rpc-internal-error
          "process/read failed"))
      (test:handler-process-flow-post-detached-state)))
  (CodexExecServerRpcErrorError
    -32603
    CodexAbsent
    "process/read failed"))
