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
; - ModelVerificationEvent
; - TurnStartedEvent
; - TurnCompleteEvent / TokenCountEvent / StreamInfoEvent
; - AgentMessageEvent / UserMessageEvent
; - ViewImageToolCallEvent / BackgroundEventEvent / DeprecationNoticeEvent
; - SkillsUpdateAvailable / ShutdownComplete
; - PlanUpdate(UpdatePlanArgs)
; - TurnAbortedEvent
; - StreamErrorEvent / CodexErrorInfo / NonSteerableTurnKind
; - ErrorEvent / RawResponseItemEvent
; - AgentMessageContentDeltaEvent / PlanDeltaEvent /
;   ReasoningContentDeltaEvent / ReasoningRawContentDeltaEvent
; - EnteredReviewMode(ReviewRequest) / ReviewTarget
; - ExitedReviewModeEvent / ReviewOutputEvent JSON projection
; - TurnDiffEvent
; - GetHistoryEntryResponseEvent / HistoryEntry
; - ListSkillsResponseEvent / SkillsListEntry / SkillMetadata
; - RealtimeConversationStarted/Realtime/Closed/Sdp / RealtimeVoice
; - RealtimeAudioFrame / RealtimeEvent::AudioOut
; - Op::RealtimeConversationStart/Audio/Text/Close/ListVoices
; - Submission / W3cTraceContext / Event queue wrappers
; - Op::AddToHistory / GetHistoryEntryRequest / ListMcpTools
; - Op::RefreshMcpServers / ReloadUserConfig / ListSkills / McpServerRefreshConfig
; - CompactedItem / TurnContextNetworkItem / TruncationPolicy
; - Product
; - SessionSource / SubAgentSource
; - SessionConfiguredEvent / SessionNetworkProxyRuntime
; - ExecPolicyAmendment / ReviewDecision
; - FileChange / Chunk
; - CollabAgent* events / protocol-local AgentStatus JSON
; - PatchApplyBeginEvent / PatchApplyUpdatedEvent / PatchApplyEndEvent
; - HookStartedEvent / HookCompletedEvent / HookRunSummary
; - UndoStartedEvent / UndoCompletedEvent
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
; Rust uses `Result<SessionSource, &'static str>` and `Option<...>` in the
; `SessionSource` helper tranche. This slice preserves the same visible
; success/error/absence behavior through explicit `CodexSessionSourceOk`,
; `CodexSessionSourceErr`, and `CodexAbsent`.
;
; Rust models `RealtimeEvent::ConversationItemAdded` as `serde_json::Value`.
; This slice carries that payload directly as the same JSON atom supplied by
; callers so the visible wire shape remains unchanged.
;
; Rust models `ConversationStartParams.prompt` as `Option<Option<String>>`.
; This slice preserves the same visible wire behavior by using `CodexAbsent`
; for the outer `None` (omit the field) and `JsonNull` for the inner `None`
; (`"prompt": null`).
;
; `Submission.op` and `Event.msg` remain generic in Rust. This restart subset
; projects those wrappers through the currently ported `op-json` and `item-json`
; surfaces, preserving the same visible queue-envelope JSON for the supported
; subset.
;
; Rust represents `PatchApply*Event.changes` as `HashMap<PathBuf, FileChange>`.
; This CeTTa slice models the same visible payload as an ordered list of keyed
; entries and projects it back to the Rust JSON object shape at serialization.
;
; Rust also represents `CollabWaitingEndEvent.statuses` as
; `HashMap<ThreadId, AgentStatus>`. This CeTTa slice uses the same ordered-list
; projection approach there so the visible JSON object shape remains identical.
;
; This restart subset does not yet port `account::PlanType`, so the
; `RateLimitSnapshot.plan_type` field is currently carried through as the same
; visible raw value/string supplied by callers.
;
; The unified-exec delta event stores raw bytes in Rust and serializes them as
; base64. The current CeTTa surface therefore models the event payload as text
; whose current byte sequence is base64-encoded at JSON projection time.
;
; CeTTa deviation: the `SessionConfiguredEvent.permission_profile` helper
; surface below carries the Rust-visible JSON payload directly instead of
; fully porting the nested `permissions.rs` filesystem-entry record tranche in
; the same increment. This preserves the exact wire shape for the restarted
; `session_configured` event while that lower slice is still pending.

!(import! &self json)
!(import! &self list)
!(import! &self str)
!(import! &self agent_path)

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

(= (codex:message-phase-commentary)
   (CodexMessagePhaseCommentary))

(= (codex:message-phase-final-answer)
   (CodexMessagePhaseFinalAnswer))

(= (codex:memory-citation-entry $path $line-start $line-end $note)
   (CodexMemoryCitationEntry $path $line-start $line-end $note))

(= (codex:memory-citation $entries $rollout-ids)
   (CodexMemoryCitation $entries $rollout-ids))

(= (codex:byte-range $start $end)
   (CodexByteRange $start $end))

(= (codex:text-element $byte-range $placeholder)
   (CodexTextElement $byte-range $placeholder))

(= (codex:agent-message-event $message $phase $memory-citation)
   (CodexEventAgentMessage $message $phase $memory-citation))

(= (codex:user-message-event
      $message
      $images
      $local-images
      $text-elements)
   (CodexEventUserMessage
     $message
     $images
     $local-images
     $text-elements))

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

(= (codex:exec-policy-amendment $command)
   (CodexExecPolicyAmendment $command))

(= (codex:review-decision-approved)
   (CodexReviewDecisionApproved))

(= (codex:review-decision-approved-execpolicy-amendment $proposed-execpolicy-amendment)
   (CodexReviewDecisionApprovedExecpolicyAmendment
     $proposed-execpolicy-amendment))

(= (codex:review-decision-approved-for-session)
   (CodexReviewDecisionApprovedForSession))

(= (codex:review-decision-network-policy-amendment $network-policy-amendment)
   (CodexReviewDecisionNetworkPolicyAmendment $network-policy-amendment))

(= (codex:review-decision-denied)
   (CodexReviewDecisionDenied))

(= (codex:review-decision-timed-out)
   (CodexReviewDecisionTimedOut))

(= (codex:review-decision-abort)
   (CodexReviewDecisionAbort))

(= (codex:file-change-add $content)
   (CodexFileChangeAdd $content))

(= (codex:file-change-delete $content)
   (CodexFileChangeDelete $content))

(= (codex:file-change-update $unified-diff $move-path)
   (CodexFileChangeUpdate $unified-diff $move-path))

(= (codex:chunk $orig-index $deleted-lines $inserted-lines)
   (CodexChunk $orig-index $deleted-lines $inserted-lines))

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

(= (codex:model-verification-trusted-access-for-cyber)
   (CodexModelVerificationTrustedAccessForCyber))

(= (codex:model-verification-event $verifications)
   (CodexEventModelVerification $verifications))

(= (codex:mode-kind-plan)
   (CodexModeKindPlan))

(= (codex:mode-kind-default)
   (CodexModeKindDefault))

(= (codex:turn-started-event
      $turn_id
      $started_at
      $model_context_window
      $collaboration_mode_kind)
   (CodexEventTurnStarted
     $turn_id
     $started_at
     $model_context_window
     $collaboration_mode_kind))

(= (codex:context-compacted-event)
   (CodexEventContextCompacted))

(= (codex:turn-complete-event
      $turn_id
      $last_agent_message
      $completed_at
      $duration_ms
      $time_to_first_token_ms)
   (CodexEventTurnComplete
     $turn_id
     $last_agent_message
     $completed_at
     $duration_ms
     $time_to_first_token_ms))

(= (codex:stream-info-event $message)
   (CodexEventStreamInfo $message))

(= (codex:undo-started-event $message)
   (CodexEventUndoStarted $message))

(= (codex:undo-completed-event $success $message)
   (CodexEventUndoCompleted $success $message))

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

(= (codex:view-image-tool-call-event $call_id $path)
   (CodexEventViewImageToolCall $call_id $path))

(= (codex:background-event-event $message)
   (CodexEventBackgroundEvent $message))

(= (codex:deprecation-notice-event $summary $details)
   (CodexEventDeprecationNotice $summary $details))

(= (codex:skills-update-available-event)
   (CodexEventSkillsUpdateAvailable))

(= (codex:shutdown-complete-event)
   (CodexEventShutdownComplete))

(= (codex:plan-update-event $explanation $plan)
   (CodexUpdatePlanArgs $explanation $plan))

(= (codex:turn-abort-reason-interrupted)
   (CodexTurnAbortReasonInterrupted))

(= (codex:turn-abort-reason-replaced)
   (CodexTurnAbortReasonReplaced))

(= (codex:turn-abort-reason-review-ended)
   (CodexTurnAbortReasonReviewEnded))

(= (codex:turn-aborted-event $turn-id $reason $completed-at $duration-ms)
   (CodexEventTurnAborted $turn-id $reason $completed-at $duration-ms))

(= (codex:protocol-agent-status-pending-init)
   (CodexProtocolAgentStatusPendingInit))

(= (codex:protocol-agent-status-running)
   (CodexProtocolAgentStatusRunning))

(= (codex:protocol-agent-status-interrupted)
   (CodexProtocolAgentStatusInterrupted))

(= (codex:protocol-agent-status-completed $message)
   (CodexProtocolAgentStatusCompleted $message))

(= (codex:protocol-agent-status-errored $message)
   (CodexProtocolAgentStatusErrored $message))

(= (codex:protocol-agent-status-shutdown)
   (CodexProtocolAgentStatusShutdown))

(= (codex:protocol-agent-status-not-found)
   (CodexProtocolAgentStatusNotFound))

(= (codex:collab-agent-ref $thread-id $agent-nickname $agent-role)
   (CodexCollabAgentRef $thread-id $agent-nickname $agent-role))

(= (codex:collab-agent-status-entry
      $thread-id
      $agent-nickname
      $agent-role
      $status)
   (CodexCollabAgentStatusEntry
     $thread-id
     $agent-nickname
     $agent-role
     $status))

(= (codex:collab-waiting-status-entry $thread-id $status)
   (CodexCollabWaitingStatusEntry $thread-id $status))

(= (codex:collab-agent-spawn-begin-event
      $call-id
      $sender-thread-id
      $prompt
      $model
      $reasoning-effort)
   (CodexEventCollabAgentSpawnBegin
     $call-id
     $sender-thread-id
     $prompt
     $model
     $reasoning-effort))

(= (codex:collab-agent-spawn-end-event
      $call-id
      $sender-thread-id
      $new-thread-id
      $new-agent-nickname
      $new-agent-role
      $prompt
      $model
      $reasoning-effort
      $status)
   (CodexEventCollabAgentSpawnEnd
     $call-id
     $sender-thread-id
     $new-thread-id
     $new-agent-nickname
     $new-agent-role
     $prompt
     $model
     $reasoning-effort
     $status))

(= (codex:collab-agent-interaction-begin-event
      $call-id
      $sender-thread-id
      $receiver-thread-id
      $prompt)
   (CodexEventCollabAgentInteractionBegin
     $call-id
     $sender-thread-id
     $receiver-thread-id
     $prompt))

(= (codex:collab-agent-interaction-end-event
      $call-id
      $sender-thread-id
      $receiver-thread-id
      $receiver-agent-nickname
      $receiver-agent-role
      $prompt
      $status)
   (CodexEventCollabAgentInteractionEnd
     $call-id
     $sender-thread-id
     $receiver-thread-id
     $receiver-agent-nickname
     $receiver-agent-role
     $prompt
     $status))

(= (codex:collab-waiting-begin-event
      $sender-thread-id
      $receiver-thread-ids
      $receiver-agents
      $call-id)
   (CodexEventCollabWaitingBegin
     $sender-thread-id
     $receiver-thread-ids
     $receiver-agents
     $call-id))

(= (codex:collab-waiting-end-event
      $sender-thread-id
      $call-id
      $agent-statuses
      $statuses)
   (CodexEventCollabWaitingEnd
     $sender-thread-id
     $call-id
     $agent-statuses
     $statuses))

(= (codex:collab-close-begin-event
      $call-id
      $sender-thread-id
      $receiver-thread-id)
   (CodexEventCollabCloseBegin
     $call-id
     $sender-thread-id
     $receiver-thread-id))

(= (codex:collab-close-end-event
      $call-id
      $sender-thread-id
      $receiver-thread-id
      $receiver-agent-nickname
      $receiver-agent-role
      $status)
   (CodexEventCollabCloseEnd
     $call-id
     $sender-thread-id
     $receiver-thread-id
     $receiver-agent-nickname
     $receiver-agent-role
     $status))

(= (codex:collab-resume-begin-event
      $call-id
      $sender-thread-id
      $receiver-thread-id
      $receiver-agent-nickname
      $receiver-agent-role)
   (CodexEventCollabResumeBegin
     $call-id
     $sender-thread-id
     $receiver-thread-id
     $receiver-agent-nickname
     $receiver-agent-role))

(= (codex:collab-resume-end-event
      $call-id
      $sender-thread-id
      $receiver-thread-id
      $receiver-agent-nickname
      $receiver-agent-role
      $status)
   (CodexEventCollabResumeEnd
     $call-id
     $sender-thread-id
     $receiver-thread-id
     $receiver-agent-nickname
     $receiver-agent-role
     $status))

(= (codex:non-steerable-turn-kind-review)
   (CodexNonSteerableTurnKindReview))

(= (codex:non-steerable-turn-kind-compact)
   (CodexNonSteerableTurnKindCompact))

(= (codex:codex-error-info-context-window-exceeded)
   (CodexErrorInfoContextWindowExceeded))

(= (codex:codex-error-info-usage-limit-exceeded)
   (CodexErrorInfoUsageLimitExceeded))

(= (codex:codex-error-info-server-overloaded)
   (CodexErrorInfoServerOverloaded))

(= (codex:codex-error-info-cyber-policy)
   (CodexErrorInfoCyberPolicy))

(= (codex:codex-error-info-http-connection-failed $http-status-code)
   (CodexErrorInfoHttpConnectionFailed $http-status-code))

(= (codex:codex-error-info-response-stream-connection-failed $http-status-code)
   (CodexErrorInfoResponseStreamConnectionFailed $http-status-code))

(= (codex:codex-error-info-internal-server-error)
   (CodexErrorInfoInternalServerError))

(= (codex:codex-error-info-unauthorized)
   (CodexErrorInfoUnauthorized))

(= (codex:codex-error-info-bad-request)
   (CodexErrorInfoBadRequest))

(= (codex:codex-error-info-sandbox-error)
   (CodexErrorInfoSandboxError))

(= (codex:codex-error-info-response-stream-disconnected $http-status-code)
   (CodexErrorInfoResponseStreamDisconnected $http-status-code))

(= (codex:codex-error-info-response-too-many-failed-attempts $http-status-code)
   (CodexErrorInfoResponseTooManyFailedAttempts $http-status-code))

(= (codex:codex-error-info-active-turn-not-steerable $turn-kind)
   (CodexErrorInfoActiveTurnNotSteerable $turn-kind))

(= (codex:codex-error-info-thread-rollback-failed)
   (CodexErrorInfoThreadRollbackFailed))

(= (codex:codex-error-info-other)
   (CodexErrorInfoOther))

(= (codex:stream-error-event $message $codex-error-info $additional-details)
   (CodexEventStreamError $message $codex-error-info $additional-details))

(= (codex:error-event $message $codex-error-info)
   (CodexEventError $message $codex-error-info))

(= (codex:raw-response-item-event $item)
   (CodexEventRawResponseItem $item))

(= (codex:agent-message-content-delta-event
      $thread-id
      $turn-id
      $item-id
      $delta)
   (CodexEventAgentMessageContentDelta
     $thread-id
     $turn-id
     $item-id
     $delta))

(= (codex:plan-delta-event
      $thread-id
      $turn-id
      $item-id
      $delta)
   (CodexEventPlanDelta
     $thread-id
     $turn-id
     $item-id
     $delta))

(= (codex:reasoning-content-delta-event
      $thread-id
      $turn-id
      $item-id
      $delta
      $summary-index)
   (CodexEventReasoningContentDelta
     $thread-id
     $turn-id
     $item-id
     $delta
     $summary-index))

(= (codex:reasoning-raw-content-delta-event
      $thread-id
      $turn-id
      $item-id
      $delta
      $content-index)
   (CodexEventReasoningRawContentDelta
     $thread-id
     $turn-id
     $item-id
     $delta
     $content-index))

(= (codex:exited-review-mode-event $review-output)
   (CodexEventExitedReviewMode $review-output))

(= (codex:review-target-uncommitted-changes)
   (CodexReviewTargetUncommittedChanges))

(= (codex:review-target-base-branch $branch)
   (CodexReviewTargetBaseBranch $branch))

(= (codex:review-target-commit $sha $title)
   (CodexReviewTargetCommit $sha $title))

(= (codex:review-target-custom $instructions)
   (CodexReviewTargetCustom $instructions))

(= (codex:review-request $target $user-facing-hint)
   (CodexReviewRequest $target $user-facing-hint))

(= (codex:entered-review-mode-event $review-request)
   (CodexEventEnteredReviewMode $review-request))

(= (codex:turn-diff-event $unified-diff)
   (CodexEventTurnDiff $unified-diff))

(= (codex:history-entry $conversation-id $ts $text)
   (CodexHistoryEntry $conversation-id $ts $text))

(= (codex:get-history-entry-response-event $offset $log-id $entry)
   (CodexEventGetHistoryEntryResponse $offset $log-id $entry))

; CeTTa deviation: Rust uses `PathBuf`/`AbsolutePathBuf` for skill paths and
; cwd. This protocol layer carries the same visible wire values as strings.
(= (codex:skill-scope-user)
   (CodexSkillScopeUser))

(= (codex:skill-scope-repo)
   (CodexSkillScopeRepo))

(= (codex:skill-scope-system)
   (CodexSkillScopeSystem))

(= (codex:skill-scope-admin)
   (CodexSkillScopeAdmin))

(= (codex:skill-interface
      $display-name
      $short-description
      $icon-small
      $icon-large
      $brand-color
      $default-prompt)
   (CodexSkillInterface
     $display-name
     $short-description
     $icon-small
     $icon-large
     $brand-color
     $default-prompt))

(= (codex:skill-tool-dependency
      $type
      $value
      $description
      $transport
      $command
      $url)
   (CodexSkillToolDependency
     $type
     $value
     $description
     $transport
     $command
     $url))

(= (codex:skill-dependencies $tools)
   (CodexSkillDependencies $tools))

(= (codex:skill-metadata
      $name
      $description
      $short-description
      $interface
      $dependencies
      $path
      $scope
      $enabled)
   (CodexSkillMetadata
     $name
     $description
     $short-description
     $interface
     $dependencies
     $path
     $scope
     $enabled))

(= (codex:skill-error-info $path $message)
   (CodexSkillErrorInfo $path $message))

(= (codex:skills-list-entry $cwd $skills $errors)
   (CodexSkillsListEntry $cwd $skills $errors))

(= (codex:list-skills-response-event $skills)
   (CodexEventListSkillsResponse $skills))

; CeTTa deviation: Rust uses `Vec<PathBuf>` for `ListSkills.cwds`; this slice
; carries the same visible JSON path strings directly.
(= (codex:list-skills-op $cwds $force-reload)
   (CodexOpListSkills $cwds $force-reload))

(= (codex:w3c-trace-context $traceparent $tracestate)
   (CodexW3cTraceContext $traceparent $tracestate))

(= (codex:submission $id $op $trace)
   (CodexSubmission $id $op $trace))

(= (codex:event-envelope $id $msg)
   (CodexProtocolEvent $id $msg))

(= (codex:mcp-server-refresh-config
      $mcp-servers
      $mcp-oauth-credentials-store-mode)
   (CodexMcpServerRefreshConfig
     $mcp-servers
     $mcp-oauth-credentials-store-mode))

(= (codex:add-to-history-op $text)
   (CodexOpAddToHistory $text))

(= (codex:get-history-entry-request-op $offset $log-id)
   (CodexOpGetHistoryEntryRequest $offset $log-id))

(= (codex:list-mcp-tools-op)
   (CodexOpListMcpTools))

(= (codex:refresh-mcp-servers-op $config)
   (CodexOpRefreshMcpServers $config))

(= (codex:reload-user-config-op)
   (CodexOpReloadUserConfig))

(= (codex:realtime-conversation-version-v1)
   (CodexRealtimeConversationVersionV1))

(= (codex:realtime-conversation-version-v2)
   (CodexRealtimeConversationVersionV2))

(= (codex:realtime-output-modality-text)
   (CodexRealtimeOutputModalityText))

(= (codex:realtime-output-modality-audio)
   (CodexRealtimeOutputModalityAudio))

(= (codex:conversation-start-transport-websocket)
   (CodexConversationStartTransportWebsocket))

