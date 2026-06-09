!(register-module! ../codex)
!(import! &self codex:exec_server_rpc)
!(import! &self codex:exec_server_file_system_handler)
!(import! &self codex:exec_server_handler)

(= (test:handler-fs-flow-session)
   (codex:exec-server-handler-session-handle
     "session-1"
     "connection-1"
     True))

(= (test:handler-fs-flow-initialize-only-state)
   (codex:exec-server-handler-result-state
     (codex:exec-server-handler-initialize
       (codex:exec-server-handler-state-new)
       (codex:exec-server-handler-attach-ok
         (test:handler-fs-flow-session)))))

(= (test:handler-fs-flow-initialized-state)
   (codex:exec-server-handler-string-result-state
     (codex:exec-server-handler-initialized
       (test:handler-fs-flow-initialize-only-state))))

(= (test:handler-fs-flow-ok $response)
   (codex:exec-server-fs-handler-result-ok $response))

(= (test:handler-fs-flow-err $message)
   (codex:exec-server-fs-handler-result-err
     (codex:exec-server-rpc-internal-error $message)))

!(assertEqual
  (codex:exec-server-handler-result-error
    (codex:exec-server-handler-fs-read-file-flow
      (codex:exec-server-handler-state-new)
      (test:handler-fs-flow-ok
        (CodexTestFsReadFileResponse))))
  (CodexExecServerRpcErrorError
    -32600
    CodexAbsent
    "client must call initialize before using filesystem methods"))

!(assertEqual
  (codex:exec-server-handler-result-error
    (codex:exec-server-handler-fs-read-file-flow
      (test:handler-fs-flow-initialize-only-state)
      (test:handler-fs-flow-ok
        (CodexTestFsReadFileResponse))))
  (CodexExecServerRpcErrorError
    -32600
    CodexAbsent
    "client must send initialized before using filesystem methods"))

!(assertEqual
  (codex:exec-server-handler-result-value
    (codex:exec-server-handler-fs-read-file-flow
      (test:handler-fs-flow-initialized-state)
      (test:handler-fs-flow-ok
        (CodexTestFsReadFileResponse))))
  (CodexTestFsReadFileResponse))

!(assertEqual
  (codex:exec-server-handler-result-error
    (codex:exec-server-handler-fs-write-file-flow
      (test:handler-fs-flow-initialized-state)
      (test:handler-fs-flow-err
        "fs/writeFile failed")))
  (CodexExecServerRpcErrorError
    -32603
    CodexAbsent
    "fs/writeFile failed"))

!(assertEqual
  (codex:exec-server-handler-result-value
    (codex:exec-server-handler-fs-create-directory-flow
      (test:handler-fs-flow-initialized-state)
      (test:handler-fs-flow-ok
        (CodexTestFsCreateDirectoryResponse))))
  (CodexTestFsCreateDirectoryResponse))

!(assertEqual
  (codex:exec-server-handler-result-value
    (codex:exec-server-handler-fs-get-metadata-flow
      (test:handler-fs-flow-initialized-state)
      (test:handler-fs-flow-ok
        (CodexTestFsGetMetadataResponse))))
  (CodexTestFsGetMetadataResponse))

!(assertEqual
  (codex:exec-server-handler-result-value
    (codex:exec-server-handler-fs-read-directory-flow
      (test:handler-fs-flow-initialized-state)
      (test:handler-fs-flow-ok
        (CodexTestFsReadDirectoryResponse))))
  (CodexTestFsReadDirectoryResponse))

!(assertEqual
  (codex:exec-server-handler-result-value
    (codex:exec-server-handler-fs-remove-flow
      (test:handler-fs-flow-initialized-state)
      (test:handler-fs-flow-ok
        (CodexTestFsRemoveResponse))))
  (CodexTestFsRemoveResponse))

!(assertEqual
  (codex:exec-server-handler-result-value
    (codex:exec-server-handler-fs-copy-flow
      (test:handler-fs-flow-initialized-state)
      (test:handler-fs-flow-ok
        (CodexTestFsCopyResponse))))
  (CodexTestFsCopyResponse))
