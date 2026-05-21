!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:permissions)
!(import! &self codex:fs_sandbox)
!(import! &self codex:exec_server_rpc)
!(import! &self codex:exec_server_runtime_paths)
!(import! &self codex:exec_server_file_system_protocol)
!(import! &self codex:exec_server_fs_helper)
!(import! &self codex:exec_server_sandboxed_file_system)

(= (test:runtime-paths)
   (codex:exec-server-runtime-paths
     "/opt/codex/bin/codex"
     CodexAbsent))

(= (test:file-system)
   (codex:exec-server-sandboxed-file-system-new
     (test:runtime-paths)))

(= (test:restricted-sandbox)
   (codex:fs-sandbox-context-from-file-system-policy
     (codex:file-system-sandbox-policy-restricted ())))

(= (test:unrestricted-sandbox)
   (codex:fs-sandbox-context-from-file-system-policy
     (codex:file-system-sandbox-policy-unrestricted)))

(= (test:full-write-sandbox)
   (codex:fs-sandbox-context-from-file-system-policy
     (codex:file-system-sandbox-policy-restricted
       ((codex:file-system-sandbox-entry
          (codex:file-system-path-special
            (codex:file-system-special-path-root))
          (codex:file-system-access-write))))))

(= (test:sandboxed-error $kind $message)
   (codex:exec-server-sandboxed-fs-file-system-error $kind $message))

(= (test:unit-ok)
   (CodexExecServerSandboxedFsResultOk
     (CodexExecServerSandboxedFsUnit)))

!(assertEqual
  (codex:exec-server-file-system-sandbox-runner-runtime-paths
    (codex:exec-server-sandboxed-file-system-runner
      (test:file-system)))
  (test:runtime-paths))

!(assertEqual
  (codex:exec-server-sandboxed-fs-map-sandbox-error
    (codex:exec-server-rpc-not-found "missing"))
  (test:sandboxed-error
    (codex:exec-server-sandboxed-fs-error-kind-not-found)
    "missing"))

!(assertEqual
  (codex:exec-server-sandboxed-fs-map-sandbox-error
    (codex:exec-server-rpc-invalid-request "bad sandbox"))
  (test:sandboxed-error
    (codex:exec-server-sandboxed-fs-error-kind-invalid-input)
    "bad sandbox"))

!(assertEqual
  (codex:exec-server-sandboxed-fs-map-sandbox-error
    (codex:exec-server-rpc-internal-error "helper failed"))
  (test:sandboxed-error
    (codex:exec-server-sandboxed-fs-error-kind-other)
    "helper failed"))

!(assertEqual
  (codex:exec-server-sandboxed-fs-require-platform-sandbox
    (test:restricted-sandbox))
  (CodexExecServerSandboxedFsResultOk
    (test:restricted-sandbox)))

!(assertEqual
  (codex:exec-server-sandboxed-fs-require-platform-sandbox CodexAbsent)
  (CodexExecServerSandboxedFsResultErr
    (test:sandboxed-error
      (codex:exec-server-sandboxed-fs-error-kind-invalid-input)
      "sandboxed filesystem operations require ReadOnly or WorkspaceWrite sandbox policy")))

!(assertEqual
  (codex:exec-server-sandboxed-fs-require-platform-sandbox
    (test:unrestricted-sandbox))
  (CodexExecServerSandboxedFsResultErr
    (test:sandboxed-error
      (codex:exec-server-sandboxed-fs-error-kind-invalid-input)
      "sandboxed filesystem operations require ReadOnly or WorkspaceWrite sandbox policy")))

!(assertEqual
  (codex:exec-server-sandboxed-fs-require-platform-sandbox
    (test:full-write-sandbox))
  (CodexExecServerSandboxedFsResultErr
    (test:sandboxed-error
      (codex:exec-server-sandboxed-fs-error-kind-invalid-input)
      "sandboxed filesystem operations require ReadOnly or WorkspaceWrite sandbox policy")))

