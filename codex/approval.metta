; Visible approval-decision slice for the restarted Codex port.
;
; This ports the narrow, user-runnable approval core from
; openai-codex/codex-rs/core/src/{exec_policy.rs,tools/sandboxing.rs}:
; - `ExecApprovalRequirement` result shapes
; - explicit prefix-rule allow/prompt/forbidden handling
; - default unmatched-command fallback for the currently restarted command set
; - prompt and forbidden reason rendering from the most specific matched rule
;
; Deliberate restart-slice limits:
; - dangerous-command escalation is deferred until the command-safety slice
; - proposed execpolicy amendments stay `null` until the amendment slice lands
; - the heredoc/single-prefix complex shell parser is not present yet, so this
;   slice only expands `bash|sh|zsh -c|-lc` wrappers through `shell-plain-commands`
; - user-facing reason strings currently use simple token-joining instead of
;   Rust's full shlex rendering

!(import! &self command)
!(import! &self exec_policy)
!(import! &self json)
!(import! &self list)
!(import! &self shell)
!(import! &self str)

(= (codex:ask-for-approval-never)
   "never")

(= (codex:ask-for-approval-on-failure)
   "on_failure")

(= (codex:ask-for-approval-on-request)
   "on_request")

(= (codex:ask-for-approval-unless-trusted)
   "unless_trusted")

(= (codex:ask-for-approval-granular $sandbox-approval)
   (CodexAskForApprovalGranular $sandbox-approval))

(= (codex:ask-for-approval-granular-config
      $sandbox-approval
      $rules
      $skill-approval
      $request-permissions
      $mcp-elicitations)
   (CodexAskForApprovalGranularConfig
     $sandbox-approval
     $rules
     $skill-approval
     $request-permissions
     $mcp-elicitations))

(= (codex:file-system-sandbox-restricted)
   "restricted")

(= (codex:file-system-sandbox-unrestricted)
   "unrestricted")

(= (codex:approval-skip $bypass_sandbox)
   (CodexExecApprovalRequirementSkip $bypass_sandbox CodexAbsent))

(= (codex:approval-needs-approval $reason)
   (CodexExecApprovalRequirementNeedsApproval $reason CodexAbsent))

(= (codex:approval-forbidden $reason)
   (CodexExecApprovalRequirementForbidden $reason))

(= (codex:approval-requirement-type
      (CodexExecApprovalRequirementSkip $bypass_sandbox $amendment))
   "skip")

(= (codex:approval-requirement-type
      (CodexExecApprovalRequirementNeedsApproval $reason $amendment))
   "needs_approval")

(= (codex:approval-requirement-type
      (CodexExecApprovalRequirementForbidden $reason))
   "forbidden")

(= (codex:approval-optional-string-json $value)
   (if (== $value CodexAbsent)
       JsonNull
       (JsonString $value)))

(= (codex:approval-amendment-json $amendment)
   JsonNull)

(= (codex:approval-requirement-json
      (CodexExecApprovalRequirementSkip $bypass_sandbox $amendment))
   (JsonObject
     ((JsonPair "type" (JsonString "skip"))
      (JsonPair "bypass_sandbox" (JsonBool $bypass_sandbox))
      (JsonPair "proposed_execpolicy_amendment"
        (codex:approval-amendment-json $amendment)))))

(= (codex:approval-requirement-json
      (CodexExecApprovalRequirementNeedsApproval $reason $amendment))
   (JsonObject
     ((JsonPair "type" (JsonString "needs_approval"))
      (JsonPair "reason" (codex:approval-optional-string-json $reason))
      (JsonPair "proposed_execpolicy_amendment"
        (codex:approval-amendment-json $amendment)))))

(= (codex:approval-requirement-json
      (CodexExecApprovalRequirementForbidden $reason))
   (JsonObject
     ((JsonPair "type" (JsonString "forbidden"))
      (JsonPair "reason" (JsonString $reason)))))

(= (codex:is-safe-parsed-command-type? $type)
   (if (== $type "read")
       True
       (if (== $type "list_files")
           True
           (if (== $type "search")
               True
               False))))

(= (codex:all-safe-parsed-commands? ())
   True)

(= (codex:all-safe-parsed-commands? $items)
   (let ($head $tail) (decons-atom $items)
     (if (codex:is-safe-parsed-command-type? (codex:parsed-command-type $head))
         (codex:all-safe-parsed-commands? $tail)
         False)))

(= (codex:is-known-safe-command? $tokens)
   (let $parsed (codex:parse-command $tokens)
     (if (== $parsed ())
         False
         (codex:all-safe-parsed-commands? $parsed))))

