; Rust-faithful pure stream-event helper slice.
;
; This ports the pure helper behavior from:
; - openai-codex/codex-rs/core/src/stream_events_utils.rs
;
; Covered in this increment:
; - image_generation_artifact_path
; - strip_hidden_assistant_markup
; - strip_hidden_assistant_markup_and_parse_memory_citation
; - raw_assistant_output_text_from_item
; - response_item_may_include_external_context
; - last_assistant_message_from_item
; - completed_item_defers_mailbox_delivery_to_next_turn
; - response_input_to_response_item
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust also saves image bytes asynchronously after base64 decoding. This
;   slice ports the deterministic artifact path and message-routing decisions;
;   filesystem persistence belongs with the later async/runtime helper slice.
; - Rust uses `PathBuf::join` for all artifact path components. CeTTa appends
;   the constant/sanitized components lexically; after Rust's sanitizer has
;   removed path separators from session and call ids, the visible path is the
;   same for the absolute codex_home values used by Codex and avoids symbolic
;   path-helper reduction at this eval boundary.
; - The current CeTTa protocol serializer has not yet exposed Rust
;   `ResponseItem::ToolSearchCall`. This helper still recognizes the Rust
;   constructor shape locally so the external-context predicate keeps the same
;   algorithmic branch when that variant is passed through this boundary.
; - Rust's `FunctionCallOutputPayload` carries success metadata. The current
;   CeTTa protocol body constructors model the text/content-items body only,
;   matching the existing protocol/context wire-body surface until payload
;   metadata is ported.

!(import! &self list)
!(import! &self json)
!(import! &self memory_citation)
!(import! &self protocol)
!(import! &self str)
!(import! &self stream_parser)

(= (codex:generated-image-artifacts-dir)
   "generated_images")

(= (codex:image-generation-artifact-fallback-name)
   "generated_image")

(= (codex:stream-events-is-artifact-path-char $char)
   (case $char
     (("0" True)
      ("1" True)
      ("2" True)
      ("3" True)
      ("4" True)
      ("5" True)
      ("6" True)
      ("7" True)
      ("8" True)
      ("9" True)
      ("A" True)
      ("B" True)
      ("C" True)
      ("D" True)
      ("E" True)
      ("F" True)
      ("G" True)
      ("H" True)
      ("I" True)
      ("J" True)
      ("K" True)
      ("L" True)
      ("M" True)
      ("N" True)
      ("O" True)
      ("P" True)
      ("Q" True)
      ("R" True)
      ("S" True)
      ("T" True)
      ("U" True)
      ("V" True)
      ("W" True)
      ("X" True)
      ("Y" True)
      ("Z" True)
      ("a" True)
      ("b" True)
      ("c" True)
      ("d" True)
      ("e" True)
      ("f" True)
      ("g" True)
      ("h" True)
      ("i" True)
      ("j" True)
      ("k" True)
      ("l" True)
      ("m" True)
      ("n" True)
      ("o" True)
      ("p" True)
      ("q" True)
      ("r" True)
      ("s" True)
      ("t" True)
      ("u" True)
      ("v" True)
      ("w" True)
      ("x" True)
      ("y" True)
      ("z" True)
      ("-" True)
      ("_" True)
      ($other False))))

(= (codex:image-generation-sanitize-artifact-component-from $value $index $acc)
   (if (== $index (str-length $value))
       $acc
       (let $char (str-slice $value $index (+ $index 1))
         (codex:image-generation-sanitize-artifact-component-from
           $value
           (+ $index 1)
           (str-concat
             $acc
             (if (codex:stream-events-is-artifact-path-char $char)
                 $char
                 "_"))))))

(= (codex:image-generation-sanitize-artifact-component $value)
   (let $sanitized
     (codex:image-generation-sanitize-artifact-component-from $value 0 "")
     (if (== $sanitized "")
         (codex:image-generation-artifact-fallback-name)
         $sanitized)))

(= (codex:image-generation-artifact-root $codex-home)
   (str-concat $codex-home "/generated_images"))

(= (codex:image-generation-artifact-path-from-components
      $generated-root
      $session-dir
      $file-name)
   (str-concat
     (str-concat
       (str-concat
         (str-concat $generated-root "/")
         $session-dir)
       "/")
     $file-name))

