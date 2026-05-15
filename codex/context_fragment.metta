; Narrow Rust-faithful contextual-fragment slice for the restarted Codex port.
;
; This ports the visible behavior from:
; - openai-codex/codex-rs/core/src/context/fragment.rs
; - openai-codex/codex-rs/core/src/context/user_instructions.rs
; - openai-codex/codex-rs/core/src/context/user_shell_command.rs
; - openai-codex/codex-rs/core/src/context/turn_aborted.rs
;
; Covered in this increment:
; - generic contextual fragment render / matches_text / into(ResponseItem)
; - UserInstructions
; - UserShellCommand
; - TurnAborted
; - EnvironmentContext
; - SkillInstructions
; - SubagentNotification
; - PermissionsInstructions wrapper onto the generic fragment surface
; - narrow standard contextual-user-fragment detection for the concrete
;   user-role fragments above
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust uses `eq_ignore_ascii_case()` on start/end markers. The current CeTTa
;   string surface does not expose that helper, so this slice reconstructs the
;   same ASCII-only comparison explicitly.
; - Rust stores `UserShellCommand.duration_seconds` as `f64`. The current
;   visible CeTTa surface instead carries duration in milliseconds so the
;   fragment can still render the exact four-decimal-seconds body text without
;   introducing a second floating-point formatting slice.
; - Rust builds `EnvironmentContext` from session/turn runtime objects. The
;   current CeTTa slice ports the pure visible behavior through direct
;   constructor helpers rather than the surrounding runtime stack.
; - Rust's `SkillInstructions` also exposes `From<&SkillInjection>`, and
;   `SubagentNotification` takes `AgentStatus` from the protocol crate. The
;   current CeTTa slice ports the same visible fragment bodies through direct
;   constructor helpers because the surrounding runtime injection layer is not
;   ported yet.
; - Rust's hook-prompt parsing delegates to quick-xml and therefore accepts a
;   broader XML surface. The current CeTTa slice ports the specific
;   `hook_prompt` shape emitted by Codex itself, with predefined XML entities,
;   because there is not yet a general XML parser in the runtime.

!(import! &self permissions_instructions)
!(import! &self protocol)
!(import! &self json)
!(import! &self str)

(= (codex:contextual-fragment $role $start-marker $end-marker $body)
   (CodexContextualFragment $role $start-marker $end-marker $body))

(= (codex:contextual-fragment-role
      (CodexContextualFragment $role $start-marker $end-marker $body))
   $role)

(= (codex:contextual-fragment-start-marker
      (CodexContextualFragment $role $start-marker $end-marker $body))
   $start-marker)

(= (codex:contextual-fragment-end-marker
      (CodexContextualFragment $role $start-marker $end-marker $body))
   $end-marker)

(= (codex:contextual-fragment-body
      (CodexContextualFragment $role $start-marker $end-marker $body))
   $body)

