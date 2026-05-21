; Rust-faithful exec-server HTTP body stream client slice.
;
; This ports deterministic client-side behavior from:
; - openai-codex/codex-rs/exec-server/src/client/rpc_http_client.rs
;   - HTTP_BODY_DELTA_CHANNEL_CAPACITY
;   - buffered request forcing `stream_response = false`
;   - streamed request id generation, `stream_response = true`, route insert
; - openai-codex/codex-rs/exec-server/src/client/http_response_body_stream.rs
;   - HttpResponseBodyStream::remote initial state
;   - HttpResponseBodyStream::recv sequencing/EOF/error behavior
;   - body-delta route handling for unknown, terminal, and full routes
;   - fail-all behavior for transport disconnect
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust stores body routes in `ArcSwap<HashMap<String, Sender<_>>>` and uses
;   bounded Tokio mpsc channels. This pure CeTTa slice represents the routing
;   table as an ordered request-id list and represents receiver state as an
;   explicit queue. The route decisions, generated ids, capacity boundary,
;   sequence checks, EOF handling, and failure messages are preserved.
; - Rust errors are returned as `ExecServerError::Protocol(message)`, whose
;   display adds the `exec-server protocol error:` prefix. This slice returns
;   the protocol message itself so callers can wrap it at the later error
;   boundary without changing the stream algorithm.

!(import! &self list)
!(import! &self exec_server_process_protocol)
!(import! &self exec_server_http_protocol)

(= (codex:exec-server-http-body-delta-channel-capacity)
   256)

(= (codex:exec-server-http-body-backpressure-message)
   "body delta channel filled before delivery")

(= (codex:exec-server-http-body-transport-disconnected-message)
   "exec-server transport disconnected")

(= (codex:exec-server-http-body-client-state $next-id $route-ids)
   (CodexExecServerHttpBodyClientState $next-id $route-ids))

(= (codex:exec-server-http-body-client-state-default)
   (CodexExecServerHttpBodyClientState 1 ()))

(= (codex:exec-server-http-body-client-state-next-id
      (CodexExecServerHttpBodyClientState $next-id $route-ids))
   $next-id)

(= (codex:exec-server-http-body-client-state-route-ids
      (CodexExecServerHttpBodyClientState $next-id $route-ids))
   $route-ids)

(= (codex:exec-server-http-body-client-state-with-route-ids
      (CodexExecServerHttpBodyClientState $next-id $route-ids)
      $new-route-ids)
   (CodexExecServerHttpBodyClientState $next-id $new-route-ids))

(= (codex:exec-server-http-body-request-id-from-counter $counter)
   (format-args "http-{}" ($counter)))

(= (codex:exec-server-http-body-next-request-id-result
      $request-id
      $state)
   (CodexExecServerHttpBodyNextRequestIdResult $request-id $state))

(= (codex:exec-server-http-body-next-request-id-result-request-id
      (CodexExecServerHttpBodyNextRequestIdResult $request-id $state))
   $request-id)

(= (codex:exec-server-http-body-next-request-id-result-state
      (CodexExecServerHttpBodyNextRequestIdResult $request-id $state))
   $state)

(= (codex:exec-server-http-body-next-request-id
      (CodexExecServerHttpBodyClientState $next-id $route-ids))
   (CodexExecServerHttpBodyNextRequestIdResult
     (codex:exec-server-http-body-request-id-from-counter $next-id)
     (CodexExecServerHttpBodyClientState
       (+ $next-id 1)
       $route-ids)))

(= (codex:exec-server-http-body-route-id-contains () $request-id)
   False)

(= (codex:exec-server-http-body-route-id-contains $route-ids $request-id)
   (if (== (list:first $route-ids) $request-id)
       True
       (codex:exec-server-http-body-route-id-contains
         (list:rest $route-ids)
         $request-id)))

(= (codex:exec-server-http-body-route-id-remove () $request-id)
   ())

(= (codex:exec-server-http-body-route-id-remove $route-ids $request-id)
   (let $head (list:first $route-ids)
     (let $tail
       (codex:exec-server-http-body-route-id-remove
         (list:rest $route-ids)
         $request-id)
       (if (== $head $request-id)
           $tail
           (list:cons $head $tail)))))

(= (codex:exec-server-http-body-route-active $state $request-id)
   (codex:exec-server-http-body-route-id-contains
     (codex:exec-server-http-body-client-state-route-ids $state)
     $request-id))

