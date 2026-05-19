; Rust-faithful requirements exec-policy slice.
;
; This ports the pure validation/conversion core from:
; - openai-codex/codex-rs/config/src/requirements_exec_policy.rs
;
; Covered in this increment:
; - RequirementsExecPolicy wrapper/as_ref shape
; - TOML-shaped prefix-rule, decision, and pattern-token constructors
; - validation order and parse error display strings
; - conversion into the internal exec-policy prefix-rule representation
;
; Required CeTTa representation notes for audit:
; - Rust obtains these structs through serde TOML deserialization. The current
;   CeTTa slice starts from equivalent constructor values; text TOML parsing
;   belongs with the config parser layer.
; - Rust returns Result<T, RequirementsExecPolicyParseError>. CeTTa exposes the
;   same boundary as explicit Ok/Error constructors so file-mode tests can
;   inspect failures without depending on host exceptions.

!(import! &self exec_policy)
!(import! &self list)
!(import! &self num_format)
!(import! &self str)

(= (codex:requirements-exec-policy $policy)
   (CodexRequirementsExecPolicy $policy))

(= (codex:requirements-exec-policy-policy
      (CodexRequirementsExecPolicy $policy))
   $policy)

(= (codex:requirements-exec-policy-toml $prefix-rules)
   (CodexRequirementsExecPolicyToml $prefix-rules))

(= (codex:requirements-exec-policy-prefix-rule-toml
      $pattern
      $decision)
   (CodexRequirementsExecPolicyPrefixRuleToml
     $pattern
     $decision
     CodexAbsent))

(= (codex:requirements-exec-policy-prefix-rule-toml
      $pattern
      $decision
      $justification)
   (CodexRequirementsExecPolicyPrefixRuleToml
     $pattern
     $decision
     $justification))

(= (codex:requirements-exec-policy-pattern-token $token)
   (CodexRequirementsExecPolicyPatternTokenToml $token CodexAbsent))

(= (codex:requirements-exec-policy-pattern-any-of $alternatives)
   (CodexRequirementsExecPolicyPatternTokenToml CodexAbsent $alternatives))

(= (codex:requirements-exec-policy-pattern-token-raw
      $token
      $any-of)
   (CodexRequirementsExecPolicyPatternTokenToml $token $any-of))

(= (codex:requirements-exec-policy-decision-allow)
   (CodexRequirementsExecPolicyDecisionTomlAllow))

(= (codex:requirements-exec-policy-decision-prompt)
   (CodexRequirementsExecPolicyDecisionTomlPrompt))

(= (codex:requirements-exec-policy-decision-forbidden)
   (CodexRequirementsExecPolicyDecisionTomlForbidden))

(= (codex:requirements-exec-policy-parse-ok $value)
   (CodexRequirementsExecPolicyParseOk $value))

(= (codex:requirements-exec-policy-parse-error $error)
   (CodexRequirementsExecPolicyParseError $error))

(= (codex:requirements-exec-policy-parse-value
      (CodexRequirementsExecPolicyParseOk $value))
   $value)

(= (codex:requirements-exec-policy-parse-error-value
      (CodexRequirementsExecPolicyParseError $error))
   $error)

(= (codex:requirements-exec-policy-parse-error-message
      (CodexRequirementsExecPolicyParseErrorEmptyPrefixRules))
   "rules prefix_rules cannot be empty")

(= (codex:requirements-exec-policy-parse-error-message
      (CodexRequirementsExecPolicyParseErrorEmptyPattern $rule-index))
   (str-concat
     "rules prefix_rule at index "
     (str-concat
       (codex:num-format-number-text $rule-index)
       " has an empty pattern")))

(= (codex:requirements-exec-policy-parse-error-message
      (CodexRequirementsExecPolicyParseErrorInvalidPatternToken
        $rule-index
        $token-index
        $reason))
   (str-concat
     "rules prefix_rule at index "
     (str-concat
       (codex:num-format-number-text $rule-index)
       (str-concat
         " has an invalid pattern token at index "
         (str-concat
           (codex:num-format-number-text $token-index)
           (str-concat ": " $reason))))))

(= (codex:requirements-exec-policy-parse-error-message
      (CodexRequirementsExecPolicyParseErrorEmptyJustification $rule-index))
   (str-concat
     "rules prefix_rule at index "
     (str-concat
       (codex:num-format-number-text $rule-index)
       " has an empty justification")))

