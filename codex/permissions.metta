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

!(import! &self list)

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
