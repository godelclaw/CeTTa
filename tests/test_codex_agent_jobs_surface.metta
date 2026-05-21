!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:agent_jobs)
!(import! &self codex:function_tool)

!(assertEqual
  (codex:agent-job-default-concurrency)
  16)

!(assertEqual
  (codex:agent-job-max-concurrency)
  64)

!(assertEqual
  (codex:agent-job-status-poll-interval-ms)
  250)

!(assertEqual
  (codex:agent-job-progress-emit-interval-ms)
  1000)

!(assertEqual
  (codex:agent-job-default-item-timeout-seconds)
  1800)

!(assertEqual
  (codex:agent-job-status-as-str (codex:agent-job-status-running))
  "running")

!(assertEqual
  (codex:is-agent-job-status-final (codex:agent-job-status-pending))
  False)

!(assertEqual
  (codex:is-agent-job-status-final (codex:agent-job-status-completed))
  True)

!(assertEqual
  (codex:is-agent-job-status-final (codex:agent-job-status-failed))
  True)

!(assertEqual
  (codex:is-agent-job-status-final (codex:agent-job-status-cancelled))
  True)

!(assertEqual
  (codex:agent-job-item-status-as-str
    (codex:agent-job-item-status-completed))
  "completed")

!(assertEqual
  (codex:agent-job-status-parse "cancelled")
  (codex:agent-job-ok (codex:agent-job-status-cancelled)))

!(assertEqual
  (codex:agent-job-status-parse "paused")
  (codex:agent-job-err "invalid agent job status: paused"))

!(assertEqual
  (codex:agent-job-item-status-parse "running")
  (codex:agent-job-ok (codex:agent-job-item-status-running)))

!(assertEqual
  (codex:agent-job-item-status-parse "paused")
  (codex:agent-job-err "invalid agent job item status: paused"))

!(assertEqual
  (codex:agent-job-normalize-concurrency CodexAbsent CodexAbsent)
  16)

!(assertEqual
  (codex:agent-job-normalize-concurrency 0 CodexAbsent)
  1)

!(assertEqual
  (codex:agent-job-normalize-concurrency 128 CodexAbsent)
  64)

!(assertEqual
  (codex:agent-job-normalize-concurrency 20 12)
  12)

!(assertEqual
  (codex:agent-job-normalize-concurrency 20 0)
  1)

!(assertEqual
  (codex:agent-job-normalize-max-runtime-seconds CodexAbsent)
  (codex:agent-job-ok CodexAbsent))

!(assertEqual
  (codex:agent-job-normalize-max-runtime-seconds 0)
  (codex:agent-job-err
    (codex:function-call-error-respond-to-model
      "max_runtime_seconds must be >= 1")))

!(assertEqual
  (codex:agent-job-normalize-max-runtime-seconds 60)
  (codex:agent-job-ok 60))

!(assertEqual
  (codex:agent-job-render-instruction-template
    "Hello {name}; raw {{keep}}; score {score}; nested {payload}"
    (JsonObject
      ((JsonPair "name" (JsonString "Ada"))
       (JsonPair "score" (JsonNumber "7"))
       (JsonPair
         "payload"
         (JsonObject ((JsonPair "ok" (JsonBool True))))))))
  "Hello Ada; raw {keep}; score 7; nested {\"ok\":true}")

!(assertEqual
  (codex:agent-job-render-instruction-template
    "No object {{literal}} {missing}"
    (JsonArray ()))
  "No object {literal} {missing}")

!(assertEqual
  (codex:agent-job-json-pretty
    (JsonObject
      ((JsonPair "path" (JsonString "src/lib.rs"))
       (JsonPair
         "result"
         (JsonObject
           ((JsonPair "ok" (JsonBool True))
            (JsonPair
              "items"
              (JsonArray ((JsonNumber "1") (JsonString "two"))))))))))
  "{\n  \"path\": \"src/lib.rs\",\n  \"result\": {\n    \"ok\": true,\n    \"items\": [\n      1,\n      \"two\"\n    ]\n  }\n}")

