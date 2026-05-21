!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:function_tool)
!(import! &self codex:context)
!(import! &self codex:agent_jobs)
!(import! &self codex:agent_jobs_result)

(= (test-agent-job-result-job $last-error)
   (codex:agent-job
     "job-1"
     "example"
     (codex:agent-job-status-failed)
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
     $last-error))

(= (test-agent-job-result-progress)
   (codex:agent-job-progress 3 0 0 1 2))

(= (test-agent-job-result-failed-item $item-id $source-id $last-error)
   (codex:agent-job-item
     "job-1"
     $item-id
     0
     $source-id
     (JsonObject ())
     (codex:agent-job-item-status-failed)
     1
     $last-error
     CodexAbsent
     CodexAbsent
     CodexAbsent))

!(assertEqual
  (codex:agent-job-result-failed-item-summary-limit)
  5)

!(assertEqual
  (codex:agent-job-result-failed-items-query "job-1")
  (CodexAgentJobResultFailedItemsQuery
    "job-1"
    (codex:agent-job-item-status-failed)
    5))

!(assertEqual
  (codex:agent-job-result-load-job-error "job-1" "db down")
  (codex:function-call-error-respond-to-model
    "failed to load agent job job-1: db down"))

!(assertEqual
  (codex:agent-job-result-job-not-found-error "job-1")
  (codex:function-call-error-respond-to-model
    "agent job job-1 not found"))

!(assertEqual
  (codex:agent-job-result-export-output-error "job-1" "disk full")
  (codex:function-call-error-respond-to-model
    "failed to export output csv job-1: disk full"))

!(assertEqual
  (codex:agent-job-result-load-progress-error "job-1" "db down")
  (codex:function-call-error-respond-to-model
    "failed to load agent job progress job-1: db down"))

!(assertEqual
  (codex:agent-job-result-serialize-error "bad value")
  (codex:function-call-error-fatal
    "failed to serialize spawn_agents_on_csv result: bad value"))

!(assertEqual
  (codex:agent-job-result-export-plan
    True
    (test-agent-job-result-job CodexAbsent))
  CodexAbsent)

!(assertEqual
  (codex:agent-job-result-export-plan
    False
    (test-agent-job-result-job CodexAbsent))
  (codex:agent-job-result-export-snapshot
    (test-agent-job-result-job CodexAbsent)))

!(assertEqual
  (codex:agent-job-result-option-nonempty-text "  ")
  CodexAbsent)

!(assertEqual
  (codex:agent-job-result-option-nonempty-text "job failed")
  "job failed")

!(assertEqual
  (codex:agent-job-result-failure-summaries
    ((codex:agent-job-item
       "job-1"
       "item-1"
       0
       "src-1"
       (JsonObject ())
       (codex:agent-job-item-status-failed)
       1
       "worker failed"
       CodexAbsent
       CodexAbsent
       CodexAbsent)
     (codex:agent-job-item
       "job-1"
       "item-2"
       1
       CodexAbsent
       (JsonObject ())
       (codex:agent-job-item-status-failed)
       1
       "  "
       CodexAbsent
       CodexAbsent
       CodexAbsent)
     (codex:agent-job-item
       "job-1"
       "item-3"
       2
       CodexAbsent
       (JsonObject ())
       (codex:agent-job-item-status-failed)
       1
       CodexAbsent
       CodexAbsent
       CodexAbsent
       CodexAbsent)))
  ((codex:agent-job-failure-summary "item-1" "src-1" "worker failed")))

!(assertEqual
  (codex:agent-job-result-failed-item-errors
    6
    ((test-agent-job-result-failed-item "item-1" CodexAbsent "err-1")
     (test-agent-job-result-failed-item "item-2" CodexAbsent "err-2")
     (test-agent-job-result-failed-item "item-3" CodexAbsent "err-3")
     (test-agent-job-result-failed-item "item-4" CodexAbsent "err-4")
     (test-agent-job-result-failed-item "item-5" CodexAbsent "err-5")
     (test-agent-job-result-failed-item "item-6" CodexAbsent "err-6")))
  ((codex:agent-job-failure-summary "item-1" CodexAbsent "err-1")
   (codex:agent-job-failure-summary "item-2" CodexAbsent "err-2")
   (codex:agent-job-failure-summary "item-3" CodexAbsent "err-3")
   (codex:agent-job-failure-summary "item-4" CodexAbsent "err-4")
   (codex:agent-job-failure-summary "item-5" CodexAbsent "err-5")))

!(assertEqual
  (codex:agent-job-result-summary
    (test-agent-job-result-job "job failed")
    (test-agent-job-result-progress)
    ((codex:agent-job-item
       "job-1"
       "item-1"
       0
       CodexAbsent
       (JsonObject ())
       (codex:agent-job-item-status-failed)
       1
       "worker failed"
       CodexAbsent
       CodexAbsent
       CodexAbsent)))
  (codex:spawn-agents-on-csv-result
    "job-1"
    "failed"
    "/tmp/output.csv"
    3
    1
    2
    "job failed"
    ((codex:agent-job-failure-summary
       "item-1"
       CodexAbsent
       "worker failed"))))

!(assertEqual
  (codex:agent-job-result-summary
    (test-agent-job-result-job CodexAbsent)
    (test-agent-job-result-progress)
    ((codex:agent-job-item
       "job-1"
       "item-1"
       0
       CodexAbsent
       (JsonObject ())
       (codex:agent-job-item-status-failed)
       1
       " "
       CodexAbsent
       CodexAbsent
       CodexAbsent)))
  (codex:spawn-agents-on-csv-result
    "job-1"
    "failed"
    "/tmp/output.csv"
    3
    1
    2
    "agent job has failed items but no error details were recorded"
    CodexAbsent))

!(assertEqualToResult
  (codex:spawn-agents-on-csv-result-output-json
    (codex:agent-job-result-summary
      (test-agent-job-result-job CodexAbsent)
      (codex:agent-job-progress 1 0 0 1 0)
      ()))
  ("{\"job_id\":\"job-1\",\"status\":\"failed\",\"output_csv_path\":\"/tmp/output.csv\",\"total_items\":1,\"completed_items\":1,\"failed_items\":0,\"job_error\":null,\"failed_item_errors\":null}"))

!(assertEqual
  (codex:spawn-agents-on-csv-result-tool-output
    (codex:agent-job-result-summary
      (test-agent-job-result-job CodexAbsent)
      (codex:agent-job-progress 1 0 0 1 0)
      ()))
  (codex:function-tool-output-from-text
    "{\"job_id\":\"job-1\",\"status\":\"failed\",\"output_csv_path\":\"/tmp/output.csv\",\"total_items\":1,\"completed_items\":1,\"failed_items\":0,\"job_error\":null,\"failed_item_errors\":null}"
    True))
