; Rust-faithful account plan-type helper slice.
;
; This ports:
; - openai-codex/codex-rs/protocol/src/account.rs
;
; Covered in this increment:
; - PlanType variants and wire names
; - PlanType family helper predicates

(= (codex:plan-type-free)
   (CodexPlanTypeFree))

(= (codex:plan-type-go)
   (CodexPlanTypeGo))

(= (codex:plan-type-plus)
   (CodexPlanTypePlus))

(= (codex:plan-type-pro)
   (CodexPlanTypePro))

(= (codex:plan-type-pro-lite)
   (CodexPlanTypeProLite))

(= (codex:plan-type-team)
   (CodexPlanTypeTeam))

(= (codex:plan-type-self-serve-business-usage-based)
   (CodexPlanTypeSelfServeBusinessUsageBased))

(= (codex:plan-type-business)
   (CodexPlanTypeBusiness))

(= (codex:plan-type-enterprise-cbp-usage-based)
   (CodexPlanTypeEnterpriseCbpUsageBased))

(= (codex:plan-type-enterprise)
   (CodexPlanTypeEnterprise))

(= (codex:plan-type-edu)
   (CodexPlanTypeEdu))

(= (codex:plan-type-unknown)
   (CodexPlanTypeUnknown))

(= (codex:default-plan-type)
   (codex:plan-type-free))

(= (codex:plan-type-wire-name $plan-type)
   (case $plan-type
     (((CodexPlanTypeFree) "free")
      ((CodexPlanTypeGo) "go")
      ((CodexPlanTypePlus) "plus")
      ((CodexPlanTypePro) "pro")
      ((CodexPlanTypeProLite) "prolite")
      ((CodexPlanTypeTeam) "team")
      ((CodexPlanTypeSelfServeBusinessUsageBased) "self_serve_business_usage_based")
      ((CodexPlanTypeBusiness) "business")
      ((CodexPlanTypeEnterpriseCbpUsageBased) "enterprise_cbp_usage_based")
      ((CodexPlanTypeEnterprise) "enterprise")
      ((CodexPlanTypeEdu) "edu")
      ((CodexPlanTypeUnknown) "unknown"))))

(= (codex:plan-type-from-wire-name $wire-name)
   (case $wire-name
     (("free" (CodexPlanTypeFree))
      ("go" (CodexPlanTypeGo))
      ("plus" (CodexPlanTypePlus))
      ("pro" (CodexPlanTypePro))
      ("prolite" (CodexPlanTypeProLite))
      ("team" (CodexPlanTypeTeam))
      ("self_serve_business_usage_based" (CodexPlanTypeSelfServeBusinessUsageBased))
      ("business" (CodexPlanTypeBusiness))
      ("enterprise_cbp_usage_based" (CodexPlanTypeEnterpriseCbpUsageBased))
      ("enterprise" (CodexPlanTypeEnterprise))
      ("edu" (CodexPlanTypeEdu))
      ($other (CodexPlanTypeUnknown)))))

(= (codex:plan-type-is-team-like $plan-type)
   (case $plan-type
     (((CodexPlanTypeTeam) True)
      ((CodexPlanTypeSelfServeBusinessUsageBased) True)
      ($other False))))

(= (codex:plan-type-is-business-like $plan-type)
   (case $plan-type
     (((CodexPlanTypeBusiness) True)
      ((CodexPlanTypeEnterpriseCbpUsageBased) True)
      ($other False))))

(= (codex:plan-type-is-workspace-account $plan-type)
   (case $plan-type
     (((CodexPlanTypeTeam) True)
      ((CodexPlanTypeSelfServeBusinessUsageBased) True)
      ((CodexPlanTypeBusiness) True)
      ((CodexPlanTypeEnterpriseCbpUsageBased) True)
      ((CodexPlanTypeEnterprise) True)
      ((CodexPlanTypeEdu) True)
      ($other False))))
