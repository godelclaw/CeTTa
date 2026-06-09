; Rust-faithful exec-server filesystem helper slice.
;
; This ports deterministic behavior from:
; - openai-codex/codex-rs/exec-server/src/fs_helper.rs
;   - CODEX_FS_HELPER_ARG1
;   - FsHelperRequest / FsHelperResponse / FsHelperPayload serde envelopes
;   - FsHelperPayload operation and expect_* mismatch policy
;   - run_direct_request response shaping, option defaults, and error mapping
; - openai-codex/codex-rs/exec-server/src/fs_helper_main.rs
;   - main runtime startup, run_main exit-code, and stderr policy
;   - run_main stdin read, request parse, response wrapping, response
;     serialization, stdout write, and newline write ordering
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust executes filesystem operations asynchronously through DirectFileSystem.
;   This pure slice takes symbolic direct-operation outcomes at that runtime
;   boundary while preserving the same request dispatch, option defaults,
;   response shaping, and JSON-RPC error mapping.
; - Rust decodes write-file standard base64 into arbitrary bytes before calling
;   DirectFileSystem. CeTTa currently has standard base64 encoding but not a
;   standard base64 decoder, so this slice takes a symbolic decode outcome and
;   preserves the exact invalid-request branch and message prefix from Rust.
; - Rust byte vectors may contain arbitrary bytes. This slice represents bytes
;   as current CeTTa text at the boundary; binary materialization belongs in
;   the eventual filesystem runtime bridge.
; - Rust `main` and `run_main` perform tokio runtime startup, stdin/stdout I/O,
;   serde parsing, and serde serialization. This slice takes those runtime
;   outcomes symbolically while preserving Rust's branch order, response
;   wrapping, stderr text, and stdout write/newline ordering.

!(import! &self json)
!(import! &self str)
!(import! &self exec_server_rpc)
!(import! &self exec_server_file_system_protocol)

(= (codex:exec-server-fs-helper-arg1)
   "--codex-run-as-fs-helper")

(= (codex:exec-server-fs-helper-request-read-file $params)
   (CodexExecServerFsHelperRequestReadFile $params))

(= (codex:exec-server-fs-helper-request-write-file $params)
   (CodexExecServerFsHelperRequestWriteFile $params))

(= (codex:exec-server-fs-helper-request-create-directory $params)
   (CodexExecServerFsHelperRequestCreateDirectory $params))

(= (codex:exec-server-fs-helper-request-get-metadata $params)
   (CodexExecServerFsHelperRequestGetMetadata $params))

(= (codex:exec-server-fs-helper-request-read-directory $params)
   (CodexExecServerFsHelperRequestReadDirectory $params))

(= (codex:exec-server-fs-helper-request-remove $params)
   (CodexExecServerFsHelperRequestRemove $params))

(= (codex:exec-server-fs-helper-request-copy $params)
   (CodexExecServerFsHelperRequestCopy $params))

(= (codex:exec-server-fs-helper-request-operation
      (CodexExecServerFsHelperRequestReadFile $params))
   (codex:exec-server-fs-read-file-method))

(= (codex:exec-server-fs-helper-request-operation
      (CodexExecServerFsHelperRequestWriteFile $params))
   (codex:exec-server-fs-write-file-method))

(= (codex:exec-server-fs-helper-request-operation
      (CodexExecServerFsHelperRequestCreateDirectory $params))
   (codex:exec-server-fs-create-directory-method))

(= (codex:exec-server-fs-helper-request-operation
      (CodexExecServerFsHelperRequestGetMetadata $params))
   (codex:exec-server-fs-get-metadata-method))

(= (codex:exec-server-fs-helper-request-operation
      (CodexExecServerFsHelperRequestReadDirectory $params))
   (codex:exec-server-fs-read-directory-method))

(= (codex:exec-server-fs-helper-request-operation
      (CodexExecServerFsHelperRequestRemove $params))
   (codex:exec-server-fs-remove-method))

(= (codex:exec-server-fs-helper-request-operation
      (CodexExecServerFsHelperRequestCopy $params))
   (codex:exec-server-fs-copy-method))

