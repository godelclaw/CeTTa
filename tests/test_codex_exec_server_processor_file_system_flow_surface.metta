!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:exec_server_rpc)
!(import! &self codex:exec_server_file_system_handler)
!(import! &self codex:exec_server_file_system_protocol)
!(import! &self codex:exec_server_handler)
!(import! &self codex:exec_server_processor)

(= (test:processor-fs-flow-session)
   (codex:exec-server-handler-session-handle
     "session-1"
     "connection-1"
     True))

(= (test:processor-fs-flow-handler-state)
   (codex:exec-server-handler-string-result-state
     (codex:exec-server-handler-initialized
       (codex:exec-server-handler-result-state
         (codex:exec-server-handler-initialize
           (codex:exec-server-handler-state-new)
           (codex:exec-server-handler-attach-ok
             (test:processor-fs-flow-session)))))))

(= (test:processor-fs-flow-state)
   (codex:exec-server-processor-runtime-state-with-handler
     (codex:exec-server-processor-runtime-state-new)
     (test:processor-fs-flow-handler-state)))

(= (test:processor-fs-flow-request-id $id)
   (codex:exec-server-rpc-request-id-integer $id))

(= (test:processor-fs-flow-ok $response)
   (codex:exec-server-fs-handler-result-ok $response))

(= (test:processor-fs-flow-err $message)
   (codex:exec-server-fs-handler-result-err
     (codex:exec-server-rpc-internal-error $message)))

!(assertEqual
  (codex:exec-server-processor-step-result-outbound
    (codex:exec-server-processor-handle-fs-read-file-route-flow
      (codex:exec-server-processor-runtime-state-new)
      (test:processor-fs-flow-request-id 41)
      (test:processor-fs-flow-ok
        (codex:exec-server-fs-read-file-response "aGk="))
      (codex:exec-server-processor-send-outcome-ok)))
  ((CodexExecServerRpcServerOutboundError
     (CodexExecServerRpcRequestIdInteger 41)
     (CodexExecServerRpcErrorError
       -32600
       CodexAbsent
       "client must call initialize before using filesystem methods"))))

!(assertEqual
  (codex:exec-server-processor-step-result-outbound
    (codex:exec-server-processor-handle-fs-read-file-route-flow
      (test:processor-fs-flow-state)
      (test:processor-fs-flow-request-id 42)
      (test:processor-fs-flow-ok
        (codex:exec-server-fs-read-file-response "aGk="))
      (codex:exec-server-processor-send-outcome-ok)))
  ((CodexExecServerRpcServerOutboundResponse
     (CodexExecServerRpcRequestIdInteger 42)
     (JsonObject
       ((JsonPair "dataBase64" (JsonString "aGk=")))))))

!(assertEqual
  (codex:exec-server-processor-step-result-outbound
    (codex:exec-server-processor-handle-fs-write-file-route-flow
      (test:processor-fs-flow-state)
      (test:processor-fs-flow-request-id 43)
      (test:processor-fs-flow-err "fs/writeFile failed")
      (codex:exec-server-processor-send-outcome-ok)))
  ((CodexExecServerRpcServerOutboundError
     (CodexExecServerRpcRequestIdInteger 43)
     (CodexExecServerRpcErrorError
       -32603
       CodexAbsent
       "fs/writeFile failed"))))

!(assertEqual
  (codex:exec-server-processor-step-result-outbound
    (codex:exec-server-processor-handle-fs-write-file-route-flow
      (test:processor-fs-flow-state)
      (test:processor-fs-flow-request-id 44)
      (test:processor-fs-flow-ok
        (codex:exec-server-fs-write-file-response))
      (codex:exec-server-processor-send-outcome-ok)))
  ((CodexExecServerRpcServerOutboundResponse
     (CodexExecServerRpcRequestIdInteger 44)
     (JsonObject ()))))

!(assertEqual
  (codex:exec-server-processor-step-result-outbound
    (codex:exec-server-processor-handle-fs-create-directory-route-flow
      (test:processor-fs-flow-state)
      (test:processor-fs-flow-request-id 45)
      (test:processor-fs-flow-ok
        (codex:exec-server-fs-create-directory-response))
      (codex:exec-server-processor-send-outcome-ok)))
  ((CodexExecServerRpcServerOutboundResponse
     (CodexExecServerRpcRequestIdInteger 45)
     (JsonObject ()))))

!(assertEqual
  (codex:exec-server-processor-step-result-outbound
    (codex:exec-server-processor-handle-fs-get-metadata-route-flow
      (test:processor-fs-flow-state)
      (test:processor-fs-flow-request-id 46)
      (test:processor-fs-flow-ok
        (codex:exec-server-fs-get-metadata-response
          False
          True
          False
          100
          200))
      (codex:exec-server-processor-send-outcome-ok)))
  ((CodexExecServerRpcServerOutboundResponse
     (CodexExecServerRpcRequestIdInteger 46)
     (JsonObject
       ((JsonPair "isDirectory" (JsonBool False))
        (JsonPair "isFile" (JsonBool True))
        (JsonPair "isSymlink" (JsonBool False))
        (JsonPair "createdAtMs" (JsonNumber "100"))
        (JsonPair "modifiedAtMs" (JsonNumber "200")))))))

!(assertEqual
  (codex:exec-server-processor-step-result-outbound
    (codex:exec-server-processor-handle-fs-read-directory-route-flow
      (test:processor-fs-flow-state)
      (test:processor-fs-flow-request-id 47)
      (test:processor-fs-flow-ok
        (codex:exec-server-fs-read-directory-response
          ((codex:exec-server-fs-read-directory-entry
             "src"
             True
             False)
           (codex:exec-server-fs-read-directory-entry
             "README.md"
             False
             True))))
      (codex:exec-server-processor-send-outcome-ok)))
  ((CodexExecServerRpcServerOutboundResponse
     (CodexExecServerRpcRequestIdInteger 47)
     (JsonObject
       ((JsonPair
          "entries"
          (JsonArray
            ((JsonObject
               ((JsonPair "fileName" (JsonString "src"))
                (JsonPair "isDirectory" (JsonBool True))
                (JsonPair "isFile" (JsonBool False))))
             (JsonObject
               ((JsonPair "fileName" (JsonString "README.md"))
                (JsonPair "isDirectory" (JsonBool False))
                (JsonPair "isFile" (JsonBool True))))))))))))

!(assertEqual
  (codex:exec-server-processor-step-result-outbound
    (codex:exec-server-processor-handle-fs-remove-route-flow
      (test:processor-fs-flow-state)
      (test:processor-fs-flow-request-id 48)
      (test:processor-fs-flow-ok
        (codex:exec-server-fs-remove-response))
      (codex:exec-server-processor-send-outcome-ok)))
  ((CodexExecServerRpcServerOutboundResponse
     (CodexExecServerRpcRequestIdInteger 48)
     (JsonObject ()))))

!(assertEqual
  (codex:exec-server-processor-step-result-outbound
    (codex:exec-server-processor-handle-fs-copy-route-flow
      (test:processor-fs-flow-state)
      (test:processor-fs-flow-request-id 49)
      (test:processor-fs-flow-ok
        (codex:exec-server-fs-copy-response))
      (codex:exec-server-processor-send-outcome-ok)))
  ((CodexExecServerRpcServerOutboundResponse
     (CodexExecServerRpcRequestIdInteger 49)
     (JsonObject ()))))
