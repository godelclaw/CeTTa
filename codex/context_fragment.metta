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
; - AvailableSkillsInstructions
; - AvailablePluginsInstructions
; - AppsInstructions
; - PluginInstructions
; - CollaborationModeInstructions
; - PersonalitySpecInstructions
; - ImageGenerationInstructions
; - ModelSwitchInstructions
; - GuardianFollowupReviewReminder
; - HookAdditionalContext
; - ApprovedCommandPrefixSaved
; - NetworkRuleSaved
; - RealtimeStartInstructions
; - RealtimeStartWithInstructions
; - RealtimeEndInstructions
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
; - Rust's `AvailableSkillsInstructions` is built from `AvailableSkills`, and
;   `AvailablePluginsInstructions::from_plugins()` returns `Option<Self>`.
;   The current CeTTa slice keeps the same visible behavior through direct
;   helper records, using `Empty` for the absent `Option` case because there is
;   not yet a broader runtime option layer in this port slice.
; - Rust's `AppsInstructions::from_connectors()` depends on the wider
;   `AppInfo` surface, and `CollaborationModeInstructions` depends on the full
;   `CollaborationMode.settings` runtime config object. The current CeTTa slice
;   ports the exact visible fragment behavior through direct helper records that
;   keep only the fields read by these fragment constructors.
; - Rust's `NetworkRuleSaved::new()` depends on the wider approvals protocol
;   `NetworkPolicyAmendment`/`NetworkPolicyRuleAction` surface. The current
;   CeTTa slice ports the exact visible fragment behavior through direct helper
;   records that keep only the action/host fields read by this fragment.
; - Rust loads the realtime conversation instructions through `include_str!`
;   prompt files and trims them before wrapping them in the fragment body. The
;   current CeTTa slice ports those exact visible prompt texts as inline string
;   constants because there is not yet a prompt-file loader at this layer.
; - Rust's hook-prompt parsing delegates to quick-xml and therefore accepts a
;   broader XML surface. The current CeTTa slice ports the specific
;   `hook_prompt` shape emitted by Codex itself, with predefined XML entities,
;   because there is not yet a general XML parser in the runtime.

!(import! &self permissions_instructions)
!(import! &self protocol)
!(import! &self json)
!(import! &self list)
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
   ; CeTTa reduction detail: reuse the protocol slice's already-stable ASCII
   ; lower helper. The visible ASCII-only behavior matches Rust.
   (codex:product-ascii-lower-text $text))

(= (codex:text-equals-ignore-ascii-case $lhs $rhs)
   (let $lhs-lower (codex:ascii-lower-text $lhs)
     (let $rhs-lower (codex:ascii-lower-text $rhs)
       (== $lhs-lower $rhs-lower))))

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
   (case
     (codex:contextual-fragment-matches-markers
       (codex:user-instructions-start-marker)
       (codex:user-instructions-end-marker)
       $text)
     ((True True)
      (False False))))

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
   (case
     (codex:contextual-fragment-matches-markers
       (codex:user-shell-command-start-marker)
       (codex:user-shell-command-end-marker)
       $text)
     ((True True)
      (False False))))

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
   (case
     (codex:contextual-fragment-matches-markers
       (codex:turn-aborted-start-marker)
       (codex:turn-aborted-end-marker)
       $text)
     ((True True)
      (False False))))

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

(= (codex:environment-context-cwd-lines CodexAbsent)
   ())

(= (codex:environment-context-cwd-lines $cwd)
   ((format-args
      "  <cwd>{}</cwd>"
      ($cwd))))

(= (codex:environment-context-current-date-lines CodexAbsent)
   ())

(= (codex:environment-context-current-date-lines $current-date)
   ((format-args
      "  <current_date>{}</current_date>"
      ($current-date))))

(= (codex:environment-context-timezone-lines CodexAbsent)
   ())

(= (codex:environment-context-timezone-lines $timezone)
   ((format-args
      "  <timezone>{}</timezone>"
      ($timezone))))

(= (codex:environment-context-domain-lines $domains $tag-name)
   (if (== $domains ())
       ()
       (let $head (list:first $domains)
         (let $tail (list:rest $domains)
           (let $tail-lines
             (eval
               (codex:environment-context-domain-lines
                 $tail
                 $tag-name))
             (eval
               (list:append
                 ((format-args "    <{}>{}</{}>" ($tag-name $head $tag-name)))
                 $tail-lines)))))))

