; Rust-faithful exec-server filesystem handler slice.
;
; This ports deterministic behavior from:
; - openai-codex/codex-rs/exec-server/src/server/file_system_handler.rs
;   - FileSystemHandler::new shape
;   - read_file base64 response projection
;   - write_file base64 decode error mapping
;   - create_directory recursive unwrap_or(true)
;   - get_metadata response projection
;   - read_directory entry response projection
;   - remove recursive/force unwrap_or(true)
;   - copy recursive option forwarding
;   - map_fs_error ErrorKind -> JSON-RPC error policy
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust owns a live `LocalFileSystem` and awaits async filesystem operations.
;   This pure slice takes symbolic filesystem outcomes at that runtime boundary
;   and preserves the same response shaping and error mapping.
; - Rust decodes write-file standard base64 into bytes before calling the
;   filesystem. CeTTa currently has standard base64 encoding but not a standard
;   base64 decoder, so this slice takes a symbolic decode outcome and preserves
;   the exact invalid-request branch and message prefix from Rust.
; - Rust byte vectors may contain arbitrary bytes. This slice represents bytes
;   as current CeTTa text at the boundary; binary materialization belongs in
;   the eventual filesystem runtime bridge.

!(import! &self str)
!(import! &self exec_server_rpc)
!(import! &self exec_server_file_system_protocol)

(= (codex:exec-server-fs-handler-local-file-system $runtime-paths)
   (CodexExecServerFsHandlerLocalFileSystem $runtime-paths))

(= (codex:exec-server-fs-handler
      $file-system)
   (CodexExecServerFsHandler $file-system))

(= (codex:exec-server-fs-handler-new $runtime-paths)
   (CodexExecServerFsHandler
     (CodexExecServerFsHandlerLocalFileSystem $runtime-paths)))

(= (codex:exec-server-fs-handler-file-system
      (CodexExecServerFsHandler $file-system))
   $file-system)

(= (codex:exec-server-fs-handler-local-file-system-runtime-paths
      (CodexExecServerFsHandlerLocalFileSystem $runtime-paths))
   $runtime-paths)

(= (codex:exec-server-fs-handler-result-ok $value)
   (CodexExecServerFsHandlerResultOk $value))

(= (codex:exec-server-fs-handler-result-err $error)
   (CodexExecServerFsHandlerResultErr $error))

(= (codex:exec-server-fs-handler-result-value
      (CodexExecServerFsHandlerResultOk $value))
   $value)

(= (codex:exec-server-fs-handler-result-error
      (CodexExecServerFsHandlerResultErr $error))
   $error)

(= (codex:exec-server-fs-handler-error-kind-not-found)
   (CodexExecServerFsHandlerErrorKindNotFound))

(= (codex:exec-server-fs-handler-error-kind-invalid-input)
   (CodexExecServerFsHandlerErrorKindInvalidInput))

(= (codex:exec-server-fs-handler-error-kind-permission-denied)
   (CodexExecServerFsHandlerErrorKindPermissionDenied))

(= (codex:exec-server-fs-handler-error-kind-other)
   (CodexExecServerFsHandlerErrorKindOther))

(= (codex:exec-server-fs-handler-file-system-error $kind $message)
   (CodexExecServerFsHandlerFileSystemError $kind $message))

(= (codex:exec-server-fs-handler-file-system-error-kind
      (CodexExecServerFsHandlerFileSystemError $kind $message))
   $kind)

(= (codex:exec-server-fs-handler-file-system-error-message
      (CodexExecServerFsHandlerFileSystemError $kind $message))
   $message)

(= (codex:exec-server-fs-handler-map-fs-error
      (CodexExecServerFsHandlerFileSystemError
        (CodexExecServerFsHandlerErrorKindNotFound)
        $message))
   (codex:exec-server-rpc-not-found $message))

(= (codex:exec-server-fs-handler-map-fs-error
      (CodexExecServerFsHandlerFileSystemError
        (CodexExecServerFsHandlerErrorKindInvalidInput)
        $message))
   (codex:exec-server-rpc-invalid-request $message))

