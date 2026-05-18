; Rust-faithful pure agent-identity helper slice.
;
; This ports the pure data and URL helper surface from:
; - openai-codex/codex-rs/agent-identity/src/lib.rs
;
; Covered in this increment:
; - AgentIdentityKey / AgentTaskAuthorizationTarget data shapes
; - AgentBillOfMaterials / build_abom
; - AgentAssertionEnvelope serialization and RegisterTaskRequest JSON shape
; - RegisterTaskResponse parsing and task-id selection branch order
; - signing/decryption seam control flow and Rust error messages
; - agent_identity_request_id
; - agent_registration_url, agent_task_registration_url, agent_identity_biscuit_url
; - normalize_chatgpt_base_url
;
; Required CeTTa representation notes for audit:
; - Rust signing/decryption/key-material helpers depend on Ed25519 PKCS#8,
;   SHA-512, and crypto_box seal support. Those are runtime-library work, not
;   pure MeTTa rewrites, and are intentionally not claimed by this helper slice.
; - task-id selection exposes a `with-decryption-result` seam so direct and
;   missing-id Rust branches are exact while encrypted-id decryption waits for
;   the crypto runtime helper.
; - signing-key and decrypt helpers below model Rust's result/error flow with
;   injected crypto-step results. They intentionally do not implement Ed25519,
;   PKCS#8, base64 decode, crypto_box unseal, or byte-level UTF-8 decoding.

!(import! &self str)
!(import! &self system)
!(import! &self protocol)
!(import! &self json)
!(import! &self str_base64url)

(= (codex:agent-identity-key
      $agent-runtime-id
      $private-key-pkcs8-base64)
   (CodexAgentIdentityKey
     $agent-runtime-id
     $private-key-pkcs8-base64))

(= (codex:agent-identity-key-agent-runtime-id
      (CodexAgentIdentityKey $agent-runtime-id $private-key-pkcs8-base64))
   $agent-runtime-id)

(= (codex:agent-identity-key-private-key-pkcs8-base64
      (CodexAgentIdentityKey $agent-runtime-id $private-key-pkcs8-base64))
   $private-key-pkcs8-base64)

(= (codex:agent-task-authorization-target
      $agent-runtime-id
      $task-id)
   (CodexAgentTaskAuthorizationTarget $agent-runtime-id $task-id))

(= (codex:agent-task-authorization-target-agent-runtime-id
      (CodexAgentTaskAuthorizationTarget $agent-runtime-id $task-id))
   $agent-runtime-id)

(= (codex:agent-task-authorization-target-task-id
      (CodexAgentTaskAuthorizationTarget $agent-runtime-id $task-id))
   $task-id)

(= (codex:agent-bill-of-materials
      $agent-version
      $agent-harness-id
      $running-location)
   (CodexAgentBillOfMaterials
     $agent-version
     $agent-harness-id
     $running-location))

(= (codex:agent-bill-of-materials-agent-version
      (CodexAgentBillOfMaterials
        $agent-version
        $agent-harness-id
        $running-location))
   $agent-version)

(= (codex:agent-bill-of-materials-agent-harness-id
      (CodexAgentBillOfMaterials
        $agent-version
        $agent-harness-id
        $running-location))
   $agent-harness-id)

(= (codex:agent-bill-of-materials-running-location
      (CodexAgentBillOfMaterials
        $agent-version
        $agent-harness-id
        $running-location))
   $running-location)

(= (codex:agent-assertion-envelope
      $agent-runtime-id
      $task-id
      $timestamp
      $signature)
   (CodexAgentAssertionEnvelope
     $agent-runtime-id
     $task-id
     $timestamp
     $signature))

(= (codex:agent-assertion-envelope-agent-runtime-id
      (CodexAgentAssertionEnvelope
        $agent-runtime-id
        $task-id
        $timestamp
        $signature))
   $agent-runtime-id)

(= (codex:agent-assertion-envelope-task-id
      (CodexAgentAssertionEnvelope
        $agent-runtime-id
        $task-id
        $timestamp
        $signature))
   $task-id)

