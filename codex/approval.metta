; Visible approval-decision slice for the restarted Codex port.
;
; This ports the narrow, user-runnable approval core from
; openai-codex/codex-rs/core/src/{exec_policy.rs,tools/sandboxing.rs}:
; - `ExecApprovalRequirement` result shapes
; - explicit prefix-rule allow/prompt/forbidden handling
; - default unmatched-command fallback for the currently restarted command set
; - dangerous-command escalation from Rust command safety for the visible
;   Unix command subset
; - prompt and forbidden reason rendering from the most specific matched rule
; - approval-side proposed execpolicy amendments derived from matched rules
;
; Deliberate restart-slice limits:
; - the heredoc/single-prefix complex shell parser is conservative compared to
;   Rust's tree-sitter-backed parser and rejects ambiguous shell forms
; - user-facing reason strings currently use simple token-joining instead of
;   Rust's full shlex rendering
; - Rust has a Windows-only ReadOnly-sandbox no-protection branch in
;   `render_decision_for_unmatched_command`; this Unix CeTTa runtime slice does
;   not claim Windows command execution yet.

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

(= (codex:file-system-sandbox-external-sandbox)
   "external-sandbox")

(= (codex:approval-sandbox-policy-danger-full-access)
   (CodexApprovalSandboxPolicyDangerFullAccess))

(= (codex:approval-sandbox-policy-read-only)
   (CodexApprovalSandboxPolicyReadOnly))

(= (codex:approval-sandbox-policy-external-sandbox)
   (CodexApprovalSandboxPolicyExternalSandbox))

(= (codex:approval-sandbox-policy-workspace-write)
   (CodexApprovalSandboxPolicyWorkspaceWrite))

(= (codex:approval-sandbox-policy-from-file-system-kind $file_system_sandbox_kind)
   (if (== $file_system_sandbox_kind
            (codex:file-system-sandbox-unrestricted))
       (codex:approval-sandbox-policy-danger-full-access)
       (if (== $file_system_sandbox_kind
                (codex:file-system-sandbox-external-sandbox))
           (codex:approval-sandbox-policy-external-sandbox)
           (codex:approval-sandbox-policy-read-only))))

(= (codex:is-approval-sandbox-policy-explicitly-disabled $sandbox_policy)
   (case $sandbox_policy
     (((CodexApprovalSandboxPolicyDangerFullAccess) True)
      ((CodexApprovalSandboxPolicyExternalSandbox) True)
      ($other False))))

(= (codex:approval-sandbox-permissions-use-default)
   "use_default")

(= (codex:approval-sandbox-permissions-with-additional-permissions)
   "with_additional_permissions")

(= (codex:approval-sandbox-permissions-require-escalated)
   "require_escalated")

(= (codex:is-approval-sandbox-permissions-override $sandbox_permissions)
   (not (== $sandbox_permissions
            (codex:approval-sandbox-permissions-use-default))))

(= (codex:is-file-system-sandbox-kind-unrestricted-or-external
      $file_system_sandbox_kind)
   (if (== $file_system_sandbox_kind
            (codex:file-system-sandbox-unrestricted))
       True
       (== $file_system_sandbox_kind
           (codex:file-system-sandbox-external-sandbox))))

(= (codex:prompt-conflict-reason)
   "approval required by policy, but AskForApproval is set to Never")

(= (codex:reject-sandbox-approval-reason)
   "approval required by policy, but AskForApproval::Granular.sandbox_approval is false")

(= (codex:reject-rules-approval-reason)
   "approval required by policy rule, but AskForApproval::Granular.rules is false")

(= (codex:approval-skip $bypass_sandbox)
   (codex:approval-skip $bypass_sandbox CodexAbsent))

(= (codex:approval-skip $bypass_sandbox $amendment)
   (CodexExecApprovalRequirementSkip $bypass_sandbox $amendment))

(= (codex:approval-needs-approval $reason)
   (codex:approval-needs-approval $reason CodexAbsent))

(= (codex:approval-needs-approval $reason $amendment)
   (CodexExecApprovalRequirementNeedsApproval $reason $amendment))

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

(= (codex:approval-amendment-json CodexAbsent)
   JsonNull)

(= (codex:approval-amendment-json
      (CodexExecPolicyAmendment $command))
   (codex:string-list-json $command))