(= (codex:conversation-start-transport-webrtc $sdp)
   (CodexConversationStartTransportWebrtc $sdp))

(= (codex:conversation-start-params
      $output-modality
      $prompt
      $session-id
      $transport
      $voice)
   (CodexConversationStartParams
     $output-modality
     $prompt
     $session-id
     $transport
     $voice))

(= (codex:conversation-audio-params $frame)
   (CodexConversationAudioParams $frame))

(= (codex:conversation-text-params $text)
   (CodexConversationTextParams $text))

(= (codex:realtime-conversation-start-op $params)
   (CodexOpRealtimeConversationStart $params))

(= (codex:realtime-conversation-audio-op $params)
   (CodexOpRealtimeConversationAudio $params))

(= (codex:realtime-conversation-text-op $params)
   (CodexOpRealtimeConversationText $params))

(= (codex:realtime-conversation-close-op)
   (CodexOpRealtimeConversationClose))

(= (codex:realtime-conversation-list-voices-op)
   (CodexOpRealtimeConversationListVoices))

(= (codex:realtime-conversation-started-event $session-id $version)
   (CodexEventRealtimeConversationStarted $session-id $version))

(= (codex:realtime-audio-frame
      $data
      $sample-rate
      $num-channels
      $samples-per-channel
      $item-id)
   (CodexRealtimeAudioFrame
     $data
     $sample-rate
     $num-channels
     $samples-per-channel
     $item-id))

(= (codex:realtime-transcript-delta $delta)
   (CodexRealtimeTranscriptDelta $delta))

(= (codex:realtime-transcript-done $text)
   (CodexRealtimeTranscriptDone $text))

(= (codex:realtime-transcript-entry $role $text)
   (CodexRealtimeTranscriptEntry $role $text))

(= (codex:realtime-handoff-requested
      $handoff-id
      $item-id
      $input-transcript
      $active-transcript)
   (CodexRealtimeHandoffRequested
     $handoff-id
     $item-id
     $input-transcript
     $active-transcript))

(= (codex:realtime-noop-requested $call-id $item-id)
   (CodexRealtimeNoopRequested $call-id $item-id))

(= (codex:realtime-input-audio-speech-started $item-id)
   (CodexRealtimeInputAudioSpeechStarted $item-id))

(= (codex:realtime-response-cancelled $response-id)
   (CodexRealtimeResponseCancelled $response-id))

(= (codex:realtime-response-created $response-id)
   (CodexRealtimeResponseCreated $response-id))

(= (codex:realtime-response-done $response-id)
   (CodexRealtimeResponseDone $response-id))

(= (codex:realtime-event-session-updated $session-id $instructions)
   (CodexRealtimeEventSessionUpdated $session-id $instructions))

(= (codex:realtime-event-input-audio-speech-started $event)
   (CodexRealtimeEventInputAudioSpeechStarted $event))

(= (codex:realtime-event-input-transcript-delta $event)
   (CodexRealtimeEventInputTranscriptDelta $event))

(= (codex:realtime-event-input-transcript-done $event)
   (CodexRealtimeEventInputTranscriptDone $event))

(= (codex:realtime-event-output-transcript-delta $event)
   (CodexRealtimeEventOutputTranscriptDelta $event))

(= (codex:realtime-event-output-transcript-done $event)
   (CodexRealtimeEventOutputTranscriptDone $event))

(= (codex:realtime-event-audio-out $event)
   (CodexRealtimeEventAudioOut $event))

(= (codex:realtime-event-response-created $event)
   (CodexRealtimeEventResponseCreated $event))

(= (codex:realtime-event-response-cancelled $event)
   (CodexRealtimeEventResponseCancelled $event))

(= (codex:realtime-event-response-done $event)
   (CodexRealtimeEventResponseDone $event))

(= (codex:realtime-event-conversation-item-added $item)
   (CodexRealtimeEventConversationItemAdded $item))

(= (codex:realtime-event-conversation-item-done $item-id)
   (CodexRealtimeEventConversationItemDone $item-id))

(= (codex:realtime-event-handoff-requested $event)
   (CodexRealtimeEventHandoffRequested $event))

(= (codex:realtime-event-noop-requested $event)
   (CodexRealtimeEventNoopRequested $event))

(= (codex:realtime-event-error $message)
   (CodexRealtimeEventError $message))

(= (codex:realtime-conversation-realtime-event $payload)
   (CodexEventRealtimeConversationRealtime $payload))

(= (codex:realtime-conversation-closed-event $reason)
   (CodexEventRealtimeConversationClosed $reason))

(= (codex:realtime-conversation-sdp-event $sdp)
   (CodexEventRealtimeConversationSdp $sdp))

(= (codex:realtime-voice-alloy)
   (CodexRealtimeVoiceAlloy))

(= (codex:realtime-voice-arbor)
   (CodexRealtimeVoiceArbor))

(= (codex:realtime-voice-ash)
   (CodexRealtimeVoiceAsh))

(= (codex:realtime-voice-ballad)
   (CodexRealtimeVoiceBallad))

(= (codex:realtime-voice-breeze)
   (CodexRealtimeVoiceBreeze))

(= (codex:realtime-voice-cedar)
   (CodexRealtimeVoiceCedar))

(= (codex:realtime-voice-coral)
   (CodexRealtimeVoiceCoral))

(= (codex:realtime-voice-cove)
   (CodexRealtimeVoiceCove))

(= (codex:realtime-voice-echo)
   (CodexRealtimeVoiceEcho))

(= (codex:realtime-voice-ember)
   (CodexRealtimeVoiceEmber))

(= (codex:realtime-voice-juniper)
   (CodexRealtimeVoiceJuniper))

(= (codex:realtime-voice-maple)
   (CodexRealtimeVoiceMaple))

(= (codex:realtime-voice-marin)
   (CodexRealtimeVoiceMarin))

(= (codex:realtime-voice-sage)
   (CodexRealtimeVoiceSage))

(= (codex:realtime-voice-shimmer)
   (CodexRealtimeVoiceShimmer))

(= (codex:realtime-voice-sol)
   (CodexRealtimeVoiceSol))

(= (codex:realtime-voice-spruce)
   (CodexRealtimeVoiceSpruce))

(= (codex:realtime-voice-vale)
   (CodexRealtimeVoiceVale))

(= (codex:realtime-voice-verse)
   (CodexRealtimeVoiceVerse))

(= (codex:realtime-voices-list $v1 $v2 $default-v1 $default-v2)
   (CodexRealtimeVoicesList $v1 $v2 $default-v1 $default-v2))

(= (codex:realtime-voices-list-builtin)
   (CodexRealtimeVoicesList
     ((CodexRealtimeVoiceJuniper)
      (CodexRealtimeVoiceMaple)
      (CodexRealtimeVoiceSpruce)
      (CodexRealtimeVoiceEmber)
      (CodexRealtimeVoiceVale)
      (CodexRealtimeVoiceBreeze)
      (CodexRealtimeVoiceArbor)
      (CodexRealtimeVoiceSol)
      (CodexRealtimeVoiceCove))
     ((CodexRealtimeVoiceAlloy)
      (CodexRealtimeVoiceAsh)
      (CodexRealtimeVoiceBallad)
      (CodexRealtimeVoiceCoral)
      (CodexRealtimeVoiceEcho)
      (CodexRealtimeVoiceSage)
      (CodexRealtimeVoiceShimmer)
      (CodexRealtimeVoiceVerse)
      (CodexRealtimeVoiceMarin)
      (CodexRealtimeVoiceCedar))
     (CodexRealtimeVoiceCove)
     (CodexRealtimeVoiceMarin)))

(= (codex:realtime-conversation-list-voices-response-event $voices)
   (CodexEventRealtimeConversationListVoicesResponse $voices))

(= (codex:product-chatgpt)
   (CodexProductChatgpt))

(= (codex:product-codex)
   (CodexProductCodex))

(= (codex:product-atlas)
   (CodexProductAtlas))

(= (codex:session-source-ok $source)
   (CodexSessionSourceOk $source))

(= (codex:session-source-err $message)
   (CodexSessionSourceErr $message))

(= (codex:session-source-cli)
   (CodexSessionSourceCli))

(= (codex:session-source-vscode)
   (CodexSessionSourceVSCode))

(= (codex:session-source-exec)
   (CodexSessionSourceExec))

(= (codex:session-source-mcp)
   (CodexSessionSourceMcp))

(= (codex:session-source-custom $source)
   (CodexSessionSourceCustom $source))

(= (codex:session-source-subagent $source)
   (CodexSessionSourceSubAgent $source))

(= (codex:session-source-unknown)
   (CodexSessionSourceUnknown))

(= (codex:subagent-source-review)
   (CodexSubAgentSourceReview))

(= (codex:subagent-source-compact)
   (CodexSubAgentSourceCompact))

(= (codex:subagent-source-thread-spawn
      $parent-thread-id
      $depth
      $agent-path
      $agent-nickname
      $agent-role)
   (CodexSubAgentSourceThreadSpawn
     $parent-thread-id
     $depth
     $agent-path
     $agent-nickname
     $agent-role))

(= (codex:subagent-source-memory-consolidation)
   (CodexSubAgentSourceMemoryConsolidation))

(= (codex:subagent-source-other $other)
   (CodexSubAgentSourceOther $other))

(= (codex:compacted-item $message $replacement-history)
   (CodexCompactedItem $message $replacement-history))

(= (codex:compacted-item-to-response-item
      (CodexCompactedItem $message $replacement-history))
   ; Rust `From<CompactedItem> for ResponseItem` ignores
   ; `replacement_history` and always returns an assistant `message` with a
   ; single `output_text`.
   (CodexResponseItemMessage
     "assistant"
     ((CodexOutputText $message))
     CodexAbsent))

(= (codex:turn-context-network-item $allowed-domains $denied-domains)
   (CodexTurnContextNetworkItem $allowed-domains $denied-domains))

(= (codex:truncation-policy-bytes $bytes)
   (CodexTruncationPolicyBytes $bytes))

(= (codex:truncation-policy-tokens $tokens)
   (CodexTruncationPolicyTokens $tokens))

(= (codex:truncation-policy-token-budget
      (CodexTruncationPolicyBytes $bytes))
   (trunc-math (ceil-math (/ $bytes 4))))

(= (codex:truncation-policy-token-budget
      (CodexTruncationPolicyTokens $tokens))
   $tokens)

(= (codex:truncation-policy-byte-budget
      (CodexTruncationPolicyBytes $bytes))
   $bytes)

(= (codex:truncation-policy-byte-budget
      (CodexTruncationPolicyTokens $tokens))
   (* $tokens 4))

(= (codex:truncation-policy-mul
      (CodexTruncationPolicyBytes $bytes)
      $multiplier)
   (CodexTruncationPolicyBytes
     (trunc-math (ceil-math (* $bytes $multiplier)))))

(= (codex:truncation-policy-mul
      (CodexTruncationPolicyTokens $tokens)
      $multiplier)
   (CodexTruncationPolicyTokens
     (trunc-math (ceil-math (* $tokens $multiplier)))))

(= (codex:session-approvals-reviewer-user)
   (CodexSessionApprovalsReviewerUser))

(= (codex:session-approvals-reviewer-auto-review)
   (CodexSessionApprovalsReviewerAutoReview))

(= (codex:session-service-tier-fast)
   (CodexSessionServiceTierFast))

(= (codex:session-service-tier-flex)
   (CodexSessionServiceTierFlex))

(= (codex:session-reasoning-effort-none)
   (CodexSessionReasoningEffortNone))

(= (codex:session-reasoning-effort-minimal)
   (CodexSessionReasoningEffortMinimal))

(= (codex:session-reasoning-effort-low)
   (CodexSessionReasoningEffortLow))

(= (codex:session-reasoning-effort-medium)
   (CodexSessionReasoningEffortMedium))

(= (codex:session-reasoning-effort-high)
   (CodexSessionReasoningEffortHigh))

(= (codex:session-reasoning-effort-xhigh)
   (CodexSessionReasoningEffortXHigh))

(= (codex:session-approval-policy-untrusted)
   (CodexSessionApprovalPolicyUnlessTrusted))

(= (codex:session-approval-policy-on-failure)
   (CodexSessionApprovalPolicyOnFailure))

(= (codex:session-approval-policy-on-request)
   (CodexSessionApprovalPolicyOnRequest))

(= (codex:session-approval-policy-never)
   (CodexSessionApprovalPolicyNever))

(= (codex:session-approval-policy-granular-config
      $sandbox-approval
      $rules
      $skill-approval
      $request-permissions
      $mcp-elicitations)
   (CodexSessionGranularApprovalConfig
     $sandbox-approval
     $rules
     $skill-approval
     $request-permissions
     $mcp-elicitations))

(= (codex:session-approval-policy-granular $config)
   (CodexSessionApprovalPolicyGranular $config))

(= (codex:session-network-access-restricted)
   (CodexSessionNetworkAccessRestricted))

(= (codex:session-network-access-enabled)
   (CodexSessionNetworkAccessEnabled))

(= (codex:session-read-only-access-full)
   (CodexSessionReadOnlyAccessFull))

(= (codex:session-read-only-access-restricted
      $include-platform-defaults
      $readable-roots)
   (CodexSessionReadOnlyAccessRestricted
     $include-platform-defaults
     $readable-roots))

(= (codex:session-sandbox-policy-danger-full-access)
   (CodexSessionSandboxPolicyDangerFullAccess))

(= (codex:session-sandbox-policy-read-only $access $network-access)
   (CodexSessionSandboxPolicyReadOnly $access $network-access))

(= (codex:session-sandbox-policy-external-sandbox $network-access)
   (CodexSessionSandboxPolicyExternalSandbox $network-access))

(= (codex:session-sandbox-policy-workspace-write
      $writable-roots
      $read-only-access
      $network-access
      $exclude-tmpdir-env-var
      $exclude-slash-tmp)
   (CodexSessionSandboxPolicyWorkspaceWrite
     $writable-roots
     $read-only-access
     $network-access
     $exclude-tmpdir-env-var
     $exclude-slash-tmp))

(= (codex:session-network-sandbox-policy-restricted)
   (CodexSessionNetworkSandboxPolicyRestricted))

(= (codex:session-network-sandbox-policy-enabled)
   (CodexSessionNetworkSandboxPolicyEnabled))

(= (codex:session-network-proxy-runtime $http-addr $socks-addr)
   (CodexSessionNetworkProxyRuntime $http-addr $socks-addr))

(= (codex:session-permission-profile-disabled-json)
   (JsonObject
     ((JsonPair "type" (JsonString "disabled")))))

(= (codex:session-permission-profile-external-json $network-policy)
   (JsonObject
     ((JsonPair "type" (JsonString "external"))
      (JsonPair
        "network"
        (codex:session-network-sandbox-policy-json $network-policy)))))

(= (codex:session-permission-profile-managed-unrestricted-json
      $network-policy)
   (JsonObject
     ((JsonPair "type" (JsonString "managed"))
      (JsonPair
        "file_system"
        (JsonObject
          ((JsonPair "type" (JsonString "unrestricted")))))
      (JsonPair
        "network"
        (codex:session-network-sandbox-policy-json $network-policy)))))

(= (codex:session-permission-profile-managed-restricted-json
      $entries
      $glob-scan-max-depth
      $network-policy)
   (let $file-system-pairs
     ((JsonPair "type" (JsonString "restricted"))
      (JsonPair "entries" (JsonArray $entries)))
     (let $file-system-pairs-2
       (if (== $glob-scan-max-depth CodexAbsent)
           $file-system-pairs
           (codex:protocol-append-json-pair
             $file-system-pairs
             "glob_scan_max_depth"
             (JsonNumber $glob-scan-max-depth)))
       (JsonObject
         ((JsonPair "type" (JsonString "managed"))
          (JsonPair "file_system" (JsonObject $file-system-pairs-2))
          (JsonPair
            "network"
            (codex:session-network-sandbox-policy-json $network-policy)))))))

(= (codex:session-configured-event
      $session-id
      $forked-from-id
      $thread-name
      $model
      $model-provider-id
      $service-tier
      $approval-policy
      $approvals-reviewer
      $sandbox-policy
      $permission-profile
      $cwd
      $reasoning-effort
      $history-log-id
      $history-entry-count
      $initial-messages
      $network-proxy
      $rollout-path)
   (CodexEventSessionConfigured
     $session-id
     $forked-from-id
     $thread-name
     $model
     $model-provider-id
     $service-tier
     $approval-policy
     $approvals-reviewer
     $sandbox-policy
     $permission-profile
     $cwd
     $reasoning-effort
     $history-log-id
     $history-entry-count
     $initial-messages
     $network-proxy
     $rollout-path))

(= (codex:patch-apply-file-change-add $path $content)
   (CodexProtocolPatchApplyFileChangeAdd $path $content))

(= (codex:patch-apply-file-change-delete $path $content)
   (CodexProtocolPatchApplyFileChangeDelete $path $content))

(= (codex:patch-apply-file-change-update $path $unified-diff $move-path)
   (CodexProtocolPatchApplyFileChangeUpdate $path $unified-diff $move-path))

(= (codex:patch-apply-status-completed)
   (CodexPatchApplyStatusCompleted))

(= (codex:patch-apply-status-failed)
   (CodexPatchApplyStatusFailed))

(= (codex:patch-apply-status-declined)
   (CodexPatchApplyStatusDeclined))

(= (codex:patch-apply-begin-event
      $call-id
      $turn-id
      $auto-approved
      $changes)
   (CodexEventPatchApplyBegin $call-id $turn-id $auto-approved $changes))

(= (codex:patch-apply-updated-event $call-id $changes)
   (CodexEventPatchApplyUpdated $call-id $changes))

(= (codex:patch-apply-end-event
      $call-id
      $turn-id
      $stdout
      $stderr
      $success
      $changes
      $status)
   (CodexEventPatchApplyEnd
     $call-id
     $turn-id
     $stdout
     $stderr
     $success
     $changes
     $status))

(= (codex:hook-event-name-pre-tool-use)
   (CodexHookEventNamePreToolUse))

(= (codex:hook-event-name-permission-request)
   (CodexHookEventNamePermissionRequest))

(= (codex:hook-event-name-post-tool-use)
   (CodexHookEventNamePostToolUse))

(= (codex:hook-event-name-session-start)
   (CodexHookEventNameSessionStart))

(= (codex:hook-event-name-user-prompt-submit)
   (CodexHookEventNameUserPromptSubmit))

(= (codex:hook-event-name-stop)
   (CodexHookEventNameStop))

(= (codex:hook-handler-type-command)
   (CodexHookHandlerTypeCommand))

(= (codex:hook-handler-type-prompt)
   (CodexHookHandlerTypePrompt))

(= (codex:hook-handler-type-agent)
   (CodexHookHandlerTypeAgent))

(= (codex:hook-execution-mode-sync)
   (CodexHookExecutionModeSync))

(= (codex:hook-execution-mode-async)
   (CodexHookExecutionModeAsync))

(= (codex:hook-scope-thread)
   (CodexHookScopeThread))

(= (codex:hook-scope-turn)
   (CodexHookScopeTurn))

(= (codex:hook-source-system)
   (CodexHookSourceSystem))

(= (codex:hook-source-user)
   (CodexHookSourceUser))

(= (codex:hook-source-project)
   (CodexHookSourceProject))

(= (codex:hook-source-mdm)
   (CodexHookSourceMdm))

(= (codex:hook-source-session-flags)
   (CodexHookSourceSessionFlags))

(= (codex:hook-source-legacy-managed-config-file)
   (CodexHookSourceLegacyManagedConfigFile))

(= (codex:hook-source-legacy-managed-config-mdm)
   (CodexHookSourceLegacyManagedConfigMdm))

(= (codex:hook-source-unknown)
   (CodexHookSourceUnknown))

(= (codex:hook-run-status-running)
   (CodexHookRunStatusRunning))

(= (codex:hook-run-status-completed)
   (CodexHookRunStatusCompleted))

(= (codex:hook-run-status-failed)
   (CodexHookRunStatusFailed))

(= (codex:hook-run-status-blocked)
   (CodexHookRunStatusBlocked))

(= (codex:hook-run-status-stopped)
   (CodexHookRunStatusStopped))

(= (codex:hook-output-entry-kind-warning)
   (CodexHookOutputEntryKindWarning))

(= (codex:hook-output-entry-kind-stop)
   (CodexHookOutputEntryKindStop))

(= (codex:hook-output-entry-kind-feedback)
   (CodexHookOutputEntryKindFeedback))

(= (codex:hook-output-entry-kind-context)
   (CodexHookOutputEntryKindContext))

(= (codex:hook-output-entry-kind-error)
   (CodexHookOutputEntryKindError))

(= (codex:hook-output-entry $kind $text)
   (CodexHookOutputEntry $kind $text))

