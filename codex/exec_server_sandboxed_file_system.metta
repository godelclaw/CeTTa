; Rust-faithful exec-server sandboxed filesystem slice.
;
; This ports deterministic behavior from:
; - openai-codex/codex-rs/exec-server/src/sandboxed_file_system.rs
;   - SandboxedFileSystem::new runner shape
;   - run_sandboxed JSON-RPC-error to filesystem-error mapping
;   - require_platform_sandbox
;   - helper request construction for every ExecutorFileSystem operation
;   - helper payload expectation and response projection policy
;   - read-file invalid base64 error mapping
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust awaits `FileSystemSandboxRunner::run`, which prepares and executes a
;   sandboxed helper process. This pure slice takes a symbolic runner outcome
;   at that runtime boundary and preserves the exact request construction,
;   expectation checks, and error mapping around it.
; - Rust decodes read-file standard base64 into arbitrary bytes. CeTTa
;   currently has standard base64 encoding but not a standard base64 decoder,
;   so this slice takes a symbolic decode outcome and preserves the exact
;   invalid-data branch and message prefix from Rust.
; - Rust stores `FileSystemSandboxContext.permissions` as a full permission
;   profile. This slice uses the existing CeTTa `fs_sandbox` context that
;   carries the already materialized filesystem sandbox policy because
;   `sandboxed_file_system.rs` only observes `should_run_in_sandbox` here.

!(import! &self str)
!(import! &self exec_server_rpc)
!(import! &self exec_server_file_system_protocol)
!(import! &self exec_server_fs_helper)
!(import! &self fs_sandbox)

(= (codex:exec-server-file-system-sandbox-runner $runtime-paths)
   (CodexExecServerFileSystemSandboxRunner $runtime-paths))

(= (codex:exec-server-file-system-sandbox-runner-runtime-paths
      (CodexExecServerFileSystemSandboxRunner $runtime-paths))
   $runtime-paths)

(= (codex:exec-server-sandboxed-file-system $sandbox-runner)
   (CodexExecServerSandboxedFileSystem $sandbox-runner))

(= (codex:exec-server-sandboxed-file-system-new $runtime-paths)
   (CodexExecServerSandboxedFileSystem
     (CodexExecServerFileSystemSandboxRunner $runtime-paths)))

(= (codex:exec-server-sandboxed-file-system-runner
      (CodexExecServerSandboxedFileSystem $sandbox-runner))
   $sandbox-runner)

(= (codex:exec-server-sandboxed-fs-result-ok $value)
   (CodexExecServerSandboxedFsResultOk $value))

(= (codex:exec-server-sandboxed-fs-result-err $error)
   (CodexExecServerSandboxedFsResultErr $error))

(= (codex:exec-server-sandboxed-fs-result-value
      (CodexExecServerSandboxedFsResultOk $value))
   $value)

(= (codex:exec-server-sandboxed-fs-result-error
      (CodexExecServerSandboxedFsResultErr $error))
   $error)

(= (codex:exec-server-sandboxed-fs-unit)
   (CodexExecServerSandboxedFsUnit))

(= (codex:exec-server-sandboxed-fs-error-kind-not-found)
   (CodexExecServerSandboxedFsErrorKindNotFound))

(= (codex:exec-server-sandboxed-fs-error-kind-invalid-input)
   (CodexExecServerSandboxedFsErrorKindInvalidInput))

(= (codex:exec-server-sandboxed-fs-error-kind-invalid-data)
   (CodexExecServerSandboxedFsErrorKindInvalidData))

(= (codex:exec-server-sandboxed-fs-error-kind-other)
   (CodexExecServerSandboxedFsErrorKindOther))

(= (codex:exec-server-sandboxed-fs-file-system-error
      $kind
      $message)
   (CodexExecServerSandboxedFsFileSystemError $kind $message))

(= (codex:exec-server-sandboxed-fs-file-system-error-kind
      (CodexExecServerSandboxedFsFileSystemError $kind $message))
   $kind)

(= (codex:exec-server-sandboxed-fs-file-system-error-message
      (CodexExecServerSandboxedFsFileSystemError $kind $message))
   $message)

(= (codex:exec-server-sandboxed-fs-map-sandbox-error
      (CodexExecServerRpcErrorError $code $data $message))
   (if (== $code -32004)
       (CodexExecServerSandboxedFsFileSystemError
         (CodexExecServerSandboxedFsErrorKindNotFound)
         $message)
       (if (== $code -32600)
           (CodexExecServerSandboxedFsFileSystemError
             (CodexExecServerSandboxedFsErrorKindInvalidInput)
             $message)
           (CodexExecServerSandboxedFsFileSystemError
             (CodexExecServerSandboxedFsErrorKindOther)
             $message))))

