; Rust-faithful exec-server transport slice.
;
; This ports deterministic behavior from:
; - openai-codex/codex-rs/exec-server/src/server/transport.rs
;   - DEFAULT_LISTEN_URL
;   - ExecServerListenUrlParseError shape and Display text
;   - parse_listen_url scheme and socket-address classification
;   - run_transport parse-before-listener decision
;   - run_websocket_listener setup decisions
;   - websocket accept success/error branch behavior
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust delegates address validation to `SocketAddr::from_str`, binds a Tokio
;   `TcpListener`, prints the kernel-assigned local address, flushes stdout,
;   accepts TCP streams, and upgrades them with tungstenite. This pure slice
;   keeps those runtime effects as explicit plans and accept outcomes.
; - CeTTa has no standard SocketAddr parser. The pure parser below preserves
;   the same visible behavior for IPv4 `IP:PORT` inputs used by the Rust tests,
;   rejects hostnames and out-of-range ports, and accepts the common bracketed
;   IPv6 hextet/compression forms. Less common IPv6 forms such as embedded IPv4
;   tails remain a runtime bridge responsibility when live networking is added.

!(import! &self list)
!(import! &self str)
!(import! &self exec_server_connection)
!(import! &self exec_server_processor)

(= (codex:exec-server-transport-default-listen-url)
   "ws://127.0.0.1:0")

(= (codex:exec-server-transport-address-family-ipv4)
   (CodexExecServerTransportAddressFamilyIpv4))

(= (codex:exec-server-transport-address-family-ipv6)
   (CodexExecServerTransportAddressFamilyIpv6))

(= (codex:exec-server-transport-socket-addr $family $address $port)
   (CodexExecServerTransportSocketAddr $family $address $port))

(= (codex:exec-server-transport-socket-addr-family
      (CodexExecServerTransportSocketAddr $family $address $port))
   $family)

(= (codex:exec-server-transport-socket-addr-address
      (CodexExecServerTransportSocketAddr $family $address $port))
   $address)

(= (codex:exec-server-transport-socket-addr-port
      (CodexExecServerTransportSocketAddr $family $address $port))
   $port)

(= (codex:exec-server-transport-socket-addr-display
      (CodexExecServerTransportSocketAddr
        (CodexExecServerTransportAddressFamilyIpv4)
        $address
        $port))
   (format-args "{}:{}" ($address $port)))

(= (codex:exec-server-transport-socket-addr-display
      (CodexExecServerTransportSocketAddr
        (CodexExecServerTransportAddressFamilyIpv6)
        $address
        $port))
   (format-args "[{}]:{}" ($address $port)))

(= (codex:exec-server-transport-parse-ok $socket-addr)
   (CodexExecServerTransportParseOk $socket-addr))

(= (codex:exec-server-transport-parse-err $error)
   (CodexExecServerTransportParseErr $error))

(= (codex:exec-server-transport-parse-result-socket-addr $result)
   (case (collapse $result)
     ((((CodexExecServerTransportParseOk $socket-addr))
       $socket-addr))))

(= (codex:exec-server-transport-parse-result-error $result)
   (case (collapse $result)
     ((((CodexExecServerTransportParseErr $error))
       $error))))

(= (codex:exec-server-transport-parse-error-unsupported-listen-url
      $listen-url)
   (CodexExecServerTransportParseErrorUnsupportedListenUrl $listen-url))

(= (codex:exec-server-transport-parse-error-invalid-websocket-listen-url
      $listen-url)
   (CodexExecServerTransportParseErrorInvalidWebSocketListenUrl $listen-url))

(= (codex:exec-server-transport-parse-error-display
      (CodexExecServerTransportParseErrorUnsupportedListenUrl $listen-url))
   (format-args
     "unsupported --listen URL `{}`; expected `ws://IP:PORT`"
     ($listen-url)))

(= (codex:exec-server-transport-parse-error-display
      (CodexExecServerTransportParseErrorInvalidWebSocketListenUrl
        $listen-url))
   (format-args
     "invalid websocket --listen URL `{}`; expected `ws://IP:PORT`"
     ($listen-url)))

(= (codex:exec-server-transport-starts-with $text $prefix)
   (let $text-len (str-length $text)
     (let $prefix-len (str-length $prefix)
       (if (< $text-len $prefix-len)
           False
           (== (str-slice $text 0 $prefix-len) $prefix)))))

(= (codex:exec-server-transport-is-decimal-digit $char)
   (case $char
     (("0" True)
      ("1" True)
      ("2" True)
      ("3" True)
      ("4" True)
      ("5" True)
      ("6" True)
      ("7" True)
      ("8" True)
      ("9" True)
      ($other False))))

