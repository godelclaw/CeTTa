; Visible minimal tool-execution slice for the restarted Codex port.
;
; This ports the narrowest runnable `exec_command` path from
; openai-codex/codex-rs/core/src/tools/{handlers/unified_exec.rs,context.rs}
; and codex-rs/core/src/unified_exec/mod.rs:
; - exec_command JSON argument decoding
; - shell selection and argv derivation
; - running/completed unified-exec output formatting
; - write_stdin JSON decoding and lowering
; - custom-tool-call -> custom-tool-call-output lowering for exec_command and
;   write_stdin
; - unified-exec pre/post hook payload helpers
;
; Required slice-local deviations from Rust, documented for later audit:
; - Rust generates random six-hex chunk IDs. This slice derives a stable chunk
;   marker from the tool call id because the current CeTTa library surface has
;   no RNG helper yet.
; - Rust truncation preserves UTF-8 scalar boundaries. CeTTa's current
;   `str-slice` surface is byte-indexed, so the truncation helper is
;   byte-oriented in this slice. The demo/tests keep ASCII output until a
;   scalar-aware string helper lands.
; - Rust does not need a helper to resume a prior exec result object because
;   its async handler layer can naturally thread `session_id` into a later
;   write_stdin tool call. This slice adds an internal
;   `codex:run-exec-command-then-write-stdin-result` helper only for
;   deterministic local surface coverage, because the current evaluator is
;   still brittle when a single `.metta` file tries to rebuild follow-on JSON
;   from a prior result. The public `write_stdin` tool path remains unchanged,
;   but the helper keeps the resumed-session metadata lane auditable. When the
;   initial open already settles before the synthetic follow-up poll, the
;   helper now returns that settled run directly instead of fabricating a
;   write_stdin error, because the watcher-backed session runtime can now
;   complete that fast.
; - Rust applies `apply_patch` interception inside unified_exec. The restarted
;   CeTTa tool layer does not yet have the full unified_exec/orchestrator
;   stack, so the visible interception is wired at the custom-tool-call
;   lowering surface instead. This preserves the exec_command behavior that is
;   user-visible in the current restart slices.
; - Rust threads unified-exec shell mode and login-shell allowance from the
;   session/tool config layer. This slice now ports the `get_command()`
;   algorithm itself, including explicit-login rejection and zsh-fork shell
;   selection, but the public visible `exec_command` path still feeds it the
;   default runtime config (`Direct`, default session shell,
;   `allow_login_shell = true`) until the higher config layer is ported.
; - The restarted tool surface does not yet expose the full unified-exec
;   approval/session config. This slice now ports Rust-shaped
;   `sandbox_permissions` / `additional_permissions` parsing, validation, and
;   request_permissions grant carry-over through explicit visible state, but
;   the native process runtime is still unsandboxed. The merged permission
;   profile therefore gates execution and feeds the visible `apply_patch`
;   intercept lane, but it cannot yet constrain arbitrary spawned processes.
; - Rust streams exec output as many delta events with original read chunk
;   boundaries and raw bytes. The current CeTTa session snapshot surface only
;   exposes per-poll unread stdout/stderr text, so the visible event helpers
;   reconstruct at most one delta per stream per poll. Embedded NUL bytes are
;   also not preserved through the current text atom surface, so event chunks
;   remain faithful for ordinary text output but not yet for arbitrary binary
;   output.
; - Rust threads unified-exec hook payloads through the registry/runtime layer.
;   The restarted CeTTa slice exposes deterministic helper constructors for the
;   same pre/post payload decisions instead of a full hook runtime.
; - Direct `apply_patch` execution and exec_command interception therefore use
;   the current local CLI assumptions from `codex:apply_patch`.

!(import! &self apply_patch)
!(import! &self command)
!(import! &self json)
!(import! &self list_dir)
!(import! &self list)
!(import! &self path)
!(import! &self process)
!(import! &self protocol)
!(import! &self request_permissions)
!(import! &self request_user_input)
!(import! &self update_plan)
!(import! &self str)
!(import! &self system)

(= (codex:default-exec-yield-time-ms)
   10000)

(= (codex:default-write-stdin-yield-time-ms)
   250)

(= (codex:minimum-exec-yield-time-ms)
   250)

(= (codex:maximum-exec-yield-time-ms)
   30000)

(= (codex:default-max-output-tokens)
   10000)

(= (codex:maximum-raw-output-bytes)
   1048576)

(= (codex:sandbox-permissions-use-default)
   "use_default")

(= (codex:sandbox-permissions-with-additional-permissions)
   "with_additional_permissions")

(= (codex:sandbox-permissions-require-escalated)
   "require_escalated")

(= (codex:json-object-optional-value $object $key)
   (case (json-object-get $object $key)
     ((Empty CodexAbsent)
      (JsonNull CodexAbsent)
      ($value $value))))

(= (codex:json-object-required-string $object $key)
   (json-string-value (json-object-get $object $key)))

(= (codex:json-object-required-int $object $key)
   (codex:decimal-string-to-number
     (json-number-value (json-object-get $object $key))))

(= (codex:json-object-optional-string $object $key)
   (case (codex:json-object-optional-value $object $key)
     ((CodexAbsent CodexAbsent)
      ((JsonString $text) $text))))

(= (codex:json-object-optional-bool $object $key)
   (case (codex:json-object-optional-value $object $key)
     ((CodexAbsent CodexAbsent)
      ((JsonBool $value) $value))))

(= (codex:json-object-optional-int $object $key)
   (case (codex:json-object-optional-value $object $key)
     ((CodexAbsent CodexAbsent)
      ((JsonNumber $text) (codex:decimal-string-to-number $text)))))

(= (codex:json-object-optional-object $object $key)
   (codex:request-permissions-json-object-optional-object $object $key))

(= (codex:json-object-optional-array $object $key)
   (codex:request-permissions-json-object-optional-array $object $key))

(= (codex:decimal-digit-value "0")
   0)

(= (codex:decimal-digit-value "1")
   1)

(= (codex:decimal-digit-value "2")
   2)

(= (codex:decimal-digit-value "3")
   3)

(= (codex:decimal-digit-value "4")
   4)

(= (codex:decimal-digit-value "5")
   5)

(= (codex:decimal-digit-value "6")
   6)

(= (codex:decimal-digit-value "7")
   7)

(= (codex:decimal-digit-value "8")
   8)

(= (codex:decimal-digit-value "9")
   9)

(= (codex:decimal-string-to-number $text)
   (if (== $text "")
       0
       (codex:decimal-string-to-number-from $text 0 0)))

(= (codex:decimal-string-to-number-from $text $index $acc)
   (if (== $index (str-length $text))
       $acc
       (let $digit-char (str-slice $text $index (+ $index 1))
         (codex:decimal-string-to-number-from
           $text
           (+ $index 1)
           (+ (* $acc 10) (codex:decimal-digit-value $digit-char))))))