(= (codex:exec-server-http-body-insert-route-ok $state)
   (CodexExecServerHttpBodyInsertRouteOk $state))

(= (codex:exec-server-http-body-insert-route-err $message)
   (CodexExecServerHttpBodyInsertRouteErr $message))

(= (codex:exec-server-http-body-insert-route-result-state
      (CodexExecServerHttpBodyInsertRouteOk $state))
   $state)

(= (codex:exec-server-http-body-insert-route-result-message
      (CodexExecServerHttpBodyInsertRouteErr $message))
   $message)

(= (codex:exec-server-http-body-insert-route $state $request-id)
   (if (codex:exec-server-http-body-route-active $state $request-id)
       (CodexExecServerHttpBodyInsertRouteErr
         (format-args
           "http response stream already registered for request {}"
           ($request-id)))
       (CodexExecServerHttpBodyInsertRouteOk
         (codex:exec-server-http-body-client-state-with-route-ids
           $state
           (list:append
             (codex:exec-server-http-body-client-state-route-ids $state)
             (list:cons $request-id ()))))))

(= (codex:exec-server-http-body-remove-route $state $request-id)
   (codex:exec-server-http-body-client-state-with-route-ids
     $state
     (codex:exec-server-http-body-route-id-remove
       (codex:exec-server-http-body-client-state-route-ids $state)
       $request-id)))

(= (codex:exec-server-http-body-force-buffered-request
      (CodexExecServerHttpRequestParams
        $method
        $url
        $headers
        $body
        $timeout-ms
        $request-id
        $stream-response))
   (codex:exec-server-http-request-params
     $method
     $url
     $headers
     $body
     $timeout-ms
     $request-id
     False))

(= (codex:exec-server-http-body-force-streamed-request
      (CodexExecServerHttpRequestParams
        $method
        $url
        $headers
        $body
        $timeout-ms
        $request-id
        $stream-response)
      $generated-request-id)
   (codex:exec-server-http-request-params
     $method
     $url
     $headers
     $body
     $timeout-ms
     $generated-request-id
     True))

(= (codex:exec-server-http-body-prepare-stream-request-ok
      $state
      $params
      $stream)
   (CodexExecServerHttpBodyPrepareStreamRequestOk
     $state
     $params
     $stream))

(= (codex:exec-server-http-body-prepare-stream-request-err $message)
   (CodexExecServerHttpBodyPrepareStreamRequestErr $message))

(= (codex:exec-server-http-body-prepare-stream-request-result-state
      (CodexExecServerHttpBodyPrepareStreamRequestOk
        $state
        $params
        $stream))
   $state)

(= (codex:exec-server-http-body-prepare-stream-request-result-params
      (CodexExecServerHttpBodyPrepareStreamRequestOk
        $state
        $params
        $stream))
   $params)

(= (codex:exec-server-http-body-prepare-stream-request-result-stream
      (CodexExecServerHttpBodyPrepareStreamRequestOk
        $state
        $params
        $stream))
   $stream)

(= (codex:exec-server-http-body-prepare-stream-request-result-message
      (CodexExecServerHttpBodyPrepareStreamRequestErr $message))
   $message)

(= (codex:exec-server-http-body-prepare-stream-request $state $params)
   (let $next
     (codex:exec-server-http-body-next-request-id $state)
     (let $request-id
       (codex:exec-server-http-body-next-request-id-result-request-id $next)
       (case (codex:exec-server-http-body-insert-route
               (codex:exec-server-http-body-next-request-id-result-state $next)
               $request-id)
         (((CodexExecServerHttpBodyInsertRouteOk $inserted-state)
           (CodexExecServerHttpBodyPrepareStreamRequestOk
             $inserted-state
             (codex:exec-server-http-body-force-streamed-request
               $params
               $request-id)
             (codex:exec-server-http-body-remote-stream-new
               $request-id)))
          ((CodexExecServerHttpBodyInsertRouteErr $message)
           (CodexExecServerHttpBodyPrepareStreamRequestErr $message)))))))

(= (codex:exec-server-http-body-delta-request-id
      (CodexExecServerHttpRequestBodyDeltaNotification
        $request-id
        $seq
        $delta
        $done
        $error))
   $request-id)