!(assertEqual
  (codex:agent-job-build-worker-prompt
    (codex:agent-job
      "job-1"
      "example"
      (codex:agent-job-status-running)
      "Review {path}; literal {{braces}}."
      True
      CodexAbsent
      (JsonObject
        ((JsonPair "type" (JsonString "object"))
         (JsonPair
           "properties"
           (JsonObject
             ((JsonPair
                "summary"
                (JsonObject ((JsonPair "type" (JsonString "string"))))))))))
      ("path")
      "/tmp/input.csv"
      "/tmp/output.csv"
      "2026-05-21T00:00:00+00:00"
      "2026-05-21T00:00:00+00:00"
      CodexAbsent
      CodexAbsent
      CodexAbsent)
    (codex:agent-job-item
      "job-1"
      "item-1"
      0
      CodexAbsent
      (JsonObject
        ((JsonPair "path" (JsonString "src/lib.rs"))
         (JsonPair "priority" (JsonNumber "2"))))
      (codex:agent-job-item-status-running)
      1
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent))
  "You are processing one item for a generic agent job.\nJob ID: job-1\nItem ID: item-1\n\nTask instruction:\nReview src/lib.rs; literal {braces}.\n\nInput row (JSON):\n{\n  \"path\": \"src/lib.rs\",\n  \"priority\": 2\n}\n\nExpected result schema (JSON Schema or {}):\n{\n  \"type\": \"object\",\n  \"properties\": {\n    \"summary\": {\n      \"type\": \"string\"\n    }\n  }\n}\n\nYou MUST call the `report_agent_job_result` tool exactly once with:\n1. `job_id` = \"job-1\"\n2. `item_id` = \"item-1\"\n3. `result` = a JSON object that contains your analysis result for this row.\n\nIf you need to stop the job early, include `stop` = true in the tool call.\n\nAfter the tool call succeeds, stop.")

!(assertEqual
  (codex:agent-job-output-schema-pretty CodexAbsent)
  "{}")

