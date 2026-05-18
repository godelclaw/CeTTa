; Rust-faithful runtime model-provider abstraction slice.
;
; This ports the pure/provider-selection behavior from:
; - openai-codex/codex-rs/model-provider/src/provider.rs
; - openai-codex/codex-rs/model-provider/src/amazon_bedrock/mod.rs
; - openai-codex/codex-rs/model-provider/src/amazon_bedrock/mantle.rs
;
; Covered in this increment:
; - create_model_provider selection for Amazon Bedrock vs configured providers
; - ConfiguredModelProvider auth-manager scoping through auth_manager_for_provider
; - ProviderAccountState / ProviderAccountError shape and account_state rules
; - api_provider and api_auth projection over already-materialized auth snapshots
; - Amazon Bedrock Mantle supported-region base URL rules
;
; Required CeTTa representation notes for audit:
; - Rust stores providers behind Arc<dyn ModelProvider>. CeTTa represents those
;   runtime providers as tagged atoms with explicit dispatch helpers.
; - Rust ModelProvider::auth is async and may refresh/load auth from AuthManager.
;   This slice exposes cached-auth and test-auth-manager seams for deterministic
;   pure tests; external bearer refresh behavior remains in external_bearer.
; - Rust Amazon Bedrock api_provider resolves the region through AWS auth context.
;   CeTTa does not yet have AWS SDK bindings, so the faithful pure seam accepts a
;   resolved region explicitly and applies the same Mantle base-url validation.

!(import! &self account)
!(import! &self auth_provider)
!(import! &self error)
!(import! &self login_auth)
!(import! &self model_provider_auth)
!(import! &self model_provider_info)
!(import! &self str)

(= (codex:auth-manager-from-auth-for-testing $auth)
   (CodexAuthManagerCached $auth))

(= (codex:auth-manager-auth-cached $auth-manager)
   (case $auth-manager
     (((CodexAuthManagerCached $auth) $auth)
      ($other CodexAbsent))))

(= (codex:auth-manager-has-external-auth $auth-manager)
   (case $auth-manager
     (((CodexAuthManagerExternalBearerOnly $refresher) True)
      ($other False))))

(= (codex:provider-account-state $account $requires-openai-auth)
   (CodexProviderAccountState $account $requires-openai-auth))

(= (codex:provider-account-state-account
      (CodexProviderAccountState $account $requires-openai-auth))
   $account)

(= (codex:provider-account-state-requires-openai-auth
      (CodexProviderAccountState $account $requires-openai-auth))
   $requires-openai-auth)

(= (codex:provider-account-state-ok $state)
   (CodexProviderAccountStateOk $state))

(= (codex:provider-account-state-err $error)
   (CodexProviderAccountStateErr $error))

(= (codex:provider-account-state-result-value
      (CodexProviderAccountStateOk $state))
   $state)

(= (codex:provider-account-state-result-error
      (CodexProviderAccountStateErr $error))
   $error)

(= (codex:provider-account-error-missing-chatgpt-account-details)
   (CodexProviderAccountErrorMissingChatgptAccountDetails))

(= (codex:provider-account-error-display
      (CodexProviderAccountErrorMissingChatgptAccountDetails))
   "email and plan type are required for chatgpt authentication")

(= (codex:configured-model-provider $provider-info $auth-manager)
   (case $provider-info
     (($materialized-provider-info
       (case (codex:auth-manager-for-provider
               $auth-manager
               $materialized-provider-info)
         (($scoped-auth-manager
           (CodexConfiguredModelProvider
             $materialized-provider-info
             $scoped-auth-manager))))))))

(= (codex:amazon-bedrock-model-provider $provider-info)
   (case $provider-info
     (($materialized-provider-info
       (let $aws (codex:model-provider-info-aws $materialized-provider-info)
         (CodexAmazonBedrockModelProvider
           $materialized-provider-info
           (if (== $aws CodexAbsent)
               (codex:default-model-provider-aws-auth-info)
               $aws)))))))

(= (codex:create-model-provider $provider-info $auth-manager)
   (if (codex:model-provider-info-is-amazon-bedrock $provider-info)
       (codex:amazon-bedrock-model-provider $provider-info)
       (codex:configured-model-provider $provider-info $auth-manager)))

(= (codex:model-provider-runtime-info
      (CodexConfiguredModelProvider $provider-info $auth-manager))
   $provider-info)

(= (codex:model-provider-runtime-info
      (CodexAmazonBedrockModelProvider $provider-info $aws))
   $provider-info)

(= (codex:model-provider-auth-manager
      (CodexConfiguredModelProvider $provider-info $auth-manager))
   $auth-manager)

