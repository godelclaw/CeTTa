; Rust-faithful login CodexAuth snapshot slice.
;
; This ports the pure snapshot accessors needed from:
; - openai-codex/codex-rs/login/src/auth/manager.rs
;
; Covered in this increment:
; - CodexAuth::ApiKey
; - CodexAuth::Chatgpt / ChatgptAuthTokens over current TokenData
; - CodexAuth::AgentIdentity over AgentIdentityAuthRecord metadata
; - auth_mode, api_auth_mode, get_token, account metadata, and helper predicates
; - auth_provider_from_auth for bearer-backed and AgentIdentity auth variants
;
; Required CeTTa representation notes for audit:
; - Rust Chatgpt auth stores mutable state behind Arc/Mutex and may refresh it.
;   This slice represents the current snapshot only; refresh/runtime loading is a
;   separate AuthManager concern.
; - Rust AgentIdentity initializes a process task over the network, then signs an
;   Authorization header from the task id and private key. This slice represents
;   the record and any already-initialized authorization header explicitly; the
;   network registration and cryptographic signing implementation are separate
;   runtime-library work.

!(import! &self auth_provider)
!(import! &self account)
!(import! &self token_data)

(= (codex:auth-mode-api-key)
   (CodexAuthModeApiKey))

(= (codex:auth-mode-chatgpt)
   (CodexAuthModeChatgpt))

(= (codex:auth-mode-chatgpt-auth-tokens)
   (CodexAuthModeChatgptAuthTokens))

(= (codex:auth-mode-agent-identity)
   (CodexAuthModeAgentIdentity))

(= (codex:agent-identity-auth-record
      $agent-runtime-id
      $agent-private-key
      $account-id
      $chatgpt-user-id
      $email
      $plan-type
      $chatgpt-account-is-fedramp)
   (case $plan-type
     (($materialized-plan-type
       (CodexAgentIdentityAuthRecord
         $agent-runtime-id
         $agent-private-key
         $account-id
         $chatgpt-user-id
         $email
         $materialized-plan-type
         $chatgpt-account-is-fedramp)))))

(= (codex:agent-identity-auth-record-agent-runtime-id
      (CodexAgentIdentityAuthRecord
        $agent-runtime-id
        $agent-private-key
        $account-id
        $chatgpt-user-id
        $email
        $plan-type
        $chatgpt-account-is-fedramp))
   $agent-runtime-id)

(= (codex:agent-identity-auth-record-agent-private-key
      (CodexAgentIdentityAuthRecord
        $agent-runtime-id
        $agent-private-key
        $account-id
        $chatgpt-user-id
        $email
        $plan-type
        $chatgpt-account-is-fedramp))
   $agent-private-key)

(= (codex:agent-identity-auth-record-account-id
      (CodexAgentIdentityAuthRecord
        $agent-runtime-id
        $agent-private-key
        $account-id
        $chatgpt-user-id
        $email
        $plan-type
        $chatgpt-account-is-fedramp))
   $account-id)

(= (codex:agent-identity-auth-record-chatgpt-user-id
      (CodexAgentIdentityAuthRecord
        $agent-runtime-id
        $agent-private-key
        $account-id
        $chatgpt-user-id
        $email
        $plan-type
        $chatgpt-account-is-fedramp))
   $chatgpt-user-id)

(= (codex:agent-identity-auth-record-email
      (CodexAgentIdentityAuthRecord
        $agent-runtime-id
        $agent-private-key
        $account-id
        $chatgpt-user-id
        $email
        $plan-type
        $chatgpt-account-is-fedramp))
   $email)

(= (codex:agent-identity-auth-record-plan-type
      (CodexAgentIdentityAuthRecord
        $agent-runtime-id
        $agent-private-key
        $account-id
        $chatgpt-user-id
        $email
        $plan-type
        $chatgpt-account-is-fedramp))
   $plan-type)

(= (codex:agent-identity-auth-record-is-fedramp-account
      (CodexAgentIdentityAuthRecord
        $agent-runtime-id
        $agent-private-key
        $account-id
        $chatgpt-user-id
        $email
        $plan-type
        $chatgpt-account-is-fedramp))
   $chatgpt-account-is-fedramp)

