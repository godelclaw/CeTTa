; Rust-faithful protocol auth helper slice.
;
; This ports the pure data/helper surface from:
; - openai-codex/codex-rs/protocol/src/auth.rs
;
; Covered in this increment:
; - auth::PlanType Known/Unknown
; - auth::KnownPlan wire values, display names, and workspace grouping
; - RefreshTokenFailedReason and RefreshTokenFailedError shape

!(import! &self str)

(= (codex:auth-known-plan-free)
   (CodexAuthKnownPlanFree))

(= (codex:auth-known-plan-go)
   (CodexAuthKnownPlanGo))

(= (codex:auth-known-plan-plus)
   (CodexAuthKnownPlanPlus))

(= (codex:auth-known-plan-pro)
   (CodexAuthKnownPlanPro))

(= (codex:auth-known-plan-pro-lite)
   (CodexAuthKnownPlanProLite))

(= (codex:auth-known-plan-team)
   (CodexAuthKnownPlanTeam))

(= (codex:auth-known-plan-self-serve-business-usage-based)
   (CodexAuthKnownPlanSelfServeBusinessUsageBased))

(= (codex:auth-known-plan-business)
   (CodexAuthKnownPlanBusiness))

(= (codex:auth-known-plan-enterprise-cbp-usage-based)
   (CodexAuthKnownPlanEnterpriseCbpUsageBased))

(= (codex:auth-known-plan-enterprise)
   (CodexAuthKnownPlanEnterprise))

(= (codex:auth-known-plan-edu)
   (CodexAuthKnownPlanEdu))

(= (codex:auth-plan-type-known $known-plan)
   (case $known-plan
     (($materialized-known-plan
       (CodexAuthPlanTypeKnown $materialized-known-plan)))))

(= (codex:auth-plan-type-unknown $raw)
   (CodexAuthPlanTypeUnknown $raw))

(= (codex:auth-ascii-lower-char $char)
   (case $char
     (("A" "a") ("B" "b") ("C" "c") ("D" "d") ("E" "e") ("F" "f")
      ("G" "g") ("H" "h") ("I" "i") ("J" "j") ("K" "k") ("L" "l")
      ("M" "m") ("N" "n") ("O" "o") ("P" "p") ("Q" "q") ("R" "r")
      ("S" "s") ("T" "t") ("U" "u") ("V" "v") ("W" "w") ("X" "x")
      ("Y" "y") ("Z" "z")
      ($other $other))))

(= (codex:auth-ascii-lower-text $text)
   (if (== (str-length $text) 0)
       ""
       (str-concat
         (codex:auth-ascii-lower-char (str-slice $text 0 1))
         (codex:auth-ascii-lower-text
           (str-slice $text 1 (str-length $text))))))

(= (codex:auth-plan-type-from-raw-value $raw)
   (case (codex:auth-ascii-lower-text $raw)
     (("free" (codex:auth-plan-type-known (CodexAuthKnownPlanFree)))
      ("go" (codex:auth-plan-type-known (CodexAuthKnownPlanGo)))
      ("plus" (codex:auth-plan-type-known (CodexAuthKnownPlanPlus)))
      ("pro" (codex:auth-plan-type-known (CodexAuthKnownPlanPro)))
      ("prolite" (codex:auth-plan-type-known (CodexAuthKnownPlanProLite)))
      ("team" (codex:auth-plan-type-known (CodexAuthKnownPlanTeam)))
      ("self_serve_business_usage_based"
       (codex:auth-plan-type-known
         (CodexAuthKnownPlanSelfServeBusinessUsageBased)))
      ("business" (codex:auth-plan-type-known (CodexAuthKnownPlanBusiness)))
      ("enterprise_cbp_usage_based"
       (codex:auth-plan-type-known
         (CodexAuthKnownPlanEnterpriseCbpUsageBased)))
      ("enterprise" (codex:auth-plan-type-known (CodexAuthKnownPlanEnterprise)))
      ("hc" (codex:auth-plan-type-known (CodexAuthKnownPlanEnterprise)))
      ("education" (codex:auth-plan-type-known (CodexAuthKnownPlanEdu)))
      ("edu" (codex:auth-plan-type-known (CodexAuthKnownPlanEdu)))
      ($other (codex:auth-plan-type-unknown $raw)))))

