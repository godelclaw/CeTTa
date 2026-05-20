; Rust-faithful pure config-permissions slice.
;
; This ports deterministic helper behavior from:
; - openai-codex/codex-rs/core/src/config/permissions.rs
; - openai-codex/codex-rs/config/src/permissions_toml.rs
;
; Covered in this increment:
; - FilesystemPermissionsToml / FilesystemPermissionToml data shape
; - resolve_permission_profile / compile_permission_profile
; - network_proxy_config_from_profile_network
; - get_readable_roots_required_for_codex_runtime
; - compile_network_sandbox_policy
; - glob helper behavior used by filesystem profile compilation
; - glob_scan_max_depth validation
; - forward-compatible `:special_path` parsing
;
; Required CeTTa representation notes for audit:
; - Rust receives FilesystemPermissionsToml entries as BTreeMap iteration.
;   This slice receives equivalent constructor entries as ordered lists; the
;   future TOML parser boundary must feed these entries in Rust BTreeMap order.
; - Rust uses std::io::Result. This pure CeTTa slice represents those branches
;   as explicit CodexConfigPermissionsOk/Error values with the same messages.
; - Rust mutates a startup_warnings vector during full profile compilation.
;   This slice exposes warning collectors separately and keeps these pure
;   compile helpers focused on the returned policy entries or error.

!(import! &self list)
!(import! &self network_proxy_loader)
!(import! &self network_proxy_spec)
!(import! &self path)
!(import! &self permissions)
!(import! &self str)

(= (codex:config-permissions-result-ok $value)
   (CodexConfigPermissionsOk $value))

(= (codex:config-permissions-result-error $message)
   (CodexConfigPermissionsError $message))

(= (codex:config-permissions-result-value
      (CodexConfigPermissionsOk $value))
   $value)

(= (codex:config-permissions-result-error-message
      (CodexConfigPermissionsError $message))
   $message)

(= (codex:config-permissions-compiled-profile
      $file-system-policy
      $network-policy
      $startup-warnings)
   (CodexConfigPermissionsCompiledProfile
     $file-system-policy
     $network-policy
     $startup-warnings))

(= (codex:config-permissions-compiled-profile-file-system-policy
      (CodexConfigPermissionsCompiledProfile
        $file-system-policy
        $network-policy
        $startup-warnings))
   $file-system-policy)

(= (codex:config-permissions-compiled-profile-network-policy
      (CodexConfigPermissionsCompiledProfile
        $file-system-policy
        $network-policy
        $startup-warnings))
   $network-policy)

(= (codex:config-permissions-compiled-profile-startup-warnings
      (CodexConfigPermissionsCompiledProfile
        $file-system-policy
        $network-policy
        $startup-warnings))
   $startup-warnings)

(= (codex:filesystem-permissions-toml $glob-scan-max-depth $entries)
   (CodexFilesystemPermissionsToml $glob-scan-max-depth $entries))

(= (codex:filesystem-permissions-toml-glob-scan-max-depth
      (CodexFilesystemPermissionsToml $glob-scan-max-depth $entries))
   $glob-scan-max-depth)

(= (codex:filesystem-permissions-toml-entries
      (CodexFilesystemPermissionsToml $glob-scan-max-depth $entries))
   $entries)

(= (codex:filesystem-permission-toml-entry $path $permission)
   (CodexFilesystemPermissionTomlEntry $path $permission))

(= (codex:filesystem-permission-toml-entry-path
      (CodexFilesystemPermissionTomlEntry $path $permission))
   $path)

(= (codex:filesystem-permission-toml-entry-permission
      (CodexFilesystemPermissionTomlEntry $path $permission))
   $permission)

(= (codex:filesystem-permission-toml-access $access)
   (CodexFilesystemPermissionTomlAccess $access))

(= (codex:filesystem-permission-toml-scoped $entries)
   (CodexFilesystemPermissionTomlScoped $entries))

(= (codex:filesystem-permission-toml-access-mode
      (CodexFilesystemPermissionTomlAccess $access))
   $access)

(= (codex:filesystem-permission-toml-scoped-entries
      (CodexFilesystemPermissionTomlScoped $entries))
   $entries)

(= (codex:filesystem-permission-toml-scoped-entry $subpath $access)
   (CodexFilesystemPermissionTomlScopedEntry $subpath $access))

(= (codex:filesystem-permission-toml-scoped-entry-subpath
      (CodexFilesystemPermissionTomlScopedEntry $subpath $access))
   $subpath)

(= (codex:filesystem-permission-toml-scoped-entry-access
      (CodexFilesystemPermissionTomlScopedEntry $subpath $access))
   $access)

(= (codex:permission-profile-toml-filesystem
      (CodexPermissionProfileToml $filesystem $network))
   $filesystem)

(= (codex:config-permissions-normalize-access-mode
      (CodexFileSystemAccessModeRead))
   (CodexFileSystemAccessModeRead))

(= (codex:config-permissions-normalize-access-mode
      (CodexFileSystemAccessModeWrite))
   (CodexFileSystemAccessModeWrite))

(= (codex:config-permissions-normalize-access-mode
      (CodexFileSystemAccessModeNone))
   (CodexFileSystemAccessModeNone))

(= (codex:config-permissions-normalize-access-mode
      (codex:file-system-access-read))
   (CodexFileSystemAccessModeRead))

(= (codex:config-permissions-normalize-access-mode
      (codex:file-system-access-write))
   (CodexFileSystemAccessModeWrite))

(= (codex:config-permissions-normalize-access-mode
      (codex:file-system-access-none))
   (CodexFileSystemAccessModeNone))

(= (codex:config-permissions-normalize-filesystem-permission
      (CodexFilesystemPermissionTomlAccess $access))
   (CodexFilesystemPermissionTomlAccess
     (codex:config-permissions-normalize-access-mode $access)))

