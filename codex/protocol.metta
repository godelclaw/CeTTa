; Minimal Rust-faithful Codex protocol slice.
;
; This ports the JSON wire shape for the narrow ResponseItem subset below from
; openai-codex/codex-rs/protocol/src/models.rs and
; openai-codex/codex-rs/protocol/src/protocol.rs:
; - Message
; - Reasoning
; - FunctionCall
; - FunctionCallOutput
; - McpToolCallOutput
; - CustomToolCall
; - CustomToolCallOutput
; - ToolSearchOutput
; - WebSearchCall
; - ImageGenerationCall
; - TokenUsage / TokenUsageInfo / TokenCountEvent / RateLimitSnapshot /
;   RateLimitWindow / CreditsSnapshot / FinalOutput
; - ExecCommandOutputDeltaEvent
; - TerminalInteractionEvent
; - WebSearchBeginEvent / WebSearchEndEvent
; - ImageGenerationBeginEvent / ImageGenerationEndEvent
; - AgentMessageDeltaEvent / AgentReasoning*Event
; - McpInvocation / McpToolCallBeginEvent
; - McpStartupUpdateEvent / McpStartupCompleteEvent
; - ThreadNameUpdatedEvent / ThreadRolledBackEvent
; - WarningEvent / ModelRerouteEvent / ContextCompactedEvent
; - ReviewOutputEvent / ReviewFinding / ReviewCodeLocation / ReviewLineRange
;
; This increment covers the plain-text and structured content-item branches of
; FunctionCallOutputPayload at the JSON wire layer. The content-item subset
; follows Rust here: `input_text` and `input_image` are supported for
; function/custom tool outputs.
;
; CeTTa detail: `Empty` is a reduction sentinel, so omitted optional protocol
; fields use the internal tag `CodexAbsent` until projected back out.
;
; This restart subset does not yet port `account::PlanType`, so the
; `RateLimitSnapshot.plan_type` field is currently carried through as the same
; visible raw value/string supplied by callers.
;
; The unified-exec delta event stores raw bytes in Rust and serializes them as
; base64. The current CeTTa surface therefore models the event payload as text
; whose current byte sequence is base64-encoded at JSON projection time.

!(import! &self json)
!(import! &self str)

(= (codex:response-message $id $role $content $phase)
   (CodexResponseItemMessageWithId $id $role $content $phase))

(= (codex:user-message $text)
   (CodexResponseItemMessage "user" ((CodexInputText $text)) CodexAbsent))

(= (codex:assistant-message $text)
   (CodexResponseItemMessage "assistant" ((CodexOutputText $text)) CodexAbsent))

(= (codex:commentary-message $text)
   (CodexResponseItemMessage "assistant" ((CodexOutputText $text)) "commentary"))

(= (codex:final-response $text)
   (CodexResponseItemMessage "assistant" ((CodexOutputText $text)) "final_answer"))

(= (codex:function-call-response-item $name $arguments $call_id)
   (CodexResponseItemFunctionCall
     CodexAbsent
     $name
     CodexAbsent
     $arguments
     $call_id))

(= (codex:function-call-response-item
      $id
      $name
      $namespace
      $arguments
      $call_id)
   (CodexResponseItemFunctionCall
     $id
     $name
     $namespace
     $arguments
     $call_id))

(= (codex:function-call-output-text $text)
   (CodexFunctionCallOutputText $text))

(= (codex:function-call-output-content-items $items)
   (CodexFunctionCallOutputContentItems $items))

(= (codex:function-tool-result $call_id $output)
   (CodexResponseItemFunctionCallOutput $call_id $output))

(= (codex:tool-call $call_id $name $input)
   (CodexResponseItemCustomToolCall $call_id $name $input))

(= (codex:tool-result $call_id $output)
   (CodexResponseItemCustomToolCallOutput
     $call_id
     CodexAbsent
     (CodexFunctionCallOutputText $output)))

(= (codex:tool-result-content-items $call_id $items)
   (CodexResponseItemCustomToolCallOutput
     $call_id
     CodexAbsent
     (CodexFunctionCallOutputContentItems $items)))

(= (codex:mcp-tool-call-output $call_id $output)
   (CodexResponseItemMcpToolCallOutput $call_id $output))

(= (codex:tool-search-output $call_id $status $execution $tools)
   (CodexResponseItemToolSearchOutput $call_id $status $execution $tools))

(= (codex:named-tool-result $call_id $name $output)
   (CodexResponseItemCustomToolCallOutput
     $call_id
     $name
     (CodexFunctionCallOutputText $output)))

(= (codex:named-tool-result-content-items $call_id $name $items)
   (CodexResponseItemCustomToolCallOutput
     $call_id
     $name
     (CodexFunctionCallOutputContentItems $items)))

(= (codex:input-image $image_url)
   (CodexInputImage $image_url CodexAbsent))

(= (codex:input-image $image_url $detail)
   (CodexInputImage $image_url $detail))

(= (codex:exec-command-output-delta-event $call_id $stream $chunk)
   (CodexEventExecCommandOutputDelta $call_id $stream $chunk))

(= (codex:terminal-interaction-event $call_id $process_id $stdin)
   (CodexEventTerminalInteraction $call_id $process_id $stdin))

(= (codex:agent-message-delta-event $delta)
   (CodexEventAgentMessageDelta $delta))

(= (codex:agent-reasoning-event $text)
   (CodexEventAgentReasoning $text))

(= (codex:agent-reasoning-raw-content-event $text)
   (CodexEventAgentReasoningRawContent $text))

(= (codex:agent-reasoning-raw-content-delta-event $delta)
   (CodexEventAgentReasoningRawContentDelta $delta))

(= (codex:agent-reasoning-section-break-event $item_id $summary_index)
   (CodexEventAgentReasoningSectionBreak $item_id $summary_index))

(= (codex:agent-reasoning-delta-event $delta)
   (CodexEventAgentReasoningDelta $delta))