(= (codex:image-generation-artifact-path $codex-home $session-id $call-id)
   (codex:image-generation-artifact-path-session-from
     $codex-home
     $session-id
     $call-id
     0
     ""))

(= (codex:image-generation-artifact-path-session-from
      $codex-home
      $session-id
      $call-id
      $index
      $session-acc)
   (if (== $index (str-length $session-id))
       (let $session-dir
         (if (== $session-acc "")
             (codex:image-generation-artifact-fallback-name)
             $session-acc)
         (codex:image-generation-artifact-path-call-from
           $codex-home
           $session-dir
           $call-id
           0
           ""))
       (let $char (str-slice $session-id $index (+ $index 1))
         (codex:image-generation-artifact-path-session-from
           $codex-home
           $session-id
           $call-id
           (+ $index 1)
           (str-concat
             $session-acc
             (if (codex:stream-events-is-artifact-path-char $char)
                 $char
                 "_"))))))

(= (codex:image-generation-artifact-path-call-from
      $codex-home
      $session-dir
      $call-id
      $index
      $call-acc)
   (if (== $index (str-length $call-id))
       (let $call-name
         (if (== $call-acc "")
             (codex:image-generation-artifact-fallback-name)
             $call-acc)
         (str-concat
           (str-concat
             (str-concat
               (str-concat
                 (str-concat $codex-home "/generated_images/")
                 $session-dir)
               "/")
             $call-name)
           ".png"))
       (let $char (str-slice $call-id $index (+ $index 1))
         (codex:image-generation-artifact-path-call-from
           $codex-home
           $session-dir
           $call-id
           (+ $index 1)
           (str-concat
             $call-acc
             (if (codex:stream-events-is-artifact-path-char $char)
                 $char
                 "_"))))))

(= (codex:stream-events-hidden-markup-result $visible $memory-citation)
   (CodexStreamEventsHiddenMarkupResult $visible $memory-citation))

(= (codex:stream-events-hidden-markup-result-visible
      (CodexStreamEventsHiddenMarkupResult $visible $memory-citation))
   $visible)

(= (codex:stream-events-hidden-markup-result-memory-citation
      (CodexStreamEventsHiddenMarkupResult $visible $memory-citation))
   $memory-citation)

(= (codex:strip-hidden-assistant-markup $text $plan-mode)
   (case (once (eval (codex:strip-citations $text)))
     (((CodexStreamParserStripCitationsResult $without-citations $citations)
       (if $plan-mode
           (case
             (codex:strip-proposed-plan-blocks $without-citations)
             (($visible $visible)))
           $without-citations)))))

(= (codex:strip-hidden-assistant-markup-and-parse-memory-citation
      $text
      $plan-mode)
   (case (once (eval (codex:strip-citations $text)))
     (((CodexStreamParserStripCitationsResult $without-citations $citations)
       (let $visible
         (if $plan-mode
             (case
               (codex:strip-proposed-plan-blocks $without-citations)
               (($plan-stripped $plan-stripped)))
             $without-citations)
         (case (codex:parse-memory-citation $citations)
           (($memory-citation
             (codex:stream-events-hidden-markup-result
               $visible
               $memory-citation)))))))))

(= (codex:stream-events-output-text-content ())
   "")

(= (codex:stream-events-output-text-content $items)
   (codex:stream-events-output-text-content-acc $items ""))

(= (codex:stream-events-output-text-content-acc () $acc)
   $acc)

(= (codex:stream-events-output-text-content-acc $items $acc)
   (let $head (list:first $items)
     (let $tail (list:rest $items)
       (case $head
        (((CodexOutputText $text)
           (codex:stream-events-output-text-content-acc
             $tail
             (str-concat $acc $text)))
          ($other
           (codex:stream-events-output-text-content-acc $tail $acc)))))))

(= (codex:raw-assistant-output-text-from-item $item)
   (case (once (eval $item))
     (((CodexResponseItemMessage "assistant" $content $phase)
       (codex:stream-events-output-text-content $content))
      ((CodexResponseItemMessageWithId $id "assistant" $content $phase)
       (codex:stream-events-output-text-content $content))
      ($other CodexAbsent))))

(= (codex:response-item-may-include-external-context $item)
   (case (once (eval $item))
     (((CodexResponseItemToolSearchCall
         $id
         $call-id
         $status
         $execution
         $arguments)
       True)
      ((CodexResponseItemToolSearchOutput
         $call-id
         $status
         $execution
         $tools)
       True)
      ((CodexResponseItemWebSearchCall $id $status $action)
       True)
      ($other False))))