(= (codex:config-permissions-normalize-filesystem-permission
      (CodexFilesystemPermissionTomlScoped $entries))
   (CodexFilesystemPermissionTomlScoped $entries))

(= (codex:config-permissions-normalize-filesystem-permission
      (codex:filesystem-permission-toml-access $access))
   (CodexFilesystemPermissionTomlAccess
     (codex:config-permissions-normalize-access-mode $access)))

(= (codex:config-permissions-normalize-filesystem-permission
      (codex:filesystem-permission-toml-scoped $entries))
   (CodexFilesystemPermissionTomlScoped $entries))

(= (codex:config-permissions-normalize-filesystem-entry
      (CodexFilesystemPermissionTomlEntry $path $permission))
   (CodexFilesystemPermissionTomlEntry
     $path
     (codex:config-permissions-normalize-filesystem-permission
       $permission)))

(= (codex:config-permissions-normalize-filesystem-entry
      (codex:filesystem-permission-toml-entry $path $permission))
   (CodexFilesystemPermissionTomlEntry
     $path
     (codex:config-permissions-normalize-filesystem-permission
       $permission)))

(= (codex:config-permissions-normalize-scoped-entry
      (CodexFilesystemPermissionTomlScopedEntry $subpath $access))
   (CodexFilesystemPermissionTomlScopedEntry
     $subpath
     (codex:config-permissions-normalize-access-mode $access)))

(= (codex:config-permissions-normalize-scoped-entry
      (codex:filesystem-permission-toml-scoped-entry $subpath $access))
   (CodexFilesystemPermissionTomlScopedEntry
     $subpath
     (codex:config-permissions-normalize-access-mode $access)))

(= (codex:config-permissions-normalize-filesystem
      (CodexFilesystemPermissionsToml $glob-scan-max-depth $entries))
   (CodexFilesystemPermissionsToml $glob-scan-max-depth $entries))

(= (codex:config-permissions-normalize-filesystem
      (codex:filesystem-permissions-toml $glob-scan-max-depth $entries))
   (CodexFilesystemPermissionsToml $glob-scan-max-depth $entries))

(= (codex:config-permissions-network-proxy-config-from-profile-network
      $network)
   (if (== $network CodexAbsent)
       (codex:network-proxy-config-default)
       (codex:network-toml-apply-to-network-proxy-config
         $network
         (codex:network-proxy-config-default))))

(= (codex:config-permissions-compile-network-sandbox-policy $network)
   (if (== $network CodexAbsent)
       (codex:network-sandbox-policy-restricted)
       (if (== (codex:network-toml-enabled $network) True)
           (codex:network-sandbox-policy-enabled)
           (codex:network-sandbox-policy-restricted))))

(= (codex:config-permissions-undefined-profile-error $profile-name)
   (str-concat
     "default_permissions refers to undefined profile `"
     (str-concat $profile-name "`")))

(= (codex:config-permissions-resolve-permission-profile-entries
      ()
      $profile-name)
   (codex:config-permissions-result-error
     (codex:config-permissions-undefined-profile-error $profile-name)))

(= (codex:config-permissions-resolve-permission-profile-entries
      $entries
      $profile-name)
   (let ($head $tail) (decons-atom $entries)
     (if (== (codex:permissions-toml-entry-name $head) $profile-name)
         (codex:config-permissions-result-ok
           (codex:permissions-toml-entry-profile $head))
         (codex:config-permissions-resolve-permission-profile-entries
           $tail
           $profile-name))))

(= (codex:config-permissions-resolve-permission-profile
      (CodexPermissionsToml $entries)
      $profile-name)
   (codex:config-permissions-resolve-permission-profile-entries
     $entries
     $profile-name))

(= (codex:config-permissions-runtime-absolute-path-list $path)
   (case $path
     ((CodexAbsent ())
      ($value
       (if (path-is-absolute? $value)
           ((path-normalize $value))
           ())))))

(= (codex:config-permissions-runtime-arg0-root $codex-home)
   (if (path-is-absolute? $codex-home)
       (path-join $codex-home "tmp/arg0")
       CodexAbsent))

(= (codex:config-permissions-runtime-parent-path $path)
   (path-build-from-parts
     (path-drop-last (path-parts $path))
     (path-is-absolute? $path)))

(= (codex:config-permissions-runtime-execve-wrapper-root
      $codex-home
      $main-execve-wrapper-exe)
   (case $main-execve-wrapper-exe
     ((CodexAbsent ())
      ($path
       (if (path-is-absolute? $path)
           (let $absolute-path (eval (path-normalize $path))
             (let $arg0-root
               (eval
                 (codex:config-permissions-runtime-arg0-root $codex-home))
               (if (and
                     (not (== $arg0-root CodexAbsent))
                     (codex:permissions-path-starts-with-path
                       $absolute-path
                       $arg0-root))
                   ((codex:config-permissions-runtime-parent-path
                      $absolute-path))
                   ($absolute-path))))
           ())))))

(= (codex:config-permissions-readable-roots-required-for-codex-runtime
      $codex-home
      $zsh-path
      $main-execve-wrapper-exe)
   (let $zsh-roots
     (eval
       (codex:config-permissions-runtime-absolute-path-list $zsh-path))
     (let $execve-wrapper-roots
       (eval
         (codex:config-permissions-runtime-execve-wrapper-root
           $codex-home
           $main-execve-wrapper-exe))
       (list:append $zsh-roots $execve-wrapper-roots))))

(= (codex:config-permissions-append-result-list
      $items-result
      $tail-result)
   (case $items-result
     (((CodexConfigPermissionsError $message)
       (codex:config-permissions-result-error $message))
      ((CodexConfigPermissionsOk $items)
       (case $tail-result
         (((CodexConfigPermissionsError $message)
           (codex:config-permissions-result-error $message))
          ((CodexConfigPermissionsOk $tail-items)
           (codex:config-permissions-result-ok
             (list:append $items $tail-items)))))))))

