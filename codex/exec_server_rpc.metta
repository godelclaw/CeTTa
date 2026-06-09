; Rust-faithful exec-server RPC core slice.
;
; This ports deterministic JSON-RPC-lite behavior from:
; - openai-codex/codex-rs/app-server-protocol/src/jsonrpc_lite.rs
;   - RequestId / JSONRPCMessage / JSONRPCRequest /
;     JSONRPCNotification / JSONRPCResponse / JSONRPCError
; - openai-codex/codex-rs/exec-server/src/server/jsonrpc.rs
;   - invalid_request / invalid_params / method_not_found
;   - response_message / invalid_request_message
; - openai-codex/codex-rs/exec-server/src/rpc.rs
;   - RpcCallError
;   - RpcServerOutboundMessage / encode_server_message
;   - RpcRouter request / request_with_id / notification route invocation
;     decode, handler-result, serialization, and Option outbound policy
;   - JSON-RPC error constructors
;   - RpcClient request-id allocation, pending map routing,
;     notify/call serialization and send cleanup, request-from-server
;     rejection, and drain_pending behavior
;   - decode_params empty-object-to-null fallback policy
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust serializes/deserializes `serde_json::Value` and generated protocol
;   structs. This pure slice represents already-serialized JSON values as
;   CeTTa `Json*` atoms and preserves the same field names, field omission
;   rules, error codes, and message routing.
; - Rust stores pending requests in a `HashMap<RequestId, oneshot::Sender<_>>`.
;   This pure slice stores request id -> symbolic pending labels in a list.
;   Lookup/removal by exact request id is the visible algorithm; iteration
;   order during drain is not a Rust contract, so the CeTTa drain result uses
;   local insertion order for observability in tests.
; - Rust generic serde typed decoding cannot be represented as a pure CeTTa
;   function. The decode helpers below take symbolic primary/null decode
;   outcomes and apply the same retry rule: only an empty JSON object retries
;   decoding as JSON null, and null-decode failure returns the original error.
; - Rust `RpcRouter` stores async handler closures. This slice models the
;   deterministic method registration and lookup surface with symbolic route
;   handlers. The route invocation helpers accept symbolic decode, handler,
;   and serialization outcomes at that runtime boundary while preserving the
;   exact Rust branch decisions.

!(import! &self json)
!(import! &self list)
!(import! &self str)

(= (codex:exec-server-rpc-jsonrpc-version)
   "2.0")

(= (codex:exec-server-rpc-json-number $value)
   (JsonNumber (format-args "{}" ($value))))

(= (codex:exec-server-rpc-json-option-value $value)
   (if (== $value CodexAbsent)
       JsonNull
       $value))

(= (codex:exec-server-rpc-append-optional-json-pair
      $pairs
      $key
      $value)
   (if (== $value CodexAbsent)
       $pairs
       (list:append
         $pairs
         (list:cons (JsonPair $key $value) ()))))

(= (codex:exec-server-rpc-request-id-integer $value)
   (CodexExecServerRpcRequestIdInteger $value))

(= (codex:exec-server-rpc-request-id-string $value)
   (CodexExecServerRpcRequestIdString $value))

(= (codex:exec-server-rpc-request-id-display
      (CodexExecServerRpcRequestIdInteger $value))
   (format-args "{}" ($value)))

(= (codex:exec-server-rpc-request-id-display
      (CodexExecServerRpcRequestIdString $value))
   $value)

(= (codex:exec-server-rpc-request-id-json
      (CodexExecServerRpcRequestIdInteger $value))
   (codex:exec-server-rpc-json-number $value))

(= (codex:exec-server-rpc-request-id-json
      (CodexExecServerRpcRequestIdString $value))
   (JsonString $value))

(= (codex:exec-server-rpc-error-error
      $code
      $data
      $message)
   (CodexExecServerRpcErrorError $code $data $message))

(= (codex:exec-server-rpc-error-error-code
      (CodexExecServerRpcErrorError $code $data $message))
   $code)

(= (codex:exec-server-rpc-error-error-data
      (CodexExecServerRpcErrorError $code $data $message))
   $data)

(= (codex:exec-server-rpc-error-error-message
      (CodexExecServerRpcErrorError $code $data $message))
   $message)

(= (codex:exec-server-rpc-error-error-json
      (CodexExecServerRpcErrorError $code $data $message))
   (JsonObject
     (list:append
       (codex:exec-server-rpc-append-optional-json-pair
         ((JsonPair
            "code"
            (codex:exec-server-rpc-json-number $code)))
         "data"
         $data)
       ((JsonPair "message" (JsonString $message))))))

(= (codex:exec-server-rpc-invalid-request $message)
   (CodexExecServerRpcErrorError -32600 CodexAbsent $message))

(= (codex:exec-server-rpc-method-not-found $message)
   (CodexExecServerRpcErrorError -32601 CodexAbsent $message))