!(assertEqual
  (codex:exec-server-sandboxed-fs-read-file-request "/repo/file.txt")
  (CodexExecServerFsHelperRequestReadFile
    (CodexExecServerFsReadFileParams
      "/repo/file.txt"
      CodexAbsent)))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-fs-helper-request-json
      (codex:exec-server-sandboxed-fs-write-file-request
        "/repo/file.txt"
        "hi")))
  ("{\"operation\":\"fs/writeFile\",\"params\":{\"path\":\"/repo/file.txt\",\"dataBase64\":\"aGk=\",\"sandbox\":null}}"))

!(assertEqual
  (codex:exec-server-sandboxed-fs-create-directory-request
    "/repo/new"
    (codex:exec-server-create-directory-options False))
  (CodexExecServerFsHelperRequestCreateDirectory
    (CodexExecServerFsCreateDirectoryParams
      "/repo/new"
      False
      CodexAbsent)))

!(assertEqual
  (codex:exec-server-sandboxed-fs-remove-request
    "/repo/old"
    (codex:exec-server-remove-options False True))
  (CodexExecServerFsHelperRequestRemove
    (CodexExecServerFsRemoveParams
      "/repo/old"
      False
      True
      CodexAbsent)))

!(assertEqual
  (codex:exec-server-sandboxed-fs-copy-request
    "/repo/a"
    "/repo/b"
    (codex:exec-server-copy-options True))
  (CodexExecServerFsHelperRequestCopy
    (CodexExecServerFsCopyParams
      "/repo/a"
      "/repo/b"
      True
      CodexAbsent)))

!(assertEqual
  (codex:exec-server-sandboxed-fs-run-sandboxed
    (test:file-system)
    (test:restricted-sandbox)
    (codex:exec-server-sandboxed-fs-read-file-request
      "/repo/file.txt")
    (codex:exec-server-sandboxed-fs-runner-err
      (codex:exec-server-rpc-not-found "missing")))
  (CodexExecServerSandboxedFsResultErr
    (test:sandboxed-error
      (codex:exec-server-sandboxed-fs-error-kind-not-found)
      "missing")))

!(assertEqual
  (codex:exec-server-sandboxed-fs-read-file
    (test:file-system)
    "/repo/file.txt"
    (test:restricted-sandbox)
    (codex:exec-server-sandboxed-fs-runner-ok
      (codex:exec-server-fs-helper-payload-read-file
        (codex:exec-server-fs-read-file-response "aGk=")))
    (codex:exec-server-sandboxed-fs-base64-decode-ok "hi"))
  (CodexExecServerSandboxedFsResultOk "hi"))

!(assertEqual
  (codex:exec-server-sandboxed-fs-result-error
    (codex:exec-server-sandboxed-fs-read-file
      (test:file-system)
      "/repo/file.txt"
      (test:restricted-sandbox)
      (codex:exec-server-sandboxed-fs-runner-ok
        (codex:exec-server-fs-helper-payload-read-file
          (codex:exec-server-fs-read-file-response "!bad")))
      (codex:exec-server-sandboxed-fs-base64-decode-err
        "Invalid byte 33, offset 0.")))
  (test:sandboxed-error
    (codex:exec-server-sandboxed-fs-error-kind-invalid-data)
    "fs/readFile returned invalid base64 dataBase64: Invalid byte 33, offset 0."))

!(assertEqual
  (codex:exec-server-sandboxed-fs-result-error
    (codex:exec-server-sandboxed-fs-read-file
      (test:file-system)
      "/repo/file.txt"
      (test:restricted-sandbox)
      (codex:exec-server-sandboxed-fs-runner-ok
        (codex:exec-server-fs-helper-payload-copy
          (codex:exec-server-fs-copy-response)))
      (codex:exec-server-sandboxed-fs-base64-decode-ok
        "unused")))
  (test:sandboxed-error
    (codex:exec-server-sandboxed-fs-error-kind-other)
    "unexpected fs sandbox helper response: expected fs/readFile, got fs/copy"))

