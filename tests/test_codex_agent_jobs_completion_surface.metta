!(register-module! ../codex)
!(import! &self codex:agent_jobs)
!(import! &self codex:agent_jobs_completion)

(= (test-agent-job-progress-before)
   (codex:agent-job-progress 5 2 0 2 1))

(= (test-agent-job-progress-after)
   (codex:agent-job-progress 5 0 0 4 1))

!(assertEqual
  (codex:agent-job-loop-auto-export-error-message "disk full")
  "auto-export failed: disk full")

!(assertEqual
  (codex:agent-job-loop-completion-plan
    "job-1"
    (test-agent-job-progress-before)
    (codex:agent-job-loop-export-err "disk full")
    False
    False
    (test-agent-job-progress-after))
  (codex:agent-job-loop-completion-actions
    ((codex:agent-job-loop-mark-job-failed
       "job-1"
       "auto-export failed: disk full"))))

!(assertEqual
  (codex:agent-job-loop-completion-plan
    "job-1"
    (test-agent-job-progress-before)
    (codex:agent-job-loop-export-ok)
    True
    False
    (test-agent-job-progress-after))
  (codex:agent-job-loop-completion-actions
    ((codex:agent-job-loop-notify
       "agent job job-1 cancelled with 2 unprocessed items")
     (codex:agent-job-loop-emit-progress
       (test-agent-job-progress-before)
       True))))

!(assertEqual
  (codex:agent-job-loop-completion-plan
    "job-1"
    (test-agent-job-progress-before)
    (codex:agent-job-loop-export-ok)
    False
    True
    (test-agent-job-progress-after))
  (codex:agent-job-loop-completion-actions
    ((codex:agent-job-loop-notify
       "agent job job-1 cancelled with 2 unprocessed items")
     (codex:agent-job-loop-emit-progress
       (test-agent-job-progress-before)
       True))))

!(assertEqual
  (codex:agent-job-loop-completion-plan
    "job-1"
    (test-agent-job-progress-before)
    (codex:agent-job-loop-export-ok)
    False
    False
    (test-agent-job-progress-after))
  (codex:agent-job-loop-completion-actions
    ((codex:agent-job-loop-notify
       "agent job completed with 1 failed items")
     (codex:agent-job-loop-mark-job-completed "job-1")
     (codex:agent-job-loop-emit-progress
       (test-agent-job-progress-after)
       True))))

!(assertEqual
  (codex:agent-job-loop-completion-plan
    "job-1"
    (codex:agent-job-progress 5 0 0 5 0)
    (codex:agent-job-loop-export-ok)
    False
    False
    (codex:agent-job-progress 5 0 0 5 0))
  (codex:agent-job-loop-completion-actions
    ((codex:agent-job-loop-mark-job-completed "job-1")
     (codex:agent-job-loop-emit-progress
       (codex:agent-job-progress 5 0 0 5 0)
       True))))
