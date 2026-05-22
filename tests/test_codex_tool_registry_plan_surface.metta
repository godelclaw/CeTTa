!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:dynamic_tools)
!(import! &self codex:js_repl)
!(import! &self codex:tool_config)
!(import! &self codex:tool_registry_plan)

(= (codex-tool-config-model)
   (codex:tool-config-model-info
     (codex:config-shell-tool-type-unified-exec)
     CodexAbsent
     ()
     False))

(= (codex-tool-config-list-dir-model)
   (codex:tool-config-model-info
     (codex:config-shell-tool-type-unified-exec)
     CodexAbsent
     ("list_dir")
     False))

(= (codex-tool-config-view-image-original-model)
   (codex:tool-config-model-info
     (codex:config-shell-tool-type-unified-exec)
     CodexAbsent
     ()
     True))

(= (codex-tool-config-default-features)
   (codex:tool-config-features
     True
     True
     False
     True
     False
     False
     False))

(= (codex-tool-config-request-permissions-features)
   (codex:tool-config-features
     True
     True
     False
     True
     True
     True
     False))

(= (codex-tool-config-js-repl-features)
   (codex:tool-config-features-with-js-repl
     True
     True
     False
     True
     False
     False
     True
     False
     False))

(= (codex-tool-registry-default-config)
   (codex:tools-config-new
     (codex:tools-config-new-params
       (codex-tool-config-model)
       (codex-tool-config-default-features)
       False
       (codex:tool-config-sandbox-policy-danger-full-access)
       (codex:windows-sandbox-level-disabled))))

(= (codex-tool-registry-request-permissions-config)
   (codex:tools-config-new
     (codex:tools-config-new-params
       (codex-tool-config-model)
       (codex-tool-config-request-permissions-features)
       False
       (codex:tool-config-sandbox-policy-danger-full-access)
       (codex:windows-sandbox-level-disabled))))

(= (codex-tool-registry-js-repl-config)
   (codex:tools-config-new
     (codex:tools-config-new-params
       (codex-tool-config-model)
       (codex-tool-config-js-repl-features)
       False
       (codex:tool-config-sandbox-policy-danger-full-access)
       (codex:windows-sandbox-level-disabled))))

(= (codex-tool-registry-list-dir-config)
   (codex:tools-config-new
     (codex:tools-config-new-params
       (codex-tool-config-list-dir-model)
       (codex-tool-config-default-features)
       False
       (codex:tool-config-sandbox-policy-danger-full-access)
       (codex:windows-sandbox-level-disabled))))

(= (codex-tool-registry-view-image-original-config)
   (codex:tools-config-new
     (codex:tools-config-new-params
       (codex-tool-config-view-image-original-model)
       (codex-tool-config-default-features)
       False
       (codex:tool-config-sandbox-policy-danger-full-access)
       (codex:windows-sandbox-level-disabled))))

(= (codex-tool-registry-order-schema)
   (JsonObject
     ((JsonPair "type" (JsonString "object"))
      (JsonPair
        "properties"
        (JsonObject
          ((JsonPair
             "order_id"
             (JsonObject
               ((JsonPair "type" (JsonString "string"))))))))
      (JsonPair
        "required"
        (JsonArray ((JsonString "order_id"))))
      (JsonPair "additionalProperties" (JsonBool False)))))

(= (codex-tool-registry-ticket-schema-with-inferred-types)
   (JsonObject
     ((JsonPair
        "properties"
        (JsonObject
          ((JsonPair
             "id"
             (JsonObject
               ((JsonPair
                  "description"
                  (JsonString "Ticket identifier")))))))))))

(= (codex-tool-registry-integer-and-array-schema)
   (JsonObject
     ((JsonPair "type" (JsonString "object"))
      (JsonPair
        "properties"
        (JsonObject
          ((JsonPair
             "page"
             (JsonObject
               ((JsonPair "type" (JsonString "integer")))))
           (JsonPair
             "tags"
             (JsonObject
               ((JsonPair "type" (JsonString "array")))))))))))