(= (codex:model-provider-auth-manager
      (CodexAmazonBedrockModelProvider $provider-info $aws))
   CodexAbsent)

(= (codex:model-provider-auth-cached
      (CodexConfiguredModelProvider $provider-info $auth-manager))
   (codex:auth-manager-auth-cached $auth-manager))

(= (codex:model-provider-auth-cached
      (CodexAmazonBedrockModelProvider $provider-info $aws))
   CodexAbsent)

(= (codex:model-provider-auth-mode-from-auth $auth)
   (case $auth
     ((CodexAbsent CodexAbsent)
      ($materialized-auth
       (codex:codex-auth-auth-mode $materialized-auth)))))

(= (codex:model-provider-api-provider
      (CodexConfiguredModelProvider $provider-info $auth-manager))
   (codex:model-provider-info-to-api-provider
     $provider-info
     (codex:model-provider-auth-mode-from-auth
       (codex:auth-manager-auth-cached $auth-manager))))

(= (codex:model-provider-api-auth
      (CodexConfiguredModelProvider $provider-info $auth-manager))
   (codex:resolve-provider-auth
     (codex:auth-manager-auth-cached $auth-manager)
     $provider-info))

(= (codex:model-provider-api-auth-from-env-value
      (CodexConfiguredModelProvider $provider-info $auth-manager)
      $env-value)
   (codex:resolve-provider-auth-from-env-value
     (codex:auth-manager-auth-cached $auth-manager)
     $provider-info
     $env-value))

(= (codex:model-provider-info-with-base-url
      (CodexModelProviderInfo
        $name
        $base-url
        $env-key
        $env-key-instructions
        $experimental-bearer-token
        $auth
        $aws
        $wire-api
        $query-params
        $http-headers
        $env-http-headers
        $request-max-retries
        $stream-max-retries
        $stream-idle-timeout-ms
        $websocket-connect-timeout-ms
        $requires-openai-auth
        $supports-websockets)
      $next-base-url)
   (codex:model-provider-info-full
     $name
     $next-base-url
     $env-key
     $env-key-instructions
     $experimental-bearer-token
     $auth
     $aws
     $wire-api
     $query-params
     $http-headers
     $env-http-headers
     $request-max-retries
     $stream-max-retries
     $stream-idle-timeout-ms
     $websocket-connect-timeout-ms
     $requires-openai-auth
     $supports-websockets))

(= (codex:amazon-bedrock-mantle-service-name)
   "bedrock-mantle")

(= (codex:amazon-bedrock-mantle-region-supported $region)
   (case $region
     (("us-east-2" True)
      ("us-east-1" True)
      ("us-west-2" True)
      ("ap-southeast-3" True)
      ("ap-south-1" True)
      ("ap-northeast-1" True)
      ("eu-central-1" True)
      ("eu-west-1" True)
      ("eu-west-2" True)
      ("eu-south-1" True)
      ("eu-north-1" True)
      ("sa-east-1" True)
      ($other False))))

(= (codex:amazon-bedrock-mantle-base-url-ok $base-url)
   (CodexAmazonBedrockMantleBaseUrlOk $base-url))

(= (codex:amazon-bedrock-mantle-base-url-err $error)
   (CodexAmazonBedrockMantleBaseUrlErr $error))

(= (codex:amazon-bedrock-mantle-base-url-value
      (CodexAmazonBedrockMantleBaseUrlOk $base-url))
   $base-url)

(= (codex:amazon-bedrock-mantle-base-url-error
      (CodexAmazonBedrockMantleBaseUrlErr $error))
   $error)

(= (codex:amazon-bedrock-mantle-base-url $region)
   (if (codex:amazon-bedrock-mantle-region-supported $region)
       (codex:amazon-bedrock-mantle-base-url-ok
         (str-concat
           (str-concat "https://bedrock-mantle." $region)
           ".api.aws/v1"))
       (codex:amazon-bedrock-mantle-base-url-err
         (codex:error-fatal
           (format-args
             "Amazon Bedrock Mantle does not support region `{}`"
             ($region))))))

(= (codex:amazon-bedrock-region-from-config $aws)
   (let $region (codex:model-provider-aws-auth-info-region $aws)
     (if (== $region CodexAbsent)
         CodexAbsent
         (let $trimmed (str-trim $region)
           (if (== $trimmed "")
               CodexAbsent
               $trimmed)))))

(= (codex:amazon-bedrock-aws-auth-config $aws)
   (CodexAwsAuthConfig
     (codex:model-provider-aws-auth-info-profile $aws)
     (codex:amazon-bedrock-region-from-config $aws)
     (codex:amazon-bedrock-mantle-service-name)))

