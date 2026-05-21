; Rust-faithful exec-server local filesystem slice.
;
; This ports deterministic behavior from:
; - openai-codex/codex-rs/exec-server/src/local_file_system.rs
;   - MAX_READ_FILE_BYTES
;   - DirectFileSystem / UnsandboxedFileSystem / LocalFileSystem shapes
;   - LocalFileSystem::unsandboxed / with_runtime_paths / sandboxed /
;     file_system_for
;   - reject_sandbox_context / reject_platform_sandbox_context
;   - DirectFileSystem read-size guard, create/remove/copy branching,
;     metadata projection, directory-entry filtering, and time conversion
;   - copy_dir_recursive action selection, destination descendant check,
;     resolve_existing_path, and spawn-blocking join-error mapping
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust performs real async filesystem IO. This pure slice takes symbolic IO
;   outcomes at those runtime boundaries while preserving the same branching,
;   option handling, error messages, and response projections around them.
; - Rust stores `FileSystemSandboxContext.permissions` as a full permission
;   profile. This slice uses the existing CeTTa `fs_sandbox` context that
;   carries the already materialized filesystem sandbox policy because
;   `local_file_system.rs` only observes `should_run_in_sandbox` here.
; - Rust `resolve_existing_path` discovers the deepest existing prefix and
;   canonicalizes it through the host filesystem. This pure slice receives the
;   symbolic existing prefix and its canonicalized value, then applies the same
;   unresolved suffix reattachment rule.
; - Rust detects `SystemTime` millisecond overflow through `i64::try_from`.
;   CeTTa does not reliably reduce integer comparisons beyond the host integer
;   range, so this slice exposes that overflow branch as an explicit symbolic
;   time outcome.
; - Rust `Path::join` appends directory-entry file names. This slice uses
;   CeTTa `path-join` for symbolic child paths; directory entry file names
;   cannot be parent components in the real filesystem iterator.

!(import! &self list)
!(import! &self path)
!(import! &self str)
!(import! &self permissions)
!(import! &self fs_sandbox)
!(import! &self exec_server_file_system_protocol)
!(import! &self exec_server_sandboxed_file_system)

(= (codex:exec-server-local-fs-max-read-file-bytes)
   536870912)

(= (codex:exec-server-local-fs-i64-max)
   9223372036854775807)

(= (codex:exec-server-direct-file-system)
   (CodexExecServerDirectFileSystem))

(= (codex:exec-server-unsandboxed-file-system $file-system)
   (CodexExecServerUnsandboxedFileSystem $file-system))

(= (codex:exec-server-unsandboxed-file-system-default)
   (CodexExecServerUnsandboxedFileSystem
     (CodexExecServerDirectFileSystem)))

(= (codex:exec-server-unsandboxed-file-system-direct
      (CodexExecServerUnsandboxedFileSystem $file-system))
   $file-system)

(= (codex:exec-server-local-file-system
      $unsandboxed
      $sandboxed)
   (CodexExecServerLocalFileSystem $unsandboxed $sandboxed))

(= (codex:exec-server-local-file-system-unsandboxed)
   (CodexExecServerLocalFileSystem
     (codex:exec-server-unsandboxed-file-system-default)
     CodexAbsent))

(= (codex:exec-server-local-file-system-with-runtime-paths
      $runtime-paths)
   (CodexExecServerLocalFileSystem
     (codex:exec-server-unsandboxed-file-system-default)
     (codex:exec-server-sandboxed-file-system-new $runtime-paths)))

(= (codex:exec-server-local-file-system-unsandboxed-field
      (CodexExecServerLocalFileSystem $unsandboxed $sandboxed))
   $unsandboxed)

(= (codex:exec-server-local-file-system-sandboxed-field
      (CodexExecServerLocalFileSystem $unsandboxed $sandboxed))
   $sandboxed)

(= (codex:exec-server-local-fs-unit)
   (CodexExecServerLocalFsUnit))

(= (codex:exec-server-local-fs-result-ok $value)
   (CodexExecServerLocalFsResultOk $value))

(= (codex:exec-server-local-fs-result-err $error)
   (CodexExecServerLocalFsResultErr $error))

(= (codex:exec-server-local-fs-result-value
      (CodexExecServerLocalFsResultOk $value))
   $value)