(= (codex:exec-server-fs-helper-request-params-json
      (CodexExecServerFsHelperRequestReadFile $params))
   (codex:exec-server-fs-read-file-params-json $params))

(= (codex:exec-server-fs-helper-request-params-json
      (CodexExecServerFsHelperRequestWriteFile $params))
   (codex:exec-server-fs-write-file-params-json $params))

(= (codex:exec-server-fs-helper-request-params-json
      (CodexExecServerFsHelperRequestCreateDirectory $params))
   (codex:exec-server-fs-create-directory-params-json $params))

(= (codex:exec-server-fs-helper-request-params-json
      (CodexExecServerFsHelperRequestGetMetadata $params))
   (codex:exec-server-fs-get-metadata-params-json $params))

(= (codex:exec-server-fs-helper-request-params-json
      (CodexExecServerFsHelperRequestReadDirectory $params))
   (codex:exec-server-fs-read-directory-params-json $params))

(= (codex:exec-server-fs-helper-request-params-json
      (CodexExecServerFsHelperRequestRemove $params))
   (codex:exec-server-fs-remove-params-json $params))

(= (codex:exec-server-fs-helper-request-params-json
      (CodexExecServerFsHelperRequestCopy $params))
   (codex:exec-server-fs-copy-params-json $params))

(= (codex:exec-server-fs-helper-request-json $request)
   (JsonObject
     ((JsonPair
        "operation"
        (JsonString
          (codex:exec-server-fs-helper-request-operation $request)))
      (JsonPair
        "params"
        (codex:exec-server-fs-helper-request-params-json $request)))))

(= (codex:exec-server-fs-helper-payload-read-file $response)
   (CodexExecServerFsHelperPayloadReadFile $response))

(= (codex:exec-server-fs-helper-payload-write-file $response)
   (CodexExecServerFsHelperPayloadWriteFile $response))

(= (codex:exec-server-fs-helper-payload-create-directory $response)
   (CodexExecServerFsHelperPayloadCreateDirectory $response))

(= (codex:exec-server-fs-helper-payload-get-metadata $response)
   (CodexExecServerFsHelperPayloadGetMetadata $response))

(= (codex:exec-server-fs-helper-payload-read-directory $response)
   (CodexExecServerFsHelperPayloadReadDirectory $response))

(= (codex:exec-server-fs-helper-payload-remove $response)
   (CodexExecServerFsHelperPayloadRemove $response))

(= (codex:exec-server-fs-helper-payload-copy $response)
   (CodexExecServerFsHelperPayloadCopy $response))

(= (codex:exec-server-fs-helper-payload-operation
      (CodexExecServerFsHelperPayloadReadFile $response))
   (codex:exec-server-fs-read-file-method))

(= (codex:exec-server-fs-helper-payload-operation
      (CodexExecServerFsHelperPayloadWriteFile $response))
   (codex:exec-server-fs-write-file-method))

(= (codex:exec-server-fs-helper-payload-operation
      (CodexExecServerFsHelperPayloadCreateDirectory $response))
   (codex:exec-server-fs-create-directory-method))

(= (codex:exec-server-fs-helper-payload-operation
      (CodexExecServerFsHelperPayloadGetMetadata $response))
   (codex:exec-server-fs-get-metadata-method))

(= (codex:exec-server-fs-helper-payload-operation
      (CodexExecServerFsHelperPayloadReadDirectory $response))
   (codex:exec-server-fs-read-directory-method))

(= (codex:exec-server-fs-helper-payload-operation
      (CodexExecServerFsHelperPayloadRemove $response))
   (codex:exec-server-fs-remove-method))

(= (codex:exec-server-fs-helper-payload-operation
      (CodexExecServerFsHelperPayloadCopy $response))
   (codex:exec-server-fs-copy-method))

(= (codex:exec-server-fs-helper-payload-response-json
      (CodexExecServerFsHelperPayloadReadFile $response))
   (codex:exec-server-fs-read-file-response-json $response))

(= (codex:exec-server-fs-helper-payload-response-json
      (CodexExecServerFsHelperPayloadWriteFile $response))
   (codex:exec-server-fs-write-file-response-json $response))

