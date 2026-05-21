!(register-module! ../codex)
!(import! &self codex:exec_server_rpc)
!(import! &self codex:exec_server_file_system_protocol)
!(import! &self codex:exec_server_file_system_handler)

(= (test:fs-handler)
   (codex:exec-server-fs-handler-new
     (CodexRuntimePaths "root")))

(= (test:fs-error $kind $message)
   (codex:exec-server-fs-handler-file-system-error $kind $message))

!(assertEqual
  (codex:exec-server-fs-handler-local-file-system-runtime-paths
    (codex:exec-server-fs-handler-file-system
      (test:fs-handler)))
  (CodexRuntimePaths "root"))

!(assertEqual
  (codex:exec-server-fs-handler-map-fs-error
    (test:fs-error
      (codex:exec-server-fs-handler-error-kind-not-found)
      "missing"))
  (CodexExecServerRpcErrorError -32004 CodexAbsent "missing"))

!(assertEqual
  (codex:exec-server-fs-handler-map-fs-error
    (test:fs-error
      (codex:exec-server-fs-handler-error-kind-invalid-input)
      "bad path"))
  (CodexExecServerRpcErrorError -32600 CodexAbsent "bad path"))

!(assertEqual
  (codex:exec-server-fs-handler-map-fs-error
    (test:fs-error
      (codex:exec-server-fs-handler-error-kind-permission-denied)
      "permission denied"))
  (CodexExecServerRpcErrorError -32600 CodexAbsent "permission denied"))

!(assertEqual
  (codex:exec-server-fs-handler-map-fs-error
    (test:fs-error
      (codex:exec-server-fs-handler-error-kind-other)
      "disk error"))
  (CodexExecServerRpcErrorError -32603 CodexAbsent "disk error"))

!(assertEqual
  (codex:exec-server-fs-read-file-response-data-base64
    (codex:exec-server-fs-handler-result-value
      (codex:exec-server-fs-handler-read-file
        (test:fs-handler)
        (codex:exec-server-fs-read-file-params
          "/repo/file.txt"
          CodexAbsent)
        (codex:exec-server-fs-handler-operation-read-file-ok
          "hello"))))
  "aGVsbG8=")

!(assertEqual
  (codex:exec-server-fs-handler-result-error
    (codex:exec-server-fs-handler-read-file
      (test:fs-handler)
      (codex:exec-server-fs-read-file-params "/repo/missing" CodexAbsent)
      (codex:exec-server-fs-handler-operation-err
        (test:fs-error
          (codex:exec-server-fs-handler-error-kind-not-found)
          "No such file or directory"))))
  (CodexExecServerRpcErrorError
    -32004
    CodexAbsent
    "No such file or directory"))

!(assertEqual
  (codex:exec-server-fs-handler-result-error
    (codex:exec-server-fs-handler-write-file
      (test:fs-handler)
      (codex:exec-server-fs-write-file-params
        "/repo/file.txt"
        "!bad"
        CodexAbsent)
      (codex:exec-server-fs-handler-base64-decode-err
        "Invalid byte 33, offset 0.")
      (codex:exec-server-fs-handler-operation-write-file-ok)))
  (CodexExecServerRpcErrorError
    -32600
    CodexAbsent
    "fs/writeFile requires valid base64 dataBase64: Invalid byte 33, offset 0."))

!(assertEqual
  (codex:exec-server-fs-handler-write-file
    (test:fs-handler)
    (codex:exec-server-fs-write-file-params
      "/repo/file.txt"
      "aGk="
      CodexAbsent)
    (codex:exec-server-fs-handler-base64-decode-ok "hi")
    (codex:exec-server-fs-handler-operation-write-file-ok))
  (CodexExecServerFsHandlerResultOk
    (CodexExecServerFsWriteFileResponse)))

!(assertEqual
  (codex:exec-server-fs-handler-result-error
    (codex:exec-server-fs-handler-write-file
      (test:fs-handler)
      (codex:exec-server-fs-write-file-params
        "/repo/file.txt"
        "aGk="
        CodexAbsent)
      (codex:exec-server-fs-handler-base64-decode-ok "hi")
      (codex:exec-server-fs-handler-operation-err
        (test:fs-error
          (codex:exec-server-fs-handler-error-kind-permission-denied)
          "blocked"))))
  (CodexExecServerRpcErrorError -32600 CodexAbsent "blocked"))

!(assertEqual
  (codex:exec-server-create-directory-options-recursive
    (codex:exec-server-fs-handler-create-directory-options-from-params
      (codex:exec-server-fs-create-directory-params
        "/repo/new"
        CodexAbsent
        CodexAbsent)))
  True)

!(assertEqual
  (codex:exec-server-create-directory-options-recursive
    (codex:exec-server-fs-handler-create-directory-options-from-params
      (codex:exec-server-fs-create-directory-params
        "/repo/new"
        False
        CodexAbsent)))
  False)

!(assertEqual
  (codex:exec-server-fs-handler-create-directory
    (test:fs-handler)
    (codex:exec-server-fs-create-directory-params
      "/repo/new"
      CodexAbsent
      CodexAbsent)
    (codex:exec-server-fs-handler-operation-create-directory-ok))
  (CodexExecServerFsHandlerResultOk
    (CodexExecServerFsCreateDirectoryResponse)))

