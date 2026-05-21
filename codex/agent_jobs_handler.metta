; Rust-faithful pure BatchJobHandler dispatch slice.
;
; This ports the visible `ToolHandler for BatchJobHandler` logic from:
; - openai-codex/codex-rs/core/src/tools/handlers/agent_jobs.rs
;
; Covered in this increment:
; - ToolKind::Function kind
; - ToolPayload::Function matching
; - unsupported payload RespondToModel error
; - dispatch by `tool_name.name.as_str()` to the two agent job tools
; - unsupported tool RespondToModel error
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust awaits the selected async subhandler. This pure CeTTa shell emits the
;   exact selected subhandler plan and function arguments at that boundary; the
;   later runtime bridge must execute those plans without changing dispatch
;   conditions or error strings.

!(import! &self context)
!(import! &self function_tool)
!(import! &self tool_name)

(= (codex:batch-job-handler-kind)
   "function")

(= (codex:batch-job-handler-matches-kind $payload)
   (case $payload
     (((CodexToolPayloadFunction $arguments)
       True)
      ($other False))))

(= (codex:batch-job-handler-ok $dispatch)
   (CodexBatchJobHandlerOk $dispatch))

(= (codex:batch-job-handler-err $error)
   (CodexBatchJobHandlerErr $error))

(= (codex:batch-job-dispatch-spawn-agents-on-csv $arguments)
   (CodexBatchJobDispatchSpawnAgentsOnCsv $arguments))

(= (codex:batch-job-dispatch-report-agent-job-result $arguments)
   (CodexBatchJobDispatchReportAgentJobResult $arguments))

(= (codex:batch-job-handler-function-arguments $payload)
   (case $payload
     (((CodexToolPayloadFunction $arguments)
       (codex:batch-job-handler-ok $arguments))
      ($other
       (codex:batch-job-handler-err
         (codex:function-call-error-respond-to-model
           "agent jobs handler received unsupported payload"))))))

(= (codex:batch-job-handler-unsupported-tool-error $tool-name)
   (codex:function-call-error-respond-to-model
     (format-args "unsupported agent job tool {}" ($tool-name))))

(= (codex:batch-job-handler-dispatch $tool-name-text $arguments)
   (case $tool-name-text
     (("spawn_agents_on_csv"
       (codex:batch-job-handler-ok
         (codex:batch-job-dispatch-spawn-agents-on-csv $arguments)))
      ("report_agent_job_result"
       (codex:batch-job-handler-ok
         (codex:batch-job-dispatch-report-agent-job-result $arguments)))
      ($other
       (codex:batch-job-handler-err
         (codex:batch-job-handler-unsupported-tool-error $other))))))

(= (codex:run-batch-job-handler $tool-name $payload)
   (case (codex:batch-job-handler-function-arguments $payload)
     (((CodexBatchJobHandlerErr $error)
       (codex:batch-job-handler-err $error))
      ((CodexBatchJobHandlerOk $arguments)
       (codex:batch-job-handler-dispatch
         (codex:tool-name-name $tool-name)
         $arguments)))))
