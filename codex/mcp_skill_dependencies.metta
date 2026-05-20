; Narrow Rust-faithful MCP skill dependency helper slice.
;
; This ports the pure helper behavior from:
; - openai-codex/codex-rs/core/src/mcp_skill_dependencies.rs
;
; Covered in this increment:
; - prompt constants for MCP dependency installation
; - `format_missing_mcp_dependencies`
; - `canonical_mcp_key`
; - `canonical_mcp_server_key`
; - `canonical_mcp_dependency_key`
; - `mcp_dependency_to_server_config`
; - `collect_missing_mcp_dependencies`
; - `should_install_mcp_dependencies` prompt/answer side-effect planning
; - `filter_prompted_mcp_dependencies`
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust stores installed/missing MCP servers in `HashMap<String,
;   McpServerConfig>` and canonical-key sets in `HashSet<String>`. This CeTTa
;   slice uses deterministic list-backed maps and sets. Lookups, duplicate
;   suppression, and last write for duplicate server names are preserved for
;   the visible helper behavior; Rust HashMap iteration order is intentionally
;   not represented.
; - Rust logs warnings for malformed MCP dependencies while collecting missing
;   entries. This pure CeTTa boundary returns the same filtered missing set and
;   drops warning side effects until a session/tracing layer is ported.
; - Rust `should_install_mcp_dependencies` awaits session request_user_input,
;   handles cancellation by notifying an empty response, and records prompted
;   keys on the session after the prompt path. This pure helper receives the
;   materialized response value and returns the same install boolean, prompt
;   event, and prompted canonical keys for the runtime layer to execute.
;   CeTTa's Empty cannot be nested as a constructor field, so the no-prompt
;   auto-approved branch uses CodexAbsent for the prompt event.
; - Rust `filter_prompted_mcp_dependencies` reads a session HashSet of prompted
;   canonical keys. This pure helper receives that set as a list and preserves
;   the same canonical-key exclusion predicate.

!(import! &self list)
!(import! &self mcp)
!(import! &self str)
!(import! &self codex:skill_model)

(= (codex:mcp-skill-dependency-prompt-id)
   "skill_mcp_dependency_install")

(= (codex:mcp-dependency-option-install)
   "Install")

(= (codex:mcp-dependency-option-skip)
   "Continue anyway")

(= (codex:mcp-server-transport-stdio
      $command
      $args
      $env
      $env-vars
      $cwd)
   (CodexMcpServerTransportStdio
     $command
     $args
     $env
     $env-vars
     $cwd))

(= (codex:mcp-server-transport-stdio-command
      (CodexMcpServerTransportStdio
        $command
        $args
        $env
        $env-vars
        $cwd))
   $command)

(= (codex:mcp-server-transport-streamable-http
      $url
      $bearer-token-env-var
      $http-headers
      $env-http-headers)
   (CodexMcpServerTransportStreamableHttp
     $url
     $bearer-token-env-var
     $http-headers
     $env-http-headers))

(= (codex:mcp-server-transport-streamable-http-url
      (CodexMcpServerTransportStreamableHttp
        $url
        $bearer-token-env-var
        $http-headers
        $env-http-headers))
   $url)

(= (codex:mcp-server-config
      $transport
      $experimental-environment
      $enabled
      $required
      $supports-parallel-tool-calls
      $disabled-reason
      $startup-timeout-sec
      $tool-timeout-sec
      $default-tools-approval-mode
      $enabled-tools
      $disabled-tools
      $scopes
      $oauth-resource
      $tools)
   (CodexMcpServerConfig
     $transport
     $experimental-environment
     $enabled
     $required
     $supports-parallel-tool-calls
     $disabled-reason
     $startup-timeout-sec
     $tool-timeout-sec
     $default-tools-approval-mode
     $enabled-tools
     $disabled-tools
     $scopes
     $oauth-resource
     $tools))

(= (codex:mcp-server-config-transport
      (CodexMcpServerConfig
        $transport
        $experimental-environment
        $enabled
        $required
        $supports-parallel-tool-calls
        $disabled-reason
        $startup-timeout-sec
        $tool-timeout-sec
        $default-tools-approval-mode
        $enabled-tools
        $disabled-tools
        $scopes
        $oauth-resource
        $tools))
   $transport)

