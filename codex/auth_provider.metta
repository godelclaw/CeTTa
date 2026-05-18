; Rust-faithful header-auth provider slice.
;
; This ports the pure/header-only behavior from:
; - openai-codex/codex-rs/codex-api/src/auth.rs
; - openai-codex/codex-rs/model-provider/src/bearer_auth_provider.rs
; - openai-codex/codex-rs/model-provider/src/auth.rs unauthenticated provider
;
; Required CeTTa representation notes for audit:
; - Rust uses `dyn AuthProvider`, `Arc`, async `apply_auth`, and `HeaderMap`.
;   CeTTa does not have that trait/runtime object layer in this port yet, so
;   header-only providers are represented as tagged atoms and dispatched through
;   `codex:auth-provider-add-auth-headers`.
; - HeaderMap is represented as a list of `CodexHeader` values. Insertion keeps
;   Rust HeaderMap replacement semantics by removing any existing case-insensitive
;   key before consing the new header.
; - Rust `HeaderValue::from_str` validates byte-level HTTP header values. CeTTa's
;   current string surface does not expose byte classification, so this slice
;   rejects CR/LF injection and leaves full byte validation to a future HTTP lib.

!(import! &self list)
!(import! &self str)

(= (codex:auth-error-build $message)
   (CodexAuthErrorBuild $message))

(= (codex:auth-error-transient $message)
   (CodexAuthErrorTransient $message))

(= (codex:header $name $value)
   (CodexHeader $name $value))

(= (codex:header-name (CodexHeader $name $value))
   $name)

(= (codex:header-value (CodexHeader $name $value))
   $value)

(= (codex:auth-provider-ascii-lower-char $char)
   (case $char
     (("A" "a") ("B" "b") ("C" "c") ("D" "d") ("E" "e") ("F" "f")
      ("G" "g") ("H" "h") ("I" "i") ("J" "j") ("K" "k") ("L" "l")
      ("M" "m") ("N" "n") ("O" "o") ("P" "p") ("Q" "q") ("R" "r")
      ("S" "s") ("T" "t") ("U" "u") ("V" "v") ("W" "w") ("X" "x")
      ("Y" "y") ("Z" "z")
      ($other $other))))

(= (codex:auth-provider-ascii-lower-text $text)
   (if (== (str-length $text) 0)
       ""
       (str-concat
         (codex:auth-provider-ascii-lower-char (str-slice $text 0 1))
         (codex:auth-provider-ascii-lower-text
           (str-slice $text 1 (str-length $text))))))

(= (codex:header-name-eq $lhs $rhs)
   (== (codex:auth-provider-ascii-lower-text $lhs)
       (codex:auth-provider-ascii-lower-text $rhs)))

(= (codex:auth-provider-text-contains $text $needle)
   (> (list:len (str-split $needle $text)) 1))

(= (codex:header-value-valid $value)
   (if (codex:auth-provider-text-contains $value "\n")
       False
       (if (codex:auth-provider-text-contains $value "\r")
           False
           True)))

(= (codex:headers-remove $headers $name)
   (if (== $headers ())
       ()
       (let ($head $tail) (decons-atom $headers)
         (case (codex:headers-remove $tail $name)
           (($rest
             (if (codex:header-name-eq (codex:header-name $head) $name)
                 $rest
                 (cons-atom $head $rest))))))))

(= (codex:headers-insert $headers $name $value)
   (if (codex:header-value-valid $value)
       (cons-atom
         (codex:header $name $value)
         (codex:headers-remove $headers $name))
       $headers))

(= (codex:headers-get $headers $name)
   (if (== $headers ())
       CodexAbsent
       (let ($head $tail) (decons-atom $headers)
         (if (codex:header-name-eq (codex:header-name $head) $name)
             (codex:header-value $head)
             (case (codex:headers-get $tail $name)
               (($found $found)))))))

(= (codex:headers-contains-key $headers $name)
   (if (== (codex:headers-get $headers $name) CodexAbsent)
       False
       True))

(= (codex:auth-header-telemetry $attached $name)
   (CodexAuthHeaderTelemetry $attached $name))

(= (codex:auth-header-telemetry-attached
      (CodexAuthHeaderTelemetry $attached $name))
   $attached)

(= (codex:auth-header-telemetry-name
      (CodexAuthHeaderTelemetry $attached $name))
   $name)

(= (codex:auth-header-telemetry-from-headers $headers)
   (if (codex:headers-contains-key $headers "authorization")
       (codex:auth-header-telemetry True "authorization")
       (codex:auth-header-telemetry False CodexAbsent)))

(= (codex:auth-header-telemetry $auth-provider)
   (codex:auth-header-telemetry-from-headers
     (codex:auth-provider-to-auth-headers $auth-provider)))

(= (codex:unauthenticated-auth-provider)
   (CodexUnauthenticatedAuthProvider))

(= (codex:auth-provider-add-auth-headers
      (CodexUnauthenticatedAuthProvider)
      $headers)
   $headers)

(= (codex:bearer-auth-provider $token $account-id $is-fedramp-account)
   (CodexBearerAuthProvider $token $account-id $is-fedramp-account))

(= (codex:bearer-auth-provider-new $token)
   (codex:bearer-auth-provider $token CodexAbsent False))

(= (codex:bearer-auth-provider-for-test $token $account-id)
   (codex:bearer-auth-provider $token $account-id False))

(= (codex:bearer-auth-provider-token
      (CodexBearerAuthProvider $token $account-id $is-fedramp-account))
   $token)

(= (codex:bearer-auth-provider-account-id
      (CodexBearerAuthProvider $token $account-id $is-fedramp-account))
   $account-id)

(= (codex:bearer-auth-provider-is-fedramp-account
      (CodexBearerAuthProvider $token $account-id $is-fedramp-account))
   $is-fedramp-account)

(= (codex:bearer-auth-provider-add-token-header $token $headers)
   (if (== $token CodexAbsent)
       $headers
       (codex:headers-insert
         $headers
         "authorization"
         (str-concat "Bearer " $token))))

(= (codex:bearer-auth-provider-add-account-header $account-id $headers)
   (if (== $account-id CodexAbsent)
       $headers
       (codex:headers-insert
         $headers
         "ChatGPT-Account-ID"
         $account-id)))

(= (codex:bearer-auth-provider-add-fedramp-header False $headers)
   $headers)

(= (codex:bearer-auth-provider-add-fedramp-header True $headers)
   (codex:headers-insert $headers "X-OpenAI-Fedramp" "true"))

(= (codex:auth-provider-add-auth-headers
      (CodexBearerAuthProvider $token $account-id $is-fedramp-account)
      $headers)
   (case (codex:bearer-auth-provider-add-token-header $token $headers)
     (($with-token
       (case (codex:bearer-auth-provider-add-account-header
               $account-id
               $with-token)
         (($with-account
           (codex:bearer-auth-provider-add-fedramp-header
             $is-fedramp-account
             $with-account))))))))

(= (codex:auth-provider-to-auth-headers $auth-provider)
   (codex:auth-provider-add-auth-headers $auth-provider ()))
