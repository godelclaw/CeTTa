; Pure MCP tool approval template slice for the Codex port.
;
; Ports deterministic behavior from:
; - openai-codex/codex-rs/core/src/mcp_tool_approval_templates.rs
;
; Covered in this increment:
; - consequential-tool approval template records
; - schema-version validation for already-parsed template JSON
; - exact server/connector/tool-title matching
; - connector-name placeholder rendering
; - tool parameter display ordering and collision rejection
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust loads `consequential_tool_message_templates.json` through
;   `include_str!` and `LazyLock`, warning on parse/schema errors. This pure
;   CeTTa surface does not perform file IO or tracing yet; it accepts explicit
;   template records or an already-parsed `JsonObject` and returns `Empty` for
;   Rust's `None` cases.
; - Rust's `Option<Value>` result field is represented as `CodexAbsent` for the
;   absent `tool_params` value inside a successful rendered template.
; - Rust receives a serde_json object map. This surface preserves the local
;   `JsonObject` pair order for cloned `tool_params`; remaining display
;   parameters are still sorted by name as in Rust.

!(import! &self json)
!(import! &self list)
!(import! &self str)

(= (codex:consequential-tool-message-templates-schema-version)
   "4")

(= (codex:mcp-tool-approval-connector-name-template-var)
   "{connector_name}")

(= (codex:consequential-tool-message-template
      $connector-id
      $server-name
      $tool-title
      $template
      $template-params)
   (CodexConsequentialToolMessageTemplate
     $connector-id
     $server-name
     $tool-title
     $template
     $template-params))

(= (codex:consequential-tool-message-template-connector-id
      (CodexConsequentialToolMessageTemplate
        $connector-id
        $server-name
        $tool-title
        $template
        $template-params))
   $connector-id)

(= (codex:consequential-tool-message-template-server-name
      (CodexConsequentialToolMessageTemplate
        $connector-id
        $server-name
        $tool-title
        $template
        $template-params))
   $server-name)

(= (codex:consequential-tool-message-template-tool-title
      (CodexConsequentialToolMessageTemplate
        $connector-id
        $server-name
        $tool-title
        $template
        $template-params))
   $tool-title)

(= (codex:consequential-tool-message-template-template
      (CodexConsequentialToolMessageTemplate
        $connector-id
        $server-name
        $tool-title
        $template
        $template-params))
   $template)

(= (codex:consequential-tool-message-template-template-params
      (CodexConsequentialToolMessageTemplate
        $connector-id
        $server-name
        $tool-title
        $template
        $template-params))
   $template-params)

(= (codex:consequential-tool-template-param $name $label)
   (CodexConsequentialToolTemplateParam $name $label))

(= (codex:consequential-tool-template-param-name
      (CodexConsequentialToolTemplateParam $name $label))
   $name)

(= (codex:consequential-tool-template-param-label
      (CodexConsequentialToolTemplateParam $name $label))
   $label)

(= (codex:rendered-mcp-tool-approval-template
      $question
      $elicitation-message
      $tool-params
      $tool-params-display)
   (CodexRenderedMcpToolApprovalTemplate
     $question
     $elicitation-message
     $tool-params
     $tool-params-display))

(= (codex:rendered-mcp-tool-approval-template-question
      (CodexRenderedMcpToolApprovalTemplate
        $question
        $elicitation-message
        $tool-params
        $tool-params-display))
   $question)

(= (codex:rendered-mcp-tool-approval-template-elicitation-message
      (CodexRenderedMcpToolApprovalTemplate
        $question
        $elicitation-message
        $tool-params
        $tool-params-display))
   $elicitation-message)

(= (codex:rendered-mcp-tool-approval-template-tool-params
      (CodexRenderedMcpToolApprovalTemplate
        $question
        $elicitation-message
        $tool-params
        $tool-params-display))
   $tool-params)

(= (codex:rendered-mcp-tool-approval-template-tool-params-display
      (CodexRenderedMcpToolApprovalTemplate
        $question
        $elicitation-message
        $tool-params
        $tool-params-display))
   $tool-params-display)

(= (codex:rendered-mcp-tool-approval-param
      $name
      $value
      $display-name)
   (CodexRenderedMcpToolApprovalParam $name $value $display-name))

