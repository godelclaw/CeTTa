; Rust-faithful tool discovery and suggestion helper slice.
;
; This ports deterministic behavior from:
; - openai-codex/codex-rs/tools/src/tool_discovery.rs
;   - DiscoverableToolType / DiscoverableToolAction wire names
;   - DiscoverableTool and DiscoverablePluginInfo helper surface
;   - filter_tool_suggest_discoverable_tools_for_client
;   - create_tool_search_tool
;   - create_tool_suggest_tool
;   - collect_tool_suggest_entries
;   - format_discoverable_tools / plugin_summary
; - openai-codex/codex-rs/tools/src/tool_suggest.rs
;   - ToolSuggestArgs / ToolSuggestResult / ToolSuggestMeta shapes
;   - build_tool_suggestion_elicitation_request
;   - verified_connector_suggestion_completed
;   - all_suggested_connectors_picked_up
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust uses codex_app_server_protocol::AppInfo for connector records. The
;   existing CeTTa AppInfo surface intentionally carries fewer fields, so this
;   slice exposes a local discoverable connector record with the Rust fields
;   consumed by these helpers: id, name, description, install_url,
;   is_accessible, and is_enabled.

!(import! &self json)
!(import! &self list)
!(import! &self mcp_tool_call)
!(import! &self str)
!(import! &self tool_registry_plan)

(= (codex:discoverable-tool-type-connector)
   "connector")

(= (codex:discoverable-tool-type-plugin)
   "plugin")

(= (codex:discoverable-tool-action-install)
   "install")

(= (codex:discoverable-tool-action-enable)
   "enable")

(= (codex:tool-suggest-approval-kind-value)
   "tool_suggestion")

(= (codex:tool-suggest-tool-name)
   "tool_suggest")

(= (codex:tool-search-tool-name)
   "tool_search")

(= (codex:tool-search-default-limit)
   8)

(= (codex:tool-discovery-tui-client-name)
   "codex-tui")

(= (codex:tool-search-source-info $name $description)
   (CodexToolSearchSourceInfo $name $description))

(= (codex:tool-search-source-info-name
      (CodexToolSearchSourceInfo $name $description))
   $name)

(= (codex:tool-search-source-info-description
      (CodexToolSearchSourceInfo $name $description))
   $description)

(= (codex:tool-search-source-description-entry $name $description)
   (CodexToolSearchSourceDescriptionEntry $name $description))

(= (codex:tool-search-source-description-entry-name
      (CodexToolSearchSourceDescriptionEntry $name $description))
   $name)

(= (codex:tool-search-source-description-entry-description
      (CodexToolSearchSourceDescriptionEntry $name $description))
   $description)

(= (codex:discoverable-connector-info
      $id
      $name
      $description
      $install-url
      $is-accessible
      $is-enabled)
   (CodexDiscoverableConnectorInfo
     $id
     $name
     $description
     $install-url
     $is-accessible
     $is-enabled))

(= (codex:discoverable-connector-info-id
      (CodexDiscoverableConnectorInfo
        $id
        $name
        $description
        $install-url
        $is-accessible
        $is-enabled))
   $id)

(= (codex:discoverable-connector-info-name
      (CodexDiscoverableConnectorInfo
        $id
        $name
        $description
        $install-url
        $is-accessible
        $is-enabled))
   $name)

(= (codex:discoverable-connector-info-description
      (CodexDiscoverableConnectorInfo
        $id
        $name
        $description
        $install-url
        $is-accessible
        $is-enabled))
   $description)

(= (codex:discoverable-connector-info-install-url
      (CodexDiscoverableConnectorInfo
        $id
        $name
        $description
        $install-url
        $is-accessible
        $is-enabled))
   $install-url)

(= (codex:discoverable-connector-info-is-accessible
      (CodexDiscoverableConnectorInfo
        $id
        $name
        $description
        $install-url
        $is-accessible
        $is-enabled))
   $is-accessible)

(= (codex:discoverable-connector-info-is-enabled
      (CodexDiscoverableConnectorInfo
        $id
        $name
        $description
        $install-url
        $is-accessible
        $is-enabled))
   $is-enabled)

(= (codex:discoverable-plugin-info
      $id
      $name
      $description
      $has-skills
      $mcp-server-names
      $app-connector-ids)
   (CodexDiscoverablePluginInfo
     $id
     $name
     $description
     $has-skills
     $mcp-server-names
     $app-connector-ids))

