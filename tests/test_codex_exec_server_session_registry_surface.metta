!(register-module! ../codex)
!(import! &self codex:exec_server_rpc)
!(import! &self codex:exec_server_session_registry)

(= (test:session-registry-new-attach)
   (codex:exec-server-session-registry-attach
     (codex:exec-server-session-registry-new)
     CodexAbsent
     "notifications-a"
     "session-1"
     "connection-1"
     100))

(= (test:session-registry-after-new-attach)
   (codex:exec-server-session-registry-attach-result-registry
     (test:session-registry-new-attach)))

(= (test:session-registry-new-handle)
   (codex:exec-server-session-registry-attach-result-handle
     (test:session-registry-new-attach)))

(= (test:session-registry-entry $registry $session-id)
   (codex:exec-server-session-registry-lookup-result-entry
     (codex:exec-server-session-registry-lookup-session
       (codex:exec-server-session-registry-sessions $registry)
       $session-id)))

(= (test:session-registry-detached)
   (codex:exec-server-session-registry-detach
     (test:session-registry-after-new-attach)
     (test:session-registry-new-handle)
     100))

(= (test:session-registry-after-detach)
   (codex:exec-server-session-registry-detach-result-registry
     (test:session-registry-detached)))

(= (test:session-registry-resumed)
   (codex:exec-server-session-registry-attach
     (test:session-registry-after-detach)
     "session-1"
     "notifications-b"
     "unused-new-session"
     "connection-2"
     200))

(= (test:session-registry-after-resume)
   (codex:exec-server-session-registry-attach-result-registry
     (test:session-registry-resumed)))

(= (test:session-registry-resumed-handle)
   (codex:exec-server-session-registry-attach-result-handle
     (test:session-registry-resumed)))

!(assertEqual
  (codex:exec-server-session-registry-detached-session-ttl-ms)
  10000)

!(assertEqual
  (codex:exec-server-session-registry-test-detached-session-ttl-ms)
  200)

!(assertEqual
  (codex:exec-server-session-registry-session-count
    (codex:exec-server-session-registry-new))
  0)

!(assertEqual
  (test:session-registry-new-handle)
  (CodexExecServerSessionHandle "session-1" "connection-1"))

!(assertEqual
  (codex:exec-server-session-registry-session-count
    (test:session-registry-after-new-attach))
  1)

!(assertEqual
  (codex:exec-server-session-process-handler-notification-sender
    (codex:exec-server-session-entry-process
      (test:session-registry-entry
        (test:session-registry-after-new-attach)
        "session-1")))
  "notifications-a")

!(assertEqual
  (codex:exec-server-session-entry-has-active-connection
    (test:session-registry-entry
      (test:session-registry-after-new-attach)
      "session-1"))
  True)

!(assertEqual
  (codex:exec-server-session-registry-handle-is-session-attached
    (test:session-registry-after-new-attach)
    (test:session-registry-new-handle))
  True)

!(assertEqual
  (codex:exec-server-session-registry-attach-result-error
    (codex:exec-server-session-registry-attach
      (test:session-registry-after-new-attach)
      "session-1"
      "notifications-b"
      "unused-new-session"
      "connection-2"
      150))
  (CodexExecServerRpcErrorError
    -32600
    CodexAbsent
    "session session-1 is already attached to another connection"))

!(assertEqual
  (codex:exec-server-session-registry-detach-result-detached
    (test:session-registry-detached))
  True)

!(assertEqual
  (codex:exec-server-session-registry-handle-is-session-attached
    (test:session-registry-after-detach)
    (test:session-registry-new-handle))
  False)

!(assertEqual
  (codex:exec-server-session-process-handler-notification-sender
    (codex:exec-server-session-entry-process
      (test:session-registry-entry
        (test:session-registry-after-detach)
        "session-1")))
  CodexAbsent)

!(assertEqual
  (codex:exec-server-session-attachment-detached-connection-id
    (codex:exec-server-session-entry-attachment
      (test:session-registry-entry
        (test:session-registry-after-detach)
        "session-1")))
  "connection-1")

