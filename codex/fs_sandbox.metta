; Rust-faithful filesystem-sandbox helper environment slice.
;
; This ports deterministic helper behavior from:
; - openai-codex/codex-rs/exec-server/src/fs_sandbox.rs
;   - FS_HELPER_ENV_ALLOWLIST
;   - helper_env_key_is_allowed
;   - helper_env_from_vars
;   - helper_read_roots
;   - add_helper_runtime_permissions
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust uses compile-time `cfg!(windows)`. This pure helper exposes the target
;   branch as an explicit Boolean in `...-on-platform`, while the unparameterized
;   helper uses the Unix/Linux branch used by this CeTTa profile.
; - Rust uses `OsString::to_string_lossy()` and collects into a `HashMap`.
;   This slice receives already-materialized strings and reuses ordered
;   `CodexUnifiedExecEnvVar` pairs; lookup and duplicate-key replacement match
;   `HashMap::insert`, while iteration order is intentionally not a contract.
; - Rust lets the helper-root loop call `can_read_path_with_cwd` even after
;   observing full-disk read access. This pure helper returns early in that
;   case; the visible policy is identical because every helper root is already
;   readable.

!(import! &self list)
!(import! &self path)
!(import! &self permissions)
!(import! &self str)
!(import! &self unified_exec_env)

(= (codex:fs-helper-env-allowlist)
   ("PATH" "TMPDIR" "TMP" "TEMP"))

(= (codex:fs-helper-env-ascii-lower-char $char)
   (case $char
     (("A" "a")
      ("B" "b")
      ("C" "c")
      ("D" "d")
      ("E" "e")
      ("F" "f")
      ("G" "g")
      ("H" "h")
      ("I" "i")
      ("J" "j")
      ("K" "k")
      ("L" "l")
      ("M" "m")
      ("N" "n")
      ("O" "o")
      ("P" "p")
      ("Q" "q")
      ("R" "r")
      ("S" "s")
      ("T" "t")
      ("U" "u")
      ("V" "v")
      ("W" "w")
      ("X" "x")
      ("Y" "y")
      ("Z" "z")
      ($other $other))))

(= (codex:fs-helper-env-ascii-lower-text $text)
   (if (== $text "")
       ""
       (str-concat
         (codex:fs-helper-env-ascii-lower-char (str-slice $text 0 1))
         (codex:fs-helper-env-ascii-lower-text
           (str-slice $text 1 (str-length $text))))))

(= (codex:fs-helper-env-ascii-eq $left $right)
   (== (codex:fs-helper-env-ascii-lower-text $left)
       (codex:fs-helper-env-ascii-lower-text $right)))

(= (codex:fs-helper-env-key-in-allowlist $key $allowlist)
   (if (== $allowlist ())
       False
       (let $head (list:first $allowlist)
         (let $tail (list:rest $allowlist)
           (if (== $key $head)
               True
               (codex:fs-helper-env-key-in-allowlist $key $tail))))))

(= (codex:fs-helper-env-key-allowed-on-platform $is-windows $key)
   (if (codex:fs-helper-env-key-in-allowlist
         $key
         (codex:fs-helper-env-allowlist))
       True
       (if $is-windows
           (codex:fs-helper-env-ascii-eq $key "PATH")
           False)))

(= (codex:fs-helper-env-key-allowed $key)
   (codex:fs-helper-env-key-allowed-on-platform False $key))

(= (codex:fs-helper-env-from-vars-on-platform $is-windows $vars)
   (codex:fs-helper-env-from-vars-acc $is-windows $vars ()))

(= (codex:fs-helper-env-from-vars-acc $is-windows () $acc)
   $acc)

(= (codex:fs-helper-env-from-vars-acc $is-windows $vars $acc)
   (let $head (list:first $vars)
     (let $tail (list:rest $vars)
       (let $key (codex:unified-exec-env-var-name $head)
         (let $value (codex:unified-exec-env-var-value $head)
           (let $updated
             (if (codex:fs-helper-env-key-allowed-on-platform $is-windows $key)
                 (codex:unified-exec-env-insert $acc $key $value)
                 $acc)
             (codex:fs-helper-env-from-vars-acc
               $is-windows
               $tail
               $updated)))))))

(= (codex:fs-helper-env-from-vars $vars)
   (codex:fs-helper-env-from-vars-on-platform False $vars))

(= (codex:fs-sandbox-runtime-paths
      $codex-self-exe
      $codex-linux-sandbox-exe)
   (CodexFsSandboxRuntimePaths
     $codex-self-exe
     $codex-linux-sandbox-exe))

(= (codex:fs-sandbox-runtime-paths-codex-self-exe
      (CodexFsSandboxRuntimePaths
        $codex-self-exe
        $codex-linux-sandbox-exe))
   $codex-self-exe)