(= (codex:exec-server-rpc-invalid-params $message)
   (CodexExecServerRpcErrorError -32602 CodexAbsent $message))

(= (codex:exec-server-rpc-not-found $message)
   (CodexExecServerRpcErrorError -32004 CodexAbsent $message))

(= (codex:exec-server-rpc-internal-error $message)
   (CodexExecServerRpcErrorError -32603 CodexAbsent $message))

(= (codex:exec-server-rpc-request
      $id
      $method
      $params
      $trace)
   (CodexExecServerRpcRequest $id $method $params $trace))

(= (codex:exec-server-rpc-request-id
      (CodexExecServerRpcRequest $id $method $params $trace))
   $id)

(= (codex:exec-server-rpc-request-method
      (CodexExecServerRpcRequest $id $method $params $trace))
   $method)

(= (codex:exec-server-rpc-request-params
      (CodexExecServerRpcRequest $id $method $params $trace))
   $params)

(= (codex:exec-server-rpc-request-trace
      (CodexExecServerRpcRequest $id $method $params $trace))
   $trace)

(= (codex:exec-server-rpc-request-json
      (CodexExecServerRpcRequest $id $method $params $trace))
   (JsonObject
     (codex:exec-server-rpc-append-optional-json-pair
       (codex:exec-server-rpc-append-optional-json-pair
         ((JsonPair
            "id"
            (codex:exec-server-rpc-request-id-json $id))
          (JsonPair "method" (JsonString $method)))
         "params"
         $params)
       "trace"
       $trace)))

(= (codex:exec-server-rpc-notification $method $params)
   (CodexExecServerRpcNotification $method $params))

(= (codex:exec-server-rpc-notification-method
      (CodexExecServerRpcNotification $method $params))
   $method)

(= (codex:exec-server-rpc-notification-params
      (CodexExecServerRpcNotification $method $params))
   $params)

(= (codex:exec-server-rpc-notification-json
      (CodexExecServerRpcNotification $method $params))
   (JsonObject
     (codex:exec-server-rpc-append-optional-json-pair
       ((JsonPair "method" (JsonString $method)))
       "params"
       $params)))

(= (codex:exec-server-rpc-response $id $result)
   (CodexExecServerRpcResponse $id $result))

(= (codex:exec-server-rpc-response-id
      (CodexExecServerRpcResponse $id $result))
   $id)

(= (codex:exec-server-rpc-response-result
      (CodexExecServerRpcResponse $id $result))
   $result)

(= (codex:exec-server-rpc-response-json
      (CodexExecServerRpcResponse $id $result))
   (JsonObject
     ((JsonPair "id" (codex:exec-server-rpc-request-id-json $id))
      (JsonPair "result" $result))))

(= (codex:exec-server-rpc-error $id $error)
   (CodexExecServerRpcError $id $error))

(= (codex:exec-server-rpc-error-id
      (CodexExecServerRpcError $id $error))
   $id)

(= (codex:exec-server-rpc-error-error-field
      (CodexExecServerRpcError $id $error))
   $error)

(= (codex:exec-server-rpc-error-json
      (CodexExecServerRpcError $id $error))
   (JsonObject
     ((JsonPair "error" (codex:exec-server-rpc-error-error-json $error))
      (JsonPair "id" (codex:exec-server-rpc-request-id-json $id)))))

(= (codex:exec-server-rpc-message-request $request)
   (CodexExecServerRpcMessageRequest $request))

(= (codex:exec-server-rpc-message-notification $notification)
   (CodexExecServerRpcMessageNotification $notification))

(= (codex:exec-server-rpc-message-response $response)
   (CodexExecServerRpcMessageResponse $response))

(= (codex:exec-server-rpc-message-error $error)
   (CodexExecServerRpcMessageError $error))

(= (codex:exec-server-rpc-message-json
      (CodexExecServerRpcMessageRequest $request))
   (codex:exec-server-rpc-request-json $request))

(= (codex:exec-server-rpc-message-json
      (CodexExecServerRpcMessageNotification $notification))
   (codex:exec-server-rpc-notification-json $notification))

(= (codex:exec-server-rpc-message-json
      (CodexExecServerRpcMessageResponse $response))
   (codex:exec-server-rpc-response-json $response))

(= (codex:exec-server-rpc-message-json
      (CodexExecServerRpcMessageError $error))
   (codex:exec-server-rpc-error-json $error))

(= (codex:exec-server-rpc-ok $value)
   (CodexExecServerRpcOk $value))

(= (codex:exec-server-rpc-err $error)
   (CodexExecServerRpcErr $error))

(= (codex:exec-server-rpc-response-message $request-id $result)
   (case $result
     (((CodexExecServerRpcOk $value)
       (CodexExecServerRpcMessageResponse
         (CodexExecServerRpcResponse $request-id $value)))
      ((CodexExecServerRpcErr $error)
       (CodexExecServerRpcMessageError
         (CodexExecServerRpcError $request-id $error))))))

