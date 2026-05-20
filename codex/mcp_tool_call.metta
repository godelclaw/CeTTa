; Pure MCP tool-call approval helper slice for the Codex port.
;
; Ports deterministic behavior from:
; - openai-codex/codex-rs/core/src/mcp_tool_call.rs
;
; Covered in this increment:
; - approval question ids, labels, fallback text, and prompt options
; - MCP tool result sanitization for models without image input
; - MCP tool metadata extraction for app resources and file input params
; - MCP approval elicitation request construction
; - MCP tool-call request metadata and thread-id metadata merging
; - guardian/ARC MCP tool-call review request JSON shape
; - session/persistent approval key eligibility
; - custom MCP tool approval-mode resolution
; - elicitation metadata rendering for MCP approval requests
; - request_user_input and MCP elicitation response parsing
; - guardian review-decision mapping
; - read-only/destructive/open-world approval requirement logic
; - MCP tool-call skip event plan construction
; - MCP call metric tag sanitization and emission planning
; - MCP tool-call tracing span field planning
; - MCP sandbox-state request metadata augmentation
; - Codex Apps MCP app-used analytics planning
; - Codex Apps MCP app-used metadata lookup
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust's full MCP tool-call path is async and crosses session, hooks,
;   guardian review, telemetry, MCP transport, and config persistence. This
;   slice ports only pure approval helpers so those branches can be wired later.
; - Rust represents missing values with Option. This CeTTa surface uses
;   CodexAbsent for optional inputs and Empty for Rust `None` return values.
; - Rust receives rmcp ToolAnnotations and a larger metadata struct. The CeTTa
;   records below carry only the fields read by this pure helper subset.
; - Rust's MCP approval elicitation request builder reads thread_id and turn_id
;   from Session and TurnContext. This pure CeTTa helper receives those ids
;   explicitly while preserving the produced request shape.
; - Rust's custom MCP approval-mode helper reads the already-effective TOML
;   config layer and deserializes `mcp_servers` into a HashMap. This pure helper
;   receives list-backed server/tool config entries after parsing; per-tool
;   override, server-default, and default-Auto precedence are preserved.
; - Rust's serde_json object map is represented by JsonObject pair lists. For
;   cloned parameter objects we preserve the local pair order; display params
;   are sorted by name to match Rust's Vec sort_by branch.
; - Rust obtains guardian rejection messages from async session state. The pure
;   mapping helper receives the already-rendered rejection and timeout messages
;   explicitly.
; - Rust's notify_mcp_tool_call_skip emits events through Session and returns
;   Err(message). This pure helper returns the event list plus the same error
;   result so a runtime layer can perform the side effects later.
; - Rust emits MCP metrics through TurnContext.session_telemetry and reuses
;   codex_otel::sanitize_metric_tag_value. This slice ports the sanitizer
;   locally and returns the metric operations that the runtime should emit.
; - Rust creates a tracing Span and records parsed URL host/port fields through
;   url::Url. This pure slice returns the final span field plan; the scoped
;   origin parser below covers ordinary absolute MCP origins, explicit ports,
;   and known default ports. Full url::Url edge-case normalization remains a
;   runtime integration concern.
;   CeTTa's Empty cannot be nested as a constructor value, so Rust tracing
;   Empty field values are represented as CodexMcpSpanEmpty.
; - Rust queries the MCP connection manager asynchronously and serializes
;   SandboxState with serde_json before augmenting request metadata. This pure
;   helper receives the resolved capability bit and turn-context fields, then
;   projects the same metadata JSON shape for the runtime layer to pass through.
;   The augmentation helper materializes the same field sequence inline because
;   passing the constructed JSON through a nested helper can remain ungrounded
;   under CeTTa reduction.
; - Rust maybe_track_codex_app_used performs async metadata lookup through the
;   MCP connection manager and queues an analytics event. This pure helper
;   receives the listed ToolInfo values and connector-selection set, then
;   returns the track_app_used operation that the runtime layer should enqueue.

!(import! &self json)
!(import! &self list)
!(import! &self protocol)
!(import! &self request_user_input)
!(import! &self mcp_tool_approval_templates)
!(import! &self str)
!(import! &self turn_metadata)

(= (codex:codex-apps-mcp-server-name)
   "codex_apps")

(= (codex:mcp-tool-approval-question-id-prefix)
   "mcp_tool_call_approval")

(= (codex:mcp-tool-approval-accept)
   "Allow")

(= (codex:mcp-tool-approval-accept-for-session)
   "Allow for this session")

(= (codex:mcp-tool-approval-decline-synthetic)
   "__codex_mcp_decline__")

(= (codex:mcp-tool-approval-accept-and-remember)
   "Allow and don't ask me again")

(= (codex:mcp-tool-approval-cancel)
   "Cancel")

(= (codex:mcp-tool-approval-kind-key)
   "codex_approval_kind")

(= (codex:mcp-tool-approval-kind-mcp-tool-call)
   "mcp_tool_call")

(= (codex:mcp-tool-approval-persist-key)
   "persist")

(= (codex:mcp-tool-approval-persist-session)
   "session")

(= (codex:mcp-tool-approval-persist-always)
   "always")

(= (codex:mcp-tool-approval-source-key)
   "source")

(= (codex:mcp-tool-approval-source-connector)
   "connector")

(= (codex:mcp-tool-approval-connector-id-key)
   "connector_id")

(= (codex:mcp-tool-approval-connector-name-key)
   "connector_name")

(= (codex:mcp-tool-approval-connector-description-key)
   "connector_description")

(= (codex:mcp-tool-approval-tool-title-key)
   "tool_title")

(= (codex:mcp-tool-approval-tool-description-key)
   "tool_description")

(= (codex:mcp-tool-approval-tool-params-key)
   "tool_params")

(= (codex:mcp-tool-approval-tool-params-display-key)
   "tool_params_display")

(= (codex:mcp-tool-codex-apps-meta-key)
   "_codex_apps")

(= (codex:mcp-tool-openai-output-template-meta-key)
   "openai/outputTemplate")

(= (codex:mcp-tool-ui-resource-uri-meta-key)
   "ui/resourceUri")

(= (codex:mcp-tool-thread-id-meta-key)
   "threadId")

(= (codex:mcp-sandbox-state-meta-capability-key)
   "codex/sandbox-state-meta")

(= (codex:mcp-tool-openai-file-params-meta-key)
   "openai/fileParams")

(= (codex:codex-turn-metadata-header-key)
   "x-codex-turn-metadata")

(= (codex:mcp-tool-call-arc-monitor-callsite-default)
   "mcp_tool_call__default")

(= (codex:mcp-tool-call-arc-monitor-callsite-always-allow)
   "mcp_tool_call__always_allow")

(= (codex:mcp-call-count-metric-name)
   "codex.mcp.call")

(= (codex:mcp-call-duration-metric-name)
   "codex.mcp.call.duration_ms")

(= (codex:app-tool-approval-auto)
   (CodexAppToolApprovalAuto))

(= (codex:app-tool-approval-prompt)
   (CodexAppToolApprovalPrompt))

(= (codex:app-tool-approval-approve)
   (CodexAppToolApprovalApprove))

(= (codex:mcp-tool-approval-key $server $connector-id $tool-name)
   (CodexMcpToolApprovalKey $server $connector-id $tool-name))

(= (codex:mcp-tool-approval-key-server
      (CodexMcpToolApprovalKey $server $connector-id $tool-name))
   $server)

(= (codex:mcp-tool-approval-key-connector-id
      (CodexMcpToolApprovalKey $server $connector-id $tool-name))
   $connector-id)

(= (codex:mcp-tool-approval-key-tool-name
      (CodexMcpToolApprovalKey $server $connector-id $tool-name))
   $tool-name)

(= (codex:mcp-tool-approval-prompt-options
      $allow-session-remember
      $allow-persistent-approval)
   (CodexMcpToolApprovalPromptOptions
     $allow-session-remember
     $allow-persistent-approval))

(= (codex:mcp-tool-approval-tool-config $approval-mode)
   (CodexMcpToolApprovalToolConfig $approval-mode))

(= (codex:mcp-tool-approval-tool-entry $tool-name $config)
   (CodexMcpToolApprovalToolEntry $tool-name $config))

(= (codex:mcp-tool-approval-server-config
      $default-tools-approval-mode
      $tools)
   (CodexMcpToolApprovalServerConfig
     $default-tools-approval-mode
     $tools))

(= (codex:mcp-tool-approval-server-entry $server-name $config)
   (CodexMcpToolApprovalServerEntry $server-name $config))

(= (codex:mcp-call-metric-tag $key $value)
   (CodexMcpCallMetricTag $key $value))

(= (codex:mcp-call-counter-metric-op $metric-name $inc $tags)
   (CodexMcpCallCounterMetricOp $metric-name $inc $tags))

(= (codex:mcp-call-duration-metric-op $metric-name $duration $tags)
   (CodexMcpCallDurationMetricOp $metric-name $duration $tags))

(= (codex:mcp-tool-call-span-fields
      $server-name
      $tool-name
      $call-id
      $server-origin
      $connector-id
      $connector-name)
   (CodexMcpToolCallSpanFields
     $server-name
     $tool-name
     $call-id
     $server-origin
     $connector-id
     $connector-name))

(= (codex:mcp-tool-call-span-field $key $value)
   (CodexMcpToolCallSpanField $key $value))

(= (codex:mcp-tool-call-span-plan $name $fields)
   (CodexMcpToolCallSpanPlan $name $fields))

(= (codex:mcp-span-empty-field-value)
   CodexMcpSpanEmpty)

(= (codex:mcp-app-usage-metadata $connector-id $app-name)
   (CodexMcpAppUsageMetadata $connector-id $app-name))

(= (codex:mcp-track-events-context $model-slug $thread-id $turn-id)
   (CodexMcpTrackEventsContext $model-slug $thread-id $turn-id))

(= (codex:mcp-app-invocation-type-explicit)
   (CodexMcpAppInvocationTypeExplicit))

(= (codex:mcp-app-invocation-type-implicit)
   (CodexMcpAppInvocationTypeImplicit))

(= (codex:mcp-app-invocation $connector-id $app-name $invocation-type)
   (CodexMcpAppInvocation $connector-id $app-name $invocation-type))

(= (codex:mcp-app-used-tracking-plan $tracking $app)
   (CodexMcpAppUsedTrackingPlan $tracking $app))

(= (codex:mcp-tool-info
      $server-name
      $tool
      $connector-id
      $connector-name)
   (CodexMcpToolInfo
     $server-name
     $tool
     $connector-id
     $connector-name))

(= (codex:mcp-tool-approval-prompt-options-allow-session-remember
      (CodexMcpToolApprovalPromptOptions
        $allow-session-remember
        $allow-persistent-approval))
   $allow-session-remember)

(= (codex:mcp-tool-approval-prompt-options-allow-persistent-approval
      (CodexMcpToolApprovalPromptOptions
        $allow-session-remember
        $allow-persistent-approval))
   $allow-persistent-approval)

(= (codex:mcp-tool-approval-metadata
      $connector-id
      $connector-name
      $connector-description
      $tool-title
      $tool-description)
   (CodexMcpToolApprovalMetadata
     $connector-id
     $connector-name
     $connector-description
     $tool-title
     $tool-description))

(= (codex:mcp-tool-approval-metadata-full
      $annotations
      $connector-id
      $connector-name
      $connector-description
      $tool-title
      $tool-description
      $mcp-app-resource-uri
      $codex-apps-meta
      $openai-file-input-params)
   (CodexMcpToolApprovalMetadataFull
     $annotations
     $connector-id
     $connector-name
     $connector-description
     $tool-title
     $tool-description
     $mcp-app-resource-uri
     $codex-apps-meta
     $openai-file-input-params))