(= (codex:config-permissions-file-system-access-mode-display
      (CodexFileSystemAccessModeRead))
   "read")

(= (codex:config-permissions-file-system-access-mode-display
      (CodexFileSystemAccessModeWrite))
   "write")

(= (codex:config-permissions-file-system-access-mode-display
      (CodexFileSystemAccessModeNone))
   "none")

(= (codex:config-permissions-is-glob-char $char)
   (case $char
     (("*" True)
      ("?" True)
      ("[" True)
      ("]" True)
      ($other False))))

(= (codex:config-permissions-has-glob-chars-at $text $index)
   (if (>= $index (str-length $text))
       False
       (if (codex:config-permissions-is-glob-char
             (str-slice $text $index (+ $index 1)))
           True
           (codex:config-permissions-has-glob-chars-at
             $text
             (+ $index 1)))))

(= (codex:config-permissions-has-glob-chars $path)
   (codex:config-permissions-has-glob-chars-at $path 0))

(= (codex:config-permissions-remove-trailing-glob-suffix $path)
   (if (str-ends-with? $path "/**")
       (str-slice $path 0 (- (str-length $path) 3))
       $path))

(= (codex:config-permissions-text-contains $text $needle)
   (not (== (str-find $text $needle) Empty)))

(= (codex:config-permissions-compile-read-write-glob-error
      $path
      $access)
   (str-concat
     "filesystem glob path `"
     (str-concat
       $path
       (str-concat
         "` only supports `none` access; use an exact path or trailing `/**` for `"
         (str-concat
           (codex:config-permissions-file-system-access-mode-display $access)
           "` subtree access")))))

(= (codex:config-permissions-compile-read-write-glob-path
      $path
      $access)
   (if (not (codex:config-permissions-has-glob-chars $path))
       (codex:config-permissions-result-ok $path)
       (let $path-without-trailing-glob
         (codex:config-permissions-remove-trailing-glob-suffix $path)
         (if (not
               (codex:config-permissions-has-glob-chars
                 $path-without-trailing-glob))
             (codex:config-permissions-result-ok
               $path-without-trailing-glob)
             (codex:config-permissions-result-error
               (codex:config-permissions-compile-read-write-glob-error
                 $path
                 $access))))))

(= (codex:config-permissions-unsupported-read-write-glob-paths
      (CodexFilesystemPermissionsToml $glob-scan-max-depth $entries))
   (codex:config-permissions-unsupported-read-write-glob-paths-entries
     $entries))

(= (codex:config-permissions-unsupported-read-write-glob-paths
      (codex:filesystem-permissions-toml $glob-scan-max-depth $entries))
   (codex:config-permissions-unsupported-read-write-glob-paths-entries
     $entries))

(= (codex:config-permissions-unsupported-read-write-glob-paths-entries
      ())
   ())

(= (codex:config-permissions-unsupported-read-write-glob-paths-entries
      $entries)
   (let ($raw-head $tail) (decons-atom $entries)
     (let $head
       (codex:config-permissions-normalize-filesystem-entry
         $raw-head)
     (let $rest
       (codex:config-permissions-unsupported-read-write-glob-paths-entries
         $tail)
       (let $path (codex:filesystem-permission-toml-entry-path $head)
         (let $permission
           (eval
             (codex:filesystem-permission-toml-entry-permission $head))
           (case $permission
             (((CodexFilesystemPermissionTomlAccess $access)
               (if (and
                     (not (== $access (CodexFileSystemAccessModeNone)))
                     (codex:config-permissions-has-glob-chars
                       (codex:config-permissions-remove-trailing-glob-suffix
                         $path)))
                   (cons-atom $path $rest)
                   $rest))
              ((CodexFilesystemPermissionTomlScoped $scoped-entries)
               (list:append
                 (codex:config-permissions-unsupported-read-write-glob-paths-scoped
                   $path
                   $scoped-entries)
                 $rest))))))))))

(= (codex:config-permissions-unsupported-read-write-glob-paths-scoped
      $path
      ())
   ())

(= (codex:config-permissions-unsupported-read-write-glob-paths-scoped
      $path
      $scoped-entries)
   (let ($raw-head $tail) (decons-atom $scoped-entries)
     (let $head
       (codex:config-permissions-normalize-scoped-entry
         $raw-head)
     (let $rest
       (codex:config-permissions-unsupported-read-write-glob-paths-scoped
         $path
         $tail)
       (let $subpath
         (codex:filesystem-permission-toml-scoped-entry-subpath $head)
         (let $access
           (eval
             (codex:filesystem-permission-toml-scoped-entry-access $head))
           (if (and
                 (not (== $access (CodexFileSystemAccessModeNone)))
                 (codex:config-permissions-has-glob-chars
                   (codex:config-permissions-remove-trailing-glob-suffix
                     $subpath)))
               (let $joined
                 (eval (str-concat $path (str-concat "/" $subpath)))
                 (cons-atom $joined $rest))
               $rest)))))))

(= (codex:config-permissions-unbounded-unreadable-globstar-paths
      (CodexFilesystemPermissionsToml $glob-scan-max-depth $entries))
   (if (== $glob-scan-max-depth CodexAbsent)
       (codex:config-permissions-unbounded-unreadable-globstar-paths-entries
         $entries)
       ()))

(= (codex:config-permissions-unbounded-unreadable-globstar-paths
      (codex:filesystem-permissions-toml $glob-scan-max-depth $entries))
   (if (== $glob-scan-max-depth CodexAbsent)
       (codex:config-permissions-unbounded-unreadable-globstar-paths-entries
         $entries)
       ()))

(= (codex:config-permissions-unbounded-unreadable-globstar-paths-entries
      ())
   ())