(= (codex:last-assistant-message-from-item $item $plan-mode)
   (case (codex:raw-assistant-output-text-from-item $item)
     ((CodexAbsent
       CodexAbsent)
      ($raw-text
       (if (== $raw-text "")
           CodexAbsent
           (case
             (codex:strip-hidden-assistant-markup $raw-text $plan-mode)
             (($stripped
               (if (== (str-trim $stripped) "")
                   CodexAbsent
                   $stripped)))))))))

(= (codex:completed-item-defers-mailbox-delivery-to-next-turn
      $item
      $plan-mode)
   (case (once (eval $item))
     (((CodexResponseItemMessage "assistant" $content "commentary")
       False)
      ((CodexResponseItemMessageWithId $id "assistant" $content "commentary")
       False)
      ((CodexResponseItemMessage "assistant" $content $phase)
       (case
         (codex:last-assistant-message-from-item $item $plan-mode)
         ((CodexAbsent False)
          ($message True))))
      ((CodexResponseItemMessageWithId $id "assistant" $content $phase)
       (case
         (codex:last-assistant-message-from-item $item $plan-mode)
         ((CodexAbsent False)
          ($message True))))
      ((CodexResponseItemImageGenerationCall
         $id
         $status
         $revised-prompt
         $result)
       True)
      ($other False))))

(= (codex:response-input-message $role $content)
   (CodexResponseInputItemMessage $role $content))

(= (codex:response-input-function-call-output $call-id $output)
   (CodexResponseInputItemFunctionCallOutput $call-id $output))

(= (codex:response-input-mcp-tool-call-output $call-id $output)
   (CodexResponseInputItemMcpToolCallOutput $call-id $output))

(= (codex:response-input-custom-tool-call-output $call-id $name $output)
   (CodexResponseInputItemCustomToolCallOutput $call-id $name $output))

(= (codex:response-input-tool-search-output
      $call-id
      $status
      $execution
      $tools)
   (CodexResponseInputItemToolSearchOutput
     $call-id
     $status
     $execution
     $tools))

(= (codex:stream-events-mcp-image-detail-meta-key)
   "codex/imageDetail")

(= (codex:stream-events-json-object-optional-value $object $key)
   (case (json-object-get $object $key)
     ((Empty CodexAbsent)
      (JsonNull CodexAbsent)
      ($value $value))))

(= (codex:stream-events-json-object-optional-string $object $key)
   (case (codex:stream-events-json-object-optional-value $object $key)
     ((CodexAbsent CodexAbsent)
      ((JsonString $text) $text))))

(= (codex:stream-events-json-object-optional-object $object $key)
   (case (codex:stream-events-json-object-optional-value $object $key)
     ((CodexAbsent CodexAbsent)
      ((JsonObject $pairs) (JsonObject $pairs)))))

(= (codex:stream-events-json-object-optional-array $object $key)
   (case (codex:stream-events-json-object-optional-value $object $key)
     ((CodexAbsent CodexAbsent)
      ((JsonArray $items) $items))))

(= (codex:stream-events-append-items () $rhs)
   $rhs)

(= (codex:stream-events-append-items $lhs $rhs)
   (let ($head $tail) (decons-atom $lhs)
     (case (codex:stream-events-append-items $tail $rhs)
       (($rest
          (cons-atom $head $rest))))))

(= (codex:stream-events-append-item $items $item)
   (codex:stream-events-append-items $items ($item)))

(= (codex:stream-events-mcp-call-tool-result-json $output)
   (case (once (eval $output))
     (((CodexMcpCallToolResult $content $structured-content $is-error $meta)
       (codex:mcp-call-tool-result-json
         (CodexMcpCallToolResult
           $content
           $structured-content
           $is-error
           $meta)))
      ($json $json))))

(= (codex:stream-events-mcp-call-tool-result-as-function-call-output $result)
   (case
     (codex:stream-events-json-object-optional-value
       $result
       "structuredContent")
     ((CodexAbsent
       (codex:stream-events-mcp-call-tool-result-content-fallback-output
         $result))
      ($structured-content
       (codex:function-call-output-text
         (json-stringify $structured-content))))))

