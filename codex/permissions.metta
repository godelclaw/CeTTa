; Visible modern permissions slice for the restarted Codex port.
;
; This ports the adjacent foundational data/helper tranche from:
; - openai-codex/codex-rs/protocol/src/permissions.rs
;
; Covered in this increment:
; - NetworkSandboxPolicy
; - FileSystemAccessMode
; - FileSystemSpecialPath
; - FileSystemPath
; - FileSystemSandboxEntry
; - FileSystemSandboxKind
; - FileSystemSandboxPolicy constructors/default and JSON projection
; - foundational helper behavior:
;   - is_enabled
;   - can_read / can_write
;   - has_denied_read_restrictions
;   - has_full_disk_read_access
;   - has_full_disk_write_access
;   - include_platform_defaults
;
; Required CeTTa deviations for audit:
; - Rust carries AbsolutePathBuf/PathBuf values in the filesystem sandbox
;   layer. This restart slice carries the same visible path values directly as
;   strings, so callers are responsible for passing already-normalized visible
;   path strings wherever Rust would already have a validated path buffer.
; - Rust also exposes FromStr via serde_json for these types. That parse-side
;   bridge is deferred until the deeper JSON-to-atom coercion layer lands.
; - Rust resolves relative paths against the process cwd through
;   `AbsolutePathBuf` helpers. This restart slice preserves the same visible
;   absolute-path behavior with lexical `path-*` reducers plus narrow runtime
;   reads of `$PWD` and `$TMPDIR`, because there is no fully equivalent
;   in-language absolute-path runtime yet.

!(import! &self fs)
!(import! &self list)
!(import! &self path)
!(import! &self process)
!(import! &self str)

(= (codex:permissions-helper-cwd)
   "/")

(= (codex:permissions-helper-timeout-ms)
   1000)

(= (codex:permissions-helper-max-bytes)
   1048576)

(= (codex:permissions-current-dir)
   (let $result
     (process-run-shell-cwd-timeout-cap-bytes
       "printf %s \"$PWD\""
       (codex:permissions-helper-cwd)
       (codex:permissions-helper-timeout-ms)
       (codex:permissions-helper-max-bytes))
     (if (== (process-result-exit-code $result) 0)
         (path-normalize (process-result-stdout $result))
         (codex:permissions-helper-cwd))))

(= (codex:permissions-tmpdir-from-env)
   (let $result
     (process-run-shell-cwd-timeout-cap-bytes
       "printf %s \"$TMPDIR\""
       (codex:permissions-helper-cwd)
       (codex:permissions-helper-timeout-ms)
       (codex:permissions-helper-max-bytes))
     (if (== (process-result-exit-code $result) 0)
         (process-result-stdout $result)
         "")))

(= (codex:permissions-resolve-base-cwd $cwd)
   (if (path-is-absolute? $cwd)
       (path-normalize $cwd)
       (path-normalize
         (path-join
           (codex:permissions-current-dir)
           $cwd))))

(= (codex:permissions-absolute-root-path-for-cwd $cwd)
   "/")

(= (codex:permissions-trim-trailing-slash-unless-root "/")
   "/")

(= (codex:permissions-trim-trailing-slash-unless-root $text)
   (if (str-ends-with? $text "/")
       (codex:permissions-trim-trailing-slash-unless-root
         (str-slice $text 0 (- (str-length $text) 1)))
       $text))

(= (codex:permissions-path-starts-with-path $path $prefix)
   (let $normalized-path
     (codex:permissions-trim-trailing-slash-unless-root
       (path-normalize $path))
     (let $normalized-prefix
       (codex:permissions-trim-trailing-slash-unless-root
         (path-normalize $prefix))
       (if (== (path-is-absolute? $normalized-path)
               (path-is-absolute? $normalized-prefix))
           (if (== $normalized-prefix "/")
               True
               (if (== $normalized-path $normalized-prefix)
                   True
                   (str-starts-with?
                     $normalized-path
                     (str-concat $normalized-prefix "/"))))
           False))))

(= (codex:network-sandbox-policy-restricted)
   (CodexNetworkSandboxPolicyRestricted))

(= (codex:network-sandbox-policy-enabled)
   (CodexNetworkSandboxPolicyEnabled))

(= (codex:network-sandbox-policy-is-enabled
      (CodexNetworkSandboxPolicyRestricted))
   False)

(= (codex:network-sandbox-policy-is-enabled
      (CodexNetworkSandboxPolicyEnabled))
   True)

(= (codex:network-sandbox-policy-json
      (CodexNetworkSandboxPolicyRestricted))
   (JsonString "restricted"))

(= (codex:network-sandbox-policy-json
      (CodexNetworkSandboxPolicyEnabled))
   (JsonString "enabled"))

(= (codex:file-system-access-read)
   (CodexFileSystemAccessModeRead))

(= (codex:file-system-access-write)
   (CodexFileSystemAccessModeWrite))

(= (codex:file-system-access-none)
   (CodexFileSystemAccessModeNone))

(= (codex:file-system-access-mode-can-read
      (CodexFileSystemAccessModeRead))
   True)

(= (codex:file-system-access-mode-can-read
      (CodexFileSystemAccessModeWrite))
   True)

(= (codex:file-system-access-mode-can-read
      (CodexFileSystemAccessModeNone))
   False)

(= (codex:file-system-access-mode-can-write
      (CodexFileSystemAccessModeRead))
   False)

(= (codex:file-system-access-mode-can-write
      (CodexFileSystemAccessModeWrite))
   True)

(= (codex:file-system-access-mode-can-write
      (CodexFileSystemAccessModeNone))
   False)

(= (codex:file-system-access-mode-ordinal
      (CodexFileSystemAccessModeRead))
   0)

(= (codex:file-system-access-mode-ordinal
      (CodexFileSystemAccessModeWrite))
   1)

(= (codex:file-system-access-mode-ordinal
      (CodexFileSystemAccessModeNone))
   2)

(= (codex:file-system-access-mode-json
      (CodexFileSystemAccessModeRead))
   (JsonString "read"))

