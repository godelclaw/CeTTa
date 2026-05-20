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
; - `maybe_install_mcp_dependencies` pre-persist planning and install merge
; - `maybe_install_mcp_dependencies` post-persist OAuth login planning
; - `maybe_install_mcp_dependencies` refresh overlay planning
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
; - Rust `maybe_install_mcp_dependencies` reads feature state, configured MCP
;   servers, and global config from async services before applying config edits.
;   This helper receives those materialized values and returns the pre-persist
;   plan that the runtime layer must execute with ConfigEditsBuilder.
; - Rust performs OAuth discovery/login as async side effects after persistence.
;   This slice receives materialized `McpOAuthLoginSupport` and login-result
;   values, then returns the same notify/login/warn operations for the runtime
;   layer to execute in Rust loop order. The actual network/browser OAuth flow
;   is intentionally not performed in this pure planner.
; - Rust refreshes a `HashMap` returned by `effective_servers`, then overlays
;   updated global servers with `entry(...).or_insert_with(...)`. This helper
;   represents both maps as entry lists, preserves the effective-server entry
;   for name collisions, and appends missing updated globals in input order.

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

(= (codex:mcp-server-config-scopes
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
   $scopes)

(= (codex:mcp-server-config-oauth-resource
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
   $oauth-resource)

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

(= (codex:mcp-dependency-load-global-servers-ok $servers)
   (CodexMcpDependencyLoadGlobalServersOk $servers))

(= (codex:mcp-dependency-load-global-servers-error $message)
   (CodexMcpDependencyLoadGlobalServersError $message))

(= (codex:mcp-dependency-persist-servers-op $codex-home $servers)
   (CodexMcpDependencyPersistServersOp $codex-home $servers))

(= (codex:mcp-dependency-persist-servers-op-codex-home
      (CodexMcpDependencyPersistServersOp $codex-home $servers))
   $codex-home)

(= (codex:mcp-dependency-persist-servers-op-servers
      (CodexMcpDependencyPersistServersOp $codex-home $servers))
   $servers)

(= (codex:mcp-dependency-install-skip $reason)
   (CodexMcpDependencyInstallSkip $reason))

(= (codex:mcp-dependency-install-load-error $message)
   (CodexMcpDependencyInstallLoadError $message))

(= (codex:mcp-dependency-install-ready
      $missing
      $updated-global-servers
      $added
      $persist-op)
   (CodexMcpDependencyInstallReady
     $missing
     $updated-global-servers
     $added
     $persist-op))

(= (codex:mcp-dependency-install-ready-missing
      (CodexMcpDependencyInstallReady
        $missing
        $updated-global-servers
        $added
        $persist-op))
   $missing)

(= (codex:mcp-dependency-install-ready-updated-global-servers
      (CodexMcpDependencyInstallReady
        $missing
        $updated-global-servers
        $added
        $persist-op))
   $updated-global-servers)

(= (codex:mcp-dependency-install-ready-added
      (CodexMcpDependencyInstallReady
        $missing
        $updated-global-servers
        $added
        $persist-op))
   $added)

(= (codex:mcp-dependency-install-ready-persist-op
      (CodexMcpDependencyInstallReady
        $missing
        $updated-global-servers
        $added
        $persist-op))
   $persist-op)

(= (codex:mcp-dependency-install-merge-state
      $updated
      $servers
      $added)
   (CodexMcpDependencyInstallMergeState
     $updated
     $servers
     $added))

(= (codex:mcp-dependency-install-merge-state-updated
      (CodexMcpDependencyInstallMergeState $updated $servers $added))
   $updated)

(= (codex:mcp-dependency-install-merge-state-servers
      (CodexMcpDependencyInstallMergeState $updated $servers $added))
   $servers)

(= (codex:mcp-dependency-install-merge-state-added
      (CodexMcpDependencyInstallMergeState $updated $servers $added))
   $added)

(= (codex:mcp-dependency-oauth-support-entry $name $support)
   (CodexMcpDependencyOAuthSupportEntry $name $support))

(= (codex:mcp-dependency-oauth-support-entry-name
      (CodexMcpDependencyOAuthSupportEntry $name $support))
   $name)

(= (codex:mcp-dependency-oauth-support-entry-support
      (CodexMcpDependencyOAuthSupportEntry $name $support))
   $support)

(= (codex:mcp-dependency-oauth-notify-op $message)
   (CodexMcpDependencyOAuthNotifyOp $message))

(= (codex:mcp-dependency-oauth-warn-op $message)
   (CodexMcpDependencyOAuthWarnOp $message))

(= (codex:mcp-dependency-oauth-login-attempt-op
      $name
      $url
      $store-mode
      $http-headers
      $env-http-headers
      $scopes
      $oauth-resource
      $callback-port
      $callback-url)
   (CodexMcpDependencyOAuthLoginAttemptOp
     $name
     $url
     $store-mode
     $http-headers
     $env-http-headers
     $scopes
     $oauth-resource
     $callback-port
     $callback-url))

(= (codex:mcp-dependency-oauth-login-ok)
   (CodexMcpDependencyOAuthLoginOk))

(= (codex:mcp-dependency-oauth-login-err $error)
   (CodexMcpDependencyOAuthLoginErr $error))

(= (codex:mcp-dependency-refresh-servers-op $servers $store-mode)
   (CodexMcpDependencyRefreshServersOp $servers $store-mode))

(= (codex:mcp-dependency-refresh-servers-op-servers
      (CodexMcpDependencyRefreshServersOp $servers $store-mode))
   $servers)

(= (codex:mcp-dependency-refresh-servers-op-store-mode
      (CodexMcpDependencyRefreshServersOp $servers $store-mode))
   $store-mode)

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

(= (codex:mcp-server-entry-list-contains-name () $name)
   False)

(= (codex:mcp-server-entry-list-contains-name $entries $name)
   (let $head (list:first $entries)
     (let $tail (list:rest $entries)
       (if (== (codex:mcp-server-entry-name $head) $name)
           True
           (codex:mcp-server-entry-list-contains-name $tail $name)))))

(= (codex:mcp-server-entry-by-name () $name)
   Empty)

(= (codex:mcp-server-entry-by-name $entries $name)
   (let $head (list:first $entries)
     (let $tail (list:rest $entries)
       (if (== (codex:mcp-server-entry-name $head) $name)
           $head
           (codex:mcp-server-entry-by-name $tail $name)))))

(= (codex:mcp-dependency-oauth-support-entry-by-name () $name)
   CodexAbsent)

(= (codex:mcp-dependency-oauth-support-entry-by-name $entries $name)
   (let $head (list:first $entries)
     (let $tail (list:rest $entries)
       (if (== (codex:mcp-dependency-oauth-support-entry-name $head) $name)
           $head
           (codex:mcp-dependency-oauth-support-entry-by-name
             $tail
             $name)))))

(= (codex:mcp-dependency-oauth-authenticating-message $name)
   (format-args
     "Authenticating MCP {}... Follow instructions in your browser if prompted."
     ($name)))

(= (codex:mcp-dependency-oauth-retrying-message $name)
   (format-args
     "Retrying MCP {} authentication without scopes after provider rejection."
     ($name)))

(= (codex:mcp-dependency-oauth-error-display $error)
   (case $error
     (((CodexMcpOAuthProviderError $provider-error $provider-description)
       (codex:mcp-oauth-provider-error-display $error))
      ($other $other))))

(= (codex:mcp-dependency-oauth-failed-login-message $name $error)
   (format-args
     "failed to login to MCP dependency {}: {}"
     ($name (codex:mcp-dependency-oauth-error-display $error))))

(= (codex:mcp-dependency-oauth-unknown-support-message $name $error)
   (format-args
     "MCP server may or may not require login for dependency {}: {}"
     ($name $error)))

(= (codex:mcp-dependency-oauth-login-attempt-for
      $name
      $oauth-config
      $server-config
      $store-mode
      $callback-port
      $callback-url
      $scopes)
   (codex:mcp-dependency-oauth-login-attempt-op
     $name
     (codex:mcp-oauth-login-config-url $oauth-config)
     $store-mode
     (codex:mcp-oauth-login-config-http-headers $oauth-config)
     (codex:mcp-oauth-login-config-env-http-headers $oauth-config)
     $scopes
     (codex:mcp-server-config-oauth-resource $server-config)
     $callback-port
     $callback-url))

(= (codex:mcp-dependency-oauth-login-plan
      ()
      $support-entries
      $store-mode
      $callback-port
      $callback-url)
   ())

(= (codex:mcp-dependency-oauth-login-plan
      $added
      $support-entries
      $store-mode
      $callback-port
      $callback-url)
   (let $entry (list:first $added)
     (let $tail (list:rest $added)
       (list:append
         (codex:mcp-dependency-oauth-login-plan-for-entry
           $entry
           $support-entries
           $store-mode
           $callback-port
           $callback-url)
         (codex:mcp-dependency-oauth-login-plan
           $tail
           $support-entries
           $store-mode
           $callback-port
           $callback-url)))))

(= (codex:mcp-dependency-oauth-login-plan-for-entry
      $entry
      $support-entries
      $store-mode
      $callback-port
      $callback-url)
   (let $name (codex:mcp-server-entry-name $entry)
     (let $server-config (codex:mcp-server-entry-config $entry)
       (let $support-entry
         (codex:mcp-dependency-oauth-support-entry-by-name
           $support-entries
           $name)
         (if (== $support-entry CodexAbsent)
             ()
             (let $support
               (codex:mcp-dependency-oauth-support-entry-support
                 $support-entry)
               (if (== $support (codex:mcp-oauth-login-support-unsupported))
                   ()
                   (case $support
                     (((CodexMcpOAuthLoginSupportUnknown $error)
                       ((codex:mcp-dependency-oauth-warn-op
                          (codex:mcp-dependency-oauth-unknown-support-message
                            $name
                            $error))))
                      ((CodexMcpOAuthLoginSupportSupported $oauth-config)
                       (let $resolved-scopes
                         (codex:resolve-mcp-oauth-scopes
                           CodexAbsent
                           (codex:mcp-server-config-scopes $server-config)
                           (codex:mcp-oauth-login-config-discovered-scopes
                             $oauth-config))
                         ((codex:mcp-dependency-oauth-notify-op
                            (codex:mcp-dependency-oauth-authenticating-message
                              $name))
                          (codex:mcp-dependency-oauth-login-attempt-for
                            $name
                            $oauth-config
                            $server-config
                            $store-mode
                            $callback-port
                            $callback-url
                            (codex:resolved-mcp-oauth-scopes-scopes
                              $resolved-scopes))))))))))))))

(= (codex:mcp-dependency-oauth-first-attempt-result-plan
      $name
      $oauth-config
      $server-config
      $store-mode
      $callback-port
      $callback-url
      $resolved-scopes
      $first-result)
   (if (== $first-result (codex:mcp-dependency-oauth-login-ok))
       ()
       (case $first-result
         (((CodexMcpDependencyOAuthLoginErr $error)
           (if (codex:mcp-oauth-should-retry-without-scopes
                 $resolved-scopes
                 $error)
               ((codex:mcp-dependency-oauth-notify-op
                  (codex:mcp-dependency-oauth-retrying-message $name))
                (codex:mcp-dependency-oauth-login-attempt-for
                  $name
                  $oauth-config
                  $server-config
                  $store-mode
                  $callback-port
                  $callback-url
                  ()))
               ((codex:mcp-dependency-oauth-warn-op
                  (codex:mcp-dependency-oauth-failed-login-message
                    $name
                    $error)))))))))

(= (codex:mcp-dependency-oauth-retry-result-plan $name $retry-result)
   (if (== $retry-result (codex:mcp-dependency-oauth-login-ok))
       ()
       (case $retry-result
         (((CodexMcpDependencyOAuthLoginErr $error)
           ((codex:mcp-dependency-oauth-warn-op
              (codex:mcp-dependency-oauth-failed-login-message
                $name
                $error))))))))

(= (codex:mcp-dependency-refresh-overlay-servers
      $effective-servers
      ())
   $effective-servers)

(= (codex:mcp-dependency-refresh-overlay-servers
      $effective-servers
      $updated-global-servers)
   (let $entry (list:first $updated-global-servers)
     (let $tail (list:rest $updated-global-servers)
       (if (codex:mcp-server-entry-list-contains-name
             $effective-servers
             (codex:mcp-server-entry-name $entry))
           (codex:mcp-dependency-refresh-overlay-servers
             $effective-servers
             $tail)
           (codex:mcp-dependency-refresh-overlay-servers
             (list:append $effective-servers ($entry))
             $tail)))))

(= (codex:mcp-dependency-refresh-servers-plan
      $effective-servers
      $updated-global-servers
      $store-mode)
   (codex:mcp-dependency-refresh-servers-op
     (codex:mcp-dependency-refresh-overlay-servers
       $effective-servers
       $updated-global-servers)
     $store-mode))

(= (codex:mcp-server-entries-by-sorted-names () $entries)
   ())

(= (codex:mcp-server-entries-by-sorted-names $names $entries)
   (let $name (list:first $names)
     (let $tail (list:rest $names)
       (case (codex:mcp-server-entry-by-name $entries $name)
         ((Empty
           (codex:mcp-server-entries-by-sorted-names $tail $entries))
          ($entry
           (list:append
             ($entry)
             (codex:mcp-server-entries-by-sorted-names
               $tail
               $entries))))))))

(= (codex:mcp-server-entries-sort-by-name $entries)
   (let $names (once (eval (codex:mcp-server-entry-names $entries)))
     (case (sort-strings $names)
       ((() ())
        ($sorted-names
         (codex:mcp-server-entries-by-sorted-names
           $sorted-names
           $entries))))))

(= (codex:mcp-dependency-install-merge-plan $global-servers $missing)
   (codex:mcp-dependency-install-merge-plan-inner
     $missing
     (codex:mcp-dependency-install-merge-state
       False
       $global-servers
       ())))

(= (codex:mcp-dependency-install-merge-plan-inner () $state)
   $state)

(= (codex:mcp-dependency-install-merge-plan-inner
      $missing
      (CodexMcpDependencyInstallMergeState $updated $servers $added))
   (let $entry (list:first $missing)
     (let $tail (list:rest $missing)
       (let $name (codex:mcp-server-entry-name $entry)
         (if (codex:mcp-server-entry-list-contains-name $servers $name)
             (codex:mcp-dependency-install-merge-plan-inner
               $tail
               (codex:mcp-dependency-install-merge-state
                 $updated
                 $servers
                 $added))
             (codex:mcp-dependency-install-merge-plan-inner
               $tail
               (codex:mcp-dependency-install-merge-state
                 True
                 (codex:mcp-server-entries-sort-by-name
                   (list:append $servers ($entry)))
                 (list:append $added ($entry)))))))))

(= (codex:maybe-install-mcp-dependencies-plan
      $skill-mcp-dependency-install-enabled
      $codex-home
      $mentioned-skills
      $configured-servers
      $global-load-result)
   (if (or
         (== $mentioned-skills ())
         (not $skill-mcp-dependency-install-enabled))
       (codex:mcp-dependency-install-skip "disabled_or_no_skills")
       (let $missing
         (codex:collect-missing-mcp-dependencies
           $mentioned-skills
           $configured-servers)
         (if (== $missing ())
             (codex:mcp-dependency-install-skip "nothing_missing")
             (case $global-load-result
               (((CodexMcpDependencyLoadGlobalServersError $message)
                 (codex:mcp-dependency-install-load-error $message))
                ((CodexMcpDependencyLoadGlobalServersOk $global-servers)
                 (let $merge
                   (codex:mcp-dependency-install-merge-plan
                     $global-servers
                     $missing)
                   (if (codex:mcp-dependency-install-merge-state-updated
                         $merge)
                       (let $updated-global-servers
                         (codex:mcp-dependency-install-merge-state-servers
                           $merge)
                         (codex:mcp-dependency-install-ready
                           $missing
                           $updated-global-servers
                           (codex:mcp-dependency-install-merge-state-added
                             $merge)
                           (codex:mcp-dependency-persist-servers-op
                             $codex-home
                             $updated-global-servers)))
                       (codex:mcp-dependency-install-skip
                         "nothing_new_in_global_config"))))))))))

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
