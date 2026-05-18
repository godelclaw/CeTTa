; Rust-faithful login token-data helper slice.
;
; This ports the pure data/helper surface from:
; - openai-codex/codex-rs/login/src/token_data.rs
;
; Covered in this increment:
; - TokenData and IdTokenInfo data shapes
; - IdTokenInfo helper methods over auth::PlanType
; - JWT payload decoding and IdClaims/AuthClaims field extraction

!(import! &self auth)
!(import! &self json)
!(import! &self str)
!(import! &self str_base64url)

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

(= (codex:id-token-info-parse-ok $value)
   (CodexIdTokenInfoParseOk $value))

(= (codex:id-token-info-parse-error $reason $message)
   (CodexIdTokenInfoParseError $reason $message))

(= (codex:id-token-info-error-invalid-format)
   CodexIdTokenInfoErrorInvalidFormat)

(= (codex:id-token-info-error-base64)
   CodexIdTokenInfoErrorBase64)

(= (codex:id-token-info-error-json)
   CodexIdTokenInfoErrorJson)

(= (codex:id-token-info-parse-result-value
      (CodexIdTokenInfoParseOk $value))
   $value)

(= (codex:id-token-info-parse-result-reason
      (CodexIdTokenInfoParseError $reason $message))
   $reason)

(= (codex:id-token-info-parse-result-message
      (CodexIdTokenInfoParseError $reason $message))
   $message)

(= (codex:id-token-info-parse-invalid-format)
   (codex:id-token-info-parse-error
     (codex:id-token-info-error-invalid-format)
     "invalid ID token format"))

(= (codex:id-token-info-parse-base64-error $message)
   (codex:id-token-info-parse-error
     (codex:id-token-info-error-base64)
     $message))

(= (codex:id-token-info-parse-json-error $message)
   (codex:id-token-info-parse-error
     (codex:id-token-info-error-json)
     $message))

(= (codex:jwt-parts-three $header $payload $signature)
   (if (== $header "")
       (codex:id-token-info-parse-invalid-format)
       (if (== $payload "")
           (codex:id-token-info-parse-invalid-format)
           (if (== $signature "")
               (codex:id-token-info-parse-invalid-format)
               (CodexJwtParts $header $payload $signature)))))

(= (codex:jwt-parts $jwt)
   (case (str-split "." $jwt)
     ((($header $payload $signature)
       (codex:jwt-parts-three $header $payload $signature))
      ($other
       (codex:id-token-info-parse-invalid-format)))))

(= (codex:parse-jwt-payload-json-text $payload-text)
   (case (json-parse $payload-text)
     (((Error $source $message)
       (codex:id-token-info-parse-json-error $message))
      ($json
       (codex:id-token-info-parse-ok $json)))))

(= (codex:decode-jwt-payload-text $payload)
   (case (str-base64url-decode $payload)
     (((Error $source $message)
       (codex:id-token-info-parse-base64-error $message))
      ($payload-text
       (codex:parse-jwt-payload-json-text $payload-text)))))

(= (codex:decode-jwt-payload-json $jwt)
   (case (codex:jwt-parts $jwt)
      (((CodexJwtParts $header $payload $signature)
       (codex:decode-jwt-payload-text $payload))
      ((CodexIdTokenInfoParseError $reason $message)
       (CodexIdTokenInfoParseError $reason $message)))))

(= (codex:token-data-json-object-optional-value $object $key)
   (case (json-object-get $object $key)
     ((Empty CodexAbsent)
      (JsonNull CodexAbsent)
      ($value $value))))

(= (codex:token-data-json-object-optional-string-result $object $key)
   (case (codex:token-data-json-object-optional-value $object $key)
     ((CodexAbsent
       (codex:id-token-info-parse-ok CodexAbsent))
      ((JsonString $text)
       (codex:id-token-info-parse-ok $text))
      ($other
       (codex:id-token-info-parse-json-error
         (format-args "invalid type for `{}`; expected string or null" ($key)))))))

