; Minimal Rust-faithful Codex context helpers.
;
; This ports the pure response/log/code-mode slice from
; openai-codex/codex-rs/core/src/tools/context.rs:
; - ToolPayload log projection
; - FunctionToolOutput / ApplyPatchToolOutput / AbortedToolOutput
; - ToolSearchOutput / CallToolResult / McpToolOutput
; - ExecCommandToolOutput
; - response_input_to_code_mode_result
; - telemetry_preview
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust stores exec output as raw bytes. The current CeTTa surface represents
;   `raw_output` as text, so embedded NUL bytes are still not preserved through
;   this context layer.
; - Rust models MCP tool results with a typed struct. The current CeTTa slice
;   carries the same wire payload as JSON atoms so the pure context helpers can
;   stay self-contained without introducing a second JSON object model.

!(import! &self json)
!(import! &self image_detail)
!(import! &self list)
!(import! &self protocol)
!(import! &self str)
!(import! &self str_middle)
!(import! &self codex:output_truncation)
!(import! &self codex:string_truncate)

(= (codex:telemetry-preview-max-bytes)
   2048)

(= (codex:telemetry-preview-max-lines)
   64)

(= (codex:telemetry-preview-truncation-notice)
   "[... telemetry preview truncated ...]")

(= (codex:default-image-detail)
   "high")

(= (codex:default-max-output-tokens)
   10000)

(= (codex:mcp-image-detail-meta-key)
   "codex/imageDetail")

(= (codex:function-payload $arguments)
   (CodexToolPayloadFunction $arguments))

(= (codex:tool-search-payload $query)
   (CodexToolPayloadToolSearch $query CodexAbsent))

(= (codex:tool-search-payload $query $limit)
   (CodexToolPayloadToolSearch $query $limit))

(= (codex:custom-payload $input)
   (CodexToolPayloadCustom $input))

(= (codex:local-shell-payload $command)
   (CodexToolPayloadLocalShell $command))

(= (codex:mcp-payload $server $tool $raw-arguments)
   (CodexToolPayloadMcp $server $tool $raw-arguments))

(= (codex:tool-payload-log-payload (CodexToolPayloadFunction $arguments))
   $arguments)

(= (codex:tool-payload-log-payload
      (CodexToolPayloadToolSearch $query $limit))
   $query)

(= (codex:tool-payload-log-payload (CodexToolPayloadCustom $input))
   $input)

(= (codex:tool-payload-log-payload (CodexToolPayloadLocalShell $command))
   (str-join " " $command))

(= (codex:tool-payload-log-payload
      (CodexToolPayloadMcp $server $tool $raw-arguments))
   $raw-arguments)

(= (codex:function-tool-output $body $success $post-tool-use-response)
   (CodexToolOutputFunction $body $success $post-tool-use-response))

(= (codex:function-tool-output-from-text $text $success)
   (CodexToolOutputFunction
     ((CodexInputText $text))
     $success
     CodexAbsent))

(= (codex:function-tool-output-from-content $body $success)
   (CodexToolOutputFunction
     $body
     $success
     CodexAbsent))

(= (codex:apply-patch-tool-output-from-text $text)
   (CodexToolOutputApplyPatch $text))

(= (codex:aborted-tool-output $message)
   (CodexToolOutputAborted $message))

(= (codex:tool-search-tool-output $tools)
   (CodexToolOutputToolSearch $tools))

(= (codex:mcp-call-tool-result-output $result)
   (CodexToolOutputMcpCallToolResult $result))

(= (codex:mcp-tool-output
      $result
      $tool-input
      $wall-time-ms
      $original-image-detail-supported)
   (CodexToolOutputMcp
     $result
     $tool-input
     $wall-time-ms
     $original-image-detail-supported))

(= (codex:exec-command-tool-output
      $event-call-id
      $chunk-id
      $wall-time-ms
      $raw-output
      $max-output-tokens
      $process-id
      $exit-code
      $original-token-count
      $hook-command)
   (CodexToolOutputExecCommand
     $event-call-id
     $chunk-id
     $wall-time-ms
     $raw-output
     $max-output-tokens
     $process-id
     $exit-code
     $original-token-count
     $hook-command))