(= (codex:exec-server-local-fs-result-error
      (CodexExecServerLocalFsResultErr $error))
   $error)

(= (codex:exec-server-local-fs-unit-result
      (CodexExecServerLocalFsResultOk $value))
   (CodexExecServerLocalFsResultOk
     (CodexExecServerLocalFsUnit)))

(= (codex:exec-server-local-fs-unit-result
      (CodexExecServerLocalFsResultErr $error))
   (CodexExecServerLocalFsResultErr $error))

(= (codex:exec-server-local-fs-error-kind-not-found)
   (CodexExecServerLocalFsErrorKindNotFound))

(= (codex:exec-server-local-fs-error-kind-invalid-input)
   (CodexExecServerLocalFsErrorKindInvalidInput))

(= (codex:exec-server-local-fs-error-kind-other)
   (CodexExecServerLocalFsErrorKindOther))

(= (codex:exec-server-local-fs-error-kind-unsupported)
   (CodexExecServerLocalFsErrorKindUnsupported))

(= (codex:exec-server-local-fs-file-system-error $kind $message)
   (CodexExecServerLocalFsFileSystemError $kind $message))

(= (codex:exec-server-local-fs-file-system-error-kind
      (CodexExecServerLocalFsFileSystemError $kind $message))
   $kind)

(= (codex:exec-server-local-fs-file-system-error-message
      (CodexExecServerLocalFsFileSystemError $kind $message))
   $message)

(= (codex:exec-server-local-fs-error-is-not-found $error)
   (== (codex:exec-server-local-fs-file-system-error-kind $error)
       (CodexExecServerLocalFsErrorKindNotFound)))

(= (codex:exec-server-local-fs-configured-runtime-paths-error)
   (CodexExecServerLocalFsFileSystemError
     (CodexExecServerLocalFsErrorKindInvalidInput)
     "sandboxed filesystem operations require configured runtime paths"))

(= (codex:exec-server-local-fs-direct-sandbox-error)
   (CodexExecServerLocalFsFileSystemError
     (CodexExecServerLocalFsErrorKindInvalidInput)
     "direct filesystem operations do not accept sandbox context"))

(= (codex:exec-server-local-fs-too-large-error)
   (CodexExecServerLocalFsFileSystemError
     (CodexExecServerLocalFsErrorKindInvalidInput)
     (format-args
       "file is too large to read: limit is {} bytes"
       ((codex:exec-server-local-fs-max-read-file-bytes)))))

(= (codex:exec-server-local-fs-sandbox-should-run $sandbox)
   (if (== $sandbox CodexAbsent)
       False
       (codex:fs-sandbox-context-should-run-in-sandbox $sandbox)))

(= (codex:exec-server-local-fs-sandboxed
      (CodexExecServerLocalFileSystem $unsandboxed $sandboxed))
   (if (== $sandboxed CodexAbsent)
       (CodexExecServerLocalFsResultErr
         (codex:exec-server-local-fs-configured-runtime-paths-error))
       (CodexExecServerLocalFsResultOk $sandboxed)))

(= (codex:exec-server-local-fs-selected-unsandboxed
      $unsandboxed
      $sandbox)
   (CodexExecServerLocalFsSelectedUnsandboxed $unsandboxed $sandbox))

(= (codex:exec-server-local-fs-selected-sandboxed
      $sandboxed
      $sandbox)
   (CodexExecServerLocalFsSelectedSandboxed $sandboxed $sandbox))

(= (codex:exec-server-local-fs-file-system-for
      (CodexExecServerLocalFileSystem $unsandboxed $sandboxed)
      $sandbox)
   (if (codex:exec-server-local-fs-sandbox-should-run $sandbox)
       (case
         (codex:exec-server-local-fs-sandboxed
           (CodexExecServerLocalFileSystem $unsandboxed $sandboxed))
         (((CodexExecServerLocalFsResultErr $error)
           (CodexExecServerLocalFsResultErr $error))
          ((CodexExecServerLocalFsResultOk $sandboxed-file-system)
           (CodexExecServerLocalFsResultOk
             (CodexExecServerLocalFsSelectedSandboxed
               $sandboxed-file-system
               $sandbox)))))
       (CodexExecServerLocalFsResultOk
         (CodexExecServerLocalFsSelectedUnsandboxed
           $unsandboxed
           $sandbox))))

