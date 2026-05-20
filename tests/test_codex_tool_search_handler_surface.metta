!(register-module! ../codex)
!(import! &self list)
!(import! &self codex:context)
!(import! &self codex:function_tool)
!(import! &self codex:tool_search_entry)
!(import! &self codex:tool_search_handler)

(= (test:entry $search-text $output $bucket)
   (codex:tool-search-entry $search-text $output $bucket))

(= (test:mcp-output $server-name $tool-namespace $tool-name)
   (codex:tool-search-output-mcp
     $server-name
     $tool-namespace
     $tool-name
     CodexAbsent
     CodexAbsent))

(= (test:mcp-output-with-connector $server-name $tool-namespace $tool-name)
   (codex:tool-search-output-mcp
     $server-name
     $tool-namespace
     $tool-name
     "Google Calendar"
     CodexAbsent))

(= (test:numbered-entry $server-name $description-prefix $index)
   (let $tool-name (format-args "tool_{}" ($index))
     (test:entry
       (format-args "{} desktop tool {}" ($description-prefix $index))
       (test:mcp-output
         $server-name
         (format-args "mcp__{}__" ($server-name))
         $tool-name)
       $server-name)))

(= (test:numbered-entries $server-name $description-prefix $count)
   (list:repeat
     $count
     (test:numbered-entry $server-name $description-prefix 1)))

(= (test:bucket-run-entry $first-server $first-count $second-server $index)
   (if (< $index $first-count)
       (test:numbered-entry $first-server "computer use" 1)
       (test:numbered-entry $second-server "computer use" 1)))

(= (test:bucket-run-entries $first-server $first-count $second-server $second-count)
   (let $total-count (+ $first-count $second-count)
     (let $range (range-atom $total-count)
       (map-atom-strict
         $range
         $index
         (test:bucket-run-entry
           $first-server
           $first-count
           $second-server
           $index)))))

(= (test:handler-error-display $result)
   (case $result
     (((CodexToolSearchHandlerErr $error)
       (codex:function-call-error-display $error)))))

!(assertEqualToResult
  (let $limited
    (codex:tool-search-limit-results-by-bucket
      (eval (test:numbered-entries "other-server" "computer use" 25)))
    ((size-atom $limited)
     (codex:tool-search-count-results-for-bucket $limited "other-server")))
  ((8 8)))

!(assertEqual
  (codex:tool-search-limit-results-by-bucket
    (eval (test:bucket-run-entries "other-server" 12 "calendar" 12)))
  (eval (test:bucket-run-entries "other-server" 8 "calendar" 8)))

!(assertEqual
  (codex:tool-search-search-result-entries
    (eval (test:bucket-run-entries "other-server" 4 "computer-use" 30))
    "computer use"
    (codex:tool-search-default-limit)
    True)
  (eval (test:bucket-run-entries "other-server" 4 "computer-use" 16)))

!(assertEqual
  (codex:tool-search-search-result-entries
    (eval (test:bucket-run-entries "other-server" 4 "computer-use" 30))
    "computer use"
    12
    False)
  (eval (test:bucket-run-entries "other-server" 4 "computer-use" 8)))

!(assertEqual
  (codex:tool-search-search-result-entries
    ((CodexToolSearchEntry
       "bacon sandwich menu item"
       (CodexToolSearchOutputMcp
         "menu"
         "mcp__menu__"
         "long"
         CodexAbsent
         CodexAbsent)
       "menu")
     (CodexToolSearchEntry
       "bacon sandwich"
       (CodexToolSearchOutputMcp
         "menu"
         "mcp__menu__"
         "short"
         CodexAbsent
         CodexAbsent)
       "menu")
     (CodexToolSearchEntry
       "avocado toast"
       (CodexToolSearchOutputMcp
         "menu"
         "mcp__menu__"
         "toast"
         CodexAbsent
         CodexAbsent)
       "menu"))
    "bacon sandwich"
    8
    False)
  ((CodexToolSearchEntry
     "bacon sandwich"
     (CodexToolSearchOutputMcp
       "menu"
       "mcp__menu__"
       "short"
       CodexAbsent
       CodexAbsent)
     "menu")
   (CodexToolSearchEntry
     "bacon sandwich menu item"
     (CodexToolSearchOutputMcp
       "menu"
       "mcp__menu__"
       "long"
       CodexAbsent
       CodexAbsent)
     "menu")))

