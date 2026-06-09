!(register-module! ../codex)
!(import! &self codex:exec_server_reqwest_http_client)

(= (test:reqwest-http-two-chunks)
   (codex:exec-server-reqwest-http-stream-body
     (codex:exec-server-reqwest-http-pending-body-stream
       "http-1"
       ((codex:exec-server-reqwest-http-body-item-ok "hello")
        (codex:exec-server-reqwest-http-body-item-ok "world")))
     (True True True)))

(= (test:reqwest-http-send-fails)
   (codex:exec-server-reqwest-http-stream-body
     (codex:exec-server-reqwest-http-pending-body-stream
       "http-1"
       ((codex:exec-server-reqwest-http-body-item-ok "hello")
        (codex:exec-server-reqwest-http-body-item-ok "world")))
     (False True)))

(= (test:reqwest-http-body-errors)
   (codex:exec-server-reqwest-http-stream-body
     (codex:exec-server-reqwest-http-pending-body-stream
       "http-1"
       ((codex:exec-server-reqwest-http-body-item-ok "hello")
        (codex:exec-server-reqwest-http-body-item-err "connection reset")))
     (True False)))

!(assertEqual
  (codex:exec-server-reqwest-http-stream-body-result-notifications
    (test:reqwest-http-two-chunks))
  ((CodexExecServerHttpRequestBodyDeltaNotification
     "http-1"
     1
     (CodexExecServerByteChunk "hello")
     False
     CodexAbsent)
   (CodexExecServerHttpRequestBodyDeltaNotification
     "http-1"
     2
     (CodexExecServerByteChunk "world")
     False
     CodexAbsent)
   (CodexExecServerHttpRequestBodyDeltaNotification
     "http-1"
     3
     (CodexExecServerByteChunk "")
     True
     CodexAbsent)))

!(assertEqual
  (codex:exec-server-reqwest-http-stream-body-result-next-seq
    (test:reqwest-http-two-chunks))
  3)

!(assertEqual
  (codex:exec-server-reqwest-http-stream-body-result-reason
    (test:reqwest-http-two-chunks))
  "eof")

!(assertEqual
  (codex:exec-server-reqwest-http-stream-body-result-remaining-send-results
    (test:reqwest-http-two-chunks))
  ())

!(assertEqual
  (codex:exec-server-reqwest-http-stream-body-result-notifications
    (test:reqwest-http-send-fails))
  ((CodexExecServerHttpRequestBodyDeltaNotification
     "http-1"
     1
     (CodexExecServerByteChunk "hello")
     False
     CodexAbsent)))

!(assertEqual
  (codex:exec-server-reqwest-http-stream-body-result-reason
    (test:reqwest-http-send-fails))
  "send_failed")

!(assertEqual
  (codex:exec-server-reqwest-http-stream-body-result-next-seq
    (test:reqwest-http-send-fails))
  1)

!(assertEqual
  (codex:exec-server-reqwest-http-stream-body-result-remaining-body-items
    (test:reqwest-http-send-fails))
  ((CodexExecServerReqwestHttpBodyItemOk "world")))

!(assertEqual
  (codex:exec-server-reqwest-http-stream-body-result-notifications
    (test:reqwest-http-body-errors))
  ((CodexExecServerHttpRequestBodyDeltaNotification
     "http-1"
     1
     (CodexExecServerByteChunk "hello")
     False
     CodexAbsent)
   (CodexExecServerHttpRequestBodyDeltaNotification
     "http-1"
     2
     (CodexExecServerByteChunk "")
     True
     "connection reset")))

!(assertEqual
  (codex:exec-server-reqwest-http-stream-body-result-reason
    (test:reqwest-http-body-errors))
  "body_error")

!(assertEqual
  (codex:exec-server-reqwest-http-stream-body-result-next-seq
    (test:reqwest-http-body-errors))
  2)