!(assertEqual
  (codex:exec-server-sandboxed-fs-write-file
    (test:file-system)
    "/repo/file.txt"
    "hi"
    (test:restricted-sandbox)
    (codex:exec-server-sandboxed-fs-runner-ok
      (codex:exec-server-fs-helper-payload-write-file
        (codex:exec-server-fs-write-file-response))))
  (test:unit-ok))

!(assertEqual
  (codex:exec-server-sandboxed-fs-result-error
    (codex:exec-server-sandboxed-fs-write-file
      (test:file-system)
      "/repo/file.txt"
      "hi"
      CodexAbsent
      (codex:exec-server-sandboxed-fs-runner-ok
        (codex:exec-server-fs-helper-payload-write-file
          (codex:exec-server-fs-write-file-response)))))
  (test:sandboxed-error
    (codex:exec-server-sandboxed-fs-error-kind-invalid-input)
    "sandboxed filesystem operations require ReadOnly or WorkspaceWrite sandbox policy"))

!(assertEqual
  (codex:exec-server-sandboxed-fs-create-directory
    (test:file-system)
    "/repo/new"
    (codex:exec-server-create-directory-options True)
    (test:restricted-sandbox)
    (codex:exec-server-sandboxed-fs-runner-ok
      (codex:exec-server-fs-helper-payload-create-directory
        (codex:exec-server-fs-create-directory-response))))
  (test:unit-ok))

!(assertEqual
  (codex:exec-server-sandboxed-fs-result-value
    (codex:exec-server-sandboxed-fs-get-metadata
      (test:file-system)
      "/repo/file.txt"
      (test:restricted-sandbox)
      (codex:exec-server-sandboxed-fs-runner-ok
        (codex:exec-server-fs-helper-payload-get-metadata
          (codex:exec-server-fs-get-metadata-response
            False
            True
            False
            100
            200)))))
  (CodexExecServerFileMetadata
    False
    True
    False
    100
    200))

!(assertEqual
  (codex:exec-server-sandboxed-fs-result-value
    (codex:exec-server-sandboxed-fs-read-directory
      (test:file-system)
      "/repo"
      (test:restricted-sandbox)
      (codex:exec-server-sandboxed-fs-runner-ok
        (codex:exec-server-fs-helper-payload-read-directory
          (codex:exec-server-fs-read-directory-response
            ((codex:exec-server-fs-read-directory-entry
               "src"
               True
               False)
             (codex:exec-server-fs-read-directory-entry
               "README.md"
               False
               True)))))))
  ((CodexExecServerFsReadDirectoryEntry "src" True False)
   (CodexExecServerFsReadDirectoryEntry "README.md" False True)))

!(assertEqual
  (codex:exec-server-sandboxed-fs-remove
    (test:file-system)
    "/repo/old"
    (codex:exec-server-remove-options True True)
    (test:restricted-sandbox)
    (codex:exec-server-sandboxed-fs-runner-ok
      (codex:exec-server-fs-helper-payload-remove
        (codex:exec-server-fs-remove-response))))
  (test:unit-ok))

!(assertEqual
  (codex:exec-server-sandboxed-fs-copy
    (test:file-system)
    "/repo/a"
    "/repo/b"
    (codex:exec-server-copy-options True)
    (test:restricted-sandbox)
    (codex:exec-server-sandboxed-fs-runner-ok
      (codex:exec-server-fs-helper-payload-copy
        (codex:exec-server-fs-copy-response))))
  (test:unit-ok))

!(assertEqual
  (codex:exec-server-sandboxed-fs-result-error
    (codex:exec-server-sandboxed-fs-copy
      (test:file-system)
      "/repo/a"
      "/repo/b"
      (codex:exec-server-copy-options True)
      (test:restricted-sandbox)
      (codex:exec-server-sandboxed-fs-runner-err
        (codex:exec-server-rpc-invalid-request
          "failed to prepare fs sandbox"))))
  (test:sandboxed-error
    (codex:exec-server-sandboxed-fs-error-kind-invalid-input)
    "failed to prepare fs sandbox"))