(= (codex:ascii-lower-char $char)
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

(= (codex:ascii-lower-text $text)
   (if (== $text "")
       ""
       (str-concat
         (codex:ascii-lower-char (str-slice $text 0 1))
         (codex:ascii-lower-text
           (str-slice $text 1 (str-length $text))))))

(= (codex:text-equals-ignore-ascii-case $lhs $rhs)
   (== (codex:ascii-lower-text $lhs)
       (codex:ascii-lower-text $rhs)))

(= (codex:contextual-fragment-matches-markers $start-marker $end-marker $text)
   (if (== $start-marker "")
       False
       (if (== $end-marker "")
           False
           (let $trimmed (str-trim $text)
             (let $trimmed-len (str-length $trimmed)
               (let $start-len (str-length $start-marker)
                 (let $end-len (str-length $end-marker)
                   (if (< $trimmed-len $start-len)
                       False
                       (if (< $trimmed-len $end-len)
                           False
                           (if (codex:text-equals-ignore-ascii-case
                                 (str-slice $trimmed 0 $start-len)
                                 $start-marker)
                               (codex:text-equals-ignore-ascii-case
                                 (str-slice
                                   $trimmed
                                   (- $trimmed-len $end-len)
                                   $trimmed-len)
                                 $end-marker)
                               False))))))))))

(= (codex:contextual-fragment-matches-text $fragment $text)
   (codex:contextual-fragment-matches-markers
     (codex:contextual-fragment-start-marker $fragment)
     (codex:contextual-fragment-end-marker $fragment)
     $text))

(= (codex:contextual-fragment-render $fragment)
   (let $start-marker (codex:contextual-fragment-start-marker $fragment)
     (let $end-marker (codex:contextual-fragment-end-marker $fragment)
       (let $body (codex:contextual-fragment-body $fragment)
         (if (== $start-marker "")
             (if (== $end-marker "")
                 $body
                 (str-concat $start-marker (str-concat $body $end-marker)))
             (str-concat $start-marker (str-concat $body $end-marker)))))))

(= (codex:contextual-fragment-response-item $fragment)
   (CodexResponseItemMessage
     (codex:contextual-fragment-role $fragment)
     ((CodexInputText (codex:contextual-fragment-render $fragment)))
     CodexAbsent))

(= (codex:replace-all $text $needle $replacement)
   (str-join $replacement (str-split $needle $text)))

(= (codex:xml-escape-text $text)
   (codex:replace-all
     (codex:replace-all
       (codex:replace-all $text "&" "&amp;")
       "<"
       "&lt;")
     ">"
     "&gt;"))

(= (codex:xml-escape-attribute $text)
   (codex:replace-all
     (codex:replace-all
       (codex:xml-escape-text $text)
       "\""
       "&quot;")
     "'"
     "&apos;"))

(= (codex:xml-unescape-predefined-entities $text)
   (codex:replace-all
     (codex:replace-all
       (codex:replace-all
         (codex:replace-all
           (codex:replace-all $text "&quot;" "\"")
           "&apos;"
           "'")
         "&gt;"
         ">")
       "&lt;"
       "<")
     "&amp;"
     "&"))

(= (codex:strip-trailing-dot-zero $text)
   (if (str-ends-with? $text ".0")
       (str-slice $text 0 (- (str-length $text) 2))
       $text))

(= (codex:number-text $value)
   (codex:strip-trailing-dot-zero (format-args "{}" ($value))))

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
     (trunc-math (/ $duration-ms 1000))
     (let $millis (% $duration-ms 1000)
       (str-concat
         (codex:number-text $seconds-whole)
         (str-concat
           "."
           (str-concat
             (codex:pad-left-3 (codex:number-text $millis))
             "0"))))))

(= (codex:user-instructions-role)
   "user")

(= (codex:user-instructions-start-marker)
   "# AGENTS.md instructions for ")

(= (codex:user-instructions-end-marker)
   "</INSTRUCTIONS>")

(= (codex:user-instructions $directory $text)
   (codex:contextual-fragment
     (codex:user-instructions-role)
     (codex:user-instructions-start-marker)
     (codex:user-instructions-end-marker)
     (str-concat
       $directory
       (str-concat
         "\n\n<INSTRUCTIONS>\n"
         (str-concat $text "\n")))))

(= (codex:user-instructions-matches-text $text)
   (codex:contextual-fragment-matches-markers
     (codex:user-instructions-start-marker)
     (codex:user-instructions-end-marker)
     $text))

(= (codex:user-shell-command-role)
   "user")

(= (codex:user-shell-command-start-marker)
   "<user_shell_command>")

(= (codex:user-shell-command-end-marker)
   "</user_shell_command>")

(= (codex:user-shell-command $command $exit-code $duration-ms $output)
   (codex:contextual-fragment
     (codex:user-shell-command-role)
     (codex:user-shell-command-start-marker)
     (codex:user-shell-command-end-marker)
     (format-args
       "\n<command>\n{}\n</command>\n<result>\nExit code: {}\nDuration: {} seconds\nOutput:\n{}\n</result>\n"
       ($command
        $exit-code
        (codex:duration-ms-to-seconds-text $duration-ms)
        $output))))

(= (codex:user-shell-command-matches-text $text)
   (codex:contextual-fragment-matches-markers
     (codex:user-shell-command-start-marker)
     (codex:user-shell-command-end-marker)
     $text))

(= (codex:turn-aborted-role)
   "user")

(= (codex:turn-aborted-start-marker)
   "<turn_aborted>")

(= (codex:turn-aborted-end-marker)
   "</turn_aborted>")

(= (codex:turn-aborted-interrupted-guidance)
   "The user interrupted the previous turn on purpose. Any running unified exec processes may still be running in the background. If any tools/commands were aborted, they may have partially executed.")

