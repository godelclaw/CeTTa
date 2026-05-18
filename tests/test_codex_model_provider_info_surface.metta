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