(= (codex:exec-server-fs-helper-payload-response-json
      (CodexExecServerFsHelperPayloadCreateDirectory $response))
   (codex:exec-server-fs-create-directory-response-json $response))

(= (codex:exec-server-fs-helper-payload-response-json
      (CodexExecServerFsHelperPayloadGetMetadata $response))
   (codex:exec-server-fs-get-metadata-response-json $response))

(= (codex:exec-server-fs-helper-payload-response-json
      (CodexExecServerFsHelperPayloadReadDirectory $response))
   (codex:exec-server-fs-read-directory-response-json $response))

(= (codex:exec-server-fs-helper-payload-response-json
      (CodexExecServerFsHelperPayloadRemove $response))
   (codex:exec-server-fs-remove-response-json $response))

(= (codex:exec-server-fs-helper-payload-response-json
      (CodexExecServerFsHelperPayloadCopy $response))
   (codex:exec-server-fs-copy-response-json $response))

(= (codex:exec-server-fs-helper-payload-json $payload)
   (JsonObject
     ((JsonPair
        "operation"
        (JsonString
          (codex:exec-server-fs-helper-payload-operation $payload)))
      (JsonPair
        "response"
        (codex:exec-server-fs-helper-payload-response-json $payload)))))

(= (codex:exec-server-fs-helper-response-ok $payload)
   (CodexExecServerFsHelperResponseOk $payload))

(= (codex:exec-server-fs-helper-response-error $error)
   (CodexExecServerFsHelperResponseError $error))

(= (codex:exec-server-fs-helper-response-json
      (CodexExecServerFsHelperResponseOk $payload))
   (JsonObject
     ((JsonPair "status" (JsonString "ok"))
      (JsonPair
        "payload"
        (codex:exec-server-fs-helper-payload-json $payload)))))

(= (codex:exec-server-fs-helper-response-json
      (CodexExecServerFsHelperResponseError $error))
   (JsonObject
     ((JsonPair "status" (JsonString "error"))
      (JsonPair
        "payload"
        (codex:exec-server-rpc-error-error-json $error)))))

(= (codex:exec-server-fs-helper-result-ok $value)
   (CodexExecServerFsHelperResultOk $value))

(= (codex:exec-server-fs-helper-result-err $error)
   (CodexExecServerFsHelperResultErr $error))

(= (codex:exec-server-fs-helper-result-value
      (CodexExecServerFsHelperResultOk $value))
   $value)

(= (codex:exec-server-fs-helper-result-error
      (CodexExecServerFsHelperResultErr $error))
   $error)

(= (codex:exec-server-fs-helper-unexpected-response
      $expected
      $actual)
   (codex:exec-server-rpc-internal-error
     (format-args
       "unexpected fs sandbox helper response: expected {}, got {}"
       ($expected $actual))))

(= (codex:exec-server-fs-helper-expect-read-file $payload)
   (case $payload
     (((CodexExecServerFsHelperPayloadReadFile $response)
       (CodexExecServerFsHelperResultOk $response))
      ($other
       (CodexExecServerFsHelperResultErr
         (codex:exec-server-fs-helper-unexpected-response
           (codex:exec-server-fs-read-file-method)
           (codex:exec-server-fs-helper-payload-operation $other)))))))

(= (codex:exec-server-fs-helper-expect-write-file $payload)
   (case $payload
     (((CodexExecServerFsHelperPayloadWriteFile $response)
       (CodexExecServerFsHelperResultOk $response))
      ($other
       (CodexExecServerFsHelperResultErr
         (codex:exec-server-fs-helper-unexpected-response
           (codex:exec-server-fs-write-file-method)
           (codex:exec-server-fs-helper-payload-operation $other)))))))

(= (codex:exec-server-fs-helper-expect-create-directory $payload)
   (case $payload
     (((CodexExecServerFsHelperPayloadCreateDirectory $response)
       (CodexExecServerFsHelperResultOk $response))
      ($other
       (CodexExecServerFsHelperResultErr
         (codex:exec-server-fs-helper-unexpected-response
           (codex:exec-server-fs-create-directory-method)
           (codex:exec-server-fs-helper-payload-operation $other)))))))

