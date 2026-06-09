!(register-module! ../codex)
!(import! &self codex:exec_server_client_api)

(= (test:client-api-remote-new)
   (codex:exec-server-remote-connect-args-new
     "ws://127.0.0.1:3000/exec"
     "codex-core"))

(= (test:client-api-remote-custom)
   (codex:exec-server-remote-connect-args
     "ws://127.0.0.1:4000/exec"
     "codex-resume"
     2500
     7500
     "session-1"))

!(assertEqual
  (codex:exec-server-client-connect-timeout-ms)
  10000)

!(assertEqual
  (codex:exec-server-client-initialize-timeout-ms)
  10000)

!(assertEqual
  (codex:exec-server-client-connect-options-default)
  (CodexExecServerClientConnectOptions
    "codex-core"
    10000
    CodexAbsent))

!(assertEqual
  (codex:exec-server-remote-connect-args-websocket-url
    (test:client-api-remote-new))
  "ws://127.0.0.1:3000/exec")

!(assertEqual
  (codex:exec-server-remote-connect-args-client-name
    (test:client-api-remote-new))
  "codex-core")

!(assertEqual
  (codex:exec-server-remote-connect-args-connect-timeout-ms
    (test:client-api-remote-new))
  10000)

!(assertEqual
  (codex:exec-server-remote-connect-args-initialize-timeout-ms
    (test:client-api-remote-new))
  10000)

!(assertEqual
  (codex:exec-server-remote-connect-args-resume-session-id
    (test:client-api-remote-new))
  CodexAbsent)

!(assertEqual
  (codex:exec-server-client-connect-options-from-remote-args
    (test:client-api-remote-custom))
  (CodexExecServerClientConnectOptions
    "codex-resume"
    7500
    "session-1"))