(= (codex:file-system-access-mode-json
      (CodexFileSystemAccessModeWrite))
   (JsonString "write"))

(= (codex:file-system-access-mode-json
      (CodexFileSystemAccessModeNone))
   (JsonString "none"))

(= (codex:file-system-special-path-root)
   (CodexFileSystemSpecialPathRoot))

(= (codex:file-system-special-path-minimal)
   (CodexFileSystemSpecialPathMinimal))

(= (codex:file-system-special-path-current-working-directory)
   (CodexFileSystemSpecialPathCurrentWorkingDirectory))

(= (codex:file-system-special-path-project-roots $subpath)
   (CodexFileSystemSpecialPathProjectRoots $subpath))

(= (codex:file-system-special-path-tmpdir)
   (CodexFileSystemSpecialPathTmpdir))

(= (codex:file-system-special-path-slash-tmp)
   (CodexFileSystemSpecialPathSlashTmp))

(= (codex:file-system-special-path-unknown $path $subpath)
   (CodexFileSystemSpecialPathUnknown $path $subpath))

(= (codex:file-system-special-path-tag
      (CodexFileSystemSpecialPathRoot))
   "root")

(= (codex:file-system-special-path-tag
      (CodexFileSystemSpecialPathMinimal))
   "minimal")

(= (codex:file-system-special-path-tag
      (CodexFileSystemSpecialPathCurrentWorkingDirectory))
   "current_working_directory")

(= (codex:file-system-special-path-tag
      (CodexFileSystemSpecialPathProjectRoots $subpath))
   "project_roots")

(= (codex:file-system-special-path-tag
      (CodexFileSystemSpecialPathTmpdir))
   "tmpdir")

(= (codex:file-system-special-path-tag
      (CodexFileSystemSpecialPathSlashTmp))
   "slash_tmp")

(= (codex:file-system-special-path-tag
      (CodexFileSystemSpecialPathUnknown $path $subpath))
   "unknown")

(= (codex:file-system-special-path-project-roots-subpath
      (CodexFileSystemSpecialPathProjectRoots $subpath))
   $subpath)

(= (codex:file-system-special-path-unknown-path
      (CodexFileSystemSpecialPathUnknown $path $subpath))
   $path)

(= (codex:file-system-special-path-unknown-subpath
      (CodexFileSystemSpecialPathUnknown $path $subpath))
   $subpath)

(= (codex:file-system-special-path-json
      (CodexFileSystemSpecialPathRoot))
   (JsonObject
     ((JsonPair "kind" (JsonString "root")))))

(= (codex:file-system-special-path-json
      (CodexFileSystemSpecialPathMinimal))
   (JsonObject
     ((JsonPair "kind" (JsonString "minimal")))))

(= (codex:file-system-special-path-json
      (CodexFileSystemSpecialPathCurrentWorkingDirectory))
   (JsonObject
     ((JsonPair "kind" (JsonString "current_working_directory")))))

(= (codex:file-system-special-path-json
      (CodexFileSystemSpecialPathProjectRoots $subpath))
   (if (== $subpath CodexAbsent)
       (JsonObject
         ((JsonPair "kind" (JsonString "project_roots"))))
       (JsonObject
         ((JsonPair "kind" (JsonString "project_roots"))
          (JsonPair "subpath" (JsonString $subpath))))))

(= (codex:file-system-special-path-json
      (CodexFileSystemSpecialPathTmpdir))
   (JsonObject
     ((JsonPair "kind" (JsonString "tmpdir")))))

(= (codex:file-system-special-path-json
      (CodexFileSystemSpecialPathSlashTmp))
   (JsonObject
     ((JsonPair "kind" (JsonString "slash_tmp")))))

(= (codex:file-system-special-path-json
      (CodexFileSystemSpecialPathUnknown $path $subpath))
   (if (== $subpath CodexAbsent)
       (JsonObject
         ((JsonPair "kind" (JsonString "unknown"))
          (JsonPair "path" (JsonString $path))))
       (JsonObject
         ((JsonPair "kind" (JsonString "unknown"))
          (JsonPair "path" (JsonString $path))
          (JsonPair "subpath" (JsonString $subpath))))))

(= (codex:file-system-path-path $path)
   (CodexFileSystemPathPath $path))

(= (codex:file-system-path-glob-pattern $pattern)
   (CodexFileSystemPathGlobPattern $pattern))

(= (codex:file-system-path-special $value)
   (CodexFileSystemPathSpecial $value))

(= (codex:file-system-path-tag
      (CodexFileSystemPathPath $path))
   "path")

(= (codex:file-system-path-tag
      (CodexFileSystemPathGlobPattern $pattern))
   "glob_pattern")

(= (codex:file-system-path-tag
      (CodexFileSystemPathSpecial $value))
   "special")

(= (codex:file-system-path-absolute-path
      (CodexFileSystemPathPath $path))
   $path)

(= (codex:file-system-path-glob-pattern-value
      (CodexFileSystemPathGlobPattern $pattern))
   $pattern)

(= (codex:file-system-path-special-value
      (CodexFileSystemPathSpecial $value))
   $value)

(= (codex:file-system-path-json
      (CodexFileSystemPathPath $path))
   (JsonObject
     ((JsonPair "type" (JsonString "path"))
      (JsonPair "path" (JsonString $path)))))

(= (codex:file-system-path-json
      (CodexFileSystemPathGlobPattern $pattern))
   (JsonObject
     ((JsonPair "type" (JsonString "glob_pattern"))
      (JsonPair "pattern" (JsonString $pattern)))))

(= (codex:file-system-path-json
      (CodexFileSystemPathSpecial $value))
   (JsonObject
     ((JsonPair "type" (JsonString "special"))
      (JsonPair "value" (codex:file-system-special-path-json $value)))))

(= (codex:file-system-sandbox-entry $path $access)
   (CodexFileSystemSandboxEntry $path $access))

(= (codex:file-system-sandbox-entry-path
      (CodexFileSystemSandboxEntry $path $access))
   $path)

(= (codex:file-system-sandbox-entry-access
      (CodexFileSystemSandboxEntry $path $access))
   $access)

