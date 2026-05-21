!(register-module! ../codex)
!(import! &self codex:js_repl_stdout_exec_result)

(= (test:manager-exec-1)
   (codex:js-repl-read-stdout-manager-kernel
     (codex:js-repl-top-level-exec-state-submitted
       "turn-1"
       "exec-1")))

(= (test:pending-exec-1)
   (codex:js-repl-read-stdout-pending-execs
     ((codex:js-repl-pending-exec-entry "exec-1" sender-1))))

(= (test:contexts-exec-1)
   (codex:js-repl-read-stdout-exec-contexts
     ((codex:js-repl-exec-context-entry "exec-1" context-1))))

(= (test:tool-calls-exec-1-ready)
   (codex:js-repl-exec-tool-calls-map
     ((codex:js-repl-exec-tool-calls-entry
        "exec-1"
        (codex:js-repl-exec-tool-calls-state
          0
          ((CodexInputImage "data:image/png;base64,AAA" "high"))
          notify-1
          cancel-1)))))

(= (test:ok-result)
   (codex:js-repl-read-stdout-exec-result-step
     (codex:js-repl-kernel-to-host-exec-result
       "exec-1"
       True
       "stdout"
       CodexAbsent)
     (test:manager-exec-1)
     (test:pending-exec-1)
     (test:contexts-exec-1)
     (test:tool-calls-exec-1-ready)))

!(assertEqual
  (codex:js-repl-read-stdout-exec-result-step-result-status
    (test:ok-result))
  CodexJsReplReadStdoutExecResultStatusApplied)

!(assertEqual
  (codex:js-repl-read-stdout-manager-kernel-top-level-exec-state
    (codex:js-repl-read-stdout-exec-result-step-result-manager-kernel
      (test:ok-result)))
  (CodexJsReplTopLevelExecStateIdle))

!(assertEqual
  (codex:js-repl-read-stdout-pending-execs-entries
    (codex:js-repl-read-stdout-exec-result-step-result-pending-execs
      (test:ok-result)))
  ())

!(assertEqual
  (codex:js-repl-read-stdout-exec-contexts-entries
    (codex:js-repl-read-stdout-exec-result-step-result-exec-contexts
      (test:ok-result)))
  ())

!(assertEqual
  (codex:js-repl-exec-tool-calls-map-entries
    (codex:js-repl-read-stdout-exec-result-step-result-exec-tool-calls
      (test:ok-result)))
  ())

!(assertEqual
  (codex:js-repl-read-stdout-exec-result-step-result-actions
    (test:ok-result))
  ((CodexJsReplReadStdoutActionWaitForExecToolCalls
     "exec-1"
     CodexJsReplWaitExecToolCallsComplete)
   (CodexJsReplReadStdoutActionSendExecResult
     sender-1
     (CodexJsReplExecResultMessageOk
       ((CodexInputText "stdout")
        (CodexInputImage "data:image/png;base64,AAA" "high"))))
   (CodexJsReplExecToolCallActionCancel cancel-1)
   (CodexJsReplExecToolCallActionNotifyWaiters notify-1)))

(= (test:tool-calls-exec-1-waiting)
   (codex:js-repl-exec-tool-calls-map
     ((codex:js-repl-exec-tool-calls-entry
        "exec-1"
        (codex:js-repl-exec-tool-calls-state
          1
          ((CodexInputText "nested"))
          notify-1
          cancel-1)))))

(= (test:waiting-result)
   (codex:js-repl-read-stdout-exec-result-step
     (codex:js-repl-kernel-to-host-exec-result
       "exec-1"
       True
       "stdout"
       CodexAbsent)
     (test:manager-exec-1)
     (test:pending-exec-1)
     (test:contexts-exec-1)
     (test:tool-calls-exec-1-waiting)))

!(assertEqual
  (codex:js-repl-read-stdout-exec-result-step-result-status
    (test:waiting-result))
  CodexJsReplReadStdoutExecResultStatusWaiting)

!(assertEqual
  (codex:js-repl-read-stdout-exec-result-step-result-actions
    (test:waiting-result))
  ((CodexJsReplReadStdoutActionWaitForExecToolCalls
     "exec-1"
     (CodexJsReplWaitExecToolCallsWait notify-1))))

!(assertEqual
  (codex:js-repl-read-stdout-pending-execs-entries
    (codex:js-repl-read-stdout-exec-result-step-result-pending-execs
      (test:waiting-result)))
  ((CodexJsReplPendingExecEntry "exec-1" sender-1)))

(= (test:err-result)
   (codex:js-repl-read-stdout-exec-result-step
     (codex:js-repl-kernel-to-host-exec-result
       "exec-1"
       False
       "ignored"
       CodexAbsent)
     (test:manager-exec-1)
     (test:pending-exec-1)
     (test:contexts-exec-1)
     (codex:js-repl-exec-tool-calls-map-empty)))

!(assertEqual
  (codex:js-repl-read-stdout-exec-result-step-result-actions
    (test:err-result))
  ((CodexJsReplReadStdoutActionWaitForExecToolCalls
     "exec-1"
     CodexJsReplWaitExecToolCallsComplete)
   (CodexJsReplReadStdoutActionSendExecResult
     sender-1
     (CodexJsReplExecResultMessageErr
       "js_repl execution failed"))))

(= (test:missing-pending-result)
   (codex:js-repl-read-stdout-exec-result-step
     (codex:js-repl-kernel-to-host-exec-result
       "exec-1"
       True
       "stdout"
       CodexAbsent)
     (test:manager-exec-1)
     (codex:js-repl-read-stdout-pending-execs ())
     (test:contexts-exec-1)
     (test:tool-calls-exec-1-ready)))

!(assertEqual
  (codex:js-repl-read-stdout-manager-kernel-top-level-exec-state
    (codex:js-repl-read-stdout-exec-result-step-result-manager-kernel
      (test:missing-pending-result)))
  (CodexJsReplTopLevelExecStateSubmitted "turn-1" "exec-1"))

!(assertEqual
  (codex:js-repl-read-stdout-exec-contexts-entries
    (codex:js-repl-read-stdout-exec-result-step-result-exec-contexts
      (test:missing-pending-result)))
  ())

!(assertEqual
  (codex:js-repl-read-stdout-exec-result-step-result-actions
    (test:missing-pending-result))
  ((CodexJsReplReadStdoutActionWaitForExecToolCalls
     "exec-1"
     CodexJsReplWaitExecToolCallsComplete)
   (CodexJsReplExecToolCallActionCancel cancel-1)
   (CodexJsReplExecToolCallActionNotifyWaiters notify-1)))