(= (codex:config-permissions-unbounded-unreadable-globstar-paths-entries
      $entries)
   (let ($raw-head $tail) (decons-atom $entries)
     (let $head
       (codex:config-permissions-normalize-filesystem-entry
         $raw-head)
     (let $rest
       (codex:config-permissions-unbounded-unreadable-globstar-paths-entries
         $tail)
       (let $path (codex:filesystem-permission-toml-entry-path $head)
         (let $permission
           (eval
             (codex:filesystem-permission-toml-entry-permission $head))
           (case $permission
             (((CodexFilesystemPermissionTomlAccess
                 (CodexFileSystemAccessModeNone))
               (if (codex:config-permissions-text-contains $path "**")
                   (cons-atom $path $rest)
                   $rest))
              ((CodexFilesystemPermissionTomlAccess $access)
               $rest)
              ((CodexFilesystemPermissionTomlScoped $scoped-entries)
               (list:append
                 (codex:config-permissions-unbounded-unreadable-globstar-paths-scoped
                   $path
                   $scoped-entries)
                 $rest))))))))))

(= (codex:config-permissions-unbounded-unreadable-globstar-paths-scoped
      $path
      ())
   ())

(= (codex:config-permissions-unbounded-unreadable-globstar-paths-scoped
      $path
      $scoped-entries)
   (let ($raw-head $tail) (decons-atom $scoped-entries)
     (let $head
       (codex:config-permissions-normalize-scoped-entry
         $raw-head)
     (let $rest
       (codex:config-permissions-unbounded-unreadable-globstar-paths-scoped
         $path
         $tail)
       (let $subpath
         (codex:filesystem-permission-toml-scoped-entry-subpath $head)
         (let $access
           (eval
             (codex:filesystem-permission-toml-scoped-entry-access $head))
           (if (and
                 (== $access (CodexFileSystemAccessModeNone))
                 (codex:config-permissions-text-contains $subpath "**"))
               (let $joined
                 (eval (str-concat $path (str-concat "/" $subpath)))
                 (cons-atom $joined $rest))
               $rest)))))))

(= (codex:config-permissions-validate-glob-scan-max-depth $max-depth)
   (if (== $max-depth 0)
       (codex:config-permissions-result-error
         "glob_scan_max_depth must be at least 1")
       (codex:config-permissions-result-ok $max-depth)))

(= (codex:config-permissions-absolute-path-error $path)
   (str-concat
     "filesystem path `"
     (str-concat
       $path
       "` must be absolute, use `~/...`, or start with `:`")))

(= (codex:config-permissions-is-ascii-alpha $char)
   (case $char
     (("A" True)
      ("B" True)
      ("C" True)
      ("D" True)
      ("E" True)
      ("F" True)
      ("G" True)
      ("H" True)
      ("I" True)
      ("J" True)
      ("K" True)
      ("L" True)
      ("M" True)
      ("N" True)
      ("O" True)
      ("P" True)
      ("Q" True)
      ("R" True)
      ("S" True)
      ("T" True)
      ("U" True)
      ("V" True)
      ("W" True)
      ("X" True)
      ("Y" True)
      ("Z" True)
      ("a" True)
      ("b" True)
      ("c" True)
      ("d" True)
      ("e" True)
      ("f" True)
      ("g" True)
      ("h" True)
      ("i" True)
      ("j" True)
      ("k" True)
      ("l" True)
      ("m" True)
      ("n" True)
      ("o" True)
      ("p" True)
      ("q" True)
      ("r" True)
      ("s" True)
      ("t" True)
      ("u" True)
      ("v" True)
      ("w" True)
      ("x" True)
      ("y" True)
      ("z" True)
      ($other False))))

(= (codex:config-permissions-windows-drive-absolute-path $path)
   (if (< (str-length $path) 3)
       False
       (and
         (codex:config-permissions-is-ascii-alpha
           (str-slice $path 0 1))
         (and
           (== (str-slice $path 1 2) ":")
           (or
             (== (str-slice $path 2 3) "\\")
             (== (str-slice $path 2 3) "/"))))))

(= (codex:config-permissions-windows-absolute-path $path)
   (or
     (codex:config-permissions-windows-drive-absolute-path $path)
     (str-starts-with? $path "\\\\")))

(= (codex:config-permissions-normalize-windows-device-path
      $path)
   (if (str-starts-with? $path "\\\\?\\UNC\\")
       (str-concat
         "\\\\"
         (str-slice $path 8 (str-length $path)))
       (if (str-starts-with? $path "\\\\.\\UNC\\")
           (str-concat
             "\\\\"
             (str-slice $path 8 (str-length $path)))
           (if (str-starts-with? $path "\\\\?\\")
               (let $without-prefix
                 (eval (str-slice $path 4 (str-length $path)))
                 (if (codex:config-permissions-windows-drive-absolute-path
                       $without-prefix)
                     $without-prefix
                     CodexAbsent))
               (if (str-starts-with? $path "\\\\.\\")
                   (let $without-prefix
                     (eval (str-slice $path 4 (str-length $path)))
                     (if (codex:config-permissions-windows-drive-absolute-path
                           $without-prefix)
                         $without-prefix
                         CodexAbsent))
                   CodexAbsent)))))

(= (codex:config-permissions-normalize-absolute-path-for-platform
      $path
      $is-windows)
   (if $is-windows
       (let $normalized
         (codex:config-permissions-normalize-windows-device-path $path)
         (if (== $normalized CodexAbsent)
             $path
             $normalized))
       $path))

(= (codex:config-permissions-is-absolute-path-for-platform
      $path
      $normalized-path
      $is-windows)
   (if $is-windows
       (or
         (codex:config-permissions-windows-absolute-path $path)
         (codex:config-permissions-windows-absolute-path
           $normalized-path))
       (path-is-absolute? $normalized-path)))