(= (codex:agent-identity-auth $record)
   (codex:agent-identity-auth-with-runtime
     $record
     CodexAbsent
     CodexAbsent))

(= (codex:agent-identity-auth-with-runtime
      $record
      $process-task-id
      $authorization-header)
   (case $record
     (($materialized-record
       (CodexAgentIdentityAuth
         $materialized-record
         $process-task-id
         $authorization-header)))))

(= (codex:agent-identity-auth-record
      (CodexAgentIdentityAuth $record $process-task-id $authorization-header))
   $record)

(= (codex:agent-identity-auth-process-task-id
      (CodexAgentIdentityAuth $record $process-task-id $authorization-header))
   $process-task-id)

(= (codex:agent-identity-auth-authorization-header
      (CodexAgentIdentityAuth $record $process-task-id $authorization-header))
   $authorization-header)

(= (codex:agent-identity-auth-account-id $auth)
   (codex:agent-identity-auth-record-account-id
     (codex:agent-identity-auth-record $auth)))

(= (codex:agent-identity-auth-chatgpt-user-id $auth)
   (codex:agent-identity-auth-record-chatgpt-user-id
     (codex:agent-identity-auth-record $auth)))

(= (codex:agent-identity-auth-email $auth)
   (codex:agent-identity-auth-record-email
     (codex:agent-identity-auth-record $auth)))

(= (codex:agent-identity-auth-plan-type $auth)
   (codex:agent-identity-auth-record-plan-type
     (codex:agent-identity-auth-record $auth)))

(= (codex:agent-identity-auth-is-fedramp-account $auth)
   (codex:agent-identity-auth-record-is-fedramp-account
     (codex:agent-identity-auth-record $auth)))

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

(= (codex:codex-auth-agent-identity $auth)
   (case $auth
     (($materialized-auth
       (CodexAuthAgentIdentity $materialized-auth)))))

(= (codex:codex-auth-auth-mode (CodexAuthApiKey $api-key))
   (codex:auth-mode-api-key))

(= (codex:codex-auth-auth-mode (CodexAuthChatgpt $token-data))
   (codex:auth-mode-chatgpt))

(= (codex:codex-auth-auth-mode (CodexAuthChatgptAuthTokens $token-data))
   (codex:auth-mode-chatgpt))

(= (codex:codex-auth-auth-mode (CodexAuthAgentIdentity $auth))
   (codex:auth-mode-agent-identity))

(= (codex:codex-auth-api-auth-mode (CodexAuthApiKey $api-key))
   (codex:auth-mode-api-key))

(= (codex:codex-auth-api-auth-mode (CodexAuthChatgpt $token-data))
   (codex:auth-mode-chatgpt))

(= (codex:codex-auth-api-auth-mode
      (CodexAuthChatgptAuthTokens $token-data))
   (codex:auth-mode-chatgpt-auth-tokens))

(= (codex:codex-auth-api-auth-mode (CodexAuthAgentIdentity $auth))
   (codex:auth-mode-agent-identity))

(= (codex:codex-auth-eq $lhs $rhs)
   (== (codex:codex-auth-api-auth-mode $lhs)
       (codex:codex-auth-api-auth-mode $rhs)))

(= (codex:codex-auth-is-api-key-auth $auth)
   (== (codex:codex-auth-auth-mode $auth)
       (codex:auth-mode-api-key)))

(= (codex:codex-auth-is-chatgpt-auth (CodexAuthApiKey $api-key))
   False)

(= (codex:codex-auth-is-chatgpt-auth (CodexAuthChatgpt $token-data))
   True)

(= (codex:codex-auth-is-chatgpt-auth
      (CodexAuthChatgptAuthTokens $token-data))
   True)

(= (codex:codex-auth-is-chatgpt-auth (CodexAuthAgentIdentity $auth))
   False)

(= (codex:codex-auth-uses-codex-backend (CodexAuthApiKey $api-key))
   False)

(= (codex:codex-auth-uses-codex-backend (CodexAuthChatgpt $token-data))
   True)

(= (codex:codex-auth-uses-codex-backend
      (CodexAuthChatgptAuthTokens $token-data))
   True)

(= (codex:codex-auth-uses-codex-backend (CodexAuthAgentIdentity $auth))
   True)

(= (codex:codex-auth-is-external-chatgpt-tokens
      (CodexAuthApiKey $api-key))
   False)

