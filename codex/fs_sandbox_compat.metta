; Rust-faithful filesystem-sandbox compatibility policy slice.
;
; This ports the pure compatibility helpers from:
; - openai-codex/codex-rs/exec-server/src/fs_sandbox.rs
;   - compatibility_sandbox_policy
;   - compatibility_workspace_write_policy
;
; It also hosts the writable-root projection required by that fallback from:
; - openai-codex/codex-rs/protocol/src/permissions.rs
;   - FileSystemSandboxPolicy::get_writable_roots_with_cwd
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust keeps `get_writable_roots_with_cwd` on `FileSystemSandboxPolicy`.
;   Importing the full protocol/legacy bridge surface into the base CeTTa
;   permissions or fs_sandbox modules destabilizes already-green foundational
;   reducers under the current evaluator, so this side module carries the
;   projection exactly for the `fs_sandbox.rs` compatibility fallback.
; - Rust returns protocol `SandboxPolicy` and `WritableRoot` structs from typed
;   modules. This slice emits the same visible constructors directly, avoiding
;   an otherwise unnecessary dependency on protocol helper functions.

!(import! &self list)
!(import! &self path)
!(import! &self permissions_legacy_bridge)
!(import! &self permissions)
!(import! &self str)
!(import! &self writable_root_defaults)

(= (codex:fs-sandbox-compat-has-explicit-resolved-path-entry
      ()
      $path)
   False)

(= (codex:fs-sandbox-compat-has-explicit-resolved-path-entry
      $entries
      $path)
   (let ($head $tail) (decons-atom $entries)
     (if (== (codex:resolved-file-system-entry-path $head) $path)
         True
         (codex:fs-sandbox-compat-has-explicit-resolved-path-entry
           $tail
           $path))))

(= (codex:fs-sandbox-compat-writable-entry-paths
      $policy
      ()
      $cwd)
   ())

(= (codex:fs-sandbox-compat-writable-entry-paths
      $policy
      $resolved-entries
      $cwd)
   (let ($head $tail) (decons-atom $resolved-entries)
     (let $tail-paths
       (codex:fs-sandbox-compat-writable-entry-paths
         $policy
         $tail
         $cwd)
       (if (and
             (codex:file-system-access-mode-can-write
               (codex:resolved-file-system-entry-access $head))
             (codex:file-system-sandbox-policy-can-write-path-with-cwd
               $policy
               (codex:resolved-file-system-entry-path $head)
               $cwd))
           (list:append
             ((codex:resolved-file-system-entry-path $head))
             $tail-paths)
           $tail-paths))))

(= (codex:fs-sandbox-compat-filter-default-read-only-subpaths
      ()
      $resolved-entries)
   ())

(= (codex:fs-sandbox-compat-filter-default-read-only-subpaths
      $subpaths
      $resolved-entries)
   (let ($head $tail) (decons-atom $subpaths)
     (let $tail-subpaths
       (codex:fs-sandbox-compat-filter-default-read-only-subpaths
         $tail
         $resolved-entries)
       (if (codex:fs-sandbox-compat-has-explicit-resolved-path-entry
             $resolved-entries
             $head)
           $tail-subpaths
           (list:append ($head) $tail-subpaths)))))

(= (codex:fs-sandbox-compat-path-relative-suffix $path $prefix)
   (let $normalized-path (path-normalize $path)
     (let $normalized-prefix (path-normalize $prefix)
       (if (== $normalized-path $normalized-prefix)
           ""
           (if (== $normalized-prefix "/")
               (if (str-starts-with? $normalized-path "/")
                   (str-slice
                     $normalized-path
                     1
                     (str-length $normalized-path))
                   CodexAbsent)
               (let $prefix-with-slash
                 (str-concat $normalized-prefix "/")
                 (if (str-starts-with? $normalized-path $prefix-with-slash)
                     (str-slice
                       $normalized-path
                       (str-length $prefix-with-slash)
                       (str-length $normalized-path))
                     CodexAbsent)))))))

(= (codex:fs-sandbox-compat-raw-carveout-from-roots
      ()
      $entry-path
      $root)
   CodexAbsent)

(= (codex:fs-sandbox-compat-raw-carveout-from-roots
      $raw-writable-roots
      $entry-path
      $root)
   (let ($head $tail) (decons-atom $raw-writable-roots)
     (let $suffix
       (codex:fs-sandbox-compat-path-relative-suffix $entry-path $head)
       (if (and
             (not (== $suffix CodexAbsent))
             (not (== $suffix "")))
           (path-join $root $suffix)
           (codex:fs-sandbox-compat-raw-carveout-from-roots
             $tail
             $entry-path
             $root)))))

