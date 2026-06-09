!(register-module! ../codex)
!(import! &self json)
!(import! &self list)
!(import! &self codex:exec_server_process_protocol)
!(import! &self codex:exec_server_http_protocol)
!(import! &self codex:exec_server_http_body_stream)

(= (test:http-body-delta $request-id $seq $chunk $done $error)
   (codex:exec-server-http-body-delta-notification
     $request-id
     $seq
     (codex:exec-server-byte-chunk $chunk)
     $done
     $error))

(= (test:http-body-request $request-id $stream-response)
   (codex:exec-server-http-request-params
     "GET"
     "https://example.test/mcp"
     ()
     CodexAbsent
     CodexAbsent
     $request-id
     $stream-response))

(= (test:prepared-1)
   (codex:exec-server-http-body-prepare-stream-request
     (codex:exec-server-http-body-client-state-default)
     (test:http-body-request "caller-stream-id" False)))

(= (test:stream-ordered)
   (codex:exec-server-http-body-remote-stream
     "http-1"
     1
     False
     False
     ((test:http-body-delta "http-1" 1 "hello " False CodexAbsent)
      (test:http-body-delta "http-1" 2 "world" False CodexAbsent)
      (test:http-body-delta "http-1" 3 "!" True CodexAbsent))
     CodexAbsent))

(= (test:http-body-fail-all-mixed)
   (codex:exec-server-http-body-fail-all-http-body-streams
     (codex:exec-server-http-body-client-state
       7
       ("http-1" "http-2" "http-3"))
     ("http-2")
     ((codex:exec-server-http-body-failure-entry "stale" "old"))
     "transport closed"))

(= (test:http-body-fail-all-notifications)
   (codex:exec-server-http-body-fail-all-result-notifications
     (test:http-body-fail-all-mixed)))

(= (test:http-body-fail-all-first-notification)
   (list:first (test:http-body-fail-all-notifications)))

(= (test:http-body-fail-all-second-notification)
   (list:first
     (list:rest (test:http-body-fail-all-notifications))))

(= (test:http-body-take-http2-failure)
   (codex:exec-server-http-body-take-failure
     (codex:exec-server-http-body-fail-all-result-failures
       (test:http-body-fail-all-mixed))
     "http-2"))

(= (test:http-body-insert-clears-failure)
   (codex:exec-server-http-body-insert-route-with-failures
     (codex:exec-server-http-body-client-state-default)
     ((codex:exec-server-http-body-failure-entry "http-1" "old"))
     "http-1"))

!(assertEqual
  (codex:exec-server-http-body-delta-channel-capacity)
  256)

!(assertEqual
  (codex:exec-server-http-body-next-request-id-result-request-id
    (codex:exec-server-http-body-next-request-id
      (codex:exec-server-http-body-client-state-default)))
  "http-1")

!(assertEqual
  (codex:exec-server-http-body-client-state-next-id
    (codex:exec-server-http-body-next-request-id-result-state
      (codex:exec-server-http-body-next-request-id
        (codex:exec-server-http-body-client-state-default))))
  2)

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-http-request-params-json
      (codex:exec-server-http-body-force-buffered-request
        (test:http-body-request "ignored-stream-id" True))))
  ("{\"method\":\"GET\",\"url\":\"https://example.test/mcp\",\"headers\":[],\"bodyBase64\":null,\"requestId\":\"ignored-stream-id\",\"streamResponse\":false}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-http-request-params-json
      (codex:exec-server-http-body-prepare-stream-request-result-params
        (test:prepared-1))))
  ("{\"method\":\"GET\",\"url\":\"https://example.test/mcp\",\"headers\":[],\"bodyBase64\":null,\"requestId\":\"http-1\",\"streamResponse\":true}"))

!(assertEqual
  (codex:exec-server-http-body-route-active
    (codex:exec-server-http-body-prepare-stream-request-result-state
      (test:prepared-1))
    "http-1")
  True)

!(assertEqual
  (codex:exec-server-http-body-remote-stream-request-id
    (codex:exec-server-http-body-prepare-stream-request-result-stream
      (test:prepared-1)))
  "http-1")