(= (codex:mcp-invocation $server $tool $arguments)
   (CodexMcpInvocation $server $tool $arguments))

(= (codex:mcp-tool-call-begin-event $call_id $invocation $mcp_app_resource_uri)
   (CodexEventMcpToolCallBegin $call_id $invocation $mcp_app_resource_uri))

(= (codex:mcp-startup-status-starting)
   (CodexMcpStartupStatusStarting))

(= (codex:mcp-startup-status-ready)
   (CodexMcpStartupStatusReady))

(= (codex:mcp-startup-status-failed $error)
   (CodexMcpStartupStatusFailed $error))

(= (codex:mcp-startup-status-cancelled)
   (CodexMcpStartupStatusCancelled))

(= (codex:mcp-startup-failure $server $error)
   (CodexMcpStartupFailure $server $error))

(= (codex:mcp-startup-update-event $server $status)
   (CodexEventMcpStartupUpdate $server $status))

(= (codex:mcp-startup-complete-event $ready $failed $cancelled)
   (CodexEventMcpStartupComplete $ready $failed $cancelled))

(= (codex:thread-name-updated-event $thread_id $thread_name)
   (CodexEventThreadNameUpdated $thread_id $thread_name))

(= (codex:thread-rolled-back-event $num_turns)
   (CodexEventThreadRolledBack $num_turns))

(= (codex:warning-event $message)
   (CodexEventWarning $message))

(= (codex:guardian-warning-event $message)
   (CodexEventGuardianWarning $message))

(= (codex:model-reroute-reason-high-risk-cyber-activity)
   (CodexModelRerouteReasonHighRiskCyberActivity))

(= (codex:model-reroute-event $from_model $to_model $reason)
   (CodexEventModelReroute $from_model $to_model $reason))

(= (codex:context-compacted-event)
   (CodexEventContextCompacted))

(= (codex:web-search-begin-event $call_id)
   (CodexEventWebSearchBegin $call_id))

(= (codex:web-search-end-event $call_id $query $action)
   (CodexEventWebSearchEnd $call_id $query $action))

(= (codex:image-generation-begin-event $call_id)
   (CodexEventImageGenerationBegin $call_id))

(= (codex:image-generation-end-event
      $call_id
      $status
      $revised-prompt
      $result
      $saved-path)
   (CodexEventImageGenerationEnd
     $call_id
     $status
     $revised-prompt
     $result
     $saved-path))

(= (codex:reasoning-summary-text $text)
   (CodexReasoningItemSummaryText $text))

(= (codex:reasoning-content-reasoning-text $text)
   (CodexReasoningItemContentReasoningText $text))

(= (codex:reasoning-content-text $text)
   (CodexReasoningItemContentText $text))

(= (codex:reasoning-response-item $id $summary $content)
   (CodexResponseItemReasoning $id $summary $content CodexAbsent))

(= (codex:web-search-action-search $query $queries)
   (CodexWebSearchActionSearch $query $queries))

(= (codex:web-search-action-open-page $url)
   (CodexWebSearchActionOpenPage $url))

(= (codex:web-search-action-find-in-page $url $pattern)
   (CodexWebSearchActionFindInPage $url $pattern))

(= (codex:web-search-action-other)
   (CodexWebSearchActionOther))

(= (codex:web-search-call-response-item $id $status $action)
   (CodexResponseItemWebSearchCall $id $status $action))

(= (codex:image-generation-call-response-item
      $id
      $status
      $revised-prompt
      $result)
   (CodexResponseItemImageGenerationCall
     $id
     $status
     $revised-prompt
     $result))

(= (codex:review-line-range $start $end)
   (CodexReviewLineRange $start $end))

(= (codex:review-line-range-start
      (CodexReviewLineRange $start $end))
   $start)

(= (codex:review-line-range-end
      (CodexReviewLineRange $start $end))
   $end)

(= (codex:review-code-location $absolute-file-path $line-range)
   (CodexReviewCodeLocation $absolute-file-path $line-range))

(= (codex:review-code-location-absolute-file-path
      (CodexReviewCodeLocation $absolute-file-path $line-range))
   $absolute-file-path)

(= (codex:review-code-location-line-range
      (CodexReviewCodeLocation $absolute-file-path $line-range))
   $line-range)

(= (codex:review-finding
      $title
      $body
      $confidence-score
      $priority
      $code-location)
   (CodexReviewFinding
     $title
     $body
     $confidence-score
     $priority
     $code-location))

(= (codex:review-finding-title
      (CodexReviewFinding
        $title
        $body
        $confidence-score
        $priority
        $code-location))
   $title)

(= (codex:review-finding-body
      (CodexReviewFinding
        $title
        $body
        $confidence-score
        $priority
        $code-location))
   $body)

(= (codex:review-finding-confidence-score
      (CodexReviewFinding
        $title
        $body
        $confidence-score
        $priority
        $code-location))
   $confidence-score)

(= (codex:review-finding-priority
      (CodexReviewFinding
        $title
        $body
        $confidence-score
        $priority
        $code-location))
   $priority)

(= (codex:review-finding-code-location
      (CodexReviewFinding
        $title
        $body
        $confidence-score
        $priority
        $code-location))
   $code-location)

(= (codex:review-output-event
      $findings
      $overall-correctness
      $overall-explanation
      $overall-confidence-score)
   (CodexReviewOutputEvent
     $findings
     $overall-correctness
     $overall-explanation
     $overall-confidence-score))

(= (codex:default-review-output-event)
   (CodexReviewOutputEvent () "" "" 0.0))

(= (codex:review-output-event-findings
      (CodexReviewOutputEvent
        $findings
        $overall-correctness
        $overall-explanation
        $overall-confidence-score))
   $findings)

(= (codex:review-output-event-overall-correctness
      (CodexReviewOutputEvent
        $findings
        $overall-correctness
        $overall-explanation
        $overall-confidence-score))
   $overall-correctness)

(= (codex:review-output-event-overall-explanation
      (CodexReviewOutputEvent
        $findings
        $overall-correctness
        $overall-explanation
        $overall-confidence-score))
   $overall-explanation)

