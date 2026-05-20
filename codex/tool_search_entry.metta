; Pure tool-search-entry slice for the Codex port.
;
; Ports deterministic behavior from:
; - openai-codex/codex-rs/core/src/tools/tool_search_entry.rs
;
; Covered in this increment:
; - ToolSearchEntry shape
; - search text construction for MCP and dynamic tools
; - deterministic MCP and dynamic entry ordering
; - limit bucket selection
;
; Required slice-local deviations from Rust, documented for later audit:
; - Rust stores `output` as `LoadableToolSpec` after converting through
;   codex_tools. The full tool spec conversion layer is not ported in this
;   slice yet, so the output field is a source-preserving marker with the
;   same source identity used by those Rust conversions.
; - Rust receives MCP tools from a `HashMap` and sorts by
;   `canonical_tool_name().display()`. This pure CeTTa surface receives a list
;   of simplified MCP info records and performs the same display-key sort.
; - Rust iterates serde_json object keys in the active serde_json map order.
;   This slice iterates the CeTTa `JsonObject` pair order exposed by the local
;   JSON runtime boundary.

!(import! &self json)
!(import! &self list)
!(import! &self str)

(= (codex:tool-search-entry $search-text $output $limit-bucket)
   (CodexToolSearchEntry $search-text $output $limit-bucket))

(= (codex:tool-search-entry-search-text
      (CodexToolSearchEntry $search-text $output $limit-bucket))
   $search-text)

(= (codex:tool-search-entry-output
      (CodexToolSearchEntry $search-text $output $limit-bucket))
   $output)

(= (codex:tool-search-entry-limit-bucket
      (CodexToolSearchEntry $search-text $output $limit-bucket))
   $limit-bucket)

(= (codex:tool-search-output-mcp
      $server-name
      $tool-namespace
      $tool-name
      $connector-name
      $connector-description)
   (CodexToolSearchOutputMcp
     $server-name
     $tool-namespace
     $tool-name
     $connector-name
     $connector-description))

(= (codex:tool-search-output-dynamic $namespace $name)
   (CodexToolSearchOutputDynamic $namespace $name))

(= (codex:mcp-tool $name $title $description $input-schema)
   (CodexMcpTool $name $title $description $input-schema))

(= (codex:mcp-tool-name (CodexMcpTool $name $title $description $input-schema))
   $name)

(= (codex:mcp-tool-title (CodexMcpTool $name $title $description $input-schema))
   $title)

(= (codex:mcp-tool-description
      (CodexMcpTool $name $title $description $input-schema))
   $description)

(= (codex:mcp-tool-input-schema
      (CodexMcpTool $name $title $description $input-schema))
   $input-schema)

(= (codex:tool-search-mcp-info
      $canonical-display
      $server-name
      $callable-namespace
      $callable-name
      $tool
      $connector-name
      $connector-description
      $plugin-display-names)
   (CodexToolSearchMcpInfo
     $canonical-display
     $server-name
     $callable-namespace
     $callable-name
     $tool
     $connector-name
     $connector-description
     $plugin-display-names))

(= (codex:tool-search-mcp-info-canonical-display
      (CodexToolSearchMcpInfo
        $canonical-display
        $server-name
        $callable-namespace
        $callable-name
        $tool
        $connector-name
        $connector-description
        $plugin-display-names))
   $canonical-display)

(= (codex:tool-search-mcp-info-server-name
      (CodexToolSearchMcpInfo
        $canonical-display
        $server-name
        $callable-namespace
        $callable-name
        $tool
        $connector-name
        $connector-description
        $plugin-display-names))
   $server-name)

(= (codex:tool-search-mcp-info-callable-namespace
      (CodexToolSearchMcpInfo
        $canonical-display
        $server-name
        $callable-namespace
        $callable-name
        $tool
        $connector-name
        $connector-description
        $plugin-display-names))
   $callable-namespace)