(= (codex:exec-server-local-fs-reject-sandbox-context $sandbox)
   (if (== $sandbox CodexAbsent)
       (CodexExecServerLocalFsResultOk
         (CodexExecServerLocalFsUnit))
       (CodexExecServerLocalFsResultErr
         (codex:exec-server-local-fs-direct-sandbox-error))))

(= (codex:exec-server-local-fs-reject-platform-sandbox-context
      $sandbox)
   (if (codex:exec-server-local-fs-sandbox-should-run $sandbox)
       (CodexExecServerLocalFsResultErr
         (codex:exec-server-local-fs-configured-runtime-paths-error))
       (CodexExecServerLocalFsResultOk
         (CodexExecServerLocalFsUnit))))

(= (codex:exec-server-local-fs-file-type-directory)
   (CodexExecServerLocalFsFileTypeDirectory))

(= (codex:exec-server-local-fs-file-type-file)
   (CodexExecServerLocalFsFileTypeFile))

(= (codex:exec-server-local-fs-file-type-symlink)
   (CodexExecServerLocalFsFileTypeSymlink))

(= (codex:exec-server-local-fs-file-type-other)
   (CodexExecServerLocalFsFileTypeOther))

(= (codex:exec-server-local-fs-file-type-is-directory $file-type)
   (== $file-type (CodexExecServerLocalFsFileTypeDirectory)))

(= (codex:exec-server-local-fs-file-type-is-file $file-type)
   (== $file-type (CodexExecServerLocalFsFileTypeFile)))

(= (codex:exec-server-local-fs-file-type-is-symlink $file-type)
   (== $file-type (CodexExecServerLocalFsFileTypeSymlink)))

(= (codex:exec-server-local-fs-system-time-since-unix-ms $ms)
   (CodexExecServerLocalFsSystemTimeSinceUnixMs $ms))

(= (codex:exec-server-local-fs-system-time-err)
   (CodexExecServerLocalFsSystemTimeErr))

(= (codex:exec-server-local-fs-system-time-overflow)
   (CodexExecServerLocalFsSystemTimeOverflow))

(= (codex:exec-server-local-fs-system-time-to-unix-ms
      (CodexExecServerLocalFsSystemTimeSinceUnixMs $ms))
   (if (< $ms 0)
       0
       (if (<= $ms (codex:exec-server-local-fs-i64-max))
           $ms
           0)))

(= (codex:exec-server-local-fs-system-time-to-unix-ms
      (CodexExecServerLocalFsSystemTimeErr))
   0)

(= (codex:exec-server-local-fs-system-time-to-unix-ms
      (CodexExecServerLocalFsSystemTimeOverflow))
   0)

(= (codex:exec-server-local-fs-metadata-snapshot
      $len
      $is-directory
      $is-file
      $created-time
      $modified-time)
   (CodexExecServerLocalFsMetadataSnapshot
     $len
     $is-directory
     $is-file
     $created-time
     $modified-time))

(= (codex:exec-server-local-fs-metadata-snapshot-len
      (CodexExecServerLocalFsMetadataSnapshot
        $len
        $is-directory
        $is-file
        $created-time
        $modified-time))
   $len)

(= (codex:exec-server-local-fs-symlink-metadata-snapshot
      $file-type)
   (CodexExecServerLocalFsSymlinkMetadataSnapshot $file-type))

(= (codex:exec-server-local-fs-direct-read-file
      $path
      $sandbox
      $metadata-outcome
      $read-outcome)
   (case (codex:exec-server-local-fs-reject-sandbox-context
           $sandbox)
     (((CodexExecServerLocalFsResultErr $error)
       (CodexExecServerLocalFsResultErr $error))
      ((CodexExecServerLocalFsResultOk $unit)
       (case $metadata-outcome
         (((CodexExecServerLocalFsResultErr $error)
           (CodexExecServerLocalFsResultErr $error))
          ((CodexExecServerLocalFsResultOk $metadata)
           (if (>
                 (codex:exec-server-local-fs-metadata-snapshot-len
                   $metadata)
                 (codex:exec-server-local-fs-max-read-file-bytes))
               (CodexExecServerLocalFsResultErr
                 (codex:exec-server-local-fs-too-large-error))
               $read-outcome))))))))