!(assertEqual
  (codex:exec-server-http-body-insert-route-result-message
    (codex:exec-server-http-body-insert-route
      (codex:exec-server-http-body-prepare-stream-request-result-state
        (test:prepared-1))
      "http-1"))
  "http response stream already registered for request http-1")

!(assertEqual
  (codex:exec-server-http-body-next-request-id-result-request-id
    (codex:exec-server-http-body-next-request-id
      (codex:exec-server-http-body-remove-route
        (codex:exec-server-http-body-prepare-stream-request-result-state
          (test:prepared-1))
        "http-1")))
  "http-2")

!(assertEqual
  (codex:exec-server-http-body-route-delta-result-state
    (codex:exec-server-http-body-handle-delta-route
      (codex:exec-server-http-body-client-state-default)
      (test:http-body-delta "missing" 1 "stale" False CodexAbsent)
      0))
  (codex:exec-server-http-body-client-state-default))

!(assertEqual
  (codex:exec-server-http-body-route-active
    (codex:exec-server-http-body-route-delta-result-state
      (codex:exec-server-http-body-handle-delta-route
        (codex:exec-server-http-body-prepare-stream-request-result-state
          (test:prepared-1))
        (test:http-body-delta "http-1" 1 "" True CodexAbsent)
        0))
    "http-1")
  False)

!(assertEqual
  (codex:exec-server-http-body-client-state-route-ids
    (codex:exec-server-http-body-fail-all-result-state
      (test:http-body-fail-all-mixed)))
  ())

!(assertEqual
  (codex:exec-server-http-body-client-state-next-id
    (codex:exec-server-http-body-fail-all-result-state
      (test:http-body-fail-all-mixed)))
  7)

!(assertEqual
  (list:len (test:http-body-fail-all-notifications))
  2)

!(assertEqual
  (codex:exec-server-http-body-delta-request-id
    (test:http-body-fail-all-first-notification))
  "http-1")

!(assertEqual
  (codex:exec-server-http-body-delta-request-id
    (test:http-body-fail-all-second-notification))
  "http-3")

!(assertEqual
  (codex:exec-server-http-body-delta-seq
    (test:http-body-fail-all-first-notification))
  1)

!(assertEqual
  (codex:exec-server-http-body-delta-done
    (test:http-body-fail-all-first-notification))
  True)

!(assertEqual
  (codex:exec-server-byte-chunk-into-inner
    (codex:exec-server-http-body-delta-chunk
      (test:http-body-fail-all-first-notification)))
  "")

!(assertEqual
  (codex:exec-server-http-body-delta-error
    (test:http-body-fail-all-first-notification))
  "transport closed")

!(assertEqual
  (codex:exec-server-http-body-failure-lookup
    (codex:exec-server-http-body-fail-all-result-failures
      (test:http-body-fail-all-mixed))
    "http-2")
  "transport closed")

!(assertEqual
  (codex:exec-server-http-body-failure-lookup
    (codex:exec-server-http-body-fail-all-result-failures
      (test:http-body-fail-all-mixed))
    "stale")
  "old")

!(assertEqual
  (codex:exec-server-http-body-take-failure-result-message
    (test:http-body-take-http2-failure))
  "transport closed")

!(assertEqual
  (codex:exec-server-http-body-failure-lookup
    (codex:exec-server-http-body-take-failure-result-failures
      (test:http-body-take-http2-failure))
    "http-2")
  CodexAbsent)

!(assertEqual
  (codex:exec-server-http-body-route-active
    (codex:exec-server-http-body-insert-route-with-failures-result-state
      (test:http-body-insert-clears-failure))
    "http-1")
  True)

!(assertEqual
  (codex:exec-server-http-body-failure-lookup
    (codex:exec-server-http-body-insert-route-with-failures-result-failures
      (test:http-body-insert-clears-failure))
    "http-1")
  CodexAbsent)

!(assertEqual
  (codex:exec-server-http-body-route-delta-result-message
    (codex:exec-server-http-body-handle-delta-route
      (codex:exec-server-http-body-prepare-stream-request-result-state
        (test:prepared-1))
      (test:http-body-delta "http-1" 257 "x" False CodexAbsent)
      256))
  "body delta channel filled before delivery")

