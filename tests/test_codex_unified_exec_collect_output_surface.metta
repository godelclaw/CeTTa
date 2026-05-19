!(register-module! ../codex)
!(import! &self codex:unified_exec_collect_output)

(= (collect-buffer $chunks)
   (collect-buffer-from $chunks (codex:head-tail-buffer-new 100)))

(= (collect-buffer-from $chunks $buffer)
   (if (== $chunks ())
       $buffer
       (collect-buffer-from
         (list:rest $chunks)
         (codex:head-tail-buffer-push-chunk
           $buffer
           (list:first $chunks)))))

(= (collect-empty-buffer)
   (collect-buffer ()))

(= (collect-step
      $now-ms
      $pause-state
      $chunks
      $cancelled
      $closed
      $wait-outcome)
   (codex:unified-exec-collect-step
     $now-ms
     $pause-state
     (collect-buffer $chunks)
     $cancelled
     $closed
     $wait-outcome))

!(assertEqual
  (codex:unified-exec-post-exit-close-wait-cap-ms)
  50)

!(assertEqual
  (codex:unified-exec-collect-saturating-duration-ms 100 75)
  25)

!(assertEqual
  (codex:unified-exec-collect-saturating-duration-ms 100 125)
  0)

!(assertEqual
  (codex:unified-exec-collect-min-ms 10 50)
  10)

!(assertEqual
  (codex:unified-exec-collect-min-ms 100 50)
  50)

!(assertEqual
  (codex:unified-exec-collect-merge-exit-signal False True)
  True)

!(assertEqual
  (codex:unified-exec-collect-merge-exit-signal True False)
  True)

!(assertEqual
  (codex:unified-exec-collect-pause-state-paused-for-ms
    (codex:unified-exec-collect-pause-state True 37))
  37)

!(assertEqual
  (codex:unified-exec-collect-state-deadline-ms
    (codex:unified-exec-collect-extend-deadlines-while-paused
      (codex:unified-exec-collect-state () False 100 CodexAbsent)
      (codex:unified-exec-collect-pause-state True 25)))
  125)

!(assertEqual
  (codex:unified-exec-collect-state-deadline-ms
    (codex:unified-exec-collect-extend-deadlines-while-paused
      (codex:unified-exec-collect-state () False 100 CodexAbsent)
      (codex:unified-exec-collect-pause-state False 25)))
  100)

!(assertEqual
  (codex:unified-exec-collect-state-post-exit-deadline-ms
    (codex:unified-exec-collect-extend-deadlines-while-paused
      (codex:unified-exec-collect-state () True 100 150)
      (codex:unified-exec-collect-pause-state True 25)))
  175)

!(assertEqual
  (codex:unified-exec-collect-result-collected-text
    (codex:unified-exec-collect-output-until-deadline
      False
      100
      ((collect-step
         0
         CodexAbsent
         ("hello" " ")
         False
         False
         (codex:unified-exec-collect-wait-output-notified))
       (collect-step
         10
         CodexAbsent
         ("world")
         False
         False
         (codex:unified-exec-collect-wait-output-notified))
       (collect-step
         100
         CodexAbsent
         ()
         False
         False
         (codex:unified-exec-collect-wait-timeout)))))
  "hello world")

!(assertEqual
  (codex:unified-exec-collect-result-reason
    (codex:unified-exec-collect-output-until-deadline
      False
      100
      ((collect-step
         100
         CodexAbsent
         ()
         False
         False
         (codex:unified-exec-collect-wait-timeout)))))
  deadline_elapsed)

!(assertEqual
  (codex:unified-exec-collect-result-reason
    (codex:unified-exec-collect-output-until-deadline
      True
      100
      ((collect-step
         0
         CodexAbsent
         ()
         False
         True
         (codex:unified-exec-collect-wait-output-closed-notified)))))
  exit_signal_and_output_closed)

!(assertEqual
  (codex:unified-exec-collect-result-reason
    (codex:unified-exec-collect-output-until-deadline
      False
      100
      ((collect-step
         0
         CodexAbsent
         ()
         False
         False
         (codex:unified-exec-collect-wait-exit-notified))
       (collect-step
         5
         CodexAbsent
         ()
         False
         True
         (codex:unified-exec-collect-wait-output-closed-notified)))))
  exit_signal_and_output_closed)

!(assertEqual
  (codex:unified-exec-collect-state-post-exit-deadline-ms
    (codex:unified-exec-collect-result-state
      (codex:unified-exec-collect-output-until-deadline
        True
        1000
        ((collect-step
           0
           CodexAbsent
           ()
           False
           False
           (codex:unified-exec-collect-wait-output-notified))
         (collect-step
           51
           CodexAbsent
           ()
           False
           False
           (codex:unified-exec-collect-wait-timeout))))))
  50)

!(assertEqual
  (codex:unified-exec-collect-result-reason
    (codex:unified-exec-collect-output-until-deadline
      True
      1000
      ((collect-step
         0
         CodexAbsent
         ()
         False
         False
         (codex:unified-exec-collect-wait-output-notified))
       (collect-step
         51
         CodexAbsent
         ()
         False
         False
         (codex:unified-exec-collect-wait-timeout)))))
  post_exit_close_wait_elapsed)

!(assertEqual
  (codex:unified-exec-collect-result-reason
    (codex:unified-exec-collect-output-until-deadline
      False
      100
      ((collect-step
         100
         (codex:unified-exec-collect-pause-state True 25)
         ("late")
         False
         False
         (codex:unified-exec-collect-wait-output-notified))
       (collect-step
         125
         CodexAbsent
         ()
         False
         False
         (codex:unified-exec-collect-wait-timeout)))))
  deadline_elapsed)

!(assertEqual
  (codex:unified-exec-collect-result-collected-text
    (codex:unified-exec-collect-output-until-deadline
      False
      100
      ((collect-step
         100
         (codex:unified-exec-collect-pause-state True 25)
         ("late")
         False
         False
         (codex:unified-exec-collect-wait-output-notified))
       (collect-step
         125
         CodexAbsent
         ()
         False
         False
         (codex:unified-exec-collect-wait-timeout)))))
  "late")

!(assertEqual
  (codex:unified-exec-collect-state-post-exit-deadline-ms
    (codex:unified-exec-collect-result-state
      (codex:unified-exec-collect-output-until-deadline
        True
        100
        ((collect-step
           0
           CodexAbsent
           ()
           False
           False
           (codex:unified-exec-collect-wait-output-notified))
         (collect-step
           60
           (codex:unified-exec-collect-pause-state True 30)
           ()
           False
           False
           (codex:unified-exec-collect-wait-timeout))))))
  80)

!(assertEqual
  (codex:unified-exec-collect-result-reason
    (codex:unified-exec-collect-output-until-deadline
      True
      100
      ((collect-step
         0
         CodexAbsent
         ()
         False
         False
         (codex:unified-exec-collect-wait-output-notified))
       (collect-step
         60
         (codex:unified-exec-collect-pause-state True 30)
         ()
         False
         False
         (codex:unified-exec-collect-wait-timeout)))))
  post_exit_close_wait_timeout)

!(assertEqual
  (codex:unified-exec-collect-result-reason
    (codex:unified-exec-collect-output-until-deadline
      False
      100
      ()))
  script_exhausted)
