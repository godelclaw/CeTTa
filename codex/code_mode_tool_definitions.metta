; Rust-faithful code-mode tool definition slice.
;
; This ports deterministic behavior from:
; - openai-codex/codex-rs/tools/src/code_mode.rs
;   - code_mode_name_for_tool_name
;   - tool spec to CodeMode ToolDefinition conversion
;   - collect_code_mode_tool_definitions
;   - collect_code_mode_exec_prompt_tool_definitions
;   - create_wait_tool
;   - create_code_mode_tool grammar/wrapper shape
; - openai-codex/codex-rs/code-mode/src/description.rs
;   - is_code_mode_nested_tool
;   - normalize_code_mode_identifier
;   - augment_tool_definition/render_code_mode_sample for the schema subset
;     already represented by the CeTTa tool registry.
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust's render_json_schema_to_typescript handles the full serde_json schema
;   surface. This slice implements the object/string/number/integer/boolean/
;   array/bool subset used by the currently ported CeTTa tool specs and returns
;   `unknown` for unsupported schema shapes, matching Rust's fallback type.
; - Rust's build_exec_tool_description includes namespace grouping and MCP
;   structured content type preamble. This slice preserves section ordering,
;   code-mode-only/deferred branches, headings, and augmented tool descriptions;
;   namespace grouping/MCP shared preamble remain out of scope until the MCP
;   structured output schema port lands.

!(import! &self json)
!(import! &self list)
!(import! &self str)
!(import! &self tool_name)
!(import! &self tool_registry_plan)

(= (codex:code-mode-tool-kind-function)
   CodexCodeModeToolKindFunction)

(= (codex:code-mode-tool-kind-freeform)
   CodexCodeModeToolKindFreeform)

(= (codex:code-mode-tool-definition
      $name
      $tool-name
      $description
      $kind
      $input-schema
      $output-schema)
   (CodexCodeModeToolDefinition
     $name
     $tool-name
     $description
     $kind
     $input-schema
     $output-schema))

(= (codex:code-mode-tool-definition-name
      (CodexCodeModeToolDefinition
        $name
        $tool-name
        $description
        $kind
        $input-schema
        $output-schema))
   $name)

(= (codex:code-mode-tool-definition-tool-name
      (CodexCodeModeToolDefinition
        $name
        $tool-name
        $description
        $kind
        $input-schema
        $output-schema))
   $tool-name)

(= (codex:code-mode-tool-definition-description
      (CodexCodeModeToolDefinition
        $name
        $tool-name
        $description
        $kind
        $input-schema
        $output-schema))
   $description)

(= (codex:code-mode-tool-definition-kind
      (CodexCodeModeToolDefinition
        $name
        $tool-name
        $description
        $kind
        $input-schema
        $output-schema))
   $kind)

(= (codex:code-mode-tool-definition-input-schema
      (CodexCodeModeToolDefinition
        $name
        $tool-name
        $description
        $kind
        $input-schema
        $output-schema))
   $input-schema)

(= (codex:code-mode-tool-definition-output-schema
      (CodexCodeModeToolDefinition
        $name
        $tool-name
        $description
        $kind
        $input-schema
        $output-schema))
   $output-schema)

(= (codex:code-mode-public-tool-name)
   "exec")

(= (codex:code-mode-wait-tool-name)
   "wait")

(= (codex:is-code-mode-nested-tool $tool-name)
   (and (not (== $tool-name (codex:code-mode-public-tool-name)))
        (not (== $tool-name (codex:code-mode-wait-tool-name)))))

(= (codex:code-mode-name-for-tool-name
      (CodexToolName $name $namespace))
   (if (== $namespace CodexAbsent)
       $name
       (if (or (str-ends-with? $namespace "_")
               (str-starts-with? $name "_"))
           (str-concat $namespace $name)
           (str-concat $namespace (str-concat "_" $name)))))

(= (codex:code-mode-string-contains-char $chars $char)
   (case (str-find $chars $char)
     ((Empty False)
      ($index True))))

(= (codex:code-mode-is-identifier-start-char $char)
   (codex:code-mode-string-contains-char
     "_$abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
     $char))

(= (codex:code-mode-is-identifier-char $char)
   (codex:code-mode-string-contains-char
     "_$abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
     $char))