(= (codex:file-system-path-is-special-root $path)
   (and
     (== (codex:file-system-path-tag $path) "special")
     (== (codex:file-system-path-special-value $path)
         (CodexFileSystemSpecialPathRoot))))

(= (codex:file-system-path-is-special-minimal $path)
   (and
     (== (codex:file-system-path-tag $path) "special")
     (== (codex:file-system-path-special-value $path)
         (CodexFileSystemSpecialPathMinimal))))

(= (codex:file-system-sandbox-entry-json
      (CodexFileSystemSandboxEntry $path $access))
   (JsonObject
     ((JsonPair "path" (codex:file-system-path-json $path))
      (JsonPair "access" (codex:file-system-access-mode-json $access)))))

(= (codex:file-system-sandbox-entry-json-items $items)
   (function
     (let $json-items
       (eval
         (map-atom
           $items
           $item
           (codex:file-system-sandbox-entry-json $item)))
       (return $json-items))))

(= (codex:file-system-sandbox-kind-restricted)
   (CodexFileSystemSandboxKindRestricted))

(= (codex:file-system-sandbox-kind-unrestricted)
   (CodexFileSystemSandboxKindUnrestricted))

(= (codex:file-system-sandbox-kind-external-sandbox)
   (CodexFileSystemSandboxKindExternalSandbox))

(= (codex:file-system-sandbox-kind-json
      (CodexFileSystemSandboxKindRestricted))
   (JsonString "restricted"))

(= (codex:file-system-sandbox-kind-json
      (CodexFileSystemSandboxKindUnrestricted))
   (JsonString "unrestricted"))

(= (codex:file-system-sandbox-kind-json
      (CodexFileSystemSandboxKindExternalSandbox))
   (JsonString "external-sandbox"))

(= (codex:file-system-sandbox-policy $kind $glob-scan-max-depth $entries)
   (CodexFileSystemSandboxPolicy $kind $glob-scan-max-depth $entries))

(= (codex:file-system-sandbox-policy-kind
      (CodexFileSystemSandboxPolicy $kind $glob-scan-max-depth $entries))
   $kind)

(= (codex:file-system-sandbox-policy-glob-scan-max-depth
      (CodexFileSystemSandboxPolicy $kind $glob-scan-max-depth $entries))
   $glob-scan-max-depth)

(= (codex:file-system-sandbox-policy-entries
      (CodexFileSystemSandboxPolicy $kind $glob-scan-max-depth $entries))
   $entries)

(= (codex:file-system-sandbox-policy-default)
   (CodexFileSystemSandboxPolicy
     (CodexFileSystemSandboxKindRestricted)
     CodexAbsent
     ((CodexFileSystemSandboxEntry
        (CodexFileSystemPathSpecial
          (CodexFileSystemSpecialPathRoot))
        (CodexFileSystemAccessModeRead)))))

(= (codex:file-system-sandbox-policy-unrestricted)
   (CodexFileSystemSandboxPolicy
     (CodexFileSystemSandboxKindUnrestricted)
     CodexAbsent
     ()))

(= (codex:file-system-sandbox-policy-external-sandbox)
   (CodexFileSystemSandboxPolicy
     (CodexFileSystemSandboxKindExternalSandbox)
     CodexAbsent
     ()))

(= (codex:file-system-sandbox-policy-restricted $entries)
   (CodexFileSystemSandboxPolicy
     (CodexFileSystemSandboxKindRestricted)
     CodexAbsent
     $entries))

(= (codex:permissions-append-json-pair $pairs $key $value)
   (list:append $pairs
     ((JsonPair $key $value))))

(= (codex:file-system-sandbox-policy-json
      (CodexFileSystemSandboxPolicy $kind $glob-scan-max-depth $entries))
   (let $pairs-0
     ((JsonPair "kind" (codex:file-system-sandbox-kind-json $kind)))
     (let $pairs-1
       (if (== $glob-scan-max-depth CodexAbsent)
           $pairs-0
           (codex:permissions-append-json-pair
             $pairs-0
             "glob_scan_max_depth"
             (JsonNumber $glob-scan-max-depth)))
       (let $pairs-2
         (if (== $entries ())
             $pairs-1
             (codex:permissions-append-json-pair
               $pairs-1
               "entries"
               (JsonArray
                 (codex:file-system-sandbox-entry-json-items $entries))))
         (JsonObject $pairs-2)))))

(= (codex:file-system-special-path-shares-target $left $right)
   (if (== $left $right)
       True
       (if (and
             (== $left
                 (CodexFileSystemSpecialPathCurrentWorkingDirectory))
             (== $right
                 (CodexFileSystemSpecialPathProjectRoots CodexAbsent)))
           True
           (if (and
                 (== $left
                     (CodexFileSystemSpecialPathProjectRoots CodexAbsent))
                 (== $right
                     (CodexFileSystemSpecialPathCurrentWorkingDirectory)))
               True
               (if (and
                     (== (codex:file-system-special-path-tag $left)
                         "project_roots")
                     (== (codex:file-system-special-path-tag $right)
                         "project_roots"))
                   (== (codex:file-system-special-path-project-roots-subpath $left)
                       (codex:file-system-special-path-project-roots-subpath $right))
                   (if (and
                         (== (codex:file-system-special-path-tag $left)
                             "unknown")
                         (== (codex:file-system-special-path-tag $right)
                             "unknown"))
                       (and
                         (== (codex:file-system-special-path-unknown-path $left)
                             (codex:file-system-special-path-unknown-path $right))
                         (== (codex:file-system-special-path-unknown-subpath $left)
                             (codex:file-system-special-path-unknown-subpath $right)))
                       False))))))

(= (codex:file-system-special-path-matches-absolute-path $value $path)
   (if (== $value (CodexFileSystemSpecialPathRoot))
       (== $path "/")
       (if (== $value (CodexFileSystemSpecialPathSlashTmp))
           (== $path "/tmp")
           False)))