(= (codex:token-data-json-object-optional-object-result $object $key)
   (case (codex:token-data-json-object-optional-value $object $key)
     ((CodexAbsent
       (codex:id-token-info-parse-ok CodexAbsent))
      ((JsonObject $pairs)
       (codex:id-token-info-parse-ok (JsonObject $pairs)))
      ($other
       (codex:id-token-info-parse-json-error
         (format-args "invalid type for `{}`; expected object or null" ($key)))))))

(= (codex:token-data-json-object-optional-bool-default-false-result $object $key)
   (case (codex:token-data-json-object-optional-value $object $key)
     ((CodexAbsent
       (codex:id-token-info-parse-ok False))
      ((JsonBool $value)
       (codex:id-token-info-parse-ok $value))
      ($other
       (codex:id-token-info-parse-json-error
         (format-args "invalid type for `{}`; expected bool or null" ($key)))))))

(= (codex:token-data-json-object-optional-plan-result $object $key)
   (case (codex:token-data-json-object-optional-value $object $key)
     ((CodexAbsent
       (codex:id-token-info-parse-ok CodexAbsent))
      ((JsonString $raw)
       (codex:id-token-info-parse-ok
         (codex:auth-plan-type-from-raw-value $raw)))
      ($other
       (codex:id-token-info-parse-json-error
         (format-args "invalid type for `{}`; expected string or null" ($key)))))))

(= (codex:token-data-optional-or $lhs $rhs)
   (if (== $lhs CodexAbsent)
       $rhs
       $lhs))

(= (codex:token-data-profile-email-result $object)
   (case (codex:token-data-json-object-optional-object-result
           $object
           "https://api.openai.com/profile")
     (((CodexIdTokenInfoParseError $reason $message)
       (CodexIdTokenInfoParseError $reason $message))
      ((CodexIdTokenInfoParseOk CodexAbsent)
       (codex:id-token-info-parse-ok CodexAbsent))
      ((CodexIdTokenInfoParseOk (JsonObject $profile-pairs))
       (codex:token-data-json-object-optional-string-result
         (JsonObject $profile-pairs)
         "email")))))

(= (codex:token-data-email-or-profile-email $email $profile-email)
   (if (== $email CodexAbsent)
       $profile-email
       $email))

(= (codex:parse-chatgpt-auth-fedramp
      $jwt
      $email
      $plan-type
      $chatgpt-user-id
      $user-id
      $chatgpt-account-id
      $auth-object)
   (case (codex:token-data-json-object-optional-bool-default-false-result
           $auth-object
           "chatgpt_account_is_fedramp")
     (((CodexIdTokenInfoParseError $reason $message)
       (CodexIdTokenInfoParseError $reason $message))
      ((CodexIdTokenInfoParseOk $chatgpt-account-is-fedramp)
       (codex:id-token-info-parse-ok
         (codex:id-token-info
           $email
           $plan-type
           (codex:token-data-optional-or $chatgpt-user-id $user-id)
           $chatgpt-account-id
           $chatgpt-account-is-fedramp
           $jwt))))))

(= (codex:parse-chatgpt-auth-account-id
      $jwt
      $email
      $plan-type
      $chatgpt-user-id
      $user-id
      $auth-object)
   (case (codex:token-data-json-object-optional-string-result
           $auth-object
           "chatgpt_account_id")
     (((CodexIdTokenInfoParseError $reason $message)
       (CodexIdTokenInfoParseError $reason $message))
      ((CodexIdTokenInfoParseOk $chatgpt-account-id)
       (codex:parse-chatgpt-auth-fedramp
         $jwt
         $email
         $plan-type
         $chatgpt-user-id
         $user-id
         $chatgpt-account-id
         $auth-object)))))