(= (codex:requirements-exec-policy-parse-error-message
      (CodexRequirementsExecPolicyParseErrorMissingDecision $rule-index))
   (str-concat
     "rules prefix_rule at index "
     (str-concat
       (codex:num-format-number-text $rule-index)
       " is missing a decision")))

(= (codex:requirements-exec-policy-parse-error-message
      (CodexRequirementsExecPolicyParseErrorAllowDecisionNotAllowed
        $rule-index))
   (str-concat
     "rules prefix_rule at index "
     (str-concat
       (codex:num-format-number-text $rule-index)
       " has decision 'allow', which is not permitted in requirements.toml: Codex merges these rules with other config and uses the most restrictive result (use 'prompt' or 'forbidden')")))

(= (codex:requirements-exec-policy-empty-justification?
      $justification)
   (if (== $justification CodexAbsent)
       False
       (== (str-trim $justification) "")))

(= (codex:requirements-exec-policy-string-list-has-empty-trim?
      $values)
   (if (== $values ())
       False
       (let $head (list:first $values)
         (let $tail (list:rest $values)
           (if (== (str-trim $head) "")
               True
               (codex:requirements-exec-policy-string-list-has-empty-trim?
                 $tail))))))

(= (codex:requirements-exec-policy-decision-to-exec-decision
      CodexAbsent
      $rule-index)
   (codex:requirements-exec-policy-parse-error
     (CodexRequirementsExecPolicyParseErrorMissingDecision $rule-index)))

(= (codex:requirements-exec-policy-decision-to-exec-decision
      (CodexRequirementsExecPolicyDecisionTomlAllow)
      $rule-index)
   (codex:requirements-exec-policy-parse-error
     (CodexRequirementsExecPolicyParseErrorAllowDecisionNotAllowed
       $rule-index)))

(= (codex:requirements-exec-policy-decision-to-exec-decision
      (CodexRequirementsExecPolicyDecisionTomlPrompt)
      $rule-index)
   (codex:requirements-exec-policy-parse-ok
     (codex:decision-prompt)))

(= (codex:requirements-exec-policy-decision-to-exec-decision
      (CodexRequirementsExecPolicyDecisionTomlForbidden)
      $rule-index)
   (codex:requirements-exec-policy-parse-ok
     (codex:decision-forbidden)))

(= (codex:requirements-exec-policy-parse-pattern-token
      (CodexRequirementsExecPolicyPatternTokenToml $token $any-of)
      $rule-index
      $token-index)
   (if (== $token CodexAbsent)
       (if (== $any-of CodexAbsent)
           (codex:requirements-exec-policy-parse-error
             (CodexRequirementsExecPolicyParseErrorInvalidPatternToken
               $rule-index
               $token-index
               "set either token or any_of"))
           (if (== $any-of ())
               (codex:requirements-exec-policy-parse-error
                 (CodexRequirementsExecPolicyParseErrorInvalidPatternToken
                   $rule-index
                   $token-index
                   "any_of cannot be empty"))
               (if (codex:requirements-exec-policy-string-list-has-empty-trim?
                     $any-of)
                   (codex:requirements-exec-policy-parse-error
                     (CodexRequirementsExecPolicyParseErrorInvalidPatternToken
                       $rule-index
                       $token-index
                       "any_of cannot include empty tokens"))
                   (codex:requirements-exec-policy-parse-ok
                     (codex:pattern-any-of $any-of)))))
       (if (== $any-of CodexAbsent)
           (if (== (str-trim $token) "")
               (codex:requirements-exec-policy-parse-error
                 (CodexRequirementsExecPolicyParseErrorInvalidPatternToken
                   $rule-index
                   $token-index
                   "token cannot be empty"))
               (codex:requirements-exec-policy-parse-ok
                 (codex:pattern-token $token)))
           (codex:requirements-exec-policy-parse-error
             (CodexRequirementsExecPolicyParseErrorInvalidPatternToken
               $rule-index
               $token-index
               "set either token or any_of, not both")))))