(= (codex:exec-server-fs-handler-map-fs-error
      (CodexExecServerFsHandlerFileSystemError
        (CodexExecServerFsHandlerErrorKindPermissionDenied)
        $message))
   (codex:exec-server-rpc-invalid-request $message))

(= (codex:exec-server-fs-handler-map-fs-error
      (CodexExecServerFsHandlerFileSystemError
        (CodexExecServerFsHandlerErrorKindOther)
        $message))
   (codex:exec-server-rpc-internal-error $message))

(= (codex:exec-server-fs-handler-base64-decode-ok $bytes)
   (CodexExecServerFsHandlerBase64DecodeOk $bytes))

(= (codex:exec-server-fs-handler-base64-decode-err $message)
   (CodexExecServerFsHandlerBase64DecodeErr $message))

(= (codex:exec-server-fs-handler-operation-read-file-ok $bytes)
   (CodexExecServerFsHandlerOperationReadFileOk $bytes))

(= (codex:exec-server-fs-handler-operation-write-file-ok)
   (CodexExecServerFsHandlerOperationWriteFileOk))

(= (codex:exec-server-fs-handler-operation-create-directory-ok)
   (CodexExecServerFsHandlerOperationCreateDirectoryOk))

(= (codex:exec-server-fs-handler-operation-get-metadata-ok $metadata)
   (CodexExecServerFsHandlerOperationGetMetadataOk $metadata))

(= (codex:exec-server-fs-handler-operation-read-directory-ok $entries)
   (CodexExecServerFsHandlerOperationReadDirectoryOk $entries))

(= (codex:exec-server-fs-handler-operation-remove-ok)
   (CodexExecServerFsHandlerOperationRemoveOk))

(= (codex:exec-server-fs-handler-operation-copy-ok)
   (CodexExecServerFsHandlerOperationCopyOk))

(= (codex:exec-server-fs-handler-operation-err $error)
   (CodexExecServerFsHandlerOperationErr $error))

(= (codex:exec-server-fs-handler-option-bool-or-true $value)
   (if (== $value CodexAbsent)
       True
       $value))

(= (codex:exec-server-fs-handler-read-file
      (CodexExecServerFsHandler $file-system)
      (CodexExecServerFsReadFileParams $path $sandbox)
      (CodexExecServerFsHandlerOperationReadFileOk $bytes))
   (CodexExecServerFsHandlerResultOk
     (CodexExecServerFsReadFileResponse
       (str-base64-encode $bytes))))

(= (codex:exec-server-fs-handler-read-file
      $handler
      $params
      (CodexExecServerFsHandlerOperationErr $error))
   (CodexExecServerFsHandlerResultErr
     (codex:exec-server-fs-handler-map-fs-error $error)))

(= (codex:exec-server-fs-handler-write-file
      (CodexExecServerFsHandler $file-system)
      (CodexExecServerFsWriteFileParams $path $data-base64 $sandbox)
      (CodexExecServerFsHandlerBase64DecodeErr $message)
      $operation-outcome)
   (CodexExecServerFsHandlerResultErr
     (codex:exec-server-rpc-invalid-request
       (format-args
         "{} requires valid base64 dataBase64: {}"
         ((codex:exec-server-fs-write-file-method) $message)))))

(= (codex:exec-server-fs-handler-write-file
      (CodexExecServerFsHandler $file-system)
      (CodexExecServerFsWriteFileParams $path $data-base64 $sandbox)
      (CodexExecServerFsHandlerBase64DecodeOk $bytes)
      (CodexExecServerFsHandlerOperationWriteFileOk))
   (CodexExecServerFsHandlerResultOk
     (CodexExecServerFsWriteFileResponse)))

(= (codex:exec-server-fs-handler-write-file
      $handler
      $params
      (CodexExecServerFsHandlerBase64DecodeOk $bytes)
      (CodexExecServerFsHandlerOperationErr $error))
   (CodexExecServerFsHandlerResultErr
     (codex:exec-server-fs-handler-map-fs-error $error)))