(= (codex:review-output-event-overall-confidence-score
      (CodexReviewOutputEvent
        $findings
        $overall-correctness
        $overall-explanation
        $overall-confidence-score))
   $overall-confidence-score)

(= (codex:token-usage
      $input-tokens
      $cached-input-tokens
      $output-tokens
      $reasoning-output-tokens
      $total-tokens)
   (CodexTokenUsage
     $input-tokens
     $cached-input-tokens
     $output-tokens
     $reasoning-output-tokens
     $total-tokens))

(= (codex:default-token-usage)
   (CodexTokenUsage 0 0 0 0 0))

(= (codex:token-usage-input-tokens
      (CodexTokenUsage
        $input-tokens
        $cached-input-tokens
        $output-tokens
        $reasoning-output-tokens
        $total-tokens))
   $input-tokens)

(= (codex:token-usage-cached-input-tokens
      (CodexTokenUsage
        $input-tokens
        $cached-input-tokens
        $output-tokens
        $reasoning-output-tokens
        $total-tokens))
   $cached-input-tokens)

(= (codex:token-usage-output-tokens
      (CodexTokenUsage
        $input-tokens
        $cached-input-tokens
        $output-tokens
        $reasoning-output-tokens
        $total-tokens))
   $output-tokens)

(= (codex:token-usage-reasoning-output-tokens
      (CodexTokenUsage
        $input-tokens
        $cached-input-tokens
        $output-tokens
        $reasoning-output-tokens
        $total-tokens))
   $reasoning-output-tokens)

(= (codex:token-usage-total-tokens
      (CodexTokenUsage
        $input-tokens
        $cached-input-tokens
        $output-tokens
        $reasoning-output-tokens
        $total-tokens))
   $total-tokens)

(= (codex:final-output $token-usage)
   (CodexFinalOutput $token-usage))

(= (codex:final-output-token-usage (CodexFinalOutput $token-usage))
   $token-usage)

(= (codex:token-usage-info
      $total-token-usage
      $last-token-usage
      $model-context-window)
   (CodexTokenUsageInfo
     $total-token-usage
     $last-token-usage
     $model-context-window))

(= (codex:token-usage-info-total-token-usage
      (CodexTokenUsageInfo
        $total-token-usage
        $last-token-usage
        $model-context-window))
   $total-token-usage)

(= (codex:token-usage-info-last-token-usage
      (CodexTokenUsageInfo
        $total-token-usage
        $last-token-usage
        $model-context-window))
   $last-token-usage)

(= (codex:token-usage-info-model-context-window
      (CodexTokenUsageInfo
        $total-token-usage
        $last-token-usage
        $model-context-window))
   $model-context-window)

(= (codex:token-count-event $info $rate-limits)
   (CodexTokenCountEvent $info $rate-limits))

(= (codex:token-count-event-info
      (CodexTokenCountEvent $info $rate-limits))
   $info)

(= (codex:token-count-event-rate-limits
      (CodexTokenCountEvent $info $rate-limits))
   $rate-limits)

(= (codex:rate-limit-reached-type-rate-limit-reached)
   "rate_limit_reached")

(= (codex:rate-limit-reached-type-workspace-owner-credits-depleted)
   "workspace_owner_credits_depleted")

(= (codex:rate-limit-reached-type-workspace-member-credits-depleted)
   "workspace_member_credits_depleted")

(= (codex:rate-limit-reached-type-workspace-owner-usage-limit-reached)
   "workspace_owner_usage_limit_reached")

(= (codex:rate-limit-reached-type-workspace-member-usage-limit-reached)
   "workspace_member_usage_limit_reached")

(= (codex:rate-limit-window $used-percent $window-minutes $resets-at)
   (CodexRateLimitWindow $used-percent $window-minutes $resets-at))

(= (codex:rate-limit-window-used-percent
      (CodexRateLimitWindow $used-percent $window-minutes $resets-at))
   $used-percent)

(= (codex:rate-limit-window-window-minutes
      (CodexRateLimitWindow $used-percent $window-minutes $resets-at))
   $window-minutes)

(= (codex:rate-limit-window-resets-at
      (CodexRateLimitWindow $used-percent $window-minutes $resets-at))
   $resets-at)

(= (codex:credits-snapshot $has-credits $unlimited $balance)
   (CodexCreditsSnapshot $has-credits $unlimited $balance))

(= (codex:credits-snapshot-has-credits
      (CodexCreditsSnapshot $has-credits $unlimited $balance))
   $has-credits)

(= (codex:credits-snapshot-unlimited
      (CodexCreditsSnapshot $has-credits $unlimited $balance))
   $unlimited)

(= (codex:credits-snapshot-balance
      (CodexCreditsSnapshot $has-credits $unlimited $balance))
   $balance)

(= (codex:rate-limit-snapshot
      $limit-id
      $limit-name
      $primary
      $secondary
      $credits
      $plan-type
      $rate-limit-reached-type)
   (CodexRateLimitSnapshot
     $limit-id
     $limit-name
     $primary
     $secondary
     $credits
     $plan-type
     $rate-limit-reached-type))

(= (codex:rate-limit-snapshot-limit-id
      (CodexRateLimitSnapshot
        $limit-id
        $limit-name
        $primary
        $secondary
        $credits
        $plan-type
        $rate-limit-reached-type))
   $limit-id)

(= (codex:rate-limit-snapshot-limit-name
      (CodexRateLimitSnapshot
        $limit-id
        $limit-name
        $primary
        $secondary
        $credits
        $plan-type
        $rate-limit-reached-type))
   $limit-name)

(= (codex:rate-limit-snapshot-primary
      (CodexRateLimitSnapshot
        $limit-id
        $limit-name
        $primary
        $secondary
        $credits
        $plan-type
        $rate-limit-reached-type))
   $primary)

