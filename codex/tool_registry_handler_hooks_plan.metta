; Rust-faithful ToolRegistry handler hook-payload planning slice.
;
; This ports deterministic handler methods used by:
; - openai-codex/codex-rs/core/src/tools/registry.rs
;   - handler.pre_tool_use_payload(&invocation)
;   - handler.post_tool_use_payload(&invocation, &output)
; - openai-codex/codex-rs/core/src/tools/handlers/unified_exec.rs
; - openai-codex/codex-rs/core/src/tools/handlers/apply_patch.rs
;
; Covered in this increment:
; - registry binding kind dispatch for currently ported hook-producing handlers
; - unified_exec pre-hook payload for plain `exec_command` function calls
; - unified_exec post-hook payload for completed ExecCommandToolOutput
; - apply_patch pre/post hook payloads for function and custom payloads
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust calls trait-object methods on concrete handlers. This pure CeTTa plan
;   dispatches by the handler kind already stored in ToolRegistryHandlerBinding.
; - Rust's unified_exec `is_mutating` gate depends on command parsing, shell
;   resolution, and `is_known_safe_command`. That async gate is intentionally not
;   represented here; this slice only ports hook payload selection.
; - The context and tools slices both currently define legacy
;   codex:json-object-optional-* helpers. Importing both in one module multiplies
;   parse branches, so this slice uses tools' matching truncation helper directly
;   instead of importing context solely for ExecCommandToolOutput projection.
; - Rust hook methods return one Option. CeTTa fallback equations can enumerate
;   beside the matching branch, so these dispatch helpers use single case/if
;   bodies to keep the same deterministic surface behavior.

!(import! &self tools)
!(import! &self tool_registry_plan)
!(import! &self tool_router_dispatch_plan)

(= (codex:tool-registry-handler-unified-exec-pre-tool-use-payload
      $invocation)
   (case $invocation
     (((CodexToolInvocation
         $session
         $turn
         $cancellation-token
         $tracker
         $call-id
         (CodexToolName "exec_command" CodexAbsent)
         $source
         (CodexToolPayloadFunction $arguments))
       (codex:exec-command-pre-tool-use-payload-from-input $arguments))
      ($other Empty))))

(= (codex:tool-registry-handler-apply-patch-pre-tool-use-payload
      $invocation)
   (codex:apply-patch-pre-tool-use-payload
     (codex:tool-router-tool-invocation-payload $invocation)))

(= (codex:tool-registry-handler-pre-tool-use-payload
      (CodexToolRegistryHandlerBinding $name $kind)
      $invocation)
   (if (== $kind (codex:tool-handler-kind-unified-exec))
       (codex:tool-registry-handler-unified-exec-pre-tool-use-payload
         $invocation)
       (if (== $kind (codex:tool-handler-kind-apply-patch))
           (codex:tool-registry-handler-apply-patch-pre-tool-use-payload
             $invocation)
           Empty)))

(= (codex:tool-registry-handler-exec-output-post-tool-use-response
      $output)
   (case $output
     (((CodexToolOutputExecCommand
         $event-call-id
         $chunk-id
         $wall-time-ms
         $raw-output
         $max-output-tokens
         CodexAbsent
         $exit-code
         $original-token-count
         $hook-command)
       (if (or (== $hook-command CodexAbsent)
               (== $hook-command ""))
           Empty
           (JsonString
             (codex:format-truncated-output $raw-output $max-output-tokens))))
      ($other Empty))))

(= (codex:tool-registry-handler-unified-exec-post-tool-use-id
      $call-id
      $event-call-id)
   (if (== $event-call-id "")
       $call-id
       $event-call-id))

(= (codex:tool-registry-handler-unified-exec-post-tool-use-payload
      $invocation
      $output)
   (case ($invocation $output)
     ((((CodexToolInvocation
          $session
          $turn
          $cancellation-token
          $tracker
          $call-id
          $tool-name
          $source
          (CodexToolPayloadFunction $arguments))
        (CodexToolOutputExecCommand
          $event-call-id
          $chunk-id
          $wall-time-ms
          $raw-output
          $max-output-tokens
          CodexAbsent
          $exit-code
          $original-token-count
          $hook-command))
       (let $tool-response
         (codex:tool-registry-handler-exec-output-post-tool-use-response
           (CodexToolOutputExecCommand
             $event-call-id
             $chunk-id
             $wall-time-ms
             $raw-output
             $max-output-tokens
             CodexAbsent
             $exit-code
             $original-token-count
             $hook-command))
         (if (== $tool-response Empty)
             Empty
             (codex:post-tool-use-payload
               (codex:hook-tool-name-bash)
               (codex:tool-registry-handler-unified-exec-post-tool-use-id
                 $call-id
                 $event-call-id)
               (codex:hook-command-input-json $hook-command)
               $tool-response))))
      ($other Empty))))

(= (codex:tool-registry-handler-apply-patch-post-tool-use-payload
      $invocation
      $output)
   (codex:apply-patch-post-tool-use-payload
     (codex:tool-router-tool-invocation-call-id $invocation)
     (codex:tool-router-tool-invocation-payload $invocation)
     $output))

(= (codex:tool-registry-handler-post-tool-use-payload
      (CodexToolRegistryHandlerBinding $name $kind)
      $invocation
      $output)
   (if (== $kind (codex:tool-handler-kind-unified-exec))
       (codex:tool-registry-handler-unified-exec-post-tool-use-payload
         $invocation
         $output)
       (if (== $kind (codex:tool-handler-kind-apply-patch))
           (codex:tool-registry-handler-apply-patch-post-tool-use-payload
             $invocation
             $output)
           Empty)))
