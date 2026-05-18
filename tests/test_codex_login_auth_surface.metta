!(register-module! ../codex)
!(import! &self codex:account)
!(import! &self codex:auth)
!(import! &self codex:login_auth)
!(import! &self codex:token_data)

(= (codex-login-auth-team-token-data)
   (codex:token-data
     (codex:id-token-info
       "team@example.com"
       (codex:auth-plan-type-known (codex:auth-known-plan-team))
       "chatgpt-user-123"
       "account-team"
       True
       "raw.jwt.sig")
     "chatgpt-access"
     "chatgpt-refresh"
     "account-team"))

(= (codex-login-auth-unknown-token-data)
   (codex:token-data
     (codex:id-token-info
       "unknown@example.com"
       (codex:auth-plan-type-unknown "legacy")
       "chatgpt-user-unknown"
       "account-unknown"
       False
       "raw.jwt.sig")
     "unknown-access"
     "unknown-refresh"
     "account-unknown"))

(= (codex-login-auth-absent-plan-token-data)
   (codex:token-data
     (codex:id-token-info
       CodexAbsent
       CodexAbsent
       CodexAbsent
       CodexAbsent
       False
       "raw.jwt.sig")
     "absent-access"
     "absent-refresh"
     CodexAbsent))

(= (codex-login-auth-api-key)
   (codex:codex-auth-api-key "sk-test"))

(= (codex-login-auth-chatgpt)
   (codex:codex-auth-chatgpt
     (codex-login-auth-team-token-data)))

(= (codex-login-auth-external-chatgpt)
   (codex:codex-auth-chatgpt-auth-tokens
     (codex-login-auth-team-token-data)))

!(assertEqualToResult
  (codex:codex-auth-auth-mode (codex-login-auth-api-key))
  ((CodexAuthModeApiKey)))

!(assertEqualToResult
  (codex:codex-auth-auth-mode (codex-login-auth-chatgpt))
  ((CodexAuthModeChatgpt)))

!(assertEqualToResult
  (codex:codex-auth-auth-mode (codex-login-auth-external-chatgpt))
  ((CodexAuthModeChatgpt)))

!(assertEqualToResult
  (codex:codex-auth-api-auth-mode (codex-login-auth-external-chatgpt))
  ((CodexAuthModeChatgptAuthTokens)))

!(assertEqualToResult
  (codex:codex-auth-eq
    (codex-login-auth-api-key)
    (codex:codex-auth-api-key "different-key"))
  (True))

!(assertEqualToResult
  (codex:codex-auth-eq
    (codex-login-auth-chatgpt)
    (codex-login-auth-external-chatgpt))
  (False))

!(assertEqualToResult
  ((codex:codex-auth-is-api-key-auth (codex-login-auth-api-key))
   (codex:codex-auth-is-api-key-auth (codex-login-auth-chatgpt))
   (codex:codex-auth-is-chatgpt-auth (codex-login-auth-chatgpt))
   (codex:codex-auth-is-chatgpt-auth (codex-login-auth-external-chatgpt))
   (codex:codex-auth-uses-codex-backend (codex-login-auth-api-key))
   (codex:codex-auth-uses-codex-backend (codex-login-auth-chatgpt))
   (codex:codex-auth-is-external-chatgpt-tokens
     (codex-login-auth-external-chatgpt)))
  ((True False True True False True True)))

!(assertEqualToResult
  (codex:codex-auth-api-key-option (codex-login-auth-api-key))
  ("sk-test"))

!(assertEqualToResult
  (codex:codex-auth-api-key-option (codex-login-auth-chatgpt))
  (CodexAbsent))

!(assertEqualToResult
  ((codex:codex-auth-get-account-id (codex-login-auth-chatgpt))
   (codex:codex-auth-get-account-email (codex-login-auth-chatgpt))
   (codex:codex-auth-get-chatgpt-user-id (codex-login-auth-chatgpt))
   (codex:codex-auth-is-fedramp-account (codex-login-auth-chatgpt)))
  (("account-team" "team@example.com" "chatgpt-user-123" True)))

!(assertEqualToResult
  (codex:codex-auth-account-plan-type (codex-login-auth-chatgpt))
  ((CodexPlanTypeTeam)))

!(assertEqualToResult
  (codex:codex-auth-is-workspace-account (codex-login-auth-chatgpt))
  (True))

!(assertEqualToResult
  (codex:codex-auth-account-plan-type
    (codex:codex-auth-chatgpt
      (codex-login-auth-unknown-token-data)))
  ((CodexPlanTypeUnknown)))

!(assertEqualToResult
  (codex:codex-auth-account-plan-type
    (codex:codex-auth-chatgpt
      (codex-login-auth-absent-plan-token-data)))
  ((CodexPlanTypeUnknown)))

!(assertEqualToResult
  (codex:codex-auth-account-plan-type (codex-login-auth-api-key))
  (CodexAbsent))

!(assertEqualToResult
  (codex:codex-auth-is-workspace-account (codex-login-auth-api-key))
  (False))