(= (codex:fs-sandbox-compat-raw-carveout-path
      $preserve-raw-carveout-paths
      $entry-path
      $root
      $raw-writable-roots)
   (if $preserve-raw-carveout-paths
       (if (== $entry-path $root)
           CodexAbsent
           (if (codex:permissions-path-starts-with-path $entry-path $root)
               $entry-path
               (codex:fs-sandbox-compat-raw-carveout-from-roots
                 $raw-writable-roots
                 $entry-path
                 $root)))
       CodexAbsent))

(= (codex:fs-sandbox-compat-read-only-carveout-for-entry
      $entry
      $policy
      $cwd
      $root
      $preserve-raw-carveout-paths
      $raw-writable-roots)
   (let $entry-path (codex:resolved-file-system-entry-path $entry)
     (let $raw-carveout-path
       (codex:fs-sandbox-compat-raw-carveout-path
         $preserve-raw-carveout-paths
         $entry-path
         $root
         $raw-writable-roots)
       (if (not (== $raw-carveout-path CodexAbsent))
           $raw-carveout-path
           (let $effective-path
             (codex:permissions-normalize-effective-absolute-path $entry-path)
             (if (or
                   (== $effective-path $root)
                   (not
                     (codex:permissions-path-starts-with-path
                       $effective-path
                       $root)))
                 CodexAbsent
                 $effective-path))))))

(= (codex:fs-sandbox-compat-read-only-carveouts-for-root
      ()
      $policy
      $cwd
      $root
      $preserve-raw-carveout-paths
      $raw-writable-roots)
   ())

(= (codex:fs-sandbox-compat-read-only-carveouts-for-root
      $resolved-entries
      $policy
      $cwd
      $root
      $preserve-raw-carveout-paths
      $raw-writable-roots)
   (let ($head $tail) (decons-atom $resolved-entries)
     (let $tail-carveouts
       (codex:fs-sandbox-compat-read-only-carveouts-for-root
         $tail
         $policy
         $cwd
         $root
         $preserve-raw-carveout-paths
         $raw-writable-roots)
       (if (and
             (not
               (codex:file-system-access-mode-can-write
                 (codex:resolved-file-system-entry-access $head)))
             (not
               (codex:file-system-sandbox-policy-can-write-path-with-cwd
                 $policy
                 (codex:resolved-file-system-entry-path $head)
                 $cwd)))
           (let $carveout
             (codex:fs-sandbox-compat-read-only-carveout-for-entry
               $head
               $policy
               $cwd
               $root
               $preserve-raw-carveout-paths
               $raw-writable-roots)
             (if (== $carveout CodexAbsent)
                 $tail-carveouts
                 (list:append ($carveout) $tail-carveouts)))
           $tail-carveouts))))

(= (codex:fs-sandbox-compat-raw-writable-roots-for-effective-root
      ()
      $root)
   ())

(= (codex:fs-sandbox-compat-raw-writable-roots-for-effective-root
      $writable-entries
      $root)
   (let ($head $tail) (decons-atom $writable-entries)
     (let $tail-roots
       (codex:fs-sandbox-compat-raw-writable-roots-for-effective-root
         $tail
         $root)
       (if (== (codex:permissions-normalize-effective-absolute-path $head)
               $root)
           (list:append ($head) $tail-roots)
           $tail-roots))))

(= (codex:fs-sandbox-compat-root-preserve-raw-carveout-paths $root)
   (not (== (path-normalize $root) "/")))

(= (codex:fs-sandbox-compat-root-protect-missing-dot-codex $root $cwd)
   (if (path-is-absolute? $cwd)
       (== (codex:permissions-normalize-effective-absolute-path $cwd)
           $root)
       False))

(= (codex:fs-sandbox-compat-writable-root-for-root
      $policy
      $resolved-entries
      $writable-entries
      $cwd
      $root)
   (let $preserve-raw-carveout-paths
     (codex:fs-sandbox-compat-root-preserve-raw-carveout-paths $root)
     (let $raw-writable-roots
       (codex:fs-sandbox-compat-raw-writable-roots-for-effective-root
         $writable-entries
         $root)
       (let $protect-missing-dot-codex
         (codex:fs-sandbox-compat-root-protect-missing-dot-codex $root $cwd)
         (let $default-read-only-subpaths
           (codex:fs-sandbox-compat-filter-default-read-only-subpaths
             (codex:default-read-only-subpaths-for-writable-root
               $root
               $protect-missing-dot-codex)
             $resolved-entries)
           (let $explicit-carveouts
             (codex:fs-sandbox-compat-read-only-carveouts-for-root
               $resolved-entries
               $policy
               $cwd
               $root
               $preserve-raw-carveout-paths
               $raw-writable-roots)
             (CodexWritableRoot
               $root
               (codex:permissions-dedup-absolute-paths
                 (list:append
                   $default-read-only-subpaths
                   $explicit-carveouts)
                 False))))))))

