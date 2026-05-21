; Visible legacy-sandbox bridge slice for the restarted Codex port.
;
; This ports the adjacent Rust helper from:
; - openai-codex/codex-rs/protocol/src/permissions.rs
;   - FileSystemSandboxPolicy::to_legacy_sandbox_policy
;
; Required CeTTa deviations for audit:
; - Rust returns `io::Result<SandboxPolicy>`. This restart slice exposes an
;   explicit tagged sum because CeTTa does not yet have a dedicated
;   `io::Result` carrier with the same ergonomics.
; - This slice lives outside `codex:permissions` and emits the same
;   `CodexSession...` constructors directly because importing the large
;   `codex:protocol` module next to the foundational permissions reducers
;   destabilizes already-green resolver helpers under the current evaluator.
;   Protocol JSON/projector helpers can still consume these constructors when
;   callers import `codex:protocol` separately.

!(import! &self permissions)

(= (codex:file-system-sandbox-policy-to-legacy-result-ok $policy)
   (CodexFileSystemSandboxPolicyToLegacyResultOk $policy))

(= (codex:file-system-sandbox-policy-to-legacy-result-error $message)
   (CodexFileSystemSandboxPolicyToLegacyResultError $message))

(= (codex:file-system-sandbox-policy-to-legacy-result-is-ok
      (CodexFileSystemSandboxPolicyToLegacyResultOk $policy))
   True)

(= (codex:file-system-sandbox-policy-to-legacy-result-is-ok
      (CodexFileSystemSandboxPolicyToLegacyResultError $message))
   False)

(= (codex:file-system-sandbox-policy-to-legacy-result-policy
      (CodexFileSystemSandboxPolicyToLegacyResultOk $policy))
   $policy)

(= (codex:file-system-sandbox-policy-to-legacy-result-error-message
      (CodexFileSystemSandboxPolicyToLegacyResultError $message))
   $message)

(= (codex:file-system-sandbox-policy-to-legacy-collect-path-entry
      $access
      $path
      $cwd-absolute
      $workspace-root-writable
      $writable-roots
      $readable-roots)
   (if (codex:file-system-access-mode-can-write $access)
       (if (== $cwd-absolute $path)
           (CodexFileSystemSandboxPolicyLegacyPathCollect
             True
             $writable-roots
             $readable-roots)
           (CodexFileSystemSandboxPolicyLegacyPathCollect
             $workspace-root-writable
             (list:append $writable-roots ($path))
             $readable-roots))
       (if (codex:file-system-access-mode-can-read $access)
           (CodexFileSystemSandboxPolicyLegacyPathCollect
             $workspace-root-writable
             $writable-roots
             (list:append $readable-roots ($path)))
           (CodexFileSystemSandboxPolicyLegacyPathCollect
             $workspace-root-writable
             $writable-roots
             $readable-roots))))

(= (codex:file-system-sandbox-policy-legacy-path-collect-workspace-root-writable
      (CodexFileSystemSandboxPolicyLegacyPathCollect
        $workspace-root-writable
        $writable-roots
        $readable-roots))
   $workspace-root-writable)

(= (codex:file-system-sandbox-policy-legacy-path-collect-writable-roots
      (CodexFileSystemSandboxPolicyLegacyPathCollect
        $workspace-root-writable
        $writable-roots
        $readable-roots))
   $writable-roots)

(= (codex:file-system-sandbox-policy-legacy-path-collect-readable-roots
      (CodexFileSystemSandboxPolicyLegacyPathCollect
        $workspace-root-writable
        $writable-roots
        $readable-roots))
   $readable-roots)

(= (codex:file-system-sandbox-policy-to-legacy-network-access
      (CodexNetworkSandboxPolicyEnabled))
   (CodexSessionNetworkAccessEnabled))

(= (codex:file-system-sandbox-policy-to-legacy-network-access
      (CodexNetworkSandboxPolicyRestricted))
   (CodexSessionNetworkAccessRestricted))