(= (codex:turn-aborted $guidance)
   (codex:contextual-fragment
     (codex:turn-aborted-role)
     (codex:turn-aborted-start-marker)
     (codex:turn-aborted-end-marker)
     (str-concat
       "\n"
       (str-concat $guidance "\n"))))

(= (codex:turn-aborted-matches-text $text)
   (codex:contextual-fragment-matches-markers
     (codex:turn-aborted-start-marker)
     (codex:turn-aborted-end-marker)
     $text))

(= (codex:environment-context-role)
   "user")

(= (codex:environment-context-start-marker)
   "<environment_context>")

(= (codex:environment-context-end-marker)
   "</environment_context>")

(= (codex:environment-network-context $allowed-domains $denied-domains)
   (CodexEnvironmentNetworkContext $allowed-domains $denied-domains))

(= (codex:environment-network-context-allowed-domains
      (CodexEnvironmentNetworkContext $allowed-domains $denied-domains))
   $allowed-domains)

(= (codex:environment-network-context-denied-domains
      (CodexEnvironmentNetworkContext $allowed-domains $denied-domains))
   $denied-domains)

(= (codex:environment-context
      $cwd
      $shell
      $current-date
      $timezone
      $network
      $subagents)
   (CodexEnvironmentContext
     $cwd
     $shell
     $current-date
     $timezone
     $network
     $subagents))

(= (codex:environment-context-cwd
      (CodexEnvironmentContext
        $cwd
        $shell
        $current-date
        $timezone
        $network
        $subagents))
   $cwd)

(= (codex:environment-context-shell
      (CodexEnvironmentContext
        $cwd
        $shell
        $current-date
        $timezone
        $network
        $subagents))
   $shell)

(= (codex:environment-context-current-date
      (CodexEnvironmentContext
        $cwd
        $shell
        $current-date
        $timezone
        $network
        $subagents))
   $current-date)

(= (codex:environment-context-timezone
      (CodexEnvironmentContext
        $cwd
        $shell
        $current-date
        $timezone
        $network
        $subagents))
   $timezone)

(= (codex:environment-context-network
      (CodexEnvironmentContext
        $cwd
        $shell
        $current-date
        $timezone
        $network
        $subagents))
   $network)

(= (codex:environment-context-subagents
      (CodexEnvironmentContext
        $cwd
        $shell
        $current-date
        $timezone
        $network
        $subagents))
   $subagents)

(= (codex:environment-context-equals-except-shell $left $right)
   (if (== (codex:environment-context-cwd $left)
           (codex:environment-context-cwd $right))
       (if (== (codex:environment-context-current-date $left)
               (codex:environment-context-current-date $right))
           (if (== (codex:environment-context-timezone $left)
                   (codex:environment-context-timezone $right))
               (if (== (codex:environment-context-network $left)
                       (codex:environment-context-network $right))
                   (if (== (codex:environment-context-subagents $left)
                           (codex:environment-context-subagents $right))
                       True
                       False)
                   False)
               False)
           False)
       False))

(= (codex:environment-context-with-subagents $context $subagents)
   (if (== $subagents "")
       $context
       (codex:environment-context
         (codex:environment-context-cwd $context)
         (codex:environment-context-shell $context)
         (codex:environment-context-current-date $context)
         (codex:environment-context-timezone $context)
         (codex:environment-context-network $context)
         $subagents)))

(= (codex:append-item $items $item)
   (list:append $items ($item)))

(= (codex:environment-context-domain-lines $domains $tag-name)
   (if (== $domains ())
       ()
       (let $head (list:first $domains)
         (let $tail (list:rest $domains)
           (cons-atom
             (format-args "    <{}>{}</{}>" ($tag-name $head $tag-name))
             (codex:environment-context-domain-lines $tail $tag-name))))))

(= (codex:prefix-lines $lines $prefix)
   (if (== $lines ())
       ()
       (let $head (list:first $lines)
         (let $tail (list:rest $lines)
           (cons-atom
             (str-concat $prefix $head)
             (codex:prefix-lines $tail $prefix))))))

(= (codex:environment-context-subagent-lines $subagents)
   (if (== $subagents "")
       ()
       (let $lines (str-split "\n" $subagents)
         (codex:prefix-lines $lines "    "))))

