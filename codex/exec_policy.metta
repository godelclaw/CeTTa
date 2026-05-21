; Visible prefix-rule exec-policy slice for the restarted Codex port.
;
; This ports the already-parsed prefix-rule evaluation core from
; openai-codex/codex-rs/execpolicy/src/{decision,rule,policy,execpolicycheck}.rs:
; - Decision ordering
; - PatternToken matching, including alternative tokens
; - PrefixRuleMatch JSON shape
; - optional host-executable resolution and resolvedProgram JSON
; - HeuristicsRuleMatch fallback shape
; - network-rule protocol parsing, host normalization, and compiled domains
; - strictest-decision aggregation across one or more commands
; - child_uses_parent_exec_policy comparison over the three ConfigLayerStack
;   values used by Rust
; - format_exec_policy_error_with_source parse-error display selection
; - load_exec_policy layer ordering and load_exec_policy_with_warning downgrade
;
; This increment intentionally starts from already-parsed rule constructors
; rather than Starlark policy-file parsing. That parser and its validation
; hooks (`match` / `not_match`, file loading) land in later exec-policy
; slices.

!(import! &self json)
!(import! &self list)
!(import! &self str)

; Rust receives full Config values and derives these fields from
; ConfigLayerStack. The CeTTa port keeps the exact comparison boundary explicit
; until ConfigLayerStack itself is ported.
(= (codex:exec-policy-config-summary
      $enabled-config-folders
      $ignore-user-and-project-exec-policy-rules
      $requirements-exec-policy)
   (CodexExecPolicyConfigSummary
     $enabled-config-folders
     $ignore-user-and-project-exec-policy-rules
     $requirements-exec-policy))

(= (codex:child-uses-parent-exec-policy $parent-config $child-config)
   (case (once (eval $parent-config))
     (((CodexExecPolicyConfigSummary
          $parent-folders
          $parent-ignore-rules
          $parent-requirements-policy)
       (case (once (eval $child-config))
         (((CodexExecPolicyConfigSummary
              $child-folders
              $child-ignore-rules
              $child-requirements-policy)
           (and
             (== $parent-folders $child-folders)
             (and
               (== $parent-ignore-rules $child-ignore-rules)
               (== $parent-requirements-policy $child-requirements-policy))))))))))

(= (codex:exec-policy-source-location $path $line)
   (CodexExecPolicySourceLocation $path $line))

(= (codex:exec-policy-parse-source-error
      $message
      $structured-location)
   (CodexExecPolicyParseSourceError
     $message
     $structured-location))

(= (codex:exec-policy-error-parse-policy $path $source)
   (CodexExecPolicyErrorParsePolicy $path $source))

(= (codex:exec-policy-error-other $message)
   (CodexExecPolicyErrorOther $message))

(= (codex:exec-policy-error-read-file $path $message)
   (CodexExecPolicyErrorReadFile $path $message))

(= (codex:exec-policy-load-ok $policy)
   (CodexExecPolicyLoadOk $policy))

(= (codex:exec-policy-load-error $error)
   (CodexExecPolicyLoadError $error))

(= (codex:exec-policy-load-value
      (CodexExecPolicyLoadOk $policy))
   $policy)

(= (codex:exec-policy-load-error-value
      (CodexExecPolicyLoadError $error))
   $error)

(= (codex:exec-policy-load-with-warning-ok $policy $warning)
   (CodexExecPolicyLoadWithWarningOk $policy $warning))

(= (codex:exec-policy-load-with-warning-policy
      (CodexExecPolicyLoadWithWarningOk $policy $warning))
   $policy)

(= (codex:exec-policy-load-with-warning-warning
      (CodexExecPolicyLoadWithWarningOk $policy $warning))
   $warning)

(= (codex:exec-policy-layer-source-system)
   CodexExecPolicyLayerSourceSystem)

(= (codex:exec-policy-layer-source-user)
   CodexExecPolicyLayerSourceUser)

(= (codex:exec-policy-layer-source-project)
   CodexExecPolicyLayerSourceProject)

(= (codex:exec-policy-layer-source-other)
   CodexExecPolicyLayerSourceOther)

; Rust reads each enabled layer's `.codex/rules/*.rules` files here. Until the
; Starlark parser/file loader lands, this pure boundary receives the equivalent
; already-parsed policy for each layer and preserves the same ordering/skipping
; and requirements-overlay semantics.
(= (codex:exec-policy-load-layer $source $policy)
   (codex:exec-policy-load-layer $source $policy True))

