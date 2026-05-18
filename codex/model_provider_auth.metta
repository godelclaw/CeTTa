; Rust-faithful model-provider auth resolution slice.
;
; This ports the pure/header-resolution behavior from:
; - openai-codex/codex-rs/model-provider/src/auth.rs
;
; Covered in this increment:
; - auth_manager_for_provider command-auth selection shape
; - bearer_auth_for_provider precedence
; - resolve_provider_auth precedence
;
; Required CeTTa representation notes for audit:
; - Rust returns `Arc<dyn AuthProvider>` and `Result<SharedAuthProvider>`.
;   CeTTa returns tagged provider atoms wrapped in
;   `CodexModelProviderAuthResolveOk` / `Err`; those provider atoms are consumed
;   by `codex:auth-provider-add-auth-headers`.
; - AgentIdentity auth-provider signing is not in this slice; the resolver
;   consumes the bearer-backed `CodexAuth` snapshots exported by `login_auth`.

!(import! &self auth_provider)
!(import! &self external_bearer)
!(import! &self login_auth)
!(import! &self model_provider_info)

(= (codex:auth-manager-external-bearer-only $config)
   (case $config
     (($materialized-config
       (codex:external-bearer-auth-manager
         (codex:bearer-token-refresher-new $materialized-config))))))

(= (codex:auth-manager-for-provider $auth-manager $provider)
   (let $config (codex:model-provider-info-auth $provider)
     (if (== $config CodexAbsent)
         $auth-manager
         (codex:auth-manager-external-bearer-only $config))))

(= (codex:model-provider-auth-resolve-ok $auth-provider)
   (CodexModelProviderAuthResolveOk $auth-provider))

(= (codex:model-provider-auth-resolve-err $error)
   (CodexModelProviderAuthResolveErr $error))

(= (codex:model-provider-auth-resolve-value
      (CodexModelProviderAuthResolveOk $auth-provider))
   $auth-provider)

(= (codex:model-provider-auth-resolve-error
      (CodexModelProviderAuthResolveErr $error))
   $error)

(= (codex:bearer-auth-for-provider $provider)
   (case (codex:model-provider-api-key $provider)
     (((CodexModelProviderApiKeyErr $error)
       (codex:model-provider-auth-resolve-err $error))
      ((CodexModelProviderApiKeyOk $api-key)
       (if (== $api-key CodexAbsent)
           (let $experimental-token
             (codex:model-provider-info-experimental-bearer-token $provider)
             (if (== $experimental-token CodexAbsent)
                 (codex:model-provider-auth-resolve-ok CodexAbsent)
                 (codex:model-provider-auth-resolve-ok
                   (codex:bearer-auth-provider-new $experimental-token))))
           (codex:model-provider-auth-resolve-ok
             (codex:bearer-auth-provider-new $api-key)))))))

(= (codex:bearer-auth-for-provider-from-env-value $provider $env-value)
   (case (codex:model-provider-api-key-from-env-value $provider $env-value)
     (((CodexModelProviderApiKeyErr $error)
       (codex:model-provider-auth-resolve-err $error))
      ((CodexModelProviderApiKeyOk $api-key)
       (if (== $api-key CodexAbsent)
           (let $experimental-token
             (codex:model-provider-info-experimental-bearer-token $provider)
             (if (== $experimental-token CodexAbsent)
                 (codex:model-provider-auth-resolve-ok CodexAbsent)
                 (codex:model-provider-auth-resolve-ok
                   (codex:bearer-auth-provider-new $experimental-token))))
           (codex:model-provider-auth-resolve-ok
             (codex:bearer-auth-provider-new $api-key)))))))

(= (codex:resolve-provider-auth $auth $provider)
   (case (codex:bearer-auth-for-provider $provider)
     (((CodexModelProviderAuthResolveErr $error)
       (codex:model-provider-auth-resolve-err $error))
      ((CodexModelProviderAuthResolveOk $provider-auth)
       (if (== $provider-auth CodexAbsent)
           (if (== $auth CodexAbsent)
               (codex:model-provider-auth-resolve-ok
                 (codex:unauthenticated-auth-provider))
               (codex:model-provider-auth-resolve-ok
                 (codex:auth-provider-from-auth $auth)))
           (codex:model-provider-auth-resolve-ok $provider-auth))))))

(= (codex:resolve-provider-auth-from-env-value $auth $provider $env-value)
   (case (codex:bearer-auth-for-provider-from-env-value $provider $env-value)
     (((CodexModelProviderAuthResolveErr $error)
       (codex:model-provider-auth-resolve-err $error))
      ((CodexModelProviderAuthResolveOk $provider-auth)
       (if (== $provider-auth CodexAbsent)
           (if (== $auth CodexAbsent)
               (codex:model-provider-auth-resolve-ok
                 (codex:unauthenticated-auth-provider))
               (codex:model-provider-auth-resolve-ok
                 (codex:auth-provider-from-auth $auth)))
           (codex:model-provider-auth-resolve-ok $provider-auth))))))
