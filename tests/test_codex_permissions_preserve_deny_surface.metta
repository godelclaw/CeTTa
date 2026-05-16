!(register-module! ../codex)
!(import! &self codex:permissions)

!(assertEqualToResult
  (== (codex:file-system-sandbox-policy-preserve-deny-read-restrictions-from
        (codex:file-system-sandbox-policy-unrestricted)
        (codex:file-system-sandbox-policy
          (codex:file-system-sandbox-kind-restricted)
          2
          ((codex:file-system-sandbox-entry
             (codex:file-system-path-glob-pattern "/tmp/project/**/*.env")
             (codex:file-system-access-none)))))
      (codex:file-system-sandbox-policy
        (codex:file-system-sandbox-kind-restricted)
        2
        ((codex:file-system-sandbox-entry
           (codex:file-system-path-special
             (codex:file-system-special-path-root))
           (codex:file-system-access-write))
         (codex:file-system-sandbox-entry
           (codex:file-system-path-glob-pattern "/tmp/project/**/*.env")
           (codex:file-system-access-none)))))
  (True))

!(assertEqualToResult
  (== (codex:file-system-sandbox-policy-preserve-deny-read-restrictions-from
        (codex:file-system-sandbox-policy-restricted
          ((codex:file-system-sandbox-entry
             (codex:file-system-path-path "/repo")
             (codex:file-system-access-read))))
        (codex:file-system-sandbox-policy
          (codex:file-system-sandbox-kind-restricted)
          3
          ((codex:file-system-sandbox-entry
             (codex:file-system-path-path "/tmp/private")
             (codex:file-system-access-none)))))
      (codex:file-system-sandbox-policy
        (codex:file-system-sandbox-kind-restricted)
        3
        ((codex:file-system-sandbox-entry
           (codex:file-system-path-path "/repo")
           (codex:file-system-access-read))
         (codex:file-system-sandbox-entry
           (codex:file-system-path-path "/tmp/private")
           (codex:file-system-access-none)))))
  (True))

!(assertEqualToResult
  (== (codex:file-system-sandbox-policy-preserve-deny-read-restrictions-from
        (codex:file-system-sandbox-policy
          (codex:file-system-sandbox-kind-restricted)
          5
          ((codex:file-system-sandbox-entry
             (codex:file-system-path-path "/tmp/private")
             (codex:file-system-access-none))))
        (codex:file-system-sandbox-policy
          (codex:file-system-sandbox-kind-restricted)
          3
          ((codex:file-system-sandbox-entry
             (codex:file-system-path-path "/tmp/private")
             (codex:file-system-access-none)))))
      (codex:file-system-sandbox-policy
        (codex:file-system-sandbox-kind-restricted)
        5
        ((codex:file-system-sandbox-entry
           (codex:file-system-path-path "/tmp/private")
           (codex:file-system-access-none)))))
  (True))