(= (codex:exec-server-sandboxed-fs-require-platform-sandbox-error)
   (CodexExecServerSandboxedFsFileSystemError
     (CodexExecServerSandboxedFsErrorKindInvalidInput)
     "sandboxed filesystem operations require ReadOnly or WorkspaceWrite sandbox policy"))

(= (codex:exec-server-sandboxed-fs-require-platform-sandbox $sandbox)
   (if (== $sandbox CodexAbsent)
       (CodexExecServerSandboxedFsResultErr
         (codex:exec-server-sandboxed-fs-require-platform-sandbox-error))
       (if (codex:fs-sandbox-context-should-run-in-sandbox $sandbox)
           (CodexExecServerSandboxedFsResultOk $sandbox)
           (CodexExecServerSandboxedFsResultErr
             (codex:exec-server-sandboxed-fs-require-platform-sandbox-error)))))

(= (codex:exec-server-sandboxed-fs-runner-ok $payload)
   (CodexExecServerSandboxedFsRunnerOk $payload))

(= (codex:exec-server-sandboxed-fs-runner-err $error)
   (CodexExecServerSandboxedFsRunnerErr $error))

(= (codex:exec-server-sandboxed-fs-run-sandboxed
      (CodexExecServerSandboxedFileSystem $sandbox-runner)
      $sandbox
      $request
      (CodexExecServerSandboxedFsRunnerOk $payload))
   (CodexExecServerSandboxedFsResultOk $payload))

(= (codex:exec-server-sandboxed-fs-run-sandboxed
      (CodexExecServerSandboxedFileSystem $sandbox-runner)
      $sandbox
      $request
      (CodexExecServerSandboxedFsRunnerErr $error))
   (CodexExecServerSandboxedFsResultErr
     (codex:exec-server-sandboxed-fs-map-sandbox-error $error)))

(= (codex:exec-server-sandboxed-fs-base64-decode-ok $bytes)
   (CodexExecServerSandboxedFsBase64DecodeOk $bytes))

(= (codex:exec-server-sandboxed-fs-base64-decode-err $message)
   (CodexExecServerSandboxedFsBase64DecodeErr $message))

(= (codex:exec-server-sandboxed-fs-read-file-request $path)
   (CodexExecServerFsHelperRequestReadFile
     (CodexExecServerFsReadFileParams $path CodexAbsent)))

(= (codex:exec-server-sandboxed-fs-write-file-request
      $path
      $contents)
   (CodexExecServerFsHelperRequestWriteFile
     (CodexExecServerFsWriteFileParams
       $path
       (str-base64-encode $contents)
       CodexAbsent)))

(= (codex:exec-server-sandboxed-fs-create-directory-request
      $path
      (CodexExecServerCreateDirectoryOptions $recursive))
   (CodexExecServerFsHelperRequestCreateDirectory
     (CodexExecServerFsCreateDirectoryParams
       $path
       $recursive
       CodexAbsent)))

(= (codex:exec-server-sandboxed-fs-get-metadata-request $path)
   (CodexExecServerFsHelperRequestGetMetadata
     (CodexExecServerFsGetMetadataParams $path CodexAbsent)))

(= (codex:exec-server-sandboxed-fs-read-directory-request $path)
   (CodexExecServerFsHelperRequestReadDirectory
     (CodexExecServerFsReadDirectoryParams $path CodexAbsent)))

(= (codex:exec-server-sandboxed-fs-remove-request
      $path
      (CodexExecServerRemoveOptions $recursive $force))
   (CodexExecServerFsHelperRequestRemove
     (CodexExecServerFsRemoveParams
       $path
       $recursive
       $force
       CodexAbsent)))

(= (codex:exec-server-sandboxed-fs-copy-request
      $source-path
      $destination-path
      (CodexExecServerCopyOptions $recursive))
   (CodexExecServerFsHelperRequestCopy
     (CodexExecServerFsCopyParams
       $source-path
       $destination-path
       $recursive
       CodexAbsent)))

(= (codex:exec-server-sandboxed-fs-map-helper-result
      (CodexExecServerFsHelperResultOk $value))
   (CodexExecServerSandboxedFsResultOk $value))

(= (codex:exec-server-sandboxed-fs-map-helper-result
      (CodexExecServerFsHelperResultErr $error))
   (CodexExecServerSandboxedFsResultErr
     (codex:exec-server-sandboxed-fs-map-sandbox-error $error)))

(= (codex:exec-server-sandboxed-fs-read-file-decode-result
      (CodexExecServerFsReadFileResponse $data-base64)
      (CodexExecServerSandboxedFsBase64DecodeOk $bytes))
   (CodexExecServerSandboxedFsResultOk $bytes))