(= (codex:file-system-paths-share-target $left $right)
   (if (and
         (== (codex:file-system-path-tag $left) "path")
         (== (codex:file-system-path-tag $right) "path"))
       (== (codex:file-system-path-absolute-path $left)
           (codex:file-system-path-absolute-path $right))
       (if (and
             (== (codex:file-system-path-tag $left) "special")
             (== (codex:file-system-path-tag $right) "special"))
           (codex:file-system-special-path-shares-target
             (codex:file-system-path-special-value $left)
             (codex:file-system-path-special-value $right))
           (if (and
                 (== (codex:file-system-path-tag $left) "path")
                 (== (codex:file-system-path-tag $right) "special"))
               (codex:file-system-special-path-matches-absolute-path
                 (codex:file-system-path-special-value $right)
                 (codex:file-system-path-absolute-path $left))
               (if (and
                     (== (codex:file-system-path-tag $left) "special")
                     (== (codex:file-system-path-tag $right) "path"))
                   (codex:file-system-special-path-matches-absolute-path
                     (codex:file-system-path-special-value $left)
                     (codex:file-system-path-absolute-path $right))
                   (if (and
                         (== (codex:file-system-path-tag $left) "glob_pattern")
                         (== (codex:file-system-path-tag $right) "glob_pattern"))
                       (== (codex:file-system-path-glob-pattern-value $left)
                           (codex:file-system-path-glob-pattern-value $right))
                       False))))))

(= (codex:file-system-sandbox-entry-has-same-target-write-override
      ()
      $entry)
   False)

(= (codex:file-system-sandbox-entry-has-same-target-write-override
      $entries
      (CodexFileSystemSandboxEntry $path $access))
   (let ($candidate $tail) (decons-atom $entries)
     (let $candidate-path
       (codex:file-system-sandbox-entry-path $candidate)
       (let $candidate-access
         (codex:file-system-sandbox-entry-access $candidate)
         (if (and
               (codex:file-system-access-mode-can-write $candidate-access)
               (and
                 (> (codex:file-system-access-mode-ordinal $candidate-access)
                    (codex:file-system-access-mode-ordinal $access))
                 (codex:file-system-paths-share-target $candidate-path $path)))
             True
             (codex:file-system-sandbox-entry-has-same-target-write-override
               $tail
               (CodexFileSystemSandboxEntry $path $access)))))))

(= (codex:file-system-sandbox-entry-is-write-narrowing
      $entries
      (CodexFileSystemSandboxEntry
        (CodexFileSystemPathPath $path)
        $access))
   (if (codex:file-system-access-mode-can-write $access)
       False
       (not
         (codex:file-system-sandbox-entry-has-same-target-write-override
           $entries
           (CodexFileSystemSandboxEntry
             (CodexFileSystemPathPath $path)
             $access)))))

(= (codex:file-system-sandbox-entry-is-write-narrowing
      $entries
      (CodexFileSystemSandboxEntry
        (CodexFileSystemPathGlobPattern $pattern)
        $access))
   (not (codex:file-system-access-mode-can-write $access)))

(= (codex:file-system-sandbox-entry-is-write-narrowing
      $entries
      (CodexFileSystemSandboxEntry
        (CodexFileSystemPathSpecial $value)
        $access))
   (codex:file-system-special-entry-is-write-narrowing
     $entries
     $value
     $access))

(= (codex:file-system-sandbox-entries-have-write-narrowing ())
   False)

(= (codex:file-system-sandbox-entries-have-write-narrowing $entries)
   (let ($head $tail) (decons-atom $entries)
     (if (codex:file-system-sandbox-entry-is-write-narrowing
           $entries
           $head)
         True
         (codex:file-system-sandbox-entries-have-write-narrowing
           $tail))))

(= (codex:file-system-sandbox-entries-have-root-read-access ())
   False)

(= (codex:file-system-sandbox-entries-have-root-read-access $entries)
   (let ($head $tail) (decons-atom $entries)
     (if (and
           (codex:file-system-path-is-special-root
             (codex:file-system-sandbox-entry-path $head))
           (codex:file-system-access-mode-can-read
             (codex:file-system-sandbox-entry-access $head)))
         True
         (codex:file-system-sandbox-entries-have-root-read-access
           $tail))))

(= (codex:file-system-sandbox-entries-have-root-write-access ())
   False)

(= (codex:file-system-sandbox-entries-have-root-write-access $entries)
   (let ($head $tail) (decons-atom $entries)
     (if (and
           (codex:file-system-path-is-special-root
             (codex:file-system-sandbox-entry-path $head))
           (codex:file-system-access-mode-can-write
             (codex:file-system-sandbox-entry-access $head)))
         True
         (codex:file-system-sandbox-entries-have-root-write-access
           $tail))))

(= (codex:file-system-sandbox-entries-have-denied-read ())
   False)

(= (codex:file-system-sandbox-entries-have-denied-read $entries)
   (let ($head $tail) (decons-atom $entries)
     (if (== (codex:file-system-sandbox-entry-access $head)
             (CodexFileSystemAccessModeNone))
         True
         (codex:file-system-sandbox-entries-have-denied-read
           $tail))))

(= (codex:file-system-sandbox-entries-include-platform-defaults ())
   False)

(= (codex:file-system-sandbox-entries-include-platform-defaults $entries)
   (let ($head $tail) (decons-atom $entries)
     (if (and
           (codex:file-system-path-is-special-minimal
             (codex:file-system-sandbox-entry-path $head))
           (codex:file-system-access-mode-can-read
             (codex:file-system-sandbox-entry-access $head)))
         True
         (codex:file-system-sandbox-entries-include-platform-defaults
           $tail))))

(= (codex:file-system-sandbox-policy-has-denied-read-restrictions
      (CodexFileSystemSandboxPolicy $kind $glob-scan-max-depth $entries))
   (if (== $kind (CodexFileSystemSandboxKindRestricted))
       (codex:file-system-sandbox-entries-have-denied-read $entries)
       False))

(= (codex:file-system-sandbox-entries-contain-entry
      ()
      $entry)
   False)

(= (codex:file-system-sandbox-entries-contain-entry
      $entries
      $entry)
   (let ($head $tail) (decons-atom $entries)
     (if (== $head $entry)
         True
         (codex:file-system-sandbox-entries-contain-entry
           $tail
           $entry))))

