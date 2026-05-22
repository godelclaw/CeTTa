!(register-module! ../codex)
!(import! &self json)
!(import! &self str)
!(import! &self codex:code_mode_tool_definitions)

(= (test:function-spec $name $description)
   (codex:tool-spec-function
     (codex:responses-api-tool
       $name
       $description
       False
       CodexAbsent
       (codex:json-schema-object-with-required-and-additional-properties
         ((JsonPair "order_id" (codex:json-schema-string)))
         ("order_id")
         False)
      (codex:json-schema-object
        ((JsonPair "ok" (codex:json-schema-boolean)))))))

(= (test:freeform-spec)
   (codex:tool-spec-freeform
     (codex:freeform-tool
       "apply_patch"
       "Apply a patch"
       "grammar"
       "lark"
       "start: patch")))

(= (test:namespace-spec)
   (CodexToolSpecNamespace
     (CodexResponsesApiNamespace
       "mcp__memory__"
       "Memory tools"
       ((CodexResponsesApiNamespaceToolFunction
          (codex:responses-api-tool
            "read_graph"
            "Read graph"
            False
            CodexAbsent
            (codex:json-schema-object-with-additional-properties () False)
            CodexAbsent))
        (CodexResponsesApiNamespaceToolFunction
          (codex:responses-api-tool
            "_hidden"
            "Hidden tool"
            False
            CodexAbsent
            (codex:json-schema-object-with-additional-properties () False)
            CodexAbsent))))))

(= (test:contains $haystack $needle)
   (case (str-find $haystack $needle)
     ((Empty False)
      ($index True))))

(= (test:structured-echo-schema)
   (codex:json-schema-object-with-required-and-additional-properties
     ((JsonPair "echo" (codex:json-schema-string)))
     ("echo")
     False))

(= (test:mcp-call-tool-result-schema $structured-content-schema)
   (codex:json-schema-object-with-required-and-additional-properties
     ((JsonPair "content"
        (codex:json-schema-array
          (codex:json-schema-object ())))
      (JsonPair "structuredContent" $structured-content-schema)
      (JsonPair "isError" (codex:json-schema-boolean))
      (JsonPair "_meta" (codex:json-schema-object ())))
     ("content")
     False))

(= (test:mcp-definition $name $raw-name $description $structured-content-schema)
   (codex:code-mode-tool-definition
     $name
     (codex:namespaced-tool-name "mcp__sample__" $raw-name)
     $description
     (codex:code-mode-tool-kind-function)
     (codex:json-schema-object-with-additional-properties () False)
     (test:mcp-call-tool-result-schema $structured-content-schema)))

(= (test:mcp-description)
   (codex:build-code-mode-exec-tool-description
     ((test:mcp-definition
        "mcp__sample__alpha"
        "alpha"
        "First tool"
        (codex:json-schema-object-with-additional-properties () False))
      (test:mcp-definition
        "mcp__sample__beta"
        "beta"
        "Second tool"
        (codex:json-schema-object-with-additional-properties () False)))
     ((codex:code-mode-tool-namespace-description
        "mcp__sample__"
        "mcp__sample"
        "Shared namespace guidance."))
     True
     False))

(= (test:mcp-description-empty-namespace)
   (codex:build-code-mode-exec-tool-description
     ((test:mcp-definition
        "mcp__sample__alpha"
        "alpha"
        "First tool"
        (codex:json-schema-object-with-additional-properties () False)))
     ((codex:code-mode-tool-namespace-description
        "mcp__sample__"
        "mcp__sample"
        ""))
     True
     False))

(= (test:collected-definitions)
   (codex:collect-code-mode-exec-prompt-tool-definitions
     ((test:function-spec "zeta" "Zeta tool")
      (test:function-spec "wait" "Wait tool")
      (test:function-spec "alpha" "Alpha tool")
      (test:function-spec "alpha" "Duplicate alpha")
      (test:freeform-spec)
      (test:namespace-spec)
      (CodexToolSpecToolSearch))))

(= (test:augmented-definition)
   (codex:tool-spec-to-code-mode-tool-definition
     (test:function-spec "lookup_order" "Look up an order")))

!(assertEqualToResult
  (codex:is-code-mode-nested-tool "exec")
  (False))

!(assertEqualToResult
  (codex:is-code-mode-nested-tool "wait")
  (False))

!(assertEqualToResult
  (codex:is-code-mode-nested-tool "exec_command")
  (True))

!(assertEqualToResult
  (codex:code-mode-name-for-tool-name
    (CodexToolName "read_graph" "mcp__memory__"))
  ("mcp__memory__read_graph"))

!(assertEqualToResult
  (codex:code-mode-name-for-tool-name
    (CodexToolName "_hidden" "mcp__memory__"))
  ("mcp__memory___hidden"))

!(assertEqualToResult
  (codex:code-mode-name-for-tool-name
    (CodexToolName "alpha" "mcp__memory__"))
  ("mcp__memory__alpha"))

!(assertEqualToResult
  (codex:normalize-code-mode-identifier "hidden-dynamic-tool")
  ("hidden_dynamic_tool"))

!(assertEqualToResult
  (codex:normalize-code-mode-identifier "1bad-name")
  ("_bad_name"))

!(assertEqualToResult
  (codex:code-mode-tool-definition-name
    (test:augmented-definition))
  ("lookup_order"))

