!(register-module! ../codex)
!(import! &self codex:auth)
!(import! &self codex:auth_provider)
!(import! &self codex:error)
!(import! &self codex:login_auth)
!(import! &self codex:model_provider_auth)
!(import! &self codex:model_provider_info)
!(import! &self codex:token_data)

(= (codex-model-provider-auth-default-provider)
   (codex:default-model-provider-info))

(= (codex-model-provider-auth-env-provider)
   (codex:model-provider-info
     "CETTA_CODEX_TEST_PROVIDER_API_KEY"
     "Set CETTA_CODEX_TEST_PROVIDER_API_KEY."
     CodexAbsent
     CodexAbsent))

(= (codex-model-provider-auth-experimental-provider)
   (codex:model-provider-info
     CodexAbsent
     CodexAbsent
     "experimental-token"
     CodexAbsent))

(= (codex-model-provider-auth-env-and-experimental-provider)
   (codex:model-provider-info
     "CETTA_CODEX_TEST_PROVIDER_API_KEY"
     "Set CETTA_CODEX_TEST_PROVIDER_API_KEY."
     "experimental-token"
     CodexAbsent))

(= (codex-model-provider-auth-command-config)
   (codex:model-provider-auth-info
     "print-token"
     ()
     5000
     300000
     "/repo"))

(= (codex-model-provider-auth-command-provider)
   (codex:model-provider-info
     CodexAbsent
     CodexAbsent
     CodexAbsent
     (codex-model-provider-auth-command-config)))

(= (codex-model-provider-auth-token-data)
   (codex:token-data
     (codex:id-token-info
       "user@example.com"
       (codex:auth-plan-type-known (codex:auth-known-plan-enterprise))
       "user-123"
       "workspace-123"
       True
       "raw.jwt.sig")
     "chatgpt-token"
     "refresh-token"
     "workspace-123"))

!(assertEqualToResult
  (codex:model-provider-api-key-result-value
    (codex:model-provider-api-key-from-env-value
      (codex-model-provider-auth-default-provider)
      CodexAbsent))
  (CodexAbsent))

!(assertEqualToResult
  (codex:error-display
    (codex:model-provider-api-key-result-error
      (codex:model-provider-api-key-from-env-value
        (codex-model-provider-auth-env-provider)
        CodexAbsent)))
  ("Missing environment variable: `CETTA_CODEX_TEST_PROVIDER_API_KEY`. Set CETTA_CODEX_TEST_PROVIDER_API_KEY."))

!(assertEqualToResult
  (codex:error-display
    (codex:error-env-var
      (codex:env-var-error "CETTA_CODEX_TEST_NO_INSTRUCTIONS" CodexAbsent)))
  ("Missing environment variable: `CETTA_CODEX_TEST_NO_INSTRUCTIONS`."))

!(assertEqualToResult
  (codex:error-display
    (codex:model-provider-api-key-result-error
      (codex:model-provider-api-key-from-env-value
        (codex-model-provider-auth-env-provider)
        "   ")))
  ("Missing environment variable: `CETTA_CODEX_TEST_PROVIDER_API_KEY`. Set CETTA_CODEX_TEST_PROVIDER_API_KEY."))

!(assertEqualToResult
  (codex:model-provider-api-key-result-value
    (codex:model-provider-api-key-from-env-value
      (codex-model-provider-auth-env-provider)
      "  env-token  "))
  ("  env-token  "))

!(assertEqualToResult
  (codex:headers-get
    (codex:auth-provider-to-auth-headers
      (codex:model-provider-auth-resolve-value
        (codex:bearer-auth-for-provider
          (codex-model-provider-auth-experimental-provider))))
    "authorization")
  ("Bearer experimental-token"))

!(assertEqualToResult
  (codex:headers-get
    (codex:auth-provider-to-auth-headers
      (codex:model-provider-auth-resolve-value
        (codex:bearer-auth-for-provider-from-env-value
          (codex-model-provider-auth-env-and-experimental-provider)
          "env-token")))
    "authorization")
  ("Bearer env-token"))

!(assertEqualToResult
  (codex:headers-get
    (codex:auth-provider-to-auth-headers
      (codex:model-provider-auth-resolve-value
        (codex:resolve-provider-auth
          (codex:codex-auth-api-key "sk-cached")
          (codex-model-provider-auth-default-provider))))
    "authorization")
  ("Bearer sk-cached"))

!(assertEqualToResult
  (codex:headers-get
    (codex:auth-provider-to-auth-headers
      (codex:model-provider-auth-resolve-value
        (codex:resolve-provider-auth
          (codex:codex-auth-chatgpt
            (codex-model-provider-auth-token-data))
          (codex-model-provider-auth-default-provider))))
    "ChatGPT-Account-ID")
  ("workspace-123"))

!(assertEqualToResult
  (codex:headers-get
    (codex:auth-provider-to-auth-headers
      (codex:model-provider-auth-resolve-value
        (codex:resolve-provider-auth
          (codex:codex-auth-chatgpt
            (codex-model-provider-auth-token-data))
          (codex-model-provider-auth-default-provider))))
    "X-OpenAI-Fedramp")
  ("true"))

!(assertEqualToResult
  (codex:auth-provider-to-auth-headers
    (codex:model-provider-auth-resolve-value
      (codex:resolve-provider-auth
        CodexAbsent
        (codex-model-provider-auth-default-provider))))
  (()))

!(assertEqualToResult
  (codex:model-provider-auth-resolve-error
    (codex:resolve-provider-auth-from-env-value
      CodexAbsent
      (codex-model-provider-auth-env-provider)
      CodexAbsent))
  ((CodexErrEnvVar
     (CodexEnvVarError
       "CETTA_CODEX_TEST_PROVIDER_API_KEY"
       "Set CETTA_CODEX_TEST_PROVIDER_API_KEY."))))

!(assertEqualToResult
  (codex:auth-manager-for-provider
    (CodexBaseAuthManager)
    (codex-model-provider-auth-default-provider))
  ((CodexBaseAuthManager)))

!(assertEqualToResult
  (codex:auth-manager-for-provider
    (CodexBaseAuthManager)
    (codex-model-provider-auth-command-provider))
  ((CodexAuthManagerExternalBearerOnly
     (CodexBearerTokenRefresher
       (CodexModelProviderAuthInfo
         "print-token"
         ()
         5000
         300000
         "/repo")
       CodexAbsent))))