(= (codex:exec-server-local-fs-direct-write-file
      $path
      $contents
      $sandbox
      $write-outcome)
   (case (codex:exec-server-local-fs-reject-sandbox-context
           $sandbox)
     (((CodexExecServerLocalFsResultErr $error)
       (CodexExecServerLocalFsResultErr $error))
      ((CodexExecServerLocalFsResultOk $unit)
       (codex:exec-server-local-fs-unit-result $write-outcome)))))

(= (codex:exec-server-local-fs-create-directory-plan
      (CodexExecServerCreateDirectoryOptions $recursive))
   (if $recursive
       (CodexExecServerLocalFsCreateDirAll)
       (CodexExecServerLocalFsCreateDir)))

(= (codex:exec-server-local-fs-direct-create-directory
      $path
      $options
      $sandbox
      $create-outcome)
   (case (codex:exec-server-local-fs-reject-sandbox-context
           $sandbox)
     (((CodexExecServerLocalFsResultErr $error)
       (CodexExecServerLocalFsResultErr $error))
      ((CodexExecServerLocalFsResultOk $unit)
       (codex:exec-server-local-fs-unit-result $create-outcome)))))

(= (codex:exec-server-local-fs-direct-get-metadata
      $path
      $sandbox
      $metadata-outcome
      $symlink-metadata-outcome)
   (case (codex:exec-server-local-fs-reject-sandbox-context
           $sandbox)
     (((CodexExecServerLocalFsResultErr $error)
       (CodexExecServerLocalFsResultErr $error))
      ((CodexExecServerLocalFsResultOk $unit)
       (case $metadata-outcome
         (((CodexExecServerLocalFsResultErr $error)
           (CodexExecServerLocalFsResultErr $error))
          ((CodexExecServerLocalFsResultOk
             (CodexExecServerLocalFsMetadataSnapshot
               $len
               $is-directory
               $is-file
               $created-time
               $modified-time))
           (case $symlink-metadata-outcome
             (((CodexExecServerLocalFsResultErr $error)
               (CodexExecServerLocalFsResultErr $error))
              ((CodexExecServerLocalFsResultOk
                 (CodexExecServerLocalFsSymlinkMetadataSnapshot
                   $file-type))
               (CodexExecServerLocalFsResultOk
                 (CodexExecServerFileMetadata
                   $is-directory
                   $is-file
                   (codex:exec-server-local-fs-file-type-is-symlink
                     $file-type)
                   (codex:exec-server-local-fs-system-time-to-unix-ms
                     $created-time)
                   (codex:exec-server-local-fs-system-time-to-unix-ms
                     $modified-time)))))))))))))

(= (codex:exec-server-local-fs-directory-entry
      $file-name
      $metadata-outcome)
   (CodexExecServerLocalFsDirectoryEntry $file-name $metadata-outcome))

(= (codex:exec-server-local-fs-read-directory-entry-from-metadata
      (CodexExecServerLocalFsDirectoryEntry
        $file-name
        (CodexExecServerLocalFsResultErr $error)))
   CodexAbsent)

(= (codex:exec-server-local-fs-read-directory-entry-from-metadata
      (CodexExecServerLocalFsDirectoryEntry
        $file-name
        (CodexExecServerLocalFsResultOk
          (CodexExecServerLocalFsMetadataSnapshot
            $len
            $is-directory
            $is-file
            $created-time
            $modified-time))))
   (CodexExecServerFsReadDirectoryEntry
     $file-name
     $is-directory
     $is-file))

(= (codex:exec-server-local-fs-read-directory-entries ())
   ())

(= (codex:exec-server-local-fs-read-directory-entries $entries)
   (let $head (list:first $entries)
     (let $tail (list:rest $entries)
       (let $tail-entries
         (codex:exec-server-local-fs-read-directory-entries $tail)
         (let $entry
           (codex:exec-server-local-fs-read-directory-entry-from-metadata
             $head)
           (if (== $entry CodexAbsent)
               $tail-entries
               (list:append ($entry) $tail-entries)))))))