(= (codex:rendered-mcp-tool-approval-param-name
      (CodexRenderedMcpToolApprovalParam $name $value $display-name))
   $name)

(= (codex:rendered-mcp-tool-approval-param-value
      (CodexRenderedMcpToolApprovalParam $name $value $display-name))
   $value)

(= (codex:rendered-mcp-tool-approval-param-display-name
      (CodexRenderedMcpToolApprovalParam $name $value $display-name))
   $display-name)

(= (codex:mcp-tool-approval-tool-params-result
      $tool-params
      $display-params)
   (CodexMcpToolApprovalToolParamsResult $tool-params $display-params))

(= (codex:mcp-tool-approval-tool-params-result-tool-params
      (CodexMcpToolApprovalToolParamsResult $tool-params $display-params))
   $tool-params)

(= (codex:mcp-tool-approval-tool-params-result-display-params
      (CodexMcpToolApprovalToolParamsResult $tool-params $display-params))
   $display-params)

(= (codex:mcp-tool-approval-template-param-state
      $handled-names
      $display-names
      $display-params)
   (CodexMcpToolApprovalTemplateParamState
     $handled-names
     $display-names
     $display-params))

(= (codex:mcp-tool-approval-list-contains $items $item)
   (if (== $items ())
       False
       (let $head (list:first $items)
         (let $tail (list:rest $items)
           (if (== $head $item)
               True
               (codex:mcp-tool-approval-list-contains $tail $item))))))

(= (codex:mcp-tool-approval-list-add $items $item)
   (if (codex:mcp-tool-approval-list-contains $items $item)
       $items
       (list:append $items ($item))))

(= (codex:mcp-tool-approval-present-string $value)
   (if (== $value CodexAbsent)
       Empty
       (let $trimmed (str-trim $value)
         (if (== $trimmed "")
             Empty
             $trimmed))))

(= (codex:mcp-tool-approval-replace-all $text $needle $replacement)
   (case (str-find $text $needle)
     ((Empty $text)
      ($index
       (str-concat
         (str-slice $text 0 $index)
         (str-concat
           $replacement
           (codex:mcp-tool-approval-replace-all
             (str-slice
               $text
               (+ $index (str-length $needle))
               (str-length $text))
             $needle
             $replacement)))))))

(= (codex:render-mcp-tool-approval-question-template
      $template
      $connector-name)
   (let $trimmed-template (str-trim $template)
     (if (== $trimmed-template "")
         Empty
         (let $connector-var
           (codex:mcp-tool-approval-connector-name-template-var)
           (case (str-find $trimmed-template $connector-var)
             ((Empty $trimmed-template)
              ($index
               (case (codex:mcp-tool-approval-present-string $connector-name)
                 ((Empty Empty)
                  ($trimmed-connector-name
                   (codex:mcp-tool-approval-replace-all
                     $trimmed-template
                     $connector-var
                     $trimmed-connector-name)))))))))))

(= (codex:mcp-tool-approval-template-matches
      $template
      $server-name
      $connector-id
      $tool-title)
   (and
     (== (codex:consequential-tool-message-template-server-name $template)
         $server-name)
     (and
       (== (codex:consequential-tool-message-template-connector-id $template)
           $connector-id)
       (== (codex:consequential-tool-message-template-tool-title $template)
           $tool-title))))

(= (codex:mcp-tool-approval-find-template
      ()
      $server-name
      $connector-id
      $tool-title)
   Empty)

(= (codex:mcp-tool-approval-find-template
      $templates
      $server-name
      $connector-id
      $tool-title)
   (let $head (list:first $templates)
     (let $tail (list:rest $templates)
       (if (codex:mcp-tool-approval-template-matches
             $head
             $server-name
             $connector-id
             $tool-title)
           $head
           (codex:mcp-tool-approval-find-template
             $tail
             $server-name
             $connector-id
             $tool-title)))))

(= (codex:mcp-tool-approval-json-object-get-present
      (JsonObject $pairs)
      $key)
   (case (json-object-get (JsonObject $pairs) $key)
     ((Empty Empty)
      ($value $value))))