(= (codex:tool-search-mcp-info-callable-name
      (CodexToolSearchMcpInfo
        $canonical-display
        $server-name
        $callable-namespace
        $callable-name
        $tool
        $connector-name
        $connector-description
        $plugin-display-names))
   $callable-name)

(= (codex:tool-search-mcp-info-tool
      (CodexToolSearchMcpInfo
        $canonical-display
        $server-name
        $callable-namespace
        $callable-name
        $tool
        $connector-name
        $connector-description
        $plugin-display-names))
   $tool)

(= (codex:tool-search-mcp-info-connector-name
      (CodexToolSearchMcpInfo
        $canonical-display
        $server-name
        $callable-namespace
        $callable-name
        $tool
        $connector-name
        $connector-description
        $plugin-display-names))
   $connector-name)

(= (codex:tool-search-mcp-info-connector-description
      (CodexToolSearchMcpInfo
        $canonical-display
        $server-name
        $callable-namespace
        $callable-name
        $tool
        $connector-name
        $connector-description
        $plugin-display-names))
   $connector-description)

(= (codex:tool-search-mcp-info-plugin-display-names
      (CodexToolSearchMcpInfo
        $canonical-display
        $server-name
        $callable-namespace
        $callable-name
        $tool
        $connector-name
        $connector-description
        $plugin-display-names))
   $plugin-display-names)

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

(= (codex:tool-search-optional-original-part $value)
   (case $value
     ((CodexAbsent ())
      ($other
       (let $trimmed (str-trim $other)
         (if (== $trimmed "")
             ()
             ($other)))))))

(= (codex:tool-search-trimmed-list-parts $items)
   (if (== $items ())
       ()
       (let $head (list:first $items)
         (let $tail (list:rest $items)
           (let $trimmed (str-trim $head)
             (let $rest (eval (codex:tool-search-trimmed-list-parts $tail))
               (if (== $trimmed "")
                   $rest
                   (cons-atom $trimmed $rest))))))))

(= (codex:tool-search-json-pair-keys $pairs)
   (if (== $pairs ())
       ()
       (let $head (list:first $pairs)
         (let $tail (list:rest $pairs)
           (case $head
             (((JsonPair $key $value)
               (let $rest (eval (codex:tool-search-json-pair-keys $tail))
                 (cons-atom $key $rest)))))))))

(= (codex:tool-search-json-object-property-keys $schema)
   (case (json-object-get $schema "properties")
     ((Empty ())
      (JsonNull ())
      ((JsonObject $pairs)
       (codex:tool-search-json-pair-keys $pairs))
      ($other ()))))

(= (codex:build-mcp-search-text $info)
   (let $tool (codex:tool-search-mcp-info-tool $info)
     (let $base-parts
       ((codex:tool-search-mcp-info-canonical-display $info)
        (codex:tool-search-mcp-info-callable-name $info)
        (codex:mcp-tool-name $tool)
        (codex:tool-search-mcp-info-server-name $info))
       (str-join
         " "
         (list:append
           $base-parts
           (list:append
             (codex:tool-search-optional-original-part
               (codex:mcp-tool-title $tool))
             (list:append
               (codex:tool-search-optional-original-part
                 (codex:mcp-tool-description $tool))
               (list:append
                 (codex:tool-search-optional-original-part
                   (codex:tool-search-mcp-info-connector-name $info))
                 (list:append
                   (codex:tool-search-optional-original-part
                     (codex:tool-search-mcp-info-connector-description $info))
                   (list:append
                     (codex:tool-search-trimmed-list-parts
                       (codex:tool-search-mcp-info-plugin-display-names $info))
                     (codex:tool-search-json-object-property-keys
                       (codex:mcp-tool-input-schema $tool))))))))))))

(= (codex:tool-search-name-with-spaces $name)
   (str-join " " (str-split "_" $name)))

(= (codex:tool-search-dynamic-namespace-part $namespace)
   (case $namespace
     ((CodexAbsent ())
      ($other ($other)))))

