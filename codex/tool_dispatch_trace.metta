; Rust-faithful tool dispatch trace mapping slice.
;
; This ports deterministic behavior from:
; - openai-codex/codex-rs/core/src/tools/tool_dispatch_trace.rs
; - openai-codex/codex-rs/rollout-trace/src/tool_dispatch.rs
;
; Covered in this increment:
; - ToolCallSource requester mapping
; - ToolDispatchInvocation and ToolDispatchResult projection
; - ToolDispatchPayload cloning/projection, including local-shell fields
; - dispatch trace suppression for the public code-mode `exec` boundary
; - trace kind, label, input preview, and JSON payload construction
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust owns an enabled/disabled ToolDispatchTraceContext with a TraceWriter
;   and appends raw events as side effects. CeTTa represents the same
;   start/completed/failed event payload decisions as pure data records.
; - Rust receives a trait-object ToolOutput. This slice uses the already-ported
;   `codex:tool-output-*` helpers over concrete CeTTa output atoms.
; - The older CeTTa ToolPayload::LocalShell surface only carried `command`.
;   This slice adds a trace-local local-shell payload constructor with the full
;   Rust ShellToolCallParams field set and still accepts the older command-only
;   atom by filling the omitted fields with `CodexAbsent`.

!(import! &self context)
!(import! &self json)
!(import! &self str)
!(import! &self tool_name)

(= (codex:tool-dispatch-preview-max-chars)
   160)

(= (codex:tool-dispatch-public-code-tool-name)
   "exec")

(= (codex:tool-call-source-direct)
   (CodexToolCallSourceDirect))

(= (codex:tool-call-source-js-repl)
   (CodexToolCallSourceJsRepl))

(= (codex:tool-call-source-code-mode $cell-id $runtime-tool-call-id)
   (CodexToolCallSourceCodeMode $cell-id $runtime-tool-call-id))

(= (codex:tool-dispatch-requester-model $model-visible-call-id)
   (CodexToolDispatchRequesterModel $model-visible-call-id))

(= (codex:tool-dispatch-requester-code-cell
      $runtime-cell-id
      $runtime-tool-call-id)
   (CodexToolDispatchRequesterCodeCell
     $runtime-cell-id
     $runtime-tool-call-id))

(= (codex:tool-dispatch-requester-fields
      $model-visible-call-id
      $code-mode-runtime-tool-id
      $raw-requester)
   (CodexToolDispatchRequesterFields
     $model-visible-call-id
     $code-mode-runtime-tool-id
     $raw-requester))

(= (codex:tool-dispatch-raw-requester-model)
   (CodexToolDispatchRawRequesterModel))

(= (codex:tool-dispatch-raw-requester-code-cell $runtime-cell-id)
   (CodexToolDispatchRawRequesterCodeCell $runtime-cell-id))

(= (codex:tool-dispatch-requester-from-source $source $call-id)
   (case $source
     (((CodexToolCallSourceDirect)
       (codex:tool-dispatch-requester-model $call-id))
      ((CodexToolCallSourceCodeMode $cell-id $runtime-tool-call-id)
       (codex:tool-dispatch-requester-code-cell
         $cell-id
         $runtime-tool-call-id))
      ((CodexToolCallSourceJsRepl)
       CodexAbsent))))

(= (codex:tool-dispatch-requester-fields-from-requester
      (CodexToolDispatchRequesterModel $model-visible-call-id))
   (codex:tool-dispatch-requester-fields
     $model-visible-call-id
     CodexAbsent
     (codex:tool-dispatch-raw-requester-model)))

(= (codex:tool-dispatch-requester-fields-from-requester
      (CodexToolDispatchRequesterCodeCell
        $runtime-cell-id
        $runtime-tool-call-id))
   (codex:tool-dispatch-requester-fields
     CodexAbsent
     $runtime-tool-call-id
     (codex:tool-dispatch-raw-requester-code-cell $runtime-cell-id)))

(= (codex:tool-dispatch-invocation-input
      $thread-id
      $codex-turn-id
      $tool-call-id
      $tool-name
      $source
      $payload)
   (CodexToolDispatchInvocationInput
     $thread-id
     $codex-turn-id
     $tool-call-id
     $tool-name
     $source
     $payload))

(= (codex:tool-dispatch-invocation
      $thread-id
      $codex-turn-id
      $tool-call-id
      $tool-name
      $tool-namespace
      $requester
      $payload)
   (CodexToolDispatchInvocation
     $thread-id
     $codex-turn-id
     $tool-call-id
     $tool-name
     $tool-namespace
     $requester
     $payload))

