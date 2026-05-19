!(register-module! ../codex)
!(import! &self codex:unified_exec_write_stdin)

(= (write-stdin-state $has-exited $exit-code $failure-message)
   (codex:unified-exec-process-state
     $has-exited
     $exit-code
     $failure-message))

(= (write-stdin-output-handles)
   (codex:unified-exec-output-handles
     output-buffer-1
     output-notify-1
     False
     output-closed-notify-1
     cancellation-token-1))

(= (write-stdin-process $has-exited $exit-code $failure-message)
   (codex:unified-exec-process-with-output-handles
     (write-stdin-state $has-exited $exit-code $failure-message)
     (write-stdin-output-handles)))

(= (write-stdin-entry
      $process-id
      $call-id
      $last-used
      $has-exited
      $exit-code
      $failure-message
      $tty)
   (codex:unified-exec-process-entry
     (write-stdin-process
       $has-exited
       $exit-code
       $failure-message)
     $call-id
     $process-id
     "bash -lc cat"
     $tty
     CodexAbsent
     session-1
     $last-used))

(= (write-stdin-store-with-entry $entry)
   (codex:unified-exec-process-store-put-entry
     (codex:unified-exec-process-store-reserve-process-id
       (codex:unified-exec-process-store-default)
       (codex:unified-exec-process-entry-process-id $entry))
     $entry))

(= (write-stdin-manager-with-entry $entry)
   (codex:unified-exec-process-manager
     (write-stdin-store-with-entry $entry)
     12000))

(= (write-stdin-request $process-id $input $yield-time-ms)
   (codex:unified-exec-write-stdin-request
     $process-id
     $input
     $yield-time-ms
     2000))

(= (write-stdin-runtime-ok $output)
   (codex:unified-exec-write-stdin-runtime-inputs
     (codex:unified-exec-process-write-ok)
     $output
     125
     "abc123"
     CodexAbsent))

(= (write-stdin-runtime-write-err $error $output)
   (codex:unified-exec-write-stdin-runtime-inputs
     (codex:unified-exec-process-write-err $error)
     $output
     125
     "abc123"
     CodexAbsent))

!(assertEqual
  (codex:unified-exec-process-write-result-kind
    (codex:unified-exec-process-write-ok))
  ok)

!(assertEqual
  (codex:unified-exec-process-write-result-error
    (codex:unified-exec-process-write-err
      (codex:unified-exec-error-write-to-stdin)))
  (codex:unified-exec-error-write-to-stdin))

!(assertEqual
  (codex:unified-exec-write-stdin-runtime-inputs-chunk-id
    (write-stdin-runtime-ok "hello"))
  "abc123")

!(assertEqual
  (codex:unified-exec-approx-token-count "")
  0)

!(assertEqual
  (codex:unified-exec-approx-token-count "hello")
  2)

!(assertEqual
  (let $result
    (codex:unified-exec-write-stdin
      (codex:unified-exec-process-manager-new 12000)
      (write-stdin-request 41 "x" 1000)
      25
      (write-stdin-runtime-ok "ignored"))
    (codex:unified-exec-write-stdin-result-kind $result))
  err)

!(assertEqual
  (let $result
    (codex:unified-exec-write-stdin
      (codex:unified-exec-process-manager-new 12000)
      (write-stdin-request 41 "x" 1000)
      25
      (write-stdin-runtime-ok "ignored"))
    (codex:unified-exec-error-kind
      (codex:unified-exec-write-stdin-result-error $result)))
  unknown_process_id)

!(assertEqual
  (let $result
    (codex:unified-exec-write-stdin
      (write-stdin-manager-with-entry
        (write-stdin-entry
          41
          "call-41"
          10
          False
          CodexAbsent
          CodexAbsent
          False))
      (write-stdin-request 41 "x" 1000)
      25
      (write-stdin-runtime-ok "ignored"))
    (codex:unified-exec-error-kind
      (codex:unified-exec-write-stdin-result-error $result)))
  stdin_closed)