(= (codex:json-object-optional-value $object $key)
   (case (json-object-get $object $key)
     ((Empty CodexAbsent)
      (JsonNull CodexAbsent)
      ($value $value))))

(= (codex:json-object-optional-string $object $key)
   (case (codex:json-object-optional-value $object $key)
     ((CodexAbsent CodexAbsent)
      ((JsonString $text) $text))))

(= (codex:json-object-optional-bool $object $key)
   (case (codex:json-object-optional-value $object $key)
     ((CodexAbsent CodexAbsent)
      ((JsonBool $value) $value))))

(= (codex:json-object-optional-object $object $key)
   (case (codex:json-object-optional-value $object $key)
     ((CodexAbsent CodexAbsent)
      ((JsonObject $pairs) (JsonObject $pairs)))))

(= (codex:json-object-optional-array $object $key)
   (case (codex:json-object-optional-value $object $key)
     ((CodexAbsent CodexAbsent)
      ((JsonArray $items) $items))))

(= (codex:append-items () $rhs)
   $rhs)

(= (codex:append-items $lhs $rhs)
   (let ($head $tail) (decons-atom $lhs)
     (case (codex:append-items $tail $rhs)
       (($rest
          (cons-atom $head $rest))))))

(= (codex:append-item $items $item)
   (codex:append-items $items ($item)))

(= (codex:is-blank-text $text)
   (== (str-trim $text) ""))

(= (codex:function-call-output-content-items-to-text ())
   Empty)

(= (codex:function-call-output-content-items-to-text $items)
   (let $segments (codex:function-call-output-text-segments $items)
     (if (== $segments ())
         Empty
         (str-join "\n" $segments))))

(= (codex:function-call-output-text-segments ())
   ())

(= (codex:function-call-output-text-segments $items)
   (let ($head $tail) (decons-atom $items)
     (case $head
       (((CodexInputText $text)
        (if (codex:is-blank-text $text)
            (codex:function-call-output-text-segments $tail)
            (case (codex:function-call-output-text-segments $tail)
              (($tail-segments
                (cons-atom $text $tail-segments))))))
       ((CodexInputImage $image-url $detail)
        (codex:function-call-output-text-segments $tail))))))

(= (codex:function-call-output-to-text (CodexFunctionCallOutputText $text))
   $text)

(= (codex:function-call-output-to-text (CodexFunctionCallOutputContentItems $items))
   (codex:function-call-output-content-items-to-text $items))

(= (codex:function-tool-output-into-text
      (CodexToolOutputFunction $body $success $post-tool-use-response))
   (case (codex:function-call-output-content-items-to-text $body)
     ((Empty "")
      ($text $text))))

(= (codex:content-item-code-mode-segment (CodexInputText $text))
   (if (codex:is-blank-text $text)
       CodexAbsent
       $text))

(= (codex:content-item-code-mode-segment (CodexOutputText $text))
   (if (codex:is-blank-text $text)
       CodexAbsent
       $text))

(= (codex:content-item-code-mode-segment (CodexInputImage $image-url $detail))
   (if (codex:is-blank-text $image-url)
       CodexAbsent
       $image-url))

(= (codex:content-items-to-code-mode-segments ())
   ())

(= (codex:content-items-to-code-mode-segments $items)
   (let ($head $tail) (decons-atom $items)
     (case (codex:content-item-code-mode-segment $head)
       ((CodexAbsent
         (codex:content-items-to-code-mode-segments $tail))
        ($segment
         (case (codex:content-items-to-code-mode-segments $tail)
           (($tail-segments
             (cons-atom $segment $tail-segments)))))))))

(= (codex:content-items-to-code-mode-result $items)
   (JsonString
     (str-join
       "\n"
       (codex:content-items-to-code-mode-segments $items))))

(= (codex:function-tool-response $call-id $payload $body $success)
   (let $output
     (case $body
       ((((CodexInputText $text))
         (codex:function-call-output-text $text))
        ($items
         (codex:function-call-output-content-items $items))))
     (case $payload
       (((CodexToolPayloadCustom $input)
         (case $output
           (((CodexFunctionCallOutputText $text)
             (codex:tool-result $call-id $text))
            ((CodexFunctionCallOutputContentItems $items)
             (codex:tool-result-content-items $call-id $items)))))
        ($_
         (codex:function-tool-result $call-id $output))))))

