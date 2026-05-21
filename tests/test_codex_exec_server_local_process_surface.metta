!(register-module! ../codex)
!(import! &self codex:exec_process_event_log)
!(import! &self codex:exec_server_process_id)
!(import! &self codex:exec_server_process_protocol)
!(import! &self codex:exec_server_local_process)

(= (test:process-id $value)
   (codex:exec-server-process-id-new $value))

(= (test:env-pair $key $value)
   (codex:exec-server-protocol-string-pair $key $value))

(= (test:env-policy)
   (codex:exec-server-exec-env-policy
     (codex:exec-server-shell-env-inherit-none)
     True
     ("*TOKEN*")
     ((test:env-pair "POLICY_SET" "policy"))
     ("PATH")))

(= (test:params $process-id $argv $env-policy $env $tty $pipe-stdin)
   (codex:exec-server-exec-params
     $process-id
     $argv
     "/tmp"
     $env-policy
     $env
     $tty
     $pipe-stdin
     CodexAbsent))

(= (test:byte $text)
   (codex:exec-server-byte-chunk $text))

(= (test:chunk $seq $text)
   (codex:exec-server-process-output-chunk
     $seq
     (codex:exec-server-output-stream-stdout)
     (test:byte $text)))

(= (test:event-log)
   (codex:exec-process-event-log-new 256 1048576))

(= (test:running-process
      $tty
      $pipe-stdin
      $output
      $retained-bytes
      $next-seq
      $exit-code
      $open-streams
      $closed)
   (codex:exec-server-local-running-process
     TestSession
     $tty
     $pipe-stdin
     $output
     $retained-bytes
     $next-seq
     $exit-code
     0
     (test:event-log)
     TestNotify
     $open-streams
     $closed))

(= (test:local-with-entry $process-id $entry)
   (codex:exec-server-local-process-with-entry
     (codex:exec-server-local-process-default)
     $process-id
     $entry))

(= (test:local-running
      $process-id
      $tty
      $pipe-stdin
      $output
      $retained-bytes
      $next-seq
      $exit-code
      $open-streams
      $closed)
   (test:local-with-entry
     $process-id
     (codex:exec-server-local-process-entry-running
       (test:running-process
         $tty
         $pipe-stdin
         $output
         $retained-bytes
         $next-seq
         $exit-code
         $open-streams
         $closed))))

(= (test:entry $local $process-id)
   (codex:exec-server-local-process-entry $local $process-id))

(= (test:running $local $process-id)
   (codex:exec-server-local-process-entry-running-process
     (test:entry $local $process-id)))

(= (test:read-response $result)
   (codex:exec-server-local-read-outcome-response
     (codex:exec-server-local-result-value $result)))

!(assertEqual
  (codex:exec-server-local-error-code
    (codex:exec-server-local-result-error
      (codex:exec-server-local-start-process-plan
        (codex:exec-server-local-process-default)
        (test:params
          (test:process-id "empty")
          ()
          CodexAbsent
          ()
          False
          False)
        ()
        (codex:exec-server-local-host-platform-other))))
  -32602)

!(assertEqual
  (codex:exec-server-local-string-pairs-lookup
    (codex:exec-server-local-spawn-request-env
      (codex:exec-server-local-result-value
        (codex:exec-server-local-start-process-plan
          (codex:exec-server-local-process-default)
          (test:params
            (test:process-id "env")
            ("true")
            (test:env-policy)
            ((test:env-pair "OVERLAY" "overlay")
             (test:env-pair "POLICY_SET" "overlay-wins"))
            False
            False)
          ((test:env-pair "POLICY_SET" "policy")
           (test:env-pair "BASE" "base"))
          (codex:exec-server-local-host-platform-windows))))
    "POLICY_SET")
  "overlay-wins")

!(assertEqual
  (codex:exec-server-local-string-pairs-lookup
    (codex:exec-server-local-spawn-request-env
      (codex:exec-server-local-result-value
        (codex:exec-server-local-start-process-plan
          (codex:exec-server-local-process-default)
          (test:params
            (test:process-id "env-win")
            ("true")
            (test:env-policy)
            ()
            False
            False)
          ()
          (codex:exec-server-local-host-platform-windows))))
    "PATHEXT")
  ".COM;.EXE;.BAT;.CMD")

!(assertEqual
  (codex:exec-server-local-spawn-request-mode
    (codex:exec-server-local-result-value
      (codex:exec-server-local-start-process-plan
        (codex:exec-server-local-process-default)
        (test:params
          (test:process-id "pty")
          ("bash")
          CodexAbsent
          ()
          True
          True)
        ()
        (codex:exec-server-local-host-platform-other))))
  (codex:exec-server-local-spawn-mode-pty))

!(assertEqual
  (codex:exec-server-local-result-kind
    (codex:exec-server-local-start-process-plan
      (codex:exec-server-local-result-process
        (codex:exec-server-local-start-process-plan
          (codex:exec-server-local-process-default)
          (test:params
            (test:process-id "dup")
            ("true")
            CodexAbsent
            ()
            False
            False)
          ()
          (codex:exec-server-local-host-platform-other)))
      (test:params
        (test:process-id "dup")
        ("true")
        CodexAbsent
        ()
        False
        False)
      ()
      (codex:exec-server-local-host-platform-other)))
  err)