(= (codex:exec-server-local-fs-direct-read-directory
      $path
      $sandbox
      $read-dir-outcome)
   (case (codex:exec-server-local-fs-reject-sandbox-context
           $sandbox)
     (((CodexExecServerLocalFsResultErr $error)
       (CodexExecServerLocalFsResultErr $error))
      ((CodexExecServerLocalFsResultOk $unit)
       (case $read-dir-outcome
         (((CodexExecServerLocalFsResultErr $error)
           (CodexExecServerLocalFsResultErr $error))
          ((CodexExecServerLocalFsResultOk $entries)
           (CodexExecServerLocalFsResultOk
             (codex:exec-server-local-fs-read-directory-entries
               $entries)))))))))

(= (codex:exec-server-local-fs-remove-plan-noop)
   (CodexExecServerLocalFsRemovePlanNoop))

(= (codex:exec-server-local-fs-remove-plan-remove-dir-all)
   (CodexExecServerLocalFsRemovePlanRemoveDirAll))

(= (codex:exec-server-local-fs-remove-plan-remove-dir)
   (CodexExecServerLocalFsRemovePlanRemoveDir))

(= (codex:exec-server-local-fs-remove-plan-remove-file)
   (CodexExecServerLocalFsRemovePlanRemoveFile))

(= (codex:exec-server-local-fs-remove-plan
      (CodexExecServerRemoveOptions $recursive $force)
      (CodexExecServerLocalFsResultErr $error))
   (if (and
         (codex:exec-server-local-fs-error-is-not-found $error)
         $force)
       (CodexExecServerLocalFsResultOk
         (CodexExecServerLocalFsRemovePlanNoop))
       (CodexExecServerLocalFsResultErr $error)))

(= (codex:exec-server-local-fs-remove-plan
      (CodexExecServerRemoveOptions $recursive $force)
      (CodexExecServerLocalFsResultOk
        (CodexExecServerLocalFsSymlinkMetadataSnapshot $file-type)))
   (CodexExecServerLocalFsResultOk
     (if (codex:exec-server-local-fs-file-type-is-directory $file-type)
         (if $recursive
             (CodexExecServerLocalFsRemovePlanRemoveDirAll)
             (CodexExecServerLocalFsRemovePlanRemoveDir))
         (CodexExecServerLocalFsRemovePlanRemoveFile))))

(= (codex:exec-server-local-fs-direct-remove
      $path
      $options
      $sandbox
      $symlink-metadata-outcome
      $remove-outcome)
   (case (codex:exec-server-local-fs-reject-sandbox-context
           $sandbox)
     (((CodexExecServerLocalFsResultErr $error)
       (CodexExecServerLocalFsResultErr $error))
      ((CodexExecServerLocalFsResultOk $unit)
       (case
         (codex:exec-server-local-fs-remove-plan
           $options
           $symlink-metadata-outcome)
         (((CodexExecServerLocalFsResultErr $error)
           (CodexExecServerLocalFsResultErr $error))
          ((CodexExecServerLocalFsResultOk $plan)
           (if (== $plan (CodexExecServerLocalFsRemovePlanNoop))
               (CodexExecServerLocalFsResultOk
                 (CodexExecServerLocalFsUnit))
               (codex:exec-server-local-fs-unit-result
                 $remove-outcome)))))))))

(= (codex:exec-server-local-fs-copy-plan-copy-dir-recursive)
   (CodexExecServerLocalFsCopyPlanCopyDirRecursive))

(= (codex:exec-server-local-fs-copy-plan-copy-symlink)
   (CodexExecServerLocalFsCopyPlanCopySymlink))

(= (codex:exec-server-local-fs-copy-plan-copy-file)
   (CodexExecServerLocalFsCopyPlanCopyFile))

(= (codex:exec-server-local-fs-copy-requires-recursive-error)
   (CodexExecServerLocalFsFileSystemError
     (CodexExecServerLocalFsErrorKindInvalidInput)
     "fs/copy requires recursive: true when sourcePath is a directory"))

(= (codex:exec-server-local-fs-copy-descendant-error)
   (CodexExecServerLocalFsFileSystemError
     (CodexExecServerLocalFsErrorKindInvalidInput)
     "fs/copy cannot copy a directory to itself or one of its descendants"))

(= (codex:exec-server-local-fs-copy-unsupported-file-type-error)
   (CodexExecServerLocalFsFileSystemError
     (CodexExecServerLocalFsErrorKindInvalidInput)
     "fs/copy only supports regular files, directories, and symlinks"))