(= (codex:mcp-tool-approval-metadata-annotations
      (CodexMcpToolApprovalMetadata
        $connector-id
        $connector-name
        $connector-description
        $tool-title
        $tool-description))
   CodexAbsent)

(= (codex:mcp-tool-approval-metadata-annotations
      (CodexMcpToolApprovalMetadataFull
        $annotations
        $connector-id
        $connector-name
        $connector-description
        $tool-title
        $tool-description
        $mcp-app-resource-uri
        $codex-apps-meta
        $openai-file-input-params))
   $annotations)

(= (codex:mcp-tool-approval-metadata-annotations CodexAbsent)
   CodexAbsent)

(= (codex:mcp-tool-approval-metadata-annotations Empty)
   CodexAbsent)

(= (codex:mcp-tool-approval-metadata-connector-id
      (CodexMcpToolApprovalMetadata
        $connector-id
        $connector-name
        $connector-description
        $tool-title
        $tool-description))
   $connector-id)

(= (codex:mcp-tool-approval-metadata-connector-id
      (CodexMcpToolApprovalMetadataFull
        $annotations
        $connector-id
        $connector-name
        $connector-description
        $tool-title
        $tool-description
        $mcp-app-resource-uri
        $codex-apps-meta
        $openai-file-input-params))
   $connector-id)

(= (codex:mcp-tool-approval-metadata-connector-id CodexAbsent)
   CodexAbsent)

(= (codex:mcp-tool-approval-metadata-connector-id Empty)
   CodexAbsent)

(= (codex:mcp-tool-approval-metadata-connector-name
      (CodexMcpToolApprovalMetadata
        $connector-id
        $connector-name
        $connector-description
        $tool-title
        $tool-description))
   $connector-name)

(= (codex:mcp-tool-approval-metadata-connector-name
      (CodexMcpToolApprovalMetadataFull
        $annotations
        $connector-id
        $connector-name
        $connector-description
        $tool-title
        $tool-description
        $mcp-app-resource-uri
        $codex-apps-meta
        $openai-file-input-params))
   $connector-name)

(= (codex:mcp-tool-approval-metadata-connector-name CodexAbsent)
   CodexAbsent)

(= (codex:mcp-tool-approval-metadata-connector-name Empty)
   CodexAbsent)

(= (codex:mcp-tool-approval-metadata-connector-description
      (CodexMcpToolApprovalMetadata
        $connector-id
        $connector-name
        $connector-description
        $tool-title
        $tool-description))
   $connector-description)

(= (codex:mcp-tool-approval-metadata-connector-description
      (CodexMcpToolApprovalMetadataFull
        $annotations
        $connector-id
        $connector-name
        $connector-description
        $tool-title
        $tool-description
        $mcp-app-resource-uri
        $codex-apps-meta
        $openai-file-input-params))
   $connector-description)

(= (codex:mcp-tool-approval-metadata-connector-description CodexAbsent)
   CodexAbsent)

(= (codex:mcp-tool-approval-metadata-connector-description Empty)
   CodexAbsent)

(= (codex:mcp-tool-approval-metadata-tool-title
      (CodexMcpToolApprovalMetadata
        $connector-id
        $connector-name
        $connector-description
        $tool-title
        $tool-description))
   $tool-title)

(= (codex:mcp-tool-approval-metadata-tool-title
      (CodexMcpToolApprovalMetadataFull
        $annotations
        $connector-id
        $connector-name
        $connector-description
        $tool-title
        $tool-description
        $mcp-app-resource-uri
        $codex-apps-meta
        $openai-file-input-params))
   $tool-title)

(= (codex:mcp-tool-approval-metadata-tool-title CodexAbsent)
   CodexAbsent)

(= (codex:mcp-tool-approval-metadata-tool-title Empty)
   CodexAbsent)

(= (codex:mcp-tool-approval-metadata-tool-description
      (CodexMcpToolApprovalMetadata
        $connector-id
        $connector-name
        $connector-description
        $tool-title
        $tool-description))
   $tool-description)

(= (codex:mcp-tool-approval-metadata-tool-description
      (CodexMcpToolApprovalMetadataFull
        $annotations
        $connector-id
        $connector-name
        $connector-description
        $tool-title
        $tool-description
        $mcp-app-resource-uri
        $codex-apps-meta
        $openai-file-input-params))
   $tool-description)

(= (codex:mcp-tool-approval-metadata-tool-description CodexAbsent)
   CodexAbsent)

(= (codex:mcp-tool-approval-metadata-tool-description Empty)
   CodexAbsent)

(= (codex:mcp-tool-approval-metadata-codex-apps-meta
      (CodexMcpToolApprovalMetadata
        $connector-id
        $connector-name
        $connector-description
        $tool-title
        $tool-description))
   CodexAbsent)

(= (codex:mcp-tool-approval-metadata-codex-apps-meta
      (CodexMcpToolApprovalMetadataFull
        $annotations
        $connector-id
        $connector-name
        $connector-description
        $tool-title
        $tool-description
        $mcp-app-resource-uri
        $codex-apps-meta
        $openai-file-input-params))
   $codex-apps-meta)

(= (codex:mcp-tool-approval-metadata-codex-apps-meta CodexAbsent)
   CodexAbsent)

(= (codex:mcp-tool-approval-metadata-codex-apps-meta Empty)
   CodexAbsent)

(= (codex:mcp-tool-approval-metadata-mcp-app-resource-uri
      (CodexMcpToolApprovalMetadata
        $connector-id
        $connector-name
        $connector-description
        $tool-title
        $tool-description))
   CodexAbsent)

(= (codex:mcp-tool-approval-metadata-mcp-app-resource-uri
      (CodexMcpToolApprovalMetadataFull
        $annotations
        $connector-id
        $connector-name
        $connector-description
        $tool-title
        $tool-description
        $mcp-app-resource-uri
        $codex-apps-meta
        $openai-file-input-params))
   $mcp-app-resource-uri)

(= (codex:mcp-tool-approval-metadata-mcp-app-resource-uri CodexAbsent)
   CodexAbsent)

(= (codex:mcp-tool-approval-metadata-mcp-app-resource-uri Empty)
   CodexAbsent)

(= (codex:mcp-tool-approval-metadata-openai-file-input-params
      (CodexMcpToolApprovalMetadata
        $connector-id
        $connector-name
        $connector-description
        $tool-title
        $tool-description))
   CodexAbsent)

(= (codex:mcp-tool-approval-metadata-openai-file-input-params
      (CodexMcpToolApprovalMetadataFull
        $annotations
        $connector-id
        $connector-name
        $connector-description
        $tool-title
        $tool-description
        $mcp-app-resource-uri
        $codex-apps-meta
        $openai-file-input-params))
   $openai-file-input-params)

(= (codex:mcp-tool-approval-metadata-openai-file-input-params CodexAbsent)
   CodexAbsent)

(= (codex:mcp-tool-approval-metadata-openai-file-input-params Empty)
   CodexAbsent)

(= (codex:mcp-tool-annotations
      $read-only-hint
      $destructive-hint
      $open-world-hint)
   (CodexMcpToolAnnotations
     $read-only-hint
     $destructive-hint
     $open-world-hint))

(= (codex:mcp-tool-annotations-read-only-hint
      (CodexMcpToolAnnotations
        $read-only-hint
        $destructive-hint
        $open-world-hint))
   $read-only-hint)

(= (codex:mcp-tool-annotations-destructive-hint
      (CodexMcpToolAnnotations
        $read-only-hint
        $destructive-hint
        $open-world-hint))
   $destructive-hint)

(= (codex:mcp-tool-annotations-open-world-hint
      (CodexMcpToolAnnotations
        $read-only-hint
        $destructive-hint
        $open-world-hint))
   $open-world-hint)

(= (codex:mcp-tool-approval-decision-accept)
   (CodexMcpToolApprovalDecisionAccept))

(= (codex:mcp-tool-approval-decision-accept-for-session)
   (CodexMcpToolApprovalDecisionAcceptForSession))

(= (codex:mcp-tool-approval-decision-accept-and-remember)
   (CodexMcpToolApprovalDecisionAcceptAndRemember))

(= (codex:mcp-tool-approval-decision-cancel)
   (CodexMcpToolApprovalDecisionCancel))

(= (codex:mcp-tool-approval-decision-decline $message)
   (CodexMcpToolApprovalDecisionDecline $message))

(= (codex:mcp-tool-approval-decision-blocked-by-safety-monitor $message)
   (CodexMcpToolApprovalDecisionBlockedBySafetyMonitor $message))

(= (codex:mcp-tool-approval-elicitation-response $action $content $meta)
   (CodexMcpToolApprovalElicitationResponse $action $content $meta))

(= (codex:mcp-tool-approval-elicitation-request
      $server
      $metadata
      $tool-params
      $tool-params-display
      $question
      $message-override
      $prompt-options)
   (CodexMcpToolApprovalElicitationRequest
     $server
     $metadata
     $tool-params
     $tool-params-display
     $question
     $message-override
     $prompt-options))

(= (codex:mcp-server-elicitation-request-form
      $meta
      $message
      $requested-schema)
   (CodexMcpServerElicitationRequestForm
     $meta
     $message
     $requested-schema))

(= (codex:mcp-server-elicitation-request-params
      $thread-id
      $turn-id
      $server-name
      $request)
   (CodexMcpServerElicitationRequestParams
     $thread-id
     $turn-id
     $server-name
     $request))

(= (codex:mcp-tool-call-present $value)
   (if (== $value CodexAbsent) False True))

(= (codex:mcp-tool-call-list-contains $items $item)
   (if (== $items ())
       False
       (let $head (list:first $items)
         (let $tail (list:rest $items)
           (if (== $head $item)
               True
               (codex:mcp-tool-call-list-contains $tail $item))))))

(= (codex:mcp-tool-call-bool-or-default $value $default)
   (if (== $value CodexAbsent) $default $value))

(= (codex:mcp-metric-tag-max-len)
   256)

(= (codex:mcp-metric-tag-is-ascii-alphanumeric $char)
   (let $found
     (str-find
       "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
       $char)
     (if (== $found Empty) False True)))

(= (codex:mcp-metric-tag-is-valid-char $char)
   (let $found
     (str-find
       "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz._-/"
       $char)
     (if (== $found Empty) False True)))

(= (codex:mcp-metric-tag-sanitize-chars-from $value $index $acc)
   (let $len (str-length $value)
     (if (== $index $len)
         $acc
         (let $char (str-slice $value $index (+ $index 1))
           (case (codex:mcp-metric-tag-is-valid-char $char)
             ((True
               (codex:mcp-metric-tag-sanitize-chars-from
                 $value
                 (+ $index 1)
                 (str-concat $acc $char)))
              (False
               (codex:mcp-metric-tag-sanitize-chars-from
                 $value
                 (+ $index 1)
                 (str-concat $acc "_")))))))))

(= (codex:mcp-metric-tag-trim-leading-underscores $value)
   (if (== (str-length $value) 0)
       ""
       (if (== (str-slice $value 0 1) "_")
           (codex:mcp-metric-tag-trim-leading-underscores
             (str-slice $value 1 (str-length $value)))
           $value)))

(= (codex:mcp-metric-tag-trim-trailing-underscores $value)
   (let $len (str-length $value)
     (if (== $len 0)
         ""
         (if (== (str-slice $value (- $len 1) $len) "_")
             (codex:mcp-metric-tag-trim-trailing-underscores
               (str-slice $value 0 (- $len 1)))
             $value))))

(= (codex:mcp-metric-tag-trim-underscores $value)
   (codex:mcp-metric-tag-trim-trailing-underscores
     (codex:mcp-metric-tag-trim-leading-underscores $value)))

