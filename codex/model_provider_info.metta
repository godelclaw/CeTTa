; Rust-faithful model-provider-info slice.
;
; This ports the auth-relevant parts of:
; - openai-codex/codex-rs/model-provider-info/src/lib.rs
; - openai-codex/codex-rs/protocol/src/config_types.rs ModelProviderAuthInfo
;
; Covered in this increment:
; - ModelProviderInfo fields used by auth, retry, timeout, and provider identity
; - ModelProviderAuthInfo data shape used by command-backed provider auth
; - ModelProviderInfo::api_key env-key lookup semantics
; - WireApi::Responses display/parse surface
; - retry/timeout defaults and hard retry caps
; - OpenAI / Amazon Bedrock / base-url OSS provider constructor shape
; - ModelProviderInfo::validate auth/AWS conflict rules
; - built_in_model_providers and merge_configured_model_providers catalog rules
; - supports_remote_compaction and Azure Responses provider detection
; - ModelProviderInfo::to_api_provider default URL, headers, retry, and timeout
;   projection
;
; Required CeTTa representation notes for audit:
; - Rust returns Result<Option<String>, CodexErr>. CeTTa represents that as
;   `CodexModelProviderApiKeyOk` with `CodexAbsent` for None, or
;   `CodexModelProviderApiKeyErr`.
; - Rust timeout helpers return `Duration`; CeTTa exposes the effective
;   millisecond values until a duration type is needed by runtime HTTP code.
; - Rust create_oss_provider reads CODEX_OSS_* from the process environment.
;   This slice includes the pure base-url constructor and default-port helper;
;   environment override parsing belongs with the runtime config/env layer.
; - Rust provider catalogs are HashMap<String, ModelProviderInfo>. CeTTa uses an
;   ordered entry list so tests can inspect it deterministically; lookup,
;   insert-if-absent, and replace preserve Rust HashMap semantics.
; - Rust HeaderMap is represented as a list of CodexModelProviderHeader values.
;   Insertion removes any existing case-insensitive key before consing the new
;   header, preserving HeaderMap replacement semantics. CeTTa currently skips
;   CR/LF header values; full byte-level HeaderName/HeaderValue validation
;   belongs with the future HTTP library.
; - Rust build_header_map reads std::env directly. The pure
;   to-api-provider-from-env-values seam mirrors that behavior with injected
;   environment values so tests do not depend on process-global environment.

!(import! &self error)
!(import! &self str)
!(import! &self system)

(= (codex:model-provider-info-package-version)
   "0.124.0")

(= (codex:default-stream-idle-timeout-ms)
   300000)

(= (codex:default-stream-max-retries)
   5)

(= (codex:default-request-max-retries)
   4)

(= (codex:default-websocket-connect-timeout-ms)
   15000)

(= (codex:max-stream-max-retries)
   100)

(= (codex:max-request-max-retries)
   100)

(= (codex:openai-provider-name)
   "OpenAI")

(= (codex:openai-provider-id)
   "openai")

(= (codex:amazon-bedrock-provider-name)
   "Amazon Bedrock")

(= (codex:amazon-bedrock-provider-id)
   "amazon-bedrock")

(= (codex:amazon-bedrock-default-base-url)
   "https://bedrock-mantle.us-east-1.api.aws/v1")

(= (codex:openai-api-default-base-url)
   "https://api.openai.com/v1")

(= (codex:chatgpt-codex-backend-base-url)
   "https://chatgpt.com/backend-api/codex")

(= (codex:legacy-ollama-chat-provider-id)
   "ollama-chat")

(= (codex:ollama-chat-provider-removed-error)
   "`ollama-chat` is no longer supported.\nHow to fix: replace `ollama-chat` with `ollama` in `model_provider`, `oss_provider`, or `--local-provider`.\nMore info: https://github.com/openai/codex/discussions/7782")

(= (codex:chat-wire-api-removed-error)
   "`wire_api = \"chat\"` is no longer supported.\nHow to fix: set `wire_api = \"responses\"` in your provider config.\nMore info: https://github.com/openai/codex/discussions/7782")

(= (codex:default-lmstudio-port)
   1234)

(= (codex:default-ollama-port)
   11434)

(= (codex:lmstudio-oss-provider-id)
   "lmstudio")

(= (codex:ollama-oss-provider-id)
   "ollama")

(= (codex:wire-api-responses)
   (CodexWireApiResponses))

(= (codex:wire-api-display (CodexWireApiResponses))
   "responses")

(= (codex:wire-api-parse-ok $wire-api)
   (CodexWireApiParseOk $wire-api))

(= (codex:wire-api-parse-err $message)
   (CodexWireApiParseErr $message))

(= (codex:wire-api-parse-value
      (CodexWireApiParseOk $wire-api))
   $wire-api)

(= (codex:wire-api-parse-error
      (CodexWireApiParseErr $message))
   $message)

