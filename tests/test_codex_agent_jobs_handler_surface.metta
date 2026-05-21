!(register-module! ../codex)
!(import! &self codex:agent_jobs_handler)
!(import! &self codex:context)
!(import! &self codex:function_tool)
!(import! &self codex:tool_name)

!(assertEqual
  (codex:batch-job-handler-kind)
  "function")

!(assertEqual
  (codex:batch-job-handler-matches-kind (codex:function-payload "{}"))
  True)

!(assertEqual
  (codex:batch-job-handler-matches-kind (codex:tool-search-payload "agent"))
  False)

!(assertEqual
  (codex:batch-job-handler-function-arguments (codex:custom-payload "raw"))
  (codex:batch-job-handler-err
    (codex:function-call-error-respond-to-model
      "agent jobs handler received unsupported payload")))

!(assertEqual
  (codex:run-batch-job-handler
    (codex:plain-tool-name "spawn_agents_on_csv")
    (codex:function-payload "{\"csv_path\":\"input.csv\"}"))
  (codex:batch-job-handler-ok
    (codex:batch-job-dispatch-spawn-agents-on-csv
      "{\"csv_path\":\"input.csv\"}")))

!(assertEqual
  (codex:run-batch-job-handler
    (codex:namespaced-tool-name "ns:" "report_agent_job_result")
    (codex:function-payload "{\"job_id\":\"job-1\"}"))
  (codex:batch-job-handler-ok
    (codex:batch-job-dispatch-report-agent-job-result
      "{\"job_id\":\"job-1\"}")))

!(assertEqual
  (codex:run-batch-job-handler
    (codex:plain-tool-name "missing_agent_job_tool")
    (codex:function-payload "{}"))
  (codex:batch-job-handler-err
    (codex:function-call-error-respond-to-model
      "unsupported agent job tool missing_agent_job_tool")))