(= (codex:mcp-metric-tag-contains-ascii-alphanumeric-from $value $index)
   (if (== $index (str-length $value))
       False
       (if (codex:mcp-metric-tag-is-ascii-alphanumeric
             (str-slice $value $index (+ $index 1)))
           True
           (codex:mcp-metric-tag-contains-ascii-alphanumeric-from
             $value
             (+ $index 1)))))

(= (codex:mcp-metric-tag-contains-ascii-alphanumeric $value)
   (codex:mcp-metric-tag-contains-ascii-alphanumeric-from $value 0))

(= (codex:sanitize-mcp-metric-tag-value-after-trim "")
   "unspecified")

(= (codex:sanitize-mcp-metric-tag-value-after-trim $trimmed)
   (if (codex:mcp-metric-tag-contains-ascii-alphanumeric $trimmed)
       (if (<= (str-length $trimmed)
               (codex:mcp-metric-tag-max-len))
           $trimmed
           (str-slice
             $trimmed
             0
             (codex:mcp-metric-tag-max-len)))
       "unspecified"))

(= (codex:sanitize-mcp-metric-tag-value-after-sanitize $sanitized)
   (case (codex:mcp-metric-tag-trim-underscores $sanitized)
     (($trimmed
       (codex:sanitize-mcp-metric-tag-value-after-trim $trimmed)))))

(= (codex:sanitize-mcp-metric-tag-value $value)
   (if (== $value "")
       "unspecified"
       (case (codex:mcp-metric-tag-sanitize-chars-from $value 0 "")
         (($sanitized
           (codex:sanitize-mcp-metric-tag-value-after-sanitize
             $sanitized))))))

(= (codex:mcp-call-metric-optional-string-is-nonempty $value)
   (if (or (== $value CodexAbsent)
           (== $value ""))
       False
       True))

(= (codex:mcp-call-metric-tags-from-presence
      $status-value
      $tool-value
      False
      False
      $connector-id
      $connector-name)
   ((CodexMcpCallMetricTag "status" $status-value)
    (CodexMcpCallMetricTag "tool" $tool-value)))

(= (codex:mcp-call-metric-tags-from-presence
      $status-value
      $tool-value
      True
      False
      $connector-id
      $connector-name)
   (case (codex:sanitize-mcp-metric-tag-value $connector-id)
     (($connector-id-value
       ((CodexMcpCallMetricTag "status" $status-value)
        (CodexMcpCallMetricTag "tool" $tool-value)
        (CodexMcpCallMetricTag
          "connector_id"
          $connector-id-value))))))

(= (codex:mcp-call-metric-tags-from-presence
      $status-value
      $tool-value
      False
      True
      $connector-id
      $connector-name)
   (case (codex:sanitize-mcp-metric-tag-value $connector-name)
     (($connector-name-value
       ((CodexMcpCallMetricTag "status" $status-value)
        (CodexMcpCallMetricTag "tool" $tool-value)
        (CodexMcpCallMetricTag
          "connector_name"
          $connector-name-value))))))

(= (codex:mcp-call-metric-tags-from-presence
      $status-value
      $tool-value
      True
      True
      $connector-id
      $connector-name)
   (case (codex:sanitize-mcp-metric-tag-value $connector-id)
     (($connector-id-value
       (case (codex:sanitize-mcp-metric-tag-value $connector-name)
         (($connector-name-value
           ((CodexMcpCallMetricTag "status" $status-value)
            (CodexMcpCallMetricTag "tool" $tool-value)
            (CodexMcpCallMetricTag
              "connector_id"
              $connector-id-value)
            (CodexMcpCallMetricTag
              "connector_name"
              $connector-name-value)))))))))

(= (codex:mcp-call-metric-tags
      $status
      $tool-name
      $connector-id
      $connector-name)
   (case (codex:sanitize-mcp-metric-tag-value $status)
     (($status-value
       (case (codex:sanitize-mcp-metric-tag-value $tool-name)
         (($tool-value
           (case
             (codex:mcp-call-metric-optional-string-is-nonempty
               $connector-id)
             (($connector-id-present
               (case
                 (codex:mcp-call-metric-optional-string-is-nonempty
                   $connector-name)
                 (($connector-name-present
                   (codex:mcp-call-metric-tags-from-presence
                     $status-value
                     $tool-value
                     $connector-id-present
                     $connector-name-present
                     $connector-id
                     $connector-name))))))))))))))

(= (codex:emit-mcp-call-metrics-plan-from-tags $tags $duration)
   (if (or (== $duration CodexAbsent)
           (== $duration Empty))
       ((CodexMcpCallCounterMetricOp
          (codex:mcp-call-count-metric-name)
          1
          $tags))
       ((CodexMcpCallCounterMetricOp
          (codex:mcp-call-count-metric-name)
          1
          $tags)
        (CodexMcpCallDurationMetricOp
          (codex:mcp-call-duration-metric-name)
          $duration
          $tags))))

(= (codex:emit-mcp-call-metrics-plan
      $status
      $tool-name
      $connector-id
      $connector-name
      $duration)
   (case (codex:mcp-call-metric-tags
           $status
           $tool-name
           $connector-id
           $connector-name)
     (($tags
       (codex:emit-mcp-call-metrics-plan-from-tags $tags $duration)))))

(= (codex:mcp-span-ascii-lower-char $char)
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
      ($other $char))))

(= (codex:mcp-span-ascii-lower-text $text)
   (if (== $text "")
       ""
       (str-concat
         (codex:mcp-span-ascii-lower-char (str-slice $text 0 1))
         (codex:mcp-span-ascii-lower-text
           (str-slice $text 1 (str-length $text))))))

(= (codex:mcp-tool-call-span-optional-text $value)
   (if (== $value CodexAbsent)
       ""
       $value))

(= (codex:mcp-tool-call-span-transport $server-origin)
   (if (== $server-origin CodexAbsent)
       ""
       (if (== $server-origin "stdio")
           "stdio"
           "streamable_http")))

(= (codex:mcp-span-known-default-port $scheme)
   (case (codex:mcp-span-ascii-lower-text $scheme)
     (("http" 80)
      ("https" 443)
      ("ws" 80)
      ("wss" 443)
      ("ftp" 21)
      ($other CodexAbsent))))

(= (codex:mcp-span-decimal-digit-value $digit)
   (case $digit
     (("0" 0)
      ("1" 1)
      ("2" 2)
      ("3" 3)
      ("4" 4)
      ("5" 5)
      ("6" 6)
      ("7" 7)
      ("8" 8)
      ("9" 9))))

(= (codex:mcp-span-decimal-digit-value-or-absent $digit)
   (case $digit
     (("0" 0)
      ("1" 1)
      ("2" 2)
      ("3" 3)
      ("4" 4)
      ("5" 5)
      ("6" 6)
      ("7" 7)
      ("8" 8)
      ("9" 9)
      ($other CodexAbsent))))

(= (codex:mcp-span-is-decimal-digit $digit)
   (let $found (str-find "0123456789" $digit)
     (if (== $found Empty) False True)))

(= (codex:mcp-span-is-decimal-digits-from $text $index)
   (if (== $index (str-length $text))
       True
       (if (codex:mcp-span-is-decimal-digit
             (str-slice $text $index (+ $index 1)))
           (codex:mcp-span-is-decimal-digits-from $text (+ $index 1))
           False)))

(= (codex:mcp-span-is-decimal-digits $text)
   (if (== $text "")
       False
       (codex:mcp-span-is-decimal-digits-from $text 0)))

(= (codex:mcp-span-decimal-string-to-number-from $text $index $acc)
   (if (== $index (str-length $text))
       $acc
       (let $digit
         (codex:mcp-span-decimal-digit-value
           (str-slice $text $index (+ $index 1)))
         (codex:mcp-span-decimal-string-to-number-from
           $text
           (+ $index 1)
           (+ (* $acc 10) $digit)))))

(= (codex:mcp-span-decimal-string-to-number $text)
   (codex:mcp-span-decimal-string-to-number-from $text 0 0))

(= (codex:mcp-span-parse-explicit-port $text)
   (if (codex:mcp-span-is-decimal-digits $text)
       (let $port (codex:mcp-span-decimal-string-to-number $text)
         (if (<= $port 65535) $port CodexAbsent))
       CodexAbsent))

(= (codex:mcp-span-explicit-port-fields-from
      $host
      $text
      $index
      $acc)
   (if (== $index (str-length $text))
       (if (<= $acc 65535)
           (CodexMcpSpanParsedServerFields $host $acc)
           CodexAbsent)
       (let $digit
         (codex:mcp-span-decimal-digit-value-or-absent
           (str-slice $text $index (+ $index 1)))
         (if (== $digit CodexAbsent)
             CodexAbsent
             (codex:mcp-span-explicit-port-fields-from
               $host
               $text
               (+ $index 1)
               (+ (* $acc 10) $digit))))))

(= (codex:mcp-span-explicit-port-fields $host $text)
   (if (== $text "")
       CodexAbsent
       (codex:mcp-span-explicit-port-fields-from $host $text 0 0)))

(= (codex:mcp-span-min-index $left $right)
   (if (<= $left $right) $left $right))

(= (codex:mcp-span-url-authority-end $text)
   (let $len (str-length $text)
     (let $slash
       (case (str-find $text "/")
         ((Empty $len)
          ($index $index)))
       (let $query
         (case (str-find $text "?")
           ((Empty $len)
            ($index $index)))
         (let $fragment
           (case (str-find $text "#")
             ((Empty $len)
              ($index $index)))
           (codex:mcp-span-min-index
             $slash
             (codex:mcp-span-min-index $query $fragment)))))))

(= (codex:mcp-span-url-authority-end-from $text $index)
   (if (== $index 0)
       (codex:mcp-span-url-authority-end $text)
       (+ $index
          (codex:mcp-span-url-authority-end
            (str-slice $text $index (str-length $text))))))

(= (codex:mcp-span-origin-parts-from-scheme-end
      $server-origin
      $scheme-end)
   (let $after-scheme
     (str-slice
       $server-origin
       (+ $scheme-end 3)
       (str-length $server-origin))
     (let $authority-end
       (codex:mcp-span-url-authority-end-from $after-scheme 0)
       (let $authority
         (str-slice $after-scheme 0 $authority-end)
         (if (== $authority "")
             CodexAbsent
             (CodexMcpSpanOriginParts
               (str-slice $server-origin 0 $scheme-end)
               $authority))))))

(= (codex:mcp-span-origin-parts $server-origin)
   (case (str-find $server-origin "://")
     ((Empty CodexAbsent)
      ($scheme-end
       (codex:mcp-span-origin-parts-from-scheme-end
         $server-origin
         $scheme-end)))))

(= (codex:mcp-span-server-fields-from-scheme-end
      $server-origin
      $scheme-end)
   (let $after-scheme
     (str-slice
       $server-origin
       (+ $scheme-end 3)
       (str-length $server-origin))
     (let $authority-end
       (codex:mcp-span-url-authority-end-from $after-scheme 0)
       (let $authority
         (str-slice $after-scheme 0 $authority-end)
         (if (== $authority "")
             CodexAbsent
             (codex:mcp-span-host-port-from-authority
               (str-slice $server-origin 0 $scheme-end)
               $authority))))))

(= (codex:mcp-span-authority-without-userinfo $authority)
   (case (str-find $authority "@")
     ((Empty $authority)
      ($at-index
       (str-slice
         $authority
         (+ $at-index 1)
         (str-length $authority))))))