(= (codex:exec-policy-load-layer $source $policy $enabled)
   (CodexExecPolicyLoadLayer $source $policy $enabled))

(= (codex:exec-policy-load-layer-source
      (CodexExecPolicyLoadLayer $source $policy $enabled))
   $source)

(= (codex:exec-policy-load-layer-policy
      (CodexExecPolicyLoadLayer $source $policy $enabled))
   $policy)

(= (codex:exec-policy-load-layer-enabled
      (CodexExecPolicyLoadLayer $source $policy $enabled))
   $enabled)

(= (codex:exec-policy-load-config-stack
      $layers
      $ignore-user-and-project-exec-policy-rules
      $requirements-exec-policy)
   (CodexExecPolicyLoadConfigStack
     $layers
     $ignore-user-and-project-exec-policy-rules
     $requirements-exec-policy))

(= (codex:is-exec-policy-load-layer-skipped-by-ignore
      CodexExecPolicyLayerSourceSystem)
   False)

(= (codex:is-exec-policy-load-layer-skipped-by-ignore
      CodexExecPolicyLayerSourceUser)
   True)

(= (codex:is-exec-policy-load-layer-skipped-by-ignore
      CodexExecPolicyLayerSourceProject)
   True)

(= (codex:is-exec-policy-load-layer-skipped-by-ignore
      CodexExecPolicyLayerSourceOther)
   False)

(= (codex:load-exec-policy-merge-layers
      ()
      $ignore-user-and-project-exec-policy-rules
      $policy)
   $policy)

(= (codex:load-exec-policy-merge-layers
      $layers
      $ignore-user-and-project-exec-policy-rules
      $policy)
   (let $head (list:first $layers)
     (let $tail (list:rest $layers)
       (let $source (codex:exec-policy-load-layer-source $head)
         (let $enabled (codex:exec-policy-load-layer-enabled $head)
           (if (or
                 (not $enabled)
                 (and
                   $ignore-user-and-project-exec-policy-rules
                   (codex:is-exec-policy-load-layer-skipped-by-ignore
                     $source)))
               (codex:load-exec-policy-merge-layers
                 $tail
                 $ignore-user-and-project-exec-policy-rules
                 $policy)
               (codex:load-exec-policy-merge-layers
                 $tail
                 $ignore-user-and-project-exec-policy-rules
                 (codex:policy-merge-overlay
                   $policy
                   (codex:exec-policy-load-layer-policy $head)))))))))

(= (codex:exec-policy-requirements-overlay-policy CodexAbsent)
   CodexAbsent)

(= (codex:exec-policy-requirements-overlay-policy
      (CodexRequirementsExecPolicy $policy))
   $policy)

(= (codex:load-exec-policy-from-config-stack
      (CodexExecPolicyLoadConfigStack
        $layers
        $ignore-user-and-project-exec-policy-rules
        $requirements-exec-policy))
   (let $policy
     (codex:load-exec-policy-merge-layers
       $layers
       $ignore-user-and-project-exec-policy-rules
       (codex:policy ()))
     (let $requirements-policy
       (codex:exec-policy-requirements-overlay-policy
         $requirements-exec-policy)
       (if (== $requirements-policy CodexAbsent)
           (codex:exec-policy-load-ok $policy)
           (codex:exec-policy-load-ok
             (codex:policy-merge-overlay
               $policy
               $requirements-policy))))))

(= (codex:load-exec-policy-with-warning-from-result
      (CodexExecPolicyLoadOk $policy))
   (codex:exec-policy-load-with-warning-ok $policy CodexAbsent))

(= (codex:load-exec-policy-with-warning-from-result
      (CodexExecPolicyLoadError
        (CodexExecPolicyErrorParsePolicy $path $source)))
   (codex:exec-policy-load-with-warning-ok
     (codex:policy ())
     (CodexExecPolicyErrorParsePolicy $path $source)))

(= (codex:load-exec-policy-with-warning-from-result
      (CodexExecPolicyLoadError
        (CodexExecPolicyErrorReadFile $path $message)))
   (codex:exec-policy-load-error
     (CodexExecPolicyErrorReadFile $path $message)))

(= (codex:load-exec-policy-with-warning-from-result
      (CodexExecPolicyLoadError
        (CodexExecPolicyErrorOther $message)))
   (codex:exec-policy-load-error
     (CodexExecPolicyErrorOther $message)))

(= (codex:exec-policy-source-error-message
      (CodexExecPolicyParseSourceError $message $structured-location))
   $message)

