!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:exec_process_event_log)
!(import! &self codex:exec_server_process_protocol)
!(import! &self codex:exec_server_client_session)

(= (test:client-session-output $seq $stream $text)
   (codex:exec-process-event-output
     (codex:exec-process-output-chunk $seq $stream $text)))

(= (test:client-session-publish-state $state $event)
   (codex:exec-server-client-session-publish-result-state
     (codex:exec-server-client-session-publish-ordered-event
       $state
       $event)))

(= (test:client-session-replay $state)
   (codex:exec-process-event-receiver-replay
     (codex:exec-process-event-log-subscribe
       (codex:exec-server-client-session-state-event-log $state))))

(= (test:client-session-state-after-reordered)
   (let $state-0 (codex:exec-server-client-session-state-new)
     (let $state-1
       (test:client-session-publish-state
         $state-0
         (codex:exec-process-event-closed 4))
       (let $state-2
         (test:client-session-publish-state
           $state-1
           (test:client-session-output
             1
             (codex:exec-output-stream-stdout)
             "one"))
         (let $state-3
           (test:client-session-publish-state
             $state-2
             (codex:exec-process-event-exited 3 0))
           (test:client-session-publish-state
             $state-3
             (test:client-session-output
               2
               (codex:exec-output-stream-stderr)
               "two")))))))

!(assertEqual
  (codex:exec-server-client-process-event-channel-capacity)
  256)

!(assertEqual
  (codex:exec-server-client-process-event-retained-bytes)
  1048576)

!(assertEqual
  (codex:exec-server-client-session-state-wake-seq
    (codex:exec-server-client-session-state-new))
  0)

!(assertEqual
  (codex:exec-server-client-session-state-failure
    (codex:exec-server-client-session-state-new))
  CodexAbsent)

!(assertEqual
  (codex:exec-server-client-saturating-add-one-u64 41)
  42)

!(assertEqual
  (codex:exec-server-client-saturating-add-one-u64
    (codex:exec-server-client-u64-max))
  (CodexExecServerClientU64Max))

!(assertEqual
  (codex:exec-server-client-session-state-wake-seq
    (codex:exec-server-client-session-note-change
      (codex:exec-server-client-session-note-change
        (codex:exec-server-client-session-state-new)
        7)
      3))
  7)

!(assertEqual
  (codex:exec-server-client-session-publish-result-published-closed
    (codex:exec-server-client-session-publish-ordered-event
      (codex:exec-server-client-session-state-new)
      (codex:exec-process-event-closed 4)))
  False)

!(assertEqual
  (test:client-session-replay
    (test:client-session-publish-state
      (codex:exec-server-client-session-state-new)
      (codex:exec-process-event-closed 4)))
  ())

!(assertEqual
  (codex:exec-server-client-session-publish-result-published-closed
    (codex:exec-server-client-session-publish-ordered-event
      (let $state-0 (codex:exec-server-client-session-state-new)
        (let $state-1
          (test:client-session-publish-state
            $state-0
            (codex:exec-process-event-closed 4))
          (let $state-2
            (test:client-session-publish-state
              $state-1
              (test:client-session-output
                1
                (codex:exec-output-stream-stdout)
                "one"))
            (let $state-3
              (test:client-session-publish-state
                $state-2
                (codex:exec-process-event-exited 3 0))
              $state-3))))
      (test:client-session-output
        2
        (codex:exec-output-stream-stderr)
        "two")))
  True)

!(assertEqual
  (test:client-session-replay (test:client-session-state-after-reordered))
  ((CodexExecProcessEventOutput
     (CodexExecProcessOutputChunk
       1
       (CodexExecOutputStreamStdout)
       "one"))
   (CodexExecProcessEventOutput
     (CodexExecProcessOutputChunk
       2
       (CodexExecOutputStreamStderr)
       "two"))
   (CodexExecProcessEventExited 3 0)
   (CodexExecProcessEventClosed 4)))

!(assertEqual
  (test:client-session-replay
    (let $state-1
      (test:client-session-publish-state
        (codex:exec-server-client-session-state-new)
        (test:client-session-output
          1
          (codex:exec-output-stream-stdout)
          "one"))
      (test:client-session-publish-state
        $state-1
        (test:client-session-output
          1
          (codex:exec-output-stream-stderr)
          "duplicate"))))
  ((CodexExecProcessEventOutput
     (CodexExecProcessOutputChunk
       1
       (CodexExecOutputStreamStdout)
       "one"))))

!(assertEqual
  (test:client-session-replay
    (let $state-1
      (test:client-session-publish-state
        (codex:exec-server-client-session-state-new)
        (codex:exec-process-event-closed 2))
      (test:client-session-publish-state
        $state-1
        (codex:exec-process-event-failed "transport failed"))))
  ((CodexExecProcessEventFailed "transport failed")))

