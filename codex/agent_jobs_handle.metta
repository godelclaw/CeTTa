; Rust-faithful pure spawn_agents_on_csv handle orchestration slice.
;
; This ports deterministic branch behavior from:
; - openai-codex/codex-rs/core/src/tools/handlers/agent_jobs.rs
;
; Covered in this increment:
; - csv read/create/mark-running/run-loop error message mapping
; - post-create build_runner_options error cleanup
; - mark-running transition branch
; - concurrency background-event message construction
; - run_agent_job_loop error cleanup
; - successful handoff into final-result loading
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust resolves paths, reads files, creates the job, builds runner options,
;   mutates job status, emits a background event, awaits the run loop, and then
;   loads/export/summarizes the final result inline. This pure slice receives
;   the already-computed boundary results and emits the exact ordered action
;   plan plus the visible return/error. The runtime bridge must execute the
;   actions in order and ignore cleanup/notification failures where Rust uses
;   `let _ = ...`.

!(import! &self agent_jobs)
!(import! &self agent_jobs_runner_options)
!(import! &self function_tool)

(= (codex:spawn-agents-on-csv-handle-ok $actions)
   (CodexSpawnAgentsOnCsvHandleOk $actions))

(= (codex:spawn-agents-on-csv-handle-err $actions $error)
   (CodexSpawnAgentsOnCsvHandleErr $actions $error))

(= (codex:spawn-agents-on-csv-handle-create-agent-job
      $create-params
      $items)
   (CodexSpawnAgentsOnCsvHandleCreateAgentJob $create-params $items))

(= (codex:spawn-agents-on-csv-handle-build-runner-options
      $requested-concurrency)
   (CodexSpawnAgentsOnCsvHandleBuildRunnerOptions $requested-concurrency))

(= (codex:spawn-agents-on-csv-handle-mark-job-failed
      $job-id
      $error-message)
   (CodexSpawnAgentsOnCsvHandleMarkJobFailed $job-id $error-message))

(= (codex:spawn-agents-on-csv-handle-mark-job-running $job-id)
   (CodexSpawnAgentsOnCsvHandleMarkJobRunning $job-id))

(= (codex:spawn-agents-on-csv-handle-notify-background-event $message)
   (CodexSpawnAgentsOnCsvHandleNotifyBackgroundEvent $message))

(= (codex:spawn-agents-on-csv-handle-run-agent-job-loop
      $job-id
      $options)
   (CodexSpawnAgentsOnCsvHandleRunAgentJobLoop $job-id $options))

(= (codex:spawn-agents-on-csv-handle-final-result $job-id)
   (CodexSpawnAgentsOnCsvHandleFinalResult $job-id))

(= (codex:spawn-agents-on-csv-handle-read-csv-error
      $input-path-display
      $error-display)
   (codex:function-call-error-respond-to-model
     (format-args
       "failed to read csv input {}: {}"
       ($input-path-display $error-display))))

(= (codex:spawn-agents-on-csv-handle-create-job-error $error-display)
   (codex:function-call-error-respond-to-model
     (format-args "failed to create agent job: {}" ($error-display))))

(= (codex:spawn-agents-on-csv-handle-transition-running-error
      $job-id
      $error-display)
   (codex:function-call-error-respond-to-model
     (format-args
       "failed to transition agent job {} to running: {}"
       ($job-id $error-display))))

(= (codex:spawn-agents-on-csv-handle-run-loop-failed-message
      $error-display)
   (format-args "job runner failed: {}" ($error-display)))

(= (codex:spawn-agents-on-csv-handle-run-loop-error
      $job-id
      $error-display)
   (codex:function-call-error-respond-to-model
     (format-args
       "agent job {} failed: {}"
       ($job-id $error-display))))

(= (codex:spawn-agents-on-csv-handle-debug-option-usize $value)
   (case $value
     ((CodexAbsent "None")
      ($some (format-args "Some({})" ($some))))))

(= (codex:spawn-agents-on-csv-handle-concurrency-message
      $job-id
      $requested-concurrency
      $max-threads
      $effective-concurrency)
   (let $requested-display
     (codex:spawn-agents-on-csv-handle-debug-option-usize
       $requested-concurrency)
     (let $max-threads-display
       (codex:spawn-agents-on-csv-handle-debug-option-usize $max-threads)
       (format-args
         "agent job concurrency: job_id={} requested={} max_threads={} effective={}"
         ($job-id
          $requested-display
          $max-threads-display
          $effective-concurrency)))))