(= (codex:exec-policy-source-error-structured-location
      (CodexExecPolicyParseSourceError $message $structured-location))
   $structured-location)

(= (codex:exec-policy-error-message
      (CodexExecPolicyErrorOther $message))
   $message)

(= (codex:exec-policy-error-message
      (CodexExecPolicyErrorParsePolicy $path $source))
   (codex:format-exec-policy-error-with-source
     (CodexExecPolicyErrorParsePolicy $path $source)))

(= (codex:exec-policy-trim-start $text)
   (codex:exec-policy-trim-start-from $text 0))

(= (codex:exec-policy-trim-start-from $text $index)
   (if (>= $index (str-length $text))
       ""
       (let $char (str-slice $text $index (+ $index 1))
         (if (or (== $char " ") (or (== $char "\t") (== $char "\r")))
             (codex:exec-policy-trim-start-from $text (+ $index 1))
             (str-slice $text $index (str-length $text))))))

(= (codex:exec-policy-first-line $message)
   (let $lines (str-split "\n" $message)
     (if (== $lines ())
         ""
         (str-trim (list:first $lines)))))

(= (codex:exec-policy-first-error-line $lines)
   (if (== $lines ())
       CodexAbsent
       (let $head (list:first $lines)
         (let $tail (list:rest $lines)
           (if (str-starts-with?
                 (codex:exec-policy-trim-start $head)
                 "error: ")
               $head
               (codex:exec-policy-first-error-line $tail))))))

(= (codex:exec-policy-drop-last-list-item $items)
   (if (== $items ())
       ()
       (let $head (list:first $items)
         (let $tail (list:rest $items)
           (if (== $tail ())
               ()
               (let $rest
                 (eval (codex:exec-policy-drop-last-list-item $tail))
                 (cons-atom $head $rest)))))))

(= (codex:exec-policy-last-list-item $items $fallback)
   (if (== $items ())
       $fallback
       (let $head (list:first $items)
         (let $tail (list:rest $items)
           (if (== $tail ())
               $head
               (codex:exec-policy-last-list-item $tail $head))))))

(= (codex:exec-policy-rsplit-once $delimiter $text)
   (let $parts (str-split $delimiter $text)
     (if (== (list:len $parts) 1)
         CodexAbsent
         (CodexExecPolicySplitOnce
           (str-join
             $delimiter
             (codex:exec-policy-drop-last-list-item $parts))
           (codex:exec-policy-last-list-item $parts "")))))

(= (codex:exec-policy-digit-value $char)
   (if (== $char "0")
       0
       (if (== $char "1")
           1
           (if (== $char "2")
               2
               (if (== $char "3")
                   3
                   (if (== $char "4")
                       4
                       (if (== $char "5")
                           5
                           (if (== $char "6")
                               6
                               (if (== $char "7")
                                   7
                                   (if (== $char "8")
                                       8
                                       (if (== $char "9")
                                           9
                                           CodexAbsent)))))))))))

(= (codex:exec-policy-parse-usize $text)
   (if (== (str-length $text) 0)
       CodexAbsent
       (codex:exec-policy-parse-usize-from $text 0 0)))

(= (codex:exec-policy-parse-usize-from $text $index $acc)
   (if (>= $index (str-length $text))
       $acc
       (let $digit
         (codex:exec-policy-digit-value
           (str-slice $text $index (+ $index 1)))
         (if (== $digit CodexAbsent)
             CodexAbsent
             (codex:exec-policy-parse-usize-from
               $text
               (+ $index 1)
               (+ (* $acc 10) $digit))))))

(= (codex:exec-policy-parse-starlark-line-from-message $message)
   (let $first-line (str-trim (codex:exec-policy-first-line $message))
     (case
       (codex:exec-policy-rsplit-once ": starlark error:" $first-line)
       ((CodexAbsent CodexAbsent)
        ((CodexExecPolicySplitOnce $path-and-position $detail)
         (let $parts (str-split ":" $path-and-position)
           (if (< (list:len $parts) 3)
               CodexAbsent
               (let $column
                 (codex:exec-policy-parse-usize
                   (codex:exec-policy-last-list-item $parts ""))
                 (if (== $column CodexAbsent)
                     CodexAbsent
                     (let $without-column
                       (codex:exec-policy-drop-last-list-item $parts)
                       (let $line
                         (codex:exec-policy-parse-usize
                           (codex:exec-policy-last-list-item
                             $without-column
                             ""))
                         (if (or (== $line CodexAbsent) (== $line 0))
                             CodexAbsent
                             (codex:exec-policy-source-location
                               (str-join
                                 ":"
                                 (codex:exec-policy-drop-last-list-item
                                   $without-column))
                               $line)))))))))))))