(= (codex:discoverable-plugin-info-id
      (CodexDiscoverablePluginInfo
        $id
        $name
        $description
        $has-skills
        $mcp-server-names
        $app-connector-ids))
   $id)

(= (codex:discoverable-plugin-info-name
      (CodexDiscoverablePluginInfo
        $id
        $name
        $description
        $has-skills
        $mcp-server-names
        $app-connector-ids))
   $name)

(= (codex:discoverable-plugin-info-description
      (CodexDiscoverablePluginInfo
        $id
        $name
        $description
        $has-skills
        $mcp-server-names
        $app-connector-ids))
   $description)

(= (codex:discoverable-plugin-info-has-skills
      (CodexDiscoverablePluginInfo
        $id
        $name
        $description
        $has-skills
        $mcp-server-names
        $app-connector-ids))
   $has-skills)

(= (codex:discoverable-plugin-info-mcp-server-names
      (CodexDiscoverablePluginInfo
        $id
        $name
        $description
        $has-skills
        $mcp-server-names
        $app-connector-ids))
   $mcp-server-names)

(= (codex:discoverable-plugin-info-app-connector-ids
      (CodexDiscoverablePluginInfo
        $id
        $name
        $description
        $has-skills
        $mcp-server-names
        $app-connector-ids))
   $app-connector-ids)

(= (codex:discoverable-tool-connector $connector)
   (CodexDiscoverableToolConnector $connector))

(= (codex:discoverable-tool-plugin $plugin)
   (CodexDiscoverableToolPlugin $plugin))

(= (codex:discoverable-tool-type
      (CodexDiscoverableToolConnector $connector))
   (codex:discoverable-tool-type-connector))

(= (codex:discoverable-tool-type
      (CodexDiscoverableToolPlugin $plugin))
   (codex:discoverable-tool-type-plugin))

(= (codex:discoverable-tool-id
      (CodexDiscoverableToolConnector $connector))
   (codex:discoverable-connector-info-id $connector))

(= (codex:discoverable-tool-id
      (CodexDiscoverableToolPlugin $plugin))
   (codex:discoverable-plugin-info-id $plugin))

(= (codex:discoverable-tool-name
      (CodexDiscoverableToolConnector $connector))
   (codex:discoverable-connector-info-name $connector))

(= (codex:discoverable-tool-name
      (CodexDiscoverableToolPlugin $plugin))
   (codex:discoverable-plugin-info-name $plugin))

(= (codex:discoverable-tool-description
      (CodexDiscoverableToolConnector $connector))
   (codex:discoverable-connector-info-description $connector))

(= (codex:discoverable-tool-description
      (CodexDiscoverableToolPlugin $plugin))
   (codex:discoverable-plugin-info-description $plugin))

(= (codex:discoverable-tool-install-url
      (CodexDiscoverableToolConnector $connector))
   (codex:discoverable-connector-info-install-url $connector))

(= (codex:discoverable-tool-install-url
      (CodexDiscoverableToolPlugin $plugin))
   CodexAbsent)

(= (codex:is-discoverable-tool-plugin
      (CodexDiscoverableToolPlugin $plugin))
   True)

(= (codex:is-discoverable-tool-plugin
      (CodexDiscoverableToolConnector $connector))
   False)

(= (codex:filter-tool-suggest-discoverable-tools-for-client-from
      ()
      $app-server-client-name)
   ())

(= (codex:filter-tool-suggest-discoverable-tools-for-client-from
      $discoverable-tools
      $app-server-client-name)
   (let ($head $tail) (decons-atom $discoverable-tools)
     (case (codex:filter-tool-suggest-discoverable-tools-for-client-from
             $tail
             $app-server-client-name)
       (($filtered-tail
         (if (and
               (== $app-server-client-name (codex:tool-discovery-tui-client-name))
               (codex:is-discoverable-tool-plugin $head))
             $filtered-tail
             (cons-atom $head $filtered-tail)))))))

(= (codex:filter-tool-suggest-discoverable-tools-for-client
      $discoverable-tools
      $app-server-client-name)
   (codex:filter-tool-suggest-discoverable-tools-for-client-from
     $discoverable-tools
     $app-server-client-name))