(= (codex:exec-server-http-body-delta-seq
      (CodexExecServerHttpRequestBodyDeltaNotification
        $request-id
        $seq
        $delta
        $done
        $error))
   $seq)

(= (codex:exec-server-http-body-delta-chunk
      (CodexExecServerHttpRequestBodyDeltaNotification
        $request-id
        $seq
        $delta
        $done
        $error))
   $delta)

(= (codex:exec-server-http-body-delta-done
      (CodexExecServerHttpRequestBodyDeltaNotification
        $request-id
        $seq
        $delta
        $done
        $error))
   $done)

(= (codex:exec-server-http-body-delta-error
      (CodexExecServerHttpRequestBodyDeltaNotification
        $request-id
        $seq
        $delta
        $done
        $error))
   $error)

(= (codex:exec-server-http-body-delta-terminal $delta)
   (or (codex:exec-server-http-body-delta-done $delta)
       (not
         (== (codex:exec-server-http-body-delta-error $delta)
             CodexAbsent))))

(= (codex:exec-server-http-body-route-delta-delivered
      $state
      $removed)
   (CodexExecServerHttpBodyRouteDeltaDelivered $state $removed))

(= (codex:exec-server-http-body-route-delta-ignored $state)
   (CodexExecServerHttpBodyRouteDeltaIgnored $state))

(= (codex:exec-server-http-body-route-delta-backpressure
      $state
      $message)
   (CodexExecServerHttpBodyRouteDeltaBackpressure $state $message))

(= (codex:exec-server-http-body-route-delta-result-state
      (CodexExecServerHttpBodyRouteDeltaDelivered $state $removed))
   $state)

(= (codex:exec-server-http-body-route-delta-result-state
      (CodexExecServerHttpBodyRouteDeltaIgnored $state))
   $state)

(= (codex:exec-server-http-body-route-delta-result-state
      (CodexExecServerHttpBodyRouteDeltaBackpressure $state $message))
   $state)

(= (codex:exec-server-http-body-route-delta-result-message
      (CodexExecServerHttpBodyRouteDeltaBackpressure $state $message))
   $message)

(= (codex:exec-server-http-body-handle-delta-route
      $state
      $delta
      $queued-frames)
   (let $request-id (codex:exec-server-http-body-delta-request-id $delta)
     (if (not
           (codex:exec-server-http-body-route-active $state $request-id))
         (CodexExecServerHttpBodyRouteDeltaIgnored $state)
         (if (>= $queued-frames
                 (codex:exec-server-http-body-delta-channel-capacity))
             (CodexExecServerHttpBodyRouteDeltaBackpressure
               (codex:exec-server-http-body-remove-route
                 $state
                 $request-id)
               (codex:exec-server-http-body-backpressure-message))
             (if (codex:exec-server-http-body-delta-terminal $delta)
                 (CodexExecServerHttpBodyRouteDeltaDelivered
                   (codex:exec-server-http-body-remove-route
                     $state
                     $request-id)
                   True)
                 (CodexExecServerHttpBodyRouteDeltaDelivered
                   $state
                   False))))))

(= (codex:exec-server-http-body-remote-stream
      $request-id
      $next-seq
      $pending-eof
      $closed
      $queue
      $failure)
   (CodexExecServerHttpBodyRemoteStream
     $request-id
     $next-seq
     $pending-eof
     $closed
     $queue
     $failure))

(= (codex:exec-server-http-body-remote-stream-new $request-id)
   (CodexExecServerHttpBodyRemoteStream
     $request-id
     1
     False
     False
     ()
     CodexAbsent))

(= (codex:exec-server-http-body-remote-stream-request-id
      (CodexExecServerHttpBodyRemoteStream
        $request-id
        $next-seq
        $pending-eof
        $closed
        $queue
        $failure))
   $request-id)

(= (codex:exec-server-http-body-remote-stream-next-seq
      (CodexExecServerHttpBodyRemoteStream
        $request-id
        $next-seq
        $pending-eof
        $closed
        $queue
        $failure))
   $next-seq)

(= (codex:exec-server-http-body-remote-stream-pending-eof
      (CodexExecServerHttpBodyRemoteStream
        $request-id
        $next-seq
        $pending-eof
        $closed
        $queue
        $failure))
   $pending-eof)

(= (codex:exec-server-http-body-remote-stream-closed
      (CodexExecServerHttpBodyRemoteStream
        $request-id
        $next-seq
        $pending-eof
        $closed
        $queue
        $failure))
   $closed)

