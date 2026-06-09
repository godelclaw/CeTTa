; Rust-faithful exec-server remote filesystem slice.
;
; This ports deterministic adapter behavior from:
; - openai-codex/codex-rs/exec-server/src/remote_file_system.rs
;   - RemoteFileSystem::new
;   - remote_sandbox_context
;   - map_remote_error
;   - ExecutorFileSystem method client-get, parameter construction,
;     response projection, base64 encode/decode boundary, and error mapping
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust owns a `LazyRemoteExecServerClient` and awaits async RPC methods. This
;   pure slice takes symbolic lazy-client and RPC call outcomes at that runtime
;   boundary while preserving the exact branch order and parameter shaping.
; - Rust decodes `dataBase64` using the standard base64 engine. CeTTa currently
;   has standard base64 encoding but no standard base64 decoder, so `read_file`
;   receives a symbolic decode outcome and preserves the invalid-data message.
; - Rust maps `ExecServerError::to_string()` for non-special errors. This slice
;   models the display strings for the error variants currently represented in
;   the exec-server CeTTa port.

!(import! &self list)
!(import! &self str)
!(import! &self fs_sandbox)
!(import! &self exec_server_file_system_protocol)

(= (codex:exec-server-remote-fs-invalid-request-error-code)
   -32600)

(= (codex:exec-server-remote-fs-not-found-error-code)
   -32004)

(= (codex:exec-server-remote-file-system $client)
   (CodexExecServerRemoteFileSystem $client))

(= (codex:exec-server-remote-file-system-new $client)
   (CodexExecServerRemoteFileSystem $client))

(= (codex:exec-server-remote-file-system-client
      (CodexExecServerRemoteFileSystem $client))
   $client)

(= (codex:exec-server-remote-fs-error-kind-not-found)
   (CodexExecServerRemoteFsErrorKindNotFound))

(= (codex:exec-server-remote-fs-error-kind-invalid-input)
   (CodexExecServerRemoteFsErrorKindInvalidInput))

(= (codex:exec-server-remote-fs-error-kind-broken-pipe)
   (CodexExecServerRemoteFsErrorKindBrokenPipe))

(= (codex:exec-server-remote-fs-error-kind-invalid-data)
   (CodexExecServerRemoteFsErrorKindInvalidData))

(= (codex:exec-server-remote-fs-error-kind-other)
   (CodexExecServerRemoteFsErrorKindOther))

(= (codex:exec-server-remote-fs-io-error $kind $message)
   (CodexExecServerRemoteFsIoError $kind $message))

(= (codex:exec-server-remote-fs-io-error-kind
      (CodexExecServerRemoteFsIoError $kind $message))
   $kind)

(= (codex:exec-server-remote-fs-io-error-message
      (CodexExecServerRemoteFsIoError $kind $message))
   $message)

(= (codex:exec-server-remote-fs-error-display
      (CodexExecServerClientErrorJson $message))
   (str-concat
     "failed to serialize or deserialize exec-server JSON: "
     $message))

(= (codex:exec-server-remote-fs-error-display
      (CodexExecServerClientErrorProtocol $message))
   (str-concat "exec-server protocol error: " $message))

(= (codex:exec-server-remote-fs-error-display
      (CodexExecServerClientErrorOther $message))
   $message)

(= (codex:exec-server-remote-fs-map-remote-error $error)
   (case $error
     (((CodexExecServerClientErrorServer -32004 $message)
       (CodexExecServerRemoteFsIoError
         (CodexExecServerRemoteFsErrorKindNotFound)
         $message))
      ((CodexExecServerClientErrorServer -32600 $message)
       (CodexExecServerRemoteFsIoError
         (CodexExecServerRemoteFsErrorKindInvalidInput)
         $message))
      ((CodexExecServerClientErrorServer $code $message)
       (CodexExecServerRemoteFsIoError
         (CodexExecServerRemoteFsErrorKindOther)
         $message))
      ((CodexExecServerClientErrorClosed)
       (CodexExecServerRemoteFsIoError
         (CodexExecServerRemoteFsErrorKindBrokenPipe)
         "exec-server transport closed"))
      ((CodexExecServerClientErrorDisconnected $message)
       (CodexExecServerRemoteFsIoError
         (CodexExecServerRemoteFsErrorKindBrokenPipe)
         "exec-server transport closed"))
      ($other
       (CodexExecServerRemoteFsIoError
         (CodexExecServerRemoteFsErrorKindOther)
         (codex:exec-server-remote-fs-error-display $other))))))

(= (codex:exec-server-remote-fs-client-get-ok $client)
   (CodexExecServerRemoteFsClientGetOk $client))