(= (codex:codex-auth-is-external-chatgpt-tokens
      (CodexAuthChatgpt $token-data))
   False)

(= (codex:codex-auth-is-external-chatgpt-tokens
      (CodexAuthChatgptAuthTokens $token-data))
   True)

(= (codex:codex-auth-is-external-chatgpt-tokens
      (CodexAuthAgentIdentity $auth))
   False)

(= (codex:codex-auth-api-key-option (CodexAuthApiKey $api-key))
   $api-key)

(= (codex:codex-auth-api-key-option (CodexAuthChatgpt $token-data))
   CodexAbsent)

(= (codex:codex-auth-api-key-option
      (CodexAuthChatgptAuthTokens $token-data))
   CodexAbsent)

(= (codex:codex-auth-api-key-option (CodexAuthAgentIdentity $auth))
   CodexAbsent)

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

(= (codex:codex-auth-get-token (CodexAuthAgentIdentity $auth))
   (codex:codex-auth-token-result-err
     "agent identity auth does not expose a bearer token"))

(= (codex:codex-auth-get-account-id (CodexAuthApiKey $api-key))
   CodexAbsent)

(= (codex:codex-auth-get-account-id (CodexAuthChatgpt $token-data))
   (codex:token-data-account-id $token-data))

(= (codex:codex-auth-get-account-id (CodexAuthChatgptAuthTokens $token-data))
   (codex:token-data-account-id $token-data))

(= (codex:codex-auth-get-account-id (CodexAuthAgentIdentity $auth))
   (codex:agent-identity-auth-account-id $auth))

(= (codex:codex-auth-get-account-email (CodexAuthApiKey $api-key))
   CodexAbsent)

(= (codex:codex-auth-get-account-email (CodexAuthChatgpt $token-data))
   (codex:id-token-info-email
     (codex:token-data-id-token $token-data)))

(= (codex:codex-auth-get-account-email
      (CodexAuthChatgptAuthTokens $token-data))
   (codex:id-token-info-email
     (codex:token-data-id-token $token-data)))

(= (codex:codex-auth-get-account-email (CodexAuthAgentIdentity $auth))
   (codex:agent-identity-auth-email $auth))

(= (codex:codex-auth-get-chatgpt-user-id (CodexAuthApiKey $api-key))
   CodexAbsent)

(= (codex:codex-auth-get-chatgpt-user-id (CodexAuthChatgpt $token-data))
   (codex:id-token-info-chatgpt-user-id
     (codex:token-data-id-token $token-data)))

(= (codex:codex-auth-get-chatgpt-user-id
      (CodexAuthChatgptAuthTokens $token-data))
   (codex:id-token-info-chatgpt-user-id
     (codex:token-data-id-token $token-data)))

(= (codex:codex-auth-get-chatgpt-user-id
      (CodexAuthAgentIdentity $auth))
   (codex:agent-identity-auth-chatgpt-user-id $auth))

(= (codex:codex-auth-is-fedramp-account (CodexAuthApiKey $api-key))
   False)

(= (codex:codex-auth-is-fedramp-account (CodexAuthChatgpt $token-data))
   (codex:id-token-info-is-fedramp-account
     (codex:token-data-id-token $token-data)))

(= (codex:codex-auth-is-fedramp-account
      (CodexAuthChatgptAuthTokens $token-data))
   (codex:id-token-info-is-fedramp-account
     (codex:token-data-id-token $token-data)))

(= (codex:codex-auth-is-fedramp-account (CodexAuthAgentIdentity $auth))
   (codex:agent-identity-auth-is-fedramp-account $auth))

(= (codex:codex-auth-known-plan-account-plan-type $known-plan)
   (case $known-plan
     (((CodexAuthKnownPlanFree) (codex:plan-type-free))
      ((CodexAuthKnownPlanGo) (codex:plan-type-go))
      ((CodexAuthKnownPlanPlus) (codex:plan-type-plus))
      ((CodexAuthKnownPlanPro) (codex:plan-type-pro))
      ((CodexAuthKnownPlanProLite) (codex:plan-type-pro-lite))
      ((CodexAuthKnownPlanTeam) (codex:plan-type-team))
      ((CodexAuthKnownPlanSelfServeBusinessUsageBased)
       (codex:plan-type-self-serve-business-usage-based))
      ((CodexAuthKnownPlanBusiness) (codex:plan-type-business))
      ((CodexAuthKnownPlanEnterpriseCbpUsageBased)
       (codex:plan-type-enterprise-cbp-usage-based))
      ((CodexAuthKnownPlanEnterprise) (codex:plan-type-enterprise))
      ((CodexAuthKnownPlanEdu) (codex:plan-type-edu)))))

