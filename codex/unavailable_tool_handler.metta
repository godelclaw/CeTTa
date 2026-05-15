; Narrow Rust-faithful unavailable-tool handler slice.
;
; This ports:
; - openai-codex/codex-rs/core/src/tools/handlers/unavailable_tool.rs
;
; Covered in this increment:
; - unavailable_tool_message
; - UnavailableToolHandler kind
; - function-payload success path
; - unsupported-payload RespondToModel error
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust lowers an async `ToolHandler` over `ToolInvocation`. The current CeTTa
;   port preserves the same visible logic through a pure helper over the
;   already-ported `ToolName` and `ToolPayload` shapes, with explicit `Ok`/`Err`
;   result constructors instead of Rust `Result`.

!(import! &self context)
!(import! &self function_tool)
!(import! &self str)
!(import! &self tool_name)

(= (codex:unavailable-tool-handler-kind)
   "function")

(= (codex:default-unavailable-tool-next-step)
   "Retry after the tool becomes available or ask the user to re-enable it.")

(= (codex:unavailable-tool-message-from-display $tool-name-display $next-step)
   (str-concat
     "Tool `"
     (str-concat
       $tool-name-display
       (str-concat
         "` is not currently available. It appeared in earlier tool calls in this conversation, but its implementation is not available in the current request. "
         $next-step))))

(= (codex:unavailable-tool-message $tool-name $next-step)
   (codex:unavailable-tool-message-from-display
     (codex:tool-name-display $tool-name)
     $next-step))

(= (codex:unavailable-tool-handler-ok $output)
   (CodexUnavailableToolHandlerOk $output))

(= (codex:unavailable-tool-handler-err $error)
   (CodexUnavailableToolHandlerErr $error))

(= (codex:run-unavailable-tool-handler $tool-name $payload)
   (case $payload
     (((CodexToolPayloadFunction $arguments)
       (codex:unavailable-tool-handler-ok
         (codex:function-tool-output-from-text
           (codex:unavailable-tool-message
             $tool-name
             (codex:default-unavailable-tool-next-step))
           False)))
      ($other
       (codex:unavailable-tool-handler-err
         (codex:function-call-error-respond-to-model
           "unavailable tool handler received unsupported payload"))))))