(= (codex:exec-policy-message-for-display $source)
   (let $message (codex:exec-policy-source-error-message $source)
     (let $error-line
       (codex:exec-policy-first-error-line
         (str-split "\n" $message))
       (if (== $error-line CodexAbsent)
         (let $first-line (codex:exec-policy-first-line $message)
           (case
             (codex:exec-policy-rsplit-once
               ": starlark error: "
               $first-line)
             ((CodexAbsent $first-line)
              ((CodexExecPolicySplitOnce $before $detail)
               (str-trim $detail)))))
         $error-line))))

(= (codex:exec-policy-select-error-location
      $structured-location
      $parsed-location)
   (if (== $structured-location CodexAbsent)
       $parsed-location
       (case $structured-location
         (((CodexExecPolicySourceLocation $structured-path $structured-line)
           (if (and (== $structured-line 1)
                    (not (== $parsed-location CodexAbsent)))
               (case $parsed-location
                 (((CodexExecPolicySourceLocation $parsed-path $parsed-line)
                   (if (> $parsed-line 1)
                       $parsed-location
                       $structured-location))))
               $structured-location))))))

(= (codex:format-exec-policy-error-location
      (CodexExecPolicySourceLocation $path $line)
      $message)
   (format-args
     "{}:{}: {} (problem is on or around line {})"
     ($path $line $message $line)))

(= (codex:format-exec-policy-error-with-source
      (CodexExecPolicyErrorParsePolicy $path $source))
   (let $rendered-source
     (codex:exec-policy-source-error-message $source)
     (let $location
       (codex:exec-policy-select-error-location
         (codex:exec-policy-source-error-structured-location $source)
         (codex:exec-policy-parse-starlark-line-from-message
           $rendered-source))
       (let $message (codex:exec-policy-message-for-display $source)
         (if (== $location CodexAbsent)
             (format-args "{}: {}" ($path $message))
             (codex:format-exec-policy-error-location
               $location
               $message))))))

(= (codex:format-exec-policy-error-with-source
      (CodexExecPolicyErrorOther $message))
   $message)

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
   (CodexExecPolicy
     (codex:exec-policy-materialize-list
       (codex:expand-prefix-rule-specs $rule_specs))))

; Rust Policy fields are concrete collections. Force list-producing CeTTa
; constructors at policy boundaries so callers do not observe producer terms.
(= (codex:exec-policy-materialize-list $values)
   (case (once (eval $values))
     (($materialized-values
       (codex:exec-policy-materialize-list-inner $materialized-values)))))

(= (codex:exec-policy-materialize-list-inner $values)
   (if (== $values ())
       ()
       (let $head (list:first $values)
         (let $tail (list:rest $values)
           (case (once (eval $head))
             (($materialized-head
               (case
                 (codex:exec-policy-materialize-list-inner $tail)
                 (($materialized-tail
                   (cons-atom
                     $materialized-head
                     $materialized-tail)))))))))))

(= (codex:policy-from-parts $rule_specs $network_rules $host_executables)
   (CodexExecPolicyFull
     (codex:exec-policy-materialize-list
       (codex:expand-prefix-rule-specs $rule_specs))
     (codex:exec-policy-materialize-list $network_rules)
     (codex:exec-policy-materialize-list $host_executables)))

(= (codex:policy-with-host-executables $rule_specs $host_executables)
   (codex:policy-from-parts $rule_specs () $host_executables))

(= (codex:policy-with-network-rules $rule_specs $network_rules)
   (codex:policy-from-parts $rule_specs $network_rules ()))

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

(= (codex:policy-rebuild-like $policy $rules $network_rules $host_executables)
   (CodexExecPolicyFull
     (codex:exec-policy-materialize-list $rules)
     (codex:exec-policy-materialize-list $network_rules)
     (codex:exec-policy-materialize-list $host_executables)))

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

(= (codex:exec-policy-dedup-sorted-strings $items)
   (if (== $items ())
       ()
       (let $head (list:first $items)
         (let $tail (list:rest $items)
           (if (== $tail ())
               ($head)
               (let $dedup-tail
                 (codex:exec-policy-dedup-sorted-strings $tail)
                 (if (== $head (list:first $dedup-tail))
                     $dedup-tail
                     (cons-atom $head $dedup-tail))))))))