(= (codex:exec-server-fs-helper-expect-get-metadata $payload)
   (case $payload
     (((CodexExecServerFsHelperPayloadGetMetadata $response)
       (CodexExecServerFsHelperResultOk $response))
      ($other
       (CodexExecServerFsHelperResultErr
         (codex:exec-server-fs-helper-unexpected-response
           (codex:exec-server-fs-get-metadata-method)
           (codex:exec-server-fs-helper-payload-operation $other)))))))

(= (codex:exec-server-fs-helper-expect-read-directory $payload)
   (case $payload
     (((CodexExecServerFsHelperPayloadReadDirectory $response)
       (CodexExecServerFsHelperResultOk $response))
      ($other
       (CodexExecServerFsHelperResultErr
         (codex:exec-server-fs-helper-unexpected-response
           (codex:exec-server-fs-read-directory-method)
           (codex:exec-server-fs-helper-payload-operation $other)))))))

(= (codex:exec-server-fs-helper-expect-remove $payload)
   (case $payload
     (((CodexExecServerFsHelperPayloadRemove $response)
       (CodexExecServerFsHelperResultOk $response))
      ($other
       (CodexExecServerFsHelperResultErr
         (codex:exec-server-fs-helper-unexpected-response
           (codex:exec-server-fs-remove-method)
           (codex:exec-server-fs-helper-payload-operation $other)))))))

(= (codex:exec-server-fs-helper-expect-copy $payload)
   (case $payload
     (((CodexExecServerFsHelperPayloadCopy $response)
       (CodexExecServerFsHelperResultOk $response))
      ($other
       (CodexExecServerFsHelperResultErr
         (codex:exec-server-fs-helper-unexpected-response
           (codex:exec-server-fs-copy-method)
           (codex:exec-server-fs-helper-payload-operation $other)))))))

(= (codex:exec-server-fs-helper-error-kind-not-found)
   (CodexExecServerFsHelperErrorKindNotFound))

(= (codex:exec-server-fs-helper-error-kind-invalid-input)
   (CodexExecServerFsHelperErrorKindInvalidInput))

(= (codex:exec-server-fs-helper-error-kind-permission-denied)
   (CodexExecServerFsHelperErrorKindPermissionDenied))

(= (codex:exec-server-fs-helper-error-kind-other)
   (CodexExecServerFsHelperErrorKindOther))

(= (codex:exec-server-fs-helper-file-system-error $kind $message)
   (CodexExecServerFsHelperFileSystemError $kind $message))

(= (codex:exec-server-fs-helper-map-fs-error
      (CodexExecServerFsHelperFileSystemError
        (CodexExecServerFsHelperErrorKindNotFound)
        $message))
   (codex:exec-server-rpc-not-found $message))

(= (codex:exec-server-fs-helper-map-fs-error
      (CodexExecServerFsHelperFileSystemError
        (CodexExecServerFsHelperErrorKindInvalidInput)
        $message))
   (codex:exec-server-rpc-invalid-request $message))

(= (codex:exec-server-fs-helper-map-fs-error
      (CodexExecServerFsHelperFileSystemError
        (CodexExecServerFsHelperErrorKindPermissionDenied)
        $message))
   (codex:exec-server-rpc-invalid-request $message))

(= (codex:exec-server-fs-helper-map-fs-error
      (CodexExecServerFsHelperFileSystemError
        (CodexExecServerFsHelperErrorKindOther)
        $message))
   (codex:exec-server-rpc-internal-error $message))

(= (codex:exec-server-fs-helper-base64-decode-ok $bytes)
   (CodexExecServerFsHelperBase64DecodeOk $bytes))

(= (codex:exec-server-fs-helper-base64-decode-err $message)
   (CodexExecServerFsHelperBase64DecodeErr $message))

(= (codex:exec-server-fs-helper-direct-operation-read-file-ok $bytes)
   (CodexExecServerFsHelperDirectOperationReadFileOk $bytes))

(= (codex:exec-server-fs-helper-direct-operation-write-file-ok)
   (CodexExecServerFsHelperDirectOperationWriteFileOk))

(= (codex:exec-server-fs-helper-direct-operation-create-directory-ok)
   (CodexExecServerFsHelperDirectOperationCreateDirectoryOk))

