!(register-module! ../codex)
!(import! &self codex:exec_server_environment)
!(import! &self codex:exec_server_runtime_paths)

(= (test:runtime-paths)
   (codex:exec-server-runtime-paths-result-paths
     (codex:exec-server-runtime-paths-new
       "/usr/local/bin/codex"
       "/usr/local/bin/codex-linux-sandbox")))

!(assertEqual
  (codex:exec-server-url-env-var)
  "CODEX_EXEC_SERVER_URL")

!(assertEqual
  (codex:exec-server-local-environment-id)
  "local")

!(assertEqual
  (codex:exec-server-remote-environment-id)
  "remote")

!(assertEqual
  (codex:exec-server-normalize-exec-server-url CodexAbsent)
  (CodexExecServerNormalizedUrl CodexAbsent False))

!(assertEqual
  (codex:exec-server-normalize-exec-server-url "  ")
  (CodexExecServerNormalizedUrl CodexAbsent False))

!(assertEqual
  (codex:exec-server-normalize-exec-server-url " NoNe ")
  (CodexExecServerNormalizedUrl CodexAbsent True))

!(assertEqual
  (codex:exec-server-normalize-exec-server-url " ws://127.0.0.1:8765 ")
  (CodexExecServerNormalizedUrl "ws://127.0.0.1:8765" False))

!(assertEqual
  (codex:exec-server-environment-is-remote
    (codex:exec-server-environment-create-result-environment
      (codex:exec-server-environment-create
        CodexAbsent
        (test:runtime-paths))))
  False)

!(assertEqual
  (codex:exec-server-environment-local-runtime-paths
    (codex:exec-server-environment-create-result-environment
      (codex:exec-server-environment-create
        CodexAbsent
        (test:runtime-paths))))
  (CodexExecServerRuntimePaths
    "/usr/local/bin/codex"
    "/usr/local/bin/codex-linux-sandbox"))

!(assertEqual
  (codex:exec-server-environment-local-runtime-paths
    (codex:exec-server-environment-create-result-environment
      (codex:exec-server-environment-create-for-tests CodexAbsent)))
  CodexAbsent)

!(assertEqual
  (codex:exec-server-environment-create-result-message
    (codex:exec-server-environment-create-for-tests "none"))
  "disabled mode does not create an Environment")

!(assertEqual
  (codex:exec-server-environment-exec-server-url
    (codex:exec-server-environment-create-result-environment
      (codex:exec-server-environment-create-for-tests
        " ws://127.0.0.1:8765 ")))
  "ws://127.0.0.1:8765")

!(assertEqual
  (codex:exec-server-environment-is-remote
    (codex:exec-server-environment-create-result-environment
      (codex:exec-server-environment-create-for-tests
        " ws://127.0.0.1:8765 ")))
  True)

!(assertEqual
  (codex:exec-server-environment-manager-default-environment-id
    (codex:exec-server-environment-manager-new
      (codex:exec-server-environment-manager-args-from-url
        CodexAbsent
        (test:runtime-paths))))
  "local")

!(assertEqual
  (codex:exec-server-environment-is-remote
    (codex:exec-server-environment-manager-default-environment
      (codex:exec-server-environment-manager-new
        (codex:exec-server-environment-manager-args-from-url
          CodexAbsent
          (test:runtime-paths)))))
  False)

!(assertEqual
  (codex:exec-server-environment-manager-get-environment
    (codex:exec-server-environment-manager-new
      (codex:exec-server-environment-manager-args-from-url
        CodexAbsent
        (test:runtime-paths)))
    "remote")
  CodexAbsent)

!(assertEqual
  (codex:exec-server-environment-manager-default-environment-id
    (codex:exec-server-environment-manager-new
      (codex:exec-server-environment-manager-args-from-url
        " NoNe "
        (test:runtime-paths))))
  CodexAbsent)

!(assertEqual
  (codex:exec-server-environment-manager-default-environment
    (codex:exec-server-environment-manager-new
      (codex:exec-server-environment-manager-args-from-url
        " NoNe "
        (test:runtime-paths))))
  CodexAbsent)

!(assertEqual
  (codex:exec-server-environment-local-runtime-paths
    (codex:exec-server-environment-manager-local-environment
      (codex:exec-server-environment-manager-new
        (codex:exec-server-environment-manager-args-from-url
          " NoNe "
          (test:runtime-paths)))))
  (CodexExecServerRuntimePaths
    "/usr/local/bin/codex"
    "/usr/local/bin/codex-linux-sandbox"))

!(assertEqual
  (codex:exec-server-environment-manager-default-environment-id
    (codex:exec-server-environment-manager-new
      (codex:exec-server-environment-manager-args-from-url
        "ws://127.0.0.1:8765"
        (test:runtime-paths))))
  "remote")

!(assertEqual
  (codex:exec-server-environment-exec-server-url
    (codex:exec-server-environment-manager-default-environment
      (codex:exec-server-environment-manager-new
        (codex:exec-server-environment-manager-args-from-url
          "ws://127.0.0.1:8765"
          (test:runtime-paths)))))
  "ws://127.0.0.1:8765")

!(assertEqual
  (codex:exec-server-environment-is-remote
    (codex:exec-server-environment-manager-get-environment
      (codex:exec-server-environment-manager-new
        (codex:exec-server-environment-manager-args-from-url
          "ws://127.0.0.1:8765"
          (test:runtime-paths)))
      "local"))
  False)

!(assertEqual
  (codex:exec-server-environment-manager-get-environment
    (codex:exec-server-environment-manager-new
      (codex:exec-server-environment-manager-args-from-url
        "ws://127.0.0.1:8765"
        (test:runtime-paths)))
    "missing")
  CodexAbsent)

!(assertEqual
  (codex:exec-server-environment-manager-default-environment-id
    (codex:exec-server-environment-manager-default-for-tests))
  "local")

!(assertEqual
  (codex:exec-server-environment-local-runtime-paths
    (codex:exec-server-environment-manager-default-environment
      (codex:exec-server-environment-manager-default-for-tests)))
  CodexAbsent)
