!(register-module! ../codex)
!(import! &self codex:js_repl_exec_tool_calls)

(= (test:single-map)
   (codex:js-repl-register-exec-tool-calls-map
     (codex:js-repl-exec-tool-calls-map-empty)
     "exec-1"
     notify-1
     cancel-1))

!(assertEqual
  (codex:js-repl-exec-tool-calls-state-in-flight
    (codex:js-repl-exec-tool-calls-default notify-1 cancel-1))
  0)

!(assertEqual
  (codex:js-repl-exec-tool-calls-state-content-items
    (codex:js-repl-exec-tool-calls-default notify-1 cancel-1))
  ())

!(assertEqual
  (codex:js-repl-exec-tool-calls-map-entries
    (test:single-map))
  ((CodexJsReplExecToolCallsEntry
     "exec-1"
     (CodexJsReplExecToolCallsState 0 () notify-1 cancel-1))))

!(assertEqual
  (codex:js-repl-exec-tool-calls-map-entries
    (codex:js-repl-register-exec-tool-calls-map
      (test:single-map)
      "exec-1"
      notify-2
      cancel-2))
  ((CodexJsReplExecToolCallsEntry
     "exec-1"
     (CodexJsReplExecToolCallsState 0 () notify-2 cancel-2))))

!(assertEqual
  (codex:js-repl-begin-exec-tool-call-result-cancel
    (codex:js-repl-begin-exec-tool-call-map
      (test:single-map)
      "exec-1"))
  cancel-1)

!(assertEqual
  (codex:js-repl-exec-tool-calls-map-find-state
    (codex:js-repl-begin-exec-tool-call-result-map
      (codex:js-repl-begin-exec-tool-call-map
        (test:single-map)
        "exec-1"))
    "exec-1")
  (CodexJsReplExecToolCallsState 1 () notify-1 cancel-1))

!(assertEqual
  (codex:js-repl-begin-exec-tool-call-result-cancel
    (codex:js-repl-begin-exec-tool-call-map
      (test:single-map)
      "missing"))
  CodexAbsent)

!(assertEqual
  (codex:js-repl-wait-for-exec-tool-calls-map-step
    (codex:js-repl-begin-exec-tool-call-result-map
      (codex:js-repl-begin-exec-tool-call-map
        (test:single-map)
        "exec-1"))
    "exec-1")
  (CodexJsReplWaitExecToolCallsWait notify-1))

!(assertEqual
  (codex:js-repl-wait-for-exec-tool-calls-map-step
    (test:single-map)
    "exec-1")
  CodexJsReplWaitExecToolCallsComplete)

!(assertEqual
  (codex:js-repl-exec-tool-calls-state-content-items
    (codex:js-repl-exec-tool-calls-map-find-state
      (codex:js-repl-record-exec-content-item-map
        (codex:js-repl-record-exec-content-item-map
          (test:single-map)
          "exec-1"
          (CodexInputText "alpha"))
        "exec-1"
        (CodexInputImage "data:image/png;base64,AAA" "high"))
      "exec-1"))
  ((CodexInputText "alpha")
   (CodexInputImage "data:image/png;base64,AAA" "high")))

!(assertEqual
  (codex:js-repl-record-exec-content-item-map
    (test:single-map)
    "missing"
    (CodexInputText "ignored"))
  (test:single-map))

!(assertEqual
  (codex:js-repl-finish-exec-tool-call-result-actions
    (codex:js-repl-finish-exec-tool-call-map
      (codex:js-repl-begin-exec-tool-call-result-map
        (codex:js-repl-begin-exec-tool-call-map
          (test:single-map)
          "exec-1"))
      "exec-1"))
  ((CodexJsReplExecToolCallActionNotifyWaiters notify-1)))

!(assertEqual
  (codex:js-repl-exec-tool-calls-map-find-state
    (codex:js-repl-finish-exec-tool-call-result-map
      (codex:js-repl-finish-exec-tool-call-map
        (codex:js-repl-begin-exec-tool-call-result-map
          (codex:js-repl-begin-exec-tool-call-map
            (test:single-map)
            "exec-1"))
        "exec-1"))
    "exec-1")
  (CodexJsReplExecToolCallsState 0 () notify-1 cancel-1))

!(assertEqual
  (codex:js-repl-finish-exec-tool-call-result-actions
    (codex:js-repl-finish-exec-tool-call-map
      (test:single-map)
      "exec-1"))
  ())

!(assertEqual
  (codex:js-repl-finish-exec-tool-call-result-actions
    (codex:js-repl-finish-exec-tool-call-map
      (codex:js-repl-begin-exec-tool-call-result-map
        (codex:js-repl-begin-exec-tool-call-map
          (codex:js-repl-begin-exec-tool-call-result-map
            (codex:js-repl-begin-exec-tool-call-map
              (test:single-map)
              "exec-1"))
          "exec-1"))
      "exec-1"))
  ())

!(assertEqual
  (codex:js-repl-exec-tool-calls-state-in-flight
    (codex:js-repl-exec-tool-calls-map-find-state
      (codex:js-repl-finish-exec-tool-call-result-map
        (codex:js-repl-finish-exec-tool-call-map
          (codex:js-repl-begin-exec-tool-call-result-map
            (codex:js-repl-begin-exec-tool-call-map
              (codex:js-repl-begin-exec-tool-call-result-map
                (codex:js-repl-begin-exec-tool-call-map
                  (test:single-map)
                  "exec-1"))
              "exec-1"))
          "exec-1"))
      "exec-1"))
  1)

!(assertEqual
  (codex:js-repl-clear-exec-tool-calls-result-actions
    (codex:js-repl-clear-exec-tool-calls-map
      (test:single-map)
      "exec-1"))
  ((CodexJsReplExecToolCallActionCancel cancel-1)
   (CodexJsReplExecToolCallActionNotifyWaiters notify-1)))

!(assertEqual
  (codex:js-repl-exec-tool-calls-map-entries
    (codex:js-repl-clear-exec-tool-calls-result-map
      (codex:js-repl-clear-exec-tool-calls-map
        (test:single-map)
        "exec-1")))
  ())

!(assertEqual
  (codex:js-repl-clear-exec-tool-calls-result-actions
    (codex:js-repl-clear-exec-tool-calls-map
      (test:single-map)
      "missing"))
  ())

!(assertEqual
  (codex:js-repl-clear-exec-tool-calls-result-actions
    (codex:js-repl-clear-all-exec-tool-calls-map
      (codex:js-repl-register-exec-tool-calls-map
        (test:single-map)
        "exec-2"
        notify-2
        cancel-2)))
  ((CodexJsReplExecToolCallActionCancel cancel-1)
   (CodexJsReplExecToolCallActionNotifyWaiters notify-1)
   (CodexJsReplExecToolCallActionCancel cancel-2)
   (CodexJsReplExecToolCallActionNotifyWaiters notify-2)))

!(assertEqual
  (codex:js-repl-exec-tool-calls-map-entries
    (codex:js-repl-clear-exec-tool-calls-result-map
      (codex:js-repl-clear-all-exec-tool-calls-map
        (test:single-map))))
  ())
