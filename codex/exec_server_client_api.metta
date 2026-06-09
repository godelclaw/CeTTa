; Rust-faithful exec-server client API slice.
;
; This ports deterministic client API data behavior from:
; - openai-codex/codex-rs/exec-server/src/client_api.rs
;   - ExecServerClientConnectOptions
;   - RemoteExecServerConnectArgs
; - openai-codex/codex-rs/exec-server/src/client.rs
;   - CONNECT_TIMEOUT
;   - INITIALIZE_TIMEOUT
;   - ExecServerClientConnectOptions::default
;   - From<RemoteExecServerConnectArgs> for ExecServerClientConnectOptions
;   - RemoteExecServerConnectArgs::new
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust stores timeouts as `std::time::Duration`. This pure CeTTa slice stores
;   the same values as integer milliseconds because duration objects are a
;   runtime/library boundary not yet represented as a native CeTTa type.

(= (codex:exec-server-client-connect-timeout-ms)
   10000)

(= (codex:exec-server-client-initialize-timeout-ms)
   10000)

(= (codex:exec-server-client-default-client-name)
   "codex-core")

(= (codex:exec-server-client-connect-options
      $client-name
      $initialize-timeout-ms
      $resume-session-id)
   (CodexExecServerClientConnectOptions
     $client-name
     $initialize-timeout-ms
     $resume-session-id))

(= (codex:exec-server-client-connect-options-default)
   (CodexExecServerClientConnectOptions
     (codex:exec-server-client-default-client-name)
     (codex:exec-server-client-initialize-timeout-ms)
     CodexAbsent))

(= (codex:exec-server-client-connect-options-client-name
      (CodexExecServerClientConnectOptions
        $client-name
        $initialize-timeout-ms
        $resume-session-id))
   $client-name)

(= (codex:exec-server-client-connect-options-initialize-timeout-ms
      (CodexExecServerClientConnectOptions
        $client-name
        $initialize-timeout-ms
        $resume-session-id))
   $initialize-timeout-ms)

(= (codex:exec-server-client-connect-options-resume-session-id
      (CodexExecServerClientConnectOptions
        $client-name
        $initialize-timeout-ms
        $resume-session-id))
   $resume-session-id)

(= (codex:exec-server-remote-connect-args
      $websocket-url
      $client-name
      $connect-timeout-ms
      $initialize-timeout-ms
      $resume-session-id)
   (CodexRemoteExecServerConnectArgs
     $websocket-url
     $client-name
     $connect-timeout-ms
     $initialize-timeout-ms
     $resume-session-id))

(= (codex:exec-server-remote-connect-args-new
      $websocket-url
      $client-name)
   (CodexRemoteExecServerConnectArgs
     $websocket-url
     $client-name
     (codex:exec-server-client-connect-timeout-ms)
     (codex:exec-server-client-initialize-timeout-ms)
     CodexAbsent))

(= (codex:exec-server-remote-connect-args-websocket-url
      (CodexRemoteExecServerConnectArgs
        $websocket-url
        $client-name
        $connect-timeout-ms
        $initialize-timeout-ms
        $resume-session-id))
   $websocket-url)

(= (codex:exec-server-remote-connect-args-client-name
      (CodexRemoteExecServerConnectArgs
        $websocket-url
        $client-name
        $connect-timeout-ms
        $initialize-timeout-ms
        $resume-session-id))
   $client-name)

(= (codex:exec-server-remote-connect-args-connect-timeout-ms
      (CodexRemoteExecServerConnectArgs
        $websocket-url
        $client-name
        $connect-timeout-ms
        $initialize-timeout-ms
        $resume-session-id))
   $connect-timeout-ms)

(= (codex:exec-server-remote-connect-args-initialize-timeout-ms
      (CodexRemoteExecServerConnectArgs
        $websocket-url
        $client-name
        $connect-timeout-ms
        $initialize-timeout-ms
        $resume-session-id))
   $initialize-timeout-ms)

(= (codex:exec-server-remote-connect-args-resume-session-id
      (CodexRemoteExecServerConnectArgs
        $websocket-url
        $client-name
        $connect-timeout-ms
        $initialize-timeout-ms
        $resume-session-id))
   $resume-session-id)

(= (codex:exec-server-client-connect-options-from-remote-args
      (CodexRemoteExecServerConnectArgs
        $websocket-url
        $client-name
        $connect-timeout-ms
        $initialize-timeout-ms
        $resume-session-id))
   (CodexExecServerClientConnectOptions
     $client-name
     $initialize-timeout-ms
     $resume-session-id))