(= (codex:fs-sandbox-compat-writable-roots-for-roots
      $policy
      $resolved-entries
      $writable-entries
      $cwd
      ())
   ())

(= (codex:fs-sandbox-compat-writable-roots-for-roots
      $policy
      $resolved-entries
      $writable-entries
      $cwd
      $roots)
   (let ($head $tail) (decons-atom $roots)
     (list:append
       ((codex:fs-sandbox-compat-writable-root-for-root
          $policy
          $resolved-entries
          $writable-entries
          $cwd
          $head))
       (codex:fs-sandbox-compat-writable-roots-for-roots
         $policy
         $resolved-entries
         $writable-entries
         $cwd
         $tail))))

(= (codex:fs-sandbox-compat-policy-get-writable-roots-with-cwd
      $policy
      $cwd)
   ; Rust returns one concrete `Vec<WritableRoot>`. The current CeTTa
   ; evaluator can expose duplicate equivalent reductions from the recursive
   ; permission helpers, so collapse this public vector boundary once.
   (once
     (if (codex:file-system-sandbox-policy-has-full-disk-write-access $policy)
         ()
         (let $resolved-entries
           (once (codex:file-system-resolved-entries-with-cwd $policy $cwd))
           (let $writable-entries
             (once
               (codex:fs-sandbox-compat-writable-entry-paths
                 $policy
                 $resolved-entries
                 $cwd))
             (codex:fs-sandbox-compat-writable-roots-for-roots
               $policy
               $resolved-entries
               $writable-entries
               $cwd
               (once
                 (codex:permissions-dedup-absolute-paths
                   $writable-entries
                   True))))))))

(= (codex:fs-sandbox-compat-writable-root-root
      (CodexWritableRoot $root $read-only-subpaths))
   $root)

(= (codex:fs-sandbox-compat-root-paths-excluding-cwd
      ()
      $cwd-absolute)
   ())

(= (codex:fs-sandbox-compat-root-paths-excluding-cwd
      $writable-roots
      $cwd-absolute)
   (let ($head $tail) (decons-atom $writable-roots)
     (let $tail-roots
       (codex:fs-sandbox-compat-root-paths-excluding-cwd
         $tail
         $cwd-absolute)
       (let $root
         (codex:fs-sandbox-compat-writable-root-root $head)
         (if (and
               (not (== $cwd-absolute CodexAbsent))
               (== $root $cwd-absolute))
             $tail-roots
             (list:append ($root) $tail-roots))))))

(= (codex:fs-sandbox-compatibility-read-only-access
      $file-system-policy
      $cwd)
   ; Rust materializes exactly one `ReadOnlyAccess` enum value.
   (once
     (if (codex:file-system-sandbox-policy-has-full-disk-read-access
           $file-system-policy)
         (CodexSessionReadOnlyAccessFull)
         (CodexSessionReadOnlyAccessRestricted
           (codex:file-system-sandbox-policy-include-platform-defaults
             $file-system-policy)
           (once
             (codex:file-system-sandbox-policy-get-readable-roots-with-cwd
               $file-system-policy
               $cwd))))))

(= (codex:fs-sandbox-compatibility-workspace-write-policy
      $file-system-policy
      $cwd)
   ; Rust constructs a single fallback `SandboxPolicy::WorkspaceWrite`.
   (once
     (let $cwd-absolute
       (if (path-is-absolute? $cwd)
           (path-normalize $cwd)
           CodexAbsent)
       (CodexSessionSandboxPolicyWorkspaceWrite
         (once
           (codex:fs-sandbox-compat-root-paths-excluding-cwd
             (once
               (codex:fs-sandbox-compat-policy-get-writable-roots-with-cwd
                 $file-system-policy
                 $cwd))
             $cwd-absolute))
         (once
           (codex:fs-sandbox-compatibility-read-only-access
             $file-system-policy
             $cwd))
         False
         True
         True))))

(= (codex:fs-sandbox-compatibility-sandbox-policy
      $file-system-policy
      $network-policy
      $cwd)
   (let $result
     (once
       (codex:file-system-sandbox-policy-to-legacy-sandbox-policy
         $file-system-policy
         $network-policy
         $cwd))
     (if (codex:file-system-sandbox-policy-to-legacy-result-is-ok $result)
         (codex:file-system-sandbox-policy-to-legacy-result-policy $result)
         (once
           (codex:fs-sandbox-compatibility-workspace-write-policy
             $file-system-policy
             $cwd)))))
