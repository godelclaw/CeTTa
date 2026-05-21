; Rust-faithful exec-server JSON-RPC connection framing slice.
;
; This ports deterministic behavior from:
; - openai-codex/codex-rs/exec-server/src/connection.rs
;   - CHANNEL_CAPACITY
;   - JsonRpcConnectionEvent
;   - from_stdio reader line policy
;   - from_websocket frame policy
;   - send_disconnected / send_malformed_message
;   - write_jsonrpc_line_message / serialize_jsonrpc_message
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust owns Tokio mpsc/watch channels and spawned reader/writer tasks. This
;   pure slice represents the same visible events and state changes as data;
;   actual async channel ownership belongs with the future CeTTa runtime bridge.
; - Rust parses bytes into `codex_app_server_protocol::JSONRPCMessage` using
;   serde. This slice accepts a symbolic parse outcome and applies the same
;   framing, skip, and error-message policy around that boundary.
; - Rust websocket binary frames parse raw bytes. Until a byte-vector CeTTa
;   primitive is in this port, binary frame payloads are carried symbolically;
;   the success/error routing matches the Rust branch.

!(import! &self json)
!(import! &self str)
!(import! &self exec_server_rpc)

(= (codex:exec-server-connection-channel-capacity)
   128)

(= (codex:exec-server-json-rpc-connection-event-message $message)
   (CodexExecServerJsonRpcConnectionEventMessage $message))

(= (codex:exec-server-json-rpc-connection-event-malformed-message $reason)
   (CodexExecServerJsonRpcConnectionEventMalformedMessage $reason))

(= (codex:exec-server-json-rpc-connection-event-disconnected $reason)
   (CodexExecServerJsonRpcConnectionEventDisconnected $reason))

(= (codex:exec-server-json-rpc-connection-event-reason
      (CodexExecServerJsonRpcConnectionEventMalformedMessage $reason))
   $reason)

(= (codex:exec-server-json-rpc-connection-event-reason
      (CodexExecServerJsonRpcConnectionEventDisconnected $reason))
   $reason)

(= (codex:exec-server-connection-no-event)
   (CodexExecServerConnectionNoEvent))

(= (codex:exec-server-connection-parse-ok $message)
   (CodexExecServerConnectionParseOk $message))

(= (codex:exec-server-connection-parse-err $error)
   (CodexExecServerConnectionParseErr $error))

(= (codex:exec-server-connection-send-disconnected-result
      $disconnected
      $event)
   (CodexExecServerConnectionSendDisconnectedResult
     $disconnected
     $event))

(= (codex:exec-server-connection-send-disconnected-result-disconnected
      (CodexExecServerConnectionSendDisconnectedResult
        $disconnected
        $event))
   $disconnected)

(= (codex:exec-server-connection-send-disconnected-result-event
      (CodexExecServerConnectionSendDisconnectedResult
        $disconnected
        $event))
   $event)

(= (codex:exec-server-connection-send-disconnected $reason)
   (CodexExecServerConnectionSendDisconnectedResult
     True
     (CodexExecServerJsonRpcConnectionEventDisconnected $reason)))

(= (codex:exec-server-connection-send-malformed-message $reason)
   (CodexExecServerJsonRpcConnectionEventMalformedMessage
     (if (== $reason CodexAbsent)
         "malformed JSON-RPC message"
         $reason)))

(= (codex:exec-server-connection-stdio-parse-error-reason
      $reader-label
      $error)
   (str-concat
     (str-concat
       (str-concat
         "failed to parse JSON-RPC message from "
         $reader-label)
       ": ")
     $error))

(= (codex:exec-server-connection-stdio-read-error-reason
      $reader-label
      $error)
   (str-concat
     (str-concat
       (str-concat
         "failed to read JSON-RPC message from "
         $reader-label)
       ": ")
     $error))

(= (codex:exec-server-connection-websocket-parse-error-reason
      $reader-label
      $error)
   (str-concat
     (str-concat
       (str-concat
         "failed to parse websocket JSON-RPC message from "
         $reader-label)
       ": ")
     $error))

(= (codex:exec-server-connection-websocket-read-error-reason
      $reader-label
      $error)
   (str-concat
     (str-concat
       (str-concat
         "failed to read websocket JSON-RPC message from "
         $reader-label)
       ": ")
     $error))