(= (codex:clamp-yield-time-ms $value)
   (if (< $value (codex:minimum-exec-yield-time-ms))
       (codex:minimum-exec-yield-time-ms)
       (if (> $value (codex:maximum-exec-yield-time-ms))
           (codex:maximum-exec-yield-time-ms)
           $value)))

(= (codex:resolve-tty $value)
   (if (== $value CodexAbsent)
       False
       $value))

(= (codex:resolve-max-output-tokens $value)
   (if (== $value CodexAbsent)
       (codex:default-max-output-tokens)
       $value))

(= (codex:resolve-sandbox-permissions CodexAbsent)
   (codex:sandbox-permissions-use-default))

(= (codex:resolve-sandbox-permissions $value)
   (if (== $value (codex:sandbox-permissions-with-additional-permissions))
       (codex:sandbox-permissions-with-additional-permissions)
       (if (== $value (codex:sandbox-permissions-require-escalated))
           (codex:sandbox-permissions-require-escalated)
           (codex:sandbox-permissions-use-default))))

(= (codex:resolve-yield-time-ms $value)
   (if (== $value CodexAbsent)
       (codex:default-exec-yield-time-ms)
       (codex:clamp-yield-time-ms $value)))

(= (codex:resolve-write-stdin-yield-time-ms $value)
   (if (== $value CodexAbsent)
       (codex:default-write-stdin-yield-time-ms)
       $value))

(= (codex:resolve-workdir $workdir)
   (if (== $workdir CodexAbsent)
       (system-cwd)
       (if (path-is-absolute? $workdir)
           (path-normalize $workdir)
           ; This keeps the same lexical normalization as `path-join`, but
           ; avoids the current evaluator sensitivity we repeatedly hit when a
           ; relative workdir is consumed through nested surface assertions.
           (path-normalize
             (str-concat
               (str-concat (system-cwd) "/")
               $workdir)))))

(= (codex:hook-tool-name $name $matcher-aliases)
   (CodexHookToolName $name $matcher-aliases))

(= (codex:hook-tool-name-bash)
   (codex:hook-tool-name "Bash" ()))

(= (codex:pre-tool-use-payload $tool-name $tool-input)
   (CodexPreToolUsePayload $tool-name $tool-input))

(= (codex:post-tool-use-payload
      $tool-name
      $tool-use-id
      $tool-input
      $tool-response)
   (CodexPostToolUsePayload
     $tool-name
     $tool-use-id
     $tool-input
     $tool-response))

(= (codex:hook-tool-name-name
      (CodexHookToolName $name $matcher-aliases))
   $name)

(= (codex:hook-tool-name-matcher-aliases
      (CodexHookToolName $name $matcher-aliases))
   $matcher-aliases)

(= (codex:pre-tool-use-payload-tool-name
      (CodexPreToolUsePayload $tool-name $tool-input))
   $tool-name)

(= (codex:pre-tool-use-payload-tool-input
      (CodexPreToolUsePayload $tool-name $tool-input))
   $tool-input)

(= (codex:post-tool-use-payload-tool-name
      (CodexPostToolUsePayload
        $tool-name
        $tool-use-id
        $tool-input
        $tool-response))
   $tool-name)

(= (codex:post-tool-use-payload-tool-use-id
      (CodexPostToolUsePayload
        $tool-name
        $tool-use-id
        $tool-input
        $tool-response))
   $tool-use-id)

(= (codex:post-tool-use-payload-tool-input
      (CodexPostToolUsePayload
        $tool-name
        $tool-use-id
        $tool-input
        $tool-response))
   $tool-input)

(= (codex:post-tool-use-payload-tool-response
      (CodexPostToolUsePayload
        $tool-name
        $tool-use-id
        $tool-input
        $tool-response))
   $tool-response)

(= (codex:hook-command-input-json $command)
   (JsonObject
     ((JsonPair "command" (JsonString $command)))))

(= (codex:hook-tool-name-json (CodexHookToolName $name $matcher-aliases))
   (JsonObject
     ((JsonPair "name" (JsonString $name))
      (JsonPair "matcher_aliases"
        (JsonArray
          (eval
            (map-atom
              $matcher-aliases
              $alias
              (JsonString $alias))))))))

(= (codex:pre-tool-use-payload-json
      (CodexPreToolUsePayload $tool-name $tool-input))
   (JsonObject
     ((JsonPair "tool_name" (codex:hook-tool-name-json $tool-name))
      (JsonPair "tool_input" $tool-input))))

(= (codex:post-tool-use-payload-json
      (CodexPostToolUsePayload
        $tool-name
        $tool-use-id
        $tool-input
        $tool-response))
   (JsonObject
     ((JsonPair "tool_name" (codex:hook-tool-name-json $tool-name))
      (JsonPair "tool_use_id" (JsonString $tool-use-id))
      (JsonPair "tool_input" $tool-input)
      (JsonPair "tool_response" $tool-response))))

(= (codex:parse-exec-command-args $input)
   (let $json (json-parse $input)
     (let $cmd (codex:json-object-required-string $json "cmd")
       (let $workdir (codex:json-object-optional-string $json "workdir")
         (let $resolved-workdir (codex:resolve-workdir $workdir)
           (let $shell (codex:json-object-optional-string $json "shell")
             (let $login (codex:json-object-optional-bool $json "login")
               (let $tty (codex:json-object-optional-bool $json "tty")
                 (let $yield-time-ms (codex:json-object-optional-int $json "yield_time_ms")
                   (let $max-output-tokens
                     (codex:json-object-optional-int $json "max_output_tokens")
                     (let $sandbox-permissions
                       (codex:resolve-sandbox-permissions
                         (codex:json-object-optional-string
                           $json
                           "sandbox_permissions"))
                       (let $additional-permissions-json
                         (codex:json-object-optional-object
                           $json
                           "additional_permissions")
                         (let $prefix-rule-json
                           (codex:json-object-optional-array
                             $json
                             "prefix_rule")
                           (CodexExecCommandArgs
                             $cmd
                             $resolved-workdir
                             $shell
                             $login
                             (codex:resolve-tty $tty)
                             (codex:resolve-yield-time-ms $yield-time-ms)
                             (codex:resolve-max-output-tokens $max-output-tokens)
                             $sandbox-permissions
                             (if (== $additional-permissions-json CodexAbsent)
                                 CodexAbsent
                                 (codex:normalize-request-permission-profile
                                   $resolved-workdir
                                   (codex:request-permission-profile-from-json
                                     $additional-permissions-json)))
                             (codex:json-object-optional-string
                               $json
                               "justification")
                             (if (== $prefix-rule-json CodexAbsent)
                                 CodexAbsent
                                 (codex:request-permissions-string-array-from-optional-json
                                   $prefix-rule-json))))))))))))))))