(= (codex:rate-limit-snapshot-secondary
      (CodexRateLimitSnapshot
        $limit-id
        $limit-name
        $primary
        $secondary
        $credits
        $plan-type
        $rate-limit-reached-type))
   $secondary)

(= (codex:rate-limit-snapshot-credits
      (CodexRateLimitSnapshot
        $limit-id
        $limit-name
        $primary
        $secondary
        $credits
        $plan-type
        $rate-limit-reached-type))
   $credits)

(= (codex:rate-limit-snapshot-plan-type
      (CodexRateLimitSnapshot
        $limit-id
        $limit-name
        $primary
        $secondary
        $credits
        $plan-type
        $rate-limit-reached-type))
   $plan-type)

(= (codex:rate-limit-snapshot-rate-limit-reached-type
      (CodexRateLimitSnapshot
        $limit-id
        $limit-name
        $primary
        $secondary
        $credits
        $plan-type
        $rate-limit-reached-type))
   $rate-limit-reached-type)

(= (codex:default-image-detail)
   "high")

(= (codex:image-open-tag-text)
   "<image>")

(= (codex:image-close-tag-text)
   "</image>")

(= (codex:local-image-label-text $label-number)
   (format-args "[Image #{}]" ($label-number)))

(= (codex:local-image-open-tag-text $label-number)
   (format-args
     "<image name={}>"
     ((codex:local-image-label-text $label-number))))

(= (codex:is-local-image-open-tag-text $text)
   (if (str-starts-with? $text "<image name=")
       (str-ends-with? $text ">")
       False))

(= (codex:is-local-image-close-tag-text $text)
   (codex:is-image-close-tag-text $text))

(= (codex:is-image-open-tag-text $text)
   (== $text (codex:image-open-tag-text)))

(= (codex:is-image-close-tag-text $text)
   (== $text (codex:image-close-tag-text)))

(= (codex:item-type (CodexResponseItemMessage $role $content $phase))
   "message")

(= (codex:item-type (CodexResponseItemMessageWithId $id $role $content $phase))
   "message")

(= (codex:item-type
      (CodexResponseItemReasoning $id $summary $content $encrypted-content))
   "reasoning")

(= (codex:item-type
      (CodexResponseItemFunctionCall $id $name $namespace $arguments $call_id))
   "function_call")

(= (codex:item-type (CodexResponseItemFunctionCallOutput $call_id $output))
   "function_call_output")

(= (codex:item-type (CodexResponseItemMcpToolCallOutput $call_id $output))
   "mcp_tool_call_output")

(= (codex:item-type (CodexResponseItemCustomToolCall $call_id $name $input))
   "custom_tool_call")

(= (codex:item-type
      (CodexResponseItemCustomToolCallOutput $call_id $name $output))
   "custom_tool_call_output")

(= (codex:item-type
      (CodexResponseItemToolSearchOutput
        $call_id
        $status
        $execution
        $tools))
   "tool_search_output")

(= (codex:item-type
      (CodexResponseItemWebSearchCall $id $status $action))
   "web_search_call")

(= (codex:item-type
      (CodexResponseItemImageGenerationCall
        $id
        $status
        $revised-prompt
        $result))
   "image_generation_call")

(= (codex:item-type
      (CodexEventExecCommandOutputDelta $call_id $stream $chunk))
   "exec_command_output_delta")

(= (codex:item-type
      (CodexEventTerminalInteraction $call_id $process_id $stdin))
   "terminal_interaction")

(= (codex:item-type
      (CodexEventAgentMessageDelta $delta))
   "agent_message_delta")

(= (codex:item-type
      (CodexEventAgentReasoning $text))
   "agent_reasoning")

(= (codex:item-type
      (CodexEventAgentReasoningRawContent $text))
   "agent_reasoning_raw_content")

(= (codex:item-type
      (CodexEventAgentReasoningRawContentDelta $delta))
   "agent_reasoning_raw_content_delta")

(= (codex:item-type
      (CodexEventAgentReasoningSectionBreak $item_id $summary_index))
   "agent_reasoning_section_break")

(= (codex:item-type
      (CodexEventAgentReasoningDelta $delta))
   "agent_reasoning_delta")

(= (codex:item-type
      (CodexEventMcpToolCallBegin $call_id $invocation $mcp_app_resource_uri))
   "mcp_tool_call_begin")

(= (codex:item-type
      (CodexEventMcpStartupUpdate $server $status))
   "mcp_startup_update")

(= (codex:item-type
      (CodexEventMcpStartupComplete $ready $failed $cancelled))
   "mcp_startup_complete")

(= (codex:item-type
      (CodexEventThreadNameUpdated $thread_id $thread_name))
   "thread_name_updated")

(= (codex:item-type
      (CodexEventThreadRolledBack $num_turns))
   "thread_rolled_back")

(= (codex:item-type
      (CodexEventWarning $message))
   "warning")

(= (codex:item-type
      (CodexEventGuardianWarning $message))
   "guardian_warning")

(= (codex:item-type
      (CodexEventModelReroute $from_model $to_model $reason))
   "model_reroute")

(= (codex:item-type
      (CodexEventContextCompacted))
   "context_compacted")

(= (codex:item-type
      (CodexEventWebSearchBegin $call_id))
   "web_search_begin")

(= (codex:item-type
      (CodexEventWebSearchEnd $call_id $query $action))
   "web_search_end")

(= (codex:item-type
      (CodexEventImageGenerationBegin $call_id))
   "image_generation_begin")

(= (codex:item-type
      (CodexEventImageGenerationEnd
        $call_id
        $status
        $revised-prompt
        $result
        $saved-path))
   "image_generation_end")

(= (codex:message-role (CodexResponseItemMessage $role $content $phase))
   $role)

(= (codex:message-role (CodexResponseItemMessageWithId $id $role $content $phase))
   $role)

(= (codex:message-phase (CodexResponseItemMessage $role $content $phase))
   (if (== $phase CodexAbsent) Empty $phase))

(= (codex:message-phase (CodexResponseItemMessageWithId $id $role $content $phase))
   (if (== $phase CodexAbsent) Empty $phase))

