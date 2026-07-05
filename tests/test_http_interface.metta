!(import! &self http)
!(import! &self system)
!(import! &self str)

; Hermetic transport check over file:// (no network; status is 0 for file).
!(assertEqualToResult
  (let $cwd (system:cwd)
    (let $url (str:concat "file://" (str:concat $cwd "/tests/support/http_fixture.txt"))
      (http:result-body (http:request "GET" $url () "" 5000 1048576))))
  ("hello-http\n"))

!(assertEqualToResult
  (let $cwd (system:cwd)
    (let $url (str:concat "file://" (str:concat $cwd "/tests/support/http_fixture.txt"))
      (http:result-status (http:request "GET" $url () "" 5000 1048576))))
  (0))

; The byte cap is enforced at receive time.
!(assertEqualToResult
  (let $cwd (system:cwd)
    (let $url (str:concat "file://" (str:concat $cwd "/tests/support/http_fixture.txt"))
      (http:result-body (http:request "GET" $url () "" 5000 5))))
  ("hello"))

; Transport errors come back as a case-classifiable Error atom.
!(assertEqualToResult
  (case (http:request "GET" "file:///nonexistent-cetta-http-probe" () "" 5000 1024)
    (((HttpResult $s $b) (UnexpectedResult $s))
     ((Error $call $msg) transport-error-as-expected)
     ($other (Unexpected $other))))
  (transport-error-as-expected))

; Non-allowlisted protocols are rejected.
!(assertEqualToResult
  (case (http:request "GET" "gopher://localhost/1" () "" 5000 1024)
    (((HttpResult $s $b) (UnexpectedResult $s))
     ((Error $call $msg) protocol-rejected-as-expected)
     ($other (Unexpected $other))))
  (protocol-rejected-as-expected))