(= (codex:file-system-sandbox-entries-append-missing-deny-read-entries
      $entries
      ())
   $entries)

(= (codex:file-system-sandbox-entries-append-missing-deny-read-entries
      $entries
      $existing-entries)
   (let ($head $tail) (decons-atom $existing-entries)
     (if (== (codex:file-system-sandbox-entry-access $head)
             (CodexFileSystemAccessModeNone))
         (if (codex:file-system-sandbox-entries-contain-entry
               $entries
               $head)
             (codex:file-system-sandbox-entries-append-missing-deny-read-entries
               $entries
               $tail)
             (codex:file-system-sandbox-entries-append-missing-deny-read-entries
               (list:append $entries ($head))
               $tail))
         (codex:file-system-sandbox-entries-append-missing-deny-read-entries
           $entries
           $tail))))

; Rust mutates `self` in place. CeTTa returns the updated policy value instead,
; while preserving the same visible result after the mutation would complete.
(= (codex:file-system-sandbox-policy-preserve-deny-read-restrictions-from
      (CodexFileSystemSandboxPolicy $kind $glob-scan-max-depth $entries)
      (CodexFileSystemSandboxPolicy
        $existing-kind
        $existing-glob-scan-max-depth
        $existing-entries))
   (let $has-deny-read-entries
     (codex:file-system-sandbox-entries-have-denied-read $existing-entries)
     (let $normalized-policy
       (if (and
             (== $kind (CodexFileSystemSandboxKindUnrestricted))
             $has-deny-read-entries)
           (CodexFileSystemSandboxPolicy
             (CodexFileSystemSandboxKindRestricted)
             CodexAbsent
             ((CodexFileSystemSandboxEntry
                (CodexFileSystemPathSpecial
                  (CodexFileSystemSpecialPathRoot))
                (CodexFileSystemAccessModeWrite))))
           (CodexFileSystemSandboxPolicy
             $kind
             $glob-scan-max-depth
             $entries))
       (codex:file-system-sandbox-policy-preserve-deny-read-restrictions-from-normalized
         $normalized-policy
         (CodexFileSystemSandboxPolicy
           $existing-kind
           $existing-glob-scan-max-depth
           $existing-entries)))))

(= (codex:file-system-sandbox-policy-preserve-deny-read-restrictions-from-normalized
      (CodexFileSystemSandboxPolicy $kind $glob-scan-max-depth $entries)
      (CodexFileSystemSandboxPolicy
        $existing-kind
        $existing-glob-scan-max-depth
        $existing-entries))
   (if (not (== $kind (CodexFileSystemSandboxKindRestricted)))
       (CodexFileSystemSandboxPolicy
         $kind
         $glob-scan-max-depth
         $entries)
       (let $merged-glob-scan-max-depth
         (if (== $glob-scan-max-depth CodexAbsent)
             $existing-glob-scan-max-depth
             $glob-scan-max-depth)
         (let $merged-entries
           (codex:file-system-sandbox-entries-append-missing-deny-read-entries
             $entries
             $existing-entries)
           (CodexFileSystemSandboxPolicy
             $kind
             $merged-glob-scan-max-depth
             $merged-entries)))))

(= (codex:file-system-sandbox-policy-has-full-disk-read-access
      (CodexFileSystemSandboxPolicy $kind $glob-scan-max-depth $entries))
   (if (== $kind (CodexFileSystemSandboxKindUnrestricted))
       True
       (if (== $kind (CodexFileSystemSandboxKindExternalSandbox))
           True
           (and
             (codex:file-system-sandbox-entries-have-root-read-access $entries)
             (not
               (codex:file-system-sandbox-entries-have-denied-read
                 $entries))))))

(= (codex:file-system-sandbox-policy-has-full-disk-write-access
      (CodexFileSystemSandboxPolicy $kind $glob-scan-max-depth $entries))
   (if (== $kind (CodexFileSystemSandboxKindUnrestricted))
       True
       (if (== $kind (CodexFileSystemSandboxKindExternalSandbox))
           True
           (and
             (codex:file-system-sandbox-entries-have-root-write-access $entries)
             (not
               (codex:file-system-sandbox-entries-have-write-narrowing
                 $entries))))))

(= (codex:file-system-sandbox-policy-include-platform-defaults
      (CodexFileSystemSandboxPolicy $kind $glob-scan-max-depth $entries))
   (if (== $kind (CodexFileSystemSandboxKindRestricted))
       (and
         (not
           (codex:file-system-sandbox-policy-has-full-disk-read-access
             (CodexFileSystemSandboxPolicy
               $kind
               $glob-scan-max-depth
               $entries)))
         (codex:file-system-sandbox-entries-include-platform-defaults
           $entries))
       False))
(= (codex:file-system-special-entry-is-write-narrowing
      $entries
      $value
      $access)
   (if (codex:file-system-access-mode-can-write $access)
       False
       (if (== $value (CodexFileSystemSpecialPathRoot))
           (== $access (CodexFileSystemAccessModeNone))
           (if (== $value (CodexFileSystemSpecialPathMinimal))
               False
               (if (== (codex:file-system-special-path-tag $value) "unknown")
                   False
                   (not
                     (codex:file-system-sandbox-entry-has-same-target-write-override
                       $entries
                       (CodexFileSystemSandboxEntry
                         (CodexFileSystemPathSpecial $value)
                         $access))))))))

(= (codex:resolved-file-system-entry $path $access)
   (CodexResolvedFileSystemEntry $path $access))

(= (codex:resolved-file-system-entry-path
      (CodexResolvedFileSystemEntry $path $access))
   $path)

(= (codex:resolved-file-system-entry-access
      (CodexResolvedFileSystemEntry $path $access))
   $access)

(= (codex:resolved-file-system-entry-specificity
      (CodexResolvedFileSystemEntry $path $access))
   (+ (list:len (path-parts $path))
      (if (path-is-absolute? $path) 1 0)))

(= (codex:file-system-resolve-special-path
      (CodexFileSystemSpecialPathRoot)
      $cwd)
   CodexAbsent)