(= (codex:tool-output-success-for-logging
      (CodexToolOutputFunction $body $success $post-tool-use-response))
   (if (== $success CodexAbsent)
       True
       $success))

(= (codex:tool-output-success-for-logging (CodexToolOutputApplyPatch $text))
   True)

(= (codex:tool-output-success-for-logging (CodexToolOutputAborted $message))
   False)

(= (codex:tool-output-success-for-logging (CodexToolOutputToolSearch $tools))
   True)

(= (codex:mcp-call-tool-result-success $result)
   (case (codex:json-object-optional-bool $result "isError")
     ((True False)
      ($_ True))))

(= (codex:tool-output-success-for-logging
      (CodexToolOutputMcpCallToolResult $result))
   (codex:mcp-call-tool-result-success $result))

(= (codex:tool-output-success-for-logging
      (CodexToolOutputMcp $result $tool-input $wall-time-ms $supported))
   (codex:mcp-call-tool-result-success $result))

(= (codex:tool-output-success-for-logging
      (CodexToolOutputExecCommand
        $event-call-id
        $chunk-id
        $wall-time-ms
        $raw-output
        $max-output-tokens
        $process-id
        $exit-code
        $original-token-count
        $hook-command))
   True)

(= (codex:tool-output-log-preview
      (CodexToolOutputFunction $body $success $post-tool-use-response))
   (codex:telemetry-preview
     (codex:function-tool-output-into-text
       (CodexToolOutputFunction $body $success $post-tool-use-response))))

(= (codex:tool-output-log-preview (CodexToolOutputApplyPatch $text))
   (codex:telemetry-preview $text))

(= (codex:tool-output-log-preview (CodexToolOutputAborted $message))
   (codex:telemetry-preview $message))

(= (codex:tool-output-log-preview (CodexToolOutputToolSearch $tools))
   (codex:telemetry-preview (json-stringify (JsonArray $tools))))

(= (codex:tool-output-log-preview
      (CodexToolOutputMcpCallToolResult $result))
   (let $payload (codex:mcp-call-tool-result-as-function-call-output $result)
     (case (codex:function-call-output-to-text $payload)
       ((Empty
         (codex:telemetry-preview
           (codex:mcp-call-tool-result-content-json-text $result)))
        ($preview
         (codex:telemetry-preview $preview))))))

(= (codex:tool-output-log-preview
      (CodexToolOutputMcp $result $tool-input $wall-time-ms $supported))
   (let $payload
     (codex:mcp-tool-output-response-payload
       $result
       $wall-time-ms
       $supported)
     (case (codex:function-call-output-to-text $payload)
       ((Empty
         (codex:telemetry-preview
           (codex:mcp-call-tool-result-content-json-text $result)))
        ($preview
         (codex:telemetry-preview $preview))))))

(= (codex:tool-output-log-preview
      (CodexToolOutputExecCommand
        $event-call-id
        $chunk-id
        $wall-time-ms
        $raw-output
        $max-output-tokens
        $process-id
        $exit-code
        $original-token-count
        $hook-command))
   (codex:telemetry-preview
     (codex:exec-command-tool-output-response-text
       (CodexToolOutputExecCommand
         $event-call-id
         $chunk-id
         $wall-time-ms
         $raw-output
         $max-output-tokens
         $process-id
         $exit-code
         $original-token-count
         $hook-command))))

(= (codex:tool-output-post-tool-use-response
      (CodexToolOutputFunction $body $success $post-tool-use-response)
      $call-id
      $payload)
   (if (== $post-tool-use-response CodexAbsent)
       CodexAbsent
       $post-tool-use-response))

(= (codex:tool-output-post-tool-use-response
      (CodexToolOutputApplyPatch $text)
      $call-id
      $payload)
   (JsonString $text))

(= (codex:tool-output-post-tool-use-response
      (CodexToolOutputAborted $message)
      $call-id
      $payload)
   CodexAbsent)

(= (codex:tool-output-post-tool-use-response
      (CodexToolOutputToolSearch $tools)
      $call-id
      $payload)
   CodexAbsent)