(= (codex:normalize-code-mode-identifier-from
      $tool-key
      $index
      $acc)
   (if (== $index (str-length $tool-key))
       (if (== $acc "") "_" $acc)
       (let $char (str-slice $tool-key $index (+ $index 1))
         (let $valid
           (if (== $index 0)
               (codex:code-mode-is-identifier-start-char $char)
               (codex:code-mode-is-identifier-char $char))
           (codex:normalize-code-mode-identifier-from
             $tool-key
             (+ $index 1)
             (str-concat $acc (if $valid $char "_")))))))

(= (codex:normalize-code-mode-identifier $tool-key)
   (codex:normalize-code-mode-identifier-from $tool-key 0 ""))

(= (codex:code-mode-render-schema-field
      (JsonObject $pairs)
      $field)
   (json-object-get (JsonObject $pairs) $field))

(= (codex:code-mode-render-object-properties ())
   "")

(= (codex:code-mode-render-object-properties $pairs)
   (let ($head $tail) (decons-atom $pairs)
     (case $head
       (((JsonPair $name $schema)
         (let $rendered
           (str-concat
             $name
             (str-concat
               ": "
               (str-concat
                 (codex:render-json-schema-to-typescript $schema)
                 ";")))
           (if (== $tail ())
               $rendered
               (str-concat
                 $rendered
                 (str-concat
                   " "
                   (codex:code-mode-render-object-properties
                     $tail))))))))))

(= (codex:code-mode-render-object-type (JsonObject $pairs))
   (let $properties (json-object-get (JsonObject $pairs) "properties")
     (case $properties
       (((JsonObject $property-pairs)
         (if (== $property-pairs ())
             "{}"
             (str-concat
               "{ "
               (str-concat
                 (codex:code-mode-render-object-properties
                   $property-pairs)
                 " }"))))
        ($other "{}")))))

(= (codex:render-json-array-items-to-typescript $items)
   (if (== $items JsonNull)
       "unknown"
       (codex:render-json-schema-to-typescript $items)))

(= (codex:render-json-object-schema-to-typescript
      (JsonString $schema-type)
      $schema)
   (if (== $schema-type "string")
       "string"
       (if (== $schema-type "number")
           "number"
           (if (== $schema-type "integer")
               "number"
               (if (== $schema-type "boolean")
                   "boolean"
                   (if (== $schema-type "null")
                       "null"
                       (if (== $schema-type "array")
                           (str-concat
                             "Array<"
                             (str-concat
                               (codex:render-json-array-items-to-typescript
                                 (json-object-get $schema "items"))
                               ">"))
                           (if (== $schema-type "object")
                               (codex:code-mode-render-object-type $schema)
                               "unknown"))))))))

(= (codex:render-json-object-schema-to-typescript
      JsonNull
      $schema)
   "unknown")

(= (codex:render-json-object-schema-to-typescript
      (JsonBool $value)
      $schema)
   "unknown")

(= (codex:render-json-object-schema-to-typescript
      (JsonNumber $value)
      $schema)
   "unknown")

(= (codex:render-json-object-schema-to-typescript
      (JsonArray $items)
      $schema)
   "unknown")

(= (codex:render-json-schema-to-typescript (JsonBool True))
   "unknown")

(= (codex:render-json-schema-to-typescript (JsonBool False))
   "never")

(= (codex:render-json-schema-to-typescript (JsonObject $pairs))
   (let $schema (JsonObject $pairs)
     (codex:render-json-object-schema-to-typescript
       (codex:code-mode-render-schema-field $schema "type")
       $schema)))

(= (codex:render-json-schema-to-typescript JsonNull)
   "unknown")

(= (codex:render-json-schema-to-typescript (JsonString $value))
   "unknown")

(= (codex:render-json-schema-to-typescript (JsonNumber $value))
   "unknown")

(= (codex:render-json-schema-to-typescript (JsonArray $items))
   "unknown")

(= (codex:render-code-mode-tool-declaration
      $tool-name
      $input-name
      $input-type
      $output-type)
   (function
     (case (codex:normalize-code-mode-identifier $tool-name)
       (($identifier
         (case (str-concat
                 $identifier
                 (str-concat
                   "("
                   (str-concat
                     $input-name
                     (str-concat
                       ": "
                       (str-concat
                         $input-type
                         (str-concat
                           "): Promise<"
                           (str-concat $output-type ">;")))))))
           (($declaration (return $declaration)))))))))