(= (codex:exec-policy-string-list-remove $values $needle)
   (if (== $values ())
       ()
       (let $head (list:first $values)
         (let $tail (list:rest $values)
           (let $rest (eval
             (codex:exec-policy-string-list-remove $tail $needle))
             (if (== $head $needle)
                 $rest
                 (cons-atom $head $rest)))))))

(= (codex:exec-policy-upsert-domain $entries $host)
   (list:push
     (codex:exec-policy-string-list-remove $entries $host)
     $host))

(= (codex:exec-policy-ascii-lower-char $char)
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

(= (codex:exec-policy-ascii-lower-text $text)
   (if (== (str-length $text) 0)
       ""
       (str-concat
         (codex:exec-policy-ascii-lower-char
           (str-slice $text 0 1))
         (codex:exec-policy-ascii-lower-text
           (str-slice $text 1 (str-length $text))))))

(= (codex:exec-policy-text-contains? $text $needle)
   (case (str-find $text $needle)
     ((Empty False)
      ($index True))))

(= (codex:exec-policy-has-network-rule-path-syntax? $host)
   (if (codex:exec-policy-text-contains? $host "://")
       True
       (if (codex:exec-policy-text-contains? $host "/")
           True
           (if (codex:exec-policy-text-contains? $host "?")
               True
               (codex:exec-policy-text-contains? $host "#")))))

(= (codex:exec-policy-is-ascii-digit-char? $char)
   (if (== $char "0")
       True
       (if (== $char "1")
           True
           (if (== $char "2")
               True
               (if (== $char "3")
                   True
                   (if (== $char "4")
                       True
                       (if (== $char "5")
                           True
                           (if (== $char "6")
                               True
                               (if (== $char "7")
                                   True
                                   (if (== $char "8")
                                       True
                                       (== $char "9")))))))))))

(= (codex:exec-policy-is-nonempty-ascii-digits? $text)
   (if (== $text "")
       False
       (codex:exec-policy-is-ascii-digits-from? $text 0)))

(= (codex:exec-policy-is-ascii-digits-from? $text $index)
   (if (== $index (str-length $text))
       True
       (if (codex:exec-policy-is-ascii-digit-char?
             (str-slice $text $index (+ $index 1)))
           (codex:exec-policy-is-ascii-digits-from?
             $text
             (+ $index 1))
           False)))

(= (codex:exec-policy-count-char-from $text $char $index $acc)
   (if (== $index (str-length $text))
       $acc
       (codex:exec-policy-count-char-from
         $text
         $char
         (+ $index 1)
         (if (== (str-slice $text $index (+ $index 1)) $char)
             (+ $acc 1)
             $acc))))

(= (codex:exec-policy-count-char $text $char)
   (codex:exec-policy-count-char-from $text $char 0 0))

; Rust checks char::is_whitespace. The current CeTTa profile has no Unicode
; whitespace predicate, so this mirrors the ASCII whitespace that can be
; written portably in policy fixtures; a wider string primitive should replace
; it when the parser slice needs Unicode-equivalent validation.
(= (codex:exec-policy-has-ascii-whitespace-from? $text $index)
   (if (== $index (str-length $text))
       False
       (let $char (str-slice $text $index (+ $index 1))
         (if (== $char " ")
             True
             (if (== $char "\t")
                 True
                 (if (== $char "\n")
                     True
                     (if (== $char "\r")
                         True
                         (codex:exec-policy-has-ascii-whitespace-from?
                           $text
                           (+ $index 1)))))))))

(= (codex:exec-policy-has-ascii-whitespace? $text)
   (codex:exec-policy-has-ascii-whitespace-from? $text 0))

(= (codex:exec-policy-trim-end-dots $text)
   (if (== $text "")
       ""
       (if (str-ends-with? $text ".")
           (codex:exec-policy-trim-end-dots
             (str-slice $text 0 (- (str-length $text) 1)))
           $text)))

(= (codex:network-rule-protocol-http)
   (CodexExecPolicyNetworkRuleProtocolHttp))

(= (codex:network-rule-protocol-https)
   (CodexExecPolicyNetworkRuleProtocolHttps))

(= (codex:network-rule-protocol-socks5-tcp)
   (CodexExecPolicyNetworkRuleProtocolSocks5Tcp))

(= (codex:network-rule-protocol-socks5-udp)
   (CodexExecPolicyNetworkRuleProtocolSocks5Udp))

(= (codex:parse-network-rule-protocol $raw)
   (if (== $raw "http")
       (CodexExecPolicyNetworkRuleProtocolOk
         (codex:network-rule-protocol-http))
       (if (== $raw "https")
           (CodexExecPolicyNetworkRuleProtocolOk
             (codex:network-rule-protocol-https))
           (if (== $raw "https_connect")
               (CodexExecPolicyNetworkRuleProtocolOk
                 (codex:network-rule-protocol-https))
               (if (== $raw "http-connect")
                   (CodexExecPolicyNetworkRuleProtocolOk
                     (codex:network-rule-protocol-https))
                   (if (== $raw "socks5_tcp")
                       (CodexExecPolicyNetworkRuleProtocolOk
                         (codex:network-rule-protocol-socks5-tcp))
                       (if (== $raw "socks5_udp")
                           (CodexExecPolicyNetworkRuleProtocolOk
                             (codex:network-rule-protocol-socks5-udp))
                           (CodexExecPolicyNetworkRuleProtocolError
                             (str-concat
                               "network_rule protocol must be one of http, https, socks5_tcp, socks5_udp (got "
                               (str-concat $raw ")"))))))))))

(= (codex:network-rule-protocol-policy-string
      (CodexExecPolicyNetworkRuleProtocolHttp))
   "http")

(= (codex:network-rule-protocol-policy-string
      (CodexExecPolicyNetworkRuleProtocolHttps))
   "https")

(= (codex:network-rule-protocol-policy-string
      (CodexExecPolicyNetworkRuleProtocolSocks5Tcp))
   "socks5_tcp")

(= (codex:network-rule-protocol-policy-string
      (CodexExecPolicyNetworkRuleProtocolSocks5Udp))
   "socks5_udp")

(= (codex:parse-network-rule-decision $raw)
   (if (== $raw "deny")
       (codex:decision-forbidden)
       $raw))

(= (codex:normalize-network-rule-host $raw)
   (let $host (str-trim $raw)
     (if (== $host "")
         (CodexExecPolicyNetworkRuleHostError
           "network_rule host cannot be empty")
         (if (codex:exec-policy-has-network-rule-path-syntax? $host)
             (CodexExecPolicyNetworkRuleHostError
               "network_rule host must be a hostname or IP literal (without scheme or path)")
             (if (str-starts-with? $host "[")
                 (codex:normalize-network-rule-bracketed-host $raw $host)
                 (codex:normalize-network-rule-unbracketed-host $host))))))

(= (codex:normalize-network-rule-bracketed-host $raw $host)
   (let $stripped (str-slice $host 1 (str-length $host))
     (let $close-index (str-find $stripped "]")
       (if (== $close-index Empty)
           (CodexExecPolicyNetworkRuleHostError
             "network_rule host has an invalid bracketed IPv6 literal")
           (let $inside (str-slice $stripped 0 $close-index)
             (let $rest
               (str-slice $stripped (+ $close-index 1) (str-length $stripped))
               (if (== $rest "")
                   (codex:normalize-network-rule-finish-host $inside)
                   (if (str-starts-with? $rest ":")
                       (let $port (str-slice $rest 1 (str-length $rest))
                         (if (codex:exec-policy-is-nonempty-ascii-digits? $port)
                             (codex:normalize-network-rule-finish-host $inside)
                             (CodexExecPolicyNetworkRuleHostError
                               (str-concat
                                 "network_rule host contains an unsupported suffix: "
                                 $raw))))
                       (CodexExecPolicyNetworkRuleHostError
                         (str-concat
                           "network_rule host contains an unsupported suffix: "
                           $raw))))))))))

(= (codex:normalize-network-rule-unbracketed-host $host)
   (if (== (codex:exec-policy-count-char $host ":") 1)
       (let $parts (str-split ":" $host)
         (let $candidate (list:first $parts)
           (let $port (list:first (list:rest $parts))
             (if (and
                   (not (== $candidate ""))
                   (and
                     (not (== $port ""))
                     (codex:exec-policy-is-nonempty-ascii-digits? $port)))
                 (codex:normalize-network-rule-finish-host $candidate)
                 (codex:normalize-network-rule-finish-host $host)))))
       (codex:normalize-network-rule-finish-host $host)))

(= (codex:normalize-network-rule-finish-host $host)
   (let $normalized
     (codex:exec-policy-ascii-lower-text
       (str-trim (codex:exec-policy-trim-end-dots $host)))
     (if (== $normalized "")
         (CodexExecPolicyNetworkRuleHostError
           "network_rule host cannot be empty")
         (if (codex:exec-policy-text-contains? $normalized "*")
             (CodexExecPolicyNetworkRuleHostError
               "network_rule host must be a specific host; wildcards are not allowed")
             (if (codex:exec-policy-has-ascii-whitespace? $normalized)
                 (CodexExecPolicyNetworkRuleHostError
                   "network_rule host cannot contain whitespace")
                 (CodexExecPolicyNetworkRuleHostOk $normalized))))))

(= (codex:network-rule $host $protocol $decision)
   (codex:network-rule $host $protocol $decision CodexAbsent))

(= (codex:network-rule $host $protocol $decision $justification)
   (case (codex:normalize-network-rule-host $host)
     (((CodexExecPolicyNetworkRuleHostOk $normalized-host)
       (CodexExecPolicyNetworkRule
         $normalized-host
         $protocol
         $decision
         $justification))
      ((CodexExecPolicyNetworkRuleHostError $message)
       (CodexExecPolicyNetworkRuleError $message)))))

(= (codex:network-rule-host
      (CodexExecPolicyNetworkRule $host $protocol $decision $justification))
   $host)

(= (codex:network-rule-protocol
      (CodexExecPolicyNetworkRule $host $protocol $decision $justification))
   $protocol)

(= (codex:network-rule-decision
      (CodexExecPolicyNetworkRule $host $protocol $decision $justification))
   $decision)

(= (codex:network-rule-justification
      (CodexExecPolicyNetworkRule $host $protocol $decision $justification))
   $justification)

(= (codex:compiled-network-domains $policy)
   (codex:compiled-network-domains-from-rules
     (codex:policy-network-rules $policy)
     ()
     ()))

(= (codex:compiled-network-domains-from-rules $rules $allowed $denied)
   (if (== $rules ())
       (CodexExecPolicyCompiledNetworkDomains $allowed $denied)
       (let $rule (list:first $rules)
         (let $tail (list:rest $rules)
           (let $host (codex:network-rule-host $rule)
             (let $decision (codex:network-rule-decision $rule)
               (if (== $decision (codex:decision-allow))
                   (codex:compiled-network-domains-from-rules
                     $tail
                     (codex:exec-policy-upsert-domain $allowed $host)
                     (codex:exec-policy-string-list-remove $denied $host))
                   (if (== $decision (codex:decision-forbidden))
                       (codex:compiled-network-domains-from-rules
                         $tail
                         (codex:exec-policy-string-list-remove $allowed $host)
                         (codex:exec-policy-upsert-domain $denied $host))
                       (codex:compiled-network-domains-from-rules
                         $tail
                         $allowed
                         $denied)))))))))

(= (codex:compiled-network-domains-allowed
      (CodexExecPolicyCompiledNetworkDomains $allowed $denied))
   $allowed)

(= (codex:compiled-network-domains-denied
      (CodexExecPolicyCompiledNetworkDomains $allowed $denied))
   $denied)

(= (codex:compiled-network-domains-json
      (CodexExecPolicyCompiledNetworkDomains $allowed $denied))
   (JsonObject
     ((JsonPair "allowed" (codex:string-list-json $allowed))
      (JsonPair "denied" (codex:string-list-json $denied)))))

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

(= (codex:remove-host-executable-by-name $host_executables $name)
   (if (== $host_executables ())
       ()
       (let $head (list:first $host_executables)
         (let $tail (list:rest $host_executables)
           (let $rest
             (eval (codex:remove-host-executable-by-name $tail $name))
             (if (== (codex:host-executable-name $head) $name)
                 $rest
                 (cons-atom $head $rest)))))))

(= (codex:set-host-executable-paths $policy $name $paths)
   (let $normalized-name (codex:executable-lookup-key $name)
     (codex:policy-rebuild-like
       $policy
       (codex:policy-rules $policy)
       (codex:policy-network-rules $policy)
       (list:push
         (codex:remove-host-executable-by-name
           (codex:policy-host-executables $policy)
           $normalized-name)
         (codex:host-executable $normalized-name $paths)))))

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

(= (codex:prefix-rule-from-raw-prefix $prefix $decision)
   (if (== $prefix ())
       (CodexExecPolicyPrefixRuleError
         "prefix cannot be empty")
       (let $first (list:first $prefix)
         (let $rest (eval (list:rest $prefix))
           (CodexExecPolicyPrefixRule
             $first
             (eval
               (map-atom
                 $rest
                 $token
                 (codex:pattern-token $token)))
             $decision
             CodexAbsent)))))

(= (codex:policy-add-prefix-rule $policy $prefix $decision)
   (if (== $prefix ())
       (CodexExecPolicyRuleError "prefix cannot be empty")
       (codex:policy-rebuild-like
         $policy
         (list:push
           (codex:policy-rules $policy)
           (codex:prefix-rule-from-raw-prefix $prefix $decision))
         (codex:policy-network-rules $policy)
         (codex:policy-host-executables $policy))))

(= (codex:merge-host-executables $base $overlay)
   (if (== $overlay ())
       $base
       (let $head (list:first $overlay)
         (let $tail (list:rest $overlay)
           (codex:merge-host-executables
             (list:push
               (codex:remove-host-executable-by-name
                 $base
                 (codex:host-executable-name $head))
               $head)
             $tail)))))

(= (codex:policy-merge-overlay $base $overlay)
   (codex:policy-rebuild-like
     $base
     (list:append
       (codex:policy-rules $base)
       (codex:policy-rules $overlay))
     (list:append
       (codex:policy-network-rules $base)
       (codex:policy-network-rules $overlay))
     (codex:merge-host-executables
       (codex:policy-host-executables $base)
       (codex:policy-host-executables $overlay))))

(= (codex:render-pattern-token
      (CodexExecPolicyPatternTokenSingle $value))
   $value)

(= (codex:render-pattern-token
      (CodexExecPolicyPatternTokenAlts $alternatives))
   (str-concat
     "["
     (str-concat (str-join "|" $alternatives) "]")))

(= (codex:render-pattern-token-list $tokens)
   (if (== $tokens ())
       ()
       (let $head (list:first $tokens)
         (let $tail (list:rest $tokens)
           (case (codex:render-pattern-token $head)
             (($rendered-head
               (case (codex:render-pattern-token-list $tail)
                 (($rendered-tail
                   (cons-atom $rendered-head $rendered-tail)))))))))))

(= (codex:rule-allowed-prefix
      (CodexExecPolicyPrefixRule $first $rest "allow" $justification))
   (case (codex:render-pattern-token-list $rest)
     (($rendered-rest
       (cons-atom $first $rendered-rest)))))

(= (codex:rule-allowed-prefix
      (CodexExecPolicyPrefixRule $first $rest "prompt" $justification))
   CodexAbsent)

(= (codex:rule-allowed-prefix
      (CodexExecPolicyPrefixRule $first $rest "forbidden" $justification))
   CodexAbsent)

(= (codex:policy-allowed-prefix-record $prefix)
   (json-stringify (codex:string-list-json $prefix)))

(= (codex:policy-allowed-prefixes-from-rules $rules)
   (if (== $rules ())
       ()
       (let $head (list:first $rules)
         (let $tail (list:rest $rules)
           (let $rest (codex:policy-allowed-prefixes-from-rules $tail)
             (let $prefix (codex:rule-allowed-prefix $head)
               (if (== $prefix CodexAbsent)
                   $rest
                   (cons-atom $prefix $rest))))))))

(= (codex:policy-allowed-prefix-records $prefixes)
   (eval
     (map-atom
       $prefixes
       $prefix
       (codex:policy-allowed-prefix-record $prefix))))

(= (codex:policy-allowed-prefix-for-record $prefixes $record)
   (let $head (list:first $prefixes)
     (let $tail (list:rest $prefixes)
       (if (== (codex:policy-allowed-prefix-record $head) $record)
           $head
           (codex:policy-allowed-prefix-for-record $tail $record)))))

(= (codex:policy-allowed-prefixes-from-records $prefixes $records)
   (if (== $records ())
       ()
       (let $head (list:first $records)
         (let $tail (list:rest $records)
           (case (codex:policy-allowed-prefix-for-record $prefixes $head)
             (($prefix
               (case
                 (codex:policy-allowed-prefixes-from-records
                   $prefixes
                   $tail)
                 (($rest
                   (cons-atom $prefix $rest)))))))))))

(= (codex:policy-allowed-prefixes $policy)
   (let $prefixes
     (codex:policy-allowed-prefixes-from-rules
       (codex:policy-rules $policy))
     (case (codex:policy-allowed-prefix-records $prefixes)
       (($records
         (codex:policy-allowed-prefixes-from-records
           $prefixes
           (codex:exec-policy-dedup-sorted-strings
             (sort-strings $records))))))))

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
