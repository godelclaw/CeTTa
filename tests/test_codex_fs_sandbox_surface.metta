!(register-module! ../codex)
!(import! &self codex:fs_sandbox)
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