(= (codex:config-permissions-parse-absolute-path-for-platform
      $path
      $is-windows)
   (let $normalized-path
     (eval
       (codex:config-permissions-normalize-absolute-path-for-platform
         $path
         $is-windows))
     (if (and
           (not
             (codex:config-permissions-is-absolute-path-for-platform
               $path
               $normalized-path
               $is-windows))
           (and
             (not (== $path "~"))
             (not (str-starts-with? $path "~/"))))
         (codex:config-permissions-result-error
           (codex:config-permissions-absolute-path-error $path))
         (codex:config-permissions-result-ok
           (if $is-windows
               $normalized-path
               (path-normalize $normalized-path))))))

(= (codex:config-permissions-parse-absolute-path $path)
   (codex:config-permissions-parse-absolute-path-for-platform
     $path
     False))

(= (codex:config-permissions-valid-relative-subpath-parts ())
   True)

(= (codex:config-permissions-valid-relative-subpath-parts $parts)
   (let ($head $tail) (decons-atom $parts)
     (if (or
           (== $head "")
           (or (== $head ".") (== $head "..")))
         False
         (codex:config-permissions-valid-relative-subpath-parts $tail))))

(= (codex:config-permissions-relative-subpath-error $subpath)
   (str-concat
     "filesystem subpath `"
     (str-concat
       $subpath
       "` must be a descendant path without `.` or `..` components")))

(= (codex:config-permissions-parse-relative-subpath $subpath)
   (let $parts (eval (str-split "/" $subpath))
     (if (== $subpath "")
         (codex:config-permissions-result-error
           (codex:config-permissions-relative-subpath-error $subpath))
         (case
           (codex:config-permissions-valid-relative-subpath-parts $parts)
           ((True
             (codex:config-permissions-result-ok $subpath))
            (False
             (codex:config-permissions-result-error
               (codex:config-permissions-relative-subpath-error
                 $subpath))))))))

(= (codex:config-permissions-parse-special-path $path)
   (case $path
     ((":root" (codex:file-system-special-path-root))
      (":minimal" (codex:file-system-special-path-minimal))
      (":project_roots"
       (codex:file-system-special-path-project-roots CodexAbsent))
      (":tmpdir" (codex:file-system-special-path-tmpdir))
      ($other
       (if (str-starts-with? $path ":")
           (codex:file-system-special-path-unknown $path CodexAbsent)
           CodexAbsent)))))

(= (codex:config-permissions-nested-path-error $path)
   (str-concat
     "filesystem path `"
     (str-concat $path "` does not support nested entries")))

(= (codex:config-permissions-compile-filesystem-path $path)
   (let $special (codex:config-permissions-parse-special-path $path)
     (if (== $special CodexAbsent)
         (case (codex:config-permissions-parse-absolute-path $path)
           (((CodexConfigPermissionsOk $absolute-path)
             (codex:config-permissions-result-ok
               (codex:file-system-path-path $absolute-path)))
            ((CodexConfigPermissionsError $message)
             (codex:config-permissions-result-error $message))))
         (codex:config-permissions-result-ok
           (codex:file-system-path-special $special)))))

(= (codex:config-permissions-special-path-supports-scoped-pattern
      $special)
   (case $special
     (((CodexFileSystemSpecialPathProjectRoots $subpath) True)
      ($other False))))

(= (codex:config-permissions-special-path-supports-nested-entry
      $special)
   (case $special
     (((CodexFileSystemSpecialPathProjectRoots $subpath) True)
      ((CodexFileSystemSpecialPathUnknown $path $subpath) True)
      ($other False))))

(= (codex:config-permissions-compile-filesystem-access-path
      $path
      $access)
   (if (not (codex:config-permissions-has-glob-chars $path))
       (codex:config-permissions-compile-filesystem-path $path)
       (if (== $access (CodexFileSystemAccessModeNone))
           (case (codex:config-permissions-parse-absolute-path $path)
             (((CodexConfigPermissionsOk $absolute-path)
               (codex:config-permissions-result-ok
                 (codex:file-system-path-glob-pattern $absolute-path)))
              ((CodexConfigPermissionsError $message)
               (codex:config-permissions-result-error $message))))
           (case
             (codex:config-permissions-compile-read-write-glob-path
               $path
               $access)
             (((CodexConfigPermissionsOk $compiled-path)
               (codex:config-permissions-compile-filesystem-path
                 $compiled-path))
              ((CodexConfigPermissionsError $message)
               (codex:config-permissions-result-error $message)))))))

(= (codex:config-permissions-compile-scoped-filesystem-path
      $path
      $subpath)
   (if (== $subpath ".")
       (codex:config-permissions-compile-filesystem-path $path)
       (let $special (codex:config-permissions-parse-special-path $path)
         (if (== $special CodexAbsent)
             (case (codex:config-permissions-parse-relative-subpath $subpath)
               (((CodexConfigPermissionsOk $relative-subpath)
                 (case (codex:config-permissions-parse-absolute-path $path)
                   (((CodexConfigPermissionsOk $base)
                     (codex:config-permissions-result-ok
                       (codex:file-system-path-path
                         (path-join $base $relative-subpath))))
                    ((CodexConfigPermissionsError $message)
                     (codex:config-permissions-result-error $message)))))
                ((CodexConfigPermissionsError $message)
                 (codex:config-permissions-result-error $message))))
             (if (codex:config-permissions-special-path-supports-nested-entry
                   $special)
                 (case (codex:config-permissions-parse-relative-subpath $subpath)
                   (((CodexConfigPermissionsOk $relative-subpath)
                     (case $special
                       (((CodexFileSystemSpecialPathProjectRoots $old-subpath)
                         (codex:config-permissions-result-ok
                           (codex:file-system-path-special
                             (codex:file-system-special-path-project-roots
                               $relative-subpath))))
                        ((CodexFileSystemSpecialPathUnknown $unknown-path $old-subpath)
                         (codex:config-permissions-result-ok
                           (codex:file-system-path-special
                             (codex:file-system-special-path-unknown
                               $unknown-path
                               $relative-subpath)))))))
                    ((CodexConfigPermissionsError $message)
                     (codex:config-permissions-result-error $message))))
                 (codex:config-permissions-result-error
                   (codex:config-permissions-nested-path-error $path)))))))