(= (codex:approval-requirement-json $requirement)
   (case $requirement
     (((CodexExecApprovalRequirementSkip $bypass_sandbox $amendment)
       (JsonObject
         ((JsonPair "type" (JsonString "skip"))
          (JsonPair "bypass_sandbox" (JsonBool $bypass_sandbox))
          (JsonPair "proposed_execpolicy_amendment"
            (codex:approval-amendment-json (once (eval $amendment)))))))
      ((CodexExecApprovalRequirementNeedsApproval $reason $amendment)
       (JsonObject
         ((JsonPair "type" (JsonString "needs_approval"))
          (JsonPair "reason"
            (codex:approval-optional-string-json (once (eval $reason))))
          (JsonPair "proposed_execpolicy_amendment"
            (codex:approval-amendment-json (once (eval $amendment)))))))
      ((CodexExecApprovalRequirementForbidden $reason)
       (JsonObject
         ((JsonPair "type" (JsonString "forbidden"))
          (JsonPair "reason" (JsonString $reason))))))))

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
   (let $parsed (once (eval (codex:parse-command $tokens)))
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
                   ((Empty
                     (case
                       (shell-single-command-prefix $shell $flag $script)
                       ((Empty (CodexExecPolicyCommands ($tokens) False))
                        ($single-command
                         (CodexExecPolicyCommands
                           ($single-command)
                           True)))))
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
   (codex:render-decision-for-unmatched-command-with-sandbox
     $approval_policy
     (codex:approval-sandbox-policy-from-file-system-kind
       $file_system_sandbox_kind)
     $file_system_sandbox_kind
     (codex:approval-sandbox-permissions-use-default)
     $command
     $used_complex_parsing))

(= (codex:render-decision-for-unmatched-command-with-sandbox
      $approval_policy
      $sandbox_policy
      $file_system_sandbox_kind
      $sandbox_permissions
      $command
      $used_complex_parsing)
   (if (codex:is-known-safe-command? $command)
       (if $used_complex_parsing
           (codex:render-decision-for-unmatched-nonsafe
             $approval_policy
             $sandbox_policy
             $file_system_sandbox_kind
             $sandbox_permissions
             $command)
           (codex:decision-allow))
       (codex:render-decision-for-unmatched-nonsafe
         $approval_policy
         $sandbox_policy
         $file_system_sandbox_kind
         $sandbox_permissions
         $command)))

(= (codex:render-decision-for-unmatched-nonsafe
      $approval_policy
      $sandbox_policy
      $file_system_sandbox_kind
      $sandbox_permissions
      $command)
   (if (codex:is-command-dangerous $command)
       (codex:render-decision-for-dangerous-command
         $approval_policy
         $sandbox_policy)
       (codex:render-decision-for-unmatched-unsafe
         $approval_policy
         $file_system_sandbox_kind
         $sandbox_permissions)))

(= (codex:render-decision-for-dangerous-command
      $approval_policy
      $sandbox_policy)
   (if (== $approval_policy (codex:ask-for-approval-never))
       (if (codex:is-approval-sandbox-policy-explicitly-disabled
             $sandbox_policy)
           (codex:decision-allow)
           (codex:decision-forbidden))
       (codex:decision-prompt)))

(= (codex:render-decision-for-unmatched-unsafe
      $approval_policy
      $file_system_sandbox_kind
      $sandbox_permissions)
   (if (== $approval_policy (codex:ask-for-approval-never))
       (codex:decision-allow)
       (if (== $approval_policy (codex:ask-for-approval-on-failure))
           (codex:decision-allow)
           (if (== $approval_policy (codex:ask-for-approval-unless-trusted))
               (codex:decision-prompt)
               (if (== $approval_policy (codex:ask-for-approval-on-request))
                   (if (codex:is-file-system-sandbox-kind-unrestricted-or-external
                         $file_system_sandbox_kind)
                       (codex:decision-allow)
                       (if (codex:is-approval-sandbox-permissions-override
                             $sandbox_permissions)
                           (codex:decision-prompt)
                           (codex:decision-allow)))
                   (if (codex:is-file-system-sandbox-kind-unrestricted-or-external
                         $file_system_sandbox_kind)
                       (codex:decision-allow)
                       (if (codex:is-approval-sandbox-permissions-override
                             $sandbox_permissions)
                           (codex:decision-prompt)
                           (codex:decision-allow))))))))

(= (codex:approval-heuristics-fallback
      $approval_policy
      $file_system_sandbox_kind
      $used_complex_parsing)
   (codex:approval-heuristics-fallback-with-sandbox
     $approval_policy
     (codex:approval-sandbox-policy-from-file-system-kind
       $file_system_sandbox_kind)
     $file_system_sandbox_kind
     (codex:approval-sandbox-permissions-use-default)
     $used_complex_parsing))

(= (codex:approval-heuristics-fallback-with-sandbox
      $approval_policy
      $sandbox_policy
      $file_system_sandbox_kind
      $sandbox_permissions
      $used_complex_parsing)
   (CodexApprovalHeuristicsFallback
     $approval_policy
     $sandbox_policy
     $file_system_sandbox_kind
     $sandbox_permissions
     $used_complex_parsing))

(= (codex:heuristics-fallback-decision-for-command
      (CodexApprovalHeuristicsFallback
        $approval_policy
        $sandbox_policy
        $file_system_sandbox_kind
        $sandbox_permissions
        $used_complex_parsing)
      $command)
   (codex:render-decision-for-unmatched-command-with-sandbox
     $approval_policy
     $sandbox_policy
     $file_system_sandbox_kind
     $sandbox_permissions
     $command
     $used_complex_parsing))

(= (codex:rule-match-prefix
      (CodexExecPolicyPrefixRuleMatch $matched_prefix $decision $justification))
   $matched_prefix)

(= (codex:rule-match-prefix
      (CodexExecPolicyPrefixRuleMatchResolved
        $matched_prefix
        $decision
        $resolved_program
        $justification))
   $matched_prefix)

(= (codex:approval-rule-match-decision
      (CodexExecPolicyPrefixRuleMatch $matched_prefix $decision $justification))
   $decision)

(= (codex:approval-rule-match-decision
      (CodexExecPolicyPrefixRuleMatchResolved
        $matched_prefix
        $decision
        $resolved_program
        $justification))
   $decision)

(= (codex:approval-rule-match-decision
      (CodexExecPolicyHeuristicsRuleMatch $command $decision))
   $decision)

(= (codex:rule-match-justification
      (CodexExecPolicyPrefixRuleMatch $matched_prefix $decision $justification))
   $justification)

(= (codex:rule-match-justification
      (CodexExecPolicyPrefixRuleMatchResolved
        $matched_prefix
        $decision
        $resolved_program
        $justification))
   $justification)

(= (codex:is-policy-rule-match?
      (CodexExecPolicyPrefixRuleMatch $matched_prefix $decision $justification))
   True)

(= (codex:is-policy-rule-match?
      (CodexExecPolicyPrefixRuleMatchResolved
        $matched_prefix
        $decision
        $resolved_program
        $justification))
   True)

(= (codex:is-policy-rule-match?
      (CodexExecPolicyHeuristicsRuleMatch $command $decision))
   False)

(= (codex:is-policy-match-for-decision? $rule_match $decision)
   (if (codex:is-policy-rule-match? $rule_match)
       (== (codex:approval-rule-match-decision $rule_match) $decision)
       False))

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
      (CodexExecPolicyPrefixRuleMatch
        $candidate_prefix
        $candidate_decision
        $candidate_justification))
   (if (> (list:len $candidate_prefix) (list:len $best_prefix))
       (CodexExecPolicyPrefixRuleMatch
         $candidate_prefix
         $candidate_decision
         $candidate_justification)
       (CodexExecPolicyPrefixRuleMatch
         $best_prefix
         $best_decision
         $best_justification)))

