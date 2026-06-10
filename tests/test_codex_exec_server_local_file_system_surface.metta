!(register-module! ../codex)
!(import! &self codex:permissions)
!(import! &self codex:fs_sandbox)
!(import! &self codex:exec_server_runtime_paths)
!(import! &self codex:exec_server_file_system_protocol)
!(import! &self codex:exec_server_sandboxed_file_system)
!(import! &self codex:exec_server_local_file_system)

(= (test:runtime-paths)
   (codex:exec-server-runtime-paths
     "/opt/codex/bin/codex"
     CodexAbsent))

(= (test:local-unsandboxed)
   (codex:exec-server-local-file-system-unsandboxed))

(= (test:local-with-runtime-paths)
   (codex:exec-server-local-file-system-with-runtime-paths
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

(= (test:error $kind $message)
   (codex:exec-server-local-fs-file-system-error $kind $message))

(= (test:not-found $message)
   (test:error
     (codex:exec-server-local-fs-error-kind-not-found)
     $message))

(= (test:other-error $message)
   (test:error
     (codex:exec-server-local-fs-error-kind-other)
     $message))

(= (test:metadata
      $len
      $is-directory
      $is-file
      $created-time
      $modified-time)
   (codex:exec-server-local-fs-metadata-snapshot
     $len
     $is-directory
     $is-file
     $created-time
     $modified-time))

(= (test:symlink-metadata $file-type)
   (codex:exec-server-local-fs-symlink-metadata-snapshot
     $file-type))

(= (test:unit-ok)
   (CodexExecServerLocalFsResultOk
     (CodexExecServerLocalFsUnit)))

(= (assert-value-equal $value $expected)
   (let $actual $value
     (assertEqual $actual $expected)))

!(assertEqual
  (codex:exec-server-local-fs-max-read-file-bytes)
  536870912)

!(assertEqual
  (codex:exec-server-local-file-system-sandboxed-field
    (test:local-unsandboxed))
  CodexAbsent)

!(assertEqual
  (codex:exec-server-local-file-system-sandboxed-field
    (test:local-with-runtime-paths))
  (codex:exec-server-sandboxed-file-system-new
    (test:runtime-paths)))

!(assertEqual
  (codex:exec-server-local-fs-file-system-for
    (test:local-unsandboxed)
    CodexAbsent)
  (CodexExecServerLocalFsResultOk
    (CodexExecServerLocalFsSelectedUnsandboxed
      (CodexExecServerUnsandboxedFileSystem
        (CodexExecServerDirectFileSystem))
      CodexAbsent)))

!(assertEqual
  (codex:exec-server-local-fs-file-system-for
    (test:local-unsandboxed)
    (test:restricted-sandbox))
  (CodexExecServerLocalFsResultErr
    (test:error
      (codex:exec-server-local-fs-error-kind-invalid-input)
      "sandboxed filesystem operations require configured runtime paths")))

!(assertEqual
  (codex:exec-server-local-fs-file-system-for
    (test:local-with-runtime-paths)
    (test:restricted-sandbox))
  (CodexExecServerLocalFsResultOk
    (CodexExecServerLocalFsSelectedSandboxed
      (codex:exec-server-sandboxed-file-system-new
        (test:runtime-paths))
      (test:restricted-sandbox))))

!(assertEqual
  (codex:exec-server-local-fs-file-system-for
    (test:local-with-runtime-paths)
    (test:unrestricted-sandbox))
  (CodexExecServerLocalFsResultOk
    (CodexExecServerLocalFsSelectedUnsandboxed
      (CodexExecServerUnsandboxedFileSystem
        (CodexExecServerDirectFileSystem))
      (test:unrestricted-sandbox))))

!(assertEqual
  (codex:exec-server-local-fs-reject-sandbox-context
    (test:restricted-sandbox))
  (CodexExecServerLocalFsResultErr
    (test:error
      (codex:exec-server-local-fs-error-kind-invalid-input)
      "direct filesystem operations do not accept sandbox context")))

!(assertEqual
  (codex:exec-server-local-fs-reject-platform-sandbox-context
    (test:unrestricted-sandbox))
  (test:unit-ok))

!(assertEqual
  (codex:exec-server-local-fs-reject-platform-sandbox-context
    (test:full-write-sandbox))
  (test:unit-ok))

!(assertEqual
  (codex:exec-server-local-fs-reject-platform-sandbox-context
    (test:restricted-sandbox))
  (CodexExecServerLocalFsResultErr
    (test:error
      (codex:exec-server-local-fs-error-kind-invalid-input)
      "sandboxed filesystem operations require configured runtime paths")))

!(assertEqual
  (codex:exec-server-local-fs-direct-read-file
    "/repo/file.txt"
    CodexAbsent
    (CodexExecServerLocalFsResultOk
      (test:metadata
        5
        False
        True
        (codex:exec-server-local-fs-system-time-since-unix-ms 10)
        (codex:exec-server-local-fs-system-time-since-unix-ms 20)))
    (CodexExecServerLocalFsResultOk "hello"))
  (CodexExecServerLocalFsResultOk "hello"))

!(assertEqual
  (codex:exec-server-local-fs-direct-read-file
    "/repo/huge.bin"
    CodexAbsent
    (CodexExecServerLocalFsResultOk
      (test:metadata
        536870913
        False
        True
        (codex:exec-server-local-fs-system-time-err)
        (codex:exec-server-local-fs-system-time-err)))
    (CodexExecServerLocalFsResultOk "unused"))
  (CodexExecServerLocalFsResultErr
    (test:error
      (codex:exec-server-local-fs-error-kind-invalid-input)
      "file is too large to read: limit is 536870912 bytes")))

!(assertEqual
  (codex:exec-server-local-fs-direct-read-file
    "/repo/file.txt"
    (test:unrestricted-sandbox)
    (CodexExecServerLocalFsResultOk
      (test:metadata
        5
        False
        True
        (codex:exec-server-local-fs-system-time-err)
        (codex:exec-server-local-fs-system-time-err)))
    (CodexExecServerLocalFsResultOk "unused"))
  (CodexExecServerLocalFsResultErr
    (test:error
      (codex:exec-server-local-fs-error-kind-invalid-input)
      "direct filesystem operations do not accept sandbox context")))

!(assertEqual
  (codex:exec-server-local-fs-create-directory-plan
    (codex:exec-server-create-directory-options True))
  (CodexExecServerLocalFsCreateDirAll))

!(assertEqual
  (codex:exec-server-local-fs-create-directory-plan
    (codex:exec-server-create-directory-options False))
  (CodexExecServerLocalFsCreateDir))

!(assertEqual
  (codex:exec-server-local-fs-direct-write-file
    "/repo/file.txt"
    "hello"
    CodexAbsent
    (CodexExecServerLocalFsResultOk "ignored"))
  (test:unit-ok))

!(assertEqual
  (codex:exec-server-local-fs-direct-create-directory
    "/repo/new"
    (codex:exec-server-create-directory-options True)
    CodexAbsent
    (CodexExecServerLocalFsResultOk "ignored"))
  (test:unit-ok))

!(assertEqual
  (codex:exec-server-local-fs-direct-get-metadata
    "/repo/link"
    CodexAbsent
    (CodexExecServerLocalFsResultOk
      (test:metadata
        8
        False
        True
        (codex:exec-server-local-fs-system-time-since-unix-ms 100)
        (codex:exec-server-local-fs-system-time-err)))
    (CodexExecServerLocalFsResultOk
      (test:symlink-metadata
        (codex:exec-server-local-fs-file-type-symlink))))
  (CodexExecServerLocalFsResultOk
    (CodexExecServerFileMetadata False True True 100 0)))

!(assertEqual
  (codex:exec-server-local-fs-system-time-to-unix-ms
    (codex:exec-server-local-fs-system-time-since-unix-ms -1))
  0)

!(assertEqual
  (codex:exec-server-local-fs-system-time-to-unix-ms
    (codex:exec-server-local-fs-system-time-overflow))
  0)

!(assertEqual
  (codex:exec-server-local-fs-direct-read-directory
    "/repo"
    CodexAbsent
    (CodexExecServerLocalFsResultOk
      ((codex:exec-server-local-fs-directory-entry
         "src"
         (CodexExecServerLocalFsResultOk
           (test:metadata
             0
             True
             False
             (codex:exec-server-local-fs-system-time-err)
             (codex:exec-server-local-fs-system-time-err))))
       (codex:exec-server-local-fs-directory-entry
         "broken"
         (CodexExecServerLocalFsResultErr
           (test:not-found "missing during metadata read")))
       (codex:exec-server-local-fs-directory-entry
         "README.md"
         (CodexExecServerLocalFsResultOk
           (test:metadata
             100
             False
             True
             (codex:exec-server-local-fs-system-time-err)
             (codex:exec-server-local-fs-system-time-err)))))))
  (CodexExecServerLocalFsResultOk
    ((CodexExecServerFsReadDirectoryEntry "src" True False)
     (CodexExecServerFsReadDirectoryEntry "README.md" False True))))

!(assertEqual
  (codex:exec-server-local-fs-remove-plan
    (codex:exec-server-remove-options True True)
    (CodexExecServerLocalFsResultErr
      (test:not-found "missing")))
  (CodexExecServerLocalFsResultOk
    (CodexExecServerLocalFsRemovePlanNoop)))

!(assertEqual
  (codex:exec-server-local-fs-direct-remove
    "/repo/missing"
    (codex:exec-server-remove-options True True)
    CodexAbsent
    (CodexExecServerLocalFsResultErr
      (test:not-found "missing"))
    (CodexExecServerLocalFsResultErr
      (test:other-error "should not be used")))
  (test:unit-ok))

!(assertEqual
  (codex:exec-server-local-fs-remove-plan
    (codex:exec-server-remove-options True False)
    (CodexExecServerLocalFsResultOk
      (test:symlink-metadata
        (codex:exec-server-local-fs-file-type-directory))))
  (CodexExecServerLocalFsResultOk
    (CodexExecServerLocalFsRemovePlanRemoveDirAll)))

!(assertEqual
  (codex:exec-server-local-fs-remove-plan
    (codex:exec-server-remove-options False False)
    (CodexExecServerLocalFsResultOk
      (test:symlink-metadata
        (codex:exec-server-local-fs-file-type-directory))))
  (CodexExecServerLocalFsResultOk
    (CodexExecServerLocalFsRemovePlanRemoveDir)))

!(assertEqual
  (codex:exec-server-local-fs-remove-plan
    (codex:exec-server-remove-options True False)
    (CodexExecServerLocalFsResultOk
      (test:symlink-metadata
        (codex:exec-server-local-fs-file-type-symlink))))
  (CodexExecServerLocalFsResultOk
    (CodexExecServerLocalFsRemovePlanRemoveFile)))

!(assertEqual
  (codex:exec-server-local-fs-copy-plan
    (codex:exec-server-copy-options False)
    (CodexExecServerLocalFsResultOk
      (test:symlink-metadata
        (codex:exec-server-local-fs-file-type-directory)))
    (CodexExecServerLocalFsResultOk False))
  (CodexExecServerLocalFsResultErr
    (test:error
      (codex:exec-server-local-fs-error-kind-invalid-input)
      "fs/copy requires recursive: true when sourcePath is a directory")))

!(assertEqual
  (codex:exec-server-local-fs-copy-plan
    (codex:exec-server-copy-options True)
    (CodexExecServerLocalFsResultOk
      (test:symlink-metadata
        (codex:exec-server-local-fs-file-type-directory)))
    (CodexExecServerLocalFsResultOk True))
  (CodexExecServerLocalFsResultErr
    (test:error
      (codex:exec-server-local-fs-error-kind-invalid-input)
      "fs/copy cannot copy a directory to itself or one of its descendants")))

!(assertEqual
  (codex:exec-server-local-fs-copy-plan
    (codex:exec-server-copy-options True)
    (CodexExecServerLocalFsResultOk
      (test:symlink-metadata
        (codex:exec-server-local-fs-file-type-directory)))
    (CodexExecServerLocalFsResultOk False))
  (CodexExecServerLocalFsResultOk
    (CodexExecServerLocalFsCopyPlanCopyDirRecursive)))

!(assertEqual
  (codex:exec-server-local-fs-copy-plan
    (codex:exec-server-copy-options True)
    (CodexExecServerLocalFsResultOk
      (test:symlink-metadata
        (codex:exec-server-local-fs-file-type-file)))
    CodexAbsent)
  (CodexExecServerLocalFsResultOk
    (CodexExecServerLocalFsCopyPlanCopyFile)))

!(assertEqual
  (codex:exec-server-local-fs-copy-plan
    (codex:exec-server-copy-options True)
    (CodexExecServerLocalFsResultOk
      (test:symlink-metadata
        (codex:exec-server-local-fs-file-type-symlink)))
    CodexAbsent)
  (CodexExecServerLocalFsResultOk
    (CodexExecServerLocalFsCopyPlanCopySymlink)))

!(assertEqual
  (codex:exec-server-local-fs-copy-plan
    (codex:exec-server-copy-options True)
    (CodexExecServerLocalFsResultOk
      (test:symlink-metadata
        (codex:exec-server-local-fs-file-type-other)))
    CodexAbsent)
  (CodexExecServerLocalFsResultErr
    (test:error
      (codex:exec-server-local-fs-error-kind-invalid-input)
      "fs/copy only supports regular files, directories, and symlinks")))

!(assertEqual
  (codex:exec-server-local-fs-direct-copy
    "/repo/a"
    "/repo/b"
    (codex:exec-server-copy-options True)
    CodexAbsent
    (codex:exec-server-local-fs-copy-task-join-err
      "panic in blocking task"))
  (CodexExecServerLocalFsResultErr
    (test:error
      (codex:exec-server-local-fs-error-kind-other)
      "filesystem task failed: panic in blocking task")))

!(assertEqual
  (codex:exec-server-local-fs-direct-copy
    "/repo/a"
    "/repo/b"
    (codex:exec-server-copy-options True)
    CodexAbsent
    (codex:exec-server-local-fs-copy-task-ok
      (CodexExecServerLocalFsResultOk
        (test:symlink-metadata
          (codex:exec-server-local-fs-file-type-file)))
      CodexAbsent
      (CodexExecServerLocalFsResultOk "ignored")))
  (test:unit-ok))

!(assertEqual
  (codex:exec-server-local-fs-copy-dir-action-create-dir-all
    "/repo/target")
  (CodexExecServerLocalFsCopyDirActionCreateDirAll "/repo/target"))

!(assertEqual
  (codex:exec-server-local-fs-copy-dir-entry-action
    "/repo/source"
    "/repo/target"
    (codex:exec-server-local-fs-copy-dir-entry
       "src"
       (codex:exec-server-local-fs-file-type-directory)))
  (CodexExecServerLocalFsCopyDirActionRecurse
    "/repo/source/src"
    "/repo/target/src"))

!(assertEqual
  (codex:exec-server-local-fs-copy-dir-entry-action
    "/repo/source"
    "/repo/target"
    (codex:exec-server-local-fs-copy-dir-entry
      "current"
      (codex:exec-server-local-fs-file-type-symlink)))
  (CodexExecServerLocalFsCopyDirActionCopySymlink
    "/repo/source/current"
    "/repo/target/current"))

!(assertEqual
  (codex:exec-server-local-fs-copy-dir-entry-action
    "/repo/source"
    "/repo/target"
    (codex:exec-server-local-fs-copy-dir-entry
      "README.md"
      (codex:exec-server-local-fs-file-type-file)))
  (CodexExecServerLocalFsCopyDirActionCopyFile
    "/repo/source/README.md"
    "/repo/target/README.md"))

!(assertEqual
  (codex:exec-server-local-fs-copy-dir-entry-action
    "/repo/source"
    "/repo/target"
    (codex:exec-server-local-fs-copy-dir-entry
      "socket"
      (codex:exec-server-local-fs-file-type-other)))
  CodexAbsent)

!(assertEqual
  (codex:exec-server-local-fs-resolve-existing-path-from-prefix
    "/repo/missing/child.txt"
    "/repo"
    "/real/repo")
  (CodexExecServerLocalFsResultOk
    "/real/repo/missing/child.txt"))

!(assert-value-equal
  (codex:exec-server-local-fs-destination-is-same-or-descendant
    "/repo/source"
    "/repo/source/nested")
  True)

!(assert-value-equal
  (codex:exec-server-local-fs-destination-is-same-or-descendant
    "/repo/source"
    "/repo/source-other")
  False)
