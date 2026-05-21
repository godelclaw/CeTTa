; Rust-faithful pure agent jobs helper slice.
;
; This ports deterministic helper behavior from:
; - openai-codex/codex-rs/core/src/tools/handlers/agent_jobs.rs
; - openai-codex/codex-rs/state/src/model/agent_job.rs
;
; Covered in this increment:
; - agent job constants
; - AgentJobStatus / AgentJobItemStatus text and finality helpers
; - normalize_concurrency
; - normalize_max_runtime_seconds
; - render_instruction_template
; - ensure_unique_headers
; - AgentJob result/progress JSON projections
; - value_to_csv_string / csv_escape / render_job_csv
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust's CSV input parser uses the `csv` crate. This slice does not re-port
;   that parser yet; it ports the deterministic CSV renderer used for output
;   snapshots.
; - Rust `render_job_csv` receives full `codex_state::AgentJobItem` structs with
;   timestamps. This CeTTa projection carries only fields read by the renderer;
;   optional timestamp fields are expected to already be RFC3339 text when
;   present.

!(import! &self function_tool)
!(import! &self json)
!(import! &self list)
!(import! &self str)

(= (codex:agent-job-ok $value)
   (CodexAgentJobOk $value))

(= (codex:agent-job-err $error)
   (CodexAgentJobErr $error))

(= (codex:agent-job-default-concurrency)
   16)

(= (codex:agent-job-max-concurrency)
   64)

(= (codex:agent-job-status-poll-interval-ms)
   250)

(= (codex:agent-job-progress-emit-interval-ms)
   1000)

(= (codex:agent-job-default-item-timeout-seconds)
   1800)

(= (codex:agent-job-status-pending)
   (CodexAgentJobStatusPending))

(= (codex:agent-job-status-running)
   (CodexAgentJobStatusRunning))

(= (codex:agent-job-status-completed)
   (CodexAgentJobStatusCompleted))

(= (codex:agent-job-status-failed)
   (CodexAgentJobStatusFailed))

(= (codex:agent-job-status-cancelled)
   (CodexAgentJobStatusCancelled))

(= (codex:agent-job-status-as-str (CodexAgentJobStatusPending))
   "pending")

(= (codex:agent-job-status-as-str (CodexAgentJobStatusRunning))
   "running")

(= (codex:agent-job-status-as-str (CodexAgentJobStatusCompleted))
   "completed")

(= (codex:agent-job-status-as-str (CodexAgentJobStatusFailed))
   "failed")

(= (codex:agent-job-status-as-str (CodexAgentJobStatusCancelled))
   "cancelled")

(= (codex:is-agent-job-status-final $status)
   (case (once (eval $status))
     (((CodexAgentJobStatusCompleted) True)
      ((CodexAgentJobStatusFailed) True)
      ((CodexAgentJobStatusCancelled) True)
      ($other False))))

(= (codex:agent-job-item-status-pending)
   (CodexAgentJobItemStatusPending))

(= (codex:agent-job-item-status-running)
   (CodexAgentJobItemStatusRunning))

(= (codex:agent-job-item-status-completed)
   (CodexAgentJobItemStatusCompleted))

(= (codex:agent-job-item-status-failed)
   (CodexAgentJobItemStatusFailed))

(= (codex:agent-job-item-status-as-str (CodexAgentJobItemStatusPending))
   "pending")

(= (codex:agent-job-item-status-as-str (CodexAgentJobItemStatusRunning))
   "running")

(= (codex:agent-job-item-status-as-str (CodexAgentJobItemStatusCompleted))
   "completed")

(= (codex:agent-job-item-status-as-str (CodexAgentJobItemStatusFailed))
   "failed")

(= (codex:agent-job-normalize-concurrency $requested $max-threads)
   (let $requested-value
     (case $requested
       ((CodexAbsent (codex:agent-job-default-concurrency))
        ($value $value)))
     (let $at-least-one
       (if (< $requested-value 1) 1 $requested-value)
       (let $capped
         (if (> $at-least-one (codex:agent-job-max-concurrency))
             (codex:agent-job-max-concurrency)
             $at-least-one)
         (case $max-threads
           ((CodexAbsent $capped)
            ($limit
             (let $limit-at-least-one
               (if (< $limit 1) 1 $limit)
               (if (< $capped $limit-at-least-one)
                   $capped
                   $limit-at-least-one)))))))))