(= (codex:hook-run-summary
      $id
      $event-name
      $handler-type
      $execution-mode
      $scope
      $source-path
      $source
      $display-order
      $status
      $status-message
      $started-at
      $completed-at
      $duration-ms
      $entries)
   (CodexHookRunSummary
     $id
     $event-name
     $handler-type
     $execution-mode
     $scope
     $source-path
     $source
     $display-order
     $status
     $status-message
     $started-at
     $completed-at
     $duration-ms
     $entries))

(= (codex:hook-started-event $turn-id $run)
   (CodexEventHookStarted $turn-id $run))

(= (codex:hook-completed-event $turn-id $run)
   (CodexEventHookCompleted $turn-id $run))

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
      (CodexEventAgentMessage $message $phase $memory-citation))
   "agent_message")

(= (codex:item-type
      (CodexEventUserMessage
        $message
        $images
        $local-images
        $text-elements))
   "user_message")

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
      (CodexEventModelVerification $verifications))
   "model_verification")

(= (codex:item-type
      (CodexEventTurnStarted
        $turn_id
        $started_at
        $model_context_window
        $collaboration_mode_kind))
   "task_started")

(= (codex:item-type
      (CodexEventContextCompacted))
   "context_compacted")

(= (codex:item-type
      (CodexEventTurnComplete
        $turn_id
        $last_agent_message
        $completed_at
        $duration_ms
        $time_to_first_token_ms))
   "task_complete")

(= (codex:item-type
      (CodexTokenCountEvent $info $rate-limits))
   "token_count")

(= (codex:item-type
      (CodexEventStreamInfo $message))
   "stream_info")

(= (codex:item-type
      (CodexEventUndoStarted $message))
   "undo_started")

(= (codex:item-type
      (CodexEventUndoCompleted $success $message))
   "undo_completed")

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

(= (codex:item-type
      (CodexEventViewImageToolCall $call_id $path))
   "view_image_tool_call")

(= (codex:item-type
      (CodexEventBackgroundEvent $message))
   "background_event")

(= (codex:item-type
      (CodexEventDeprecationNotice $summary $details))
   "deprecation_notice")

(= (codex:item-type
      (CodexEventSkillsUpdateAvailable))
   "skills_update_available")

(= (codex:item-type
      (CodexEventShutdownComplete))
   "shutdown_complete")

(= (codex:item-type
      (CodexUpdatePlanArgs $explanation $plan))
   "plan_update")

(= (codex:item-type
      (CodexEventTurnAborted $turn-id $reason $completed-at $duration-ms))
   "turn_aborted")

(= (codex:item-type
      (CodexEventCollabAgentSpawnBegin
        $call-id
        $sender-thread-id
        $prompt
        $model
        $reasoning-effort))
   "collab_agent_spawn_begin")

(= (codex:item-type
      (CodexEventCollabAgentSpawnEnd
        $call-id
        $sender-thread-id
        $new-thread-id
        $new-agent-nickname
        $new-agent-role
        $prompt
        $model
        $reasoning-effort
        $status))
   "collab_agent_spawn_end")

(= (codex:item-type
      (CodexEventCollabAgentInteractionBegin
        $call-id
        $sender-thread-id
        $receiver-thread-id
        $prompt))
   "collab_agent_interaction_begin")

(= (codex:item-type
      (CodexEventCollabAgentInteractionEnd
        $call-id
        $sender-thread-id
        $receiver-thread-id
        $receiver-agent-nickname
        $receiver-agent-role
        $prompt
        $status))
   "collab_agent_interaction_end")

(= (codex:item-type
      (CodexEventCollabWaitingBegin
        $sender-thread-id
        $receiver-thread-ids
        $receiver-agents
        $call-id))
   "collab_waiting_begin")

(= (codex:item-type
      (CodexEventCollabWaitingEnd
        $sender-thread-id
        $call-id
        $agent-statuses
        $statuses))
   "collab_waiting_end")

(= (codex:item-type
      (CodexEventCollabCloseBegin
        $call-id
        $sender-thread-id
        $receiver-thread-id))
   "collab_close_begin")

(= (codex:item-type
      (CodexEventCollabCloseEnd
        $call-id
        $sender-thread-id
        $receiver-thread-id
        $receiver-agent-nickname
        $receiver-agent-role
        $status))
   "collab_close_end")

(= (codex:item-type
      (CodexEventCollabResumeBegin
        $call-id
        $sender-thread-id
        $receiver-thread-id
        $receiver-agent-nickname
        $receiver-agent-role))
   "collab_resume_begin")

(= (codex:item-type
      (CodexEventCollabResumeEnd
        $call-id
        $sender-thread-id
        $receiver-thread-id
        $receiver-agent-nickname
        $receiver-agent-role
        $status))
   "collab_resume_end")

(= (codex:item-type
      (CodexEventStreamError $message $codex-error-info $additional-details))
   "stream_error")

(= (codex:item-type
      (CodexEventError $message $codex-error-info))
   "error")

(= (codex:item-type
      (CodexEventRawResponseItem $item))
   "raw_response_item")

(= (codex:item-type
      (CodexEventAgentMessageContentDelta
        $thread-id
        $turn-id
        $item-id
        $delta))
   "agent_message_content_delta")

(= (codex:item-type
      (CodexEventPlanDelta
        $thread-id
        $turn-id
        $item-id
        $delta))
   "plan_delta")

(= (codex:item-type
      (CodexEventReasoningContentDelta
        $thread-id
        $turn-id
        $item-id
        $delta
        $summary-index))
   "reasoning_content_delta")

(= (codex:item-type
      (CodexEventReasoningRawContentDelta
        $thread-id
        $turn-id
        $item-id
        $delta
        $content-index))
   "reasoning_raw_content_delta")

(= (codex:item-type
      (CodexEventExitedReviewMode $review-output))
   "exited_review_mode")

(= (codex:item-type
      (CodexEventEnteredReviewMode $review-request))
   "entered_review_mode")

(= (codex:item-type
      (CodexEventTurnDiff $unified-diff))
   "turn_diff")

(= (codex:item-type
      (CodexEventGetHistoryEntryResponse $offset $log-id $entry))
   "get_history_entry_response")

(= (codex:item-type
      (CodexEventListSkillsResponse $skills))
   "list_skills_response")

(= (codex:item-type
      (CodexEventRealtimeConversationStarted $session-id $version))
   "realtime_conversation_started")

(= (codex:item-type
      (CodexEventRealtimeConversationRealtime $payload))
   "realtime_conversation_realtime")

(= (codex:item-type
      (CodexEventRealtimeConversationClosed $reason))
   "realtime_conversation_closed")

(= (codex:item-type
      (CodexEventRealtimeConversationSdp $sdp))
   "realtime_conversation_sdp")

(= (codex:item-type
      (CodexEventRealtimeConversationListVoicesResponse $voices))
   "realtime_conversation_list_voices_response")

(= (codex:item-type
      (CodexEventSessionConfigured
        $session-id
        $forked-from-id
        $thread-name
        $model
        $model-provider-id
        $service-tier
        $approval-policy
        $approvals-reviewer
        $sandbox-policy
        $permission-profile
        $cwd
        $reasoning-effort
        $history-log-id
        $history-entry-count
        $initial-messages
        $network-proxy
        $rollout-path))
   "session_configured")

(= (codex:item-type
      (CodexEventPatchApplyBegin
        $call-id
        $turn-id
        $auto-approved
        $changes))
   "patch_apply_begin")

(= (codex:item-type
      (CodexEventPatchApplyUpdated $call-id $changes))
   "patch_apply_updated")

(= (codex:item-type
      (CodexEventPatchApplyEnd
        $call-id
        $turn-id
        $stdout
        $stderr
        $success
        $changes
        $status))
   "patch_apply_end")

(= (codex:item-type
      (CodexEventHookStarted $turn-id $run))
   "hook_started")

(= (codex:item-type
      (CodexEventHookCompleted $turn-id $run))
   "hook_completed")

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

(= (codex:memory-citation-entry-path
      (CodexMemoryCitationEntry $path $line-start $line-end $note))
   $path)

(= (codex:memory-citation-entry-line-start
      (CodexMemoryCitationEntry $path $line-start $line-end $note))
   $line-start)

(= (codex:memory-citation-entry-line-end
      (CodexMemoryCitationEntry $path $line-start $line-end $note))
   $line-end)

(= (codex:memory-citation-entry-note
      (CodexMemoryCitationEntry $path $line-start $line-end $note))
   $note)

(= (codex:memory-citation-entries
      (CodexMemoryCitation $entries $rollout-ids))
   $entries)

(= (codex:memory-citation-rollout-ids
      (CodexMemoryCitation $entries $rollout-ids))
   $rollout-ids)

(= (codex:byte-range-start
      (CodexByteRange $start $end))
   $start)

(= (codex:byte-range-end
      (CodexByteRange $start $end))
   $end)

(= (codex:text-element-byte-range
      (CodexTextElement $byte-range $placeholder))
   $byte-range)

(= (codex:text-element-placeholder
      (CodexTextElement $byte-range $placeholder))
   (if (== $placeholder CodexAbsent) Empty $placeholder))

(= (codex:agent-message-event-message
      (CodexEventAgentMessage $message $phase $memory-citation))
   $message)

(= (codex:agent-message-event-phase
      (CodexEventAgentMessage $message $phase $memory-citation))
   (if (== $phase CodexAbsent) Empty $phase))

(= (codex:agent-message-event-memory-citation
      (CodexEventAgentMessage $message $phase $memory-citation))
   (if (== $memory-citation CodexAbsent) Empty $memory-citation))

(= (codex:user-message-event-message
      (CodexEventUserMessage
        $message
        $images
        $local-images
        $text-elements))
   $message)

(= (codex:user-message-event-images
      (CodexEventUserMessage
        $message
        $images
        $local-images
        $text-elements))
   (if (== $images CodexAbsent) Empty $images))

(= (codex:user-message-event-local-images
      (CodexEventUserMessage
        $message
        $images
        $local-images
        $text-elements))
   $local-images)

(= (codex:user-message-event-text-elements
      (CodexEventUserMessage
        $message
        $images
        $local-images
        $text-elements))
   $text-elements)

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

(= (codex:model-verification-event-verifications
      (CodexEventModelVerification $verifications))
   $verifications)

(= (codex:turn-started-turn-id
      (CodexEventTurnStarted
        $turn_id
        $started_at
        $model_context_window
        $collaboration_mode_kind))
   $turn_id)

(= (codex:turn-started-started-at
      (CodexEventTurnStarted
        $turn_id
        $started_at
        $model_context_window
        $collaboration_mode_kind))
   (if (== $started_at CodexAbsent) Empty $started_at))

(= (codex:turn-started-model-context-window
      (CodexEventTurnStarted
        $turn_id
        $started_at
        $model_context_window
        $collaboration_mode_kind))
   (if (== $model_context_window CodexAbsent) Empty $model_context_window))

(= (codex:turn-started-collaboration-mode-kind
      (CodexEventTurnStarted
        $turn_id
        $started_at
        $model_context_window
        $collaboration_mode_kind))
   $collaboration_mode_kind)

(= (codex:turn-complete-turn-id
      (CodexEventTurnComplete
        $turn_id
        $last_agent_message
        $completed_at
        $duration_ms
        $time_to_first_token_ms))
   $turn_id)

(= (codex:turn-complete-last-agent-message
      (CodexEventTurnComplete
        $turn_id
        $last_agent_message
        $completed_at
        $duration_ms
        $time_to_first_token_ms))
   (if (== $last_agent_message CodexAbsent) Empty $last_agent_message))

(= (codex:turn-complete-completed-at
      (CodexEventTurnComplete
        $turn_id
        $last_agent_message
        $completed_at
        $duration_ms
        $time_to_first_token_ms))
   (if (== $completed_at CodexAbsent) Empty $completed_at))

(= (codex:turn-complete-duration-ms
      (CodexEventTurnComplete
        $turn_id
        $last_agent_message
        $completed_at
        $duration_ms
        $time_to_first_token_ms))
   (if (== $duration_ms CodexAbsent) Empty $duration_ms))

(= (codex:turn-complete-time-to-first-token-ms
      (CodexEventTurnComplete
        $turn_id
        $last_agent_message
        $completed_at
        $duration_ms
        $time_to_first_token_ms))
   (if (== $time_to_first_token_ms CodexAbsent) Empty $time_to_first_token_ms))

(= (codex:stream-info-message
      (CodexEventStreamInfo $message))
   $message)

(= (codex:undo-started-message
      (CodexEventUndoStarted $message))
   (if (== $message CodexAbsent) Empty $message))

(= (codex:undo-completed-success
      (CodexEventUndoCompleted $success $message))
   $success)

(= (codex:undo-completed-message
      (CodexEventUndoCompleted $success $message))
   (if (== $message CodexAbsent) Empty $message))

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

(= (codex:view-image-tool-call-call-id
      (CodexEventViewImageToolCall $call_id $path))
   $call_id)

(= (codex:view-image-tool-call-path
      (CodexEventViewImageToolCall $call_id $path))
   $path)

(= (codex:background-event-message
      (CodexEventBackgroundEvent $message))
   $message)

(= (codex:deprecation-notice-summary
      (CodexEventDeprecationNotice $summary $details))
   $summary)

(= (codex:deprecation-notice-details
      (CodexEventDeprecationNotice $summary $details))
   (if (== $details CodexAbsent) Empty $details))

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

(= (codex:model-verification-json
      (CodexModelVerificationTrustedAccessForCyber))
   (JsonString "trusted_access_for_cyber"))

; Rust `ModeKind` also has hidden `PairProgramming` and `Execute` variants, but
; both are `skip_serializing`. This output-only protocol slice therefore models
; just the serializable wire values.
(= (codex:mode-kind-json
      (CodexModeKindPlan))
   (JsonString "plan"))

(= (codex:mode-kind-json
      (CodexModeKindDefault))
   (JsonString "default"))

(= (codex:message-phase-json
      (CodexMessagePhaseCommentary))
   (JsonString "commentary"))

(= (codex:message-phase-json
      (CodexMessagePhaseFinalAnswer))
   (JsonString "final_answer"))

(= (codex:memory-citation-entry-json
      (CodexMemoryCitationEntry $path $line-start $line-end $note))
   (JsonObject
     ((JsonPair "path" (JsonString $path))
      (JsonPair "lineStart" (JsonNumber $line-start))
      (JsonPair "lineEnd" (JsonNumber $line-end))
      (JsonPair "note" (JsonString $note)))))

(= (codex:memory-citation-json
      (CodexMemoryCitation $entries $rollout-ids))
   (JsonObject
     ((JsonPair
        "entries"
        (JsonArray
          (map-atom $entries $item (codex:memory-citation-entry-json $item))))
      (JsonPair
        "rolloutIds"
        (JsonArray
          (map-atom $rollout-ids $item (JsonString $item)))))))

(= (codex:byte-range-json
      (CodexByteRange $start $end))
   (JsonObject
     ((JsonPair "start" (JsonNumber $start))
      (JsonPair "end" (JsonNumber $end)))))

(= (codex:text-element-json
      (CodexTextElement $byte-range $placeholder))
   (if (== $placeholder CodexAbsent)
       (JsonObject
         ((JsonPair "byte_range" (codex:byte-range-json $byte-range))
          (JsonPair "placeholder" JsonNull)))
       (JsonObject
         ((JsonPair "byte_range" (codex:byte-range-json $byte-range))
          (JsonPair "placeholder" (JsonString $placeholder))))))

(= (codex:turn-abort-reason-json
      (CodexTurnAbortReasonInterrupted))
   (JsonString "interrupted"))

(= (codex:turn-abort-reason-json
      (CodexTurnAbortReasonReplaced))
   (JsonString "replaced"))

(= (codex:turn-abort-reason-json
      (CodexTurnAbortReasonReviewEnded))
   (JsonString "review_ended"))

(= (codex:protocol-agent-status-json-value-for-completed $message)
   (if (== $message CodexAbsent)
       JsonNull
       (JsonString $message)))

(= (codex:protocol-agent-status-json
      (CodexProtocolAgentStatusPendingInit))
   (JsonString "pending_init"))

(= (codex:protocol-agent-status-json
      (CodexProtocolAgentStatusRunning))
   (JsonString "running"))

(= (codex:protocol-agent-status-json
      (CodexProtocolAgentStatusInterrupted))
   (JsonString "interrupted"))

(= (codex:protocol-agent-status-json
      (CodexProtocolAgentStatusCompleted $message))
   (JsonObject
     ((JsonPair
        "completed"
        (codex:protocol-agent-status-json-value-for-completed $message)))))

(= (codex:protocol-agent-status-json
      (CodexProtocolAgentStatusErrored $message))
   (JsonObject
     ((JsonPair "errored" (JsonString $message)))))

(= (codex:protocol-agent-status-json
      (CodexProtocolAgentStatusShutdown))
   (JsonString "shutdown"))

(= (codex:protocol-agent-status-json
      (CodexProtocolAgentStatusNotFound))
   (JsonString "not_found"))

(= (codex:collab-agent-ref-json-pairs
      $thread-id
      $agent-nickname
      $agent-role)
   (let $pairs-1
     ((JsonPair "thread_id" (JsonString $thread-id)))
     (let $pairs-2
       (codex:append-optional-json-string-pair
         $pairs-1
         "agent_nickname"
         $agent-nickname)
       (codex:append-optional-json-string-pair
         $pairs-2
         "agent_role"
         $agent-role))))

(= (codex:collab-agent-ref-json
      (CodexCollabAgentRef $thread-id $agent-nickname $agent-role))
   (JsonObject
     (codex:collab-agent-ref-json-pairs
       $thread-id
       $agent-nickname
       $agent-role)))

(= (codex:collab-agent-refs-json $items)
   (JsonArray
     (map-atom $items $item (codex:collab-agent-ref-json $item))))

(= (codex:collab-agent-status-entry-json
      (CodexCollabAgentStatusEntry
        $thread-id
        $agent-nickname
        $agent-role
        $status))
   (let $pairs-1
     (codex:collab-agent-ref-json-pairs
       $thread-id
       $agent-nickname
       $agent-role)
     (JsonObject
       (codex:protocol-append-json-pair
         $pairs-1
         "status"
         (codex:protocol-agent-status-json $status)))))

(= (codex:collab-agent-status-entries-json $items)
   (JsonArray
     (map-atom $items $item (codex:collab-agent-status-entry-json $item))))

(= (codex:collab-waiting-status-json-pair
      (CodexCollabWaitingStatusEntry $thread-id $status))
   (JsonPair $thread-id (codex:protocol-agent-status-json $status)))

(= (codex:collab-waiting-statuses-json $items)
   (JsonObject
     (map-atom $items $item (codex:collab-waiting-status-json-pair $item))))

(= (codex:non-steerable-turn-kind-json
      (CodexNonSteerableTurnKindReview))
   (JsonString "review"))

(= (codex:non-steerable-turn-kind-json
      (CodexNonSteerableTurnKindCompact))
   (JsonString "compact"))

(= (codex:optional-http-status-code-json $http-status-code)
   (if (== $http-status-code CodexAbsent)
       JsonNull
       (JsonNumber $http-status-code)))

(= (codex:codex-error-info-json
      (CodexErrorInfoContextWindowExceeded))
   (JsonString "context_window_exceeded"))

(= (codex:codex-error-info-json
      (CodexErrorInfoUsageLimitExceeded))
   (JsonString "usage_limit_exceeded"))

(= (codex:codex-error-info-json
      (CodexErrorInfoServerOverloaded))
   (JsonString "server_overloaded"))

(= (codex:codex-error-info-json
      (CodexErrorInfoCyberPolicy))
   (JsonString "cyber_policy"))

(= (codex:codex-error-info-json
      (CodexErrorInfoHttpConnectionFailed $http-status-code))
   (JsonObject
     ((JsonPair
        "http_connection_failed"
        (JsonObject
          ((JsonPair
             "http_status_code"
             (codex:optional-http-status-code-json $http-status-code))))))))

(= (codex:codex-error-info-json
      (CodexErrorInfoResponseStreamConnectionFailed $http-status-code))
   (JsonObject
     ((JsonPair
        "response_stream_connection_failed"
        (JsonObject
          ((JsonPair
             "http_status_code"
             (codex:optional-http-status-code-json $http-status-code))))))))

(= (codex:codex-error-info-json
      (CodexErrorInfoInternalServerError))
   (JsonString "internal_server_error"))

(= (codex:codex-error-info-json
      (CodexErrorInfoUnauthorized))
   (JsonString "unauthorized"))

(= (codex:codex-error-info-json
      (CodexErrorInfoBadRequest))
   (JsonString "bad_request"))

(= (codex:codex-error-info-json
      (CodexErrorInfoSandboxError))
   (JsonString "sandbox_error"))