(= (codex:tool-suggest-entry
      $id
      $name
      $description
      $tool-type
      $has-skills
      $mcp-server-names
      $app-connector-ids)
   (CodexToolSuggestEntry
     $id
     $name
     $description
     $tool-type
     $has-skills
     $mcp-server-names
     $app-connector-ids))

(= (codex:tool-suggest-entry-id
      (CodexToolSuggestEntry
        $id
        $name
        $description
        $tool-type
        $has-skills
        $mcp-server-names
        $app-connector-ids))
   $id)

(= (codex:tool-suggest-entry-name
      (CodexToolSuggestEntry
        $id
        $name
        $description
        $tool-type
        $has-skills
        $mcp-server-names
        $app-connector-ids))
   $name)

(= (codex:tool-suggest-entry-description
      (CodexToolSuggestEntry
        $id
        $name
        $description
        $tool-type
        $has-skills
        $mcp-server-names
        $app-connector-ids))
   $description)

(= (codex:tool-suggest-entry-tool-type
      (CodexToolSuggestEntry
        $id
        $name
        $description
        $tool-type
        $has-skills
        $mcp-server-names
        $app-connector-ids))
   $tool-type)

(= (codex:tool-suggest-entry-has-skills
      (CodexToolSuggestEntry
        $id
        $name
        $description
        $tool-type
        $has-skills
        $mcp-server-names
        $app-connector-ids))
   $has-skills)

(= (codex:tool-suggest-entry-mcp-server-names
      (CodexToolSuggestEntry
        $id
        $name
        $description
        $tool-type
        $has-skills
        $mcp-server-names
        $app-connector-ids))
   $mcp-server-names)

(= (codex:tool-suggest-entry-app-connector-ids
      (CodexToolSuggestEntry
        $id
        $name
        $description
        $tool-type
        $has-skills
        $mcp-server-names
        $app-connector-ids))
   $app-connector-ids)

(= (codex:collect-tool-suggest-entries ())
   ())

(= (codex:collect-tool-suggest-entries $discoverable-tools)
   (let ($head $tail) (decons-atom $discoverable-tools)
     (case (codex:collect-tool-suggest-entries $tail)
       (($tail-entries
         (case $head
           (((CodexDiscoverableToolConnector $connector)
             (cons-atom
               (codex:tool-suggest-entry
                 (codex:discoverable-connector-info-id $connector)
                 (codex:discoverable-connector-info-name $connector)
                 (codex:discoverable-connector-info-description $connector)
                 (codex:discoverable-tool-type-connector)
                 False
                 ()
                 ())
               $tail-entries))
            ((CodexDiscoverableToolPlugin $plugin)
             (cons-atom
               (codex:tool-suggest-entry
                 (codex:discoverable-plugin-info-id $plugin)
                 (codex:discoverable-plugin-info-name $plugin)
                 (codex:discoverable-plugin-info-description $plugin)
                 (codex:discoverable-tool-type-plugin)
                 (codex:discoverable-plugin-info-has-skills $plugin)
                 (codex:discoverable-plugin-info-mcp-server-names $plugin)
                 (codex:discoverable-plugin-info-app-connector-ids $plugin))
               $tail-entries)))))))))

(= (codex:tool-discovery-string-le $left $right)
   (case (sort-strings ($left $right))
     ((($first $second)
       (== $first $left)))))

(= (codex:tool-suggest-entry-le $left $right)
   (let $left-name (codex:tool-suggest-entry-name $left)
     (let $right-name (codex:tool-suggest-entry-name $right)
       (if (== $left-name $right-name)
           (codex:tool-discovery-string-le
             (codex:tool-suggest-entry-id $left)
             (codex:tool-suggest-entry-id $right))
           (codex:tool-discovery-string-le $left-name $right-name)))))

(= (codex:insert-tool-suggest-entry-sorted $entry ())
   ($entry))

(= (codex:insert-tool-suggest-entry-sorted $entry $sorted)
   (let ($head $tail) (decons-atom $sorted)
     (if (codex:tool-suggest-entry-le $entry $head)
         (cons-atom $entry $sorted)
         (case (codex:insert-tool-suggest-entry-sorted $entry $tail)
           (($inserted-tail
             (cons-atom $head $inserted-tail)))))))

(= (codex:sort-tool-suggest-entries ())
   ())

