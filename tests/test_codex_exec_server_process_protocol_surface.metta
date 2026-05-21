!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:exec_server_process_id)
!(import! &self codex:exec_server_process_protocol)

(= (test:process-id)
   (codex:exec-server-process-id-new "proc-1"))

(= (test:env-policy)
   (codex:exec-server-exec-env-policy
     (codex:exec-server-shell-env-inherit-core)
     False
     ("*TOKEN*")
     ((codex:exec-server-protocol-string-pair "A" "1")
      (codex:exec-server-protocol-string-pair "B" "2"))
     ("PATH")))

(= (test:output-chunk)
   (codex:exec-server-process-output-chunk
     7
     (codex:exec-server-output-stream-stderr)
     (codex:exec-server-byte-chunk "hi")))

!(assertEqual
  (codex:exec-server-protocol-initialize-method)
  "initialize")

!(assertEqual
  (codex:exec-server-protocol-exec-method)
  "process/start")

!(assertEqual
  (codex:exec-server-protocol-exec-output-delta-method)
  "process/output")

!(assertEqual
  (codex:exec-server-protocol-http-request-body-delta-method)
  "http/request/bodyDelta")

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-byte-chunk-json
      (codex:exec-server-byte-chunk "hi")))
  ("\"aGk=\""))

!(assertEqual
  (codex:exec-server-byte-chunk-into-inner
    (codex:exec-server-byte-chunk "stdin"))
  "stdin")

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-initialize-params-json
      (codex:exec-server-initialize-params
        "codex"
        CodexAbsent)))
  ("{\"clientName\":\"codex\",\"resumeSessionId\":null}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-initialize-params-json
      (codex:exec-server-initialize-params
        "codex"
        "session-1")))
  ("{\"clientName\":\"codex\",\"resumeSessionId\":\"session-1\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-initialize-response-json
      (codex:exec-server-initialize-response "session-2")))
  ("{\"sessionId\":\"session-2\"}"))

!(assertEqual
  (codex:exec-server-shell-env-inherit-json-string
    (codex:exec-server-shell-env-inherit-all))
  "all")

!(assertEqual
  (codex:exec-server-shell-env-inherit-json-string
    (codex:exec-server-shell-env-inherit-none))
  "none")

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-exec-env-policy-json
      (test:env-policy)))
  ("{\"inherit\":\"core\",\"ignoreDefaultExcludes\":false,\"exclude\":[\"*TOKEN*\"],\"set\":{\"A\":\"1\",\"B\":\"2\"},\"includeOnly\":[\"PATH\"]}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-exec-params-json
      (codex:exec-server-exec-params
        (test:process-id)
        ("bash" "-lc" "echo hi")
        "/tmp"
        (test:env-policy)
        ((codex:exec-server-protocol-string-pair "TERM" "xterm"))
        False
        True
        CodexAbsent)))
  ("{\"processId\":\"proc-1\",\"argv\":[\"bash\",\"-lc\",\"echo hi\"],\"cwd\":\"/tmp\",\"envPolicy\":{\"inherit\":\"core\",\"ignoreDefaultExcludes\":false,\"exclude\":[\"*TOKEN*\"],\"set\":{\"A\":\"1\",\"B\":\"2\"},\"includeOnly\":[\"PATH\"]},\"env\":{\"TERM\":\"xterm\"},\"tty\":false,\"pipeStdin\":true,\"arg0\":null}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-exec-params-json
      (codex:exec-server-exec-params
        (test:process-id)
        ("python")
        "/repo"
        CodexAbsent
        ()
        True
        False
        "python3")))
  ("{\"processId\":\"proc-1\",\"argv\":[\"python\"],\"cwd\":\"/repo\",\"envPolicy\":null,\"env\":{},\"tty\":true,\"pipeStdin\":false,\"arg0\":\"python3\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-exec-response-json
      (codex:exec-server-exec-response (test:process-id))))
  ("{\"processId\":\"proc-1\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-read-params-json
      (codex:exec-server-read-params
        (test:process-id)
        CodexAbsent
        4096
        100)))
  ("{\"processId\":\"proc-1\",\"afterSeq\":null,\"maxBytes\":4096,\"waitMs\":100}"))

!(assertEqual
  (codex:exec-server-output-stream-json-string
    (codex:exec-server-output-stream-pty))
  "pty")

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-process-output-chunk-json
      (test:output-chunk)))
  ("{\"seq\":7,\"stream\":\"stderr\",\"chunk\":\"aGk=\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-read-response-json
      (codex:exec-server-read-response
        ((test:output-chunk))
        8
        True
        0
        True
        CodexAbsent)))
  ("{\"chunks\":[{\"seq\":7,\"stream\":\"stderr\",\"chunk\":\"aGk=\"}],\"nextSeq\":8,\"exited\":true,\"exitCode\":0,\"closed\":true,\"failure\":null}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-write-params-json
      (codex:exec-server-write-params
        (test:process-id)
        (codex:exec-server-byte-chunk "x"))))
  ("{\"processId\":\"proc-1\",\"chunk\":\"eA==\"}"))

!(assertEqual
  (codex:exec-server-write-status-json-string
    (codex:exec-server-write-status-accepted))
  "accepted")

!(assertEqual
  (codex:exec-server-write-status-json-string
    (codex:exec-server-write-status-stdin-closed))
  "stdinClosed")

!(assertEqual
  (codex:exec-server-write-status-json-string
    (codex:exec-server-write-status-starting))
  "starting")

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-write-response-json
      (codex:exec-server-write-response
        (codex:exec-server-write-status-unknown-process))))
  ("{\"status\":\"unknownProcess\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-terminate-params-json
      (codex:exec-server-terminate-params (test:process-id))))
  ("{\"processId\":\"proc-1\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-terminate-response-json
      (codex:exec-server-terminate-response False)))
  ("{\"running\":false}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-output-delta-notification-json
      (codex:exec-server-output-delta-notification
        (test:process-id)
        9
        (codex:exec-server-output-stream-stdout)
        (codex:exec-server-byte-chunk "hi"))))
  ("{\"processId\":\"proc-1\",\"seq\":9,\"stream\":\"stdout\",\"chunk\":\"aGk=\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-exited-notification-json
      (codex:exec-server-exited-notification
        (test:process-id)
        10
        0)))
  ("{\"processId\":\"proc-1\",\"seq\":10,\"exitCode\":0}"))

!(assertEqualToResult
  (json-stringify
    (codex:exec-server-closed-notification-json
      (codex:exec-server-closed-notification
        (test:process-id)
        11)))
  ("{\"processId\":\"proc-1\",\"seq\":11}"))