(= (codex:exec-server-local-fs-copy-plan
      (CodexExecServerCopyOptions $recursive)
      (CodexExecServerLocalFsResultErr $error)
      $descendant-check-outcome)
   (CodexExecServerLocalFsResultErr $error))

(= (codex:exec-server-local-fs-copy-plan
      (CodexExecServerCopyOptions $recursive)
      (CodexExecServerLocalFsResultOk
        (CodexExecServerLocalFsSymlinkMetadataSnapshot $file-type))
      $descendant-check-outcome)
   (if (codex:exec-server-local-fs-file-type-is-directory $file-type)
       (if (not $recursive)
           (CodexExecServerLocalFsResultErr
             (codex:exec-server-local-fs-copy-requires-recursive-error))
           (case $descendant-check-outcome
             (((CodexExecServerLocalFsResultErr $error)
               (CodexExecServerLocalFsResultErr $error))
              ((CodexExecServerLocalFsResultOk $is-descendant)
               (if $is-descendant
                   (CodexExecServerLocalFsResultErr
                     (codex:exec-server-local-fs-copy-descendant-error))
                   (CodexExecServerLocalFsResultOk
                     (CodexExecServerLocalFsCopyPlanCopyDirRecursive)))))))
       (if (codex:exec-server-local-fs-file-type-is-symlink $file-type)
           (CodexExecServerLocalFsResultOk
             (CodexExecServerLocalFsCopyPlanCopySymlink))
           (if (codex:exec-server-local-fs-file-type-is-file $file-type)
               (CodexExecServerLocalFsResultOk
                 (CodexExecServerLocalFsCopyPlanCopyFile))
               (CodexExecServerLocalFsResultErr
                 (codex:exec-server-local-fs-copy-unsupported-file-type-error))))))

(= (codex:exec-server-local-fs-copy-task-ok
      $source-metadata-outcome
      $descendant-check-outcome
      $operation-outcome)
   (CodexExecServerLocalFsCopyTaskOk
     $source-metadata-outcome
     $descendant-check-outcome
     $operation-outcome))

(= (codex:exec-server-local-fs-copy-task-join-err $message)
   (CodexExecServerLocalFsCopyTaskJoinErr $message))

(= (codex:exec-server-local-fs-copy-task-join-error $message)
   (CodexExecServerLocalFsFileSystemError
     (CodexExecServerLocalFsErrorKindOther)
     (format-args "filesystem task failed: {}" ($message))))

(= (codex:exec-server-local-fs-direct-copy
      $source-path
      $destination-path
      $options
      $sandbox
      (CodexExecServerLocalFsCopyTaskJoinErr $message))
   (case (codex:exec-server-local-fs-reject-sandbox-context
           $sandbox)
     (((CodexExecServerLocalFsResultErr $error)
       (CodexExecServerLocalFsResultErr $error))
      ((CodexExecServerLocalFsResultOk $unit)
       (CodexExecServerLocalFsResultErr
         (codex:exec-server-local-fs-copy-task-join-error
           $message))))))

(= (codex:exec-server-local-fs-direct-copy
      $source-path
      $destination-path
      $options
      $sandbox
      (CodexExecServerLocalFsCopyTaskOk
        $source-metadata-outcome
        $descendant-check-outcome
        $operation-outcome))
   (case (codex:exec-server-local-fs-reject-sandbox-context
           $sandbox)
     (((CodexExecServerLocalFsResultErr $error)
       (CodexExecServerLocalFsResultErr $error))
      ((CodexExecServerLocalFsResultOk $unit)
       (case
         (codex:exec-server-local-fs-copy-plan
           $options
           $source-metadata-outcome
           $descendant-check-outcome)
         (((CodexExecServerLocalFsResultErr $error)
           (CodexExecServerLocalFsResultErr $error))
          ((CodexExecServerLocalFsResultOk $plan)
           (codex:exec-server-local-fs-unit-result
             $operation-outcome))))))))

(= (codex:exec-server-local-fs-copy-dir-entry
      $file-name
      $file-type)
   (CodexExecServerLocalFsCopyDirEntry $file-name $file-type))

(= (codex:exec-server-local-fs-copy-dir-action-create-dir-all
      $target)
   (CodexExecServerLocalFsCopyDirActionCreateDirAll $target))