(= (codex:sort-tool-suggest-entries $entries)
   (let ($head $tail) (decons-atom $entries)
     (case (codex:sort-tool-suggest-entries $tail)
       (($sorted-tail
         (codex:insert-tool-suggest-entry-sorted $head $sorted-tail))))))

(= (codex:tool-suggest-entry-ids ())
   ())

(= (codex:tool-suggest-entry-ids $entries)
   (let ($head $tail) (decons-atom $entries)
     (case (codex:tool-suggest-entry-ids $tail)
       (($tail-ids
         (cons-atom
           (codex:tool-suggest-entry-id $head)
           $tail-ids))))))

(= (codex:tool-search-source-description-merged
      $existing-description
      $source-description)
   (if (== $existing-description CodexAbsent)
       $source-description
       $existing-description))

(= (codex:tool-search-source-descriptions-upsert
      $entries
      $source)
   (if (== $entries ())
       ((codex:tool-search-source-description-entry
          (codex:tool-search-source-info-name $source)
          (codex:tool-search-source-info-description $source)))
       (let ($head $tail) (decons-atom $entries)
         (if (== (codex:tool-search-source-description-entry-name $head)
                 (codex:tool-search-source-info-name $source))
             (cons-atom
               (codex:tool-search-source-description-entry
                 (codex:tool-search-source-description-entry-name $head)
                 (codex:tool-search-source-description-merged
                   (codex:tool-search-source-description-entry-description
                     $head)
                   (codex:tool-search-source-info-description $source)))
               $tail)
             (case (codex:tool-search-source-descriptions-upsert
                     $tail
                     $source)
               (($updated-tail
                 (cons-atom $head $updated-tail))))))))

(= (codex:tool-search-source-descriptions-acc $sources $entries)
   (if (== $sources ())
       $entries
       (let ($head $tail) (decons-atom $sources)
         (codex:tool-search-source-descriptions-acc
           $tail
           (codex:tool-search-source-descriptions-upsert
             $entries
             $head)))))

(= (codex:tool-search-source-descriptions $sources)
   (codex:tool-search-source-descriptions-acc $sources ()))

(= (codex:tool-search-source-description-entry-le $left $right)
   (codex:tool-discovery-string-le
     (codex:tool-search-source-description-entry-name $left)
     (codex:tool-search-source-description-entry-name $right)))

(= (codex:insert-tool-search-source-description-sorted
      $entry
      $sorted)
   (if (== $sorted ())
       ($entry)
       (let ($head $tail) (decons-atom $sorted)
         (if (codex:tool-search-source-description-entry-le $entry $head)
             (cons-atom $entry $sorted)
             (case (codex:insert-tool-search-source-description-sorted
                     $entry
                     $tail)
               (($inserted-tail
                 (cons-atom $head $inserted-tail))))))))

(= (codex:sort-tool-search-source-descriptions $entries)
   (if (== $entries ())
       ()
       (let ($head $tail) (decons-atom $entries)
         (case (codex:sort-tool-search-source-descriptions $tail)
           (($sorted-tail
             (codex:insert-tool-search-source-description-sorted
               $head
               $sorted-tail)))))))

(= (codex:format-tool-search-source-description
      (CodexToolSearchSourceDescriptionEntry $name $description))
   (if (== $description CodexAbsent)
       (str-concat "- " $name)
       (str-concat
         "- "
         (str-concat
           $name
           (str-concat ": " $description)))))

(= (codex:format-tool-search-source-descriptions $entries)
   (if (== $entries ())
       ()
       (let ($head $tail) (decons-atom $entries)
         (case (codex:format-tool-search-source-descriptions $tail)
           (($tail-lines
             (cons-atom
               (codex:format-tool-search-source-description $head)
               $tail-lines)))))))

(= (codex:tool-search-source-descriptions-text $sources)
   (case (codex:tool-search-source-descriptions $sources)
     (($source-descriptions
       (case (codex:sort-tool-search-source-descriptions
               $source-descriptions)
         ((()
           "None currently enabled.")
          ($sorted-sources
           (str-join
             "\n"
             (codex:format-tool-search-source-descriptions
               $sorted-sources)))))))))