!(assertEqual
  (let $result
    (codex:unified-exec-write-stdin
      (write-stdin-manager-with-entry
        (write-stdin-entry
          41
          "call-41"
          10
          False
          CodexAbsent
          CodexAbsent
          False))
      (write-stdin-request 41 "x" 1000)
      25
      (write-stdin-runtime-ok "ignored"))
    (let $entry
      (codex:unified-exec-process-store-get-entry
        (codex:unified-exec-process-manager-process-store
          (codex:unified-exec-write-stdin-result-manager
            $result))
        41)
      (codex:unified-exec-process-entry-last-used $entry)))
  25)

!(assertEqual
  (let $result
    (codex:unified-exec-write-stdin
      (write-stdin-manager-with-entry
        (write-stdin-entry
          41
          "call-41"
          10
          False
          7
          CodexAbsent
          True))
      (write-stdin-request 41 "exit\n" 1000)
      25
      (write-stdin-runtime-ok "hello world"))
    (codex:unified-exec-write-stdin-result-kind $result))
  ok)

!(assertEqual
  (let $result
    (codex:unified-exec-write-stdin
      (write-stdin-manager-with-entry
        (write-stdin-entry
          41
          "call-41"
          10
          False
          7
          CodexAbsent
          True))
      (write-stdin-request 41 "exit\n" 1000)
      25
      (write-stdin-runtime-ok "hello world"))
    (let $output
      (codex:unified-exec-write-stdin-result-output $result)
      (codex:unified-exec-exec-output-event-call-id $output)))
  "call-41")

!(assertEqual
  (let $result
    (codex:unified-exec-write-stdin
      (write-stdin-manager-with-entry
        (write-stdin-entry
          41
          "call-41"
          10
          False
          7
          CodexAbsent
          True))
      (write-stdin-request 41 "exit\n" 1000)
      25
      (write-stdin-runtime-ok "hello world"))
    (let $output
      (codex:unified-exec-write-stdin-result-output $result)
      (codex:unified-exec-exec-output-process-id $output)))
  41)

!(assertEqual
  (let $result
    (codex:unified-exec-write-stdin
      (write-stdin-manager-with-entry
        (write-stdin-entry
          41
          "call-41"
          10
          False
          7
          CodexAbsent
          True))
      (write-stdin-request 41 "exit\n" 1000)
      25
      (write-stdin-runtime-ok "hello world"))
    (let $output
      (codex:unified-exec-write-stdin-result-output $result)
      (codex:unified-exec-exec-output-exit-code $output)))
  7)

!(assertEqual
  (let $result
    (codex:unified-exec-write-stdin
      (write-stdin-manager-with-entry
        (write-stdin-entry
          41
          "call-41"
          10
          False
          7
          CodexAbsent
          True))
      (write-stdin-request 41 "exit\n" 1000)
      25
      (write-stdin-runtime-ok "hello world"))
    (let $output
      (codex:unified-exec-write-stdin-result-output $result)
      (codex:unified-exec-exec-output-original-token-count
        $output)))
  3)

!(assertEqual
  (let $result
    (codex:unified-exec-write-stdin
      (write-stdin-manager-with-entry
        (write-stdin-entry
          41
          "call-41"
          10
          False
          7
          CodexAbsent
          True))
      (write-stdin-request 41 "exit\n" 1000)
      25
      (write-stdin-runtime-ok "hello world"))
    (let $collection-request
      (codex:unified-exec-write-stdin-result-collection-request
        $result)
      (codex:unified-exec-write-stdin-collection-request-yield-time-ms
        $collection-request)))
  1000)

!(assertEqual
  (let $result
    (codex:unified-exec-write-stdin
      (write-stdin-manager-with-entry
        (write-stdin-entry
          41
          "call-41"
          10
          False
          7
          CodexAbsent
          True))
      (write-stdin-request 41 "exit\n" 1000)
      25
      (write-stdin-runtime-ok "hello world"))
    (codex:unified-exec-write-stdin-result-post-write-sleep-ms
      $result))
  100)

!(assertEqual
  (let $result
    (codex:unified-exec-write-stdin
      (write-stdin-manager-with-entry
        (write-stdin-entry
          41
          "call-41"
          10
          False
          CodexAbsent
          CodexAbsent
          True))
      (write-stdin-request 41 "" 100)
      25
      (write-stdin-runtime-ok "poll"))
    (let $collection-request
      (codex:unified-exec-write-stdin-result-collection-request
        $result)
      (codex:unified-exec-write-stdin-collection-request-yield-time-ms
        $collection-request)))
  5000)