(= (codex:agent-job-normalize-max-runtime-seconds $requested)
   (if (== $requested CodexAbsent)
       (codex:agent-job-ok CodexAbsent)
       (if (== $requested 0)
           (codex:agent-job-err
             (codex:function-call-error-respond-to-model
               "max_runtime_seconds must be >= 1"))
           (codex:agent-job-ok $requested))))

(= (codex:agent-job-str-replace-all $text $needle $replacement)
   (str-join $replacement (str-split $needle $text)))

(= (codex:agent-job-render-template-value $value)
   (case (once (eval $value))
     (((JsonString $text) $text)
      ($other (json-stringify $other)))))

(= (codex:agent-job-render-instruction-template-pairs $rendered $pairs)
   (if (== $pairs ())
       $rendered
       (let ($head $tail) (decons-atom $pairs)
         (case $head
           (((JsonPair $key $value)
             (codex:agent-job-render-instruction-template-pairs
               (codex:agent-job-str-replace-all
                 $rendered
                 (str-concat "{" (str-concat $key "}"))
                 (codex:agent-job-render-template-value $value))
               $tail)))))))

(= (codex:agent-job-render-instruction-template $instruction $row-json)
   (let $open-brace-sentinel "__CODEX_OPEN_BRACE__"
     (let $close-brace-sentinel "__CODEX_CLOSE_BRACE__"
       (let $escaped-open
         (codex:agent-job-str-replace-all
           $instruction
           "{{"
           $open-brace-sentinel)
         (let $escaped
           (codex:agent-job-str-replace-all
             $escaped-open
             "}}"
             $close-brace-sentinel)
           (let $substituted
             (case (once (eval $row-json))
               (((JsonObject $pairs)
                 (codex:agent-job-render-instruction-template-pairs
                   $escaped
                   $pairs))
                ($other $escaped)))
             (codex:agent-job-str-replace-all
               (codex:agent-job-str-replace-all
                 $substituted
                 $open-brace-sentinel
                 "{")
               $close-brace-sentinel
               "}")))))))

(= (codex:agent-job-list-contains $items $item)
   (if (== $items ())
       False
       (let ($head $tail) (decons-atom $items)
         (if (== $head $item)
             True
             (codex:agent-job-list-contains $tail $item)))))

(= (codex:agent-job-ensure-unique-headers-from $headers $seen)
   (if (== $headers ())
       (codex:agent-job-ok ())
       (let ($head $tail) (decons-atom $headers)
         (if (codex:agent-job-list-contains $seen $head)
             (codex:agent-job-err
               (codex:function-call-error-respond-to-model
                 (format-args "csv header {} is duplicated" ($head))))
             (codex:agent-job-ensure-unique-headers-from
               $tail
               (cons-atom $head $seen))))))

(= (codex:agent-job-ensure-unique-headers $headers)
   (codex:agent-job-ensure-unique-headers-from $headers ()))

(= (codex:agent-job-json-number $value)
   (JsonNumber (format-args "{}" ($value))))

(= (codex:agent-job-json-option-string $value)
   (if (== $value CodexAbsent)
       JsonNull
       (JsonString $value)))

(= (codex:agent-job-json-option-value $value)
   (if (== $value CodexAbsent)
       JsonNull
       $value))

(= (codex:agent-job-failure-summary $item-id $source-id $last-error)
   (CodexAgentJobFailureSummary $item-id $source-id $last-error))

(= (codex:agent-job-failure-summary-json
      (CodexAgentJobFailureSummary $item-id $source-id $last-error))
   (JsonObject
     ((JsonPair "item_id" (JsonString $item-id))
      (JsonPair "source_id" (codex:agent-job-json-option-string $source-id))
      (JsonPair "last_error" (JsonString $last-error)))))

(= (codex:agent-job-failure-summaries-json $summaries)
   (JsonArray
     (map-atom
       $summaries
       $summary
       (codex:agent-job-failure-summary-json $summary))))

(= (codex:agent-job-json-option-failure-summaries $summaries)
   (if (== $summaries CodexAbsent)
       JsonNull
       (codex:agent-job-failure-summaries-json $summaries)))