(= (codex:agent-assertion-envelope-timestamp
      (CodexAgentAssertionEnvelope
        $agent-runtime-id
        $task-id
        $timestamp
        $signature))
   $timestamp)

(= (codex:agent-assertion-envelope-signature
      (CodexAgentAssertionEnvelope
        $agent-runtime-id
        $task-id
        $timestamp
        $signature))
   $signature)

(= (codex:agent-assertion-envelope-json
      (CodexAgentAssertionEnvelope
        $agent-runtime-id
        $task-id
        $timestamp
        $signature))
   (JsonObject
     ((JsonPair "agent_runtime_id" (JsonString $agent-runtime-id))
      (JsonPair "signature" (JsonString $signature))
      (JsonPair "task_id" (JsonString $task-id))
      (JsonPair "timestamp" (JsonString $timestamp)))))

(= (codex:serialize-agent-assertion $envelope)
   ; Rust serializes a BTreeMap, so field order is lexicographic.
   (case (json-stringify (codex:agent-assertion-envelope-json $envelope))
     (($payload
       (str-base64url-encode-no-pad $payload)))))

(= (codex:agent-identity-auth-header-ok $header)
   (CodexAgentIdentityAuthHeaderOk $header))

(= (codex:agent-identity-auth-header-err $message)
   (CodexAgentIdentityAuthHeaderErr $message))

(= (codex:agent-identity-auth-header-value
      (CodexAgentIdentityAuthHeaderOk $header))
   $header)

(= (codex:agent-identity-auth-header-error
      (CodexAgentIdentityAuthHeaderErr $message))
   $message)

(= (codex:agent-identity-string-result-ok $value)
   (CodexAgentIdentityStringResultOk $value))

(= (codex:agent-identity-string-result-err $message)
   (CodexAgentIdentityStringResultErr $message))

(= (codex:agent-identity-string-result-value
      (CodexAgentIdentityStringResultOk $value))
   $value)

(= (codex:agent-identity-string-result-error
      (CodexAgentIdentityStringResultErr $message))
   $message)

(= (codex:agent-identity-crypto-step-ok $value)
   (CodexAgentIdentityCryptoStepOk $value))

(= (codex:agent-identity-crypto-step-err $message)
   (CodexAgentIdentityCryptoStepErr $message))

(= (codex:agent-identity-error-stored-private-key-base64)
   "stored agent identity private key is not valid base64")

(= (codex:agent-identity-error-stored-private-key-pkcs8)
   "stored agent identity private key is not valid PKCS#8")

(= (codex:agent-identity-error-encrypted-task-id-base64)
   "encrypted task id is not valid base64")

(= (codex:agent-identity-error-decrypt-encrypted-task-id)
   "failed to decrypt encrypted task id")

(= (codex:agent-identity-error-decrypted-task-id-utf8)
   "decrypted task id is not valid UTF-8")

(= (codex:signing-key-from-private-key-pkcs8-base64-with-crypto-results
      $private-key-pkcs8-base64
      $private-key-base64-result
      $pkcs8-result)
   (case $private-key-base64-result
     (((CodexAgentIdentityCryptoStepErr $message)
       (codex:agent-identity-string-result-err
         (codex:agent-identity-error-stored-private-key-base64)))
      ((CodexAgentIdentityCryptoStepOk $private-key-der)
       (case $pkcs8-result
         (((CodexAgentIdentityCryptoStepErr $pkcs8-message)
           (codex:agent-identity-string-result-err
             (codex:agent-identity-error-stored-private-key-pkcs8)))
          ((CodexAgentIdentityCryptoStepOk $signing-key)
           (codex:agent-identity-string-result-ok $signing-key))))))))

(= (codex:signing-key-from-agent-identity-key-with-crypto-results
      $key
      $private-key-base64-result
      $pkcs8-result)
   (codex:signing-key-from-private-key-pkcs8-base64-with-crypto-results
     (codex:agent-identity-key-private-key-pkcs8-base64 $key)
     $private-key-base64-result
     $pkcs8-result))

