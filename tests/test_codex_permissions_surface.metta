!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:permissions)

!(assertEqualToResult
  (json-stringify
    (codex:network-sandbox-policy-json
      (codex:network-sandbox-policy-restricted)))
  ("\"restricted\""))

!(assertEqualToResult
  (== (codex:network-sandbox-policy-is-enabled
        (codex:network-sandbox-policy-enabled))
      True)
  (True))

!(assertEqualToResult
  (== (codex:file-system-access-mode-can-read
        (codex:file-system-access-none))
      False)
  (True))

!(assertEqualToResult
  (== (codex:file-system-access-mode-can-write
        (codex:file-system-access-write))
      True)
  (True))

!(assertEqualToResult
  (json-stringify
    (codex:file-system-special-path-json
      (codex:file-system-special-path-project-roots CodexAbsent)))
  ("{\"kind\":\"project_roots\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:file-system-special-path-json
      (codex:file-system-special-path-unknown
        ":future_special_path"
        "subdir")))
  ("{\"kind\":\"unknown\",\"path\":\":future_special_path\",\"subpath\":\"subdir\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:file-system-path-json
      (codex:file-system-path-special
        (codex:file-system-special-path-slash-tmp))))
  ("{\"type\":\"special\",\"value\":{\"kind\":\"slash_tmp\"}}"))

!(assertEqualToResult
  (json-stringify
    (codex:file-system-sandbox-entry-json
      (codex:file-system-sandbox-entry
        (codex:file-system-path-path "/repo")
        (codex:file-system-access-read))))
  ("{\"path\":{\"type\":\"path\",\"path\":\"/repo\"},\"access\":\"read\"}"))

!(assertEqualToResult
  (== (codex:file-system-sandbox-policy-default)
      (codex:file-system-sandbox-policy
        (codex:file-system-sandbox-kind-restricted)
        CodexAbsent
        ((codex:file-system-sandbox-entry
           (codex:file-system-path-special
             (codex:file-system-special-path-root))
           (codex:file-system-access-read)))))
  (True))

!(assertEqualToResult
  (json-stringify
    (codex:file-system-sandbox-policy-json
      (codex:file-system-sandbox-policy-default)))
  ("{\"kind\":\"restricted\",\"entries\":[{\"path\":{\"type\":\"special\",\"value\":{\"kind\":\"root\"}},\"access\":\"read\"}]}"))

!(assertEqualToResult
  (json-stringify
    (codex:file-system-sandbox-policy-json
        (codex:file-system-sandbox-policy
          (codex:file-system-sandbox-kind-restricted)
          3
          ((codex:file-system-sandbox-entry
           (codex:file-system-path-glob-pattern "**/*.secret")
           (codex:file-system-access-none))))))
  ("{\"kind\":\"restricted\",\"glob_scan_max_depth\":3,\"entries\":[{\"path\":{\"type\":\"glob_pattern\",\"pattern\":\"**/*.secret\"},\"access\":\"none\"}]}"))

!(assertEqualToResult
  (== (codex:file-system-sandbox-policy-has-denied-read-restrictions
        (codex:file-system-sandbox-policy-restricted
          ((codex:file-system-sandbox-entry
             (codex:file-system-path-glob-pattern "**/*.secret")
             (codex:file-system-access-none)))))
      True)
  (True))

!(assertEqualToResult
  (== (codex:file-system-sandbox-policy-has-full-disk-read-access
        (codex:file-system-sandbox-policy-unrestricted))
      True)
  (True))

!(assertEqualToResult
  (== (codex:file-system-sandbox-policy-has-full-disk-read-access
        (codex:file-system-sandbox-policy-restricted
          ((codex:file-system-sandbox-entry
             (codex:file-system-path-special
               (codex:file-system-special-path-root))
             (codex:file-system-access-read)))))
      True)
  (True))

!(assertEqualToResult
  (== (codex:file-system-sandbox-policy-has-full-disk-read-access
        (codex:file-system-sandbox-policy-restricted
          ((codex:file-system-sandbox-entry
             (codex:file-system-path-special
               (codex:file-system-special-path-root))
             (codex:file-system-access-read))
           (codex:file-system-sandbox-entry
             (codex:file-system-path-path "/repo/private")
             (codex:file-system-access-none)))))
      False)
  (True))

!(assertEqualToResult
  (== (codex:file-system-sandbox-policy-has-full-disk-write-access
        (codex:file-system-sandbox-policy-restricted
          ((codex:file-system-sandbox-entry
             (codex:file-system-path-special
               (codex:file-system-special-path-root))
             (codex:file-system-access-write)))))
      True)
  (True))

!(assertEqualToResult
  (== (codex:file-system-sandbox-policy-include-platform-defaults
        (codex:file-system-sandbox-policy-restricted
          ((codex:file-system-sandbox-entry
             (codex:file-system-path-special
               (codex:file-system-special-path-minimal))
             (codex:file-system-access-read)))))
      True)
  (True))

!(assertEqualToResult
  (== (codex:file-system-sandbox-policy-include-platform-defaults
        (codex:file-system-sandbox-policy-restricted
          ((codex:file-system-sandbox-entry
             (codex:file-system-path-special
               (codex:file-system-special-path-root))
             (codex:file-system-access-read))
           (codex:file-system-sandbox-entry
             (codex:file-system-path-special
               (codex:file-system-special-path-minimal))
             (codex:file-system-access-read)))))
      False)
  (True))