(= (codex:spawn-agents-on-csv-handle-after-run-loop
      $create-action
      $build-options-action
      $mark-running-action
      $notify-action
      $run-action
      $job-id
      $run-loop-result)
   (case (once (eval $run-loop-result))
     (((CodexAgentJobErr $run-error-display)
       (let $failed-message
         (codex:spawn-agents-on-csv-handle-run-loop-failed-message
           $run-error-display)
         (let $return-error
           (codex:spawn-agents-on-csv-handle-run-loop-error
             $job-id
             $run-error-display)
           (codex:spawn-agents-on-csv-handle-err
             ($create-action
              $build-options-action
              $mark-running-action
              $notify-action
              $run-action
              (codex:spawn-agents-on-csv-handle-mark-job-failed
                $job-id
                $failed-message))
             $return-error))))
      ((CodexAgentJobOk $run-loop-value)
       (codex:spawn-agents-on-csv-handle-ok
         ($create-action
          $build-options-action
          $mark-running-action
          $notify-action
          $run-action
          (codex:spawn-agents-on-csv-handle-final-result $job-id)))))))

(= (codex:spawn-agents-on-csv-handle-running-continuation-for-options
      $create-action
      $build-options-action
      $mark-running-action
      $job-id
      $requested-concurrency
      $effective-concurrency
      $spawn-config
      $run-loop-result
      $max-threads)
   (case
     (codex:spawn-agents-on-csv-handle-concurrency-message
       $job-id
       $requested-concurrency
       $max-threads
       $effective-concurrency)
     (($concurrency-message
       (codex:spawn-agents-on-csv-handle-after-run-loop
         $create-action
         $build-options-action
         $mark-running-action
         (CodexSpawnAgentsOnCsvHandleNotifyBackgroundEvent
           $concurrency-message)
         (CodexSpawnAgentsOnCsvHandleRunAgentJobLoop
           $job-id
           (CodexAgentJobRunnerOptions $effective-concurrency $spawn-config))
         $job-id
         $run-loop-result)))))

(= (codex:spawn-agents-on-csv-handle-after-create
      $create-action
      $job-id
      $requested-concurrency
      (CodexAgentJobOk
        (CodexAgentJobRunnerOptions $effective-concurrency $spawn-config))
      (CodexAgentJobOk $unit)
      $run-loop-result
      $max-threads)
   (codex:spawn-agents-on-csv-handle-running-continuation-for-options
     $create-action
     (CodexSpawnAgentsOnCsvHandleBuildRunnerOptions $requested-concurrency)
     (CodexSpawnAgentsOnCsvHandleMarkJobRunning $job-id)
     $job-id
     $requested-concurrency
     $effective-concurrency
     $spawn-config
     $run-loop-result
     $max-threads))

(= (codex:spawn-agents-on-csv-handle-after-create
      $create-action
      $job-id
      $requested-concurrency
      (CodexAgentJobErr $error)
      $mark-running-result
      $run-loop-result
      $max-threads)
   (codex:spawn-agents-on-csv-handle-err
     ($create-action
      (CodexSpawnAgentsOnCsvHandleBuildRunnerOptions $requested-concurrency)
      (CodexSpawnAgentsOnCsvHandleMarkJobFailed
        $job-id
        (codex:function-call-error-display $error)))
     $error))

(= (codex:spawn-agents-on-csv-handle-after-create
      $create-action
      $job-id
      $requested-concurrency
      (CodexAgentJobOk
        (CodexAgentJobRunnerOptions $effective-concurrency $spawn-config))
      (CodexAgentJobErr $error-display)
      $run-loop-result
      $max-threads)
   (codex:spawn-agents-on-csv-handle-err
     ($create-action
      (CodexSpawnAgentsOnCsvHandleBuildRunnerOptions $requested-concurrency)
      (CodexSpawnAgentsOnCsvHandleMarkJobRunning $job-id))
     (codex:spawn-agents-on-csv-handle-transition-running-error
       $job-id
       $error-display)))

(= (codex:spawn-agents-on-csv-handle-plan
      $prepared
      $create-result
      $runner-options-result
      $mark-running-result
      $run-loop-result
      $max-threads)
   (let $materialized-prepared (once (eval $prepared))
     (let $create-params
       (codex:prepared-spawn-agents-on-csv-create-params
         $materialized-prepared)
       (let $items
         (codex:prepared-spawn-agents-on-csv-items $materialized-prepared)
         (let $job-id (codex:agent-job-create-params-id $create-params)
           (let $requested-concurrency
             (codex:prepared-spawn-agents-on-csv-requested-concurrency
               $materialized-prepared)
             (let $create-action
               (codex:spawn-agents-on-csv-handle-create-agent-job
                 $create-params
                 $items)
               (case (once (eval $create-result))
                 (((CodexAgentJobErr $create-error-display)
                   (codex:spawn-agents-on-csv-handle-err
                     ($create-action)
                     (codex:spawn-agents-on-csv-handle-create-job-error
                       $create-error-display)))
                  ((CodexAgentJobOk $created-job)
                   (codex:spawn-agents-on-csv-handle-after-create
                     $create-action
                     $job-id
                     $requested-concurrency
                     $runner-options-result
                     $mark-running-result
                     $run-loop-result
                     $max-threads)))))))))))
