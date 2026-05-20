!(register-module! ../codex)
!(import! &self codex:config_permissions)
!(import! &self codex:network_proxy_loader)
!(import! &self codex:network_proxy_spec)
!(import! &self codex:permissions)
!(import! &self path)

(= (network-with-enabled $enabled)
   (codex:network-toml
     $enabled
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     (codex:network-mode-full)
     CodexAbsent
     CodexAbsent
     CodexAbsent))

!(assertEqual
  (codex:network-proxy-config-enabled
    (codex:config-permissions-network-proxy-config-from-profile-network
      (network-with-enabled True)))
  True)

!(assertEqual
  (codex:network-proxy-config-mode
    (codex:config-permissions-network-proxy-config-from-profile-network
      (network-with-enabled True)))
  (codex:network-mode-full))

!(assertEqual
  (codex:config-permissions-compile-network-sandbox-policy
    (network-with-enabled True))
  (codex:network-sandbox-policy-enabled))

!(assertEqual
  (codex:config-permissions-compile-network-sandbox-policy
    (network-with-enabled False))
  (codex:network-sandbox-policy-restricted))

!(assertEqual
  (codex:config-permissions-compile-network-sandbox-policy CodexAbsent)
  (codex:network-sandbox-policy-restricted))

!(assertEqual
  (codex:config-permissions-has-glob-chars "src/**/*.rs")
  True)

!(assertEqual
  (codex:config-permissions-has-glob-chars "docs")
  False)

!(assertEqual
  (codex:config-permissions-remove-trailing-glob-suffix "docs/**")
  "docs")

!(assertEqualToResult
  (codex:config-permissions-compile-read-write-glob-path
    "docs/**"
    (codex:file-system-access-read))
  ((CodexConfigPermissionsOk "docs")))

!(assertEqualToResult
  (codex:config-permissions-compile-read-write-glob-path
    "src/**/*.rs"
    (codex:file-system-access-read))
  ((CodexConfigPermissionsError
     "filesystem glob path `src/**/*.rs` only supports `none` access; use an exact path or trailing `/**` for `read` subtree access")))

!(assertEqualToResult
  (codex:config-permissions-validate-glob-scan-max-depth 0)
  ((CodexConfigPermissionsError
     "glob_scan_max_depth must be at least 1")))

!(assertEqualToResult
  (codex:config-permissions-validate-glob-scan-max-depth 2)
  ((CodexConfigPermissionsOk 2)))

!(assertEqualToResult
  (codex:config-permissions-parse-relative-subpath "docs/**")
  ((CodexConfigPermissionsOk "docs/**")))

!(assertEqualToResult
  (codex:config-permissions-parse-relative-subpath "../secrets")
  ((CodexConfigPermissionsError
     "filesystem subpath `../secrets` must be a descendant path without `.` or `..` components")))

!(assertEqual
  (codex:config-permissions-normalize-absolute-path-for-platform
    "\\\\?\\D:\\c\\x\\worktrees\\2508\\swift-base"
    True)
  "D:\\c\\x\\worktrees\\2508\\swift-base")

!(assertEqual
  (codex:config-permissions-normalize-absolute-path-for-platform
    "\\\\?\\UNC\\server\\share"
    True)
  "\\\\server\\share")

!(assertEqualToResult
  (codex:config-permissions-parse-absolute-path-for-platform
    "\\\\?\\D:\\c\\x"
    True)
  ((CodexConfigPermissionsOk "D:\\c\\x")))

!(assertEqualToResult
  (codex:config-permissions-parse-absolute-path-for-platform
    "relative\\path"
    True)
  ((CodexConfigPermissionsError
     "filesystem path `relative\\path` must be absolute, use `~/...`, or start with `:`")))

!(assertEqual
  (codex:config-permissions-parse-special-path ":project_roots")
  (codex:file-system-special-path-project-roots CodexAbsent))

!(assertEqual
  (codex:config-permissions-parse-special-path ":future_special_path")
  (codex:file-system-special-path-unknown
    ":future_special_path"
    CodexAbsent))

!(assertEqual
  (codex:config-permissions-parse-special-path "/repo")
  CodexAbsent)

!(assertEqualToResult
  (codex:config-permissions-compile-scoped-filesystem-path
    ":project_roots"
    ".")
  ((CodexConfigPermissionsOk
     (CodexFileSystemPathSpecial
       (CodexFileSystemSpecialPathProjectRoots CodexAbsent)))))

!(assertEqualToResult
  (codex:config-permissions-compile-filesystem-permissions
    (CodexFilesystemPermissionsToml
      CodexAbsent
      ((CodexFilesystemPermissionTomlEntry
         ":project_roots"
         (CodexFilesystemPermissionTomlScoped
           ((CodexFilesystemPermissionTomlScopedEntry
              "docs/**"
              (CodexFileSystemAccessModeRead)))))))
    "/workspace")
  ((CodexConfigPermissionsOk
     (CodexFileSystemSandboxPolicy
       (CodexFileSystemSandboxKindRestricted)
       CodexAbsent
       ((CodexFileSystemSandboxEntry
          (CodexFileSystemPathSpecial
            (CodexFileSystemSpecialPathProjectRoots "docs"))
          (CodexFileSystemAccessModeRead)))))))

!(assertEqualToResult
  (codex:config-permissions-compile-filesystem-permissions
    (CodexFilesystemPermissionsToml
      2
      ((CodexFilesystemPermissionTomlEntry
         ":project_roots"
         (CodexFilesystemPermissionTomlScoped
           ((CodexFilesystemPermissionTomlScopedEntry
              "**/*.env"
              (CodexFileSystemAccessModeNone)))))))
    "/workspace")
  ((CodexConfigPermissionsOk
     (CodexFileSystemSandboxPolicy
       (CodexFileSystemSandboxKindRestricted)
       2
       ((CodexFileSystemSandboxEntry
          (CodexFileSystemPathGlobPattern "/workspace/**/*.env")
          (CodexFileSystemAccessModeNone)))))))