!(assertEqual
  (codex:exec-server-fs-handler-result-error
    (codex:exec-server-fs-handler-create-directory
      (test:fs-handler)
      (codex:exec-server-fs-create-directory-params
        "/repo/new"
        True
        CodexAbsent)
      (codex:exec-server-fs-handler-operation-err
        (test:fs-error
          (codex:exec-server-fs-handler-error-kind-invalid-input)
          "not a directory"))))
  (CodexExecServerRpcErrorError -32600 CodexAbsent "not a directory"))

!(assertEqual
  (codex:exec-server-fs-handler-result-value
    (codex:exec-server-fs-handler-get-metadata
      (test:fs-handler)
      (codex:exec-server-fs-get-metadata-params "/repo/file.txt" CodexAbsent)
      (codex:exec-server-fs-handler-operation-get-metadata-ok
        (codex:exec-server-file-metadata
          False
          True
          False
          100
          200))))
  (CodexExecServerFsGetMetadataResponse
    False
    True
    False
    100
    200))

!(assertEqual
  (codex:exec-server-fs-handler-result-error
    (codex:exec-server-fs-handler-get-metadata
      (test:fs-handler)
      (codex:exec-server-fs-get-metadata-params "/repo/file.txt" CodexAbsent)
      (codex:exec-server-fs-handler-operation-err
        (test:fs-error
          (codex:exec-server-fs-handler-error-kind-other)
          "metadata failed"))))
  (CodexExecServerRpcErrorError -32603 CodexAbsent "metadata failed"))

!(assertEqual
  (codex:exec-server-fs-handler-result-value
    (codex:exec-server-fs-handler-read-directory
      (test:fs-handler)
      (codex:exec-server-fs-read-directory-params "/repo" CodexAbsent)
      (codex:exec-server-fs-handler-operation-read-directory-ok
        ((codex:exec-server-fs-read-directory-entry "src" True False)
         (codex:exec-server-fs-read-directory-entry
           "README.md"
           False
           True)))))
  (CodexExecServerFsReadDirectoryResponse
    ((CodexExecServerFsReadDirectoryEntry "src" True False)
     (CodexExecServerFsReadDirectoryEntry "README.md" False True))))

!(assertEqual
  (codex:exec-server-remove-options-recursive
    (codex:exec-server-fs-handler-remove-options-from-params
      (codex:exec-server-fs-remove-params
        "/repo/old"
        CodexAbsent
        CodexAbsent
        CodexAbsent)))
  True)

!(assertEqual
  (codex:exec-server-remove-options-force
    (codex:exec-server-fs-handler-remove-options-from-params
      (codex:exec-server-fs-remove-params
        "/repo/old"
        CodexAbsent
        CodexAbsent
        CodexAbsent)))
  True)

!(assertEqual
  (codex:exec-server-remove-options-recursive
    (codex:exec-server-fs-handler-remove-options-from-params
      (codex:exec-server-fs-remove-params
        "/repo/old"
        False
        False
        CodexAbsent)))
  False)

!(assertEqual
  (codex:exec-server-remove-options-force
    (codex:exec-server-fs-handler-remove-options-from-params
      (codex:exec-server-fs-remove-params
        "/repo/old"
        False
        False
        CodexAbsent)))
  False)

!(assertEqual
  (codex:exec-server-fs-handler-remove
    (test:fs-handler)
    (codex:exec-server-fs-remove-params
      "/repo/old"
      CodexAbsent
      CodexAbsent
      CodexAbsent)
    (codex:exec-server-fs-handler-operation-remove-ok))
  (CodexExecServerFsHandlerResultOk
    (CodexExecServerFsRemoveResponse)))

!(assertEqual
  (codex:exec-server-fs-handler-result-error
    (codex:exec-server-fs-handler-remove
      (test:fs-handler)
      (codex:exec-server-fs-remove-params
        "/repo/old"
        True
        True
        CodexAbsent)
      (codex:exec-server-fs-handler-operation-err
        (test:fs-error
          (codex:exec-server-fs-handler-error-kind-not-found)
          "missing"))))
  (CodexExecServerRpcErrorError -32004 CodexAbsent "missing"))

!(assertEqual
  (codex:exec-server-copy-options-recursive
    (codex:exec-server-fs-handler-copy-options-from-params
      (codex:exec-server-fs-copy-params
        "/repo/a"
        "/repo/b"
        False
        CodexAbsent)))
  False)

!(assertEqual
  (codex:exec-server-fs-handler-copy
    (test:fs-handler)
    (codex:exec-server-fs-copy-params
      "/repo/a"
      "/repo/b"
      True
      CodexAbsent)
    (codex:exec-server-fs-handler-operation-copy-ok))
  (CodexExecServerFsHandlerResultOk
    (CodexExecServerFsCopyResponse)))

!(assertEqual
  (codex:exec-server-fs-handler-result-error
    (codex:exec-server-fs-handler-copy
      (test:fs-handler)
      (codex:exec-server-fs-copy-params
        "/repo/a"
        "/repo/b"
        True
        CodexAbsent)
      (codex:exec-server-fs-handler-operation-err
        (test:fs-error
          (codex:exec-server-fs-handler-error-kind-other)
          "copy failed"))))
  (CodexExecServerRpcErrorError -32603 CodexAbsent "copy failed"))
