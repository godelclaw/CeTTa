; Rust-faithful ToolRouter::build_tool_call slice.
;
; This ports deterministic behavior from:
; - openai-codex/codex-rs/core/src/tools/router.rs
;   - ToolRouter::build_tool_call
; - openai-codex/codex-rs/protocol/src/models.rs
;   - SearchToolCallParams
;   - LocalShellAction::Exec -> ShellToolCallParams projection
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust resolves MCP tool metadata asynchronously through Session. This pure
;   slice receives the already-visible MCP tool info list as an explicit input
;   and applies the same canonical ToolName equality rule before constructing
;   an MCP payload.
; - Rust's serde_json error messages are produced by serde. This slice exposes
;   the same successful SearchToolCallParams projection and keeps malformed
;   parse handling at the explicit CeTTa JSON parse boundary for a later
;   fallible-serde compatibility pass.
; - Rust's LocalShellAction carries env/user, but ShellToolCallParams does not.
;   The full CeTTa local-shell action helper accepts those fields and drops
;   them when projecting to the same ShellToolCallParams fields Rust builds.

!(import! &self function_tool)
!(import! &self json)
!(import! &self str)
!(import! &self tool_router_dispatch_plan)

(= (codex:tool-router-build-tool-call-ok $tool-call)
   (CodexToolRouterBuildToolCallOk $tool-call))

(= (codex:tool-router-build-tool-call-none)
   (CodexToolRouterBuildToolCallNone))

(= (codex:tool-router-build-tool-call-error $error)
   (CodexToolRouterBuildToolCallError $error))

(= (codex:tool-router-build-tool-call-result-tool-call
      (CodexToolRouterBuildToolCallOk $tool-call))
   $tool-call)

(= (codex:tool-router-build-tool-call-result-error
      (CodexToolRouterBuildToolCallError $error))
   $error)

(= (codex:tool-router-build-mcp-tool-info
      $callable-namespace
      $callable-name
      $server-name
      $tool-name)
   (CodexToolRouterBuildMcpToolInfo
     $callable-namespace
     $callable-name
     $server-name
     $tool-name))

(= (codex:tool-router-build-mcp-tool-info-canonical-tool-name
      (CodexToolRouterBuildMcpToolInfo
        $callable-namespace
        $callable-name
        $server-name
        $tool-name))
   (codex:namespaced-tool-name $callable-namespace $callable-name))

(= (codex:tool-router-build-mcp-tool-info-server-name
      (CodexToolRouterBuildMcpToolInfo
        $callable-namespace
        $callable-name
        $server-name
        $tool-name))
   $server-name)

(= (codex:tool-router-build-mcp-tool-info-tool-name
      (CodexToolRouterBuildMcpToolInfo
        $callable-namespace
        $callable-name
        $server-name
        $tool-name))
   $tool-name)

(= (codex:tool-router-build-tool-name-equal
      (CodexToolName $left-name $left-namespace)
      (CodexToolName $right-name $right-namespace))
   (and (== $left-name $right-name)
        (== $left-namespace $right-namespace)))

(= (codex:tool-router-build-resolve-mcp-tool-info
      ()
      $tool-name)
   CodexAbsent)

(= (codex:tool-router-build-resolve-mcp-tool-info
      $tool-infos
      $tool-name)
   (let ($head $tail) (decons-atom $tool-infos)
     (if (codex:tool-router-build-tool-name-equal
           (codex:tool-router-build-mcp-tool-info-canonical-tool-name
             $head)
           $tool-name)
         $head
         (codex:tool-router-build-resolve-mcp-tool-info
           $tail
           $tool-name))))

(= (codex:tool-router-build-function-call
      $mcp-tool-infos
      $name
      $namespace
      $arguments
      $call-id)
   (let $tool-name (codex:tool-name $namespace $name)
     (case (codex:tool-router-build-resolve-mcp-tool-info
             $mcp-tool-infos
             $tool-name)
       ((CodexAbsent
         (codex:tool-router-build-tool-call-ok
           (codex:tool-router-dispatch-tool-call
             $tool-name
             $call-id
             (codex:tool-router-dispatch-function-payload
               $arguments))))
        ((CodexToolRouterBuildMcpToolInfo
           $callable-namespace
           $callable-name
           $server-name
           $mcp-tool-name)
         (codex:tool-router-build-tool-call-ok
           (codex:tool-router-dispatch-tool-call
             (codex:tool-router-build-mcp-tool-info-canonical-tool-name
               (CodexToolRouterBuildMcpToolInfo
                 $callable-namespace
                 $callable-name
                 $server-name
                 $mcp-tool-name))
             $call-id
             (codex:tool-router-dispatch-mcp-payload
               $server-name
               $mcp-tool-name
               $arguments))))))))

