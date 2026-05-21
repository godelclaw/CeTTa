!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:agent_jobs)
!(import! &self codex:agent_jobs_handle)
!(import! &self codex:agent_jobs_runner_options)
!(import! &self codex:function_tool)

(= (test-agent-job-handle-create-params)
   (codex:agent-job-create-params
     "job-abcdef123456"
     "agent-job-abcdef12"
     "Review {name}"
     True
     CodexAbsent
     CodexAbsent
     ("name")
     "/tmp/input.csv"
     "/tmp/input.agent-job-abcdef12.output.csv"))

(= (test-agent-job-handle-items)
   ((codex:agent-job-item-create-params
      "row-1"
      0
      CodexAbsent
      (JsonObject ((JsonPair "name" (JsonString "Ada")))))))

(= (test-agent-job-handle-prepared $requested-concurrency)
   (codex:prepared-spawn-agents-on-csv
     (test-agent-job-handle-create-params)
     (test-agent-job-handle-items)
     $requested-concurrency))

(= (test-agent-job-handle-create-action)
   (codex:spawn-agents-on-csv-handle-create-agent-job
     (test-agent-job-handle-create-params)
     (test-agent-job-handle-items)))

(= (test-agent-job-handle-options)
   (codex:agent-job-runner-options 8 spawn-config-1))

!(assertEqual
  (codex:spawn-agents-on-csv-handle-read-csv-error
    "/tmp/input.csv"
    "permission denied")
  (codex:function-call-error-respond-to-model
    "failed to read csv input /tmp/input.csv: permission denied"))

!(assertEqual
  (codex:spawn-agents-on-csv-handle-concurrency-message
    "job-1"
    CodexAbsent
    CodexAbsent
    16)
  "agent job concurrency: job_id=job-1 requested=None max_threads=None effective=16")

!(assertEqual
  (codex:spawn-agents-on-csv-handle-concurrency-message
    "job-1"
    4
    12
    8)
  "agent job concurrency: job_id=job-1 requested=Some(4) max_threads=Some(12) effective=8")

!(assertEqual
  (codex:spawn-agents-on-csv-handle-plan
    (test-agent-job-handle-prepared 4)
    (codex:agent-job-err "db locked")
    (codex:agent-job-ok (test-agent-job-handle-options))
    (codex:agent-job-ok ())
    (codex:agent-job-ok ())
    12)
  (codex:spawn-agents-on-csv-handle-err
    ((test-agent-job-handle-create-action))
    (codex:function-call-error-respond-to-model
      "failed to create agent job: db locked")))

!(assertEqual
  (codex:spawn-agents-on-csv-handle-plan
    (test-agent-job-handle-prepared 4)
    (codex:agent-job-ok created-job)
    (CodexAgentJobErr
      (codex:function-call-error-respond-to-model
        "agent depth limit reached; this session cannot spawn more subagents"))
    (codex:agent-job-ok ())
    (codex:agent-job-ok ())
    12)
  (codex:spawn-agents-on-csv-handle-err
    ((test-agent-job-handle-create-action)
     (codex:spawn-agents-on-csv-handle-build-runner-options 4)
     (codex:spawn-agents-on-csv-handle-mark-job-failed
       "job-abcdef123456"
       "agent depth limit reached; this session cannot spawn more subagents"))
    (codex:function-call-error-respond-to-model
      "agent depth limit reached; this session cannot spawn more subagents")))

!(assertEqual
  (codex:spawn-agents-on-csv-handle-plan
    (test-agent-job-handle-prepared 4)
    (codex:agent-job-ok created-job)
    (CodexAgentJobErr
      (codex:function-call-error-fatal "spawn config crashed"))
    (codex:agent-job-ok ())
    (codex:agent-job-ok ())
    12)
  (codex:spawn-agents-on-csv-handle-err
    ((test-agent-job-handle-create-action)
     (codex:spawn-agents-on-csv-handle-build-runner-options 4)
     (codex:spawn-agents-on-csv-handle-mark-job-failed
       "job-abcdef123456"
       "Fatal error: spawn config crashed"))
    (codex:function-call-error-fatal "spawn config crashed")))

!(assertEqual
  (codex:spawn-agents-on-csv-handle-plan
    (test-agent-job-handle-prepared 4)
    (codex:agent-job-ok created-job)
    (CodexAgentJobOk (CodexAgentJobRunnerOptions 8 spawn-config-1))
    (CodexAgentJobErr "db down")
    (codex:agent-job-ok ())
    12)
  (codex:spawn-agents-on-csv-handle-err
    ((test-agent-job-handle-create-action)
     (codex:spawn-agents-on-csv-handle-build-runner-options 4)
     (codex:spawn-agents-on-csv-handle-mark-job-running
       "job-abcdef123456"))
    (codex:function-call-error-respond-to-model
      "failed to transition agent job job-abcdef123456 to running: db down")))

!(assertEqual
  (codex:spawn-agents-on-csv-handle-plan
    (test-agent-job-handle-prepared 4)
    (codex:agent-job-ok created-job)
    (CodexAgentJobOk (CodexAgentJobRunnerOptions 8 spawn-config-1))
    (CodexAgentJobOk ())
    (CodexAgentJobErr "loop down")
    12)
  (codex:spawn-agents-on-csv-handle-err
    ((test-agent-job-handle-create-action)
     (codex:spawn-agents-on-csv-handle-build-runner-options 4)
     (codex:spawn-agents-on-csv-handle-mark-job-running
       "job-abcdef123456")
     (codex:spawn-agents-on-csv-handle-notify-background-event
       "agent job concurrency: job_id=job-abcdef123456 requested=Some(4) max_threads=Some(12) effective=8")
     (codex:spawn-agents-on-csv-handle-run-agent-job-loop
       "job-abcdef123456"
       (test-agent-job-handle-options))
     (codex:spawn-agents-on-csv-handle-mark-job-failed
       "job-abcdef123456"
       "job runner failed: loop down"))
    (codex:function-call-error-respond-to-model
      "agent job job-abcdef123456 failed: loop down")))

!(assertEqual
  (codex:spawn-agents-on-csv-handle-plan
    (test-agent-job-handle-prepared 4)
    (codex:agent-job-ok created-job)
    (CodexAgentJobOk (CodexAgentJobRunnerOptions 8 spawn-config-1))
    (CodexAgentJobOk ())
    (CodexAgentJobOk ())
    12)
  (codex:spawn-agents-on-csv-handle-ok
    ((test-agent-job-handle-create-action)
     (codex:spawn-agents-on-csv-handle-build-runner-options 4)
     (codex:spawn-agents-on-csv-handle-mark-job-running
       "job-abcdef123456")
     (codex:spawn-agents-on-csv-handle-notify-background-event
       "agent job concurrency: job_id=job-abcdef123456 requested=Some(4) max_threads=Some(12) effective=8")
     (codex:spawn-agents-on-csv-handle-run-agent-job-loop
       "job-abcdef123456"
       (test-agent-job-handle-options))
     (codex:spawn-agents-on-csv-handle-final-result
       "job-abcdef123456"))))