(= (codex:exec-server-rpc-invalid-request-message $reason)
   (CodexExecServerRpcMessageError
     (CodexExecServerRpcError
       (CodexExecServerRpcRequestIdInteger -1)
       (codex:exec-server-rpc-invalid-request $reason))))

(= (codex:exec-server-rpc-call-error-closed)
   (CodexExecServerRpcCallErrorClosed))

(= (codex:exec-server-rpc-call-error-json $error)
   (CodexExecServerRpcCallErrorJson $error))

(= (codex:exec-server-rpc-call-error-server $error)
   (CodexExecServerRpcCallErrorServer $error))

(= (codex:exec-server-rpc-client-event-notification $notification)
   (CodexExecServerRpcClientEventNotification $notification))

(= (codex:exec-server-rpc-client-event-disconnected $reason)
   (CodexExecServerRpcClientEventDisconnected $reason))

(= (codex:exec-server-rpc-server-outbound-response
      $request-id
      $result)
   (CodexExecServerRpcServerOutboundResponse $request-id $result))

(= (codex:exec-server-rpc-server-outbound-error
      $request-id
      $error)
   (CodexExecServerRpcServerOutboundError $request-id $error))

(= (codex:exec-server-rpc-server-outbound-notification $notification)
   (CodexExecServerRpcServerOutboundNotification $notification))

(= (codex:exec-server-rpc-encode-server-message $message)
   (case $message
     (((CodexExecServerRpcServerOutboundResponse $request-id $result)
       (CodexExecServerRpcMessageResponse
         (CodexExecServerRpcResponse $request-id $result)))
      ((CodexExecServerRpcServerOutboundError $request-id $error)
       (CodexExecServerRpcMessageError
         (CodexExecServerRpcError $request-id $error)))
      ((CodexExecServerRpcServerOutboundNotification $notification)
       (CodexExecServerRpcMessageNotification $notification)))))

(= (codex:exec-server-rpc-pending-request $request-id $label)
   (CodexExecServerRpcPendingRequest $request-id $label))

(= (codex:exec-server-rpc-pending-request-id
      (CodexExecServerRpcPendingRequest $request-id $label))
   $request-id)

(= (codex:exec-server-rpc-pending-request-label
      (CodexExecServerRpcPendingRequest $request-id $label))
   $label)

(= (codex:exec-server-rpc-pending-count $pending)
   (list:len $pending))

(= (codex:exec-server-rpc-pending-insert $pending $request-id $label)
   (list:append
     $pending
     (list:cons
       (CodexExecServerRpcPendingRequest $request-id $label)
       ())))

(= (codex:exec-server-rpc-pending-remove-missing $pending)
   (CodexExecServerRpcPendingRemoveMissing $pending))

(= (codex:exec-server-rpc-pending-remove-found $label $pending)
   (CodexExecServerRpcPendingRemoveFound $label $pending))

(= (codex:exec-server-rpc-pending-remove-result-label
      (CodexExecServerRpcPendingRemoveFound $label $pending))
   $label)

(= (codex:exec-server-rpc-pending-remove-result-pending
      (CodexExecServerRpcPendingRemoveMissing $pending))
   $pending)

(= (codex:exec-server-rpc-pending-remove-result-pending
      (CodexExecServerRpcPendingRemoveFound $label $pending))
   $pending)

(= (codex:exec-server-rpc-pending-remove () $request-id)
   (CodexExecServerRpcPendingRemoveMissing ()))

(= (codex:exec-server-rpc-pending-remove $pending $request-id)
   (let $head (list:first $pending)
     (let $tail (list:rest $pending)
       (if (== (codex:exec-server-rpc-pending-request-id $head)
               $request-id)
           (CodexExecServerRpcPendingRemoveFound
             (codex:exec-server-rpc-pending-request-label $head)
             $tail)
           (case (codex:exec-server-rpc-pending-remove
                   $tail
                   $request-id)
             (((CodexExecServerRpcPendingRemoveMissing $next-pending)
               (CodexExecServerRpcPendingRemoveMissing
                 (list:cons $head $next-pending)))
              ((CodexExecServerRpcPendingRemoveFound $label $next-pending)
               (CodexExecServerRpcPendingRemoveFound
                 $label
                 (list:cons $head $next-pending)))))))))

(= (codex:exec-server-rpc-client-state
      $next-request-id
      $pending
      $disconnected)
   (CodexExecServerRpcClientState
     $next-request-id
     $pending
     $disconnected))

(= (codex:exec-server-rpc-client-state-new)
   (CodexExecServerRpcClientState 1 () False))

(= (codex:exec-server-rpc-client-state-next-request-id
      (CodexExecServerRpcClientState
        $next-request-id
        $pending
        $disconnected))
   $next-request-id)

(= (codex:exec-server-rpc-client-state-pending
      (CodexExecServerRpcClientState
        $next-request-id
        $pending
        $disconnected))
   $pending)

