; Visible sandbox-root helper slice for the restarted Codex port.
;
; This ports the adjacent Rust helpers from:
; - openai-codex/codex-rs/protocol/src/protocol.rs
;   - ReadOnlyAccess::get_readable_roots_with_cwd
;   - SandboxPolicy::new_read_only_policy
;   - SandboxPolicy::new_workspace_write_policy
;   - SandboxPolicy::get_readable_roots_with_cwd
;   - SandboxPolicy::get_writable_roots_with_cwd
;
; Required CeTTa deviations for audit:
; - Rust stores explicit readable/writable roots as `AbsolutePathBuf`, so those
;   configured entries are already validated before these helpers run. The
;   restarted CeTTa protocol layer carries the same visible values as plain
;   strings, so this helper assumes configured roots are already absolute and
;   only validates runtime-derived additions such as `cwd` and `TMPDIR`.
; - This slice lives outside `codex:protocol` because the current evaluator is
;   unstable when the large protocol module and additional runtime-backed path
;   reducers are loaded together. Keeping the helper in a narrow side module
;   preserves the Rust-visible behavior without changing the wire surface.

!(import! &self fs)
!(import! &self list)
!(import! &self path)
!(import! &self process)
!(import! &self protocol)
!(import! &self str)
!(import! &self writable_root_defaults)

(= (codex:sandbox-roots-helper-cwd)
   "/")

(= (codex:sandbox-roots-helper-timeout-ms)
   1000)

(= (codex:sandbox-roots-helper-max-bytes)
   1048576)

(= (codex:session-sandbox-policy-new-read-only-policy)
   (codex:session-sandbox-policy-read-only
     (codex:session-read-only-access-full)
     False))

(= (codex:session-sandbox-policy-new-workspace-write-policy)
   (codex:session-sandbox-policy-workspace-write
     ()
     (codex:session-read-only-access-full)
     False
     False
     False))

(= (codex:sandbox-roots-list-contains () $item)
   False)

(= (codex:sandbox-roots-list-contains $items $item)
   (let ($head $tail) (decons-atom $items)
     (if (== $head $item)
         True
         (codex:sandbox-roots-list-contains $tail $item))))

(= (codex:sandbox-roots-append-unique () $item)
   ($item))

(= (codex:sandbox-roots-append-unique $items $item)
   (codex:sandbox-roots-dedup
     (eval (list:push $items $item))))

(= (codex:sandbox-roots-dedup-script)
   "import os\nitems = os.environ.get('CODEX_SANDBOX_ROOTS_ITEMS', '').split('\\n')\nseen = []\nfor item in items:\n    if item not in seen:\n        seen.append(item)\nprint('\\n'.join(seen), end='')")

(= (codex:sandbox-roots-dedup-joined $joined-items)
   (let $result
     (process-run-cmd-cwd-env-timeout-cap-bytes
       ("/usr/bin/python3"
        "-c"
        (codex:sandbox-roots-dedup-script))
       (codex:sandbox-roots-helper-cwd)
       ((Env "CODEX_SANDBOX_ROOTS_ITEMS" $joined-items))
       (codex:sandbox-roots-helper-timeout-ms)
       (codex:sandbox-roots-helper-max-bytes))
     (if (== (process-result-exit-code $result) 0)
         (str-split "\n" (process-result-stdout $result))
         ())))

(= (codex:sandbox-roots-dedup ())
   ())

(= (codex:sandbox-roots-dedup $items)
   (codex:sandbox-roots-dedup-joined
     (str-join "\n" $items)))

(= (codex:sandbox-roots-append-joined-line "" $item)
   $item)

(= (codex:sandbox-roots-append-joined-line $joined-items $item)
   (str-concat
     (str-concat $joined-items "\n")
     $item))

(= (codex:sandbox-roots-merge-joined-lines "" $rhs)
   $rhs)

(= (codex:sandbox-roots-merge-joined-lines $lhs "")
   $lhs)

(= (codex:sandbox-roots-merge-joined-lines $lhs $rhs)
   (str-concat
     (str-concat $lhs "\n")
     $rhs))

(= (codex:sandbox-roots-tmpdir-from-env)
   (let $result
     (process-run-shell-cwd-timeout-cap-bytes
       "printf %s \"$TMPDIR\""
       (codex:sandbox-roots-helper-cwd)
       (codex:sandbox-roots-helper-timeout-ms)
       (codex:sandbox-roots-helper-max-bytes))
     (if (== (process-result-exit-code $result) 0)
         (process-result-stdout $result)
         "")))

(= (codex:session-read-only-access-get-readable-roots-with-cwd
      (CodexSessionReadOnlyAccessFull)
      $cwd)
   ())

(= (codex:session-read-only-access-get-readable-roots-with-cwd
      (CodexSessionReadOnlyAccessRestricted
        $include-platform-defaults
        $readable-roots)
      $cwd)
   (if (path-is-absolute? $cwd)
       (codex:sandbox-roots-dedup-joined
         (codex:sandbox-roots-append-joined-line
           (str-join "\n" $readable-roots)
           $cwd))
       (codex:sandbox-roots-dedup-joined
         (str-join "\n" $readable-roots))))