(= (codex:mcp-span-host-port-from-bracketed $scheme $host-part)
   (case (str-find $host-part "]")
     ((Empty CodexAbsent)
      ($close-index
       (let $host (str-slice $host-part 1 $close-index)
         (if (== $host "")
             CodexAbsent
             (let $rest
               (str-slice
                 $host-part
                 (+ $close-index 1)
                 (str-length $host-part))
                   (if (== $rest "")
                       (if (== $scheme "http")
                           (CodexMcpSpanParsedServerFields $host 80)
                           (if (== $scheme "https")
                               (CodexMcpSpanParsedServerFields $host 443)
                               (if (== $scheme "ws")
                                   (CodexMcpSpanParsedServerFields $host 80)
                                   (if (== $scheme "wss")
                                       (CodexMcpSpanParsedServerFields
                                         $host
                                         443)
                                       (if (== $scheme "ftp")
                                           (CodexMcpSpanParsedServerFields
                                             $host
                                             21)
                                           (CodexMcpSpanParsedServerFields
                                             $host
                                             CodexAbsent))))))
                       (if (str-starts-with? $rest ":")
                       (codex:mcp-span-explicit-port-fields
                         $host
                         (str-slice $rest 1 (str-length $rest)))
                       CodexAbsent)))))))))

(= (codex:mcp-span-host-port-from-reg-name $scheme $host-part)
   (let $parts (str-split ":" $host-part)
         (if (== (list:len $parts) 1)
             (if (== $host-part "")
                 CodexAbsent
             (if (== $scheme "http")
                 (CodexMcpSpanParsedServerFields $host-part 80)
                 (if (== $scheme "https")
                     (CodexMcpSpanParsedServerFields $host-part 443)
                     (if (== $scheme "ws")
                         (CodexMcpSpanParsedServerFields $host-part 80)
                         (if (== $scheme "wss")
                             (CodexMcpSpanParsedServerFields
                               $host-part
                               443)
                             (if (== $scheme "ftp")
                                 (CodexMcpSpanParsedServerFields
                                   $host-part
                                   21)
                                 (CodexMcpSpanParsedServerFields
                                   $host-part
                                   CodexAbsent)))))))
         (if (== (list:len $parts) 2)
             (let $host (list:first $parts)
                 (let $port-text (list:first (list:rest $parts))
                   (if (== $host "")
                       CodexAbsent
                     (codex:mcp-span-explicit-port-fields
                       $host
                       $port-text))))
             CodexAbsent))))

(= (codex:mcp-span-host-port-from-authority $scheme $authority)
   (let $host-part
     (codex:mcp-span-authority-without-userinfo $authority)
     (if (str-starts-with? $host-part "[")
         (codex:mcp-span-host-port-from-bracketed $scheme $host-part)
         (codex:mcp-span-host-port-from-reg-name $scheme $host-part))))

(= (codex:mcp-span-server-fields-from-origin $server-origin)
   (case (str-find $server-origin "://")
     ((Empty CodexAbsent)
      ($scheme-end
       (codex:mcp-span-server-fields-from-scheme-end
         $server-origin
         $scheme-end)))))

(= (codex:mcp-span-port-field-value $port)
   (if (== $port CodexAbsent)
       (codex:mcp-span-empty-field-value)
       $port))

(= (codex:mcp-tool-call-span-plan-from-server-fields
      $conversation-id
      $turn-id
      $fields
      $server-address
      $server-port)
   (case $fields
     (((CodexMcpToolCallSpanFields
         $server-name
         $tool-name
         $call-id
         $server-origin
         $connector-id
         $connector-name)
       (CodexMcpToolCallSpanPlan
         "mcp.tools.call"
         ((CodexMcpToolCallSpanField "otel.kind" "client")
          (CodexMcpToolCallSpanField "rpc.system" "jsonrpc")
          (CodexMcpToolCallSpanField "rpc.method" "tools/call")
          (CodexMcpToolCallSpanField "mcp.server.name" $server-name)
          (CodexMcpToolCallSpanField
            "mcp.server.origin"
            (codex:mcp-tool-call-span-optional-text $server-origin))
          (CodexMcpToolCallSpanField
            "mcp.transport"
            (codex:mcp-tool-call-span-transport $server-origin))
          (CodexMcpToolCallSpanField
            "mcp.connector.id"
            (codex:mcp-tool-call-span-optional-text $connector-id))
          (CodexMcpToolCallSpanField
            "mcp.connector.name"
            (codex:mcp-tool-call-span-optional-text $connector-name))
          (CodexMcpToolCallSpanField "tool.name" $tool-name)
          (CodexMcpToolCallSpanField "tool.call_id" $call-id)
          (CodexMcpToolCallSpanField "conversation.id" $conversation-id)
          (CodexMcpToolCallSpanField "session.id" $conversation-id)
          (CodexMcpToolCallSpanField "turn.id" $turn-id)
          (CodexMcpToolCallSpanField "server.address" $server-address)
          (CodexMcpToolCallSpanField "server.port" $server-port)))))))

(= (codex:mcp-tool-call-span-plan
      $conversation-id
      $turn-id
      $fields)
   (case $fields
     (((CodexMcpToolCallSpanFields
         $server-name
         $tool-name
         $call-id
         $server-origin
         $connector-id
         $connector-name)
       (case (codex:mcp-span-server-fields-from-origin $server-origin)
         ((CodexAbsent
           (codex:mcp-tool-call-span-plan-from-server-fields
             $conversation-id
             $turn-id
             $fields
             (codex:mcp-span-empty-field-value)
             (codex:mcp-span-empty-field-value)))
          ((CodexMcpSpanParsedServerFields $host $port)
           (codex:mcp-tool-call-span-plan-from-server-fields
             $conversation-id
             $turn-id
             $fields
             $host
             (codex:mcp-span-port-field-value $port)))))))))

(= (codex:mcp-tool-call-approval-mode-or-default CodexAbsent)
   (codex:app-tool-approval-auto))

(= (codex:mcp-tool-call-approval-mode-or-default Empty)
   (codex:app-tool-approval-auto))

(= (codex:mcp-tool-call-approval-mode-or-default
      (CodexAppToolApprovalAuto))
   (codex:app-tool-approval-auto))

(= (codex:mcp-tool-call-approval-mode-or-default
      (CodexAppToolApprovalPrompt))
   (codex:app-tool-approval-prompt))

(= (codex:mcp-tool-call-approval-mode-or-default
      (CodexAppToolApprovalApprove))
   (codex:app-tool-approval-approve))

(= (codex:mcp-tool-call-json-value-or-null $value)
   (if (== $value CodexAbsent)
       JsonNull
       (if (== $value Empty)
           JsonNull
           $value)))

(= (codex:mcp-tool-call-json-string-or-empty $value)
   (case $value
     (((JsonString $text) $text)
      ($other Empty))))

(= (codex:get-mcp-app-resource-uri CodexAbsent)
   Empty)

(= (codex:get-mcp-app-resource-uri Empty)
   Empty)

(= (codex:get-mcp-app-resource-uri (JsonObject $pairs))
   (let $meta (JsonObject $pairs)
     (case
       (case (json-object-get $meta "ui")
         (((JsonObject $ui-pairs)
           (codex:mcp-tool-call-json-string-or-empty
             (json-object-get
               (JsonObject $ui-pairs)
               "resourceUri")))
          ($other Empty)))
       ((Empty
          (case
            (codex:mcp-tool-call-json-string-or-empty
              (json-object-get
                $meta
                (codex:mcp-tool-ui-resource-uri-meta-key)))
            ((Empty
               (codex:mcp-tool-call-json-string-or-empty
                 (json-object-get
                   $meta
                   (codex:mcp-tool-openai-output-template-meta-key))))
             ($flat-uri $flat-uri))))
        ($nested-uri $nested-uri)))))

(= (codex:get-mcp-app-resource-uri (JsonString $value))
   Empty)

(= (codex:get-mcp-app-resource-uri (JsonArray $items))
   Empty)

(= (codex:get-mcp-app-resource-uri (JsonNumber $value))
   Empty)

(= (codex:get-mcp-app-resource-uri (JsonBool $value))
   Empty)

(= (codex:get-mcp-app-resource-uri JsonNull)
   Empty)

(= (codex:declared-openai-file-input-param-names CodexAbsent)
   ())

(= (codex:declared-openai-file-input-param-names Empty)
   ())

(= (codex:declared-openai-file-input-param-names (JsonObject $pairs))
   (case
     (json-object-get
       (JsonObject $pairs)
       (codex:mcp-tool-openai-file-params-meta-key))
     (((JsonArray $items)
       (codex:mcp-tool-call-openai-file-param-names $items))
      ($other ()))))

(= (codex:declared-openai-file-input-param-names (JsonString $value))
   ())

(= (codex:declared-openai-file-input-param-names (JsonArray $items))
   ())

(= (codex:declared-openai-file-input-param-names (JsonNumber $value))
   ())

(= (codex:declared-openai-file-input-param-names (JsonBool $value))
   ())

(= (codex:declared-openai-file-input-param-names JsonNull)
   ())

(= (codex:mcp-tool-call-openai-file-param-names $items)
   (if (== $items ())
       ()
       (let ($head $tail) (decons-atom $items)
         (case
           (codex:mcp-tool-call-openai-file-param-names $tail)
           (($tail-names
             (case $head
               (((JsonString $value)
                 (if (== $value "")
                     $tail-names
                     (cons-atom $value $tail-names)))
                ($other $tail-names)))))))))

(= (codex:mcp-tool-approval-elicitation-object-schema)
   (JsonObject
     ((JsonPair "type" (JsonString "object"))
      (JsonPair "properties" (JsonObject ())))))

(= (codex:mcp-tool-approval-elicitation-message
      $question
      $message-override)
   (if (== $message-override CodexAbsent)
       (codex:request-user-input-question-text $question)
       (if (== $message-override Empty)
           (codex:request-user-input-question-text $question)
           $message-override)))

(= (codex:build-mcp-tool-approval-elicitation-request
      $thread-id
      $turn-id
      $request)
   (case (eval $request)
     (((CodexMcpToolApprovalElicitationRequest
         $server
         $metadata
         $tool-params
         $tool-params-display
         $question
         $message-override
         $prompt-options)
       (codex:mcp-server-elicitation-request-params
         $thread-id
         $turn-id
         $server
         (codex:mcp-server-elicitation-request-form
           (codex:build-mcp-tool-approval-elicitation-meta
             $server
             $metadata
             $tool-params
             $tool-params-display
             $prompt-options)
           (codex:mcp-tool-approval-elicitation-message
             $question
             $message-override)
           (codex:mcp-tool-approval-elicitation-object-schema)))))))

(= (codex:mcp-server-elicitation-request-json
      (CodexMcpServerElicitationRequestParams
        $thread-id
        $turn-id
        $server-name
        (CodexMcpServerElicitationRequestForm
          $meta
          $message
          $requested-schema)))
   (JsonObject
     ((JsonPair "threadId" (JsonString $thread-id))
      (JsonPair
        "turnId"
        (if (== $turn-id CodexAbsent)
            JsonNull
            (JsonString $turn-id)))
      (JsonPair "serverName" (JsonString $server-name))
      (JsonPair "mode" (JsonString "form"))
      (JsonPair "_meta" (codex:mcp-tool-call-json-value-or-null $meta))
      (JsonPair "message" (JsonString $message))
      (JsonPair "requestedSchema" $requested-schema))))

(= (codex:mcp-tool-call-image-content-omitted-text)
   "<image content omitted because you do not support image input>")

(= (codex:mcp-tool-call-omitted-image-content-block)
   (JsonObject
     ((JsonPair "type" (JsonString "text"))
      (JsonPair
        "text"
        (JsonString
          (codex:mcp-tool-call-image-content-omitted-text))))))