(= (codex:build-dynamic-search-text $tool)
   (let $name (codex:dynamic-tool-spec-name $tool)
     (let $base-parts
       ($name
        (codex:tool-search-name-with-spaces $name)
        (codex:dynamic-tool-spec-description $tool))
       (str-join
         " "
         (list:append
           $base-parts
           (list:append
             (codex:tool-search-dynamic-namespace-part
               (codex:dynamic-tool-spec-namespace $tool))
             (codex:tool-search-json-object-property-keys
               (codex:dynamic-tool-spec-input-schema $tool))))))))

(= (codex:mcp-tool-search-entry $info)
   (codex:tool-search-entry
     (codex:build-mcp-search-text $info)
     (codex:tool-search-output-mcp
       (codex:tool-search-mcp-info-server-name $info)
       (codex:tool-search-mcp-info-callable-namespace $info)
       (codex:tool-search-mcp-info-callable-name $info)
       (codex:tool-search-mcp-info-connector-name $info)
       (codex:tool-search-mcp-info-connector-description $info))
     (codex:tool-search-mcp-info-server-name $info)))

(= (codex:dynamic-tool-search-entry $tool)
   (codex:tool-search-entry
     (codex:build-dynamic-search-text $tool)
     (codex:tool-search-output-dynamic
       (codex:dynamic-tool-spec-namespace $tool)
       (codex:dynamic-tool-spec-name $tool))
     CodexAbsent))

(= (codex:tool-search-mcp-sort-keys $infos)
   (if (== $infos ())
       ()
       (let $head (list:first $infos)
         (let $tail (list:rest $infos)
           (case (codex:tool-search-mcp-info-canonical-display $head)
             (($sort-key
               (let $rest (eval (codex:tool-search-mcp-sort-keys $tail))
                 (cons-atom $sort-key $rest)))))))))

(= (codex:tool-search-take-mcp-by-sort-key $sort-key $infos)
   (if (== $infos ())
       (CodexToolSearchTakeMcpMissing $sort-key)
       (let $head (list:first $infos)
         (let $tail (list:rest $infos)
           (case (codex:tool-search-mcp-info-canonical-display $head)
             (($head-sort-key
               (if (== $sort-key $head-sort-key)
                   (CodexToolSearchTakeMcpFound $head $tail)
                   (case (codex:tool-search-take-mcp-by-sort-key $sort-key $tail)
                     (((CodexToolSearchTakeMcpFound $info $remaining)
                       (CodexToolSearchTakeMcpFound
                         $info
                         (cons-atom $head $remaining)))
                      ((CodexToolSearchTakeMcpMissing $missing-sort-key)
                       (CodexToolSearchTakeMcpMissing $missing-sort-key))))))))))))

(= (codex:tool-search-mcp-infos-from-sorted-keys $infos $keys)
   (if (== $keys ())
       ()
       (let $key (list:first $keys)
         (let $tail-keys (list:rest $keys)
           (case (codex:tool-search-take-mcp-by-sort-key $key $infos)
             (((CodexToolSearchTakeMcpFound $info $remaining-infos)
               (let $tail-infos
                 (eval
                   (codex:tool-search-mcp-infos-from-sorted-keys
                     $remaining-infos
                     $tail-keys))
                 (cons-atom $info $tail-infos)))
              ((CodexToolSearchTakeMcpMissing $missing-sort-key)
               ())))))))

(= (codex:tool-search-sort-mcp-infos $infos)
   (if (== $infos ())
       ()
       (case (eval (codex:tool-search-mcp-sort-keys $infos))
         (($sort-keys
           (case (sort-strings $sort-keys)
             (($sorted-keys
               (codex:tool-search-mcp-infos-from-sorted-keys
                 $infos
                 $sorted-keys)))))))))