(= (codex:tool-output-post-tool-use-response
      (CodexToolOutputMcpCallToolResult $result)
      $call-id
      $payload)
   CodexAbsent)

(= (codex:tool-output-post-tool-use-response
      (CodexToolOutputMcp $result $tool-input $wall-time-ms $supported)
      $call-id
      $payload)
   $result)

(= (codex:tool-output-post-tool-use-response
      (CodexToolOutputExecCommand
        $event-call-id
        $chunk-id
        $wall-time-ms
        $raw-output
        $max-output-tokens
        $process-id
        $exit-code
        $original-token-count
        $hook-command)
      $call-id
      $payload)
   (if (== $process-id CodexAbsent)
       (if (== $hook-command CodexAbsent)
           CodexAbsent
           (JsonString
             (codex:exec-command-tool-output-truncated-output
               (CodexToolOutputExecCommand
                 $event-call-id
                 $chunk-id
                 $wall-time-ms
                 $raw-output
                 $max-output-tokens
                 $process-id
                 $exit-code
                 $original-token-count
                 $hook-command))))
       CodexAbsent))

(= (codex:tool-output-to-response-item
      (CodexToolOutputFunction $body $success $post-tool-use-response)
      $call-id
      $payload)
   (codex:function-tool-response $call-id $payload $body $success))

(= (codex:tool-output-to-response-item
      (CodexToolOutputApplyPatch $text)
      $call-id
      $payload)
   (codex:function-tool-response
     $call-id
     $payload
     ((CodexInputText $text))
     True))

(= (codex:tool-output-to-response-item
      (CodexToolOutputAborted $message)
      $call-id
      (CodexToolPayloadToolSearch $query $limit))
   (codex:tool-search-output $call-id "completed" "client" ()))

(= (codex:tool-output-to-response-item
      (CodexToolOutputAborted $message)
      $call-id
      (CodexToolPayloadMcp $server $tool $raw-arguments))
   (codex:mcp-tool-call-output
     $call-id
     (codex:mcp-call-tool-result-from-error-text $message)))

(= (codex:tool-output-to-response-item
      (CodexToolOutputAborted $message)
      $call-id
      $payload)
   (codex:function-tool-response
     $call-id
     $payload
     ((CodexInputText $message))
     CodexAbsent))

(= (codex:tool-output-to-response-item
      (CodexToolOutputToolSearch $tools)
      $call-id
      $payload)
   (codex:tool-search-output $call-id "completed" "client" $tools))

(= (codex:tool-output-to-response-item
      (CodexToolOutputMcpCallToolResult $result)
      $call-id
      $payload)
   (codex:mcp-tool-call-output $call-id $result))

(= (codex:tool-output-to-response-item
      (CodexToolOutputMcp $result $tool-input $wall-time-ms $supported)
      $call-id
      $payload)
   ; The current evaluator can duplicate identical MCP payload reductions after
   ; the image-detail helper split. Rust emits one deterministic response item,
   ; so this port forces that visible boundary with `once`.
   (case (once (codex:mcp-tool-output-response-payload $result $wall-time-ms $supported))
     (((CodexFunctionCallOutputText $text)
       (codex:function-tool-result
         $call-id
         (codex:function-call-output-text $text)))
      ((CodexFunctionCallOutputContentItems $items)
       (codex:function-tool-result
         $call-id
         (codex:function-call-output-content-items $items))))))

(= (codex:tool-output-to-response-item
      (CodexToolOutputExecCommand
        $event-call-id
        $chunk-id
        $wall-time-ms
        $raw-output
        $max-output-tokens
        $process-id
        $exit-code
        $original-token-count
        $hook-command)
      $call-id
      $payload)
   (codex:function-tool-response
     $call-id
     $payload
     ((CodexInputText
        (codex:exec-command-tool-output-response-text
          (CodexToolOutputExecCommand
            $event-call-id
            $chunk-id
            $wall-time-ms
            $raw-output
            $max-output-tokens
            $process-id
            $exit-code
            $original-token-count
            $hook-command))))
     True))