!(assertEqualToResult
  (json-stringify
    (codex:tool-spec-json
      (codex:create-update-plan-tool)))
  ("{\"type\":\"function\",\"name\":\"update_plan\",\"description\":\"Updates the task plan.\\nProvide an optional explanation and a list of plan items, each with a step and status.\\nAt most one step can be in_progress at a time.\\n\",\"strict\":false,\"parameters\":{\"type\":\"object\",\"properties\":{\"explanation\":{\"type\":\"string\"},\"plan\":{\"type\":\"array\",\"description\":\"The list of steps\",\"items\":{\"type\":\"object\",\"properties\":{\"step\":{\"type\":\"string\"},\"status\":{\"type\":\"string\",\"description\":\"One of: pending, in_progress, completed\"}},\"required\":[\"step\",\"status\"],\"additionalProperties\":false}}},\"required\":[\"plan\"],\"additionalProperties\":false}}"))

!(assertEqualToResult
  (json-stringify
    (codex:tool-spec-json
      (codex:create-list-dir-tool)))
  ("{\"type\":\"function\",\"name\":\"list_dir\",\"description\":\"Lists entries in a local directory with 1-indexed entry numbers and simple type labels.\",\"strict\":false,\"parameters\":{\"type\":\"object\",\"properties\":{\"dir_path\":{\"type\":\"string\",\"description\":\"Absolute path to the directory to list.\"},\"offset\":{\"type\":\"number\",\"description\":\"The entry number to start listing from. Must be 1 or greater.\"},\"limit\":{\"type\":\"number\",\"description\":\"The maximum number of entries to return.\"},\"depth\":{\"type\":\"number\",\"description\":\"The maximum directory depth to traverse. Must be 1 or greater.\"}},\"required\":[\"dir_path\"],\"additionalProperties\":false}}"))

!(assertEqual
  (json-stringify
    (codex:tool-spec-json
      (codex:create-view-image-tool False)))
  "{\"type\":\"function\",\"name\":\"view_image\",\"description\":\"View a local image from the filesystem (only use if given a full filepath by the user, and the image isn't already attached to the thread context within <image ...> tags).\",\"strict\":false,\"parameters\":{\"type\":\"object\",\"properties\":{\"path\":{\"type\":\"string\",\"description\":\"Local filesystem path to an image file\"}},\"required\":[\"path\"],\"additionalProperties\":false}}")

!(assertEqualToResult
  (json-stringify
    (codex:function-tool-output-schema
      (codex:tool-spec-function-tool
        (codex:create-view-image-tool False))))
  ("{\"type\":\"object\",\"properties\":{\"image_url\":{\"type\":\"string\",\"description\":\"Data URL for the loaded image.\"},\"detail\":{\"type\":[\"string\",\"null\"],\"description\":\"Image detail hint returned by view_image. Returns `original` when original resolution is preserved, otherwise `null`.\"}},\"required\":[\"image_url\",\"detail\"],\"additionalProperties\":false}"))

!(assertEqualToResult
  (json-stringify
    (json-object-get
      (json-object-get
        (codex:function-tool-parameters
          (codex:tool-spec-function-tool
            (codex:create-view-image-tool True)))
        "properties")
      "detail"))
  ("{\"type\":\"string\",\"description\":\"Optional detail override. The only supported value is `original`; omit this field for default resized behavior. Use `original` to preserve the file's original resolution instead of resizing to fit. This is important when high-fidelity image perception or precise localization is needed, especially for CUA agents.\"}"))