(= (codex:environment-context-network-lines $network)
   (case $network
     (((CodexEnvironmentNetworkContext $allowed-domains $denied-domains)
       (let $allowed-lines
         (codex:environment-context-domain-lines
           $allowed-domains
           "allowed")
         (let $denied-lines
           (codex:environment-context-domain-lines
             $denied-domains
             "denied")
           (let $lines-0
             (codex:append-item () "  <network enabled=\"true\">")
             (let $lines-1 (list:append $lines-0 $allowed-lines)
               (let $lines-2 (list:append $lines-1 $denied-lines)
                 (codex:append-item $lines-2 "  </network>"))))))))))

(= (codex:environment-context-subagents-block-lines $subagents)
   (let $subagent-lines (codex:environment-context-subagent-lines $subagents)
     (let $lines-0
       (codex:append-item () "  <subagents>")
       (let $lines-1 (list:append $lines-0 $subagent-lines)
         (codex:append-item $lines-1 "  </subagents>")))))

(= (codex:environment-context-lines $context)
   (case $context
     (((CodexEnvironmentContext
         $cwd
         $shell
         $current-date
         $timezone
         $network
         $subagents)
       (let $lines-0
         (if (== $cwd CodexAbsent)
             ()
             (codex:append-item
               ()
               (format-args
                 "  <cwd>{}</cwd>"
                 ($cwd))))
         (let $lines-1
           (codex:append-item
             $lines-0
             (format-args
               "  <shell>{}</shell>"
               ($shell)))
           (let $lines-2
             (if (== $current-date CodexAbsent)
                 $lines-1
                 (codex:append-item
                   $lines-1
                   (format-args
                     "  <current_date>{}</current_date>"
                     ($current-date))))
             (let $lines-3
               (if (== $timezone CodexAbsent)
                   $lines-2
                   (codex:append-item
                     $lines-2
                     (format-args
                       "  <timezone>{}</timezone>"
                       ($timezone))))
               (let $lines-4
                 (if (== $network CodexAbsent)
                     $lines-3
                     (list:append
                       $lines-3
                       (codex:environment-context-network-lines $network)))
                 (if (== $subagents CodexAbsent)
                     $lines-4
                     (list:append
                       $lines-4
                       (codex:environment-context-subagents-block-lines
                         $subagents))))))))))))

(= (codex:environment-context-fragment $context)
   (codex:contextual-fragment
     (codex:environment-context-role)
     (codex:environment-context-start-marker)
     (codex:environment-context-end-marker)
     (format-args
       "\n{}\n"
       ((str-join "\n" (codex:environment-context-lines $context))))))

(= (codex:environment-context-matches-text $text)
   (codex:contextual-fragment-matches-markers
     (codex:environment-context-start-marker)
     (codex:environment-context-end-marker)
     $text))

(= (codex:hook-prompt-fragment $text $hook-run-id)
   (CodexHookPromptFragment $text $hook-run-id))

(= (codex:hook-prompt-fragment-text
      (CodexHookPromptFragment $text $hook-run-id))
   $text)

(= (codex:hook-prompt-fragment-hook-run-id
      (CodexHookPromptFragment $text $hook-run-id))
   $hook-run-id)

(= (codex:hook-prompt-item $id $fragments)
   (CodexHookPromptItem $id $fragments))

(= (codex:hook-prompt-item-id
      (CodexHookPromptItem $id $fragments))
   $id)

(= (codex:hook-prompt-item-fragments
      (CodexHookPromptItem $id $fragments))
   $fragments)

(= (codex:hook-prompt-start-prefix-double)
   "<hook_prompt hook_run_id=\"")

(= (codex:hook-prompt-start-prefix-single)
   "<hook_prompt hook_run_id='")

(= (codex:hook-prompt-close-tag)
   "</hook_prompt>")

(= (codex:serialize-hook-prompt-fragment $fragment)
   (let $hook-run-id (codex:hook-prompt-fragment-hook-run-id $fragment)
     (if (== (str-trim $hook-run-id) "")
         Empty
         (str-concat
           (codex:hook-prompt-start-prefix-double)
           (str-concat
             (codex:xml-escape-attribute $hook-run-id)
             (str-concat
               "\">"
               (str-concat
                 (codex:xml-escape-text
                   (codex:hook-prompt-fragment-text $fragment))
                 (codex:hook-prompt-close-tag))))))))