(= (codex:wire-api-from-string "responses")
   (codex:wire-api-parse-ok (codex:wire-api-responses)))

(= (codex:wire-api-from-string "chat")
   (codex:wire-api-parse-err
     (codex:chat-wire-api-removed-error)))

(= (codex:model-provider-header $name $value)
   (CodexModelProviderHeader $name $value))

(= (codex:model-provider-header-name
      (CodexModelProviderHeader $name $value))
   $name)

(= (codex:model-provider-header-value
      (CodexModelProviderHeader $name $value))
   $value)

(= (codex:model-provider-env-value $name $value)
   (CodexModelProviderEnvValue $name $value))

(= (codex:model-provider-env-value-name
      (CodexModelProviderEnvValue $name $value))
   $name)

(= (codex:model-provider-env-value-value
      (CodexModelProviderEnvValue $name $value))
   $value)

(= (codex:api-retry-config
      $max-attempts
      $base-delay-ms
      $retry-429
      $retry-5xx
      $retry-transport)
   (CodexApiRetryConfig
     $max-attempts
     $base-delay-ms
     $retry-429
     $retry-5xx
     $retry-transport))

(= (codex:api-retry-config-max-attempts
      (CodexApiRetryConfig
        $max-attempts
        $base-delay-ms
        $retry-429
        $retry-5xx
        $retry-transport))
   $max-attempts)

(= (codex:api-retry-config-base-delay-ms
      (CodexApiRetryConfig
        $max-attempts
        $base-delay-ms
        $retry-429
        $retry-5xx
        $retry-transport))
   $base-delay-ms)

(= (codex:api-retry-config-retry-429
      (CodexApiRetryConfig
        $max-attempts
        $base-delay-ms
        $retry-429
        $retry-5xx
        $retry-transport))
   $retry-429)

(= (codex:api-retry-config-retry-5xx
      (CodexApiRetryConfig
        $max-attempts
        $base-delay-ms
        $retry-429
        $retry-5xx
        $retry-transport))
   $retry-5xx)

(= (codex:api-retry-config-retry-transport
      (CodexApiRetryConfig
        $max-attempts
        $base-delay-ms
        $retry-429
        $retry-5xx
        $retry-transport))
   $retry-transport)

(= (codex:api-provider
      $name
      $base-url
      $query-params
      $headers
      $retry
      $stream-idle-timeout-ms)
   (CodexApiProvider
     $name
     $base-url
     $query-params
     $headers
     $retry
     $stream-idle-timeout-ms))

(= (codex:api-provider-name
      (CodexApiProvider
        $name
        $base-url
        $query-params
        $headers
        $retry
        $stream-idle-timeout-ms))
   $name)

(= (codex:api-provider-base-url
      (CodexApiProvider
        $name
        $base-url
        $query-params
        $headers
        $retry
        $stream-idle-timeout-ms))
   $base-url)

(= (codex:api-provider-query-params
      (CodexApiProvider
        $name
        $base-url
        $query-params
        $headers
        $retry
        $stream-idle-timeout-ms))
   $query-params)

(= (codex:api-provider-headers
      (CodexApiProvider
        $name
        $base-url
        $query-params
        $headers
        $retry
        $stream-idle-timeout-ms))
   $headers)

(= (codex:api-provider-retry
      (CodexApiProvider
        $name
        $base-url
        $query-params
        $headers
        $retry
        $stream-idle-timeout-ms))
   $retry)

(= (codex:api-provider-stream-idle-timeout-ms
      (CodexApiProvider
        $name
        $base-url
        $query-params
        $headers
        $retry
        $stream-idle-timeout-ms))
   $stream-idle-timeout-ms)

(= (codex:model-provider-to-api-provider-ok $provider)
   (CodexModelProviderToApiProviderOk $provider))

(= (codex:model-provider-to-api-provider-err $message)
   (CodexModelProviderToApiProviderErr $message))

(= (codex:model-provider-to-api-provider-result-value
      (CodexModelProviderToApiProviderOk $provider))
   $provider)

(= (codex:model-provider-to-api-provider-result-error
      (CodexModelProviderToApiProviderErr $message))
   $message)

(= (codex:model-provider-auth-info
      $command
      $args
      $timeout-ms
      $refresh-interval-ms
      $cwd)
   (CodexModelProviderAuthInfo
     $command
     $args
     $timeout-ms
     $refresh-interval-ms
     $cwd))

(= (codex:model-provider-auth-info-command
      (CodexModelProviderAuthInfo
        $command
        $args
        $timeout-ms
        $refresh-interval-ms
        $cwd))
   $command)

(= (codex:model-provider-auth-info-args
      (CodexModelProviderAuthInfo
        $command
        $args
        $timeout-ms
        $refresh-interval-ms
        $cwd))
   $args)

(= (codex:model-provider-auth-info-timeout-ms
      (CodexModelProviderAuthInfo
        $command
        $args
        $timeout-ms
        $refresh-interval-ms
        $cwd))
   $timeout-ms)

