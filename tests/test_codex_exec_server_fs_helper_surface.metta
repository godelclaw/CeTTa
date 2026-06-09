!(register-module! ../codex)
!(import! &self json)
!(import! &self str)
!(import! &self codex:exec_server_rpc)
!(import! &self codex:exec_server_file_system_protocol)
!(import! &self codex:exec_server_fs_helper)

(= (test:permissions-json)
   (JsonObject
     ((JsonPair "type" (JsonString "managed"))
      (JsonPair
        "file_system"
        (JsonObject ((JsonPair "type" (JsonString "read-only")))))
      (JsonPair "network" (JsonString "disabled")))))

(= (test:sandbox)
   (codex:exec-server-fs-sandbox-context
     (test:permissions-json)
     "/repo"
     (codex:exec-server-fs-windows-sandbox-level-disabled)
     False
     False))

(= (test:helper-error $kind $message)
   (codex:exec-server-fs-helper-file-system-error $kind $message))

(= (test:read-file-request)
   (codex:exec-server-fs-helper-request-read-file
     (codex:exec-server-fs-read-file-params
       "/repo/file.txt"
       CodexAbsent)))

(= (test:read-file-payload)
   (codex:exec-server-fs-helper-payload-read-file
     (codex:exec-server-fs-read-file-response "aGk=")))

!(assertEqual
  (codex:exec-server-fs-helper-arg1)
  "--codex-run-as-fs-helper")

!(assertEqual
  (codex:exec-server-fs-helper-request-operation
    (codex:exec-server-fs-helper-request-write-file
      (codex:exec-server-fs-write-file-params
        "/repo/file.txt"
        "aGk="
        CodexAbsent)))
  "fs/writeFile")

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-fs-helper-request-json
      (codex:exec-server-fs-helper-request-write-file
        (codex:exec-server-fs-write-file-params
          "/repo/file.txt"
          "aGk="
          CodexAbsent))))
  ("{\"operation\":\"fs/writeFile\",\"params\":{\"path\":\"/repo/file.txt\",\"dataBase64\":\"aGk=\",\"sandbox\":null}}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-fs-helper-payload-json
      (codex:exec-server-fs-helper-payload-read-file
        (codex:exec-server-fs-read-file-response "aGk="))))
  ("{\"operation\":\"fs/readFile\",\"response\":{\"dataBase64\":\"aGk=\"}}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-fs-helper-response-json
      (codex:exec-server-fs-helper-response-ok
        (codex:exec-server-fs-helper-payload-copy
          (codex:exec-server-fs-copy-response)))))
  ("{\"status\":\"ok\",\"payload\":{\"operation\":\"fs/copy\",\"response\":{}}}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-fs-helper-response-json
      (codex:exec-server-fs-helper-response-error
        (codex:exec-server-rpc-invalid-request "bad request"))))
  ("{\"status\":\"error\",\"payload\":{\"code\":-32600,\"message\":\"bad request\"}}"))

!(assertEqual
  (codex:exec-server-fs-helper-expect-read-file
    (codex:exec-server-fs-helper-payload-read-file
      (codex:exec-server-fs-read-file-response "aGk=")))
  (CodexExecServerFsHelperResultOk
    (CodexExecServerFsReadFileResponse "aGk=")))

!(assertEqual
  (codex:exec-server-fs-helper-result-error
    (codex:exec-server-fs-helper-expect-read-file
      (codex:exec-server-fs-helper-payload-copy
        (codex:exec-server-fs-copy-response))))
  (CodexExecServerRpcErrorError
    -32603
    CodexAbsent
    "unexpected fs sandbox helper response: expected fs/readFile, got fs/copy"))

!(assertEqual
  (codex:exec-server-fs-helper-map-fs-error
    (test:helper-error
      (codex:exec-server-fs-helper-error-kind-not-found)
      "missing"))
  (CodexExecServerRpcErrorError -32004 CodexAbsent "missing"))

!(assertEqual
  (codex:exec-server-fs-helper-map-fs-error
    (test:helper-error
      (codex:exec-server-fs-helper-error-kind-invalid-input)
      "bad input"))
  (CodexExecServerRpcErrorError -32600 CodexAbsent "bad input"))

!(assertEqual
  (codex:exec-server-fs-helper-map-fs-error
    (test:helper-error
      (codex:exec-server-fs-helper-error-kind-permission-denied)
      "permission denied"))
  (CodexExecServerRpcErrorError -32600 CodexAbsent "permission denied"))