(= (codex:pick-more-specific-rule-match
      (CodexExecPolicyPrefixRuleMatch $best_prefix $best_decision $best_justification)
      (CodexExecPolicyPrefixRuleMatchResolved
        $candidate_prefix
        $candidate_decision
        $candidate_resolved_program
        $candidate_justification))
   (if (> (list:len $candidate_prefix) (list:len $best_prefix))
       (CodexExecPolicyPrefixRuleMatchResolved
         $candidate_prefix
         $candidate_decision
         $candidate_resolved_program
         $candidate_justification)
       (CodexExecPolicyPrefixRuleMatch
         $best_prefix
         $best_decision
         $best_justification)))

(= (codex:pick-more-specific-rule-match
      (CodexExecPolicyPrefixRuleMatchResolved
        $best_prefix
        $best_decision
        $best_resolved_program
        $best_justification)
      (CodexExecPolicyPrefixRuleMatch
        $candidate_prefix
        $candidate_decision
        $candidate_justification))
   (if (> (list:len $candidate_prefix) (list:len $best_prefix))
       (CodexExecPolicyPrefixRuleMatch
         $candidate_prefix
         $candidate_decision
         $candidate_justification)
       (CodexExecPolicyPrefixRuleMatchResolved
         $best_prefix
         $best_decision
         $best_resolved_program
         $best_justification)))