(= (codex:codex-error-info-json
      (CodexErrorInfoResponseStreamDisconnected $http-status-code))
   (JsonObject
     ((JsonPair
        "response_stream_disconnected"
        (JsonObject
          ((JsonPair
             "http_status_code"
             (codex:optional-http-status-code-json $http-status-code))))))))

(= (codex:codex-error-info-json
      (CodexErrorInfoResponseTooManyFailedAttempts $http-status-code))
   (JsonObject
     ((JsonPair
        "response_too_many_failed_attempts"
        (JsonObject
          ((JsonPair
             "http_status_code"
             (codex:optional-http-status-code-json $http-status-code))))))))

(= (codex:codex-error-info-json
      (CodexErrorInfoActiveTurnNotSteerable $turn-kind))
   (JsonObject
     ((JsonPair
        "active_turn_not_steerable"
        (JsonObject
          ((JsonPair
             "turn_kind"
             (codex:non-steerable-turn-kind-json $turn-kind))))))))

(= (codex:codex-error-info-json
      (CodexErrorInfoThreadRollbackFailed))
   (JsonString "thread_rollback_failed"))

(= (codex:codex-error-info-json
      (CodexErrorInfoOther))
   (JsonString "other"))

(= (codex:codex-error-info-affects-turn-status
      (CodexErrorInfoThreadRollbackFailed))
   False)

(= (codex:codex-error-info-affects-turn-status
      (CodexErrorInfoActiveTurnNotSteerable $turn-kind))
   False)

(= (codex:codex-error-info-affects-turn-status
      (CodexErrorInfoContextWindowExceeded))
   True)

(= (codex:codex-error-info-affects-turn-status
      (CodexErrorInfoUsageLimitExceeded))
   True)

(= (codex:codex-error-info-affects-turn-status
      (CodexErrorInfoServerOverloaded))
   True)

(= (codex:codex-error-info-affects-turn-status
      (CodexErrorInfoCyberPolicy))
   True)

(= (codex:codex-error-info-affects-turn-status
      (CodexErrorInfoHttpConnectionFailed $http-status-code))
   True)

(= (codex:codex-error-info-affects-turn-status
      (CodexErrorInfoResponseStreamConnectionFailed $http-status-code))
   True)

(= (codex:codex-error-info-affects-turn-status
      (CodexErrorInfoInternalServerError))
   True)

(= (codex:codex-error-info-affects-turn-status
      (CodexErrorInfoUnauthorized))
   True)

(= (codex:codex-error-info-affects-turn-status
      (CodexErrorInfoBadRequest))
   True)

(= (codex:codex-error-info-affects-turn-status
      (CodexErrorInfoSandboxError))
   True)

(= (codex:codex-error-info-affects-turn-status
      (CodexErrorInfoResponseStreamDisconnected $http-status-code))
   True)

(= (codex:codex-error-info-affects-turn-status
      (CodexErrorInfoResponseTooManyFailedAttempts $http-status-code))
   True)

(= (codex:codex-error-info-affects-turn-status
      (CodexErrorInfoOther))
   True)

(= (codex:error-event-affects-turn-status
      (CodexEventError $message $codex-error-info))
   (if (== $codex-error-info CodexAbsent)
       True
       (codex:codex-error-info-affects-turn-status $codex-error-info)))

; Rust `HasLegacyEvent` / `EventMsg::as_legacy_events` currently projects these
; delta events to the existing legacy event stream. The boolean flag is accepted
; now so later `ItemStarted` / `ItemCompleted` ports can preserve the same
; method surface even though the currently ported delta variants ignore it.
(= (codex:event-as-legacy-events
      (CodexEventAgentMessageContentDelta
        $thread-id
        $turn-id
        $item-id
        $delta)
      $show-raw-agent-reasoning)
   ((CodexEventAgentMessageDelta $delta)))

(= (codex:event-as-legacy-events
      (CodexEventPlanDelta
        $thread-id
        $turn-id
        $item-id
        $delta)
      $show-raw-agent-reasoning)
   ())

(= (codex:event-as-legacy-events
      (CodexEventReasoningContentDelta
        $thread-id
        $turn-id
        $item-id
        $delta
        $summary-index)
      $show-raw-agent-reasoning)
   ((CodexEventAgentReasoningDelta $delta)))

(= (codex:event-as-legacy-events
      (CodexEventReasoningRawContentDelta
        $thread-id
        $turn-id
        $item-id
        $delta
        $content-index)
      $show-raw-agent-reasoning)
   ((CodexEventAgentReasoningRawContentDelta $delta)))

(= (codex:review-line-range-json
      (CodexReviewLineRange $start $end))
   (JsonObject
     ((JsonPair "start" (JsonNumber $start))
      (JsonPair "end" (JsonNumber $end)))))

(= (codex:review-code-location-json
      (CodexReviewCodeLocation $absolute-file-path $line-range))
   (JsonObject
     ((JsonPair "absolute_file_path" (JsonString $absolute-file-path))
      (JsonPair "line_range" (codex:review-line-range-json $line-range)))))

(= (codex:review-finding-json
      (CodexReviewFinding
        $title
        $body
        $confidence-score
        $priority
        $code-location))
   (JsonObject
     ((JsonPair "title" (JsonString $title))
      (JsonPair "body" (JsonString $body))
      (JsonPair "confidence_score" (JsonNumber $confidence-score))
      (JsonPair "priority" (JsonNumber $priority))
      (JsonPair "code_location" (codex:review-code-location-json $code-location)))))

(= (codex:review-findings-json $findings)
   (JsonArray
     (map-atom $findings $item (codex:review-finding-json $item))))

(= (codex:review-output-event-json
      (CodexReviewOutputEvent
        $findings
        $overall-correctness
        $overall-explanation
        $overall-confidence-score))
   (JsonObject
     ((JsonPair "findings" (codex:review-findings-json $findings))
     (JsonPair "overall_correctness" (JsonString $overall-correctness))
     (JsonPair "overall_explanation" (JsonString $overall-explanation))
     (JsonPair "overall_confidence_score" (JsonNumber $overall-confidence-score)))))

(= (codex:review-target-json
      (CodexReviewTargetUncommittedChanges))
   (JsonObject
     ((JsonPair "type" (JsonString "uncommittedChanges")))))

(= (codex:review-target-json
      (CodexReviewTargetBaseBranch $branch))
   (JsonObject
     ((JsonPair "type" (JsonString "baseBranch"))
      (JsonPair "branch" (JsonString $branch)))))

(= (codex:review-target-json
      (CodexReviewTargetCommit $sha $title))
   (JsonObject
     ((JsonPair "type" (JsonString "commit"))
      (JsonPair "sha" (JsonString $sha))
      (JsonPair
        "title"
        (if (== $title CodexAbsent)
            JsonNull
            (JsonString $title))))))

(= (codex:review-target-json
      (CodexReviewTargetCustom $instructions))
   (JsonObject
     ((JsonPair "type" (JsonString "custom"))
      (JsonPair "instructions" (JsonString $instructions)))))

(= (codex:review-request-json-pairs
      (CodexReviewRequest $target $user-facing-hint))
   (if (== $user-facing-hint CodexAbsent)
       ((JsonPair "target" (codex:review-target-json $target)))
       ((JsonPair "target" (codex:review-target-json $target))
        (JsonPair "user_facing_hint" (JsonString $user-facing-hint)))))

(= (codex:history-entry-json
      (CodexHistoryEntry $conversation-id $ts $text))
   (JsonObject
     ((JsonPair "conversation_id" (JsonString $conversation-id))
      (JsonPair "ts" (JsonNumber $ts))
      (JsonPair "text" (JsonString $text)))))

(= (codex:exec-policy-amendment-command
      (CodexExecPolicyAmendment $command))
   $command)

(= (codex:exec-policy-amendment-json
      (CodexExecPolicyAmendment $command))
   (codex:json-string-array $command))

(= (codex:network-policy-rule-action-json
      (CodexNetworkPolicyRuleActionAllow))
   (JsonString "allow"))

(= (codex:network-policy-rule-action-json
      (CodexNetworkPolicyRuleActionDeny))
   (JsonString "deny"))

(= (codex:network-policy-amendment-json
      (CodexNetworkPolicyAmendment $action $host))
   (JsonObject
     ((JsonPair "host" (JsonString $host))
      (JsonPair "action" (codex:network-policy-rule-action-json $action)))))

(= (codex:review-decision-json
      (CodexReviewDecisionApproved))
   (JsonString "approved"))

(= (codex:review-decision-json
      (CodexReviewDecisionApprovedExecpolicyAmendment
        $proposed-execpolicy-amendment))
   (JsonObject
     ((JsonPair
        "approved_execpolicy_amendment"
        (JsonObject
          ((JsonPair
             "proposed_execpolicy_amendment"
             (codex:exec-policy-amendment-json
               $proposed-execpolicy-amendment))))))))

(= (codex:review-decision-json
      (CodexReviewDecisionApprovedForSession))
   (JsonString "approved_for_session"))

(= (codex:review-decision-json
      (CodexReviewDecisionNetworkPolicyAmendment
        $network-policy-amendment))
   (JsonObject
     ((JsonPair
        "network_policy_amendment"
        (JsonObject
          ((JsonPair
             "network_policy_amendment"
             (codex:network-policy-amendment-json
               $network-policy-amendment))))))))

(= (codex:review-decision-json
      (CodexReviewDecisionDenied))
   (JsonString "denied"))

(= (codex:review-decision-json
      (CodexReviewDecisionTimedOut))
   (JsonString "timed_out"))

(= (codex:review-decision-json
      (CodexReviewDecisionAbort))
   (JsonString "abort"))

(= (codex:review-decisions-json $decisions)
   (JsonArray
     (map-atom $decisions $item (codex:review-decision-json $item))))

(= (codex:review-decision-opaque-string
      (CodexReviewDecisionApproved))
   "approved")

(= (codex:review-decision-opaque-string
      (CodexReviewDecisionApprovedExecpolicyAmendment
        $proposed-execpolicy-amendment))
   "approved_with_amendment")

(= (codex:review-decision-opaque-string
      (CodexReviewDecisionApprovedForSession))
   "approved_for_session")

(= (codex:review-decision-opaque-string
      (CodexReviewDecisionNetworkPolicyAmendment
        (CodexNetworkPolicyAmendment
          (CodexNetworkPolicyRuleActionAllow)
          $host)))
   "approved_with_network_policy_allow")

(= (codex:review-decision-opaque-string
      (CodexReviewDecisionNetworkPolicyAmendment
        (CodexNetworkPolicyAmendment
          (CodexNetworkPolicyRuleActionDeny)
          $host)))
   "denied_with_network_policy_deny")

(= (codex:review-decision-opaque-string
      (CodexReviewDecisionDenied))
   "denied")

(= (codex:review-decision-opaque-string
      (CodexReviewDecisionTimedOut))
   "timed_out")

(= (codex:review-decision-opaque-string
      (CodexReviewDecisionAbort))
   "abort")

(= (codex:file-change-json
      (CodexFileChangeAdd $content))
   (JsonObject
     ((JsonPair "type" (JsonString "add"))
      (JsonPair "content" (JsonString $content)))))

(= (codex:file-change-json
      (CodexFileChangeDelete $content))
   (JsonObject
     ((JsonPair "type" (JsonString "delete"))
      (JsonPair "content" (JsonString $content)))))

(= (codex:file-change-json
      (CodexFileChangeUpdate $unified-diff $move-path))
   (JsonObject
     ((JsonPair "type" (JsonString "update"))
      (JsonPair "unified_diff" (JsonString $unified-diff))
      (JsonPair
        "move_path"
        (if (== $move-path CodexAbsent)
            JsonNull
            (JsonString $move-path))))))

(= (codex:file-changes-json $changes)
   (JsonArray
     (map-atom $changes $item (codex:file-change-json $item))))

(= (codex:chunk-json
      (CodexChunk $orig-index $deleted-lines $inserted-lines))
   (JsonObject
     ((JsonPair "orig_index" (JsonNumber $orig-index))
      (JsonPair "deleted_lines" (codex:json-string-array $deleted-lines))
      (JsonPair "inserted_lines" (codex:json-string-array $inserted-lines)))))

(= (codex:chunks-json $chunks)
   (JsonArray
     (map-atom $chunks $item (codex:chunk-json $item))))

(= (codex:protocol-append-item $items $item)
   (list:append $items ($item)))

(= (codex:protocol-append-json-pair $pairs $key $value)
   (codex:protocol-append-item $pairs (JsonPair $key $value)))

(= (codex:optional-string-json $value)
   (if (== $value CodexAbsent)
       JsonNull
       (JsonString $value)))

(= (codex:skill-scope-json
      (CodexSkillScopeUser))
   (JsonString "user"))

(= (codex:skill-scope-json
      (CodexSkillScopeRepo))
   (JsonString "repo"))

(= (codex:skill-scope-json
      (CodexSkillScopeSystem))
   (JsonString "system"))

(= (codex:skill-scope-json
      (CodexSkillScopeAdmin))
   (JsonString "admin"))

(= (codex:skill-interface-json
      (CodexSkillInterface
        $display-name
        $short-description
        $icon-small
        $icon-large
        $brand-color
        $default-prompt))
   (JsonObject
     ((JsonPair "display_name" (codex:optional-string-json $display-name))
      (JsonPair "short_description" (codex:optional-string-json $short-description))
      (JsonPair "icon_small" (codex:optional-string-json $icon-small))
      (JsonPair "icon_large" (codex:optional-string-json $icon-large))
      (JsonPair "brand_color" (codex:optional-string-json $brand-color))
      (JsonPair "default_prompt" (codex:optional-string-json $default-prompt)))))

(= (codex:skill-tool-dependency-json-pairs
      (CodexSkillToolDependency
        $type
        $value
        $description
        $transport
        $command
        $url))
   (let $pairs-1
     ((JsonPair "type" (JsonString $type))
      (JsonPair "value" (JsonString $value)))
     (let $pairs-2
       (if (== $description CodexAbsent)
           $pairs-1
           (codex:protocol-append-json-pair
             $pairs-1
             "description"
             (JsonString $description)))
       (let $pairs-3
         (if (== $transport CodexAbsent)
             $pairs-2
             (codex:protocol-append-json-pair
               $pairs-2
               "transport"
               (JsonString $transport)))
         (let $pairs-4
           (if (== $command CodexAbsent)
               $pairs-3
               (codex:protocol-append-json-pair
                 $pairs-3
                 "command"
                 (JsonString $command)))
           (if (== $url CodexAbsent)
               $pairs-4
               (codex:protocol-append-json-pair
                 $pairs-4
                 "url"
                 (JsonString $url))))))))

(= (codex:skill-tool-dependency-json $dependency)
   (JsonObject (codex:skill-tool-dependency-json-pairs $dependency)))

(= (codex:skill-tool-dependencies-json $dependencies)
   (JsonArray
     (map-atom
       $dependencies
       $item
       (codex:skill-tool-dependency-json $item))))

(= (codex:skill-dependencies-json
      (CodexSkillDependencies $tools))
   (JsonObject
     ((JsonPair "tools" (codex:skill-tool-dependencies-json $tools)))))

(= (codex:skill-metadata-json-pairs
      (CodexSkillMetadata
        $name
        $description
        $short-description
        $interface
        $dependencies
        $path
        $scope
        $enabled))
   (let $pairs-1
     ((JsonPair "name" (JsonString $name))
      (JsonPair "description" (JsonString $description)))
     (let $pairs-2
       (if (== $short-description CodexAbsent)
           $pairs-1
           (codex:protocol-append-json-pair
             $pairs-1
             "short_description"
             (JsonString $short-description)))
       (let $pairs-3
         (if (== $interface CodexAbsent)
             $pairs-2
             (codex:protocol-append-json-pair
               $pairs-2
               "interface"
               (codex:skill-interface-json $interface)))
         (let $pairs-4
           (if (== $dependencies CodexAbsent)
               $pairs-3
               (codex:protocol-append-json-pair
                 $pairs-3
                 "dependencies"
                 (codex:skill-dependencies-json $dependencies)))
           (let $pairs-5
             (codex:protocol-append-json-pair
               $pairs-4
               "path"
               (JsonString $path))
             (let $pairs-6
               (codex:protocol-append-json-pair
                 $pairs-5
                 "scope"
                 (codex:skill-scope-json $scope))
               (codex:protocol-append-json-pair
                 $pairs-6
                 "enabled"
                 (JsonBool $enabled)))))))))

(= (codex:skill-metadata-json $skill)
   (JsonObject (codex:skill-metadata-json-pairs $skill)))

(= (codex:skill-metadatas-json $skills)
   (JsonArray
     (map-atom $skills $item (codex:skill-metadata-json $item))))

(= (codex:skill-error-info-json
      (CodexSkillErrorInfo $path $message))
   (JsonObject
     ((JsonPair "path" (JsonString $path))
      (JsonPair "message" (JsonString $message)))))

(= (codex:skill-error-infos-json $errors)
   (JsonArray
     (map-atom $errors $item (codex:skill-error-info-json $item))))

(= (codex:skills-list-entry-json
      (CodexSkillsListEntry $cwd $skills $errors))
   (JsonObject
     ((JsonPair "cwd" (JsonString $cwd))
      (JsonPair "skills" (codex:skill-metadatas-json $skills))
      (JsonPair "errors" (codex:skill-error-infos-json $errors)))))

(= (codex:skills-list-entries-json $entries)
   (JsonArray
     (map-atom $entries $item (codex:skills-list-entry-json $item))))

(= (codex:realtime-voice-json
      (CodexRealtimeVoiceAlloy))
   (JsonString "alloy"))

(= (codex:realtime-voice-json
      (CodexRealtimeVoiceArbor))
   (JsonString "arbor"))

(= (codex:realtime-voice-json
      (CodexRealtimeVoiceAsh))
   (JsonString "ash"))

(= (codex:realtime-voice-json
      (CodexRealtimeVoiceBallad))
   (JsonString "ballad"))

(= (codex:realtime-voice-json
      (CodexRealtimeVoiceBreeze))
   (JsonString "breeze"))

(= (codex:realtime-voice-json
      (CodexRealtimeVoiceCedar))
   (JsonString "cedar"))

(= (codex:realtime-voice-json
      (CodexRealtimeVoiceCoral))
   (JsonString "coral"))

(= (codex:realtime-voice-json
      (CodexRealtimeVoiceCove))
   (JsonString "cove"))

(= (codex:realtime-voice-json
      (CodexRealtimeVoiceEcho))
   (JsonString "echo"))

(= (codex:realtime-voice-json
      (CodexRealtimeVoiceEmber))
   (JsonString "ember"))

(= (codex:realtime-voice-json
      (CodexRealtimeVoiceJuniper))
   (JsonString "juniper"))

(= (codex:realtime-voice-json
      (CodexRealtimeVoiceMaple))
   (JsonString "maple"))

(= (codex:realtime-voice-json
      (CodexRealtimeVoiceMarin))
   (JsonString "marin"))

(= (codex:realtime-voice-json
      (CodexRealtimeVoiceSage))
   (JsonString "sage"))

(= (codex:realtime-voice-json
      (CodexRealtimeVoiceShimmer))
   (JsonString "shimmer"))

(= (codex:realtime-voice-json
      (CodexRealtimeVoiceSol))
   (JsonString "sol"))

(= (codex:realtime-voice-json
      (CodexRealtimeVoiceSpruce))
   (JsonString "spruce"))

(= (codex:realtime-voice-json
      (CodexRealtimeVoiceVale))
   (JsonString "vale"))

(= (codex:realtime-voice-json
      (CodexRealtimeVoiceVerse))
   (JsonString "verse"))

(= (codex:realtime-voices-json $voices)
   (JsonArray
     (map-atom $voices $item (codex:realtime-voice-json $item))))

(= (codex:realtime-conversation-version-json
      (CodexRealtimeConversationVersionV1))
   (JsonString "v1"))

(= (codex:realtime-conversation-version-json
      (CodexRealtimeConversationVersionV2))
   (JsonString "v2"))

(= (codex:realtime-output-modality-json
      (CodexRealtimeOutputModalityText))
   (JsonString "text"))

(= (codex:realtime-output-modality-json
      (CodexRealtimeOutputModalityAudio))
   (JsonString "audio"))

(= (codex:conversation-start-transport-json
      (CodexConversationStartTransportWebsocket))
   (JsonObject
     ((JsonPair "type" (JsonString "websocket")))))

(= (codex:conversation-start-transport-json
      (CodexConversationStartTransportWebrtc $sdp))
   (JsonObject
     ((JsonPair "type" (JsonString "webrtc"))
      (JsonPair "sdp" (JsonString $sdp)))))