(= (codex:parse-chatgpt-auth-user-id
      $jwt
      $email
      $plan-type
      $chatgpt-user-id
      $auth-object)
   (case (codex:token-data-json-object-optional-string-result
           $auth-object
           "user_id")
     (((CodexIdTokenInfoParseError $reason $message)
       (CodexIdTokenInfoParseError $reason $message))
      ((CodexIdTokenInfoParseOk $user-id)
       (codex:parse-chatgpt-auth-account-id
         $jwt
         $email
         $plan-type
         $chatgpt-user-id
         $user-id
         $auth-object)))))

(= (codex:parse-chatgpt-auth-chatgpt-user-id
      $jwt
      $email
      $plan-type
      $auth-object)
   (case (codex:token-data-json-object-optional-string-result
           $auth-object
           "chatgpt_user_id")
     (((CodexIdTokenInfoParseError $reason $message)
       (CodexIdTokenInfoParseError $reason $message))
      ((CodexIdTokenInfoParseOk $chatgpt-user-id)
       (codex:parse-chatgpt-auth-user-id
         $jwt
         $email
         $plan-type
         $chatgpt-user-id
         $auth-object)))))

(= (codex:parse-chatgpt-auth-claims-object $jwt $email $auth-object)
   (case (codex:token-data-json-object-optional-plan-result
           $auth-object
           "chatgpt_plan_type")
     (((CodexIdTokenInfoParseError $reason $message)
       (CodexIdTokenInfoParseError $reason $message))
      ((CodexIdTokenInfoParseOk $plan-type)
       (codex:parse-chatgpt-auth-chatgpt-user-id
         $jwt
         $email
         $plan-type
         $auth-object)))))

(= (codex:parse-chatgpt-id-claims-auth
      $jwt
      $object
      $email)
   (case (codex:token-data-json-object-optional-object-result
           $object
           "https://api.openai.com/auth")
     (((CodexIdTokenInfoParseError $reason $message)
       (CodexIdTokenInfoParseError $reason $message))
      ((CodexIdTokenInfoParseOk CodexAbsent)
       (codex:id-token-info-parse-ok
         (codex:id-token-info
           $email
           CodexAbsent
           CodexAbsent
           CodexAbsent
           False
           $jwt)))
      ((CodexIdTokenInfoParseOk (JsonObject $auth-pairs))
       (codex:parse-chatgpt-auth-claims-object
         $jwt
         $email
         (JsonObject $auth-pairs))))))

(= (codex:parse-chatgpt-id-claims-profile
      $jwt
      $object
      $email)
   (case (codex:token-data-profile-email-result $object)
     (((CodexIdTokenInfoParseError $reason $message)
       (CodexIdTokenInfoParseError $reason $message))
      ((CodexIdTokenInfoParseOk $profile-email)
       (codex:parse-chatgpt-id-claims-auth
         $jwt
         $object
         (codex:token-data-email-or-profile-email
           $email
           $profile-email))))))

(= (codex:parse-chatgpt-id-claims-object $jwt $object)
   (case (codex:token-data-json-object-optional-string-result $object "email")
     (((CodexIdTokenInfoParseError $reason $message)
       (CodexIdTokenInfoParseError $reason $message))
      ((CodexIdTokenInfoParseOk $email)
       (codex:parse-chatgpt-id-claims-profile
         $jwt
         $object
         $email)))))

(= (codex:parse-chatgpt-jwt-claims $jwt)
   (case (codex:decode-jwt-payload-json $jwt)
     (((CodexIdTokenInfoParseError $reason $message)
       (CodexIdTokenInfoParseError $reason $message))
      ((CodexIdTokenInfoParseOk (JsonObject $pairs))
       (codex:parse-chatgpt-id-claims-object
         $jwt
         (JsonObject $pairs)))
      ((CodexIdTokenInfoParseOk $other)
       (codex:id-token-info-parse-json-error
         "invalid JWT payload JSON; expected object")))))

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