(= (codex:mcp-server-entry $name $config)
   (CodexMcpServerEntry $name $config))

(= (codex:mcp-server-entry-name (CodexMcpServerEntry $name $config))
   $name)

(= (codex:mcp-server-entry-config (CodexMcpServerEntry $name $config))
   $config)

(= (codex:mcp-dependency-ok $value)
   (CodexMcpDependencyOk $value))

(= (codex:mcp-dependency-err $message)
   (CodexMcpDependencyErr $message))

(= (codex:mcp-dependency-collect-state $seen-canonical-keys $missing)
   (CodexMcpDependencyCollectState $seen-canonical-keys $missing))

(= (codex:mcp-dependency-should-install-plan
      $install
      $request-event
      $record-prompted-keys)
   (CodexMcpDependencyShouldInstallPlan
     $install
     $request-event
     $record-prompted-keys))

(= (codex:mcp-dependency-collect-state-seen
      (CodexMcpDependencyCollectState $seen-canonical-keys $missing))
   $seen-canonical-keys)

(= (codex:mcp-dependency-collect-state-missing
      (CodexMcpDependencyCollectState $seen-canonical-keys $missing))
   $missing)

(= (codex:mcp-skill-metadata-name
      (CodexCoreSkillMetadata
        $name
        $description
        $short-description
        $interface
        $dependencies
        $policy
        $path
        $scope))
   $name)

(= (codex:mcp-skill-metadata-dependencies
      (CodexCoreSkillMetadata
        $name
        $description
        $short-description
        $interface
        $dependencies
        $policy
        $path
        $scope))
   $dependencies)

(= (codex:mcp-skill-metadata-name
      (CodexSkillMetadata
        $name
        $description
        $short-description
        $interface
        $dependencies
        $path
        $scope
        $enabled))
   $name)

(= (codex:mcp-skill-metadata-dependencies
      (CodexSkillMetadata
        $name
        $description
        $short-description
        $interface
        $dependencies
        $path
        $scope
        $enabled))
   $dependencies)

(= (codex:mcp-skill-dependencies-tools
      (CodexSkillDependencies $tools))
   $tools)

(= (codex:mcp-skill-tool-dependency-type
      (CodexSkillToolDependency
        $type
        $value
        $description
        $transport
        $command
        $url))
   $type)

(= (codex:mcp-skill-tool-dependency-value
      (CodexSkillToolDependency
        $type
        $value
        $description
        $transport
        $command
        $url))
   $value)

(= (codex:mcp-skill-tool-dependency-transport
      (CodexSkillToolDependency
        $type
        $value
        $description
        $transport
        $command
        $url))
   $transport)

(= (codex:mcp-skill-tool-dependency-command
      (CodexSkillToolDependency
        $type
        $value
        $description
        $transport
        $command
        $url))
   $command)

(= (codex:mcp-skill-tool-dependency-url
      (CodexSkillToolDependency
        $type
        $value
        $description
        $transport
        $command
        $url))
   $url)

(= (codex:mcp-skill-dependencies-ascii-lower-char $char)
   (case $char
     (("A" "a")
      ("B" "b")
      ("C" "c")
      ("D" "d")
      ("E" "e")
      ("F" "f")
      ("G" "g")
      ("H" "h")
      ("I" "i")
      ("J" "j")
      ("K" "k")
      ("L" "l")
      ("M" "m")
      ("N" "n")
      ("O" "o")
      ("P" "p")
      ("Q" "q")
      ("R" "r")
      ("S" "s")
      ("T" "t")
      ("U" "u")
      ("V" "v")
      ("W" "w")
      ("X" "x")
      ("Y" "y")
      ("Z" "z")
      ($other $other))))

(= (codex:mcp-skill-dependencies-ascii-lower-text $text)
   (if (== $text "")
       ""
       (str-concat
         (codex:mcp-skill-dependencies-ascii-lower-char
           (str-slice $text 0 1))
         (codex:mcp-skill-dependencies-ascii-lower-text
           (str-slice $text 1 (str-length $text))))))

(= (codex:mcp-skill-dependencies-eq-ignore-ascii-case $left $right)
   (== (codex:mcp-skill-dependencies-ascii-lower-text $left)
       (codex:mcp-skill-dependencies-ascii-lower-text $right)))