(= (codex:spawn-agents-on-csv-result
      $job-id
      $status
      $output-csv-path
      $total-items
      $completed-items
      $failed-items
      $job-error
      $failed-item-errors)
   (CodexSpawnAgentsOnCsvResult
     $job-id
     $status
     $output-csv-path
     $total-items
     $completed-items
     $failed-items
     $job-error
     $failed-item-errors))

(= (codex:spawn-agents-on-csv-result-json
      (CodexSpawnAgentsOnCsvResult
        $job-id
        $status
        $output-csv-path
        $total-items
        $completed-items
        $failed-items
        $job-error
        $failed-item-errors))
   (JsonObject
     ((JsonPair "job_id" (JsonString $job-id))
      (JsonPair "status" (JsonString $status))
      (JsonPair "output_csv_path" (JsonString $output-csv-path))
      (JsonPair "total_items" (codex:agent-job-json-number $total-items))
      (JsonPair
        "completed_items"
        (codex:agent-job-json-number $completed-items))
      (JsonPair "failed_items" (codex:agent-job-json-number $failed-items))
      (JsonPair "job_error" (codex:agent-job-json-option-string $job-error))
      (JsonPair
        "failed_item_errors"
        (codex:agent-job-json-option-failure-summaries
          $failed-item-errors)))))

(= (codex:agent-job-progress-update
      $job-id
      $total-items
      $pending-items
      $running-items
      $completed-items
      $failed-items
      $eta-seconds)
   (CodexAgentJobProgressUpdate
     $job-id
     $total-items
     $pending-items
     $running-items
     $completed-items
     $failed-items
     $eta-seconds))

(= (codex:agent-job-progress-update-json
      (CodexAgentJobProgressUpdate
        $job-id
        $total-items
        $pending-items
        $running-items
        $completed-items
        $failed-items
        $eta-seconds))
   (JsonObject
     ((JsonPair "job_id" (JsonString $job-id))
      (JsonPair "total_items" (codex:agent-job-json-number $total-items))
      (JsonPair "pending_items" (codex:agent-job-json-number $pending-items))
      (JsonPair "running_items" (codex:agent-job-json-number $running-items))
      (JsonPair
        "completed_items"
        (codex:agent-job-json-number $completed-items))
      (JsonPair "failed_items" (codex:agent-job-json-number $failed-items))
      (JsonPair
        "eta_seconds"
        (case $eta-seconds
          ((CodexAbsent JsonNull)
           ($value (codex:agent-job-json-number $value))))))))

(= (codex:report-agent-job-result-tool-result $accepted)
   (CodexReportAgentJobResultToolResult $accepted))

(= (codex:report-agent-job-result-tool-result-json
      (CodexReportAgentJobResultToolResult $accepted))
   (JsonObject
     ((JsonPair "accepted" (JsonBool $accepted)))))

(= (codex:agent-job-value-to-csv-string $value)
   (case (once (eval $value))
     ((JsonNull "")
      ((JsonString $text) $text)
      ((JsonBool True) "true")
      ((JsonBool False) "false")
      ((JsonNumber $text) $text)
      ($other (json-stringify $other)))))

(= (codex:agent-job-string-contains $text $needle)
   (case (str-find $text $needle)
     ((Empty False)
      ($index True))))

(= (codex:agent-job-csv-needs-escaping $value)
   (if (codex:agent-job-string-contains $value ",")
       True
       (if (codex:agent-job-string-contains $value "\n")
           True
           (if (codex:agent-job-string-contains $value "\r")
               True
               (codex:agent-job-string-contains $value "\"")))))

(= (codex:agent-job-csv-escape $value)
   (if (codex:agent-job-csv-needs-escaping $value)
       (let $escaped
         (codex:agent-job-str-replace-all $value "\"" "\"\"")
         (str-concat "\"" (str-concat $escaped "\"")))
       $value))

(= (codex:agent-job-item
      $job-id
      $item-id
      $row-index
      $source-id
      $row-json
      $status
      $attempt-count
      $last-error
      $result-json
      $reported-at
      $completed-at)
   (CodexAgentJobItem
     $job-id
     $item-id
     $row-index
     $source-id
     $row-json
     $status
     $attempt-count
     $last-error
     $result-json
     $reported-at
     $completed-at))