!(assertEqual
  (codex:freeform-tool-format-definition
    (codex:tool-spec-freeform-tool
      (codex:create-apply-patch-freeform-tool)))
  "start: begin_patch hunk+ end_patch\nbegin_patch: \"*** Begin Patch\" LF\nend_patch: \"*** End Patch\" LF?\n\nhunk: add_hunk | delete_hunk | update_hunk\nadd_hunk: \"*** Add File: \" filename LF add_line+\ndelete_hunk: \"*** Delete File: \" filename LF\nupdate_hunk: \"*** Update File: \" filename LF change_move? change?\n\nfilename: /(.+)/\nadd_line: \"+\" /(.*)/ LF -> line\n\nchange_move: \"*** Move to: \" filename LF\nchange: (change_context | change_line)+ eof_line?\nchange_context: (\"@@\" | \"@@ \" /(.+)/) LF\nchange_line: (\"+\" | \"-\" | \" \") /(.*)/ LF\neof_line: \"*** End of File\" LF\n\n%import common.LF\n")

!(assertEqual
  (codex:freeform-tool-format-definition
    (codex:tool-spec-freeform-tool
      (codex:create-js-repl-tool)))
  (codex:js-repl-freeform-grammar))

!(assertEqualToResult
  (json-stringify
    (codex:tool-spec-json
      (codex:create-js-repl-reset-tool)))
  ("{\"type\":\"function\",\"name\":\"js_repl_reset\",\"description\":\"Restarts the js_repl kernel for this run and clears persisted top-level bindings.\",\"strict\":false,\"parameters\":{\"type\":\"object\",\"properties\":{},\"additionalProperties\":false}}"))

!(assertEqualToResult
  (codex:tool-spec-name
    (codex:tool-spec-tool-search
      "client"
      "Search deferred tools."
      (codex:json-schema-object-with-required-and-additional-properties
        ((JsonPair "query" (codex:json-schema-string)))
        ("query")
        False)))
  ("tool_search"))

!(assertEqualToResult
  (json-stringify
    (codex:tool-spec-json
      (codex:tool-spec-tool-search
        "client"
        "Search deferred tools."
        (codex:json-schema-object-with-required-and-additional-properties
          ((JsonPair "query" (codex:json-schema-string)))
          ("query")
          False))))
  ("{\"type\":\"tool_search\",\"execution\":\"client\",\"description\":\"Search deferred tools.\",\"parameters\":{\"type\":\"object\",\"properties\":{\"query\":{\"type\":\"string\"}},\"required\":[\"query\"],\"additionalProperties\":false}}"))

!(assertEqualToResult
  (codex:tool-spec-name
    (codex:tool-spec-namespace
      (codex:responses-api-namespace
        "mcp__calendar__"
        "Plan events."
        ())))
  ("mcp__calendar__"))

!(assertEqualToResult
  (json-stringify
    (codex:tool-spec-json
      (codex:tool-spec-namespace
        (codex:responses-api-namespace
          "mcp__calendar__"
          "Plan events."
          ((codex:responses-api-namespace-tool-function
             (codex:responses-api-tool
               "create_event"
               "Create a calendar event."
               False
               True
               (codex:json-schema-object ())
               CodexAbsent)))))))
  ("{\"type\":\"namespace\",\"name\":\"mcp__calendar__\",\"description\":\"Plan events.\",\"tools\":[{\"type\":\"function\",\"name\":\"create_event\",\"description\":\"Create a calendar event.\",\"strict\":false,\"defer_loading\":true,\"parameters\":{\"type\":\"object\",\"properties\":{}}}]}"))

!(assertEqualToResult
  (json-stringify
    (codex:responses-api-tool-json
      (codex:dynamic-tool-to-responses-api-tool
        (codex:dynamic-tool-spec
          CodexAbsent
          "lookup_order"
          "Look up an order"
          (codex-tool-registry-order-schema)
          True))))
  ("{\"type\":\"function\",\"name\":\"lookup_order\",\"description\":\"Look up an order\",\"strict\":false,\"defer_loading\":true,\"parameters\":{\"type\":\"object\",\"properties\":{\"order_id\":{\"type\":\"string\"}},\"required\":[\"order_id\"],\"additionalProperties\":false}}"))