(= (codex:exec-server-transport-decimal-digit-value $char)
   (case $char
     (("0" 0)
      ("1" 1)
      ("2" 2)
      ("3" 3)
      ("4" 4)
      ("5" 5)
      ("6" 6)
      ("7" 7)
      ("8" 8)
      ("9" 9))))

(= (codex:exec-server-transport-is-decimal-string $text)
   (if (== (str-length $text) 0)
       False
       (codex:exec-server-transport-is-decimal-string-from $text 0)))

(= (codex:exec-server-transport-is-decimal-string-from $text $index)
   (if (== $index (str-length $text))
       True
       (if (codex:exec-server-transport-is-decimal-digit
             (str-slice $text $index (+ $index 1)))
           (codex:exec-server-transport-is-decimal-string-from
             $text
             (+ $index 1))
           False)))

(= (codex:exec-server-transport-decimal-string-to-number $text)
   (codex:exec-server-transport-decimal-string-to-number-from
     $text
     0
     0))

(= (codex:exec-server-transport-decimal-string-to-number-from
      $text
      $index
      $acc)
   (if (== $index (str-length $text))
       $acc
       (codex:exec-server-transport-decimal-string-to-number-from
         $text
         (+ $index 1)
         (+
           (* $acc 10)
           (codex:exec-server-transport-decimal-digit-value
             (str-slice $text $index (+ $index 1)))))))

(= (codex:exec-server-transport-is-valid-port-text $port-text)
   (if (codex:exec-server-transport-is-decimal-string $port-text)
       (<=
         (codex:exec-server-transport-decimal-string-to-number $port-text)
         65535)
       False))

(= (codex:exec-server-transport-is-valid-ipv4-octet $octet)
   (if (codex:exec-server-transport-is-decimal-string $octet)
       (<=
         (codex:exec-server-transport-decimal-string-to-number $octet)
         255)
       False))

(= (codex:exec-server-transport-are-valid-ipv4-octets ())
   True)

(= (codex:exec-server-transport-are-valid-ipv4-octets $octets)
   (if (codex:exec-server-transport-is-valid-ipv4-octet
         (list:first $octets))
       (codex:exec-server-transport-are-valid-ipv4-octets
         (list:rest $octets))
       False))

(= (codex:exec-server-transport-is-valid-ipv4-address $address)
   (let $octets (str-split "." $address)
     (if (== (list:len $octets) 4)
         (codex:exec-server-transport-are-valid-ipv4-octets $octets)
         False)))

(= (codex:exec-server-transport-is-ascii-hex-char $char)
   (case (str-find "0123456789abcdefABCDEF" $char)
     ((Empty False)
      ($index True))))

(= (codex:exec-server-transport-is-valid-ipv6-hextet $hextet)
   (let $len (str-length $hextet)
     (if (== $len 0)
         False
         (if (> $len 4)
             False
             (codex:exec-server-transport-are-ascii-hex-chars-from
               $hextet
               0)))))

(= (codex:exec-server-transport-are-ascii-hex-chars-from
      $text
      $index)
   (if (== $index (str-length $text))
       True
       (if (codex:exec-server-transport-is-ascii-hex-char
             (str-slice $text $index (+ $index 1)))
           (codex:exec-server-transport-are-ascii-hex-chars-from
             $text
             (+ $index 1))
           False)))

(= (codex:exec-server-transport-are-valid-ipv6-hextets ())
   True)

(= (codex:exec-server-transport-are-valid-ipv6-hextets $hextets)
   (if (codex:exec-server-transport-is-valid-ipv6-hextet
         (list:first $hextets))
       (codex:exec-server-transport-are-valid-ipv6-hextets
         (list:rest $hextets))
       False))

(= (codex:exec-server-transport-ipv6-segment-count-ok $count)
   (CodexExecServerTransportIpv6SegmentCountOk $count))

(= (codex:exec-server-transport-ipv6-segment-count-err)
   (CodexExecServerTransportIpv6SegmentCountErr))

(= (codex:exec-server-transport-ipv6-segment-count $segment)
   (if (== $segment "")
       (CodexExecServerTransportIpv6SegmentCountOk 0)
       (let $hextets (str-split ":" $segment)
         (if (codex:exec-server-transport-are-valid-ipv6-hextets
               $hextets)
             (CodexExecServerTransportIpv6SegmentCountOk
               (list:len $hextets))
             (CodexExecServerTransportIpv6SegmentCountErr)))))

(= (codex:exec-server-transport-is-valid-compressed-ipv6-address
      $left
      $right)
   (case (codex:exec-server-transport-ipv6-segment-count $left)
     (((CodexExecServerTransportIpv6SegmentCountErr)
       False)
      ((CodexExecServerTransportIpv6SegmentCountOk $left-count)
       (case (codex:exec-server-transport-ipv6-segment-count $right)
         (((CodexExecServerTransportIpv6SegmentCountErr)
           False)
          ((CodexExecServerTransportIpv6SegmentCountOk $right-count)
           (< (+ $left-count $right-count) 8))))))))