(= (codex:message-id (CodexResponseItemMessage $role $content $phase))
   Empty)

(= (codex:message-id (CodexResponseItemMessageWithId $id $role $content $phase))
   (if (== $id CodexAbsent) Empty $id))

(= (codex:tool-call-name (CodexResponseItemCustomToolCall $call_id $name $input))
   $name)

(= (codex:function-call-name
      (CodexResponseItemFunctionCall $id $name $namespace $arguments $call_id))
   $name)

(= (codex:function-call-namespace
      (CodexResponseItemFunctionCall $id $name $namespace $arguments $call_id))
   $namespace)

(= (codex:message-text
      (CodexResponseItemMessage $role ((CodexInputText $text)) $phase))
   $text)

(= (codex:message-text
      (CodexResponseItemMessageWithId $id $role ((CodexInputText $text)) $phase))
   $text)

(= (codex:message-text
      (CodexResponseItemMessage $role ((CodexOutputText $text)) $phase))
   $text)

(= (codex:message-text
      (CodexResponseItemMessageWithId $id $role ((CodexOutputText $text)) $phase))
   $text)

(= (codex:tool-result-output-text
      (CodexResponseItemCustomToolCallOutput
        $call_id
        $name
        (CodexFunctionCallOutputText $text)))
   $text)

(= (codex:tool-result-call-id
      (CodexResponseItemCustomToolCallOutput
        $call_id
        $name
        $output))
   $call_id)

(= (codex:mcp-tool-call-output-call-id
      (CodexResponseItemMcpToolCallOutput $call_id $output))
   $call_id)

(= (codex:mcp-tool-call-output-result
      (CodexResponseItemMcpToolCallOutput $call_id $output))
   $output)

(= (codex:tool-search-output-call-id
      (CodexResponseItemToolSearchOutput
        $call_id
        $status
        $execution
        $tools))
   $call_id)

(= (codex:tool-search-output-tools
      (CodexResponseItemToolSearchOutput
        $call_id
        $status
        $execution
        $tools))
   $tools)

(= (codex:exec-command-output-delta-call-id
      (CodexEventExecCommandOutputDelta $call_id $stream $chunk))
   $call_id)

(= (codex:exec-command-output-delta-stream
      (CodexEventExecCommandOutputDelta $call_id $stream $chunk))
   $stream)

(= (codex:exec-command-output-delta-chunk
      (CodexEventExecCommandOutputDelta $call_id $stream $chunk))
   $chunk)

(= (codex:terminal-interaction-call-id
      (CodexEventTerminalInteraction $call_id $process_id $stdin))
   $call_id)

(= (codex:terminal-interaction-process-id
      (CodexEventTerminalInteraction $call_id $process_id $stdin))
   $process_id)

(= (codex:terminal-interaction-stdin
      (CodexEventTerminalInteraction $call_id $process_id $stdin))
   $stdin)

(= (codex:agent-message-delta-text
      (CodexEventAgentMessageDelta $delta))
   $delta)

(= (codex:agent-reasoning-text
      (CodexEventAgentReasoning $text))
   $text)

(= (codex:agent-reasoning-raw-content-text
      (CodexEventAgentReasoningRawContent $text))
   $text)

(= (codex:agent-reasoning-raw-content-delta-text
      (CodexEventAgentReasoningRawContentDelta $delta))
   $delta)

(= (codex:agent-reasoning-section-break-item-id
      (CodexEventAgentReasoningSectionBreak $item_id $summary_index))
   $item_id)

(= (codex:agent-reasoning-section-break-summary-index
      (CodexEventAgentReasoningSectionBreak $item_id $summary_index))
   $summary_index)

(= (codex:agent-reasoning-delta-text
      (CodexEventAgentReasoningDelta $delta))
   $delta)

(= (codex:mcp-invocation-server
      (CodexMcpInvocation $server $tool $arguments))
   $server)

(= (codex:mcp-invocation-tool
      (CodexMcpInvocation $server $tool $arguments))
   $tool)

(= (codex:mcp-invocation-arguments
      (CodexMcpInvocation $server $tool $arguments))
   (if (== $arguments CodexAbsent) Empty $arguments))

(= (codex:mcp-tool-call-begin-call-id
      (CodexEventMcpToolCallBegin $call_id $invocation $mcp_app_resource_uri))
   $call_id)

(= (codex:mcp-tool-call-begin-invocation
      (CodexEventMcpToolCallBegin $call_id $invocation $mcp_app_resource_uri))
   $invocation)

(= (codex:mcp-tool-call-begin-mcp_app_resource_uri
      (CodexEventMcpToolCallBegin $call_id $invocation $mcp_app_resource_uri))
   (if (== $mcp_app_resource_uri CodexAbsent) Empty $mcp_app_resource_uri))

(= (codex:mcp-startup-status-error
      (CodexMcpStartupStatusFailed $error))
   $error)

(= (codex:mcp-startup-failure-server
      (CodexMcpStartupFailure $server $error))
   $server)

(= (codex:mcp-startup-failure-error
      (CodexMcpStartupFailure $server $error))
   $error)

(= (codex:mcp-startup-update-server
      (CodexEventMcpStartupUpdate $server $status))
   $server)

(= (codex:mcp-startup-update-status
      (CodexEventMcpStartupUpdate $server $status))
   $status)

(= (codex:mcp-startup-complete-ready
      (CodexEventMcpStartupComplete $ready $failed $cancelled))
   $ready)

(= (codex:mcp-startup-complete-failed
      (CodexEventMcpStartupComplete $ready $failed $cancelled))
   $failed)

(= (codex:mcp-startup-complete-cancelled
      (CodexEventMcpStartupComplete $ready $failed $cancelled))
   $cancelled)

(= (codex:thread-name-updated-thread-id
      (CodexEventThreadNameUpdated $thread_id $thread_name))
   $thread_id)