(= (codex:conversation-start-params-json
      (CodexConversationStartParams
        $output-modality
        $prompt
        $session-id
        $transport
        $voice))
   (let $pairs-1
     ((JsonPair
        "output_modality"
        (codex:realtime-output-modality-json $output-modality)))
     (let $pairs-2
       (case $prompt
         ((CodexAbsent $pairs-1)
          (JsonNull
            (codex:protocol-append-json-pair
              $pairs-1
              "prompt"
              JsonNull))
          ($text
            (codex:protocol-append-json-pair
              $pairs-1
              "prompt"
              (JsonString $text)))))
       (let $pairs-3
         (if (== $session-id CodexAbsent)
             $pairs-2
             (codex:protocol-append-json-pair
               $pairs-2
               "session_id"
               (JsonString $session-id)))
         (let $pairs-4
           (if (== $transport CodexAbsent)
               $pairs-3
               (codex:protocol-append-json-pair
                 $pairs-3
                 "transport"
                 (codex:conversation-start-transport-json $transport)))
           (let $pairs-5
             (if (== $voice CodexAbsent)
                 $pairs-4
                 (codex:protocol-append-json-pair
                   $pairs-4
                   "voice"
                   (codex:realtime-voice-json $voice)))
             (JsonObject $pairs-5)))))))

(= (codex:conversation-audio-params-json
      (CodexConversationAudioParams $frame))
   (JsonObject
     ((JsonPair "frame" (codex:realtime-audio-frame-json $frame)))))

(= (codex:conversation-text-params-json
      (CodexConversationTextParams $text))
   (JsonObject
     ((JsonPair "text" (JsonString $text)))))

(= (codex:realtime-audio-frame-json
      (CodexRealtimeAudioFrame
        $data
        $sample-rate
        $num-channels
        $samples-per-channel
        $item-id))
   (let $pairs-1
     ((JsonPair "data" (JsonString $data))
      (JsonPair "sample_rate" (JsonNumber $sample-rate))
      (JsonPair "num_channels" (JsonNumber $num-channels)))
     (let $pairs-2
       (if (== $samples-per-channel CodexAbsent)
           $pairs-1
           (codex:protocol-append-json-pair
             $pairs-1
             "samples_per_channel"
             (JsonNumber $samples-per-channel)))
       (let $pairs-3
         (if (== $item-id CodexAbsent)
             $pairs-2
             (codex:protocol-append-json-pair
               $pairs-2
               "item_id"
               (JsonString $item-id)))
         (JsonObject $pairs-3)))))

(= (codex:realtime-transcript-delta-json
      (CodexRealtimeTranscriptDelta $delta))
   (JsonObject
     ((JsonPair "delta" (JsonString $delta)))))

(= (codex:realtime-transcript-done-json
      (CodexRealtimeTranscriptDone $text))
   (JsonObject
     ((JsonPair "text" (JsonString $text)))))

(= (codex:realtime-transcript-entry-json
      (CodexRealtimeTranscriptEntry $role $text))
   (JsonObject
     ((JsonPair "role" (JsonString $role))
      (JsonPair "text" (JsonString $text)))))

(= (codex:realtime-transcript-entries-json $entries)
   (JsonArray
     (eval (map-atom $entries $item (codex:realtime-transcript-entry-json $item)))))

(= (codex:realtime-handoff-requested-json
      (CodexRealtimeHandoffRequested
        $handoff-id
        $item-id
        $input-transcript
        $active-transcript))
   (JsonObject
     ((JsonPair "handoff_id" (JsonString $handoff-id))
      (JsonPair "item_id" (JsonString $item-id))
      (JsonPair "input_transcript" (JsonString $input-transcript))
      (JsonPair
        "active_transcript"
        (codex:realtime-transcript-entries-json $active-transcript)))))

(= (codex:realtime-noop-requested-json
      (CodexRealtimeNoopRequested $call-id $item-id))
   (JsonObject
     ((JsonPair "call_id" (JsonString $call-id))
      (JsonPair "item_id" (JsonString $item-id)))))

(= (codex:realtime-input-audio-speech-started-json
      (CodexRealtimeInputAudioSpeechStarted $item-id))
   (JsonObject
     ((JsonPair
        "item_id"
        (if (== $item-id CodexAbsent)
            JsonNull
            (JsonString $item-id))))))

(= (codex:realtime-response-cancelled-json
      (CodexRealtimeResponseCancelled $response-id))
   (JsonObject
     ((JsonPair
        "response_id"
        (if (== $response-id CodexAbsent)
            JsonNull
            (JsonString $response-id))))))

(= (codex:realtime-response-created-json
      (CodexRealtimeResponseCreated $response-id))
   (JsonObject
     ((JsonPair
        "response_id"
        (if (== $response-id CodexAbsent)
            JsonNull
            (JsonString $response-id))))))

(= (codex:realtime-response-done-json
      (CodexRealtimeResponseDone $response-id))
   (JsonObject
     ((JsonPair
        "response_id"
        (if (== $response-id CodexAbsent)
            JsonNull
            (JsonString $response-id))))))

(= (codex:realtime-event-json
      (CodexRealtimeEventSessionUpdated $session-id $instructions))
   (JsonObject
     ((JsonPair
        "SessionUpdated"
        (JsonObject
          ((JsonPair "session_id" (JsonString $session-id))
           (JsonPair
             "instructions"
             (if (== $instructions CodexAbsent)
                 JsonNull
                 (JsonString $instructions)))))))))

(= (codex:realtime-event-json
      (CodexRealtimeEventInputAudioSpeechStarted $event))
   (JsonObject
     ((JsonPair
        "InputAudioSpeechStarted"
        (codex:realtime-input-audio-speech-started-json $event)))))

(= (codex:realtime-event-json
      (CodexRealtimeEventInputTranscriptDelta $event))
   (JsonObject
     ((JsonPair
        "InputTranscriptDelta"
        (codex:realtime-transcript-delta-json $event)))))

(= (codex:realtime-event-json
      (CodexRealtimeEventInputTranscriptDone $event))
   (JsonObject
     ((JsonPair
        "InputTranscriptDone"
        (codex:realtime-transcript-done-json $event)))))

(= (codex:realtime-event-json
      (CodexRealtimeEventOutputTranscriptDelta $event))
   (JsonObject
     ((JsonPair
        "OutputTranscriptDelta"
        (codex:realtime-transcript-delta-json $event)))))

(= (codex:realtime-event-json
      (CodexRealtimeEventOutputTranscriptDone $event))
   (JsonObject
     ((JsonPair
        "OutputTranscriptDone"
        (codex:realtime-transcript-done-json $event)))))

(= (codex:realtime-event-json
      (CodexRealtimeEventAudioOut $event))
   (JsonObject
     ((JsonPair
        "AudioOut"
        (codex:realtime-audio-frame-json $event)))))

(= (codex:realtime-event-json
      (CodexRealtimeEventResponseCreated $event))
   (JsonObject
     ((JsonPair
        "ResponseCreated"
        (codex:realtime-response-created-json $event)))))

(= (codex:realtime-event-json
      (CodexRealtimeEventResponseCancelled $event))
   (JsonObject
     ((JsonPair
        "ResponseCancelled"
        (codex:realtime-response-cancelled-json $event)))))

(= (codex:realtime-event-json
      (CodexRealtimeEventResponseDone $event))
   (JsonObject
     ((JsonPair
        "ResponseDone"
        (codex:realtime-response-done-json $event)))))

(= (codex:realtime-event-json
      (CodexRealtimeEventConversationItemAdded $item))
   (JsonObject
     ((JsonPair "ConversationItemAdded" $item))))

(= (codex:realtime-event-json
      (CodexRealtimeEventConversationItemDone $item-id))
   (JsonObject
     ((JsonPair
        "ConversationItemDone"
        (JsonObject
          ((JsonPair "item_id" (JsonString $item-id))))))))

(= (codex:realtime-event-json
      (CodexRealtimeEventHandoffRequested $event))
   (JsonObject
     ((JsonPair
        "HandoffRequested"
        (codex:realtime-handoff-requested-json $event)))))

(= (codex:realtime-event-json
      (CodexRealtimeEventNoopRequested $event))
   (JsonObject
     ((JsonPair
        "NoopRequested"
        (codex:realtime-noop-requested-json $event)))))

(= (codex:realtime-event-json
      (CodexRealtimeEventError $message))
   (JsonObject
     ((JsonPair "Error" (JsonString $message)))))

(= (codex:realtime-voices-list-json
      (CodexRealtimeVoicesList $v1 $v2 $default-v1 $default-v2))
   (JsonObject
     ((JsonPair "v1" (codex:realtime-voices-json $v1))
      (JsonPair "v2" (codex:realtime-voices-json $v2))
      (JsonPair "defaultV1" (codex:realtime-voice-json $default-v1))
      (JsonPair "defaultV2" (codex:realtime-voice-json $default-v2)))))

(= (codex:compacted-item-json
      (CodexCompactedItem $message $replacement-history))
   (let $pairs
     ((JsonPair "message" (JsonString $message)))
     (JsonObject
       (if (== $replacement-history CodexAbsent)
           $pairs
           (codex:protocol-append-json-pair
             $pairs
             "replacement_history"
             (codex:items-json $replacement-history))))))

(= (codex:turn-context-network-item-json
      (CodexTurnContextNetworkItem $allowed-domains $denied-domains))
   (JsonObject
     ((JsonPair
        "allowed_domains"
        (JsonArray
          (eval (map-atom $allowed-domains $domain (JsonString $domain)))))
      (JsonPair
        "denied_domains"
        (JsonArray
          (eval (map-atom $denied-domains $domain (JsonString $domain))))))))

(= (codex:truncation-policy-json
      (CodexTruncationPolicyBytes $bytes))
   (JsonObject
     ((JsonPair "mode" (JsonString "bytes"))
      (JsonPair "limit" (JsonNumber $bytes)))))

(= (codex:truncation-policy-json
      (CodexTruncationPolicyTokens $tokens))
   (JsonObject
     ((JsonPair "mode" (JsonString "tokens"))
      (JsonPair "limit" (JsonNumber $tokens)))))

; CeTTa evaluator detail: normalize the incoming product first so nested callers
; like `product-json (product-from-session-source-name ...)` reduce to the same
; Rust-visible wire string as already-materialized constructors.
(= (codex:product-json-unresolved
      (codex:product-from-session-source-name $value))
   (let $normalized (codex:product-ascii-lower-text (str-trim $value))
     (if (== $normalized "chatgpt")
         (JsonString "chatgpt")
         (if (== $normalized "codex")
             (JsonString "codex")
             (if (== $normalized "atlas")
                 (JsonString "atlas")
                 Empty)))))

(= (codex:product-json $product)
   (let $resolved (once $product)
     (case $resolved
       (((CodexProductChatgpt) (JsonString "chatgpt"))
        ((CodexProductCodex) (JsonString "codex"))
        ((CodexProductAtlas) (JsonString "atlas"))
        ($other (codex:product-json-unresolved $product))))))

(= (codex:product-to-app-platform
      (CodexProductChatgpt))
   "chat")

(= (codex:product-to-app-platform
      (CodexProductCodex))
   "codex")

(= (codex:product-to-app-platform
      (CodexProductAtlas))
   "atlas")

(= (codex:product-ascii-lower-char $char)
   (case $char
     (("A" "a")
      ("B" "b")
      ("C" "c")
      ("D" "d")
      ("E" "e")
      ("F" "f")
      ("G" "g")
      ("H" "h")
      ("I" "i")
      ("J" "j")
      ("K" "k")
      ("L" "l")
      ("M" "m")
      ("N" "n")
      ("O" "o")
      ("P" "p")
      ("Q" "q")
      ("R" "r")
      ("S" "s")
      ("T" "t")
      ("U" "u")
      ("V" "v")
      ("W" "w")
      ("X" "x")
      ("Y" "y")
      ("Z" "z")
      ($other $other))))

(= (codex:product-ascii-lower-text $text)
   (if (== $text "")
       ""
       (str-concat
         (codex:product-ascii-lower-char
           (str-slice $text 0 1))
         (codex:product-ascii-lower-text
           (str-slice $text 1 (str-length $text))))))

; CeTTa deviation: Rust returns `Option<Product>` here. This restart surface
; uses `CodexAbsent` for the no-product case.
; CeTTa evaluator detail: this public constructor boundary is forced through
; `once` so nested consumers like `product-json` observe the normalized product
; constructor rather than the unreduced normalization term.
(= (codex:product-from-session-source-name $value)
   (once
     (let $normalized (codex:product-ascii-lower-text (str-trim $value))
       (if (== $normalized "chatgpt")
           (CodexProductChatgpt)
           (if (== $normalized "codex")
               (CodexProductCodex)
               (if (== $normalized "atlas")
                   (CodexProductAtlas)
                   CodexAbsent))))))

(= (codex:subagent-source-display
      (CodexSubAgentSourceReview))
   "review")

(= (codex:subagent-source-display
      (CodexSubAgentSourceCompact))
   "compact")

(= (codex:subagent-source-display
      (CodexSubAgentSourceThreadSpawn
        $parent-thread-id
        $depth
        $agent-path
        $agent-nickname
        $agent-role))
   (format-args "thread_spawn_{}_d{}" ($parent-thread-id $depth)))

(= (codex:subagent-source-display
      (CodexSubAgentSourceMemoryConsolidation))
   "memory_consolidation")

(= (codex:subagent-source-display
      (CodexSubAgentSourceOther $other))
   $other)

(= (codex:session-source-display
      (CodexSessionSourceCli))
   "cli")

(= (codex:session-source-display
      (CodexSessionSourceVSCode))
   "vscode")

(= (codex:session-source-display
      (CodexSessionSourceExec))
   "exec")

(= (codex:session-source-display
      (CodexSessionSourceMcp))
   "mcp")

(= (codex:session-source-display
      (CodexSessionSourceCustom $source))
   $source)

(= (codex:session-source-display
      (CodexSessionSourceSubAgent $sub-source))
   (str-concat "subagent_" (codex:subagent-source-display $sub-source)))

(= (codex:session-source-display
      (CodexSessionSourceUnknown))
   "unknown")

; CeTTa evaluator detail: this public constructor boundary is forced through
; `once` to collapse duplicate equivalent reductions from the recursive
; normalization path. The visible Rust result surface is unchanged.
(= (codex:session-source-from-startup-arg $value)
   (once
     (let $trimmed (str-trim $value)
       (if (== $trimmed "")
           (codex:session-source-err "session source must not be empty")
           (let $normalized (codex:product-ascii-lower-text $trimmed)
             (codex:session-source-ok
               (if (== $normalized "cli")
                   (codex:session-source-cli)
                   (if (== $normalized "vscode")
                       (codex:session-source-vscode)
                       (if (== $normalized "exec")
                           (codex:session-source-exec)
                           (if (or (== $normalized "mcp")
                                   (or (== $normalized "appserver")
                                       (or (== $normalized "app-server")
                                           (== $normalized "app_server"))))
                               (codex:session-source-mcp)
                               (if (== $normalized "unknown")
                                   (codex:session-source-unknown)
                                   (codex:session-source-custom $normalized))))))))))))

(= (codex:session-source-thread-source-name
      (CodexSessionSourceCli))
   "user")

(= (codex:session-source-thread-source-name
      (CodexSessionSourceVSCode))
   "user")

(= (codex:session-source-thread-source-name
      (CodexSessionSourceExec))
   "user")

(= (codex:session-source-thread-source-name
      (CodexSessionSourceSubAgent $sub-source))
   "subagent")

(= (codex:session-source-thread-source-name
      (CodexSessionSourceMcp))
   CodexAbsent)

(= (codex:session-source-thread-source-name
      (CodexSessionSourceCustom $source))
   CodexAbsent)

(= (codex:session-source-thread-source-name
      (CodexSessionSourceUnknown))
   CodexAbsent)

(= (codex:subagent-source-get-nickname
      (CodexSubAgentSourceReview))
   CodexAbsent)

(= (codex:subagent-source-get-nickname
      (CodexSubAgentSourceCompact))
   CodexAbsent)

(= (codex:subagent-source-get-nickname
      (CodexSubAgentSourceThreadSpawn
        $parent-thread-id
        $depth
        $agent-path
        $agent-nickname
        $agent-role))
   $agent-nickname)

(= (codex:subagent-source-get-nickname
      (CodexSubAgentSourceMemoryConsolidation))
   "Morpheus")

(= (codex:subagent-source-get-nickname
      (CodexSubAgentSourceOther $other))
   CodexAbsent)

(= (codex:session-source-get-nickname
      (CodexSessionSourceSubAgent $sub-source))
   (codex:subagent-source-get-nickname $sub-source))

(= (codex:session-source-get-nickname
      (CodexSessionSourceCli))
   CodexAbsent)

(= (codex:session-source-get-nickname
      (CodexSessionSourceVSCode))
   CodexAbsent)

(= (codex:session-source-get-nickname
      (CodexSessionSourceExec))
   CodexAbsent)

(= (codex:session-source-get-nickname
      (CodexSessionSourceMcp))
   CodexAbsent)

(= (codex:session-source-get-nickname
      (CodexSessionSourceCustom $source))
   CodexAbsent)

(= (codex:session-source-get-nickname
      (CodexSessionSourceUnknown))
   CodexAbsent)

(= (codex:subagent-source-get-agent-role
      (CodexSubAgentSourceReview))
   CodexAbsent)

(= (codex:subagent-source-get-agent-role
      (CodexSubAgentSourceCompact))
   CodexAbsent)

(= (codex:subagent-source-get-agent-role
      (CodexSubAgentSourceThreadSpawn
        $parent-thread-id
        $depth
        $agent-path
        $agent-nickname
        $agent-role))
   $agent-role)

(= (codex:subagent-source-get-agent-role
      (CodexSubAgentSourceMemoryConsolidation))
   "memory builder")

(= (codex:subagent-source-get-agent-role
      (CodexSubAgentSourceOther $other))
   CodexAbsent)

(= (codex:session-source-get-agent-role
      (CodexSessionSourceSubAgent $sub-source))
   (codex:subagent-source-get-agent-role $sub-source))

(= (codex:session-source-get-agent-role
      (CodexSessionSourceCli))
   CodexAbsent)

(= (codex:session-source-get-agent-role
      (CodexSessionSourceVSCode))
   CodexAbsent)

(= (codex:session-source-get-agent-role
      (CodexSessionSourceExec))
   CodexAbsent)

(= (codex:session-source-get-agent-role
      (CodexSessionSourceMcp))
   CodexAbsent)

(= (codex:session-source-get-agent-role
      (CodexSessionSourceCustom $source))
   CodexAbsent)

(= (codex:session-source-get-agent-role
      (CodexSessionSourceUnknown))
   CodexAbsent)

(= (codex:subagent-source-get-agent-path
      (CodexSubAgentSourceReview))
   CodexAbsent)

(= (codex:subagent-source-get-agent-path
      (CodexSubAgentSourceCompact))
   CodexAbsent)

(= (codex:subagent-source-get-agent-path
      (CodexSubAgentSourceThreadSpawn
        $parent-thread-id
        $depth
        $agent-path
        $agent-nickname
        $agent-role))
   $agent-path)

(= (codex:subagent-source-get-agent-path
      (CodexSubAgentSourceMemoryConsolidation))
   (codex:agent-path-morpheus))

(= (codex:subagent-source-get-agent-path
      (CodexSubAgentSourceOther $other))
   CodexAbsent)

(= (codex:session-source-get-agent-path
      (CodexSessionSourceSubAgent $sub-source))
   (codex:subagent-source-get-agent-path $sub-source))

(= (codex:session-source-get-agent-path
      (CodexSessionSourceCli))
   CodexAbsent)

(= (codex:session-source-get-agent-path
      (CodexSessionSourceVSCode))
   CodexAbsent)

(= (codex:session-source-get-agent-path
      (CodexSessionSourceExec))
   CodexAbsent)

(= (codex:session-source-get-agent-path
      (CodexSessionSourceMcp))
   CodexAbsent)

(= (codex:session-source-get-agent-path
      (CodexSessionSourceCustom $source))
   CodexAbsent)

(= (codex:session-source-get-agent-path
      (CodexSessionSourceUnknown))
   CodexAbsent)

(= (codex:session-source-restriction-product
      (CodexSessionSourceCustom $source))
   (codex:product-from-session-source-name $source))

(= (codex:session-source-restriction-product
      (CodexSessionSourceCli))
   (codex:product-codex))

(= (codex:session-source-restriction-product
      (CodexSessionSourceVSCode))
   (codex:product-codex))

(= (codex:session-source-restriction-product
      (CodexSessionSourceExec))
   (codex:product-codex))

(= (codex:session-source-restriction-product
      (CodexSessionSourceMcp))
   (codex:product-codex))

(= (codex:session-source-restriction-product
      (CodexSessionSourceUnknown))
   (codex:product-codex))

(= (codex:session-source-restriction-product
      (CodexSessionSourceSubAgent $sub-source))
   CodexAbsent)

(= (codex:session-source-matches-product-restriction $source $products)
   (if (== $products ())
       True
       (let $product (codex:session-source-restriction-product $source)
         (if (== $product CodexAbsent)
             False
             (codex:product-matches-product-restriction
               $product
               $products)))))