(= (codex:tool-dispatch-invocation-from-input
      (CodexToolDispatchInvocationInput
        $thread-id
        $codex-turn-id
        $tool-call-id
        $tool-name
        $source
        $payload))
   (case (codex:tool-dispatch-requester-from-source $source $tool-call-id)
     ((CodexAbsent CodexAbsent)
      ($requester
       (codex:tool-dispatch-invocation
         $thread-id
         $codex-turn-id
         $tool-call-id
         (codex:tool-name-name $tool-name)
         (codex:tool-name-namespace $tool-name)
         $requester
         (codex:tool-dispatch-payload $payload))))))

(= (codex:tool-dispatch-function-payload $arguments)
   (CodexToolDispatchPayloadFunction $arguments))

(= (codex:tool-dispatch-tool-search-payload $query $limit)
   (CodexToolDispatchPayloadToolSearch $query $limit))

(= (codex:tool-dispatch-custom-payload $input)
   (CodexToolDispatchPayloadCustom $input))

(= (codex:tool-dispatch-local-shell-payload
      $command
      $workdir
      $timeout-ms
      $sandbox-permissions
      $prefix-rule
      $additional-permissions
      $justification)
   (CodexToolDispatchPayloadLocalShell
     $command
     $workdir
     $timeout-ms
     $sandbox-permissions
     $prefix-rule
     $additional-permissions
     $justification))

(= (codex:tool-dispatch-mcp-payload $server $tool $raw-arguments)
   (CodexToolDispatchPayloadMcp $server $tool $raw-arguments))

(= (codex:tool-dispatch-payload $payload)
   (case $payload
     (((CodexToolPayloadFunction $arguments)
       (codex:tool-dispatch-function-payload $arguments))
      ((CodexToolPayloadToolSearch $query $limit)
       (codex:tool-dispatch-tool-search-payload $query $limit))
      ((CodexToolPayloadCustom $input)
       (codex:tool-dispatch-custom-payload $input))
      ((CodexToolPayloadLocalShell $command)
       (codex:tool-dispatch-local-shell-payload
         $command
         CodexAbsent
         CodexAbsent
         CodexAbsent
         CodexAbsent
         CodexAbsent
         CodexAbsent))
      ((CodexToolPayloadLocalShellParams
         $command
         $workdir
         $timeout-ms
         $sandbox-permissions
         $prefix-rule
         $additional-permissions
         $justification)
       (codex:tool-dispatch-local-shell-payload
         $command
         $workdir
         $timeout-ms
         $sandbox-permissions
         $prefix-rule
         $additional-permissions
         $justification))
      ((CodexToolPayloadMcp $server $tool $raw-arguments)
       (codex:tool-dispatch-mcp-payload
         $server
         $tool
         $raw-arguments)))))

(= (codex:tool-dispatch-local-shell-params-payload
      $command
      $workdir
      $timeout-ms
      $sandbox-permissions
      $prefix-rule
      $additional-permissions
      $justification)
   (CodexToolPayloadLocalShellParams
     $command
     $workdir
     $timeout-ms
     $sandbox-permissions
     $prefix-rule
     $additional-permissions
     $justification))

(= (codex:tool-dispatch-truncate-preview $value)
   (if (> (str-length $value) (codex:tool-dispatch-preview-max-chars))
       (str-concat
         (str-slice $value 0 (codex:tool-dispatch-preview-max-chars))
         "...")
       $value))

(= (codex:tool-dispatch-payload-log-preview $payload)
   (case $payload
     (((CodexToolDispatchPayloadFunction $arguments)
       (codex:tool-dispatch-truncate-preview $arguments))
      ((CodexToolDispatchPayloadToolSearch $query $limit)
       (codex:tool-dispatch-truncate-preview $query))
      ((CodexToolDispatchPayloadCustom $input)
       (codex:tool-dispatch-truncate-preview $input))
      ((CodexToolDispatchPayloadLocalShell
         $command
         $workdir
         $timeout-ms
         $sandbox-permissions
         $prefix-rule
         $additional-permissions
         $justification)
       (codex:tool-dispatch-truncate-preview (str-join " " $command)))
      ((CodexToolDispatchPayloadMcp $server $tool $raw-arguments)
       (codex:tool-dispatch-truncate-preview $raw-arguments)))))

(= (codex:tool-dispatch-string-list-json $items)
   (if (== $items ())
       (JsonArray ())
       (let ($head $tail) (decons-atom $items)
         (case (codex:tool-dispatch-string-list-json $tail)
           (((JsonArray $rest)
             (JsonArray (cons-atom (JsonString $head) $rest))))))))

(= (codex:tool-dispatch-json-optional-string $value)
   (if (== $value CodexAbsent)
       JsonNull
       (JsonString $value)))

(= (codex:tool-dispatch-json-optional-number $value)
   (if (== $value CodexAbsent)
       JsonNull
       (JsonNumber $value)))

(= (codex:tool-dispatch-json-optional-string-list $value)
   (if (== $value CodexAbsent)
       JsonNull
       (codex:tool-dispatch-string-list-json $value)))

