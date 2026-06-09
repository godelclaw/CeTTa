; Rust-faithful exec-server remote process slice.
;
; This ports deterministic adapter behavior from:
; - openai-codex/codex-rs/exec-server/src/remote_process.rs
;   - RemoteProcess::new
;   - ExecBackend::start client-get/register/exec/unregister-on-error flow
;   - RemoteExecProcess delegated process_id, subscribe_wake,
;     subscribe_events, read, write, terminate behavior
;   - RemoteExecProcess Drop scheduling session unregister
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust owns async clients, `Arc<RemoteExecProcess>`, watch receivers, event
;   receivers, and a spawned unregister task in `Drop`. This pure slice takes
;   symbolic client/register/exec outcomes at that runtime boundary and returns
;   explicit delegation or scheduled-unregister atoms while preserving the
;   branch order and visible parameters.
; - Rust byte vectors may contain arbitrary bytes. This slice uses the current
;   CeTTa text-backed `ByteChunk` representation from the process protocol.

!(import! &self exec_server_process_protocol)

(= (codex:exec-server-remote-process $client)
   (CodexExecServerRemoteProcess $client))

(= (codex:exec-server-remote-process-new $client)
   (CodexExecServerRemoteProcess $client))

(= (codex:exec-server-remote-process-client
      (CodexExecServerRemoteProcess $client))
   $client)

(= (codex:exec-server-remote-process-session
      $process-id
      $wake-receiver
      $event-receiver)
   (CodexExecServerRemoteProcessSession
     $process-id
     $wake-receiver
     $event-receiver))

(= (codex:exec-server-remote-process-session-process-id
      (CodexExecServerRemoteProcessSession
        $process-id
        $wake-receiver
        $event-receiver))
   $process-id)

(= (codex:exec-server-remote-process-session-wake-receiver
      (CodexExecServerRemoteProcessSession
        $process-id
        $wake-receiver
        $event-receiver))
   $wake-receiver)

(= (codex:exec-server-remote-process-session-event-receiver
      (CodexExecServerRemoteProcessSession
        $process-id
        $wake-receiver
        $event-receiver))
   $event-receiver)

(= (codex:exec-server-remote-exec-process $session)
   (CodexExecServerRemoteExecProcess $session))

(= (codex:exec-server-remote-exec-process-session
      (CodexExecServerRemoteExecProcess $session))
   $session)

(= (codex:exec-server-remote-process-client-get-ok $client)
   (CodexExecServerRemoteProcessClientGetOk $client))

(= (codex:exec-server-remote-process-client-get-err $error)
   (CodexExecServerRemoteProcessClientGetErr $error))

(= (codex:exec-server-remote-process-register-ok $session)
   (CodexExecServerRemoteProcessRegisterOk $session))

(= (codex:exec-server-remote-process-register-err $error)
   (CodexExecServerRemoteProcessRegisterErr $error))

(= (codex:exec-server-remote-process-exec-ok $response)
   (CodexExecServerRemoteProcessExecOk $response))

(= (codex:exec-server-remote-process-exec-err $error)
   (CodexExecServerRemoteProcessExecErr $error))

(= (codex:exec-server-remote-process-start-ok
      $process
      $unregistered-session)
   (CodexExecServerRemoteProcessStartOk
     $process
     $unregistered-session))

(= (codex:exec-server-remote-process-start-err
      $error
      $unregistered-session)
   (CodexExecServerRemoteProcessStartErr
     $error
     $unregistered-session))

(= (codex:exec-server-remote-process-start-result-process
      (CodexExecServerRemoteProcessStartOk
        $process
        $unregistered-session))
   $process)

(= (codex:exec-server-remote-process-start-result-error
      (CodexExecServerRemoteProcessStartErr
        $error
        $unregistered-session))
   $error)

(= (codex:exec-server-remote-process-start-result-unregistered-session
      (CodexExecServerRemoteProcessStartOk
        $process
        $unregistered-session))
   $unregistered-session)

