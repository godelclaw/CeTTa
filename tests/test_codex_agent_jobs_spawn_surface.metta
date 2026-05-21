!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:agent_jobs)
!(import! &self codex:agent_jobs_active)
!(import! &self codex:agent_jobs_spawn)

(= (test-agent-job-spawn-job)
   (codex:agent-job
     "job-1"
     "example"
     (codex:agent-job-status-running)
     "Review {path}"
     True
     CodexAbsent
     CodexAbsent
     ("path")
     "/tmp/input.csv"
     "/tmp/output.csv"
     "2026-05-21T00:00:00+00:00"
     "2026-05-21T00:00:00+00:00"
     CodexAbsent
     CodexAbsent
     CodexAbsent))

(= (test-agent-job-spawn-item)
   (codex:agent-job-item
     "job-1"
     "item-1"
     0
     CodexAbsent
     (JsonObject ((JsonPair "path" (JsonString "src/lib.rs"))))
     (codex:agent-job-item-status-pending)
     0
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent))

(= (test-agent-job-spawn-request)
   (codex:agent-job-build-spawn-worker-request
     (test-agent-job-spawn-job)
     (test-agent-job-spawn-item)
     (CodexTestSpawnConfig)
     ("env-a" "env-b")))

!(assertEqual
  (codex:agent-job-spawn-pending-gate True 0 4)
  (codex:agent-job-spawn-pending-skip))

!(assertEqual
  (codex:agent-job-spawn-pending-gate False 4 4)
  (codex:agent-job-spawn-pending-skip))

!(assertEqual
  (codex:agent-job-spawn-pending-gate False 2 5)
  (codex:agent-job-spawn-pending-list 3))

!(assertEqual
  (codex:agent-job-spawn-worker-source "job-1")
  "agent_job:job-1")

!(assertEqual
  (codex:agent-job-spawn-worker-request-source
    (test-agent-job-spawn-request))
  "agent_job:job-1")

!(assertEqual
  (codex:agent-job-spawn-worker-request-environments
    (test-agent-job-spawn-request))
  ("env-a" "env-b"))

!(assertEqual
  (codex:agent-job-spawn-worker-request-first-text
    (test-agent-job-spawn-request))
  (codex:agent-job-build-worker-prompt
    (test-agent-job-spawn-job)
    (test-agent-job-spawn-item)))

!(assertEqual
  (codex:agent-job-spawn-item-after-attempt
    "job-1"
    (test-agent-job-spawn-item)
    (codex:agent-job-spawn-worker-agent-limit-reached)
    CodexAbsent
    1000
    CodexAbsent)
  (codex:agent-job-spawn-item-result
    False
    (codex:agent-job-spawn-loop-break)
    ((codex:agent-job-spawn-mark-pending
       "job-1"
       "item-1"
       CodexAbsent))))

!(assertEqual
  (codex:agent-job-spawn-item-after-attempt
    "job-1"
    (test-agent-job-spawn-item)
    (codex:agent-job-spawn-worker-err "queue closed")
    CodexAbsent
    1000
    CodexAbsent)
  (codex:agent-job-spawn-item-result
    True
    (codex:agent-job-spawn-loop-continue)
    ((codex:agent-job-spawn-mark-failed
       "job-1"
       "item-1"
       "failed to spawn worker: queue closed"))))

!(assertEqual
  (codex:agent-job-spawn-item-after-attempt
    "job-1"
    (test-agent-job-spawn-item)
    (codex:agent-job-spawn-worker-ok "thread-1")
    False
    1000
    CodexAbsent)
  (codex:agent-job-spawn-item-result
    False
    (codex:agent-job-spawn-loop-continue)
    ((codex:agent-job-spawn-mark-running-with-thread
       "job-1"
       "item-1"
       "thread-1")
     (codex:agent-job-spawn-shutdown-thread "thread-1"))))

!(assertEqual
  (codex:agent-job-spawn-item-after-attempt
    "job-1"
    (test-agent-job-spawn-item)
    (codex:agent-job-spawn-worker-ok "thread-2")
    True
    1000
    CodexAbsent)
  (codex:agent-job-spawn-item-result
    True
    (codex:agent-job-spawn-loop-continue)
    ((codex:agent-job-spawn-mark-running-with-thread
       "job-1"
       "item-1"
       "thread-2")
     (codex:agent-job-spawn-activate-thread
       "thread-2"
       (codex:agent-job-active-item "item-1" 1000 CodexAbsent)))))