!(assertEqual
  (codex:exec-server-client-session-state-failure
    (codex:exec-server-client-session-set-failure
      (codex:exec-server-client-session-state-new)
      "transport failed"))
  "transport failed")

!(assertEqual
  (test:client-session-replay
    (codex:exec-server-client-session-set-failure
      (codex:exec-server-client-session-set-failure
        (codex:exec-server-client-session-state-new)
        "first failure")
      "second failure"))
  ((CodexExecProcessEventFailed "first failure")))

!(assertEqual
  (codex:exec-server-client-session-state-wake-seq
    (codex:exec-server-client-session-set-failure
      (codex:exec-server-client-session-set-failure
        (codex:exec-server-client-session-state-new)
        "first failure")
      "second failure"))
  2)

!(assertEqual
  (codex:exec-server-client-session-failed-response
    (codex:exec-server-client-session-set-failure
      (codex:exec-server-client-session-state-new)
      "transport failed"))
  (CodexExecServerReadResponse
    ()
    2
    True
    CodexAbsent
    True
    "transport failed"))

!(assertEqual
  (codex:exec-server-client-session-failed-response
    (codex:exec-server-client-session-state-new))
  CodexAbsent)

!(assertEqual
  (codex:exec-server-client-disconnected-message CodexAbsent)
  "exec-server transport disconnected")

!(assertEqual
  (codex:exec-server-client-disconnected-message "reader ended")
  "exec-server transport disconnected: reader ended")

!(assertEqual
  (codex:exec-server-client-is-transport-closed-error
    (codex:exec-server-client-error-closed))
  True)

!(assertEqual
  (codex:exec-server-client-is-transport-closed-error
    (codex:exec-server-client-error-disconnected
      "exec-server transport disconnected"))
  True)

!(assertEqual
  (codex:exec-server-client-is-transport-closed-error
    (codex:exec-server-client-error-server
      -32000
      "JSON-RPC transport closed"))
  True)

!(assertEqual
  (codex:exec-server-client-is-transport-closed-error
    (codex:exec-server-client-error-server
      -32001
      "JSON-RPC transport closed"))
  False)

!(assertEqual
  (codex:exec-server-client-record-disconnected-result-message
    (codex:exec-server-client-record-disconnected
      CodexAbsent
      "first"))
  "first")

!(assertEqual
  (codex:exec-server-client-record-disconnected-result-message
    (codex:exec-server-client-record-disconnected
      "first"
      "second"))
  "first")

!(assertEqual
  (codex:exec-server-client-call-flow-result-rpc-called
    (codex:exec-server-client-call-flow
      "already disconnected"
      (CodexExecServerRpcOk (JsonString "ignored"))))
  False)

!(assertEqual
  (codex:exec-server-client-call-flow-result-error
    (codex:exec-server-client-call-flow
      "already disconnected"
      (CodexExecServerRpcOk (JsonString "ignored"))))
  (CodexExecServerClientErrorDisconnected "already disconnected"))

!(assertEqual
  (codex:exec-server-client-call-flow-result-value
    (codex:exec-server-client-call-flow
      CodexAbsent
      (CodexExecServerRpcOk (JsonString "ok"))))
  (JsonString "ok"))

!(assertEqual
  (codex:exec-server-client-call-flow-result-error
    (codex:exec-server-client-call-flow
      CodexAbsent
      (CodexExecServerRpcErr
        (CodexExecServerRpcCallErrorClosed))))
  (CodexExecServerClientErrorDisconnected
    "exec-server transport disconnected"))

!(assertEqual
  (codex:exec-server-client-call-flow-result-latch
    (codex:exec-server-client-call-flow
      CodexAbsent
      (CodexExecServerRpcErr
        (CodexExecServerRpcCallErrorServer
          (CodexExecServerRpcErrorError
            -32000
            CodexAbsent
            "JSON-RPC transport closed")))))
  "exec-server transport disconnected")

!(assertEqual
  (codex:exec-server-client-call-flow-result-error
    (codex:exec-server-client-call-flow
      CodexAbsent
      (CodexExecServerRpcErr
        (CodexExecServerRpcCallErrorServer
          (CodexExecServerRpcErrorError
            -32001
            CodexAbsent
            "JSON-RPC transport closed")))))
  (CodexExecServerClientErrorServer
    -32001
    "JSON-RPC transport closed"))

!(assertEqual
  (codex:exec-server-client-call-flow-result-latch
    (codex:exec-server-client-call-flow
      CodexAbsent
      (CodexExecServerRpcErr
        (CodexExecServerRpcCallErrorJson
          "response decode failed"))))
  CodexAbsent)

!(assertEqual
  (codex:exec-server-client-call-flow-result-error
    (codex:exec-server-client-call-flow
      CodexAbsent
      (CodexExecServerRpcErr
        (CodexExecServerRpcCallErrorJson
          "response decode failed"))))
  (CodexExecServerClientErrorJson "response decode failed"))