(= (codex:thread-name-updated-thread-name
      (CodexEventThreadNameUpdated $thread_id $thread_name))
   (if (== $thread_name CodexAbsent) Empty $thread_name))

(= (codex:thread-rolled-back-num-turns
      (CodexEventThreadRolledBack $num_turns))
   $num_turns)

(= (codex:warning-message
      (CodexEventWarning $message))
   $message)

(= (codex:guardian-warning-message
      (CodexEventGuardianWarning $message))
   $message)

(= (codex:model-reroute-from-model
      (CodexEventModelReroute $from_model $to_model $reason))
   $from_model)

(= (codex:model-reroute-to-model
      (CodexEventModelReroute $from_model $to_model $reason))
   $to_model)

(= (codex:model-reroute-reason
      (CodexEventModelReroute $from_model $to_model $reason))
   $reason)

(= (codex:web-search-begin-call-id
      (CodexEventWebSearchBegin $call_id))
   $call_id)

(= (codex:web-search-end-call-id
      (CodexEventWebSearchEnd $call_id $query $action))
   $call_id)

(= (codex:web-search-end-query
      (CodexEventWebSearchEnd $call_id $query $action))
   $query)

(= (codex:web-search-end-action
      (CodexEventWebSearchEnd $call_id $query $action))
   $action)

(= (codex:image-generation-begin-call-id
      (CodexEventImageGenerationBegin $call_id))
   $call_id)

(= (codex:image-generation-end-call-id
      (CodexEventImageGenerationEnd
        $call_id
        $status
        $revised-prompt
        $result
        $saved-path))
   $call_id)

(= (codex:image-generation-end-status
      (CodexEventImageGenerationEnd
        $call_id
        $status
        $revised-prompt
        $result
        $saved-path))
   $status)

(= (codex:image-generation-end-revised-prompt
      (CodexEventImageGenerationEnd
        $call_id
        $status
        $revised-prompt
        $result
        $saved-path))
   (if (== $revised-prompt CodexAbsent) Empty $revised-prompt))

(= (codex:image-generation-end-result
      (CodexEventImageGenerationEnd
        $call_id
        $status
        $revised-prompt
        $result
        $saved-path))
   $result)

(= (codex:image-generation-end-saved-path
      (CodexEventImageGenerationEnd
        $call_id
        $status
        $revised-prompt
        $result
        $saved-path))
   (if (== $saved-path CodexAbsent) Empty $saved-path))

(= (codex:web-search-action-json
      (CodexWebSearchActionSearch $query $queries))
   (JsonObject
     ((JsonPair "type" (JsonString "search"))
      (JsonPair "query" (JsonString $query))
      (JsonPair "queries" (JsonArray (map-atom $queries $item (JsonString $item)))))))

(= (codex:web-search-action-json
      (CodexWebSearchActionOpenPage $url))
   (JsonObject
     ((JsonPair "type" (JsonString "open_page"))
      (JsonPair "url" (JsonString $url)))))

(= (codex:web-search-action-json
      (CodexWebSearchActionFindInPage $url $pattern))
   (JsonObject
     ((JsonPair "type" (JsonString "find_in_page"))
      (JsonPair "url" (JsonString $url))
      (JsonPair "pattern" (JsonString $pattern)))))

(= (codex:web-search-action-json
      (CodexWebSearchActionOther))
   (JsonObject
     ((JsonPair "type" (JsonString "other")))))

(= (codex:mcp-invocation-json
      (CodexMcpInvocation $server $tool $arguments))
   (if (== $arguments CodexAbsent)
       (JsonObject
         ((JsonPair "server" (JsonString $server))
          (JsonPair "tool" (JsonString $tool))))
       (JsonObject
         ((JsonPair "server" (JsonString $server))
          (JsonPair "tool" (JsonString $tool))
          (JsonPair "arguments" $arguments)))))

(= (codex:mcp-startup-status-json
      (CodexMcpStartupStatusStarting))
   (JsonObject
     ((JsonPair "state" (JsonString "starting")))))

(= (codex:mcp-startup-status-json
      (CodexMcpStartupStatusReady))
   (JsonObject
     ((JsonPair "state" (JsonString "ready")))))

(= (codex:mcp-startup-status-json
      (CodexMcpStartupStatusFailed $error))
   (JsonObject
     ((JsonPair "state" (JsonString "failed"))
      (JsonPair "error" (JsonString $error)))))

(= (codex:mcp-startup-status-json
      (CodexMcpStartupStatusCancelled))
   (JsonObject
     ((JsonPair "state" (JsonString "cancelled")))))

(= (codex:mcp-startup-failure-json
      (CodexMcpStartupFailure $server $error))
   (JsonObject
     ((JsonPair "server" (JsonString $server))
      (JsonPair "error" (JsonString $error)))))

(= (codex:model-reroute-reason-json
      (CodexModelRerouteReasonHighRiskCyberActivity))
   (JsonString "high_risk_cyber_activity"))

(= (codex:content-item-json (CodexInputText $text))
   (JsonObject
     ((JsonPair "type" (JsonString "input_text"))
      (JsonPair "text" (JsonString $text)))))

(= (codex:content-item-json (CodexInputImage $image_url $detail))
   (if (== $detail CodexAbsent)
       (JsonObject
         ((JsonPair "type" (JsonString "input_image"))
          (JsonPair "image_url" (JsonString $image_url))))
       (JsonObject
         ((JsonPair "type" (JsonString "input_image"))
          (JsonPair "image_url" (JsonString $image_url))
          (JsonPair "detail" (JsonString $detail))))))

(= (codex:content-item-json (CodexOutputText $text))
   (JsonObject
     ((JsonPair "type" (JsonString "output_text"))
      (JsonPair "text" (JsonString $text)))))

(= (codex:content-json $items)
   (function
     (let $json-items (eval (map-atom $items $item (codex:content-item-json $item)))
       (return (JsonArray $json-items)))))

(= (codex:output-json (CodexFunctionCallOutputText $text))
   (JsonString $text))