!(assertEqual
  (codex:exec-server-fs-helper-map-fs-error
    (test:helper-error
      (codex:exec-server-fs-helper-error-kind-other)
      "other failure"))
  (CodexExecServerRpcErrorError -32603 CodexAbsent "other failure"))

!(assertEqual
  (codex:exec-server-create-directory-options-recursive
    (codex:exec-server-fs-helper-create-directory-options-from-params
      (codex:exec-server-fs-create-directory-params
        "/repo/new"
        CodexAbsent
        CodexAbsent)))
  True)

!(assertEqual
  (codex:exec-server-create-directory-options-recursive
    (codex:exec-server-fs-helper-create-directory-options-from-params
      (codex:exec-server-fs-create-directory-params
        "/repo/new"
        False
        CodexAbsent)))
  False)

!(assertEqual
  (codex:exec-server-remove-options-recursive
    (codex:exec-server-fs-helper-remove-options-from-params
      (codex:exec-server-fs-remove-params
        "/repo/old"
        CodexAbsent
        CodexAbsent
        CodexAbsent)))
  True)

!(assertEqual
  (codex:exec-server-remove-options-force
    (codex:exec-server-fs-helper-remove-options-from-params
      (codex:exec-server-fs-remove-params
        "/repo/old"
        CodexAbsent
        CodexAbsent
        CodexAbsent)))
  True)

!(assertEqual
  (codex:exec-server-remove-options-force
    (codex:exec-server-fs-helper-remove-options-from-params
      (codex:exec-server-fs-remove-params
        "/repo/old"
        False
        False
        CodexAbsent)))
  False)

!(assertEqual
  (codex:exec-server-copy-options-recursive
    (codex:exec-server-fs-helper-copy-options-from-params
      (codex:exec-server-fs-copy-params
        "/repo/a"
        "/repo/b"
        True
        CodexAbsent)))
  True)

!(assertEqual
  (codex:exec-server-fs-helper-result-value
    (codex:exec-server-fs-helper-run-direct-request
      (codex:exec-server-fs-helper-request-read-file
        (codex:exec-server-fs-read-file-params
          "/repo/file.txt"
          (test:sandbox)))
      CodexAbsent
      (codex:exec-server-fs-helper-direct-operation-read-file-ok
        "hello")))
  (CodexExecServerFsHelperPayloadReadFile
    (CodexExecServerFsReadFileResponse "aGVsbG8=")))

!(assertEqual
  (codex:exec-server-fs-helper-result-error
    (codex:exec-server-fs-helper-run-direct-request
      (codex:exec-server-fs-helper-request-write-file
        (codex:exec-server-fs-write-file-params
          "/repo/file.txt"
          "!bad"
          CodexAbsent))
      (codex:exec-server-fs-helper-base64-decode-err
        "Invalid byte 33, offset 0.")
      (codex:exec-server-fs-helper-direct-operation-write-file-ok)))
  (CodexExecServerRpcErrorError
    -32600
    CodexAbsent
    "fs/writeFile requires valid base64 dataBase64: Invalid byte 33, offset 0."))

!(assertEqual
  (codex:exec-server-fs-helper-run-direct-request
    (codex:exec-server-fs-helper-request-write-file
      (codex:exec-server-fs-write-file-params
        "/repo/file.txt"
        "aGk="
        CodexAbsent))
    (codex:exec-server-fs-helper-base64-decode-ok "hi")
    (codex:exec-server-fs-helper-direct-operation-write-file-ok))
  (CodexExecServerFsHelperResultOk
    (CodexExecServerFsHelperPayloadWriteFile
      (CodexExecServerFsWriteFileResponse))))

!(assertEqual
  (codex:exec-server-fs-helper-result-value
    (codex:exec-server-fs-helper-run-direct-request
      (codex:exec-server-fs-helper-request-get-metadata
        (codex:exec-server-fs-get-metadata-params
          "/repo/file.txt"
          CodexAbsent))
      CodexAbsent
      (codex:exec-server-fs-helper-direct-operation-get-metadata-ok
        (codex:exec-server-file-metadata
          False
          True
          False
          100
          200))))
  (CodexExecServerFsHelperPayloadGetMetadata
    (CodexExecServerFsGetMetadataResponse
      False
      True
      False
      100
      200)))