(= (codex:parse-write-stdin-args $input)
   (let $json (json-parse $input)
     (let $chars (codex:json-object-optional-string $json "chars")
       (let $yield-time-ms (codex:json-object-optional-int $json "yield_time_ms")
         (let $max-output-tokens
           (codex:json-object-optional-int $json "max_output_tokens")
           (CodexWriteStdinArgs
             (codex:json-object-required-int $json "session_id")
             (if (== $chars CodexAbsent) "" $chars)
             (codex:resolve-write-stdin-yield-time-ms $yield-time-ms)
             (codex:resolve-max-output-tokens $max-output-tokens)))))))

(= (codex:exec-command-text
      (CodexExecCommandArgs
        $cmd
        $workdir
        $shell
        $use-login-shell
        $tty
        $yield-time-ms
        $max-output-tokens
        $sandbox-permissions
        $additional-permissions
        $justification
        $prefix-rule))
   $cmd)

(= (codex:exec-command-cwd
      (CodexExecCommandArgs
        $cmd
        $workdir
        $shell
        $use-login-shell
        $tty
        $yield-time-ms
        $max-output-tokens
        $sandbox-permissions
        $additional-permissions
        $justification
        $prefix-rule))
   $workdir)

(= (codex:exec-command-shell
      (CodexExecCommandArgs
        $cmd
        $workdir
        $shell
        $use-login-shell
        $tty
        $yield-time-ms
        $max-output-tokens
        $sandbox-permissions
        $additional-permissions
        $justification
        $prefix-rule))
   $shell)

(= (codex:exec-command-login-shell
      (CodexExecCommandArgs
        $cmd
        $workdir
        $shell
        $use-login-shell
        $tty
        $yield-time-ms
        $max-output-tokens
        $sandbox-permissions
        $additional-permissions
        $justification
        $prefix-rule))
   $use-login-shell)

(= (codex:exec-command-tty
      (CodexExecCommandArgs
        $cmd
        $workdir
        $shell
        $use-login-shell
        $tty
        $yield-time-ms
        $max-output-tokens
        $sandbox-permissions
        $additional-permissions
        $justification
        $prefix-rule))
   $tty)

(= (codex:exec-command-yield-time-ms
      (CodexExecCommandArgs
        $cmd
        $workdir
        $shell
        $use-login-shell
        $tty
        $yield-time-ms
        $max-output-tokens
        $sandbox-permissions
        $additional-permissions
        $justification
        $prefix-rule))
   $yield-time-ms)

(= (codex:exec-command-max-output-tokens
      (CodexExecCommandArgs
        $cmd
        $workdir
        $shell
        $use-login-shell
        $tty
        $yield-time-ms
        $max-output-tokens
        $sandbox-permissions
        $additional-permissions
        $justification
        $prefix-rule))
   $max-output-tokens)

(= (codex:exec-command-sandbox-permissions
      (CodexExecCommandArgs
        $cmd
        $workdir
        $shell
        $use-login-shell
        $tty
        $yield-time-ms
        $max-output-tokens
        $sandbox-permissions
        $additional-permissions
        $justification
        $prefix-rule))
   $sandbox-permissions)

(= (codex:exec-command-additional-permissions
      (CodexExecCommandArgs
        $cmd
        $workdir
        $shell
        $use-login-shell
        $tty
        $yield-time-ms
        $max-output-tokens
        $sandbox-permissions
        $additional-permissions
        $justification
        $prefix-rule))
   $additional-permissions)

(= (codex:exec-command-justification
      (CodexExecCommandArgs
        $cmd
        $workdir
        $shell
        $use-login-shell
        $tty
        $yield-time-ms
        $max-output-tokens
        $sandbox-permissions
        $additional-permissions
        $justification
        $prefix-rule))
   $justification)

(= (codex:exec-command-prefix-rule
      (CodexExecCommandArgs
        $cmd
        $workdir
        $shell
        $use-login-shell
        $tty
        $yield-time-ms
        $max-output-tokens
        $sandbox-permissions
        $additional-permissions
        $justification
        $prefix-rule))
   $prefix-rule)

(= (codex:exec-command-context $approval-policy $additional-permissions-allowed)
   (CodexExecCommandContext $approval-policy $additional-permissions-allowed))

(= (codex:exec-command-runtime-config
      $session-shell
      $shell-mode
      $allow-login-shell)
   (CodexExecCommandRuntimeConfig
     $session-shell
     $shell-mode
     $allow-login-shell))

(= (codex:direct-shell-mode)
   CodexUnifiedExecShellModeDirect)

(= (codex:zsh-fork-shell-mode $shell-zsh-path $main-execve-wrapper-exe)
   (CodexUnifiedExecShellModeZshFork
     $shell-zsh-path
     $main-execve-wrapper-exe))

(= (codex:default-exec-command-runtime-config)
   (codex:exec-command-runtime-config
     (process-default-shell)
     (codex:direct-shell-mode)
     True))

(= (codex:default-exec-command-context)
   (codex:exec-command-context
     (codex:ask-for-approval-never)
     False))

(= (codex:exec-command-context-approval-policy
      (CodexExecCommandContext $approval-policy $additional-permissions-allowed))
   $approval-policy)

(= (codex:exec-command-context-additional-permissions-allowed
      (CodexExecCommandContext $approval-policy $additional-permissions-allowed))
   $additional-permissions-allowed)

(= (codex:exec-command-runtime-config-session-shell
      (CodexExecCommandRuntimeConfig
        $session-shell
        $shell-mode
        $allow-login-shell))
   $session-shell)

(= (codex:exec-command-runtime-config-shell-mode
      (CodexExecCommandRuntimeConfig
        $session-shell
        $shell-mode
        $allow-login-shell))
   $shell-mode)

(= (codex:exec-command-runtime-config-allow-login-shell
      (CodexExecCommandRuntimeConfig
        $session-shell
        $shell-mode
        $allow-login-shell))
   $allow-login-shell)

(= (codex:exec-command-permission-plan-type
      (CodexExecCommandPermissionPlanOk
        $sandbox-permissions
        $additional-permissions
        $permissions-preapproved))
   "ok")

(= (codex:exec-command-permission-plan-type
      (CodexExecCommandPermissionPlanError $message))
   "error")

(= (codex:exec-command-permission-plan-message
      (CodexExecCommandPermissionPlanError $message))
   $message)

(= (codex:exec-command-permission-plan-sandbox-permissions
      (CodexExecCommandPermissionPlanOk
        $sandbox-permissions
        $additional-permissions
        $permissions-preapproved))
   $sandbox-permissions)

(= (codex:exec-command-permission-plan-additional-permissions
      (CodexExecCommandPermissionPlanOk
        $sandbox-permissions
        $additional-permissions
        $permissions-preapproved))
   $additional-permissions)

