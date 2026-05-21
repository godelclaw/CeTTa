!(register-module! ../codex)
!(import! &self codex:js_repl_kernel_io)
!(import! &self codex:js_repl_kernel_lifecycle)

(= (test:recent-stderr $lines)
   (codex:js-repl-arc-mutex
     (codex:js-repl-recent-stderr-buffer
       (codex:js-repl-stderr-tail-line-limit)
       $lines)))

!(assertEqual
  (codex:js-repl-kill-kernel-child-plan-operations
    (codex:js-repl-kill-kernel-child-plan-from-observation
      (codex:js-repl-child-inspection
        10
        (codex:js-repl-child-try-wait-exited
          (codex:js-repl-exit-status-code 0)))
      "reset"
      (codex:js-repl-start-kill-error "unused")
      (codex:js-repl-kill-wait-timeout)))
  ((CodexJsReplKillOperationInspect 10 "reset")))

!(assertEqual
  (codex:js-repl-kill-kernel-child-plan-warnings
    (codex:js-repl-kill-kernel-child-plan-from-observation
      (codex:js-repl-child-inspection
        10
        (codex:js-repl-child-try-wait-exited
          (codex:js-repl-exit-status-code 0)))
      "reset"
      (codex:js-repl-start-kill-error "unused")
      (codex:js-repl-kill-wait-timeout)))
  ())

!(assertEqual
  (codex:js-repl-kill-kernel-child-plan-warnings
    (codex:js-repl-kill-kernel-child-plan-from-observation
      (codex:js-repl-child-inspection
        11
        (codex:js-repl-child-try-wait-running))
      "drop"
      (codex:js-repl-start-kill-error "permission denied")
      (codex:js-repl-kill-wait-ok)))
  ((CodexJsReplKillWarning
     "failed to send kill signal to js_repl kernel"
     11
     "drop"
     "permission denied")))

!(assertEqual
  (codex:js-repl-kill-kernel-child-plan-operations
    (codex:js-repl-kill-kernel-child-plan-from-observation
      (codex:js-repl-child-inspection
        12
        (codex:js-repl-child-try-wait-error "try_wait failed"))
      "reset"
      (codex:js-repl-start-kill-ok)
      (codex:js-repl-kill-wait-timeout)))
  ((CodexJsReplKillOperationInspect 12 "reset")
   (CodexJsReplKillOperationStartKill 12 "reset")
   (CodexJsReplKillOperationWait 12 "reset" 2)))

!(assertEqual
  (codex:js-repl-kill-kernel-child-plan-warnings
    (codex:js-repl-kill-kernel-child-plan-from-observation
      (codex:js-repl-child-inspection
        12
        (codex:js-repl-child-try-wait-error "try_wait failed"))
      "reset"
      (codex:js-repl-start-kill-ok)
      (codex:js-repl-kill-wait-timeout)))
  ((CodexJsReplKillWarning
     "failed to inspect js_repl kernel before kill"
     12
     "reset"
     "try_wait failed")
   (CodexJsReplKillWarning
     "timed out waiting for js_repl kernel to exit after kill"
     12
     "reset"
     CodexAbsent)))

!(assertEqual
  (codex:js-repl-kill-kernel-child-plan-warnings
    (codex:js-repl-kill-kernel-child-plan-from-observation
      (codex:js-repl-child-inspection
        13
        (codex:js-repl-child-try-wait-running))
      "shutdown"
      (codex:js-repl-start-kill-ok)
      (codex:js-repl-kill-wait-error "wait failed")))
  ((CodexJsReplKillWarning
     "failed while waiting for js_repl kernel exit"
     13
     "shutdown"
     "wait failed")))

!(assertEqual
  (codex:js-repl-truncate-id-list
    ("a" "b" "c" "d" "e" "f" "g" "h"))
  ("a" "b" "c" "d" "e" "f" "g" "h"))

!(assertEqual
  (codex:js-repl-truncate-id-list
    ("a" "b" "c" "d" "e" "f" "g" "h" "i" "j"))
  ("a" "b" "c" "d" "e" "f" "g" "h" "...+2"))

!(assertEqual
  (codex:js-repl-recent-stderr-buffer-lines
    (codex:js-repl-arc-mutex-value
      (codex:js-repl-read-stderr-step-recent-stderr
        (codex:js-repl-read-stderr-apply-line-state
          (test:recent-stderr ("old"))
          (codex:js-repl-read-stderr-warnings ())
          "  alpha  "))))
  ("old" "alpha"))

!(assertEqual
  (codex:js-repl-read-stderr-warnings-items
    (codex:js-repl-read-stderr-step-warnings
      (codex:js-repl-read-stderr-apply-line-state
        (test:recent-stderr ("old"))
        (codex:js-repl-read-stderr-warnings ())
        "  alpha  ")))
  ("js_repl stderr: alpha"))

!(assertEqual
  (codex:js-repl-recent-stderr-buffer-lines
    (codex:js-repl-arc-mutex-value
      (codex:js-repl-read-stderr-step-recent-stderr
        (codex:js-repl-read-stderr-apply-line-state
          (test:recent-stderr ("old"))
          (codex:js-repl-read-stderr-warnings ())
          "   "))))
  ("old"))

!(assertEqual
  (codex:js-repl-read-stderr-warnings-items
    (codex:js-repl-read-stderr-step-warnings
      (codex:js-repl-read-stderr-apply-line-state
        (test:recent-stderr ("old"))
        (codex:js-repl-read-stderr-warnings ())
        "   ")))
  ())

!(assertEqual
  (codex:js-repl-read-stderr-warnings-items
    (codex:js-repl-read-stderr-add-read-error-warning
      (codex:js-repl-read-stderr-warnings ())
      "read failed"))
  ("js_repl kernel stderr ended: read failed"))

!(assertEqual
  (codex:js-repl-read-stderr-end-eof)
  CodexJsReplReadStderrEndEof)

!(assertEqual
  (codex:js-repl-read-stderr-end-read-error "read failed")
  (CodexJsReplReadStderrEndReadError "read failed"))

!(assertEqual
  (codex:js-repl-read-stderr-end-shutdown)
  CodexJsReplReadStderrEndShutdown)

; Direct EOF remains a whole-loop boundary that does not mutate stderr.
!(assertEqual
  (codex:js-repl-read-stderr-result-lines
    (codex:js-repl-read-stderr-plan
      (test:recent-stderr ("old"))
      ((codex:js-repl-stderr-reader-event-eof))))
  ("old"))

!(assertEqual
  (codex:js-repl-read-stderr-result-warnings
    (codex:js-repl-read-stderr-plan
      (test:recent-stderr ("old"))
      ((codex:js-repl-stderr-reader-event-read-error "read failed"))))
  ("js_repl kernel stderr ended: read failed"))

!(assertEqual
  (codex:js-repl-read-stderr-result-end
    (codex:js-repl-read-stderr-plan
      (test:recent-stderr ("old"))
      ((codex:js-repl-stderr-reader-event-shutdown))))
  CodexJsReplReadStderrEndShutdown)