(= (codex:file-system-sandbox-policy-to-legacy-special-state
      $value
      $access
      $cwd
      $has-full-disk-read-access
      $include-platform-defaults
      $workspace-root-writable
      $writable-roots
      $readable-roots
      $tmpdir-writable
      $slash-tmp-writable
      $unbridgeable-root-write)
   (if (== $value (CodexFileSystemSpecialPathRoot))
       (if (== $access (CodexFileSystemAccessModeNone))
           (CodexFileSystemSandboxPolicyLegacySpecialCollect
             $include-platform-defaults
             $workspace-root-writable
             $writable-roots
             $readable-roots
             $tmpdir-writable
             $slash-tmp-writable
             $unbridgeable-root-write)
           (if (== $access (CodexFileSystemAccessModeRead))
               (if $has-full-disk-read-access
                   (CodexFileSystemSandboxPolicyLegacySpecialCollect
                     $include-platform-defaults
                     $workspace-root-writable
                     $writable-roots
                     $readable-roots
                     $tmpdir-writable
                     $slash-tmp-writable
                     $unbridgeable-root-write)
                   (CodexFileSystemSandboxPolicyLegacySpecialCollect
                     $include-platform-defaults
                     $workspace-root-writable
                     $writable-roots
                     (list:append
                       $readable-roots
                       ((codex:permissions-absolute-root-path-for-cwd
                          $cwd)))
                     $tmpdir-writable
                     $slash-tmp-writable
                     $unbridgeable-root-write))
               (CodexFileSystemSandboxPolicyLegacySpecialCollect
                 $include-platform-defaults
                 $workspace-root-writable
                 $writable-roots
                 $readable-roots
                 $tmpdir-writable
                 $slash-tmp-writable
                 True)))
       (if (== $value (CodexFileSystemSpecialPathMinimal))
           (CodexFileSystemSandboxPolicyLegacySpecialCollect
             (if (codex:file-system-access-mode-can-read $access)
                 True
                 $include-platform-defaults)
             $workspace-root-writable
             $writable-roots
             $readable-roots
             $tmpdir-writable
             $slash-tmp-writable
             $unbridgeable-root-write)
           (if (== $value (CodexFileSystemSpecialPathCurrentWorkingDirectory))
               (if (codex:file-system-access-mode-can-write $access)
                   (CodexFileSystemSandboxPolicyLegacySpecialCollect
                     $include-platform-defaults
                     True
                     $writable-roots
                     $readable-roots
                     $tmpdir-writable
                     $slash-tmp-writable
                     $unbridgeable-root-write)
                   (let $resolved-path
                     (codex:file-system-resolve-special-path $value $cwd)
                     (if (and
                           (codex:file-system-access-mode-can-read $access)
                           (not (== $resolved-path CodexAbsent)))
                         (CodexFileSystemSandboxPolicyLegacySpecialCollect
                           $include-platform-defaults
                           $workspace-root-writable
                           $writable-roots
                           (list:append $readable-roots ($resolved-path))
                           $tmpdir-writable
                           $slash-tmp-writable
                           $unbridgeable-root-write)
                         (CodexFileSystemSandboxPolicyLegacySpecialCollect
                           $include-platform-defaults
                           $workspace-root-writable
                           $writable-roots
                           $readable-roots
                           $tmpdir-writable
                           $slash-tmp-writable
                           $unbridgeable-root-write))))
               (if (and
                     (== (codex:file-system-special-path-tag $value) "project_roots")
                     (and
                       (== (codex:file-system-special-path-project-roots-subpath $value)
                           CodexAbsent)
                       (codex:file-system-access-mode-can-write $access)))
                   (CodexFileSystemSandboxPolicyLegacySpecialCollect
                     $include-platform-defaults
                     True
                     $writable-roots
                     $readable-roots
                     $tmpdir-writable
                     $slash-tmp-writable
                     $unbridgeable-root-write)
                   (if (== $value (CodexFileSystemSpecialPathTmpdir))
                       (if (codex:file-system-access-mode-can-write $access)
                           (CodexFileSystemSandboxPolicyLegacySpecialCollect
                             $include-platform-defaults
                             $workspace-root-writable
                             $writable-roots
                             $readable-roots
                             True
                             $slash-tmp-writable
                             $unbridgeable-root-write)
                           (let $resolved-path
                             (codex:file-system-resolve-special-path $value $cwd)
                             (if (and
                                   (codex:file-system-access-mode-can-read $access)
                                   (not (== $resolved-path CodexAbsent)))
                                 (CodexFileSystemSandboxPolicyLegacySpecialCollect
                                   $include-platform-defaults
                                   $workspace-root-writable
                                   $writable-roots
                                   (list:append $readable-roots ($resolved-path))
                                   $tmpdir-writable
                                   $slash-tmp-writable
                                   $unbridgeable-root-write)
                                 (CodexFileSystemSandboxPolicyLegacySpecialCollect
                                   $include-platform-defaults
                                   $workspace-root-writable
                                   $writable-roots
                                   $readable-roots
                                   $tmpdir-writable
                                   $slash-tmp-writable
                                   $unbridgeable-root-write))))
                       (if (== $value (CodexFileSystemSpecialPathSlashTmp))
                           (if (codex:file-system-access-mode-can-write $access)
                               (CodexFileSystemSandboxPolicyLegacySpecialCollect
                                 $include-platform-defaults
                                 $workspace-root-writable
                                 $writable-roots
                                 $readable-roots
                                 $tmpdir-writable
                                 True
                                 $unbridgeable-root-write)
                               (let $resolved-path
                                 (codex:file-system-resolve-special-path $value $cwd)
                                 (if (and
                                       (codex:file-system-access-mode-can-read $access)
                                       (not (== $resolved-path CodexAbsent)))
                                     (CodexFileSystemSandboxPolicyLegacySpecialCollect
                                       $include-platform-defaults
                                       $workspace-root-writable
                                       $writable-roots
                                       (list:append $readable-roots ($resolved-path))
                                       $tmpdir-writable
                                       $slash-tmp-writable
                                       $unbridgeable-root-write)
                                     (CodexFileSystemSandboxPolicyLegacySpecialCollect
                                       $include-platform-defaults
                                       $workspace-root-writable
                                       $writable-roots
                                       $readable-roots
                                       $tmpdir-writable
                                       $slash-tmp-writable
                                       $unbridgeable-root-write))))
                           (let $resolved-path
                             (codex:file-system-resolve-special-path $value $cwd)
                             (if (== $resolved-path CodexAbsent)
                                 (CodexFileSystemSandboxPolicyLegacySpecialCollect
                                   $include-platform-defaults
                                   $workspace-root-writable
                                   $writable-roots
                                   $readable-roots
                                   $tmpdir-writable
                                   $slash-tmp-writable
                                   $unbridgeable-root-write)
                                 (if (codex:file-system-access-mode-can-write $access)
                                     (CodexFileSystemSandboxPolicyLegacySpecialCollect
                                       $include-platform-defaults
                                       $workspace-root-writable
                                       (list:append $writable-roots ($resolved-path))
                                       $readable-roots
                                       $tmpdir-writable
                                       $slash-tmp-writable
                                       $unbridgeable-root-write)
                                     (if (codex:file-system-access-mode-can-read $access)
                                         (CodexFileSystemSandboxPolicyLegacySpecialCollect
                                           $include-platform-defaults
                                           $workspace-root-writable
                                           $writable-roots
                                           (list:append $readable-roots ($resolved-path))
                                           $tmpdir-writable
                                           $slash-tmp-writable
                                           $unbridgeable-root-write)
                                         (CodexFileSystemSandboxPolicyLegacySpecialCollect
                                           $include-platform-defaults
                                           $workspace-root-writable
                                           $writable-roots
                                           $readable-roots
                                           $tmpdir-writable
                                           $slash-tmp-writable
                                           $unbridgeable-root-write))))))))))))

