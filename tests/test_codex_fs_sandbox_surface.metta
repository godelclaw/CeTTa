!(register-module! ../codex)
!(import! &self codex:fs_sandbox)
!(import! &self codex:permissions)
!(import! &self codex:unified_exec_env)

(= (test:fs-helper-vars)
   ((codex:unified-exec-env-var "PATH" "/bin")
    (codex:unified-exec-env-var "HOME" "/home/user")
    (codex:unified-exec-env-var "TMPDIR" "/tmpdir")
    (codex:unified-exec-env-var "CODEX_TOKEN" "secret")
    (codex:unified-exec-env-var "PATH" "/usr/bin")))

!(assertEqual
  (codex:fs-helper-env-allowlist)
  ("PATH" "TMPDIR" "TMP" "TEMP"))

!(assertEqual
  (codex:fs-helper-env-key-allowed "PATH")
  True)

!(assertEqual
  (codex:fs-helper-env-key-allowed "TMPDIR")
  True)

!(assertEqual
  (codex:fs-helper-env-key-allowed "TMP")
  True)

!(assertEqual
  (codex:fs-helper-env-key-allowed "TEMP")
  True)

!(assertEqual
  (codex:fs-helper-env-key-allowed "HOME")
  False)

!(assertEqual
  (codex:fs-helper-env-key-allowed "CODEX_TOKEN")
  False)

!(assertEqual
  (codex:fs-helper-env-key-allowed "Path")
  False)

!(assertEqual
  (codex:fs-helper-env-key-allowed-on-platform True "Path")
  True)

!(assertEqual
  (codex:fs-helper-env-key-allowed-on-platform True "PaTh")
  True)

!(assertEqual
  (codex:fs-helper-env-key-allowed-on-platform False "PaTh")
  False)

!(assertEqual
  (codex:unified-exec-env-get
    (codex:fs-helper-env-from-vars (test:fs-helper-vars))
    "PATH")
  "/usr/bin")

!(assertEqual
  (codex:unified-exec-env-get
    (codex:fs-helper-env-from-vars (test:fs-helper-vars))
    "TMPDIR")
  "/tmpdir")

!(assertEqual
  (codex:unified-exec-env-get
    (codex:fs-helper-env-from-vars (test:fs-helper-vars))
    "HOME")
  CodexAbsent)

!(assertEqual
  (codex:unified-exec-env-get
    (codex:fs-helper-env-from-vars (test:fs-helper-vars))
    "CODEX_TOKEN")
  CodexAbsent)

!(assertEqual
  (codex:unified-exec-env-get
    (codex:fs-helper-env-from-vars-on-platform
      True
      ((codex:unified-exec-env-var "Path" "C:\\Windows")
       (codex:unified-exec-env-var "HOME" "C:\\Users\\codex")))
    "Path")
  "C:\\Windows")

!(assertEqual
  (codex:fs-sandbox-helper-read-roots
    (codex:fs-sandbox-runtime-paths
      "/opt/codex/bin/codex"
      CodexAbsent))
  ("/opt/codex/bin"))

!(assertEqual
  (codex:fs-sandbox-helper-read-roots
    (codex:fs-sandbox-runtime-paths
      "/opt/codex/bin/codex"
      "/opt/codex/aliases/codex-linux-sandbox"))
  ("/opt/codex/bin" "/opt/codex/aliases"))

!(assertEqual
  (codex:fs-sandbox-helper-read-roots
    (codex:fs-sandbox-runtime-paths
      "/opt/codex/bin/codex"
      "/opt/codex/bin/codex-linux-sandbox"))
  ("/opt/codex/bin"))

!(assertEqual
  (codex:file-system-sandbox-policy-include-platform-defaults
    (codex:fs-sandbox-add-helper-runtime-permissions
      (codex:file-system-sandbox-policy-restricted ())
      ()
      "/workspace"))
  True)

!(assertEqual
  (codex:fs-sandbox-add-helper-runtime-permissions
    (codex:file-system-sandbox-policy-restricted
      ((codex:fs-sandbox-minimal-read-entry)))
    ()
    "/workspace")
  (codex:file-system-sandbox-policy-restricted
    ((codex:fs-sandbox-minimal-read-entry))))

!(assertEqual
  (let $policy
    (codex:fs-sandbox-add-helper-runtime-permissions
      (codex:file-system-sandbox-policy-restricted
        ((codex:file-system-sandbox-entry
           (codex:file-system-path-path "/workspace/writable")
           (codex:file-system-access-write))))
      ("/opt/codex/bin")
      "/workspace")
    (and
      (codex:file-system-sandbox-policy-can-read-path-with-cwd
        $policy
        "/opt/codex/bin/codex"
        "/workspace")
      (codex:file-system-sandbox-policy-can-write-path-with-cwd
        $policy
        "/workspace/writable"
        "/workspace")))
  True)

!(assertEqual
  (codex:fs-sandbox-add-helper-runtime-permissions
    (codex:file-system-sandbox-policy-restricted
      ((codex:file-system-sandbox-entry
         (codex:file-system-path-special
           (codex:file-system-special-path-root))
         (codex:file-system-access-read))))
    ("/opt/codex/bin")
    "/workspace")
  (codex:file-system-sandbox-policy-restricted
    ((codex:file-system-sandbox-entry
       (codex:file-system-path-special
         (codex:file-system-special-path-root))
       (codex:file-system-access-read)))))

!(assertEqual
  (let $policy
    (codex:fs-sandbox-add-helper-runtime-permissions
      (codex:file-system-sandbox-policy-restricted ())
      ("/opt/codex/bin" "/opt/codex/aliases")
      "/workspace")
    (and
      (codex:file-system-sandbox-policy-can-read-path-with-cwd
        $policy
        "/opt/codex/bin/codex"
        "/workspace")
      (codex:file-system-sandbox-policy-can-read-path-with-cwd
        $policy
        "/opt/codex/aliases/codex-linux-sandbox"
        "/workspace")))
  True)