!(assertEqualToResult
  (codex:tool-search-mcp-namespace-description
    "mcp__calendar__"
    CodexAbsent
    CodexAbsent)
  ("Tools in the mcp__calendar__ namespace."))

!(assertEqualToResult
  (codex:tool-search-mcp-namespace-description
    "mcp__calendar__"
    "  Google Calendar  "
    CodexAbsent)
  ("Tools for working with Google Calendar."))

!(assertEqualToResult
  (codex:tool-search-mcp-namespace-description
    "mcp__calendar__"
    "Google Calendar"
    "  Manage calendar events.  ")
  ("Manage calendar events."))

!(assertEqual
  (codex:tool-search-search-output-tools
    ((CodexToolSearchEntry
       "create calendar event"
       (CodexToolSearchOutputMcp
         "calendar"
         "mcp__calendar__"
         "create_event"
         CodexAbsent
         CodexAbsent)
       "calendar")
     (CodexToolSearchEntry
       "codex app automation"
       (CodexToolSearchOutputDynamic "codex_app" "automation_update")
       CodexAbsent)
     (CodexToolSearchEntry
       "list calendar events"
       (CodexToolSearchOutputMcp
         "calendar"
         "mcp__calendar__"
         "list_events"
         CodexAbsent
         CodexAbsent)
       "calendar")))
  ((CodexToolSearchOutputNamespace
     "mcp__calendar__"
     "Tools in the mcp__calendar__ namespace."
     ((CodexToolSearchOutputMcp
        "calendar"
        "mcp__calendar__"
        "create_event"
        CodexAbsent
        CodexAbsent)
      (CodexToolSearchOutputMcp
        "calendar"
        "mcp__calendar__"
        "list_events"
        CodexAbsent
        CodexAbsent)))
   (CodexToolSearchOutputNamespace
     "codex_app"
     "Tools in the codex_app namespace."
     ((CodexToolSearchOutputDynamic "codex_app" "automation_update")))))

!(assertEqual
  (codex:tool-search-coalesce-loadable-tool-specs
    ((CodexToolSearchOutputMcp
       "calendar"
       "mcp__calendar__"
       "create_event"
       "Google Calendar"
       "  Manage calendar events.  ")
     (CodexToolSearchOutputDynamic CodexAbsent "local_tool")
     (CodexToolSearchOutputMcp
       "calendar"
       "mcp__calendar__"
       "list_events"
       "Google Calendar"
       "  Manage calendar events.  ")))
  ((CodexToolSearchOutputNamespace
     "mcp__calendar__"
     "Manage calendar events."
     ((CodexToolSearchOutputMcp
        "calendar"
        "mcp__calendar__"
        "create_event"
        "Google Calendar"
        "  Manage calendar events.  ")
      (CodexToolSearchOutputMcp
        "calendar"
        "mcp__calendar__"
        "list_events"
        "Google Calendar"
        "  Manage calendar events.  ")))
   (CodexToolSearchOutputDynamic CodexAbsent "local_tool")))

!(assertEqualToResult
  (codex:tool-search-handler-kind)
  ("function"))

!(assertEqualToResult
  (codex:tool-search-default-limit)
  (8))

!(assertEqualToResult
  (codex:tool-search-default-limit-for-bucket "computer-use")
  (20))

!(assertEqualToResult
  (codex:tool-search-default-limit-for-bucket "calendar")
  (8))

!(assertEqualToResult
  (test:handler-error-display
    (codex:run-tool-search-handler
      ()
      (codex:tool-search-payload "   ")))
  ("query must not be empty"))

!(assertEqualToResult
  (test:handler-error-display
    (codex:run-tool-search-handler
      ()
      (codex:tool-search-payload "calendar" 0)))
  ("limit must be greater than zero"))

!(assertEqualToResult
  (test:handler-error-display
    (codex:run-tool-search-handler
      ()
      (codex:function-payload "{}")))
  ("Fatal error: tool_search handler received unsupported payload"))

!(assertEqualToResult
  (codex:run-tool-search-handler
    ()
    (codex:tool-search-payload "calendar"))
  ((CodexToolSearchHandlerOk (CodexToolOutputToolSearch ()))))