(= (codex:exec-server-http-body-remote-stream-queue
      (CodexExecServerHttpBodyRemoteStream
        $request-id
        $next-seq
        $pending-eof
        $closed
        $queue
        $failure))
   $queue)

(= (codex:exec-server-http-body-remote-stream-failure
      (CodexExecServerHttpBodyRemoteStream
        $request-id
        $next-seq
        $pending-eof
        $closed
        $queue
        $failure))
   $failure)

(= (codex:exec-server-http-body-remote-stream-with-queue
      (CodexExecServerHttpBodyRemoteStream
        $request-id
        $next-seq
        $pending-eof
        $closed
        $queue
        $failure)
      $new-queue)
   (CodexExecServerHttpBodyRemoteStream
     $request-id
     $next-seq
     $pending-eof
     $closed
     $new-queue
     $failure))

(= (codex:exec-server-http-body-remote-stream-with-failure
      (CodexExecServerHttpBodyRemoteStream
        $request-id
        $next-seq
        $pending-eof
        $closed
        $queue
        $failure)
      $new-failure)
   (CodexExecServerHttpBodyRemoteStream
     $request-id
     $next-seq
     $pending-eof
     $closed
     $queue
     $new-failure))

(= (codex:exec-server-http-body-stream-enqueue-ok $stream)
   (CodexExecServerHttpBodyStreamEnqueueOk $stream))

(= (codex:exec-server-http-body-stream-enqueue-full
      $stream
      $message)
   (CodexExecServerHttpBodyStreamEnqueueFull $stream $message))

(= (codex:exec-server-http-body-stream-enqueue-closed $stream)
   (CodexExecServerHttpBodyStreamEnqueueClosed $stream))

(= (codex:exec-server-http-body-stream-enqueue-result-stream
      (CodexExecServerHttpBodyStreamEnqueueOk $stream))
   $stream)

(= (codex:exec-server-http-body-stream-enqueue-result-stream
      (CodexExecServerHttpBodyStreamEnqueueFull $stream $message))
   $stream)

(= (codex:exec-server-http-body-stream-enqueue-result-stream
      (CodexExecServerHttpBodyStreamEnqueueClosed $stream))
   $stream)

(= (codex:exec-server-http-body-stream-enqueue-result-message
      (CodexExecServerHttpBodyStreamEnqueueFull $stream $message))
   $message)

(= (codex:exec-server-http-body-stream-enqueue-delta $stream $delta)
   (if (codex:exec-server-http-body-remote-stream-closed $stream)
       (CodexExecServerHttpBodyStreamEnqueueClosed $stream)
       (if (>= (list:len
                 (codex:exec-server-http-body-remote-stream-queue $stream))
               (codex:exec-server-http-body-delta-channel-capacity))
           (CodexExecServerHttpBodyStreamEnqueueFull
             (codex:exec-server-http-body-remote-stream-with-failure
               $stream
               (codex:exec-server-http-body-backpressure-message))
             (codex:exec-server-http-body-backpressure-message))
           (CodexExecServerHttpBodyStreamEnqueueOk
             (codex:exec-server-http-body-remote-stream-with-queue
               $stream
               (list:append
                 (codex:exec-server-http-body-remote-stream-queue $stream)
                 (list:cons $delta ())))))))

(= (codex:exec-server-http-body-stream-fail $stream $message)
   (codex:exec-server-http-body-stream-enqueue-delta
     $stream
     (codex:exec-server-http-body-delta-notification
       (codex:exec-server-http-body-remote-stream-request-id $stream)
       1
       (codex:exec-server-byte-chunk "")
       True
       $message)))

(= (codex:exec-server-http-body-recv-chunk $chunk $stream)
   (CodexExecServerHttpBodyRecvChunk $chunk $stream))

(= (codex:exec-server-http-body-recv-eof $stream)
   (CodexExecServerHttpBodyRecvEof $stream))

(= (codex:exec-server-http-body-recv-err $message $stream)
   (CodexExecServerHttpBodyRecvErr $message $stream))

(= (codex:exec-server-http-body-recv-result-kind
      (CodexExecServerHttpBodyRecvChunk $chunk $stream))
   "chunk")

(= (codex:exec-server-http-body-recv-result-kind
      (CodexExecServerHttpBodyRecvEof $stream))
   "eof")