(= (codex:exec-server-remote-process-start-result-unregistered-session
      (CodexExecServerRemoteProcessStartErr
        $error
        $unregistered-session))
   $unregistered-session)

(= (codex:exec-server-remote-process-start-flow
      (CodexExecServerRemoteProcess $lazy-client)
      $params
      (CodexExecServerRemoteProcessClientGetErr $error)
      $register-outcome
      $exec-outcome)
   (CodexExecServerRemoteProcessStartErr $error CodexAbsent))

(= (codex:exec-server-remote-process-start-flow
      (CodexExecServerRemoteProcess $lazy-client)
      $params
      (CodexExecServerRemoteProcessClientGetOk $client)
      (CodexExecServerRemoteProcessRegisterErr $error)
      $exec-outcome)
   (CodexExecServerRemoteProcessStartErr $error CodexAbsent))

(= (codex:exec-server-remote-process-start-flow
      (CodexExecServerRemoteProcess $lazy-client)
      $params
      (CodexExecServerRemoteProcessClientGetOk $client)
      (CodexExecServerRemoteProcessRegisterOk $session)
      (CodexExecServerRemoteProcessExecErr $error))
   (CodexExecServerRemoteProcessStartErr $error $session))

(= (codex:exec-server-remote-process-start-flow
      (CodexExecServerRemoteProcess $lazy-client)
      $params
      (CodexExecServerRemoteProcessClientGetOk $client)
      (CodexExecServerRemoteProcessRegisterOk $session)
      (CodexExecServerRemoteProcessExecOk $response))
   (CodexExecServerRemoteProcessStartOk
     (CodexExecServerRemoteExecProcess $session)
     CodexAbsent))

(= (codex:exec-server-remote-process-start-process-id $params)
   (codex:exec-server-exec-params-process-id $params))

(= (codex:exec-server-remote-exec-process-process-id
      (CodexExecServerRemoteExecProcess $session))
   (codex:exec-server-remote-process-session-process-id $session))

(= (codex:exec-server-remote-exec-process-subscribe-wake
      (CodexExecServerRemoteExecProcess $session))
   (codex:exec-server-remote-process-session-wake-receiver $session))

(= (codex:exec-server-remote-exec-process-subscribe-events
      (CodexExecServerRemoteExecProcess $session))
   (codex:exec-server-remote-process-session-event-receiver $session))

(= (codex:exec-server-remote-exec-process-read-params
      (CodexExecServerRemoteExecProcess $session)
      $after-seq
      $max-bytes
      $wait-ms)
   (CodexExecServerReadParams
     (codex:exec-server-remote-process-session-process-id $session)
     $after-seq
     $max-bytes
     $wait-ms))

(= (codex:exec-server-remote-exec-process-read-delegation
      $process
      $after-seq
      $max-bytes
      $wait-ms)
   (CodexExecServerRemoteProcessDelegatedRead
     (codex:exec-server-remote-exec-process-read-params
       $process
       $after-seq
       $max-bytes
       $wait-ms)))

(= (codex:exec-server-remote-exec-process-write-params
      (CodexExecServerRemoteExecProcess $session)
      $chunk)
   (CodexExecServerWriteParams
     (codex:exec-server-remote-process-session-process-id $session)
     (CodexExecServerByteChunk $chunk)))

(= (codex:exec-server-remote-exec-process-write-delegation
      $process
      $chunk)
   (CodexExecServerRemoteProcessDelegatedWrite
     (codex:exec-server-remote-exec-process-write-params
       $process
       $chunk)))

(= (codex:exec-server-remote-exec-process-terminate-params
      (CodexExecServerRemoteExecProcess $session))
   (CodexExecServerTerminateParams
     (codex:exec-server-remote-process-session-process-id $session)))

(= (codex:exec-server-remote-exec-process-terminate-delegation
      $process)
   (CodexExecServerRemoteProcessDelegatedTerminate
     (codex:exec-server-remote-exec-process-terminate-params $process)))

(= (codex:exec-server-remote-exec-process-drop
      (CodexExecServerRemoteExecProcess $session))
   (CodexExecServerRemoteProcessScheduledUnregister $session))