(= (codex:parse-hook-prompt-fragment-with-prefix
      $trimmed
      $start-prefix
      $end-of-open-tag)
   (if (str-starts-with? $trimmed $start-prefix)
       (if (str-ends-with? $trimmed (codex:hook-prompt-close-tag))
           (let $after-prefix
             (str-slice
               $trimmed
               (str-length $start-prefix)
               (str-length $trimmed))
             (let $end-of-id (str-find $after-prefix $end-of-open-tag)
               (if (== $end-of-id Empty)
                   Empty
                   (let $hook-run-id
                     (codex:xml-unescape-predefined-entities
                       (str-slice $after-prefix 0 $end-of-id))
                     (if (== (str-trim $hook-run-id) "")
                         Empty
                         (let $body-start
                           (+ (str-length $start-prefix)
                              (+ $end-of-id
                                 (str-length $end-of-open-tag)))
                           (let $body-end
                             (- (str-length $trimmed)
                                (str-length
                                  (codex:hook-prompt-close-tag)))
                             (codex:hook-prompt-fragment
                               (codex:xml-unescape-predefined-entities
                                 (str-slice $trimmed $body-start $body-end))
                               $hook-run-id))))))))
           Empty)
       Empty))

(= (codex:parse-hook-prompt-fragment $text)
   (let $trimmed (str-trim $text)
     (let $parsed-double
       (codex:parse-hook-prompt-fragment-with-prefix
         $trimmed
         (codex:hook-prompt-start-prefix-double)
         "\">")
       (if (== $parsed-double Empty)
           (codex:parse-hook-prompt-fragment-with-prefix
             $trimmed
             (codex:hook-prompt-start-prefix-single)
             "'>")
           $parsed-double))))

(= (codex:build-hook-prompt-message-content $fragments)
   (if (== $fragments ())
       ()
       (let $head (list:first $fragments)
         (let $tail (list:rest $fragments)
           (let $tail-content
             (codex:build-hook-prompt-message-content $tail)
             (let $serialized (codex:serialize-hook-prompt-fragment $head)
               (if (== $serialized Empty)
                   $tail-content
                   (cons-atom (CodexInputText $serialized) $tail-content))))))))

(= (codex:build-hook-prompt-message $fragments)
   (let $content (codex:build-hook-prompt-message-content $fragments)
     (if (== $content ())
         Empty
         (CodexResponseItemMessage "user" $content CodexAbsent))))

(= (codex:hook-prompt-parse-fragments-ok $fragments)
   (CodexHookPromptParseFragmentsOk $fragments))

(= (codex:hook-prompt-parse-fragments-invalid)
   (CodexHookPromptParseFragmentsInvalid))

(= (codex:parse-visible-hook-prompt-message-fragments $content)
   (if (== $content ())
       (codex:hook-prompt-parse-fragments-ok ())
       (let $head (list:first $content)
         (let $tail (list:rest $content)
           (case $head
             (((CodexInputText $text)
               (let $fragment (codex:parse-hook-prompt-fragment $text)
                 (if (== $fragment Empty)
                     (if (codex:is-standard-contextual-user-text $text)
                         (codex:parse-visible-hook-prompt-message-fragments
                           $tail)
                         (codex:hook-prompt-parse-fragments-invalid))
                     (case
                       (codex:parse-visible-hook-prompt-message-fragments
                         $tail)
                       (((CodexHookPromptParseFragmentsOk $fragments)
                         (codex:hook-prompt-parse-fragments-ok
                           (cons-atom $fragment $fragments)))
                        ((CodexHookPromptParseFragmentsInvalid)
                         (codex:hook-prompt-parse-fragments-invalid)))))))
              ($other
                (codex:hook-prompt-parse-fragments-invalid))))))))

(= (codex:parse-visible-hook-prompt-message $id $content)
   (case (codex:parse-visible-hook-prompt-message-fragments $content)
     (((CodexHookPromptParseFragmentsOk $fragments)
       (if (== $fragments ())
           Empty
           (codex:hook-prompt-item $id $fragments)))
      ((CodexHookPromptParseFragmentsInvalid)
       Empty))))

(= (codex:skill-instructions-role)
   "user")

(= (codex:skill-instructions-start-marker)
   "<skill>")

(= (codex:skill-instructions-end-marker)
   "</skill>")

