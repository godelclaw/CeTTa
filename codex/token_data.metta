; Rust-faithful login token-data helper slice.
;
; This ports the pure data/helper surface from:
; - openai-codex/codex-rs/login/src/token_data.rs
;
; Covered in this increment:
; - TokenData and IdTokenInfo data shapes
; - IdTokenInfo helper methods over auth::PlanType
;
; Pending runtime-library support:
; - JWT base64url decoding and serde claim parsing are not in this slice.

!(import! &self auth)

(= (codex:id-token-info
      $email
      $chatgpt-plan-type
      $chatgpt-user-id
      $chatgpt-account-id
      $chatgpt-account-is-fedramp
      $raw-jwt)
   (case $chatgpt-plan-type
     (($materialized-plan-type
       (CodexIdTokenInfo
         $email
         $materialized-plan-type
         $chatgpt-user-id
         $chatgpt-account-id
         $chatgpt-account-is-fedramp
         $raw-jwt)))))

(= (codex:default-id-token-info)
   (CodexIdTokenInfo
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     False
     ""))

(= (codex:id-token-info-email
      (CodexIdTokenInfo
        $email
        $chatgpt-plan-type
        $chatgpt-user-id
        $chatgpt-account-id
        $chatgpt-account-is-fedramp
        $raw-jwt))
   $email)

(= (codex:id-token-info-chatgpt-plan-type
      (CodexIdTokenInfo
        $email
        $chatgpt-plan-type
        $chatgpt-user-id
        $chatgpt-account-id
        $chatgpt-account-is-fedramp
        $raw-jwt))
   $chatgpt-plan-type)

(= (codex:id-token-info-chatgpt-user-id
      (CodexIdTokenInfo
        $email
        $chatgpt-plan-type
        $chatgpt-user-id
        $chatgpt-account-id
        $chatgpt-account-is-fedramp
        $raw-jwt))
   $chatgpt-user-id)

(= (codex:id-token-info-chatgpt-account-id
      (CodexIdTokenInfo
        $email
        $chatgpt-plan-type
        $chatgpt-user-id
        $chatgpt-account-id
        $chatgpt-account-is-fedramp
        $raw-jwt))
   $chatgpt-account-id)

(= (codex:id-token-info-chatgpt-account-is-fedramp
      (CodexIdTokenInfo
        $email
        $chatgpt-plan-type
        $chatgpt-user-id
        $chatgpt-account-id
        $chatgpt-account-is-fedramp
        $raw-jwt))
   $chatgpt-account-is-fedramp)

(= (codex:id-token-info-raw-jwt
      (CodexIdTokenInfo
        $email
        $chatgpt-plan-type
        $chatgpt-user-id
        $chatgpt-account-id
        $chatgpt-account-is-fedramp
        $raw-jwt))
   $raw-jwt)

(= (codex:id-token-info-chatgpt-plan-type-display CodexAbsent)
   CodexAbsent)

(= (codex:id-token-info-chatgpt-plan-type-display $chatgpt-plan-type)
   (case (codex:auth-plan-type-display-name $chatgpt-plan-type)
     (($display-name $display-name))))

(= (codex:id-token-info-get-chatgpt-plan-type $info)
   (case (codex:id-token-info-chatgpt-plan-type $info)
     (($chatgpt-plan-type
       (codex:id-token-info-chatgpt-plan-type-display
         $chatgpt-plan-type)))))

(= (codex:id-token-info-chatgpt-plan-type-raw CodexAbsent)
   CodexAbsent)

(= (codex:id-token-info-chatgpt-plan-type-raw $chatgpt-plan-type)
   (case (codex:auth-plan-type-raw-value $chatgpt-plan-type)
     (($raw-value $raw-value))))

(= (codex:id-token-info-get-chatgpt-plan-type-raw $info)
   (case (codex:id-token-info-chatgpt-plan-type $info)
     (($chatgpt-plan-type
       (codex:id-token-info-chatgpt-plan-type-raw
         $chatgpt-plan-type)))))

(= (codex:id-token-info-plan-is-workspace-account CodexAbsent)
   False)

(= (codex:id-token-info-plan-is-workspace-account
      (CodexAuthPlanTypeKnown $known-plan))
   (codex:auth-known-plan-is-workspace-account $known-plan))

(= (codex:id-token-info-plan-is-workspace-account
      (CodexAuthPlanTypeUnknown $raw))
   False)

(= (codex:id-token-info-is-workspace-account $info)
   (case (codex:id-token-info-chatgpt-plan-type $info)
     (($chatgpt-plan-type
       (codex:id-token-info-plan-is-workspace-account
         $chatgpt-plan-type)))))

(= (codex:id-token-info-is-fedramp-account $info)
   (codex:id-token-info-chatgpt-account-is-fedramp $info))

(= (codex:token-data $id-token $access-token $refresh-token $account-id)
   (case $id-token
     (($materialized-id-token
       (CodexTokenData
         $materialized-id-token
         $access-token
         $refresh-token
         $account-id)))))

(= (codex:token-data-id-token
      (CodexTokenData $id-token $access-token $refresh-token $account-id))
   $id-token)

(= (codex:token-data-access-token
      (CodexTokenData $id-token $access-token $refresh-token $account-id))
   $access-token)

(= (codex:token-data-refresh-token
      (CodexTokenData $id-token $access-token $refresh-token $account-id))
   $refresh-token)

(= (codex:token-data-account-id
      (CodexTokenData $id-token $access-token $refresh-token $account-id))
   $account-id)