(= (codex:exec-server-rpc-client-state-disconnected
      (CodexExecServerRpcClientState
        $next-request-id
        $pending
        $disconnected))
   $disconnected)

(= (codex:exec-server-rpc-client-state-pending-count $state)
   (codex:exec-server-rpc-pending-count
     (codex:exec-server-rpc-client-state-pending $state)))

(= (codex:exec-server-rpc-client-state-with-disconnected
      (CodexExecServerRpcClientState
        $next-request-id
        $pending
        $disconnected)
      $new-disconnected)
   (CodexExecServerRpcClientState
     $next-request-id
     $pending
     $new-disconnected))

(= (codex:exec-server-rpc-client-state-with-pending
      (CodexExecServerRpcClientState
        $next-request-id
        $pending
        $disconnected)
      $new-pending)
   (CodexExecServerRpcClientState
     $next-request-id
     $new-pending
     $disconnected))

(= (codex:exec-server-rpc-client-state-remove-pending
      $state
      $request-id)
   (codex:exec-server-rpc-client-state-with-pending
     $state
     (codex:exec-server-rpc-pending-remove-result-pending
       (codex:exec-server-rpc-pending-remove
         (codex:exec-server-rpc-client-state-pending $state)
         $request-id))))

(= (codex:exec-server-rpc-call-start-ok $request-id $state)
   (CodexExecServerRpcCallStartOk $request-id $state))

(= (codex:exec-server-rpc-call-start-closed $state)
   (CodexExecServerRpcCallStartClosed $state))

(= (codex:exec-server-rpc-call-start-result-request-id
      (CodexExecServerRpcCallStartOk $request-id $state))
   $request-id)

(= (codex:exec-server-rpc-call-start-result-state
      (CodexExecServerRpcCallStartOk $request-id $state))
   $state)

(= (codex:exec-server-rpc-call-start-result-state
      (CodexExecServerRpcCallStartClosed $state))
   $state)

(= (codex:exec-server-rpc-client-start-call $state $label)
   (let $request-id
     (CodexExecServerRpcRequestIdInteger
       (codex:exec-server-rpc-client-state-next-request-id $state))
     (let $next-request-id
       (+ (codex:exec-server-rpc-client-state-next-request-id $state) 1)
       (if (codex:exec-server-rpc-client-state-disconnected $state)
           (CodexExecServerRpcCallStartClosed
             (CodexExecServerRpcClientState
               $next-request-id
               (codex:exec-server-rpc-client-state-pending $state)
               True))
           (CodexExecServerRpcCallStartOk
             $request-id
             (CodexExecServerRpcClientState
               $next-request-id
               (codex:exec-server-rpc-pending-insert
                 (codex:exec-server-rpc-client-state-pending $state)
                 $request-id
                 $label)
               (codex:exec-server-rpc-client-state-disconnected
                 $state)))))))

(= (codex:exec-server-rpc-client-send-ok)
   (CodexExecServerRpcClientSendOk))

(= (codex:exec-server-rpc-client-send-closed)
   (CodexExecServerRpcClientSendClosed))

(= (codex:exec-server-rpc-client-notify-result-ok $message)
   (CodexExecServerRpcClientNotifyResultOk $message))

(= (codex:exec-server-rpc-client-notify-result-err $message)
   (CodexExecServerRpcClientNotifyResultErr $message))

(= (codex:exec-server-rpc-client-notify-result-message
      (CodexExecServerRpcClientNotifyResultOk $message))
   $message)

(= (codex:exec-server-rpc-client-notify-result-message
      (CodexExecServerRpcClientNotifyResultErr $message))
   $message)

(= (codex:exec-server-rpc-client-notify-flow
      $method
      (CodexExecServerRpcSerializeOutcomeErr $message)
      $send-outcome)
   (CodexExecServerRpcClientNotifyResultErr $message))

(= (codex:exec-server-rpc-client-notify-flow
      $method
      (CodexExecServerRpcSerializeOutcomeOk $params-json)
      (CodexExecServerRpcClientSendClosed))
   (CodexExecServerRpcClientNotifyResultErr
     "JSON-RPC transport closed"))

(= (codex:exec-server-rpc-client-notify-flow
      $method
      (CodexExecServerRpcSerializeOutcomeOk $params-json)
      (CodexExecServerRpcClientSendOk))
   (CodexExecServerRpcClientNotifyResultOk
     (CodexExecServerRpcMessageNotification
       (CodexExecServerRpcNotification $method $params-json))))

(= (codex:exec-server-rpc-client-call-dispatch-awaiting
      $state
      $request-id
      $message)
   (CodexExecServerRpcClientCallDispatchAwaiting
     $state
     $request-id
     $message))

(= (codex:exec-server-rpc-client-call-dispatch-err
      $state
      $error)
   (CodexExecServerRpcClientCallDispatchErr $state $error))