(= (codex:skill-instructions $name $path $contents)
   (codex:contextual-fragment
     (codex:skill-instructions-role)
     (codex:skill-instructions-start-marker)
     (codex:skill-instructions-end-marker)
     (format-args
       "\n<name>{}</name>\n<path>{}</path>\n{}\n"
       ($name $path $contents))))

(= (codex:skill-instructions-matches-text $text)
   (codex:contextual-fragment-matches-markers
     (codex:skill-instructions-start-marker)
     (codex:skill-instructions-end-marker)
     $text))

(= (codex:agent-status-pending-init)
   (CodexAgentStatusPendingInit))

(= (codex:agent-status-running)
   (CodexAgentStatusRunning))

(= (codex:agent-status-interrupted)
   (CodexAgentStatusInterrupted))

(= (codex:agent-status-completed $message)
   (CodexAgentStatusCompleted $message))

(= (codex:agent-status-errored $message)
   (CodexAgentStatusErrored $message))

(= (codex:agent-status-shutdown)
   (CodexAgentStatusShutdown))

(= (codex:agent-status-not-found)
   (CodexAgentStatusNotFound))

(= (codex:agent-status-json-value-for-completed $message)
   (if (== $message CodexAbsent)
       (JsonNull CodexAbsent)
       (JsonString $message)))

(= (codex:agent-status-json (CodexAgentStatusPendingInit))
   (JsonString "pending_init"))

(= (codex:agent-status-json (CodexAgentStatusRunning))
   (JsonString "running"))

(= (codex:agent-status-json (CodexAgentStatusInterrupted))
   (JsonString "interrupted"))

(= (codex:agent-status-json (CodexAgentStatusCompleted $message))
   (JsonObject
     ((JsonPair
        "completed"
        (codex:agent-status-json-value-for-completed $message)))))

(= (codex:agent-status-json (CodexAgentStatusErrored $message))
   (JsonObject
     ((JsonPair "errored" (JsonString $message)))))

(= (codex:agent-status-json (CodexAgentStatusShutdown))
   (JsonString "shutdown"))

(= (codex:agent-status-json (CodexAgentStatusNotFound))
   (JsonString "not_found"))

(= (codex:subagent-notification-role)
   "user")

(= (codex:subagent-notification-start-marker)
   "<subagent_notification>")

(= (codex:subagent-notification-end-marker)
   "</subagent_notification>")

(= (codex:subagent-notification $agent-reference $status)
   (codex:contextual-fragment
     (codex:subagent-notification-role)
     (codex:subagent-notification-start-marker)
     (codex:subagent-notification-end-marker)
     (format-args
       "\n{}\n"
       ((json-stringify
          (JsonObject
            ((JsonPair "agent_path" (JsonString $agent-reference))
             (JsonPair "status" (codex:agent-status-json $status)))))))))

(= (codex:subagent-notification-matches-text $text)
   (codex:contextual-fragment-matches-markers
     (codex:subagent-notification-start-marker)
     (codex:subagent-notification-end-marker)
     $text))

(= (codex:permissions-contextual-fragment $instructions)
   (codex:contextual-fragment
     (codex:permissions-instructions-role)
     (codex:permissions-instructions-start-marker)
     (codex:permissions-instructions-end-marker)
     (codex:permissions-instructions-body $instructions)))

(= (codex:is-standard-contextual-user-text $text)
   (if (codex:user-instructions-matches-text $text)
       True
       (if (codex:environment-context-matches-text $text)
           True
           (if (codex:skill-instructions-matches-text $text)
               True
               (if (codex:user-shell-command-matches-text $text)
                   True
                   (if (codex:turn-aborted-matches-text $text)
                       True
                       (if (codex:subagent-notification-matches-text $text)
                           True
                           False)))))))

(= (codex:is-memory-excluded-standard-contextual-user-text $text)
   (if (codex:user-instructions-matches-text $text)
       True
       (if (codex:skill-instructions-matches-text $text)
           True
           False)))

(= (codex:is-contextual-user-fragment $content-item)
   (case $content-item
     (((CodexInputText $text)
       (let $fragment (codex:parse-hook-prompt-fragment $text)
         (if (== $fragment Empty)
             (codex:is-standard-contextual-user-text $text)
             True)))
      ($other False))))

(= (codex:is-memory-excluded-contextual-user-fragment $content-item)
   (case $content-item
     (((CodexInputText $text)
       (codex:is-memory-excluded-standard-contextual-user-text $text))
      ($other False))))