(= (codex:render-code-mode-sample
      $description
      $tool-name
      $input-name
      $input-type
      $output-type)
   (function
     (case (codex:render-code-mode-tool-declaration
             $tool-name
             $input-name
             $input-type
             $output-type)
       (($declaration
         (case (str-concat
                 $description
                 (str-concat
                   "\n\nexec tool declaration:\n```ts\ndeclare const tools: { "
                   (str-concat
                     $declaration
                     " };\n```")))
           (($sample (return $sample)))))))))

(= (codex:code-mode-definition-input-name
      CodexCodeModeToolKindFunction)
   "args")

(= (codex:code-mode-definition-input-name
      CodexCodeModeToolKindFreeform)
   "input")

(= (codex:code-mode-definition-input-type
      CodexCodeModeToolKindFunction
      $input-schema)
   (if (== $input-schema CodexAbsent)
       "unknown"
       (codex:render-json-schema-to-typescript $input-schema)))

(= (codex:code-mode-definition-input-type
      CodexCodeModeToolKindFreeform
      $input-schema)
   "string")

(= (codex:code-mode-definition-output-type $output-schema)
   (if (== $output-schema CodexAbsent)
       "unknown"
       (codex:render-json-schema-to-typescript $output-schema)))

(= (codex:freeform-tool-description
      (CodexFreeformTool
        $name
        $description
        $format-type
        $format-syntax
        $format-definition))
   $description)

(= (codex:augment-code-mode-tool-definition
      (CodexCodeModeToolDefinition
        $name
        $tool-name
        $description
        $kind
        $input-schema
        $output-schema))
   (if (== $name (codex:code-mode-public-tool-name))
       (CodexCodeModeToolDefinition
         $name
         $tool-name
         $description
         $kind
         $input-schema
         $output-schema)
       (case (codex:code-mode-definition-input-name $kind)
         (($input-name
           (case (codex:code-mode-definition-input-type $kind $input-schema)
             (($input-type
               (case (codex:code-mode-definition-output-type $output-schema)
                 (($output-type
                   (case (codex:render-code-mode-sample
                           $description
                           $name
                           $input-name
                           $input-type
                           $output-type)
                     (($augmented-description
                       (CodexCodeModeToolDefinition
                         $name
                         $tool-name
                         $augmented-description
                         $kind
                         $input-schema
                         $output-schema)))))))))))))))

(= (codex:code-mode-tool-definitions-for-spec
      (CodexToolSpecFunction
        (CodexResponsesApiTool
          $name
          $description
          $strict
          $defer-loading
          $parameters
          $output-schema)))
   ((codex:code-mode-tool-definition
      $name
      (codex:plain-tool-name $name)
      $description
      (codex:code-mode-tool-kind-function)
      $parameters
      $output-schema)))

(= (codex:code-mode-tool-definitions-for-spec
      (CodexToolSpecFreeform
        (CodexFreeformTool
          $name
          $description
          $format-type
          $format-syntax
          $format-definition)))
   ((codex:code-mode-tool-definition
      $name
      (codex:plain-tool-name $name)
      $description
      (codex:code-mode-tool-kind-freeform)
      CodexAbsent
      CodexAbsent)))

(= (codex:code-mode-tool-definitions-for-namespace-tools
      $namespace-name
      ())
   ())

(= (codex:code-mode-tool-definitions-for-namespace-tools
      $namespace-name
      $tools)
   (let ($head $tail) (decons-atom $tools)
     (case $head
       (((CodexResponsesApiNamespaceToolFunction
           (CodexResponsesApiTool
             $tool-name
             $description
             $strict
             $defer-loading
             $parameters
             $output-schema))
(let $canonical-tool-name
           (codex:namespaced-tool-name $namespace-name $tool-name)
           (case (codex:code-mode-name-for-tool-name
                   $canonical-tool-name)
             (($code-mode-name
               (case (codex:code-mode-tool-definitions-for-namespace-tools
                       $namespace-name
                       $tail)
                 (($tail-definitions
                   (cons-atom
                     (codex:code-mode-tool-definition
                       $code-mode-name
                       $canonical-tool-name
                       $description
                       (codex:code-mode-tool-kind-function)
                       $parameters
                       $output-schema)
                     $tail-definitions)))))))))))))

(= (codex:code-mode-tool-definitions-for-spec
      (CodexToolSpecNamespace
        (CodexResponsesApiNamespace $namespace-name $description $tools)))
   (codex:code-mode-tool-definitions-for-namespace-tools
     $namespace-name
     $tools))