(= (codex:exec-server-fs-helper-direct-operation-get-metadata-ok $metadata)
   (CodexExecServerFsHelperDirectOperationGetMetadataOk $metadata))

(= (codex:exec-server-fs-helper-direct-operation-read-directory-ok $entries)
   (CodexExecServerFsHelperDirectOperationReadDirectoryOk $entries))

(= (codex:exec-server-fs-helper-direct-operation-remove-ok)
   (CodexExecServerFsHelperDirectOperationRemoveOk))

(= (codex:exec-server-fs-helper-direct-operation-copy-ok)
   (CodexExecServerFsHelperDirectOperationCopyOk))

(= (codex:exec-server-fs-helper-direct-operation-err $error)
   (CodexExecServerFsHelperDirectOperationErr $error))

(= (codex:exec-server-fs-helper-option-bool-or-true $value)
   (if (== $value CodexAbsent)
       True
       $value))

(= (codex:exec-server-fs-helper-create-directory-options-from-params
      (CodexExecServerFsCreateDirectoryParams $path $recursive $sandbox))
   (CodexExecServerCreateDirectoryOptions
     (codex:exec-server-fs-helper-option-bool-or-true $recursive)))

(= (codex:exec-server-fs-helper-remove-options-from-params
      (CodexExecServerFsRemoveParams $path $recursive $force $sandbox))
   (CodexExecServerRemoveOptions
     (codex:exec-server-fs-helper-option-bool-or-true $recursive)
     (codex:exec-server-fs-helper-option-bool-or-true $force)))

(= (codex:exec-server-fs-helper-copy-options-from-params
      (CodexExecServerFsCopyParams
        $source-path
        $destination-path
        $recursive
        $sandbox))
   (CodexExecServerCopyOptions $recursive))

(= (codex:exec-server-fs-helper-run-direct-read-file
      (CodexExecServerFsReadFileParams $path $sandbox)
      $operation-outcome)
   (case $operation-outcome
     (((CodexExecServerFsHelperDirectOperationReadFileOk $bytes)
       (CodexExecServerFsHelperResultOk
         (CodexExecServerFsHelperPayloadReadFile
           (CodexExecServerFsReadFileResponse
             (str-base64-encode $bytes)))))
      ((CodexExecServerFsHelperDirectOperationErr $error)
       (CodexExecServerFsHelperResultErr
         (codex:exec-server-fs-helper-map-fs-error $error))))))

(= (codex:exec-server-fs-helper-run-direct-write-file
      (CodexExecServerFsWriteFileParams $path $data-base64 $sandbox)
      $decode-outcome
      $operation-outcome)
   (case $decode-outcome
     (((CodexExecServerFsHelperBase64DecodeErr $message)
       (CodexExecServerFsHelperResultErr
         (codex:exec-server-rpc-invalid-request
           (format-args
             "{} requires valid base64 dataBase64: {}"
             ((codex:exec-server-fs-write-file-method) $message)))))
      ((CodexExecServerFsHelperBase64DecodeOk $bytes)
       (case $operation-outcome
         (((CodexExecServerFsHelperDirectOperationWriteFileOk)
           (CodexExecServerFsHelperResultOk
             (CodexExecServerFsHelperPayloadWriteFile
               (CodexExecServerFsWriteFileResponse))))
          ((CodexExecServerFsHelperDirectOperationErr $error)
           (CodexExecServerFsHelperResultErr
             (codex:exec-server-fs-helper-map-fs-error $error)))))))))

(= (codex:exec-server-fs-helper-run-direct-create-directory
      (CodexExecServerFsCreateDirectoryParams $path $recursive $sandbox)
      $operation-outcome)
   (case $operation-outcome
     (((CodexExecServerFsHelperDirectOperationCreateDirectoryOk)
       (CodexExecServerFsHelperResultOk
         (CodexExecServerFsHelperPayloadCreateDirectory
           (CodexExecServerFsCreateDirectoryResponse))))
      ((CodexExecServerFsHelperDirectOperationErr $error)
       (CodexExecServerFsHelperResultErr
         (codex:exec-server-fs-helper-map-fs-error $error))))))