(= (codex:requirements-exec-policy-parse-pattern-tokens
      $tokens
      $rule-index
      $token-index)
   (if (== $tokens ())
       (codex:requirements-exec-policy-parse-ok ())
       (let $head (list:first $tokens)
         (let $tail (list:rest $tokens)
           (case
             (codex:requirements-exec-policy-parse-pattern-token
               $head
               $rule-index
               $token-index)
             (((CodexRequirementsExecPolicyParseError $error)
               (codex:requirements-exec-policy-parse-error $error))
              ((CodexRequirementsExecPolicyParseOk $parsed-head)
               (case
                 (codex:requirements-exec-policy-parse-pattern-tokens
                   $tail
                   $rule-index
                   (+ $token-index 1))
                 (((CodexRequirementsExecPolicyParseError $error)
                   (codex:requirements-exec-policy-parse-error $error))
                  ((CodexRequirementsExecPolicyParseOk $parsed-tail)
                   (codex:requirements-exec-policy-parse-ok
                     (cons-atom $parsed-head $parsed-tail))))))))))))

(= (codex:requirements-exec-policy-prefix-rule-to-spec
      (CodexRequirementsExecPolicyPrefixRuleToml
        $pattern
        $decision
        $justification)
      $rule-index)
   (if (codex:requirements-exec-policy-empty-justification?
         $justification)
       (codex:requirements-exec-policy-parse-error
         (CodexRequirementsExecPolicyParseErrorEmptyJustification
           $rule-index))
       (if (== $pattern ())
           (codex:requirements-exec-policy-parse-error
             (CodexRequirementsExecPolicyParseErrorEmptyPattern
               $rule-index))
           (case
             (codex:requirements-exec-policy-parse-pattern-tokens
               $pattern
               $rule-index
               0)
             (((CodexRequirementsExecPolicyParseError $error)
               (codex:requirements-exec-policy-parse-error $error))
              ((CodexRequirementsExecPolicyParseOk $pattern-tokens)
               (case
                 (codex:requirements-exec-policy-decision-to-exec-decision
                   $decision
                   $rule-index)
                 (((CodexRequirementsExecPolicyParseError $error)
                   (codex:requirements-exec-policy-parse-error $error))
                  ((CodexRequirementsExecPolicyParseOk $exec-decision)
                   (codex:requirements-exec-policy-parse-ok
                     (codex:prefix-rule
                       $pattern-tokens
                       $exec-decision
                       $justification)))))))))))

(= (codex:requirements-exec-policy-prefix-rules-to-specs
      $prefix-rules
      $rule-index)
   (if (== $prefix-rules ())
       (codex:requirements-exec-policy-parse-ok ())
       (let $head (list:first $prefix-rules)
         (let $tail (list:rest $prefix-rules)
           (case
             (codex:requirements-exec-policy-prefix-rule-to-spec
               $head
               $rule-index)
             (((CodexRequirementsExecPolicyParseError $error)
               (codex:requirements-exec-policy-parse-error $error))
              ((CodexRequirementsExecPolicyParseOk $spec)
               (case
                 (codex:requirements-exec-policy-prefix-rules-to-specs
                   $tail
                   (+ $rule-index 1))
                 (((CodexRequirementsExecPolicyParseError $error)
                   (codex:requirements-exec-policy-parse-error $error))
                  ((CodexRequirementsExecPolicyParseOk $specs)
                   (codex:requirements-exec-policy-parse-ok
                     (cons-atom $spec $specs))))))))))))

(= (codex:requirements-exec-policy-to-policy
      (CodexRequirementsExecPolicyToml $prefix-rules))
   (if (== $prefix-rules ())
       (codex:requirements-exec-policy-parse-error
         (CodexRequirementsExecPolicyParseErrorEmptyPrefixRules))
       (case
         (codex:requirements-exec-policy-prefix-rules-to-specs
           $prefix-rules
           0)
         (((CodexRequirementsExecPolicyParseError $error)
           (codex:requirements-exec-policy-parse-error $error))
          ((CodexRequirementsExecPolicyParseOk $specs)
           (codex:requirements-exec-policy-parse-ok
             (codex:policy $specs)))))))

(= (codex:requirements-exec-policy-to-requirements-policy $toml)
   (case (codex:requirements-exec-policy-to-policy $toml)
     (((CodexRequirementsExecPolicyParseError $error)
       (codex:requirements-exec-policy-parse-error $error))
      ((CodexRequirementsExecPolicyParseOk $policy)
       (codex:requirements-exec-policy-parse-ok
         (codex:requirements-exec-policy $policy))))))