(= (codex:tool-search-tool-description $source-descriptions)
   (str-concat
     "# Tool discovery\n\nSearches over deferred tool metadata with BM25 and exposes matching tools for the next model call.\n\nYou have access to tools from the following sources:\n"
     (str-concat
       $source-descriptions
       (str-concat
         "\nSome of the tools may not have been provided to you upfront, and you should use this tool (`"
         (str-concat
           (codex:tool-search-tool-name)
           (str-concat
             "`) to search for the required tools. For MCP tool discovery, always use `"
             (str-concat
               (codex:tool-search-tool-name)
               "` instead of `list_mcp_resources` or `list_mcp_resource_templates`.")))))))

(= (codex:tool-search-tool-parameters-schema $default-limit)
   (codex:json-schema-object-with-required-and-additional-properties
     ((JsonPair "limit"
        (codex:json-schema-number
          (format-args
            "Maximum number of tools to return (defaults to {})."
            ($default-limit))))
      (JsonPair "query"
        (codex:json-schema-string
          "Search query for deferred tools.")))
     ("query")
     False))

(= (codex:create-tool-search-tool
      $searchable-sources
      $default-limit)
   (case (codex:tool-search-source-descriptions-text $searchable-sources)
     (($source-descriptions
       (codex:tool-spec-tool-search
         "client"
         (codex:tool-search-tool-description $source-descriptions)
         (codex:tool-search-tool-parameters-schema $default-limit))))))

(= (codex:tool-suggest-plugin-summary-details
      $has-skills
      $mcp-server-names
      $app-connector-ids)
   (list:append
     (if $has-skills ("skills") ())
     (list:append
       (if (== $mcp-server-names ())
           ()
           ((str-concat
              "MCP servers: "
              (str-join ", " $mcp-server-names))))
       (if (== $app-connector-ids ())
           ()
           ((str-concat
              "app connectors: "
              (str-join ", " $app-connector-ids)))))))

(= (codex:tool-suggest-plugin-summary $tool)
   (case (codex:tool-suggest-plugin-summary-details
           (codex:tool-suggest-entry-has-skills $tool)
           (codex:tool-suggest-entry-mcp-server-names $tool)
           (codex:tool-suggest-entry-app-connector-ids $tool))
     ((()
       "No description provided.")
      ($details
       (str-join "; " $details)))))

(= (codex:tool-suggest-entry-description-or-fallback $tool)
   (case (codex:tool-suggest-entry-description $tool)
     ((CodexAbsent
       (if (== (codex:tool-suggest-entry-tool-type $tool)
               (codex:discoverable-tool-type-connector))
           "No description provided."
           (codex:tool-suggest-plugin-summary $tool)))
      ($description
       (case (str-trim $description)
         ((""
           (if (== (codex:tool-suggest-entry-tool-type $tool)
                   (codex:discoverable-tool-type-connector))
               "No description provided."
               (codex:tool-suggest-plugin-summary $tool)))
          ($trimmed $trimmed)))))))

(= (codex:format-tool-suggest-entry $tool)
   (str-concat
     "- "
     (str-concat
       (codex:tool-suggest-entry-name $tool)
       (str-concat
         " (id: `"
         (str-concat
           (codex:tool-suggest-entry-id $tool)
           (str-concat
             "`, type: "
             (str-concat
               (codex:tool-suggest-entry-tool-type $tool)
               (str-concat
                 ", action: install): "
                 (codex:tool-suggest-entry-description-or-fallback
                   $tool)))))))))

(= (codex:format-tool-suggest-entries ())
   ())

(= (codex:format-tool-suggest-entries $entries)
   (let ($head $tail) (decons-atom $entries)
     (case (codex:format-tool-suggest-entries $tail)
       (($tail-lines
         (cons-atom
           (codex:format-tool-suggest-entry $head)
           $tail-lines))))))

(= (codex:format-discoverable-tools $discoverable-tools)
   (case (codex:sort-tool-suggest-entries $discoverable-tools)
     (($sorted-tools
       (str-join
         "\n"
         (codex:format-tool-suggest-entries $sorted-tools))))))