(= (codex:stream-events-mcp-call-tool-result-content-fallback-output $result)
   (case
     (codex:stream-events-json-object-optional-array $result "content")
     ((CodexAbsent
       (codex:function-call-output-text (json-stringify (JsonArray ()))))
      ($content
       (case (codex:stream-events-convert-mcp-content-to-items $content)
         ((CodexAbsent
           (codex:function-call-output-text
             (json-stringify (JsonArray $content))))
          ($items
           (codex:function-call-output-content-items $items))))))))

(= (codex:stream-events-convert-mcp-content-to-items ())
   CodexAbsent)

(= (codex:stream-events-convert-mcp-content-to-items $content)
   (codex:stream-events-convert-mcp-content-to-items-acc
     $content
     False
     ()))

(= (codex:stream-events-convert-mcp-content-to-items-acc () False $acc)
   CodexAbsent)

(= (codex:stream-events-convert-mcp-content-to-items-acc () True $acc)
   $acc)

(= (codex:stream-events-convert-mcp-content-to-items-acc
      $content
      $saw-image
      $acc)
   (let ($head $tail) (decons-atom $content)
     (let $converted
       (codex:stream-events-mcp-content-item-to-function-output-item $head)
       (codex:stream-events-convert-mcp-content-to-items-acc
         $tail
         (if (codex:stream-events-is-mcp-content-item-image $head)
             True
             $saw-image)
         (codex:stream-events-append-item $acc $converted)))))

(= (codex:stream-events-is-mcp-content-item-image $content)
   (case $content
     (((JsonObject $pairs)
       (== (codex:stream-events-json-object-optional-string
             (JsonObject $pairs)
             "type")
           "image"))
      ($_ False))))

(= (codex:stream-events-mcp-content-item-to-function-output-item $content)
   (case $content
     (((JsonObject $pairs)
       (let $object (JsonObject $pairs)
         (case
           (codex:stream-events-json-object-optional-string $object "type")
           (("text"
             (CodexInputText
               (json-string-value (json-object-get $object "text"))))
            ("image"
             (CodexInputImage
               (codex:stream-events-mcp-content-image-url $object)
               (codex:stream-events-mcp-content-image-detail $object)))
            ($_
             (CodexInputText (json-stringify $object)))))))
      ($other
       (CodexInputText (json-stringify $other))))))

(= (codex:stream-events-mcp-content-image-url $object)
   (let $data (json-string-value (json-object-get $object "data"))
     (if (str-starts-with? $data "data:")
         $data
         (let $mime-type
           (case
             (codex:stream-events-json-object-optional-string
               $object
               "mimeType")
             ((CodexAbsent
               (case
                 (codex:stream-events-json-object-optional-string
                   $object
                   "mime_type")
                 ((CodexAbsent "application/octet-stream")
                  ($mime-type-alt $mime-type-alt))))
              ($mime-type-main $mime-type-main)))
           (str-concat
             "data:"
             (str-concat
               $mime-type
               (str-concat ";base64," $data)))))))

(= (codex:stream-events-mcp-content-image-detail $object)
   (let $detail
     (case
       (codex:stream-events-json-object-optional-object $object "_meta")
       ((CodexAbsent CodexAbsent)
        ($meta
         (codex:stream-events-json-object-optional-string
           $meta
           (codex:stream-events-mcp-image-detail-meta-key)))))
     (case $detail
       (("auto" "auto")
        ("low" "low")
        ("high" "high")
        ("original" "original")
        ($_
         (codex:default-image-detail))))))

(= (codex:response-input-to-response-item $input)
   (case (once (eval $input))
     (((CodexResponseInputItemFunctionCallOutput $call-id $output)
       (CodexResponseItemFunctionCallOutput $call-id $output))
      ((CodexResponseInputItemCustomToolCallOutput $call-id $name $output)
       (CodexResponseItemCustomToolCallOutput $call-id $name $output))
      ((CodexResponseInputItemMcpToolCallOutput $call-id $output)
       (CodexResponseItemFunctionCallOutput
         $call-id
         (codex:stream-events-mcp-call-tool-result-as-function-call-output
           (codex:stream-events-mcp-call-tool-result-json $output))))
      ((CodexResponseInputItemToolSearchOutput
         $call-id
         $status
         $execution
         $tools)
       (CodexResponseItemToolSearchOutput
         $call-id
         $status
         $execution
         $tools))
      ($other CodexAbsent))))
