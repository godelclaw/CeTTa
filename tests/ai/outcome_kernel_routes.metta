; Keep both source translation and evaluator execution controls explicit.
(= (okroute:argv $binary $language $route $program)
   (case $route
     (((Routes $first $second)
        ("/usr/bin/env" $first $second $binary "--lang" $language "--profile" "ai" "-e" $program))
      ($single ("/usr/bin/env" $single $binary "--lang" $language "--profile" "ai" "-e" $program)))))