(= (codex:tool-output-code-mode-result
      (CodexToolOutputFunction $body $success $post-tool-use-response)
      $payload)
   (codex:response-input-to-code-mode-result
     (codex:tool-output-to-response-item
       (CodexToolOutputFunction $body $success $post-tool-use-response)
       ""
       $payload)))

(= (codex:tool-output-code-mode-result
      (CodexToolOutputApplyPatch $text)
      $payload)
   (JsonObject ()))

(= (codex:tool-output-code-mode-result
      (CodexToolOutputAborted $message)
      $payload)
   (codex:response-input-to-code-mode-result
     (codex:tool-output-to-response-item
       (CodexToolOutputAborted $message)
       ""
       $payload)))

(= (codex:tool-output-code-mode-result
      (CodexToolOutputToolSearch $tools)
      $payload)
   (JsonArray $tools))

(= (codex:tool-output-code-mode-result
      (CodexToolOutputMcpCallToolResult $result)
      $payload)
   $result)

(= (codex:tool-output-code-mode-result
      (CodexToolOutputMcp $result $tool-input $wall-time-ms $supported)
      $payload)
   $result)

(= (codex:tool-output-code-mode-result
      (CodexToolOutputExecCommand
        $event-call-id
        $chunk-id
        $wall-time-ms
        $raw-output
        $max-output-tokens
        $process-id
        $exit-code
        $original-token-count
        $hook-command)
      $payload)
   (codex:exec-command-tool-output-code-mode-json
     (CodexToolOutputExecCommand
       $event-call-id
       $chunk-id
       $wall-time-ms
       $raw-output
       $max-output-tokens
       $process-id
       $exit-code
       $original-token-count
       $hook-command)))

(= (codex:tool-output-code-mode-result-json-string $output $payload)
   (case (codex:tool-output-code-mode-result $output $payload)
     (($json (json-stringify $json)))))

(= (codex:response-input-to-code-mode-result
      (CodexResponseItemMessage $role $content $phase))
   (codex:content-items-to-code-mode-result $content))

(= (codex:response-input-to-code-mode-result
      (CodexResponseItemFunctionCallOutput $call-id (CodexFunctionCallOutputText $text)))
   (JsonString $text))

(= (codex:response-input-to-code-mode-result
      (CodexResponseItemFunctionCallOutput
        $call-id
        (CodexFunctionCallOutputContentItems $items)))
   (codex:content-items-to-code-mode-result $items))

(= (codex:response-input-to-code-mode-result
      (CodexResponseItemCustomToolCallOutput
        $call-id
        $name
        (CodexFunctionCallOutputText $text)))
   (JsonString $text))

(= (codex:response-input-to-code-mode-result
      (CodexResponseItemCustomToolCallOutput
        $call-id
        $name
        (CodexFunctionCallOutputContentItems $items)))
   (codex:content-items-to-code-mode-result $items))

(= (codex:response-input-to-code-mode-result
      (CodexResponseItemToolSearchOutput
        $call-id
        $status
        $execution
        $tools))
   (JsonArray $tools))

(= (codex:response-input-to-code-mode-result
      (CodexResponseItemMcpToolCallOutput $call-id $output))
   $output)

(= (codex:mcp-call-tool-result-from-error-text $text)
   (JsonObject
     ((JsonPair "content"
        (JsonArray
          ((JsonObject
             ((JsonPair "type" (JsonString "text"))
              (JsonPair "text" (JsonString $text)))))))
      (JsonPair "isError" (JsonBool True)))))

(= (codex:mcp-call-tool-result-content-json-text $result)
   (json-stringify
     (case (codex:json-object-optional-array $result "content")
       ((CodexAbsent (JsonArray ()))
        ($content (JsonArray $content))))))

(= (codex:mcp-call-tool-result-as-function-call-output $result)
   (case (codex:json-object-optional-value $result "structuredContent")
     ((CodexAbsent
       (codex:mcp-call-tool-result-content-fallback-output $result))
      ($structured-content
       (codex:function-call-output-text
         (json-stringify $structured-content))))))