(= (codex:exec-server-connection-stdio-line-event
      $reader-label
      $line
      $parse-outcome)
   (if (== (str-trim $line) "")
       (CodexExecServerConnectionNoEvent)
       (case $parse-outcome
         (((CodexExecServerConnectionParseOk $message)
           (CodexExecServerJsonRpcConnectionEventMessage $message))
          ((CodexExecServerConnectionParseErr $error)
           (CodexExecServerJsonRpcConnectionEventMalformedMessage
             (codex:exec-server-connection-stdio-parse-error-reason
               $reader-label
               $error)))))))

(= (codex:exec-server-connection-stdio-eof-event)
   (codex:exec-server-connection-send-disconnected CodexAbsent))

(= (codex:exec-server-connection-stdio-read-error-event
      $reader-label
      $error)
   (codex:exec-server-connection-send-disconnected
     (codex:exec-server-connection-stdio-read-error-reason
       $reader-label
       $error)))

(= (codex:exec-server-connection-websocket-frame-text $text)
   (CodexExecServerConnectionWebsocketFrameText $text))

(= (codex:exec-server-connection-websocket-frame-binary $bytes)
   (CodexExecServerConnectionWebsocketFrameBinary $bytes))

(= (codex:exec-server-connection-websocket-frame-close)
   (CodexExecServerConnectionWebsocketFrameClose))

(= (codex:exec-server-connection-websocket-frame-ping $bytes)
   (CodexExecServerConnectionWebsocketFramePing $bytes))

(= (codex:exec-server-connection-websocket-frame-pong $bytes)
   (CodexExecServerConnectionWebsocketFramePong $bytes))

(= (codex:exec-server-connection-websocket-frame-other $value)
   (CodexExecServerConnectionWebsocketFrameOther $value))

(= (codex:exec-server-connection-websocket-frame-error $error)
   (CodexExecServerConnectionWebsocketFrameError $error))

(= (codex:exec-server-connection-websocket-frame-none)
   (CodexExecServerConnectionWebsocketFrameNone))

(= (codex:exec-server-connection-websocket-data-frame-event
      $reader-label
      $parse-outcome)
   (case $parse-outcome
     (((CodexExecServerConnectionParseOk $message)
       (CodexExecServerJsonRpcConnectionEventMessage $message))
      ((CodexExecServerConnectionParseErr $error)
       (CodexExecServerJsonRpcConnectionEventMalformedMessage
         (codex:exec-server-connection-websocket-parse-error-reason
           $reader-label
           $error))))))

(= (codex:exec-server-connection-websocket-frame-event
      $reader-label
      $frame
      $parse-outcome)
   (case $frame
     (((CodexExecServerConnectionWebsocketFrameText $text)
       (codex:exec-server-connection-websocket-data-frame-event
         $reader-label
         $parse-outcome))
      ((CodexExecServerConnectionWebsocketFrameBinary $bytes)
       (codex:exec-server-connection-websocket-data-frame-event
         $reader-label
         $parse-outcome))
      ((CodexExecServerConnectionWebsocketFrameClose)
       (codex:exec-server-connection-send-disconnected CodexAbsent))
      ((CodexExecServerConnectionWebsocketFramePing $bytes)
       (CodexExecServerConnectionNoEvent))
      ((CodexExecServerConnectionWebsocketFramePong $bytes)
       (CodexExecServerConnectionNoEvent))
      ((CodexExecServerConnectionWebsocketFrameOther $value)
       (CodexExecServerConnectionNoEvent))
      ((CodexExecServerConnectionWebsocketFrameError $error)
       (codex:exec-server-connection-send-disconnected
         (codex:exec-server-connection-websocket-read-error-reason
           $reader-label
           $error)))
      ((CodexExecServerConnectionWebsocketFrameNone)
       (codex:exec-server-connection-send-disconnected CodexAbsent)))))

(= (codex:exec-server-connection-serialize-jsonrpc-message $message)
   (json-stringify
     (codex:exec-server-rpc-message-json $message)))