(= (codex:agent-job-item-id
      (CodexAgentJobItem
        $job-id
        $item-id
        $row-index
        $source-id
        $row-json
        $status
        $attempt-count
        $last-error
        $result-json
        $reported-at
        $completed-at))
   $item-id)

(= (codex:agent-job-item-job-id
      (CodexAgentJobItem
        $job-id
        $item-id
        $row-index
        $source-id
        $row-json
        $status
        $attempt-count
        $last-error
        $result-json
        $reported-at
        $completed-at))
   $job-id)

(= (codex:agent-job-item-row-index
      (CodexAgentJobItem
        $job-id
        $item-id
        $row-index
        $source-id
        $row-json
        $status
        $attempt-count
        $last-error
        $result-json
        $reported-at
        $completed-at))
   $row-index)

(= (codex:agent-job-item-source-id
      (CodexAgentJobItem
        $job-id
        $item-id
        $row-index
        $source-id
        $row-json
        $status
        $attempt-count
        $last-error
        $result-json
        $reported-at
        $completed-at))
   $source-id)

(= (codex:agent-job-item-row-json
      (CodexAgentJobItem
        $job-id
        $item-id
        $row-index
        $source-id
        $row-json
        $status
        $attempt-count
        $last-error
        $result-json
        $reported-at
        $completed-at))
   $row-json)

(= (codex:agent-job-item-status
      (CodexAgentJobItem
        $job-id
        $item-id
        $row-index
        $source-id
        $row-json
        $status
        $attempt-count
        $last-error
        $result-json
        $reported-at
        $completed-at))
   $status)

(= (codex:agent-job-item-attempt-count
      (CodexAgentJobItem
        $job-id
        $item-id
        $row-index
        $source-id
        $row-json
        $status
        $attempt-count
        $last-error
        $result-json
        $reported-at
        $completed-at))
   $attempt-count)

(= (codex:agent-job-item-last-error
      (CodexAgentJobItem
        $job-id
        $item-id
        $row-index
        $source-id
        $row-json
        $status
        $attempt-count
        $last-error
        $result-json
        $reported-at
        $completed-at))
   $last-error)

(= (codex:agent-job-item-result-json
      (CodexAgentJobItem
        $job-id
        $item-id
        $row-index
        $source-id
        $row-json
        $status
        $attempt-count
        $last-error
        $result-json
        $reported-at
        $completed-at))
   $result-json)

(= (codex:agent-job-item-reported-at
      (CodexAgentJobItem
        $job-id
        $item-id
        $row-index
        $source-id
        $row-json
        $status
        $attempt-count
        $last-error
        $result-json
        $reported-at
        $completed-at))
   $reported-at)

(= (codex:agent-job-item-completed-at
      (CodexAgentJobItem
        $job-id
        $item-id
        $row-index
        $source-id
        $row-json
        $status
        $attempt-count
        $last-error
        $result-json
        $reported-at
        $completed-at))
   $completed-at)

(= (codex:agent-job-option-text $text)
   (if (== $text CodexAbsent)
       ""
       $text))

(= (codex:agent-job-option-result-json-text $value)
   (if (== $value CodexAbsent)
       ""
       (json-stringify $value)))

(= (codex:agent-job-output-headers $headers)
   (list:append
     $headers
     ("job_id"
      "item_id"
      "row_index"
      "source_id"
      "status"
      "attempt_count"
      "last_error"
      "result_json"
      "reported_at"
      "completed_at")))

(= (codex:agent-job-csv-line $values)
   (str-join
     ","
     (map-atom
       $values
       $value
       (codex:agent-job-csv-escape $value))))

(= (codex:agent-job-row-json-value-for-header (JsonObject $pairs) $header)
   (let $value (json-object-get (JsonObject $pairs) $header)
     (if (== $value Empty)
         ""
         (codex:agent-job-value-to-csv-string $value))))

(= (codex:agent-job-row-values-for-headers $headers $row-json)
   (map-atom
     $headers
     $header
     (codex:agent-job-row-json-value-for-header $row-json $header)))