!(assertEqual
  (codex:exec-server-local-started-task-requests
    (codex:exec-server-local-result-value
      (codex:exec-server-local-start-process-spawned
        (codex:exec-server-local-result-process
          (codex:exec-server-local-start-process-plan
            (codex:exec-server-local-process-default)
            (test:params
              (test:process-id "started")
              ("bash")
              CodexAbsent
              ()
              True
              False)
            ()
            (codex:exec-server-local-host-platform-other)))
        (test:params
          (test:process-id "started")
          ("bash")
          CodexAbsent
          ()
          True
          False)
        TestSession
        TestNotify)))
  ((CodexExecServerLocalStreamTaskRequest
     (CodexExecServerProcessId "started")
     (CodexExecServerExecOutputStreamPty)
     TestNotify)
   (CodexExecServerLocalStreamTaskRequest
     (CodexExecServerProcessId "started")
     (CodexExecServerExecOutputStreamPty)
     TestNotify)
   (CodexExecServerLocalExitWatchTaskRequest
     (CodexExecServerProcessId "started")
     TestNotify)))

!(assertEqual
  (codex:exec-server-local-process-entry
    (codex:exec-server-local-result-process
      (codex:exec-server-local-start-process-spawn-failed
        (codex:exec-server-local-result-process
          (codex:exec-server-local-start-process-plan
            (codex:exec-server-local-process-default)
            (test:params
              (test:process-id "spawn-fail")
              ("bad")
              CodexAbsent
              ()
              False
              False)
            ()
            (codex:exec-server-local-host-platform-other)))
        (test:process-id "spawn-fail")
        "boom"))
    (test:process-id "spawn-fail"))
  CodexAbsent)

!(assertEqual
  (codex:exec-server-local-running-process-output
    (test:running
      (codex:exec-server-local-result-process
        (codex:exec-server-local-record-output-with-capacity
          (codex:exec-server-local-result-process
            (codex:exec-server-local-record-output-with-capacity
              (test:local-running
                (test:process-id "retain")
                False
                False
                ()
                0
                1
                CodexAbsent
                2
                False)
              (test:process-id "retain")
              (codex:exec-server-output-stream-stdout)
              (test:byte "abc")
              4))
          (test:process-id "retain")
          (codex:exec-server-output-stream-stdout)
          (test:byte "de")
          4))
      (test:process-id "retain")))
  ((CodexExecServerProcessOutputChunk
     2
     (CodexExecServerExecOutputStreamStdout)
     (CodexExecServerByteChunk "de"))))

!(assertEqual
  (codex:exec-server-local-running-process-retained-bytes
    (test:running
      (codex:exec-server-local-result-process
        (codex:exec-server-local-record-output-with-capacity
          (codex:exec-server-local-result-process
            (codex:exec-server-local-record-output-with-capacity
              (test:local-running
                (test:process-id "retain-bytes")
                False
                False
                ()
                0
                1
                CodexAbsent
                2
                False)
              (test:process-id "retain-bytes")
              (codex:exec-server-output-stream-stdout)
              (test:byte "abc")
              4))
          (test:process-id "retain-bytes")
          (codex:exec-server-output-stream-stdout)
          (test:byte "de")
          4))
      (test:process-id "retain-bytes")))
  2)

!(assertEqual
  (test:read-response
    (codex:exec-server-local-exec-read-step
      (test:local-running
        (test:process-id "read-max")
        False
        False
        ((test:chunk 1 "abcde")
         (test:chunk 2 "f"))
        6
        3
        CodexAbsent
        2
        False)
      (codex:exec-server-read-params
        (test:process-id "read-max")
        CodexAbsent
        3
        CodexAbsent)
      True))
  (CodexExecServerReadResponse
    ((CodexExecServerProcessOutputChunk
       1
       (CodexExecServerExecOutputStreamStdout)
       (CodexExecServerByteChunk "abcde")))
    2
    False
    CodexAbsent
    False
    CodexAbsent))

!(assertEqual
  (codex:exec-server-local-read-outcome-kind
    (codex:exec-server-local-result-value
      (codex:exec-server-local-exec-read-step
        (test:local-running
          (test:process-id "pending")
          False
          False
          ()
          0
          1
          CodexAbsent
          2
          False)
        (codex:exec-server-read-params
          (test:process-id "pending")
          CodexAbsent
          CodexAbsent
          1000)
        False)))
  pending)

!(assertEqual
  (codex:exec-server-local-read-outcome-kind
    (codex:exec-server-local-result-value
      (codex:exec-server-local-exec-read-step
        (test:local-running
          (test:process-id "terminal")
          False
          False
          ()
          0
          2
          0
          2
          False)
        (codex:exec-server-read-params
          (test:process-id "terminal")
          0
          CodexAbsent
          1000)
        False)))
  ready)