!(assertEqualToResult
  (json-stringify
    (codex:function-tool-parameters
      (codex:dynamic-tool-to-responses-api-tool
        (codex:dynamic-tool-spec
          CodexAbsent
          "lookup_ticket"
          "Fetch a ticket"
          (codex-tool-registry-ticket-schema-with-inferred-types)
          False))))
  ("{\"type\":\"object\",\"properties\":{\"id\":{\"type\":\"string\",\"description\":\"Ticket identifier\"}}}"))

!(assertEqualToResult
  (json-stringify
    (let $schema (eval (codex-tool-registry-integer-and-array-schema))
      (codex:parse-tool-input-schema $schema)))
  ("{\"type\":\"object\",\"properties\":{\"page\":{\"type\":\"integer\"},\"tags\":{\"type\":\"array\",\"items\":{\"type\":\"string\"}}}}"))

!(assertEqualToResult
  (json-stringify
    (codex:loadable-tool-spec-json
      (codex:dynamic-tool-to-loadable-tool-spec
        (codex:dynamic-tool-spec
          "tickets"
          "lookup_order"
          "Look up an order"
          (codex-tool-registry-order-schema)
          True))))
  ("{\"type\":\"namespace\",\"name\":\"tickets\",\"description\":\"Tools in the tickets namespace.\",\"tools\":[{\"type\":\"function\",\"name\":\"lookup_order\",\"description\":\"Look up an order\",\"strict\":false,\"defer_loading\":true,\"parameters\":{\"type\":\"object\",\"properties\":{\"order_id\":{\"type\":\"string\"}},\"required\":[\"order_id\"],\"additionalProperties\":false}}]}"))

!(assertEqualToResult
  (json-stringify
    (codex:loadable-tool-spec-json
      (codex:dynamic-tool-to-loadable-tool-spec
        (codex:dynamic-tool-spec
          CodexAbsent
          "run_sql"
          "Query database"
          (codex:json-schema-object ())
          False))))
  ("{\"type\":\"function\",\"name\":\"run_sql\",\"description\":\"Query database\",\"strict\":false,\"parameters\":{\"type\":\"object\",\"properties\":{}}}"))

!(assertEqualToResult
  (json-stringify
    (codex:loadable-tool-specs-json
      (codex:coalesce-loadable-tool-specs
        ((codex:dynamic-tool-to-loadable-tool-spec
           (codex:dynamic-tool-spec
             "tickets"
             "lookup_order"
             "Look up an order"
             (codex-tool-registry-order-schema)
             True))
         (codex:dynamic-tool-to-loadable-tool-spec
           (codex:dynamic-tool-spec
             CodexAbsent
             "run_sql"
             "Query database"
             (codex:json-schema-object ())
             False))
         (codex:dynamic-tool-to-loadable-tool-spec
           (codex:dynamic-tool-spec
             "tickets"
             "create_order"
             "Create an order"
             (codex:json-schema-object ())
             False))))))
  ("[{\"type\":\"namespace\",\"name\":\"tickets\",\"description\":\"Tools in the tickets namespace.\",\"tools\":[{\"type\":\"function\",\"name\":\"lookup_order\",\"description\":\"Look up an order\",\"strict\":false,\"defer_loading\":true,\"parameters\":{\"type\":\"object\",\"properties\":{\"order_id\":{\"type\":\"string\"}},\"required\":[\"order_id\"],\"additionalProperties\":false}},{\"type\":\"function\",\"name\":\"create_order\",\"description\":\"Create an order\",\"strict\":false,\"parameters\":{\"type\":\"object\",\"properties\":{}}}]},{\"type\":\"function\",\"name\":\"run_sql\",\"description\":\"Query database\",\"strict\":false,\"parameters\":{\"type\":\"object\",\"properties\":{}}}]"))