(= (codex:tool-dispatch-json-optional-raw $value)
   (if (== $value CodexAbsent)
       JsonNull
       $value))

(= (codex:tool-dispatch-search-arguments-json $query $limit)
   (if (== $limit CodexAbsent)
       (JsonObject
         ((JsonPair "query" (JsonString $query))))
       (JsonObject
         ((JsonPair "query" (JsonString $query))
          (JsonPair "limit" (JsonNumber $limit))))))

(= (codex:tool-dispatch-payload-json $payload)
   (case $payload
     (((CodexToolDispatchPayloadFunction $arguments)
       (JsonObject
         ((JsonPair "type" (JsonString "function"))
          (JsonPair "arguments" (JsonString $arguments)))))
      ((CodexToolDispatchPayloadToolSearch $query $limit)
       (JsonObject
         ((JsonPair "type" (JsonString "tool_search"))
          (JsonPair "arguments"
            (codex:tool-dispatch-search-arguments-json $query $limit)))))
      ((CodexToolDispatchPayloadCustom $input)
       (JsonObject
         ((JsonPair "type" (JsonString "custom"))
          (JsonPair "input" (JsonString $input)))))
      ((CodexToolDispatchPayloadLocalShell
         $command
         $workdir
         $timeout-ms
         $sandbox-permissions
         $prefix-rule
         $additional-permissions
         $justification)
       (JsonObject
         ((JsonPair "type" (JsonString "local_shell"))
          (JsonPair "command" (codex:tool-dispatch-string-list-json $command))
          (JsonPair "workdir"
            (codex:tool-dispatch-json-optional-string $workdir))
          (JsonPair "timeout_ms"
            (codex:tool-dispatch-json-optional-number $timeout-ms))
          (JsonPair "sandbox_permissions"
            (codex:tool-dispatch-json-optional-string $sandbox-permissions))
          (JsonPair "prefix_rule"
            (codex:tool-dispatch-json-optional-string-list $prefix-rule))
          (JsonPair "additional_permissions"
            (codex:tool-dispatch-json-optional-raw $additional-permissions))
          (JsonPair "justification"
            (codex:tool-dispatch-json-optional-string $justification)))))
      ((CodexToolDispatchPayloadMcp $server $tool $raw-arguments)
       (JsonObject
         ((JsonPair "type" (JsonString "mcp"))
          (JsonPair "server" (JsonString $server))
          (JsonPair "tool" (JsonString $tool))
          (JsonPair "raw_arguments" (JsonString $raw-arguments))))))))

(= (codex:tool-dispatch-kind-mcp $server $tool)
   (CodexToolDispatchKindMcp $server $tool))

(= (codex:tool-dispatch-kind-exec-command)
   (CodexToolDispatchKindExecCommand))

(= (codex:tool-dispatch-kind-write-stdin)
   (CodexToolDispatchKindWriteStdin))

(= (codex:tool-dispatch-kind-apply-patch)
   (CodexToolDispatchKindApplyPatch))

(= (codex:tool-dispatch-kind-web)
   (CodexToolDispatchKindWeb))

(= (codex:tool-dispatch-kind-image-generation)
   (CodexToolDispatchKindImageGeneration))

(= (codex:tool-dispatch-kind-spawn-agent)
   (CodexToolDispatchKindSpawnAgent))

(= (codex:tool-dispatch-kind-send-message)
   (CodexToolDispatchKindSendMessage))

(= (codex:tool-dispatch-kind-assign-agent-task)
   (CodexToolDispatchKindAssignAgentTask))

(= (codex:tool-dispatch-kind-wait-agent)
   (CodexToolDispatchKindWaitAgent))

(= (codex:tool-dispatch-kind-close-agent)
   (CodexToolDispatchKindCloseAgent))

(= (codex:tool-dispatch-kind-other $name)
   (CodexToolDispatchKindOther $name))

(= (codex:tool-dispatch-kind-for-name $tool-name)
   (case $tool-name
     (("exec_command" (codex:tool-dispatch-kind-exec-command))
      ("local_shell" (codex:tool-dispatch-kind-exec-command))
      ("shell" (codex:tool-dispatch-kind-exec-command))
      ("shell_command" (codex:tool-dispatch-kind-exec-command))
      ("write_stdin" (codex:tool-dispatch-kind-write-stdin))
      ("apply_patch" (codex:tool-dispatch-kind-apply-patch))
      ("web_search" (codex:tool-dispatch-kind-web))
      ("web_search_preview" (codex:tool-dispatch-kind-web))
      ("image_generation" (codex:tool-dispatch-kind-image-generation))
      ("image_query" (codex:tool-dispatch-kind-image-generation))
      ("spawn_agent" (codex:tool-dispatch-kind-spawn-agent))
      ("send_message" (codex:tool-dispatch-kind-send-message))
      ("followup_task" (codex:tool-dispatch-kind-assign-agent-task))
      ("wait_agent" (codex:tool-dispatch-kind-wait-agent))
      ("close_agent" (codex:tool-dispatch-kind-close-agent))
      ($other (codex:tool-dispatch-kind-other $other)))))