!(assertEqual
  (codex:exec-server-fs-helper-result-value
    (codex:exec-server-fs-helper-run-direct-request
      (codex:exec-server-fs-helper-request-read-directory
        (codex:exec-server-fs-read-directory-params
          "/repo"
          CodexAbsent))
      CodexAbsent
      (codex:exec-server-fs-helper-direct-operation-read-directory-ok
        ((codex:exec-server-fs-read-directory-entry "src" True False)
         (codex:exec-server-fs-read-directory-entry
           "README.md"
           False
           True)))))
  (CodexExecServerFsHelperPayloadReadDirectory
    (CodexExecServerFsReadDirectoryResponse
      ((CodexExecServerFsReadDirectoryEntry "src" True False)
       (CodexExecServerFsReadDirectoryEntry "README.md" False True)))))

!(assertEqual
  (codex:exec-server-fs-helper-run-direct-request
    (codex:exec-server-fs-helper-request-remove
      (codex:exec-server-fs-remove-params
        "/repo/old"
        CodexAbsent
        CodexAbsent
        CodexAbsent))
    CodexAbsent
    (codex:exec-server-fs-helper-direct-operation-remove-ok))
  (CodexExecServerFsHelperResultOk
    (CodexExecServerFsHelperPayloadRemove
      (CodexExecServerFsRemoveResponse))))

!(assertEqual
  (codex:exec-server-fs-helper-result-error
    (codex:exec-server-fs-helper-run-direct-request
      (codex:exec-server-fs-helper-request-copy
        (codex:exec-server-fs-copy-params
          "/repo/a"
          "/repo/b"
          True
          CodexAbsent))
      CodexAbsent
      (codex:exec-server-fs-helper-direct-operation-err
        (test:helper-error
          (codex:exec-server-fs-helper-error-kind-other)
          "copy failed"))))
  (CodexExecServerRpcErrorError -32603 CodexAbsent "copy failed"))

!(assertEqual
  (codex:exec-server-fs-helper-main-exit-code
    (codex:exec-server-fs-helper-main-flow
      (codex:exec-server-fs-helper-main-runtime-err
        "builder failed")
      (codex:exec-server-fs-helper-main-run-main-ok)))
  1)

!(assertEqual
  (codex:exec-server-fs-helper-main-stderr
    (codex:exec-server-fs-helper-main-flow
      (codex:exec-server-fs-helper-main-runtime-err
        "builder failed")
      (codex:exec-server-fs-helper-main-run-main-ok)))
  (str-concat
    "failed to start fs sandbox helper runtime: builder failed"
    "\n"))

!(assertEqual
  (codex:exec-server-fs-helper-main-flow
    (codex:exec-server-fs-helper-main-runtime-ok)
    (codex:exec-server-fs-helper-main-run-main-ok))
  (CodexExecServerFsHelperMainResult 0 CodexAbsent))

!(assertEqual
  (codex:exec-server-fs-helper-main-stderr
    (codex:exec-server-fs-helper-main-flow
      (codex:exec-server-fs-helper-main-runtime-ok)
      (codex:exec-server-fs-helper-main-run-main-err
        "parse failed")))
  (str-concat "fs sandbox helper failed: parse failed" "\n"))

!(assertEqual
  (codex:exec-server-fs-helper-main-response-from-direct
    (codex:exec-server-fs-helper-run-main-direct-ok
      (test:read-file-payload)))
  (CodexExecServerFsHelperResponseOk
    (CodexExecServerFsHelperPayloadReadFile
      (CodexExecServerFsReadFileResponse "aGk="))))

!(assertEqual
  (codex:exec-server-fs-helper-main-response-from-direct
    (codex:exec-server-fs-helper-run-main-direct-err
      (codex:exec-server-rpc-invalid-request "bad request")))
  (CodexExecServerFsHelperResponseError
    (CodexExecServerRpcErrorError -32600 CodexAbsent "bad request")))

!(assertEqual
  (codex:exec-server-fs-helper-run-main-flow
    (codex:exec-server-fs-helper-run-main-read-stdin-err
      "stdin failed")
    (codex:exec-server-fs-helper-run-main-parse-request-ok
      (test:read-file-request))
    (codex:exec-server-fs-helper-run-main-direct-ok
      (test:read-file-payload))
    (codex:exec-server-fs-helper-run-main-serialize-response-ok
      "encoded")
    (codex:exec-server-fs-helper-run-main-write-response-ok)
    (codex:exec-server-fs-helper-run-main-write-newline-ok))
  (CodexExecServerFsHelperRunMainResultErr "" "stdin failed"))