(= (codex:prefix-lines $lines $prefix)
   (if (== $lines ())
       ()
       (let $head (list:first $lines)
         (let $tail (list:rest $lines)
           (let $tail-lines
             (eval (codex:prefix-lines $tail $prefix))
             (eval
               (list:append
                 ((str-concat $prefix $head))
                 $tail-lines)))))))

(= (codex:environment-context-subagent-lines $subagents)
   (if (== $subagents "")
       ()
       (let $lines (str-split "\n" $subagents)
         (codex:prefix-lines $lines "    "))))

(= (codex:environment-context-network-lines CodexAbsent)
   ())

(= (codex:environment-context-network-lines $network)
   (let $allowed-domains
     (codex:environment-network-context-allowed-domains $network)
     (let $denied-domains
       (codex:environment-network-context-denied-domains $network)
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
                 (eval
                   (codex:append-item $lines-2 "  </network>"))))))))))

(= (codex:environment-context-subagents-block-lines CodexAbsent)
   ())

(= (codex:environment-context-subagents-block-lines $subagents)
   (let $subagent-lines (codex:environment-context-subagent-lines $subagents)
     (let $lines-0
       (codex:append-item () "  <subagents>")
       (let $lines-1 (list:append $lines-0 $subagent-lines)
         (eval
           (codex:append-item $lines-1 "  </subagents>"))))))

(= (codex:environment-context-lines-from-fields
      $cwd
      $shell
      $current-date
      $timezone
      $network
      $subagents)
   (eval
     (list:append
       (codex:environment-context-cwd-lines $cwd)
       (list:append
         ((format-args
            "  <shell>{}</shell>"
            ($shell)))
         (list:append
           (codex:environment-context-current-date-lines $current-date)
           (list:append
             (codex:environment-context-timezone-lines $timezone)
             (list:append
               (if (== $network CodexAbsent)
                   ()
                   (eval
                     (codex:environment-context-network-lines
                       $network)))
               (if (== $subagents CodexAbsent)
                   ()
                   (eval
                     (codex:environment-context-subagents-block-lines
                       $subagents))))))))))

(= (codex:environment-context-lines $context)
   (codex:environment-context-lines-from-fields
     (codex:environment-context-cwd $context)
     (codex:environment-context-shell $context)
     (codex:environment-context-current-date $context)
     (codex:environment-context-timezone $context)
     (codex:environment-context-network $context)
     (codex:environment-context-subagents $context)))

(= (codex:append-line-text $text $line)
   (if (== $text "")
       $line
       (if (== $line "")
           $text
           (str-concat $text (str-concat "\n" $line)))))

(= (codex:environment-context-domain-lines-text () $tag-name)
   "")

(= (codex:environment-context-domain-lines-text $domains $tag-name)
   (let $head (list:first $domains)
     (let $tail (list:rest $domains)
       (let $line
         (format-args "    <{}>{}</{}>" ($tag-name $head $tag-name))
         (codex:append-line-text
           $line
           (codex:environment-context-domain-lines-text $tail $tag-name))))))

(= (codex:prefixed-lines-text () $prefix)
   "")

(= (codex:prefixed-lines-text $lines $prefix)
   (let $head (list:first $lines)
     (let $tail (list:rest $lines)
       (let $line (str-concat $prefix $head)
         (codex:append-line-text
           $line
           (codex:prefixed-lines-text $tail $prefix))))))

(= (codex:environment-context-subagents-block-text $subagents)
   (if (== $subagents CodexAbsent)
       ""
       (if (== $subagents "")
       ""
           (let $inner
             (codex:prefixed-lines-text (str-split "\n" $subagents) "    ")
             (str-concat
               "  <subagents>\n"
               (str-concat $inner "\n  </subagents>"))))))

(= (codex:environment-context-network-block-text $network)
   (if (== $network CodexAbsent)
       ""
       (let $text-0 "  <network enabled=\"true\">"
         (let $allowed-text
           (codex:environment-context-domain-lines-text
             (codex:environment-network-context-allowed-domains $network)
             "allowed")
           (let $text-1
             (codex:append-line-text $text-0 $allowed-text)
             (let $denied-text
               (codex:environment-context-domain-lines-text
                 (codex:environment-network-context-denied-domains $network)
                 "denied")
               (let $text-2
                 (codex:append-line-text $text-1 $denied-text)
                 (codex:append-line-text $text-2 "  </network>"))))))))