(= (codex:exec-server-sandboxed-fs-read-file-decode-result
      (CodexExecServerFsReadFileResponse $data-base64)
      (CodexExecServerSandboxedFsBase64DecodeErr $message))
   (CodexExecServerSandboxedFsResultErr
     (CodexExecServerSandboxedFsFileSystemError
       (CodexExecServerSandboxedFsErrorKindInvalidData)
       (format-args
         "fs/readFile returned invalid base64 dataBase64: {}"
         ($message)))))

(= (codex:exec-server-sandboxed-fs-read-file
      $file-system
      $path
      $sandbox
      $runner-outcome
      $decode-outcome)
   (case (codex:exec-server-sandboxed-fs-require-platform-sandbox
           $sandbox)
     (((CodexExecServerSandboxedFsResultErr $error)
       (CodexExecServerSandboxedFsResultErr $error))
      ((CodexExecServerSandboxedFsResultOk $required-sandbox)
       (let $runner-result
         (codex:exec-server-sandboxed-fs-run-sandboxed
           $file-system
           $required-sandbox
           (codex:exec-server-sandboxed-fs-read-file-request $path)
           $runner-outcome)
         (case $runner-result
           (((CodexExecServerSandboxedFsResultErr $error)
             (CodexExecServerSandboxedFsResultErr $error))
            ((CodexExecServerSandboxedFsResultOk $payload)
             (case
               (codex:exec-server-sandboxed-fs-map-helper-result
                 (codex:exec-server-fs-helper-expect-read-file $payload))
               (((CodexExecServerSandboxedFsResultErr $error)
                 (CodexExecServerSandboxedFsResultErr $error))
                ((CodexExecServerSandboxedFsResultOk $response)
                 (codex:exec-server-sandboxed-fs-read-file-decode-result
                   $response
                   $decode-outcome))))))))))))

(= (codex:exec-server-sandboxed-fs-unit-helper-result
      $helper-result)
   (case (codex:exec-server-sandboxed-fs-map-helper-result
           $helper-result)
     (((CodexExecServerSandboxedFsResultErr $error)
       (CodexExecServerSandboxedFsResultErr $error))
      ((CodexExecServerSandboxedFsResultOk $response)
       (CodexExecServerSandboxedFsResultOk
         (CodexExecServerSandboxedFsUnit))))))

(= (codex:exec-server-sandboxed-fs-write-file
      $file-system
      $path
      $contents
      $sandbox
      $runner-outcome)
   (case (codex:exec-server-sandboxed-fs-require-platform-sandbox
           $sandbox)
     (((CodexExecServerSandboxedFsResultErr $error)
       (CodexExecServerSandboxedFsResultErr $error))
      ((CodexExecServerSandboxedFsResultOk $required-sandbox)
       (case (codex:exec-server-sandboxed-fs-run-sandboxed
               $file-system
               $required-sandbox
               (codex:exec-server-sandboxed-fs-write-file-request
                 $path
                 $contents)
               $runner-outcome)
         (((CodexExecServerSandboxedFsResultErr $error)
           (CodexExecServerSandboxedFsResultErr $error))
          ((CodexExecServerSandboxedFsResultOk $payload)
           (codex:exec-server-sandboxed-fs-unit-helper-result
             (codex:exec-server-fs-helper-expect-write-file $payload)))))))))

(= (codex:exec-server-sandboxed-fs-create-directory
      $file-system
      $path
      $options
      $sandbox
      $runner-outcome)
   (case (codex:exec-server-sandboxed-fs-require-platform-sandbox
           $sandbox)
     (((CodexExecServerSandboxedFsResultErr $error)
       (CodexExecServerSandboxedFsResultErr $error))
      ((CodexExecServerSandboxedFsResultOk $required-sandbox)
       (case (codex:exec-server-sandboxed-fs-run-sandboxed
               $file-system
               $required-sandbox
               (codex:exec-server-sandboxed-fs-create-directory-request
                 $path
                 $options)
               $runner-outcome)
         (((CodexExecServerSandboxedFsResultErr $error)
           (CodexExecServerSandboxedFsResultErr $error))
          ((CodexExecServerSandboxedFsResultOk $payload)
           (codex:exec-server-sandboxed-fs-unit-helper-result
             (codex:exec-server-fs-helper-expect-create-directory
               $payload)))))))))