!(assertEqual
  (codex:agent-job-runtime-timeout-seconds
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
  1800)

!(assertEqual
  (codex:agent-job-runtime-timeout-seconds
    (codex:agent-job
      "job-1"
      "example"
      (codex:agent-job-status-running)
      "Review {path}"
      True
      75
      CodexAbsent
      ("path")
      "/tmp/input.csv"
      "/tmp/output.csv"
      "2026-05-21T00:00:00+00:00"
      "2026-05-21T00:00:00+00:00"
      CodexAbsent
      CodexAbsent
      CodexAbsent))
  75)

!(assertEqual
  (codex:agent-job-file-stem-or-default "/tmp/report.csv")
  "report")

!(assertEqual
  (codex:agent-job-file-stem-or-default "/tmp/report.final.csv")
  "report.final")

!(assertEqual
  (codex:agent-job-file-stem-or-default "/tmp/.env")
  ".env")

!(assertEqual
  (codex:agent-job-file-stem-or-default "/tmp/.env.local")
  ".env")

!(assertEqual
  (codex:agent-job-file-stem-or-default "/")
  "agent_job_output")

!(assertEqual
  (codex:agent-job-default-output-csv-path
    "/tmp/report.csv"
    "123456789abcdef")
  "/tmp/report.agent-job-12345678.csv")

!(assertEqual
  (codex:agent-job-default-output-csv-path
    "/tmp/report.final.csv"
    "abcdef0123456789")
  "/tmp/report.final.agent-job-abcdef01.csv")

!(assertEqual
  (codex:agent-job-default-output-csv-path
    "/tmp/"
    "123456789abcdef")
  "/tmp.agent-job-12345678.csv")

!(assertEqual
  (codex:agent-job-default-output-csv-path
    "/"
    "123456789abcdef")
  "/agent_job_output.agent-job-12345678.csv")

!(assertEqual
  (codex:agent-job-ensure-unique-headers ("id" "name" "id"))
  (codex:agent-job-err
    (codex:function-call-error-respond-to-model
      "csv header id is duplicated")))

!(assertEqual
  (codex:agent-job-ensure-unique-headers ("id" "name"))
  (codex:agent-job-ok ()))

!(assertEqual
  (codex:agent-job-value-to-csv-string JsonNull)
  "")

!(assertEqual
  (codex:agent-job-value-to-csv-string (JsonBool False))
  "false")

!(assertEqual
  (codex:agent-job-value-to-csv-string
    (JsonArray ((JsonString "a") (JsonNumber "2"))))
  "[\"a\",2]")

!(assertEqual
  (codex:agent-job-csv-escape "plain")
  "plain")

!(assertEqual
  (codex:agent-job-csv-escape "a,b")
  "\"a,b\"")

!(assertEqual
  (codex:agent-job-csv-escape "say \"hi\"")
  "\"say \"\"hi\"\"\"")

!(assertEqual
  (codex:agent-job-render-job-csv
    ("name" "note")
    ((codex:agent-job-item
       "job-1"
       "item-1"
       0
       "src-1"
       (JsonObject
         ((JsonPair "name" (JsonString "Ada"))
          (JsonPair "note" (JsonString "says \"hi\", now"))))
       (codex:agent-job-item-status-completed)
       2
       CodexAbsent
       (JsonObject ((JsonPair "answer" (JsonNumber "42"))))
       "2026-05-21T10:00:00+00:00"
       CodexAbsent)))
  (codex:agent-job-ok
    "name,note,job_id,item_id,row_index,source_id,status,attempt_count,last_error,result_json,reported_at,completed_at\nAda,\"says \"\"hi\"\", now\",job-1,item-1,0,src-1,completed,2,,\"{\"\"answer\"\":42}\",2026-05-21T10:00:00+00:00,\n"))

!(assertEqual
  (codex:agent-job-render-job-csv
    ("name")
    ((codex:agent-job-item
       "job-1"
       "item-1"
       0
       CodexAbsent
       (JsonString "not-object")
       (codex:agent-job-item-status-failed)
       1
       "bad row"
       CodexAbsent
       CodexAbsent
       CodexAbsent)))
  (codex:agent-job-err
    (codex:function-call-error-respond-to-model
      "row_json for item item-1 is not a JSON object")))

!(assertEqualToResult
  (json-stringify
    (codex:spawn-agents-on-csv-result-json
      (codex:spawn-agents-on-csv-result
        "job-1"
        "failed"
        "/tmp/out.csv"
        3
        1
        2
        "job failed"
        ((codex:agent-job-failure-summary
           "item-2"
           CodexAbsent
           "worker failed")))))
  ("{\"job_id\":\"job-1\",\"status\":\"failed\",\"output_csv_path\":\"/tmp/out.csv\",\"total_items\":3,\"completed_items\":1,\"failed_items\":2,\"job_error\":\"job failed\",\"failed_item_errors\":[{\"item_id\":\"item-2\",\"source_id\":null,\"last_error\":\"worker failed\"}]}"))

!(assertEqualToResult
  (json-stringify
    (codex:agent-job-progress-update-json
      (codex:agent-job-progress-update "job-1" 10 5 2 2 1 CodexAbsent)))
  ("{\"job_id\":\"job-1\",\"total_items\":10,\"pending_items\":5,\"running_items\":2,\"completed_items\":2,\"failed_items\":1,\"eta_seconds\":null}"))

!(assertEqualToResult
  (json-stringify
    (codex:report-agent-job-result-tool-result-json
      (codex:report-agent-job-result-tool-result True)))
  ("{\"accepted\":true}"))
