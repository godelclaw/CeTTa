!(register-module! ../codex)
!(import! &self codex:exec_server_http_protocol)
!(import! &self codex:exec_server_reqwest_http_client)

(= (test:reqwest-http-request $stream-response)
   (codex:exec-server-http-request-params
     "GET"
     "https://example.test/mcp"
     ((codex:exec-server-http-header "accept" "application/json"))
     CodexAbsent
     CodexAbsent
     "http-1"
     $stream-response))

(= (test:reqwest-http-network-response)
   (codex:exec-server-reqwest-http-network-response
     200
     ((codex:exec-server-reqwest-http-raw-response-header
        "content-type"
        "application/json")
      (codex:exec-server-reqwest-http-raw-response-header
        "x-binary"
        CodexAbsent))
     "buffered-body"
     ((codex:exec-server-reqwest-http-body-item-ok "chunk"))))

(= (test:reqwest-http-streamed-run)
   (codex:exec-server-reqwest-http-run-flow
     (test:reqwest-http-request True)
     (codex:exec-server-reqwest-http-method-ok "GET")
     (codex:exec-server-reqwest-http-url-ok "https" "https://example.test/mcp")
     (codex:exec-server-reqwest-http-headers-ok
       ((codex:exec-server-http-header "accept" "application/json")))
     (codex:exec-server-reqwest-http-send-ok
       (test:reqwest-http-network-response))
     (codex:exec-server-reqwest-http-body-read-err "should not read")))

(= (test:reqwest-http-buffered-run)
   (codex:exec-server-reqwest-http-run-flow
     (test:reqwest-http-request False)
     (codex:exec-server-reqwest-http-method-ok "GET")
     (codex:exec-server-reqwest-http-url-ok "https" "https://example.test/mcp")
     (codex:exec-server-reqwest-http-headers-ok
       ((codex:exec-server-http-header "accept" "application/json")))
     (codex:exec-server-reqwest-http-send-ok
       (test:reqwest-http-network-response))
     (codex:exec-server-reqwest-http-body-read-ok "buffered-body")))

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
  (codex:exec-server-reqwest-http-run-result-error
    (codex:exec-server-reqwest-http-run-flow
      (test:reqwest-http-request False)
      (codex:exec-server-reqwest-http-method-err
        "invalid method")
      (codex:exec-server-reqwest-http-url-err
        "url should not be checked")
      (codex:exec-server-reqwest-http-headers-err
        (CodexExecServerRpcErrorError -32602 CodexAbsent "headers"))
      (codex:exec-server-reqwest-http-send-err "send")
      (codex:exec-server-reqwest-http-body-read-err "body")))
  (CodexExecServerRpcErrorError
    -32602
    CodexAbsent
    "http/request method is invalid: invalid method"))

!(assertEqual
  (codex:exec-server-reqwest-http-run-result-error
    (codex:exec-server-reqwest-http-run-flow
      (test:reqwest-http-request False)
      (codex:exec-server-reqwest-http-method-ok "GET")
      (codex:exec-server-reqwest-http-url-err "relative URL")
      (codex:exec-server-reqwest-http-headers-ok ())
      (codex:exec-server-reqwest-http-send-err "send")
      (codex:exec-server-reqwest-http-body-read-err "body")))
  (CodexExecServerRpcErrorError
    -32602
    CodexAbsent
    "http/request url is invalid: relative URL"))

!(assertEqual
  (codex:exec-server-reqwest-http-run-result-error
    (codex:exec-server-reqwest-http-run-flow
      (test:reqwest-http-request False)
      (codex:exec-server-reqwest-http-method-ok "GET")
      (codex:exec-server-reqwest-http-url-ok "file" "file:///tmp/x")
      (codex:exec-server-reqwest-http-headers-ok ())
      (codex:exec-server-reqwest-http-send-err "send")
      (codex:exec-server-reqwest-http-body-read-err "body")))
  (CodexExecServerRpcErrorError
    -32602
    CodexAbsent
    "http/request only supports http and https URLs, got file"))

!(assertEqual
  (codex:exec-server-reqwest-http-run-result-error
    (codex:exec-server-reqwest-http-run-flow
      (test:reqwest-http-request False)
      (codex:exec-server-reqwest-http-method-ok "GET")
      (codex:exec-server-reqwest-http-url-ok "https" "https://example.test")
      (codex:exec-server-reqwest-http-headers-err
        (CodexExecServerRpcErrorError
          -32602
          CodexAbsent
          "http/request header name is invalid: bad"))
      (codex:exec-server-reqwest-http-send-err "send")
      (codex:exec-server-reqwest-http-body-read-err "body")))
  (CodexExecServerRpcErrorError
    -32602
    CodexAbsent
    "http/request header name is invalid: bad"))

!(assertEqual
  (codex:exec-server-reqwest-http-run-result-error
    (codex:exec-server-reqwest-http-run-flow
      (test:reqwest-http-request False)
      (codex:exec-server-reqwest-http-method-ok "GET")
      (codex:exec-server-reqwest-http-url-ok "https" "https://example.test")
      (codex:exec-server-reqwest-http-headers-ok ())
      (codex:exec-server-reqwest-http-send-err
        "connection refused")
      (codex:exec-server-reqwest-http-body-read-err "body")))
  (CodexExecServerRpcErrorError
    -32603
    CodexAbsent
    "http/request failed: connection refused"))

!(assertEqual
  (codex:exec-server-reqwest-http-run-result-error
    (codex:exec-server-reqwest-http-run-flow
      (test:reqwest-http-request False)
      (codex:exec-server-reqwest-http-method-ok "GET")
      (codex:exec-server-reqwest-http-url-ok "https" "https://example.test")
      (codex:exec-server-reqwest-http-headers-ok ())
      (codex:exec-server-reqwest-http-send-ok
        (test:reqwest-http-network-response))
      (codex:exec-server-reqwest-http-body-read-err
        "broken body")))
  (CodexExecServerRpcErrorError
    -32603
    CodexAbsent
    "failed to read http/request response body: broken body"))

!(assertEqual
  (codex:exec-server-http-request-response-json
    (codex:exec-server-reqwest-http-run-result-response
      (test:reqwest-http-streamed-run)))
  (JsonObject
    ((JsonPair "status" (JsonNumber "200"))
     (JsonPair
       "headers"
       (JsonArray
         ((JsonObject
            ((JsonPair "name" (JsonString "content-type"))
             (JsonPair "value" (JsonString "application/json")))))))
     (JsonPair "bodyBase64" (JsonString "")))))

!(assertEqual
  (codex:exec-server-reqwest-http-run-result-pending-stream
    (test:reqwest-http-streamed-run))
  (CodexExecServerReqwestHttpPendingBodyStream
    "http-1"
    ((CodexExecServerReqwestHttpBodyItemOk "chunk"))))

!(assertEqual
  (codex:exec-server-http-request-response-json
    (codex:exec-server-reqwest-http-run-result-response
      (test:reqwest-http-buffered-run)))
  (JsonObject
    ((JsonPair "status" (JsonNumber "200"))
     (JsonPair
       "headers"
       (JsonArray
         ((JsonObject
            ((JsonPair "name" (JsonString "content-type"))
             (JsonPair "value" (JsonString "application/json")))))))
     (JsonPair "bodyBase64" (JsonString "YnVmZmVyZWQtYm9keQ==")))))

!(assertEqual
  (codex:exec-server-reqwest-http-run-result-pending-stream
    (test:reqwest-http-buffered-run))
  CodexAbsent)

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