(= (codex:pick-more-specific-rule-match
      (CodexExecPolicyPrefixRuleMatchResolved
        $best_prefix
        $best_decision
        $best_resolved_program
        $best_justification)
      (CodexExecPolicyPrefixRuleMatchResolved
        $candidate_prefix
        $candidate_decision
        $candidate_resolved_program
        $candidate_justification))
   (if (> (list:len $candidate_prefix) (list:len $best_prefix))
       (CodexExecPolicyPrefixRuleMatchResolved
         $candidate_prefix
         $candidate_decision
         $candidate_resolved_program
         $candidate_justification)
       (CodexExecPolicyPrefixRuleMatchResolved
         $best_prefix
         $best_decision
         $best_resolved_program
         $best_justification)))

(= (codex:quoted-command-text $tokens)
   (str-concat "`" (str-concat (codex:join-command $tokens) "`")))

(= (codex:derive-prompt-reason $command $matched_rules)
   (case (codex:best-rule-for-decision $matched_rules (codex:decision-prompt))
     ((CodexAbsent CodexAbsent)
      ((CodexExecPolicyPrefixRuleMatch $matched_prefix $decision CodexAbsent)
       (str-concat
         (codex:quoted-command-text $command)
         " requires approval by policy"))
      ((CodexExecPolicyPrefixRuleMatch $matched_prefix $decision $justification)
       (str-concat
         (codex:quoted-command-text $command)
         (str-concat " requires approval: " $justification)))
      ((CodexExecPolicyPrefixRuleMatchResolved
         $matched_prefix
         $decision
         $resolved_program
         CodexAbsent)
       (str-concat
         (codex:quoted-command-text $command)
         " requires approval by policy"))
      ((CodexExecPolicyPrefixRuleMatchResolved
         $matched_prefix
         $decision
         $resolved_program
         $justification)
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
         (str-concat " rejected: " $justification)))
      ((CodexExecPolicyPrefixRuleMatchResolved
         $matched_prefix
         $decision
         $resolved_program
         CodexAbsent)
       (str-concat
         (codex:quoted-command-text $command)
         (str-concat
           " rejected: policy forbids commands starting with "
           (codex:quoted-command-text $matched_prefix))))
      ((CodexExecPolicyPrefixRuleMatchResolved
         $matched_prefix
         $decision
         $resolved_program
         $justification)
       (str-concat
         (codex:quoted-command-text $command)
         (str-concat " rejected: " $justification))))))

(= (codex:all-commands-explicitly-allowed? $policy ())
   True)

