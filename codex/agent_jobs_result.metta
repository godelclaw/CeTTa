; Rust-faithful pure spawn_agents_on_csv final-result slice.
;
; This ports deterministic branch behavior from:
; - openai-codex/codex-rs/core/src/tools/handlers/agent_jobs.rs
;
; Covered in this increment:
; - post-run job/progress/export error message mapping
; - output CSV missing -> export snapshot action
; - job.last_error non-empty filtering
; - failed-item summary limit/filtering and fallback job_error message
; - final SpawnAgentsOnCsvResult and FunctionToolOutput text payload
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust loads the job/progress from StateRuntime, checks output-path existence,
;   optionally exports CSV, and serializes with `serde_json::to_string` inline.
;   This pure slice receives those boundary facts and emits the exact decisions
;   and JSON/tool-output payload; the runtime bridge must perform the DB/filesystem
;   operations before calling these helpers.

!(import! &self context)
!(import! &self function_tool)
!(import! &self json)
!(import! &self str)
!(import! &self agent_jobs)

(= (codex:agent-job-result-failed-item-summary-limit)
   5)

(= (codex:agent-job-result-failed-items-query $job-id)
   (CodexAgentJobResultFailedItemsQuery
     $job-id
     (codex:agent-job-item-status-failed)
     (codex:agent-job-result-failed-item-summary-limit)))

(= (codex:agent-job-result-job-status
      (CodexAgentJob
        $id
        $name
        $status
        $instruction
        $auto-export
        $max-runtime-seconds
        $output-schema-json
        $input-headers
        $input-csv-path
        $output-csv-path
        $created-at
        $updated-at
        $started-at
        $completed-at
        $last-error))
   $status)

(= (codex:agent-job-result-job-output-csv-path
      (CodexAgentJob
        $id
        $name
        $status
        $instruction
        $auto-export
        $max-runtime-seconds
        $output-schema-json
        $input-headers
        $input-csv-path
        $output-csv-path
        $created-at
        $updated-at
        $started-at
        $completed-at
        $last-error))
   $output-csv-path)

(= (codex:agent-job-result-job-last-error
      (CodexAgentJob
        $id
        $name
        $status
        $instruction
        $auto-export
        $max-runtime-seconds
        $output-schema-json
        $input-headers
        $input-csv-path
        $output-csv-path
        $created-at
        $updated-at
        $started-at
        $completed-at
        $last-error))
   $last-error)

(= (codex:agent-job-result-load-job-error $job-id $error-display)
   (codex:function-call-error-respond-to-model
     (format-args
       "failed to load agent job {}: {}"
       ($job-id $error-display))))

(= (codex:agent-job-result-job-not-found-error $job-id)
   (codex:function-call-error-respond-to-model
     (format-args "agent job {} not found" ($job-id))))

(= (codex:agent-job-result-export-output-error $job-id $error-display)
   (codex:function-call-error-respond-to-model
     (format-args
       "failed to export output csv {}: {}"
       ($job-id $error-display))))

(= (codex:agent-job-result-load-progress-error $job-id $error-display)
   (codex:function-call-error-respond-to-model
     (format-args
       "failed to load agent job progress {}: {}"
       ($job-id $error-display))))

(= (codex:agent-job-result-serialize-error $error-display)
   (codex:function-call-error-fatal
     (format-args
       "failed to serialize spawn_agents_on_csv result: {}"
       ($error-display))))

(= (codex:agent-job-result-export-snapshot $job)
   (CodexAgentJobResultExportSnapshot $job))

(= (codex:agent-job-result-export-plan $output-exists $job)
   (if $output-exists
       CodexAbsent
       (codex:agent-job-result-export-snapshot $job)))

(= (codex:agent-job-result-option-nonempty-text $text)
   (case $text
     ((CodexAbsent CodexAbsent)
      ($value
       (if (== (str-trim $value) "")
           CodexAbsent
           $value)))))

(= (codex:agent-job-result-item-last-error-text $item)
   (let $last-error (codex:agent-job-item-last-error $item)
     (if (== $last-error CodexAbsent) "" $last-error)))

(= (codex:agent-job-result-failure-summaries ())
   ())

(= (codex:agent-job-result-failure-summaries $items)
   (let ($item $tail) (decons-atom $items)
     (let $last-error
       (codex:agent-job-result-item-last-error-text $item)
       (case (codex:agent-job-result-failure-summaries $tail)
         ((()
           (if (== (str-trim $last-error) "")
               ()
               (let $item-id (codex:agent-job-item-id $item)
                 (let $source-id (codex:agent-job-item-source-id $item)
                   ((CodexAgentJobFailureSummary
                      $item-id
                      $source-id
                      $last-error))))))
          ($tail-summaries
           (if (== (str-trim $last-error) "")
               $tail-summaries
               (let $item-id (codex:agent-job-item-id $item)
                 (let $source-id (codex:agent-job-item-source-id $item)
                   (cons-atom
                     (CodexAgentJobFailureSummary
                       $item-id
                       $source-id
                       $last-error)
                     $tail-summaries))))))))))

(= (codex:agent-job-result-missing-failed-detail-error)
   "agent job has failed items but no error details were recorded")

(= (codex:agent-job-result-failed-item-errors $failed-items $items)
   (if (> $failed-items 0)
       (let $summary-items
         (codex:take-first-items
           $items
           (codex:agent-job-result-failed-item-summary-limit))
         (case (codex:agent-job-result-failure-summaries $summary-items)
           ((()
             CodexAbsent)
            ($summaries $summaries))))
       CodexAbsent))

(= (codex:agent-job-result-effective-job-error
      $job-error
      $failed-items
      $failed-item-errors)
   (if (and
         (> $failed-items 0)
         (and (== $failed-item-errors CodexAbsent)
              (== $job-error CodexAbsent)))
       (codex:agent-job-result-missing-failed-detail-error)
       $job-error))

(= (codex:agent-job-result-summary
      $job
      $progress
      $failed-items)
   (let $materialized-job (once (eval $job))
     (let $materialized-progress (once (eval $progress))
       (let $failed-count
         (codex:agent-job-progress-failed-items $materialized-progress)
         (let $failed-item-errors
           (codex:agent-job-result-failed-item-errors
             $failed-count
             $failed-items)
           (let $job-error
             (codex:agent-job-result-option-nonempty-text
               (codex:agent-job-result-job-last-error $materialized-job))
             (codex:spawn-agents-on-csv-result
               (codex:agent-job-id $materialized-job)
               (codex:agent-job-status-as-str
                 (codex:agent-job-result-job-status $materialized-job))
               (codex:agent-job-result-job-output-csv-path $materialized-job)
               (codex:agent-job-progress-total-items $materialized-progress)
               (codex:agent-job-progress-completed-items
                 $materialized-progress)
               $failed-count
               (codex:agent-job-result-effective-job-error
                 $job-error
                 $failed-count
                 $failed-item-errors)
               $failed-item-errors)))))))

(= (codex:spawn-agents-on-csv-result-output-json $result)
   (json-stringify
     (codex:spawn-agents-on-csv-result-json $result)))

(= (codex:spawn-agents-on-csv-result-tool-output $result)
   (codex:function-tool-output-from-text
     (codex:spawn-agents-on-csv-result-output-json $result)
     True))