(= (codex:file-system-sandbox-policy-legacy-special-collect-include-platform-defaults
      (CodexFileSystemSandboxPolicyLegacySpecialCollect
        $include-platform-defaults
        $workspace-root-writable
        $writable-roots
        $readable-roots
        $tmpdir-writable
        $slash-tmp-writable
        $unbridgeable-root-write))
   $include-platform-defaults)

(= (codex:file-system-sandbox-policy-legacy-special-collect-workspace-root-writable
      (CodexFileSystemSandboxPolicyLegacySpecialCollect
        $include-platform-defaults
        $workspace-root-writable
        $writable-roots
        $readable-roots
        $tmpdir-writable
        $slash-tmp-writable
        $unbridgeable-root-write))
   $workspace-root-writable)

(= (codex:file-system-sandbox-policy-legacy-special-collect-writable-roots
      (CodexFileSystemSandboxPolicyLegacySpecialCollect
        $include-platform-defaults
        $workspace-root-writable
        $writable-roots
        $readable-roots
        $tmpdir-writable
        $slash-tmp-writable
        $unbridgeable-root-write))
   $writable-roots)

(= (codex:file-system-sandbox-policy-legacy-special-collect-readable-roots
      (CodexFileSystemSandboxPolicyLegacySpecialCollect
        $include-platform-defaults
        $workspace-root-writable
        $writable-roots
        $readable-roots
        $tmpdir-writable
        $slash-tmp-writable
        $unbridgeable-root-write))
   $readable-roots)