(= (codex:exec-command-permission-plan-permissions-preapproved
      (CodexExecCommandPermissionPlanOk
        $sandbox-permissions
        $additional-permissions
        $permissions-preapproved))
   $permissions-preapproved)

(= (codex:exec-command-permission-plan-json
      (CodexExecCommandPermissionPlanOk
        $sandbox-permissions
        $additional-permissions
        $permissions-preapproved))
   (JsonObject
     ((JsonPair "type" (JsonString "ok"))
      (JsonPair "sandbox_permissions" (JsonString $sandbox-permissions))
      (JsonPair "additional_permissions"
        (codex:request-permission-profile-json $additional-permissions))
      (JsonPair "permissions_preapproved"
        (JsonBool $permissions-preapproved)))))

(= (codex:exec-command-permission-plan-json
      (CodexExecCommandPermissionPlanError $message))
   (JsonObject
     ((JsonPair "type" (JsonString "error"))
      (JsonPair "message" (JsonString $message)))))

(= (codex:is-sandbox-permissions-with-additional-permissions? $value)
   (== $value (codex:sandbox-permissions-with-additional-permissions)))

(= (codex:is-sandbox-permissions-require-escalated? $value)
   (== $value (codex:sandbox-permissions-require-escalated)))

(= (codex:resolve-effective-exec-command-permissions
      $state
      $sandbox-permissions
      $additional-permissions
      $cwd)
   (if (codex:is-sandbox-permissions-require-escalated? $sandbox-permissions)
       (CodexExecEffectiveAdditionalPermissions
         $sandbox-permissions
         $additional-permissions
         False)
       (let $granted-permissions
         (codex:request-permissions-granted-permissions $state)
         (let $effective-permissions
           (codex:merge-request-permission-profiles
             $additional-permissions
             $granted-permissions)
           (CodexExecEffectiveAdditionalPermissions
             (if (and
                   (not (== $effective-permissions CodexAbsent))
                   (not
                     (codex:is-sandbox-permissions-with-additional-permissions?
                       $sandbox-permissions)))
                 (codex:sandbox-permissions-with-additional-permissions)
                 $sandbox-permissions)
             $effective-permissions
             (codex:is-request-permissions-preapproved
               $effective-permissions
               $granted-permissions
               $cwd))))))

(= (codex:exec-effective-additional-permissions-sandbox-permissions
      (CodexExecEffectiveAdditionalPermissions
        $sandbox-permissions
        $additional-permissions
        $permissions-preapproved))
   $sandbox-permissions)

(= (codex:exec-effective-additional-permissions-additional-permissions
      (CodexExecEffectiveAdditionalPermissions
        $sandbox-permissions
        $additional-permissions
        $permissions-preapproved))
   $additional-permissions)

(= (codex:exec-effective-additional-permissions-permissions-preapproved
      (CodexExecEffectiveAdditionalPermissions
        $sandbox-permissions
        $additional-permissions
        $permissions-preapproved))
   $permissions-preapproved)

(= (codex:normalize-and-validate-exec-command-permissions
      $additional-permissions-allowed
      $approval-policy
      $sandbox-permissions
      $additional-permissions
      $permissions-preapproved
      $cwd)
   (if (and
         (and
           (not $permissions-preapproved)
           (not $additional-permissions-allowed))
         (or
           (codex:is-sandbox-permissions-with-additional-permissions?
             $sandbox-permissions)
           (not (== $additional-permissions CodexAbsent))))
       (CodexExecCommandPermissionPlanError
         "additional permissions are disabled; enable `features.exec_permission_approvals` before using `with_additional_permissions`")
       (if (codex:is-sandbox-permissions-with-additional-permissions?
             $sandbox-permissions)
           (if (and
                 (not $permissions-preapproved)
                 (not (== $approval-policy (codex:ask-for-approval-on-request))))
               (CodexExecCommandPermissionPlanError
                 (format-args
                   "approval policy is {}; reject command — you cannot request additional permissions unless the approval policy is OnRequest"
                   ($approval-policy)))
               (if (== $additional-permissions CodexAbsent)
                   (CodexExecCommandPermissionPlanError
                     "missing `additional_permissions`; provide at least one of `network` or `file_system` when using `with_additional_permissions`")
                   (let $normalized
                     (codex:normalize-request-permission-profile
                       $cwd
                       $additional-permissions)
                     (if (codex:is-request-permission-profile-empty? $normalized)
                         (CodexExecCommandPermissionPlanError
                           "`additional_permissions` must include at least one requested permission in `network` or `file_system`")
                         (CodexExecCommandPermissionPlanOk
                           $sandbox-permissions
                           $normalized
                           $permissions-preapproved)))))
           (if (not (== $additional-permissions CodexAbsent))
               (CodexExecCommandPermissionPlanError
                 "`additional_permissions` requires `sandbox_permissions` set to `with_additional_permissions`")
               (CodexExecCommandPermissionPlanOk
                 $sandbox-permissions
                 CodexAbsent
                 $permissions-preapproved)))))

(= (codex:resolve-exec-command-permission-plan $context $state $args)
   (let $effective
     (codex:resolve-effective-exec-command-permissions
       $state
       (codex:exec-command-sandbox-permissions $args)
       (codex:exec-command-additional-permissions $args)
       (codex:exec-command-cwd $args))
     (if (and
           (and
             (codex:is-sandbox-permissions-require-escalated?
               (codex:exec-effective-additional-permissions-sandbox-permissions
                 $effective))
             (not
               (codex:exec-effective-additional-permissions-permissions-preapproved
                 $effective)))
           (not
             (==
               (codex:exec-command-context-approval-policy $context)
               (codex:ask-for-approval-on-request))))
         (CodexExecCommandPermissionPlanError
           (format-args
             "approval policy is {}; reject command — you cannot ask for escalated permissions if the approval policy is {}"
             ((codex:exec-command-context-approval-policy $context)
              (codex:exec-command-context-approval-policy $context))))
         (codex:normalize-and-validate-exec-command-permissions
           (codex:exec-command-context-additional-permissions-allowed
             $context)
           (codex:exec-command-context-approval-policy $context)
           (codex:exec-effective-additional-permissions-sandbox-permissions
             $effective)
           (codex:exec-effective-additional-permissions-additional-permissions
             $effective)
           (codex:exec-effective-additional-permissions-permissions-preapproved
             $effective)
           (codex:exec-command-cwd $args)))))

(= (codex:exec-command-permission-plan-json-with-context-state
      $context
      $state
      $input)
   (json-stringify
     (codex:exec-command-permission-plan-json
       (codex:resolve-exec-command-permission-plan
         $context
         $state
         (codex:parse-exec-command-args $input)))))

(= (codex:write-stdin-session-id
      (CodexWriteStdinArgs
        $session-id
        $chars
        $yield-time-ms
        $max-output-tokens))
   $session-id)