(= (codex:model-provider-auth-info-refresh-interval-ms
      (CodexModelProviderAuthInfo
        $command
        $args
        $timeout-ms
        $refresh-interval-ms
        $cwd))
   $refresh-interval-ms)

(= (codex:model-provider-auth-info-cwd
      (CodexModelProviderAuthInfo
        $command
        $args
        $timeout-ms
        $refresh-interval-ms
        $cwd))
   $cwd)

(= (codex:model-provider-aws-auth-info $profile $region)
   (CodexModelProviderAwsAuthInfo $profile $region))

(= (codex:model-provider-aws-auth-info-profile
      (CodexModelProviderAwsAuthInfo $profile $region))
   $profile)

(= (codex:model-provider-aws-auth-info-region
      (CodexModelProviderAwsAuthInfo $profile $region))
   $region)

(= (codex:default-model-provider-aws-auth-info)
   (codex:model-provider-aws-auth-info CodexAbsent CodexAbsent))

(= (codex:model-provider-info
      $env-key
      $env-key-instructions
      $experimental-bearer-token
      $auth)
   (codex:model-provider-info-full
     ""
     CodexAbsent
     $env-key
     $env-key-instructions
     $experimental-bearer-token
     $auth
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

(= (codex:model-provider-info-full
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
     $supports-websockets))

(= (codex:default-model-provider-info)
   (codex:model-provider-info-full
     ""
     CodexAbsent
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

(= (codex:model-provider-info-name
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
        $supports-websockets))
   $name)

(= (codex:model-provider-info-base-url
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
        $supports-websockets))
   $base-url)

(= (codex:model-provider-info-env-key
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
        $supports-websockets))
   $env-key)

(= (codex:model-provider-info-env-key-instructions
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
        $supports-websockets))
   $env-key-instructions)

(= (codex:model-provider-info-experimental-bearer-token
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
        $supports-websockets))
   $experimental-bearer-token)

(= (codex:model-provider-info-auth
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
        $supports-websockets))
   $auth)

(= (codex:model-provider-info-aws
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
        $supports-websockets))
   $aws)

(= (codex:model-provider-info-wire-api
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
        $supports-websockets))
   $wire-api)

(= (codex:model-provider-info-query-params
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
        $supports-websockets))
   $query-params)

(= (codex:model-provider-info-http-headers
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
        $supports-websockets))
   $http-headers)

(= (codex:model-provider-info-env-http-headers
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
        $supports-websockets))
   $env-http-headers)

(= (codex:model-provider-info-request-max-retries-raw
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
        $supports-websockets))
   $request-max-retries)

(= (codex:model-provider-info-stream-max-retries-raw
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
        $supports-websockets))
   $stream-max-retries)

(= (codex:model-provider-info-stream-idle-timeout-ms-raw
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
        $supports-websockets))
   $stream-idle-timeout-ms)

(= (codex:model-provider-info-websocket-connect-timeout-ms-raw
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
        $supports-websockets))
   $websocket-connect-timeout-ms)

(= (codex:model-provider-info-requires-openai-auth
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
        $supports-websockets))
   $requires-openai-auth)

(= (codex:model-provider-info-supports-websockets
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
        $supports-websockets))
   $supports-websockets)

(= (codex:model-provider-api-key-ok $value)
   (CodexModelProviderApiKeyOk $value))

(= (codex:model-provider-api-key-err $error)
   (CodexModelProviderApiKeyErr $error))

(= (codex:model-provider-api-key-result-value
      (CodexModelProviderApiKeyOk $value))
   $value)

(= (codex:model-provider-api-key-result-error
      (CodexModelProviderApiKeyErr $error))
   $error)

(= (codex:model-provider-info-validate-ok)
   (CodexModelProviderInfoValidateOk))

(= (codex:model-provider-info-validate-err $message)
   (CodexModelProviderInfoValidateErr $message))

(= (codex:model-provider-info-validate-error
      (CodexModelProviderInfoValidateErr $message))
   $message)

(= (codex:model-provider-info-is-present $value)
   (if (== $value CodexAbsent) False True))

(= (codex:model-provider-info-append-conflict-text
      $conflicts
      $condition
      $name)
   (if $condition
       (if (== $conflicts "")
           $name
           (str-concat
             (str-concat $conflicts ", ")
             $name))
       $conflicts))

(= (codex:model-provider-info-auth-conflicts $provider)
   (let $conflicts-0 ""
     (let $conflicts-1
       (codex:model-provider-info-append-conflict-text
         $conflicts-0
         (codex:model-provider-info-is-present
           (codex:model-provider-info-env-key $provider))
         "env_key")
       (let $conflicts-2
         (codex:model-provider-info-append-conflict-text
           $conflicts-1
           (codex:model-provider-info-is-present
             (codex:model-provider-info-experimental-bearer-token $provider))
           "experimental_bearer_token")
         (codex:model-provider-info-append-conflict-text
           $conflicts-2
           (codex:model-provider-info-requires-openai-auth $provider)
           "requires_openai_auth")))))

