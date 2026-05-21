!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:exec_server_process_protocol)
!(import! &self codex:exec_server_http_protocol)

(= (test:http-headers)
   ((codex:exec-server-http-header "accept" "application/json")
    (codex:exec-server-http-header "x-trace" "abc")))

!(assertEqual
  (codex:exec-server-http-request-method)
  "http/request")

!(assertEqual
  (codex:exec-server-http-request-body-delta-method)
  "http/request/bodyDelta")

!(assertEqual
  (codex:exec-server-http-header-name
    (codex:exec-server-http-header "accept" "application/json"))
  "accept")

!(assertEqual
  (codex:exec-server-http-header-value
    (codex:exec-server-http-header "accept" "application/json"))
  "application/json")

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-http-header-json
      (codex:exec-server-http-header "accept" "application/json")))
  ("{\"name\":\"accept\",\"value\":\"application/json\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-http-request-params-json
      (codex:exec-server-http-request-params
        "GET"
        "https://example.test"
        ()
        CodexAbsent
        CodexAbsent
        "req-1"
        False)))
  ("{\"method\":\"GET\",\"url\":\"https://example.test\",\"headers\":[],\"bodyBase64\":null,\"requestId\":\"req-1\",\"streamResponse\":false}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-http-request-params-json
      (codex:exec-server-http-request-params
        "POST"
        "https://example.test/upload"
        (test:http-headers)
        (codex:exec-server-byte-chunk "hi")
        1234
        "req-2"
        True)))
  ("{\"method\":\"POST\",\"url\":\"https://example.test/upload\",\"headers\":[{\"name\":\"accept\",\"value\":\"application/json\"},{\"name\":\"x-trace\",\"value\":\"abc\"}],\"bodyBase64\":\"aGk=\",\"timeoutMs\":1234,\"requestId\":\"req-2\",\"streamResponse\":true}"))

!(assertEqualToResult
  (codex:exec-server-http-request-timeout-ms-from-json
    (json-parse
      "{\"method\":\"GET\",\"url\":\"https://example.test\",\"requestId\":\"req-omitted-timeout\"}"))
  (CodexAbsent))

!(assertEqualToResult
  (codex:exec-server-http-request-timeout-ms-from-json
    (json-parse
      "{\"method\":\"GET\",\"url\":\"https://example.test\",\"requestId\":\"req-null-timeout\",\"timeoutMs\":null}"))
  (CodexAbsent))

!(assertEqualToResult
  (codex:exec-server-http-request-timeout-ms-from-json
    (json-parse
      "{\"method\":\"GET\",\"url\":\"https://example.test\",\"requestId\":\"req-explicit-timeout\",\"timeoutMs\":1234}"))
  ("1234"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-http-request-response-json
      (codex:exec-server-http-request-response
        201
        (test:http-headers)
        (codex:exec-server-byte-chunk "ok"))))
  ("{\"status\":201,\"headers\":[{\"name\":\"accept\",\"value\":\"application/json\"},{\"name\":\"x-trace\",\"value\":\"abc\"}],\"bodyBase64\":\"b2s=\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-http-body-delta-notification-json
      (codex:exec-server-http-body-delta-notification
        "req-2"
        1
        (codex:exec-server-byte-chunk "chunk")
        False
        CodexAbsent)))
  ("{\"requestId\":\"req-2\",\"seq\":1,\"deltaBase64\":\"Y2h1bms=\",\"done\":false,\"error\":null}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-http-body-delta-notification-json
      (codex:exec-server-http-body-delta-notification
        "req-2"
        2
        (codex:exec-server-byte-chunk "!")
        True
        "network closed")))
  ("{\"requestId\":\"req-2\",\"seq\":2,\"deltaBase64\":\"IQ==\",\"done\":true,\"error\":\"network closed\"}"))