(= (codex:auth-known-plan-display-name $known-plan)
   (case $known-plan
     (((CodexAuthKnownPlanFree) "Free")
      ((CodexAuthKnownPlanGo) "Go")
      ((CodexAuthKnownPlanPlus) "Plus")
      ((CodexAuthKnownPlanPro) "Pro")
      ((CodexAuthKnownPlanProLite) "Pro Lite")
      ((CodexAuthKnownPlanTeam) "Team")
      ((CodexAuthKnownPlanSelfServeBusinessUsageBased)
       "Self Serve Business Usage Based")
      ((CodexAuthKnownPlanBusiness) "Business")
      ((CodexAuthKnownPlanEnterpriseCbpUsageBased)
       "Enterprise CBP Usage Based")
      ((CodexAuthKnownPlanEnterprise) "Enterprise")
      ((CodexAuthKnownPlanEdu) "Edu"))))

(= (codex:auth-known-plan-raw-value $known-plan)
   (case $known-plan
     (((CodexAuthKnownPlanFree) "free")
      ((CodexAuthKnownPlanGo) "go")
      ((CodexAuthKnownPlanPlus) "plus")
      ((CodexAuthKnownPlanPro) "pro")
      ((CodexAuthKnownPlanProLite) "prolite")
      ((CodexAuthKnownPlanTeam) "team")
      ((CodexAuthKnownPlanSelfServeBusinessUsageBased)
       "self_serve_business_usage_based")
      ((CodexAuthKnownPlanBusiness) "business")
      ((CodexAuthKnownPlanEnterpriseCbpUsageBased)
       "enterprise_cbp_usage_based")
      ((CodexAuthKnownPlanEnterprise) "enterprise")
      ((CodexAuthKnownPlanEdu) "edu"))))

(= (codex:auth-known-plan-is-workspace-account $known-plan)
   (case $known-plan
     (((CodexAuthKnownPlanTeam) True)
      ((CodexAuthKnownPlanSelfServeBusinessUsageBased) True)
      ((CodexAuthKnownPlanBusiness) True)
      ((CodexAuthKnownPlanEnterpriseCbpUsageBased) True)
      ((CodexAuthKnownPlanEnterprise) True)
      ((CodexAuthKnownPlanEdu) True)
      ($other False))))

(= (codex:auth-plan-type-display-name $plan-type)
   (case $plan-type
     (((CodexAuthPlanTypeKnown $known-plan)
       (codex:auth-known-plan-display-name $known-plan))
      ((CodexAuthPlanTypeUnknown $raw)
       $raw))))

(= (codex:auth-plan-type-raw-value $plan-type)
   (case $plan-type
     (((CodexAuthPlanTypeKnown $known-plan)
       (codex:auth-known-plan-raw-value $known-plan))
      ((CodexAuthPlanTypeUnknown $raw)
       $raw))))

(= (codex:refresh-token-failed-reason-expired)
   (CodexRefreshTokenFailedReasonExpired))

(= (codex:refresh-token-failed-reason-exhausted)
   (CodexRefreshTokenFailedReasonExhausted))

(= (codex:refresh-token-failed-reason-revoked)
   (CodexRefreshTokenFailedReasonRevoked))

(= (codex:refresh-token-failed-reason-other)
   (CodexRefreshTokenFailedReasonOther))

(= (codex:refresh-token-failed-error $reason $message)
   (case $reason
     (($materialized-reason
       (CodexRefreshTokenFailedError $materialized-reason $message)))))

(= (codex:refresh-token-failed-error-reason
      (CodexRefreshTokenFailedError $reason $message))
   $reason)

(= (codex:refresh-token-failed-error-message
      (CodexRefreshTokenFailedError $reason $message))
   $message)
