!(register-module! ../codex)
!(import! &self codex:agent_jobs)
!(import! &self codex:function_tool)

!(assertEqual
  (codex:prepare-report-agent-job-result
    "{\"job_id\":\"job-1\",\"item_id\":\"item-1\",\"result\":{\"answer\":42},\"stop\":true}"
    "thread-9")
  (codex:agent-job-ok
    (codex:prepared-report-agent-job-result
      (codex:report-agent-job-result-record-params
        "job-1"
        "item-1"
        "thread-9"
        (JsonObject ((JsonPair "answer" (JsonNumber "42")))))
      True)))

!(assertEqual
  (codex:prepare-report-agent-job-result
    "{\"job_id\":\"job-1\",\"item_id\":\"item-1\",\"result\":{\"answer\":42}}"
    "thread-9")
  (codex:agent-job-ok
    (codex:prepared-report-agent-job-result
      (codex:report-agent-job-result-record-params
        "job-1"
        "item-1"
        "thread-9"
        (JsonObject ((JsonPair "answer" (JsonNumber "42")))))
      CodexAbsent)))

!(assertEqual
  (codex:prepare-report-agent-job-result "{}" "thread-9")
  (codex:agent-job-err
    (codex:function-call-error-respond-to-model
      "failed to parse function arguments: missing field `job_id`")))

!(assertEqual
  (codex:prepare-report-agent-job-result
    "{\"job_id\":\"job-1\",\"item_id\":\"item-1\",\"result\":\"bad\"}"
    "thread-9")
  (codex:agent-job-err
    (codex:function-call-error-respond-to-model
      "result must be a JSON object")))

!(assertEqual
  (codex:report-agent-job-result-stop-requested CodexAbsent)
  False)

!(assertEqual
  (codex:report-agent-job-result-should-cancel True True)
  True)

!(assertEqual
  (codex:report-agent-job-result-should-cancel False True)
  False)

!(assertEqual
  (codex:report-agent-job-result-record-error "job-1" "item-1" "db down")
  (codex:function-call-error-respond-to-model
    "failed to record agent job result for job-1 / item-1: db down"))

!(assertEqual
  (codex:finish-report-agent-job-result True True)
  (codex:completed-report-agent-job-result
    (CodexToolOutputFunction
      ((CodexInputText "{\"accepted\":true}"))
      True
      CodexAbsent)
    "cancelled by worker request"))

!(assertEqual
  (codex:finish-report-agent-job-result False True)
  (codex:completed-report-agent-job-result
    (CodexToolOutputFunction
      ((CodexInputText "{\"accepted\":false}"))
      True
      CodexAbsent)
    CodexAbsent))

!(assertEqual
  (codex:finish-report-agent-job-result True CodexAbsent)
  (codex:completed-report-agent-job-result
    (CodexToolOutputFunction
      ((CodexInputText "{\"accepted\":true}"))
      True
      CodexAbsent)
    CodexAbsent))