(= (codex:config-permissions-compile-scoped-filesystem-pattern
      $path
      $subpath
      $access
      $policy-cwd)
   (if (not (== $access (CodexFileSystemAccessModeNone)))
       (codex:config-permissions-result-error
         (str-concat
           "filesystem glob subpath `"
           (str-concat
             $subpath
             "` only supports `none` access")))
       (case (codex:config-permissions-parse-relative-subpath $subpath)
         (((CodexConfigPermissionsOk $relative-subpath)
           (let $special (codex:config-permissions-parse-special-path $path)
             (if (== $special CodexAbsent)
                 (case (codex:config-permissions-parse-absolute-path $path)
                   (((CodexConfigPermissionsOk $base)
                     (codex:config-permissions-result-ok
                       (path-join $base $relative-subpath)))
                    ((CodexConfigPermissionsError $message)
                     (codex:config-permissions-result-error $message))))
                 (if (codex:config-permissions-special-path-supports-scoped-pattern
                       $special)
                     (codex:config-permissions-result-ok
                       (path-join $policy-cwd $relative-subpath))
                     (codex:config-permissions-result-error
                       (codex:config-permissions-nested-path-error $path))))))
          ((CodexConfigPermissionsError $message)
           (codex:config-permissions-result-error $message))))))

(= (codex:config-permissions-compile-filesystem-permission
      $path
      (CodexFilesystemPermissionTomlAccess $access)
      $policy-cwd)
   (case
     (codex:config-permissions-compile-filesystem-access-path
       $path
       $access)
     (((CodexConfigPermissionsOk $compiled-path)
       (codex:config-permissions-result-ok
         ((codex:file-system-sandbox-entry $compiled-path $access))))
      ((CodexConfigPermissionsError $message)
       (codex:config-permissions-result-error $message)))))

(= (codex:config-permissions-compile-filesystem-permission
      $path
      (CodexFilesystemPermissionTomlScoped $scoped-entries)
      $policy-cwd)
   (codex:config-permissions-compile-filesystem-scoped-entries
     $path
     $scoped-entries
     $policy-cwd))

(= (codex:config-permissions-compile-filesystem-scoped-entries
      $path
      ()
      $policy-cwd)
   (codex:config-permissions-result-ok ()))

(= (codex:config-permissions-compile-filesystem-scoped-entries
      $path
      $scoped-entries
      $policy-cwd)
   (let ($raw-head $tail) (decons-atom $scoped-entries)
     (let $head
       (codex:config-permissions-normalize-scoped-entry
         $raw-head)
       (let $subpath
         (codex:filesystem-permission-toml-scoped-entry-subpath $head)
         (let $access
           (eval
             (codex:filesystem-permission-toml-scoped-entry-access $head))
           (let $special (codex:config-permissions-parse-special-path $path)
             (let $has-glob
               (codex:config-permissions-has-glob-chars $subpath)
               (let $can-compile-as-pattern
                 (if (== $special CodexAbsent)
                     True
                     (codex:config-permissions-special-path-supports-scoped-pattern
                       $special))
                 (let $head-result
                   (if (and
                         $has-glob
                         (and
                           (== $access (CodexFileSystemAccessModeNone))
                           $can-compile-as-pattern))
                       (case
                         (codex:config-permissions-compile-scoped-filesystem-pattern
                           $path
                           $subpath
                           $access
                           $policy-cwd)
                         (((CodexConfigPermissionsOk $pattern)
                           (codex:config-permissions-result-ok
                             ((codex:file-system-sandbox-entry
                                (codex:file-system-path-glob-pattern $pattern)
                                $access))))
                          ((CodexConfigPermissionsError $message)
                           (codex:config-permissions-result-error $message))))
                       (case
                         (codex:config-permissions-compile-read-write-glob-path
                           $subpath
                           $access)
                         (((CodexConfigPermissionsOk $compiled-subpath)
                           (case
                             (codex:config-permissions-compile-scoped-filesystem-path
                               $path
                               $compiled-subpath)
                             (((CodexConfigPermissionsOk $compiled-path)
                               (codex:config-permissions-result-ok
                                 ((codex:file-system-sandbox-entry
                                    $compiled-path
                                    $access))))
                              ((CodexConfigPermissionsError $message)
                               (codex:config-permissions-result-error
                                 $message)))))
                          ((CodexConfigPermissionsError $message)
                           (codex:config-permissions-result-error $message)))))
                   (codex:config-permissions-append-result-list
                     $head-result
                     (codex:config-permissions-compile-filesystem-scoped-entries
                       $path
                       $tail
                       $policy-cwd)))))))))))

(= (codex:config-permissions-compile-filesystem-permission-entry
      $entry
      $policy-cwd)
   (codex:config-permissions-compile-filesystem-permission
     (codex:filesystem-permission-toml-entry-path $entry)
     (eval (codex:filesystem-permission-toml-entry-permission $entry))
     $policy-cwd))

(= (codex:config-permissions-compile-filesystem-permission-entries
      ()
      $policy-cwd)
   (codex:config-permissions-result-ok ()))

(= (codex:config-permissions-compile-filesystem-permission-entries
      $entries
      $policy-cwd)
   (let ($raw-head $tail) (decons-atom $entries)
     (let $head
       (codex:config-permissions-normalize-filesystem-entry
         $raw-head)
       (codex:config-permissions-append-result-list
         (codex:config-permissions-compile-filesystem-permission-entry
           $head
           $policy-cwd)
         (codex:config-permissions-compile-filesystem-permission-entries
           $tail
           $policy-cwd)))))

