!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:agent_jobs)
!(import! &self codex:agent_jobs_finalize)

!(assertEqual
  (codex:agent-job-finalize-finished-item
    "job-1"
    "item-missing"
    "thread-1"
    CodexAbsent)
  (codex:agent-job-finalize-err
    "job item not found for finalization: job-1/item-missing"))

!(assertEqual
  (codex:agent-job-finalize-finished-item
    "job-1"
    "item-1"
    "thread-1"
    (codex:agent-job-item
      "job-1"
      "item-1"
      0
      CodexAbsent
      (JsonObject ())
      (codex:agent-job-item-status-running)
      1
      CodexAbsent
      (JsonObject ((JsonPair "ok" (JsonBool True))))
      "2026-01-01T00:00:00Z"
      CodexAbsent))
  (codex:agent-job-finalize-ok
    (codex:agent-job-finalize-plan
      (codex:agent-job-finalize-mark-completed "job-1" "item-1")
      "thread-1")))

!(assertEqual
  (codex:agent-job-finalize-finished-item
    "job-1"
    "item-2"
    "thread-2"
    (codex:agent-job-item
      "job-1"
      "item-2"
      1
      CodexAbsent
      (JsonObject ())
      (codex:agent-job-item-status-running)
      1
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent))
  (codex:agent-job-finalize-ok
    (codex:agent-job-finalize-plan
      (codex:agent-job-finalize-mark-failed
        "job-1"
        "item-2"
        "worker finished without calling report_agent_job_result")
      "thread-2")))

!(assertEqual
  (codex:agent-job-finalize-finished-item
    "job-1"
    "item-3"
    "thread-3"
    (codex:agent-job-item
      "job-1"
      "item-3"
      2
      CodexAbsent
      (JsonObject ())
      (codex:agent-job-item-status-completed)
      1
      CodexAbsent
      (JsonObject ((JsonPair "ok" (JsonBool True))))
      "2026-01-01T00:00:00Z"
      "2026-01-01T00:00:01Z"))
  (codex:agent-job-finalize-ok
    (codex:agent-job-finalize-plan CodexAbsent "thread-3")))