(= (codex:output-json (CodexFunctionCallOutputContentItems $items))
   (codex:content-json $items))

(= (codex:item-json (CodexResponseItemMessage $role $content $phase))
   (if (== $phase CodexAbsent)
       (JsonObject
         ((JsonPair "type" (JsonString "message"))
          (JsonPair "role" (JsonString $role))
          (JsonPair "content" (codex:content-json $content))))
       (JsonObject
         ((JsonPair "type" (JsonString "message"))
         (JsonPair "role" (JsonString $role))
         (JsonPair "content" (codex:content-json $content))
         (JsonPair "phase" (JsonString $phase))))))

(= (codex:item-json
      (CodexResponseItemFunctionCall $id $name $namespace $arguments $call_id))
   (if (== $namespace CodexAbsent)
       (if (== $id CodexAbsent)
           (JsonObject
             ((JsonPair "type" (JsonString "function_call"))
              (JsonPair "name" (JsonString $name))
              (JsonPair "arguments" (JsonString $arguments))
              (JsonPair "call_id" (JsonString $call_id))))
           (JsonObject
             ((JsonPair "type" (JsonString "function_call"))
              (JsonPair "id" (JsonString $id))
              (JsonPair "name" (JsonString $name))
              (JsonPair "arguments" (JsonString $arguments))
              (JsonPair "call_id" (JsonString $call_id)))))
       (if (== $id CodexAbsent)
           (JsonObject
             ((JsonPair "type" (JsonString "function_call"))
              (JsonPair "name" (JsonString $name))
              (JsonPair "namespace" (JsonString $namespace))
              (JsonPair "arguments" (JsonString $arguments))
              (JsonPair "call_id" (JsonString $call_id))))
           (JsonObject
             ((JsonPair "type" (JsonString "function_call"))
              (JsonPair "id" (JsonString $id))
              (JsonPair "name" (JsonString $name))
              (JsonPair "namespace" (JsonString $namespace))
              (JsonPair "arguments" (JsonString $arguments))
              (JsonPair "call_id" (JsonString $call_id)))))))

(= (codex:item-json (CodexResponseItemFunctionCallOutput $call_id $output))
   (JsonObject
     ((JsonPair "type" (JsonString "function_call_output"))
      (JsonPair "call_id" (JsonString $call_id))
      (JsonPair "output" (codex:output-json $output)))))

(= (codex:item-json (CodexResponseItemMcpToolCallOutput $call_id $output))
   (JsonObject
     ((JsonPair "type" (JsonString "mcp_tool_call_output"))
      (JsonPair "call_id" (JsonString $call_id))
      (JsonPair "output" $output))))

(= (codex:item-json (CodexResponseItemCustomToolCall $call_id $name $input))
   (JsonObject
     ((JsonPair "type" (JsonString "custom_tool_call"))
      (JsonPair "call_id" (JsonString $call_id))
      (JsonPair "name" (JsonString $name))
      (JsonPair "input" (JsonString $input)))))

(= (codex:item-json
      (CodexResponseItemCustomToolCallOutput
        $call_id
        $name
        $output))
   (if (== $name CodexAbsent)
       (JsonObject
         ((JsonPair "type" (JsonString "custom_tool_call_output"))
          (JsonPair "call_id" (JsonString $call_id))
          (JsonPair "output" (codex:output-json $output))))
       (JsonObject
         ((JsonPair "type" (JsonString "custom_tool_call_output"))
          (JsonPair "call_id" (JsonString $call_id))
         (JsonPair "name" (JsonString $name))
         (JsonPair "output" (codex:output-json $output))))))

(= (codex:item-json
      (CodexResponseItemToolSearchOutput
        $call_id
        $status
        $execution
        $tools))
   (JsonObject
     ((JsonPair "type" (JsonString "tool_search_output"))
      (JsonPair "call_id" (JsonString $call_id))
      (JsonPair "status" (JsonString $status))
      (JsonPair "execution" (JsonString $execution))
      (JsonPair "tools" (JsonArray $tools)))))

(= (codex:item-json
      (CodexEventExecCommandOutputDelta $call_id $stream $chunk))
   (JsonObject
     ((JsonPair "type" (JsonString "exec_command_output_delta"))
      (JsonPair "call_id" (JsonString $call_id))
      (JsonPair "stream" (JsonString $stream))
      (JsonPair "chunk" (JsonString (str-base64-encode $chunk))))))

(= (codex:item-json
      (CodexEventTerminalInteraction $call_id $process_id $stdin))
   (JsonObject
     ((JsonPair "type" (JsonString "terminal_interaction"))
      (JsonPair "call_id" (JsonString $call_id))
      (JsonPair "process_id" (JsonString $process_id))
      (JsonPair "stdin" (JsonString $stdin)))))

(= (codex:item-json
      (CodexEventAgentMessageDelta $delta))
   (JsonObject
     ((JsonPair "type" (JsonString "agent_message_delta"))
      (JsonPair "delta" (JsonString $delta)))))

(= (codex:item-json
      (CodexEventAgentReasoning $text))
   (JsonObject
     ((JsonPair "type" (JsonString "agent_reasoning"))
      (JsonPair "text" (JsonString $text)))))

(= (codex:item-json
      (CodexEventAgentReasoningRawContent $text))
   (JsonObject
     ((JsonPair "type" (JsonString "agent_reasoning_raw_content"))
      (JsonPair "text" (JsonString $text)))))

(= (codex:item-json
      (CodexEventAgentReasoningRawContentDelta $delta))
   (JsonObject
     ((JsonPair "type" (JsonString "agent_reasoning_raw_content_delta"))
      (JsonPair "delta" (JsonString $delta)))))

(= (codex:item-json
      (CodexEventAgentReasoningSectionBreak $item_id $summary_index))
   (JsonObject
     ((JsonPair "type" (JsonString "agent_reasoning_section_break"))
      (JsonPair "item_id" (JsonString $item_id))
      (JsonPair "summary_index" (JsonNumber $summary_index)))))