(= (codex:exec-server-http-body-recv-result-kind
      (CodexExecServerHttpBodyRecvErr $message $stream))
   "err")

(= (codex:exec-server-http-body-recv-result-chunk
      (CodexExecServerHttpBodyRecvChunk $chunk $stream))
   $chunk)

(= (codex:exec-server-http-body-recv-result-message
      (CodexExecServerHttpBodyRecvErr $message $stream))
   $message)

(= (codex:exec-server-http-body-recv-result-stream
      (CodexExecServerHttpBodyRecvChunk $chunk $stream))
   $stream)

(= (codex:exec-server-http-body-recv-result-stream
      (CodexExecServerHttpBodyRecvEof $stream))
   $stream)

(= (codex:exec-server-http-body-recv-result-stream
      (CodexExecServerHttpBodyRecvErr $message $stream))
   $stream)

(= (codex:exec-server-http-body-recv-failed-message
      $request-id
      $error)
   (format-args
     "http response stream `{}` failed: {}"
     ($request-id $error)))

(= (codex:exec-server-http-body-recv-seq-error-message
      $request-id
      $actual
      $expected)
   (format-args
     "http response stream `{}` received seq {}, expected {}"
     ($request-id $actual $expected)))

(= (codex:exec-server-http-body-stream-recv
      (CodexExecServerHttpBodyRemoteStream
        $request-id
        $next-seq
        True
        $closed
        $queue
        $failure))
   (CodexExecServerHttpBodyRecvEof
     (CodexExecServerHttpBodyRemoteStream
       $request-id
       $next-seq
       False
       True
       $queue
       $failure)))

(= (codex:exec-server-http-body-stream-recv
      (CodexExecServerHttpBodyRemoteStream
        $request-id
        $next-seq
        False
        $closed
        $queue
        $failure))
   (if (== $queue ())
       (if (== $failure CodexAbsent)
           (CodexExecServerHttpBodyRecvEof
             (CodexExecServerHttpBodyRemoteStream
               $request-id
               $next-seq
               False
               True
               ()
               CodexAbsent))
           (CodexExecServerHttpBodyRecvErr
             (codex:exec-server-http-body-recv-failed-message
               $request-id
               $failure)
             (CodexExecServerHttpBodyRemoteStream
               $request-id
               $next-seq
               False
               True
               ()
               CodexAbsent)))
       (let $delta (list:first $queue)
         (let $tail (list:rest $queue)
           (let $actual-seq
             (codex:exec-server-http-body-delta-seq $delta)
             (if (not (== $actual-seq $next-seq))
                 (CodexExecServerHttpBodyRecvErr
                   (codex:exec-server-http-body-recv-seq-error-message
                     $request-id
                     $actual-seq
                     $next-seq)
                   (CodexExecServerHttpBodyRemoteStream
                     $request-id
                     $next-seq
                     False
                     True
                     $tail
                     $failure))
                 (let $next-stream
                   (CodexExecServerHttpBodyRemoteStream
                     $request-id
                     (+ $next-seq 1)
                     False
                     $closed
                     $tail
                     $failure)
                   (let $error
                     (codex:exec-server-http-body-delta-error $delta)
                     (if (not (== $error CodexAbsent))
                         (CodexExecServerHttpBodyRecvErr
                           (codex:exec-server-http-body-recv-failed-message
                             $request-id
                             $error)
                           (CodexExecServerHttpBodyRemoteStream
                             $request-id
                             (+ $next-seq 1)
                             False
                             True
                             $tail
                             $failure))
                         (let $chunk
                           (codex:exec-server-byte-chunk-into-inner
                             (codex:exec-server-http-body-delta-chunk $delta))
                           (if (codex:exec-server-http-body-delta-done $delta)
                               (if (== $chunk "")
                                   (CodexExecServerHttpBodyRecvEof
                                     (CodexExecServerHttpBodyRemoteStream
                                       $request-id
                                       (+ $next-seq 1)
                                       False
                                       True
                                       $tail
                                       $failure))
                                   (CodexExecServerHttpBodyRecvChunk
                                     $chunk
                                     (CodexExecServerHttpBodyRemoteStream
                                       $request-id
                                       (+ $next-seq 1)
                                       True
                                       True
                                       $tail
                                       $failure)))
                               (CodexExecServerHttpBodyRecvChunk
                                 $chunk
                                 $next-stream))))))))))))
