; Rust-faithful pure agent job CSV export snapshot slice.
;
; This ports deterministic branch behavior from:
; - openai-codex/codex-rs/core/src/tools/handlers/agent_jobs.rs
;
; Covered in this increment:
; - export snapshot initial list-items request
; - render_job_csv error mapping for auto-export
; - output parent directory creation before file write
; - final ordered filesystem action plan
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust performs async DB listing and filesystem writes inline. This pure slice
;   emits the same ordered boundary actions; the runtime bridge must execute the
;   list-items action, then call the after-list helper with the returned items,
;   then execute filesystem actions in order.
; - Rust stores `AgentJob.output_csv_path` from an `AbsolutePathBuf`. This slice
;   therefore treats paths as Unix-style absolute strings and uses the existing
;   CeTTa path helpers to recover the parent directory.

!(import! &self agent_jobs)
!(import! &self function_tool)
!(import! &self path)
!(import! &self str)

(= (codex:agent-job-export-ok $actions)
   (CodexAgentJobExportOk $actions))

(= (codex:agent-job-export-err $message)
   (CodexAgentJobExportErr $message))

(= (codex:agent-job-export-list-items $job-id)
   (CodexAgentJobExportListItems $job-id CodexAbsent CodexAbsent))

(= (codex:agent-job-export-create-dir-all $path)
   (CodexAgentJobExportCreateDirAll $path))

(= (codex:agent-job-export-write-file $path $content)
   (CodexAgentJobExportWriteFile $path $content))

(= (codex:agent-job-export-start-plan $job)
   (let $materialized-job (once (eval $job))
     (codex:agent-job-export-ok
       ((CodexAgentJobExportListItems
          (codex:agent-job-id $materialized-job)
          CodexAbsent
          CodexAbsent)))))

(= (codex:agent-job-export-render-error-message $error)
   (format-args
     "failed to render job csv for auto-export: {}"
     ((codex:function-call-error-display $error))))

(= (codex:agent-job-export-job-input-headers
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
   $input-headers)

(= (codex:agent-job-export-job-output-csv-path
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

(= (codex:agent-job-export-output-parent $output-csv-path)
   (if (== $output-csv-path "/")
       CodexAbsent
       (path-dirname $output-csv-path)))

(= (codex:agent-job-export-write-actions $output-csv-path $csv-content)
   (case (codex:agent-job-export-output-parent $output-csv-path)
     ((CodexAbsent
       ((CodexAgentJobExportWriteFile $output-csv-path $csv-content)))
      ($parent
       ((CodexAgentJobExportCreateDirAll $parent)
        (CodexAgentJobExportWriteFile $output-csv-path $csv-content))))))

(= (codex:agent-job-export-after-list $job $items)
   (let $materialized-job (once (eval $job))
     (case
       (codex:agent-job-render-job-csv
         (codex:agent-job-export-job-input-headers $materialized-job)
         $items)
       (((CodexAgentJobErr $error)
         (codex:agent-job-export-err
           (codex:agent-job-export-render-error-message $error)))
        ((CodexAgentJobOk $csv-content)
         (codex:agent-job-export-ok
           (codex:agent-job-export-write-actions
             (codex:agent-job-export-job-output-csv-path $materialized-job)
             $csv-content)))))))