(= (codex:exec-server-fs-helper-run-direct-get-metadata
      (CodexExecServerFsGetMetadataParams $path $sandbox)
      $operation-outcome)
   (case $operation-outcome
     (((CodexExecServerFsHelperDirectOperationGetMetadataOk
         (CodexExecServerFileMetadata
           $is-directory
           $is-file
           $is-symlink
           $created-at-ms
           $modified-at-ms))
       (CodexExecServerFsHelperResultOk
         (CodexExecServerFsHelperPayloadGetMetadata
           (CodexExecServerFsGetMetadataResponse
             $is-directory
             $is-file
             $is-symlink
             $created-at-ms
             $modified-at-ms))))
      ((CodexExecServerFsHelperDirectOperationErr $error)
       (CodexExecServerFsHelperResultErr
         (codex:exec-server-fs-helper-map-fs-error $error))))))

(= (codex:exec-server-fs-helper-run-direct-read-directory
      (CodexExecServerFsReadDirectoryParams $path $sandbox)
      $operation-outcome)
   (case $operation-outcome
     (((CodexExecServerFsHelperDirectOperationReadDirectoryOk $entries)
       (CodexExecServerFsHelperResultOk
         (CodexExecServerFsHelperPayloadReadDirectory
           (CodexExecServerFsReadDirectoryResponse $entries))))
      ((CodexExecServerFsHelperDirectOperationErr $error)
       (CodexExecServerFsHelperResultErr
         (codex:exec-server-fs-helper-map-fs-error $error))))))

(= (codex:exec-server-fs-helper-run-direct-remove
      (CodexExecServerFsRemoveParams $path $recursive $force $sandbox)
      $operation-outcome)
   (case $operation-outcome
     (((CodexExecServerFsHelperDirectOperationRemoveOk)
       (CodexExecServerFsHelperResultOk
         (CodexExecServerFsHelperPayloadRemove
           (CodexExecServerFsRemoveResponse))))
      ((CodexExecServerFsHelperDirectOperationErr $error)
       (CodexExecServerFsHelperResultErr
         (codex:exec-server-fs-helper-map-fs-error $error))))))

(= (codex:exec-server-fs-helper-run-direct-copy
      (CodexExecServerFsCopyParams
        $source-path
        $destination-path
        $recursive
        $sandbox)
      $operation-outcome)
   (case $operation-outcome
     (((CodexExecServerFsHelperDirectOperationCopyOk)
       (CodexExecServerFsHelperResultOk
         (CodexExecServerFsHelperPayloadCopy
           (CodexExecServerFsCopyResponse))))
      ((CodexExecServerFsHelperDirectOperationErr $error)
       (CodexExecServerFsHelperResultErr
         (codex:exec-server-fs-helper-map-fs-error $error))))))

(= (codex:exec-server-fs-helper-run-direct-request
      $request
      $decode-outcome
      $operation-outcome)
   (case $request
     (((CodexExecServerFsHelperRequestReadFile $params)
       (codex:exec-server-fs-helper-run-direct-read-file
         $params
         $operation-outcome))
      ((CodexExecServerFsHelperRequestWriteFile $params)
       (codex:exec-server-fs-helper-run-direct-write-file
         $params
         $decode-outcome
         $operation-outcome))
      ((CodexExecServerFsHelperRequestCreateDirectory $params)
       (codex:exec-server-fs-helper-run-direct-create-directory
         $params
         $operation-outcome))
      ((CodexExecServerFsHelperRequestGetMetadata $params)
       (codex:exec-server-fs-helper-run-direct-get-metadata
         $params
         $operation-outcome))
      ((CodexExecServerFsHelperRequestReadDirectory $params)
       (codex:exec-server-fs-helper-run-direct-read-directory
         $params
         $operation-outcome))
      ((CodexExecServerFsHelperRequestRemove $params)
       (codex:exec-server-fs-helper-run-direct-remove
         $params
         $operation-outcome))
      ((CodexExecServerFsHelperRequestCopy $params)
       (codex:exec-server-fs-helper-run-direct-copy
         $params
         $operation-outcome)))))