(= (codex:task-registration-signing-payload $key $timestamp)
   (str-concat
     (str-concat
       (codex:agent-identity-key-agent-runtime-id $key)
       ":")
     $timestamp))

(= (codex:agent-assertion-signing-payload $key $task-id $timestamp)
   (str-concat
     (str-concat
       (str-concat
         (str-concat
           (codex:agent-identity-key-agent-runtime-id $key)
           ":")
         $task-id)
       ":")
     $timestamp))

(= (codex:sign-task-registration-payload-with-signature-result
      $key
      $timestamp
      $signing-key-result
      $signature-base64)
   (case $signing-key-result
     (((CodexAgentIdentityStringResultErr $message)
       (codex:agent-identity-string-result-err $message))
      ((CodexAgentIdentityStringResultOk $signing-key)
       (codex:agent-identity-string-result-ok $signature-base64)))))

(= (codex:decrypt-task-id-response-with-crypto-results
      $key
      $encrypted-task-id
      $signing-key-result
      $encrypted-task-id-base64-result
      $unseal-result
      $utf8-result)
   (case $signing-key-result
     (((CodexAgentIdentityStringResultErr $message)
       (codex:agent-identity-string-result-err $message))
      ((CodexAgentIdentityStringResultOk $signing-key)
       (case $encrypted-task-id-base64-result
         (((CodexAgentIdentityCryptoStepErr $base64-message)
           (codex:agent-identity-string-result-err
             (codex:agent-identity-error-encrypted-task-id-base64)))
          ((CodexAgentIdentityCryptoStepOk $ciphertext)
           (case $unseal-result
             (((CodexAgentIdentityCryptoStepErr $unseal-message)
               (codex:agent-identity-string-result-err
                 (codex:agent-identity-error-decrypt-encrypted-task-id)))
              ((CodexAgentIdentityCryptoStepOk $plaintext-bytes)
               (case $utf8-result
                 (((CodexAgentIdentityCryptoStepErr $utf8-message)
                   (codex:agent-identity-string-result-err
                     (codex:agent-identity-error-decrypted-task-id-utf8)))
                  ((CodexAgentIdentityCryptoStepOk $plaintext)
                   (codex:agent-identity-string-result-ok $plaintext))))))))))))))

(= (codex:authorization-header-for-agent-task-with-signature-timestamp
      $key
      $target
      $signature
      $timestamp)
   ; Same Rust control flow with signing/time injected until Ed25519 support lands.
   (let $key-runtime-id
     (codex:agent-identity-key-agent-runtime-id $key)
     (let $target-runtime-id
       (codex:agent-task-authorization-target-agent-runtime-id $target)
       (if (== $key-runtime-id $target-runtime-id)
           (codex:agent-identity-auth-header-ok
             (str-concat
               "AgentAssertion "
               (codex:serialize-agent-assertion
                 (codex:agent-assertion-envelope
                   $target-runtime-id
                   (codex:agent-task-authorization-target-task-id $target)
                   $timestamp
                   $signature))))
           (codex:agent-identity-auth-header-err
             (str-concat
               (str-concat
                 (str-concat
                   "agent task runtime "
                   $target-runtime-id)
                 " does not match stored agent identity ")
               $key-runtime-id))))))

(= (codex:register-task-request $timestamp $signature)
   (CodexRegisterTaskRequest $timestamp $signature))

(= (codex:register-task-request-timestamp
      (CodexRegisterTaskRequest $timestamp $signature))
   $timestamp)

(= (codex:register-task-request-signature
      (CodexRegisterTaskRequest $timestamp $signature))
   $signature)

(= (codex:register-task-request-json
      (CodexRegisterTaskRequest $timestamp $signature))
   (JsonObject
     ((JsonPair "timestamp" (JsonString $timestamp))
      (JsonPair "signature" (JsonString $signature)))))