!(assertEqualToResult
  (codex:code-mode-tool-definition-description
    (test:augmented-definition))
  ("Look up an order\n\nexec tool declaration:\n```ts\ndeclare const tools: { lookup_order(args: { order_id: string; }): Promise<{ ok: boolean; }>; };\n```"))

!(assertEqualToResult
  (codex:code-mode-definition-output-type
    (test:mcp-call-tool-result-schema
      (test:structured-echo-schema)))
  ("CallToolResult<{ echo: string; }>"))

!(assertEqualToResult
  (test:contains
    (codex:code-mode-tool-definition-description
      (codex:augment-code-mode-tool-definition
        (test:mcp-definition
          "mcp__sample__echo"
          "echo"
          "Echo tool"
          (test:structured-echo-schema))))
    "Promise<CallToolResult<{ echo: string; }>>;")
  (True))

!(assertEqualToResult
  (codex:tool-spec-to-code-mode-tool-definition
    (CodexToolSpecToolSearch))
  (CodexAbsent))

!(assertEqualToResult
  (codex:code-mode-tool-definition-names
    (test:collected-definitions))
  (("alpha" "apply_patch" "mcp__memory___hidden" "mcp__memory__read_graph" "zeta")))

!(assertEqualToResult
  (codex:code-mode-tool-definition-description
    (list:first
      (codex:collect-code-mode-tool-definitions
        ((test:freeform-spec)))))
  ("Apply a patch\n\nexec tool declaration:\n```ts\ndeclare const tools: { apply_patch(input: string): Promise<unknown>; };\n```"))

!(assertEqualToResult
  (json-stringify
    (codex:tool-spec-json
      (codex:create-code-mode-wait-tool)))
  ("{\"type\":\"function\",\"name\":\"wait\",\"description\":\"Waits on a yielded `exec` cell and returns new output or completion.\\n- Use `wait` only after `exec` returns `Script running with cell ID ...`.\\n- `cell_id` identifies the running `exec` cell to resume.\\n- `yield_time_ms` controls how long to wait for more output before yielding again. If omitted, `wait` uses its default wait timeout.\\n- `max_tokens` limits how much new output this wait call returns.\\n- `terminate: true` stops the running cell instead of waiting for more output.\\n- `wait` returns only the new output since the last yield, or the final completion or termination result for that cell.\\n- If the cell is still running, `wait` may yield again with the same `cell_id`.\\n- If the cell has already finished, `wait` returns the completed result and closes the cell.\",\"strict\":false,\"parameters\":{\"type\":\"object\",\"properties\":{\"cell_id\":{\"type\":\"string\",\"description\":\"Identifier of the running exec cell.\"},\"max_tokens\":{\"type\":\"number\",\"description\":\"Maximum number of output tokens to return for this wait call.\"},\"terminate\":{\"type\":\"boolean\",\"description\":\"Whether to terminate the running exec cell.\"},\"yield_time_ms\":{\"type\":\"number\",\"description\":\"How long to wait (in milliseconds) for more output before yielding again.\"}},\"required\":[\"cell_id\"],\"additionalProperties\":false}}"))

!(assertEqualToResult
  (codex:freeform-tool-format-definition
    (codex:tool-spec-freeform-tool
      (codex:create-code-mode-exec-tool () () False False)))
  ("\nstart: pragma_source | plain_source\npragma_source: PRAGMA_LINE NEWLINE SOURCE\nplain_source: SOURCE\n\nPRAGMA_LINE: /[ \\t]*\\/\\/ @exec:[^\\r\\n]*/\nNEWLINE: /\\r?\\n/\nSOURCE: /[\\s\\S]+/\n"))

!(assertEqualToResult
  (case (str-find
          (codex:code-mode-tool-definition-description
            (list:first
              (codex:collect-code-mode-tool-definitions
                ((test:function-spec "alpha" "Alpha tool")))))
          "declare const tools")
    ((Empty False)
     ($index True)))
  (True))

!(assertEqualToResult
  (test:contains
    (test:mcp-description)
    "## mcp__sample\nShared namespace guidance.")
  (True))

!(assertEqualToResult
  (test:contains
    (test:mcp-description)
    "declare const tools: { mcp__sample__alpha(args: {}): Promise<CallToolResult<{}>>; };")
  (True))

!(assertEqualToResult
  (test:contains
    (test:mcp-description)
    "declare const tools: { mcp__sample__beta(args: {}): Promise<CallToolResult<{}>>; };")
  (True))

!(assertEqualToResult
  (test:contains
    (test:mcp-description)
    "Shared MCP Types:\n```ts\ntype Role = \"user\" | \"assistant\";")
  (True))

!(assertEqualToResult
  (test:contains
    (test:mcp-description)
    "type CallToolResult<TStructured = { [key: string]: unknown }> = {")
  (True))

!(assertEqualToResult
  (test:contains
    (test:mcp-description-empty-namespace)
    "## mcp__sample")
  (False))

!(assertEqualToResult
  (case (str-find
          (codex:freeform-tool-description
            (codex:tool-spec-freeform-tool
              (codex:create-code-mode-exec-tool
                (codex:collect-code-mode-exec-prompt-tool-definitions
                  ((test:function-spec "alpha" "Alpha tool")))
                ()
                True
                False)))
          "Use `exec/wait` tool")
    ((Empty False)
     ($index True)))
  (True))
