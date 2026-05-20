; Protocol dynamic-tools slice for the Codex port.
;
; Ports deterministic data-shape and JSON behavior from:
; - openai-codex/codex-rs/protocol/src/dynamic_tools.rs
;
; Covered in this increment:
; - DynamicToolSpec with camelCase JSON projection
; - DynamicToolSpec deserialization defaulting, including the legacy
;   exposeToContext -> deferLoading inversion
; - DynamicToolCallRequest, DynamicToolResponse, and output content items
;
; Required slice-local deviations from Rust, documented for later audit:
; - Rust serde reports structured deserialization errors for missing or
;   incorrectly typed required fields. This CeTTa surface follows the existing
;   local JSON-boundary convention and exposes direct field readers; invalid
;   required fields remain unreduced at the call site until the shared serde
;   error surface is ported.

!(import! &self json)

(= (codex:dynamic-tool-spec
      $namespace
      $name
      $description
      $input-schema
      $defer-loading)
   (CodexDynamicToolSpec
     $namespace
     $name
     $description
     $input-schema
     $defer-loading))

(= (codex:dynamic-tool-spec-namespace
      (CodexDynamicToolSpec
        $namespace
        $name
        $description
        $input-schema
        $defer-loading))
   $namespace)

(= (codex:dynamic-tool-spec-name
      (CodexDynamicToolSpec
        $namespace
        $name
        $description
        $input-schema
        $defer-loading))
   $name)

(= (codex:dynamic-tool-spec-description
      (CodexDynamicToolSpec
        $namespace
        $name
        $description
        $input-schema
        $defer-loading))
   $description)

(= (codex:dynamic-tool-spec-input-schema
      (CodexDynamicToolSpec
        $namespace
        $name
        $description
        $input-schema
        $defer-loading))
   $input-schema)

(= (codex:dynamic-tool-spec-defer-loading
      (CodexDynamicToolSpec
        $namespace
        $name
        $description
        $input-schema
        $defer-loading))
   $defer-loading)

(= (codex:dynamic-tool-call-request
      $call-id
      $turn-id
      $namespace
      $tool
      $arguments)
   (CodexDynamicToolCallRequest
     $call-id
     $turn-id
     $namespace
     $tool
     $arguments))

(= (codex:dynamic-tool-call-request-call-id
      (CodexDynamicToolCallRequest
        $call-id
        $turn-id
        $namespace
        $tool
        $arguments))
   $call-id)

(= (codex:dynamic-tool-call-request-turn-id
      (CodexDynamicToolCallRequest
        $call-id
        $turn-id
        $namespace
        $tool
        $arguments))
   $turn-id)

(= (codex:dynamic-tool-call-request-namespace
      (CodexDynamicToolCallRequest
        $call-id
        $turn-id
        $namespace
        $tool
        $arguments))
   $namespace)

(= (codex:dynamic-tool-call-request-tool
      (CodexDynamicToolCallRequest
        $call-id
        $turn-id
        $namespace
        $tool
        $arguments))
   $tool)

(= (codex:dynamic-tool-call-request-arguments
      (CodexDynamicToolCallRequest
        $call-id
        $turn-id
        $namespace
        $tool
        $arguments))
   $arguments)

(= (codex:dynamic-tool-response $content-items $success)
   (CodexDynamicToolResponse $content-items $success))

(= (codex:dynamic-tool-response-content-items
      (CodexDynamicToolResponse $content-items $success))
   $content-items)

(= (codex:dynamic-tool-response-success
      (CodexDynamicToolResponse $content-items $success))
   $success)

(= (codex:dynamic-tool-output-item-input-text $text)
   (CodexDynamicToolCallOutputContentItemInputText $text))

(= (codex:dynamic-tool-output-item-input-image $image-url)
   (CodexDynamicToolCallOutputContentItemInputImage $image-url))

(= (codex:dynamic-tool-output-item-text
      (CodexDynamicToolCallOutputContentItemInputText $text))
   $text)

(= (codex:dynamic-tool-output-item-image-url
      (CodexDynamicToolCallOutputContentItemInputImage $image-url))
   $image-url)

(= (codex:dynamic-tools-deserialize-error $message)
   (CodexDynamicToolsDeserializeError $message))

(= (codex:dynamic-tools-json-object-optional-value $object $key)
   (case (json-object-get $object $key)
     ((Empty CodexAbsent)
      (JsonNull CodexAbsent)
      ($value $value))))

(= (codex:dynamic-tools-json-object-required-string $object $key)
   (json-string-value (json-object-get $object $key)))

(= (codex:dynamic-tools-json-object-optional-string $object $key)
   (case (codex:dynamic-tools-json-object-optional-value $object $key)
     ((CodexAbsent CodexAbsent)
      ((JsonString $text) $text))))

(= (codex:dynamic-tools-json-object-optional-bool $object $key)
   (case (codex:dynamic-tools-json-object-optional-value $object $key)
     ((CodexAbsent CodexAbsent)
      ((JsonBool $value) $value))))