(= (codex:product-list-contains $products $needle)
   (if (== $products ())
       False
       (if (== (list:first $products) $needle)
           True
           (codex:product-list-contains
             (list:rest $products)
             $needle))))

(= (codex:product-matches-product-restriction $product $products)
   (if (== $products ())
       True
       (codex:product-list-contains $products $product)))

(= (codex:append-optional-json-string-pair $pairs $key $value)
   (if (== $value CodexAbsent)
       $pairs
       (codex:protocol-append-json-pair $pairs $key (JsonString $value))))

(= (codex:append-optional-json-value-pair $pairs $key $value)
   (if (== $value CodexAbsent)
       $pairs
       (codex:protocol-append-json-pair $pairs $key $value)))

(= (codex:json-string-array $items)
   (JsonArray
     (map-atom $items $item (JsonString $item))))

(= (codex:session-approvals-reviewer-json
      (CodexSessionApprovalsReviewerUser))
   (JsonString "user"))

(= (codex:session-approvals-reviewer-json
      (CodexSessionApprovalsReviewerAutoReview))
   (JsonString "guardian_subagent"))

(= (codex:session-service-tier-json
      (CodexSessionServiceTierFast))
   (JsonString "fast"))

(= (codex:session-service-tier-json
      (CodexSessionServiceTierFlex))
   (JsonString "flex"))

(= (codex:session-reasoning-effort-json
      (CodexSessionReasoningEffortNone))
   (JsonString "none"))

(= (codex:session-reasoning-effort-json
      (CodexSessionReasoningEffortMinimal))
   (JsonString "minimal"))

(= (codex:session-reasoning-effort-json
      (CodexSessionReasoningEffortLow))
   (JsonString "low"))

(= (codex:session-reasoning-effort-json
      (CodexSessionReasoningEffortMedium))
   (JsonString "medium"))

(= (codex:session-reasoning-effort-json
      (CodexSessionReasoningEffortHigh))
   (JsonString "high"))

(= (codex:session-reasoning-effort-json
      (CodexSessionReasoningEffortXHigh))
   (JsonString "xhigh"))

(= (codex:session-approval-policy-json
      (CodexSessionApprovalPolicyUnlessTrusted))
   (JsonString "untrusted"))

(= (codex:session-approval-policy-json
      (CodexSessionApprovalPolicyOnFailure))
   (JsonString "on-failure"))

(= (codex:session-approval-policy-json
      (CodexSessionApprovalPolicyOnRequest))
   (JsonString "on-request"))

(= (codex:session-approval-policy-json
      (CodexSessionApprovalPolicyNever))
   (JsonString "never"))

(= (codex:session-granular-approval-config-json
      (CodexSessionGranularApprovalConfig
        $sandbox-approval
        $rules
        $skill-approval
        $request-permissions
        $mcp-elicitations))
   (JsonObject
     ((JsonPair "sandbox_approval" (JsonBool $sandbox-approval))
      (JsonPair "rules" (JsonBool $rules))
      (JsonPair "skill_approval" (JsonBool $skill-approval))
      (JsonPair "request_permissions" (JsonBool $request-permissions))
      (JsonPair "mcp_elicitations" (JsonBool $mcp-elicitations)))))

(= (codex:session-approval-policy-json
      (CodexSessionApprovalPolicyGranular $config))
   (JsonObject
     ((JsonPair "granular" (codex:session-granular-approval-config-json $config)))))

(= (codex:session-network-access-json
      (CodexSessionNetworkAccessRestricted))
   (JsonString "restricted"))

(= (codex:session-network-access-json
      (CodexSessionNetworkAccessEnabled))
   (JsonString "enabled"))

(= (codex:session-read-only-access-json
      (CodexSessionReadOnlyAccessFull))
   (JsonObject
     ((JsonPair "type" (JsonString "full-access")))))

(= (codex:session-read-only-access-json
      (CodexSessionReadOnlyAccessRestricted
        $include-platform-defaults
        $readable-roots))
   (let $pairs-1
     ((JsonPair "type" (JsonString "restricted"))
      (JsonPair
        "include_platform_defaults"
        (JsonBool $include-platform-defaults)))
     (let $pairs-2
       (if (== $readable-roots ())
           $pairs-1
           (codex:protocol-append-json-pair
             $pairs-1
             "readable_roots"
             (codex:json-string-array $readable-roots)))
       (JsonObject $pairs-2))))

(= (codex:session-sandbox-policy-json
      (CodexSessionSandboxPolicyDangerFullAccess))
   (JsonObject
     ((JsonPair "type" (JsonString "danger-full-access")))))

(= (codex:session-sandbox-policy-json
      (CodexSessionSandboxPolicyReadOnly $access $network-access))
   (let $pairs-1
     ((JsonPair "type" (JsonString "read-only")))
     (let $pairs-2
       (if (== $access (CodexSessionReadOnlyAccessFull))
           $pairs-1
           (codex:protocol-append-json-pair
             $pairs-1
             "access"
             (codex:session-read-only-access-json $access)))
       (let $pairs-3
         (if $network-access
             (codex:protocol-append-json-pair
               $pairs-2
               "network_access"
               (JsonBool $network-access))
             $pairs-2)
         (JsonObject $pairs-3)))))

(= (codex:session-sandbox-policy-json
      (CodexSessionSandboxPolicyExternalSandbox $network-access))
   (JsonObject
     ((JsonPair "type" (JsonString "external-sandbox"))
      (JsonPair
        "network_access"
        (codex:session-network-access-json $network-access)))))

(= (codex:session-sandbox-policy-json
      (CodexSessionSandboxPolicyWorkspaceWrite
        $writable-roots
        $read-only-access
        $network-access
        $exclude-tmpdir-env-var
        $exclude-slash-tmp))
   (let $pairs-1
     ((JsonPair "type" (JsonString "workspace-write")))
     (let $pairs-2
       (if (== $writable-roots ())
           $pairs-1
           (codex:protocol-append-json-pair
             $pairs-1
             "writable_roots"
             (codex:json-string-array $writable-roots)))
       (let $pairs-3
         (if (== $read-only-access (CodexSessionReadOnlyAccessFull))
             $pairs-2
             (codex:protocol-append-json-pair
               $pairs-2
               "read_only_access"
               (codex:session-read-only-access-json $read-only-access)))
         (let $pairs-4
           (codex:protocol-append-json-pair
             $pairs-3
             "network_access"
             (JsonBool $network-access))
           (let $pairs-5
             (codex:protocol-append-json-pair
               $pairs-4
               "exclude_tmpdir_env_var"
               (JsonBool $exclude-tmpdir-env-var))
             (let $pairs-6
               (codex:protocol-append-json-pair
                 $pairs-5
                 "exclude_slash_tmp"
                 (JsonBool $exclude-slash-tmp))
               (JsonObject $pairs-6))))))))

(= (codex:session-network-sandbox-policy-json
      (CodexSessionNetworkSandboxPolicyRestricted))
   (JsonString "restricted"))

(= (codex:session-network-sandbox-policy-json
      (CodexSessionNetworkSandboxPolicyEnabled))
   (JsonString "enabled"))

(= (codex:session-network-proxy-runtime-json
      (CodexSessionNetworkProxyRuntime $http-addr $socks-addr))
   (JsonObject
     ((JsonPair "http_addr" (JsonString $http-addr))
      (JsonPair "socks_addr" (JsonString $socks-addr)))))

(= (codex:patch-apply-file-change-json
      (CodexProtocolPatchApplyFileChangeAdd $path $content))
   (JsonObject
     ((JsonPair "type" (JsonString "add"))
      (JsonPair "content" (JsonString $content)))))

(= (codex:patch-apply-file-change-json
      (CodexProtocolPatchApplyFileChangeDelete $path $content))
   (JsonObject
     ((JsonPair "type" (JsonString "delete"))
      (JsonPair "content" (JsonString $content)))))

(= (codex:patch-apply-file-change-json
      (CodexProtocolPatchApplyFileChangeUpdate $path $unified-diff $move-path))
   (JsonObject
     ((JsonPair "type" (JsonString "update"))
      (JsonPair "unified_diff" (JsonString $unified-diff))
      (JsonPair
        "move_path"
        (if (== $move-path CodexAbsent)
            JsonNull
            (JsonString $move-path))))))

(= (codex:patch-apply-file-change-json-pair
      (CodexProtocolPatchApplyFileChangeAdd $path $content))
   (JsonPair $path
     (codex:patch-apply-file-change-json
       (CodexProtocolPatchApplyFileChangeAdd $path $content))))

(= (codex:patch-apply-file-change-json-pair
      (CodexProtocolPatchApplyFileChangeDelete $path $content))
   (JsonPair $path
     (codex:patch-apply-file-change-json
       (CodexProtocolPatchApplyFileChangeDelete $path $content))))

(= (codex:patch-apply-file-change-json-pair
      (CodexProtocolPatchApplyFileChangeUpdate $path $unified-diff $move-path))
   (JsonPair $path
     (codex:patch-apply-file-change-json
       (CodexProtocolPatchApplyFileChangeUpdate
         $path
         $unified-diff
         $move-path))))

(= (codex:patch-apply-file-changes-json $changes)
   (JsonObject
     (map-atom $changes $item (codex:patch-apply-file-change-json-pair $item))))

(= (codex:patch-apply-status-json
      (CodexPatchApplyStatusCompleted))
   (JsonString "completed"))

(= (codex:patch-apply-status-json
      (CodexPatchApplyStatusFailed))
   (JsonString "failed"))

(= (codex:patch-apply-status-json
      (CodexPatchApplyStatusDeclined))
   (JsonString "declined"))

(= (codex:hook-event-name-json
      (CodexHookEventNamePreToolUse))
   (JsonString "pre_tool_use"))

(= (codex:hook-event-name-json
      (CodexHookEventNamePermissionRequest))
   (JsonString "permission_request"))

(= (codex:hook-event-name-json
      (CodexHookEventNamePostToolUse))
   (JsonString "post_tool_use"))

(= (codex:hook-event-name-json
      (CodexHookEventNameSessionStart))
   (JsonString "session_start"))

(= (codex:hook-event-name-json
      (CodexHookEventNameUserPromptSubmit))
   (JsonString "user_prompt_submit"))

(= (codex:hook-event-name-json
      (CodexHookEventNameStop))
   (JsonString "stop"))

(= (codex:hook-handler-type-json
      (CodexHookHandlerTypeCommand))
   (JsonString "command"))

(= (codex:hook-handler-type-json
      (CodexHookHandlerTypePrompt))
   (JsonString "prompt"))

(= (codex:hook-handler-type-json
      (CodexHookHandlerTypeAgent))
   (JsonString "agent"))

(= (codex:hook-execution-mode-json
      (CodexHookExecutionModeSync))
   (JsonString "sync"))

(= (codex:hook-execution-mode-json
      (CodexHookExecutionModeAsync))
   (JsonString "async"))

(= (codex:hook-scope-json
      (CodexHookScopeThread))
   (JsonString "thread"))

(= (codex:hook-scope-json
      (CodexHookScopeTurn))
   (JsonString "turn"))

(= (codex:hook-source-json
      (CodexHookSourceSystem))
   (JsonString "system"))

(= (codex:hook-source-json
      (CodexHookSourceUser))
   (JsonString "user"))

(= (codex:hook-source-json
      (CodexHookSourceProject))
   (JsonString "project"))

(= (codex:hook-source-json
      (CodexHookSourceMdm))
   (JsonString "mdm"))

(= (codex:hook-source-json
      (CodexHookSourceSessionFlags))
   (JsonString "session_flags"))

(= (codex:hook-source-json
      (CodexHookSourceLegacyManagedConfigFile))
   (JsonString "legacy_managed_config_file"))

(= (codex:hook-source-json
      (CodexHookSourceLegacyManagedConfigMdm))
   (JsonString "legacy_managed_config_mdm"))

(= (codex:hook-source-json
      (CodexHookSourceUnknown))
   (JsonString "unknown"))

(= (codex:hook-run-status-json
      (CodexHookRunStatusRunning))
   (JsonString "running"))

(= (codex:hook-run-status-json
      (CodexHookRunStatusCompleted))
   (JsonString "completed"))

(= (codex:hook-run-status-json
      (CodexHookRunStatusFailed))
   (JsonString "failed"))

(= (codex:hook-run-status-json
      (CodexHookRunStatusBlocked))
   (JsonString "blocked"))

(= (codex:hook-run-status-json
      (CodexHookRunStatusStopped))
   (JsonString "stopped"))

(= (codex:hook-output-entry-kind-json
      (CodexHookOutputEntryKindWarning))
   (JsonString "warning"))

(= (codex:hook-output-entry-kind-json
      (CodexHookOutputEntryKindStop))
   (JsonString "stop"))

(= (codex:hook-output-entry-kind-json
      (CodexHookOutputEntryKindFeedback))
   (JsonString "feedback"))

(= (codex:hook-output-entry-kind-json
      (CodexHookOutputEntryKindContext))
   (JsonString "context"))

(= (codex:hook-output-entry-kind-json
      (CodexHookOutputEntryKindError))
   (JsonString "error"))

(= (codex:hook-output-entry-json
      (CodexHookOutputEntry $kind $text))
   (JsonObject
     ((JsonPair "kind" (codex:hook-output-entry-kind-json $kind))
      (JsonPair "text" (JsonString $text)))))

(= (codex:hook-output-entries-json $entries)
   (JsonArray
     (map-atom $entries $item (codex:hook-output-entry-json $item))))

(= (codex:hook-run-summary-json
      (CodexHookRunSummary
        $id
        $event-name
        $handler-type
        $execution-mode
        $scope
        $source-path
        $source
        $display-order
        $status
        $status-message
        $started-at
        $completed-at
        $duration-ms
        $entries))
   (JsonObject
     ((JsonPair "id" (JsonString $id))
      (JsonPair "event_name" (codex:hook-event-name-json $event-name))
      (JsonPair "handler_type" (codex:hook-handler-type-json $handler-type))
      (JsonPair "execution_mode" (codex:hook-execution-mode-json $execution-mode))
      (JsonPair "scope" (codex:hook-scope-json $scope))
      (JsonPair "source_path" (JsonString $source-path))
      (JsonPair "source" (codex:hook-source-json $source))
      (JsonPair "display_order" (JsonNumber $display-order))
      (JsonPair "status" (codex:hook-run-status-json $status))
      (JsonPair
        "status_message"
        (if (== $status-message CodexAbsent)
            JsonNull
            (JsonString $status-message)))
      (JsonPair "started_at" (JsonNumber $started-at))
      (JsonPair
        "completed_at"
        (if (== $completed-at CodexAbsent)
            JsonNull
            (JsonNumber $completed-at)))
      (JsonPair
        "duration_ms"
        (if (== $duration-ms CodexAbsent)
            JsonNull
            (JsonNumber $duration-ms)))
      (JsonPair "entries" (codex:hook-output-entries-json $entries)))))

(= (codex:plan-update-step-status-json
      (CodexUpdatePlanStepStatusPending))
   (JsonString "pending"))

(= (codex:plan-update-step-status-json
      (CodexUpdatePlanStepStatusInProgress))
   (JsonString "in_progress"))

(= (codex:plan-update-step-status-json
      (CodexUpdatePlanStepStatusCompleted))
   (JsonString "completed"))

(= (codex:plan-update-step-json
      (CodexUpdatePlanStep $step $status))
   (JsonObject
     ((JsonPair "step" (JsonString $step))
      (JsonPair "status" (codex:plan-update-step-status-json $status)))))

(= (codex:plan-update-steps-json $steps)
   (JsonArray
     (map-atom $steps $item (codex:plan-update-step-json $item))))

(= (codex:token-usage-json
      (CodexTokenUsage
        $input-tokens
        $cached-input-tokens
        $output-tokens
        $reasoning-output-tokens
        $total-tokens))
   (JsonObject
     ((JsonPair "input_tokens" (JsonNumber $input-tokens))
      (JsonPair "cached_input_tokens" (JsonNumber $cached-input-tokens))
      (JsonPair "output_tokens" (JsonNumber $output-tokens))
      (JsonPair "reasoning_output_tokens" (JsonNumber $reasoning-output-tokens))
      (JsonPair "total_tokens" (JsonNumber $total-tokens)))))

(= (codex:token-usage-info-json
      (CodexTokenUsageInfo
        $total-token-usage
        $last-token-usage
        $model-context-window))
   (if (== $model-context-window CodexAbsent)
       (JsonObject
         ((JsonPair
            "total_token_usage"
            (codex:token-usage-json $total-token-usage))
          (JsonPair
            "last_token_usage"
            (codex:token-usage-json $last-token-usage))
          (JsonPair "model_context_window" JsonNull)))
       (JsonObject
         ((JsonPair
            "total_token_usage"
            (codex:token-usage-json $total-token-usage))
          (JsonPair
            "last_token_usage"
            (codex:token-usage-json $last-token-usage))
          (JsonPair
            "model_context_window"
            (JsonNumber $model-context-window))))))

(= (codex:rate-limit-window-json
      (CodexRateLimitWindow $used-percent $window-minutes $resets-at))
   (if (== $window-minutes CodexAbsent)
       (if (== $resets-at CodexAbsent)
           (JsonObject
             ((JsonPair "used_percent" (JsonNumber $used-percent))
              (JsonPair "window_minutes" JsonNull)
              (JsonPair "resets_at" JsonNull)))
           (JsonObject
             ((JsonPair "used_percent" (JsonNumber $used-percent))
              (JsonPair "window_minutes" JsonNull)
              (JsonPair "resets_at" (JsonNumber $resets-at)))))
       (if (== $resets-at CodexAbsent)
           (JsonObject
             ((JsonPair "used_percent" (JsonNumber $used-percent))
              (JsonPair "window_minutes" (JsonNumber $window-minutes))
              (JsonPair "resets_at" JsonNull)))
           (JsonObject
             ((JsonPair "used_percent" (JsonNumber $used-percent))
              (JsonPair "window_minutes" (JsonNumber $window-minutes))
              (JsonPair "resets_at" (JsonNumber $resets-at)))))))

(= (codex:credits-snapshot-json
      (CodexCreditsSnapshot $has-credits $unlimited $balance))
   (if (== $balance CodexAbsent)
       (JsonObject
         ((JsonPair "has_credits" (JsonBool $has-credits))
          (JsonPair "unlimited" (JsonBool $unlimited))
          (JsonPair "balance" JsonNull)))
       (JsonObject
         ((JsonPair "has_credits" (JsonBool $has-credits))
          (JsonPair "unlimited" (JsonBool $unlimited))
          (JsonPair "balance" (JsonString $balance))))))

(= (codex:rate-limit-reached-type-json $text)
   (JsonString $text))

(= (codex:rate-limit-snapshot-json
      (CodexRateLimitSnapshot
        $limit-id
        $limit-name
        $primary
        $secondary
        $credits
        $plan-type
        $rate-limit-reached-type))
   (JsonObject
     ((JsonPair
        "limit_id"
        (if (== $limit-id CodexAbsent) JsonNull (JsonString $limit-id)))
      (JsonPair
        "limit_name"
        (if (== $limit-name CodexAbsent) JsonNull (JsonString $limit-name)))
      (JsonPair
        "primary"
        (if (== $primary CodexAbsent)
            JsonNull
            (codex:rate-limit-window-json $primary)))
      (JsonPair
        "secondary"
        (if (== $secondary CodexAbsent)
            JsonNull
            (codex:rate-limit-window-json $secondary)))
      (JsonPair
        "credits"
        (if (== $credits CodexAbsent)
            JsonNull
            (codex:credits-snapshot-json $credits)))
      (JsonPair
        "plan_type"
        (if (== $plan-type CodexAbsent) JsonNull (JsonString $plan-type)))
      (JsonPair
        "rate_limit_reached_type"
        (if (== $rate-limit-reached-type CodexAbsent)
            JsonNull
            (codex:rate-limit-reached-type-json $rate-limit-reached-type))))))

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
      (CodexEventAgentMessage $message $phase $memory-citation))
   (JsonObject
     ((JsonPair "type" (JsonString "agent_message"))
      (JsonPair "message" (JsonString $message))
      (JsonPair
        "phase"
        (if (== $phase CodexAbsent)
            JsonNull
            (codex:message-phase-json $phase)))
      (JsonPair
        "memory_citation"
        (if (== $memory-citation CodexAbsent)
            JsonNull
            (codex:memory-citation-json $memory-citation))))))