(= (codex:exec-server-remote-fs-client-get-err $error)
   (CodexExecServerRemoteFsClientGetErr $error))

(= (codex:exec-server-remote-fs-call-ok $response)
   (CodexExecServerRemoteFsCallOk $response))

(= (codex:exec-server-remote-fs-call-err $error)
   (CodexExecServerRemoteFsCallErr $error))

(= (codex:exec-server-remote-fs-base64-decode-ok $bytes)
   (CodexExecServerRemoteFsBase64DecodeOk $bytes))

(= (codex:exec-server-remote-fs-base64-decode-err $message)
   (CodexExecServerRemoteFsBase64DecodeErr $message))

(= (codex:exec-server-remote-fs-result-ok $params $value)
   (CodexExecServerRemoteFsResultOk $params $value))

(= (codex:exec-server-remote-fs-result-err $params $error)
   (CodexExecServerRemoteFsResultErr $params $error))

(= (codex:exec-server-remote-fs-result-params
      (CodexExecServerRemoteFsResultOk $params $value))
   $params)

(= (codex:exec-server-remote-fs-result-params
      (CodexExecServerRemoteFsResultErr $params $error))
   $params)

(= (codex:exec-server-remote-fs-result-value
      (CodexExecServerRemoteFsResultOk $params $value))
   $value)

(= (codex:exec-server-remote-fs-result-error
      (CodexExecServerRemoteFsResultErr $params $error))
   $error)

(= (codex:exec-server-remote-fs-unit)
   (CodexExecServerRemoteFsUnit))

(= (codex:exec-server-remote-fs-remote-sandbox-context $sandbox)
   (if (== $sandbox CodexAbsent)
       CodexAbsent
       (codex:fs-sandbox-context-drop-cwd-if-unused $sandbox)))

(= (codex:exec-server-remote-fs-read-file-invalid-data-message
      $decode-error)
   (str-concat
     "remote fs/readFile returned invalid base64 dataBase64: "
     $decode-error))

(= (codex:exec-server-remote-fs-read-file-flow
      $path
      $sandbox
      (CodexExecServerRemoteFsClientGetErr $error)
      $call-outcome
      $decode-outcome)
   (CodexExecServerRemoteFsResultErr
     CodexAbsent
     (codex:exec-server-remote-fs-map-remote-error $error)))

(= (codex:exec-server-remote-fs-read-file-flow
      $path
      $sandbox
      (CodexExecServerRemoteFsClientGetOk $client)
      (CodexExecServerRemoteFsCallErr $error)
      $decode-outcome)
   (let $params
     (CodexExecServerFsReadFileParams
       $path
       (codex:exec-server-remote-fs-remote-sandbox-context $sandbox))
     (CodexExecServerRemoteFsResultErr
       $params
       (codex:exec-server-remote-fs-map-remote-error $error))))

(= (codex:exec-server-remote-fs-read-file-flow
      $path
      $sandbox
      (CodexExecServerRemoteFsClientGetOk $client)
      (CodexExecServerRemoteFsCallOk
        (CodexExecServerFsReadFileResponse $data-base64))
      (CodexExecServerRemoteFsBase64DecodeErr $message))
   (let $params
     (CodexExecServerFsReadFileParams
       $path
       (codex:exec-server-remote-fs-remote-sandbox-context $sandbox))
     (CodexExecServerRemoteFsResultErr
       $params
       (CodexExecServerRemoteFsIoError
         (CodexExecServerRemoteFsErrorKindInvalidData)
         (codex:exec-server-remote-fs-read-file-invalid-data-message
           $message)))))

(= (codex:exec-server-remote-fs-read-file-flow
      $path
      $sandbox
      (CodexExecServerRemoteFsClientGetOk $client)
      (CodexExecServerRemoteFsCallOk
        (CodexExecServerFsReadFileResponse $data-base64))
      (CodexExecServerRemoteFsBase64DecodeOk $bytes))
   (let $params
     (CodexExecServerFsReadFileParams
       $path
       (codex:exec-server-remote-fs-remote-sandbox-context $sandbox))
     (CodexExecServerRemoteFsResultOk $params $bytes)))

(= (codex:exec-server-remote-fs-write-file-flow
      $path
      $contents
      $sandbox
      (CodexExecServerRemoteFsClientGetErr $error)
      $call-outcome)
   (CodexExecServerRemoteFsResultErr
     CodexAbsent
     (codex:exec-server-remote-fs-map-remote-error $error)))