(= (codex:sanitize-mcp-tool-result-content-block (JsonObject $pairs))
   (if (== (json-object-get (JsonObject $pairs) "type")
           (JsonString "image"))
       (codex:mcp-tool-call-omitted-image-content-block)
       (JsonObject $pairs)))

(= (codex:sanitize-mcp-tool-result-content-block (JsonString $value))
   (JsonString $value))

(= (codex:sanitize-mcp-tool-result-content-block (JsonArray $items))
   (JsonArray $items))

(= (codex:sanitize-mcp-tool-result-content-block (JsonNumber $value))
   (JsonNumber $value))

(= (codex:sanitize-mcp-tool-result-content-block (JsonBool $value))
   (JsonBool $value))

(= (codex:sanitize-mcp-tool-result-content-block JsonNull)
   JsonNull)

(= (codex:sanitize-mcp-tool-result-content-blocks $content)
   (if (== $content ())
       ()
       (let ($head $tail) (decons-atom $content)
         (case (codex:sanitize-mcp-tool-result-content-block $head)
           (($sanitized-head
             (case
               (codex:sanitize-mcp-tool-result-content-blocks $tail)
               (($sanitized-tail
                 (cons-atom $sanitized-head $sanitized-tail))))))))))

(= (codex:sanitize-mcp-tool-result-for-model True $result)
   (case (eval $result)
     (($evaluated $evaluated))))

(= (codex:sanitize-mcp-tool-result-for-model False $result)
   (case (eval $result)
     (((CodexMcpToolCallResultErr $message)
       (CodexMcpToolCallResultErr $message))
      ((CodexMcpToolCallResultOk $call-tool-result)
       (case (eval $call-tool-result)
         (((CodexMcpCallToolResult
             $content
             $structured-content
             $is-error
             $meta)
           (case
             (codex:sanitize-mcp-tool-result-content-blocks $content)
             (($sanitized-content
               (CodexMcpToolCallResultOk
                 (CodexMcpCallToolResult
                   $sanitized-content
                   $structured-content
                   $is-error
                   $meta))))))))))))

(= (codex:mcp-tool-call-skip-plan $events $result)
   (CodexMcpToolCallSkipPlan $events $result))

(= (codex:mcp-tool-call-skip-plan-events
      (CodexMcpToolCallSkipPlan $events $result))
   $events)

(= (codex:mcp-tool-call-skip-plan-result
      (CodexMcpToolCallSkipPlan $events $result))
   $result)

(= (codex:notify-mcp-tool-call-skip-plan
      $call-id
      $invocation
      $mcp-app-resource-uri
      $message
      True)
   (let $result
     (codex:mcp-tool-call-result-err $message)
     (codex:mcp-tool-call-skip-plan
       ((codex:mcp-tool-call-end-event
          $call-id
          $invocation
          $mcp-app-resource-uri
          (codex:duration 0 0)
          $result))
       $result)))

(= (codex:notify-mcp-tool-call-skip-plan
      $call-id
      $invocation
      $mcp-app-resource-uri
      $message
      False)
   (let $result
     (codex:mcp-tool-call-result-err $message)
     (codex:mcp-tool-call-skip-plan
       ((codex:mcp-tool-call-begin-event
          $call-id
          $invocation
          $mcp-app-resource-uri)
        (codex:mcp-tool-call-end-event
          $call-id
          $invocation
          $mcp-app-resource-uri
          (codex:duration 0 0)
          $result))
       $result)))

(= (codex:mcp-tool-call-trim-end-question-marks $text)
   (if (== $text "")
       ""
       (if (str-ends-with? $text "?")
           (codex:mcp-tool-call-trim-end-question-marks
             (str-slice $text 0 (- (str-length $text) 1)))
           $text)))

(= (codex:mcp-tool-call-present-trimmed-string $value)
   (if (== $value CodexAbsent)
       Empty
       (let $trimmed (str-trim $value)
         (if (== $trimmed "") Empty $trimmed))))

(= (codex:mcp-tool-approval-server-config-default-mode $config)
   (case (eval $config)
     (((CodexMcpToolApprovalServerConfig $default-tools-approval-mode $tools)
       $default-tools-approval-mode)
      ((CodexMcpServerConfig
         $transport
         $experimental-environment
         $enabled
         $required
         $supports-parallel-tool-calls
         $disabled-reason
         $startup-timeout-sec
         $tool-timeout-sec
         $default-tools-approval-mode
         $enabled-tools
         $disabled-tools
         $scopes
         $oauth-resource
         $tools)
       $default-tools-approval-mode)
      ($other CodexAbsent))))

(= (codex:mcp-tool-approval-server-config-tools $config)
   (case (eval $config)
     (((CodexMcpToolApprovalServerConfig $default-tools-approval-mode $tools)
       $tools)
      ((CodexMcpServerConfig
         $transport
         $experimental-environment
         $enabled
         $required
         $supports-parallel-tool-calls
         $disabled-reason
         $startup-timeout-sec
         $tool-timeout-sec
         $default-tools-approval-mode
         $enabled-tools
         $disabled-tools
         $scopes
         $oauth-resource
         $tools)
       $tools)
      ($other ()))))

(= (codex:mcp-tool-approval-tool-config-mode $config)
   (case (eval $config)
     (((CodexMcpToolApprovalToolConfig $approval-mode)
       $approval-mode)
      ((CodexMcpServerToolConfig $approval-mode)
       $approval-mode)
      ($other CodexAbsent))))

(= (codex:mcp-tool-approval-server-config-by-name $servers $server)
   (if (== $servers ())
       Empty
       (let $head (list:first $servers)
         (let $tail (list:rest $servers)
           (case (eval $head)
             (((CodexMcpToolApprovalServerEntry $name $config)
               (if (== $name $server)
                   $config
                   (codex:mcp-tool-approval-server-config-by-name
                     $tail
                     $server)))
              ((CodexMcpServerEntry $name $config)
               (if (== $name $server)
                   $config
                   (codex:mcp-tool-approval-server-config-by-name
                     $tail
                     $server)))
              ($other
               (codex:mcp-tool-approval-server-config-by-name
                 $tail
                 $server))))))))

(= (codex:mcp-tool-approval-tool-config-by-name $tools $tool-name)
   (if (== $tools ())
       Empty
       (let $head (list:first $tools)
         (let $tail (list:rest $tools)
           (case (eval $head)
             (((CodexMcpToolApprovalToolEntry $name $config)
               (if (== $name $tool-name)
                   $config
                   (codex:mcp-tool-approval-tool-config-by-name
                     $tail
                     $tool-name)))
              ((CodexMcpServerToolEntry $name $config)
               (if (== $name $tool-name)
                   $config
                   (codex:mcp-tool-approval-tool-config-by-name
                     $tail
                     $tool-name)))
              ($other
               (codex:mcp-tool-approval-tool-config-by-name
                 $tail
                 $tool-name))))))))

(= (codex:custom-mcp-tool-approval-mode-from-server-config
      $server-config
      $tool-name)
   (let $default-mode
     (codex:mcp-tool-approval-server-config-default-mode $server-config)
     (case
       (codex:mcp-tool-approval-tool-config-by-name
         (codex:mcp-tool-approval-server-config-tools $server-config)
         $tool-name)
       ((Empty
          (codex:mcp-tool-call-approval-mode-or-default $default-mode))
        ($tool-config
         (case (codex:mcp-tool-approval-tool-config-mode $tool-config)
           ((CodexAbsent
              (codex:mcp-tool-call-approval-mode-or-default $default-mode))
            ($tool-mode
             (codex:mcp-tool-call-approval-mode-or-default $tool-mode)))))))))

(= (codex:custom-mcp-tool-approval-mode $servers $server $tool-name)
   (case (codex:mcp-tool-approval-server-config-by-name $servers $server)
     ((Empty (codex:app-tool-approval-auto))
      ($server-config
       (codex:custom-mcp-tool-approval-mode-from-server-config
         $server-config
         $tool-name)))))

(= (codex:is-mcp-tool-approval-question-id $question-id)
   (let $prefix (codex:mcp-tool-approval-question-id-prefix)
     (if (str-starts-with? $question-id $prefix)
         (let $suffix
           (str-slice $question-id (str-length $prefix) (str-length $question-id))
           (str-starts-with? $suffix "_"))
         False)))

(= (codex:mcp-tool-approval-prompt-options-from-keys
      $session-approval-key
      $persistent-approval-key
      $tool-call-mcp-elicitation-enabled)
   (codex:mcp-tool-approval-prompt-options
     (codex:mcp-tool-call-present $session-approval-key)
     (and
       $tool-call-mcp-elicitation-enabled
       (codex:mcp-tool-call-present $persistent-approval-key))))

(= (codex:build-mcp-tool-approval-fallback-message
      $server
      $tool-name
      $connector-name)
   (let $actor
     (case (codex:mcp-tool-call-present-trimmed-string $connector-name)
       ((Empty
          (if (== $server (codex:codex-apps-mcp-server-name))
              "this app"
              (format-args "the {} MCP server" ($server))))
        ($name $name)))
     (format-args "Allow {} to run tool \"{}\"?" ($actor $tool-name))))

(= (codex:mcp-tool-approval-question-options
      (CodexMcpToolApprovalPromptOptions
        $allow-session-remember
        $allow-persistent-approval))
   (let $allow
     (codex:request-user-input-option
       (codex:mcp-tool-approval-accept)
       "Run the tool and continue.")
     (let $session
       (codex:request-user-input-option
         (codex:mcp-tool-approval-accept-for-session)
         "Run the tool and remember this choice for this session.")
       (let $remember
         (codex:request-user-input-option
           (codex:mcp-tool-approval-accept-and-remember)
           "Run the tool and remember this choice for future tool calls.")
         (let $cancel
           (codex:request-user-input-option
             (codex:mcp-tool-approval-cancel)
             "Cancel this tool call.")
           (if $allow-session-remember
               (if $allow-persistent-approval
                   ($allow $session $remember $cancel)
                   ($allow $session $cancel))
               (if $allow-persistent-approval
                   ($allow $remember $cancel)
                   ($allow $cancel))))))))

(= (codex:build-mcp-tool-approval-question
      $question-id
      $server
      $tool-name
      $connector-name
      $prompt-options
      $question-override)
   (let $base-question
     (if (== $question-override CodexAbsent)
         (codex:build-mcp-tool-approval-fallback-message
           $server
           $tool-name
           $connector-name)
         $question-override)
     (codex:request-user-input-question
       $question-id
       "Approve app tool call?"
       (str-concat
         (codex:mcp-tool-call-trim-end-question-marks $base-question)
         "?")
       False
       False
       (codex:mcp-tool-approval-question-options $prompt-options))))

(= (codex:mcp-tool-approval-question-text $question $monitor-reason)
   (case (codex:mcp-tool-call-present-trimmed-string $monitor-reason)
     ((Empty $question)
      ($reason
       (format-args
         "Tool call needs your approval. Reason: {}"
         ($reason))))))

(= (codex:arc-monitor-interrupt-message $reason)
   (let $trimmed (str-trim $reason)
     (if (== $trimmed "")
         "Tool call was cancelled because of safety risks."
         (format-args
           "Tool call was cancelled because of safety risks: {}"
           ($trimmed)))))

(= (codex:mcp-tool-approval-callsite-mode $approval-mode)
   (if (== $approval-mode (codex:app-tool-approval-approve))
       (codex:mcp-tool-call-arc-monitor-callsite-always-allow)
       (codex:mcp-tool-call-arc-monitor-callsite-default)))

