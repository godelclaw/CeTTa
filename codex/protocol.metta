; Minimal Rust-faithful Codex protocol slice.
;
; This ports the JSON wire shape for the narrow ResponseItem subset below from
; openai-codex/codex-rs/protocol/src/models.rs and
; openai-codex/codex-rs/protocol/src/protocol.rs:
; - Message
; - Reasoning
; - FunctionCallOutput
; - McpToolCallOutput
; - CustomToolCall
; - CustomToolCallOutput
; - ToolSearchOutput
; - WebSearchCall
; - ImageGenerationCall
; - ExecCommandOutputDeltaEvent
; - TerminalInteractionEvent
;
; This increment covers the plain-text and structured content-item branches of
; FunctionCallOutputPayload at the JSON wire layer. The content-item subset
; follows Rust here: `input_text` and `input_image` are supported for
; function/custom tool outputs.
;
; CeTTa detail: `Empty` is a reduction sentinel, so omitted optional protocol
; fields use the internal tag `CodexAbsent` until projected back out.
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

(= (codex:items-json $items)
   (function
     (let $json-items (eval (map-atom $items $item (codex:item-json $item)))
       (return (JsonArray $json-items)))))