(= (codex:environment-context-body-text $context)
   (let $text-0
     (if (== (codex:environment-context-cwd $context) CodexAbsent)
         ""
         (format-args
           "  <cwd>{}</cwd>"
           ((codex:environment-context-cwd $context))))
     (let $text-1
       (codex:append-line-text
         $text-0
         (format-args
           "  <shell>{}</shell>"
           ((codex:environment-context-shell $context))))
       (let $text-2
         (if (== (codex:environment-context-current-date $context) CodexAbsent)
             $text-1
             (codex:append-line-text
               $text-1
               (format-args
                 "  <current_date>{}</current_date>"
                 ((codex:environment-context-current-date $context)))))
         (let $text-3
           (if (== (codex:environment-context-timezone $context) CodexAbsent)
               $text-2
               (codex:append-line-text
                 $text-2
                 (format-args
                   "  <timezone>{}</timezone>"
                   ((codex:environment-context-timezone $context)))))
           (let $network-block
             (codex:environment-context-network-block-text
               (codex:environment-context-network $context))
             (let $text-4
               (if (== $network-block "")
                   $text-3
                   (codex:append-line-text $text-3 $network-block))
               (let $subagents-block
                 (codex:environment-context-subagents-block-text
                   (codex:environment-context-subagents $context))
                 (if (== $subagents-block "")
                     $text-4
                     (codex:append-line-text $text-4 $subagents-block))))))))))

(= (codex:environment-context-fragment $context)
   (codex:contextual-fragment
     (codex:environment-context-role)
     (codex:environment-context-start-marker)
     (codex:environment-context-end-marker)
     (format-args
       "\n{}\n"
       ((codex:environment-context-body-text $context)))))

(= (codex:environment-context-matches-text $text)
   (case
     (codex:contextual-fragment-matches-markers
       (codex:environment-context-start-marker)
       (codex:environment-context-end-marker)
       $text)
     ((True True)
      (False False))))

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
   (case
     (codex:contextual-fragment-matches-markers
       (codex:skill-instructions-start-marker)
       (codex:skill-instructions-end-marker)
       $text)
     ((True True)
      (False False))))

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
   (case
     (codex:contextual-fragment-matches-markers
       (codex:subagent-notification-start-marker)
       (codex:subagent-notification-end-marker)
       $text)
     ((True True)
      (False False))))

(= (codex:permissions-contextual-fragment $instructions)
   (codex:contextual-fragment
     (codex:permissions-instructions-role)
     (codex:permissions-instructions-start-marker)
     (codex:permissions-instructions-end-marker)
     (codex:permissions-instructions-body $instructions)))

(= (codex:apps-mcp-server-name)
   "codex_apps")

(= (codex:apps-instructions-role)
   "developer")

(= (codex:apps-instructions-start-marker)
   "<apps_instructions>")

(= (codex:apps-instructions-end-marker)
   "</apps_instructions>")

(= (codex:app-info $id $name $is-accessible $is-enabled)
   (CodexAppInfo $id $name $is-accessible $is-enabled))

(= (codex:app-info-id (CodexAppInfo $id $name $is-accessible $is-enabled))
   $id)

(= (codex:app-info-name (CodexAppInfo $id $name $is-accessible $is-enabled))
   $name)

(= (codex:app-info-is-accessible
      (CodexAppInfo $id $name $is-accessible $is-enabled))
   $is-accessible)

(= (codex:app-info-is-enabled
      (CodexAppInfo $id $name $is-accessible $is-enabled))
   $is-enabled)

(= (codex:any-accessible-enabled-connectors $connectors)
   (if (== $connectors ())
       False
       (let $head (list:first $connectors)
         (let $tail (list:rest $connectors)
           (if (codex:app-info-is-accessible $head)
               (if (codex:app-info-is-enabled $head)
                   True
                   (codex:any-accessible-enabled-connectors $tail))
               (codex:any-accessible-enabled-connectors $tail))))))