!(assertEqual
  (codex:exec-server-session-attachment-detached-expires-at-ms
    (codex:exec-server-session-entry-attachment
      (test:session-registry-entry
        (test:session-registry-after-detach)
        "session-1")))
  10100)

!(assertEqual
  (test:session-registry-resumed-handle)
  (CodexExecServerSessionHandle "session-1" "connection-2"))

!(assertEqual
  (codex:exec-server-session-process-handler-notification-sender
    (codex:exec-server-session-entry-process
      (test:session-registry-entry
        (test:session-registry-after-resume)
        "session-1")))
  "notifications-b")

!(assertEqual
  (codex:exec-server-session-attachment-current-connection-id
    (codex:exec-server-session-entry-attachment
      (test:session-registry-entry
        (test:session-registry-after-resume)
        "session-1")))
  "connection-2")

!(assertEqual
  (codex:exec-server-session-attachment-detached-connection-id
    (codex:exec-server-session-entry-attachment
      (test:session-registry-entry
        (test:session-registry-after-resume)
        "session-1")))
  CodexAbsent)

!(assertEqual
  (codex:exec-server-session-registry-detach-result-detached
    (codex:exec-server-session-registry-detach
      (test:session-registry-after-resume)
      (test:session-registry-new-handle)
      250))
  False)

!(assertEqual
  (codex:exec-server-session-attachment-current-connection-id
    (codex:exec-server-session-entry-attachment
      (test:session-registry-entry
        (codex:exec-server-session-registry-detach-result-registry
          (codex:exec-server-session-registry-detach
            (test:session-registry-after-resume)
            (test:session-registry-new-handle)
            250))
        "session-1")))
  "connection-2")

!(assertEqual
  (codex:exec-server-session-registry-expire-result-removed
    (codex:exec-server-session-registry-expire-if-detached
      (codex:exec-server-session-registry-detach-result-registry
        (codex:exec-server-session-registry-detach
          (test:session-registry-after-resume)
          (test:session-registry-resumed-handle)
          300))
      "session-1"
      "connection-2"
      10299))
  False)

!(assertEqual
  (codex:exec-server-session-registry-expire-result-removed
    (codex:exec-server-session-registry-expire-if-detached
      (codex:exec-server-session-registry-detach-result-registry
        (codex:exec-server-session-registry-detach
          (test:session-registry-after-resume)
          (test:session-registry-resumed-handle)
          300))
      "session-1"
      "connection-2"
      10300))
  True)

!(assertEqual
  (codex:exec-server-session-registry-session-count
    (codex:exec-server-session-registry-expire-result-registry
      (codex:exec-server-session-registry-expire-if-detached
        (codex:exec-server-session-registry-detach-result-registry
          (codex:exec-server-session-registry-detach
            (test:session-registry-after-resume)
            (test:session-registry-resumed-handle)
            300))
        "session-1"
        "connection-2"
        10300)))
  0)

!(assertEqual
  (codex:exec-server-session-registry-attach-result-error
    (codex:exec-server-session-registry-attach
      (test:session-registry-after-detach)
      "session-1"
      "notifications-c"
      "unused-new-session"
      "connection-3"
      10100))
  (CodexExecServerRpcErrorError
    -32600
    CodexAbsent
    "unknown session id session-1"))

!(assertEqual
  (codex:exec-server-session-registry-session-count
    (codex:exec-server-session-registry-attach-result-registry
      (codex:exec-server-session-registry-attach
        (test:session-registry-after-detach)
        "session-1"
        "notifications-c"
        "unused-new-session"
        "connection-3"
        10100)))
  0)

!(assertEqual
  (codex:exec-server-session-registry-attach-result-error
    (codex:exec-server-session-registry-attach
      (codex:exec-server-session-registry-new)
      "missing-session"
      "notifications-c"
      "unused-new-session"
      "connection-3"
      0))
  (CodexExecServerRpcErrorError
    -32600
    CodexAbsent
    "unknown session id missing-session"))