(= (codex:agent-task-registration-timeout-seconds)
   30)

(= (codex:register-task-response
      $task-id
      $task-id-camel
      $encrypted-task-id
      $encrypted-task-id-camel)
   (CodexRegisterTaskResponse
     $task-id
     $task-id-camel
     $encrypted-task-id
     $encrypted-task-id-camel))

(= (codex:register-task-response-task-id
      (CodexRegisterTaskResponse
        $task-id
        $task-id-camel
        $encrypted-task-id
        $encrypted-task-id-camel))
   $task-id)

(= (codex:register-task-response-task-id-camel
      (CodexRegisterTaskResponse
        $task-id
        $task-id-camel
        $encrypted-task-id
        $encrypted-task-id-camel))
   $task-id-camel)

(= (codex:register-task-response-encrypted-task-id
      (CodexRegisterTaskResponse
        $task-id
        $task-id-camel
        $encrypted-task-id
        $encrypted-task-id-camel))
   $encrypted-task-id)

(= (codex:register-task-response-encrypted-task-id-camel
      (CodexRegisterTaskResponse
        $task-id
        $task-id-camel
        $encrypted-task-id
        $encrypted-task-id-camel))
   $encrypted-task-id-camel)

(= (codex:agent-identity-json-object-optional-value $object $key)
   (case (json-object-get $object $key)
     ((Empty CodexAbsent)
      (JsonNull CodexAbsent)
      ($value $value))))

(= (codex:agent-identity-json-object-optional-string $object $key)
   (case (codex:agent-identity-json-object-optional-value $object $key)
     ((CodexAbsent CodexAbsent)
      ((JsonString $value) $value))))

(= (codex:register-task-response-from-json $object)
   (codex:register-task-response
     (codex:agent-identity-json-object-optional-string $object "task_id")
     (codex:agent-identity-json-object-optional-string $object "taskId")
     (codex:agent-identity-json-object-optional-string $object "encrypted_task_id")
     (codex:agent-identity-json-object-optional-string $object "encryptedTaskId")))

(= (codex:register-task-response-selected-task-id $response)
   (let $task-id
     (codex:register-task-response-task-id $response)
     (if (== $task-id CodexAbsent)
         (codex:register-task-response-task-id-camel $response)
         $task-id)))

(= (codex:register-task-response-selected-encrypted-task-id $response)
   (let $encrypted-task-id
     (codex:register-task-response-encrypted-task-id $response)
     (if (== $encrypted-task-id CodexAbsent)
         (codex:register-task-response-encrypted-task-id-camel $response)
         $encrypted-task-id)))

(= (codex:agent-task-id-result-ok $task-id)
   (CodexAgentTaskIdResultOk $task-id))

(= (codex:agent-task-id-result-err $message)
   (CodexAgentTaskIdResultErr $message))

(= (codex:agent-task-id-result-value
      (CodexAgentTaskIdResultOk $task-id))
   $task-id)

(= (codex:agent-task-id-result-error
      (CodexAgentTaskIdResultErr $message))
   $message)

(= (codex:agent-task-id-result-from-agent-identity-string-result
      (CodexAgentIdentityStringResultOk $value))
   (codex:agent-task-id-result-ok $value))

(= (codex:agent-task-id-result-from-agent-identity-string-result
      (CodexAgentIdentityStringResultErr $message))
   (codex:agent-task-id-result-err $message))

(= (codex:task-id-from-register-task-response-with-agent-identity-decryption-result
      $key
      $response
      $decryption-result)
   (codex:task-id-from-register-task-response-with-decryption-result
     $key
     $response
     (codex:agent-task-id-result-from-agent-identity-string-result
       $decryption-result)))

(= (codex:task-id-from-register-task-response-with-decryption-result
      $key
      $response
      $decryption-result)
   (let $task-id
     (codex:register-task-response-selected-task-id $response)
     (if (== $task-id CodexAbsent)
         (let $encrypted-task-id
           (codex:register-task-response-selected-encrypted-task-id $response)
           (if (== $encrypted-task-id CodexAbsent)
               (codex:agent-task-id-result-err
                 "agent task registration response omitted task id")
               $decryption-result))
         (codex:agent-task-id-result-ok $task-id))))