(= (codex:all-commands-explicitly-allowed? $policy $commands)
   (let ($head $tail) (decons-atom $commands)
     (let $matches
       (codex:matches-for-command-with-options
         $policy
         $head
         (codex:match-options True))
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

(= (codex:any-policy-rule-match? ())
   False)

(= (codex:any-policy-rule-match? $matches)
   (let ($head $tail) (decons-atom $matches)
     (if (codex:is-policy-rule-match? $head)
         True
         (codex:any-policy-rule-match? $tail))))

(= (codex:any-policy-rule-match-for-decision? () $decision)
   False)

(= (codex:any-policy-rule-match-for-decision? $matches $decision)
   (let ($head $tail) (decons-atom $matches)
     (if (codex:is-policy-match-for-decision? $head $decision)
         True
         (codex:any-policy-rule-match-for-decision? $tail $decision))))

(= (codex:approval-policy-prompt-rejection-reason
      $approval_policy
      $prompt_is_rule)
   (if (== $approval_policy (codex:ask-for-approval-never))
       (codex:prompt-conflict-reason)
       (case $approval_policy
         (((CodexAskForApprovalGranular False)
           (if $prompt_is_rule
               CodexAbsent
               (codex:reject-sandbox-approval-reason)))
          ((CodexAskForApprovalGranular True)
           CodexAbsent)
          ((CodexAskForApprovalGranularConfig
             $sandbox-approval
             $rules
             $skill-approval
             $request-permissions
             $mcp-elicitations)
           (if $prompt_is_rule
               (if $rules
                   CodexAbsent
                   (codex:reject-rules-approval-reason))
               (if $sandbox-approval
                   CodexAbsent
                   (codex:reject-sandbox-approval-reason))))
          ($other CodexAbsent)))))

(= (codex:first-heuristics-command-for-decision () $decision)
   CodexAbsent)

(= (codex:first-heuristics-command-for-decision $matches $decision)
   (let ($head $tail) (decons-atom $matches)
     (case $head
       (((CodexExecPolicyHeuristicsRuleMatch $command $match_decision)
         (if (== $match_decision $decision)
             $command
             (codex:first-heuristics-command-for-decision $tail $decision)))
        ($other
         (codex:first-heuristics-command-for-decision $tail $decision))))))

(= (codex:execpolicy-amendment-from-command-or-absent $command)
   (if (== $command CodexAbsent)
       CodexAbsent
       (CodexExecPolicyAmendment $command)))

(= (codex:try-derive-execpolicy-amendment-for-prompt-rules $matched_rules)
   (if (codex:any-policy-rule-match-for-decision?
         $matched_rules
         (codex:decision-prompt))
       CodexAbsent
       (let $command
         (once
           (eval
             (codex:first-heuristics-command-for-decision
               $matched_rules
               (codex:decision-prompt))))
         (codex:execpolicy-amendment-from-command-or-absent $command))))

(= (codex:try-derive-execpolicy-amendment-for-allow-rules $matched_rules)
   (if (codex:any-policy-rule-match? $matched_rules)
       CodexAbsent
       (let $command
         (once
           (eval
             (codex:first-heuristics-command-for-decision
               $matched_rules
               (codex:decision-allow))))
         (codex:execpolicy-amendment-from-command-or-absent $command))))

(= (codex:approval-auto-amendment
      $used_complex_parsing
      $matched_rules
      $decision)
   (if $used_complex_parsing
       CodexAbsent
       (if (== $decision (codex:decision-prompt))
           (codex:try-derive-execpolicy-amendment-for-prompt-rules
             $matched_rules)
           (if (== $decision (codex:decision-allow))
               (codex:try-derive-execpolicy-amendment-for-allow-rules
                 $matched_rules)
               CodexAbsent))))

(= (codex:prefer-requested-amendment $requested_amendment $auto_amendment)
   (if (== $requested_amendment CodexAbsent)
       $auto_amendment
       $requested_amendment))

(= (codex:banned-prefix-suggestions)
   (("python3")
    ("python3" "-")
    ("python3" "-c")
    ("python")
    ("python" "-")
    ("python" "-c")
    ("py")
    ("py" "-3")
    ("pythonw")
    ("pyw")
    ("pypy")
    ("pypy3")
    ("git")
    ("bash")
    ("bash" "-lc")
    ("sh")
    ("sh" "-c")
    ("sh" "-lc")
    ("zsh")
    ("zsh" "-lc")
    ("/bin/zsh")
    ("/bin/zsh" "-lc")
    ("/bin/bash")
    ("/bin/bash" "-lc")
    ("pwsh")
    ("pwsh" "-Command")
    ("pwsh" "-c")
    ("powershell")
    ("powershell" "-Command")
    ("powershell" "-c")
    ("powershell.exe")
    ("powershell.exe" "-Command")
    ("powershell.exe" "-c")
    ("env")
    ("sudo")
    ("node")
    ("node" "-e")
    ("perl")
    ("perl" "-e")
    ("ruby")
    ("ruby" "-e")
    ("php")
    ("php" "-r")
    ("lua")
    ("lua" "-e")
    ("osascript")))

(= (codex:prefix-in-list? $prefix ())
   False)

(= (codex:prefix-in-list? $prefix $prefixes)
   (let ($head $tail) (decons-atom $prefixes)
     (if (== $prefix $head)
         True
         (codex:prefix-in-list? $prefix $tail))))

(= (codex:banned-prefix-suggestion? $prefix)
   (codex:prefix-in-list? $prefix (codex:banned-prefix-suggestions)))

(= (codex:prefix-rule-would-approve-all-commands?
      $policy
      $prefix_rule
      $approval_policy
      $file_system_sandbox_kind
      $commands
      $used_complex_parsing)
   (codex:prefix-rule-would-approve-all-commands-with-sandbox?
     $policy
     $prefix_rule
     $approval_policy
     (codex:approval-sandbox-policy-from-file-system-kind
       $file_system_sandbox_kind)
     $file_system_sandbox_kind
     (codex:approval-sandbox-permissions-use-default)
     $commands
     $used_complex_parsing))

(= (codex:prefix-rule-would-approve-all-commands-with-sandbox?
      $policy
      $prefix_rule
      $approval_policy
      $sandbox_policy
      $file_system_sandbox_kind
      $sandbox_permissions
      $commands
      $used_complex_parsing)
   (let $amended_policy
     (codex:policy-add-prefix-rule
       $policy
       $prefix_rule
       (codex:decision-allow))
     (let $evaluation
       (codex:approval-evaluation-with-sandbox
         $amended_policy
         $approval_policy
         $sandbox_policy
         $file_system_sandbox_kind
         $sandbox_permissions
         $commands
         $used_complex_parsing)
       (== (codex:check-output-decision $evaluation) (codex:decision-allow)))))

(= (codex:derive-requested-execpolicy-amendment-from-prefix-rule
      $prefix_rule
      $matched_rules
      $policy
      $approval_policy
      $file_system_sandbox_kind
      $commands
      $used_complex_parsing)
   (codex:derive-requested-execpolicy-amendment-from-prefix-rule-with-sandbox
     $prefix_rule
     $matched_rules
     $policy
     $approval_policy
     (codex:approval-sandbox-policy-from-file-system-kind
       $file_system_sandbox_kind)
     $file_system_sandbox_kind
     (codex:approval-sandbox-permissions-use-default)
     $commands
     $used_complex_parsing))

(= (codex:derive-requested-execpolicy-amendment-from-prefix-rule-with-sandbox
      $prefix_rule
      $matched_rules
      $policy
      $approval_policy
      $sandbox_policy
      $file_system_sandbox_kind
      $sandbox_permissions
      $commands
      $used_complex_parsing)
   (if (== $prefix_rule CodexAbsent)
       CodexAbsent
       (if (== $prefix_rule ())
           CodexAbsent
           (if (codex:banned-prefix-suggestion? $prefix_rule)
               CodexAbsent
               (if (codex:any-policy-rule-match? $matched_rules)
                   CodexAbsent
                   (if (codex:prefix-rule-would-approve-all-commands-with-sandbox?
                         $policy
                         $prefix_rule
                         $approval_policy
                         $sandbox_policy
                         $file_system_sandbox_kind
                         $sandbox_permissions
                         $commands
                         $used_complex_parsing)
                       (CodexExecPolicyAmendment $prefix_rule)
                       CodexAbsent))))))

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
   (codex:approval-evaluation-with-sandbox
     $policy
     $approval_policy
     (codex:approval-sandbox-policy-from-file-system-kind
       $file_system_sandbox_kind)
     $file_system_sandbox_kind
     (codex:approval-sandbox-permissions-use-default)
     $commands
     $used_complex_parsing))

(= (codex:approval-evaluation-with-sandbox
      $policy
      $approval_policy
      $sandbox_policy
      $file_system_sandbox_kind
      $sandbox_permissions
      $commands
      $used_complex_parsing)
   (codex:check-policy-multiple-with-options-and-heuristics
     $policy
     $commands
     (codex:approval-heuristics-fallback-with-sandbox
       $approval_policy
       $sandbox_policy
       $file_system_sandbox_kind
       $sandbox_permissions
       $used_complex_parsing)
     (codex:match-options True)))

(= (codex:approval-for-command
      $approval_policy
      $file_system_sandbox_kind
      $policy
      $command)
   (codex:approval-for-command-with-prefix-rule
     $approval_policy
     $file_system_sandbox_kind
     $policy
     $command
     CodexAbsent))

(= (codex:approval-for-command-with-prefix-rule
      $approval_policy
      $file_system_sandbox_kind
      $policy
      $command
      $prefix_rule)
   (codex:approval-for-command-with-sandbox-and-prefix-rule
     $approval_policy
     (codex:approval-sandbox-policy-from-file-system-kind
       $file_system_sandbox_kind)
     $file_system_sandbox_kind
     (codex:approval-sandbox-permissions-use-default)
     $policy
     $command
     $prefix_rule))

(= (codex:approval-for-command-with-sandbox
      $approval_policy
      $sandbox_policy
      $file_system_sandbox_kind
      $sandbox_permissions
      $policy
      $command)
   (codex:approval-for-command-with-sandbox-and-prefix-rule
     $approval_policy
     $sandbox_policy
     $file_system_sandbox_kind
     $sandbox_permissions
     $policy
     $command
     CodexAbsent))

(= (codex:approval-for-command-with-sandbox-and-prefix-rule
      $approval_policy
      $sandbox_policy
      $file_system_sandbox_kind
      $sandbox_permissions
      $policy
      $command
      $prefix_rule)
   (let $policy_commands (codex:commands-for-exec-policy $command)
     (let $commands (codex:exec-policy-command-list $policy_commands)
       (let $used_complex_parsing
         (codex:exec-policy-used-complex-parsing $policy_commands)
         (let $evaluation
           (codex:approval-evaluation-with-sandbox
             $policy
             $approval_policy
             $sandbox_policy
             $file_system_sandbox_kind
             $sandbox_permissions
             $commands
             $used_complex_parsing)
           (let $matched_rules
             (once (eval (codex:check-output-matched-rules $evaluation)))
             (let $requested_amendment
               (once
                 (eval
                   (codex:derive-requested-execpolicy-amendment-from-prefix-rule-with-sandbox
                     $prefix_rule
                     $matched_rules
                     $policy
                     $approval_policy
                     $sandbox_policy
                     $file_system_sandbox_kind
                     $sandbox_permissions
                     $commands
                     $used_complex_parsing)))
               (codex:approval-from-evaluation
                 $approval_policy
                 $policy
                 $commands
                 $command
                 $evaluation
                 $used_complex_parsing
                 $requested_amendment))))))))

(= (codex:approval-from-evaluation
      $approval_policy
      $policy
      $commands
      $command
      $evaluation)
   (codex:approval-from-evaluation
     $approval_policy
     $policy
     $commands
     $command
     $evaluation
     False
     CodexAbsent))

(= (codex:approval-from-evaluation
      $approval_policy
      $policy
      $commands
      $command
      $evaluation
      $used_complex_parsing
      $requested_amendment)
   (let $decision (once (eval (codex:check-output-decision $evaluation)))
     (let $matched_rules (once (eval (codex:check-output-matched-rules $evaluation)))
       (let $auto_amendment
         (once
           (eval
             (codex:approval-auto-amendment
               $used_complex_parsing
               $matched_rules
               $decision)))
         (let $amendment
           (codex:prefer-requested-amendment
             $requested_amendment
             $auto_amendment)
           (if (== $decision (codex:decision-forbidden))
               (codex:approval-forbidden
                 (codex:derive-forbidden-reason
                   $command
                   $matched_rules))
               (if (== $decision (codex:decision-prompt))
                   (let $prompt_rejection_reason
                     (codex:approval-policy-prompt-rejection-reason
                       $approval_policy
                       (codex:any-policy-rule-match-for-decision?
                         $matched_rules
                         (codex:decision-prompt)))
                     (if (== $prompt_rejection_reason CodexAbsent)
                         (codex:approval-needs-approval
                           (codex:derive-prompt-reason
                             $command
                             $matched_rules)
                           $amendment)
                       (codex:approval-forbidden
                         $prompt_rejection_reason)))
                   (codex:approval-skip
                     (codex:all-commands-explicitly-allowed? $policy $commands)
                     $amendment))))))))
