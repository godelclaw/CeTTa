!(register-module! ../codex)
!(import! &self codex:permissions)
!(import! &self codex:fs_sandbox)
!(import! &self codex:exec_server_file_system_protocol)
!(import! &self codex:exec_server_remote_file_system)

(= (test:remote-fs-absolute-sandbox)
   (codex:fs-sandbox-context-from-file-system-policy-with-cwd
     (codex:file-system-sandbox-policy-restricted
       ((codex:file-system-sandbox-entry
          (codex:file-system-path-path "/workspace")
          (codex:file-system-access-read))))
     "/workspace"))

(= (test:remote-fs-cwd-sandbox)
   (codex:fs-sandbox-context-from-file-system-policy-with-cwd
     (codex:file-system-sandbox-policy-restricted
       ((codex:file-system-sandbox-entry
          (codex:file-system-path-special
            (codex:file-system-special-path-current-working-directory))
          (codex:file-system-access-read))))
     "/workspace"))

(= (test:remote-fs-client-ok)
   (codex:exec-server-remote-fs-client-get-ok (CodexRemoteClient)))

(= (test:remote-fs-unit-call-ok)
   (codex:exec-server-remote-fs-call-ok (CodexIgnoredResponse)))

!(assertEqual
  (codex:exec-server-remote-file-system-client
    (codex:exec-server-remote-file-system-new
      (CodexLazyRemoteClient "ws://example.test")))
  (CodexLazyRemoteClient "ws://example.test"))

!(assertEqual
  (codex:fs-sandbox-context-cwd
    (codex:exec-server-remote-fs-remote-sandbox-context
      (test:remote-fs-absolute-sandbox)))
  CodexAbsent)

!(assertEqual
  (codex:fs-sandbox-context-cwd
    (codex:exec-server-remote-fs-remote-sandbox-context
      (test:remote-fs-cwd-sandbox)))
  "/workspace")

!(assertEqual
  (codex:exec-server-remote-fs-io-error-kind
    (codex:exec-server-remote-fs-map-remote-error
      (CodexExecServerClientErrorClosed)))
  (CodexExecServerRemoteFsErrorKindBrokenPipe))

!(assertEqual
  (codex:exec-server-remote-fs-io-error-message
    (codex:exec-server-remote-fs-map-remote-error
      (CodexExecServerClientErrorDisconnected
        "exec-server transport disconnected")))
  "exec-server transport closed")

!(assertEqual
  (codex:exec-server-remote-fs-map-remote-error
    (CodexExecServerClientErrorServer -32004 "missing"))
  (CodexExecServerRemoteFsIoError
    (CodexExecServerRemoteFsErrorKindNotFound)
    "missing"))

!(assertEqual
  (codex:exec-server-remote-fs-map-remote-error
    (CodexExecServerClientErrorServer -32600 "bad request"))
  (CodexExecServerRemoteFsIoError
    (CodexExecServerRemoteFsErrorKindInvalidInput)
    "bad request"))

!(assertEqual
  (codex:exec-server-remote-fs-map-remote-error
    (CodexExecServerClientErrorServer -32603 "server failed"))
  (CodexExecServerRemoteFsIoError
    (CodexExecServerRemoteFsErrorKindOther)
    "server failed"))

!(assertEqual
  (codex:exec-server-remote-fs-map-remote-error
    (CodexExecServerClientErrorJson "decode failed"))
  (CodexExecServerRemoteFsIoError
    (CodexExecServerRemoteFsErrorKindOther)
    "failed to serialize or deserialize exec-server JSON: decode failed"))

!(assertEqual
  (codex:exec-server-remote-fs-result-params
    (codex:exec-server-remote-fs-read-file-flow
      "/workspace/file.txt"
      CodexAbsent
      (codex:exec-server-remote-fs-client-get-err
        (CodexExecServerClientErrorClosed))
      (codex:exec-server-remote-fs-call-ok
        (codex:exec-server-fs-read-file-response "aGk="))
      (codex:exec-server-remote-fs-base64-decode-ok "hi")))
  CodexAbsent)