(= (codex:tool-router-build-decimal-digit-value "0")
   0)

(= (codex:tool-router-build-decimal-digit-value "1")
   1)

(= (codex:tool-router-build-decimal-digit-value "2")
   2)

(= (codex:tool-router-build-decimal-digit-value "3")
   3)

(= (codex:tool-router-build-decimal-digit-value "4")
   4)

(= (codex:tool-router-build-decimal-digit-value "5")
   5)

(= (codex:tool-router-build-decimal-digit-value "6")
   6)

(= (codex:tool-router-build-decimal-digit-value "7")
   7)

(= (codex:tool-router-build-decimal-digit-value "8")
   8)

(= (codex:tool-router-build-decimal-digit-value "9")
   9)

(= (codex:tool-router-build-decimal-string-to-number $text)
   (if (== $text "")
       0
       (codex:tool-router-build-decimal-string-to-number-from
         $text
         0
         0)))

(= (codex:tool-router-build-decimal-string-to-number-from
      $text
      $index
      $acc)
   (if (== $index (str-length $text))
       $acc
       (let $digit-char (str-slice $text $index (+ $index 1))
         (codex:tool-router-build-decimal-string-to-number-from
           $text
           (+ $index 1)
           (+ (* $acc 10)
              (codex:tool-router-build-decimal-digit-value
                $digit-char))))))

(= (codex:tool-router-build-json-object-optional-value $object $key)
   (case (json-object-get $object $key)
     ((Empty CodexAbsent)
      (JsonNull CodexAbsent)
      ($value $value))))

(= (codex:tool-router-build-json-object-optional-number $object $key)
   (case (codex:tool-router-build-json-object-optional-value $object $key)
     ((CodexAbsent CodexAbsent)
      ((JsonNumber $value)
       (codex:tool-router-build-decimal-string-to-number
         (format-args "{}" ($value)))))))

(= (codex:tool-router-build-tool-search-arguments-json (JsonObject $pairs))
   (JsonObject $pairs))

(= (codex:tool-router-build-tool-search-arguments-json $arguments)
   (json-parse $arguments))

(= (codex:tool-router-build-tool-search-query $object)
   (json-string-value (json-object-get $object "query")))

(= (codex:tool-router-build-tool-search-limit $object)
   (codex:tool-router-build-json-object-optional-number $object "limit"))

(= (codex:tool-router-build-tool-search-call
      $call-id
      $execution
      $arguments)
   (if (and (not (== $call-id CodexAbsent))
            (== $execution "client"))
       (let $object
         (codex:tool-router-build-tool-search-arguments-json $arguments)
         (codex:tool-router-build-tool-call-ok
           (codex:tool-router-dispatch-tool-call
             (codex:plain-tool-name "tool_search")
             $call-id
             (codex:tool-router-dispatch-tool-search-payload
               (codex:tool-router-build-tool-search-query $object)
               (codex:tool-router-build-tool-search-limit $object)))))
       (codex:tool-router-build-tool-call-none)))

(= (codex:tool-router-build-local-shell-action-full
      $command
      $timeout-ms
      $working-directory
      $env
      $user)
   (CodexLocalShellExecActionFull
     $command
     $timeout-ms
     $working-directory
     $env
     $user))

(= (codex:tool-router-build-sandbox-permissions-use-default)
   "use_default")

(= (codex:tool-router-build-local-shell-call-id $call-id $id)
   (if (not (== $call-id CodexAbsent))
       (CodexToolRouterBuildLocalShellCallIdOk $call-id)
       (if (not (== $id CodexAbsent))
           (CodexToolRouterBuildLocalShellCallIdOk $id)
           (CodexToolRouterBuildLocalShellCallIdError
             (CodexFunctionCallErrorMissingLocalShellCallId)))))

(= (codex:tool-router-build-local-shell-payload
      (CodexLocalShellExecAction $command))
   (codex:tool-router-dispatch-local-shell-params-payload
     $command
     CodexAbsent
     CodexAbsent
     (codex:tool-router-build-sandbox-permissions-use-default)
     CodexAbsent
     CodexAbsent
     CodexAbsent))