(= (codex:item-json
      (CodexEventAgentReasoningDelta $delta))
   (JsonObject
     ((JsonPair "type" (JsonString "agent_reasoning_delta"))
      (JsonPair "delta" (JsonString $delta)))))

(= (codex:item-json
      (CodexEventMcpToolCallBegin $call_id $invocation $mcp_app_resource_uri))
   (if (== $mcp_app_resource_uri CodexAbsent)
       (JsonObject
         ((JsonPair "type" (JsonString "mcp_tool_call_begin"))
          (JsonPair "call_id" (JsonString $call_id))
          (JsonPair "invocation" (codex:mcp-invocation-json $invocation))))
       (JsonObject
         ((JsonPair "type" (JsonString "mcp_tool_call_begin"))
          (JsonPair "call_id" (JsonString $call_id))
         (JsonPair "invocation" (codex:mcp-invocation-json $invocation))
         (JsonPair "mcp_app_resource_uri" (JsonString $mcp_app_resource_uri))))))

(= (codex:item-json
      (CodexEventMcpStartupUpdate $server $status))
   (JsonObject
     ((JsonPair "type" (JsonString "mcp_startup_update"))
      (JsonPair "server" (JsonString $server))
      (JsonPair "status" (codex:mcp-startup-status-json $status)))))

(= (codex:item-json
      (CodexEventMcpStartupComplete $ready $failed $cancelled))
   (JsonObject
     ((JsonPair "type" (JsonString "mcp_startup_complete"))
      (JsonPair "ready" (JsonArray (map-atom $ready $item (JsonString $item))))
      (JsonPair
        "failed"
        (JsonArray (map-atom $failed $item (codex:mcp-startup-failure-json $item))))
      (JsonPair
        "cancelled"
        (JsonArray (map-atom $cancelled $item (JsonString $item)))))))

(= (codex:item-json
      (CodexEventThreadNameUpdated $thread_id $thread_name))
   (if (== $thread_name CodexAbsent)
       (JsonObject
         ((JsonPair "type" (JsonString "thread_name_updated"))
          (JsonPair "thread_id" (JsonString $thread_id))))
       (JsonObject
         ((JsonPair "type" (JsonString "thread_name_updated"))
          (JsonPair "thread_id" (JsonString $thread_id))
          (JsonPair "thread_name" (JsonString $thread_name))))))

(= (codex:item-json
      (CodexEventThreadRolledBack $num_turns))
   (JsonObject
     ((JsonPair "type" (JsonString "thread_rolled_back"))
      (JsonPair "num_turns" (JsonNumber $num_turns)))))

(= (codex:item-json
      (CodexEventWarning $message))
   (JsonObject
     ((JsonPair "type" (JsonString "warning"))
      (JsonPair "message" (JsonString $message)))))

(= (codex:item-json
      (CodexEventGuardianWarning $message))
   (JsonObject
     ((JsonPair "type" (JsonString "guardian_warning"))
      (JsonPair "message" (JsonString $message)))))

(= (codex:item-json
      (CodexEventModelReroute $from_model $to_model $reason))
   (JsonObject
     ((JsonPair "type" (JsonString "model_reroute"))
      (JsonPair "from_model" (JsonString $from_model))
      (JsonPair "to_model" (JsonString $to_model))
      (JsonPair "reason" (codex:model-reroute-reason-json $reason)))))

(= (codex:item-json
      (CodexEventContextCompacted))
   (JsonObject
     ((JsonPair "type" (JsonString "context_compacted")))))

(= (codex:item-json
      (CodexEventWebSearchBegin $call_id))
   (JsonObject
     ((JsonPair "type" (JsonString "web_search_begin"))
      (JsonPair "call_id" (JsonString $call_id)))))

(= (codex:item-json
      (CodexEventWebSearchEnd $call_id $query $action))
   (JsonObject
     ((JsonPair "type" (JsonString "web_search_end"))
      (JsonPair "call_id" (JsonString $call_id))
      (JsonPair "query" (JsonString $query))
      (JsonPair "action" (codex:web-search-action-json $action)))))

(= (codex:item-json
      (CodexEventImageGenerationBegin $call_id))
   (JsonObject
     ((JsonPair "type" (JsonString "image_generation_begin"))
      (JsonPair "call_id" (JsonString $call_id)))))

(= (codex:item-json
      (CodexEventImageGenerationEnd
        $call_id
        $status
        $revised-prompt
        $result
        $saved-path))
   (if (== $revised-prompt CodexAbsent)
       (if (== $saved-path CodexAbsent)
           (JsonObject
             ((JsonPair "type" (JsonString "image_generation_end"))
              (JsonPair "call_id" (JsonString $call_id))
              (JsonPair "status" (JsonString $status))
              (JsonPair "result" (JsonString $result))))
           (JsonObject
             ((JsonPair "type" (JsonString "image_generation_end"))
              (JsonPair "call_id" (JsonString $call_id))
              (JsonPair "status" (JsonString $status))
              (JsonPair "result" (JsonString $result))
              (JsonPair "saved_path" (JsonString $saved-path)))))
       (if (== $saved-path CodexAbsent)
           (JsonObject
             ((JsonPair "type" (JsonString "image_generation_end"))
              (JsonPair "call_id" (JsonString $call_id))
              (JsonPair "status" (JsonString $status))
              (JsonPair "revised_prompt" (JsonString $revised-prompt))
              (JsonPair "result" (JsonString $result))))
           (JsonObject
             ((JsonPair "type" (JsonString "image_generation_end"))
              (JsonPair "call_id" (JsonString $call_id))
              (JsonPair "status" (JsonString $status))
              (JsonPair "revised_prompt" (JsonString $revised-prompt))
              (JsonPair "result" (JsonString $result))
              (JsonPair "saved_path" (JsonString $saved-path)))))))

(= (codex:items-json $items)
   (function
     (let $json-items (eval (map-atom $items $item (codex:item-json $item)))
       (return (JsonArray $json-items)))))
