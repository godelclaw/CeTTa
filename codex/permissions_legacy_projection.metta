; Visible legacy-session to modern-permissions projection slice for the
; restarted Codex port.
;
; This checkpoint ports the adjacent stable subset from:
; - openai-codex/codex-rs/protocol/src/permissions.rs
;   - impl From<&SandboxPolicy> for NetworkSandboxPolicy
;   - impl From<&SandboxPolicy> for FileSystemSandboxPolicy
;     - DangerFullAccess
;     - ExternalSandbox
;     - ReadOnly
;
; Required CeTTa deviations for audit:
; - This slice lives in a side module instead of `codex:permissions` because
;   importing the large legacy `codex:protocol` surface into the already-green
;   modern permissions module regresses unrelated helper reductions under the
;   current evaluator. The visible behavior is preserved.

!(import! &self list)
!(import! &self permissions)
!(import! &self protocol)

(= (codex:network-sandbox-policy-from-session-sandbox-policy $sandbox-policy)
   (if (codex:session-sandbox-policy-has-full-network-access $sandbox-policy)
       (codex:network-sandbox-policy-enabled)
       (codex:network-sandbox-policy-restricted)))

(= (codex:permissions-legacy-projection-read-path-entries $paths)
   (function
     (let $entries
       (eval
         (map-atom
           $paths
           $path
           (codex:file-system-sandbox-entry
             (codex:file-system-path-path $path)
             (codex:file-system-access-read))))
       (return $entries))))

(= (codex:permissions-legacy-projection-session-read-only-entries
      (CodexSessionReadOnlyAccessFull))
   ((CodexFileSystemSandboxEntry
      (CodexFileSystemPathSpecial
        (CodexFileSystemSpecialPathRoot))
      (CodexFileSystemAccessModeRead))))

(= (codex:permissions-legacy-projection-session-read-only-entries
      (CodexSessionReadOnlyAccessRestricted
        True
        $readable-roots))
   (let $path-entries
     (codex:permissions-legacy-projection-read-path-entries $readable-roots)
     (let $with-minimal
       (eval
         (list:append
           ((CodexFileSystemSandboxEntry
              (CodexFileSystemPathSpecial
                (CodexFileSystemSpecialPathMinimal))
              (CodexFileSystemAccessModeRead)))
           $path-entries))
       (eval
         (list:append
           ((CodexFileSystemSandboxEntry
              (CodexFileSystemPathSpecial
                (CodexFileSystemSpecialPathCurrentWorkingDirectory))
              (CodexFileSystemAccessModeRead)))
           $with-minimal)))))

(= (codex:permissions-legacy-projection-session-read-only-entries
      (CodexSessionReadOnlyAccessRestricted
        False
        $readable-roots))
   (let $path-entries
     (codex:permissions-legacy-projection-read-path-entries $readable-roots)
     (eval
       (list:append
         ((CodexFileSystemSandboxEntry
            (CodexFileSystemPathSpecial
              (CodexFileSystemSpecialPathCurrentWorkingDirectory))
            (CodexFileSystemAccessModeRead)))
         $path-entries))))

(= (codex:file-system-sandbox-policy-from-session-sandbox-policy
      (CodexSessionSandboxPolicyDangerFullAccess))
   (codex:file-system-sandbox-policy-unrestricted))

(= (codex:file-system-sandbox-policy-from-session-sandbox-policy
      (CodexSessionSandboxPolicyExternalSandbox $network-access))
   (codex:file-system-sandbox-policy-external-sandbox))

(= (codex:file-system-sandbox-policy-from-session-sandbox-policy
      (CodexSessionSandboxPolicyReadOnly $access $network-access))
   (let $entries-results
     (collapse
       (codex:permissions-legacy-projection-session-read-only-entries
         $access))
     (let $entries
       (list:first $entries-results)
       (codex:file-system-sandbox-policy-restricted $entries))))
