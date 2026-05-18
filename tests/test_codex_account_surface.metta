!(register-module! ../codex)
!(import! &self codex:account)

!(assertEqualToResult
  (codex:plan-type-wire-name
    (codex:plan-type-self-serve-business-usage-based))
  ("self_serve_business_usage_based"))

!(assertEqualToResult
  (codex:plan-type-wire-name
    (codex:plan-type-enterprise-cbp-usage-based))
  ("enterprise_cbp_usage_based"))

!(assertEqualToResult
  (codex:plan-type-wire-name (codex:plan-type-pro-lite))
  ("prolite"))

!(assertEqualToResult
  (codex:plan-type-from-wire-name "self_serve_business_usage_based")
  ((CodexPlanTypeSelfServeBusinessUsageBased)))

!(assertEqualToResult
  (codex:plan-type-from-wire-name "prolite")
  ((CodexPlanTypeProLite)))

!(assertEqualToResult
  (codex:plan-type-from-wire-name "enterprise_cbp_usage_based")
  ((CodexPlanTypeEnterpriseCbpUsageBased)))

!(assertEqualToResult
  (codex:plan-type-from-wire-name "unexpected")
  ((CodexPlanTypeUnknown)))

!(assertEqualToResult
  (codex:plan-type-is-team-like (codex:plan-type-team))
  (True))

!(assertEqualToResult
  (codex:plan-type-is-team-like
    (codex:plan-type-self-serve-business-usage-based))
  (True))

!(assertEqualToResult
  (codex:plan-type-is-team-like (codex:plan-type-business))
  (False))

!(assertEqualToResult
  (codex:plan-type-is-business-like (codex:plan-type-business))
  (True))

!(assertEqualToResult
  (codex:plan-type-is-business-like
    (codex:plan-type-enterprise-cbp-usage-based))
  (True))

!(assertEqualToResult
  (codex:plan-type-is-business-like (codex:plan-type-team))
  (False))

!(assertEqualToResult
  (codex:plan-type-is-workspace-account (codex:plan-type-enterprise))
  (True))

!(assertEqualToResult
  (codex:plan-type-is-workspace-account (codex:plan-type-edu))
  (True))

!(assertEqualToResult
  (codex:plan-type-is-workspace-account (codex:plan-type-pro))
  (False))

!(assertEqualToResult
  (codex:provider-account-api-key)
  ((CodexProviderAccountApiKey)))

!(assertEqualToResult
  (codex:provider-account-amazon-bedrock)
  ((CodexProviderAccountAmazonBedrock)))

!(assertEqualToResult
  (codex:provider-account-chatgpt
    "zar@example.com"
    (codex:plan-type-pro))
  ((CodexProviderAccountChatgpt "zar@example.com" (CodexPlanTypePro))))

!(assertEqualToResult
  (codex:provider-account-chatgpt-email
    (codex:provider-account-chatgpt
      "zar@example.com"
      (codex:plan-type-pro-lite)))
  ("zar@example.com"))

!(assertEqualToResult
  (codex:provider-account-chatgpt-plan-type
    (codex:provider-account-chatgpt
      "zar@example.com"
      (codex:plan-type-pro-lite)))
  ((CodexPlanTypeProLite)))