(= (codex:exec-server-rpc-client-call-dispatch-result-state
      (CodexExecServerRpcClientCallDispatchAwaiting
        $state
        $request-id
        $message))
   $state)

(= (codex:exec-server-rpc-client-call-dispatch-result-state
      (CodexExecServerRpcClientCallDispatchErr $state $error))
   $state)

(= (codex:exec-server-rpc-client-call-dispatch-result-request-id
      (CodexExecServerRpcClientCallDispatchAwaiting
        $state
        $request-id
        $message))
   $request-id)

(= (codex:exec-server-rpc-client-call-dispatch-result-message
      (CodexExecServerRpcClientCallDispatchAwaiting
        $state
        $request-id
        $message))
   $message)

(= (codex:exec-server-rpc-client-call-dispatch-result-error
      (CodexExecServerRpcClientCallDispatchErr $state $error))
   $error)

(= (codex:exec-server-rpc-client-call-dispatch-after-start
      $state
      $request-id
      $method
      (CodexExecServerRpcSerializeOutcomeErr $message)
      $send-outcome)
   (CodexExecServerRpcClientCallDispatchErr
     (codex:exec-server-rpc-client-state-remove-pending
       $state
       $request-id)
     (CodexExecServerRpcCallErrorJson $message)))

(= (codex:exec-server-rpc-client-call-dispatch-after-start
      $state
      $request-id
      $method
      (CodexExecServerRpcSerializeOutcomeOk $params-json)
      (CodexExecServerRpcClientSendClosed))
   (CodexExecServerRpcClientCallDispatchErr
     (codex:exec-server-rpc-client-state-remove-pending
       $state
       $request-id)
     (CodexExecServerRpcCallErrorClosed)))

(= (codex:exec-server-rpc-client-call-dispatch-after-start
      $state
      $request-id
      $method
      (CodexExecServerRpcSerializeOutcomeOk $params-json)
      (CodexExecServerRpcClientSendOk))
   (CodexExecServerRpcClientCallDispatchAwaiting
     $state
     $request-id
     (CodexExecServerRpcMessageRequest
       (CodexExecServerRpcRequest
         $request-id
         $method
         $params-json
         CodexAbsent))))

(= (codex:exec-server-rpc-client-call-dispatch
      $state
      $method
      $label
      $serialize-outcome
      $send-outcome)
   (case (codex:exec-server-rpc-client-start-call $state $label)
     (((CodexExecServerRpcCallStartClosed $next-state)
       (CodexExecServerRpcClientCallDispatchErr
         $next-state
         (CodexExecServerRpcCallErrorClosed)))
      ((CodexExecServerRpcCallStartOk $request-id $next-state)
       (codex:exec-server-rpc-client-call-dispatch-after-start
         $next-state
         $request-id
         $method
         $serialize-outcome
         $send-outcome)))))

(= (codex:exec-server-rpc-client-call-finish-ok $value)
   (CodexExecServerRpcClientCallFinishOk $value))

(= (codex:exec-server-rpc-client-call-finish-err $error)
   (CodexExecServerRpcClientCallFinishErr $error))

(= (codex:exec-server-rpc-client-call-finish-result-value
      (CodexExecServerRpcClientCallFinishOk $value))
   $value)

(= (codex:exec-server-rpc-client-call-finish-result-error
      (CodexExecServerRpcClientCallFinishErr $error))
   $error)

(= (codex:exec-server-rpc-client-call-finish
      (CodexExecServerRpcErr $error)
      $deserialize-outcome)
   (CodexExecServerRpcClientCallFinishErr $error))

(= (codex:exec-server-rpc-client-call-finish
      (CodexExecServerRpcOk $json)
      (CodexExecServerRpcDecodeOutcomeErr $message))
   (CodexExecServerRpcClientCallFinishErr
     (CodexExecServerRpcCallErrorJson $message)))

(= (codex:exec-server-rpc-client-call-finish
      (CodexExecServerRpcOk $json)
      (CodexExecServerRpcDecodeOutcomeOk $value))
   (CodexExecServerRpcClientCallFinishOk $value))

(= (codex:exec-server-rpc-handle-message-ignored $state)
   (CodexExecServerRpcHandleMessageIgnored $state))

(= (codex:exec-server-rpc-handle-message-delivered
      $state
      $label
      $result)
   (CodexExecServerRpcHandleMessageDelivered $state $label $result))

(= (codex:exec-server-rpc-handle-message-event $state $event)
   (CodexExecServerRpcHandleMessageEvent $state $event))

(= (codex:exec-server-rpc-handle-message-protocol-error
      $state
      $message)
   (CodexExecServerRpcHandleMessageProtocolError $state $message))

(= (codex:exec-server-rpc-handle-message-result-state
      (CodexExecServerRpcHandleMessageIgnored $state))
   $state)

(= (codex:exec-server-rpc-handle-message-result-state
      (CodexExecServerRpcHandleMessageDelivered $state $label $result))
   $state)

