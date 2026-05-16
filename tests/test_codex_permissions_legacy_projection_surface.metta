!(register-module! ../codex)
!(import! &self codex:permissions)
!(import! &self codex:permissions_legacy_projection)
!(import! &self list)
!(import! &self process)

!(assertEqualToResult
  (process-result-exit-code
    (process-run-shell
      "rm -rf /home/zarclaw/repos/CeTTa/runtime/codex-permissions-legacy-projection && mkdir -p /home/zarclaw/repos/CeTTa/runtime/codex-permissions-legacy-projection/workspace/docs"))
  (0))

!(assertEqualToResult
  (== (codex:network-sandbox-policy-from-session-sandbox-policy
        (codex:session-sandbox-policy-danger-full-access))
      (codex:network-sandbox-policy-enabled))
  (True))

!(assertEqualToResult
  (== (codex:network-sandbox-policy-from-session-sandbox-policy
        (codex:session-sandbox-policy-read-only
          (codex:session-read-only-access-full)
          False))
      (codex:network-sandbox-policy-restricted))
  (True))

!(assertEqualToResult
  (let $policy-results
    (collapse
      (codex:file-system-sandbox-policy-from-session-sandbox-policy
        (codex:session-sandbox-policy-danger-full-access)))
    (let $policy
      (list:first $policy-results)
      (== $policy
          (codex:file-system-sandbox-policy-unrestricted))))
  (True))

!(assertEqualToResult
  (let $policy-results
    (collapse
      (codex:file-system-sandbox-policy-from-session-sandbox-policy
        (codex:session-sandbox-policy-external-sandbox
          (codex:session-network-access-restricted))))
    (let $policy
      (list:first $policy-results)
      (== $policy
          (codex:file-system-sandbox-policy-external-sandbox))))
  (True))

!(assertEqualToResult
  (let $policy-results
    (collapse
      (codex:file-system-sandbox-policy-from-session-sandbox-policy
        (codex:session-sandbox-policy-read-only
          (codex:session-read-only-access-restricted
            True
            ("/home/zarclaw/repos/CeTTa/runtime/codex-permissions-legacy-projection/workspace/docs"))
          False)))
    (let $policy
      (list:first $policy-results)
      (== $policy
          (codex:file-system-sandbox-policy-restricted
            ((codex:file-system-sandbox-entry
               (codex:file-system-path-special
                 (codex:file-system-special-path-current-working-directory))
               (codex:file-system-access-read))
             (codex:file-system-sandbox-entry
               (codex:file-system-path-special
                 (codex:file-system-special-path-minimal))
               (codex:file-system-access-read))
             (codex:file-system-sandbox-entry
               (codex:file-system-path-path
                 "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-legacy-projection/workspace/docs")
               (codex:file-system-access-read)))))))
  (True))
