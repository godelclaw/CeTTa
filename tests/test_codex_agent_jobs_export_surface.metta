!(register-module! ../codex)
!(import! &self codex:agent_jobs_export)

!(assertEqual
  (codex:agent-job-export-render-error-message
    (CodexFunctionCallErrorRespondToModel "bad render"))
  "failed to render job csv for auto-export: bad render")

!(assertEqual
  (codex:agent-job-export-output-parent "/tmp/out/result.csv")
  "/tmp/out")

!(assertEqual
  (codex:agent-job-export-output-parent "/")
  CodexAbsent)

!(assertEqual
  (codex:agent-job-export-start-plan
    (CodexAgentJob
      "job-1"
      "example"
      (CodexAgentJobStatusRunning)
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
      CodexAbsent))
  (codex:agent-job-export-ok
    ((codex:agent-job-export-list-items "job-1"))))