(= (codex:code-mode-tool-definitions-for-spec
      (CodexToolSpecLocalShell))
   ())

(= (codex:code-mode-tool-definitions-for-spec
      (CodexToolSpecToolSearch))
   ())

(= (codex:code-mode-tool-definitions-for-spec
      (CodexToolSpecImageGeneration $output-format))
   ())

(= (codex:code-mode-tool-definitions-for-spec
      (CodexToolSpecWebSearch))
   ())

(= (codex:code-mode-tool-definitions-for-specs ())
   ())

(= (codex:code-mode-tool-definitions-for-specs $specs)
   (let ($head $tail) (decons-atom $specs)
     (case (codex:code-mode-tool-definitions-for-spec $head)
       (($head-definitions
         (case (codex:code-mode-tool-definitions-for-specs $tail)
           (($tail-definitions
             (list:append
               $head-definitions
               $tail-definitions)))))))))

(= (codex:code-mode-tool-definition-for-spec $spec)
   (let $definitions (codex:code-mode-tool-definitions-for-spec $spec)
     (if (== $definitions ())
         CodexAbsent
         (list:first $definitions))))

(= (codex:tool-spec-to-code-mode-tool-definition $spec)
   (case (codex:code-mode-tool-definition-for-spec $spec)
     ((CodexAbsent CodexAbsent)
      ($definition
       (if (codex:is-code-mode-nested-tool
             (codex:code-mode-tool-definition-name $definition))
           (codex:augment-code-mode-tool-definition $definition)
           CodexAbsent)))))

(= (codex:code-mode-filter-nested-definitions ())
   ())

(= (codex:code-mode-filter-nested-definitions $definitions)
   (let ($head $tail) (decons-atom $definitions)
     (case (codex:code-mode-filter-nested-definitions $tail)
       (($filtered-tail
         (case (codex:code-mode-tool-definition-name $head)
           (($name
             (if (codex:is-code-mode-nested-tool $name)
                 (cons-atom $head $filtered-tail)
                 $filtered-tail)))))))))

(= (codex:code-mode-augment-definitions ())
   ())

(= (codex:code-mode-augment-definitions $definitions)
   (let ($head $tail) (decons-atom $definitions)
     (case (codex:augment-code-mode-tool-definition $head)
       (($augmented-head
         (case (codex:code-mode-augment-definitions $tail)
           (($augmented-tail
             (cons-atom $augmented-head $augmented-tail)))))))))

(= (codex:code-mode-tool-definition-names ())
   ())

(= (codex:code-mode-tool-definition-names $definitions)
   (let ($head $tail) (decons-atom $definitions)
     (case (codex:code-mode-tool-definition-name $head)
       (($name
         (case (codex:code-mode-tool-definition-names $tail)
           (($tail-names
             (cons-atom $name $tail-names)))))))))

(= (codex:code-mode-dedup-sorted-strings ())
   ())

(= (codex:code-mode-dedup-sorted-strings $items)
   (let ($head $tail) (decons-atom $items)
     (if (== $tail ())
         ($head)
         (case (codex:code-mode-dedup-sorted-strings $tail)
           (($dedup-tail
             (if (== $head (list:first $dedup-tail))
                 $dedup-tail
                 (cons-atom $head $dedup-tail))))))))

(= (codex:code-mode-find-definition-by-name
      ()
      $name)
   CodexAbsent)

(= (codex:code-mode-find-definition-by-name
      $definitions
      $name)
   (let ($head $tail) (decons-atom $definitions)
     (if (== (codex:code-mode-tool-definition-name $head) $name)
         $head
         (codex:code-mode-find-definition-by-name $tail $name))))

(= (codex:code-mode-definitions-by-names
      ()
      $definitions)
   ())

(= (codex:code-mode-definitions-by-names
      $names
      $definitions)
   (let ($head $tail) (decons-atom $names)
     (case (codex:code-mode-find-definition-by-name
             $definitions
             $head)
       ((CodexAbsent
         (codex:code-mode-definitions-by-names
           $tail
           $definitions))
        ($definition
         (case (codex:code-mode-definitions-by-names
                 $tail
                 $definitions)
           (($tail-definitions
             (cons-atom
               $definition
               $tail-definitions)))))))))

(= (codex:code-mode-sort-dedup-definitions $definitions)
   (case (codex:code-mode-tool-definition-names $definitions)
     (($names
       (case (sort-strings $names)
         (($sorted-names
           (case (codex:code-mode-dedup-sorted-strings $sorted-names)
             (($deduped-names
               (codex:code-mode-definitions-by-names
                 $deduped-names
                 $definitions)))))))))))

