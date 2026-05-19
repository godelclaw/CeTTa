; Visible prefix-rule exec-policy slice for the restarted Codex port.
;
; This ports the already-parsed prefix-rule evaluation core from
; openai-codex/codex-rs/execpolicy/src/{decision,rule,policy,execpolicycheck}.rs:
; - Decision ordering
; - PatternToken matching, including alternative tokens
; - PrefixRuleMatch JSON shape
; - optional host-executable resolution and resolvedProgram JSON
; - HeuristicsRuleMatch fallback shape
; - strictest-decision aggregation across one or more commands
;
; This increment intentionally starts from already-parsed rule constructors
; rather than Starlark policy-file parsing. That parser and its validation
; hooks (`match` / `not_match`, file loading) land in later exec-policy
; slices.

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

(= (codex:policy-from-parts $rule_specs $network_rules $host_executables)
   (CodexExecPolicyFull
     (codex:expand-prefix-rule-specs $rule_specs)
     $network_rules
     $host_executables))

(= (codex:policy-with-host-executables $rule_specs $host_executables)
   (codex:policy-from-parts $rule_specs () $host_executables))

(= (codex:policy-rules (CodexExecPolicy $rules))
   $rules)

(= (codex:policy-rules
      (CodexExecPolicyFull $rules $network_rules $host_executables))
   $rules)

(= (codex:policy-network-rules (CodexExecPolicy $rules))
   ())

(= (codex:policy-network-rules
      (CodexExecPolicyFull $rules $network_rules $host_executables))
   $network_rules)

(= (codex:policy-host-executables (CodexExecPolicy $rules))
   ())

(= (codex:policy-host-executables
      (CodexExecPolicyFull $rules $network_rules $host_executables))
   $host_executables)

(= (codex:match-options)
   (CodexExecPolicyMatchOptions False))

(= (codex:match-options $resolve_host_executables)
   (CodexExecPolicyMatchOptions $resolve_host_executables))

(= (codex:match-options-resolve-host-executables
      (CodexExecPolicyMatchOptions $resolve_host_executables))
   $resolve_host_executables)

(= (codex:no-heuristics-fallback)
   CodexAbsent)

(= (codex:heuristics-fallback-decision $decision)
   (CodexExecPolicyHeuristicsFallbackDecision $decision))

(= (codex:heuristics-fallback-decision-for-command
      (CodexExecPolicyHeuristicsFallbackDecision $decision)
      $command)
   $decision)

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

(= (codex:rule-match-decision
      (CodexExecPolicyPrefixRuleMatchResolved
        $matched_prefix
        $decision
        $resolved_program
        $justification))
   $decision)

