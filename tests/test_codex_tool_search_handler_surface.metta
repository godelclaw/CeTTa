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
