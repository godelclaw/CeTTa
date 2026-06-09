; Rust-faithful exec-server reqwest HTTP client slice.
;
; This ports deterministic reqwest HTTP client behavior from:
; - openai-codex/codex-rs/exec-server/src/client/reqwest_http_client.rs
;   - PendingReqwestHttpBodyStream shape
;   - ReqwestHttpRequestRunner::run method/url/scheme/header validation,
;     send/body read error mapping, and stream-vs-buffered response shaping
;   - ReqwestHttpRequestRunner::stream_body body chunk loop
;     sequence numbering, notification construction, send-failure return,
;     body-error terminal notification, and EOF terminal notification
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust reads `reqwest::Response::bytes_stream()` asynchronously and sends
;   notifications through `RpcNotificationSender`. This pure slice receives
;   symbolic parser results, network responses, body items, and send results at
;   that runtime boundary, preserving the exact branch order and emitted
;   payloads.
; - Rust byte vectors may contain arbitrary bytes. This slice reuses the
;   current text-backed `ByteChunk` representation from the process protocol.

!(import! &self list)
!(import! &self str)
!(import! &self exec_server_process_protocol)
!(import! &self exec_server_http_protocol)
!(import! &self exec_server_rpc)

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

(= (codex:exec-server-reqwest-http-method-ok $method)
   (CodexExecServerReqwestHttpMethodOk $method))

(= (codex:exec-server-reqwest-http-method-err $message)
   (CodexExecServerReqwestHttpMethodErr $message))

(= (codex:exec-server-reqwest-http-url-ok $scheme $url)
   (CodexExecServerReqwestHttpUrlOk $scheme $url))

(= (codex:exec-server-reqwest-http-url-err $message)
   (CodexExecServerReqwestHttpUrlErr $message))

(= (codex:exec-server-reqwest-http-headers-ok $headers)
   (CodexExecServerReqwestHttpHeadersOk $headers))

(= (codex:exec-server-reqwest-http-headers-err $error)
   (CodexExecServerReqwestHttpHeadersErr $error))

(= (codex:exec-server-reqwest-http-network-response
      $status
      $headers
      $body-bytes
      $body-items)
   (CodexExecServerReqwestHttpNetworkResponse
     $status
     $headers
     $body-bytes
     $body-items))

(= (codex:exec-server-reqwest-http-send-ok $response)
   (CodexExecServerReqwestHttpSendOk $response))

(= (codex:exec-server-reqwest-http-send-err $message)
   (CodexExecServerReqwestHttpSendErr $message))

(= (codex:exec-server-reqwest-http-body-read-ok $bytes)
   (CodexExecServerReqwestHttpBodyReadOk $bytes))

(= (codex:exec-server-reqwest-http-body-read-err $message)
   (CodexExecServerReqwestHttpBodyReadErr $message))

(= (codex:exec-server-reqwest-http-raw-response-header $name $value)
   (CodexExecServerReqwestHttpRawResponseHeader $name $value))

(= (codex:exec-server-reqwest-http-response-headers ())
   ())

(= (codex:exec-server-reqwest-http-response-headers $headers)
   (let $head (list:first $headers)
     (let $tail
       (codex:exec-server-reqwest-http-response-headers
         (list:rest $headers))
       (case $head
         (((CodexExecServerReqwestHttpRawResponseHeader $name CodexAbsent)
           $tail)
          ((CodexExecServerReqwestHttpRawResponseHeader $name $value)
           (list:cons
             (CodexExecServerHttpHeader $name $value)
             $tail)))))))

(= (codex:exec-server-reqwest-http-run-result-ok
      $response
      $pending-stream)
   (CodexExecServerReqwestHttpRunResultOk
     $response
     $pending-stream))

(= (codex:exec-server-reqwest-http-run-result-err $error)
   (CodexExecServerReqwestHttpRunResultErr $error))

(= (codex:exec-server-reqwest-http-run-result-response
      (CodexExecServerReqwestHttpRunResultOk
        $response
        $pending-stream))
   $response)

(= (codex:exec-server-reqwest-http-run-result-pending-stream
      (CodexExecServerReqwestHttpRunResultOk
        $response
        $pending-stream))
   $pending-stream)

(= (codex:exec-server-reqwest-http-run-result-error
      (CodexExecServerReqwestHttpRunResultErr $error))
   $error)

(= (codex:exec-server-reqwest-http-invalid-method-error $message)
   (codex:exec-server-rpc-invalid-params
     (str-concat "http/request method is invalid: " $message)))

