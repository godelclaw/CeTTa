; Rust-faithful exec-server reqwest HTTP client slice.
;
; This ports deterministic streaming behavior from:
; - openai-codex/codex-rs/exec-server/src/client/reqwest_http_client.rs
;   - PendingReqwestHttpBodyStream shape
;   - ReqwestHttpRequestRunner::stream_body body chunk loop
;     sequence numbering, notification construction, send-failure return,
;     body-error terminal notification, and EOF terminal notification
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust reads `reqwest::Response::bytes_stream()` asynchronously and sends
;   notifications through `RpcNotificationSender`. This pure slice receives
;   symbolic body items and symbolic send results at that runtime boundary,
;   preserving the exact loop decisions and emitted notification payloads.
; - Rust byte vectors may contain arbitrary bytes. This slice reuses the
;   current text-backed `ByteChunk` representation from the process protocol.

!(import! &self list)
!(import! &self exec_server_process_protocol)
!(import! &self exec_server_http_protocol)

(= (codex:exec-server-reqwest-http-pending-body-stream
      $request-id
      $body-items)
   (CodexExecServerReqwestHttpPendingBodyStream
     $request-id
     $body-items))

(= (codex:exec-server-reqwest-http-pending-body-stream-request-id
      (CodexExecServerReqwestHttpPendingBodyStream
        $request-id
        $body-items))
   $request-id)

(= (codex:exec-server-reqwest-http-pending-body-stream-body-items
      (CodexExecServerReqwestHttpPendingBodyStream
        $request-id
        $body-items))
   $body-items)

(= (codex:exec-server-reqwest-http-body-item-ok $bytes)
   (CodexExecServerReqwestHttpBodyItemOk $bytes))

(= (codex:exec-server-reqwest-http-body-item-err $message)
   (CodexExecServerReqwestHttpBodyItemErr $message))

(= (codex:exec-server-reqwest-http-stream-body-result
      $notifications
      $next-seq
      $reason
      $remaining-body-items
      $remaining-send-results)
   (CodexExecServerReqwestHttpStreamBodyResult
     $notifications
     $next-seq
     $reason
     $remaining-body-items
     $remaining-send-results))

(= (codex:exec-server-reqwest-http-stream-body-result-notifications
      (CodexExecServerReqwestHttpStreamBodyResult
        $notifications
        $next-seq
        $reason
        $remaining-body-items
        $remaining-send-results))
   $notifications)

(= (codex:exec-server-reqwest-http-stream-body-result-next-seq
      (CodexExecServerReqwestHttpStreamBodyResult
        $notifications
        $next-seq
        $reason
        $remaining-body-items
        $remaining-send-results))
   $next-seq)

(= (codex:exec-server-reqwest-http-stream-body-result-reason
      (CodexExecServerReqwestHttpStreamBodyResult
        $notifications
        $next-seq
        $reason
        $remaining-body-items
        $remaining-send-results))
   $reason)

(= (codex:exec-server-reqwest-http-stream-body-result-remaining-body-items
      (CodexExecServerReqwestHttpStreamBodyResult
        $notifications
        $next-seq
        $reason
        $remaining-body-items
        $remaining-send-results))
   $remaining-body-items)

(= (codex:exec-server-reqwest-http-stream-body-result-remaining-send-results
      (CodexExecServerReqwestHttpStreamBodyResult
        $notifications
        $next-seq
        $reason
        $remaining-body-items
        $remaining-send-results))
   $remaining-send-results)

(= (codex:exec-server-reqwest-http-pop-send-result ())
   (CodexExecServerReqwestHttpSendResult True ()))

(= (codex:exec-server-reqwest-http-pop-send-result $send-results)
   (CodexExecServerReqwestHttpSendResult
     (list:first $send-results)
     (list:rest $send-results)))

(= (codex:exec-server-reqwest-http-send-result-delivered
      (CodexExecServerReqwestHttpSendResult $delivered $remaining))
   $delivered)

(= (codex:exec-server-reqwest-http-send-result-remaining
      (CodexExecServerReqwestHttpSendResult $delivered $remaining))
   $remaining)

(= (codex:exec-server-reqwest-http-body-delta
      $request-id
      $seq
      $bytes
      $done
      $error)
   (CodexExecServerHttpRequestBodyDeltaNotification
     $request-id
     $seq
     (CodexExecServerByteChunk $bytes)
     $done
     $error))

(= (codex:exec-server-reqwest-http-stream-body-acc
      $request-id
      ()
      $seq
      $send-results
      $notifications)
   (let $send
     (codex:exec-server-reqwest-http-pop-send-result $send-results)
     (CodexExecServerReqwestHttpStreamBodyResult
       (list:append
         $notifications
         ((codex:exec-server-reqwest-http-body-delta
            $request-id
            $seq
            ""
            True
            CodexAbsent)))
       $seq
       "eof"
       ()
       (codex:exec-server-reqwest-http-send-result-remaining $send))))

(= (codex:exec-server-reqwest-http-stream-body-acc
      $request-id
      $body-items
      $seq
      $send-results
      $notifications)
   (let $item (list:first $body-items)
     (let $tail (list:rest $body-items)
       (case $item
         (((CodexExecServerReqwestHttpBodyItemOk $bytes)
           (let $delta
             (codex:exec-server-reqwest-http-body-delta
               $request-id
               $seq
               $bytes
               False
               CodexAbsent)
             (let $send
               (codex:exec-server-reqwest-http-pop-send-result
                 $send-results)
               (let $next-notifications
                 (list:append $notifications ($delta))
                 (if (codex:exec-server-reqwest-http-send-result-delivered
                       $send)
                     (codex:exec-server-reqwest-http-stream-body-acc
                       $request-id
                       $tail
                       (+ $seq 1)
                       (codex:exec-server-reqwest-http-send-result-remaining
                         $send)
                       $next-notifications)
                     (CodexExecServerReqwestHttpStreamBodyResult
                       $next-notifications
                       $seq
                       "send_failed"
                       $tail
                       (codex:exec-server-reqwest-http-send-result-remaining
                         $send)))))))
          ((CodexExecServerReqwestHttpBodyItemErr $message)
           (let $send
             (codex:exec-server-reqwest-http-pop-send-result
               $send-results)
             (CodexExecServerReqwestHttpStreamBodyResult
               (list:append
                 $notifications
                 ((codex:exec-server-reqwest-http-body-delta
                    $request-id
                    $seq
                    ""
                    True
                    $message)))
               $seq
               "body_error"
               $tail
               (codex:exec-server-reqwest-http-send-result-remaining
                 $send)))))))))

(= (codex:exec-server-reqwest-http-stream-body
      (CodexExecServerReqwestHttpPendingBodyStream
        $request-id
        $body-items)
      $send-results)
   (codex:exec-server-reqwest-http-stream-body-acc
     $request-id
     $body-items
     1
     $send-results
     ()))
