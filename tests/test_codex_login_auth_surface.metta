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

(= (codex-login-auth-agent-record)
   (codex:agent-identity-auth-record
     "agent-runtime-1"
     "private-key"
     "agent-account"
     "agent-user"
     "agent@example.com"
     (codex:plan-type-enterprise)
     True))

(= (codex-login-auth-agent)
   (codex:agent-identity-auth
     (codex-login-auth-agent-record)))

(= (codex-login-auth-agent-initialized)
   (codex:agent-identity-auth-with-runtime
     (codex-login-auth-agent-record)
     "task-123"
     "Bearer signed-agent-token"))

(= (codex-login-auth-agent-codex-auth)
   (codex:codex-auth-agent-identity
     (codex-login-auth-agent)))

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
  (codex:codex-auth-auth-mode (codex-login-auth-agent-codex-auth))
  ((CodexAuthModeAgentIdentity)))

!(assertEqualToResult
  (codex:codex-auth-api-auth-mode (codex-login-auth-agent-codex-auth))
  ((CodexAuthModeAgentIdentity)))

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
  (codex:codex-auth-eq
    (codex-login-auth-agent-codex-auth)
    (codex:codex-auth-agent-identity
      (codex:agent-identity-auth
        (codex:agent-identity-auth-record
          "agent-runtime-2"
          "different-key"
          "other-account"
          "other-user"
          "other@example.com"
          (codex:plan-type-pro)
          False))))
  (True))

!(assertEqualToResult
  ((codex:codex-auth-is-api-key-auth (codex-login-auth-api-key))
   (codex:codex-auth-is-api-key-auth (codex-login-auth-chatgpt))
   (codex:codex-auth-is-chatgpt-auth (codex-login-auth-chatgpt))
   (codex:codex-auth-is-chatgpt-auth (codex-login-auth-external-chatgpt))
   (codex:codex-auth-uses-codex-backend (codex-login-auth-api-key))
   (codex:codex-auth-uses-codex-backend (codex-login-auth-chatgpt))
   (codex:codex-auth-is-external-chatgpt-tokens
     (codex-login-auth-external-chatgpt))
   (codex:codex-auth-is-chatgpt-auth (codex-login-auth-agent-codex-auth))
   (codex:codex-auth-uses-codex-backend
     (codex-login-auth-agent-codex-auth)))
  ((True False True True False True True False True)))

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

!(assertEqualToResult
  ((codex:agent-identity-auth-record-agent-runtime-id
     (codex-login-auth-agent-record))
   (codex:agent-identity-auth-record-agent-private-key
     (codex-login-auth-agent-record))
   (codex:agent-identity-auth-record-account-id
     (codex-login-auth-agent-record))
   (codex:agent-identity-auth-record-chatgpt-user-id
     (codex-login-auth-agent-record))
   (codex:agent-identity-auth-record-email
     (codex-login-auth-agent-record))
   (codex:agent-identity-auth-record-plan-type
     (codex-login-auth-agent-record))
   (codex:agent-identity-auth-record-is-fedramp-account
     (codex-login-auth-agent-record)))
  (("agent-runtime-1"
    "private-key"
    "agent-account"
    "agent-user"
    "agent@example.com"
    (CodexPlanTypeEnterprise)
    True)))

!(assertEqualToResult
  ((codex:codex-auth-get-account-id (codex-login-auth-agent-codex-auth))
   (codex:codex-auth-get-account-email (codex-login-auth-agent-codex-auth))
   (codex:codex-auth-get-chatgpt-user-id
     (codex-login-auth-agent-codex-auth))
   (codex:codex-auth-account-plan-type (codex-login-auth-agent-codex-auth))
   (codex:codex-auth-is-fedramp-account (codex-login-auth-agent-codex-auth))
   (codex:codex-auth-is-workspace-account
     (codex-login-auth-agent-codex-auth)))
  (("agent-account"
    "agent@example.com"
    "agent-user"
    (CodexPlanTypeEnterprise)
    True
    True)))

!(assertEqualToResult
  (codex:codex-auth-token-result-message
    (codex:codex-auth-get-token
      (codex-login-auth-agent-codex-auth)))
  ("agent identity auth does not expose a bearer token"))

!(assertEqualToResult
  ((codex:headers-get
      (codex:auth-provider-to-auth-headers
        (codex:auth-provider-from-auth
          (codex-login-auth-agent-codex-auth)))
      "authorization")
   (codex:headers-get
      (codex:auth-provider-to-auth-headers
        (codex:auth-provider-from-auth
          (codex-login-auth-agent-codex-auth)))
      "ChatGPT-Account-ID")
   (codex:headers-get
      (codex:auth-provider-to-auth-headers
        (codex:auth-provider-from-auth
          (codex-login-auth-agent-codex-auth)))
      "X-OpenAI-Fedramp"))
  ((CodexAbsent "agent-account" "true")))

!(assertEqualToResult
  ((codex:headers-get
      (codex:auth-provider-to-auth-headers
        (codex:agent-identity-auth-provider
          (codex-login-auth-agent-initialized)))
      "authorization")
   (codex:headers-get
      (codex:auth-provider-to-auth-headers
        (codex:agent-identity-auth-provider
          (codex-login-auth-agent-initialized)))
      "ChatGPT-Account-ID"))
  (("Bearer signed-agent-token" "agent-account")))