(= (codex:exec-server-rpc-handle-message-result-state
      (CodexExecServerRpcHandleMessageEvent $state $event))
   $state)

(= (codex:exec-server-rpc-handle-message-result-state
      (CodexExecServerRpcHandleMessageProtocolError $state $message))
   $state)

(= (codex:exec-server-rpc-handle-message-result-label
      (CodexExecServerRpcHandleMessageDelivered $state $label $result))
   $label)

(= (codex:exec-server-rpc-handle-message-result-result
      (CodexExecServerRpcHandleMessageDelivered $state $label $result))
   $result)

(= (codex:exec-server-rpc-handle-message-result-event
      (CodexExecServerRpcHandleMessageEvent $state $event))
   $event)

(= (codex:exec-server-rpc-handle-message-result-message
      (CodexExecServerRpcHandleMessageProtocolError $state $message))
   $message)

(= (codex:exec-server-rpc-handle-response
      (CodexExecServerRpcClientState
        $next-request-id
        $pending
        $disconnected)
      $request-id
      $result)
   (case (codex:exec-server-rpc-pending-remove $pending $request-id)
     (((CodexExecServerRpcPendingRemoveMissing $next-pending)
       (CodexExecServerRpcHandleMessageIgnored
         (CodexExecServerRpcClientState
           $next-request-id
           $next-pending
           $disconnected)))
      ((CodexExecServerRpcPendingRemoveFound $label $next-pending)
       (CodexExecServerRpcHandleMessageDelivered
         (CodexExecServerRpcClientState
           $next-request-id
           $next-pending
           $disconnected)
         $label
         (CodexExecServerRpcOk $result))))))

(= (codex:exec-server-rpc-handle-error
      (CodexExecServerRpcClientState
        $next-request-id
        $pending
        $disconnected)
      $request-id
      $error)
   (case (codex:exec-server-rpc-pending-remove $pending $request-id)
     (((CodexExecServerRpcPendingRemoveMissing $next-pending)
       (CodexExecServerRpcHandleMessageIgnored
         (CodexExecServerRpcClientState
           $next-request-id
           $next-pending
           $disconnected)))
      ((CodexExecServerRpcPendingRemoveFound $label $next-pending)
       (CodexExecServerRpcHandleMessageDelivered
         (CodexExecServerRpcClientState
           $next-request-id
           $next-pending
           $disconnected)
         $label
         (CodexExecServerRpcErr
           (CodexExecServerRpcCallErrorServer $error)))))))

(= (codex:exec-server-rpc-handle-server-message $state $message)
   (case $message
     (((CodexExecServerRpcMessageResponse
         (CodexExecServerRpcResponse $id $result))
       (codex:exec-server-rpc-handle-response $state $id $result))
      ((CodexExecServerRpcMessageError
         (CodexExecServerRpcError $id $error))
       (codex:exec-server-rpc-handle-error $state $id $error))
      ((CodexExecServerRpcMessageNotification $notification)
       (CodexExecServerRpcHandleMessageEvent
         $state
         (CodexExecServerRpcClientEventNotification $notification)))
      ((CodexExecServerRpcMessageRequest
         (CodexExecServerRpcRequest $id $method $params $trace))
       (CodexExecServerRpcHandleMessageProtocolError
         $state
         (str-concat
           "unexpected JSON-RPC request from remote server: "
           $method))))))

(= (codex:exec-server-rpc-drain-pending-labels () $labels)
   (list:reverse $labels))

(= (codex:exec-server-rpc-drain-pending-labels $pending $labels)
   (codex:exec-server-rpc-drain-pending-labels
     (list:rest $pending)
     (list:cons
       (codex:exec-server-rpc-pending-request-label (list:first $pending))
       $labels)))

(= (codex:exec-server-rpc-drain-pending-result $state $closed-labels)
   (CodexExecServerRpcDrainPendingResult $state $closed-labels))

(= (codex:exec-server-rpc-drain-pending-result-state
      (CodexExecServerRpcDrainPendingResult $state $closed-labels))
   $state)

(= (codex:exec-server-rpc-drain-pending-result-closed-labels
      (CodexExecServerRpcDrainPendingResult $state $closed-labels))
   $closed-labels)

(= (codex:exec-server-rpc-drain-pending
      (CodexExecServerRpcClientState
        $next-request-id
        $pending
        $disconnected))
   (CodexExecServerRpcDrainPendingResult
     (CodexExecServerRpcClientState
       $next-request-id
       ()
       $disconnected)
     (codex:exec-server-rpc-drain-pending-labels $pending ())))

(= (codex:exec-server-rpc-decode-outcome-ok $value)
   (CodexExecServerRpcDecodeOutcomeOk $value))

(= (codex:exec-server-rpc-decode-outcome-err $message)
   (CodexExecServerRpcDecodeOutcomeErr $message))