(= (codex:aws-auth-config-profile
      (CodexAwsAuthConfig $profile $region $service))
   $profile)

(= (codex:aws-auth-config-region
      (CodexAwsAuthConfig $profile $region $service))
   $region)

(= (codex:aws-auth-config-service
      (CodexAwsAuthConfig $profile $region $service))
   $service)

(= (codex:model-provider-api-provider-with-region
      (CodexAmazonBedrockModelProvider $provider-info $aws)
      $region)
   (case (codex:amazon-bedrock-mantle-base-url $region)
     (((CodexAmazonBedrockMantleBaseUrlErr $error)
       (codex:model-provider-to-api-provider-err $error))
      ((CodexAmazonBedrockMantleBaseUrlOk $base-url)
       (codex:model-provider-info-to-api-provider
         (codex:model-provider-info-with-base-url $provider-info $base-url)
         CodexAbsent)))))

(= (codex:model-provider-api-provider-with-region
      (CodexConfiguredModelProvider $provider-info $auth-manager)
      $region)
   (codex:model-provider-api-provider
     (CodexConfiguredModelProvider $provider-info $auth-manager)))

(= (codex:model-provider-api-provider
      (CodexAmazonBedrockModelProvider $provider-info $aws))
   (let $region (codex:amazon-bedrock-region-from-config $aws)
     (if (== $region CodexAbsent)
         (codex:model-provider-to-api-provider-err
           (codex:error-fatal
             "Amazon Bedrock provider requires resolved AWS region for CeTTa api_provider seam"))
         (codex:model-provider-api-provider-with-region
           (CodexAmazonBedrockModelProvider $provider-info $aws)
           $region))))

(= (codex:model-provider-api-auth
      (CodexAmazonBedrockModelProvider $provider-info $aws))
   (codex:model-provider-auth-resolve-err
     (codex:error-fatal
       "Amazon Bedrock SigV4 auth requires an AWS auth runtime")))

(= (codex:model-provider-api-auth-from-env-value
      (CodexAmazonBedrockModelProvider $provider-info $aws)
      $env-value)
   (codex:model-provider-api-auth
     (CodexAmazonBedrockModelProvider $provider-info $aws)))

(= (codex:model-provider-account-state
      (CodexAmazonBedrockModelProvider $provider-info $aws))
   (codex:provider-account-state-ok
     (codex:provider-account-state
       (codex:provider-account-amazon-bedrock)
       False)))

(= (codex:model-provider-chatgpt-account-state $auth)
   (let $email (codex:codex-auth-get-account-email $auth)
     (let $plan-type (codex:codex-auth-account-plan-type $auth)
       (if (== $email CodexAbsent)
           (codex:provider-account-state-err
             (codex:provider-account-error-missing-chatgpt-account-details))
           (if (== $plan-type CodexAbsent)
               (codex:provider-account-state-err
                 (codex:provider-account-error-missing-chatgpt-account-details))
               (codex:provider-account-state-ok
                 (codex:provider-account-state
                   (codex:provider-account-chatgpt $email $plan-type)
                   True)))))))

(= (codex:model-provider-openai-account-state-from-auth CodexAbsent)
   (codex:provider-account-state-ok
     (codex:provider-account-state CodexAbsent True)))

(= (codex:model-provider-openai-account-state-from-auth
      (CodexAuthApiKey $api-key))
   (codex:provider-account-state-ok
     (codex:provider-account-state
       (codex:provider-account-api-key)
       True)))

(= (codex:model-provider-openai-account-state-from-auth
      (CodexAuthChatgpt $token-data))
   (codex:model-provider-chatgpt-account-state
     (CodexAuthChatgpt $token-data)))

(= (codex:model-provider-openai-account-state-from-auth
      (CodexAuthChatgptAuthTokens $token-data))
   (codex:model-provider-chatgpt-account-state
     (CodexAuthChatgptAuthTokens $token-data)))

(= (codex:model-provider-openai-account-state-from-auth
      (CodexAuthAgentIdentity $auth))
   (codex:model-provider-chatgpt-account-state
     (CodexAuthAgentIdentity $auth)))

(= (codex:model-provider-account-state
      (CodexConfiguredModelProvider $provider-info $auth-manager))
   (if (codex:model-provider-info-requires-openai-auth $provider-info)
       (codex:model-provider-openai-account-state-from-auth
         (codex:auth-manager-auth-cached $auth-manager))
       (codex:provider-account-state-ok
         (codex:provider-account-state CodexAbsent False))))
