(= (http:request $method $url $headers $body $timeout-ms $max-bytes)
   (function
     (case (__cetta_lib_http_request $method $url $headers $body $timeout-ms $max-bytes)
       (($result (return $result))))))

(= (http:get $url)
   (http:request "GET" $url () "" 30000 8388608))

(= (http:get $url $headers)
   (http:request "GET" $url $headers "" 30000 8388608))

(= (http:post $url $headers $body)
   (http:request "POST" $url $headers $body 60000 8388608))

(= (http:result-status (HttpResult $status $body)) $status)

(= (http:result-body (HttpResult $status $body)) $body)