(= (codex:file-system-resolve-special-path
      (CodexFileSystemSpecialPathMinimal)
      $cwd)
   CodexAbsent)

(= (codex:file-system-resolve-special-path
      (CodexFileSystemSpecialPathCurrentWorkingDirectory)
      $cwd)
   (codex:permissions-resolve-base-cwd $cwd))

(= (codex:file-system-resolve-special-path
      (CodexFileSystemSpecialPathProjectRoots $subpath)
      $cwd)
   (if (== $subpath CodexAbsent)
       (codex:permissions-resolve-base-cwd $cwd)
       (path-normalize
         (path-join
           (codex:permissions-resolve-base-cwd $cwd)
           $subpath))))

(= (codex:file-system-resolve-special-path
      (CodexFileSystemSpecialPathTmpdir)
      $cwd)
   (let $tmpdir (codex:permissions-tmpdir-from-env)
     (if (or
           (== $tmpdir "")
           (not (path-is-absolute? $tmpdir)))
         CodexAbsent
         (path-normalize $tmpdir))))

(= (codex:file-system-resolve-special-path
      (CodexFileSystemSpecialPathSlashTmp)
      $cwd)
   (if (== (fs-path-kind "/tmp") "directory")
       "/tmp"
       CodexAbsent))

(= (codex:file-system-resolve-special-path
      (CodexFileSystemSpecialPathUnknown $path $subpath)
      $cwd)
   CodexAbsent)

(= (codex:file-system-resolve-path
      (CodexFileSystemPathPath $path)
      $cwd)
   (path-normalize $path))

(= (codex:file-system-resolve-path
      (CodexFileSystemPathGlobPattern $pattern)
      $cwd)
   CodexAbsent)

(= (codex:file-system-resolve-path
      (CodexFileSystemPathSpecial $value)
      $cwd)
   (codex:file-system-resolve-special-path $value $cwd))

(= (codex:file-system-resolve-entry-path
      (CodexFileSystemPathSpecial
        (CodexFileSystemSpecialPathRoot))
      $cwd)
   (codex:permissions-absolute-root-path-for-cwd
     (codex:permissions-resolve-base-cwd $cwd)))

(= (codex:file-system-resolve-entry-path $path $cwd)
   (codex:file-system-resolve-path $path $cwd))

(= (codex:file-system-resolve-candidate-path $path $cwd)
   (if (path-is-absolute? $path)
       (path-normalize $path)
       (path-normalize
         (path-join
           (codex:permissions-resolve-base-cwd $cwd)
           $path))))

(= (codex:file-system-resolved-entry-precedes? $candidate $best)
   (let $candidate-specificity
     (codex:resolved-file-system-entry-specificity $candidate)
     (let $best-specificity
       (codex:resolved-file-system-entry-specificity $best)
       (if (> $candidate-specificity $best-specificity)
           True
           (if (< $candidate-specificity $best-specificity)
               False
               (> (codex:file-system-access-mode-ordinal
                    (codex:resolved-file-system-entry-access $candidate))
                  (codex:file-system-access-mode-ordinal
                    (codex:resolved-file-system-entry-access $best))))))))

(= (codex:file-system-resolved-entries-with-cwd
      (CodexFileSystemSandboxPolicy $kind $glob-scan-max-depth ())
      $cwd)
   ())

(= (codex:file-system-resolved-entries-with-cwd
      (CodexFileSystemSandboxPolicy $kind $glob-scan-max-depth $entries)
      $cwd)
   (let ($head $tail) (decons-atom $entries)
     (let $tail-resolved
       (codex:file-system-resolved-entries-with-cwd
         (CodexFileSystemSandboxPolicy
           $kind
           $glob-scan-max-depth
           $tail)
         $cwd)
       (let $resolved-path
         (codex:file-system-resolve-entry-path
           (codex:file-system-sandbox-entry-path $head)
           $cwd)
         (if (== $resolved-path CodexAbsent)
             $tail-resolved
             (list:append
               ((codex:resolved-file-system-entry
                  $resolved-path
                  (codex:file-system-sandbox-entry-access $head)))
               $tail-resolved))))))

(= (codex:file-system-best-resolved-entry-for-path () $candidate-path)
   CodexAbsent)

(= (codex:file-system-best-resolved-entry-for-path $entries $candidate-path)
   (let ($head $tail) (decons-atom $entries)
     (let $head-path
       (codex:resolved-file-system-entry-path $head)
       (let $best-tail
         (codex:file-system-best-resolved-entry-for-path $tail $candidate-path)
         (if (codex:permissions-path-starts-with-path $candidate-path $head-path)
             (if (== $best-tail CodexAbsent)
                 $head
                 (if (codex:file-system-resolved-entry-precedes? $head $best-tail)
                     $head
                     $best-tail))
             $best-tail)))))

(= (codex:file-system-sandbox-policy-resolve-access-with-cwd
      (CodexFileSystemSandboxPolicy
        (CodexFileSystemSandboxKindUnrestricted)
        $glob-scan-max-depth
        $entries)
      $path
      $cwd)
   (CodexFileSystemAccessModeWrite))

(= (codex:file-system-sandbox-policy-resolve-access-with-cwd
      (CodexFileSystemSandboxPolicy
        (CodexFileSystemSandboxKindExternalSandbox)
        $glob-scan-max-depth
        $entries)
      $path
      $cwd)
   (CodexFileSystemAccessModeWrite))

(= (codex:file-system-sandbox-policy-resolve-access-with-cwd
      (CodexFileSystemSandboxPolicy
        (CodexFileSystemSandboxKindRestricted)
        $glob-scan-max-depth
        $entries)
      $path
      $cwd)
   (let $candidate-path
     (codex:file-system-resolve-candidate-path $path $cwd)
     (let $best-entry
       (codex:file-system-best-resolved-entry-for-path
         (codex:file-system-resolved-entries-with-cwd
           (CodexFileSystemSandboxPolicy
             (CodexFileSystemSandboxKindRestricted)
             $glob-scan-max-depth
             $entries)
           $cwd)
         $candidate-path)
       (if (== $best-entry CodexAbsent)
           (CodexFileSystemAccessModeNone)
           (codex:resolved-file-system-entry-access $best-entry)))))

