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