(= (codex:mcp-call-tool-result-content-fallback-output $result)
   (case (codex:json-object-optional-array $result "content")
     ((CodexAbsent
       (codex:function-call-output-text
         (json-stringify (JsonArray ()))))
      ($content
       (case (codex:convert-mcp-content-to-items $content)
         ((CodexAbsent
           (codex:function-call-output-text
             (json-stringify (JsonArray $content))))
          ($items
           (codex:function-call-output-content-items $items))))))))

(= (codex:convert-mcp-content-to-items ())
   CodexAbsent)

(= (codex:convert-mcp-content-to-items $content)
   (codex:convert-mcp-content-to-items-acc $content False ()))

(= (codex:convert-mcp-content-to-items-acc () False $acc)
   CodexAbsent)

(= (codex:convert-mcp-content-to-items-acc () True $acc)
   $acc)

(= (codex:convert-mcp-content-to-items-acc $content $saw-image $acc)
   (let ($head $tail) (decons-atom $content)
     (let $converted (codex:mcp-content-item-to-function-output-item $head)
       (codex:convert-mcp-content-to-items-acc
         $tail
         (if (codex:is-mcp-content-item-image? $head)
             True
             $saw-image)
         (codex:append-item $acc $converted)))))

(= (codex:is-mcp-content-item-image? $content)
   (case $content
     (((JsonObject $pairs)
       (== (codex:json-object-optional-string (JsonObject $pairs) "type") "image"))
      ($_ False))))

(= (codex:mcp-content-item-to-function-output-item $content)
   (case $content
     (((JsonObject $pairs)
       (let $object (JsonObject $pairs)
         (case (codex:json-object-optional-string $object "type")
           (("text"
             (CodexInputText
               (json-string-value (json-object-get $object "text"))))
            ("image"
             (CodexInputImage
               (codex:mcp-content-image-url $object)
               (codex:mcp-content-image-detail $object)))
            ($_
             (CodexInputText (json-stringify $object)))))))
      ($other
       (CodexInputText (json-stringify $other))))))

(= (codex:mcp-content-image-url $object)
   (let $data (json-string-value (json-object-get $object "data"))
     (if (str-starts-with? $data "data:")
         $data
         (let $mime-type
           (case (codex:json-object-optional-string $object "mimeType")
             ((CodexAbsent
               (case (codex:json-object-optional-string $object "mime_type")
                 ((CodexAbsent "application/octet-stream")
                  ($mime-type-alt $mime-type-alt))))
              ($mime-type-main $mime-type-main)))
           (str-concat
             "data:"
             (str-concat
               $mime-type
               (str-concat ";base64," $data)))))))

(= (codex:mcp-content-image-detail $object)
   (let $detail
     (case (codex:json-object-optional-object $object "_meta")
       ((CodexAbsent CodexAbsent)
        ($meta
         (codex:json-object-optional-string
           $meta
           (codex:mcp-image-detail-meta-key)))))
     (case $detail
       (("auto" "auto")
        ("low" "low")
        ("high" "high")
        ("original" "original")
        ($_
         (codex:default-image-detail))))))

(= (codex:mcp-tool-output-response-payload $result $wall-time-ms $supported)
   (let $header
     (format-args
       "Wall time: {} seconds\nOutput:"
       ((codex:duration-ms-to-seconds-text $wall-time-ms)))
     (case (codex:mcp-call-tool-result-as-function-call-output $result)
      (((CodexFunctionCallOutputText $text)
        (if (== $text "")
             (codex:function-call-output-text $header)
             (codex:function-call-output-text
               (str-concat $header (str-concat "\n" $text)))))
        ((CodexFunctionCallOutputContentItems $items)
         ; The imported image-detail helper can currently surface duplicate
         ; identical reductions at this module boundary. Rust has a single
         ; deterministic result here, so the CeTTa port forces that visible
         ; shape with `once`.
         (case (once (codex:sanitize-original-image-detail-items $supported $items))
           (($sanitized-items
             (codex:function-call-output-content-items
               (cons-atom
                 (CodexInputText $header)
                 $sanitized-items))))))))))

(= (codex:strip-trailing-dot-zero $text)
   (if (str-ends-with? $text ".0")
       (str-slice $text 0 (- (str-length $text) 2))
       $text))

(= (codex:number-text $value)
   (codex:strip-trailing-dot-zero (format-args "{}" ($value))))