(= (codex:agent-job-item-metadata-values
      $job-id
      $item-id
      $row-index
      $source-id
      $status
      $attempt-count
      $last-error
      $result-json
      $reported-at
      $completed-at)
   (let $row-index-text (format-args "{}" ($row-index))
     (let $source-id-text (codex:agent-job-option-text $source-id)
       (let $status-text (codex:agent-job-item-status-as-str $status)
         (let $attempt-count-text (format-args "{}" ($attempt-count))
           (let $last-error-text (codex:agent-job-option-text $last-error)
             (let $result-json-text
               (codex:agent-job-option-result-json-text $result-json)
               (let $reported-at-text
                 (codex:agent-job-option-text $reported-at)
                 (let $completed-at-text
                   (codex:agent-job-option-text $completed-at)
                   (let $tail0 ()
                     (let $tail1 (cons-atom $completed-at-text $tail0)
                       (let $tail2 (cons-atom $reported-at-text $tail1)
                         (let $tail3 (cons-atom $result-json-text $tail2)
                           (let $tail4 (cons-atom $last-error-text $tail3)
                             (let $tail5
                               (cons-atom $attempt-count-text $tail4)
                               (let $tail6 (cons-atom $status-text $tail5)
                                 (let $tail7
                                   (cons-atom $source-id-text $tail6)
                                   (let $tail8
                                     (cons-atom $row-index-text $tail7)
                                     (let $tail9
                                       (cons-atom $item-id $tail8)
                                       (cons-atom
                                         $job-id
                                         $tail9))))))))))))))))))))

(= (codex:agent-job-render-item-row $headers $item)
   (let $materialized-item (once (eval $item))
     (let $job-id (codex:agent-job-item-job-id $materialized-item)
       (let $item-id (codex:agent-job-item-id $materialized-item)
         (let $row-index (codex:agent-job-item-row-index $materialized-item)
           (let $source-id (codex:agent-job-item-source-id $materialized-item)
             (let $row-json (codex:agent-job-item-row-json $materialized-item)
               (let $status (codex:agent-job-item-status $materialized-item)
                 (let $attempt-count
                   (codex:agent-job-item-attempt-count $materialized-item)
                   (let $last-error
                     (codex:agent-job-item-last-error $materialized-item)
                     (let $result-json
                       (codex:agent-job-item-result-json $materialized-item)
                       (let $reported-at
                         (codex:agent-job-item-reported-at $materialized-item)
                         (let $completed-at
                           (codex:agent-job-item-completed-at $materialized-item)
                           (case (once (eval $row-json))
                             (((JsonObject $pairs)
                               (let $row-values
                                 (codex:agent-job-row-values-for-headers
                                   $headers
                                   (JsonObject $pairs))
                                 (let $metadata-values
                                   (codex:agent-job-item-metadata-values
                                     $job-id
                                     $item-id
                                     $row-index
                                     $source-id
                                     $status
                                     $attempt-count
                                     $last-error
                                     $result-json
                                     $reported-at
                                     $completed-at)
                                   (codex:agent-job-ok
                                     (codex:agent-job-csv-line
                                       (list:append
                                         $row-values
                                         $metadata-values))))))
                              ($other
                               (codex:agent-job-err
                                 (codex:function-call-error-respond-to-model
                                   (format-args
                                     "row_json for item {} is not a JSON object"
                                     ($item-id))))))))))))))))))))

(= (codex:agent-job-render-item-rows $headers $items)
   (if (== $items ())
       (codex:agent-job-ok "")
       (let ($head $tail) (decons-atom $items)
         (case (codex:agent-job-render-item-row $headers $head)
           (((CodexAgentJobErr $error)
             (codex:agent-job-err $error))
            ((CodexAgentJobOk $line)
             (case (codex:agent-job-render-item-rows $headers $tail)
               (((CodexAgentJobErr $error)
                 (codex:agent-job-err $error))
                ((CodexAgentJobOk $tail-lines)
                 (codex:agent-job-ok
                   (str-concat
                     $line
                     (str-concat "\n" $tail-lines))))))))))))

(= (codex:agent-job-render-job-csv $headers $items)
   (case (codex:agent-job-render-item-rows $headers $items)
     (((CodexAgentJobErr $error)
       (codex:agent-job-err $error))
      ((CodexAgentJobOk $rows)
       (codex:agent-job-ok
         (str-concat
           (codex:agent-job-csv-line
             (codex:agent-job-output-headers $headers))
           (str-concat "\n" $rows)))))))