(= (codex:session-mcp-tool-approval-key
      $invocation
      $metadata
      $approval-mode)
   (if (not (== $approval-mode (codex:app-tool-approval-auto)))
       Empty
       (let $server (codex:mcp-invocation-server $invocation)
         (let $connector-id
           (if (== $metadata CodexAbsent)
               CodexAbsent
               (codex:mcp-tool-approval-metadata-connector-id $metadata))
           (if (and
                 (== $server (codex:codex-apps-mcp-server-name))
                 (== $connector-id CodexAbsent))
               Empty
               (codex:mcp-tool-approval-key
                 $server
                 $connector-id
                 (codex:mcp-invocation-tool $invocation)))))))

(= (codex:persistent-mcp-tool-approval-key
      $invocation
      $metadata
      $approval-mode)
   (codex:session-mcp-tool-approval-key
     $invocation
     $metadata
     $approval-mode))

(= (codex:mcp-tool-call-json-pair-names ())
   ())

(= (codex:mcp-tool-call-json-pair-names $pairs)
   (let $head (list:first $pairs)
     (let $tail (list:rest $pairs)
       (case $head
         (((JsonPair $name $value)
           (list:append
             ($name)
             (codex:mcp-tool-call-json-pair-names $tail))))))))

(= (codex:mcp-tool-call-pair-value-by-name () $name)
   Empty)

(= (codex:mcp-tool-call-pair-value-by-name $pairs $name)
   (let $head (list:first $pairs)
     (let $tail (list:rest $pairs)
       (case $head
         (((JsonPair $pair-name $value)
           (if (== $pair-name $name)
               $value
               (codex:mcp-tool-call-pair-value-by-name $tail $name))))))))

(= (codex:mcp-tool-call-display-params-from-names $names $pairs)
   (if (== $names ())
       ()
       (let $name (list:first $names)
         (let $tail (list:rest $names)
           (case (codex:mcp-tool-call-pair-value-by-name $pairs $name)
             ((Empty
                (codex:mcp-tool-call-display-params-from-names $tail $pairs))
              ($value
               (list:append
                 ((codex:rendered-mcp-tool-approval-param
                    $name
                    $value
                    $name))
                 (codex:mcp-tool-call-display-params-from-names
                   $tail
                   $pairs)))))))))

(= (codex:build-mcp-tool-approval-display-params CodexAbsent)
   Empty)

(= (codex:build-mcp-tool-approval-display-params (JsonObject $pairs))
   (case (codex:mcp-tool-call-json-pair-names $pairs)
     (($names
       (case (sort-strings $names)
         (($sorted-names
           (codex:mcp-tool-call-display-params-from-names
             $sorted-names
             $pairs))))))))

(= (codex:build-mcp-tool-approval-display-params (JsonString $value))
   Empty)

(= (codex:build-mcp-tool-approval-display-params (JsonArray $items))
   Empty)

(= (codex:build-mcp-tool-approval-display-params (JsonNumber $value))
   Empty)

(= (codex:build-mcp-tool-approval-display-params (JsonBool $value))
   Empty)

(= (codex:build-mcp-tool-approval-display-params JsonNull)
   Empty)

(= (codex:mcp-tool-approval-display-param-json
      (CodexRenderedMcpToolApprovalParam $name $value $display-name))
   (JsonObject
     ((JsonPair "name" (JsonString $name))
      (JsonPair "value" $value)
      (JsonPair "display_name" (JsonString $display-name)))))

(= (codex:mcp-tool-approval-display-params-json $display-params)
   (if (== $display-params CodexAbsent)
       CodexAbsent
       (function
         (let $json-items
           (eval
             (map-atom
               $display-params
               $param
               (codex:mcp-tool-approval-display-param-json $param)))
           (return (JsonArray $json-items))))))

(= (codex:mcp-tool-call-pairs $pairs)
   $pairs)

(= (codex:mcp-tool-call-append-json-pair $pairs $key $value)
   (codex:protocol-append-json-pair $pairs $key $value))

(= (codex:mcp-tool-call-append-optional-json-string-pair $pairs $key $value)
   (if (not (codex:mcp-tool-call-present $value))
       (codex:mcp-tool-call-pairs $pairs)
       (codex:mcp-tool-call-append-json-pair
         $pairs
         $key
         (JsonString $value))))

(= (codex:mcp-tool-call-append-optional-json-value-pair $pairs $key $value)
   (if (not (codex:mcp-tool-call-present $value))
       (codex:mcp-tool-call-pairs $pairs)
       (codex:mcp-tool-call-append-json-pair $pairs $key $value)))

(= (codex:mcp-tool-call-append-optional-json-bool-pair $pairs $key $value)
   (if (not (codex:mcp-tool-call-present $value))
       (codex:mcp-tool-call-pairs $pairs)
       (codex:mcp-tool-call-append-json-pair
         $pairs
         $key
         (JsonBool $value))))

(= (codex:mcp-tool-call-set-json-pair $pairs $key $value)
   (if (== $pairs ())
       ((JsonPair $key $value))
       (let $head (list:first $pairs)
         (let $tail (list:rest $pairs)
           (case $head
             (((JsonPair $pair-key $pair-value)
               (if (== $pair-key $key)
                   (cons-atom (JsonPair $key $value) $tail)
                   (case
                     (codex:mcp-tool-call-set-json-pair
                       $tail
                       $key
                       $value)
                     (($updated-tail
                       (cons-atom $head $updated-tail))))))))))))

(= (codex:with-mcp-tool-call-thread-id-meta CodexAbsent $thread-id)
   (JsonObject
     ((JsonPair
        (codex:mcp-tool-thread-id-meta-key)
        (JsonString $thread-id)))))

(= (codex:with-mcp-tool-call-thread-id-meta Empty $thread-id)
   (codex:with-mcp-tool-call-thread-id-meta CodexAbsent $thread-id))

(= (codex:with-mcp-tool-call-thread-id-meta (JsonObject $pairs) $thread-id)
   (JsonObject
     (codex:mcp-tool-call-set-json-pair
       $pairs
       (codex:mcp-tool-thread-id-meta-key)
       (JsonString $thread-id))))

(= (codex:with-mcp-tool-call-thread-id-meta (JsonString $value) $thread-id)
   (JsonString $value))

(= (codex:with-mcp-tool-call-thread-id-meta (JsonArray $items) $thread-id)
   (JsonArray $items))

(= (codex:with-mcp-tool-call-thread-id-meta (JsonNumber $value) $thread-id)
   (JsonNumber $value))

(= (codex:with-mcp-tool-call-thread-id-meta (JsonBool $value) $thread-id)
   (JsonBool $value))

(= (codex:with-mcp-tool-call-thread-id-meta JsonNull $thread-id)
   JsonNull)

(= (codex:mcp-tool-call-sandbox-state-permission-profile-pairs
      $permission-profile-json)
   (case $permission-profile-json
     ((CodexAbsent ())
      (Empty ())
      ($json ((JsonPair "permissionProfile" $json))))))

(= (codex:mcp-tool-call-sandbox-state-optional-path-json $path)
   (case $path
     ((CodexAbsent JsonNull)
      (Empty JsonNull)
      ($value (JsonString $value)))))

(= (codex:mcp-tool-call-sandbox-state-json
      $permission-profile-json
      $sandbox-policy
      $codex-linux-sandbox-exe
      $sandbox-cwd
      $use-legacy-landlock)
   (let $pairs-1
     (codex:mcp-tool-call-sandbox-state-permission-profile-pairs
       $permission-profile-json)
     (let $pairs-2
       (codex:mcp-tool-call-append-json-pair
         $pairs-1
         "sandboxPolicy"
         (codex:session-sandbox-policy-json $sandbox-policy))
       (let $pairs-3
         (codex:mcp-tool-call-append-json-pair
           $pairs-2
           "codexLinuxSandboxExe"
           (codex:mcp-tool-call-sandbox-state-optional-path-json
             $codex-linux-sandbox-exe))
         (let $pairs-4
           (codex:mcp-tool-call-append-json-pair
             $pairs-3
             "sandboxCwd"
             (JsonString $sandbox-cwd))
           (let $pairs-5
             (codex:mcp-tool-call-append-json-pair
               $pairs-4
               "useLegacyLandlock"
               (JsonBool $use-legacy-landlock))
             (JsonObject $pairs-5)))))))

(= (codex:augment-mcp-tool-request-meta-with-sandbox-state-json
      CodexAbsent
      $sandbox-state)
   (JsonObject
     ((JsonPair
        (codex:mcp-sandbox-state-meta-capability-key)
        $sandbox-state))))

(= (codex:augment-mcp-tool-request-meta-with-sandbox-state-json
      Empty
      $sandbox-state)
   (codex:augment-mcp-tool-request-meta-with-sandbox-state-json
     CodexAbsent
     $sandbox-state))

(= (codex:augment-mcp-tool-request-meta-with-sandbox-state-json
      (JsonObject $pairs)
      $sandbox-state)
   (JsonObject
     (codex:mcp-tool-call-set-json-pair
       $pairs
       (codex:mcp-sandbox-state-meta-capability-key)
       $sandbox-state)))

(= (codex:augment-mcp-tool-request-meta-with-sandbox-state-json
      (JsonString $value)
      $sandbox-state)
   (JsonString $value))

(= (codex:augment-mcp-tool-request-meta-with-sandbox-state-json
      (JsonArray $items)
      $sandbox-state)
   (JsonArray $items))

(= (codex:augment-mcp-tool-request-meta-with-sandbox-state-json
      (JsonNumber $value)
      $sandbox-state)
   (JsonNumber $value))

(= (codex:augment-mcp-tool-request-meta-with-sandbox-state-json
      (JsonBool $value)
      $sandbox-state)
   (JsonBool $value))

(= (codex:augment-mcp-tool-request-meta-with-sandbox-state-json
      JsonNull
      $sandbox-state)
   JsonNull)

(= (codex:augment-mcp-tool-request-meta-with-sandbox-state
      $supports-sandbox-state-meta
      $meta
      $permission-profile-json
      $sandbox-policy
      $codex-linux-sandbox-exe
      $sandbox-cwd
      $use-legacy-landlock)
   (if (== $supports-sandbox-state-meta True)
       (let $pairs-1
         (codex:mcp-tool-call-sandbox-state-permission-profile-pairs
           $permission-profile-json)
         (let $pairs-2
           (codex:mcp-tool-call-append-json-pair
             $pairs-1
             "sandboxPolicy"
             (codex:session-sandbox-policy-json $sandbox-policy))
           (let $pairs-3
             (codex:mcp-tool-call-append-json-pair
               $pairs-2
               "codexLinuxSandboxExe"
               (codex:mcp-tool-call-sandbox-state-optional-path-json
                 $codex-linux-sandbox-exe))
             (let $pairs-4
               (codex:mcp-tool-call-append-json-pair
                 $pairs-3
                 "sandboxCwd"
                 (JsonString $sandbox-cwd))
               (let $pairs-5
                 (codex:mcp-tool-call-append-json-pair
                   $pairs-4
                   "useLegacyLandlock"
                   (JsonBool $use-legacy-landlock))
                 (codex:augment-mcp-tool-request-meta-with-sandbox-state-json
                   $meta
                   (JsonObject $pairs-5)))))))
       $meta))

(= (codex:mcp-app-usage-metadata-or-default CodexAbsent)
   (CodexMcpAppUsageMetadata CodexAbsent CodexAbsent))

(= (codex:mcp-app-usage-metadata-or-default Empty)
   (CodexMcpAppUsageMetadata CodexAbsent CodexAbsent))

(= (codex:mcp-app-usage-metadata-or-default
      (CodexMcpAppUsageMetadata $connector-id $app-name))
   (CodexMcpAppUsageMetadata $connector-id $app-name))

(= (codex:lookup-mcp-app-usage-metadata () $server $tool-name)
   Empty)

