; Minimal Rust-faithful Codex protocol slice.
;
; This ports the JSON wire shape for the narrow ResponseItem subset below from
; openai-codex/codex-rs/protocol/src/models.rs:
; - Message
; - CustomToolCall
; - CustomToolCallOutput
;
; This first increment intentionally covers only the plain-text branches of
; ContentItem and FunctionCallOutputPayload. The array content-item branch will
; land in a later slice.
;
; CeTTa detail: `Empty` is a reduction sentinel, so omitted optional protocol
; fields use the internal tag `CodexAbsent` until projected back out.

!(import! &self json)

(= (codex:user-message $text)
   (CodexResponseItemMessage "user" ((CodexInputText $text)) CodexAbsent))

(= (codex:assistant-message $text)
   (CodexResponseItemMessage "assistant" ((CodexOutputText $text)) CodexAbsent))

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

(= (codex:item-type (CodexResponseItemMessage $role $content $phase))
   "message")

(= (codex:item-type (CodexResponseItemCustomToolCall $call_id $name $input))
   "custom_tool_call")

(= (codex:item-type
      (CodexResponseItemCustomToolCallOutput $call_id $name $output))
   "custom_tool_call_output")

(= (codex:message-role (CodexResponseItemMessage $role $content $phase))
   $role)

(= (codex:message-phase (CodexResponseItemMessage $role $content $phase))
   (if (== $phase CodexAbsent) Empty $phase))

(= (codex:tool-call-name (CodexResponseItemCustomToolCall $call_id $name $input))
   $name)

(= (codex:tool-result-output-text
      (CodexResponseItemCustomToolCallOutput
        $call_id
        $name
        (CodexFunctionCallOutputText $text)))
   $text)

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

(= (codex:items-json $items)
   (function
     (let $json-items (eval (map-atom $items $item (codex:item-json $item)))
       (return (JsonArray $json-items)))))
