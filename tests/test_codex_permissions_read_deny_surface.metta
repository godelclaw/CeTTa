!(register-module! ../codex)
!(import! &self codex:permissions)
!(import! &self codex:permissions_read_deny)
!(import! &self process)

(= (codex-prd-root)
   "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny")

!(assertEqualToResult
  (process-result-exit-code
    (process-run-shell
      "rm -rf /home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny && mkdir -p /home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/denied /home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/real /home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/private /home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/app/nested && ln -s /home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/real /home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/alias && printf secret > /home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/denied/nested.txt && printf secret > /home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/real/secret.txt && printf secret > /home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/private/secret1.txt && printf secret > /home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/.env && printf secret > /home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/app/.env && printf secret > /home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/app/file42.txt && printf secret > /home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/app/nested/file42.txt && printf secret > '/home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/[' && printf notes > /home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/notes.txt"))
  (0))

!(assertEqualToResult
  (== (codex:read-deny-matcher-new
        (codex:file-system-sandbox-policy-unrestricted)
        (codex-prd-root))
      CodexAbsent)
  (True))

!(assertEqualToResult
  (== (codex:file-system-sandbox-policy-is-read-denied-with-cwd
        (codex:file-system-sandbox-policy-restricted
          ((codex:file-system-sandbox-entry
             (codex:file-system-path-path
               "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/denied")
             (codex:file-system-access-none))))
        "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/denied"
        (codex-prd-root))
      True)
  (True))

!(assertEqualToResult
  (== (codex:file-system-sandbox-policy-is-read-denied-with-cwd
        (codex:file-system-sandbox-policy-restricted
          ((codex:file-system-sandbox-entry
             (codex:file-system-path-path
               "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/denied")
             (codex:file-system-access-none))))
        "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/denied/nested.txt"
        (codex-prd-root))
      True)
  (True))

!(assertEqualToResult
  (== (codex:file-system-sandbox-policy-is-read-denied-with-cwd
        (codex:file-system-sandbox-policy-restricted
          ((codex:file-system-sandbox-entry
             (codex:file-system-path-path
               "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/denied")
             (codex:file-system-access-none))))
        "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/other.txt"
        (codex-prd-root))
      False)
  (True))

!(assertEqualToResult
  (== (codex:file-system-sandbox-policy-is-read-denied-with-cwd
        (codex:file-system-sandbox-policy-restricted
          ((codex:file-system-sandbox-entry
             (codex:file-system-path-path
               "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/real")
             (codex:file-system-access-none))))
        "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/alias/secret.txt"
        (codex-prd-root))
      True)
  (True))

!(assertEqualToResult
  (== (codex:file-system-sandbox-policy-is-read-denied-with-cwd
        (codex:file-system-sandbox-policy-restricted
          ((codex:file-system-sandbox-entry
             (codex:file-system-path-glob-pattern
               "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/private/secret?.txt")
             (codex:file-system-access-none))))
        "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/private/secret1.txt"
        (codex-prd-root))
      True)
  (True))

!(assertEqualToResult
  (== (codex:file-system-sandbox-policy-is-read-denied-with-cwd
        (codex:file-system-sandbox-policy-restricted
          ((codex:file-system-sandbox-entry
             (codex:file-system-path-glob-pattern
               "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/*/file[0-9]?.txt")
             (codex:file-system-access-none))))
        "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/app/file42.txt"
        (codex-prd-root))
      True)
  (True))

!(assertEqualToResult
  (== (codex:file-system-sandbox-policy-is-read-denied-with-cwd
        (codex:file-system-sandbox-policy-restricted
          ((codex:file-system-sandbox-entry
             (codex:file-system-path-glob-pattern
               "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/*/file[0-9]?.txt")
             (codex:file-system-access-none))))
        "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/app/nested/file42.txt"
        (codex-prd-root))
      False)
  (True))

!(assertEqualToResult
  (== (codex:file-system-sandbox-policy-is-read-denied-with-cwd
        (codex:file-system-sandbox-policy-restricted
          ((codex:file-system-sandbox-entry
             (codex:file-system-path-glob-pattern
               "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/**/*.env")
             (codex:file-system-access-none))))
        "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/.env"
        (codex-prd-root))
      True)
  (True))

!(assertEqualToResult
  (== (codex:file-system-sandbox-policy-is-read-denied-with-cwd
        (codex:file-system-sandbox-policy-restricted
          ((codex:file-system-sandbox-entry
             (codex:file-system-path-glob-pattern
               "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/**/*.env")
             (codex:file-system-access-none))))
        "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/app/.env"
        (codex-prd-root))
      True)
  (True))

!(assertEqualToResult
  (== (codex:file-system-sandbox-policy-is-read-denied-with-cwd
        (codex:file-system-sandbox-policy-restricted
          ((codex:file-system-sandbox-entry
             (codex:file-system-path-glob-pattern
               "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/[")
             (codex:file-system-access-none))))
        "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/["
        (codex-prd-root))
      True)
  (True))

!(assertEqualToResult
  (== (codex:file-system-sandbox-policy-is-read-denied-with-cwd
        (codex:file-system-sandbox-policy-restricted
          ((codex:file-system-sandbox-entry
             (codex:file-system-path-glob-pattern
               "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/[")
             (codex:file-system-access-none))))
        "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-read-deny/notes.txt"
        (codex-prd-root))
      False)
  (True))