(= (codex:apps-instructions)
   (codex:contextual-fragment
     (codex:apps-instructions-role)
     (codex:apps-instructions-start-marker)
     (codex:apps-instructions-end-marker)
     (str-concat
       "\n## Apps (Connectors)\nApps (Connectors) can be explicitly triggered in user messages in the format `[$app-name](app://{connector_id})`. Apps can also be implicitly triggered as long as the context suggests usage of available apps.\nAn app is equivalent to a set of MCP tools within the `"
       (str-concat
         (codex:apps-mcp-server-name)
         (str-concat
           "` MCP.\nAn installed app's MCP tools are either provided to you already, or can be lazy-loaded through the `tool_search` tool. If `tool_search` is available, the apps that are searchable by `tools_search` will be listed by it.\nDo not additionally call list_mcp_resources or list_mcp_resource_templates for apps.\n"
           "")))))

(= (codex:apps-instructions-from-connectors $connectors)
   (if (codex:any-accessible-enabled-connectors $connectors)
       (codex:apps-instructions)
       Empty))

(= (codex:apps-instructions-matches-text $text)
   (let $trimmed-lower (codex:ascii-lower-text (str-trim $text))
     (if (str-starts-with? $trimmed-lower "<apps_instructions>")
         (str-ends-with? $trimmed-lower "</apps_instructions>")
         False)))

(= (codex:plugin-instructions-role)
   "developer")

(= (codex:plugin-instructions-start-marker)
   "")

(= (codex:plugin-instructions-end-marker)
   "")

(= (codex:plugin-instructions $text)
   (codex:contextual-fragment
     (codex:plugin-instructions-role)
     (codex:plugin-instructions-start-marker)
     (codex:plugin-instructions-end-marker)
     $text))

(= (codex:plugin-instructions-matches-text $text)
   (codex:contextual-fragment-matches-markers
     (codex:plugin-instructions-start-marker)
     (codex:plugin-instructions-end-marker)
     $text))

(= (codex:collaboration-mode-instructions-role)
   "developer")

(= (codex:collaboration-mode-instructions-start-marker)
   "<collaboration_mode>")

(= (codex:collaboration-mode-instructions-end-marker)
   "</collaboration_mode>")

(= (codex:settings $model $reasoning-effort $developer-instructions)
   (CodexSettings $model $reasoning-effort $developer-instructions))

(= (codex:settings-model (CodexSettings $model $reasoning-effort $developer-instructions))
   $model)

(= (codex:settings-reasoning-effort
      (CodexSettings $model $reasoning-effort $developer-instructions))
   $reasoning-effort)

(= (codex:settings-developer-instructions
      (CodexSettings $model $reasoning-effort $developer-instructions))
   $developer-instructions)

(= (codex:collaboration-mode $mode $settings)
   (CodexCollaborationMode $mode $settings))

(= (codex:collaboration-mode-kind
      (CodexCollaborationMode $mode $settings))
   $mode)

(= (codex:collaboration-mode-settings
      (CodexCollaborationMode $mode $settings))
   $settings)

(= (codex:collaboration-mode-instructions $instructions)
   (codex:contextual-fragment
     (codex:collaboration-mode-instructions-role)
     (codex:collaboration-mode-instructions-start-marker)
     (codex:collaboration-mode-instructions-end-marker)
     $instructions))

(= (codex:collaboration-mode-instructions-from-collaboration-mode
      $collaboration-mode)
   (let $developer-instructions
     (codex:settings-developer-instructions
       (codex:collaboration-mode-settings $collaboration-mode))
     (if (== $developer-instructions CodexAbsent)
         Empty
         (if (== $developer-instructions "")
             Empty
             (codex:collaboration-mode-instructions
               $developer-instructions)))))

(= (codex:collaboration-mode-instructions-matches-text $text)
   (codex:contextual-fragment-matches-markers
     (codex:collaboration-mode-instructions-start-marker)
     (codex:collaboration-mode-instructions-end-marker)
     $text))

(= (codex:personality-spec-instructions-role)
   "developer")

(= (codex:personality-spec-instructions-start-marker)
   "<personality_spec>")

(= (codex:personality-spec-instructions-end-marker)
   "</personality_spec>")

(= (codex:personality-spec-instructions $spec)
   (codex:contextual-fragment
     (codex:personality-spec-instructions-role)
     (codex:personality-spec-instructions-start-marker)
     (codex:personality-spec-instructions-end-marker)
     (format-args
       " The user has requested a new communication style. Future messages should adhere to the following personality: \n{} "
       ($spec))))

