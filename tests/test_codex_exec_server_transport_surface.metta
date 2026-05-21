!(register-module! ../codex)
!(import! &self codex:exec_server_connection)
!(import! &self codex:exec_server_processor)
!(import! &self codex:exec_server_transport)

(= (test:transport-runtime-paths)
   (CodexRuntimePaths "root"))

(= (test:transport-default-socket)
   (CodexExecServerTransportSocketAddr
     (CodexExecServerTransportAddressFamilyIpv4)
     "127.0.0.1"
     0))

(= (test:transport-bind-socket)
   (CodexExecServerTransportSocketAddr
     (CodexExecServerTransportAddressFamilyIpv4)
     "127.0.0.1"
     1234))

(= (test:transport-local-socket)
   (CodexExecServerTransportSocketAddr
     (CodexExecServerTransportAddressFamilyIpv4)
     "127.0.0.1"
     4321))

(= (test:transport-listener-plan)
   (codex:exec-server-transport-websocket-listener-plan
     (test:transport-bind-socket)
     (test:transport-local-socket)
     (test:transport-runtime-paths)))

!(assertEqual
  (codex:exec-server-transport-default-listen-url)
  "ws://127.0.0.1:0")

!(assertEqual
  (codex:exec-server-transport-parse-result-socket-addr
    (codex:exec-server-transport-parse-listen-url
      (codex:exec-server-transport-default-listen-url)))
  (test:transport-default-socket))

!(assertEqual
  (codex:exec-server-transport-parse-result-socket-addr
    (codex:exec-server-transport-parse-listen-url
      "ws://127.0.0.1:1234"))
  (test:transport-bind-socket))

!(assertEqual
  (codex:exec-server-transport-socket-addr-display
    (test:transport-bind-socket))
  "127.0.0.1:1234")

!(assertEqual
  (codex:exec-server-transport-parse-error-display
    (codex:exec-server-transport-parse-result-error
      (codex:exec-server-transport-parse-listen-url
        "ws://localhost:1234")))
  "invalid websocket --listen URL `ws://localhost:1234`; expected `ws://IP:PORT`")

!(assertEqual
  (codex:exec-server-transport-parse-error-display
    (codex:exec-server-transport-parse-result-error
      (codex:exec-server-transport-parse-listen-url
        "http://127.0.0.1:1234")))
  "unsupported --listen URL `http://127.0.0.1:1234`; expected `ws://IP:PORT`")

!(assertEqual
  (codex:exec-server-transport-parse-error-display
    (codex:exec-server-transport-parse-result-error
      (codex:exec-server-transport-parse-listen-url
        "ws://127.0.0.1")))
  "invalid websocket --listen URL `ws://127.0.0.1`; expected `ws://IP:PORT`")

!(assertEqual
  (codex:exec-server-transport-parse-error-display
    (codex:exec-server-transport-parse-result-error
      (codex:exec-server-transport-parse-listen-url
        "ws://127.0.0.1:65536")))
  "invalid websocket --listen URL `ws://127.0.0.1:65536`; expected `ws://IP:PORT`")

!(assertEqual
  (codex:exec-server-transport-parse-error-display
    (codex:exec-server-transport-parse-result-error
      (codex:exec-server-transport-parse-listen-url
        "ws://256.0.0.1:1234")))
  "invalid websocket --listen URL `ws://256.0.0.1:1234`; expected `ws://IP:PORT`")

!(assertEqual
  (codex:exec-server-transport-parse-result-socket-addr
    (codex:exec-server-transport-parse-listen-url
      "ws://[::1]:1234"))
  (CodexExecServerTransportSocketAddr
    (CodexExecServerTransportAddressFamilyIpv6)
    "::1"
    1234))

!(assertEqual
  (codex:exec-server-transport-socket-addr-display
    (CodexExecServerTransportSocketAddr
      (CodexExecServerTransportAddressFamilyIpv6)
      "::1"
      1234))
  "[::1]:1234")

