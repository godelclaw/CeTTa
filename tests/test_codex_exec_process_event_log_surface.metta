!(register-module! ../codex)
!(import! &self codex:exec_process_event_log)

(= (test:exec-event-output $seq $text)
   (codex:exec-process-event-output
     (codex:exec-process-output-chunk
       $seq
       (codex:exec-output-stream-stdout)
       $text)))

!(assertEqual
  (codex:exec-process-event-seq
    (test:exec-event-output 7 "chunk"))
  7)

!(assertEqual
  (codex:exec-process-event-seq
    (codex:exec-process-event-exited 8 0))
  8)

!(assertEqual
  (codex:exec-process-event-seq
    (codex:exec-process-event-closed 9))
  9)

!(assertEqual
  (codex:exec-process-event-seq
    (codex:exec-process-event-failed "disconnected"))
  CodexAbsent)

!(assertEqual
  (codex:exec-process-event-retained-len
    (test:exec-event-output 1 "large"))
  5)

!(assertEqual
  (codex:exec-process-event-retained-len
    (codex:exec-process-event-failed "transport failed"))
  16)

!(assertEqual
  (codex:exec-process-event-receiver-replay
    (codex:exec-process-event-log-subscribe
      (let $log-0 (codex:exec-process-event-log-new 8 3)
        (let $log-1
          (codex:exec-process-event-log-publish
            $log-0
            (test:exec-event-output 1 "large"))
          (let $log-2
            (codex:exec-process-event-log-publish
              $log-1
              (codex:exec-process-event-exited 2 0))
            (codex:exec-process-event-log-publish
              $log-2
              (codex:exec-process-event-closed 3)))))))
  ((CodexExecProcessEventExited 2 0)
   (CodexExecProcessEventClosed 3)))

!(assertEqual
  (codex:exec-process-event-receiver-replay
    (codex:exec-process-event-log-subscribe
      (let $log-0 (codex:exec-process-event-log-new 2 100)
        (let $log-1
          (codex:exec-process-event-log-publish
            $log-0
            (test:exec-event-output 1 "a"))
          (let $log-2
            (codex:exec-process-event-log-publish
              $log-1
              (test:exec-event-output 2 "b"))
            (codex:exec-process-event-log-publish
              $log-2
              (test:exec-event-output 3 "c")))))))
  ((CodexExecProcessEventOutput
     (CodexExecProcessOutputChunk
       2
       (CodexExecOutputStreamStdout)
       "b"))
   (CodexExecProcessEventOutput
     (CodexExecProcessOutputChunk
       3
       (CodexExecOutputStreamStdout)
       "c"))))

!(assertEqual
  (codex:exec-process-event-history-retained-bytes
    (codex:exec-process-event-log-history
      (let $log-0 (codex:exec-process-event-log-new 8 4)
        (let $log-1
          (codex:exec-process-event-log-publish
            $log-0
            (test:exec-event-output 1 "ab"))
          (codex:exec-process-event-log-publish
            $log-1
            (test:exec-event-output 2 "cde"))))))
  3)

!(assertEqual
  (codex:exec-process-event-receiver-replay
    (codex:exec-process-event-receiver-empty))
  ())

!(assertEqual
  (codex:exec-process-event-recv-result-event
    (codex:exec-process-event-receiver-recv
      (codex:exec-process-event-receiver
        ((CodexExecProcessEventExited 4 0)
         (CodexExecProcessEventClosed 5)))))
  (CodexExecProcessEventExited 4 0))

!(assertEqual
  (codex:exec-process-event-receiver-replay
    (codex:exec-process-event-recv-result-receiver
      (codex:exec-process-event-receiver-recv
        (codex:exec-process-event-receiver
          ((CodexExecProcessEventExited 4 0)
           (CodexExecProcessEventClosed 5))))))
  ((CodexExecProcessEventClosed 5)))

!(assertEqual
  (codex:exec-process-event-receiver-recv
    (codex:exec-process-event-receiver-empty))
  (CodexExecProcessEventRecvLivePending
    (CodexExecProcessEventReceiver ())))