(= (codex:exec-server-fs-helper-main-runtime-ok)
   (CodexExecServerFsHelperMainRuntimeOk))

(= (codex:exec-server-fs-helper-main-runtime-err $message)
   (CodexExecServerFsHelperMainRuntimeErr $message))

(= (codex:exec-server-fs-helper-run-main-read-stdin-ok $input)
   (CodexExecServerFsHelperRunMainReadStdinOk $input))

(= (codex:exec-server-fs-helper-run-main-read-stdin-err $message)
   (CodexExecServerFsHelperRunMainReadStdinErr $message))

(= (codex:exec-server-fs-helper-run-main-parse-request-ok $request)
   (CodexExecServerFsHelperRunMainParseRequestOk $request))

(= (codex:exec-server-fs-helper-run-main-parse-request-err $message)
   (CodexExecServerFsHelperRunMainParseRequestErr $message))

(= (codex:exec-server-fs-helper-run-main-direct-ok $payload)
   (CodexExecServerFsHelperResultOk $payload))

(= (codex:exec-server-fs-helper-run-main-direct-err $error)
   (CodexExecServerFsHelperResultErr $error))

(= (codex:exec-server-fs-helper-run-main-serialize-response-ok $text)
   (CodexExecServerFsHelperRunMainSerializeResponseOk $text))

(= (codex:exec-server-fs-helper-run-main-serialize-response-err
      $message)
   (CodexExecServerFsHelperRunMainSerializeResponseErr $message))

(= (codex:exec-server-fs-helper-run-main-write-response-ok)
   (CodexExecServerFsHelperRunMainWriteResponseOk))

(= (codex:exec-server-fs-helper-run-main-write-response-err $message)
   (CodexExecServerFsHelperRunMainWriteResponseErr $message))

(= (codex:exec-server-fs-helper-run-main-write-newline-ok)
   (CodexExecServerFsHelperRunMainWriteNewlineOk))

(= (codex:exec-server-fs-helper-run-main-write-newline-err $message)
   (CodexExecServerFsHelperRunMainWriteNewlineErr $message))

(= (codex:exec-server-fs-helper-run-main-result-ok $stdout)
   (CodexExecServerFsHelperRunMainResultOk $stdout))

(= (codex:exec-server-fs-helper-run-main-result-err
      $stdout
      $message)
   (CodexExecServerFsHelperRunMainResultErr $stdout $message))

(= (codex:exec-server-fs-helper-run-main-result-stdout
      (CodexExecServerFsHelperRunMainResultOk $stdout))
   $stdout)

(= (codex:exec-server-fs-helper-run-main-result-stdout
      (CodexExecServerFsHelperRunMainResultErr $stdout $message))
   $stdout)

(= (codex:exec-server-fs-helper-run-main-result-error
      (CodexExecServerFsHelperRunMainResultErr $stdout $message))
   $message)

(= (codex:exec-server-fs-helper-main-result
      $exit-code
      $stderr)
   (CodexExecServerFsHelperMainResult $exit-code $stderr))

(= (codex:exec-server-fs-helper-main-exit-code
      (CodexExecServerFsHelperMainResult $exit-code $stderr))
   $exit-code)

(= (codex:exec-server-fs-helper-main-stderr
      (CodexExecServerFsHelperMainResult $exit-code $stderr))
   $stderr)

(= (codex:exec-server-fs-helper-main-run-main-ok)
   (CodexExecServerFsHelperRunMainResultOk ""))

(= (codex:exec-server-fs-helper-main-run-main-err $message)
   (CodexExecServerFsHelperRunMainResultErr "" $message))

(= (codex:exec-server-fs-helper-main-eprintln-stderr $message)
   (str-concat $message "\n"))

(= (codex:exec-server-fs-helper-main-flow
      (CodexExecServerFsHelperMainRuntimeErr $message)
      $run-main-result)
   (CodexExecServerFsHelperMainResult
     1
     (codex:exec-server-fs-helper-main-eprintln-stderr
       (format-args
         "failed to start fs sandbox helper runtime: {}"
         ($message)))))

(= (codex:exec-server-fs-helper-main-flow
      (CodexExecServerFsHelperMainRuntimeOk)
      (CodexExecServerFsHelperRunMainResultOk $stdout))
   (CodexExecServerFsHelperMainResult 0 CodexAbsent))