!(assertEqualToResult
  (json-stringify
    (json-object-get
      (json-object-get
        (codex:function-tool-parameters
          (codex:tool-spec-function-tool
            (codex:create-exec-command-tool True True)))
        "properties")
      "additional_permissions"))
  ("{\"type\":\"object\",\"properties\":{\"file_system\":{\"type\":\"object\",\"properties\":{\"read\":{\"type\":\"array\",\"description\":\"Absolute paths to grant read access to.\",\"items\":{\"type\":\"string\"}},\"write\":{\"type\":\"array\",\"description\":\"Absolute paths to grant write access to.\",\"items\":{\"type\":\"string\"}}},\"additionalProperties\":false},\"network\":{\"type\":\"object\",\"properties\":{\"enabled\":{\"type\":\"boolean\",\"description\":\"Set to true to request network access.\"}},\"additionalProperties\":false}},\"additionalProperties\":false}"))

!(assertEqualToResult
  (json-stringify
    (codex:function-tool-output-schema
      (codex:tool-spec-function-tool
        (codex:create-write-stdin-tool))))
  ("{\"type\":\"object\",\"properties\":{\"chunk_id\":{\"type\":\"string\",\"description\":\"Chunk identifier included when the response reports one.\"},\"wall_time_seconds\":{\"type\":\"number\",\"description\":\"Elapsed wall time spent waiting for output in seconds.\"},\"exit_code\":{\"type\":\"number\",\"description\":\"Process exit code when the command finished during this call.\"},\"session_id\":{\"type\":\"number\",\"description\":\"Session identifier to pass to write_stdin when the process is still running.\"},\"original_token_count\":{\"type\":\"number\",\"description\":\"Approximate token count before output truncation.\"},\"output\":{\"type\":\"string\",\"description\":\"Command output text, possibly truncated.\"}},\"required\":[\"wall_time_seconds\",\"output\"],\"additionalProperties\":false}"))

!(assertEqualToResult
  (unique
    (codex:string-list-contains
      (codex:tool-registry-plan-spec-names
        (codex:build-tool-registry-plan
          (codex-tool-registry-default-config)))
      "js_repl"))
  (False))

!(assertEqualToResult
  (unique
    (codex:string-list-contains
      (codex:tool-registry-plan-spec-names
        (codex:build-tool-registry-plan
          (codex-tool-registry-js-repl-config)))
      "js_repl"))
  (True))

!(assertEqualToResult
  (unique
    (codex:string-list-contains
      (codex:tool-registry-plan-spec-names
        (codex:build-tool-registry-plan
          (codex-tool-registry-js-repl-config)))
      "js_repl_reset"))
  (True))

!(assertEqualToResult
  (unique
    (codex:tool-registry-plan-handler-pairs-json
      (codex:build-tool-registry-plan
        (codex-tool-registry-js-repl-config))))
  ((JsonArray
     ((JsonArray ((JsonString "exec_command") (JsonString "UnifiedExec")))
      (JsonArray ((JsonString "write_stdin") (JsonString "UnifiedExec")))
      (JsonArray ((JsonString "update_plan") (JsonString "Plan")))
      (JsonArray ((JsonString "js_repl") (JsonString "JsRepl")))
      (JsonArray ((JsonString "js_repl_reset") (JsonString "JsReplReset")))
      (JsonArray ((JsonString "request_user_input") (JsonString "RequestUserInput")))
      (JsonArray ((JsonString "apply_patch") (JsonString "ApplyPatch")))
      (JsonArray ((JsonString "view_image") (JsonString "ViewImage")))))))

!(assertEqualToResult
  (unique
    (codex:string-list-contains
      (codex:tool-registry-plan-spec-names
        (codex:build-tool-registry-plan
          (codex:tools-config-with-has-environment
            (codex-tool-registry-js-repl-config)
            False)))
      "js_repl"))
  (False))
