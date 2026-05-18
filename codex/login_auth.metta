; Rust-faithful login CodexAuth snapshot slice.
;
; This ports the pure snapshot accessors needed from:
; - openai-codex/codex-rs/login/src/auth/manager.rs
;
; Covered in this increment:
; - CodexAuth::ApiKey
; - CodexAuth::Chatgpt / ChatgptAuthTokens over current TokenData
; - get_token, get_account_id, and is_fedramp_account helper behavior
; - auth_provider_from_auth for bearer-backed auth variants
;
; Required CeTTa representation notes for audit:
; - Rust Chatgpt auth stores mutable state behind Arc/Mutex and may refresh it.
;   This slice represents the current snapshot only; refresh/runtime loading is a
;   separate AuthManager concern.
; - AgentIdentity auth requires the Rust agent-identity signing runtime and is
;   intentionally not represented here yet. The provider-auth resolver therefore
;   covers the bearer-backed CodexAuth variants in this slice.

!(import! &self auth_provider)
!(import! &self token_data)

(= (codex:codex-auth-api-key $api-key)
   (CodexAuthApiKey $api-key))

(= (codex:codex-auth-chatgpt $token-data)
   (case $token-data
     (($materialized-token-data
       (CodexAuthChatgpt $materialized-token-data)))))

(= (codex:codex-auth-chatgpt-auth-tokens $token-data)
   (case $token-data
     (($materialized-token-data
       (CodexAuthChatgptAuthTokens $materialized-token-data)))))

(= (codex:codex-auth-token-result-ok $token)
   (CodexAuthTokenResultOk $token))

(= (codex:codex-auth-token-result-err $message)
   (CodexAuthTokenResultErr $message))

(= (codex:codex-auth-token-result-value
      (CodexAuthTokenResultOk $token))
   $token)

(= (codex:codex-auth-token-result-message
      (CodexAuthTokenResultErr $message))
   $message)

(= (codex:codex-auth-get-token (CodexAuthApiKey $api-key))
   (codex:codex-auth-token-result-ok $api-key))

(= (codex:codex-auth-get-token (CodexAuthChatgpt $token-data))
   (codex:codex-auth-token-result-ok
     (codex:token-data-access-token $token-data)))

(= (codex:codex-auth-get-token (CodexAuthChatgptAuthTokens $token-data))
   (codex:codex-auth-token-result-ok
     (codex:token-data-access-token $token-data)))

(= (codex:codex-auth-get-account-id (CodexAuthApiKey $api-key))
   CodexAbsent)

(= (codex:codex-auth-get-account-id (CodexAuthChatgpt $token-data))
   (codex:token-data-account-id $token-data))

(= (codex:codex-auth-get-account-id (CodexAuthChatgptAuthTokens $token-data))
   (codex:token-data-account-id $token-data))

(= (codex:codex-auth-is-fedramp-account (CodexAuthApiKey $api-key))
   False)

(= (codex:codex-auth-is-fedramp-account (CodexAuthChatgpt $token-data))
   (codex:id-token-info-is-fedramp-account
     (codex:token-data-id-token $token-data)))

(= (codex:codex-auth-is-fedramp-account
      (CodexAuthChatgptAuthTokens $token-data))
   (codex:id-token-info-is-fedramp-account
     (codex:token-data-id-token $token-data)))

(= (codex:codex-auth-token-option $auth)
   (case (codex:codex-auth-get-token $auth)
     (((CodexAuthTokenResultOk $token)
       $token)
      ((CodexAuthTokenResultErr $message)
       CodexAbsent))))

(= (codex:auth-provider-from-auth $auth)
   (codex:bearer-auth-provider
     (codex:codex-auth-token-option $auth)
     (codex:codex-auth-get-account-id $auth)
     (codex:codex-auth-is-fedramp-account $auth)))
