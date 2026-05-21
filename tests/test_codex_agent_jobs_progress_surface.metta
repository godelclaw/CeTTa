!(register-module! ../codex)
!(import! &self codex:agent_jobs)

!(assertEqual
  (codex:agent-job-progress-emitter-new 5000)
  (codex:agent-job-progress-emitter 5000 4000 0 0))

!(assertEqual
  (codex:agent-job-progress-emitter-new 500)
  (codex:agent-job-progress-emitter 500 500 0 0))

!(assertEqual
  (codex:agent-job-progress-emitter-maybe-emit
    (codex:agent-job-progress-emitter-new 5000)
    "job-1"
    (codex:agent-job-progress 10 9 0 1 0)
    6000
    False)
  (codex:agent-job-progress-emitter-result
    (codex:agent-job-progress-emitter 5000 6000 1 0)
    "agent_job_progress:{\"job_id\":\"job-1\",\"total_items\":10,\"pending_items\":9,\"running_items\":0,\"completed_items\":1,\"failed_items\":0,\"eta_seconds\":9}"))

!(assertEqual
  (codex:agent-job-progress-emitter-maybe-emit
    (codex:agent-job-progress-emitter 5000 6000 1 0)
    "job-1"
    (codex:agent-job-progress 10 9 0 1 0)
    6500
    False)
  (codex:agent-job-progress-emitter-result
    (codex:agent-job-progress-emitter 5000 6000 1 0)
    CodexAbsent))

!(assertEqual
  (codex:agent-job-progress-emitter-maybe-emit
    (codex:agent-job-progress-emitter 5000 6000 1 0)
    "job-1"
    (codex:agent-job-progress 10 9 0 1 0)
    7000
    False)
  (codex:agent-job-progress-emitter-result
    (codex:agent-job-progress-emitter 5000 7000 1 0)
    "agent_job_progress:{\"job_id\":\"job-1\",\"total_items\":10,\"pending_items\":9,\"running_items\":0,\"completed_items\":1,\"failed_items\":0,\"eta_seconds\":18}"))

!(assertEqual
  (codex:agent-job-progress-emitter-maybe-emit
    (codex:agent-job-progress-emitter 5000 6500 1 0)
    "job-1"
    (codex:agent-job-progress 10 8 0 1 1)
    6600
    False)
  (codex:agent-job-progress-emitter-result
    (codex:agent-job-progress-emitter 5000 6600 2 1)
    "agent_job_progress:{\"job_id\":\"job-1\",\"total_items\":10,\"pending_items\":8,\"running_items\":0,\"completed_items\":1,\"failed_items\":1,\"eta_seconds\":6}"))

!(assertEqual
  (codex:agent-job-progress-emitter-maybe-emit
    (codex:agent-job-progress-emitter 5000 6500 0 0)
    "job-1"
    (codex:agent-job-progress 10 10 0 0 0)
    6600
    True)
  (codex:agent-job-progress-emitter-result
    (codex:agent-job-progress-emitter 5000 6600 0 0)
    "agent_job_progress:{\"job_id\":\"job-1\",\"total_items\":10,\"pending_items\":10,\"running_items\":0,\"completed_items\":0,\"failed_items\":0,\"eta_seconds\":null}"))

!(assertEqual
  (codex:agent-job-normalize-whole-number 18446744073709551616)
  "18446744073709551615")