(= (codex:dynamic-tools-json-object-required-array $object $key)
   (json-array-items (json-object-get $object $key)))

(= (codex:dynamic-tools-nullable-string-json $value)
   (if (== $value CodexAbsent)
       JsonNull
       (JsonString $value)))

(= (codex:dynamic-tool-spec-defer-loading-from-json $json)
   (let $defer-loading
     (codex:dynamic-tools-json-object-optional-bool $json "deferLoading")
     (if (== $defer-loading CodexAbsent)
         (let $expose-to-context
           (codex:dynamic-tools-json-object-optional-bool $json "exposeToContext")
           (if (== $expose-to-context CodexAbsent)
               False
               (if $expose-to-context False True)))
         $defer-loading)))

(= (codex:dynamic-tool-spec-from-json $json)
   (codex:dynamic-tool-spec
     (codex:dynamic-tools-json-object-optional-string $json "namespace")
     (codex:dynamic-tools-json-object-required-string $json "name")
     (codex:dynamic-tools-json-object-required-string $json "description")
     (json-object-get $json "inputSchema")
     (codex:dynamic-tool-spec-defer-loading-from-json $json)))

(= (codex:dynamic-tool-spec-json
      (CodexDynamicToolSpec
        $namespace
        $name
        $description
        $input-schema
        $defer-loading))
   (if (== $namespace CodexAbsent)
       (JsonObject
         ((JsonPair "name" (JsonString $name))
          (JsonPair "description" (JsonString $description))
          (JsonPair "inputSchema" $input-schema)
          (JsonPair "deferLoading" (JsonBool $defer-loading))))
       (JsonObject
         ((JsonPair "namespace" (JsonString $namespace))
          (JsonPair "name" (JsonString $name))
          (JsonPair "description" (JsonString $description))
          (JsonPair "inputSchema" $input-schema)
          (JsonPair "deferLoading" (JsonBool $defer-loading))))))

(= (codex:dynamic-tool-call-request-from-json $json)
   (codex:dynamic-tool-call-request
     (codex:dynamic-tools-json-object-required-string $json "callId")
     (codex:dynamic-tools-json-object-required-string $json "turnId")
     (codex:dynamic-tools-json-object-optional-string $json "namespace")
     (codex:dynamic-tools-json-object-required-string $json "tool")
     (json-object-get $json "arguments")))

(= (codex:dynamic-tool-call-request-json
      (CodexDynamicToolCallRequest
        $call-id
        $turn-id
        $namespace
        $tool
        $arguments))
   (JsonObject
     ((JsonPair "callId" (JsonString $call-id))
      (JsonPair "turnId" (JsonString $turn-id))
      (JsonPair
        "namespace"
        (codex:dynamic-tools-nullable-string-json $namespace))
      (JsonPair "tool" (JsonString $tool))
      (JsonPair "arguments" $arguments))))

(= (codex:dynamic-tool-output-item-from-json $json)
   (let $kind (codex:dynamic-tools-json-object-required-string $json "type")
     (if (== $kind "inputText")
         (codex:dynamic-tool-output-item-input-text
           (codex:dynamic-tools-json-object-required-string $json "text"))
         (if (== $kind "inputImage")
             (codex:dynamic-tool-output-item-input-image
               (codex:dynamic-tools-json-object-required-string $json "imageUrl"))
             (codex:dynamic-tools-deserialize-error
               "unsupported dynamic tool output content item type")))))

(= (codex:dynamic-tool-output-items-from-json-items $items)
   (map-atom-strict
     $items
     $item
     (codex:dynamic-tool-output-item-from-json $item)))

(= (codex:dynamic-tool-response-from-json $json)
   (codex:dynamic-tool-response
     (codex:dynamic-tool-output-items-from-json-items
       (codex:dynamic-tools-json-object-required-array $json "contentItems"))
     (case (json-object-get $json "success")
       (((JsonBool $success) $success)))))

(= (codex:dynamic-tool-output-item-json
      (CodexDynamicToolCallOutputContentItemInputText $text))
   (JsonObject
     ((JsonPair "type" (JsonString "inputText"))
      (JsonPair "text" (JsonString $text)))))

(= (codex:dynamic-tool-output-item-json
      (CodexDynamicToolCallOutputContentItemInputImage $image-url))
   (JsonObject
     ((JsonPair "type" (JsonString "inputImage"))
      (JsonPair "imageUrl" (JsonString $image-url)))))

(= (codex:dynamic-tool-output-items-json $items)
   (JsonArray
     (map-atom-strict
       $items
       $item
       (codex:dynamic-tool-output-item-json $item))))

(= (codex:dynamic-tool-response-json
      (CodexDynamicToolResponse $content-items $success))
   (JsonObject
     ((JsonPair
        "contentItems"
        (codex:dynamic-tool-output-items-json $content-items))
      (JsonPair "success" (JsonBool $success)))))