(= (codex:config-permissions-compile-filesystem-permissions
      (CodexFilesystemPermissionsToml $glob-scan-max-depth $entries)
      $policy-cwd)
   (codex:config-permissions-compile-filesystem-permissions-normalized
     $glob-scan-max-depth
     $entries
     $policy-cwd))

(= (codex:config-permissions-compile-filesystem-permissions
      (codex:filesystem-permissions-toml $glob-scan-max-depth $entries)
      $policy-cwd)
   (codex:config-permissions-compile-filesystem-permissions-normalized
     $glob-scan-max-depth
     $entries
     $policy-cwd))

(= (codex:config-permissions-compile-filesystem-permissions-normalized
      $glob-scan-max-depth
      $entries
      $policy-cwd)
   (case
     (codex:config-permissions-compile-filesystem-permission-entries
       $entries
       $policy-cwd)
     (((CodexConfigPermissionsError $message)
       (codex:config-permissions-result-error $message))
      ((CodexConfigPermissionsOk $compiled-entries)
       (case
         (codex:config-permissions-validate-glob-scan-max-depth
           $glob-scan-max-depth)
         (((CodexConfigPermissionsOk $valid-depth)
           (codex:config-permissions-result-ok
             (codex:file-system-sandbox-policy
               (codex:file-system-sandbox-kind-restricted)
               $valid-depth
               $compiled-entries)))
          ((CodexConfigPermissionsError $message)
           (codex:config-permissions-result-error $message))))))))

(= (codex:config-permissions-missing-filesystem-entries-warning
      $profile-name)
   (str-concat
     "Permissions profile `"
     (str-concat
       $profile-name
       "` does not define any recognized filesystem entries for this version of Codex. Filesystem access will remain restricted. Upgrade Codex if this profile expects filesystem permissions.")))

(= (codex:config-permissions-unsupported-read-write-glob-warning
      $pattern)
   (str-concat
     "Filesystem glob `"
     (str-concat
       $pattern
       "` uses `read` or `write` access, which is not fully supported by this platform's sandboxing. Use an exact path or trailing `/**` subtree rule instead. `none` deny-read globs are supported.")))

(= (codex:config-permissions-unbounded-unreadable-globstar-warning
      $pattern)
   (str-concat
     "Filesystem deny-read glob `"
     (str-concat
       $pattern
       "` uses `**`. Non-macOS sandboxing does not support unbounded `**` natively; set `glob_scan_max_depth` in this filesystem profile to cap Linux glob expansion and silence this warning, or enumerate explicit depths such as `*.env`, `*/*.env`, and `*/*/*.env`.")))

(= (codex:config-permissions-unknown-special-path-warning
      (CodexFileSystemSpecialPathUnknown $path $subpath))
   (if (== $subpath CodexAbsent)
       (str-concat
         "Configured filesystem path `"
         (str-concat
           $path
           "` is not recognized by this version of Codex and will be ignored. Upgrade Codex if this path is required."))
       (str-concat
         "Configured filesystem path `"
         (str-concat
           $path
           (str-concat
             "` with nested entry `"
             (str-concat
               $subpath
               "` is not recognized by this version of Codex and will be ignored. Upgrade Codex if this path is required."))))))

(= (codex:config-permissions-maybe-unknown-special-path-warning-list
      $special)
   (case $special
     (((CodexFileSystemSpecialPathUnknown $path $subpath)
       ((codex:config-permissions-unknown-special-path-warning
          (CodexFileSystemSpecialPathUnknown $path $subpath))))
      ($other ()))))

(= (codex:config-permissions-warning-list-from-unsupported-paths
      ())
   ())

(= (codex:config-permissions-warning-list-from-unsupported-paths
      $paths)
   (let ($head $tail) (decons-atom $paths)
     (let $warning
       (codex:config-permissions-unsupported-read-write-glob-warning
         $head)
       (let $tail-warnings
         (codex:config-permissions-warning-list-from-unsupported-paths
           $tail)
         (cons-atom $warning $tail-warnings)))))

(= (codex:config-permissions-warning-list-from-unbounded-paths
      ())
   ())

(= (codex:config-permissions-warning-list-from-unbounded-paths
      $paths)
   (let ($head $tail) (decons-atom $paths)
     (let $warning
       (codex:config-permissions-unbounded-unreadable-globstar-warning
         $head)
       (let $tail-warnings
         (codex:config-permissions-warning-list-from-unbounded-paths
           $tail)
         (cons-atom $warning $tail-warnings)))))

(= (codex:config-permissions-compiled-filesystem-path-warnings
      $path)
   (let $special (codex:config-permissions-parse-special-path $path)
     (if (== $special CodexAbsent)
         ()
         (codex:config-permissions-maybe-unknown-special-path-warning-list
           $special))))

(= (codex:config-permissions-access-entry-unknown-special-warnings
      $path
      $access)
   (if (not (codex:config-permissions-has-glob-chars $path))
       (codex:config-permissions-compiled-filesystem-path-warnings
         $path)
       (if (== $access (CodexFileSystemAccessModeNone))
           ()
           (case
             (codex:config-permissions-compile-read-write-glob-path
               $path
               $access)
             (((CodexConfigPermissionsOk $compiled-path)
               (codex:config-permissions-compiled-filesystem-path-warnings
                 $compiled-path))
              ((CodexConfigPermissionsError $message)
               ()))))))