(= (codex:file-system-sandbox-policy-can-read-path-with-cwd
      $policy
      $path
      $cwd)
   (codex:file-system-access-mode-can-read
     (codex:file-system-sandbox-policy-resolve-access-with-cwd
       $policy
       $path
       $cwd)))

(= (codex:file-system-sandbox-policy-can-write-path-with-cwd
      $policy
      $path
      $cwd)
   (codex:file-system-access-mode-can-write
     (codex:file-system-sandbox-policy-resolve-access-with-cwd
       $policy
       $path
       $cwd)))

(= (codex:file-system-sandbox-policy-with-additional-readable-roots
      (CodexFileSystemSandboxPolicy $kind $glob-scan-max-depth $entries)
      $cwd
      ()
      )
   (CodexFileSystemSandboxPolicy $kind $glob-scan-max-depth $entries))

(= (codex:file-system-sandbox-policy-with-additional-readable-roots
      (CodexFileSystemSandboxPolicy $kind $glob-scan-max-depth $entries)
      $cwd
      $additional-readable-roots)
   (if (codex:file-system-sandbox-policy-has-full-disk-read-access
         (CodexFileSystemSandboxPolicy $kind $glob-scan-max-depth $entries))
       (CodexFileSystemSandboxPolicy $kind $glob-scan-max-depth $entries)
       (let ($head $tail) (decons-atom $additional-readable-roots)
         (if (codex:file-system-sandbox-policy-can-read-path-with-cwd
               (CodexFileSystemSandboxPolicy $kind $glob-scan-max-depth $entries)
               $head
               $cwd)
             (codex:file-system-sandbox-policy-with-additional-readable-roots
               (CodexFileSystemSandboxPolicy $kind $glob-scan-max-depth $entries)
               $cwd
               $tail)
             (codex:file-system-sandbox-policy-with-additional-readable-roots
               (CodexFileSystemSandboxPolicy
                 $kind
                 $glob-scan-max-depth
                 (list:append
                   $entries
                   ((CodexFileSystemSandboxEntry
                      (CodexFileSystemPathPath (path-normalize $head))
                      (CodexFileSystemAccessModeRead)))))
               $cwd
               $tail)))))

(= (codex:file-system-sandbox-policy-with-additional-writable-roots
      (CodexFileSystemSandboxPolicy $kind $glob-scan-max-depth $entries)
      $cwd
      ())
   (CodexFileSystemSandboxPolicy $kind $glob-scan-max-depth $entries))

(= (codex:file-system-sandbox-policy-with-additional-writable-roots
      (CodexFileSystemSandboxPolicy $kind $glob-scan-max-depth $entries)
      $cwd
      $additional-writable-roots)
   (let ($head $tail) (decons-atom $additional-writable-roots)
     (if (codex:file-system-sandbox-policy-can-write-path-with-cwd
           (CodexFileSystemSandboxPolicy $kind $glob-scan-max-depth $entries)
           $head
           $cwd)
         (codex:file-system-sandbox-policy-with-additional-writable-roots
           (CodexFileSystemSandboxPolicy $kind $glob-scan-max-depth $entries)
           $cwd
           $tail)
         (codex:file-system-sandbox-policy-with-additional-writable-roots
           (CodexFileSystemSandboxPolicy
             $kind
             $glob-scan-max-depth
             (list:append
               $entries
               ((CodexFileSystemSandboxEntry
                  (CodexFileSystemPathPath (path-normalize $head))
                  (CodexFileSystemAccessModeWrite)))))
           $cwd
           $tail))))

; Rust canonicalizes effective absolute paths before deduping readable and
; unreadable root projections. The restart slice uses `realpath -m` to
; preserve the same visible absolute-path behavior across existing ancestors
; while still tolerating missing suffixes.
(= (codex:permissions-normalize-effective-absolute-path $path)
   (let $result
     (process-run-cmd-cwd-env-timeout-cap-bytes
       ("/usr/bin/realpath" "-m" "--" $path)
       (codex:permissions-helper-cwd)
       ()
       (codex:permissions-helper-timeout-ms)
       (codex:permissions-helper-max-bytes))
     (if (== (process-result-exit-code $result) 0)
         (str-trim (process-result-stdout $result))
         (path-normalize $path))))

(= (codex:permissions-string-list-contains $needle ())
   False)

(= (codex:permissions-string-list-contains $needle $items)
   (let ($head $tail) (decons-atom $items)
     (if (== $needle $head)
         True
         (codex:permissions-string-list-contains $needle $tail))))

(= (codex:permissions-dedup-absolute-paths () $normalize-effective-paths)
   ())

(= (codex:permissions-dedup-absolute-paths $paths $normalize-effective-paths)
   (codex:permissions-dedup-absolute-paths-acc
     $paths
     $normalize-effective-paths
     ()))

(= (codex:permissions-dedup-absolute-paths-acc
      ()
      $normalize-effective-paths
      $acc)
   $acc)

(= (codex:permissions-dedup-absolute-paths-acc
      $paths
      $normalize-effective-paths
      $acc)
   (let ($head $tail) (decons-atom $paths)
     (let $dedup-path
       (if $normalize-effective-paths
           (codex:permissions-normalize-effective-absolute-path $head)
           $head)
       (codex:permissions-dedup-absolute-paths-acc
         $tail
         $normalize-effective-paths
         (if (codex:permissions-string-list-contains $dedup-path $acc)
             $acc
             (list:append $acc ($dedup-path)))))))

(= (codex:file-system-sandbox-policy-readable-root-paths
      $policy
      ()
      $cwd)
   ())

(= (codex:file-system-sandbox-policy-readable-root-paths
      $policy
      $resolved-entries
      $cwd)
   (let ($head $tail) (decons-atom $resolved-entries)
     (let $tail-paths
       (codex:file-system-sandbox-policy-readable-root-paths
         $policy
         $tail
         $cwd)
       (if (and
             (codex:file-system-access-mode-can-read
               (codex:resolved-file-system-entry-access $head))
             (codex:file-system-sandbox-policy-can-read-path-with-cwd
               $policy
               (codex:resolved-file-system-entry-path $head)
               $cwd))
           (list:append
             ((codex:resolved-file-system-entry-path $head))
             $tail-paths)
           $tail-paths))))