(= (codex:exec-server-rpc-is-empty-json-object $json)
   (case $json
     (((JsonObject ()) True)
      ($other False))))

(= (codex:exec-server-rpc-decode-params-policy
      $params
      $primary-outcome
      $null-outcome)
   (case $primary-outcome
     (((CodexExecServerRpcDecodeOutcomeOk $value)
       (CodexExecServerRpcDecodeOutcomeOk $value))
      ((CodexExecServerRpcDecodeOutcomeErr $primary-error)
       (if (codex:exec-server-rpc-is-empty-json-object $params)
           (case $null-outcome
             (((CodexExecServerRpcDecodeOutcomeOk $null-value)
               (CodexExecServerRpcDecodeOutcomeOk $null-value))
              ((CodexExecServerRpcDecodeOutcomeErr $null-error)
               (CodexExecServerRpcDecodeOutcomeErr $primary-error))))
           (CodexExecServerRpcDecodeOutcomeErr $primary-error))))))

(= (codex:exec-server-rpc-decode-request-params-policy
      $params
      $primary-outcome
      $null-outcome)
   (case (codex:exec-server-rpc-decode-params-policy
           $params
           $primary-outcome
           $null-outcome)
     (((CodexExecServerRpcDecodeOutcomeOk $value)
       (CodexExecServerRpcOk $value))
      ((CodexExecServerRpcDecodeOutcomeErr $message)
       (CodexExecServerRpcErr
         (codex:exec-server-rpc-invalid-params $message))))))

(= (codex:exec-server-rpc-decode-notification-params-policy
      $params
      $primary-outcome
      $null-outcome)
   (codex:exec-server-rpc-decode-params-policy
     $params
     $primary-outcome
     $null-outcome))

(= (codex:exec-server-rpc-serialize-outcome-ok $json)
   (CodexExecServerRpcSerializeOutcomeOk $json))

(= (codex:exec-server-rpc-serialize-outcome-err $message)
   (CodexExecServerRpcSerializeOutcomeErr $message))

(= (codex:exec-server-rpc-request-route-result-none)
   (CodexExecServerRpcRequestRouteResultNone))

(= (codex:exec-server-rpc-request-route-result-some $outbound)
   (CodexExecServerRpcRequestRouteResultSome $outbound))

(= (codex:exec-server-rpc-request-route-result-outbound
      (CodexExecServerRpcRequestRouteResultSome $outbound))
   $outbound)

(= (codex:exec-server-rpc-notification-handler-ok)
   (CodexExecServerRpcNotificationHandlerOk))

(= (codex:exec-server-rpc-notification-handler-err $message)
   (CodexExecServerRpcNotificationHandlerErr $message))

(= (codex:exec-server-rpc-notification-route-result-ok)
   (CodexExecServerRpcNotificationRouteResultOk))

(= (codex:exec-server-rpc-notification-route-result-err $message)
   (CodexExecServerRpcNotificationRouteResultErr $message))

(= (codex:exec-server-rpc-notification-route-result-message
      (CodexExecServerRpcNotificationRouteResultErr $message))
   $message)

(= (codex:exec-server-rpc-router-request-invoke
      (CodexExecServerRpcRequest $id $method $params $trace)
      (CodexExecServerRpcErr $error)
      $handler-outcome
      $serialize-outcome)
   (CodexExecServerRpcRequestRouteResultSome
     (CodexExecServerRpcServerOutboundError $id $error)))

(= (codex:exec-server-rpc-router-request-invoke
      (CodexExecServerRpcRequest $id $method $params $trace)
      (CodexExecServerRpcOk $decoded-params)
      (CodexExecServerRpcErr $error)
      $serialize-outcome)
   (CodexExecServerRpcRequestRouteResultSome
     (CodexExecServerRpcServerOutboundError $id $error)))

(= (codex:exec-server-rpc-router-request-invoke
      (CodexExecServerRpcRequest $id $method $params $trace)
      (CodexExecServerRpcOk $decoded-params)
      (CodexExecServerRpcOk $handler-value)
      (CodexExecServerRpcSerializeOutcomeErr $message))
   (CodexExecServerRpcRequestRouteResultSome
     (CodexExecServerRpcServerOutboundError
       $id
       (codex:exec-server-rpc-internal-error $message))))

(= (codex:exec-server-rpc-router-request-invoke
      (CodexExecServerRpcRequest $id $method $params $trace)
      (CodexExecServerRpcOk $decoded-params)
      (CodexExecServerRpcOk $handler-value)
      (CodexExecServerRpcSerializeOutcomeOk $json))
   (CodexExecServerRpcRequestRouteResultSome
     (CodexExecServerRpcServerOutboundResponse $id $json)))

(= (codex:exec-server-rpc-router-request-with-id-invoke
      (CodexExecServerRpcRequest $id $method $params $trace)
      (CodexExecServerRpcErr $error)
      $handler-outcome)
   (CodexExecServerRpcRequestRouteResultSome
     (CodexExecServerRpcServerOutboundError $id $error)))