(= (codex:approx-bytes-for-tokens $tokens)
   (codex:output-truncation-approx-bytes-for-tokens $tokens))

(= (codex:approx-tokens-from-byte-count $bytes)
   (codex:output-truncation-approx-tokens-from-byte-count $bytes))

(= (codex:count-lines $text)
   (codex:output-truncation-count-lines $text))

(= (codex:token-truncation-marker $removed-bytes)
   (codex:string-truncate-format-truncation-marker
     True
     (codex:approx-tokens-from-byte-count $removed-bytes)))

(= (codex:truncate-middle-with-token-budget $text $max-tokens)
   (let $policy
     (codex:output-truncation-policy-tokens $max-tokens)
     (codex:output-truncation-truncate-text $text $policy)))

(= (codex:truncate-middle-with-token-budget-bytes $text $max-bytes)
   (codex:string-truncate-with-byte-estimate $text $max-bytes True))

(= (codex:resolve-max-output-tokens $max-output-tokens)
   (if (== $max-output-tokens CodexAbsent)
       (codex:default-max-output-tokens)
       $max-output-tokens))

(= (codex:format-truncated-output $text $max-output-tokens)
   (let $resolved-max-output-tokens
     (codex:resolve-max-output-tokens $max-output-tokens)
     (let $policy
       (codex:output-truncation-policy-tokens
         $resolved-max-output-tokens)
       (codex:output-truncation-formatted-truncate-text
         $text
         $policy))))

(= (codex:pad-left-3 $text)
   (if (== (str-length $text) 0)
       "000"
       (if (== (str-length $text) 1)
           (str-concat "00" $text)
           (if (== (str-length $text) 2)
               (str-concat "0" $text)
               $text))))

(= (codex:duration-ms-to-seconds-text $duration-ms)
   (let $seconds-whole
     (trunc-math (/ $duration-ms 1000))
     (let $millis (% $duration-ms 1000)
       (str-concat
         (codex:number-text $seconds-whole)
         (str-concat
           "."
           (str-concat
             (codex:pad-left-3 (codex:number-text $millis))
             "0"))))))

(= (codex:strip-trailing-zeroes $text)
   (if (str-ends-with? $text "0")
       (codex:strip-trailing-zeroes
         (str-slice $text 0 (- (str-length $text) 1)))
       $text))

(= (codex:duration-ms-to-json-seconds-text $duration-ms)
   (let $seconds-text (codex:duration-ms-to-seconds-text $duration-ms)
     (let $without-zeroes (codex:strip-trailing-zeroes $seconds-text)
       (if (str-ends-with? $without-zeroes ".")
           (str-slice
             $without-zeroes
             0
             (- (str-length $without-zeroes) 1))
           $without-zeroes))))

(= (codex:exec-command-tool-output-truncated-output
      (CodexToolOutputExecCommand
        $event-call-id
        $chunk-id
        $wall-time-ms
        $raw-output
        $max-output-tokens
        $process-id
        $exit-code
        $original-token-count
        $hook-command))
   (codex:format-truncated-output $raw-output $max-output-tokens))

(= (codex:exec-command-tool-output-response-lines
      (CodexToolOutputExecCommand
        $event-call-id
        $chunk-id
        $wall-time-ms
        $raw-output
        $max-output-tokens
        $process-id
        $exit-code
        $original-token-count
        $hook-command))
   (case
     (if (== $chunk-id "")
         ()
         ((format-args "Chunk ID: {}" ($chunk-id))))
     (($lines1
       (case
         (codex:append-item
           $lines1
           (format-args
             "Wall time: {} seconds"
             ((codex:duration-ms-to-seconds-text $wall-time-ms))))
         (($lines2
           (case
             (if (== $exit-code CodexAbsent)
                 $lines2
                 (codex:append-item
                   $lines2
                   (format-args
                     "Process exited with code {}"
                     ($exit-code))))
             (($lines3
               (case
                 (if (== $process-id CodexAbsent)
                     $lines3
                     (codex:append-item
                       $lines3
                       (format-args
                         "Process running with session ID {}"
                         ($process-id))))
                 (($lines4
                   (case
                     (if (== $original-token-count CodexAbsent)
                         $lines4
                         (codex:append-item
                           $lines4
                           (format-args
                             "Original token count: {}"
                             ($original-token-count))))
                     (($lines5
                       (case (codex:append-item $lines5 "Output:")
                         (($lines6
                           (codex:append-item
                             $lines6
                             (codex:exec-command-tool-output-truncated-output
                               (CodexToolOutputExecCommand
                                 $event-call-id
                                 $chunk-id
                                 $wall-time-ms
                                 $raw-output
                                 $max-output-tokens
                                 $process-id
                                 $exit-code
                                 $original-token-count
                                 $hook-command))))))))))))))))))))))

