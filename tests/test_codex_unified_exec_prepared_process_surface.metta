!(register-module! ../codex)
!(import! &self codex:unified_exec_prepared_process)

(= (prepared-state $has-exited $exit-code)
   (codex:unified-exec-process-state
     $has-exited
     $exit-code
     CodexAbsent))

(= (prepared-output-handles)
   (codex:unified-exec-output-handles
     output-buffer-1
     output-notify-1
     False
     output-closed-notify-1
     cancellation-token-1))

(= (prepared-process $has-exited $exit-code)
   (codex:unified-exec-process-with-output-handles
     (prepared-state $has-exited $exit-code)
     (prepared-output-handles)))

(= (prepared-entry $process-id $last-used $session $tty)
   (codex:unified-exec-process-entry
     (prepared-process False CodexAbsent)
     "call-1"
     $process-id
     "bash -lc test"
     $tty
     CodexAbsent
     $session
     $last-used))

(= (prepared-store-with-entry $entry)
   (codex:unified-exec-process-store-put-entry
     (codex:unified-exec-process-store-reserve-process-id
       (codex:unified-exec-process-store-default)
       (codex:unified-exec-process-entry-process-id $entry))
     $entry))

!(assertEqual
  (codex:unified-exec-output-handles-output-buffer
    (prepared-output-handles))
  output-buffer-1)

!(assertEqual
  (codex:unified-exec-output-handles-output-notify
    (prepared-output-handles))
  output-notify-1)

!(assertEqual
  (codex:unified-exec-output-handles-output-closed
    (prepared-output-handles))
  False)

!(assertEqual
  (codex:unified-exec-output-handles-output-closed-notify
    (prepared-output-handles))
  output-closed-notify-1)

!(assertEqual
  (codex:unified-exec-output-handles-cancellation-token
    (prepared-output-handles))
  cancellation-token-1)

!(assertEqual
  (codex:unified-exec-process-with-output-handles-state
    (prepared-process True 0))
  (prepared-state True 0))

!(assertEqual
  (codex:unified-exec-process-output-handles
    (prepared-process False CodexAbsent))
  (prepared-output-handles))

!(assertEqual
  (codex:unified-exec-process-entry-has-exited
    (codex:unified-exec-process-entry
      (prepared-process True 7)
      "call-1"
      41
      "bash"
      True
      CodexAbsent
      session-1
      10))
  True)

!(assertEqual
  (codex:unified-exec-process-entry-exit-code
    (codex:unified-exec-process-entry
      (prepared-process True 7)
      "call-1"
      41
      "bash"
      True
      CodexAbsent
      session-1
      10))
  7)

!(assertEqual
  (codex:unified-exec-process-entry-last-used
    (codex:unified-exec-process-entry-with-last-used
      (prepared-entry 41 10 session-1 True)
      25))
  25)

!(assertEqual
  (codex:unified-exec-pause-state-from-session CodexAbsent)
  CodexAbsent)

!(assertEqual
  (codex:unified-exec-pause-state-from-session session-1)
  (codex:unified-exec-pause-state-subscription session-1))

!(assertEqual
  (let $result
    (codex:unified-exec-prepare-process-handles
      (codex:unified-exec-process-store-default)
      41
      25)
    (codex:unified-exec-prepare-process-handles-result-kind
      $result))
  err)

!(assertEqual
  (let $result
    (codex:unified-exec-prepare-process-handles
      (codex:unified-exec-process-store-default)
      41
      25)
    (codex:unified-exec-error-kind
      (codex:unified-exec-prepare-process-handles-result-error
        $result)))
  unknown_process_id)

!(assertEqual
  (let $result
    (codex:unified-exec-prepare-process-handles
      (codex:unified-exec-process-store-default)
      41
      25)
    (codex:unified-exec-prepare-process-handles-result-store
      $result))
  (codex:unified-exec-process-store-default))

!(assertEqual
  (let $result
    (codex:unified-exec-prepare-process-handles
      (prepared-store-with-entry
        (prepared-entry 41 10 session-1 True))
      41
      25)
    (codex:unified-exec-prepare-process-handles-result-kind
      $result))
  ok)

