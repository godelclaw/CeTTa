; Rust-faithful exec-server filesystem protocol slice.
;
; This ports deterministic wire/data shapes from:
; - openai-codex/codex-rs/exec-server/src/protocol.rs
;   - FS_* JSON-RPC method constants
;   - FsReadFileParams / FsReadFileResponse
;   - FsWriteFileParams / FsWriteFileResponse
;   - FsCreateDirectoryParams / FsCreateDirectoryResponse
;   - FsGetMetadataParams / FsGetMetadataResponse
;   - FsReadDirectoryParams / FsReadDirectoryEntry /
;     FsReadDirectoryResponse
;   - FsRemoveParams / FsRemoveResponse
;   - FsCopyParams / FsCopyResponse
; - openai-codex/codex-rs/exec-server/src/file_system.rs
;   - CreateDirectoryOptions / RemoveOptions / CopyOptions
;   - FileMetadata / ReadDirectoryEntry
;   - FileSystemSandboxContext JSON field shape
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust uses `AbsolutePathBuf` for all filesystem paths. This pure protocol
;   slice carries already-validated absolute path strings and serializes them
;   as the same JSON strings; path validation belongs with the runtime
;   filesystem boundary.
; - Rust `FileSystemSandboxContext.permissions` stores a full
;   `PermissionProfile`. This protocol slice carries the already-projected
;   permission-profile JSON value so this file can remain independent from the
;   broad core protocol module while preserving the visible executor wire
;   shape.

!(import! &self json)
!(import! &self list)

(= (codex:exec-server-fs-read-file-method)
   "fs/readFile")

(= (codex:exec-server-fs-write-file-method)
   "fs/writeFile")

(= (codex:exec-server-fs-create-directory-method)
   "fs/createDirectory")

(= (codex:exec-server-fs-get-metadata-method)
   "fs/getMetadata")

(= (codex:exec-server-fs-read-directory-method)
   "fs/readDirectory")

(= (codex:exec-server-fs-remove-method)
   "fs/remove")

(= (codex:exec-server-fs-copy-method)
   "fs/copy")

(= (codex:exec-server-fs-json-number $value)
   (JsonNumber (format-args "{}" ($value))))

(= (codex:exec-server-fs-json-option-bool $value)
   (if (== $value CodexAbsent)
       JsonNull
       (JsonBool $value)))

(= (codex:exec-server-fs-append-optional-json-string-pair
      $pairs
      $key
      $value)
   (if (== $value CodexAbsent)
       $pairs
       (list:append $pairs ((JsonPair $key (JsonString $value))))))

(= (codex:exec-server-fs-windows-sandbox-level-disabled)
   (CodexExecServerFsWindowsSandboxLevelDisabled))

(= (codex:exec-server-fs-windows-sandbox-level-restricted-token)
   (CodexExecServerFsWindowsSandboxLevelRestrictedToken))

(= (codex:exec-server-fs-windows-sandbox-level-elevated)
   (CodexExecServerFsWindowsSandboxLevelElevated))

(= (codex:exec-server-fs-windows-sandbox-level-json-string
      (CodexExecServerFsWindowsSandboxLevelDisabled))
   "disabled")

(= (codex:exec-server-fs-windows-sandbox-level-json-string
      (CodexExecServerFsWindowsSandboxLevelRestrictedToken))
   "restricted-token")

(= (codex:exec-server-fs-windows-sandbox-level-json-string
      (CodexExecServerFsWindowsSandboxLevelElevated))
   "elevated")

(= (codex:exec-server-fs-sandbox-context
      $permissions-json
      $cwd
      $windows-sandbox-level
      $windows-sandbox-private-desktop
      $use-legacy-landlock)
   (CodexExecServerFsSandboxContext
     $permissions-json
     $cwd
     $windows-sandbox-level
     $windows-sandbox-private-desktop
     $use-legacy-landlock))

(= (codex:exec-server-fs-sandbox-context-permissions-json
      (CodexExecServerFsSandboxContext
        $permissions-json
        $cwd
        $windows-sandbox-level
        $windows-sandbox-private-desktop
        $use-legacy-landlock))
   $permissions-json)

(= (codex:exec-server-fs-sandbox-context-json
      (CodexExecServerFsSandboxContext
        $permissions-json
        $cwd
        $windows-sandbox-level
        $windows-sandbox-private-desktop
        $use-legacy-landlock))
   (JsonObject
     (list:append
       (codex:exec-server-fs-append-optional-json-string-pair
         ((JsonPair "permissions" $permissions-json))
         "cwd"
         $cwd)
       ((JsonPair
          "windowsSandboxLevel"
          (JsonString
            (codex:exec-server-fs-windows-sandbox-level-json-string
              $windows-sandbox-level)))
        (JsonPair
          "windowsSandboxPrivateDesktop"
          (JsonBool $windows-sandbox-private-desktop))
        (JsonPair "useLegacyLandlock" (JsonBool $use-legacy-landlock))))))