(= (codex:codex-auth-plan-type-account-plan-type CodexAbsent)
   (codex:plan-type-unknown))

(= (codex:codex-auth-plan-type-account-plan-type
      (CodexAuthPlanTypeKnown $known-plan))
   (codex:codex-auth-known-plan-account-plan-type $known-plan))

(= (codex:codex-auth-plan-type-account-plan-type
      (CodexAuthPlanTypeUnknown $raw))
   (codex:plan-type-unknown))

(= (codex:codex-auth-token-data-account-plan-type $token-data)
   (codex:codex-auth-plan-type-account-plan-type
     (codex:id-token-info-chatgpt-plan-type
       (codex:token-data-id-token $token-data))))

(= (codex:codex-auth-account-plan-type (CodexAuthApiKey $api-key))
   CodexAbsent)

(= (codex:codex-auth-account-plan-type (CodexAuthChatgpt $token-data))
   (codex:codex-auth-token-data-account-plan-type $token-data))

(= (codex:codex-auth-account-plan-type
      (CodexAuthChatgptAuthTokens $token-data))
   (codex:codex-auth-token-data-account-plan-type $token-data))

(= (codex:codex-auth-account-plan-type (CodexAuthAgentIdentity $auth))
   (codex:agent-identity-auth-plan-type $auth))

(= (codex:codex-auth-is-workspace-account $auth)
   (let $plan-type (codex:codex-auth-account-plan-type $auth)
     (if (== $plan-type CodexAbsent)
         False
         (codex:plan-type-is-workspace-account $plan-type))))

(= (codex:codex-auth-token-option $auth)
   (case (codex:codex-auth-get-token $auth)
     (((CodexAuthTokenResultOk $token)
       $token)
      ((CodexAuthTokenResultErr $message)
       CodexAbsent))))

(= (codex:agent-identity-auth-provider $auth)
   (CodexAgentIdentityAuthProvider $auth))

(= (codex:agent-identity-auth-provider-add-authorization-header
      $authorization-header
      $headers)
   (if (== $authorization-header CodexAbsent)
       $headers
       (codex:headers-insert $headers "authorization" $authorization-header)))

(= (codex:auth-provider-add-auth-headers
      (CodexAgentIdentityAuthProvider
        (CodexAgentIdentityAuth $record $process-task-id $authorization-header))
      $headers)
   (case (codex:agent-identity-auth-provider-add-authorization-header
           $authorization-header
           $headers)
     (($with-authorization
       (case (codex:headers-insert
               $with-authorization
               "ChatGPT-Account-ID"
               (codex:agent-identity-auth-record-account-id $record))
         (($with-account
           (if (codex:agent-identity-auth-record-is-fedramp-account $record)
               (codex:headers-insert
                 $with-account
                 "X-OpenAI-Fedramp"
                 "true")
               $with-account))))))))

(= (codex:auth-provider-from-auth $auth)
   (case $auth
     (((CodexAuthAgentIdentity $agent-identity-auth)
       (codex:agent-identity-auth-provider $agent-identity-auth))
      ((CodexAuthApiKey $api-key)
       (codex:bearer-auth-provider
         (codex:codex-auth-token-option $auth)
         (codex:codex-auth-get-account-id $auth)
         (codex:codex-auth-is-fedramp-account $auth)))
      ((CodexAuthChatgpt $token-data)
       (codex:bearer-auth-provider
         (codex:codex-auth-token-option $auth)
         (codex:codex-auth-get-account-id $auth)
         (codex:codex-auth-is-fedramp-account $auth)))
      ((CodexAuthChatgptAuthTokens $token-data)
       (codex:bearer-auth-provider
         (codex:codex-auth-token-option $auth)
         (codex:codex-auth-get-account-id $auth)
         (codex:codex-auth-is-fedramp-account $auth))))))
