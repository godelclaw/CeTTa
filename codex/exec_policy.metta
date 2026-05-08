; Visible prefix-rule exec-policy slice for the restarted Codex port.
;
; This ports the already-parsed prefix-rule evaluation core from
; openai-codex/codex-rs/execpolicy/src/{decision,rule,policy,execpolicycheck}.rs:
; - Decision ordering
; - PatternToken matching, including alternative tokens
; - PrefixRuleMatch JSON shape
; - strictest-decision aggregation across one or more commands
;
; This increment intentionally starts from already-parsed rule constructors
; rather than Starlark policy-file parsing. That parser and its validation
; hooks (`match` / `not_match`, host_executable, file loading) land in later
; exec-policy slices.

!(import! &self json)
!(import! &self list)
!(import! &self str)

(= (codex:decision-allow)
   "allow")

(= (codex:decision-prompt)
   "prompt")

(= (codex:decision-forbidden)
   "forbidden")

(= (codex:pattern-token $token)
   (CodexExecPolicyPatternTokenSingle $token))

(= (codex:pattern-any-of $alternatives)
   (if (== (list:len $alternatives) 1)
       (CodexExecPolicyPatternTokenSingle (list:first $alternatives))
       (CodexExecPolicyPatternTokenAlts $alternatives)))

(= (codex:prefix-rule $pattern)
   (CodexExecPolicyPrefixRuleSpec $pattern "allow" CodexAbsent))

(= (codex:prefix-rule $pattern $decision)
   (CodexExecPolicyPrefixRuleSpec $pattern $decision CodexAbsent))

(= (codex:prefix-rule $pattern $decision $justification)
   (CodexExecPolicyPrefixRuleSpec $pattern $decision $justification))

(= (codex:policy $rule_specs)
   (CodexExecPolicy (codex:expand-prefix-rule-specs $rule_specs)))

(= (codex:policy-rules (CodexExecPolicy $rules))
   $rules)

(= (codex:decision-rank $decision)
   (if (== $decision "allow")
       0
       (if (== $decision "prompt")
           1
           2)))

(= (codex:max-decision $lhs $rhs)
   (if (> (codex:decision-rank $lhs) (codex:decision-rank $rhs))
       $lhs
       $rhs))

(= (codex:decision-from-matched-rules $rules)
   (if (== $rules ())
       CodexAbsent
       (codex:decision-from-matched-rules-acc
         (list:rest $rules)
         (codex:rule-match-decision (list:first $rules)))))

(= (codex:decision-from-matched-rules-acc $rules $decision)
   (if (== $rules ())
       $decision
       (codex:decision-from-matched-rules-acc
         (list:rest $rules)
         (codex:max-decision
           $decision
           (codex:rule-match-decision (list:first $rules))))))

(= (codex:rule-match-decision
      (CodexExecPolicyPrefixRuleMatch $matched_prefix $decision $justification))
   $decision)

(= (codex:optional-string-json $value)
   (if (== $value CodexAbsent)
       JsonNull
       (JsonString $value)))

(= (codex:string-list-json $values)
   (if (== $values ())
       (JsonArray ())
       (JsonArray
         (eval (map-atom $values $value (JsonString $value))))))

(= (codex:rule-match-json
      (CodexExecPolicyPrefixRuleMatch $matched_prefix $decision $justification))
   (if (== $justification CodexAbsent)
       (JsonObject
         ((JsonPair "prefixRuleMatch"
            (JsonObject
              ((JsonPair "matchedPrefix" (codex:string-list-json $matched_prefix))
               (JsonPair "decision" (JsonString $decision)))))))
       (JsonObject
         ((JsonPair "prefixRuleMatch"
            (JsonObject
              ((JsonPair "matchedPrefix" (codex:string-list-json $matched_prefix))
               (JsonPair "decision" (JsonString $decision))
               (JsonPair "justification" (JsonString $justification)))))))))

(= (codex:matched-rules-json $matched_rules)
   (JsonArray
     (eval (map-atom $matched_rules $rule_match (codex:rule-match-json $rule_match)))))

(= (codex:check-output-json (CodexExecPolicyCheckOutput $matched_rules $decision))
   (if (== $decision CodexAbsent)
       (JsonObject
         ((JsonPair "matchedRules" (codex:matched-rules-json $matched_rules))))
       (JsonObject
         ((JsonPair "matchedRules" (codex:matched-rules-json $matched_rules))
          (JsonPair "decision" (JsonString $decision))))))

(= (codex:check-output-decision (CodexExecPolicyCheckOutput $matched_rules $decision))
   (if (== $decision CodexAbsent) Empty $decision))

(= (codex:check-output-matched-rules (CodexExecPolicyCheckOutput $matched_rules $decision))
   $matched_rules)

(= (codex:pattern-token-matches? (CodexExecPolicyPatternTokenSingle $expected) $token)
   (== $expected $token))

(= (codex:pattern-token-matches? (CodexExecPolicyPatternTokenAlts $alternatives) $token)
   (codex:string-list-contains? $alternatives $token))

(= (codex:string-list-contains? $values $needle)
   (if (== $values ())
       False
       (if (== (list:first $values) $needle)
           True
           (codex:string-list-contains? (list:rest $values) $needle))))