!(assertEqual
  (codex:exec-server-remote-fs-result-params
    (codex:exec-server-remote-fs-read-file-flow
      "/workspace/file.txt"
      (test:remote-fs-absolute-sandbox)
      (test:remote-fs-client-ok)
      (codex:exec-server-remote-fs-call-ok
        (codex:exec-server-fs-read-file-response "aGk="))
      (codex:exec-server-remote-fs-base64-decode-ok "hi")))
  (CodexExecServerFsReadFileParams
    "/workspace/file.txt"
    (codex:fs-sandbox-context-drop-cwd-if-unused
      (test:remote-fs-absolute-sandbox))))

!(assertEqual
  (codex:exec-server-remote-fs-result-value
    (codex:exec-server-remote-fs-read-file-flow
      "/workspace/file.txt"
      CodexAbsent
      (test:remote-fs-client-ok)
      (codex:exec-server-remote-fs-call-ok
        (codex:exec-server-fs-read-file-response "aGk="))
      (codex:exec-server-remote-fs-base64-decode-ok "hi")))
  "hi")

!(assertEqual
  (codex:exec-server-remote-fs-result-error
    (codex:exec-server-remote-fs-read-file-flow
      "/workspace/file.txt"
      CodexAbsent
      (test:remote-fs-client-ok)
      (codex:exec-server-remote-fs-call-ok
        (codex:exec-server-fs-read-file-response "%%%%"))
      (codex:exec-server-remote-fs-base64-decode-err
        "invalid byte")))
  (CodexExecServerRemoteFsIoError
    (CodexExecServerRemoteFsErrorKindInvalidData)
    "remote fs/readFile returned invalid base64 dataBase64: invalid byte"))

!(assertEqual
  (codex:exec-server-remote-fs-result-params
    (codex:exec-server-remote-fs-write-file-flow
      "/workspace/file.txt"
      "hi"
      CodexAbsent
      (test:remote-fs-client-ok)
      (test:remote-fs-unit-call-ok)))
  (CodexExecServerFsWriteFileParams
    "/workspace/file.txt"
    "aGk="
    CodexAbsent))

!(assertEqual
  (codex:exec-server-remote-fs-result-params
    (codex:exec-server-remote-fs-create-directory-flow
      "/workspace/new"
      (codex:exec-server-create-directory-options False)
      CodexAbsent
      (test:remote-fs-client-ok)
      (test:remote-fs-unit-call-ok)))
  (CodexExecServerFsCreateDirectoryParams
    "/workspace/new"
    False
    CodexAbsent))

!(assertEqual
  (codex:exec-server-remote-fs-result-value
    (codex:exec-server-remote-fs-get-metadata-flow
      "/workspace/file.txt"
      CodexAbsent
      (test:remote-fs-client-ok)
      (codex:exec-server-remote-fs-call-ok
        (codex:exec-server-fs-get-metadata-response
          False
          True
          False
          100
          200))))
  (CodexExecServerFileMetadata False True False 100 200))

!(assertEqual
  (codex:exec-server-remote-fs-result-value
    (codex:exec-server-remote-fs-read-directory-flow
      "/workspace"
      CodexAbsent
      (test:remote-fs-client-ok)
      (codex:exec-server-remote-fs-call-ok
        (codex:exec-server-fs-read-directory-response
          ((codex:exec-server-fs-read-directory-entry "src" True False)
           (codex:exec-server-fs-read-directory-entry "README.md" False True))))))
  ((CodexExecServerRemoteFsReadDirectoryEntry "src" True False)
   (CodexExecServerRemoteFsReadDirectoryEntry "README.md" False True)))

!(assertEqual
  (codex:exec-server-remote-fs-result-params
    (codex:exec-server-remote-fs-remove-flow
      "/workspace/old"
      (codex:exec-server-remove-options True False)
      CodexAbsent
      (test:remote-fs-client-ok)
      (test:remote-fs-unit-call-ok)))
  (CodexExecServerFsRemoveParams
    "/workspace/old"
    True
    False
    CodexAbsent))

!(assertEqual
  (codex:exec-server-remote-fs-result-params
    (codex:exec-server-remote-fs-copy-flow
      "/workspace/src"
      "/workspace/dst"
      (codex:exec-server-copy-options True)
      CodexAbsent
      (test:remote-fs-client-ok)
      (test:remote-fs-unit-call-ok)))
  (CodexExecServerFsCopyParams
    "/workspace/src"
    "/workspace/dst"
    True
    CodexAbsent))