(= (codex:exec-server-rpc-router-request-with-id-invoke
      (CodexExecServerRpcRequest $id $method $params $trace)
      (CodexExecServerRpcOk $decoded-params)
      (CodexExecServerRpcErr $error))
   (CodexExecServerRpcRequestRouteResultSome
     (CodexExecServerRpcServerOutboundError $id $error)))

(= (codex:exec-server-rpc-router-request-with-id-invoke
      (CodexExecServerRpcRequest $id $method $params $trace)
      (CodexExecServerRpcOk $decoded-params)
      (CodexExecServerRpcOk $unit))
   (CodexExecServerRpcRequestRouteResultNone))

(= (codex:exec-server-rpc-router-notification-invoke
      (CodexExecServerRpcNotification $method $params)
      (CodexExecServerRpcDecodeOutcomeErr $message)
      $handler-outcome)
   (CodexExecServerRpcNotificationRouteResultErr $message))

(= (codex:exec-server-rpc-router-notification-invoke
      (CodexExecServerRpcNotification $method $params)
      (CodexExecServerRpcDecodeOutcomeOk $decoded-params)
      (CodexExecServerRpcNotificationHandlerErr $message))
   (CodexExecServerRpcNotificationRouteResultErr $message))

(= (codex:exec-server-rpc-router-notification-invoke
      (CodexExecServerRpcNotification $method $params)
      (CodexExecServerRpcDecodeOutcomeOk $decoded-params)
      (CodexExecServerRpcNotificationHandlerOk))
   (CodexExecServerRpcNotificationRouteResultOk))

(= (codex:exec-server-rpc-route-entry $method $handler)
   (CodexExecServerRpcRouteEntry $method $handler))

(= (codex:exec-server-rpc-route-entry-method
      (CodexExecServerRpcRouteEntry $method $handler))
   $method)

(= (codex:exec-server-rpc-route-entry-handler
      (CodexExecServerRpcRouteEntry $method $handler))
   $handler)

(= (codex:exec-server-rpc-route-lookup () $method)
   CodexAbsent)

(= (codex:exec-server-rpc-route-lookup $routes $method)
   (let $head (list:first $routes)
     (if (== (codex:exec-server-rpc-route-entry-method $head) $method)
         (codex:exec-server-rpc-route-entry-handler $head)
         (codex:exec-server-rpc-route-lookup
           (list:rest $routes)
           $method))))

(= (codex:exec-server-rpc-route-upsert () $method $handler)
   (list:cons
     (CodexExecServerRpcRouteEntry $method $handler)
     ()))

(= (codex:exec-server-rpc-route-upsert $routes $method $handler)
   (let $head (list:first $routes)
     (let $tail (list:rest $routes)
       (if (== (codex:exec-server-rpc-route-entry-method $head) $method)
           (list:cons
             (CodexExecServerRpcRouteEntry $method $handler)
             $tail)
           (list:cons
             $head
             (codex:exec-server-rpc-route-upsert
               $tail
               $method
               $handler))))))

(= (codex:exec-server-rpc-router $request-routes $notification-routes)
   (CodexExecServerRpcRouter $request-routes $notification-routes))

(= (codex:exec-server-rpc-router-new)
   (CodexExecServerRpcRouter () ()))

(= (codex:exec-server-rpc-router-request-routes
      (CodexExecServerRpcRouter $request-routes $notification-routes))
   $request-routes)

(= (codex:exec-server-rpc-router-notification-routes
      (CodexExecServerRpcRouter $request-routes $notification-routes))
   $notification-routes)

(= (codex:exec-server-rpc-router-request
      (CodexExecServerRpcRouter $request-routes $notification-routes)
      $method
      $handler)
   (CodexExecServerRpcRouter
     (codex:exec-server-rpc-route-upsert $request-routes $method $handler)
     $notification-routes))

(= (codex:exec-server-rpc-router-request-with-id
      (CodexExecServerRpcRouter $request-routes $notification-routes)
      $method
      $handler)
   (CodexExecServerRpcRouter
     (codex:exec-server-rpc-route-upsert $request-routes $method $handler)
     $notification-routes))

(= (codex:exec-server-rpc-router-notification
      (CodexExecServerRpcRouter $request-routes $notification-routes)
      $method
      $handler)
   (CodexExecServerRpcRouter
     $request-routes
     (codex:exec-server-rpc-route-upsert
       $notification-routes
       $method
       $handler)))

(= (codex:exec-server-rpc-router-request-route $router $method)
   (codex:exec-server-rpc-route-lookup
     (codex:exec-server-rpc-router-request-routes $router)
     $method))

(= (codex:exec-server-rpc-router-notification-route $router $method)
   (codex:exec-server-rpc-route-lookup
     (codex:exec-server-rpc-router-notification-routes $router)
     $method))