(= (codex:commands-for-exec-policy $tokens)
   (if (== (list:len $tokens) 3)
       (let $shell (list:at $tokens 0)
         (let $flag (list:at $tokens 1)
           (let $script (list:at $tokens 2)
             (if (codex:is-shell-wrapper-parts? $shell $flag)
                 (case (shell-plain-commands
                         (codex:rebuild-shell-wrapper $shell $flag $script))
                   ((Empty (CodexExecPolicyCommands ($tokens) False))
                    ($commands
                     (if (== $commands ())
                         (CodexExecPolicyCommands ($tokens) False)
                         (CodexExecPolicyCommands $commands False)))))
                 (CodexExecPolicyCommands ($tokens) False)))))
       (CodexExecPolicyCommands ($tokens) False)))

(= (codex:exec-policy-command-list
      (CodexExecPolicyCommands $commands $used_complex_parsing))
   $commands)

(= (codex:exec-policy-used-complex-parsing
      (CodexExecPolicyCommands $commands $used_complex_parsing))
   $used_complex_parsing)

(= (codex:render-decision-for-unmatched-command
      $approval_policy
      $file_system_sandbox_kind
      $command
      $used_complex_parsing)
   (if (codex:is-known-safe-command? $command)
       (if $used_complex_parsing
           (codex:render-decision-for-unmatched-unsafe
             $approval_policy
             $file_system_sandbox_kind)
           (codex:decision-allow))
       (codex:render-decision-for-unmatched-unsafe
         $approval_policy
         $file_system_sandbox_kind)))

(= (codex:render-decision-for-unmatched-unsafe
      $approval_policy
      $file_system_sandbox_kind)
   (if (== $approval_policy (codex:ask-for-approval-never))
       (codex:decision-allow)
       (if (== $approval_policy (codex:ask-for-approval-on-failure))
           (codex:decision-allow)
           (if (== $approval_policy (codex:ask-for-approval-unless-trusted))
               (codex:decision-prompt)
               (if (== $approval_policy (codex:ask-for-approval-on-request))
                   (if (== $file_system_sandbox_kind
                            (codex:file-system-sandbox-unrestricted))
                       (codex:decision-allow)
                       (codex:decision-allow))
                   (codex:decision-allow))))))

(= (codex:rule-match-prefix
      (CodexExecPolicyPrefixRuleMatch $matched_prefix $decision $justification))
   $matched_prefix)

(= (codex:approval-rule-match-decision
      (CodexExecPolicyPrefixRuleMatch $matched_prefix $decision $justification))
   $decision)

(= (codex:rule-match-justification
      (CodexExecPolicyPrefixRuleMatch $matched_prefix $decision $justification))
   $justification)

(= (codex:is-policy-match-for-decision? $rule_match $decision)
   (== (codex:approval-rule-match-decision $rule_match) $decision))

(= (codex:best-rule-for-decision $matched_rules $decision)
   (codex:best-rule-for-decision-acc $matched_rules $decision CodexAbsent))

(= (codex:best-rule-for-decision-acc () $decision $best)
   $best)

(= (codex:best-rule-for-decision-acc $matched_rules $decision $best)
   (let ($head $tail) (decons-atom $matched_rules)
     (if (codex:is-policy-match-for-decision? $head $decision)
         (let $next-best (codex:pick-more-specific-rule-match $best $head)
           (codex:best-rule-for-decision-acc $tail $decision $next-best))
         (codex:best-rule-for-decision-acc $tail $decision $best))))

(= (codex:pick-more-specific-rule-match CodexAbsent $candidate)
   $candidate)

(= (codex:pick-more-specific-rule-match
      (CodexExecPolicyPrefixRuleMatch $best_prefix $best_decision $best_justification)
      (CodexExecPolicyPrefixRuleMatch $candidate_prefix $candidate_decision $candidate_justification))
   (if (> (list:len $candidate_prefix) (list:len $best_prefix))
       (CodexExecPolicyPrefixRuleMatch
         $candidate_prefix
         $candidate_decision
         $candidate_justification)
       (CodexExecPolicyPrefixRuleMatch
         $best_prefix
         $best_decision
         $best_justification)))

(= (codex:quoted-command-text $tokens)
   (str-concat "`" (str-concat (codex:join-command $tokens) "`")))

(= (codex:derive-prompt-reason $command $matched_rules)
   (case (codex:best-rule-for-decision $matched_rules (codex:decision-prompt))
     ((CodexAbsent Empty)
      ((CodexExecPolicyPrefixRuleMatch $matched_prefix $decision CodexAbsent)
       (str-concat
         (codex:quoted-command-text $command)
         " requires approval by policy"))
      ((CodexExecPolicyPrefixRuleMatch $matched_prefix $decision $justification)
       (str-concat
         (codex:quoted-command-text $command)
         (str-concat " requires approval: " $justification))))))

