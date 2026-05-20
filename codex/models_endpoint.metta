; Rust-faithful OpenAI-compatible models endpoint slice.
;
; This ports the pure/request-preparation behavior from:
; - openai-codex/codex-rs/model-provider/src/models_endpoint.rs
; - openai-codex/codex-rs/login/src/auth_env_telemetry.rs
;
; Covered in this increment:
; - MODELS_REFRESH_TIMEOUT and MODELS_ENDPOINT constants
; - OpenAiModelsEndpoint provider/auth-manager shape
; - has_command_auth and uses_codex_backend predicates
; - AuthEnvTelemetry collection with secret-safe provider key bucketing
; - pre-network list_models request plan: auth snapshot, auth mode,
;   ApiProvider projection, AuthProvider resolution, and request telemetry
;
; Required CeTTa representation notes for audit:
; - Rust OpenAiModelsEndpoint::auth awaits AuthManager::auth, which can refresh
;   runtime state. This pure seam consumes already-materialized auth snapshots
;   represented by CodexAuthManagerCached; external refresh remains in the
;   external_bearer runtime slice.
; - Rust reads process environment directly. The CeTTa seam takes explicit
;   env-value atoms so tests stay deterministic and do not mutate process-global
;   environment. CeTTa strings cannot represent Rust VarError::NotUnicode, so
;   only NotPresent/trim-empty/present behavior is modeled here.
; - Rust list_models performs real HTTP with timeout and maps API errors. CeTTa
;   exposes the request plan up to the runtime/network boundary; the HTTP client
;   and timeout executor belong with the future HTTP/process runtime library.

!(import! &self auth_provider)
!(import! &self login_auth)
!(import! &self model_provider_auth)
!(import! &self model_provider_info)
!(import! &self str)

(= (codex:models-refresh-timeout-ms)
   5000)

(= (codex:models-endpoint-path)
   "/models")

(= (codex:openai-api-key-env-var)
   "OPENAI_API_KEY")

(= (codex:codex-api-key-env-var)
   "CODEX_API_KEY")

(= (codex:refresh-token-url-override-env-var)
   "CODEX_REFRESH_TOKEN_URL_OVERRIDE")

(= (codex:openai-models-endpoint $provider-info $auth-manager)
   (CodexOpenAiModelsEndpoint $provider-info $auth-manager))

(= (codex:openai-models-endpoint-provider-info
      (CodexOpenAiModelsEndpoint $provider-info $auth-manager))
   $provider-info)

(= (codex:openai-models-endpoint-auth-manager
      (CodexOpenAiModelsEndpoint $provider-info $auth-manager))
   $auth-manager)

(= (codex:openai-models-endpoint-auth
      (CodexOpenAiModelsEndpoint $provider-info $auth-manager))
   (case $auth-manager
     ((CodexAbsent CodexAbsent)
      ((CodexAuthManagerCached $auth) $auth)
      ($other CodexAbsent))))

(= (codex:openai-models-endpoint-auth-mode $endpoint)
   (let $auth (codex:openai-models-endpoint-auth $endpoint)
     (case $auth
       ((CodexAbsent CodexAbsent)
        ($materialized-auth
         (codex:codex-auth-auth-mode $materialized-auth))))))

(= (codex:openai-models-endpoint-has-command-auth
      (CodexOpenAiModelsEndpoint $provider-info $auth-manager))
   (codex:model-provider-info-has-command-auth $provider-info))

(= (codex:openai-models-endpoint-uses-codex-backend $endpoint)
   (let $auth (codex:openai-models-endpoint-auth $endpoint)
     (case $auth
       ((CodexAbsent False)
        ($materialized-auth
         (codex:codex-auth-uses-codex-backend $materialized-auth))))))

(= (codex:auth-env-telemetry
      $openai-api-key-env-present
      $codex-api-key-env-present
      $codex-api-key-env-enabled
      $provider-env-key-name
      $provider-env-key-present
      $refresh-token-url-override-present)
   (CodexAuthEnvTelemetry
     $openai-api-key-env-present
     $codex-api-key-env-present
     $codex-api-key-env-enabled
     $provider-env-key-name
     $provider-env-key-present
     $refresh-token-url-override-present))

(= (codex:auth-env-telemetry-openai-api-key-env-present
      (CodexAuthEnvTelemetry
        $openai-api-key-env-present
        $codex-api-key-env-present
        $codex-api-key-env-enabled
        $provider-env-key-name
        $provider-env-key-present
        $refresh-token-url-override-present))
   $openai-api-key-env-present)

(= (codex:auth-env-telemetry-codex-api-key-env-present
      (CodexAuthEnvTelemetry
        $openai-api-key-env-present
        $codex-api-key-env-present
        $codex-api-key-env-enabled
        $provider-env-key-name
        $provider-env-key-present
        $refresh-token-url-override-present))
   $codex-api-key-env-present)

