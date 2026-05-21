!(register-module! ../codex)
!(import! &self codex:exec_server_rpc)
!(import! &self codex:exec_server_process_protocol)
!(import! &self codex:exec_server_http_protocol)
!(import! &self codex:exec_server_file_system_protocol)
!(import! &self codex:exec_server_handler)
!(import! &self codex:exec_server_registry)

(= (test:handler-session)
   (codex:exec-server-handler-session-handle
     "session-1"
     "connection-1"
     True))

(= (test:handler-detached-session)
   (codex:exec-server-handler-session-handle
     "session-1"
     "connection-1"
     False))

(= (test:handler-initialized-state)
   (codex:exec-server-handler-string-result-state
     (codex:exec-server-handler-initialized
       (codex:exec-server-handler-result-state
         (codex:exec-server-handler-initialize
           (codex:exec-server-handler-state-new)
           (codex:exec-server-handler-attach-ok
             (test:handler-session)))))))

(= (test:handler-http-params $request-id $stream-response)
   (codex:exec-server-http-request-params
     "GET"
     "https://example.test/"
     ()
     CodexAbsent
     CodexAbsent
     $request-id
     $stream-response))

(= (test:registry-router)
   (codex:exec-server-registry-build-router))

!(assertEqual
  (codex:exec-server-handler-state-new)
  (CodexExecServerHandlerState
    CodexAbsent
    ()
    False
    0
    False
    False))

!(assertEqual
  (codex:exec-server-handler-is-session-attached
    (codex:exec-server-handler-state-new))
  True)

!(assertEqual
  (codex:exec-server-handler-is-session-attached
    (codex:exec-server-handler-state-with-session
      (codex:exec-server-handler-state-new)
      (test:handler-detached-session)))
  False)

!(assertEqual
  (codex:exec-server-handler-require-result-error
    (codex:exec-server-handler-require-session-attached
      (codex:exec-server-handler-state-new)))
  (CodexExecServerRpcErrorError
    -32600
    CodexAbsent
    "client must call initialize before using methods"))

!(assertEqual
  (codex:exec-server-handler-require-result-error
    (codex:exec-server-handler-exec-check
      (codex:exec-server-handler-state-new)))
  (CodexExecServerRpcErrorError
    -32600
    CodexAbsent
    "client must call initialize before using exec methods"))

!(assertEqual
  (codex:exec-server-handler-string-result-message
    (codex:exec-server-handler-initialized
      (codex:exec-server-handler-state-new)))
  "received `initialized` notification before `initialize`")

!(assertEqual
  (codex:exec-server-handler-result-error
    (codex:exec-server-handler-initialize
      (codex:exec-server-handler-state-new)
      (codex:exec-server-handler-attach-err
        (codex:exec-server-rpc-invalid-request
          "unknown session id missing"))))
  (CodexExecServerRpcErrorError
    -32600
    CodexAbsent
    "unknown session id missing"))

!(assertEqual
  (codex:exec-server-handler-state-initialize-requested
    (codex:exec-server-handler-result-state
      (codex:exec-server-handler-initialize
        (codex:exec-server-handler-state-new)
        (codex:exec-server-handler-attach-err
          (codex:exec-server-rpc-invalid-request
            "unknown session id missing")))))
  False)

!(assertEqual
  (codex:exec-server-handler-result-value
    (codex:exec-server-handler-initialize
      (codex:exec-server-handler-state-new)
      (codex:exec-server-handler-attach-ok
        (test:handler-session))))
  (CodexExecServerInitializeResponse "session-1"))

!(assertEqual
  (codex:exec-server-handler-state-initialize-requested
    (codex:exec-server-handler-result-state
      (codex:exec-server-handler-initialize
        (codex:exec-server-handler-state-new)
        (codex:exec-server-handler-attach-ok
          (test:handler-session)))))
  True)

!(assertEqual
  (codex:exec-server-handler-result-error
    (codex:exec-server-handler-initialize
      (codex:exec-server-handler-result-state
        (codex:exec-server-handler-initialize
          (codex:exec-server-handler-state-new)
          (codex:exec-server-handler-attach-ok
            (test:handler-session))))
      (codex:exec-server-handler-attach-ok
        (test:handler-session))))
  (CodexExecServerRpcErrorError
    -32600
    CodexAbsent
    "initialize may only be sent once per connection"))