(= (codex:write-stdin-chars
      (CodexWriteStdinArgs
        $session-id
        $chars
        $yield-time-ms
        $max-output-tokens))
   $chars)

(= (codex:write-stdin-yield-time-ms
      (CodexWriteStdinArgs
        $session-id
        $chars
        $yield-time-ms
        $max-output-tokens))
   $yield-time-ms)

(= (codex:write-stdin-max-output-tokens
      (CodexWriteStdinArgs
        $session-id
        $chars
        $yield-time-ms
        $max-output-tokens))
   $max-output-tokens)

(= (codex:exec-command-use-login-shell-plan
      $runtime-config
      $args)
   (let $login (codex:exec-command-login-shell $args)
     (if (== $login CodexAbsent)
         (CodexExecCommandUseLoginShellOk
           (codex:exec-command-runtime-config-allow-login-shell $runtime-config))
         (if (and
               $login
               (not
                 (codex:exec-command-runtime-config-allow-login-shell
                   $runtime-config)))
             (CodexExecCommandUseLoginShellError
               "login shell is disabled by config; omit `login` or set it to false.")
             (CodexExecCommandUseLoginShellOk $login)))))

(= (codex:exec-command-use-login-shell-plan-message
      (CodexExecCommandUseLoginShellError $message))
   $message)

(= (codex:exec-command-use-login-shell-plan-value
      (CodexExecCommandUseLoginShellOk $use-login-shell))
   $use-login-shell)

(= (codex:resolve-exec-command-direct-shell $runtime-config $args)
   (let $model-shell-path (codex:exec-command-shell $args)
     (if (== $model-shell-path CodexAbsent)
         (codex:exec-command-runtime-config-session-shell $runtime-config)
         (process-shell-from-model-provided-path $model-shell-path))))

(= (codex:exec-command-argv-for-shell-mode
      CodexUnifiedExecShellModeDirect
      $runtime-config
      $args
      $use-login-shell)
   (CodexExecCommandArgvOk
     (once
       (process-shell-argv
         (codex:resolve-exec-command-direct-shell $runtime-config $args)
         (codex:exec-command-text $args)
         $use-login-shell))))

(= (codex:exec-command-argv-for-shell-mode
      (CodexUnifiedExecShellModeZshFork
        $shell-zsh-path
        $main-execve-wrapper-exe)
      $runtime-config
      $args
      $use-login-shell)
   ; Rust stores `main_execve_wrapper_exe` on the mode, but
   ; `get_command()` only needs `shell_zsh_path`.
   (CodexExecCommandArgvOk
     ($shell-zsh-path
      (if $use-login-shell "-lc" "-c")
      (codex:exec-command-text $args))))

(= (codex:exec-command-argv-with-runtime-config $runtime-config $args)
   (once
     (case
       (codex:exec-command-use-login-shell-plan $runtime-config $args)
       (((CodexExecCommandUseLoginShellError $message)
         (CodexExecCommandArgvError $message))
        ((CodexExecCommandUseLoginShellOk $use-login-shell)
         (codex:exec-command-argv-for-shell-mode
           (codex:exec-command-runtime-config-shell-mode $runtime-config)
           $runtime-config
           $args
           $use-login-shell))))))

(= (codex:default-exec-command-use-login-shell $args)
   (let $login (codex:exec-command-login-shell $args)
     (if (== $login CodexAbsent)
         True
         $login)))

(= (codex:exec-command-argv $args)
   (once
     (process-shell-argv
       (codex:resolve-exec-command-direct-shell
         (codex:default-exec-command-runtime-config)
         $args)
       (codex:exec-command-text $args)
       (codex:default-exec-command-use-login-shell $args))))

(= (codex:exec-command-argv-plan-message
      (CodexExecCommandArgvError $message))
   $message)

(= (codex:strip-trailing-dot-zero $text)
   (if (str-ends-with? $text ".0")
       (str-slice $text 0 (- (str-length $text) 2))
       $text))

(= (codex:number-text $value)
   (codex:strip-trailing-dot-zero (format-args "{}" ($value))))

(= (codex:normalize-whole-number $value)
   (codex:decimal-string-to-number (codex:number-text $value)))

(= (codex:approx-token-count $text)
   (codex:normalize-whole-number
     (ceil-math (/ (str-length $text) 4))))

(= (codex:approx-bytes-for-tokens $tokens)
   (* $tokens 4))

(= (codex:approx-tokens-from-byte-count $bytes)
   (codex:normalize-whole-number
     (ceil-math (/ $bytes 4))))

(= (codex:is-string-contains $text $needle)
   (case (str-find $text $needle)
     ((Empty False)
      ($index True))))

(= (codex:count-lines $text)
   (if (== $text "")
       0
       (let $parts (str-split "\n" $text)
         (if (str-ends-with? $text "\n")
             (- (list:len $parts) 1)
             (list:len $parts)))))

(= (codex:token-truncation-marker $removed-bytes)
   (str-concat
     "..."
     (str-concat
       (codex:number-text
         (codex:approx-tokens-from-byte-count $removed-bytes))
       " tokens truncated...")))

(= (codex:truncate-middle-with-token-budget $text $max-tokens)
   (let $max-bytes (codex:approx-bytes-for-tokens $max-tokens)
     (codex:truncate-middle-with-token-budget-bytes $text $max-bytes)))

(= (codex:truncate-middle-with-token-budget-bytes $text $max-bytes)
   (if (<= (str-length $text) $max-bytes)
       $text
       (if (== $max-bytes 0)
           (codex:token-truncation-marker (str-length $text))
           (let $text-len (str-length $text)
             (let $left-budget (/ $max-bytes 2)
               (let $right-budget (- $max-bytes $left-budget)
                 (let $prefix-end
                   (if (> $left-budget $text-len) $text-len $left-budget)
                   (let $suffix-start-target
                     (if (> $right-budget $text-len)
                         0
                         (- $text-len $right-budget))
                     (let $suffix-start
                       (if (< $suffix-start-target $prefix-end)
                           $prefix-end
                           $suffix-start-target)
                       (str-concat
                         (str-slice $text 0 $prefix-end)
                         (str-concat
                           (codex:token-truncation-marker
                             (- $text-len $max-bytes))
                           (str-slice $text $suffix-start $text-len))))))))))))

(= (codex:format-truncated-output $text $max-output-tokens)
   (let $max-bytes (codex:approx-bytes-for-tokens $max-output-tokens)
     (if (<= (str-length $text) $max-bytes)
         $text
         (str-concat
           (format-args "Total output lines: {}\n\n" ((codex:count-lines $text)))
           (codex:truncate-middle-with-token-budget $text $max-output-tokens)))))