!(assertEqual
  (codex:exec-server-write-response-status
    (codex:exec-server-local-result-value
      (codex:exec-server-local-exec-write
        (codex:exec-server-local-process-default)
        (codex:exec-server-write-params
          (test:process-id "missing")
          (test:byte "x"))
        True)))
  (codex:exec-server-write-status-unknown-process))

!(assertEqual
  (codex:exec-server-write-response-status
    (codex:exec-server-local-result-value
      (codex:exec-server-local-exec-write
        (test:local-with-entry
          (test:process-id "starting-write")
          (codex:exec-server-local-process-entry-starting))
        (codex:exec-server-write-params
          (test:process-id "starting-write")
          (test:byte "x"))
        True)))
  (codex:exec-server-write-status-starting))

!(assertEqual
  (codex:exec-server-write-response-status
    (codex:exec-server-local-result-value
      (codex:exec-server-local-exec-write
        (test:local-running
          (test:process-id "stdin-closed")
          False
          False
          ()
          0
          1
          CodexAbsent
          2
          False)
        (codex:exec-server-write-params
          (test:process-id "stdin-closed")
          (test:byte "x"))
        True)))
  (codex:exec-server-write-status-stdin-closed))

!(assertEqual
  (codex:exec-server-write-response-status
    (codex:exec-server-local-result-value
      (codex:exec-server-local-exec-write
        (test:local-running
          (test:process-id "accepted")
          False
          True
          ()
          0
          1
          CodexAbsent
          2
          False)
        (codex:exec-server-write-params
          (test:process-id "accepted")
          (test:byte "x"))
        True)))
  (codex:exec-server-write-status-accepted))

!(assertEqual
  (codex:exec-server-local-error-message
    (codex:exec-server-local-result-error
      (codex:exec-server-local-exec-write
        (test:local-running
          (test:process-id "write-fail")
          False
          True
          ()
          0
          1
          CodexAbsent
          2
          False)
        (codex:exec-server-write-params
          (test:process-id "write-fail")
          (test:byte "x"))
        False)))
  "failed to write to process stdin")

!(assertEqual
  (codex:exec-server-terminate-response-running
    (codex:exec-server-local-terminate-outcome-response
      (codex:exec-server-local-result-value
        (codex:exec-server-local-terminate-process
          (test:local-running
            (test:process-id "term")
            False
            False
            ()
            0
            1
            CodexAbsent
            2
            False)
          (codex:exec-server-terminate-params
            (test:process-id "term"))))))
  True)

!(assertEqual
  (codex:exec-server-local-terminate-outcome-request
    (codex:exec-server-local-result-value
      (codex:exec-server-local-terminate-process
        (test:local-running
          (test:process-id "term-exited")
          False
          False
          ()
          0
          2
          0
          2
          False)
        (codex:exec-server-terminate-params
          (test:process-id "term-exited")))))
  CodexAbsent)

!(assertEqual
  (codex:exec-server-local-exit-recorded-closed-notification
    (codex:exec-server-local-result-value
      (codex:exec-server-local-record-exit
        (test:local-running
          (test:process-id "exit-open")
          False
          False
          ()
          0
          1
          CodexAbsent
          2
          False)
        (test:process-id "exit-open")
        0)))
  CodexAbsent)

!(assertEqual
  (codex:exec-server-local-maybe-closed-result-notification
    (codex:exec-server-local-result-value
      (codex:exec-server-local-finish-output-stream
        (codex:exec-server-local-result-process
          (codex:exec-server-local-finish-output-stream
            (codex:exec-server-local-result-process
              (codex:exec-server-local-record-exit
                (test:local-running
                  (test:process-id "close-after-streams")
                  False
                  False
                  ()
                  0
                  1
                  CodexAbsent
                  2
                  False)
                (test:process-id "close-after-streams")
                0))
            (test:process-id "close-after-streams")))
        (test:process-id "close-after-streams"))))
  (CodexExecServerExecClosedNotification
    (CodexExecServerProcessId "close-after-streams")
    2))

!(assertEqual
  (codex:exec-server-local-exit-recorded-closed-notification
    (codex:exec-server-local-result-value
      (codex:exec-server-local-record-exit
        (test:local-running
          (test:process-id "exit-closed")
          False
          False
          ()
          0
          1
          CodexAbsent
          0
          False)
        (test:process-id "exit-closed")
        0)))
  (CodexExecServerExecClosedNotification
    (CodexExecServerProcessId "exit-closed")
    2))

!(assertEqual
  (codex:exec-server-local-shutdown-result-terminate-requests
    (codex:exec-server-local-shutdown
      (codex:exec-server-local-process-with-entry
        (test:local-with-entry
          (test:process-id "shutdown-starting")
          (codex:exec-server-local-process-entry-starting))
        (test:process-id "shutdown-running")
        (codex:exec-server-local-process-entry-running
          (test:running-process
            False
            False
            ()
            0
            1
            CodexAbsent
            2
            False)))))
  ((CodexExecServerLocalShutdownSessionRequest
     (CodexExecServerProcessId "shutdown-running"))))