(= (codex:file-system-sandbox-policy-legacy-special-collect-tmpdir-writable
      (CodexFileSystemSandboxPolicyLegacySpecialCollect
        $include-platform-defaults
        $workspace-root-writable
        $writable-roots
        $readable-roots
        $tmpdir-writable
        $slash-tmp-writable
        $unbridgeable-root-write))
   $tmpdir-writable)

(= (codex:file-system-sandbox-policy-legacy-special-collect-slash-tmp-writable
      (CodexFileSystemSandboxPolicyLegacySpecialCollect
        $include-platform-defaults
        $workspace-root-writable
        $writable-roots
        $readable-roots
        $tmpdir-writable
        $slash-tmp-writable
        $unbridgeable-root-write))
   $slash-tmp-writable)

(= (codex:file-system-sandbox-policy-legacy-special-collect-unbridgeable-root-write
      (CodexFileSystemSandboxPolicyLegacySpecialCollect
        $include-platform-defaults
        $workspace-root-writable
        $writable-roots
        $readable-roots
        $tmpdir-writable
        $slash-tmp-writable
        $unbridgeable-root-write))
   $unbridgeable-root-write)

(= (codex:file-system-sandbox-policy-to-legacy-collect-state
      ()
      $cwd
      $has-full-disk-read-access
      $include-platform-defaults
      $workspace-root-writable
      $writable-roots
      $readable-roots
      $tmpdir-writable
      $slash-tmp-writable
      $unbridgeable-root-write)
   (CodexFileSystemSandboxPolicyLegacyCollectState
     $include-platform-defaults
     $workspace-root-writable
     $writable-roots
     $readable-roots
     $tmpdir-writable
     $slash-tmp-writable
     $unbridgeable-root-write))

(= (codex:file-system-sandbox-policy-to-legacy-collect-state
      $entries
      $cwd
      $has-full-disk-read-access
      $include-platform-defaults
      $workspace-root-writable
      $writable-roots
      $readable-roots
      $tmpdir-writable
      $slash-tmp-writable
      $unbridgeable-root-write)
   (let ($head $tail) (decons-atom $entries)
     (let $path
       (codex:file-system-sandbox-entry-path $head)
       (let $access
         (codex:file-system-sandbox-entry-access $head)
         (if (== (codex:file-system-path-tag $path) "glob_pattern")
             (codex:file-system-sandbox-policy-to-legacy-collect-state
               $tail
               $cwd
               $has-full-disk-read-access
               $include-platform-defaults
               $workspace-root-writable
               $writable-roots
               $readable-roots
               $tmpdir-writable
               $slash-tmp-writable
               $unbridgeable-root-write)
             (if (== (codex:file-system-path-tag $path) "path")
                 (let $path-state
                   (codex:file-system-sandbox-policy-to-legacy-collect-path-entry
                     $access
                     (codex:file-system-path-absolute-path $path)
                     $cwd
                     $workspace-root-writable
                     $writable-roots
                     $readable-roots)
                   (codex:file-system-sandbox-policy-to-legacy-collect-state
                     $tail
                     $cwd
                     $has-full-disk-read-access
                     $include-platform-defaults
                     (codex:file-system-sandbox-policy-legacy-path-collect-workspace-root-writable
                       $path-state)
                     (codex:file-system-sandbox-policy-legacy-path-collect-writable-roots
                       $path-state)
                     (codex:file-system-sandbox-policy-legacy-path-collect-readable-roots
                       $path-state)
                     $tmpdir-writable
                     $slash-tmp-writable
                     $unbridgeable-root-write))
                 (let $special-state
                   (codex:file-system-sandbox-policy-to-legacy-special-state
                     (codex:file-system-path-special-value $path)
                     $access
                     $cwd
                     $has-full-disk-read-access
                     $include-platform-defaults
                     $workspace-root-writable
                     $writable-roots
                     $readable-roots
                     $tmpdir-writable
                     $slash-tmp-writable
                     $unbridgeable-root-write)
                   (codex:file-system-sandbox-policy-to-legacy-collect-state
                     $tail
                     $cwd
                     $has-full-disk-read-access
                     (codex:file-system-sandbox-policy-legacy-special-collect-include-platform-defaults
                       $special-state)
                     (codex:file-system-sandbox-policy-legacy-special-collect-workspace-root-writable
                       $special-state)
                     (codex:file-system-sandbox-policy-legacy-special-collect-writable-roots
                       $special-state)
                     (codex:file-system-sandbox-policy-legacy-special-collect-readable-roots
                       $special-state)
                     (codex:file-system-sandbox-policy-legacy-special-collect-tmpdir-writable
                       $special-state)
                     (codex:file-system-sandbox-policy-legacy-special-collect-slash-tmp-writable
                       $special-state)
                     (codex:file-system-sandbox-policy-legacy-special-collect-unbridgeable-root-write
                       $special-state)))))))))