(= (codex:mcp-tool-approval-display-template-params
      ()
      $tool-object
      $display-names
      $handled-names
      $display-params)
   (codex:mcp-tool-approval-template-param-state
     $handled-names
     $display-names
     $display-params))

(= (codex:mcp-tool-approval-display-template-params
      $template-params
      $tool-object
      $display-names
      $handled-names
      $display-params)
   (let $template-param (list:first $template-params)
     (let $tail (list:rest $template-params)
       (let $label
         (str-trim
           (codex:consequential-tool-template-param-label $template-param))
         (if (== $label "")
             Empty
             (let $name
               (codex:consequential-tool-template-param-name $template-param)
               (case (codex:mcp-tool-approval-json-object-get-present
                       $tool-object
                       $name)
                 ((Empty
                   (codex:mcp-tool-approval-display-template-params
                     $tail
                     $tool-object
                     $display-names
                     $handled-names
                     $display-params))
                  ($value
                   (if (codex:mcp-tool-approval-list-contains
                         $display-names
                         $label)
                       Empty
                       (codex:mcp-tool-approval-display-template-params
                         $tail
                         $tool-object
                         (codex:mcp-tool-approval-list-add
                           $display-names
                           $label)
                         (codex:mcp-tool-approval-list-add
                           $handled-names
                           $name)
                         (list:append
                           $display-params
                           ((codex:rendered-mcp-tool-approval-param
                              $name
                              $value
                              $label))))))))))))))

(= (codex:mcp-tool-approval-remaining-param-names
      ()
      $handled-names)
   ())

(= (codex:mcp-tool-approval-remaining-param-names
      $pairs
      $handled-names)
   (let $pair (list:first $pairs)
     (let $tail (list:rest $pairs)
       (case $pair
         (((JsonPair $name $value)
           (let $remaining
             (codex:mcp-tool-approval-remaining-param-names
               $tail
               $handled-names)
             (if (codex:mcp-tool-approval-list-contains
                   $handled-names
                   $name)
                 $remaining
                 (list:append ($name) $remaining)))))))))

(= (codex:mcp-tool-approval-pair-value-by-name () $name)
   Empty)

(= (codex:mcp-tool-approval-pair-value-by-name $pairs $name)
   (let $pair (list:first $pairs)
     (let $tail (list:rest $pairs)
       (case $pair
         (((JsonPair $pair-name $value)
           (if (== $pair-name $name)
               $value
               (codex:mcp-tool-approval-pair-value-by-name
                 $tail
                 $name))))))))

(= (codex:mcp-tool-approval-display-remaining-params
      $pairs
      ()
      $display-names
      $display-params)
   $display-params)

(= (codex:mcp-tool-approval-display-remaining-params
      $pairs
      $remaining-names
      $display-names
      $display-params)
   (let $name (list:first $remaining-names)
     (let $tail (list:rest $remaining-names)
       (if (codex:mcp-tool-approval-list-contains $display-names $name)
           Empty
           (case (codex:mcp-tool-approval-pair-value-by-name $pairs $name)
             ((Empty Empty)
              ($value
               (codex:mcp-tool-approval-display-remaining-params
                 $pairs
                 $tail
                 (codex:mcp-tool-approval-list-add $display-names $name)
                 (list:append
                   $display-params
                   ((codex:rendered-mcp-tool-approval-param
                      $name
                      $value
                      $name)))))))))))

(= (codex:render-mcp-tool-approval-tool-params
      (JsonObject $tool-param-pairs)
      $template-params)
   (case (codex:mcp-tool-approval-display-template-params
           $template-params
           (JsonObject $tool-param-pairs)
           ()
           ()
           ())
     ((Empty Empty)
      ((CodexMcpToolApprovalTemplateParamState
         $handled-names
         $display-names
         $display-params)
       (let $remaining-names
         (codex:mcp-tool-approval-remaining-param-names
           $tool-param-pairs
           $handled-names)
         (case (sort-strings $remaining-names)
           ((() (codex:mcp-tool-approval-tool-params-result
                  (JsonObject $tool-param-pairs)
                  $display-params))
            ($sorted-names
             (case (codex:mcp-tool-approval-display-remaining-params
                     $tool-param-pairs
                     $sorted-names
                     $display-names
                     $display-params)
               ((Empty Empty)
                ($all-display-params
                 (codex:mcp-tool-approval-tool-params-result
                   (JsonObject $tool-param-pairs)
                   $all-display-params))))))))))))