(= (codex:tool-suggest-tool-description $discoverable-tool-lines)
   (str-concat
     "# Tool suggestion discovery\n\nSuggests a missing connector in an installed plugin, or in narrower cases a not installed but discoverable plugin, when the user clearly wants a capability that is not currently available in the active `tools` list.\n\nUse this ONLY when:\n- You've already tried to find a matching available tool for the user's request but couldn't find a good match. This includes `"
     (str-concat
       (codex:tool-search-tool-name)
       (str-concat
         "` (if available) and other means.\n- For connectors/apps that are not installed but needed for an installed plugin, suggest to install them if the task requirements match precisely.\n- For plugins that are not installed but discoverable, only suggest discoverable and installable plugins when the user's intent very explicitly and unambiguously matches that plugin itself. Do not suggest a plugin just because one of its connectors or capabilities seems relevant.\n\nTool suggestions should only use the discoverable tools listed here. DO NOT explore or recommend tools that are not on this list.\n\nDiscoverable tools:\n"
         (str-concat
           $discoverable-tool-lines
           (str-concat
             "\n\nWorkflow:\n\n1. Ensure all possible means have been exhausted to find an existing available tool but none of them matches the request intent.\n2. Match the user's request against the discoverable tools list above. Apply the stricter explicit-and-unambiguous rule for *discoverable tools* like plugin install suggestions; *missing tools* like connector install suggestions continue to use the normal clear-fit standard.\n3. If one tool clearly fits, call `"
             (str-concat
               (codex:tool-suggest-tool-name)
               (str-concat
                 "` with:\n   - `tool_type`: `connector` or `plugin`\n   - `action_type`: `install` or `enable`\n   - `tool_id`: exact id from the discoverable tools list above\n   - `suggest_reason`: concise one-line user-facing reason this tool can help with the current request\n4. After the suggestion flow completes:\n   - if the user finished the install or enable flow, continue by searching again or using the newly available tool\n   - if the user did not finish, continue without that tool, and don't suggest that tool again unless the user explicitly asks for it."
                 ""))))))))

(= (codex:tool-suggest-tool-parameters-schema $discoverable-tool-ids)
   (codex:json-schema-object-with-required-and-additional-properties
     ((JsonPair "action_type"
        (codex:json-schema-string
          "Suggested action for the tool. Use \"install\" or \"enable\"."))
      (JsonPair "suggest_reason"
        (codex:json-schema-string
          "Concise one-line user-facing reason why this tool can help with the current request."))
      (JsonPair "tool_id"
        (codex:json-schema-string
          (str-concat
            "Connector or plugin id to suggest. Must be one of: "
            (str-concat $discoverable-tool-ids "."))))
      (JsonPair "tool_type"
        (codex:json-schema-string
          "Type of discoverable tool to suggest. Use \"connector\" or \"plugin\".")))
     ("tool_type" "action_type" "tool_id" "suggest_reason")
     False))

(= (codex:create-tool-suggest-tool $discoverable-tools)
   (case (codex:tool-suggest-entry-ids $discoverable-tools)
     (($ids
       (case (codex:format-discoverable-tools $discoverable-tools)
         (($discoverable-tool-lines
           (codex:tool-spec-function
             (codex:responses-api-tool
               (codex:tool-suggest-tool-name)
               (codex:tool-suggest-tool-description $discoverable-tool-lines)
               False
               CodexAbsent
               (codex:tool-suggest-tool-parameters-schema
                 (str-join ", " $ids))
               CodexAbsent)))))))))

(= (codex:tool-suggest-args
      $tool-type
      $action-type
      $tool-id
      $suggest-reason)
   (CodexToolSuggestArgs
     $tool-type
     $action-type
     $tool-id
     $suggest-reason))

(= (codex:tool-suggest-args-tool-type
      (CodexToolSuggestArgs
        $tool-type
        $action-type
        $tool-id
        $suggest-reason))
   $tool-type)

(= (codex:tool-suggest-args-action-type
      (CodexToolSuggestArgs
        $tool-type
        $action-type
        $tool-id
        $suggest-reason))
   $action-type)

(= (codex:tool-suggest-args-tool-id
      (CodexToolSuggestArgs
        $tool-type
        $action-type
        $tool-id
        $suggest-reason))
   $tool-id)

(= (codex:tool-suggest-args-suggest-reason
      (CodexToolSuggestArgs
        $tool-type
        $action-type
        $tool-id
        $suggest-reason))
   $suggest-reason)

(= (codex:tool-suggest-meta
      $tool-type
      $action-type
      $suggest-reason
      $tool-id
      $tool-name
      $install-url)
   (CodexToolSuggestMeta
     $tool-type
     $action-type
     $suggest-reason
     $tool-id
     $tool-name
     $install-url))