!(assertEqual
  (codex:exec-server-http-body-route-active
    (codex:exec-server-http-body-route-delta-result-state
      (codex:exec-server-http-body-handle-delta-route
        (codex:exec-server-http-body-prepare-stream-request-result-state
          (test:prepared-1))
        (test:http-body-delta "http-1" 257 "x" False CodexAbsent)
        256))
    "http-1")
  False)

!(assertEqual
  (codex:exec-server-http-body-recv-result-kind
    (codex:exec-server-http-body-stream-recv (test:stream-ordered)))
  "chunk")

!(assertEqual
  (codex:exec-server-http-body-recv-result-chunk
    (codex:exec-server-http-body-stream-recv (test:stream-ordered)))
  "hello ")

!(assertEqual
  (let $first (codex:exec-server-http-body-stream-recv (test:stream-ordered))
    (let $second
      (codex:exec-server-http-body-stream-recv
        (codex:exec-server-http-body-recv-result-stream $first))
      (codex:exec-server-http-body-recv-result-chunk $second)))
  "world")

!(assertEqual
  (let $first (codex:exec-server-http-body-stream-recv (test:stream-ordered))
    (let $second
      (codex:exec-server-http-body-stream-recv
        (codex:exec-server-http-body-recv-result-stream $first))
      (let $third
        (codex:exec-server-http-body-stream-recv
          (codex:exec-server-http-body-recv-result-stream $second))
        (codex:exec-server-http-body-recv-result-chunk $third))))
  "!")

!(assertEqual
  (let $first (codex:exec-server-http-body-stream-recv (test:stream-ordered))
    (let $second
      (codex:exec-server-http-body-stream-recv
        (codex:exec-server-http-body-recv-result-stream $first))
      (let $third
        (codex:exec-server-http-body-stream-recv
          (codex:exec-server-http-body-recv-result-stream $second))
        (let $eof
          (codex:exec-server-http-body-stream-recv
            (codex:exec-server-http-body-recv-result-stream $third))
          (codex:exec-server-http-body-recv-result-kind $eof)))))
  "eof")

!(assertEqual
  (codex:exec-server-http-body-recv-result-kind
    (codex:exec-server-http-body-stream-recv
      (codex:exec-server-http-body-remote-stream
        "http-1"
        1
        False
        False
        ((test:http-body-delta "http-1" 1 "" True CodexAbsent))
        CodexAbsent)))
  "eof")

!(assertEqual
  (codex:exec-server-http-body-recv-result-message
    (codex:exec-server-http-body-stream-recv
      (codex:exec-server-http-body-remote-stream
        "http-1"
        1
        False
        False
        ((test:http-body-delta "http-1" 2 "gap" False CodexAbsent))
        CodexAbsent)))
  "http response stream `http-1` received seq 2, expected 1")

!(assertEqual
  (codex:exec-server-http-body-recv-result-message
    (codex:exec-server-http-body-stream-recv
      (codex:exec-server-http-body-remote-stream
        "http-1"
        1
        False
        False
        ((test:http-body-delta "http-1" 1 "partial" False "network closed"))
        CodexAbsent)))
  "http response stream `http-1` failed: network closed")

!(assertEqual
  (codex:exec-server-http-body-recv-result-message
    (codex:exec-server-http-body-stream-recv
      (codex:exec-server-http-body-stream-enqueue-result-stream
        (codex:exec-server-http-body-stream-fail
          (codex:exec-server-http-body-remote-stream-new "http-1")
          (codex:exec-server-http-body-transport-disconnected-message)))))
  "http response stream `http-1` failed: exec-server transport disconnected")

!(assertEqual
  (let $stream
    (codex:exec-server-http-body-remote-stream
      "http-1"
      1
      False
      False
      ((test:http-body-delta "http-1" 1 "x" False CodexAbsent))
      (codex:exec-server-http-body-backpressure-message))
    (let $first (codex:exec-server-http-body-stream-recv $stream)
      (let $second
        (codex:exec-server-http-body-stream-recv
          (codex:exec-server-http-body-recv-result-stream $first))
        (codex:exec-server-http-body-recv-result-message $second))))
  "http response stream `http-1` failed: body delta channel filled before delivery")