(= (codex:personality-spec-instructions-matches-text $text)
   (codex:contextual-fragment-matches-markers
     (codex:personality-spec-instructions-start-marker)
     (codex:personality-spec-instructions-end-marker)
     $text))

(= (codex:image-generation-instructions-role)
   "developer")

(= (codex:image-generation-instructions-start-marker)
   "")

(= (codex:image-generation-instructions-end-marker)
   "")

(= (codex:image-generation-instructions $image-output-dir $image-output-path)
   (codex:contextual-fragment
     (codex:image-generation-instructions-role)
     (codex:image-generation-instructions-start-marker)
     (codex:image-generation-instructions-end-marker)
     (format-args
       "Generated images are saved to {} as {} by default.\nIf you need to use a generated image at another path, copy it and leave the original in place unless the user explicitly asks you to delete it."
       ($image-output-dir $image-output-path))))

(= (codex:image-generation-instructions-matches-text $text)
   (codex:contextual-fragment-matches-markers
     (codex:image-generation-instructions-start-marker)
     (codex:image-generation-instructions-end-marker)
     $text))

(= (codex:model-switch-instructions-role)
   "developer")

(= (codex:model-switch-instructions-start-marker)
   "<model_switch>")

(= (codex:model-switch-instructions-end-marker)
   "</model_switch>")

(= (codex:model-switch-instructions $model-instructions)
   (codex:contextual-fragment
     (codex:model-switch-instructions-role)
     (codex:model-switch-instructions-start-marker)
     (codex:model-switch-instructions-end-marker)
     (format-args
       "\nThe user was previously using a different model. Please continue the conversation according to the following instructions:\n\n{}\n"
       ($model-instructions))))

(= (codex:model-switch-instructions-matches-text $text)
   (codex:contextual-fragment-matches-markers
     (codex:model-switch-instructions-start-marker)
     (codex:model-switch-instructions-end-marker)
     $text))

(= (codex:guardian-followup-review-reminder-role)
   "developer")

(= (codex:guardian-followup-review-reminder-start-marker)
   "")

(= (codex:guardian-followup-review-reminder-end-marker)
   "")

(= (codex:guardian-followup-review-reminder)
   (codex:contextual-fragment
     (codex:guardian-followup-review-reminder-role)
     (codex:guardian-followup-review-reminder-start-marker)
     (codex:guardian-followup-review-reminder-end-marker)
     "Use prior reviews as context, not binding precedent. Follow the Workspace Policy. If the user explicitly approves a previously rejected action after being informed of the concrete risks, set outcome to \"allow\" unless the policy explicitly disallows user overwrites in such cases."))

(= (codex:guardian-followup-review-reminder-matches-text $text)
   (codex:contextual-fragment-matches-markers
     (codex:guardian-followup-review-reminder-start-marker)
     (codex:guardian-followup-review-reminder-end-marker)
     $text))

(= (codex:hook-additional-context-role)
   "developer")

(= (codex:hook-additional-context-start-marker)
   "")

(= (codex:hook-additional-context-end-marker)
   "")

(= (codex:hook-additional-context $text)
   (codex:contextual-fragment
     (codex:hook-additional-context-role)
     (codex:hook-additional-context-start-marker)
     (codex:hook-additional-context-end-marker)
     $text))

(= (codex:hook-additional-context-matches-text $text)
   (codex:contextual-fragment-matches-markers
     (codex:hook-additional-context-start-marker)
     (codex:hook-additional-context-end-marker)
     $text))

(= (codex:approved-command-prefix-saved-role)
   "developer")

(= (codex:approved-command-prefix-saved-start-marker)
   "")

(= (codex:approved-command-prefix-saved-end-marker)
   "")

(= (codex:approved-command-prefix-saved $prefixes)
   (codex:contextual-fragment
     (codex:approved-command-prefix-saved-role)
     (codex:approved-command-prefix-saved-start-marker)
     (codex:approved-command-prefix-saved-end-marker)
     (format-args
       "Approved command prefix saved:\n{}"
       ($prefixes))))

(= (codex:approved-command-prefix-saved-matches-text $text)
   (codex:contextual-fragment-matches-markers
     (codex:approved-command-prefix-saved-start-marker)
     (codex:approved-command-prefix-saved-end-marker)
     $text))