!(assertEqual
  (let $result
    (codex:unified-exec-prepare-process-handles
      (prepared-store-with-entry
        (prepared-entry 41 10 session-1 True))
      41
      25)
    (let $prepared
      (codex:unified-exec-prepare-process-handles-result-prepared
        $result)
      (codex:unified-exec-prepared-process-handles-process-id
        $prepared)))
  41)

!(assertEqual
  (let $result
    (codex:unified-exec-prepare-process-handles
      (prepared-store-with-entry
        (prepared-entry 41 10 session-1 True))
      41
      25)
    (let $prepared
      (codex:unified-exec-prepare-process-handles-result-prepared
        $result)
      (codex:unified-exec-prepared-process-handles-hook-command
        $prepared)))
  "bash -lc test")

!(assertEqual
  (let $result
    (codex:unified-exec-prepare-process-handles
      (prepared-store-with-entry
        (prepared-entry 41 10 session-1 True))
      41
      25)
    (let $prepared
      (codex:unified-exec-prepare-process-handles-result-prepared
        $result)
      (codex:unified-exec-prepared-process-handles-tty
        $prepared)))
  True)

!(assertEqual
  (let $result
    (codex:unified-exec-prepare-process-handles
      (prepared-store-with-entry
        (prepared-entry 41 10 session-1 True))
      41
      25)
    (let $prepared
      (codex:unified-exec-prepare-process-handles-result-prepared
        $result)
      (codex:unified-exec-prepared-process-handles-output-buffer
        $prepared)))
  output-buffer-1)

!(assertEqual
  (let $result
    (codex:unified-exec-prepare-process-handles
      (prepared-store-with-entry
        (prepared-entry 41 10 session-1 True))
      41
      25)
    (let $prepared
      (codex:unified-exec-prepare-process-handles-result-prepared
        $result)
      (codex:unified-exec-prepared-process-handles-output-notify
        $prepared)))
  output-notify-1)

!(assertEqual
  (let $result
    (codex:unified-exec-prepare-process-handles
      (prepared-store-with-entry
        (prepared-entry 41 10 session-1 True))
      41
      25)
    (let $prepared
      (codex:unified-exec-prepare-process-handles-result-prepared
        $result)
      (codex:unified-exec-prepared-process-handles-output-closed
        $prepared)))
  False)

!(assertEqual
  (let $result
    (codex:unified-exec-prepare-process-handles
      (prepared-store-with-entry
        (prepared-entry 41 10 session-1 True))
      41
      25)
    (let $prepared
      (codex:unified-exec-prepare-process-handles-result-prepared
        $result)
      (codex:unified-exec-prepared-process-handles-output-closed-notify
        $prepared)))
  output-closed-notify-1)

!(assertEqual
  (let $result
    (codex:unified-exec-prepare-process-handles
      (prepared-store-with-entry
        (prepared-entry 41 10 session-1 True))
      41
      25)
    (let $prepared
      (codex:unified-exec-prepare-process-handles-result-prepared
        $result)
      (codex:unified-exec-prepared-process-handles-cancellation-token
        $prepared)))
  cancellation-token-1)

!(assertEqual
  (let $result
    (codex:unified-exec-prepare-process-handles
      (prepared-store-with-entry
        (prepared-entry 41 10 session-1 True))
      41
      25)
    (let $prepared
      (codex:unified-exec-prepare-process-handles-result-prepared
        $result)
      (codex:unified-exec-prepared-process-handles-pause-state
        $prepared)))
  (codex:unified-exec-pause-state-subscription session-1))

!(assertEqual
  (let $result
    (codex:unified-exec-prepare-process-handles
      (prepared-store-with-entry
        (prepared-entry 41 10 CodexAbsent False))
      41
      25)
    (let $prepared
      (codex:unified-exec-prepare-process-handles-result-prepared
        $result)
      (codex:unified-exec-prepared-process-handles-pause-state
        $prepared)))
  CodexAbsent)

!(assertEqual
  (let $result
    (codex:unified-exec-prepare-process-handles
      (prepared-store-with-entry
        (prepared-entry 41 10 session-1 True))
      41
      25)
    (let $updated-entry
      (codex:unified-exec-process-store-get-entry
        (codex:unified-exec-prepare-process-handles-result-store
          $result)
        41)
      (codex:unified-exec-process-entry-last-used
        $updated-entry)))
  25)