(= (codex:item-json
      (CodexEventUserMessage
        $message
        $images
        $local-images
        $text-elements))
   (if (== $images CodexAbsent)
       (JsonObject
         ((JsonPair "type" (JsonString "user_message"))
          (JsonPair "message" (JsonString $message))
          (JsonPair
            "local_images"
            (JsonArray
              (map-atom $local-images $item (JsonString $item))))
          (JsonPair
            "text_elements"
            (JsonArray
              (map-atom $text-elements $item (codex:text-element-json $item))))))
       (JsonObject
         ((JsonPair "type" (JsonString "user_message"))
          (JsonPair "message" (JsonString $message))
          (JsonPair
            "images"
            (JsonArray
              (map-atom $images $item (JsonString $item))))
          (JsonPair
            "local_images"
            (JsonArray
              (map-atom $local-images $item (JsonString $item))))
          (JsonPair
            "text_elements"
            (JsonArray
              (map-atom $text-elements $item (codex:text-element-json $item))))))))

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
      (CodexEventModelVerification $verifications))
   (JsonObject
     ((JsonPair "type" (JsonString "model_verification"))
      (JsonPair
        "verifications"
        (JsonArray
          (map-atom $verifications $item (codex:model-verification-json $item)))))))

(= (codex:item-json
      (CodexEventTurnStarted
        $turn_id
        $started_at
        $model_context_window
        $collaboration_mode_kind))
   (if (== $started_at CodexAbsent)
       (if (== $model_context_window CodexAbsent)
           (JsonObject
             ((JsonPair "type" (JsonString "task_started"))
              (JsonPair "turn_id" (JsonString $turn_id))
              (JsonPair "model_context_window" JsonNull)
              (JsonPair
                "collaboration_mode_kind"
                (codex:mode-kind-json $collaboration_mode_kind))))
           (JsonObject
             ((JsonPair "type" (JsonString "task_started"))
              (JsonPair "turn_id" (JsonString $turn_id))
              (JsonPair "model_context_window" (JsonNumber $model_context_window))
              (JsonPair
                "collaboration_mode_kind"
                (codex:mode-kind-json $collaboration_mode_kind)))))
       (if (== $model_context_window CodexAbsent)
           (JsonObject
             ((JsonPair "type" (JsonString "task_started"))
              (JsonPair "turn_id" (JsonString $turn_id))
              (JsonPair "started_at" (JsonNumber $started_at))
              (JsonPair "model_context_window" JsonNull)
              (JsonPair
                "collaboration_mode_kind"
                (codex:mode-kind-json $collaboration_mode_kind))))
           (JsonObject
             ((JsonPair "type" (JsonString "task_started"))
              (JsonPair "turn_id" (JsonString $turn_id))
              (JsonPair "started_at" (JsonNumber $started_at))
              (JsonPair "model_context_window" (JsonNumber $model_context_window))
              (JsonPair
                "collaboration_mode_kind"
                (codex:mode-kind-json $collaboration_mode_kind)))))))

(= (codex:item-json
      (CodexEventContextCompacted))
   (JsonObject
     ((JsonPair "type" (JsonString "context_compacted")))))

(= (codex:item-json
      (CodexEventTurnComplete
        $turn_id
        $last_agent_message
        $completed_at
        $duration_ms
        $time_to_first_token_ms))
   (if (== $last_agent_message CodexAbsent)
       (if (== $completed_at CodexAbsent)
           (if (== $duration_ms CodexAbsent)
               (if (== $time_to_first_token_ms CodexAbsent)
                   (JsonObject
                     ((JsonPair "type" (JsonString "task_complete"))
                      (JsonPair "turn_id" (JsonString $turn_id))))
                   (JsonObject
                     ((JsonPair "type" (JsonString "task_complete"))
                      (JsonPair "turn_id" (JsonString $turn_id))
                      (JsonPair
                        "time_to_first_token_ms"
                        (JsonNumber $time_to_first_token_ms)))))
               (if (== $time_to_first_token_ms CodexAbsent)
                   (JsonObject
                     ((JsonPair "type" (JsonString "task_complete"))
                      (JsonPair "turn_id" (JsonString $turn_id))
                      (JsonPair "duration_ms" (JsonNumber $duration_ms))))
                   (JsonObject
                     ((JsonPair "type" (JsonString "task_complete"))
                      (JsonPair "turn_id" (JsonString $turn_id))
                      (JsonPair "duration_ms" (JsonNumber $duration_ms))
                      (JsonPair
                        "time_to_first_token_ms"
                        (JsonNumber $time_to_first_token_ms))))))
           (if (== $duration_ms CodexAbsent)
               (if (== $time_to_first_token_ms CodexAbsent)
                   (JsonObject
                     ((JsonPair "type" (JsonString "task_complete"))
                      (JsonPair "turn_id" (JsonString $turn_id))
                      (JsonPair "completed_at" (JsonNumber $completed_at))))
                   (JsonObject
                     ((JsonPair "type" (JsonString "task_complete"))
                      (JsonPair "turn_id" (JsonString $turn_id))
                      (JsonPair "completed_at" (JsonNumber $completed_at))
                      (JsonPair
                        "time_to_first_token_ms"
                        (JsonNumber $time_to_first_token_ms)))))
               (if (== $time_to_first_token_ms CodexAbsent)
                   (JsonObject
                     ((JsonPair "type" (JsonString "task_complete"))
                      (JsonPair "turn_id" (JsonString $turn_id))
                      (JsonPair "completed_at" (JsonNumber $completed_at))
                      (JsonPair "duration_ms" (JsonNumber $duration_ms))))
                   (JsonObject
                     ((JsonPair "type" (JsonString "task_complete"))
                      (JsonPair "turn_id" (JsonString $turn_id))
                      (JsonPair "completed_at" (JsonNumber $completed_at))
                      (JsonPair "duration_ms" (JsonNumber $duration_ms))
                      (JsonPair
                        "time_to_first_token_ms"
                        (JsonNumber $time_to_first_token_ms)))))))
       (if (== $completed_at CodexAbsent)
           (if (== $duration_ms CodexAbsent)
               (if (== $time_to_first_token_ms CodexAbsent)
                   (JsonObject
                     ((JsonPair "type" (JsonString "task_complete"))
                      (JsonPair "turn_id" (JsonString $turn_id))
                      (JsonPair
                        "last_agent_message"
                        (JsonString $last_agent_message))))
                   (JsonObject
                     ((JsonPair "type" (JsonString "task_complete"))
                      (JsonPair "turn_id" (JsonString $turn_id))
                      (JsonPair
                        "last_agent_message"
                        (JsonString $last_agent_message))
                      (JsonPair
                        "time_to_first_token_ms"
                        (JsonNumber $time_to_first_token_ms)))))
               (if (== $time_to_first_token_ms CodexAbsent)
                   (JsonObject
                     ((JsonPair "type" (JsonString "task_complete"))
                      (JsonPair "turn_id" (JsonString $turn_id))
                      (JsonPair
                        "last_agent_message"
                        (JsonString $last_agent_message))
                      (JsonPair "duration_ms" (JsonNumber $duration_ms))))
                   (JsonObject
                     ((JsonPair "type" (JsonString "task_complete"))
                      (JsonPair "turn_id" (JsonString $turn_id))
                      (JsonPair
                        "last_agent_message"
                        (JsonString $last_agent_message))
                      (JsonPair "duration_ms" (JsonNumber $duration_ms))
                      (JsonPair
                        "time_to_first_token_ms"
                        (JsonNumber $time_to_first_token_ms))))))
           (if (== $duration_ms CodexAbsent)
               (if (== $time_to_first_token_ms CodexAbsent)
                   (JsonObject
                     ((JsonPair "type" (JsonString "task_complete"))
                      (JsonPair "turn_id" (JsonString $turn_id))
                      (JsonPair
                        "last_agent_message"
                        (JsonString $last_agent_message))
                      (JsonPair "completed_at" (JsonNumber $completed_at))))
                   (JsonObject
                     ((JsonPair "type" (JsonString "task_complete"))
                      (JsonPair "turn_id" (JsonString $turn_id))
                      (JsonPair
                        "last_agent_message"
                        (JsonString $last_agent_message))
                      (JsonPair "completed_at" (JsonNumber $completed_at))
                      (JsonPair
                        "time_to_first_token_ms"
                        (JsonNumber $time_to_first_token_ms)))))
               (if (== $time_to_first_token_ms CodexAbsent)
                   (JsonObject
                     ((JsonPair "type" (JsonString "task_complete"))
                      (JsonPair "turn_id" (JsonString $turn_id))
                      (JsonPair
                        "last_agent_message"
                        (JsonString $last_agent_message))
                      (JsonPair "completed_at" (JsonNumber $completed_at))
                      (JsonPair "duration_ms" (JsonNumber $duration_ms))))
                   (JsonObject
                     ((JsonPair "type" (JsonString "task_complete"))
                      (JsonPair "turn_id" (JsonString $turn_id))
                      (JsonPair
                        "last_agent_message"
                        (JsonString $last_agent_message))
                      (JsonPair "completed_at" (JsonNumber $completed_at))
                      (JsonPair "duration_ms" (JsonNumber $duration_ms))
                     (JsonPair
                        "time_to_first_token_ms"
                        (JsonNumber $time_to_first_token_ms)))))))))

(= (codex:item-json
      (CodexTokenCountEvent $info $rate-limits))
   (JsonObject
     ((JsonPair "type" (JsonString "token_count"))
      (JsonPair
        "info"
        (if (== $info CodexAbsent)
            JsonNull
            (codex:token-usage-info-json $info)))
      (JsonPair
        "rate_limits"
        (if (== $rate-limits CodexAbsent)
            JsonNull
            (codex:rate-limit-snapshot-json $rate-limits))))))

(= (codex:item-json
      (CodexEventStreamInfo $message))
   (JsonObject
     ((JsonPair "type" (JsonString "stream_info"))
      (JsonPair "message" (JsonString $message)))))

(= (codex:item-json
      (CodexEventUndoStarted $message))
   (if (== $message CodexAbsent)
       (JsonObject
         ((JsonPair "type" (JsonString "undo_started"))))
       (JsonObject
         ((JsonPair "type" (JsonString "undo_started"))
          (JsonPair "message" (JsonString $message))))))

(= (codex:item-json
      (CodexEventUndoCompleted $success $message))
   (if (== $message CodexAbsent)
       (JsonObject
         ((JsonPair "type" (JsonString "undo_completed"))
          (JsonPair "success" (JsonBool $success))))
       (JsonObject
         ((JsonPair "type" (JsonString "undo_completed"))
          (JsonPair "success" (JsonBool $success))
          (JsonPair "message" (JsonString $message))))))

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

(= (codex:item-json
      (CodexEventViewImageToolCall $call_id $path))
   (JsonObject
     ((JsonPair "type" (JsonString "view_image_tool_call"))
      (JsonPair "call_id" (JsonString $call_id))
      (JsonPair "path" (JsonString $path)))))

(= (codex:item-json
      (CodexEventBackgroundEvent $message))
   (JsonObject
     ((JsonPair "type" (JsonString "background_event"))
      (JsonPair "message" (JsonString $message)))))

(= (codex:item-json
      (CodexEventDeprecationNotice $summary $details))
   (if (== $details CodexAbsent)
       (JsonObject
         ((JsonPair "type" (JsonString "deprecation_notice"))
          (JsonPair "summary" (JsonString $summary))))
       (JsonObject
         ((JsonPair "type" (JsonString "deprecation_notice"))
          (JsonPair "summary" (JsonString $summary))
          (JsonPair "details" (JsonString $details))))))

(= (codex:item-json
      (CodexEventSkillsUpdateAvailable))
   (JsonObject
     ((JsonPair "type" (JsonString "skills_update_available")))))

(= (codex:item-json
      (CodexEventShutdownComplete))
   (JsonObject
     ((JsonPair "type" (JsonString "shutdown_complete")))))

(= (codex:item-json
      (CodexUpdatePlanArgs $explanation $plan))
   (JsonObject
     ((JsonPair "type" (JsonString "plan_update"))
      (JsonPair
        "explanation"
        (if (== $explanation CodexAbsent)
            JsonNull
            (JsonString $explanation)))
      (JsonPair "plan" (codex:plan-update-steps-json $plan)))))

(= (codex:item-json
      (CodexEventTurnAborted $turn-id $reason $completed-at $duration-ms))
   (if (== $turn-id CodexAbsent)
       (if (== $completed-at CodexAbsent)
           (if (== $duration-ms CodexAbsent)
               (JsonObject
                 ((JsonPair "type" (JsonString "turn_aborted"))
                  (JsonPair "reason" (codex:turn-abort-reason-json $reason))))
               (JsonObject
                 ((JsonPair "type" (JsonString "turn_aborted"))
                  (JsonPair "reason" (codex:turn-abort-reason-json $reason))
                  (JsonPair "duration_ms" (JsonNumber $duration-ms)))))
           (if (== $duration-ms CodexAbsent)
               (JsonObject
                 ((JsonPair "type" (JsonString "turn_aborted"))
                  (JsonPair "reason" (codex:turn-abort-reason-json $reason))
                  (JsonPair "completed_at" (JsonNumber $completed-at))))
               (JsonObject
                 ((JsonPair "type" (JsonString "turn_aborted"))
                  (JsonPair "reason" (codex:turn-abort-reason-json $reason))
                  (JsonPair "completed_at" (JsonNumber $completed-at))
                  (JsonPair "duration_ms" (JsonNumber $duration-ms))))))
       (if (== $completed-at CodexAbsent)
           (if (== $duration-ms CodexAbsent)
               (JsonObject
                 ((JsonPair "type" (JsonString "turn_aborted"))
                  (JsonPair "turn_id" (JsonString $turn-id))
                  (JsonPair "reason" (codex:turn-abort-reason-json $reason))))
               (JsonObject
                 ((JsonPair "type" (JsonString "turn_aborted"))
                  (JsonPair "turn_id" (JsonString $turn-id))
                  (JsonPair "reason" (codex:turn-abort-reason-json $reason))
                  (JsonPair "duration_ms" (JsonNumber $duration-ms)))))
           (if (== $duration-ms CodexAbsent)
               (JsonObject
                 ((JsonPair "type" (JsonString "turn_aborted"))
                  (JsonPair "turn_id" (JsonString $turn-id))
                  (JsonPair "reason" (codex:turn-abort-reason-json $reason))
                  (JsonPair "completed_at" (JsonNumber $completed-at))))
               (JsonObject
                 ((JsonPair "type" (JsonString "turn_aborted"))
                  (JsonPair "turn_id" (JsonString $turn-id))
                  (JsonPair "reason" (codex:turn-abort-reason-json $reason))
                 (JsonPair "completed_at" (JsonNumber $completed-at))
                 (JsonPair "duration_ms" (JsonNumber $duration-ms))))))))

(= (codex:item-json
      (CodexEventCollabAgentSpawnBegin
        $call-id
        $sender-thread-id
        $prompt
        $model
        $reasoning-effort))
   (JsonObject
     ((JsonPair "type" (JsonString "collab_agent_spawn_begin"))
      (JsonPair "call_id" (JsonString $call-id))
      (JsonPair "sender_thread_id" (JsonString $sender-thread-id))
      (JsonPair "prompt" (JsonString $prompt))
      (JsonPair "model" (JsonString $model))
      (JsonPair
        "reasoning_effort"
        (codex:session-reasoning-effort-json $reasoning-effort)))))

(= (codex:item-json
      (CodexEventCollabAgentSpawnEnd
        $call-id
        $sender-thread-id
        $new-thread-id
        $new-agent-nickname
        $new-agent-role
        $prompt
        $model
        $reasoning-effort
        $status))
   (let $pairs-1
     ((JsonPair "type" (JsonString "collab_agent_spawn_end"))
      (JsonPair "call_id" (JsonString $call-id))
      (JsonPair "sender_thread_id" (JsonString $sender-thread-id))
      (JsonPair
        "new_thread_id"
        (if (== $new-thread-id CodexAbsent)
            JsonNull
            (JsonString $new-thread-id))))
     (let $pairs-2
       (codex:append-optional-json-string-pair
         $pairs-1
         "new_agent_nickname"
         $new-agent-nickname)
       (let $pairs-3
         (codex:append-optional-json-string-pair
           $pairs-2
           "new_agent_role"
           $new-agent-role)
         (let $pairs-4
           (codex:protocol-append-json-pair
             $pairs-3
             "prompt"
             (JsonString $prompt))
         (let $pairs-5
             (codex:protocol-append-json-pair
               $pairs-4
               "model"
               (JsonString $model))
             (let $pairs-6
               (codex:protocol-append-json-pair
                 $pairs-5
                 "reasoning_effort"
                 (codex:session-reasoning-effort-json $reasoning-effort))
               (JsonObject
                 (codex:protocol-append-json-pair
                   $pairs-6
                   "status"
                   (codex:protocol-agent-status-json $status))))))))))

(= (codex:item-json
      (CodexEventCollabAgentInteractionBegin
        $call-id
        $sender-thread-id
        $receiver-thread-id
        $prompt))
   (JsonObject
     ((JsonPair "type" (JsonString "collab_agent_interaction_begin"))
      (JsonPair "call_id" (JsonString $call-id))
      (JsonPair "sender_thread_id" (JsonString $sender-thread-id))
      (JsonPair "receiver_thread_id" (JsonString $receiver-thread-id))
      (JsonPair "prompt" (JsonString $prompt)))))

(= (codex:item-json
      (CodexEventCollabAgentInteractionEnd
        $call-id
        $sender-thread-id
        $receiver-thread-id
        $receiver-agent-nickname
        $receiver-agent-role
        $prompt
        $status))
   (let $pairs-1
     ((JsonPair "type" (JsonString "collab_agent_interaction_end"))
      (JsonPair "call_id" (JsonString $call-id))
      (JsonPair "sender_thread_id" (JsonString $sender-thread-id))
      (JsonPair "receiver_thread_id" (JsonString $receiver-thread-id)))
     (let $pairs-2
       (codex:append-optional-json-string-pair
         $pairs-1
         "receiver_agent_nickname"
         $receiver-agent-nickname)
       (let $pairs-3
         (codex:append-optional-json-string-pair
           $pairs-2
           "receiver_agent_role"
           $receiver-agent-role)
         (let $pairs-4
           (codex:protocol-append-json-pair
             $pairs-3
             "prompt"
             (JsonString $prompt))
           (JsonObject
             (codex:protocol-append-json-pair
               $pairs-4
               "status"
               (codex:protocol-agent-status-json $status))))))))

(= (codex:item-json
      (CodexEventCollabWaitingBegin
        $sender-thread-id
        $receiver-thread-ids
        $receiver-agents
        $call-id))
   (let $pairs-1
     ((JsonPair "type" (JsonString "collab_waiting_begin"))
      (JsonPair "sender_thread_id" (JsonString $sender-thread-id))
      (JsonPair
        "receiver_thread_ids"
        (codex:json-string-array $receiver-thread-ids)))
     (let $pairs-2
       (if (== $receiver-agents ())
           $pairs-1
           (codex:protocol-append-json-pair
             $pairs-1
             "receiver_agents"
             (codex:collab-agent-refs-json $receiver-agents)))
       (JsonObject
         (codex:protocol-append-json-pair
           $pairs-2
           "call_id"
           (JsonString $call-id))))))

(= (codex:item-json
      (CodexEventCollabWaitingEnd
        $sender-thread-id
        $call-id
        $agent-statuses
        $statuses))
   (let $pairs-1
     ((JsonPair "type" (JsonString "collab_waiting_end"))
      (JsonPair "sender_thread_id" (JsonString $sender-thread-id))
      (JsonPair "call_id" (JsonString $call-id)))
     (let $pairs-2
       (if (== $agent-statuses ())
           $pairs-1
           (codex:protocol-append-json-pair
             $pairs-1
             "agent_statuses"
             (codex:collab-agent-status-entries-json $agent-statuses)))
       (JsonObject
         (codex:protocol-append-json-pair
           $pairs-2
           "statuses"
           (codex:collab-waiting-statuses-json $statuses))))))

(= (codex:item-json
      (CodexEventCollabCloseBegin
        $call-id
        $sender-thread-id
        $receiver-thread-id))
   (JsonObject
     ((JsonPair "type" (JsonString "collab_close_begin"))
      (JsonPair "call_id" (JsonString $call-id))
      (JsonPair "sender_thread_id" (JsonString $sender-thread-id))
      (JsonPair "receiver_thread_id" (JsonString $receiver-thread-id)))))

(= (codex:item-json
      (CodexEventCollabCloseEnd
        $call-id
        $sender-thread-id
        $receiver-thread-id
        $receiver-agent-nickname
        $receiver-agent-role
        $status))
   (let $pairs-1
     ((JsonPair "type" (JsonString "collab_close_end"))
      (JsonPair "call_id" (JsonString $call-id))
      (JsonPair "sender_thread_id" (JsonString $sender-thread-id))
      (JsonPair "receiver_thread_id" (JsonString $receiver-thread-id)))
     (let $pairs-2
       (codex:append-optional-json-string-pair
         $pairs-1
         "receiver_agent_nickname"
         $receiver-agent-nickname)
       (let $pairs-3
         (codex:append-optional-json-string-pair
           $pairs-2
           "receiver_agent_role"
           $receiver-agent-role)
         (JsonObject
           (codex:protocol-append-json-pair
             $pairs-3
             "status"
             (codex:protocol-agent-status-json $status)))))))