(= (codex:mcp-skill-dependencies-list-contains $items $item)
   (if (== $items ())
       False
       (let $head (list:first $items)
         (let $tail (list:rest $items)
           (if (== $head $item)
               True
               (codex:mcp-skill-dependencies-list-contains $tail $item))))))

(= (codex:mcp-skill-dependencies-list-add $items $item)
   (if (codex:mcp-skill-dependencies-list-contains $items $item)
       $items
       (list:append $items ($item))))

(= (codex:mcp-server-entry-names ())
   ())

(= (codex:mcp-server-entry-names $entries)
   (let $head (list:first $entries)
     (let $tail (list:rest $entries)
       (list:append
         ((codex:mcp-server-entry-name $head))
         (codex:mcp-server-entry-names $tail)))))

(= (codex:format-missing-mcp-dependencies $missing)
   (let $names (once (eval (codex:mcp-server-entry-names $missing)))
     (case (sort-strings $names)
       ((() "")
        ($sorted-names (str-join ", " $sorted-names))))))

(= (codex:mcp-dependency-install-question $missing)
   (CodexRequestUserInputQuestion
     (codex:mcp-skill-dependency-prompt-id)
     "Install MCP servers?"
     (format-args
       "The following MCP servers are required by the selected skills but are not installed yet: {}. Install them now?"
       ((codex:format-missing-mcp-dependencies $missing)))
     False
     False
     ((CodexRequestUserInputQuestionOption
        (codex:mcp-dependency-option-install)
        "Install and enable the missing MCP servers in your global config.")
      (CodexRequestUserInputQuestionOption
        (codex:mcp-dependency-option-skip)
        "Skip installation for now and do not show again for these MCP servers in this session."))))

(= (codex:canonical-mcp-key $transport $identifier $fallback)
   (let $trimmed-identifier (str-trim $identifier)
     (if (== $trimmed-identifier "")
         $fallback
         (str-concat
           "mcp__"
           (str-concat
             $transport
             (str-concat "__" $trimmed-identifier))))))

(= (codex:canonical-mcp-server-key $name $config)
   (let $transport (codex:mcp-server-config-transport $config)
     (case $transport
       (((CodexMcpServerTransportStdio
           $command
           $args
           $env
           $env-vars
           $cwd)
         (codex:canonical-mcp-key "stdio" $command $name))
        ((CodexMcpServerTransportStreamableHttp
           $url
           $bearer-token-env-var
           $http-headers
           $env-http-headers)
         (codex:canonical-mcp-key "streamable_http" $url $name))))))

(= (codex:mcp-dependency-transport-or-default $transport)
   (case $transport
     ((CodexAbsent "streamable_http")
      ($other $other))))

(= (codex:canonical-mcp-dependency-key $dependency)
   (let $transport
     (codex:mcp-dependency-transport-or-default
       (codex:mcp-skill-tool-dependency-transport $dependency))
     (let $value (codex:mcp-skill-tool-dependency-value $dependency)
       (if (codex:mcp-skill-dependencies-eq-ignore-ascii-case
             $transport
             "streamable_http")
           (case (codex:mcp-skill-tool-dependency-url $dependency)
             ((CodexAbsent
               (codex:mcp-dependency-err
                 "missing url for streamable_http dependency"))
              ($url
               (codex:mcp-dependency-ok
                 (codex:canonical-mcp-key
                   "streamable_http"
                   $url
                   $value)))))
           (if (codex:mcp-skill-dependencies-eq-ignore-ascii-case
                 $transport
                 "stdio")
               (case (codex:mcp-skill-tool-dependency-command $dependency)
                 ((CodexAbsent
                   (codex:mcp-dependency-err
                     "missing command for stdio dependency"))
                  ($command
                   (codex:mcp-dependency-ok
                     (codex:canonical-mcp-key
                       "stdio"
                       $command
                       $value)))))
               (codex:mcp-dependency-err
                 (format-args "unsupported transport {}" ($transport))))))))

(= (codex:mcp-dependency-default-http-config $url)
   (codex:mcp-server-config
     (codex:mcp-server-transport-streamable-http
       $url
       CodexAbsent
       CodexAbsent
       CodexAbsent)
     CodexAbsent
     True
     False
     False
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     ()))