(= (codex:rule-match-decision
      (CodexExecPolicyHeuristicsRuleMatch $command $decision))
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

(= (codex:rule-match-json
      (CodexExecPolicyPrefixRuleMatchResolved
        $matched_prefix
        $decision
        $resolved_program
        $justification))
   (if (== $justification CodexAbsent)
       (JsonObject
         ((JsonPair "prefixRuleMatch"
            (JsonObject
              ((JsonPair "matchedPrefix" (codex:string-list-json $matched_prefix))
               (JsonPair "decision" (JsonString $decision))
               (JsonPair "resolvedProgram" (JsonString $resolved_program)))))))
       (JsonObject
         ((JsonPair "prefixRuleMatch"
            (JsonObject
              ((JsonPair "matchedPrefix" (codex:string-list-json $matched_prefix))
               (JsonPair "decision" (JsonString $decision))
               (JsonPair "resolvedProgram" (JsonString $resolved_program))
               (JsonPair "justification" (JsonString $justification)))))))))

(= (codex:rule-match-json
      (CodexExecPolicyHeuristicsRuleMatch $command $decision))
   (JsonObject
     ((JsonPair "heuristicsRuleMatch"
        (JsonObject
          ((JsonPair "command" (codex:string-list-json $command))
           (JsonPair "decision" (JsonString $decision))))))))

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

(= (codex:string-list-dedupe-acc $values $acc)
   (if (== $values ())
       $acc
       (let $head (list:first $values)
         (let $tail (list:rest $values)
           (if (codex:string-list-contains? $acc $head)
               (codex:string-list-dedupe-acc $tail $acc)
               (codex:string-list-dedupe-acc
                 $tail
                 (list:push $acc $head)))))))

(= (codex:string-list-dedupe $values)
   (codex:string-list-dedupe-acc $values ()))

; Rust executable_lookup_key is identity on non-Windows builds. CeTTa currently
; runs this port in the Unix-like profile used by the test runner, so the same
; behavior is exposed here; Windows suffix stripping belongs with a future
; platform-profile slice.
(= (codex:executable-lookup-key $raw)
   $raw)

(= (codex:executable-path-lookup-key $path)
   (codex:executable-path-lookup-key-from-parts
     (str-split "/" $path)
     CodexAbsent))

(= (codex:executable-path-lookup-key-from-parts $parts $last)
   (if (== $parts ())
       (if (== $last CodexAbsent)
           CodexAbsent
           (if (== $last ".")
               CodexAbsent
               (if (== $last "..")
                   CodexAbsent
                   (codex:executable-lookup-key $last))))
       (let $head (list:first $parts)
         (let $tail (list:rest $parts)
           (codex:executable-path-lookup-key-from-parts
             $tail
             (if (== $head "")
                 $last
                 $head))))))

(= (codex:exec-policy-is-unix-absolute-path $path)
   (str-starts-with? $path "/"))

(= (codex:host-executable $name $paths)
   (CodexExecPolicyHostExecutable
     (codex:executable-lookup-key $name)
     (codex:string-list-dedupe $paths)))

(= (codex:host-executable-name
      (CodexExecPolicyHostExecutable $name $paths))
   $name)

(= (codex:host-executable-paths
      (CodexExecPolicyHostExecutable $name $paths))
   $paths)

(= (codex:host-executable-paths-for-name $host_executables $name)
   (codex:host-executable-paths-for-name-acc
     $host_executables
     $name
     CodexAbsent))

(= (codex:host-executable-paths-for-name-acc $host_executables $name $found)
   (if (== $host_executables ())
       $found
       (let $head (list:first $host_executables)
         (let $tail (list:rest $host_executables)
           (let $next-found
             (if (== (codex:host-executable-name $head) $name)
                 (codex:host-executable-paths $head)
                 $found)
             (codex:host-executable-paths-for-name-acc
               $tail
               $name
               $next-found))))))

(= (codex:host-executable-allows-program? $paths $program)
   (if (== $paths CodexAbsent)
       True
       (codex:string-list-contains? $paths $program)))

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

(= (codex:matches-for-command $policy $command)
   (codex:matches-for-command-with-options-and-heuristics
     $policy
     $command
     (codex:no-heuristics-fallback)
     (codex:match-options)))

(= (codex:matches-for-command-with-options $policy $command $options)
   (codex:matches-for-command-with-options-and-heuristics
     $policy
     $command
     (codex:no-heuristics-fallback)
     $options))

(= (codex:matches-for-command-with-heuristics $policy $command $heuristics_fallback)
   (codex:matches-for-command-with-options-and-heuristics
     $policy
     $command
     $heuristics_fallback
     (codex:match-options)))

(= (codex:matches-for-command-with-options-and-heuristics
      $policy
      $command
      $heuristics_fallback
      $options)
   (let $matched_rules
     (codex:matches-for-command-rules (codex:policy-rules $policy) $command)
     (if (== $matched_rules ())
         (let $host_matches
           (if (codex:match-options-resolve-host-executables $options)
               (codex:match-host-executable-rules $policy $command)
               ())
           (if (== $host_matches ())
               (codex:heuristics-match-or-empty $command $heuristics_fallback)
               $host_matches))
         $matched_rules)))

(= (codex:heuristics-match-or-empty $command $heuristics_fallback)
   (if (== $heuristics_fallback CodexAbsent)
       ()
       ((CodexExecPolicyHeuristicsRuleMatch
          $command
          (codex:heuristics-fallback-decision-for-command
            $heuristics_fallback
            $command)))))

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

(= (codex:match-host-executable-rules $policy $command)
   (if (== $command ())
       ()
       (let $program (list:first $command)
         (if (codex:exec-policy-is-unix-absolute-path $program)
             (let $basename (codex:executable-path-lookup-key $program)
               (if (== $basename CodexAbsent)
                   ()
                   (let $host_paths
                     (codex:host-executable-paths-for-name
                       (codex:policy-host-executables $policy)
                       $basename)
                     (if (codex:host-executable-allows-program?
                           $host_paths
                           $program)
                         (let $basename_command
                           (cons-atom $basename (list:rest $command))
                           (codex:with-resolved-programs
                             (codex:matches-for-command-rules
                               (codex:policy-rules $policy)
                               $basename_command)
                             $program))
                         ()))))
             ()))))

(= (codex:with-resolved-programs $matches $resolved_program)
   (if (== $matches ())
       ()
       (let $head (list:first $matches)
         (let $tail (list:rest $matches)
           (let $rest
             (eval (codex:with-resolved-programs $tail $resolved_program))
             (cons-atom
               (codex:rule-match-with-resolved-program $head $resolved_program)
               $rest))))))

(= (codex:rule-match-with-resolved-program
      (CodexExecPolicyPrefixRuleMatch $matched_prefix $decision $justification)
      $resolved_program)
   (CodexExecPolicyPrefixRuleMatchResolved
     $matched_prefix
     $decision
     $resolved_program
     $justification))

(= (codex:rule-match-with-resolved-program
      (CodexExecPolicyPrefixRuleMatchResolved
        $matched_prefix
        $decision
        $old_resolved_program
        $justification)
      $resolved_program)
   (CodexExecPolicyPrefixRuleMatchResolved
     $matched_prefix
     $decision
     $resolved_program
     $justification))

(= (codex:check-policy $policy $command)
   (let $matched_rules (codex:matches-for-command $policy $command)
     (CodexExecPolicyCheckOutput
       $matched_rules
       (codex:decision-from-matched-rules $matched_rules))))

(= (codex:check-policy-with-options $policy $command $options)
   (let $matched_rules
     (codex:matches-for-command-with-options $policy $command $options)
     (CodexExecPolicyCheckOutput
       $matched_rules
       (codex:decision-from-matched-rules $matched_rules))))

(= (codex:check-policy-with-heuristics $policy $command $heuristics_fallback)
   (let $matched_rules
     (codex:matches-for-command-with-heuristics
       $policy
       $command
       $heuristics_fallback)
     (CodexExecPolicyCheckOutput
       $matched_rules
       (codex:decision-from-matched-rules $matched_rules))))

(= (codex:check-policy-with-options-and-heuristics
      $policy
      $command
      $heuristics_fallback
      $options)
   (let $matched_rules
     (codex:matches-for-command-with-options-and-heuristics
       $policy
       $command
       $heuristics_fallback
       $options)
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

(= (codex:check-policy-multiple-with-options $policy $commands $options)
   (if (== $commands ())
       (CodexExecPolicyCheckOutput () CodexAbsent)
       (let $all_matches
         (codex:matches-for-commands-with-options $policy $commands $options)
         (CodexExecPolicyCheckOutput
           $all_matches
           (codex:decision-from-matched-rules $all_matches)))))

(= (codex:check-policy-multiple-with-options-and-heuristics
      $policy
      $commands
      $heuristics_fallback
      $options)
   (if (== $commands ())
       (CodexExecPolicyCheckOutput () CodexAbsent)
       (let $all_matches
         (codex:matches-for-commands-with-options-and-heuristics
           $policy
           $commands
           $heuristics_fallback
           $options)
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

(= (codex:matches-for-commands-with-options $policy $commands $options)
   (codex:matches-for-commands-with-options-and-heuristics
     $policy
     $commands
     (codex:no-heuristics-fallback)
     $options))

(= (codex:matches-for-commands-with-options-and-heuristics
      $policy
      $commands
      $heuristics_fallback
      $options)
   (if (== $commands ())
       ()
       (let $head (list:first $commands)
         (let $tail (list:rest $commands)
           (let $head_matches
             (codex:matches-for-command-with-options-and-heuristics
               $policy
               $head
               $heuristics_fallback
               $options)
             (let $tail_matches
               (eval
                 (codex:matches-for-commands-with-options-and-heuristics
                   $policy
                   $tail
                   $heuristics_fallback
                   $options))
               (list:append $head_matches $tail_matches)))))))