(= (codex:auth-env-telemetry-codex-api-key-env-enabled
      (CodexAuthEnvTelemetry
        $openai-api-key-env-present
        $codex-api-key-env-present
        $codex-api-key-env-enabled
        $provider-env-key-name
        $provider-env-key-present
        $refresh-token-url-override-present))
   $codex-api-key-env-enabled)

(= (codex:auth-env-telemetry-provider-env-key-name
      (CodexAuthEnvTelemetry
        $openai-api-key-env-present
        $codex-api-key-env-present
        $codex-api-key-env-enabled
        $provider-env-key-name
        $provider-env-key-present
        $refresh-token-url-override-present))
   $provider-env-key-name)

(= (codex:auth-env-telemetry-provider-env-key-present
      (CodexAuthEnvTelemetry
        $openai-api-key-env-present
        $codex-api-key-env-present
        $codex-api-key-env-enabled
        $provider-env-key-name
        $provider-env-key-present
        $refresh-token-url-override-present))
   $provider-env-key-present)

(= (codex:auth-env-telemetry-refresh-token-url-override-present
      (CodexAuthEnvTelemetry
        $openai-api-key-env-present
        $codex-api-key-env-present
        $codex-api-key-env-enabled
        $provider-env-key-name
        $provider-env-key-present
        $refresh-token-url-override-present))
   $refresh-token-url-override-present)

(= (codex:models-endpoint-env-values-get $env-values $name)
   (case $env-values
     ((() CodexAbsent)
      ($materialized-env-values
       (let ($head $tail) (decons-atom $materialized-env-values)
         (if (== (codex:model-provider-env-value-name $head) $name)
             (codex:model-provider-env-value-value $head)
             (case (codex:models-endpoint-env-values-get $tail $name)
               (($found $found)))))))))

(= (codex:models-endpoint-env-var-present-from-values $env-values $name)
   (let $value (codex:models-endpoint-env-values-get $env-values $name)
     (case $value
       ((CodexAbsent False)
        ($materialized-value
         (not (== (str-trim $materialized-value) "")))))))

(= (codex:models-endpoint-provider-env-key-name $provider-info)
   (case (codex:model-provider-info-env-key $provider-info)
     ((CodexAbsent CodexAbsent)
      ($env-key "configured"))))

(= (codex:models-endpoint-provider-env-key-present $provider-info $env-values)
   (case (codex:model-provider-info-env-key $provider-info)
     ((CodexAbsent CodexAbsent)
      ($env-key
       (codex:models-endpoint-env-var-present-from-values
         $env-values
         $env-key)))))

(= (codex:collect-auth-env-telemetry-from-env-values
      $provider-info
      $codex-api-key-env-enabled
      $env-values)
   (let $openai-api-key-env-present
     (codex:models-endpoint-env-var-present-from-values
       $env-values
       (codex:openai-api-key-env-var))
     (let $codex-api-key-env-present
       (codex:models-endpoint-env-var-present-from-values
         $env-values
         (codex:codex-api-key-env-var))
       (let $provider-env-key-name
         (codex:models-endpoint-provider-env-key-name $provider-info)
         (let $provider-env-key-present
           (codex:models-endpoint-provider-env-key-present
             $provider-info
             $env-values)
           (let $refresh-token-url-override-present
             (codex:models-endpoint-env-var-present-from-values
               $env-values
               (codex:refresh-token-url-override-env-var))
             (codex:auth-env-telemetry
               $openai-api-key-env-present
               $codex-api-key-env-present
               $codex-api-key-env-enabled
               $provider-env-key-name
               $provider-env-key-present
               $refresh-token-url-override-present)))))))

(= (codex:openai-models-endpoint-auth-env-from-env-values
      (CodexOpenAiModelsEndpoint $provider-info $auth-manager)
      $codex-api-key-env-enabled
      $env-values)
   (codex:collect-auth-env-telemetry-from-env-values
     $provider-info
     $codex-api-key-env-enabled
     $env-values))

(= (codex:models-request-telemetry
      $auth-mode
      $auth-header-attached
      $auth-header-name
      $auth-env)
   (CodexModelsRequestTelemetry
     $auth-mode
     $auth-header-attached
     $auth-header-name
     $auth-env))

(= (codex:models-request-telemetry-auth-mode
      (CodexModelsRequestTelemetry
        $auth-mode
        $auth-header-attached
        $auth-header-name
        $auth-env))
   $auth-mode)

(= (codex:models-request-telemetry-auth-header-attached
      (CodexModelsRequestTelemetry
        $auth-mode
        $auth-header-attached
        $auth-header-name
        $auth-env))
   $auth-header-attached)

(= (codex:models-request-telemetry-auth-header-name
      (CodexModelsRequestTelemetry
        $auth-mode
        $auth-header-attached
        $auth-header-name
        $auth-env))
   $auth-header-name)