(= (codex:exec-server-reqwest-http-invalid-url-error $message)
   (codex:exec-server-rpc-invalid-params
     (str-concat "http/request url is invalid: " $message)))

(= (codex:exec-server-reqwest-http-unsupported-scheme-error $scheme)
   (codex:exec-server-rpc-invalid-params
     (str-concat
       "http/request only supports http and https URLs, got "
       $scheme)))

(= (codex:exec-server-reqwest-http-send-error $message)
   (codex:exec-server-rpc-internal-error
     (str-concat "http/request failed: " $message)))

(= (codex:exec-server-reqwest-http-body-read-error $message)
   (codex:exec-server-rpc-internal-error
     (str-concat
       "failed to read http/request response body: "
       $message)))

(= (codex:exec-server-reqwest-http-supported-scheme $scheme)
   (or (== $scheme "http") (== $scheme "https")))

(= (codex:exec-server-reqwest-http-run-after-send
      (CodexExecServerHttpRequestParams
        $method
        $url
        $headers
        $body
        $timeout-ms
        $request-id
        True)
      (CodexExecServerReqwestHttpNetworkResponse
        $status
        $response-headers
        $body-bytes
        $body-items)
      $body-read-outcome)
   (CodexExecServerReqwestHttpRunResultOk
     (CodexExecServerHttpRequestResponse
       $status
       (codex:exec-server-reqwest-http-response-headers
         $response-headers)
       (CodexExecServerByteChunk ""))
     (CodexExecServerReqwestHttpPendingBodyStream
       $request-id
       $body-items)))

(= (codex:exec-server-reqwest-http-run-after-send
      (CodexExecServerHttpRequestParams
        $method
        $url
        $headers
        $body
        $timeout-ms
        $request-id
        False)
      (CodexExecServerReqwestHttpNetworkResponse
        $status
        $response-headers
        $body-bytes
        $body-items)
      (CodexExecServerReqwestHttpBodyReadErr $message))
   (CodexExecServerReqwestHttpRunResultErr
     (codex:exec-server-reqwest-http-body-read-error $message)))

(= (codex:exec-server-reqwest-http-run-after-send
      (CodexExecServerHttpRequestParams
        $method
        $url
        $headers
        $body
        $timeout-ms
        $request-id
        False)
      (CodexExecServerReqwestHttpNetworkResponse
        $status
        $response-headers
        $body-bytes
        $body-items)
      (CodexExecServerReqwestHttpBodyReadOk $bytes))
   (CodexExecServerReqwestHttpRunResultOk
     (CodexExecServerHttpRequestResponse
       $status
       (codex:exec-server-reqwest-http-response-headers
         $response-headers)
       (CodexExecServerByteChunk $bytes))
     CodexAbsent))

(= (codex:exec-server-reqwest-http-run-flow
      $params
      (CodexExecServerReqwestHttpMethodErr $message)
      $url-outcome
      $headers-outcome
      $send-outcome
      $body-read-outcome)
   (CodexExecServerReqwestHttpRunResultErr
     (codex:exec-server-reqwest-http-invalid-method-error $message)))

(= (codex:exec-server-reqwest-http-run-flow
      $params
      (CodexExecServerReqwestHttpMethodOk $validated-method)
      (CodexExecServerReqwestHttpUrlErr $message)
      $headers-outcome
      $send-outcome
      $body-read-outcome)
   (CodexExecServerReqwestHttpRunResultErr
     (codex:exec-server-reqwest-http-invalid-url-error $message)))

(= (codex:exec-server-reqwest-http-run-flow
      $params
      (CodexExecServerReqwestHttpMethodOk $validated-method)
      (CodexExecServerReqwestHttpUrlOk $scheme $validated-url)
      $headers-outcome
      $send-outcome
      $body-read-outcome)
   (if (not (codex:exec-server-reqwest-http-supported-scheme $scheme))
       (CodexExecServerReqwestHttpRunResultErr
         (codex:exec-server-reqwest-http-unsupported-scheme-error
           $scheme))
       (case $headers-outcome
         (((CodexExecServerReqwestHttpHeadersErr $error)
           (CodexExecServerReqwestHttpRunResultErr $error))
          ((CodexExecServerReqwestHttpHeadersOk $validated-headers)
           (case $send-outcome
             (((CodexExecServerReqwestHttpSendErr $message)
               (CodexExecServerReqwestHttpRunResultErr
                 (codex:exec-server-reqwest-http-send-error $message)))
              ((CodexExecServerReqwestHttpSendOk $response)
               (codex:exec-server-reqwest-http-run-after-send
                 $params
                 $response
                 $body-read-outcome)))))))))

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