(= (codex:exec-server-transport-is-valid-full-ipv6-address $address)
   (let $hextets (str-split ":" $address)
     (if (== (list:len $hextets) 8)
         (codex:exec-server-transport-are-valid-ipv6-hextets
           $hextets)
         False)))

(= (codex:exec-server-transport-is-valid-ipv6-address-shape $address)
   (if (== (str-length $address) 0)
       False
       (let $compressed-parts (str-split "::" $address)
         (case (list:len $compressed-parts)
           ((1
             (codex:exec-server-transport-is-valid-full-ipv6-address
               $address))
            (2
             (codex:exec-server-transport-is-valid-compressed-ipv6-address
               (list:first $compressed-parts)
               (list:first (list:rest $compressed-parts))))
            ($other False))))))

(= (codex:exec-server-transport-parse-ipv4-socket-addr $socket-text)
   (let $parts (str-split ":" $socket-text)
     (if (== (list:len $parts) 2)
         (let $address (list:first $parts)
           (let $port-text (list:first (list:rest $parts))
             (if (codex:exec-server-transport-is-valid-ipv4-address $address)
                 (if (codex:exec-server-transport-is-valid-port-text
                       $port-text)
                     (CodexExecServerTransportSocketAddrParseOk
                       (CodexExecServerTransportSocketAddr
                         (CodexExecServerTransportAddressFamilyIpv4)
                         $address
                         (codex:exec-server-transport-decimal-string-to-number
                           $port-text)))
                     (CodexExecServerTransportSocketAddrParseErr))
                 (CodexExecServerTransportSocketAddrParseErr))))
         (CodexExecServerTransportSocketAddrParseErr))))

(= (codex:exec-server-transport-parse-bracketed-ipv6-socket-addr
      $socket-text)
   (case (str-find $socket-text "]")
     ((Empty
       (CodexExecServerTransportSocketAddrParseErr))
      ($close-index
       (let $address (str-slice $socket-text 1 $close-index)
         (let $tail (str-slice
                      $socket-text
                      (+ $close-index 1)
                      (str-length $socket-text))
           (if (codex:exec-server-transport-starts-with $tail ":")
               (let $port-text (str-slice $tail 1 (str-length $tail))
                 (if (codex:exec-server-transport-is-valid-ipv6-address-shape
                       $address)
                     (if (codex:exec-server-transport-is-valid-port-text
                           $port-text)
                         (CodexExecServerTransportSocketAddrParseOk
                           (CodexExecServerTransportSocketAddr
                             (CodexExecServerTransportAddressFamilyIpv6)
                             $address
                             (codex:exec-server-transport-decimal-string-to-number
                               $port-text)))
                         (CodexExecServerTransportSocketAddrParseErr))
                     (CodexExecServerTransportSocketAddrParseErr)))
               (CodexExecServerTransportSocketAddrParseErr))))))))

(= (codex:exec-server-transport-parse-socket-addr-for-family
      True
      $socket-text)
   (codex:exec-server-transport-parse-bracketed-ipv6-socket-addr
     $socket-text))

(= (codex:exec-server-transport-parse-socket-addr-for-family
      False
      $socket-text)
   (codex:exec-server-transport-parse-ipv4-socket-addr $socket-text))

(= (codex:exec-server-transport-parse-socket-addr $socket-text)
   (codex:exec-server-transport-parse-socket-addr-for-family
     (codex:exec-server-transport-starts-with $socket-text "[")
     $socket-text))

(= (codex:exec-server-transport-parse-listen-url $listen-url)
   (if (codex:exec-server-transport-starts-with $listen-url "ws://")
       (let $socket-text (str-slice $listen-url 5 (str-length $listen-url))
         (case (codex:exec-server-transport-parse-socket-addr $socket-text)
           (((CodexExecServerTransportSocketAddrParseOk $socket-addr)
             (CodexExecServerTransportParseOk $socket-addr))
            ((CodexExecServerTransportSocketAddrParseErr)
             (CodexExecServerTransportParseErr
               (CodexExecServerTransportParseErrorInvalidWebSocketListenUrl
                 $listen-url))))))
       (CodexExecServerTransportParseErr
         (CodexExecServerTransportParseErrorUnsupportedListenUrl
           $listen-url))))

(= (codex:exec-server-transport-run-plan-websocket
      $bind-address
      $runtime-paths)
   (CodexExecServerTransportRunPlanWebsocket
     $bind-address
     $runtime-paths))

(= (codex:exec-server-transport-run-plan-error $error)
   (CodexExecServerTransportRunPlanError $error))