(= (codex:exec-server-fs-json-option-sandbox $sandbox)
   (if (== $sandbox CodexAbsent)
       JsonNull
       (codex:exec-server-fs-sandbox-context-json $sandbox)))

(= (codex:exec-server-create-directory-options $recursive)
   (CodexExecServerCreateDirectoryOptions $recursive))

(= (codex:exec-server-create-directory-options-recursive
      (CodexExecServerCreateDirectoryOptions $recursive))
   $recursive)

(= (codex:exec-server-remove-options $recursive $force)
   (CodexExecServerRemoveOptions $recursive $force))

(= (codex:exec-server-remove-options-recursive
      (CodexExecServerRemoveOptions $recursive $force))
   $recursive)

(= (codex:exec-server-remove-options-force
      (CodexExecServerRemoveOptions $recursive $force))
   $force)

(= (codex:exec-server-copy-options $recursive)
   (CodexExecServerCopyOptions $recursive))

(= (codex:exec-server-copy-options-recursive
      (CodexExecServerCopyOptions $recursive))
   $recursive)

(= (codex:exec-server-file-metadata
      $is-directory
      $is-file
      $is-symlink
      $created-at-ms
      $modified-at-ms)
   (CodexExecServerFileMetadata
     $is-directory
     $is-file
     $is-symlink
     $created-at-ms
     $modified-at-ms))

(= (codex:exec-server-file-metadata-json
      (CodexExecServerFileMetadata
        $is-directory
        $is-file
        $is-symlink
        $created-at-ms
        $modified-at-ms))
   (JsonObject
     ((JsonPair "isDirectory" (JsonBool $is-directory))
      (JsonPair "isFile" (JsonBool $is-file))
      (JsonPair "isSymlink" (JsonBool $is-symlink))
      (JsonPair "createdAtMs" (codex:exec-server-fs-json-number $created-at-ms))
      (JsonPair
        "modifiedAtMs"
        (codex:exec-server-fs-json-number $modified-at-ms)))))

(= (codex:exec-server-fs-read-file-params $path $sandbox)
   (CodexExecServerFsReadFileParams $path $sandbox))

(= (codex:exec-server-fs-read-file-params-json
      (CodexExecServerFsReadFileParams $path $sandbox))
   (JsonObject
     ((JsonPair "path" (JsonString $path))
      (JsonPair
        "sandbox"
        (codex:exec-server-fs-json-option-sandbox $sandbox)))))

(= (codex:exec-server-fs-read-file-response $data-base64)
   (CodexExecServerFsReadFileResponse $data-base64))

(= (codex:exec-server-fs-read-file-response-data-base64
      (CodexExecServerFsReadFileResponse $data-base64))
   $data-base64)

(= (codex:exec-server-fs-read-file-response-json
      (CodexExecServerFsReadFileResponse $data-base64))
   (JsonObject
     ((JsonPair "dataBase64" (JsonString $data-base64)))))

(= (codex:exec-server-fs-write-file-params
      $path
      $data-base64
      $sandbox)
   (CodexExecServerFsWriteFileParams $path $data-base64 $sandbox))

(= (codex:exec-server-fs-write-file-params-json
      (CodexExecServerFsWriteFileParams $path $data-base64 $sandbox))
   (JsonObject
     ((JsonPair "path" (JsonString $path))
      (JsonPair "dataBase64" (JsonString $data-base64))
      (JsonPair
        "sandbox"
        (codex:exec-server-fs-json-option-sandbox $sandbox)))))

(= (codex:exec-server-fs-write-file-response)
   (CodexExecServerFsWriteFileResponse))

(= (codex:exec-server-fs-write-file-response-json
      (CodexExecServerFsWriteFileResponse))
   (JsonObject ()))

(= (codex:exec-server-fs-create-directory-params
      $path
      $recursive
      $sandbox)
   (CodexExecServerFsCreateDirectoryParams
     $path
     $recursive
     $sandbox))

(= (codex:exec-server-fs-create-directory-params-json
      (CodexExecServerFsCreateDirectoryParams
        $path
        $recursive
        $sandbox))
   (JsonObject
     ((JsonPair "path" (JsonString $path))
      (JsonPair
        "recursive"
        (codex:exec-server-fs-json-option-bool $recursive))
      (JsonPair
        "sandbox"
        (codex:exec-server-fs-json-option-sandbox $sandbox)))))

(= (codex:exec-server-fs-create-directory-response)
   (CodexExecServerFsCreateDirectoryResponse))

(= (codex:exec-server-fs-create-directory-response-json
      (CodexExecServerFsCreateDirectoryResponse))
   (JsonObject ()))

