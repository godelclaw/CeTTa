; Rust-faithful login token-data helper slice.
;
; This ports the pure data/helper surface from:
; - openai-codex/codex-rs/login/src/token_data.rs
;
; Covered in this increment:
; - TokenData and IdTokenInfo data shapes
; - IdTokenInfo helper methods over auth::PlanType
; - JWT payload decoding and IdClaims/AuthClaims field extraction
; - StandardJwtClaims expiration extraction

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

; CeTTa does not have chrono's DateTime<Utc> value kind yet. This preserves the
; Rust value semantics as UTC Unix timestamp seconds plus nanoseconds.
(= (codex:date-time-utc $seconds $nanoseconds)
   (CodexDateTimeUtc $seconds $nanoseconds))

(= (codex:date-time-utc-seconds (CodexDateTimeUtc $seconds $nanoseconds))
   $seconds)

(= (codex:date-time-utc-nanoseconds (CodexDateTimeUtc $seconds $nanoseconds))
   $nanoseconds)

(= (codex:date-time-utc-from-timestamp $seconds)
   (if (< $seconds -8334601228800)
       CodexAbsent
       (if (> $seconds 8210266876799)
           CodexAbsent
           (codex:date-time-utc $seconds 0))))

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

(= (codex:token-data-decimal-digit-value $digit)
   (case $digit
     (("0" 0)
      ("1" 1)
      ("2" 2)
      ("3" 3)
      ("4" 4)
      ("5" 5)
      ("6" 6)
      ("7" 7)
      ("8" 8)
      ("9" 9))))

(= (codex:token-data-is-decimal-digit $digit)
   (case $digit
     (("0" True)
      ("1" True)
      ("2" True)
      ("3" True)
      ("4" True)
      ("5" True)
      ("6" True)
      ("7" True)
      ("8" True)
      ("9" True)
      ($other False))))

(= (codex:token-data-is-unsigned-integer-text-from $text $index)
   (if (== $index (str-length $text))
       True
       (case (codex:token-data-is-decimal-digit
               (str-slice $text $index (+ $index 1)))
         ((True
           (codex:token-data-is-unsigned-integer-text-from
             $text
             (+ $index 1)))
          (False False)))))

(= (codex:token-data-is-unsigned-integer-text $text)
   (if (== $text "")
       False
       (codex:token-data-is-unsigned-integer-text-from $text 0)))

(= (codex:token-data-signed-integer-text-parts $text)
   (if (== (str-length $text) 0)
       CodexInvalidIntegerText
       (if (== (str-slice $text 0 1) "-")
           (let $digits (str-slice $text 1 (str-length $text))
             (case (codex:token-data-is-unsigned-integer-text $digits)
               ((True (CodexSignedIntegerText True $digits))
                (False CodexInvalidIntegerText))))
           (case (codex:token-data-is-unsigned-integer-text $text)
             ((True (CodexSignedIntegerText False $text))
              (False CodexInvalidIntegerText))))))

(= (codex:token-data-unsigned-digits-within-bound-from $digits $bound $index)
   (if (== $index (str-length $digits))
       True
       (let $lhs (codex:token-data-decimal-digit-value
                   (str-slice $digits $index (+ $index 1)))
         (let $rhs (codex:token-data-decimal-digit-value
                     (str-slice $bound $index (+ $index 1)))
           (if (< $lhs $rhs)
               True
               (if (> $lhs $rhs)
                   False
                   (codex:token-data-unsigned-digits-within-bound-from
                     $digits
                     $bound
                     (+ $index 1))))))))

(= (codex:token-data-unsigned-digits-within-bound $digits $bound)
   (if (< (str-length $digits) (str-length $bound))
       True
       (if (> (str-length $digits) (str-length $bound))
           False
           (codex:token-data-unsigned-digits-within-bound-from
             $digits
             $bound
             0))))

(= (codex:token-data-decimal-string-to-number $text)
   (codex:token-data-decimal-string-to-number-from $text 0 0))

(= (codex:token-data-decimal-string-to-number-from $text $index $acc)
   (if (== $index (str-length $text))
       $acc
       (let $digit-char (str-slice $text $index (+ $index 1))
         (codex:token-data-decimal-string-to-number-from
           $text
           (+ $index 1)
           (+ (* $acc 10)
              (codex:token-data-decimal-digit-value $digit-char))))))

(= (codex:token-data-exp-integer-from-parts
      (CodexSignedIntegerText True $digits))
   (case (codex:token-data-unsigned-digits-within-bound
           $digits
           "8334601228800")
     ((True
       (codex:id-token-info-parse-ok
         (- 0 (codex:token-data-decimal-string-to-number $digits))))
      (False
       (codex:id-token-info-parse-ok CodexAbsent)))))

(= (codex:token-data-exp-integer-from-parts
      (CodexSignedIntegerText False $digits))
   (case (codex:token-data-unsigned-digits-within-bound
           $digits
           "8210266876799")
     ((True
       (codex:id-token-info-parse-ok
         (codex:token-data-decimal-string-to-number $digits)))
      (False
       (codex:id-token-info-parse-ok CodexAbsent)))))

(= (codex:token-data-exp-integer-result $text)
   (case (codex:token-data-signed-integer-text-parts $text)
     ((CodexInvalidIntegerText
       (codex:id-token-info-parse-json-error
         "invalid type for `exp`; expected integer or null"))
      ($parts
       (codex:token-data-exp-integer-from-parts $parts)))))

(= (codex:token-data-json-object-optional-exp-result $object)
   (case (codex:token-data-json-object-optional-value $object "exp")
     ((CodexAbsent
       (codex:id-token-info-parse-ok CodexAbsent))
      ((JsonNumber $text)
       (codex:token-data-exp-integer-result $text))
      ($other
       (codex:id-token-info-parse-json-error
         "invalid type for `exp`; expected integer or null")))))

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

(= (codex:parse-jwt-expiration-object $object)
   (case (codex:token-data-json-object-optional-exp-result $object)
     (((CodexIdTokenInfoParseError $reason $message)
       (CodexIdTokenInfoParseError $reason $message))
      ((CodexIdTokenInfoParseOk CodexAbsent)
       (codex:id-token-info-parse-ok CodexAbsent))
      ((CodexIdTokenInfoParseOk $seconds)
       (codex:id-token-info-parse-ok
         (codex:date-time-utc-from-timestamp $seconds))))))

(= (codex:parse-jwt-expiration $jwt)
   (case (codex:decode-jwt-payload-json $jwt)
     (((CodexIdTokenInfoParseError $reason $message)
       (CodexIdTokenInfoParseError $reason $message))
      ((CodexIdTokenInfoParseOk (JsonObject $pairs))
       (codex:parse-jwt-expiration-object (JsonObject $pairs)))
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
