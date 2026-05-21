!(register-module! ../codex)
!(import! &self codex:exec_server_runtime_paths)

!(assertEqual
  (codex:exec-server-runtime-paths-result-paths
    (codex:exec-server-runtime-paths-new
      "/usr/local/bin/codex"
      CodexAbsent))
  (CodexExecServerRuntimePaths
    "/usr/local/bin/codex"
    CodexAbsent))

!(assertEqual
  (codex:exec-server-runtime-paths-codex-self-exe
    (codex:exec-server-runtime-paths-result-paths
      (codex:exec-server-runtime-paths-new
        "/usr/local/bin/codex"
        "/usr/local/bin/codex-linux-sandbox")))
  "/usr/local/bin/codex")

!(assertEqual
  (codex:exec-server-runtime-paths-codex-linux-sandbox-exe
    (codex:exec-server-runtime-paths-result-paths
      (codex:exec-server-runtime-paths-new
        "/usr/local/bin/codex"
        "/usr/local/bin/codex-linux-sandbox")))
  "/usr/local/bin/codex-linux-sandbox")

!(assertEqual
  (codex:exec-server-runtime-paths-result-message
    (codex:exec-server-runtime-paths-from-optional-paths
      CodexAbsent
      "/usr/local/bin/codex-linux-sandbox"))
  "Codex executable path is not configured")

!(assertEqual
  (codex:exec-server-runtime-paths-result-message
    (codex:exec-server-runtime-paths-new
      "codex"
      CodexAbsent))
  "path is not absolute: codex")

!(assertEqual
  (codex:exec-server-runtime-paths-result-message
    (codex:exec-server-runtime-paths-new
      "/usr/local/bin/codex"
      "codex-linux-sandbox"))
  "path is not absolute: codex-linux-sandbox")

!(assertEqual
  (codex:exec-server-runtime-paths-result-paths
    (codex:exec-server-runtime-paths-from-optional-paths
      "/opt/codex/bin/codex"
      CodexAbsent))
  (CodexExecServerRuntimePaths
    "/opt/codex/bin/codex"
    CodexAbsent))