(= (codex:exec-server-fs-helper-main-flow
      (CodexExecServerFsHelperMainRuntimeOk)
      (CodexExecServerFsHelperRunMainResultErr $stdout $message))
   (CodexExecServerFsHelperMainResult
     1
     (codex:exec-server-fs-helper-main-eprintln-stderr
       (format-args "fs sandbox helper failed: {}" ($message)))))

(= (codex:exec-server-fs-helper-main-response-from-direct
      (CodexExecServerFsHelperResultOk $payload))
   (CodexExecServerFsHelperResponseOk $payload))

(= (codex:exec-server-fs-helper-main-response-from-direct
      (CodexExecServerFsHelperResultErr $error))
   (CodexExecServerFsHelperResponseError $error))

(= (codex:exec-server-fs-helper-run-main-after-response
      $response
      (CodexExecServerFsHelperRunMainSerializeResponseErr $message)
      $write-response-outcome
      $write-newline-outcome)
   (CodexExecServerFsHelperRunMainResultErr "" $message))

(= (codex:exec-server-fs-helper-run-main-after-response
      $response
      (CodexExecServerFsHelperRunMainSerializeResponseOk $text)
      (CodexExecServerFsHelperRunMainWriteResponseErr $message)
      $write-newline-outcome)
   (CodexExecServerFsHelperRunMainResultErr "" $message))

(= (codex:exec-server-fs-helper-run-main-after-response
      $response
      (CodexExecServerFsHelperRunMainSerializeResponseOk $text)
      (CodexExecServerFsHelperRunMainWriteResponseOk)
      (CodexExecServerFsHelperRunMainWriteNewlineErr $message))
   (CodexExecServerFsHelperRunMainResultErr $text $message))

(= (codex:exec-server-fs-helper-run-main-after-response
      $response
      (CodexExecServerFsHelperRunMainSerializeResponseOk $text)
      (CodexExecServerFsHelperRunMainWriteResponseOk)
      (CodexExecServerFsHelperRunMainWriteNewlineOk))
   (CodexExecServerFsHelperRunMainResultOk
     (str-concat $text "\n")))

(= (codex:exec-server-fs-helper-run-main-after-direct
      $direct-outcome
      $serialize-outcome
      $write-response-outcome
      $write-newline-outcome)
   (codex:exec-server-fs-helper-run-main-after-response
     (codex:exec-server-fs-helper-main-response-from-direct
       $direct-outcome)
     $serialize-outcome
     $write-response-outcome
     $write-newline-outcome))

(= (codex:exec-server-fs-helper-run-main-after-parse
      $request
      $direct-outcome
      $serialize-outcome
      $write-response-outcome
      $write-newline-outcome)
   (codex:exec-server-fs-helper-run-main-after-direct
     $direct-outcome
     $serialize-outcome
     $write-response-outcome
     $write-newline-outcome))

(= (codex:exec-server-fs-helper-run-main-flow
      (CodexExecServerFsHelperRunMainReadStdinErr $message)
      $parse-outcome
      $direct-outcome
      $serialize-outcome
      $write-response-outcome
      $write-newline-outcome)
   (CodexExecServerFsHelperRunMainResultErr "" $message))

(= (codex:exec-server-fs-helper-run-main-flow
      (CodexExecServerFsHelperRunMainReadStdinOk $input)
      (CodexExecServerFsHelperRunMainParseRequestErr $message)
      $direct-outcome
      $serialize-outcome
      $write-response-outcome
      $write-newline-outcome)
   (CodexExecServerFsHelperRunMainResultErr "" $message))

(= (codex:exec-server-fs-helper-run-main-flow
      (CodexExecServerFsHelperRunMainReadStdinOk $input)
      (CodexExecServerFsHelperRunMainParseRequestOk $request)
      $direct-outcome
      $serialize-outcome
      $write-response-outcome
      $write-newline-outcome)
   (codex:exec-server-fs-helper-run-main-after-parse
     $request
     $direct-outcome
     $serialize-outcome
     $write-response-outcome
     $write-newline-outcome))
