!(register-module! ../codex)
!(import! &self codex:agent_jobs_export)

!(assertEqualToResult
  (codex:agent-job-export-after-list
    (codex:agent-job
      "job-1"
      "example"
      (codex:agent-job-status-running)
      "Review {path}"
      True
      CodexAbsent
      CodexAbsent
      ("name" "note")
      "/tmp/input.csv"
      "/tmp/out/result.csv"
      "2026-05-21T00:00:00+00:00"
      "2026-05-21T00:00:00+00:00"
      CodexAbsent
      CodexAbsent
      CodexAbsent)
    ((codex:agent-job-item
       "job-1"
       "item-1"
       0
       CodexAbsent
       (JsonObject
         ((JsonPair "name" (JsonString "Ada"))
          (JsonPair "note" (JsonString "says \"hi\", now"))))
       (codex:agent-job-item-status-completed)
       2
       CodexAbsent
       (JsonObject ((JsonPair "answer" (JsonNumber "42"))))
       "2026-05-21T10:00:00+00:00"
       CodexAbsent)))
  ((CodexAgentJobExportOk
     ((CodexAgentJobExportCreateDirAll "/tmp/out")
      (CodexAgentJobExportWriteFile
        "/tmp/out/result.csv"
        "name,note,job_id,item_id,row_index,source_id,status,attempt_count,last_error,result_json,reported_at,completed_at\nAda,\"says \"\"hi\"\", now\",job-1,item-1,0,,completed,2,,\"{\"\"answer\"\":42}\",2026-05-21T10:00:00+00:00,\n")))))

!(assertEqual
  (codex:agent-job-export-after-list
    (codex:agent-job
      "job-1"
      "example"
      (codex:agent-job-status-running)
      "Review {path}"
      True
      CodexAbsent
      CodexAbsent
      ("name" "note")
      "/tmp/input.csv"
      "/tmp/out/result.csv"
      "2026-05-21T00:00:00+00:00"
      "2026-05-21T00:00:00+00:00"
      CodexAbsent
      CodexAbsent
      CodexAbsent)
    ((codex:agent-job-item
       "job-1"
       "item-bad"
       1
       CodexAbsent
       (JsonString "not-object")
       (codex:agent-job-item-status-failed)
       1
       "bad row"
       CodexAbsent
       CodexAbsent
       CodexAbsent)))
  (codex:agent-job-export-err
    "failed to render job csv for auto-export: row_json for item item-bad is not a JSON object"))