(= (codex:lookup-mcp-app-usage-metadata $tools $server $tool-name)
   (let $head (list:first $tools)
     (let $tail (list:rest $tools)
       (case (eval $head)
         (((CodexMcpToolInfo
             $server-name
             (CodexMcpTool
               $name
               $title
               $description
               $input-schema
               $output-schema
               $annotations
               $icons
               $meta)
             $connector-id
             $connector-name)
           (if (and
                 (== $server-name $server)
                 (== $name $tool-name))
               (codex:mcp-app-usage-metadata
                 $connector-id
                 $connector-name)
               (codex:lookup-mcp-app-usage-metadata
                 $tail
                 $server
                 $tool-name)))
          ($other
           (codex:lookup-mcp-app-usage-metadata
             $tail
             $server
             $tool-name)))))))

(= (codex:mcp-app-used-invocation-type $connector-id $selected-connector-ids)
   (case $connector-id
     ((CodexAbsent (codex:mcp-app-invocation-type-implicit))
      (Empty (codex:mcp-app-invocation-type-implicit))
      ($id
        (if (codex:mcp-tool-call-list-contains
              $selected-connector-ids
              $id)
            (codex:mcp-app-invocation-type-explicit)
            (codex:mcp-app-invocation-type-implicit))))))

(= (codex:maybe-track-codex-app-used-plan
      $server
      $metadata
      $selected-connector-ids
      $model-slug
      $thread-id
      $turn-id)
   (if (== $server (codex:codex-apps-mcp-server-name))
       (case (codex:mcp-app-usage-metadata-or-default $metadata)
         (((CodexMcpAppUsageMetadata $connector-id $app-name)
           (codex:mcp-app-used-tracking-plan
             (codex:mcp-track-events-context
               $model-slug
               $thread-id
               $turn-id)
             (codex:mcp-app-invocation
               $connector-id
               $app-name
               (codex:mcp-app-used-invocation-type
                 $connector-id
                 $selected-connector-ids))))))
       Empty))

(= (codex:maybe-track-codex-app-used-plan-from-tools
      $server
      $tool-name
      $tools
      $selected-connector-ids
      $model-slug
      $thread-id
      $turn-id)
   (if (== $server (codex:codex-apps-mcp-server-name))
       (case
         (codex:lookup-mcp-app-usage-metadata
           $tools
           $server
           $tool-name)
         ((Empty
            (codex:maybe-track-codex-app-used-plan
              $server
              CodexAbsent
              $selected-connector-ids
              $model-slug
              $thread-id
              $turn-id))
          ($metadata
           (codex:maybe-track-codex-app-used-plan
             $server
             $metadata
             $selected-connector-ids
             $model-slug
             $thread-id
             $turn-id))))
       Empty))

(= (codex:mcp-tool-call-request-meta-initial-pairs $turn-metadata)
   (if (== $turn-metadata CodexAbsent)
       ()
       ((JsonPair
          (codex:codex-turn-metadata-header-key)
          $turn-metadata))))

(= (codex:mcp-tool-call-request-meta-append-codex-apps-meta
      $pairs
      $server
      $metadata)
   (let $codex-apps-meta
     (codex:mcp-tool-approval-metadata-codex-apps-meta $metadata)
     (if (and
           (== $server (codex:codex-apps-mcp-server-name))
           (codex:mcp-tool-call-present $codex-apps-meta))
         (codex:mcp-tool-call-append-json-pair
           $pairs
           (codex:mcp-tool-codex-apps-meta-key)
           $codex-apps-meta)
         (codex:mcp-tool-call-pairs $pairs))))

(= (codex:mcp-tool-call-request-meta-from-pairs $pairs)
   (if (== $pairs ()) Empty (JsonObject $pairs)))

(= (codex:build-mcp-tool-call-request-meta-from-current-meta
      $current-meta
      $server
      $metadata)
   (let $pairs-turn
     (codex:mcp-tool-call-request-meta-initial-pairs $current-meta)
     (case
       (codex:mcp-tool-call-request-meta-append-codex-apps-meta
         $pairs-turn
         $server
         $metadata)
       (($pairs-final
         (codex:mcp-tool-call-request-meta-from-pairs $pairs-final))))))

(= (codex:build-mcp-tool-call-request-meta
      $turn-metadata-state
      $server
      $metadata)
   (codex:build-mcp-tool-call-request-meta-from-current-meta
     (codex:turn-metadata-state-current-meta-value $turn-metadata-state)
     $server
     $metadata))

(= (codex:mcp-tool-call-append-persist
      $pairs
      (CodexMcpToolApprovalPromptOptions
        $allow-session-remember
        $allow-persistent-approval))
   (if $allow-session-remember
       (if $allow-persistent-approval
           (codex:mcp-tool-call-append-json-pair
             $pairs
             (codex:mcp-tool-approval-persist-key)
             (JsonArray
               ((JsonString (codex:mcp-tool-approval-persist-session))
                (JsonString (codex:mcp-tool-approval-persist-always)))))
           (codex:mcp-tool-call-append-json-pair
             $pairs
             (codex:mcp-tool-approval-persist-key)
             (JsonString (codex:mcp-tool-approval-persist-session))))
       (if $allow-persistent-approval
           (codex:mcp-tool-call-append-json-pair
             $pairs
             (codex:mcp-tool-approval-persist-key)
             (JsonString (codex:mcp-tool-approval-persist-always)))
           (codex:mcp-tool-call-pairs $pairs))))

(= (codex:mcp-tool-call-metadata-has-connector-fields
      (CodexMcpToolApprovalMetadata
        $connector-id
        $connector-name
        $connector-description
        $tool-title
        $tool-description))
   (or
     (codex:mcp-tool-call-present $connector-id)
     (or
       (codex:mcp-tool-call-present $connector-name)
       (codex:mcp-tool-call-present $connector-description))))

(= (codex:mcp-tool-call-append-metadata $pairs $server $metadata)
   (case (eval $metadata)
     ((CodexAbsent (codex:mcp-tool-call-pairs $pairs))
      ((CodexMcpToolApprovalMetadata
         $connector-id
         $connector-name
         $connector-description
         $tool-title
         $tool-description)
       (codex:mcp-tool-call-append-metadata-fields
         $pairs
         $server
         $connector-id
         $connector-name
         $connector-description
         $tool-title
         $tool-description)))))

(= (codex:mcp-tool-call-append-connector-metadata
      $pairs
      $connector-id
      $connector-name
      $connector-description)
   (case
     (codex:mcp-tool-call-append-json-pair
       $pairs
       (codex:mcp-tool-approval-source-key)
       (JsonString (codex:mcp-tool-approval-source-connector)))
     (($pairs-source
       (case
         (codex:mcp-tool-call-append-optional-json-string-pair
           $pairs-source
           (codex:mcp-tool-approval-connector-id-key)
           $connector-id)
         (($pairs-connector-id
           (case
             (codex:mcp-tool-call-append-optional-json-string-pair
               $pairs-connector-id
               (codex:mcp-tool-approval-connector-name-key)
               $connector-name)
             (($pairs-connector-name
               (codex:mcp-tool-call-append-optional-json-string-pair
                 $pairs-connector-name
                 (codex:mcp-tool-approval-connector-description-key)
                 $connector-description)))))))))))

(= (codex:mcp-tool-call-append-metadata-fields
      $pairs
      $server
      $connector-id
      $connector-name
      $connector-description
      $tool-title
      $tool-description)
   (case
     (codex:mcp-tool-call-append-optional-json-string-pair
       $pairs
       (codex:mcp-tool-approval-tool-title-key)
       $tool-title)
     (($pairs-title
       (case
         (codex:mcp-tool-call-append-optional-json-string-pair
           $pairs-title
           (codex:mcp-tool-approval-tool-description-key)
           $tool-description)
         (($pairs-description
           (case
             (and
               (== $server (codex:codex-apps-mcp-server-name))
               (codex:mcp-tool-call-metadata-has-connector-fields
                 (CodexMcpToolApprovalMetadata
                   $connector-id
                   $connector-name
                   $connector-description
                   $tool-title
                   $tool-description)))
             ((True
                (codex:mcp-tool-call-append-connector-metadata
                  $pairs-description
                  $connector-id
                  $connector-name
                  $connector-description))
              (False $pairs-description))))))))))

(= (codex:build-mcp-tool-approval-elicitation-meta
      $server
      $metadata
      $tool-params
      $tool-params-display
      $prompt-options)
   (let $pairs-kind
     ((JsonPair
        (codex:mcp-tool-approval-kind-key)
        (JsonString (codex:mcp-tool-approval-kind-mcp-tool-call))))
     (case
       (codex:mcp-tool-call-append-persist $pairs-kind $prompt-options)
       (($pairs-persist
         (case
           (codex:mcp-tool-call-append-metadata
             $pairs-persist
             $server
             $metadata)
           (($pairs-metadata
             (case
               (codex:mcp-tool-call-append-optional-json-value-pair
                 $pairs-metadata
                 (codex:mcp-tool-approval-tool-params-key)
                 $tool-params)
               (($pairs-params
                 (case
                   (codex:mcp-tool-approval-display-params-json
                     $tool-params-display)
                   (($display-json
                     (case
                       (codex:mcp-tool-call-append-optional-json-value-pair
                         $pairs-params
                         (codex:mcp-tool-approval-tool-params-display-key)
                         $display-json)
                       (($pairs-display
                         (JsonObject $pairs-display))))))))))))))))))

(= (codex:guardian-approval-request-mcp-tool-call
      $id
      $server
      $tool-name
      $arguments
      $connector-id
      $connector-name
      $connector-description
      $tool-title
      $tool-description
      $annotations)
   (CodexGuardianApprovalRequestMcpToolCall
     $id
     $server
     $tool-name
     $arguments
     $connector-id
     $connector-name
     $connector-description
     $tool-title
     $tool-description
     $annotations))

(= (codex:guardian-mcp-annotations-json
      (CodexMcpToolAnnotations
        $read-only-hint
        $destructive-hint
        $open-world-hint))
   (let $pairs-destructive
     (codex:mcp-tool-call-append-optional-json-bool-pair
       ()
       "destructive_hint"
       $destructive-hint)
     (let $pairs-open-world
       (codex:mcp-tool-call-append-optional-json-bool-pair
         $pairs-destructive
         "open_world_hint"
         $open-world-hint)
       (JsonObject
         (codex:mcp-tool-call-append-optional-json-bool-pair
           $pairs-open-world
           "read_only_hint"
           $read-only-hint)))))

(= (codex:mcp-tool-call-annotations-json-value CodexAbsent)
   CodexAbsent)

(= (codex:mcp-tool-call-annotations-json-value Empty)
   CodexAbsent)

(= (codex:mcp-tool-call-annotations-json-value
      (CodexMcpToolAnnotations
        $read-only-hint
        $destructive-hint
        $open-world-hint))
   (codex:guardian-mcp-annotations-json
     (CodexMcpToolAnnotations
       $read-only-hint
       $destructive-hint
       $open-world-hint)))