(= (codex:render-mcp-tool-approval-tool-params
      CodexAbsent
      $template-params)
   (codex:mcp-tool-approval-tool-params-result CodexAbsent ()))

(= (codex:render-mcp-tool-approval-tool-params
      (JsonArray $items)
      $template-params)
   Empty)

(= (codex:render-mcp-tool-approval-tool-params
      (JsonString $text)
      $template-params)
   Empty)

(= (codex:render-mcp-tool-approval-tool-params
      (JsonNumber $value)
      $template-params)
   Empty)

(= (codex:render-mcp-tool-approval-tool-params
      (JsonBool $value)
      $template-params)
   Empty)

(= (codex:render-mcp-tool-approval-tool-params
      JsonNull
      $template-params)
   Empty)

(= (codex:render-mcp-tool-approval-template-from-templates
      $templates
      $server-name
      $connector-id
      $connector-name
      $tool-title
      $tool-params)
   (if (== $connector-id CodexAbsent)
       Empty
       (case (codex:mcp-tool-approval-present-string $tool-title)
         ((Empty Empty)
          ($trimmed-tool-title
           (case (codex:mcp-tool-approval-find-template
                   $templates
                   $server-name
                   $connector-id
                   $trimmed-tool-title)
             ((Empty Empty)
              ($template
               (case (codex:render-mcp-tool-approval-question-template
                       (codex:consequential-tool-message-template-template
                         $template)
                       $connector-name)
                 ((Empty Empty)
                  ($elicitation-message
                   (case (codex:render-mcp-tool-approval-tool-params
                           $tool-params
                           (codex:consequential-tool-message-template-template-params
                             $template))
                     ((Empty Empty)
                      ((CodexMcpToolApprovalToolParamsResult
                         $rendered-tool-params
                         $display-params)
                       (codex:rendered-mcp-tool-approval-template
                         $elicitation-message
                         $elicitation-message
                         $rendered-tool-params
                         $display-params)))))))))))))))

(= (codex:mcp-tool-approval-template-param-from-json (JsonObject $pairs))
   (codex:consequential-tool-template-param
     (json-string-value (json-object-get (JsonObject $pairs) "name"))
     (json-string-value (json-object-get (JsonObject $pairs) "label"))))

(= (codex:mcp-tool-approval-template-params-from-json ())
   ())

(= (codex:mcp-tool-approval-template-params-from-json $items)
   (let $head (list:first $items)
     (let $tail (list:rest $items)
       (list:append
         ((codex:mcp-tool-approval-template-param-from-json $head))
         (codex:mcp-tool-approval-template-params-from-json $tail)))))

(= (codex:mcp-tool-approval-template-from-json (JsonObject $pairs))
   (codex:consequential-tool-message-template
     (json-string-value (json-object-get (JsonObject $pairs) "connector_id"))
     (json-string-value (json-object-get (JsonObject $pairs) "server_name"))
     (json-string-value (json-object-get (JsonObject $pairs) "tool_title"))
     (json-string-value (json-object-get (JsonObject $pairs) "template"))
     (codex:mcp-tool-approval-template-params-from-json
       (json-array-items
         (json-object-get (JsonObject $pairs) "template_params")))))

(= (codex:mcp-tool-approval-templates-from-json-items ())
   ())

(= (codex:mcp-tool-approval-templates-from-json-items $items)
   (let $head (list:first $items)
     (let $tail (list:rest $items)
       (list:append
         ((codex:mcp-tool-approval-template-from-json $head))
         (codex:mcp-tool-approval-templates-from-json-items $tail)))))

(= (codex:load-consequential-tool-message-templates-from-json
      (JsonObject $pairs))
   (let $schema-version
     (json-number-value
       (json-object-get (JsonObject $pairs) "schema_version"))
     (if (== $schema-version
             (codex:consequential-tool-message-templates-schema-version))
         (codex:mcp-tool-approval-templates-from-json-items
           (json-array-items
             (json-object-get (JsonObject $pairs) "templates")))
         Empty)))
