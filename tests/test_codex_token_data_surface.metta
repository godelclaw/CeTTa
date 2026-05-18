!(register-module! ../codex)
!(import! &self codex:auth)
!(import! &self codex:token_data)

(= (codex-token-data-pro-info)
   (codex:id-token-info
     "user@example.com"
     (codex:auth-plan-type-known (codex:auth-known-plan-pro))
     "user-123"
     CodexAbsent
     False
     "raw.jwt.sig"))

(= (codex-token-data-self-serve-business-info)
   (codex:id-token-info
     "user@example.com"
     (codex:auth-plan-type-known
       (codex:auth-known-plan-self-serve-business-usage-based))
     CodexAbsent
     "account-business"
     False
     "raw.jwt.sig"))

(= (codex-token-data-enterprise-cbp-info)
   (codex:id-token-info
     "user@example.com"
     (codex:auth-plan-type-known
       (codex:auth-known-plan-enterprise-cbp-usage-based))
     CodexAbsent
     "account-enterprise"
     True
     "raw.jwt.sig"))

(= (codex-token-data-unknown-info)
   (codex:id-token-info
     CodexAbsent
     (codex:auth-plan-type-unknown "legacy-tier")
     CodexAbsent
     CodexAbsent
     False
     "raw.jwt.sig"))

!(assertEqualToResult
  (codex:id-token-info-email (codex-token-data-pro-info))
  ("user@example.com"))

!(assertEqualToResult
  (codex:id-token-info-get-chatgpt-plan-type
    (codex-token-data-pro-info))
  ("Pro"))

!(assertEqualToResult
  (codex:id-token-info-get-chatgpt-plan-type-raw
    (codex-token-data-pro-info))
  ("pro"))

!(assertEqualToResult
  (codex:id-token-info-is-workspace-account
    (codex-token-data-pro-info))
  (False))

!(assertEqualToResult
  (codex:id-token-info-get-chatgpt-plan-type
    (codex-token-data-self-serve-business-info))
  ("Self Serve Business Usage Based"))

!(assertEqualToResult
  (codex:id-token-info-get-chatgpt-plan-type-raw
    (codex-token-data-self-serve-business-info))
  ("self_serve_business_usage_based"))

!(assertEqualToResult
  (codex:id-token-info-is-workspace-account
    (codex-token-data-self-serve-business-info))
  (True))

!(assertEqualToResult
  (codex:id-token-info-get-chatgpt-plan-type
    (codex-token-data-enterprise-cbp-info))
  ("Enterprise CBP Usage Based"))

!(assertEqualToResult
  (codex:id-token-info-get-chatgpt-plan-type-raw
    (codex-token-data-enterprise-cbp-info))
  ("enterprise_cbp_usage_based"))

!(assertEqualToResult
  (codex:id-token-info-is-workspace-account
    (codex-token-data-enterprise-cbp-info))
  (True))

!(assertEqualToResult
  (codex:id-token-info-chatgpt-account-id
    (codex-token-data-enterprise-cbp-info))
  ("account-enterprise"))

!(assertEqualToResult
  (codex:id-token-info-is-fedramp-account
    (codex-token-data-enterprise-cbp-info))
  (True))

!(assertEqualToResult
  (codex:id-token-info-get-chatgpt-plan-type
    (codex-token-data-unknown-info))
  ("legacy-tier"))

!(assertEqualToResult
  (codex:id-token-info-get-chatgpt-plan-type-raw
    (codex-token-data-unknown-info))
  ("legacy-tier"))

!(assertEqualToResult
  (codex:id-token-info-is-workspace-account
    (codex-token-data-unknown-info))
  (False))

!(assertEqualToResult
  (codex:id-token-info-get-chatgpt-plan-type
    (codex:default-id-token-info))
  (CodexAbsent))

!(assertEqualToResult
  (codex:id-token-info-is-fedramp-account
    (codex:default-id-token-info))
  (False))

!(assertEqualToResult
  (codex:token-data-access-token
    (codex:token-data
      (codex-token-data-pro-info)
      "access-token"
      "refresh-token"
      "account-123"))
  ("access-token"))

!(assertEqualToResult
  (codex:token-data-account-id
    (codex:token-data
      (codex-token-data-pro-info)
      "access-token"
      "refresh-token"
      "account-123"))
  ("account-123"))