(= (codex:exec-command-tool-output-response-text $output)
   (str-join "\n" (codex:exec-command-tool-output-response-lines $output)))

(= (codex:append-json-pair $pairs $key $value)
   ; CeTTa evaluation accommodation: Rust Vec pushes are fully materialized
   ; before reuse; force the equivalent list append boundary here.
   (case (codex:append-item $pairs (JsonPair $key $value))
     (($materialized $materialized))))

(= (codex:exec-command-tool-output-code-mode-json
      (CodexToolOutputExecCommand
        $event-call-id
        $chunk-id
        $wall-time-ms
        $raw-output
        $max-output-tokens
        $process-id
        $exit-code
        $original-token-count
        $hook-command))
   (let $pairs1
     (if (== $chunk-id "")
         ()
         ((JsonPair "chunk_id" (JsonString $chunk-id))))
     (let $pairs2
       (codex:append-json-pair
         $pairs1
         "wall_time_seconds"
         (JsonNumber (codex:duration-ms-to-json-seconds-text $wall-time-ms)))
       (let $pairs3
         (if (== $exit-code CodexAbsent)
             $pairs2
             (codex:append-json-pair
               $pairs2
               "exit_code"
               (JsonNumber (codex:number-text $exit-code))))
         (let $pairs4
           (if (== $process-id CodexAbsent)
               $pairs3
               (codex:append-json-pair
                 $pairs3
                 "session_id"
                 (JsonNumber (codex:number-text $process-id))))
           (let $pairs5
             (if (== $original-token-count CodexAbsent)
                 $pairs4
                 (codex:append-json-pair
                   $pairs4
                   "original_token_count"
                   (JsonNumber (codex:number-text $original-token-count))))
             (case
               (codex:append-json-pair
                 $pairs5
                 "output"
                 (JsonString
                   (codex:exec-command-tool-output-truncated-output
                     (CodexToolOutputExecCommand
                       $event-call-id
                       $chunk-id
                       $wall-time-ms
                       $raw-output
                       $max-output-tokens
                       $process-id
                       $exit-code
                       $original-token-count
                       $hook-command))))
               (($pairs6 (JsonObject $pairs6))))))))))

(= (codex:take-first-items () $limit)
   ())

(= (codex:take-first-items $items $limit)
   (if (<= $limit 0)
       ()
       (let ($head $tail) (decons-atom $items)
         (case (codex:take-first-items $tail (- $limit 1))
           (($tail-items
             (cons-atom $head $tail-items)))))))

(= (codex:telemetry-preview $content)
   (let $truncated-slice
     (str-take-bytes-at-char-boundary
       $content
       (codex:telemetry-preview-max-bytes))
     (let $truncated-by-bytes (if (== $truncated-slice $content) False True)
       (let $lines (str-split "\n" $truncated-slice)
         (let $truncated-by-lines
           (> (list:len $lines) (codex:telemetry-preview-max-lines))
           (if (and (not $truncated-by-bytes) (not $truncated-by-lines))
               $content
               (let $preview
                 (str-join
                   "\n"
                   (codex:take-first-items
                     $lines
                     (codex:telemetry-preview-max-lines)))
                 (if (== $preview "")
                     (codex:telemetry-preview-truncation-notice)
                     (if (str-ends-with? $preview "\n")
                         (str-concat
                           $preview
                           (codex:telemetry-preview-truncation-notice))
                         (str-concat
                           $preview
                           (str-concat
                             "\n"
                             (codex:telemetry-preview-truncation-notice))))))))))))