(= (codex:mcp-dependency-default-stdio-config $command)
   (codex:mcp-server-config
     (codex:mcp-server-transport-stdio
       $command
       ()
       CodexAbsent
       ()
       CodexAbsent)
     CodexAbsent
     True
     False
     False
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     ()))

(= (codex:mcp-dependency-to-server-config $dependency)
   (let $transport
     (codex:mcp-dependency-transport-or-default
       (codex:mcp-skill-tool-dependency-transport $dependency))
     (if (codex:mcp-skill-dependencies-eq-ignore-ascii-case
           $transport
           "streamable_http")
         (case (codex:mcp-skill-tool-dependency-url $dependency)
           ((CodexAbsent
             (codex:mcp-dependency-err
               "missing url for streamable_http dependency"))
            ($url
             (codex:mcp-dependency-ok
               (codex:mcp-dependency-default-http-config $url)))))
         (if (codex:mcp-skill-dependencies-eq-ignore-ascii-case
               $transport
               "stdio")
             (case (codex:mcp-skill-tool-dependency-command $dependency)
               ((CodexAbsent
                 (codex:mcp-dependency-err
                   "missing command for stdio dependency"))
                ($command
                 (codex:mcp-dependency-ok
                   (codex:mcp-dependency-default-stdio-config $command)))))
             (codex:mcp-dependency-err
               (format-args "unsupported transport {}" ($transport)))))))

(= (codex:mcp-installed-canonical-keys ())
   ())

(= (codex:mcp-installed-canonical-keys $installed)
   (let $head (list:first $installed)
     (let $tail (list:rest $installed)
       (list:append
         ((codex:canonical-mcp-server-key
            (codex:mcp-server-entry-name $head)
            (codex:mcp-server-entry-config $head)))
         (codex:mcp-installed-canonical-keys $tail)))))

(= (codex:mcp-dependency-prompted-canonical-keys ())
   ())

(= (codex:mcp-dependency-prompted-canonical-keys $missing)
   (let $head (list:first $missing)
     (let $tail (list:rest $missing)
       (list:append
         ((codex:canonical-mcp-server-key
            (codex:mcp-server-entry-name $head)
            (codex:mcp-server-entry-config $head)))
         (codex:mcp-dependency-prompted-canonical-keys $tail)))))

(= (codex:filter-prompted-mcp-dependencies $missing $prompted-canonical-keys)
   (if (== $missing ())
       ()
       (if (== $prompted-canonical-keys ())
           $missing
           (let $head (list:first $missing)
             (let $tail (list:rest $missing)
               (let $key
                 (codex:canonical-mcp-server-key
                   (codex:mcp-server-entry-name $head)
                   (codex:mcp-server-entry-config $head))
                 (if (codex:mcp-skill-dependencies-list-contains
                       $prompted-canonical-keys
                       $key)
                     (codex:filter-prompted-mcp-dependencies
                       $tail
                       $prompted-canonical-keys)
                     (list:append
                       ($head)
                       (codex:filter-prompted-mcp-dependencies
                         $tail
                         $prompted-canonical-keys)))))))))

(= (codex:mcp-dependency-response-answer-values () $question-id)
   Empty)

(= (codex:mcp-dependency-response-answer-values $entries $question-id)
   (let $head (list:first $entries)
     (let $tail (list:rest $entries)
       (case $head
         (((CodexRequestUserInputResponseEntry
             $entry-id
             (CodexRequestUserInputAnswer $answers))
           (if (== $entry-id $question-id)
               $answers
               (codex:mcp-dependency-response-answer-values
                 $tail
                 $question-id))))))))

(= (codex:mcp-dependency-install-answer-selected CodexAbsent)
   False)

(= (codex:mcp-dependency-install-answer-selected Empty)
   False)

(= (codex:mcp-dependency-install-answer-selected
      (CodexRequestUserInputResponse $answers))
   (case
     (codex:mcp-dependency-response-answer-values
       $answers
       (codex:mcp-skill-dependency-prompt-id))
     ((Empty False)
      ($values
       (codex:mcp-skill-dependencies-list-contains
         $values
         (codex:mcp-dependency-option-install))))))