(= (codex:tool-suggest-meta-json
      (CodexToolSuggestMeta
        $tool-type
        $action-type
        $suggest-reason
        $tool-id
        $tool-name
        $install-url))
   (if (== $install-url CodexAbsent)
       (JsonObject
         ((JsonPair
            "codex_approval_kind"
            (JsonString (codex:tool-suggest-approval-kind-value)))
          (JsonPair "tool_type" (JsonString $tool-type))
          (JsonPair "suggest_type" (JsonString $action-type))
          (JsonPair "suggest_reason" (JsonString $suggest-reason))
          (JsonPair "tool_id" (JsonString $tool-id))
          (JsonPair "tool_name" (JsonString $tool-name))))
       (JsonObject
         ((JsonPair
            "codex_approval_kind"
            (JsonString (codex:tool-suggest-approval-kind-value)))
          (JsonPair "tool_type" (JsonString $tool-type))
          (JsonPair "suggest_type" (JsonString $action-type))
          (JsonPair "suggest_reason" (JsonString $suggest-reason))
          (JsonPair "tool_id" (JsonString $tool-id))
          (JsonPair "tool_name" (JsonString $tool-name))
          (JsonPair "install_url" (JsonString $install-url))))))

(= (codex:build-tool-suggestion-meta
      $tool-type
      $action-type
      $suggest-reason
      $tool-id
      $tool-name
      $install-url)
   (codex:tool-suggest-meta
     $tool-type
     $action-type
     $suggest-reason
     $tool-id
     $tool-name
     $install-url))

(= (codex:build-tool-suggestion-elicitation-request
      $server-name
      $thread-id
      $turn-id
      $args
      $suggest-reason
      $tool)
   (case (codex:discoverable-tool-name $tool)
     (($tool-name
       (case (codex:discoverable-tool-install-url $tool)
         (($install-url
           (codex:mcp-server-elicitation-request-params
             $thread-id
             $turn-id
             $server-name
             (codex:mcp-server-elicitation-request-form
               (codex:tool-suggest-meta-json
                 (codex:build-tool-suggestion-meta
                   (codex:tool-suggest-args-tool-type $args)
                   (codex:tool-suggest-args-action-type $args)
                   $suggest-reason
                   (codex:discoverable-tool-id $tool)
                   $tool-name
                   $install-url))
               $suggest-reason
               (codex:mcp-tool-approval-elicitation-object-schema))))))))))

(= (codex:verified-connector-suggestion-completed
      $tool-id
      ())
   False)

(= (codex:verified-connector-suggestion-completed
      $tool-id
      $accessible-connectors)
   (let ($head $tail) (decons-atom $accessible-connectors)
     (if (== (codex:discoverable-connector-info-id $head) $tool-id)
         (codex:discoverable-connector-info-is-accessible $head)
         (codex:verified-connector-suggestion-completed
           $tool-id
           $tail))))

(= (codex:all-suggested-connectors-picked-up
      ()
      $accessible-connectors)
   True)

(= (codex:all-suggested-connectors-picked-up
      $expected-connector-ids
      $accessible-connectors)
   (let ($head $tail) (decons-atom $expected-connector-ids)
     (and
       (codex:verified-connector-suggestion-completed
         $head
         $accessible-connectors)
       (codex:all-suggested-connectors-picked-up
         $tail
         $accessible-connectors))))

(= (codex:tool-suggest-result
      $completed
      $user-confirmed
      $tool-type
      $action-type
      $tool-id
      $tool-name
      $suggest-reason)
   (CodexToolSuggestResult
     $completed
     $user-confirmed
     $tool-type
     $action-type
     $tool-id
     $tool-name
     $suggest-reason))

(= (codex:tool-suggest-result-json
      (CodexToolSuggestResult
        $completed
        $user-confirmed
        $tool-type
        $action-type
        $tool-id
        $tool-name
        $suggest-reason))
   (JsonObject
     ((JsonPair "completed" (JsonBool $completed))
      (JsonPair "user_confirmed" (JsonBool $user-confirmed))
      (JsonPair "tool_type" (JsonString $tool-type))
      (JsonPair "action_type" (JsonString $action-type))
      (JsonPair "tool_id" (JsonString $tool-id))
      (JsonPair "tool_name" (JsonString $tool-name))
      (JsonPair "suggest_reason" (JsonString $suggest-reason)))))