(= (codex:tool-search-dynamic-sort-key $tool)
   (case (codex:dynamic-tool-spec-namespace $tool)
     (($namespace
       (case (codex:dynamic-tool-spec-name $tool)
         (($name
           (if (== $namespace CodexAbsent)
               (str-concat "0|" $name)
               (str-concat
                 "1|"
                 (str-concat
                   $namespace
                   (str-concat "|" $name)))))))))))

(= (codex:tool-search-dynamic-sort-keys $tools)
   (if (== $tools ())
       ()
       (let $head (list:first $tools)
         (let $tail (list:rest $tools)
           (case (codex:tool-search-dynamic-sort-key $head)
             (($sort-key
               (let $rest (eval (codex:tool-search-dynamic-sort-keys $tail))
                 (cons-atom $sort-key $rest)))))))))

(= (codex:tool-search-take-dynamic-by-sort-key $sort-key $tools)
   (if (== $tools ())
       (CodexToolSearchTakeDynamicMissing $sort-key)
       (let $head (list:first $tools)
         (let $tail (list:rest $tools)
           (case (codex:tool-search-dynamic-sort-key $head)
             (($head-sort-key
               (if (== $sort-key $head-sort-key)
                   (CodexToolSearchTakeDynamicFound $head $tail)
                   (case (codex:tool-search-take-dynamic-by-sort-key $sort-key $tail)
                     (((CodexToolSearchTakeDynamicFound $tool $remaining)
                       (CodexToolSearchTakeDynamicFound
                         $tool
                         (cons-atom $head $remaining)))
                      ((CodexToolSearchTakeDynamicMissing $missing-sort-key)
                       (CodexToolSearchTakeDynamicMissing $missing-sort-key))))))))))))

(= (codex:tool-search-dynamic-tools-from-sorted-keys $tools $keys)
   (if (== $keys ())
       ()
       (let $key (list:first $keys)
         (let $tail-keys (list:rest $keys)
           (case (codex:tool-search-take-dynamic-by-sort-key $key $tools)
             (((CodexToolSearchTakeDynamicFound $tool $remaining-tools)
               (let $tail-tools
                 (eval
                   (codex:tool-search-dynamic-tools-from-sorted-keys
                     $remaining-tools
                     $tail-keys))
                 (cons-atom $tool $tail-tools)))
              ((CodexToolSearchTakeDynamicMissing $missing-sort-key)
               ())))))))

(= (codex:tool-search-sort-dynamic-tools $tools)
   (if (== $tools ())
       ()
       (case (eval (codex:tool-search-dynamic-sort-keys $tools))
         (($sort-keys
           (case (sort-strings $sort-keys)
             (($sorted-keys
               (codex:tool-search-dynamic-tools-from-sorted-keys
                 $tools
                 $sorted-keys)))))))))

(= (codex:tool-search-mcp-entries-from-infos $infos)
   (if (== $infos ())
       ()
       (let $head (list:first $infos)
         (let $tail (list:rest $infos)
           (case (codex:mcp-tool-search-entry $head)
             (($entry
               (let $rest
                 (eval (codex:tool-search-mcp-entries-from-infos $tail))
                 (cons-atom $entry $rest)))))))))

(= (codex:tool-search-dynamic-entries-from-tools $tools)
   (if (== $tools ())
       ()
       (let $head (list:first $tools)
         (let $tail (list:rest $tools)
           (case (codex:dynamic-tool-search-entry $head)
             (($entry
               (let $rest
                 (eval (codex:tool-search-dynamic-entries-from-tools $tail))
                 (cons-atom $entry $rest)))))))))

(= (codex:tool-search-mcp-list-or-empty $infos)
   (case $infos
     ((CodexAbsent ())
      ($other $other))))

(= (codex:build-tool-search-entries $mcp-infos $dynamic-tools)
   (list:append
     (codex:tool-search-mcp-entries-from-infos
       (codex:tool-search-sort-mcp-infos
         (codex:tool-search-mcp-list-or-empty $mcp-infos)))
     (codex:tool-search-dynamic-entries-from-tools
       (codex:tool-search-sort-dynamic-tools $dynamic-tools))))
