!(register-module! ../codex)
!(import! &self codex:permissions)
!(import! &self process)

!(assertEqualToResult
  (process-result-exit-code
    (process-run-shell
      "rm -rf /home/zarclaw/repos/CeTTa/runtime/codex-permissions-roots && mkdir -p /home/zarclaw/repos/CeTTa/runtime/codex-permissions-roots/workspace/docs"))
  (0))

!(assertEqualToResult
  (once
    (codex:file-system-sandbox-policy-get-readable-roots-with-cwd
      (codex:file-system-sandbox-policy-restricted
        ((codex:file-system-sandbox-entry
           (codex:file-system-path-special
             (codex:file-system-special-path-current-working-directory))
           (codex:file-system-access-read))))
      "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-roots/workspace"))
  (("/home/zarclaw/repos/CeTTa/runtime/codex-permissions-roots/workspace")))

!(assertEqualToResult
  (once
    (codex:file-system-sandbox-policy-get-readable-roots-with-cwd
      (codex:file-system-sandbox-policy-restricted
        ((codex:file-system-sandbox-entry
           (codex:file-system-path-special
             (codex:file-system-special-path-root))
           (codex:file-system-access-none))
         (codex:file-system-sandbox-entry
           (codex:file-system-path-path
             "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-roots/workspace/docs")
           (codex:file-system-access-read))))
      "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-roots/workspace"))
  (("/home/zarclaw/repos/CeTTa/runtime/codex-permissions-roots/workspace/docs")))

!(assertEqualToResult
  (once
    (codex:file-system-sandbox-policy-get-unreadable-roots-with-cwd
      (codex:file-system-sandbox-policy-restricted
        ((codex:file-system-sandbox-entry
           (codex:file-system-path-special
             (codex:file-system-special-path-root))
           (codex:file-system-access-none))
         (codex:file-system-sandbox-entry
           (codex:file-system-path-path
             "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-roots/workspace/docs")
           (codex:file-system-access-read))))
      "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-roots/workspace"))
  (()))

!(assertEqualToResult
  (once
    (codex:file-system-sandbox-policy-get-unreadable-globs-with-cwd
      (codex:file-system-sandbox-policy-restricted
        ((codex:file-system-sandbox-entry
           (codex:file-system-path-glob-pattern "z/*.secret")
           (codex:file-system-access-none))
         (codex:file-system-sandbox-entry
           (codex:file-system-path-glob-pattern "docs/**/*.secret")
           (codex:file-system-access-none))
         (codex:file-system-sandbox-entry
           (codex:file-system-path-glob-pattern "docs/**/*.secret")
           (codex:file-system-access-none))))
      "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-roots/workspace"))
  (("/home/zarclaw/repos/CeTTa/runtime/codex-permissions-roots/workspace/docs/**/*.secret"
    "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-roots/workspace/z/*.secret")))