!(assertEqual
  (codex:exec-server-handler-string-result-state
    (codex:exec-server-handler-initialized
      (codex:exec-server-handler-result-state
        (codex:exec-server-handler-initialize
          (codex:exec-server-handler-state-new)
          (codex:exec-server-handler-attach-ok
            (test:handler-session))))))
  (CodexExecServerHandlerState
    (CodexExecServerHandlerSessionHandle
      "session-1"
      "connection-1"
      True)
    ()
    False
    0
    True
    True))

!(assertEqual
  (codex:exec-server-handler-require-result-error
    (codex:exec-server-handler-exec-check
      (codex:exec-server-handler-result-state
        (codex:exec-server-handler-initialize
          (codex:exec-server-handler-state-new)
          (codex:exec-server-handler-attach-ok
            (test:handler-session))))))
  (CodexExecServerRpcErrorError
    -32600
    CodexAbsent
    "client must send initialized before using exec methods"))

!(assertEqual
  (codex:exec-server-handler-require-result-session
    (codex:exec-server-handler-fs-check
      (test:handler-initialized-state)))
  (CodexExecServerHandlerSessionHandle
    "session-1"
    "connection-1"
    True))

!(assertEqual
  (codex:exec-server-handler-string-result-message
    (codex:exec-server-handler-initialized
      (codex:exec-server-handler-state-with-session
        (codex:exec-server-handler-state-with-initialize-requested
          (codex:exec-server-handler-state-new)
          True)
        (test:handler-detached-session))))
  "session has been resumed by another connection")

!(assertEqual
  (codex:exec-server-handler-result-error
    (codex:exec-server-handler-http-request-reserve
      (codex:exec-server-handler-state-new)
      (test:handler-http-params "body-1" True)))
  (CodexExecServerRpcErrorError
    -32600
    CodexAbsent
    "client must call initialize before using http methods"))

!(assertEqual
  (codex:exec-server-handler-state-active-body-stream-ids
    (codex:exec-server-handler-result-state
      (codex:exec-server-handler-http-request-reserve
        (test:handler-initialized-state)
        (test:handler-http-params "body-1" True))))
  ("body-1"))

!(assertEqual
  (codex:exec-server-handler-state-active-body-stream-ids
    (codex:exec-server-handler-result-state
      (codex:exec-server-handler-http-request-reserve
        (test:handler-initialized-state)
        (test:handler-http-params "body-1" False))))
  ())

!(assertEqual
  (codex:exec-server-handler-result-error
    (codex:exec-server-handler-reserve-http-body-stream
      (codex:exec-server-handler-result-state
        (codex:exec-server-handler-http-request-reserve
          (test:handler-initialized-state)
          (test:handler-http-params "body-1" True)))
      "body-1"))
  (CodexExecServerRpcErrorError
    -32602
    CodexAbsent
    "http/request streamResponse requestId `body-1` is already active"))

!(assertEqual
  (codex:exec-server-handler-state-active-body-stream-ids
    (codex:exec-server-handler-release-http-body-stream
      (codex:exec-server-handler-result-state
        (codex:exec-server-handler-http-request-reserve
          (test:handler-initialized-state)
          (test:handler-http-params "body-1" True)))
      "body-1"))
  ())

!(assertEqual
  (codex:exec-server-handler-result-value
    (codex:exec-server-handler-start-http-body-stream
      (codex:exec-server-handler-result-state
        (codex:exec-server-handler-http-request-reserve
          (test:handler-initialized-state)
          (test:handler-http-params "body-1" True)))
      (codex:exec-server-handler-pending-http-body-stream "body-1")))
  (CodexExecServerHandlerBodyStreamStarted))

!(assertEqual
  (codex:exec-server-handler-state-background-task-count
    (codex:exec-server-handler-result-state
      (codex:exec-server-handler-start-http-body-stream
        (codex:exec-server-handler-result-state
          (codex:exec-server-handler-http-request-reserve
            (test:handler-initialized-state)
            (test:handler-http-params "body-1" True)))
        (codex:exec-server-handler-pending-http-body-stream "body-1"))))
  1)