(= (codex:session-sandbox-policy-get-readable-roots-with-cwd
      (CodexSessionSandboxPolicyDangerFullAccess)
      $cwd)
   ())

(= (codex:session-sandbox-policy-get-readable-roots-with-cwd
      (CodexSessionSandboxPolicyExternalSandbox $network-access)
      $cwd)
   ())

(= (codex:session-sandbox-policy-get-readable-roots-with-cwd
      (CodexSessionSandboxPolicyReadOnly $access $network-access)
      $cwd)
   (codex:session-read-only-access-get-readable-roots-with-cwd
     $access
     $cwd))

(= (codex:sandbox-roots-workspace-write-root-paths-joined
      $writable-roots
      $exclude-tmpdir-env-var
      $exclude-slash-tmp
      $cwd)
   (let $joined-0
     (str-join "\n" $writable-roots)
     (let $joined-1
       (if (path-is-absolute? $cwd)
           (codex:sandbox-roots-append-joined-line $joined-0 $cwd)
           $joined-0)
       (let $joined-2
         (if $exclude-slash-tmp
             $joined-1
             (if (== (fs-path-kind "/tmp") "directory")
                 (codex:sandbox-roots-append-joined-line $joined-1 "/tmp")
                 $joined-1))
         (let $tmpdir (codex:sandbox-roots-tmpdir-from-env)
           (if (or
                 $exclude-tmpdir-env-var
                 (or
                   (== $tmpdir "")
                   (not (path-is-absolute? $tmpdir))))
               $joined-2
               (codex:sandbox-roots-append-joined-line
                 $joined-2
                 $tmpdir)))))))

(= (codex:sandbox-roots-split-joined-lines "")
   ())

(= (codex:sandbox-roots-split-joined-lines $joined-items)
   (str-split "\n" $joined-items))

(= (codex:sandbox-roots-materialize-writable-root $root $cwd-root)
   (let $protect-missing-dot-codex
     (if (== $cwd-root CodexAbsent)
         False
         (== $cwd-root $root))
     (let $read-only-subpaths
       (eval
         (codex:default-read-only-subpaths-for-writable-root
           $root
           $protect-missing-dot-codex))
       (CodexWritableRoot $root $read-only-subpaths))))

(= (codex:sandbox-roots-materialize-writable-roots $roots $cwd-root)
   (function
     (let $materialized
       (eval
         (map-atom
           $roots
           $root
           (codex:sandbox-roots-materialize-writable-root
             $root
             $cwd-root)))
       (return $materialized))))

(= (codex:session-sandbox-policy-get-writable-roots-with-cwd
      (CodexSessionSandboxPolicyDangerFullAccess)
      $cwd)
   ())

(= (codex:session-sandbox-policy-get-writable-roots-with-cwd
      (CodexSessionSandboxPolicyExternalSandbox $network-access)
      $cwd)
   ())

(= (codex:session-sandbox-policy-get-writable-roots-with-cwd
      (CodexSessionSandboxPolicyReadOnly $access $network-access)
      $cwd)
   ())

(= (codex:session-sandbox-policy-get-writable-roots-with-cwd
      (CodexSessionSandboxPolicyWorkspaceWrite
        $writable-roots
        $read-only-access
        $network-access
        $exclude-tmpdir-env-var
        $exclude-slash-tmp)
      $cwd)
   (function
     (let $joined-roots
       (eval
         (codex:sandbox-roots-workspace-write-root-paths-joined
           $writable-roots
           $exclude-tmpdir-env-var
           $exclude-slash-tmp
           $cwd))
       (let $roots
         (eval
           (codex:sandbox-roots-split-joined-lines $joined-roots))
         (let $materialized
           (eval
             (codex:sandbox-roots-materialize-writable-roots
               $roots
               (if (path-is-absolute? $cwd)
                   $cwd
                   CodexAbsent)))
           (return $materialized))))))

(= (codex:session-sandbox-policy-get-readable-roots-with-cwd
      (CodexSessionSandboxPolicyWorkspaceWrite
        $writable-roots
        $read-only-access
        $network-access
        $exclude-tmpdir-env-var
        $exclude-slash-tmp)
      $cwd)
   (function
     (let $readable-roots
       (eval
         (codex:session-read-only-access-get-readable-roots-with-cwd
           $read-only-access
           $cwd))
       (let $writable-joined
         (eval
           (codex:sandbox-roots-workspace-write-root-paths-joined
             $writable-roots
             $exclude-tmpdir-env-var
             $exclude-slash-tmp
             $cwd))
         (let $joined-roots
           (eval
             (codex:sandbox-roots-merge-joined-lines
               (str-join "\n" $readable-roots)
               $writable-joined))
           (let $deduped
             (eval
               (codex:sandbox-roots-dedup-joined $joined-roots))
             (return $deduped)))))))