(= (codex:exec-server-remote-fs-write-file-flow
      $path
      $contents
      $sandbox
      (CodexExecServerRemoteFsClientGetOk $client)
      (CodexExecServerRemoteFsCallErr $error))
   (let $params
     (CodexExecServerFsWriteFileParams
       $path
       (str-base64-encode $contents)
       (codex:exec-server-remote-fs-remote-sandbox-context $sandbox))
     (CodexExecServerRemoteFsResultErr
       $params
       (codex:exec-server-remote-fs-map-remote-error $error))))

(= (codex:exec-server-remote-fs-write-file-flow
      $path
      $contents
      $sandbox
      (CodexExecServerRemoteFsClientGetOk $client)
      (CodexExecServerRemoteFsCallOk $response))
   (let $params
     (CodexExecServerFsWriteFileParams
       $path
       (str-base64-encode $contents)
       (codex:exec-server-remote-fs-remote-sandbox-context $sandbox))
     (CodexExecServerRemoteFsResultOk
       $params
       (CodexExecServerRemoteFsUnit))))

(= (codex:exec-server-remote-fs-create-directory-flow
      $path
      (CodexExecServerCreateDirectoryOptions $recursive)
      $sandbox
      (CodexExecServerRemoteFsClientGetErr $error)
      $call-outcome)
   (CodexExecServerRemoteFsResultErr
     CodexAbsent
     (codex:exec-server-remote-fs-map-remote-error $error)))

(= (codex:exec-server-remote-fs-create-directory-flow
      $path
      (CodexExecServerCreateDirectoryOptions $recursive)
      $sandbox
      (CodexExecServerRemoteFsClientGetOk $client)
      (CodexExecServerRemoteFsCallErr $error))
   (let $params
     (CodexExecServerFsCreateDirectoryParams
       $path
       $recursive
       (codex:exec-server-remote-fs-remote-sandbox-context $sandbox))
     (CodexExecServerRemoteFsResultErr
       $params
       (codex:exec-server-remote-fs-map-remote-error $error))))

(= (codex:exec-server-remote-fs-create-directory-flow
      $path
      (CodexExecServerCreateDirectoryOptions $recursive)
      $sandbox
      (CodexExecServerRemoteFsClientGetOk $client)
      (CodexExecServerRemoteFsCallOk $response))
   (let $params
     (CodexExecServerFsCreateDirectoryParams
       $path
       $recursive
       (codex:exec-server-remote-fs-remote-sandbox-context $sandbox))
     (CodexExecServerRemoteFsResultOk
       $params
       (CodexExecServerRemoteFsUnit))))

(= (codex:exec-server-remote-fs-get-metadata-flow
      $path
      $sandbox
      (CodexExecServerRemoteFsClientGetErr $error)
      $call-outcome)
   (CodexExecServerRemoteFsResultErr
     CodexAbsent
     (codex:exec-server-remote-fs-map-remote-error $error)))

(= (codex:exec-server-remote-fs-get-metadata-flow
      $path
      $sandbox
      (CodexExecServerRemoteFsClientGetOk $client)
      (CodexExecServerRemoteFsCallErr $error))
   (let $params
     (CodexExecServerFsGetMetadataParams
       $path
       (codex:exec-server-remote-fs-remote-sandbox-context $sandbox))
     (CodexExecServerRemoteFsResultErr
       $params
       (codex:exec-server-remote-fs-map-remote-error $error))))

(= (codex:exec-server-remote-fs-get-metadata-flow
      $path
      $sandbox
      (CodexExecServerRemoteFsClientGetOk $client)
      (CodexExecServerRemoteFsCallOk
        (CodexExecServerFsGetMetadataResponse
          $is-directory
          $is-file
          $is-symlink
          $created-at-ms
          $modified-at-ms)))
   (let $params
     (CodexExecServerFsGetMetadataParams
       $path
       (codex:exec-server-remote-fs-remote-sandbox-context $sandbox))
     (CodexExecServerRemoteFsResultOk
       $params
       (CodexExecServerFileMetadata
         $is-directory
         $is-file
         $is-symlink
         $created-at-ms
         $modified-at-ms))))

(= (codex:exec-server-remote-fs-read-directory-entry
      $file-name
      $is-directory
      $is-file)
   (CodexExecServerRemoteFsReadDirectoryEntry
     $file-name
     $is-directory
     $is-file))

(= (codex:exec-server-remote-fs-read-directory-entry-file-name
      (CodexExecServerRemoteFsReadDirectoryEntry
        $file-name
        $is-directory
        $is-file))
   $file-name)

(= (codex:exec-server-remote-fs-read-directory-entries ())
   ())

(= (codex:exec-server-remote-fs-read-directory-entries $entries)
   (let $head (list:first $entries)
     (let $tail (list:rest $entries)
       (case $head
         (((CodexExecServerFsReadDirectoryEntry
             $file-name
             $is-directory
             $is-file)
           (list:cons
             (CodexExecServerRemoteFsReadDirectoryEntry
               $file-name
               $is-directory
               $is-file)
             (codex:exec-server-remote-fs-read-directory-entries
               $tail))))))))