(= (codex:expand-prefix-rule-specs $rule_specs)
   (if (== $rule_specs ())
       ()
       (let $head (list:first $rule_specs)
         (let $tail (list:rest $rule_specs)
           (let $expanded_head (codex:expand-prefix-rule-spec $head)
             (let $expanded_tail (eval (codex:expand-prefix-rule-specs $tail))
               (list:append $expanded_head $expanded_tail)))))))

(= (codex:expand-prefix-rule-spec
      (CodexExecPolicyPrefixRuleSpec $pattern $decision $justification))
   (if (== $pattern ())
       ()
       (let $first_token (list:first $pattern)
         (let $rest_pattern (list:rest $pattern)
           (codex:expand-prefix-rule-first-token
             $first_token
             $rest_pattern
             $decision
             $justification)))))

(= (codex:expand-prefix-rule-first-token
      (CodexExecPolicyPatternTokenSingle $first)
      $rest_pattern
      $decision
      $justification)
   ((CodexExecPolicyPrefixRule $first $rest_pattern $decision $justification)))

(= (codex:expand-prefix-rule-first-token
      (CodexExecPolicyPatternTokenAlts $alternatives)
      $rest_pattern
      $decision
      $justification)
   (codex:expand-prefix-rule-first-alternatives
     $alternatives
     $rest_pattern
     $decision
     $justification))

(= (codex:expand-prefix-rule-first-alternatives
      $alternatives
      $rest_pattern
      $decision
      $justification)
   (if (== $alternatives ())
       ()
       (let $head (list:first $alternatives)
         (let $tail (list:rest $alternatives)
           (let $rest (eval
             (codex:expand-prefix-rule-first-alternatives
               $tail
               $rest_pattern
               $decision
               $justification))
             (cons-atom
               (CodexExecPolicyPrefixRule $head $rest_pattern $decision $justification)
               $rest))))))

(= (codex:match-prefix-rest $pattern_rest $command_tail $matched_prefix)
   (if (== $pattern_rest ())
       $matched_prefix
       (if (== $command_tail ())
           CodexAbsent
           (let $pattern_token (list:first $pattern_rest)
             (let $remaining_pattern (list:rest $pattern_rest)
               (let $command_token (list:first $command_tail)
                 (let $remaining_command (list:rest $command_tail)
                   (if (codex:pattern-token-matches? $pattern_token $command_token)
                       (codex:match-prefix-rest
                         $remaining_pattern
                         $remaining_command
                         (list:push $matched_prefix $command_token))
                       CodexAbsent))))))))

(= (codex:match-prefix-rule $rule $command)
   (if (== $command ())
       CodexAbsent
       (let $rule_first (codex:prefix-rule-first $rule)
         (let $command_first (list:first $command)
           (if (== $rule_first $command_first)
               (let $matched_prefix
                 (codex:match-prefix-rest
                   (codex:prefix-rule-rest $rule)
                   (list:rest $command)
                   ($command_first))
                 (if (== $matched_prefix CodexAbsent)
                     CodexAbsent
                     (CodexExecPolicyPrefixRuleMatch
                       $matched_prefix
                       (codex:prefix-rule-decision $rule)
                       (codex:prefix-rule-justification $rule))))
               CodexAbsent)))))

(= (codex:prefix-rule-first
      (CodexExecPolicyPrefixRule $first $rest $decision $justification))
   $first)

(= (codex:prefix-rule-rest
      (CodexExecPolicyPrefixRule $first $rest $decision $justification))
   $rest)

(= (codex:prefix-rule-decision
      (CodexExecPolicyPrefixRule $first $rest $decision $justification))
   $decision)

(= (codex:prefix-rule-justification
      (CodexExecPolicyPrefixRule $first $rest $decision $justification))
   $justification)

(= (codex:matches-for-command (CodexExecPolicy $rules) $command)
   (codex:matches-for-command-rules $rules $command))

(= (codex:matches-for-command-rules $rules $command)
   (if (== $rules ())
       ()
       (let $head (list:first $rules)
         (let $tail (list:rest $rules)
           (let $rest_matches (eval (codex:matches-for-command-rules $tail $command))
             (let $match (codex:match-prefix-rule $head $command)
               (if (== $match CodexAbsent)
                   $rest_matches
                   (cons-atom $match $rest_matches))))))))

(= (codex:check-policy $policy $command)
   (let $matched_rules (codex:matches-for-command $policy $command)
     (CodexExecPolicyCheckOutput
       $matched_rules
       (codex:decision-from-matched-rules $matched_rules))))

(= (codex:check-policy-multiple $policy $commands)
   (if (== $commands ())
       (CodexExecPolicyCheckOutput () CodexAbsent)
       (let $all_matches (codex:matches-for-commands $policy $commands)
         (CodexExecPolicyCheckOutput
           $all_matches
           (codex:decision-from-matched-rules $all_matches)))))

(= (codex:matches-for-commands $policy $commands)
   (if (== $commands ())
       ()
       (let $head (list:first $commands)
         (let $tail (list:rest $commands)
           (let $head_matches (codex:matches-for-command $policy $head)
             (let $tail_matches (eval (codex:matches-for-commands $policy $tail))
               (list:append $head_matches $tail_matches)))))))