(= (codex:file-system-sandbox-policy-get-readable-roots-with-cwd
      (CodexFileSystemSandboxPolicy $kind $glob-scan-max-depth $entries)
      $cwd)
   (once
     (if (codex:file-system-sandbox-policy-has-full-disk-read-access
           (CodexFileSystemSandboxPolicy $kind $glob-scan-max-depth $entries))
         ()
         (codex:permissions-dedup-absolute-paths
           (codex:file-system-sandbox-policy-readable-root-paths
             (CodexFileSystemSandboxPolicy $kind $glob-scan-max-depth $entries)
             (codex:file-system-resolved-entries-with-cwd
               (CodexFileSystemSandboxPolicy $kind $glob-scan-max-depth $entries)
               $cwd)
             $cwd)
           True))))

(= (codex:file-system-sandbox-policy-unreadable-root-paths
      $policy
      ()
      $cwd
      $root)
   ())

(= (codex:file-system-sandbox-policy-unreadable-root-paths
      $policy
      $resolved-entries
      $cwd
      $root)
   (let ($head $tail) (decons-atom $resolved-entries)
     (let $tail-paths
       (codex:file-system-sandbox-policy-unreadable-root-paths
         $policy
         $tail
         $cwd
       $root)
       (let $head-path
         (codex:resolved-file-system-entry-path $head)
         (if (and
               (== (codex:resolved-file-system-entry-access $head)
                   (CodexFileSystemAccessModeNone))
               (and
                 (not
                   (codex:file-system-sandbox-policy-can-read-path-with-cwd
                     $policy
                     $head-path
                     $cwd))
                 (not (== $head-path $root))))
             (list:append ($head-path) $tail-paths)
             $tail-paths)))))

(= (codex:file-system-sandbox-policy-get-unreadable-roots-with-cwd
      (CodexFileSystemSandboxPolicy
        (CodexFileSystemSandboxKindUnrestricted)
        $glob-scan-max-depth
        $entries)
      $cwd)
   ())

(= (codex:file-system-sandbox-policy-get-unreadable-roots-with-cwd
      (CodexFileSystemSandboxPolicy
        (CodexFileSystemSandboxKindExternalSandbox)
        $glob-scan-max-depth
        $entries)
      $cwd)
   ())

(= (codex:file-system-sandbox-policy-get-unreadable-roots-with-cwd
      (CodexFileSystemSandboxPolicy
        (CodexFileSystemSandboxKindRestricted)
        $glob-scan-max-depth
        $entries)
      $cwd)
   (once
     (codex:permissions-dedup-absolute-paths
       (codex:file-system-sandbox-policy-unreadable-root-paths
         (CodexFileSystemSandboxPolicy
           (CodexFileSystemSandboxKindRestricted)
           $glob-scan-max-depth
           $entries)
         (codex:file-system-resolved-entries-with-cwd
           (CodexFileSystemSandboxPolicy
             (CodexFileSystemSandboxKindRestricted)
             $glob-scan-max-depth
             $entries)
           $cwd)
         $cwd
         (codex:permissions-absolute-root-path-for-cwd
           (codex:permissions-resolve-base-cwd $cwd)))
       True)))

(= (codex:permissions-resolve-glob-pattern-with-cwd $pattern $cwd)
   (if (path-is-absolute? $pattern)
       (path-normalize $pattern)
       (path-normalize
         (path-join
           (codex:permissions-resolve-base-cwd $cwd)
           $pattern))))

(= (codex:file-system-sandbox-policy-unreadable-glob-patterns () $cwd)
   ())

(= (codex:file-system-sandbox-policy-unreadable-glob-patterns $entries $cwd)
   (let ($head $tail) (decons-atom $entries)
     (let $tail-patterns
       (codex:file-system-sandbox-policy-unreadable-glob-patterns
         $tail
         $cwd)
       (if (and
             (== (codex:file-system-sandbox-entry-access $head)
                 (CodexFileSystemAccessModeNone))
             (== (codex:file-system-path-tag
                   (codex:file-system-sandbox-entry-path $head))
                 "glob_pattern"))
           (list:append
             ((codex:permissions-resolve-glob-pattern-with-cwd
                (codex:file-system-path-glob-pattern-value
                  (codex:file-system-sandbox-entry-path $head))
                $cwd))
             $tail-patterns)
           $tail-patterns))))

(= (codex:permissions-sort-unique-lines ())
   ())

(= (codex:permissions-sort-unique-lines $items)
   (let $result
     (process-run-cmd-cwd-env-timeout-cap-bytes
       ("/bin/sh"
        "-c"
        "printf '%s\n' \"$CODEX_PERMISSION_ITEMS\" | sed '/^$/d' | LC_ALL=C sort -u")
       (codex:permissions-helper-cwd)
       ((Env "CODEX_PERMISSION_ITEMS" (str-join "\n" $items)))
       (codex:permissions-helper-timeout-ms)
       (codex:permissions-helper-max-bytes))
     (if (== (process-result-exit-code $result) 0)
         (let $stdout (str-trim (process-result-stdout $result))
           (if (== $stdout "")
               ()
               (str-split "\n" $stdout)))
         $items)))

(= (codex:file-system-sandbox-policy-get-unreadable-globs-with-cwd
      (CodexFileSystemSandboxPolicy
        (CodexFileSystemSandboxKindRestricted)
        $glob-scan-max-depth
        $entries)
      $cwd)
   (once
     (codex:permissions-sort-unique-lines
       (codex:file-system-sandbox-policy-unreadable-glob-patterns
         $entries
         $cwd))))

(= (codex:file-system-sandbox-policy-get-unreadable-globs-with-cwd
      (CodexFileSystemSandboxPolicy $kind $glob-scan-max-depth $entries)
      $cwd)
   ())