(= (codex:exec-server-remote-fs-read-directory-flow
      $path
      $sandbox
      (CodexExecServerRemoteFsClientGetErr $error)
      $call-outcome)
   (CodexExecServerRemoteFsResultErr
     CodexAbsent
     (codex:exec-server-remote-fs-map-remote-error $error)))

(= (codex:exec-server-remote-fs-read-directory-flow
      $path
      $sandbox
      (CodexExecServerRemoteFsClientGetOk $client)
      (CodexExecServerRemoteFsCallErr $error))
   (let $params
     (CodexExecServerFsReadDirectoryParams
       $path
       (codex:exec-server-remote-fs-remote-sandbox-context $sandbox))
     (CodexExecServerRemoteFsResultErr
       $params
       (codex:exec-server-remote-fs-map-remote-error $error))))

(= (codex:exec-server-remote-fs-read-directory-flow
      $path
      $sandbox
      (CodexExecServerRemoteFsClientGetOk $client)
      (CodexExecServerRemoteFsCallOk
        (CodexExecServerFsReadDirectoryResponse $entries)))
   (let $params
     (CodexExecServerFsReadDirectoryParams
       $path
       (codex:exec-server-remote-fs-remote-sandbox-context $sandbox))
     (CodexExecServerRemoteFsResultOk
       $params
       (codex:exec-server-remote-fs-read-directory-entries $entries))))

(= (codex:exec-server-remote-fs-remove-flow
      $path
      (CodexExecServerRemoveOptions $recursive $force)
      $sandbox
      (CodexExecServerRemoteFsClientGetErr $error)
      $call-outcome)
   (CodexExecServerRemoteFsResultErr
     CodexAbsent
     (codex:exec-server-remote-fs-map-remote-error $error)))

(= (codex:exec-server-remote-fs-remove-flow
      $path
      (CodexExecServerRemoveOptions $recursive $force)
      $sandbox
      (CodexExecServerRemoteFsClientGetOk $client)
      (CodexExecServerRemoteFsCallErr $error))
   (let $params
     (CodexExecServerFsRemoveParams
       $path
       $recursive
       $force
       (codex:exec-server-remote-fs-remote-sandbox-context $sandbox))
     (CodexExecServerRemoteFsResultErr
       $params
       (codex:exec-server-remote-fs-map-remote-error $error))))

(= (codex:exec-server-remote-fs-remove-flow
      $path
      (CodexExecServerRemoveOptions $recursive $force)
      $sandbox
      (CodexExecServerRemoteFsClientGetOk $client)
      (CodexExecServerRemoteFsCallOk $response))
   (let $params
     (CodexExecServerFsRemoveParams
       $path
       $recursive
       $force
       (codex:exec-server-remote-fs-remote-sandbox-context $sandbox))
     (CodexExecServerRemoteFsResultOk
       $params
       (CodexExecServerRemoteFsUnit))))

(= (codex:exec-server-remote-fs-copy-flow
      $source-path
      $destination-path
      (CodexExecServerCopyOptions $recursive)
      $sandbox
      (CodexExecServerRemoteFsClientGetErr $error)
      $call-outcome)
   (CodexExecServerRemoteFsResultErr
     CodexAbsent
     (codex:exec-server-remote-fs-map-remote-error $error)))

(= (codex:exec-server-remote-fs-copy-flow
      $source-path
      $destination-path
      (CodexExecServerCopyOptions $recursive)
      $sandbox
      (CodexExecServerRemoteFsClientGetOk $client)
      (CodexExecServerRemoteFsCallErr $error))
   (let $params
     (CodexExecServerFsCopyParams
       $source-path
       $destination-path
       $recursive
       (codex:exec-server-remote-fs-remote-sandbox-context $sandbox))
     (CodexExecServerRemoteFsResultErr
       $params
       (codex:exec-server-remote-fs-map-remote-error $error))))

(= (codex:exec-server-remote-fs-copy-flow
      $source-path
      $destination-path
      (CodexExecServerCopyOptions $recursive)
      $sandbox
      (CodexExecServerRemoteFsClientGetOk $client)
      (CodexExecServerRemoteFsCallOk $response))
   (let $params
     (CodexExecServerFsCopyParams
       $source-path
       $destination-path
       $recursive
       (codex:exec-server-remote-fs-remote-sandbox-context $sandbox))
     (CodexExecServerRemoteFsResultOk
       $params
       (CodexExecServerRemoteFsUnit))))
