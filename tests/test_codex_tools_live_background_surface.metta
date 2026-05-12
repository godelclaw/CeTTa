!(register-module! ../codex)
!(import! &self codex:tools)

(= (test:background-poll-snapshot)
   (let $args
     (codex:parse-exec-command-args
       "{\"cmd\":\"sleep 0.4; yes a | head -c 70000; sleep 1; printf done\",\"login\":false,\"yield_time_ms\":250}")
     (case
       (process-open-session-cmd-cwd-env-tty-event-call-id-hook-command-yield-cap-bytes
         (codex:exec-command-argv $args)
         (codex:exec-command-cwd $args)
         (process-create-shell-env-no-thread
           (process-default-shell-env-policy))
         (codex:exec-command-tty $args)
         "call_background_open"
         (codex:exec-command-text $args)
         (codex:exec-command-yield-time-ms $args)
         128)
       (((ProcessSessionCallResult
            True
            $error
            (ProcessSessionSnapshot
              True
              $session-id
              $has-exit-code
              $exit-code
              $stdout
              $stderr
              $aggregated-output
              $duration-ms
              $event-call-id
              $hook-command))
         (let $wait-result
           (process-run-shell-timeout-ms
             (format-args "sleep {}" ((codex:duration-ms-to-seconds-text 1800)))
             3800)
           (case
             (process-write-session-stdin-yield-cap-bytes
               $session-id
               ""
               100
               128)
             (((ProcessSessionCallResult True $write-error $snapshot)
               $snapshot)
              ($other ProcessNoSessionSnapshot)))))
        ($other ProcessNoSessionSnapshot)))))

!(assertEqualToResult
  (or
    (process-session-snapshot-is-running
      (once (test:background-poll-snapshot)))
    (codex:is-string-contains
      (process-session-snapshot-aggregated-output
        (once (test:background-poll-snapshot)))
      "done"))
  (True))

!(assertEqualToResult
  (<
    (process-session-snapshot-duration-ms
      (once (test:background-poll-snapshot)))
    1800)
  (True))
