; Minimal Rust-faithful Codex protocol slice.
;
; This ports the JSON wire shape for the narrow ResponseItem subset below from
; openai-codex/codex-rs/protocol/src/models.rs and
; openai-codex/codex-rs/protocol/src/protocol.rs:
; - Message
; - CustomToolCall
; - CustomToolCallOutput
; - ExecCommandOutputDeltaEvent
; - TerminalInteractionEvent
;
; This first increment intentionally covers only the plain-text branches of
; ContentItem and FunctionCallOutputPayload. The array content-item branch will
; land in a later slice.
;
; CeTTa detail: `Empty` is a reduction sentinel, so omitted optional protocol
; fields use the internal tag `CodexAbsent` until projected back out.
;
; The unified-exec delta event stores raw bytes in Rust and serializes them as
; base64. The current CeTTa surface therefore models the event payload as text
; whose current byte sequence is base64-encoded at JSON projection time.

!(import! &self json)
!(import! &self str)

(= (codex:user-message $text)
   (CodexResponseItemMessage "user" ((CodexInputText $text)) CodexAbsent))

(= (codex:assistant-message $text)
   (CodexResponseItemMessage "assistant" ((CodexOutputText $text)) CodexAbsent))

(= (codex:commentary-message $text)
   (CodexResponseItemMessage "assistant" ((CodexOutputText $text)) "commentary"))

(= (codex:final-response $text)
   (CodexResponseItemMessage "assistant" ((CodexOutputText $text)) "final_answer"))

(= (codex:tool-call $call_id $name $input)
   (CodexResponseItemCustomToolCall $call_id $name $input))

(= (codex:tool-result $call_id $output)
   (CodexResponseItemCustomToolCallOutput
     $call_id
     CodexAbsent
     (CodexFunctionCallOutputText $output)))

(= (codex:named-tool-result $call_id $name $output)
   (CodexResponseItemCustomToolCallOutput
     $call_id
     $name
     (CodexFunctionCallOutputText $output)))

(= (codex:exec-command-output-delta-event $call_id $stream $chunk)
   (CodexEventExecCommandOutputDelta $call_id $stream $chunk))

(= (codex:terminal-interaction-event $call_id $process_id $stdin)
   (CodexEventTerminalInteraction $call_id $process_id $stdin))

(= (codex:item-type (CodexResponseItemMessage $role $content $phase))
   "message")

(= (codex:item-type (CodexResponseItemCustomToolCall $call_id $name $input))
   "custom_tool_call")

(= (codex:item-type
      (CodexResponseItemCustomToolCallOutput $call_id $name $output))
   "custom_tool_call_output")

(= (codex:item-type
      (CodexEventExecCommandOutputDelta $call_id $stream $chunk))
   "exec_command_output_delta")

(= (codex:item-type
      (CodexEventTerminalInteraction $call_id $process_id $stdin))
   "terminal_interaction")

(= (codex:message-role (CodexResponseItemMessage $role $content $phase))
   $role)

(= (codex:message-phase (CodexResponseItemMessage $role $content $phase))
   (if (== $phase CodexAbsent) Empty $phase))

(= (codex:tool-call-name (CodexResponseItemCustomToolCall $call_id $name $input))
   $name)

(= (codex:message-text
      (CodexResponseItemMessage $role ((CodexInputText $text)) $phase))
   $text)

(= (codex:message-text
      (CodexResponseItemMessage $role ((CodexOutputText $text)) $phase))
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