(= (codex:item-json
      (CodexEventCollabResumeBegin
        $call-id
        $sender-thread-id
        $receiver-thread-id
        $receiver-agent-nickname
        $receiver-agent-role))
   (let $pairs-1
     ((JsonPair "type" (JsonString "collab_resume_begin"))
      (JsonPair "call_id" (JsonString $call-id))
      (JsonPair "sender_thread_id" (JsonString $sender-thread-id))
      (JsonPair "receiver_thread_id" (JsonString $receiver-thread-id)))
     (let $pairs-2
       (codex:append-optional-json-string-pair
         $pairs-1
         "receiver_agent_nickname"
         $receiver-agent-nickname)
       (JsonObject
         (codex:append-optional-json-string-pair
           $pairs-2
           "receiver_agent_role"
           $receiver-agent-role)))))

(= (codex:item-json
      (CodexEventCollabResumeEnd
        $call-id
        $sender-thread-id
        $receiver-thread-id
        $receiver-agent-nickname
        $receiver-agent-role
        $status))
   (let $pairs-1
     ((JsonPair "type" (JsonString "collab_resume_end"))
      (JsonPair "call_id" (JsonString $call-id))
      (JsonPair "sender_thread_id" (JsonString $sender-thread-id))
      (JsonPair "receiver_thread_id" (JsonString $receiver-thread-id)))
     (let $pairs-2
       (codex:append-optional-json-string-pair
         $pairs-1
         "receiver_agent_nickname"
         $receiver-agent-nickname)
       (let $pairs-3
         (codex:append-optional-json-string-pair
           $pairs-2
           "receiver_agent_role"
           $receiver-agent-role)
         (JsonObject
           (codex:protocol-append-json-pair
             $pairs-3
             "status"
             (codex:protocol-agent-status-json $status)))))))

(= (codex:item-json
      (CodexEventStreamError $message $codex-error-info $additional-details))
   (JsonObject
     ((JsonPair "type" (JsonString "stream_error"))
      (JsonPair "message" (JsonString $message))
      (JsonPair
        "codex_error_info"
        (if (== $codex-error-info CodexAbsent)
            JsonNull
            (codex:codex-error-info-json $codex-error-info)))
      (JsonPair
        "additional_details"
        (if (== $additional-details CodexAbsent)
            JsonNull
            (JsonString $additional-details))))))

(= (codex:item-json
      (CodexEventError $message $codex-error-info))
   (JsonObject
     ((JsonPair "type" (JsonString "error"))
      (JsonPair "message" (JsonString $message))
      (JsonPair
        "codex_error_info"
        (if (== $codex-error-info CodexAbsent)
            JsonNull
            (codex:codex-error-info-json $codex-error-info))))))

(= (codex:item-json
      (CodexEventRawResponseItem $item))
   (JsonObject
     ((JsonPair "type" (JsonString "raw_response_item"))
      (JsonPair "item" (codex:item-json $item)))))

(= (codex:item-json
      (CodexEventAgentMessageContentDelta
        $thread-id
        $turn-id
        $item-id
        $delta))
   (JsonObject
     ((JsonPair "type" (JsonString "agent_message_content_delta"))
      (JsonPair "thread_id" (JsonString $thread-id))
      (JsonPair "turn_id" (JsonString $turn-id))
      (JsonPair "item_id" (JsonString $item-id))
      (JsonPair "delta" (JsonString $delta)))))

(= (codex:item-json
      (CodexEventPlanDelta
        $thread-id
        $turn-id
        $item-id
        $delta))
   (JsonObject
     ((JsonPair "type" (JsonString "plan_delta"))
      (JsonPair "thread_id" (JsonString $thread-id))
      (JsonPair "turn_id" (JsonString $turn-id))
      (JsonPair "item_id" (JsonString $item-id))
      (JsonPair "delta" (JsonString $delta)))))

(= (codex:item-json
      (CodexEventReasoningContentDelta
        $thread-id
        $turn-id
        $item-id
        $delta
        $summary-index))
   (JsonObject
     ((JsonPair "type" (JsonString "reasoning_content_delta"))
      (JsonPair "thread_id" (JsonString $thread-id))
      (JsonPair "turn_id" (JsonString $turn-id))
      (JsonPair "item_id" (JsonString $item-id))
      (JsonPair "delta" (JsonString $delta))
      (JsonPair "summary_index" (JsonNumber $summary-index)))))

(= (codex:item-json
      (CodexEventReasoningRawContentDelta
        $thread-id
        $turn-id
        $item-id
        $delta
        $content-index))
   (JsonObject
     ((JsonPair "type" (JsonString "reasoning_raw_content_delta"))
      (JsonPair "thread_id" (JsonString $thread-id))
      (JsonPair "turn_id" (JsonString $turn-id))
     (JsonPair "item_id" (JsonString $item-id))
     (JsonPair "delta" (JsonString $delta))
     (JsonPair "content_index" (JsonNumber $content-index)))))

(= (codex:item-json
      (CodexEventExitedReviewMode $review-output))
   (JsonObject
     ((JsonPair "type" (JsonString "exited_review_mode"))
      (JsonPair
        "review_output"
        (if (== $review-output CodexAbsent)
            JsonNull
            (codex:review-output-event-json $review-output))))))

(= (codex:item-json
      (CodexEventEnteredReviewMode $review-request))
   (let $request-pairs (eval (codex:review-request-json-pairs $review-request))
     (JsonObject
       (cons-atom
         (JsonPair "type" (JsonString "entered_review_mode"))
         $request-pairs))))

(= (codex:item-json
      (CodexEventTurnDiff $unified-diff))
   (JsonObject
     ((JsonPair "type" (JsonString "turn_diff"))
      (JsonPair "unified_diff" (JsonString $unified-diff)))))

(= (codex:item-json
      (CodexEventGetHistoryEntryResponse $offset $log-id $entry))
   (if (== $entry CodexAbsent)
       (JsonObject
         ((JsonPair "type" (JsonString "get_history_entry_response"))
          (JsonPair "offset" (JsonNumber $offset))
          (JsonPair "log_id" (JsonNumber $log-id))))
       (JsonObject
         ((JsonPair "type" (JsonString "get_history_entry_response"))
          (JsonPair "offset" (JsonNumber $offset))
          (JsonPair "log_id" (JsonNumber $log-id))
          (JsonPair "entry" (codex:history-entry-json $entry))))))

(= (codex:item-json
      (CodexEventListSkillsResponse $skills))
   (JsonObject
     ((JsonPair "type" (JsonString "list_skills_response"))
      (JsonPair "skills" (codex:skills-list-entries-json $skills)))))

(= (codex:item-json
      (CodexEventRealtimeConversationStarted $session-id $version))
   (JsonObject
     ((JsonPair "type" (JsonString "realtime_conversation_started"))
      (JsonPair
        "session_id"
        (if (== $session-id CodexAbsent)
            JsonNull
            (JsonString $session-id)))
      (JsonPair
        "version"
        (codex:realtime-conversation-version-json $version)))))

(= (codex:item-json
      (CodexEventRealtimeConversationRealtime $payload))
   (JsonObject
     ((JsonPair "type" (JsonString "realtime_conversation_realtime"))
      (JsonPair "payload" (codex:realtime-event-json $payload)))))

(= (codex:item-json
      (CodexEventRealtimeConversationClosed $reason))
   (let $pairs-1
     ((JsonPair "type" (JsonString "realtime_conversation_closed")))
     (JsonObject
       (codex:append-optional-json-string-pair
         $pairs-1
         "reason"
         $reason))))

(= (codex:item-json
      (CodexEventRealtimeConversationSdp $sdp))
   (JsonObject
     ((JsonPair "type" (JsonString "realtime_conversation_sdp"))
      (JsonPair "sdp" (JsonString $sdp)))))

(= (codex:item-json
      (CodexEventRealtimeConversationListVoicesResponse $voices))
   (JsonObject
     ((JsonPair
        "type"
        (JsonString "realtime_conversation_list_voices_response"))
      (JsonPair "voices" (codex:realtime-voices-list-json $voices)))))

(= (codex:op-type
      (CodexOpRealtimeConversationStart $params))
   "realtime_conversation_start")

(= (codex:op-type
      (CodexOpRealtimeConversationAudio $params))
   "realtime_conversation_audio")

(= (codex:op-type
      (CodexOpRealtimeConversationText $params))
   "realtime_conversation_text")

(= (codex:op-type
      (CodexOpRealtimeConversationClose))
   "realtime_conversation_close")

(= (codex:op-type
      (CodexOpRealtimeConversationListVoices))
   "realtime_conversation_list_voices")

(= (codex:op-type
      (CodexOpRefreshMcpServers $config))
   "refresh_mcp_servers")

(= (codex:op-type
      (CodexOpAddToHistory $text))
   "add_to_history")

(= (codex:op-type
      (CodexOpGetHistoryEntryRequest $offset $log-id))
   "get_history_entry_request")

(= (codex:op-type
      (CodexOpListMcpTools))
   "list_mcp_tools")

(= (codex:op-type
      (CodexOpReloadUserConfig))
   "reload_user_config")

(= (codex:op-type
      (CodexOpListSkills $cwds $force-reload))
   "list_skills")

(= (codex:w3c-trace-context-json
      (CodexW3cTraceContext $traceparent $tracestate))
   (let $pairs-1 ()
     (let $pairs-2
       (if (== $traceparent CodexAbsent)
           $pairs-1
           (codex:protocol-append-json-pair
             $pairs-1
             "traceparent"
             (JsonString $traceparent)))
       (let $pairs-3
         (if (== $tracestate CodexAbsent)
             $pairs-2
             (codex:protocol-append-json-pair
               $pairs-2
               "tracestate"
               (JsonString $tracestate)))
         (JsonObject $pairs-3)))))

(= (codex:mcp-server-refresh-config-json
      (CodexMcpServerRefreshConfig
        $mcp-servers
        $mcp-oauth-credentials-store-mode))
   (JsonObject
     ((JsonPair "mcp_servers" $mcp-servers)
      (JsonPair
        "mcp_oauth_credentials_store_mode"
        $mcp-oauth-credentials-store-mode))))

(= (codex:op-json
      (CodexOpRealtimeConversationStart
        (CodexConversationStartParams
          $output-modality
          $prompt
          $session-id
          $transport
          $voice)))
   (let $pairs-1
     ((JsonPair "type" (JsonString "realtime_conversation_start"))
      (JsonPair
        "output_modality"
        (codex:realtime-output-modality-json $output-modality)))
     (let $pairs-2
       (case $prompt
         ((CodexAbsent $pairs-1)
          (JsonNull
            (codex:protocol-append-json-pair
              $pairs-1
              "prompt"
              JsonNull))
          ($text
            (codex:protocol-append-json-pair
              $pairs-1
              "prompt"
              (JsonString $text)))))
       (let $pairs-3
         (if (== $session-id CodexAbsent)
             $pairs-2
             (codex:protocol-append-json-pair
               $pairs-2
               "session_id"
               (JsonString $session-id)))
         (let $pairs-4
           (if (== $transport CodexAbsent)
               $pairs-3
               (codex:protocol-append-json-pair
                 $pairs-3
                 "transport"
                 (codex:conversation-start-transport-json $transport)))
           (let $pairs-5
             (if (== $voice CodexAbsent)
                 $pairs-4
                 (codex:protocol-append-json-pair
                   $pairs-4
                   "voice"
                   (codex:realtime-voice-json $voice)))
             (JsonObject $pairs-5)))))))

(= (codex:op-json
      (CodexOpRealtimeConversationAudio
        (CodexConversationAudioParams $frame)))
   (JsonObject
     ((JsonPair "type" (JsonString "realtime_conversation_audio"))
      (JsonPair "frame" (codex:realtime-audio-frame-json $frame)))))

(= (codex:op-json
      (CodexOpRealtimeConversationText
        (CodexConversationTextParams $text)))
   (JsonObject
     ((JsonPair "type" (JsonString "realtime_conversation_text"))
      (JsonPair "text" (JsonString $text)))))

(= (codex:op-json
      (CodexOpRealtimeConversationClose))
   (JsonObject
     ((JsonPair "type" (JsonString "realtime_conversation_close")))))

(= (codex:op-json
      (CodexOpRealtimeConversationListVoices))
   (JsonObject
     ((JsonPair "type" (JsonString "realtime_conversation_list_voices")))))

(= (codex:op-json
      (CodexOpRefreshMcpServers $config))
   (JsonObject
     ((JsonPair "type" (JsonString "refresh_mcp_servers"))
      (JsonPair "config" (codex:mcp-server-refresh-config-json $config)))))

(= (codex:op-json
      (CodexOpAddToHistory $text))
   (JsonObject
     ((JsonPair "type" (JsonString "add_to_history"))
      (JsonPair "text" (JsonString $text)))))

(= (codex:op-json
      (CodexOpGetHistoryEntryRequest $offset $log-id))
   (JsonObject
     ((JsonPair "type" (JsonString "get_history_entry_request"))
      (JsonPair "offset" (JsonNumber $offset))
      (JsonPair "log_id" (JsonNumber $log-id)))))

(= (codex:op-json
      (CodexOpListMcpTools))
   (JsonObject
     ((JsonPair "type" (JsonString "list_mcp_tools")))))

(= (codex:op-json
      (CodexOpReloadUserConfig))
   (JsonObject
     ((JsonPair "type" (JsonString "reload_user_config")))))

(= (codex:op-json
      (CodexOpListSkills $cwds $force-reload))
   (let $pairs-1
     ((JsonPair "type" (JsonString "list_skills")))
     (let $pairs-2
       (if (== $cwds ())
           $pairs-1
           (codex:protocol-append-json-pair
             $pairs-1
             "cwds"
             (JsonArray
               (eval (map-atom $cwds $cwd (JsonString $cwd))))))
       (JsonObject
         (if (== $force-reload False)
             $pairs-2
             (codex:protocol-append-json-pair
               $pairs-2
               "force_reload"
               (JsonBool $force-reload)))))))

(= (codex:submission-json
      (CodexSubmission $id $op $trace))
   (let $resolved-op (once $op)
     (if (== $trace CodexAbsent)
         (JsonObject
           ((JsonPair "id" (JsonString $id))
            (JsonPair "op" (codex:op-json $resolved-op))))
         (JsonObject
           ((JsonPair "id" (JsonString $id))
            (JsonPair "op" (codex:op-json $resolved-op))
            (JsonPair "trace" (codex:w3c-trace-context-json $trace)))))))

(= (codex:event-envelope-json
      (CodexProtocolEvent $id $msg))
   (let $resolved-msg (once $msg)
     (JsonObject
       ((JsonPair "id" (JsonString $id))
        (JsonPair "msg" (codex:item-json $resolved-msg))))))

(= (codex:item-json
      (CodexEventSessionConfigured
        $session-id
        $forked-from-id
        $thread-name
        $model
        $model-provider-id
        $service-tier
        $approval-policy
        $approvals-reviewer
        $sandbox-policy
        $permission-profile
        $cwd
        $reasoning-effort
        $history-log-id
        $history-entry-count
        $initial-messages
        $network-proxy
        $rollout-path))
   (let $pairs-1
     ((JsonPair "type" (JsonString "session_configured"))
      (JsonPair "session_id" (JsonString $session-id)))
     (let $pairs-2
       (codex:append-optional-json-string-pair
         $pairs-1
         "forked_from_id"
         $forked-from-id)
       (let $pairs-3
         (codex:append-optional-json-string-pair
           $pairs-2
           "thread_name"
           $thread-name)
         (let $pairs-4
           (codex:protocol-append-json-pair
             $pairs-3
             "model"
             (JsonString $model))
           (let $pairs-5
             (codex:protocol-append-json-pair
               $pairs-4
               "model_provider_id"
               (JsonString $model-provider-id))
             (let $pairs-6
               (codex:append-optional-json-value-pair
                 $pairs-5
                 "service_tier"
                 (if (== $service-tier CodexAbsent)
                     CodexAbsent
                     (codex:session-service-tier-json $service-tier)))
               (let $pairs-7
                 (codex:protocol-append-json-pair
                   $pairs-6
                   "approval_policy"
                   (codex:session-approval-policy-json $approval-policy))
                 (let $pairs-8
                   (codex:protocol-append-json-pair
                     $pairs-7
                     "approvals_reviewer"
                     (codex:session-approvals-reviewer-json
                       $approvals-reviewer))
                   (let $pairs-9
                     (codex:protocol-append-json-pair
                       $pairs-8
                       "sandbox_policy"
                       (codex:session-sandbox-policy-json $sandbox-policy))
                     (let $pairs-10
                       (codex:append-optional-json-value-pair
                         $pairs-9
                         "permission_profile"
                         $permission-profile)
                       (let $pairs-11
                         (codex:protocol-append-json-pair
                           $pairs-10
                           "cwd"
                           (JsonString $cwd))
                         (let $pairs-12
                           (codex:append-optional-json-value-pair
                             $pairs-11
                             "reasoning_effort"
                             (if (== $reasoning-effort CodexAbsent)
                                 CodexAbsent
                                 (codex:session-reasoning-effort-json
                                   $reasoning-effort)))
                           (let $pairs-13
                             (codex:protocol-append-json-pair
                               $pairs-12
                               "history_log_id"
                               (JsonNumber $history-log-id))
                             (let $pairs-14
                               (codex:protocol-append-json-pair
                                 $pairs-13
                                 "history_entry_count"
                                 (JsonNumber $history-entry-count))
                               (let $pairs-15
                                 (codex:append-optional-json-value-pair
                                   $pairs-14
                                   "initial_messages"
                                   (if (== $initial-messages CodexAbsent)
                                       CodexAbsent
                                       (codex:items-json $initial-messages)))
                                 (let $pairs-16
                                   (codex:append-optional-json-value-pair
                                     $pairs-15
                                     "network_proxy"
                                     (if (== $network-proxy CodexAbsent)
                                         CodexAbsent
                                         (codex:session-network-proxy-runtime-json
                                           $network-proxy)))
                                   (let $pairs-17
                                     (codex:append-optional-json-string-pair
                                       $pairs-16
                                       "rollout_path"
                                       $rollout-path)
                                     (JsonObject $pairs-17)))))))))))))))))))

(= (codex:item-json
      (CodexEventPatchApplyBegin
        $call-id
        $turn-id
        $auto-approved
        $changes))
   (JsonObject
     ((JsonPair "type" (JsonString "patch_apply_begin"))
      (JsonPair "call_id" (JsonString $call-id))
      (JsonPair "turn_id" (JsonString $turn-id))
      (JsonPair "auto_approved" (JsonBool $auto-approved))
      (JsonPair "changes" (codex:patch-apply-file-changes-json $changes)))))

(= (codex:item-json
      (CodexEventPatchApplyUpdated $call-id $changes))
   (JsonObject
     ((JsonPair "type" (JsonString "patch_apply_updated"))
      (JsonPair "call_id" (JsonString $call-id))
      (JsonPair "changes" (codex:patch-apply-file-changes-json $changes)))))

(= (codex:item-json
      (CodexEventPatchApplyEnd
        $call-id
        $turn-id
        $stdout
        $stderr
        $success
        $changes
        $status))
   (JsonObject
     ((JsonPair "type" (JsonString "patch_apply_end"))
      (JsonPair "call_id" (JsonString $call-id))
      (JsonPair "turn_id" (JsonString $turn-id))
      (JsonPair "stdout" (JsonString $stdout))
      (JsonPair "stderr" (JsonString $stderr))
      (JsonPair "success" (JsonBool $success))
      (JsonPair "changes" (codex:patch-apply-file-changes-json $changes))
      (JsonPair "status" (codex:patch-apply-status-json $status)))))

(= (codex:item-json
      (CodexEventHookStarted $turn-id $run))
   (JsonObject
     ((JsonPair "type" (JsonString "hook_started"))
      (JsonPair
        "turn_id"
        (if (== $turn-id CodexAbsent)
            JsonNull
            (JsonString $turn-id)))
      (JsonPair "run" (codex:hook-run-summary-json $run)))))

(= (codex:item-json
      (CodexEventHookCompleted $turn-id $run))
   (JsonObject
     ((JsonPair "type" (JsonString "hook_completed"))
      (JsonPair
        "turn_id"
        (if (== $turn-id CodexAbsent)
            JsonNull
            (JsonString $turn-id)))
      (JsonPair "run" (codex:hook-run-summary-json $run)))))

(= (codex:items-json $items)
   (function
     (let $json-items (eval (map-atom $items $item (codex:item-json $item)))
       (return (JsonArray $json-items)))))