(= (codex:file-system-sandbox-policy-legacy-collect-state-include-platform-defaults
      (CodexFileSystemSandboxPolicyLegacyCollectState
        $include-platform-defaults
        $workspace-root-writable
        $writable-roots
        $readable-roots
        $tmpdir-writable
        $slash-tmp-writable
        $unbridgeable-root-write))
   $include-platform-defaults)

(= (codex:file-system-sandbox-policy-legacy-collect-state-workspace-root-writable
      (CodexFileSystemSandboxPolicyLegacyCollectState
        $include-platform-defaults
        $workspace-root-writable
        $writable-roots
        $readable-roots
        $tmpdir-writable
        $slash-tmp-writable
        $unbridgeable-root-write))
   $workspace-root-writable)

(= (codex:file-system-sandbox-policy-legacy-collect-state-writable-roots
      (CodexFileSystemSandboxPolicyLegacyCollectState
        $include-platform-defaults
        $workspace-root-writable
        $writable-roots
        $readable-roots
        $tmpdir-writable
        $slash-tmp-writable
        $unbridgeable-root-write))
   $writable-roots)

(= (codex:file-system-sandbox-policy-legacy-collect-state-readable-roots
      (CodexFileSystemSandboxPolicyLegacyCollectState
        $include-platform-defaults
        $workspace-root-writable
        $writable-roots
        $readable-roots
        $tmpdir-writable
        $slash-tmp-writable
        $unbridgeable-root-write))
   $readable-roots)

(= (codex:file-system-sandbox-policy-legacy-collect-state-tmpdir-writable
      (CodexFileSystemSandboxPolicyLegacyCollectState
        $include-platform-defaults
        $workspace-root-writable
        $writable-roots
        $readable-roots
        $tmpdir-writable
        $slash-tmp-writable
        $unbridgeable-root-write))
   $tmpdir-writable)

(= (codex:file-system-sandbox-policy-legacy-collect-state-slash-tmp-writable
      (CodexFileSystemSandboxPolicyLegacyCollectState
        $include-platform-defaults
        $workspace-root-writable
        $writable-roots
        $readable-roots
        $tmpdir-writable
        $slash-tmp-writable
        $unbridgeable-root-write))
   $slash-tmp-writable)

(= (codex:file-system-sandbox-policy-legacy-collect-state-unbridgeable-root-write
      (CodexFileSystemSandboxPolicyLegacyCollectState
        $include-platform-defaults
        $workspace-root-writable
        $writable-roots
        $readable-roots
        $tmpdir-writable
        $slash-tmp-writable
        $unbridgeable-root-write))
   $unbridgeable-root-write)

(= (codex:file-system-sandbox-policy-to-legacy-error-message)
   "permissions profile requests filesystem writes outside the workspace root, which is not supported until the runtime enforces FileSystemSandboxPolicy directly")

(= (codex:file-system-sandbox-policy-to-legacy-sandbox-policy
      (CodexFileSystemSandboxPolicy
        (CodexFileSystemSandboxKindExternalSandbox)
        $glob-scan-max-depth
        $entries)
      $network-policy
      $cwd)
   (codex:file-system-sandbox-policy-to-legacy-result-ok
     (CodexSessionSandboxPolicyExternalSandbox
       (codex:file-system-sandbox-policy-to-legacy-network-access
         $network-policy))))