!(assertEqual
  (codex:exec-server-handler-result-value
    (codex:exec-server-handler-start-http-body-stream
      (codex:exec-server-handler-state-with-background
        (codex:exec-server-handler-result-state
          (codex:exec-server-handler-http-request-reserve
            (test:handler-initialized-state)
            (test:handler-http-params "body-1" True)))
        True
        0)
      (codex:exec-server-handler-pending-http-body-stream "body-1")))
  (CodexExecServerHandlerBodyStreamReleased))

!(assertEqual
  (codex:exec-server-handler-state-active-body-stream-ids
    (codex:exec-server-handler-result-state
      (codex:exec-server-handler-start-http-body-stream
        (codex:exec-server-handler-state-with-background
          (codex:exec-server-handler-result-state
            (codex:exec-server-handler-http-request-reserve
              (test:handler-initialized-state)
              (test:handler-http-params "body-1" True)))
          True
          0)
        (codex:exec-server-handler-pending-http-body-stream "body-1"))))
  ())

!(assertEqual
  (codex:exec-server-handler-state-session
    (codex:exec-server-handler-shutdown
      (test:handler-initialized-state)))
  (CodexExecServerHandlerSessionHandle
    "session-1"
    "connection-1"
    False))

!(assertEqual
  (codex:exec-server-handler-state-background-task-shutdown-cancelled
    (codex:exec-server-handler-shutdown
      (test:handler-initialized-state)))
  True)

!(assertEqual
  (codex:exec-server-rpc-router-notification-route
    (test:registry-router)
    (codex:exec-server-protocol-initialized-method))
  (CodexExecServerRegistryHandlerInitialized))

!(assertEqual
  (codex:exec-server-rpc-router-request-route
    (test:registry-router)
    (codex:exec-server-protocol-initialize-method))
  (CodexExecServerRegistryHandlerInitialize))

!(assertEqual
  (codex:exec-server-rpc-router-request-route
    (test:registry-router)
    (codex:exec-server-http-request-method))
  (CodexExecServerRegistryHandlerHttpRequestWithId))

!(assertEqual
  (codex:exec-server-rpc-router-request-route
    (test:registry-router)
    (codex:exec-server-protocol-exec-method))
  (CodexExecServerRegistryHandlerExec))

!(assertEqual
  (codex:exec-server-rpc-router-request-route
    (test:registry-router)
    (codex:exec-server-protocol-exec-read-method))
  (CodexExecServerRegistryHandlerExecRead))

!(assertEqual
  (codex:exec-server-rpc-router-request-route
    (test:registry-router)
    (codex:exec-server-protocol-exec-write-method))
  (CodexExecServerRegistryHandlerExecWrite))

!(assertEqual
  (codex:exec-server-rpc-router-request-route
    (test:registry-router)
    (codex:exec-server-protocol-exec-terminate-method))
  (CodexExecServerRegistryHandlerExecTerminate))

!(assertEqual
  (codex:exec-server-rpc-router-request-route
    (test:registry-router)
    (codex:exec-server-fs-read-file-method))
  (CodexExecServerRegistryHandlerFsReadFile))

!(assertEqual
  (codex:exec-server-rpc-router-request-route
    (test:registry-router)
    (codex:exec-server-fs-write-file-method))
  (CodexExecServerRegistryHandlerFsWriteFile))

!(assertEqual
  (codex:exec-server-rpc-router-request-route
    (test:registry-router)
    (codex:exec-server-fs-create-directory-method))
  (CodexExecServerRegistryHandlerFsCreateDirectory))

!(assertEqual
  (codex:exec-server-rpc-router-request-route
    (test:registry-router)
    (codex:exec-server-fs-get-metadata-method))
  (CodexExecServerRegistryHandlerFsGetMetadata))

!(assertEqual
  (codex:exec-server-rpc-router-request-route
    (test:registry-router)
    (codex:exec-server-fs-read-directory-method))
  (CodexExecServerRegistryHandlerFsReadDirectory))

!(assertEqual
  (codex:exec-server-rpc-router-request-route
    (test:registry-router)
    (codex:exec-server-fs-remove-method))
  (CodexExecServerRegistryHandlerFsRemove))

!(assertEqual
  (codex:exec-server-rpc-router-request-route
    (test:registry-router)
    (codex:exec-server-fs-copy-method))
  (CodexExecServerRegistryHandlerFsCopy))

!(assertEqual
  (codex:exec-server-rpc-router-request-route
    (test:registry-router)
    "missing")
  CodexAbsent)
