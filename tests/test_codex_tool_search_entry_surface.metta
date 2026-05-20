!(register-module! ../codex)
!(import! &self codex:tool_search_entry)

(= (test:ticket-schema)
   (JsonObject
     ((JsonPair "type" (JsonString "object"))
      (JsonPair
        "properties"
        (JsonObject
          ((JsonPair "id" (JsonObject ()))
           (JsonPair "include_history" (JsonObject ()))))))))

(= (test:event-schema)
   (JsonObject
     ((JsonPair
        "properties"
        (JsonObject
          ((JsonPair "date" (JsonObject ()))
           (JsonPair "title" (JsonObject ()))))))))

(= (test:empty-schema)
   (JsonObject ()))

(= (test:calendar-tool)
   (codex:mcp-tool
     "create"
     "Create Event"
     "   "
     (test:event-schema)))

(= (test:calendar-info)
   (codex:tool-search-mcp-info
     "calendar.create_event"
     "calendar"
     "mcp_calendar"
     "create_event"
     (test:calendar-tool)
     "Google Calendar"
     CodexAbsent
     (" Team " "" "Ops")))

(= (test:alpha-info)
   (codex:tool-search-mcp-info
     "alpha.read"
     "alpha"
     "mcp_alpha"
     "read"
     (codex:mcp-tool "read" CodexAbsent CodexAbsent (test:empty-schema))
     CodexAbsent
     CodexAbsent
     ()))

(= (test:zeta-info)
   (codex:tool-search-mcp-info
     "zeta.write"
     "zeta"
     "mcp_zeta"
     "write"
     (codex:mcp-tool "write" CodexAbsent CodexAbsent (test:empty-schema))
     CodexAbsent
     CodexAbsent
     ()))

(= (test:ticket-dynamic)
   (codex:dynamic-tool-spec
     "tickets"
     "lookup_ticket"
     "Lookup ticket"
     (test:ticket-schema)
     True))

(= (test:sql-dynamic)
   (codex:dynamic-tool-spec
     CodexAbsent
     "run_sql"
     "Query database"
     (test:empty-schema)
     False))

(= (test:z-dynamic)
   (codex:dynamic-tool-spec
     "z"
     "b"
     "Zed"
     (test:empty-schema)
     True))

(= (test:a-dynamic)
   (codex:dynamic-tool-spec
     CodexAbsent
     "a"
     "Aye"
     (test:empty-schema)
     True))

!(assertEqualToResult
  (codex:build-mcp-search-text (test:calendar-info))
  ("calendar.create_event create_event create calendar Create Event Google Calendar Team Ops date title"))

!(assertEqualToResult
  (codex:build-dynamic-search-text (test:ticket-dynamic))
  ("lookup_ticket lookup ticket Lookup ticket tickets id include_history"))

!(assertEqualToResult
  (codex:build-dynamic-search-text (test:sql-dynamic))
  ("run_sql run sql Query database"))

!(assertEqualToResult
  (codex:tool-search-entry-limit-bucket
    (codex:mcp-tool-search-entry (test:calendar-info)))
  ("calendar"))

!(assertEqualToResult
  (codex:tool-search-entry-limit-bucket
    (codex:dynamic-tool-search-entry (test:ticket-dynamic)))
  (CodexAbsent))

!(assertEqualToResult
  (codex:tool-search-entry-output
    (codex:mcp-tool-search-entry (test:calendar-info)))
  ((CodexToolSearchOutputMcp
     "calendar"
     "mcp_calendar"
     "create_event"
     "Google Calendar"
     CodexAbsent)))

!(assertEqualToResult
  (codex:tool-search-entry-output
    (codex:dynamic-tool-search-entry (test:ticket-dynamic)))
  ((CodexToolSearchOutputDynamic "tickets" "lookup_ticket")))

!(assertEqualToResult
  (let $entries
    (eval
      (codex:build-tool-search-entries
        ((test:zeta-info) (test:alpha-info))
        ((test:z-dynamic) (test:a-dynamic))))
    (map-atom-strict
      $entries
      $entry
      (codex:tool-search-entry-search-text $entry)))
  (("alpha.read read read alpha"
    "zeta.write write write zeta"
    "a a Aye"
    "b b Zed z")))

!(assertEqualToResult
  (let $entries
    (eval
      (codex:build-tool-search-entries
        CodexAbsent
        ((test:z-dynamic) (test:a-dynamic))))
    (map-atom-strict
      $entries
      $entry
      (codex:tool-search-entry-search-text $entry)))
  (("a a Aye"
    "b b Zed z")))