(= (codex:agent-identity-package-version)
   "0.124.0")

(= (codex:agent-identity-request-id-prefix)
   "codex-agent-identity-")

(= (codex:agent-identity-request-id)
   ; Rust uses OsRng for 16 bytes, then URL_SAFE_NO_PAD with this prefix.
   (str-concat
     (codex:agent-identity-request-id-prefix)
     (system-random-base64url-no-pad 16)))

(= (codex:agent-identity-harness-id $session-source)
   (case $session-source
     (((CodexSessionSourceVSCode)
       "codex-app")
      ($other "codex-cli"))))

(= (codex:build-agent-bill-of-materials-with-version-os
      $session-source
      $agent-version
      $os)
   (codex:agent-bill-of-materials
     $agent-version
     (codex:agent-identity-harness-id $session-source)
     (str-concat
       (str-concat (codex:session-source-display $session-source) "-")
       $os)))

(= (codex:build-agent-bill-of-materials $session-source)
   (codex:build-agent-bill-of-materials-with-version-os
     $session-source
     (codex:agent-identity-package-version)
     (system-os)))

(= (codex:agent-identity-string-contains $text $needle)
   (case (str-find $text $needle)
     ((Empty False)
      ($index True))))

(= (codex:agent-identity-trim-end-slashes $text)
   (if (== (str-length $text) 0)
       ""
       (if (str-ends-with? $text "/")
           (codex:agent-identity-trim-end-slashes
             (str-slice $text 0 (- (str-length $text) 1)))
           $text)))

(= (codex:agent-identity-strip-suffix $text $suffix)
   (if (str-ends-with? $text $suffix)
       (str-slice $text 0 (- (str-length $text) (str-length $suffix)))
       $text))

(= (codex:agent-identity-strip-control-server-suffix $base-url)
   (if (str-ends-with?
         $base-url
         "/wham/remote/control/server/enroll")
       (codex:agent-identity-strip-suffix
         $base-url
         "/wham/remote/control/server/enroll")
       (if (str-ends-with?
             $base-url
             "/wham/remote/control/server")
           (codex:agent-identity-strip-suffix
             $base-url
             "/wham/remote/control/server")
           $base-url)))

(= (codex:agent-identity-append-backend-api-if-needed $base-url)
   (if (or (str-starts-with? $base-url "https://chatgpt.com")
           (str-starts-with? $base-url "https://chat.openai.com"))
       (if (codex:agent-identity-string-contains $base-url "/backend-api")
           $base-url
           (str-concat $base-url "/backend-api"))
       $base-url))

(= (codex:normalize-chatgpt-base-url $chatgpt-base-url)
   (case (codex:agent-identity-trim-end-slashes $chatgpt-base-url)
     (($trimmed
       (case (codex:agent-identity-strip-control-server-suffix $trimmed)
         (($without-control-server
           (case (codex:agent-identity-strip-suffix
                   $without-control-server
                   "/codex")
             (($without-codex
               (codex:agent-identity-append-backend-api-if-needed
                 $without-codex)))))))))))

(= (codex:agent-registration-url $chatgpt-base-url)
   (str-concat
     (codex:agent-identity-trim-end-slashes $chatgpt-base-url)
     "/v1/agent/register"))

(= (codex:agent-task-registration-url
      $chatgpt-base-url
      $agent-runtime-id)
   (str-concat
     (str-concat
       (str-concat
         (codex:agent-identity-trim-end-slashes $chatgpt-base-url)
         "/v1/agent/")
       $agent-runtime-id)
     "/task/register"))

(= (codex:agent-identity-biscuit-url $chatgpt-base-url)
   (str-concat
     (codex:agent-identity-trim-end-slashes $chatgpt-base-url)
     "/authenticate_app_v2"))