(= (codex:exec-server-connection-serialize-jsonrpc-line-message $message)
   (function
     (case (codex:exec-server-connection-serialize-jsonrpc-message $message)
       (($encoded
         (case (str-concat $encoded "\n")
           (($line (return $line)))))))))

(= (codex:exec-server-connection-writer-outcome-ok)
   (CodexExecServerConnectionWriterOutcomeOk))

(= (codex:exec-server-connection-writer-outcome-err $error)
   (CodexExecServerConnectionWriterOutcomeErr $error))

(= (codex:exec-server-connection-stdio-write-error-reason
      $connection-label
      $error)
   (str-concat
     (str-concat
       (str-concat
         "failed to write JSON-RPC message to "
         $connection-label)
       ": ")
     $error))

(= (codex:exec-server-connection-websocket-serialize-error-reason
      $connection-label
      $error)
   (str-concat
     (str-concat
       (str-concat
         "failed to serialize JSON-RPC message for "
         $connection-label)
       ": ")
     $error))

(= (codex:exec-server-connection-websocket-write-error-reason
      $connection-label
      $error)
   (str-concat
     (str-concat
       (str-concat
         "failed to write websocket JSON-RPC message to "
         $connection-label)
       ": ")
     $error))

(= (codex:exec-server-connection-stdio-writer-event
      $connection-label
      $write-outcome)
   (case $write-outcome
     (((CodexExecServerConnectionWriterOutcomeOk)
       (CodexExecServerConnectionNoEvent))
      ((CodexExecServerConnectionWriterOutcomeErr $error)
       (codex:exec-server-connection-send-disconnected
         (codex:exec-server-connection-stdio-write-error-reason
           $connection-label
           $error))))))

(= (codex:exec-server-connection-websocket-serialize-event
      $connection-label
      $serialize-outcome)
   (case $serialize-outcome
     (((CodexExecServerConnectionWriterOutcomeOk)
       (CodexExecServerConnectionNoEvent))
      ((CodexExecServerConnectionWriterOutcomeErr $error)
       (codex:exec-server-connection-send-disconnected
         (codex:exec-server-connection-websocket-serialize-error-reason
           $connection-label
           $error))))))

(= (codex:exec-server-connection-websocket-writer-event
      $connection-label
      $write-outcome)
   (case $write-outcome
     (((CodexExecServerConnectionWriterOutcomeOk)
       (CodexExecServerConnectionNoEvent))
      ((CodexExecServerConnectionWriterOutcomeErr $error)
       (codex:exec-server-connection-send-disconnected
         (codex:exec-server-connection-websocket-write-error-reason
           $connection-label
           $error))))))

(= (codex:exec-server-json-rpc-connection-state
      $connection-label
      $outgoing
      $incoming
      $disconnected
      $task-count)
   (CodexExecServerJsonRpcConnectionState
     $connection-label
     $outgoing
     $incoming
     $disconnected
     $task-count))

(= (codex:exec-server-json-rpc-connection-from-stdio-state
      $connection-label)
   (CodexExecServerJsonRpcConnectionState
     $connection-label
     ()
     ()
     False
     2))

(= (codex:exec-server-json-rpc-connection-from-websocket-state
      $connection-label)
   (CodexExecServerJsonRpcConnectionState
     $connection-label
     ()
     ()
     False
     2))

(= (codex:exec-server-json-rpc-connection-state-disconnected
      (CodexExecServerJsonRpcConnectionState
        $connection-label
        $outgoing
        $incoming
        $disconnected
        $task-count))
   $disconnected)

(= (codex:exec-server-json-rpc-connection-state-task-count
      (CodexExecServerJsonRpcConnectionState
        $connection-label
        $outgoing
        $incoming
        $disconnected
        $task-count))
   $task-count)

(= (codex:exec-server-json-rpc-connection-parts
      $outgoing
      $incoming
      $disconnected
      $task-count)
   (CodexExecServerJsonRpcConnectionParts
     $outgoing
     $incoming
     $disconnected
     $task-count))

(= (codex:exec-server-json-rpc-connection-into-parts
      (CodexExecServerJsonRpcConnectionState
        $connection-label
        $outgoing
        $incoming
        $disconnected
        $task-count))
   (CodexExecServerJsonRpcConnectionParts
     $outgoing
     $incoming
     $disconnected
     $task-count))