(= (codex:network-policy-rule-action-allow)
   (CodexNetworkPolicyRuleActionAllow))

(= (codex:network-policy-rule-action-deny)
   (CodexNetworkPolicyRuleActionDeny))

(= (codex:network-policy-amendment $action $host)
   (CodexNetworkPolicyAmendment $action $host))

(= (codex:network-policy-amendment-action
      (CodexNetworkPolicyAmendment $action $host))
   $action)

(= (codex:network-policy-amendment-host
      (CodexNetworkPolicyAmendment $action $host))
   $host)

(= (codex:network-rule-saved-role)
   "developer")

(= (codex:network-rule-saved-start-marker)
   "")

(= (codex:network-rule-saved-end-marker)
   "")

(= (codex:network-rule-saved-action-text
      (CodexNetworkPolicyRuleActionAllow))
   "Allowed")

(= (codex:network-rule-saved-action-text
      (CodexNetworkPolicyRuleActionDeny))
   "Denied")

(= (codex:network-rule-saved-list-name
      (CodexNetworkPolicyRuleActionAllow))
   "allowlist")

(= (codex:network-rule-saved-list-name
      (CodexNetworkPolicyRuleActionDeny))
   "denylist")

(= (codex:network-rule-saved $action $host)
   (codex:contextual-fragment
     (codex:network-rule-saved-role)
     (codex:network-rule-saved-start-marker)
     (codex:network-rule-saved-end-marker)
     (format-args
       "{} network rule saved in execpolicy ({}): {}"
       ((codex:network-rule-saved-action-text $action)
        (codex:network-rule-saved-list-name $action)
        $host))))

; CeTTa reduction detail: matching the minimal amendment record directly avoids
; an extra accessor reduction layer while preserving Rust's visible behavior.
(= (codex:network-rule-saved-from-amendment
      (CodexNetworkPolicyAmendment $action $host))
   (codex:network-rule-saved $action $host))

(= (codex:network-rule-saved-matches-text $text)
   (codex:contextual-fragment-matches-markers
     (codex:network-rule-saved-start-marker)
     (codex:network-rule-saved-end-marker)
     $text))

(= (codex:realtime-conversation-role)
   "developer")

(= (codex:realtime-conversation-start-marker)
   "<realtime_conversation>")

(= (codex:realtime-conversation-end-marker)
   "</realtime_conversation>")

(= (codex:realtime-start-instructions-text)
   "Realtime conversation started.\n\nYou are operating as a backend executor behind an intermediary. The user does not talk to you directly. Any response you produce will be consumed by the intermediary and may be summarized before the user sees it.\n\nWhen invoked, you receive the latest conversation transcript and any relevant mode or metadata. The intermediary may invoke you even when backend help is not actually needed. Use the transcript to decide whether you should do work. If backend help is unnecessary, avoid verbose responses that add user-visible latency.\n\nWhen user text is routed from realtime, treat it as a transcript. It may be unpunctuated or contain recognition errors.\n\n- Keep responses concise and action-oriented. Your updates should help the intermediary respond to the user.")

(= (codex:realtime-end-instructions-text)
   "Realtime conversation ended.\n\nSubsequent user input will return to typed text rather than transcript-style text. Do not assume recognition errors or missing punctuation once realtime has ended. Resume normal chat behavior.")

(= (codex:realtime-start-instructions)
   (codex:contextual-fragment
     (codex:realtime-conversation-role)
     (codex:realtime-conversation-start-marker)
     (codex:realtime-conversation-end-marker)
     (format-args
       "\n{}\n"
       ((codex:realtime-start-instructions-text)))))

(= (codex:realtime-start-with-instructions $instructions)
   (codex:contextual-fragment
     (codex:realtime-conversation-role)
     (codex:realtime-conversation-start-marker)
     (codex:realtime-conversation-end-marker)
     (format-args
       "\n{}\n"
       ($instructions))))

(= (codex:realtime-end-instructions $reason)
   (codex:contextual-fragment
     (codex:realtime-conversation-role)
     (codex:realtime-conversation-start-marker)
     (codex:realtime-conversation-end-marker)
     (format-args
       "\n{}\n\nReason: {}\n"
       ((codex:realtime-end-instructions-text) $reason))))

