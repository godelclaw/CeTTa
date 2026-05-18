!(register-module! ../codex)
!(import! &self codex:model_provider_info)
!(import! &self list)

(= (test:model-provider-auth-config)
   (codex:model-provider-auth-info
     "print-token"
     ()
     5000
     300000
     "/repo"))

(= (test:model-provider-info-custom
      $env-key
      $experimental-bearer-token
      $auth
      $aws
      $request-max-retries
      $stream-max-retries
      $stream-idle-timeout-ms
      $websocket-connect-timeout-ms
      $requires-openai-auth
      $supports-websockets)
   (codex:model-provider-info-full
     "Custom"
     "https://provider.example/v1"
     $env-key
     CodexAbsent
     $experimental-bearer-token
     $auth
     $aws
     (codex:wire-api-responses)
     CodexAbsent
     CodexAbsent
     CodexAbsent
     $request-max-retries
     $stream-max-retries
     $stream-idle-timeout-ms
     $websocket-connect-timeout-ms
     $requires-openai-auth
     $supports-websockets))

(= (test:model-provider-custom-provider)
   (codex:model-provider-info-full
     "Custom"
     "https://example.com/v1"
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

(= (test:model-provider-custom-openai-provider)
   (codex:model-provider-info-full
     "Custom OpenAI"
     "https://override.example/v1"
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

(= (test:model-provider-named-provider $name $base-url)
   (codex:model-provider-info-full
     $name
     $base-url
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

(= (test:model-provider-api-shape-provider
      $base-url
      $query-params
      $http-headers
      $env-http-headers
      $request-max-retries
      $stream-idle-timeout-ms)
   (codex:model-provider-info-full
     "API Shape"
     $base-url
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     (codex:wire-api-responses)
     $query-params
     $http-headers
     $env-http-headers
     $request-max-retries
     CodexAbsent
     $stream-idle-timeout-ms
     CodexAbsent
     False
     False))

(= (test:model-provider-to-api-provider
      $provider
      $auth-mode
      $env-values)
   (codex:model-provider-to-api-provider-result-value
     (codex:model-provider-info-to-api-provider-from-env-values
       $provider
       $auth-mode
       $env-values)))

!(assertEqualToResult
  (codex:wire-api-display (codex:wire-api-responses))
  ("responses"))

!(assertEqualToResult
  (codex:wire-api-display
    (codex:wire-api-parse-value
      (codex:wire-api-from-string "responses")))
  ("responses"))

!(assertEqualToResult
  (codex:wire-api-parse-error
    (codex:wire-api-from-string "chat"))
  ("`wire_api = \"chat\"` is no longer supported.\nHow to fix: set `wire_api = \"responses\"` in your provider config.\nMore info: https://github.com/openai/codex/discussions/7782"))

!(assertEqualToResult
  ((codex:model-provider-info-name
      (codex:create-openai-provider CodexAbsent))
   (codex:model-provider-info-base-url
      (codex:create-openai-provider CodexAbsent))
   (codex:model-provider-info-requires-openai-auth
      (codex:create-openai-provider CodexAbsent))
   (codex:model-provider-info-supports-websockets
      (codex:create-openai-provider CodexAbsent)))
  (("OpenAI" CodexAbsent True True)))

!(assertEqualToResult
  (codex:model-provider-header-name
    (list:at
      (codex:model-provider-info-http-headers
        (codex:create-openai-provider CodexAbsent))
      0))
  ("version"))

!(assertEqualToResult
  (codex:model-provider-header-value
    (list:at
      (codex:model-provider-info-http-headers
        (codex:create-openai-provider CodexAbsent))
      0))
  ("0.124.0"))

!(assertEqualToResult
  ((codex:model-provider-info-name
      (codex:create-amazon-bedrock-provider CodexAbsent))
   (codex:model-provider-info-base-url
      (codex:create-amazon-bedrock-provider CodexAbsent))
   (codex:model-provider-info-is-amazon-bedrock
      (codex:create-amazon-bedrock-provider CodexAbsent))
   (codex:model-provider-aws-auth-info-profile
      (codex:model-provider-info-aws
        (codex:create-amazon-bedrock-provider CodexAbsent))))
  (("Amazon Bedrock" "https://bedrock-mantle.us-east-1.api.aws/v1" True CodexAbsent)))

!(assertEqualToResult
  ((codex:model-provider-info-name
      (codex:create-oss-provider-with-base-url
        "http://localhost:11434/v1"
        (codex:wire-api-responses)))
   (codex:model-provider-info-base-url
      (codex:create-oss-provider-with-base-url
        "http://localhost:11434/v1"
        (codex:wire-api-responses)))
   (codex:model-provider-info-supports-websockets
      (codex:create-oss-provider-with-base-url
        "http://localhost:11434/v1"
        (codex:wire-api-responses))))
  (("gpt-oss" "http://localhost:11434/v1" False)))

!(assertEqualToResult
  (codex:model-provider-info-base-url
    (codex:create-oss-provider-with-port
      (codex:default-ollama-port)
      (codex:wire-api-responses)))
  ("http://localhost:11434/v1"))

!(assertEqualToResult
  ((codex:model-provider-info-request-max-retries
      (codex:default-model-provider-info))
   (codex:model-provider-info-stream-max-retries
      (codex:default-model-provider-info))
   (codex:model-provider-info-effective-stream-idle-timeout-ms
      (codex:default-model-provider-info))
   (codex:model-provider-info-effective-websocket-connect-timeout-ms
      (codex:default-model-provider-info)))
  ((4 5 300000 15000)))

!(assertEqualToResult
  ((codex:api-provider-base-url
      (test:model-provider-to-api-provider
        (test:model-provider-api-shape-provider
          CodexAbsent
          CodexAbsent
          CodexAbsent
          CodexAbsent
          CodexAbsent
          CodexAbsent)
        CodexAbsent
        ()))
   (codex:api-provider-base-url
      (test:model-provider-to-api-provider
        (test:model-provider-api-shape-provider
          CodexAbsent
          CodexAbsent
          CodexAbsent
          CodexAbsent
          CodexAbsent
          CodexAbsent)
        (CodexAuthModeChatgpt)
        ()))
   (codex:api-provider-base-url
      (test:model-provider-to-api-provider
        (test:model-provider-api-shape-provider
          CodexAbsent
          CodexAbsent
          CodexAbsent
          CodexAbsent
          CodexAbsent
          CodexAbsent)
        (CodexAuthModeChatgptAuthTokens)
        ()))
   (codex:api-provider-base-url
      (test:model-provider-to-api-provider
        (test:model-provider-api-shape-provider
          CodexAbsent
          CodexAbsent
          CodexAbsent
          CodexAbsent
          CodexAbsent
          CodexAbsent)
        (CodexAuthModeAgentIdentity)
        ()))
   (codex:api-provider-base-url
      (test:model-provider-to-api-provider
        (test:model-provider-api-shape-provider
          "https://custom.example/v1"
          CodexAbsent
          CodexAbsent
          CodexAbsent
          CodexAbsent
          CodexAbsent)
        (CodexAuthModeChatgpt)
        ())))
  (("https://api.openai.com/v1"
    "https://chatgpt.com/backend-api/codex"
    "https://chatgpt.com/backend-api/codex"
    "https://chatgpt.com/backend-api/codex"
    "https://custom.example/v1")))

!(assertEqualToResult
  (let $api-provider
    (test:model-provider-to-api-provider
      (test:model-provider-api-shape-provider
        CodexAbsent
        ((codex:model-provider-header "api-version" "2025-04-01-preview"))
        CodexAbsent
        CodexAbsent
        150
        1234)
      CodexAbsent
      ())
    (let $retry (codex:api-provider-retry $api-provider)
      ((codex:api-provider-name $api-provider)
       (codex:api-provider-query-params $api-provider)
       (codex:api-retry-config-max-attempts $retry)
       (codex:api-retry-config-base-delay-ms $retry)
       (codex:api-retry-config-retry-429 $retry)
       (codex:api-retry-config-retry-5xx $retry)
       (codex:api-retry-config-retry-transport $retry)
       (codex:api-provider-stream-idle-timeout-ms $api-provider))))
  (("API Shape"
    ((CodexModelProviderHeader "api-version" "2025-04-01-preview"))
    100
    200
    False
    True
    True
    1234)))

!(assertEqualToResult
  (let $api-provider
    (test:model-provider-to-api-provider
      (test:model-provider-api-shape-provider
        CodexAbsent
        CodexAbsent
        ((codex:model-provider-header "X-Static" "static")
         (codex:model-provider-header "X-Override" "static-old"))
        ((codex:model-provider-header "X-Env" "ENV_TOKEN")
         (codex:model-provider-header "X-Blank" "ENV_BLANK")
         (codex:model-provider-header "x-override" "ENV_OVERRIDE"))
        CodexAbsent
        CodexAbsent)
      CodexAbsent
      ((codex:model-provider-env-value "ENV_TOKEN" "env-value")
       (codex:model-provider-env-value "ENV_BLANK" "   ")
       (codex:model-provider-env-value "ENV_OVERRIDE" "env-new")))
    (let $headers (codex:api-provider-headers $api-provider)
      ((codex:model-provider-headers-get $headers "X-Static")
       (codex:model-provider-headers-get $headers "X-Env")
       (codex:model-provider-headers-get $headers "X-Blank")
       (codex:model-provider-headers-get $headers "X-Override"))))
  (("static" "env-value" CodexAbsent "env-new")))

!(assertEqualToResult
  ((codex:model-provider-info-request-max-retries
      (test:model-provider-info-custom
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        150
        250
        1234
        4321
        False
        False))
   (codex:model-provider-info-stream-max-retries
      (test:model-provider-info-custom
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        150
        250
        1234
        4321
        False
        False))
   (codex:model-provider-info-effective-stream-idle-timeout-ms
      (test:model-provider-info-custom
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        150
        250
        1234
        4321
        False
        False))
   (codex:model-provider-info-effective-websocket-connect-timeout-ms
      (test:model-provider-info-custom
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        150
        250
        1234
        4321
        False
        False)))
  ((100 100 1234 4321)))

!(assertEqualToResult
  (codex:model-provider-info-validate
    (codex:create-amazon-bedrock-provider CodexAbsent))
  ((CodexModelProviderInfoValidateOk)))

!(assertEqualToResult
  (codex:model-provider-info-validate-error
    (codex:model-provider-info-validate
      (test:model-provider-info-custom
        CodexAbsent
        CodexAbsent
        (codex:model-provider-auth-info
          "   "
          ()
          5000
          300000
          "/repo")
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        False
        False)))
  ("provider auth.command must not be empty"))

!(assertEqualToResult
  (codex:model-provider-info-validate-error
    (codex:model-provider-info-validate
      (test:model-provider-info-custom
        "API_KEY"
        "inline-token"
        (test:model-provider-auth-config)
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        True
        False)))
  ("provider auth cannot be combined with env_key, experimental_bearer_token, requires_openai_auth"))

!(assertEqualToResult
  (codex:model-provider-info-validate-error
    (codex:model-provider-info-validate
      (test:model-provider-info-custom
        CodexAbsent
        CodexAbsent
        CodexAbsent
        (codex:default-model-provider-aws-auth-info)
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        False
        True)))
  ("provider aws cannot be combined with supports_websockets"))

!(assertEqualToResult
  (codex:model-provider-info-validate-error
    (codex:model-provider-info-validate
      (test:model-provider-info-custom
        "API_KEY"
        "inline-token"
        (test:model-provider-auth-config)
        (codex:default-model-provider-aws-auth-info)
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        True
        False)))
  ("provider aws cannot be combined with env_key, experimental_bearer_token, auth, requires_openai_auth"))

!(assertEqualToResult
  ((codex:model-provider-info-is-openai
      (codex:create-openai-provider CodexAbsent))
   (codex:model-provider-info-is-amazon-bedrock
      (codex:create-openai-provider CodexAbsent))
   (codex:model-provider-info-has-command-auth
      (test:model-provider-info-custom
        CodexAbsent
        CodexAbsent
        (test:model-provider-auth-config)
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        False
        False)))
  ((True False True)))

!(assertEqualToResult
  ((codex:is-azure-responses-provider
      "test"
      "https://foo.openai.azure.com/openai")
   (codex:is-azure-responses-provider
      "test"
      "https://foo.openai.azure.us/openai/deployments/bar")
   (codex:is-azure-responses-provider
      "test"
      "https://foo.cognitiveservices.azure.cn/openai")
   (codex:is-azure-responses-provider
      "test"
      "https://foo.aoai.azure.com/openai")
   (codex:is-azure-responses-provider
      "test"
      "https://foo.openai.azure-api.net/openai")
   (codex:is-azure-responses-provider
      "test"
      "https://foo.z01.azurefd.net/")
   (codex:is-azure-responses-provider
      "test"
      "https://acct.blob.core.windows.net/openai"))
  ((True True True True True True True)))

!(assertEqualToResult
  ((codex:is-azure-responses-provider
      "Azure"
      "https://example.com")
   (codex:is-azure-responses-provider
      "aZuRe"
      CodexAbsent)
   (codex:is-azure-responses-provider
      "test"
      "https://api.openai.com/v1")
   (codex:is-azure-responses-provider
      "test"
      "https://example.com/openai")
   (codex:is-azure-responses-provider
      "test"
      "https://myproxy.azurewebsites.net/openai")
   (codex:is-azure-responses-provider
      "test"
      CodexAbsent))
  ((True True False False False False)))

!(assertEqualToResult
  ((codex:model-provider-info-supports-remote-compaction
      (codex:create-openai-provider CodexAbsent))
   (codex:model-provider-info-supports-remote-compaction
      (test:model-provider-named-provider
        "Azure"
        "https://example.com/openai"))
   (codex:model-provider-info-supports-remote-compaction
      (test:model-provider-named-provider
        "Example"
        "https://example.com/v1"))
   (codex:model-provider-info-supports-remote-compaction
      (test:model-provider-named-provider
        "Example"
        "https://foo.openai.azure.com/openai")))
  ((True True False True)))

!(assertEqualToResult
  (codex:model-provider-catalog-ids
    (codex:built-in-model-providers "https://proxy.openai/v1"))
  (("openai" "amazon-bedrock" "ollama" "lmstudio")))

!(assertEqualToResult
  ((codex:model-provider-info-base-url
      (codex:model-provider-catalog-get
        (codex:built-in-model-providers "https://proxy.openai/v1")
        (codex:openai-provider-id)))
   (codex:model-provider-info-is-amazon-bedrock
      (codex:model-provider-catalog-get
        (codex:built-in-model-providers CodexAbsent)
        (codex:amazon-bedrock-provider-id)))
   (codex:model-provider-info-base-url
      (codex:model-provider-catalog-get
        (codex:built-in-model-providers CodexAbsent)
        (codex:lmstudio-oss-provider-id))))
  (("https://proxy.openai/v1" True "http://localhost:1234/v1")))

!(assertEqualToResult
  ((codex:model-provider-info-name
      (codex:model-provider-catalog-get
        (codex:model-provider-catalog-result-value
          (codex:merge-configured-model-providers
            (codex:built-in-model-providers CodexAbsent)
            ((codex:model-provider-catalog-entry
               "custom"
               (test:model-provider-custom-provider)))))
        "custom"))
   (list:len
      (codex:model-provider-catalog-result-value
        (codex:merge-configured-model-providers
          (codex:built-in-model-providers CodexAbsent)
          ((codex:model-provider-catalog-entry
             "custom"
             (test:model-provider-custom-provider)))))))
  (("Custom" 5)))

!(assertEqualToResult
  (codex:model-provider-info-name
    (codex:model-provider-catalog-get
      (codex:model-provider-catalog-result-value
        (codex:merge-configured-model-providers
          (codex:built-in-model-providers CodexAbsent)
          ((codex:model-provider-catalog-entry
             (codex:openai-provider-id)
             (test:model-provider-custom-openai-provider)))))
      (codex:openai-provider-id)))
  ("OpenAI"))

!(assertEqualToResult
  ((codex:model-provider-aws-auth-info-profile
      (codex:model-provider-info-aws
        (codex:model-provider-catalog-get
          (codex:model-provider-catalog-result-value
            (codex:merge-configured-model-providers
              (codex:built-in-model-providers CodexAbsent)
              ((codex:model-provider-catalog-entry
                 (codex:amazon-bedrock-provider-id)
                 (codex:model-provider-info-with-aws
                   (codex:default-model-provider-info)
                   (codex:model-provider-aws-auth-info
                     "codex-bedrock"
                     "us-west-2"))))))
          (codex:amazon-bedrock-provider-id))))
   (codex:model-provider-aws-auth-info-region
      (codex:model-provider-info-aws
        (codex:model-provider-catalog-get
          (codex:model-provider-catalog-result-value
            (codex:merge-configured-model-providers
              (codex:built-in-model-providers CodexAbsent)
              ((codex:model-provider-catalog-entry
                 (codex:amazon-bedrock-provider-id)
                 (codex:model-provider-info-with-aws
                   (codex:default-model-provider-info)
                   (codex:model-provider-aws-auth-info
                     "codex-bedrock"
                     "us-west-2"))))))
          (codex:amazon-bedrock-provider-id)))))
  (("codex-bedrock" "us-west-2")))

!(assertEqualToResult
  (codex:model-provider-catalog-result-error
    (codex:merge-configured-model-providers
      (codex:built-in-model-providers CodexAbsent)
      ((codex:model-provider-catalog-entry
         (codex:amazon-bedrock-provider-id)
         (codex:model-provider-info-with-aws
           (test:model-provider-custom-provider)
           (codex:model-provider-aws-auth-info
             "codex-bedrock"
             CodexAbsent))))))
  ("model_providers.amazon-bedrock only supports changing `aws.profile` and `aws.region`; other non-default provider fields are not supported"))