(= (codex:model-provider-info-aws-conflicts $provider)
   (let $conflicts-0 ""
     (let $conflicts-1
       (codex:model-provider-info-append-conflict-text
         $conflicts-0
         (codex:model-provider-info-is-present
           (codex:model-provider-info-env-key $provider))
         "env_key")
       (let $conflicts-2
         (codex:model-provider-info-append-conflict-text
           $conflicts-1
           (codex:model-provider-info-is-present
             (codex:model-provider-info-experimental-bearer-token $provider))
           "experimental_bearer_token")
         (let $conflicts-3
           (codex:model-provider-info-append-conflict-text
             $conflicts-2
             (codex:model-provider-info-is-present
               (codex:model-provider-info-auth $provider))
             "auth")
           (codex:model-provider-info-append-conflict-text
             $conflicts-3
             (codex:model-provider-info-requires-openai-auth $provider)
             "requires_openai_auth"))))))

(= (codex:model-provider-info-format-conflict-error $prefix $conflicts)
   (str-concat (str-concat $prefix " ") $conflicts))

(= (codex:model-provider-info-validate-auth $provider $auth)
   (if (== (str-trim (codex:model-provider-auth-info-command $auth)) "")
       (codex:model-provider-info-validate-err
         "provider auth.command must not be empty")
       (let $conflicts (codex:model-provider-info-auth-conflicts $provider)
         (if (== $conflicts "")
             (codex:model-provider-info-validate-ok)
             (codex:model-provider-info-validate-err
               (codex:model-provider-info-format-conflict-error
                 "provider auth cannot be combined with"
                 $conflicts))))))

(= (codex:model-provider-info-validate-aws $provider)
   (if (codex:model-provider-info-supports-websockets $provider)
       (codex:model-provider-info-validate-err
         "provider aws cannot be combined with supports_websockets")
       (let $conflicts (codex:model-provider-info-aws-conflicts $provider)
         (if (== $conflicts "")
             (codex:model-provider-info-validate-ok)
             (codex:model-provider-info-validate-err
               (codex:model-provider-info-format-conflict-error
                 "provider aws cannot be combined with"
                 $conflicts))))))

(= (codex:model-provider-info-validate $provider)
   (let $aws (codex:model-provider-info-aws $provider)
     (if (codex:model-provider-info-is-present $aws)
         (codex:model-provider-info-validate-aws $provider)
         (let $auth (codex:model-provider-info-auth $provider)
           (if (codex:model-provider-info-is-present $auth)
               (codex:model-provider-info-validate-auth $provider $auth)
               (codex:model-provider-info-validate-ok))))))

(= (codex:model-provider-info-effective-with-default-max
      $value
      $default
      $max)
   (let $raw (if (== $value CodexAbsent) $default $value)
     (if (> $raw $max) $max $raw)))

(= (codex:model-provider-info-request-max-retries $provider)
   (codex:model-provider-info-effective-with-default-max
     (codex:model-provider-info-request-max-retries-raw $provider)
     (codex:default-request-max-retries)
     (codex:max-request-max-retries)))

(= (codex:model-provider-info-stream-max-retries $provider)
   (codex:model-provider-info-effective-with-default-max
     (codex:model-provider-info-stream-max-retries-raw $provider)
     (codex:default-stream-max-retries)
     (codex:max-stream-max-retries)))

(= (codex:model-provider-info-effective-stream-idle-timeout-ms $provider)
   (let $value (codex:model-provider-info-stream-idle-timeout-ms-raw $provider)
     (if (== $value CodexAbsent)
         (codex:default-stream-idle-timeout-ms)
         $value)))

(= (codex:model-provider-info-effective-websocket-connect-timeout-ms $provider)
   (let $value
     (codex:model-provider-info-websocket-connect-timeout-ms-raw $provider)
     (if (== $value CodexAbsent)
         (codex:default-websocket-connect-timeout-ms)
         $value)))

(= (codex:create-openai-provider $base-url)
   (codex:model-provider-info-full
     (codex:openai-provider-name)
     $base-url
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     (codex:wire-api-responses)
     CodexAbsent
     ((codex:model-provider-header
        "version"
        (codex:model-provider-info-package-version)))
     ((codex:model-provider-header
        "OpenAI-Organization"
        "OPENAI_ORGANIZATION")
      (codex:model-provider-header
        "OpenAI-Project"
        "OPENAI_PROJECT"))
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     True
     True))