(= (codex:should-install-mcp-dependencies-plan
      $approval-policy
      $sandbox-policy
      $sub-id
      $missing
      $response)
   (if (codex:mcp-permission-prompt-is-auto-approved
         $approval-policy
         $sandbox-policy)
       (codex:mcp-dependency-should-install-plan True CodexAbsent ())
       (codex:mcp-dependency-should-install-plan
         (codex:mcp-dependency-install-answer-selected $response)
         (CodexRequestUserInputEvent
           (format-args "mcp-deps-{}" ($sub-id))
           $sub-id
           ((codex:mcp-dependency-install-question $missing)))
         (codex:mcp-dependency-prompted-canonical-keys $missing))))

(= (codex:mcp-server-entry-upsert () $name $config)
   ((codex:mcp-server-entry $name $config)))

(= (codex:mcp-server-entry-upsert $entries $name $config)
   (let $head (list:first $entries)
     (let $tail (list:rest $entries)
       (if (== (codex:mcp-server-entry-name $head) $name)
           (list:append
             ((codex:mcp-server-entry $name $config))
             $tail)
           (list:append
             ($head)
             (codex:mcp-server-entry-upsert $tail $name $config))))))

(= (codex:collect-missing-mcp-dependencies $mentioned-skills $installed)
   (codex:mcp-dependency-collect-state-missing
     (codex:collect-missing-mcp-dependencies-for-skills
       $mentioned-skills
       (codex:mcp-installed-canonical-keys $installed)
       (codex:mcp-dependency-collect-state () ()))))

(= (codex:collect-missing-mcp-dependencies-for-skills
      ()
      $installed-keys
      $state)
   $state)

(= (codex:collect-missing-mcp-dependencies-for-skills
      $mentioned-skills
      $installed-keys
      $state)
   (let $skill (list:first $mentioned-skills)
     (let $tail (list:rest $mentioned-skills)
       (let $next-state
         (case (codex:mcp-skill-metadata-dependencies $skill)
           ((CodexAbsent $state)
            ((CodexSkillDependencies $tools)
             (codex:collect-missing-mcp-dependencies-for-tools
               $tools
               $installed-keys
               $state))))
         (codex:collect-missing-mcp-dependencies-for-skills
           $tail
           $installed-keys
           $next-state)))))

(= (codex:collect-missing-mcp-dependencies-for-tools
      ()
      $installed-keys
      $state)
   $state)

(= (codex:collect-missing-mcp-dependencies-for-tools
      $tools
      $installed-keys
      (CodexMcpDependencyCollectState $seen-canonical-keys $missing))
   (let $tool (list:first $tools)
     (let $tail (list:rest $tools)
       (let $next-state
         (if (not
               (codex:mcp-skill-dependencies-eq-ignore-ascii-case
                 (codex:mcp-skill-tool-dependency-type $tool)
                 "mcp"))
             (codex:mcp-dependency-collect-state
               $seen-canonical-keys
               $missing)
             (case (codex:canonical-mcp-dependency-key $tool)
               (((CodexMcpDependencyErr $message)
                 (codex:mcp-dependency-collect-state
                   $seen-canonical-keys
                   $missing))
                ((CodexMcpDependencyOk $dependency-key)
                 (if (codex:mcp-skill-dependencies-list-contains
                       $installed-keys
                       $dependency-key)
                     (codex:mcp-dependency-collect-state
                       $seen-canonical-keys
                       $missing)
                     (if (codex:mcp-skill-dependencies-list-contains
                           $seen-canonical-keys
                           $dependency-key)
                         (codex:mcp-dependency-collect-state
                           $seen-canonical-keys
                           $missing)
                         (case (codex:mcp-dependency-to-server-config $tool)
                           (((CodexMcpDependencyErr $config-message)
                             (codex:mcp-dependency-collect-state
                               $seen-canonical-keys
                               $missing))
                            ((CodexMcpDependencyOk $config)
                             (codex:mcp-dependency-collect-state
                               (codex:mcp-skill-dependencies-list-add
                                 $seen-canonical-keys
                                 $dependency-key)
                               (codex:mcp-server-entry-upsert
                                 $missing
                                 (codex:mcp-skill-tool-dependency-value $tool)
                                 $config)))))))))))
         (codex:collect-missing-mcp-dependencies-for-tools
           $tail
           $installed-keys
           $next-state)))))
