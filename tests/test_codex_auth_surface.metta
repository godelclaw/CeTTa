!(register-module! ../codex)
!(import! &self codex:auth)

!(assertEqualToResult
  (codex:auth-plan-type-from-raw-value "PRO")
  ((CodexAuthPlanTypeKnown (CodexAuthKnownPlanPro))))

!(assertEqualToResult
  (codex:auth-plan-type-from-raw-value "prolite")
  ((CodexAuthPlanTypeKnown (CodexAuthKnownPlanProLite))))

!(assertEqualToResult
  (codex:auth-plan-type-from-raw-value "self_serve_business_usage_based")
  ((CodexAuthPlanTypeKnown (CodexAuthKnownPlanSelfServeBusinessUsageBased))))

!(assertEqualToResult
  (codex:auth-plan-type-from-raw-value "enterprise_cbp_usage_based")
  ((CodexAuthPlanTypeKnown (CodexAuthKnownPlanEnterpriseCbpUsageBased))))

!(assertEqualToResult
  (codex:auth-plan-type-from-raw-value "hc")
  ((CodexAuthPlanTypeKnown (CodexAuthKnownPlanEnterprise))))

!(assertEqualToResult
  (codex:auth-plan-type-from-raw-value "education")
  ((CodexAuthPlanTypeKnown (CodexAuthKnownPlanEdu))))

!(assertEqualToResult
  (codex:auth-plan-type-from-raw-value "Mystery-Tier")
  ((CodexAuthPlanTypeUnknown "Mystery-Tier")))

!(assertEqualToResult
  (codex:auth-known-plan-display-name
    (codex:auth-known-plan-pro-lite))
  ("Pro Lite"))

!(assertEqualToResult
  (codex:auth-known-plan-display-name
    (codex:auth-known-plan-self-serve-business-usage-based))
  ("Self Serve Business Usage Based"))

!(assertEqualToResult
  (codex:auth-known-plan-display-name
    (codex:auth-known-plan-enterprise-cbp-usage-based))
  ("Enterprise CBP Usage Based"))

!(assertEqualToResult
  (codex:auth-known-plan-raw-value
    (codex:auth-known-plan-enterprise))
  ("enterprise"))

!(assertEqualToResult
  (codex:auth-plan-type-display-name
    (codex:auth-plan-type-known (codex:auth-known-plan-business)))
  ("Business"))

!(assertEqualToResult
  (codex:auth-plan-type-display-name
    (codex:auth-plan-type-unknown "legacy"))
  ("legacy"))

!(assertEqualToResult
  (codex:auth-plan-type-raw-value
    (codex:auth-plan-type-known (codex:auth-known-plan-pro-lite)))
  ("prolite"))

!(assertEqualToResult
  (codex:auth-known-plan-is-workspace-account
    (codex:auth-known-plan-team))
  (True))

!(assertEqualToResult
  (codex:auth-known-plan-is-workspace-account
    (codex:auth-known-plan-enterprise-cbp-usage-based))
  (True))

!(assertEqualToResult
  (codex:auth-known-plan-is-workspace-account
    (codex:auth-known-plan-pro))
  (False))

!(assertEqualToResult
  (codex:refresh-token-failed-error-reason
    (codex:refresh-token-failed-error
      (codex:refresh-token-failed-reason-revoked)
      "token revoked"))
  ((CodexRefreshTokenFailedReasonRevoked)))

!(assertEqualToResult
  (codex:refresh-token-failed-error-message
    (codex:refresh-token-failed-error
      (codex:refresh-token-failed-reason-exhausted)
      "token exhausted"))
  ("token exhausted"))