!(assertEqual
  (codex:exec-server-fs-helper-run-main-flow
    (codex:exec-server-fs-helper-run-main-read-stdin-ok
      "{json}")
    (codex:exec-server-fs-helper-run-main-parse-request-err
      "expected value")
    (codex:exec-server-fs-helper-run-main-direct-ok
      (test:read-file-payload))
    (codex:exec-server-fs-helper-run-main-serialize-response-ok
      "encoded")
    (codex:exec-server-fs-helper-run-main-write-response-ok)
    (codex:exec-server-fs-helper-run-main-write-newline-ok))
  (CodexExecServerFsHelperRunMainResultErr "" "expected value"))

!(assertEqual
  (codex:exec-server-fs-helper-run-main-flow
    (codex:exec-server-fs-helper-run-main-read-stdin-ok
      "{json}")
    (codex:exec-server-fs-helper-run-main-parse-request-ok
      (test:read-file-request))
    (codex:exec-server-fs-helper-run-main-direct-ok
      (test:read-file-payload))
    (codex:exec-server-fs-helper-run-main-serialize-response-ok
      "encoded")
    (codex:exec-server-fs-helper-run-main-write-response-ok)
    (codex:exec-server-fs-helper-run-main-write-newline-ok))
  (CodexExecServerFsHelperRunMainResultOk
    (str-concat "encoded" "\n")))

!(assertEqual
  (codex:exec-server-fs-helper-run-main-flow
    (codex:exec-server-fs-helper-run-main-read-stdin-ok
      "{json}")
    (codex:exec-server-fs-helper-run-main-parse-request-ok
      (test:read-file-request))
    (codex:exec-server-fs-helper-run-main-direct-err
      (codex:exec-server-rpc-internal-error "fs failed"))
    (codex:exec-server-fs-helper-run-main-serialize-response-ok
      "error-json")
    (codex:exec-server-fs-helper-run-main-write-response-ok)
    (codex:exec-server-fs-helper-run-main-write-newline-ok))
  (CodexExecServerFsHelperRunMainResultOk
    (str-concat "error-json" "\n")))

!(assertEqual
  (codex:exec-server-fs-helper-run-main-flow
    (codex:exec-server-fs-helper-run-main-read-stdin-ok
      "{json}")
    (codex:exec-server-fs-helper-run-main-parse-request-ok
      (test:read-file-request))
    (codex:exec-server-fs-helper-run-main-direct-ok
      (test:read-file-payload))
    (codex:exec-server-fs-helper-run-main-serialize-response-err
      "serialize failed")
    (codex:exec-server-fs-helper-run-main-write-response-ok)
    (codex:exec-server-fs-helper-run-main-write-newline-ok))
  (CodexExecServerFsHelperRunMainResultErr "" "serialize failed"))

!(assertEqual
  (codex:exec-server-fs-helper-run-main-flow
    (codex:exec-server-fs-helper-run-main-read-stdin-ok
      "{json}")
    (codex:exec-server-fs-helper-run-main-parse-request-ok
      (test:read-file-request))
    (codex:exec-server-fs-helper-run-main-direct-ok
      (test:read-file-payload))
    (codex:exec-server-fs-helper-run-main-serialize-response-ok
      "encoded")
    (codex:exec-server-fs-helper-run-main-write-response-err
      "stdout failed")
    (codex:exec-server-fs-helper-run-main-write-newline-ok))
  (CodexExecServerFsHelperRunMainResultErr "" "stdout failed"))

!(assertEqual
  (codex:exec-server-fs-helper-run-main-flow
    (codex:exec-server-fs-helper-run-main-read-stdin-ok
      "{json}")
    (codex:exec-server-fs-helper-run-main-parse-request-ok
      (test:read-file-request))
    (codex:exec-server-fs-helper-run-main-direct-ok
      (test:read-file-payload))
    (codex:exec-server-fs-helper-run-main-serialize-response-ok
      "encoded")
    (codex:exec-server-fs-helper-run-main-write-response-ok)
    (codex:exec-server-fs-helper-run-main-write-newline-err
      "newline failed"))
  (CodexExecServerFsHelperRunMainResultErr "encoded" "newline failed"))