(= (codex:tool-router-build-local-shell-payload
      (CodexLocalShellExecActionFull
        $command
        $timeout-ms
        $working-directory
        $env
        $user))
   (codex:tool-router-dispatch-local-shell-params-payload
     $command
     $working-directory
     $timeout-ms
     (codex:tool-router-build-sandbox-permissions-use-default)
     CodexAbsent
     CodexAbsent
     CodexAbsent))

(= (codex:tool-router-build-local-shell-payload
      (CodexArcMonitorLocalShellExecAction
        $command
        $timeout-ms
        $working-directory
        $env
        $user))
   (codex:tool-router-dispatch-local-shell-params-payload
     $command
     $working-directory
     $timeout-ms
     (codex:tool-router-build-sandbox-permissions-use-default)
     CodexAbsent
     CodexAbsent
     CodexAbsent))

(= (codex:tool-router-build-local-shell-call
      $id
      $call-id
      $action)
   (case (codex:tool-router-build-local-shell-call-id $call-id $id)
     (((CodexToolRouterBuildLocalShellCallIdOk $resolved-call-id)
       (codex:tool-router-build-tool-call-ok
         (codex:tool-router-dispatch-tool-call
           (codex:plain-tool-name "local_shell")
           $resolved-call-id
           (codex:tool-router-build-local-shell-payload $action))))
      ((CodexToolRouterBuildLocalShellCallIdError $error)
       (codex:tool-router-build-tool-call-error $error)))))

(= (codex:tool-router-build-tool-call
      $mcp-tool-infos
      (CodexResponseItemFunctionCall
        $id
        $name
        $namespace
        $arguments
        $call-id))
   (codex:tool-router-build-function-call
     $mcp-tool-infos
     $name
     $namespace
     $arguments
     $call-id))

(= (codex:tool-router-build-tool-call
      $mcp-tool-infos
      (CodexResponseItemToolSearchCall
        $id
        $call-id
        $status
        $execution
        $arguments))
   (codex:tool-router-build-tool-search-call
     $call-id
     $execution
     $arguments))

(= (codex:tool-router-build-tool-call
      $mcp-tool-infos
      (CodexResponseItemCustomToolCall $call-id $name $input))
   (codex:tool-router-build-tool-call-ok
     (codex:tool-router-dispatch-tool-call
       (codex:plain-tool-name $name)
       $call-id
       (codex:tool-router-dispatch-custom-payload $input))))

(= (codex:tool-router-build-tool-call
      $mcp-tool-infos
      (CodexResponseItemLocalShellCall $id $call-id $status $action))
   (codex:tool-router-build-local-shell-call
     $id
     $call-id
     $action))

(= (codex:tool-router-build-tool-call
      $mcp-tool-infos
      (CodexResponseItemMessage $role $content $phase))
   (codex:tool-router-build-tool-call-none))

(= (codex:tool-router-build-tool-call
      $mcp-tool-infos
      (CodexResponseItemMessageWithId $id $role $content $phase))
   (codex:tool-router-build-tool-call-none))

(= (codex:tool-router-build-tool-call
      $mcp-tool-infos
      (CodexResponseItemReasoning $id $summary $content $encrypted-content))
   (codex:tool-router-build-tool-call-none))

(= (codex:tool-router-build-tool-call
      $mcp-tool-infos
      (CodexResponseItemFunctionCallOutput $call-id $output))
   (codex:tool-router-build-tool-call-none))

(= (codex:tool-router-build-tool-call
      $mcp-tool-infos
      (CodexResponseItemCustomToolCallOutput $call-id $name $output))
   (codex:tool-router-build-tool-call-none))

(= (codex:tool-router-build-tool-call
      $mcp-tool-infos
      (CodexResponseItemToolSearchOutput
        $call-id
        $status
        $execution
        $tools))
   (codex:tool-router-build-tool-call-none))

(= (codex:tool-router-build-tool-call
      $mcp-tool-infos
      (CodexResponseItemWebSearchCall $id $status $action))
   (codex:tool-router-build-tool-call-none))

(= (codex:tool-router-build-tool-call
      $mcp-tool-infos
      (CodexResponseItemImageGenerationCall
        $id
        $status
        $result
        $error
        $revised-prompt
        $partial-images
        $output-format))
   (codex:tool-router-build-tool-call-none))