(= (codex:fs-sandbox-runtime-paths-codex-linux-sandbox-exe
      (CodexFsSandboxRuntimePaths
        $codex-self-exe
        $codex-linux-sandbox-exe))
   $codex-linux-sandbox-exe)

(= (codex:fs-sandbox-path-list-contains $needle ())
   False)

(= (codex:fs-sandbox-path-list-contains $needle $items)
   (let $head (list:first $items)
     (let $tail (list:rest $items)
       (if (== $needle $head)
           True
           (codex:fs-sandbox-path-list-contains $needle $tail)))))

(= (codex:fs-sandbox-append-unique-path $items $path)
   (let $normalized (path-normalize $path)
     (if (codex:fs-sandbox-path-list-contains $normalized $items)
         $items
         (list:append $items ($normalized)))))

(= (codex:fs-sandbox-parent-root $path)
   (path-dirname (path-normalize $path)))

(= (codex:fs-sandbox-helper-read-roots $runtime-paths)
   (let $codex-root
     (codex:fs-sandbox-parent-root
       (codex:fs-sandbox-runtime-paths-codex-self-exe $runtime-paths))
     (let $roots
       (codex:fs-sandbox-append-unique-path () $codex-root)
       (let $codex-linux-sandbox-exe
         (codex:fs-sandbox-runtime-paths-codex-linux-sandbox-exe
           $runtime-paths)
         (if (== $codex-linux-sandbox-exe CodexAbsent)
             $roots
             (codex:fs-sandbox-append-unique-path
               $roots
               (codex:fs-sandbox-parent-root
                 $codex-linux-sandbox-exe)))))))

(= (codex:fs-sandbox-minimal-read-entry)
   (codex:file-system-sandbox-entry
     (codex:file-system-path-special
       (codex:file-system-special-path-minimal))
     (codex:file-system-access-read)))

(= (codex:fs-sandbox-policy-ensure-minimal-read
      (CodexFileSystemSandboxPolicy $kind $glob-scan-max-depth $entries))
   (if (codex:file-system-sandbox-policy-has-full-disk-read-access
         (CodexFileSystemSandboxPolicy
           $kind
           $glob-scan-max-depth
           $entries))
       (CodexFileSystemSandboxPolicy
         $kind
         $glob-scan-max-depth
         $entries)
       (let $minimal-read-entry
         (codex:fs-sandbox-minimal-read-entry)
         (if (codex:file-system-sandbox-entries-contain-entry
               $entries
               $minimal-read-entry)
             (CodexFileSystemSandboxPolicy
               $kind
               $glob-scan-max-depth
               $entries)
             (CodexFileSystemSandboxPolicy
               $kind
               $glob-scan-max-depth
               (list:append $entries ($minimal-read-entry)))))))

(= (codex:fs-sandbox-policy-add-helper-root
      (CodexFileSystemSandboxPolicy $kind $glob-scan-max-depth $entries)
      $cwd
      $helper-read-root)
   (if (codex:file-system-sandbox-policy-has-full-disk-read-access
         (CodexFileSystemSandboxPolicy
           $kind
           $glob-scan-max-depth
           $entries))
       (CodexFileSystemSandboxPolicy
         $kind
         $glob-scan-max-depth
         $entries)
       (if (codex:file-system-sandbox-policy-can-read-path-with-cwd
             (CodexFileSystemSandboxPolicy
               $kind
               $glob-scan-max-depth
               $entries)
             $helper-read-root
             $cwd)
           (CodexFileSystemSandboxPolicy
             $kind
             $glob-scan-max-depth
             $entries)
           (CodexFileSystemSandboxPolicy
             $kind
             $glob-scan-max-depth
             (list:append
               $entries
               ((codex:file-system-sandbox-entry
                  (codex:file-system-path-path
                    (path-normalize $helper-read-root))
                  (codex:file-system-access-read))))))))

(= (codex:fs-sandbox-add-helper-read-roots
      $file-system-policy
      $cwd
      ())
   $file-system-policy)

(= (codex:fs-sandbox-add-helper-read-roots
      $file-system-policy
      $cwd
      $helper-read-roots)
   (let $head (list:first $helper-read-roots)
     (let $tail (list:rest $helper-read-roots)
       (codex:fs-sandbox-add-helper-read-roots
         (codex:fs-sandbox-policy-add-helper-root
           $file-system-policy
           $cwd
           $head)
         $cwd
         $tail))))

(= (codex:fs-sandbox-add-helper-runtime-permissions
      $file-system-policy
      $helper-read-roots
      $cwd)
   (let $policy
     (codex:fs-sandbox-policy-ensure-minimal-read $file-system-policy)
     (if (codex:file-system-sandbox-policy-has-full-disk-read-access
           $policy)
         $policy
         (codex:fs-sandbox-add-helper-read-roots
           $policy
           $cwd
           $helper-read-roots))))