(= (codex:realtime-conversation-matches-text $text)
   (case
     (codex:contextual-fragment-matches-markers
       (codex:realtime-conversation-start-marker)
       (codex:realtime-conversation-end-marker)
       $text)
     ((True True)
      (False False))))

(= (codex:available-skills-instructions-role)
   "developer")

(= (codex:available-skills-instructions-start-marker)
   "<skills_instructions>")

(= (codex:available-skills-instructions-end-marker)
   "</skills_instructions>")

(= (codex:available-skills $skill-lines)
   (CodexAvailableSkills $skill-lines))

(= (codex:available-skills-skill-lines
      (CodexAvailableSkills $skill-lines))
   $skill-lines)

(= (codex:available-skills-instructions-guidance)
   "- Discovery: The list above is the skills available in this session (name + description + file path). Skill bodies live on disk at the listed paths.\n- Trigger rules: If the user names a skill (with `$SkillName` or plain text) OR the task clearly matches a skill's description shown above, you must use that skill for that turn. Multiple mentions mean use them all. Do not carry skills across turns unless re-mentioned.\n- Missing/blocked: If a named skill isn't in the list or the path can't be read, say so briefly and continue with the best fallback.\n- How to use a skill (progressive disclosure):\n  1) After deciding to use a skill, open its `SKILL.md`. Read only enough to follow the workflow.\n  2) When `SKILL.md` references relative paths (e.g., `scripts/foo.py`), resolve them relative to the skill directory listed above first, and only consider other paths if needed.\n  3) If `SKILL.md` points to extra folders such as `references/`, load only the specific files needed for the request; don't bulk-load everything.\n  4) If `scripts/` exist, prefer running or patching them instead of retyping large code blocks.\n  5) If `assets/` or templates exist, reuse them instead of recreating from scratch.\n- Coordination and sequencing:\n  - If multiple skills apply, choose the minimal set that covers the request and state the order you'll use them.\n  - Announce which skill(s) you're using and why (one short line). If you skip an obvious skill, say why.\n- Context hygiene:\n  - Keep context small: summarize long sections instead of pasting them; only load extra files when needed.\n  - Avoid deep reference-chasing: prefer opening only files directly linked from `SKILL.md` unless you're blocked.\n  - When variants exist (frameworks, providers, domains), pick only the relevant reference file(s) and note that choice.\n- Safety and fallback: If a skill can't be applied cleanly (missing files, unclear instructions), state the issue, pick the next-best approach, and continue.")

(= (codex:available-skills-instructions $skill-lines)
   (codex:contextual-fragment
     (codex:available-skills-instructions-role)
     (codex:available-skills-instructions-start-marker)
     (codex:available-skills-instructions-end-marker)
     (format-args
       "\n## Skills\nA skill is a set of local instructions to follow that is stored in a `SKILL.md` file. Below is the list of skills that can be used. Each entry includes a name, description, and file path so you can open the source for full instructions when using a specific skill.\n### Available skills\n{}\n### How to use skills\n{}\n"
       ((str-join "\n" (once $skill-lines))
        (codex:available-skills-instructions-guidance)))))

; CeTTa reduction detail: forcing the helper accessor through `eval` avoids a
; nested reduction hole here while preserving Rust's visible behavior.
(= (codex:available-skills-instructions-from-available-skills $available-skills)
   (function
     (let $skill-lines
       (eval (codex:available-skills-skill-lines $available-skills))
       (return
         (codex:available-skills-instructions $skill-lines)))))

(= (codex:available-skills-instructions-matches-text $text)
   (case
     (codex:contextual-fragment-matches-markers
       (codex:available-skills-instructions-start-marker)
       (codex:available-skills-instructions-end-marker)
       $text)
     ((True True)
      (False False))))

(= (codex:app-connector-id $text)
   (CodexAppConnectorId $text))

(= (codex:app-connector-id-text (CodexAppConnectorId $text))
   $text)

(= (codex:plugin-capability-summary
      $config-name
      $display-name
      $description
      $has-skills
      $mcp-server-names
      $app-connector-ids)
   (CodexPluginCapabilitySummary
     $config-name
     $display-name
     $description
     $has-skills
     $mcp-server-names
     $app-connector-ids))

(= (codex:plugin-capability-summary-config-name
      (CodexPluginCapabilitySummary
        $config-name
        $display-name
        $description
        $has-skills
        $mcp-server-names
        $app-connector-ids))
   $config-name)