(= (codex:models-request-telemetry-auth-env
      (CodexModelsRequestTelemetry
        $auth-mode
        $auth-header-attached
        $auth-header-name
        $auth-env))
   $auth-env)

(= (codex:openai-models-endpoint-request-plan
      $client-version
      $endpoint
      $timeout-ms
      $api-provider
      $api-auth
      $request-telemetry)
   (CodexOpenAiModelsEndpointRequestPlan
     $client-version
     $endpoint
     $timeout-ms
     $api-provider
     $api-auth
     $request-telemetry))

(= (codex:openai-models-endpoint-request-plan-client-version
      (CodexOpenAiModelsEndpointRequestPlan
        $client-version
        $endpoint
        $timeout-ms
        $api-provider
        $api-auth
        $request-telemetry))
   $client-version)

(= (codex:openai-models-endpoint-request-plan-endpoint
      (CodexOpenAiModelsEndpointRequestPlan
        $client-version
        $endpoint
        $timeout-ms
        $api-provider
        $api-auth
        $request-telemetry))
   $endpoint)

(= (codex:openai-models-endpoint-request-plan-timeout-ms
      (CodexOpenAiModelsEndpointRequestPlan
        $client-version
        $endpoint
        $timeout-ms
        $api-provider
        $api-auth
        $request-telemetry))
   $timeout-ms)

(= (codex:openai-models-endpoint-request-plan-api-provider
      (CodexOpenAiModelsEndpointRequestPlan
        $client-version
        $endpoint
        $timeout-ms
        $api-provider
        $api-auth
        $request-telemetry))
   $api-provider)

(= (codex:openai-models-endpoint-request-plan-api-auth
      (CodexOpenAiModelsEndpointRequestPlan
        $client-version
        $endpoint
        $timeout-ms
        $api-provider
        $api-auth
        $request-telemetry))
   $api-auth)

(= (codex:openai-models-endpoint-request-plan-telemetry
      (CodexOpenAiModelsEndpointRequestPlan
        $client-version
        $endpoint
        $timeout-ms
        $api-provider
        $api-auth
        $request-telemetry))
   $request-telemetry)

(= (codex:openai-models-endpoint-request-plan-ok $plan)
   (CodexOpenAiModelsEndpointRequestPlanOk $plan))

(= (codex:openai-models-endpoint-request-plan-err $error)
   (CodexOpenAiModelsEndpointRequestPlanErr $error))

(= (codex:openai-models-endpoint-request-plan-value
      (CodexOpenAiModelsEndpointRequestPlanOk $plan))
   $plan)

(= (codex:openai-models-endpoint-request-plan-error
      (CodexOpenAiModelsEndpointRequestPlanErr $error))
   $error)

(= (codex:openai-models-endpoint-request-plan-from-env-values
      (CodexOpenAiModelsEndpoint $provider-info $auth-manager)
      $client-version
      $provider-env-value
      $env-values
      $codex-api-key-env-enabled)
   (let $auth
     (codex:openai-models-endpoint-auth
       (CodexOpenAiModelsEndpoint $provider-info $auth-manager))
     (let $auth-mode
       (case $auth
         ((CodexAbsent CodexAbsent)
          ($materialized-auth
           (codex:codex-auth-auth-mode $materialized-auth))))
       (case (codex:model-provider-info-to-api-provider-from-env-values
               $provider-info
               $auth-mode
               $env-values)
         (((CodexModelProviderToApiProviderErr $error)
           (codex:openai-models-endpoint-request-plan-err $error))
          ((CodexModelProviderToApiProviderOk $api-provider)
           (case (codex:resolve-provider-auth-from-env-value
                   $auth
                   $provider-info
                   $provider-env-value)
             (((CodexModelProviderAuthResolveErr $error)
               (codex:openai-models-endpoint-request-plan-err $error))
              ((CodexModelProviderAuthResolveOk $api-auth)
               (let $auth-header-telemetry
                 (codex:auth-header-telemetry $api-auth)
                 (let $auth-header-attached
                   (codex:auth-header-telemetry-attached
                     $auth-header-telemetry)
                   (let $auth-header-name
                     (codex:auth-header-telemetry-name
                       $auth-header-telemetry)
                     (let $auth-env
                       (codex:collect-auth-env-telemetry-from-env-values
                         $provider-info
                         $codex-api-key-env-enabled
                         $env-values)
                       (let $request-telemetry
                         (codex:models-request-telemetry
                           $auth-mode
                           $auth-header-attached
                           $auth-header-name
                           $auth-env)
                         (let $endpoint (codex:models-endpoint-path)
                           (let $timeout-ms (codex:models-refresh-timeout-ms)
                             (codex:openai-models-endpoint-request-plan-ok
                               (codex:openai-models-endpoint-request-plan
                                 $client-version
                                 $endpoint
                                 $timeout-ms
                                 $api-provider
                                 $api-auth
                                 $request-telemetry))))))))))))))))))