(= (codex:collect-code-mode-exec-prompt-tool-definitions $specs)
   (codex:code-mode-sort-dedup-definitions
     (codex:code-mode-filter-nested-definitions
       (codex:code-mode-tool-definitions-for-specs $specs))))

(= (codex:collect-code-mode-tool-definitions $specs)
   (codex:code-mode-sort-dedup-definitions
     (codex:code-mode-augment-definitions
       (codex:code-mode-filter-nested-definitions
         (codex:code-mode-tool-definitions-for-specs $specs)))))

(= (codex:code-mode-wait-tool-description-template)
   "- Use `wait` only after `exec` returns `Script running with cell ID ...`.\n- `cell_id` identifies the running `exec` cell to resume.\n- `yield_time_ms` controls how long to wait for more output before yielding again. If omitted, `wait` uses its default wait timeout.\n- `max_tokens` limits how much new output this wait call returns.\n- `terminate: true` stops the running cell instead of waiting for more output.\n- `wait` returns only the new output since the last yield, or the final completion or termination result for that cell.\n- If the cell is still running, `wait` may yield again with the same `cell_id`.\n- If the cell has already finished, `wait` returns the completed result and closes the cell.")

(= (codex:build-code-mode-wait-tool-description)
   (codex:code-mode-wait-tool-description-template))

(= (codex:create-code-mode-wait-tool)
   (codex:tool-spec-function
     (codex:responses-api-tool
       (codex:code-mode-wait-tool-name)
       (str-concat
         "Waits on a yielded `exec` cell and returns new output or completion.\n"
         (str-trim (codex:build-code-mode-wait-tool-description)))
       False
       CodexAbsent
       (codex:json-schema-object-with-required-and-additional-properties
         ((JsonPair "cell_id"
            (codex:json-schema-string
              "Identifier of the running exec cell."))
          (JsonPair "max_tokens"
            (codex:json-schema-number
              "Maximum number of output tokens to return for this wait call."))
          (JsonPair "terminate"
            (codex:json-schema-boolean
              "Whether to terminate the running exec cell."))
          (JsonPair "yield_time_ms"
            (codex:json-schema-number
              "How long to wait (in milliseconds) for more output before yielding again.")))
         ("cell_id")
         False)
       CodexAbsent)))

(= (codex:code-mode-exec-freeform-grammar)
   "\nstart: pragma_source | plain_source\npragma_source: PRAGMA_LINE NEWLINE SOURCE\nplain_source: SOURCE\n\nPRAGMA_LINE: /[ \\t]*\\/\\/ @exec:[^\\r\\n]*/\nNEWLINE: /\\r?\\n/\nSOURCE: /[\\s\\S]+/\n")

(= (codex:code-mode-only-preface)
   "Use `exec/wait` tool to run all other tools, do not attempt to use any other tools directly")

(= (codex:code-mode-deferred-nested-tools-guidance)
   "Some nested MCP/app tools may be omitted from this description. They are still available on the global `tools` object and listed in `ALL_TOOLS`.\nTo find one, filter `ALL_TOOLS` by `name` and `description`; do not print the full `ALL_TOOLS` array. Print only a small set of relevant matches if you need to inspect them.")

