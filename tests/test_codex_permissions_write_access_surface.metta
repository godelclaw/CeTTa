!(register-module! ../codex)
!(import! &self codex:permissions)

!(assertEqualToResult
  (== (codex:file-system-sandbox-policy-has-full-disk-write-access
        (codex:file-system-sandbox-policy-restricted
          ((codex:file-system-sandbox-entry
             (codex:file-system-path-special
               (codex:file-system-special-path-root))
             (codex:file-system-access-write))
           (codex:file-system-sandbox-entry
             (codex:file-system-path-path "/repo")
             (codex:file-system-access-read)))))
      False)
  (True))

!(assertEqualToResult
  (== (codex:file-system-sandbox-policy-has-full-disk-write-access
        (codex:file-system-sandbox-policy-restricted
          ((codex:file-system-sandbox-entry
             (codex:file-system-path-special
               (codex:file-system-special-path-root))
             (codex:file-system-access-write))
           (codex:file-system-sandbox-entry
             (codex:file-system-path-path "/repo")
             (codex:file-system-access-read))
           (codex:file-system-sandbox-entry
             (codex:file-system-path-path "/repo")
             (codex:file-system-access-write)))))
      True)
  (True))

!(assertEqualToResult
  (== (codex:file-system-sandbox-policy-has-full-disk-write-access
        (codex:file-system-sandbox-policy-restricted
          ((codex:file-system-sandbox-entry
             (codex:file-system-path-special
               (codex:file-system-special-path-root))
             (codex:file-system-access-write))
           (codex:file-system-sandbox-entry
             (codex:file-system-path-special
               (codex:file-system-special-path-root))
             (codex:file-system-access-read)))))
      True)
  (True))