(= (codex:pad-left-3 $text)
   (if (== (str-length $text) 0)
       "000"
       (if (== (str-length $text) 1)
           (str-concat "00" $text)
           (if (== (str-length $text) 2)
               (str-concat "0" $text)
               $text))))

(= (codex:duration-ms-to-seconds-text $duration-ms)
   (let $seconds-whole
     (codex:normalize-whole-number (trunc-math (/ $duration-ms 1000)))
     (let $millis (% $duration-ms 1000)
       (str-concat
         (codex:number-text $seconds-whole)
         (str-concat
           "."
           (str-concat
             (codex:pad-left-3 (codex:number-text $millis))
             "0"))))))

(= (codex:chunk-id-from-call-id $call-id)
   (if (<= (str-length $call-id) 6)
       $call-id
       (str-slice $call-id 0 6)))

(= (codex:format-exec-command-output
      $chunk-id
      $duration-ms
      $is-running
      $session-id
      $has-exit-code
      $exit-code
      $aggregated-output
      $max-output-tokens
      $original-token-count)
   (if $has-exit-code
       (if $is-running
           (format-args
             "Chunk ID: {}\nWall time: {} seconds\nProcess exited with code {}\nProcess running with session ID {}\nOriginal token count: {}\nOutput:\n{}"
             ($chunk-id
              (codex:duration-ms-to-seconds-text $duration-ms)
              $exit-code
              $session-id
              (codex:number-text $original-token-count)
              (codex:format-truncated-output
                $aggregated-output
                $max-output-tokens)))
           (format-args
             "Chunk ID: {}\nWall time: {} seconds\nProcess exited with code {}\nOriginal token count: {}\nOutput:\n{}"
             ($chunk-id
              (codex:duration-ms-to-seconds-text $duration-ms)
              $exit-code
              (codex:number-text $original-token-count)
              (codex:format-truncated-output
                $aggregated-output
                $max-output-tokens))))
       (if $is-running
           (format-args
             "Chunk ID: {}\nWall time: {} seconds\nProcess running with session ID {}\nOriginal token count: {}\nOutput:\n{}"
             ($chunk-id
              (codex:duration-ms-to-seconds-text $duration-ms)
              $session-id
              (codex:number-text $original-token-count)
              (codex:format-truncated-output
                $aggregated-output
                $max-output-tokens)))
           (format-args
             "Chunk ID: {}\nWall time: {} seconds\nOriginal token count: {}\nOutput:\n{}"
             ($chunk-id
              (codex:duration-ms-to-seconds-text $duration-ms)
              (codex:number-text $original-token-count)
              (codex:format-truncated-output
                $aggregated-output
                $max-output-tokens))))))

(= (codex:make-exec-command-run-from-snapshot
      $chunk-id
      $max-output-tokens
      (ProcessSessionSnapshot
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $event-call-id
        $hook-command))
   (let $original-token-count
     (codex:approx-token-count $aggregated-output)
     (CodexExecCommandRun
       $event-call-id
       $chunk-id
       $hook-command
       $max-output-tokens
       $is-running
       $session-id
       $has-exit-code
       $exit-code
       $stdout
       $stderr
       $aggregated-output
       $duration-ms
       $original-token-count
       (codex:format-exec-command-output
         $chunk-id
         $duration-ms
         $is-running
         $session-id
         $has-exit-code
         $exit-code
         $aggregated-output
         $max-output-tokens
         $original-token-count))))

(= (codex:make-exec-command-error-run
      $call-id
      $hook-command
      $max-output-tokens
      $error)
   (let $aggregated-output (str-concat "exec_command failed: " $error)
     (let $original-token-count (codex:approx-token-count $aggregated-output)
       (CodexExecCommandRun
         $call-id
         ""
         $hook-command
         $max-output-tokens
         False
         0
         False
         0
         ""
         $error
         $aggregated-output
         0
         $original-token-count
         $aggregated-output))))

(= (codex:run-exec-command-with-context-state $context $state $call-id $input)
   (let $args (codex:parse-exec-command-args $input)
     (case
       (codex:resolve-exec-command-permission-plan $context $state $args)
       (((CodexExecCommandPermissionPlanOk
           $sandbox-permissions
           $additional-permissions
           $permissions-preapproved)
         (case
           (process-open-session-cmd-cwd-env-tty-event-call-id-hook-command-yield-cap-bytes
             (codex:exec-command-argv $args)
             (codex:exec-command-cwd $args)
             (process-create-shell-env-no-thread
               (process-default-shell-env-policy))
             (codex:exec-command-tty $args)
             $call-id
             (codex:exec-command-text $args)
             (codex:exec-command-yield-time-ms $args)
             (codex:maximum-raw-output-bytes))
           (((ProcessSessionCallResult True $error $snapshot)
             (codex:make-exec-command-run-from-snapshot
               (codex:chunk-id-from-call-id $call-id)
               (codex:exec-command-max-output-tokens $args)
               $snapshot))
            ((ProcessSessionCallResult False $error $snapshot)
             (codex:make-exec-command-error-run
               $call-id
               (codex:exec-command-text $args)
               (codex:exec-command-max-output-tokens $args)
               $error)))))
        ((CodexExecCommandPermissionPlanError $message)
         (codex:make-exec-command-error-run
           $call-id
           (codex:exec-command-text $args)
           (codex:exec-command-max-output-tokens $args)
           $message))))))

(= (codex:run-exec-command $call-id $input)
   (codex:run-exec-command-with-context-state
     (codex:default-exec-command-context)
     (codex:empty-request-permissions-state)
     $call-id
     $input))