(= (codex:exec-server-local-fs-copy-dir-action-recurse
      $source
      $target)
   (CodexExecServerLocalFsCopyDirActionRecurse $source $target))

(= (codex:exec-server-local-fs-copy-dir-action-copy-file
      $source
      $target)
   (CodexExecServerLocalFsCopyDirActionCopyFile $source $target))

(= (codex:exec-server-local-fs-copy-dir-action-copy-symlink
      $source
      $target)
   (CodexExecServerLocalFsCopyDirActionCopySymlink $source $target))

(= (codex:exec-server-local-fs-copy-dir-entry-action
      $source
      $target
      (CodexExecServerLocalFsCopyDirEntry $file-name $file-type))
   (let $source-path (path-join $source $file-name)
     (let $target-path (path-join $target $file-name)
       (if (codex:exec-server-local-fs-file-type-is-directory $file-type)
           (CodexExecServerLocalFsCopyDirActionRecurse
             $source-path
             $target-path)
           (if (codex:exec-server-local-fs-file-type-is-file $file-type)
               (CodexExecServerLocalFsCopyDirActionCopyFile
                 $source-path
                 $target-path)
               (if (codex:exec-server-local-fs-file-type-is-symlink
                     $file-type)
                   (CodexExecServerLocalFsCopyDirActionCopySymlink
                     $source-path
                     $target-path)
                   CodexAbsent))))))

(= (codex:exec-server-local-fs-str-starts-with $text $prefix)
   (let $text-len (str-length $text)
     (let $prefix-len (str-length $prefix)
       (if (< $text-len $prefix-len)
           False
           (== (str-slice $text 0 $prefix-len) $prefix)))))

(= (codex:exec-server-local-fs-str-ends-with $text $suffix)
   (let $text-len (str-length $text)
     (let $suffix-len (str-length $suffix)
       (if (< $text-len $suffix-len)
           False
           (== (str-slice $text (- $text-len $suffix-len) $text-len)
               $suffix)))))

(= (codex:exec-server-local-fs-trim-trailing-slash-unless-root
      $text)
   (if (== $text "/")
       "/"
       (if (codex:exec-server-local-fs-str-ends-with $text "/")
           (codex:exec-server-local-fs-trim-trailing-slash-unless-root
             (str-slice $text 0 (- (str-length $text) 1)))
           $text)))

(= (codex:exec-server-local-fs-path-relative-suffix $path $prefix)
   (let $normalized-path
     (codex:exec-server-local-fs-trim-trailing-slash-unless-root
       (path-normalize $path))
     (let $normalized-prefix
       (codex:exec-server-local-fs-trim-trailing-slash-unless-root
         (path-normalize $prefix))
       (if (== $normalized-path $normalized-prefix)
           ""
           (if (== $normalized-prefix "/")
               (if (codex:exec-server-local-fs-str-starts-with
                     $normalized-path
                     "/")
                   (str-slice
                     $normalized-path
                     1
                     (str-length $normalized-path))
                   CodexAbsent)
               (let $prefix-with-slash
                 (str-concat $normalized-prefix "/")
                 (if (codex:exec-server-local-fs-str-starts-with
                       $normalized-path
                       $prefix-with-slash)
                     (str-slice
                       $normalized-path
                       (str-length $prefix-with-slash)
                       (str-length $normalized-path))
                     CodexAbsent)))))))

(= (codex:exec-server-local-fs-resolve-existing-path-from-prefix
      $path
      $existing-path
      $canonical-existing-path)
   (let $suffix
     (codex:exec-server-local-fs-path-relative-suffix
       $path
       $existing-path)
     (if (== $suffix CodexAbsent)
         (CodexExecServerLocalFsResultErr
           (CodexExecServerLocalFsFileSystemError
             (CodexExecServerLocalFsErrorKindInvalidInput)
             "existing path is not a prefix of path"))
         (CodexExecServerLocalFsResultOk
           (if (== $suffix "")
               (path-normalize $canonical-existing-path)
               (path-join $canonical-existing-path $suffix))))))

(= (codex:exec-server-local-fs-destination-is-same-or-descendant
      $canonical-source
      $resolved-destination)
   (codex:permissions-path-starts-with-path
     $resolved-destination
     $canonical-source))