(= (codex:create-amazon-bedrock-provider $aws)
   (codex:model-provider-info-full
     (codex:amazon-bedrock-provider-name)
     (codex:amazon-bedrock-default-base-url)
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     (if (== $aws CodexAbsent)
         (codex:default-model-provider-aws-auth-info)
         $aws)
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

(= (codex:create-oss-provider-with-base-url $base-url $wire-api)
   (codex:model-provider-info-full
     "gpt-oss"
     $base-url
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     $wire-api
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     False
     False))

(= (codex:create-oss-provider-with-port $default-provider-port $wire-api)
   (codex:create-oss-provider-with-base-url
     (str-concat
       (str-concat
         "http://localhost:"
         (format-args "{}" ($default-provider-port)))
       "/v1")
     $wire-api))

(= (codex:model-provider-info-is-openai $provider)
   (== (codex:model-provider-info-name $provider)
       (codex:openai-provider-name)))

(= (codex:model-provider-info-is-amazon-bedrock $provider)
   (== (codex:model-provider-info-name $provider)
       (codex:amazon-bedrock-provider-name)))

(= (codex:model-provider-info-has-command-auth $provider)
   (codex:model-provider-info-is-present
     (codex:model-provider-info-auth $provider)))

(= (codex:model-provider-info-ascii-lower-char $char)
   (case $char
     (("A" "a") ("B" "b") ("C" "c") ("D" "d") ("E" "e") ("F" "f")
      ("G" "g") ("H" "h") ("I" "i") ("J" "j") ("K" "k") ("L" "l")
      ("M" "m") ("N" "n") ("O" "o") ("P" "p") ("Q" "q") ("R" "r")
      ("S" "s") ("T" "t") ("U" "u") ("V" "v") ("W" "w") ("X" "x")
      ("Y" "y") ("Z" "z")
      ($other $other))))

(= (codex:model-provider-info-ascii-lower-text $text)
   (if (== (str-length $text) 0)
       ""
       (str-concat
         (codex:model-provider-info-ascii-lower-char
           (str-slice $text 0 1))
         (codex:model-provider-info-ascii-lower-text
           (str-slice $text 1 (str-length $text))))))

(= (codex:model-provider-info-eq-ignore-ascii-case $lhs $rhs)
   (== (codex:model-provider-info-ascii-lower-text $lhs)
       (codex:model-provider-info-ascii-lower-text $rhs)))

(= (codex:model-provider-header-name-eq $lhs $rhs)
   (codex:model-provider-info-eq-ignore-ascii-case $lhs $rhs))

(= (codex:model-provider-header-text-contains $text $needle)
   (case (str-find $text $needle)
     ((Empty False)
      ($index True))))

(= (codex:model-provider-header-name-valid $name)
   (if (== $name "")
       False
       (if (codex:model-provider-header-text-contains $name "\n")
           False
           (if (codex:model-provider-header-text-contains $name "\r")
               False
               (if (codex:model-provider-header-text-contains $name " ")
                   False
                   True)))))

(= (codex:model-provider-header-value-valid $value)
   (if (codex:model-provider-header-text-contains $value "\n")
       False
       (if (codex:model-provider-header-text-contains $value "\r")
           False
           True)))

(= (codex:model-provider-header-valid $name $value)
   (if (codex:model-provider-header-name-valid $name)
       (codex:model-provider-header-value-valid $value)
       False))

(= (codex:model-provider-headers-remove () $name)
   ())

(= (codex:model-provider-headers-remove $headers $name)
   (let ($head $tail) (decons-atom $headers)
     (case (codex:model-provider-headers-remove $tail $name)
       (($rest
         (if (codex:model-provider-header-name-eq
               (codex:model-provider-header-name $head)
               $name)
             $rest
             (cons-atom $head $rest)))))))

(= (codex:model-provider-headers-insert $headers $name $value)
   (if (codex:model-provider-header-valid $name $value)
       (cons-atom
         (codex:model-provider-header $name $value)
         (codex:model-provider-headers-remove $headers $name))
       $headers))

(= (codex:model-provider-headers-get () $name)
   CodexAbsent)

(= (codex:model-provider-headers-get $headers $name)
   (let ($head $tail) (decons-atom $headers)
     (if (codex:model-provider-header-name-eq
           (codex:model-provider-header-name $head)
           $name)
         (codex:model-provider-header-value $head)
         (case (codex:model-provider-headers-get $tail $name)
           (($found $found))))))

(= (codex:model-provider-env-values-get () $name)
   CodexAbsent)

(= (codex:model-provider-env-values-get $env-values $name)
   (let ($head $tail) (decons-atom $env-values)
     (if (== (codex:model-provider-env-value-name $head) $name)
         (codex:model-provider-env-value-value $head)
         (case (codex:model-provider-env-values-get $tail $name)
           (($found $found))))))

(= (codex:model-provider-info-insert-env-header
      $headers
      $name
      CodexAbsent)
   $headers)

(= (codex:model-provider-info-insert-env-header
      $headers
      $name
      $value)
   (if (== (str-trim $value) "")
       $headers
       (codex:model-provider-headers-insert $headers $name $value)))

(= (codex:model-provider-info-fold-static-headers CodexAbsent $headers)
   $headers)

(= (codex:model-provider-info-fold-static-headers () $headers)
   $headers)

(= (codex:model-provider-info-fold-static-headers $entries $headers)
   (let ($entry $tail) (decons-atom $entries)
     (case (codex:model-provider-info-fold-static-headers
             $tail
             (codex:model-provider-headers-insert
               $headers
               (codex:model-provider-header-name $entry)
               (codex:model-provider-header-value $entry)))
       (($next-headers $next-headers)))))

(= (codex:model-provider-info-fold-env-headers-from-values
      CodexAbsent
      $env-values
      $headers)
   $headers)

(= (codex:model-provider-info-fold-env-headers-from-values
      ()
      $env-values
      $headers)
   $headers)

(= (codex:model-provider-info-fold-env-headers-from-values
      $entries
      $env-values
      $headers)
   (let ($entry $tail) (decons-atom $entries)
     (let $env-value
       (codex:model-provider-env-values-get
         $env-values
         (codex:model-provider-header-value $entry))
       (case (codex:model-provider-info-fold-env-headers-from-values
               $tail
               $env-values
               (codex:model-provider-info-insert-env-header
                 $headers
                 (codex:model-provider-header-name $entry)
                 $env-value))
         (($next-headers $next-headers))))))

(= (codex:model-provider-info-fold-env-headers-from-system
      CodexAbsent
      $headers)
   $headers)

(= (codex:model-provider-info-fold-env-headers-from-system
      ()
      $headers)
   $headers)

(= (codex:model-provider-info-fold-env-headers-from-system
      $entries
      $headers)
   (let ($entry $tail) (decons-atom $entries)
     (case (system-getenv-or-default
             (codex:model-provider-header-value $entry)
             CodexAbsent)
       (($env-value
         (case (codex:model-provider-info-fold-env-headers-from-system
                 $tail
                 (codex:model-provider-info-insert-env-header
                   $headers
                   (codex:model-provider-header-name $entry)
                   $env-value))
           (($next-headers $next-headers))))))))

(= (codex:model-provider-info-build-header-map-from-env-values
      $provider
      $env-values)
   (let $static-headers
     (codex:model-provider-info-fold-static-headers
       (codex:model-provider-info-http-headers $provider)
       ())
     (codex:model-provider-info-fold-env-headers-from-values
       (codex:model-provider-info-env-http-headers $provider)
       $env-values
       $static-headers)))

(= (codex:model-provider-info-build-header-map $provider)
   (let $static-headers
     (codex:model-provider-info-fold-static-headers
       (codex:model-provider-info-http-headers $provider)
       ())
     (codex:model-provider-info-fold-env-headers-from-system
       (codex:model-provider-info-env-http-headers $provider)
       $static-headers)))

(= (codex:model-provider-info-codex-backend-auth-mode $auth-mode)
   (case $auth-mode
     (((CodexAuthModeChatgpt) True)
      ((CodexAuthModeChatgptAuthTokens) True)
      ((CodexAuthModeAgentIdentity) True)
      ($other False))))

(= (codex:model-provider-info-default-base-url $auth-mode)
   (if (codex:model-provider-info-codex-backend-auth-mode $auth-mode)
       (codex:chatgpt-codex-backend-base-url)
       (codex:openai-api-default-base-url)))

(= (codex:model-provider-info-effective-base-url $provider $auth-mode)
   (let $base-url (codex:model-provider-info-base-url $provider)
     (if (== $base-url CodexAbsent)
         (codex:model-provider-info-default-base-url $auth-mode)
         $base-url)))

(= (codex:model-provider-info-api-retry-config $provider)
   (codex:api-retry-config
     (codex:model-provider-info-request-max-retries $provider)
     200
     False
     True
     True))

(= (codex:model-provider-info-to-api-provider-from-env-values
      $provider
      $auth-mode
      $env-values)
   (codex:model-provider-to-api-provider-ok
     (codex:api-provider
       (codex:model-provider-info-name $provider)
       (codex:model-provider-info-effective-base-url $provider $auth-mode)
       (codex:model-provider-info-query-params $provider)
       (codex:model-provider-info-build-header-map-from-env-values
         $provider
         $env-values)
       (codex:model-provider-info-api-retry-config $provider)
       (codex:model-provider-info-effective-stream-idle-timeout-ms $provider))))

(= (codex:model-provider-info-to-api-provider $provider $auth-mode)
   (codex:model-provider-to-api-provider-ok
     (codex:api-provider
       (codex:model-provider-info-name $provider)
       (codex:model-provider-info-effective-base-url $provider $auth-mode)
       (codex:model-provider-info-query-params $provider)
       (codex:model-provider-info-build-header-map $provider)
       (codex:model-provider-info-api-retry-config $provider)
       (codex:model-provider-info-effective-stream-idle-timeout-ms $provider))))

(= (codex:model-provider-info-text-contains $text $needle)
   (case (str-find $text $needle)
     ((Empty False)
      ($index True))))

(= (codex:azure-responses-base-url-markers)
   ("openai.azure."
    "cognitiveservices.azure."
    "aoai.azure."
    "azure-api."
    "azurefd."
    "windows.net/openai"))

(= (codex:matches-azure-responses-base-url-marker
      $lower-base-url
      ())
   False)

(= (codex:matches-azure-responses-base-url-marker
      $lower-base-url
      $markers)
   (let ($marker $tail) (decons-atom $markers)
     (if (codex:model-provider-info-text-contains
           $lower-base-url
           $marker)
         True
         (case (codex:matches-azure-responses-base-url-marker
                 $lower-base-url
                 $tail)
           (($result $result))))))

(= (codex:matches-azure-responses-base-url $base-url)
   (let $lower-base-url
     (codex:model-provider-info-ascii-lower-text $base-url)
     (case (codex:azure-responses-base-url-markers)
       (($markers
         (codex:matches-azure-responses-base-url-marker
           $lower-base-url
           $markers))))))

(= (codex:is-azure-responses-provider $name $base-url)
   (if (codex:model-provider-info-eq-ignore-ascii-case $name "azure")
       True
       (if (== $base-url CodexAbsent)
           False
           (codex:matches-azure-responses-base-url $base-url))))

(= (codex:model-provider-info-supports-remote-compaction $provider)
   (if (codex:model-provider-info-is-openai $provider)
       True
       (codex:is-azure-responses-provider
         (codex:model-provider-info-name $provider)
         (codex:model-provider-info-base-url $provider))))

(= (codex:model-provider-catalog-entry $id $provider)
   (CodexModelProviderCatalogEntry $id $provider))

(= (codex:model-provider-catalog-entry-id
      (CodexModelProviderCatalogEntry $id $provider))
   $id)

(= (codex:model-provider-catalog-entry-provider
      (CodexModelProviderCatalogEntry $id $provider))
   $provider)

(= (codex:model-provider-catalog-ok $catalog)
   (CodexModelProviderCatalogOk $catalog))

(= (codex:model-provider-catalog-err $message)
   (CodexModelProviderCatalogErr $message))

(= (codex:model-provider-catalog-result-value
      (CodexModelProviderCatalogOk $catalog))
   $catalog)

(= (codex:model-provider-catalog-result-error
      (CodexModelProviderCatalogErr $message))
   $message)

(= (codex:model-provider-catalog-get () $id)
   CodexAbsent)

(= (codex:model-provider-catalog-get $catalog $id)
   (let ($entry $tail) (decons-atom $catalog)
     (if (== (codex:model-provider-catalog-entry-id $entry) $id)
         (codex:model-provider-catalog-entry-provider $entry)
         (codex:model-provider-catalog-get $tail $id))))

(= (codex:model-provider-catalog-ids ())
   ())

(= (codex:model-provider-catalog-ids $catalog)
   (let ($entry $tail) (decons-atom $catalog)
     (case (codex:model-provider-catalog-ids $tail)
       (($tail-ids
         (case (codex:model-provider-catalog-entry-id $entry)
           (($id (cons-atom $id $tail-ids)))))))))

(= (codex:model-provider-catalog-append-entry () $entry)
   ($entry))

(= (codex:model-provider-catalog-append-entry $catalog $entry)
   (let ($head $tail) (decons-atom $catalog)
     (case (codex:model-provider-catalog-append-entry $tail $entry)
       (($next-tail
         (cons-atom $head $next-tail))))))

(= (codex:model-provider-catalog-insert-if-absent
      $catalog
      $id
      $provider)
   (if (== (codex:model-provider-catalog-get $catalog $id) CodexAbsent)
       (codex:model-provider-catalog-append-entry
         $catalog
         (codex:model-provider-catalog-entry $id $provider))
       $catalog))

(= (codex:model-provider-catalog-replace () $id $provider)
   ())

(= (codex:model-provider-catalog-replace $catalog $id $provider)
   (let ($entry $tail) (decons-atom $catalog)
     (if (== (codex:model-provider-catalog-entry-id $entry) $id)
         (cons-atom
           (codex:model-provider-catalog-entry $id $provider)
           $tail)
         (case (codex:model-provider-catalog-replace $tail $id $provider)
           (($next-tail
             (cons-atom $entry $next-tail)))))))

(= (codex:model-provider-info-with-aws
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
      $next-aws)
   (codex:model-provider-info-full
     $name
     $base-url
     $env-key
     $env-key-instructions
     $experimental-bearer-token
     $auth
     $next-aws
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

(= (codex:model-provider-info-default-except-aws $provider)
   (== (codex:model-provider-info-with-aws $provider CodexAbsent)
       (codex:default-model-provider-info)))

(= (codex:model-provider-aws-auth-info-merge
      (CodexModelProviderAwsAuthInfo $base-profile $base-region)
      (CodexModelProviderAwsAuthInfo $override-profile $override-region))
   (codex:model-provider-aws-auth-info
     (if (== $override-profile CodexAbsent)
         $base-profile
         $override-profile)
     (if (== $override-region CodexAbsent)
         $base-region
         $override-region)))

(= (codex:model-provider-info-merge-aws-override
      $built-in-provider
      $aws-override)
   (if (== $aws-override CodexAbsent)
       $built-in-provider
       (let $built-in-aws
         (codex:model-provider-info-aws $built-in-provider)
         (if (== $built-in-aws CodexAbsent)
             $built-in-provider
             (codex:model-provider-info-with-aws
               $built-in-provider
               (codex:model-provider-aws-auth-info-merge
                 $built-in-aws
                 $aws-override))))))

(= (codex:built-in-model-providers $openai-base-url)
   ((codex:model-provider-catalog-entry
      (codex:openai-provider-id)
      (codex:create-openai-provider $openai-base-url))
    (codex:model-provider-catalog-entry
      (codex:amazon-bedrock-provider-id)
      (codex:create-amazon-bedrock-provider CodexAbsent))
    (codex:model-provider-catalog-entry
      (codex:ollama-oss-provider-id)
      (codex:create-oss-provider-with-port
        (codex:default-ollama-port)
        (codex:wire-api-responses)))
    (codex:model-provider-catalog-entry
      (codex:lmstudio-oss-provider-id)
      (codex:create-oss-provider-with-port
        (codex:default-lmstudio-port)
        (codex:wire-api-responses)))))

(= (codex:merge-configured-amazon-bedrock-provider
      $model-providers
      $configured-provider)
   (let $aws-override (codex:model-provider-info-aws $configured-provider)
     (if (codex:model-provider-info-default-except-aws $configured-provider)
         (let $built-in-provider
           (codex:model-provider-catalog-get
             $model-providers
             (codex:amazon-bedrock-provider-id))
           (if (== $built-in-provider CodexAbsent)
               (codex:model-provider-catalog-ok $model-providers)
               (codex:model-provider-catalog-ok
                 (codex:model-provider-catalog-replace
                   $model-providers
                   (codex:amazon-bedrock-provider-id)
                   (codex:model-provider-info-merge-aws-override
                     $built-in-provider
                     $aws-override)))))
         (codex:model-provider-catalog-err
           "model_providers.amazon-bedrock only supports changing `aws.profile` and `aws.region`; other non-default provider fields are not supported"))))

(= (codex:merge-configured-model-provider-entry
      $model-providers
      (CodexModelProviderCatalogEntry $id $provider))
   (if (== $id (codex:amazon-bedrock-provider-id))
       (codex:merge-configured-amazon-bedrock-provider
         $model-providers
         $provider)
       (codex:model-provider-catalog-ok
         (codex:model-provider-catalog-insert-if-absent
           $model-providers
           $id
           $provider))))

(= (codex:merge-configured-model-providers-loop
      $model-providers
      ())
   (codex:model-provider-catalog-ok $model-providers))

(= (codex:merge-configured-model-providers-loop
      $model-providers
      $configured-model-providers)
   (let ($entry $tail) (decons-atom $configured-model-providers)
     (case (codex:merge-configured-model-provider-entry
             $model-providers
             $entry)
       (((CodexModelProviderCatalogErr $message)
         (codex:model-provider-catalog-err $message))
        ((CodexModelProviderCatalogOk $next-model-providers)
         (codex:merge-configured-model-providers-loop
           $next-model-providers
           $tail))))))

(= (codex:merge-configured-model-providers
      $model-providers
      $configured-model-providers)
   (codex:merge-configured-model-providers-loop
     $model-providers
     $configured-model-providers))

(= (codex:model-provider-api-key-from-env-value $provider $env-value)
   (let $env-key (codex:model-provider-info-env-key $provider)
     (if (== $env-key CodexAbsent)
         (codex:model-provider-api-key-ok CodexAbsent)
         (let $instructions
           (codex:model-provider-info-env-key-instructions $provider)
           (if (== $env-value CodexAbsent)
               (codex:model-provider-api-key-err
                 (codex:error-env-var
                   (codex:env-var-error $env-key $instructions)))
               (if (== (str-trim $env-value) "")
                   (codex:model-provider-api-key-err
                     (codex:error-env-var
                       (codex:env-var-error $env-key $instructions)))
                   (codex:model-provider-api-key-ok $env-value)))))))

(= (codex:model-provider-api-key $provider)
   (let $env-key (codex:model-provider-info-env-key $provider)
     (if (== $env-key CodexAbsent)
         (codex:model-provider-api-key-ok CodexAbsent)
         (case (system-getenv-or-default $env-key CodexAbsent)
           (($env-value
             (codex:model-provider-api-key-from-env-value
               $provider
               $env-value)))))))