(= (codex:exec-server-transport-run-plan-bind-address
      (CodexExecServerTransportRunPlanWebsocket
        $bind-address
        $runtime-paths))
   $bind-address)

(= (codex:exec-server-transport-run-plan-runtime-paths
      (CodexExecServerTransportRunPlanWebsocket
        $bind-address
        $runtime-paths))
   $runtime-paths)

(= (codex:exec-server-transport-run-plan-error-field
      (CodexExecServerTransportRunPlanError $error))
   $error)

(= (codex:exec-server-transport-run-transport-plan
      $listen-url
      $runtime-paths)
   (case (codex:exec-server-transport-parse-listen-url $listen-url)
     (((CodexExecServerTransportParseOk $bind-address)
       (CodexExecServerTransportRunPlanWebsocket
         $bind-address
         $runtime-paths))
      ((CodexExecServerTransportParseErr $error)
       (CodexExecServerTransportRunPlanError $error)))))

(= (codex:exec-server-transport-websocket-listener-plan
      $bind-address
      $local-addr
      $runtime-paths)
   (CodexExecServerTransportWebsocketListenerPlan
     $bind-address
     $local-addr
     (codex:exec-server-processor-connection-processor-new
       $runtime-paths)
     (format-args
       "ws://{}"
       ((codex:exec-server-transport-socket-addr-display $local-addr)))
     True))

(= (codex:exec-server-transport-websocket-listener-plan-bind-address
      (CodexExecServerTransportWebsocketListenerPlan
        $bind-address
        $local-addr
        $processor
        $printed-listen-url
        $stdout-flushed))
   $bind-address)

(= (codex:exec-server-transport-websocket-listener-plan-local-addr
      (CodexExecServerTransportWebsocketListenerPlan
        $bind-address
        $local-addr
        $processor
        $printed-listen-url
        $stdout-flushed))
   $local-addr)

(= (codex:exec-server-transport-websocket-listener-plan-processor
      (CodexExecServerTransportWebsocketListenerPlan
        $bind-address
        $local-addr
        $processor
        $printed-listen-url
        $stdout-flushed))
   $processor)

(= (codex:exec-server-transport-websocket-listener-plan-printed-listen-url
      (CodexExecServerTransportWebsocketListenerPlan
        $bind-address
        $local-addr
        $processor
        $printed-listen-url
        $stdout-flushed))
   $printed-listen-url)

(= (codex:exec-server-transport-websocket-listener-plan-stdout-flushed
      (CodexExecServerTransportWebsocketListenerPlan
        $bind-address
        $local-addr
        $processor
        $printed-listen-url
        $stdout-flushed))
   $stdout-flushed)

(= (codex:exec-server-transport-websocket-accept-ok)
   (CodexExecServerTransportWebsocketAcceptOk))

(= (codex:exec-server-transport-websocket-accept-err $message)
   (CodexExecServerTransportWebsocketAcceptErr $message))

(= (codex:exec-server-transport-websocket-accept-run-connection
      $connection-label
      $run-connection-plan)
   (CodexExecServerTransportWebsocketAcceptRunConnection
     $connection-label
     $run-connection-plan))

(= (codex:exec-server-transport-websocket-accept-warning $message)
   (CodexExecServerTransportWebsocketAcceptWarning $message))

(= (codex:exec-server-transport-websocket-accept-result-connection-label
      (CodexExecServerTransportWebsocketAcceptRunConnection
        $connection-label
        $run-connection-plan))
   $connection-label)

(= (codex:exec-server-transport-websocket-accept-result-run-connection-plan
      (CodexExecServerTransportWebsocketAcceptRunConnection
        $connection-label
        $run-connection-plan))
   $run-connection-plan)

(= (codex:exec-server-transport-websocket-accept-result-warning
      (CodexExecServerTransportWebsocketAcceptWarning $message))
   $message)

(= (codex:exec-server-transport-websocket-accept-step
      (CodexExecServerConnectionProcessor
        $session-registry
        $runtime-paths)
      $peer-addr
      (CodexExecServerTransportWebsocketAcceptOk))
   (let $connection-label
     (format-args "exec-server websocket {}" ($peer-addr))
     (CodexExecServerTransportWebsocketAcceptRunConnection
       $connection-label
       (codex:exec-server-processor-run-connection-plan
         (codex:exec-server-json-rpc-connection-into-parts
           (codex:exec-server-json-rpc-connection-from-websocket-state
             $connection-label))
         $runtime-paths))))

(= (codex:exec-server-transport-websocket-accept-step
      $processor
      $peer-addr
      (CodexExecServerTransportWebsocketAcceptErr $message))
   (CodexExecServerTransportWebsocketAcceptWarning
     (format-args
       "failed to accept exec-server websocket connection from {}: {}"
       ($peer-addr $message))))