(= (codex:exec-server-sandboxed-fs-get-metadata
      $file-system
      $path
      $sandbox
      $runner-outcome)
   (case (codex:exec-server-sandboxed-fs-require-platform-sandbox
           $sandbox)
     (((CodexExecServerSandboxedFsResultErr $error)
       (CodexExecServerSandboxedFsResultErr $error))
      ((CodexExecServerSandboxedFsResultOk $required-sandbox)
       (case (codex:exec-server-sandboxed-fs-run-sandboxed
               $file-system
               $required-sandbox
               (codex:exec-server-sandboxed-fs-get-metadata-request
                 $path)
               $runner-outcome)
         (((CodexExecServerSandboxedFsResultErr $error)
           (CodexExecServerSandboxedFsResultErr $error))
          ((CodexExecServerSandboxedFsResultOk $payload)
           (case
             (codex:exec-server-sandboxed-fs-map-helper-result
               (codex:exec-server-fs-helper-expect-get-metadata $payload))
             (((CodexExecServerSandboxedFsResultErr $error)
               (CodexExecServerSandboxedFsResultErr $error))
              ((CodexExecServerSandboxedFsResultOk
                 (CodexExecServerFsGetMetadataResponse
                   $is-directory
                   $is-file
                   $is-symlink
                   $created-at-ms
                   $modified-at-ms))
               (CodexExecServerSandboxedFsResultOk
                 (CodexExecServerFileMetadata
                   $is-directory
                   $is-file
                   $is-symlink
                   $created-at-ms
                   $modified-at-ms))))))))))))

(= (codex:exec-server-sandboxed-fs-read-directory
      $file-system
      $path
      $sandbox
      $runner-outcome)
   (case (codex:exec-server-sandboxed-fs-require-platform-sandbox
           $sandbox)
     (((CodexExecServerSandboxedFsResultErr $error)
       (CodexExecServerSandboxedFsResultErr $error))
      ((CodexExecServerSandboxedFsResultOk $required-sandbox)
       (case (codex:exec-server-sandboxed-fs-run-sandboxed
               $file-system
               $required-sandbox
               (codex:exec-server-sandboxed-fs-read-directory-request
                 $path)
               $runner-outcome)
         (((CodexExecServerSandboxedFsResultErr $error)
           (CodexExecServerSandboxedFsResultErr $error))
          ((CodexExecServerSandboxedFsResultOk $payload)
           (case
             (codex:exec-server-sandboxed-fs-map-helper-result
               (codex:exec-server-fs-helper-expect-read-directory
                 $payload))
             (((CodexExecServerSandboxedFsResultErr $error)
               (CodexExecServerSandboxedFsResultErr $error))
              ((CodexExecServerSandboxedFsResultOk
                 (CodexExecServerFsReadDirectoryResponse $entries))
               (CodexExecServerSandboxedFsResultOk $entries)))))))))))

(= (codex:exec-server-sandboxed-fs-remove
      $file-system
      $path
      $options
      $sandbox
      $runner-outcome)
   (case (codex:exec-server-sandboxed-fs-require-platform-sandbox
           $sandbox)
     (((CodexExecServerSandboxedFsResultErr $error)
       (CodexExecServerSandboxedFsResultErr $error))
      ((CodexExecServerSandboxedFsResultOk $required-sandbox)
       (case (codex:exec-server-sandboxed-fs-run-sandboxed
               $file-system
               $required-sandbox
               (codex:exec-server-sandboxed-fs-remove-request
                 $path
                 $options)
               $runner-outcome)
         (((CodexExecServerSandboxedFsResultErr $error)
           (CodexExecServerSandboxedFsResultErr $error))
          ((CodexExecServerSandboxedFsResultOk $payload)
           (codex:exec-server-sandboxed-fs-unit-helper-result
             (codex:exec-server-fs-helper-expect-remove $payload)))))))))

(= (codex:exec-server-sandboxed-fs-copy
      $file-system
      $source-path
      $destination-path
      $options
      $sandbox
      $runner-outcome)
   (case (codex:exec-server-sandboxed-fs-require-platform-sandbox
           $sandbox)
     (((CodexExecServerSandboxedFsResultErr $error)
       (CodexExecServerSandboxedFsResultErr $error))
      ((CodexExecServerSandboxedFsResultOk $required-sandbox)
       (case (codex:exec-server-sandboxed-fs-run-sandboxed
               $file-system
               $required-sandbox
               (codex:exec-server-sandboxed-fs-copy-request
                 $source-path
                 $destination-path
                 $options)
               $runner-outcome)
         (((CodexExecServerSandboxedFsResultErr $error)
           (CodexExecServerSandboxedFsResultErr $error))
          ((CodexExecServerSandboxedFsResultOk $payload)
           (codex:exec-server-sandboxed-fs-unit-helper-result
             (codex:exec-server-fs-helper-expect-copy $payload)))))))))
