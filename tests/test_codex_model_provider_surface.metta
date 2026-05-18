!(register-module! ../codex)
!(import! &self codex:account)
!(import! &self codex:auth_provider)
!(import! &self codex:error)
!(import! &self codex:login_auth)
!(import! &self codex:model_provider)
!(import! &self codex:model_provider_auth)
!(import! &self codex:model_provider_info)
!(import! &self codex:token_data)

(= (test:model-provider-command-config)
   (codex:model-provider-auth-info
     "print-token"
     ()
     5000
     300000
     "/repo"))

(= (test:model-provider-command-openai-info)
   (codex:model-provider-info-full
     (codex:openai-provider-name)
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     (test:model-provider-command-config)
     CodexAbsent
     (codex:wire-api-responses)
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     False
     True))

(= (test:model-provider-custom-info)
   (codex:model-provider-info-full
     "Custom"
     "http://localhost:1234/v1"
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     (codex:wire-api-responses)
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     False
     False))

(= (test:model-provider-experimental-token-info)
   (codex:model-provider-info-full
     "Custom"
     "http://localhost:1234/v1"
     CodexAbsent
     CodexAbsent
     "provider-token"
     CodexAbsent
     CodexAbsent
     (codex:wire-api-responses)
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     False
     False))

(= (test:model-provider-chatgpt-token-data)
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

(= (test:model-provider-missing-account-token-data)
   (codex:token-data
     (codex:id-token-info
       CodexAbsent
       CodexAbsent
       "chatgpt-user-123"
       "account-team"
       False
       "raw.jwt.sig")
     "chatgpt-access"
     "chatgpt-refresh"
     "account-team"))

(= (test:model-provider-chatgpt-auth)
   (codex:codex-auth-chatgpt
     (test:model-provider-chatgpt-token-data)))

(= (test:model-provider-openai-with-auth $auth)
   (codex:create-model-provider
     (codex:create-openai-provider CodexAbsent)
     (codex:auth-manager-from-auth-for-testing $auth)))

(= (test:model-provider-account-state-pair $provider)
   (let $state
     (codex:provider-account-state-result-value
       (codex:model-provider-account-state $provider))
     ((codex:provider-account-state-account $state)
      (codex:provider-account-state-requires-openai-auth $state))))

(= (test:model-provider-bedrock-with-aws $aws)
   (codex:create-model-provider
     (codex:create-amazon-bedrock-provider $aws)
     CodexAbsent))

(= (test:model-provider-bedrock-mantle-headers)
   (codex:headers-insert
     (codex:headers-insert
       ()
       (codex:amazon-bedrock-legacy-session-id-header)
       "019dae79-15c3-70c3-8736-3219b8602b37")
     "x-client-request-id"
     "request-id"))

!(assertEqualToResult
  (codex:auth-manager-has-external-auth
    (codex:model-provider-auth-manager
      (codex:create-model-provider
        (test:model-provider-command-openai-info)
        CodexAbsent)))
  (True))

!(assertEqualToResult
  (codex:model-provider-auth-manager
    (codex:create-model-provider
      (codex:create-amazon-bedrock-provider
        (codex:model-provider-aws-auth-info
          "codex-bedrock"
          CodexAbsent))
      (codex:auth-manager-from-auth-for-testing
        (codex:codex-auth-api-key "openai-api-key"))))
  (CodexAbsent))

!(assertEqualToResult
  (codex:model-provider-info-is-amazon-bedrock
    (codex:model-provider-runtime-info
      (codex:create-model-provider
        (codex:create-amazon-bedrock-provider CodexAbsent)
        CodexAbsent)))
  (True))

!(assertEqualToResult
  (test:model-provider-account-state-pair
    (codex:create-model-provider
      (codex:create-openai-provider CodexAbsent)
      CodexAbsent))
  ((CodexAbsent True)))

!(assertEqualToResult
  (test:model-provider-account-state-pair
    (test:model-provider-openai-with-auth
      (codex:codex-auth-api-key "openai-api-key")))
  (((CodexProviderAccountApiKey) True)))

!(assertEqualToResult
  (test:model-provider-account-state-pair
    (test:model-provider-openai-with-auth
      (test:model-provider-chatgpt-auth)))
  (((CodexProviderAccountChatgpt
       "team@example.com"
       (CodexPlanTypeTeam))
    True)))

!(assertEqualToResult
  (codex:provider-account-error-display
    (codex:provider-account-state-result-error
      (codex:model-provider-account-state
        (test:model-provider-openai-with-auth
          (codex:codex-auth-chatgpt
            (test:model-provider-missing-account-token-data))))))
  ("email and plan type are required for chatgpt authentication"))

!(assertEqualToResult
  (test:model-provider-account-state-pair
    (codex:create-model-provider
      (test:model-provider-custom-info)
      CodexAbsent))
  ((CodexAbsent False)))

!(assertEqualToResult
  (test:model-provider-account-state-pair
    (codex:create-model-provider
      (codex:create-amazon-bedrock-provider CodexAbsent)
      CodexAbsent))
  (((CodexProviderAccountAmazonBedrock) False)))

!(assertEqualToResult
  (codex:api-provider-base-url
    (codex:model-provider-to-api-provider-result-value
      (codex:model-provider-api-provider
        (test:model-provider-openai-with-auth
          (test:model-provider-chatgpt-auth)))))
  ("https://chatgpt.com/backend-api/codex"))

!(assertEqualToResult
  (codex:api-provider-base-url
    (codex:model-provider-to-api-provider-result-value
      (codex:model-provider-api-provider
        (codex:create-model-provider
          (codex:create-openai-provider CodexAbsent)
          CodexAbsent))))
  ("https://api.openai.com/v1"))

!(assertEqualToResult
  (codex:headers-get
    (codex:auth-provider-to-auth-headers
      (codex:model-provider-auth-resolve-value
        (codex:model-provider-api-auth
          (codex:create-model-provider
            (test:model-provider-experimental-token-info)
            (codex:auth-manager-from-auth-for-testing
              (test:model-provider-chatgpt-auth))))))
    "authorization")
  ("Bearer provider-token"))

!(assertEqualToResult
  (codex:amazon-bedrock-mantle-base-url-value
    (codex:amazon-bedrock-mantle-base-url "ap-northeast-1"))
  ("https://bedrock-mantle.ap-northeast-1.api.aws/v1"))

!(assertEqualToResult
  (codex:error-display
    (codex:amazon-bedrock-mantle-base-url-error
      (codex:amazon-bedrock-mantle-base-url "us-west-1")))
  ("Fatal error: Amazon Bedrock Mantle does not support region `us-west-1`"))

!(assertEqualToResult
  ((codex:aws-auth-config-profile
      (codex:amazon-bedrock-aws-auth-config
        (codex:model-provider-aws-auth-info
          "codex-bedrock"
          " us-west-2 ")))
   (codex:aws-auth-config-region
      (codex:amazon-bedrock-aws-auth-config
        (codex:model-provider-aws-auth-info
          "codex-bedrock"
          " us-west-2 ")))
   (codex:aws-auth-config-service
      (codex:amazon-bedrock-aws-auth-config
        (codex:model-provider-aws-auth-info
          "codex-bedrock"
          " us-west-2 "))))
  (("codex-bedrock" "us-west-2" "bedrock-mantle")))

!(assertEqualToResult
  (codex:api-provider-base-url
    (codex:model-provider-to-api-provider-result-value
      (codex:model-provider-api-provider-with-region
        (codex:create-model-provider
          (codex:create-amazon-bedrock-provider CodexAbsent)
          CodexAbsent)
        "eu-central-1")))
  ("https://bedrock-mantle.eu-central-1.api.aws/v1"))

!(assertEqualToResult
  (codex:api-provider-base-url
    (codex:model-provider-to-api-provider-result-value
      (codex:model-provider-api-provider
        (codex:create-model-provider
          (codex:create-amazon-bedrock-provider
            (codex:model-provider-aws-auth-info
              CodexAbsent
              " eu-west-1 "))
          CodexAbsent))))
  ("https://bedrock-mantle.eu-west-1.api.aws/v1"))

!(assertEqualToResult
  (codex:error-display
    (codex:model-provider-to-api-provider-result-error
      (codex:model-provider-api-provider-with-region
        (codex:create-model-provider
          (codex:create-amazon-bedrock-provider CodexAbsent)
          CodexAbsent)
        "us-west-1")))
  ("Fatal error: Amazon Bedrock Mantle does not support region `us-west-1`"))

!(assertEqualToResult
  ((codex:aws-bearer-token-bedrock-env-var)
   (codex:amazon-bedrock-bearer-token-from-env-value CodexAbsent)
   (codex:amazon-bedrock-bearer-token-from-env-value "   ")
   (codex:amazon-bedrock-bearer-token-from-env-value
     "  bedrock-api-key-test  "))
  (("AWS_BEARER_TOKEN_BEDROCK"
    CodexAbsent
    CodexAbsent
    "bedrock-api-key-test")))

!(assertEqualToResult
  (codex:amazon-bedrock-bearer-token-region-value
    (codex:amazon-bedrock-bearer-token-region-from-config
      (codex:model-provider-aws-auth-info
        "codex-bedrock"
        " us-west-2 ")))
  ("us-west-2"))

!(assertEqualToResult
  (codex:error-display
    (codex:amazon-bedrock-bearer-token-region-error
      (codex:amazon-bedrock-bearer-token-region-from-config
        (codex:model-provider-aws-auth-info
          CodexAbsent
          CodexAbsent))))
  ("Fatal error: Amazon Bedrock bearer token auth requires `model_providers.amazon-bedrock.aws.region`"))

!(assertEqualToResult
  ((codex:amazon-bedrock-auth-method-token
      (codex:amazon-bedrock-auth-method-value
        (codex:amazon-bedrock-resolve-auth-method-from-env-value
          (codex:model-provider-aws-auth-info
            CodexAbsent
            " us-west-2 ")
          "  bedrock-api-key-test  ")))
   (codex:amazon-bedrock-auth-method-region
      (codex:amazon-bedrock-auth-method-value
        (codex:amazon-bedrock-resolve-auth-method-from-env-value
          (codex:model-provider-aws-auth-info
            CodexAbsent
            " us-west-2 ")
          "  bedrock-api-key-test  "))))
  (("bedrock-api-key-test" "us-west-2")))

!(assertEqualToResult
  (codex:headers-get
    (codex:auth-provider-to-auth-headers
      (codex:model-provider-auth-resolve-value
        (codex:model-provider-api-auth-from-env-value
          (test:model-provider-bedrock-with-aws
            (codex:model-provider-aws-auth-info
              CodexAbsent
              " us-west-2 "))
          "  bedrock-api-key-test  ")))
    "authorization")
  ("Bearer bedrock-api-key-test"))

!(assertEqualToResult
  (codex:error-display
    (codex:model-provider-auth-resolve-error
      (codex:model-provider-api-auth-from-env-value
        (test:model-provider-bedrock-with-aws
          (codex:model-provider-aws-auth-info
            CodexAbsent
            CodexAbsent))
        "bedrock-api-key-test")))
  ("Fatal error: Amazon Bedrock bearer token auth requires `model_providers.amazon-bedrock.aws.region`"))

!(assertEqualToResult
  (codex:headers-get
    (codex:auth-provider-to-auth-headers
      (codex:model-provider-auth-resolve-value
        (codex:model-provider-api-auth
          (test:model-provider-bedrock-with-aws
            (codex:model-provider-aws-auth-info
              "codex-bedrock"
              CodexAbsent)))))
    "authorization")
  (CodexAbsent))

!(assertEqualToResult
  ((codex:headers-get
      (codex:amazon-bedrock-remove-headers-not-preserved-by-bedrock-mantle
        (test:model-provider-bedrock-mantle-headers))
      "session_id")
   (codex:headers-get
      (codex:amazon-bedrock-remove-headers-not-preserved-by-bedrock-mantle
        (test:model-provider-bedrock-mantle-headers))
      "x-client-request-id"))
  ((CodexAbsent "request-id")))