(= (codex:plugin-capability-summary-display-name
      (CodexPluginCapabilitySummary
        $config-name
        $display-name
        $description
        $has-skills
        $mcp-server-names
        $app-connector-ids))
   $display-name)

(= (codex:plugin-capability-summary-description
      (CodexPluginCapabilitySummary
        $config-name
        $display-name
        $description
        $has-skills
        $mcp-server-names
        $app-connector-ids))
   $description)

(= (codex:plugin-capability-summary-has-skills
      (CodexPluginCapabilitySummary
        $config-name
        $display-name
        $description
        $has-skills
        $mcp-server-names
        $app-connector-ids))
   $has-skills)

(= (codex:plugin-capability-summary-mcp-server-names
      (CodexPluginCapabilitySummary
        $config-name
        $display-name
        $description
        $has-skills
        $mcp-server-names
        $app-connector-ids))
   $mcp-server-names)

(= (codex:plugin-capability-summary-app-connector-ids
      (CodexPluginCapabilitySummary
        $config-name
        $display-name
        $description
        $has-skills
        $mcp-server-names
        $app-connector-ids))
   $app-connector-ids)

(= (codex:available-plugins-instructions-role)
   "developer")

(= (codex:available-plugins-instructions-start-marker)
   "<plugins_instructions>")

(= (codex:available-plugins-instructions-end-marker)
   "</plugins_instructions>")

(= (codex:available-plugins-instructions-guidance)
   "- Discovery: The list above is the plugins available in this session.\n- Skill naming: If a plugin contributes skills, those skill entries are prefixed with `plugin_name:` in the Skills list.\n- Trigger rules: If the user explicitly names a plugin, prefer capabilities associated with that plugin for that turn.\n- Relationship to capabilities: Plugins are not invoked directly. Use their underlying skills, MCP tools, and app tools to help solve the task.\n- Preference: When a relevant plugin is available, prefer using capabilities associated with that plugin over standalone capabilities that provide similar functionality.\n- Missing/blocked: If the user requests a plugin that is not listed above, or the plugin does not have relevant callable capabilities for the task, say so briefly and continue with the best fallback.")

(= (codex:available-plugins-summary-line $plugin)
   (let $display-name (codex:plugin-capability-summary-display-name $plugin)
     (let $description (codex:plugin-capability-summary-description $plugin)
       (if (== $description CodexAbsent)
           (format-args "- `{}`" ($display-name))
           (format-args "- `{}`: {}" ($display-name $description))))))

(= (codex:available-plugins-summary-lines $plugins)
   (map-atom
     $plugins
     $plugin
     (codex:available-plugins-summary-line $plugin)))

(= (codex:available-plugins-instructions $plugins)
   (codex:contextual-fragment
     (codex:available-plugins-instructions-role)
     (codex:available-plugins-instructions-start-marker)
     (codex:available-plugins-instructions-end-marker)
     (format-args
       "\n## Plugins\nA plugin is a local bundle of skills, MCP servers, and apps. Below is the list of plugins that are enabled and available in this session.\n### Available plugins\n{}\n### How to use plugins\n{}\n"
       ((str-join "\n" (codex:available-plugins-summary-lines $plugins))
        (codex:available-plugins-instructions-guidance)))))

(= (codex:available-plugins-instructions-from-plugins $plugins)
   (if (== $plugins ())
       Empty
       (codex:available-plugins-instructions $plugins)))

(= (codex:available-plugins-instructions-matches-text $text)
   (case
     (codex:contextual-fragment-matches-markers
       (codex:available-plugins-instructions-start-marker)
       (codex:available-plugins-instructions-end-marker)
       $text)
     ((True True)
      (False False))))

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
   (let $resolved-content-item (once $content-item)
     (case $resolved-content-item
     (((CodexInputText $text)
       (let $fragment (codex:parse-hook-prompt-fragment $text)
         (if (== $fragment Empty)
             (codex:is-standard-contextual-user-text $text)
             True)))
      ($other False)))))

(= (codex:is-memory-excluded-contextual-user-fragment $content-item)
   (let $resolved-content-item (once $content-item)
     (case $resolved-content-item
     (((CodexInputText $text)
       (codex:is-memory-excluded-standard-contextual-user-text $text))
      ($other False)))))