(= (codex:file-system-sandbox-policy-to-legacy-sandbox-policy
      (CodexFileSystemSandboxPolicy
        (CodexFileSystemSandboxKindUnrestricted)
        $glob-scan-max-depth
        $entries)
      $network-policy
      $cwd)
   (if (codex:network-sandbox-policy-is-enabled $network-policy)
       (codex:file-system-sandbox-policy-to-legacy-result-ok
         (CodexSessionSandboxPolicyDangerFullAccess))
       (codex:file-system-sandbox-policy-to-legacy-result-ok
         (CodexSessionSandboxPolicyExternalSandbox
           (CodexSessionNetworkAccessRestricted)))))

(= (codex:file-system-sandbox-policy-to-legacy-sandbox-policy
      (CodexFileSystemSandboxPolicy
        (CodexFileSystemSandboxKindRestricted)
        $glob-scan-max-depth
        $entries)
      $network-policy
      $cwd)
   ; CeTTa evaluator note: the nested restricted-branch bridge can remain
   ; suspended without an explicit reduction boundary, even though the Rust
   ; visible result is a single concrete `SandboxPolicy`. `once` forces the
   ; same final branch selection without changing the wire-visible behavior.
   (once
     (let $cwd-absolute
       (codex:permissions-resolve-base-cwd $cwd)
       (let $has-full-disk-read-access
         (codex:file-system-sandbox-policy-has-full-disk-read-access
           (CodexFileSystemSandboxPolicy
             (CodexFileSystemSandboxKindRestricted)
             $glob-scan-max-depth
             $entries))
         (let $has-full-disk-write-access
           (codex:file-system-sandbox-policy-has-full-disk-write-access
             (CodexFileSystemSandboxPolicy
               (CodexFileSystemSandboxKindRestricted)
               $glob-scan-max-depth
               $entries))
           (let $state
             (codex:file-system-sandbox-policy-to-legacy-collect-state
               $entries
               $cwd-absolute
               $has-full-disk-read-access
               False
               False
               ()
               ()
               False
               False
               False)
             (if $has-full-disk-write-access
                 (if (codex:network-sandbox-policy-is-enabled $network-policy)
                     (codex:file-system-sandbox-policy-to-legacy-result-ok
                       (CodexSessionSandboxPolicyDangerFullAccess))
                     (codex:file-system-sandbox-policy-to-legacy-result-ok
                       (CodexSessionSandboxPolicyExternalSandbox
                         (CodexSessionNetworkAccessRestricted))))
                 (let $read-only-access
                   (if $has-full-disk-read-access
                       (CodexSessionReadOnlyAccessFull)
                       (CodexSessionReadOnlyAccessRestricted
                         (codex:file-system-sandbox-policy-legacy-collect-state-include-platform-defaults
                           $state)
                         (codex:permissions-dedup-absolute-paths
                           (codex:file-system-sandbox-policy-legacy-collect-state-readable-roots
                             $state)
                           False)))
                   (if (codex:file-system-sandbox-policy-legacy-collect-state-workspace-root-writable
                         $state)
                       (codex:file-system-sandbox-policy-to-legacy-result-ok
                         (CodexSessionSandboxPolicyWorkspaceWrite
                           (codex:permissions-dedup-absolute-paths
                             (codex:file-system-sandbox-policy-legacy-collect-state-writable-roots
                               $state)
                             False)
                           $read-only-access
                           (codex:network-sandbox-policy-is-enabled $network-policy)
                           (not
                             (codex:file-system-sandbox-policy-legacy-collect-state-tmpdir-writable
                               $state))
                           (not
                             (codex:file-system-sandbox-policy-legacy-collect-state-slash-tmp-writable
                               $state))))
                       (if (or
                             (codex:file-system-sandbox-policy-legacy-collect-state-unbridgeable-root-write
                               $state)
                             (or
                               (not (== (codex:file-system-sandbox-policy-legacy-collect-state-writable-roots
                                          $state)
                                        ()))
                               (or
                                 (codex:file-system-sandbox-policy-legacy-collect-state-tmpdir-writable
                                   $state)
                                 (codex:file-system-sandbox-policy-legacy-collect-state-slash-tmp-writable
                                   $state))))
                           (codex:file-system-sandbox-policy-to-legacy-result-error
                             (codex:file-system-sandbox-policy-to-legacy-error-message))
                           (codex:file-system-sandbox-policy-to-legacy-result-ok
                             (CodexSessionSandboxPolicyReadOnly
                               $read-only-access
                               (codex:network-sandbox-policy-is-enabled
                                 $network-policy)))))))))))))