(= (codex:guardian-approval-request-mcp-tool-call-json $request)
   (case (eval $request)
     (((CodexGuardianApprovalRequestMcpToolCall
         $id
         $server
         $tool-name
         $arguments
         $connector-id
         $connector-name
         $connector-description
         $tool-title
         $tool-description
         $annotations)
       (let $pairs-base
         ((JsonPair "tool" (JsonString "mcp_tool_call"))
          (JsonPair "server" (JsonString $server))
          (JsonPair "tool_name" (JsonString $tool-name)))
         (let $pairs-arguments
           (codex:mcp-tool-call-append-optional-json-value-pair
             $pairs-base
             "arguments"
             $arguments)
           (let $pairs-connector-id
             (codex:mcp-tool-call-append-optional-json-string-pair
               $pairs-arguments
               "connector_id"
               $connector-id)
             (let $pairs-connector-name
               (codex:mcp-tool-call-append-optional-json-string-pair
                 $pairs-connector-id
                 "connector_name"
                 $connector-name)
               (let $pairs-connector-description
                 (codex:mcp-tool-call-append-optional-json-string-pair
                   $pairs-connector-name
                   "connector_description"
                   $connector-description)
                 (let $pairs-tool-title
                   (codex:mcp-tool-call-append-optional-json-string-pair
                     $pairs-connector-description
                     "tool_title"
                     $tool-title)
                   (let $pairs-tool-description
                     (codex:mcp-tool-call-append-optional-json-string-pair
                       $pairs-tool-title
                       "tool_description"
                       $tool-description)
                     (JsonObject
                       (codex:mcp-tool-call-append-optional-json-value-pair
                         $pairs-tool-description
                         "annotations"
                         (codex:mcp-tool-call-annotations-json-value
                           $annotations))))))))))))))

(= (codex:build-guardian-mcp-tool-review-request
      $call-id
      $invocation
      $metadata)
   (case (eval $invocation)
     (((CodexMcpInvocation $server $tool-name $arguments)
       (codex:guardian-approval-request-mcp-tool-call
         $call-id
         $server
         $tool-name
         $arguments
         (codex:mcp-tool-approval-metadata-connector-id $metadata)
         (codex:mcp-tool-approval-metadata-connector-name $metadata)
         (codex:mcp-tool-approval-metadata-connector-description $metadata)
         (codex:mcp-tool-approval-metadata-tool-title $metadata)
         (codex:mcp-tool-approval-metadata-tool-description $metadata)
         (codex:mcp-tool-approval-metadata-annotations $metadata))))))

(= (codex:prepare-arc-request-action $invocation $metadata)
   (codex:guardian-approval-request-mcp-tool-call-json
     (codex:build-guardian-mcp-tool-review-request
       "arc-monitor"
       $invocation
       $metadata)))

(= (codex:mcp-tool-call-response-answer-values () $question-id)
   Empty)

(= (codex:mcp-tool-call-answer-values $answers)
   $answers)

(= (codex:mcp-tool-call-response-answer-values $entries $question-id)
   (let $entry (list:first $entries)
     (let $tail (list:rest $entries)
       (if (== (codex:request-user-input-response-entry-id $entry) $question-id)
           (codex:mcp-tool-call-answer-values
             (codex:request-user-input-answer-values
               (codex:request-user-input-response-entry-answer $entry)))
           (codex:mcp-tool-call-response-answer-values
             $tail
             $question-id)))))

(= (codex:mcp-tool-call-decision-from-answer-values $answers)
   (if (codex:mcp-tool-call-list-contains
         $answers
         (codex:mcp-tool-approval-decline-synthetic))
       (codex:mcp-tool-approval-decision-decline CodexAbsent)
       (if (codex:mcp-tool-call-list-contains
             $answers
             (codex:mcp-tool-approval-accept-for-session))
           (codex:mcp-tool-approval-decision-accept-for-session)
           (if (codex:mcp-tool-call-list-contains
                 $answers
                 (codex:mcp-tool-approval-accept-and-remember))
               (codex:mcp-tool-approval-decision-accept-and-remember)
               (if (codex:mcp-tool-call-list-contains
                     $answers
                     (codex:mcp-tool-approval-accept))
                   (codex:mcp-tool-approval-decision-accept)
                   (codex:mcp-tool-approval-decision-cancel))))))

(= (codex:parse-mcp-tool-approval-response CodexAbsent $question-id)
   (codex:mcp-tool-approval-decision-cancel))

(= (codex:parse-mcp-tool-approval-response Empty $question-id)
   (codex:mcp-tool-approval-decision-cancel))

(= (codex:parse-mcp-tool-approval-response
      (CodexRequestUserInputResponse $entries)
      $question-id)
   (case (codex:mcp-tool-call-response-answer-values $entries $question-id)
     ((Empty (codex:mcp-tool-approval-decision-cancel))
      ($answers
       (codex:mcp-tool-call-decision-from-answer-values $answers)))))

(= (codex:mcp-tool-call-json-array-string-values ())
   ())

(= (codex:mcp-tool-call-json-array-string-values $items)
   (let $head (list:first $items)
     (let $tail (list:rest $items)
       (case $head
         (((JsonString $value)
           (list:append
             ($value)
             (codex:mcp-tool-call-json-array-string-values $tail)))
          ($other
           (codex:mcp-tool-call-json-array-string-values $tail)))))))

(= (codex:request-user-input-response-from-elicitation-content CodexAbsent)
   (codex:request-user-input-response ()))

(= (codex:request-user-input-response-from-elicitation-content (JsonObject $pairs))
   (codex:request-user-input-response
     (codex:mcp-tool-call-response-entries-from-elicitation-pairs $pairs)))

(= (codex:request-user-input-response-from-elicitation-content (JsonString $value))
   Empty)

(= (codex:request-user-input-response-from-elicitation-content (JsonArray $items))
   Empty)

(= (codex:request-user-input-response-from-elicitation-content (JsonNumber $value))
   Empty)

(= (codex:request-user-input-response-from-elicitation-content (JsonBool $value))
   Empty)

(= (codex:request-user-input-response-from-elicitation-content JsonNull)
   Empty)

(= (codex:mcp-tool-call-response-entries-from-elicitation-pairs ())
   ())

(= (codex:mcp-tool-call-response-entries-from-elicitation-pairs $pairs)
   (let $head (list:first $pairs)
     (let $tail (list:rest $pairs)
       (case $head
         (((JsonPair $question-id (JsonString $answer))
           (list:append
             ((codex:request-user-input-response-entry
                $question-id
                (codex:request-user-input-answer ($answer))))
             (codex:mcp-tool-call-response-entries-from-elicitation-pairs
               $tail)))
          ((JsonPair $question-id (JsonArray $answers))
           (case
             (codex:mcp-tool-call-json-array-string-values $answers)
             (($answer-values
               (list:append
                 ((codex:request-user-input-response-entry
                    $question-id
                    (codex:request-user-input-answer $answer-values)))
                 (codex:mcp-tool-call-response-entries-from-elicitation-pairs
                   $tail))))))
          ($other
           (codex:mcp-tool-call-response-entries-from-elicitation-pairs
             $tail)))))))

(= (codex:mcp-tool-call-meta-persist-value CodexAbsent)
   CodexAbsent)

(= (codex:mcp-tool-call-meta-persist-value Empty)
   CodexAbsent)

(= (codex:mcp-tool-call-meta-persist-value (JsonObject $pairs))
   (case (json-object-get (JsonObject $pairs) (codex:mcp-tool-approval-persist-key))
     ((Empty CodexAbsent)
      ((JsonString $value) $value)
      ($other CodexAbsent))))

(= (codex:mcp-tool-call-meta-persist-value (JsonString $value))
   CodexAbsent)

(= (codex:mcp-tool-call-meta-persist-value (JsonArray $items))
   CodexAbsent)

(= (codex:mcp-tool-call-meta-persist-value (JsonNumber $value))
   CodexAbsent)

(= (codex:mcp-tool-call-meta-persist-value (JsonBool $value))
   CodexAbsent)

(= (codex:mcp-tool-call-meta-persist-value JsonNull)
   CodexAbsent)

(= (codex:parse-mcp-tool-approval-elicitation-response CodexAbsent $question-id)
   (codex:mcp-tool-approval-decision-cancel))

(= (codex:parse-mcp-tool-approval-elicitation-response Empty $question-id)
   (codex:mcp-tool-approval-decision-cancel))

(= (codex:parse-mcp-tool-approval-elicitation-response
      (CodexMcpToolApprovalElicitationResponse
        (CodexElicitationActionDecline)
        $content
        $meta)
      $question-id)
   (codex:mcp-tool-approval-decision-decline CodexAbsent))

(= (codex:parse-mcp-tool-approval-elicitation-response
      (CodexMcpToolApprovalElicitationResponse
        (CodexElicitationActionCancel)
        $content
        $meta)
      $question-id)
   (codex:mcp-tool-approval-decision-cancel))

(= (codex:parse-mcp-tool-approval-elicitation-response
      (CodexMcpToolApprovalElicitationResponse
        (CodexElicitationActionAccept)
        $content
        $meta)
      $question-id)
   (let $persist (codex:mcp-tool-call-meta-persist-value $meta)
     (if (== $persist (codex:mcp-tool-approval-persist-session))
         (codex:mcp-tool-approval-decision-accept-for-session)
         (if (== $persist (codex:mcp-tool-approval-persist-always))
             (codex:mcp-tool-approval-decision-accept-and-remember)
             (case
               (codex:request-user-input-response-from-elicitation-content $content)
               ((Empty (codex:mcp-tool-approval-decision-accept))
                ($response
                 (let $decision
                   (codex:parse-mcp-tool-approval-response
                     $response
                     $question-id)
                   (if (== $decision
                           (codex:mcp-tool-approval-decision-cancel))
                       (codex:mcp-tool-approval-decision-accept)
                       $decision)))))))))

(= (codex:mcp-tool-approval-decision-from-guardian
      (CodexReviewDecisionApproved)
      $guardian-rejection-message
      $guardian-timeout-message)
   (codex:mcp-tool-approval-decision-accept))

(= (codex:mcp-tool-approval-decision-from-guardian
      (CodexReviewDecisionApprovedExecpolicyAmendment $amendment)
      $guardian-rejection-message
      $guardian-timeout-message)
   (codex:mcp-tool-approval-decision-accept))

(= (codex:mcp-tool-approval-decision-from-guardian
      (CodexReviewDecisionNetworkPolicyAmendment $amendment)
      $guardian-rejection-message
      $guardian-timeout-message)
   (codex:mcp-tool-approval-decision-accept))

(= (codex:mcp-tool-approval-decision-from-guardian
      (CodexReviewDecisionApprovedForSession)
      $guardian-rejection-message
      $guardian-timeout-message)
   (codex:mcp-tool-approval-decision-accept-for-session))

(= (codex:mcp-tool-approval-decision-from-guardian
      (CodexReviewDecisionDenied)
      $guardian-rejection-message
      $guardian-timeout-message)
   (codex:mcp-tool-approval-decision-decline $guardian-rejection-message))

(= (codex:mcp-tool-approval-decision-from-guardian
      (CodexReviewDecisionTimedOut)
      $guardian-rejection-message
      $guardian-timeout-message)
   (codex:mcp-tool-approval-decision-decline $guardian-timeout-message))

(= (codex:mcp-tool-approval-decision-from-guardian
      (CodexReviewDecisionAbort)
      $guardian-rejection-message
      $guardian-timeout-message)
   (codex:mcp-tool-approval-decision-decline CodexAbsent))

(= (codex:normalize-mcp-tool-approval-decision-for-mode
      $decision
      $approval-mode)
   (if (and
         (== $approval-mode (codex:app-tool-approval-prompt))
         (or
           (== $decision
               (codex:mcp-tool-approval-decision-accept-for-session))
           (== $decision
               (codex:mcp-tool-approval-decision-accept-and-remember))))
       (codex:mcp-tool-approval-decision-accept)
       $decision))

(= (codex:requires-mcp-tool-approval CodexAbsent)
   True)

(= (codex:requires-mcp-tool-approval
      (CodexMcpToolAnnotations
        $read-only-hint
        $destructive-hint
        $open-world-hint))
   (if (== $destructive-hint True)
       True
       (let $read-only
         (codex:mcp-tool-call-bool-or-default $read-only-hint False)
         (if $read-only
             False
             (or
               (codex:mcp-tool-call-bool-or-default
                 $destructive-hint
                 True)
               (codex:mcp-tool-call-bool-or-default
                 $open-world-hint
                 True))))))