(= (codex:exec-server-fs-get-metadata-params $path $sandbox)
   (CodexExecServerFsGetMetadataParams $path $sandbox))

(= (codex:exec-server-fs-get-metadata-params-json
      (CodexExecServerFsGetMetadataParams $path $sandbox))
   (JsonObject
     ((JsonPair "path" (JsonString $path))
      (JsonPair
        "sandbox"
        (codex:exec-server-fs-json-option-sandbox $sandbox)))))

(= (codex:exec-server-fs-get-metadata-response
      $is-directory
      $is-file
      $is-symlink
      $created-at-ms
      $modified-at-ms)
   (CodexExecServerFsGetMetadataResponse
     $is-directory
     $is-file
     $is-symlink
     $created-at-ms
     $modified-at-ms))

(= (codex:exec-server-fs-get-metadata-response-json
      (CodexExecServerFsGetMetadataResponse
        $is-directory
        $is-file
        $is-symlink
        $created-at-ms
        $modified-at-ms))
   (codex:exec-server-file-metadata-json
     (CodexExecServerFileMetadata
       $is-directory
       $is-file
       $is-symlink
       $created-at-ms
       $modified-at-ms)))

(= (codex:exec-server-fs-read-directory-params $path $sandbox)
   (CodexExecServerFsReadDirectoryParams $path $sandbox))

(= (codex:exec-server-fs-read-directory-params-json
      (CodexExecServerFsReadDirectoryParams $path $sandbox))
   (JsonObject
     ((JsonPair "path" (JsonString $path))
      (JsonPair
        "sandbox"
        (codex:exec-server-fs-json-option-sandbox $sandbox)))))

(= (codex:exec-server-fs-read-directory-entry
      $file-name
      $is-directory
      $is-file)
   (CodexExecServerFsReadDirectoryEntry
     $file-name
     $is-directory
     $is-file))

(= (codex:exec-server-fs-read-directory-entry-file-name
      (CodexExecServerFsReadDirectoryEntry
        $file-name
        $is-directory
        $is-file))
   $file-name)

(= (codex:exec-server-fs-read-directory-entry-json
      (CodexExecServerFsReadDirectoryEntry
        $file-name
        $is-directory
        $is-file))
   (JsonObject
     ((JsonPair "fileName" (JsonString $file-name))
      (JsonPair "isDirectory" (JsonBool $is-directory))
      (JsonPair "isFile" (JsonBool $is-file)))))

(= (codex:exec-server-fs-read-directory-entries-json $entries)
   (JsonArray
     (map-atom-strict
       $entries
       $entry
       (codex:exec-server-fs-read-directory-entry-json $entry))))

(= (codex:exec-server-fs-read-directory-response $entries)
   (CodexExecServerFsReadDirectoryResponse $entries))

(= (codex:exec-server-fs-read-directory-response-json
      (CodexExecServerFsReadDirectoryResponse $entries))
   (JsonObject
     ((JsonPair
        "entries"
        (codex:exec-server-fs-read-directory-entries-json $entries)))))

(= (codex:exec-server-fs-remove-params
      $path
      $recursive
      $force
      $sandbox)
   (CodexExecServerFsRemoveParams $path $recursive $force $sandbox))

(= (codex:exec-server-fs-remove-params-json
      (CodexExecServerFsRemoveParams
        $path
        $recursive
        $force
        $sandbox))
   (JsonObject
     ((JsonPair "path" (JsonString $path))
      (JsonPair
        "recursive"
        (codex:exec-server-fs-json-option-bool $recursive))
      (JsonPair "force" (codex:exec-server-fs-json-option-bool $force))
      (JsonPair
        "sandbox"
        (codex:exec-server-fs-json-option-sandbox $sandbox)))))

(= (codex:exec-server-fs-remove-response)
   (CodexExecServerFsRemoveResponse))

(= (codex:exec-server-fs-remove-response-json
      (CodexExecServerFsRemoveResponse))
   (JsonObject ()))

(= (codex:exec-server-fs-copy-params
      $source-path
      $destination-path
      $recursive
      $sandbox)
   (CodexExecServerFsCopyParams
     $source-path
     $destination-path
     $recursive
     $sandbox))

(= (codex:exec-server-fs-copy-params-json
      (CodexExecServerFsCopyParams
        $source-path
        $destination-path
        $recursive
        $sandbox))
   (JsonObject
     ((JsonPair "sourcePath" (JsonString $source-path))
      (JsonPair "destinationPath" (JsonString $destination-path))
      (JsonPair "recursive" (JsonBool $recursive))
      (JsonPair
        "sandbox"
        (codex:exec-server-fs-json-option-sandbox $sandbox)))))

(= (codex:exec-server-fs-copy-response)
   (CodexExecServerFsCopyResponse))

(= (codex:exec-server-fs-copy-response-json
      (CodexExecServerFsCopyResponse))
   (JsonObject ()))