(= (codex:code-mode-exec-description-template)
   "Run JavaScript code to orchestrate/compose tool calls\n- Evaluates the provided JavaScript code in a fresh V8 isolate as an async module.\n- All nested tools are available on the global `tools` object, for example `await tools.exec_command(...)`. Tool names are exposed as normalized JavaScript identifiers, for example `await tools.mcp__ologs__get_profile(...)`.\n- Nested tool methods take either a string or an object as their input argument.\n- Nested tools return either an object or a string, based on the description.\n- Runs raw JavaScript -- no Node, no file system, no network access, no console.\n- Accepts raw JavaScript source text, not JSON, quoted strings, or markdown code fences.\n- You may optionally start the tool input with a first-line pragma like `// @exec: {\"yield_time_ms\": 10000, \"max_output_tokens\": 1000}`.\n- `yield_time_ms` asks `exec` to yield early after that many milliseconds if the script is still running.\n- `max_output_tokens` sets the token budget for direct `exec` results. By default the result is truncated to 10000 tokens.\n- When the JS code is fully evaluated, the isolate's lifetime ends and unawaited promises are silently discarded.\n\n- Global helpers:\n- `exit()`: Immediately ends the current script successfully (like an early return from the top level).\n- `text(value: string | number | boolean | undefined | null)`: Appends a text item. Non-string values are stringified with `JSON.stringify(...)` when possible.\n- `image(imageUrlOrItem: string | { image_url: string; detail?: \"auto\" | \"low\" | \"high\" | \"original\" | null } | ImageContent, detail?: \"auto\" | \"low\" | \"high\" | \"original\" | null)`: Appends an image item. `image_url` can be an HTTPS URL or a base64-encoded `data:` URL. To forward an MCP tool image, pass an individual `ImageContent` block from `result.content`, for example `image(result.content[0])`. MCP image blocks may request detail with `_meta: { \"codex/imageDetail\": \"original\" }`. When provided, the second `detail` argument overrides any detail embedded in the first argument.\n- `store(key: string, value: any)`: stores a serializable value under a string key for later `exec` calls in the same session.\n- `load(key: string)`: returns the stored value for a string key, or `undefined` if it is missing.\n- `notify(value: string | number | boolean | undefined | null)`: immediately injects an extra `custom_tool_call_output` for the current `exec` call. Values are stringified like `text(...)`.\n- `setTimeout(callback: () => void, delayMs?: number)`: schedules a callback to run later and returns a timeout id. Pending timeouts do not keep `exec` alive by themselves; await an explicit promise if you need to wait for one.\n- `clearTimeout(timeoutId?: number)`: cancels a timeout created by `setTimeout`.\n- `ALL_TOOLS`: metadata for the enabled nested tools as `{ name, description }` entries.\n- `yield_control()`: yields the accumulated output to the model immediately while the script keeps running.")

(= (codex:code-mode-render-tool-heading $global-name $raw-name)
   (if (== $global-name $raw-name)
       (str-concat "### `" (str-concat $global-name "`"))
       (str-concat
         "### `"
         (str-concat
           $global-name
           (str-concat "` (`" (str-concat $raw-name "`)"))))))

(= (codex:code-mode-render-tool-reference ())
   "")

(= (codex:code-mode-render-tool-reference $definitions)
   (let ($head $tail) (decons-atom $definitions)
     (case (codex:code-mode-tool-definition-name $head)
       (($name
         (case (codex:normalize-code-mode-identifier $name)
           (($global-name
             (case (codex:code-mode-render-tool-heading $global-name $name)
               (($heading
                 (case (codex:code-mode-tool-definition-description $head)
                   (($raw-description
                     (case (str-trim $raw-description)
                       (($description
                         (case (if (== $description "")
                                   $heading
                                   (str-concat
                                     $heading
                                     (str-concat "\n" $description)))
                           (($section
                             (if (== $tail ())
                                 $section
                                 (case (codex:code-mode-render-tool-reference
                                         $tail)
                                   (($tail-reference
                                     (str-concat
                                       $section
                                       (str-concat
                                         "\n\n"
                                         $tail-reference))))))))))))))))))))))))))

(= (codex:build-code-mode-exec-tool-description
      $enabled-tools
      $namespace-descriptions
      $code-mode-only
      $deferred-tools-available)
   (let $base
     (if $code-mode-only
         (str-concat
           (codex:code-mode-only-preface)
           (str-concat
             "\n\n"
             (codex:code-mode-exec-description-template)))
         (codex:code-mode-exec-description-template))
     (let $with-deferred
       (if $deferred-tools-available
           (str-concat
             $base
             (str-concat
               "\n\n"
               (codex:code-mode-deferred-nested-tools-guidance)))
           $base)
       (if (or (not $code-mode-only)
               (== $enabled-tools ()))
           $with-deferred
           (str-concat
             $with-deferred
             (str-concat
               "\n\n"
               (codex:code-mode-render-tool-reference
                 $enabled-tools)))))))

(= (codex:create-code-mode-exec-tool
      $enabled-tools
      $namespace-descriptions
      $code-mode-only
      $deferred-tools-available)
   (codex:tool-spec-freeform
     (codex:freeform-tool
       (codex:code-mode-public-tool-name)
       (codex:build-code-mode-exec-tool-description
         $enabled-tools
         $namespace-descriptions
         $code-mode-only
         $deferred-tools-available)
       "grammar"
       "lark"
       (codex:code-mode-exec-freeform-grammar))))