(= (codex:config-permissions-scoped-entry-unknown-special-warnings
      $path
      $subpath
      $access)
   (let $special (codex:config-permissions-parse-special-path $path)
     (let $has-glob
       (codex:config-permissions-has-glob-chars $subpath)
       (let $can-compile-as-pattern
         (if (== $special CodexAbsent)
             True
             (codex:config-permissions-special-path-supports-scoped-pattern
               $special))
         (if (and
               $has-glob
               (and
                 (== $access (CodexFileSystemAccessModeNone))
                 $can-compile-as-pattern))
             ()
             (case
               (codex:config-permissions-compile-read-write-glob-path
                 $subpath
                 $access)
               (((CodexConfigPermissionsOk $compiled-subpath)
                 (if (== $compiled-subpath ".")
                     (codex:config-permissions-compiled-filesystem-path-warnings
                       $path)
                     (case $special
                       (((CodexFileSystemSpecialPathUnknown
                           $unknown-path
                           $old-subpath)
                         (case
                           (codex:config-permissions-parse-relative-subpath
                             $compiled-subpath)
                           (((CodexConfigPermissionsOk $relative-subpath)
                             ((codex:config-permissions-unknown-special-path-warning
                                (CodexFileSystemSpecialPathUnknown
                                  $unknown-path
                                  $relative-subpath))))
                            ((CodexConfigPermissionsError $message)
                             ())))
                        ($other ())))))
                ((CodexConfigPermissionsError $message)
                 ())))))))))

(= (codex:config-permissions-scoped-unknown-special-warnings
      $path
      ())
   ())

(= (codex:config-permissions-scoped-unknown-special-warnings
      $path
      $scoped-entries)
   (let ($raw-head $tail) (decons-atom $scoped-entries)
     (let $head
       (codex:config-permissions-normalize-scoped-entry
         $raw-head)
       (let $subpath
         (codex:filesystem-permission-toml-scoped-entry-subpath $head)
         (let $access
           (eval
             (codex:filesystem-permission-toml-scoped-entry-access $head))
           (list:append
             (codex:config-permissions-scoped-entry-unknown-special-warnings
               $path
               $subpath
               $access)
             (codex:config-permissions-scoped-unknown-special-warnings
               $path
               $tail)))))))

(= (codex:config-permissions-filesystem-unknown-special-warnings
      ())
   ())

(= (codex:config-permissions-filesystem-unknown-special-warnings
      $entries)
   (let ($raw-head $tail) (decons-atom $entries)
     (let $head
       (codex:config-permissions-normalize-filesystem-entry
         $raw-head)
       (let $path (codex:filesystem-permission-toml-entry-path $head)
         (let $permission
           (eval
             (codex:filesystem-permission-toml-entry-permission $head))
           (list:append
             (case $permission
               (((CodexFilesystemPermissionTomlAccess $access)
                 (codex:config-permissions-access-entry-unknown-special-warnings
                   $path
                   $access))
                ((CodexFilesystemPermissionTomlScoped $scoped-entries)
                 (codex:config-permissions-scoped-unknown-special-warnings
                   $path
                   $scoped-entries))))
             (codex:config-permissions-filesystem-unknown-special-warnings
               $tail)))))))

(= (codex:config-permissions-filesystem-startup-warnings
      $profile-name
      CodexAbsent)
   ((codex:config-permissions-missing-filesystem-entries-warning
      $profile-name)))

(= (codex:config-permissions-filesystem-startup-warnings
      $profile-name
      $filesystem)
   (let $normalized-filesystem
     (codex:config-permissions-normalize-filesystem $filesystem)
     (let $entries
       (codex:filesystem-permissions-toml-entries
         $normalized-filesystem)
       (if (== $entries ())
           ((codex:config-permissions-missing-filesystem-entries-warning
              $profile-name))
           (list:append
             (codex:config-permissions-warning-list-from-unsupported-paths
               (codex:config-permissions-unsupported-read-write-glob-paths
                 $normalized-filesystem))
             (list:append
               (codex:config-permissions-warning-list-from-unbounded-paths
                 (codex:config-permissions-unbounded-unreadable-globstar-paths
                   $normalized-filesystem))
               (codex:config-permissions-filesystem-unknown-special-warnings
                 $entries)))))))

(= (codex:config-permissions-permission-profile-startup-warnings
      $profile-name
      $profile)
   (codex:config-permissions-filesystem-startup-warnings
     $profile-name
     (codex:permission-profile-toml-filesystem $profile)))

(= (codex:config-permissions-profile-filesystem-or-empty
      CodexAbsent)
   (CodexFilesystemPermissionsToml CodexAbsent ()))

(= (codex:config-permissions-profile-filesystem-or-empty
      $filesystem)
   (codex:config-permissions-normalize-filesystem $filesystem))

(= (codex:config-permissions-compile-permission-profile-resolved
      $profile-name
      $profile
      $policy-cwd)
   (let $startup-warnings
     (eval
       (codex:config-permissions-permission-profile-startup-warnings
         $profile-name
         $profile))
     (let $filesystem
       (eval
         (codex:config-permissions-profile-filesystem-or-empty
           (codex:permission-profile-toml-filesystem $profile)))
       (case
         (codex:config-permissions-compile-filesystem-permissions
           $filesystem
           $policy-cwd)
         (((CodexConfigPermissionsOk $file-system-policy)
           (codex:config-permissions-result-ok
             (codex:config-permissions-compiled-profile
               $file-system-policy
               (codex:config-permissions-compile-network-sandbox-policy
                 (codex:permission-profile-toml-network $profile))
               $startup-warnings)))
          ((CodexConfigPermissionsError $message)
           (codex:config-permissions-result-error $message)))))))

(= (codex:config-permissions-compile-permission-profile
      $permissions
      $profile-name
      $policy-cwd)
   (case
     (codex:config-permissions-resolve-permission-profile
       $permissions
       $profile-name)
     (((CodexConfigPermissionsOk $profile)
       (codex:config-permissions-compile-permission-profile-resolved
         $profile-name
         $profile
         $policy-cwd))
      ((CodexConfigPermissionsError $message)
       (codex:config-permissions-result-error $message)))))
