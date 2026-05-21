; Rust-faithful exec-server HTTP protocol slice.
;
; This ports deterministic wire/data shapes from:
; - openai-codex/codex-rs/exec-server/src/protocol.rs
;   - HTTP_REQUEST_METHOD / HTTP_REQUEST_BODY_DELTA_METHOD
;   - HttpHeader
;   - HttpRequestParams
;   - HttpRequestResponse
;   - HttpRequestBodyDeltaNotification
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust stores `ByteChunk` as `Vec<u8>` and serializes it with standard
;   base64. This slice reuses `codex:exec-server-byte-chunk` from the
;   process protocol module, which currently carries bytes as text and
;   preserves visible JSON behavior for UTF-8/ASCII payloads.
; - Rust deserializes `timeout_ms: Option<u64>`. CeTTa JSON numbers are
;   currently surfaced as `JsonNumber $text`, so
;   `codex:exec-server-http-request-timeout-ms-from-json` returns that
;   numeric text for explicit numbers and `CodexAbsent` for omitted/null.

!(import! &self json)
!(import! &self list)
!(import! &self exec_server_process_protocol)

(= (codex:exec-server-http-request-method)
   "http/request")

(= (codex:exec-server-http-request-body-delta-method)
   "http/request/bodyDelta")

(= (codex:exec-server-http-json-number $value)
   (JsonNumber (format-args "{}" ($value))))

(= (codex:exec-server-http-json-option-byte-chunk-null $chunk)
   (if (== $chunk CodexAbsent)
       JsonNull
       (codex:exec-server-byte-chunk-json $chunk)))

(= (codex:exec-server-http-json-option-string-null $value)
   (if (== $value CodexAbsent)
       JsonNull
       (JsonString $value)))

(= (codex:exec-server-http-append-optional-json-number-pair
      $pairs
      $key
      $value)
   (if (== $value CodexAbsent)
       $pairs
       (list:append
         $pairs
         ((JsonPair
            $key
            (codex:exec-server-http-json-number $value))))))

(= (codex:exec-server-http-header $name $value)
   (CodexExecServerHttpHeader $name $value))

(= (codex:exec-server-http-header-name
      (CodexExecServerHttpHeader $name $value))
   $name)

(= (codex:exec-server-http-header-value
      (CodexExecServerHttpHeader $name $value))
   $value)

(= (codex:exec-server-http-header-json
      (CodexExecServerHttpHeader $name $value))
   (JsonObject
     ((JsonPair "name" (JsonString $name))
      (JsonPair "value" (JsonString $value)))))

(= (codex:exec-server-http-headers-json $headers)
   (JsonArray
     (map-atom-strict
       $headers
       $header
       (codex:exec-server-http-header-json $header))))

(= (codex:exec-server-http-request-params
      $method
      $url
      $headers
      $body
      $timeout-ms
      $request-id
      $stream-response)
   (CodexExecServerHttpRequestParams
     $method
     $url
     $headers
     $body
     $timeout-ms
     $request-id
     $stream-response))

(= (codex:exec-server-http-request-params-method
      (CodexExecServerHttpRequestParams
        $method
        $url
        $headers
        $body
        $timeout-ms
        $request-id
        $stream-response))
   $method)

(= (codex:exec-server-http-request-params-url
      (CodexExecServerHttpRequestParams
        $method
        $url
        $headers
        $body
        $timeout-ms
        $request-id
        $stream-response))
   $url)

(= (codex:exec-server-http-request-params-timeout-ms
      (CodexExecServerHttpRequestParams
        $method
        $url
        $headers
        $body
        $timeout-ms
        $request-id
        $stream-response))
   $timeout-ms)

(= (codex:exec-server-http-request-params-request-id
      (CodexExecServerHttpRequestParams
        $method
        $url
        $headers
        $body
        $timeout-ms
        $request-id
        $stream-response))
   $request-id)

(= (codex:exec-server-http-request-params-json
      (CodexExecServerHttpRequestParams
        $method
        $url
        $headers
        $body
        $timeout-ms
        $request-id
        $stream-response))
   (JsonObject
     (list:append
       (codex:exec-server-http-append-optional-json-number-pair
         ((JsonPair "method" (JsonString $method))
          (JsonPair "url" (JsonString $url))
          (JsonPair "headers" (codex:exec-server-http-headers-json $headers))
          (JsonPair
            "bodyBase64"
            (codex:exec-server-http-json-option-byte-chunk-null $body)))
         "timeoutMs"
         $timeout-ms)
       ((JsonPair "requestId" (JsonString $request-id))
        (JsonPair "streamResponse" (JsonBool $stream-response))))))

(= (codex:exec-server-http-json-pair-key
      (JsonPair $key $value))
   $key)

(= (codex:exec-server-http-json-pair-value
      (JsonPair $key $value))
   $value)

(= (codex:exec-server-http-json-object-field-from
      ()
      $key)
   CodexAbsent)

(= (codex:exec-server-http-json-object-field-from
      $pairs
      $key)
   (let $head (list:first $pairs)
     (if (== (codex:exec-server-http-json-pair-key $head) $key)
         (codex:exec-server-http-json-pair-value $head)
         (codex:exec-server-http-json-object-field-from
           (list:rest $pairs)
           $key))))

(= (codex:exec-server-http-json-object-field
      (JsonObject $pairs)
      $key)
   (codex:exec-server-http-json-object-field-from $pairs $key))

(= (codex:exec-server-http-request-timeout-ms-from-json $json)
   (case (codex:exec-server-http-json-object-field $json "timeoutMs")
     ((CodexAbsent CodexAbsent)
      (JsonNull CodexAbsent)
      ((JsonNumber $text) $text)
      ($other (CodexExecServerHttpTimeoutMsInvalid $other)))))

(= (codex:exec-server-http-request-response
      $status
      $headers
      $body)
   (CodexExecServerHttpRequestResponse $status $headers $body))

(= (codex:exec-server-http-request-response-status
      (CodexExecServerHttpRequestResponse $status $headers $body))
   $status)

(= (codex:exec-server-http-request-response-json
      (CodexExecServerHttpRequestResponse $status $headers $body))
   (JsonObject
     ((JsonPair "status" (codex:exec-server-http-json-number $status))
      (JsonPair "headers" (codex:exec-server-http-headers-json $headers))
      (JsonPair "bodyBase64" (codex:exec-server-byte-chunk-json $body)))))

(= (codex:exec-server-http-body-delta-notification
      $request-id
      $seq
      $delta
      $done
      $error)
   (CodexExecServerHttpRequestBodyDeltaNotification
     $request-id
     $seq
     $delta
     $done
     $error))

(= (codex:exec-server-http-body-delta-notification-request-id
      (CodexExecServerHttpRequestBodyDeltaNotification
        $request-id
        $seq
        $delta
        $done
        $error))
   $request-id)

(= (codex:exec-server-http-body-delta-notification-seq
      (CodexExecServerHttpRequestBodyDeltaNotification
        $request-id
        $seq
        $delta
        $done
        $error))
   $seq)

(= (codex:exec-server-http-body-delta-notification-json
      (CodexExecServerHttpRequestBodyDeltaNotification
        $request-id
        $seq
        $delta
        $done
        $error))
   (JsonObject
     ((JsonPair "requestId" (JsonString $request-id))
      (JsonPair "seq" (codex:exec-server-http-json-number $seq))
      (JsonPair "deltaBase64" (codex:exec-server-byte-chunk-json $delta))
      (JsonPair "done" (JsonBool $done))
      (JsonPair
        "error"
        (codex:exec-server-http-json-option-string-null $error)))))