(= (codex:derive-forbidden-reason $command $matched_rules)
   (case (codex:best-rule-for-decision $matched_rules (codex:decision-forbidden))
     ((CodexAbsent
       (str-concat
         (codex:quoted-command-text $command)
         " rejected: blocked by policy"))
      ((CodexExecPolicyPrefixRuleMatch $matched_prefix $decision CodexAbsent)
       (str-concat
         (codex:quoted-command-text $command)
         (str-concat
           " rejected: policy forbids commands starting with "
           (codex:quoted-command-text $matched_prefix))))
      ((CodexExecPolicyPrefixRuleMatch $matched_prefix $decision $justification)
       (str-concat
         (codex:quoted-command-text $command)
         (str-concat " rejected: " $justification))))))

(= (codex:all-commands-explicitly-allowed? $policy ())
   True)

(= (codex:all-commands-explicitly-allowed? $policy $commands)
   (let ($head $tail) (decons-atom $commands)
     (let $matches (codex:matches-for-command $policy $head)
       (if (codex:any-allow-rule-match? $matches)
           (codex:all-commands-explicitly-allowed? $policy $tail)
           False))))

(= (codex:any-allow-rule-match? ())
   False)

(= (codex:any-allow-rule-match? $matches)
   (let ($head $tail) (decons-atom $matches)
     (if (codex:is-policy-match-for-decision? $head (codex:decision-allow))
         True
         (codex:any-allow-rule-match? $tail))))

(= (codex:decision-for-command
      $policy
      $approval_policy
      $file_system_sandbox_kind
      $command
      $used_complex_parsing)
   (let $matches (codex:matches-for-command $policy $command)
     (let $decision (codex:decision-from-matched-rules $matches)
       (if (== $decision CodexAbsent)
           (codex:render-decision-for-unmatched-command
             $approval_policy
             $file_system_sandbox_kind
             $command
             $used_complex_parsing)
           $decision))))

(= (codex:decision-for-commands
      $policy
      $approval_policy
      $file_system_sandbox_kind
      ()
      $used_complex_parsing)
   CodexAbsent)

(= (codex:decision-for-commands
      $policy
      $approval_policy
      $file_system_sandbox_kind
      $commands
      $used_complex_parsing)
   (let ($head $tail) (decons-atom $commands)
     (let $head_decision
       (codex:decision-for-command
         $policy
         $approval_policy
         $file_system_sandbox_kind
         $head
         $used_complex_parsing)
       (if (== $tail ())
           $head_decision
           (codex:max-decision
             $head_decision
             (codex:decision-for-commands
               $policy
               $approval_policy
               $file_system_sandbox_kind
               $tail
               $used_complex_parsing))))))

(= (codex:approval-evaluation
      $policy
      $approval_policy
      $file_system_sandbox_kind
      $commands
      $used_complex_parsing)
   (CodexExecPolicyCheckOutput
     (codex:matches-for-commands $policy $commands)
     (codex:decision-for-commands
       $policy
       $approval_policy
       $file_system_sandbox_kind
       $commands
       $used_complex_parsing)))

(= (codex:approval-for-command
      $approval_policy
      $file_system_sandbox_kind
      $policy
      $command)
   (let $policy_commands (codex:commands-for-exec-policy $command)
     (let $commands (codex:exec-policy-command-list $policy_commands)
       (let $used_complex_parsing
         (codex:exec-policy-used-complex-parsing $policy_commands)
         (let $evaluation
           (codex:approval-evaluation
             $policy
             $approval_policy
             $file_system_sandbox_kind
             $commands
             $used_complex_parsing)
           (codex:approval-from-evaluation
             $approval_policy
             $policy
             $commands
             $command
             $evaluation))))))

(= (codex:approval-from-evaluation
      $approval_policy
      $policy
      $commands
      $command
      $evaluation)
   (let $decision (codex:check-output-decision $evaluation)
     (if (== $decision (codex:decision-forbidden))
         (codex:approval-forbidden
           (codex:derive-forbidden-reason
             $command
             (codex:check-output-matched-rules $evaluation)))
         (if (== $decision (codex:decision-prompt))
             (if (== $approval_policy (codex:ask-for-approval-never))
                 (codex:approval-forbidden
                   "approval required by policy, but AskForApproval is set to Never")
                 (codex:approval-needs-approval
                   (codex:derive-prompt-reason
                     $command
                     (codex:check-output-matched-rules $evaluation))))
             (codex:approval-skip
               (codex:all-commands-explicitly-allowed? $policy $commands))))))
