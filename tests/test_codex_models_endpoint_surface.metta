!(register-module! ../codex)
!(import! &self codex:account)
!(import! &self codex:auth_provider)
!(import! &self codex:login_auth)
!(import! &self codex:model_provider)
!(import! &self codex:model_provider_info)
!(import! &self codex:models_endpoint)
!(import! &self codex:token_data)

(= (test:models-endpoint-command-config)
   (codex:model-provider-auth-info
     "print-token"
     ()
     5000
     300000
     "/repo"))

(= (test:models-endpoint-command-provider)
   (codex:model-provider-info-full
     (codex:openai-provider-name)
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     (test:models-endpoint-command-config)
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

(= (test:models-endpoint-provider-env-info)
   (codex:model-provider-info-full
     "Custom"
     "http://localhost:1234/v1"
     "PROVIDER_API_KEY"
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     (codex:wire-api-responses)
     CodexAbsent
     ((codex:model-provider-header "x-static" "static-value"))
     ((codex:model-provider-header "x-env" "MODEL_HEADER"))
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     False
     False))

(= (test:models-endpoint-env-values)
   ((codex:model-provider-env-value "OPENAI_API_KEY" "   ")
    (codex:model-provider-env-value "CODEX_API_KEY" "sk-codex")
    (codex:model-provider-env-value "PROVIDER_API_KEY" "sk-provider")
    (codex:model-provider-env-value
      "CODEX_REFRESH_TOKEN_URL_OVERRIDE"
      "https://auth.example/token")
    (codex:model-provider-env-value "MODEL_HEADER" "model-header-value")))

(= (test:models-endpoint-chatgpt-token-data)
   (codex:token-data
     (codex:id-token-info
       "user@example.com"
       (codex:auth-plan-type-known (codex:auth-known-plan-pro))
       "chatgpt-user-123"
       "account-pro"
       False
       "raw.jwt.sig")
     "chatgpt-access"
     "chatgpt-refresh"
     "account-pro"))

(= (test:models-endpoint-chatgpt-auth)
   (codex:codex-auth-chatgpt
     (test:models-endpoint-chatgpt-token-data)))

(= (test:models-endpoint-provider-env-request-plan)
   (codex:openai-models-endpoint-request-plan-value
     (codex:openai-models-endpoint-request-plan-from-env-values
       (codex:openai-models-endpoint
         (test:models-endpoint-provider-env-info)
         CodexAbsent)
       "0.124.0"
       "sk-provider"
       (test:models-endpoint-env-values)
       True)))

(= (test:models-endpoint-chatgpt-request-plan)
   (codex:openai-models-endpoint-request-plan-value
     (codex:openai-models-endpoint-request-plan-from-env-values
       (codex:openai-models-endpoint
         (codex:create-openai-provider CodexAbsent)
         (codex:auth-manager-from-auth-for-testing
           (test:models-endpoint-chatgpt-auth)))
       "0.124.0"
       CodexAbsent
       ()
       False)))

(= (test:request-plan-fields
      (CodexOpenAiModelsEndpointRequestPlan
        $client-version
        $endpoint
        $timeout-ms
        $api-provider
        $api-auth
        $request-telemetry))
   ($client-version
    $endpoint
    $timeout-ms
    (codex:api-provider-base-url $api-provider)
    (codex:model-provider-headers-get
      (codex:api-provider-headers $api-provider)
      "x-env")
    (codex:headers-get
      (codex:auth-provider-to-auth-headers $api-auth)
      "authorization")))

(= (test:telemetry-fields
      (CodexModelsRequestTelemetry
        $auth-mode
        $auth-header-attached
        $auth-header-name
        $auth-env))
   ($auth-mode
    $auth-header-attached
    $auth-header-name
    (codex:auth-env-telemetry-codex-api-key-env-enabled $auth-env)))

(= (test:chatgpt-request-plan-fields
      (CodexOpenAiModelsEndpointRequestPlan
        $client-version
        $endpoint
        $timeout-ms
        $api-provider
        $api-auth
        $request-telemetry))
   ((codex:api-provider-base-url $api-provider)
    (codex:models-request-telemetry-auth-mode $request-telemetry)
    (codex:headers-get
      (codex:auth-provider-to-auth-headers $api-auth)
      "authorization")))

!(assertEqualToResult
  ((codex:models-refresh-timeout-ms)
   (codex:models-endpoint-path))
  ((5000 "/models")))

!(assertEqualToResult
  ((codex:openai-models-endpoint-has-command-auth
      (codex:openai-models-endpoint
        (test:models-endpoint-command-provider)
        CodexAbsent))
   (codex:openai-models-endpoint-has-command-auth
      (codex:openai-models-endpoint
        (codex:create-openai-provider CodexAbsent)
        CodexAbsent)))
  ((True False)))

!(assertEqualToResult
  ((codex:openai-models-endpoint-uses-codex-backend
      (codex:openai-models-endpoint
        (codex:create-openai-provider CodexAbsent)
        CodexAbsent))
   (codex:openai-models-endpoint-uses-codex-backend
      (codex:openai-models-endpoint
        (codex:create-openai-provider CodexAbsent)
        (codex:auth-manager-from-auth-for-testing
          (codex:codex-auth-api-key "sk-openai"))))
   (codex:openai-models-endpoint-uses-codex-backend
      (codex:openai-models-endpoint
        (codex:create-openai-provider CodexAbsent)
        (codex:auth-manager-from-auth-for-testing
          (test:models-endpoint-chatgpt-auth)))))
  ((False False True)))

!(assertEqualToResult
  (codex:openai-models-endpoint-auth-env-from-env-values
    (codex:openai-models-endpoint
      (test:models-endpoint-provider-env-info)
      CodexAbsent)
    False
    (test:models-endpoint-env-values))
  ((CodexAuthEnvTelemetry
     False
     True
     False
     "configured"
     True
     True)))

!(assertEqualToResult
  (test:request-plan-fields
    (test:models-endpoint-provider-env-request-plan))
  (("0.124.0"
    "/models"
    5000
    "http://localhost:1234/v1"
    "model-header-value"
    "Bearer sk-provider")))

!(assertEqualToResult
  (test:telemetry-fields
    (codex:openai-models-endpoint-request-plan-telemetry
      (test:models-endpoint-provider-env-request-plan)))
  ((CodexAbsent True "authorization" True)))

!(assertEqualToResult
  (test:chatgpt-request-plan-fields
    (test:models-endpoint-chatgpt-request-plan))
  (("https://chatgpt.com/backend-api/codex"
    (CodexAuthModeChatgpt)
    "Bearer chatgpt-access")))