(= (codex:exec-command-run-event-call-id
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   $call-id)

(= (codex:exec-command-run-call-id
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   $call-id)

(= (codex:exec-command-run-chunk-id
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   $chunk-id)

(= (codex:exec-command-run-hook-command
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   $hook-command)

(= (codex:exec-command-run-max-output-tokens
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   $max-output-tokens)

(= (codex:exec-command-run-text
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   $text)

(= (codex:is-exec-command-run-running
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   $is-running)

(= (codex:exec-command-run-session-id
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   $session-id)

(= (codex:exec-command-run-exit-code
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        True
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   $exit-code)

(= (codex:exec-command-run-stdout
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   $stdout)

(= (codex:exec-command-run-stderr
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   $stderr)

(= (codex:exec-command-run-aggregated-output
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   $aggregated-output)

(= (codex:exec-command-run-duration-ms
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   $duration-ms)

(= (codex:exec-command-run-original-token-count
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   $original-token-count)

(= (codex:is-exec-command-run-timed-out
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   False)

(= (codex:exec-command-run-output-item
      $output-call-id
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   (codex:tool-result $output-call-id $text))

(= (codex:exec-command-run-output-item
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   (codex:tool-result $call-id $text))

(= (codex:exec-command-run-truncated-output
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   (codex:format-truncated-output
     $aggregated-output
     $max-output-tokens))

(= (codex:is-exec-command-run-completed
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        False
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   True)

(= (codex:is-exec-command-run-completed
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        True
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   False)

(= (codex:exec-command-post-tool-use-id $tool-call-id $run)
   (let $event-call-id (codex:exec-command-run-event-call-id $run)
     (if (== $event-call-id "")
         $tool-call-id
         $event-call-id)))

(= (codex:exec-command-post-tool-use-response-json $run)
   (if (codex:is-exec-command-run-completed $run)
       (JsonString (codex:exec-command-run-truncated-output $run))
       CodexAbsent))

(= (codex:exec-command-pre-tool-use-payload-from-input $input)
   (let $args (once (codex:parse-exec-command-args $input))
     (codex:pre-tool-use-payload
       (codex:hook-tool-name-bash)
       (codex:hook-command-input-json
         (codex:exec-command-text $args)))))

(= (codex:exec-command-pre-tool-use-payload
      (CodexResponseItemCustomToolCall $call-id $name $input))
   (if (== $name "exec_command")
       (codex:exec-command-pre-tool-use-payload-from-input $input)
       Empty))

(= (codex:exec-command-post-tool-use-payload
      $tool-call-id
      $input
      $run)
   (let $hook-command (codex:exec-command-run-hook-command $run)
     (let $tool-response (codex:exec-command-post-tool-use-response-json $run)
       (if (or (== $hook-command "") (== $tool-response CodexAbsent))
           Empty
           (codex:post-tool-use-payload
             (codex:hook-tool-name-bash)
             (codex:exec-command-post-tool-use-id $tool-call-id $run)
             (codex:hook-command-input-json $hook-command)
             $tool-response)))))

(= (codex:write-stdin-post-tool-use-payload
      $tool-call-id
      $input
      $run)
   (let $hook-command (codex:exec-command-run-hook-command $run)
     (let $tool-response (codex:exec-command-post-tool-use-response-json $run)
       (if (or (== $hook-command "") (== $tool-response CodexAbsent))
           Empty
           (codex:post-tool-use-payload
             (codex:hook-tool-name-bash)
             (codex:exec-command-post-tool-use-id $tool-call-id $run)
             (codex:hook-command-input-json $hook-command)
             $tool-response)))))

(= (codex:single-exec-command-output-delta-items $call-id $stream $chunk)
   (if (== $chunk "")
       ()
       ((codex:exec-command-output-delta-event $call-id $stream $chunk))))

(= (codex:exec-command-run-output-delta-items
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   (if (== $chunk-id "")
       ()
       (let $stdout-items
         (codex:single-exec-command-output-delta-items
           $call-id
           "stdout"
           $stdout)
         (let $stderr-items
           (codex:single-exec-command-output-delta-items
             $call-id
             "stderr"
             $stderr)
           (list:append
             $stdout-items
             $stderr-items)))))

(= (codex:exec-command-run-output-items $output-call-id $run)
   (list:append
     (codex:exec-command-run-output-delta-items $run)
     ((codex:exec-command-run-output-item $output-call-id $run))))

(= (codex:write-stdin-result-text
      (CodexWriteStdinResultSuccess $run))
   (codex:exec-command-run-text $run))

(= (codex:write-stdin-result-text
      (CodexWriteStdinResultError $text))
   $text)

(= (codex:is-write-stdin-result-success
      (CodexWriteStdinResultSuccess $run))
   True)

(= (codex:is-write-stdin-result-success
      (CodexWriteStdinResultError $text))
   False)

(= (codex:write-stdin-result-run
      (CodexWriteStdinResultSuccess $run))
   $run)

(= (codex:write-stdin-call-result-to-result
      $call-id
      $max-output-tokens
      (ProcessSessionCallResult True $error $snapshot))
   (CodexWriteStdinResultSuccess
     (codex:make-exec-command-run-from-snapshot
       (codex:chunk-id-from-call-id $call-id)
       $max-output-tokens
       $snapshot)))

(= (codex:write-stdin-call-result-to-result
      $call-id
      $max-output-tokens
      (ProcessSessionCallResult False $error $snapshot))
   (CodexWriteStdinResultError
     (format-args "write_stdin failed: {}" ($error))))

(= (codex:run-write-stdin $call-id $input)
   (let $args (codex:parse-write-stdin-args $input)
     (case
       (process-write-session-stdin-yield-cap-bytes
         (codex:write-stdin-session-id $args)
         (codex:write-stdin-chars $args)
         (codex:write-stdin-yield-time-ms $args)
         (codex:maximum-raw-output-bytes))
       (((ProcessSessionCallResult True $error $snapshot)
         (CodexWriteStdinResultSuccess
           (codex:make-exec-command-run-from-snapshot
             (codex:chunk-id-from-call-id $call-id)
             (codex:write-stdin-max-output-tokens $args)
             $snapshot)))
       ((ProcessSessionCallResult False $error $snapshot)
         (CodexWriteStdinResultError
           (format-args "write_stdin failed: {}" ($error))))))))

(= (codex:run-write-stdin-output-text $call-id $input)
   (case
     (codex:run-write-stdin $call-id $input)
     (((CodexWriteStdinResultSuccess $run)
       (codex:exec-command-run-text $run))
      ((CodexWriteStdinResultError $text)
       $text))))

(= (codex:run-exec-command-then-write-stdin-result
      $open-call-id
      $open-input
      $write-call-id
      $chars
      $yield-time-ms)
   (case
     (codex:run-exec-command $open-call-id $open-input)
     (((CodexExecCommandRun
         $prior-call-id
         $prior-chunk-id
         $prior-hook-command
         $max-output-tokens
         True
         $session-id
         $has-exit-code
         $exit-code
         $stdout
         $stderr
         $aggregated-output
         $duration-ms
         $original-token-count
         $text)
       (case
         (process-write-session-stdin-yield-cap-bytes
           $session-id
           $chars
           $yield-time-ms
           (codex:maximum-raw-output-bytes))
         (((ProcessSessionCallResult True $error $snapshot)
           (CodexWriteStdinResultSuccess
             (codex:make-exec-command-run-from-snapshot
               (codex:chunk-id-from-call-id $write-call-id)
               $max-output-tokens
               $snapshot)))
          ((ProcessSessionCallResult False $error $snapshot)
           (CodexWriteStdinResultError
             (format-args "write_stdin failed: {}" ($error)))))))
      ((CodexExecCommandRun
         $prior-call-id
         $prior-chunk-id
         $prior-hook-command
         $max-output-tokens
         False
         $session-id
         $has-exit-code
         $exit-code
         $stdout
         $stderr
         $aggregated-output
         $duration-ms
         $original-token-count
         $text)
       (CodexWriteStdinResultSuccess
         (CodexExecCommandRun
           $prior-call-id
           $prior-chunk-id
           $prior-hook-command
           $max-output-tokens
           False
           $session-id
           $has-exit-code
           $exit-code
           $stdout
           $stderr
           $aggregated-output
           $duration-ms
           $original-token-count
           $text)))
      ($other
       (CodexWriteStdinResultError
         "write_stdin helper requires a running exec_command result")))))

(= (codex:run-exec-command-then-write-stdin-output-text
      $open-call-id
      $open-input
      $write-call-id
      $chars
      $yield-time-ms)
   (codex:write-stdin-result-text
     (codex:run-exec-command-then-write-stdin-result
       $open-call-id
       $open-input
       $write-call-id
       $chars
       $yield-time-ms)))

(= (codex:run-write-stdin-tool-call $call-id $input)
   (case
     (codex:run-write-stdin $call-id $input)
     (((CodexWriteStdinResultSuccess $run)
       (codex:tool-result
         $call-id
         (codex:exec-command-run-text $run)))
      ((CodexWriteStdinResultError $text)
       (codex:tool-result $call-id $text)))))

(= (codex:write-stdin-result-event-items
      $args
      (CodexWriteStdinResultSuccess $run))
   (list:append
     ((codex:terminal-interaction-event
         (codex:exec-command-run-event-call-id $run)
         (codex:number-text (codex:write-stdin-session-id $args))
         (codex:write-stdin-chars $args)))
     (codex:exec-command-run-output-delta-items $run)))

(= (codex:write-stdin-result-event-items
      $args
      (CodexWriteStdinResultError $text))
   ())

(= (codex:run-apply-patch-shell-command-with-request-permissions-state
      $state
      $cwd
      $command)
   (case (codex:maybe-parse-apply-patch-shell-command $cwd $command)
     (((CodexMaybeApplyPatchNotApplyPatch)
       (CodexApplyPatchInterceptNotMatched))
      ((CodexMaybeApplyPatchCorrectnessError $message)
       (CodexApplyPatchInterceptMatched
         (str-concat "apply_patch verification failed: " $message)))
      ((CodexMaybeApplyPatchBody $patch-text $action)
       (case
         (codex:apply-patch-with-request-permissions-state
           $state
           (codex:local-apply-patch-approval-policy)
           (codex:local-apply-patch-sandbox-policy)
           (codex:local-apply-patch-file-system-sandbox-policy)
           $patch-text
           $action
           (codex:local-apply-patch-has-platform-sandbox))
         (((CodexInternalApplyPatchOutput $text)
           (CodexApplyPatchInterceptMatched $text))
          ((CodexInternalApplyPatchDelegateToRuntime $runtime)
           (CodexApplyPatchInterceptMatched
             (codex:execute-apply-patch-runtime $runtime)))))))))

(= (codex:run-exec-command-tool-call-with-context-state
      $context
      $state
      $call-id
      $input)
   (let $args (codex:parse-exec-command-args $input)
     (case
       (codex:resolve-exec-command-permission-plan $context $state $args)
       (((CodexExecCommandPermissionPlanOk
           $sandbox-permissions
           $additional-permissions
           $permissions-preapproved)
         (case
           (codex:run-apply-patch-shell-command-with-request-permissions-state
             $state
             (codex:exec-command-cwd $args)
             (codex:exec-command-text $args))
           (((CodexApplyPatchInterceptNotMatched)
             (let $run
               (codex:run-exec-command-with-context-state
                 $context
                 $state
                 $call-id
                 $input)
               (codex:exec-command-run-output-item
                 $call-id
                 $run)))
            ((CodexApplyPatchInterceptMatched $text)
             (codex:tool-result $call-id $text)))))
        ((CodexExecCommandPermissionPlanError $message)
         (codex:tool-result
           $call-id
           (str-concat "exec_command failed: " $message)))))))

(= (codex:run-exec-command-tool-call $call-id $input)
   (codex:run-exec-command-tool-call-with-context-state
     (codex:default-exec-command-context)
     (codex:empty-request-permissions-state)
     $call-id
     $input))

(= (codex:run-apply-patch-tool-call $call-id $input)
   (codex:tool-result $call-id (codex:run-apply-patch-local $input)))

(= (codex:run-request-permissions-tool-call-item $call-id $input)
   ; Rust returns a CustomToolCallOutput item directly from each handler.
   ; Several imported text-output handlers already reduce correctly when their
   ; visible output text is observed, but the raw imported ResponseItem term can
   ; collapse to `Empty` inside this large module. Rebuilding the same visible
   ; item from the stable accessor preserves the Rust behavior while avoiding
   ; the current evaluator boundary issue.
   (codex:tool-result
     $call-id
     (codex:tool-result-output-text
       (once
         (codex:run-request-permissions-tool-call $call-id $input)))))

(= (codex:run-list-dir-tool-call-item $call-id $input)
   (codex:tool-result
     $call-id
     (codex:tool-result-output-text
       (once
         (codex:run-list-dir-tool-call $call-id $input)))))

(= (codex:run-request-user-input-tool-call-item $call-id $input)
   (codex:tool-result
     $call-id
     (codex:tool-result-output-text
       (once
         (codex:run-request-user-input-tool-call $call-id $input)))))

(= (codex:run-update-plan-tool-call-item $call-id $input)
   (codex:tool-result
     $call-id
     (codex:tool-result-output-text
       (once
         (codex:run-update-plan-tool-call $call-id $input)))))

; Rust dispatches from a handler registry whose imported handlers are already
; fully linked. The current CeTTa module surface needs one explicit
; helper-constructor normalization for `codex:tool-call`, and some imported
; text-output handlers are rebuilt from their stable visible output text to
; avoid current evaluator boundary issues with the raw ResponseItem term.
(= (codex:run-tool-call-item
      (codex:tool-call $call-id $name $input))
   (eval
     (codex:run-tool-call-item
       (CodexResponseItemCustomToolCall $call-id $name $input))))

(= (codex:run-tool-call-item
      (CodexResponseItemCustomToolCall $call-id $name $input))
   (if (== $name "exec_command")
       (codex:run-exec-command-tool-call $call-id $input)
       (if (== $name "write_stdin")
           (codex:run-write-stdin-tool-call $call-id $input)
           (if (== $name "apply_patch")
               (codex:run-apply-patch-tool-call $call-id $input)
               (if (== $name "list_dir")
                   (codex:run-list-dir-tool-call-item $call-id $input)
                   (if (== $name "request_permissions")
                       (codex:run-request-permissions-tool-call-item $call-id $input)
                       (if (== $name "request_user_input")
                           (codex:run-request-user-input-tool-call-item $call-id $input)
                           (if (== $name "update_plan")
                               (codex:run-update-plan-tool-call-item $call-id $input)
                               (codex:named-tool-result
                                     $call-id
                                     $name
                                     (format-args "unsupported tool: {}" ($name)))))))))))