(= (codex:exec-server-fs-handler-create-directory-options-from-params
      (CodexExecServerFsCreateDirectoryParams $path $recursive $sandbox))
   (CodexExecServerCreateDirectoryOptions
     (codex:exec-server-fs-handler-option-bool-or-true $recursive)))

(= (codex:exec-server-fs-handler-create-directory
      (CodexExecServerFsHandler $file-system)
      (CodexExecServerFsCreateDirectoryParams $path $recursive $sandbox)
      (CodexExecServerFsHandlerOperationCreateDirectoryOk))
   (CodexExecServerFsHandlerResultOk
     (CodexExecServerFsCreateDirectoryResponse)))

(= (codex:exec-server-fs-handler-create-directory
      $handler
      $params
      (CodexExecServerFsHandlerOperationErr $error))
   (CodexExecServerFsHandlerResultErr
     (codex:exec-server-fs-handler-map-fs-error $error)))

(= (codex:exec-server-fs-handler-get-metadata
      (CodexExecServerFsHandler $file-system)
      (CodexExecServerFsGetMetadataParams $path $sandbox)
      (CodexExecServerFsHandlerOperationGetMetadataOk
        (CodexExecServerFileMetadata
          $is-directory
          $is-file
          $is-symlink
          $created-at-ms
          $modified-at-ms)))
   (CodexExecServerFsHandlerResultOk
     (CodexExecServerFsGetMetadataResponse
       $is-directory
       $is-file
       $is-symlink
       $created-at-ms
       $modified-at-ms)))

(= (codex:exec-server-fs-handler-get-metadata
      $handler
      $params
      (CodexExecServerFsHandlerOperationErr $error))
   (CodexExecServerFsHandlerResultErr
     (codex:exec-server-fs-handler-map-fs-error $error)))

(= (codex:exec-server-fs-handler-read-directory
      (CodexExecServerFsHandler $file-system)
      (CodexExecServerFsReadDirectoryParams $path $sandbox)
      (CodexExecServerFsHandlerOperationReadDirectoryOk $entries))
   (CodexExecServerFsHandlerResultOk
     (CodexExecServerFsReadDirectoryResponse $entries)))

(= (codex:exec-server-fs-handler-read-directory
      $handler
      $params
      (CodexExecServerFsHandlerOperationErr $error))
   (CodexExecServerFsHandlerResultErr
     (codex:exec-server-fs-handler-map-fs-error $error)))

(= (codex:exec-server-fs-handler-remove-options-from-params
      (CodexExecServerFsRemoveParams $path $recursive $force $sandbox))
   (CodexExecServerRemoveOptions
     (codex:exec-server-fs-handler-option-bool-or-true $recursive)
     (codex:exec-server-fs-handler-option-bool-or-true $force)))

(= (codex:exec-server-fs-handler-remove
      (CodexExecServerFsHandler $file-system)
      (CodexExecServerFsRemoveParams $path $recursive $force $sandbox)
      (CodexExecServerFsHandlerOperationRemoveOk))
   (CodexExecServerFsHandlerResultOk
     (CodexExecServerFsRemoveResponse)))

(= (codex:exec-server-fs-handler-remove
      $handler
      $params
      (CodexExecServerFsHandlerOperationErr $error))
   (CodexExecServerFsHandlerResultErr
     (codex:exec-server-fs-handler-map-fs-error $error)))

(= (codex:exec-server-fs-handler-copy-options-from-params
      (CodexExecServerFsCopyParams
        $source-path
        $destination-path
        $recursive
        $sandbox))
   (CodexExecServerCopyOptions $recursive))

(= (codex:exec-server-fs-handler-copy
      (CodexExecServerFsHandler $file-system)
      (CodexExecServerFsCopyParams
        $source-path
        $destination-path
        $recursive
        $sandbox)
      (CodexExecServerFsHandlerOperationCopyOk))
   (CodexExecServerFsHandlerResultOk
     (CodexExecServerFsCopyResponse)))

(= (codex:exec-server-fs-handler-copy
      $handler
      $params
      (CodexExecServerFsHandlerOperationErr $error))
   (CodexExecServerFsHandlerResultErr
     (codex:exec-server-fs-handler-map-fs-error $error)))