(= (codex:tool-dispatch-kind $tool-name $payload)
   (case $payload
     (((CodexToolDispatchPayloadMcp $server $tool $raw-arguments)
       (codex:tool-dispatch-kind-mcp $server $tool))
      ($other
       (codex:tool-dispatch-kind-for-name $tool-name)))))

(= (codex:tool-dispatch-label $tool-name $tool-namespace $payload)
   (case $payload
     (((CodexToolDispatchPayloadMcp $server $tool $raw-arguments)
       (str-concat "mcp:" (str-concat $server (str-concat ":" $tool))))
      ($other
       (if (== $tool-namespace CodexAbsent)
           $tool-name
           (str-concat $tool-namespace (str-concat "." $tool-name)))))))

(= (codex:tool-dispatch-is-custom-payload $payload)
   (case $payload
     (((CodexToolDispatchPayloadCustom $input) True)
      ($other False))))

(= (codex:tool-dispatch-suppresses-trace
      (CodexToolDispatchInvocation
        $thread-id
        $codex-turn-id
        $tool-call-id
        $tool-name
        $tool-namespace
        $requester
        $payload))
   (and
     (and
       (codex:tool-dispatch-is-custom-payload $payload)
       (== $tool-namespace CodexAbsent))
     (== $tool-name (codex:tool-dispatch-public-code-tool-name))))

(= (codex:tool-dispatch-started-event
      $kind
      $label
      $input-preview
      $requester-fields
      $payload-json)
   (CodexToolDispatchStartedEvent
     $kind
     $label
     $input-preview
     $requester-fields
     $payload-json))

(= (codex:tool-dispatch-start-trace $invocation)
   (if (codex:tool-dispatch-suppresses-trace $invocation)
       CodexAbsent
       (case $invocation
         (((CodexToolDispatchInvocation
             $thread-id
             $codex-turn-id
             $tool-call-id
             $tool-name
             $tool-namespace
             $requester
             $payload)
           (codex:tool-dispatch-started-event
             (codex:tool-dispatch-kind $tool-name $payload)
             (codex:tool-dispatch-label $tool-name $tool-namespace $payload)
             (codex:tool-dispatch-payload-log-preview $payload)
             (codex:tool-dispatch-requester-fields-from-requester $requester)
             (codex:tool-dispatch-payload-json $payload)))))))

(= (codex:tool-dispatch-result-direct-response $response-item)
   (CodexToolDispatchResultDirectResponse $response-item))

(= (codex:tool-dispatch-result-code-mode-response $value)
   (CodexToolDispatchResultCodeModeResponse $value))

(= (codex:tool-dispatch-result-error $message)
   (CodexToolDispatchResultError $message))

(= (codex:tool-dispatch-result $source $call-id $payload $output)
   (case $source
     (((CodexToolCallSourceDirect)
       (codex:tool-dispatch-result-direct-response
         (codex:tool-output-to-response-item $output $call-id $payload)))
      ((CodexToolCallSourceCodeMode $cell-id $runtime-tool-call-id)
       (codex:tool-dispatch-result-code-mode-response
         (codex:tool-output-code-mode-result $output $payload)))
      ((CodexToolCallSourceJsRepl)
       CodexAbsent))))

(= (codex:tool-dispatch-execution-status-completed)
   (CodexToolDispatchExecutionStatusCompleted))

(= (codex:tool-dispatch-execution-status-failed)
   (CodexToolDispatchExecutionStatusFailed))

(= (codex:tool-dispatch-completed-event $status $result)
   (CodexToolDispatchCompletedEvent $status $result))

(= (codex:tool-dispatch-record-completed
      False
      $source
      $call-id
      $payload
      $output)
   CodexAbsent)

(= (codex:tool-dispatch-record-completed
      True
      $source
      $call-id
      $payload
      $output)
   (case (codex:tool-dispatch-result $source $call-id $payload $output)
     ((CodexAbsent CodexAbsent)
      ($result
       (codex:tool-dispatch-completed-event
         (if (codex:tool-output-success-for-logging $output)
             (codex:tool-dispatch-execution-status-completed)
             (codex:tool-dispatch-execution-status-failed))
         $result)))))

(= (codex:tool-dispatch-record-failed False $message)
   CodexAbsent)

(= (codex:tool-dispatch-record-failed True $message)
   (codex:tool-dispatch-completed-event
     (codex:tool-dispatch-execution-status-failed)
     (codex:tool-dispatch-result-error $message)))