!(assertEqual
  (let $result
    (codex:unified-exec-write-stdin
      (write-stdin-manager-with-entry
        (write-stdin-entry
          41
          "call-41"
          10
          False
          CodexAbsent
          CodexAbsent
          True))
      (write-stdin-request 41 "input" 1000)
      25
      (write-stdin-runtime-write-err
        (codex:unified-exec-error-process-failed "transport lost")
        "ignored"))
    (codex:unified-exec-error-kind
      (codex:unified-exec-write-stdin-result-error $result)))
  process_failed)

!(assertEqual
  (let $result
    (codex:unified-exec-write-stdin
      (write-stdin-manager-with-entry
        (write-stdin-entry
          41
          "call-41"
          10
          False
          CodexAbsent
          CodexAbsent
          True))
      (write-stdin-request 41 "input" 1000)
      25
      (write-stdin-runtime-write-err
        (codex:unified-exec-error-process-failed "transport lost")
        "ignored"))
    (codex:unified-exec-process-store-get-entry
      (codex:unified-exec-process-manager-process-store
        (codex:unified-exec-write-stdin-result-manager
          $result))
      41))
  CodexAbsent)

!(assertEqual
  (let $result
    (codex:unified-exec-write-stdin
      (write-stdin-manager-with-entry
        (write-stdin-entry
          41
          "call-exited"
          10
          True
          0
          CodexAbsent
          True))
      (write-stdin-request 41 "input" 1000)
      25
      (write-stdin-runtime-write-err
        (codex:unified-exec-error-write-to-stdin)
        "done"))
    (codex:unified-exec-write-stdin-result-kind $result))
  ok)

!(assertEqual
  (let $result
    (codex:unified-exec-write-stdin
      (write-stdin-manager-with-entry
        (write-stdin-entry
          41
          "call-exited"
          10
          True
          0
          CodexAbsent
          True))
      (write-stdin-request 41 "input" 1000)
      25
      (write-stdin-runtime-write-err
        (codex:unified-exec-error-write-to-stdin)
        "done"))
    (let $output
      (codex:unified-exec-write-stdin-result-output $result)
      (codex:unified-exec-exec-output-process-id $output)))
  CodexAbsent)

!(assertEqual
  (let $result
    (codex:unified-exec-write-stdin
      (write-stdin-manager-with-entry
        (write-stdin-entry
          41
          "call-exited"
          10
          True
          0
          CodexAbsent
          True))
      (write-stdin-request 41 "input" 1000)
      25
      (write-stdin-runtime-write-err
        (codex:unified-exec-error-write-to-stdin)
        "done"))
    (codex:unified-exec-process-store-get-entry
      (codex:unified-exec-process-manager-process-store
        (codex:unified-exec-write-stdin-result-manager
          $result))
      41))
  CodexAbsent)

!(assertEqual
  (let $result
    (codex:unified-exec-write-stdin
      (write-stdin-manager-with-entry
        (write-stdin-entry
          41
          "call-41"
          10
          False
          CodexAbsent
          CodexAbsent
          True))
      (write-stdin-request 41 "input" 1000)
      25
      (codex:unified-exec-write-stdin-runtime-inputs
        (codex:unified-exec-process-write-ok)
        "ignored"
        125
        "abc123"
        "background failed"))
    (codex:unified-exec-error-kind
      (codex:unified-exec-write-stdin-result-error $result)))
  process_failed)

!(assertEqual
  (let $result
    (codex:unified-exec-write-stdin
      (write-stdin-manager-with-entry
        (write-stdin-entry
          41
          "call-41"
          10
          False
          CodexAbsent
          CodexAbsent
          True))
      (write-stdin-request 41 "input" 1000)
      25
      (codex:unified-exec-write-stdin-runtime-inputs
        (codex:unified-exec-process-write-ok)
        "ignored"
        125
        "abc123"
        "background failed"))
    (codex:unified-exec-process-store-get-entry
      (codex:unified-exec-process-manager-process-store
        (codex:unified-exec-write-stdin-result-manager
          $result))
      41))
  CodexAbsent)
