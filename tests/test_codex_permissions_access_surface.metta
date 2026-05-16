!(register-module! ../codex)
!(import! &self codex:permissions)
!(import! &self process)

!(assertEqualToResult
  (process-result-exit-code
    (process-run-shell
      "rm -rf /home/zarclaw/repos/CeTTa/runtime/codex-permissions-access && mkdir -p /home/zarclaw/repos/CeTTa/runtime/codex-permissions-access/workspace/docs/private/public /home/zarclaw/repos/CeTTa/runtime/codex-permissions-access/extra"))
  (0))

!(assertEqualToResult
  (== (codex:file-system-sandbox-policy-resolve-access-with-cwd
        (codex:file-system-sandbox-policy-restricted
          ((codex:file-system-sandbox-entry
             (codex:file-system-path-special
               (codex:file-system-special-path-current-working-directory))
             (codex:file-system-access-write))
           (codex:file-system-sandbox-entry
             (codex:file-system-path-path
               "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-access/workspace/docs")
             (codex:file-system-access-read))
           (codex:file-system-sandbox-entry
             (codex:file-system-path-path
               "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-access/workspace/docs/private")
             (codex:file-system-access-none))
           (codex:file-system-sandbox-entry
             (codex:file-system-path-path
               "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-access/workspace/docs/private/public")
             (codex:file-system-access-write))))
        "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-access/workspace"
        "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-access/workspace")
      (codex:file-system-access-write))
  (True))

!(assertEqualToResult
  (== (codex:file-system-sandbox-policy-resolve-access-with-cwd
        (codex:file-system-sandbox-policy-restricted
          ((codex:file-system-sandbox-entry
             (codex:file-system-path-special
               (codex:file-system-special-path-current-working-directory))
             (codex:file-system-access-write))
           (codex:file-system-sandbox-entry
             (codex:file-system-path-path
               "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-access/workspace/docs")
             (codex:file-system-access-read))
           (codex:file-system-sandbox-entry
             (codex:file-system-path-path
               "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-access/workspace/docs/private")
             (codex:file-system-access-none))
           (codex:file-system-sandbox-entry
             (codex:file-system-path-path
               "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-access/workspace/docs/private/public")
             (codex:file-system-access-write))))
        "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-access/workspace/docs"
        "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-access/workspace")
      (codex:file-system-access-read))
  (True))

!(assertEqualToResult
  (== (codex:file-system-sandbox-policy-resolve-access-with-cwd
        (codex:file-system-sandbox-policy-restricted
          ((codex:file-system-sandbox-entry
             (codex:file-system-path-special
               (codex:file-system-special-path-current-working-directory))
             (codex:file-system-access-write))
           (codex:file-system-sandbox-entry
             (codex:file-system-path-path
               "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-access/workspace/docs")
             (codex:file-system-access-read))
           (codex:file-system-sandbox-entry
             (codex:file-system-path-path
               "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-access/workspace/docs/private")
             (codex:file-system-access-none))
           (codex:file-system-sandbox-entry
             (codex:file-system-path-path
               "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-access/workspace/docs/private/public")
             (codex:file-system-access-write))))
        "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-access/workspace/docs/private"
        "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-access/workspace")
      (codex:file-system-access-none))
  (True))

!(assertEqualToResult
  (== (codex:file-system-sandbox-policy-resolve-access-with-cwd
        (codex:file-system-sandbox-policy-restricted
          ((codex:file-system-sandbox-entry
             (codex:file-system-path-special
               (codex:file-system-special-path-current-working-directory))
             (codex:file-system-access-write))
           (codex:file-system-sandbox-entry
             (codex:file-system-path-path
               "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-access/workspace/docs")
             (codex:file-system-access-read))
           (codex:file-system-sandbox-entry
             (codex:file-system-path-path
               "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-access/workspace/docs/private")
             (codex:file-system-access-none))
           (codex:file-system-sandbox-entry
             (codex:file-system-path-path
               "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-access/workspace/docs/private/public")
             (codex:file-system-access-write))))
        "docs/private/public/child.txt"
        "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-access/workspace")
      (codex:file-system-access-write))
  (True))

!(assertEqualToResult
  (== (codex:file-system-sandbox-policy-can-read-path-with-cwd
        (codex:file-system-sandbox-policy-restricted
          ((codex:file-system-sandbox-entry
             (codex:file-system-path-special
               (codex:file-system-special-path-project-roots "docs"))
             (codex:file-system-access-read))))
        "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-access/workspace/docs/guide.md"
        "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-access/workspace")
      True)
  (True))

!(assertEqualToResult
  (== (codex:file-system-sandbox-policy-can-write-path-with-cwd
        (codex:file-system-sandbox-policy-restricted
          ((codex:file-system-sandbox-entry
             (codex:file-system-path-special
               (codex:file-system-special-path-current-working-directory))
             (codex:file-system-access-write))))
        "notes/today.txt"
        "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-access/workspace")
      True)
  (True))

!(assertEqualToResult
  (== (codex:file-system-sandbox-policy-with-additional-readable-roots
        (codex:file-system-sandbox-policy-restricted
          ((codex:file-system-sandbox-entry
             (codex:file-system-path-special
               (codex:file-system-special-path-current-working-directory))
             (codex:file-system-access-read))))
        "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-access/workspace"
        ("/home/zarclaw/repos/CeTTa/runtime/codex-permissions-access/workspace"))
      (codex:file-system-sandbox-policy-restricted
        ((codex:file-system-sandbox-entry
           (codex:file-system-path-special
             (codex:file-system-special-path-current-working-directory))
           (codex:file-system-access-read)))))
  (True))

!(assertEqualToResult
  (== (codex:file-system-sandbox-policy-with-additional-writable-roots
        (codex:file-system-sandbox-policy-restricted
          ((codex:file-system-sandbox-entry
             (codex:file-system-path-special
               (codex:file-system-special-path-current-working-directory))
             (codex:file-system-access-write))))
        "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-access/workspace"
        ("/home/zarclaw/repos/CeTTa/runtime/codex-permissions-access/workspace"))
      (codex:file-system-sandbox-policy-restricted
        ((codex:file-system-sandbox-entry
           (codex:file-system-path-special
             (codex:file-system-special-path-current-working-directory))
           (codex:file-system-access-write)))))
  (True))

!(assertEqualToResult
  (== (codex:file-system-sandbox-policy-with-additional-writable-roots
        (codex:file-system-sandbox-policy-restricted
          ((codex:file-system-sandbox-entry
             (codex:file-system-path-special
               (codex:file-system-special-path-current-working-directory))
             (codex:file-system-access-write))))
        "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-access/workspace"
        ("/home/zarclaw/repos/CeTTa/runtime/codex-permissions-access/extra"))
      (codex:file-system-sandbox-policy-restricted
        ((codex:file-system-sandbox-entry
           (codex:file-system-path-special
             (codex:file-system-special-path-current-working-directory))
           (codex:file-system-access-write))
         (codex:file-system-sandbox-entry
           (codex:file-system-path-path
             "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-access/extra")
           (codex:file-system-access-write)))))
  (True))
