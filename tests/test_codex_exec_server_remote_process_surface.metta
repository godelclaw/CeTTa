!(register-module! ../codex)
!(import! &self codex:exec_server_process_id)
!(import! &self codex:exec_server_process_protocol)
!(import! &self codex:exec_server_remote_process)

(= (test:remote-process-id)
   (codex:exec-server-process-id-new "proc-1"))

(= (test:remote-process-params)
   (codex:exec-server-exec-params
     (test:remote-process-id)
     ("sh" "-lc" "echo hi")
     "/workspace"
     CodexAbsent
     ()
     False
     False
     CodexAbsent))

(= (test:remote-process-session)
   (codex:exec-server-remote-process-session
     (test:remote-process-id)
     (CodexWakeReceiver "wake-1")
     (CodexEventReceiver "events-1")))

(= (test:remote-process)
   (codex:exec-server-remote-exec-process
     (test:remote-process-session)))

!(assertEqual
  (codex:exec-server-remote-process-client
    (codex:exec-server-remote-process-new
      (CodexLazyRemoteClient "ws://example.test")))
  (CodexLazyRemoteClient "ws://example.test"))

!(assertEqual
  (codex:exec-server-remote-process-start-process-id
    (test:remote-process-params))
  (test:remote-process-id))

!(assertEqual
  (codex:exec-server-remote-process-start-result-unregistered-session
    (codex:exec-server-remote-process-start-flow
      (codex:exec-server-remote-process-new (CodexLazyRemoteClient))
      (test:remote-process-params)
      (codex:exec-server-remote-process-client-get-err
        (CodexExecServerClientErrorClosed))
      (codex:exec-server-remote-process-register-ok
        (test:remote-process-session))
      (codex:exec-server-remote-process-exec-ok
        (CodexExecServerExecResponse (test:remote-process-id)))))
  CodexAbsent)

!(assertEqual
  (codex:exec-server-remote-process-start-result-error
    (codex:exec-server-remote-process-start-flow
      (codex:exec-server-remote-process-new (CodexLazyRemoteClient))
      (test:remote-process-params)
      (codex:exec-server-remote-process-client-get-ok
        (CodexRemoteClient))
      (codex:exec-server-remote-process-register-err
        (CodexExecServerClientErrorProtocol "duplicate session"))
      (codex:exec-server-remote-process-exec-ok
        (CodexExecServerExecResponse (test:remote-process-id)))))
  (CodexExecServerClientErrorProtocol "duplicate session"))

!(assertEqual
  (codex:exec-server-remote-process-start-result-unregistered-session
    (codex:exec-server-remote-process-start-flow
      (codex:exec-server-remote-process-new (CodexLazyRemoteClient))
      (test:remote-process-params)
      (codex:exec-server-remote-process-client-get-ok
        (CodexRemoteClient))
      (codex:exec-server-remote-process-register-ok
        (test:remote-process-session))
      (codex:exec-server-remote-process-exec-err
        (CodexExecServerClientErrorServer -32603 "exec failed"))))
  (test:remote-process-session))

!(assertEqual
  (codex:exec-server-remote-exec-process-session
    (codex:exec-server-remote-process-start-result-process
      (codex:exec-server-remote-process-start-flow
        (codex:exec-server-remote-process-new (CodexLazyRemoteClient))
        (test:remote-process-params)
        (codex:exec-server-remote-process-client-get-ok
          (CodexRemoteClient))
        (codex:exec-server-remote-process-register-ok
          (test:remote-process-session))
        (codex:exec-server-remote-process-exec-ok
          (CodexExecServerExecResponse (test:remote-process-id))))))
  (test:remote-process-session))

!(assertEqual
  (codex:exec-server-remote-exec-process-process-id
    (test:remote-process))
  (test:remote-process-id))

!(assertEqual
  (codex:exec-server-remote-exec-process-subscribe-wake
    (test:remote-process))
  (CodexWakeReceiver "wake-1"))

!(assertEqual
  (codex:exec-server-remote-exec-process-subscribe-events
    (test:remote-process))
  (CodexEventReceiver "events-1"))

!(assertEqual
  (codex:exec-server-remote-exec-process-read-delegation
    (test:remote-process)
    1
    4096
    50)
  (CodexExecServerRemoteProcessDelegatedRead
    (CodexExecServerReadParams
      (test:remote-process-id)
      1
      4096
      50)))

!(assertEqual
  (codex:exec-server-remote-exec-process-write-delegation
    (test:remote-process)
    "hello")
  (CodexExecServerRemoteProcessDelegatedWrite
    (CodexExecServerWriteParams
      (test:remote-process-id)
      (CodexExecServerByteChunk "hello"))))

!(assertEqual
  (codex:exec-server-remote-exec-process-terminate-delegation
    (test:remote-process))
  (CodexExecServerRemoteProcessDelegatedTerminate
    (CodexExecServerTerminateParams
      (test:remote-process-id))))

!(assertEqual
  (codex:exec-server-remote-exec-process-drop
    (test:remote-process))
  (CodexExecServerRemoteProcessScheduledUnregister
    (test:remote-process-session)))