!(assertEqual
  (codex:exec-server-transport-parse-result-socket-addr
    (codex:exec-server-transport-parse-listen-url
      "ws://[2001:db8:0:0:0:0:0:1]:443"))
  (CodexExecServerTransportSocketAddr
    (CodexExecServerTransportAddressFamilyIpv6)
    "2001:db8:0:0:0:0:0:1"
    443))

!(assertEqual
  (codex:exec-server-transport-parse-error-display
    (codex:exec-server-transport-parse-result-error
      (codex:exec-server-transport-parse-listen-url
        "ws://[::::]:1234")))
  "invalid websocket --listen URL `ws://[::::]:1234`; expected `ws://IP:PORT`")

!(assertEqual
  (codex:exec-server-transport-run-plan-bind-address
    (codex:exec-server-transport-run-transport-plan
      "ws://127.0.0.1:1234"
      (test:transport-runtime-paths)))
  (test:transport-bind-socket))

!(assertEqual
  (codex:exec-server-transport-run-plan-runtime-paths
    (codex:exec-server-transport-run-transport-plan
      "ws://127.0.0.1:1234"
      (test:transport-runtime-paths)))
  (test:transport-runtime-paths))

!(assertEqual
  (codex:exec-server-transport-parse-error-display
    (codex:exec-server-transport-run-plan-error-field
      (codex:exec-server-transport-run-transport-plan
        "tcp://127.0.0.1:1234"
        (test:transport-runtime-paths))))
  "unsupported --listen URL `tcp://127.0.0.1:1234`; expected `ws://IP:PORT`")

!(assertEqual
  (codex:exec-server-transport-websocket-listener-plan-bind-address
    (test:transport-listener-plan))
  (test:transport-bind-socket))

!(assertEqual
  (codex:exec-server-transport-websocket-listener-plan-local-addr
    (test:transport-listener-plan))
  (test:transport-local-socket))

!(assertEqual
  (codex:exec-server-processor-connection-processor-runtime-paths
    (codex:exec-server-transport-websocket-listener-plan-processor
      (test:transport-listener-plan)))
  (test:transport-runtime-paths))

!(assertEqual
  (codex:exec-server-transport-websocket-listener-plan-printed-listen-url
    (test:transport-listener-plan))
  "ws://127.0.0.1:4321")

!(assertEqual
  (codex:exec-server-transport-websocket-listener-plan-stdout-flushed
    (test:transport-listener-plan))
  True)

!(assertEqual
  (codex:exec-server-transport-websocket-accept-result-connection-label
    (codex:exec-server-transport-websocket-accept-step
      (codex:exec-server-transport-websocket-listener-plan-processor
        (test:transport-listener-plan))
      "127.0.0.1:9000"
      (codex:exec-server-transport-websocket-accept-ok)))
  "exec-server websocket 127.0.0.1:9000")

!(assertEqual
  (codex:exec-server-processor-run-connection-plan-channel-capacity
    (codex:exec-server-transport-websocket-accept-result-run-connection-plan
      (codex:exec-server-transport-websocket-accept-step
        (codex:exec-server-transport-websocket-listener-plan-processor
          (test:transport-listener-plan))
        "127.0.0.1:9000"
        (codex:exec-server-transport-websocket-accept-ok))))
  128)

!(assertEqual
  (codex:exec-server-processor-run-connection-plan-runtime-paths
    (codex:exec-server-transport-websocket-accept-result-run-connection-plan
      (codex:exec-server-transport-websocket-accept-step
        (codex:exec-server-transport-websocket-listener-plan-processor
          (test:transport-listener-plan))
        "127.0.0.1:9000"
        (codex:exec-server-transport-websocket-accept-ok))))
  (test:transport-runtime-paths))

!(assertEqual
  (codex:exec-server-transport-websocket-accept-result-warning
    (codex:exec-server-transport-websocket-accept-step
      (codex:exec-server-transport-websocket-listener-plan-processor
        (test:transport-listener-plan))
      "127.0.0.1:9001"
      (codex:exec-server-transport-websocket-accept-err
        "handshake failed")))
  "failed to accept exec-server websocket connection from 127.0.0.1:9001: handshake failed")