!(assertEqualToResult
  (codex:config-permissions-compile-filesystem-permissions
    (CodexFilesystemPermissionsToml
      CodexAbsent
      ((CodexFilesystemPermissionTomlEntry
         ":project_roots"
         (CodexFilesystemPermissionTomlScoped
           ((CodexFilesystemPermissionTomlScopedEntry
              "src/**/*.rs"
              (CodexFileSystemAccessModeRead)))))))
    "/workspace")
  ((CodexConfigPermissionsError
     "filesystem glob path `src/**/*.rs` only supports `none` access; use an exact path or trailing `/**` for `read` subtree access")))

!(assertEqualToResult
  (codex:config-permissions-compile-filesystem-permissions
    (CodexFilesystemPermissionsToml
      0
      ((CodexFilesystemPermissionTomlEntry
         ":project_roots"
         (CodexFilesystemPermissionTomlScoped
           ((CodexFilesystemPermissionTomlScopedEntry
              "src/**/*.rs"
              (CodexFileSystemAccessModeRead)))))))
    "/workspace")
  ((CodexConfigPermissionsError
     "filesystem glob path `src/**/*.rs` only supports `none` access; use an exact path or trailing `/**` for `read` subtree access")))

!(assertEqual
  (codex:config-permissions-missing-filesystem-entries-warning "workspace")
  "Permissions profile `workspace` does not define any recognized filesystem entries for this version of Codex. Filesystem access will remain restricted. Upgrade Codex if this profile expects filesystem permissions.")

!(assertEqualToResult
  (codex:config-permissions-resolve-permission-profile
    (CodexPermissionsToml ())
    "workspace")
  ((CodexConfigPermissionsError
     "default_permissions refers to undefined profile `workspace`")))

!(assertEqualToResult
  (codex:config-permissions-compile-permission-profile
    (CodexPermissionsToml
      ((CodexPermissionsTomlEntry
         "workspace"
         (CodexPermissionProfileToml
           (CodexFilesystemPermissionsToml
             CodexAbsent
             ((CodexFilesystemPermissionTomlEntry
                "/workspace/docs"
                (CodexFilesystemPermissionTomlAccess
                  (CodexFileSystemAccessModeRead)))))
           CodexAbsent))))
    "workspace"
    "/workspace")
  ((CodexConfigPermissionsOk
     (CodexConfigPermissionsCompiledProfile
       (CodexFileSystemSandboxPolicy
         (CodexFileSystemSandboxKindRestricted)
         CodexAbsent
         ((CodexFileSystemSandboxEntry
            (CodexFileSystemPathPath "/workspace/docs")
            (CodexFileSystemAccessModeRead))))
       (CodexNetworkSandboxPolicyRestricted)
       ()))))

!(assertEqualToResult
  (codex:config-permissions-compile-permission-profile
    (CodexPermissionsToml
      ((CodexPermissionsTomlEntry
         "workspace"
         (CodexPermissionProfileToml
           (CodexFilesystemPermissionsToml CodexAbsent ())
           (network-with-enabled True)))))
    "workspace"
    "/workspace")
  ((CodexConfigPermissionsOk
     (CodexConfigPermissionsCompiledProfile
       (CodexFileSystemSandboxPolicy
         (CodexFileSystemSandboxKindRestricted)
         CodexAbsent
         ())
       (CodexNetworkSandboxPolicyEnabled)
       ("Permissions profile `workspace` does not define any recognized filesystem entries for this version of Codex. Filesystem access will remain restricted. Upgrade Codex if this profile expects filesystem permissions.")))))

!(assertEqualToResult
  (codex:config-permissions-compile-permission-profile
    (CodexPermissionsToml
      ((CodexPermissionsTomlEntry
         "workspace"
         (CodexPermissionProfileToml CodexAbsent CodexAbsent))))
    "workspace"
    "/workspace")
  ((CodexConfigPermissionsOk
     (CodexConfigPermissionsCompiledProfile
       (CodexFileSystemSandboxPolicy
         (CodexFileSystemSandboxKindRestricted)
         CodexAbsent
         ())
       (CodexNetworkSandboxPolicyRestricted)
       ("Permissions profile `workspace` does not define any recognized filesystem entries for this version of Codex. Filesystem access will remain restricted. Upgrade Codex if this profile expects filesystem permissions.")))))

!(assertEqualToResult
  (codex:config-permissions-compile-permission-profile
    (CodexPermissionsToml
      ((CodexPermissionsTomlEntry
         "workspace"
         (CodexPermissionProfileToml
           (CodexFilesystemPermissionsToml
             CodexAbsent
             ((CodexFilesystemPermissionTomlEntry
                ":future_special_path"
                (CodexFilesystemPermissionTomlAccess
                  (CodexFileSystemAccessModeRead)))))
           CodexAbsent))))
    "workspace"
    "/workspace")
  ((CodexConfigPermissionsOk
     (CodexConfigPermissionsCompiledProfile
       (CodexFileSystemSandboxPolicy
         (CodexFileSystemSandboxKindRestricted)
         CodexAbsent
         ((CodexFileSystemSandboxEntry
            (CodexFileSystemPathSpecial
              (CodexFileSystemSpecialPathUnknown
                ":future_special_path"
                CodexAbsent))
            (CodexFileSystemAccessModeRead))))
       (CodexNetworkSandboxPolicyRestricted)
       ("Configured filesystem path `:future_special_path` is not recognized by this version of Codex and will be ignored. Upgrade Codex if this path is required.")))))
