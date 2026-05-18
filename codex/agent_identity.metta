; Rust-faithful pure agent-identity helper slice.
;
; This ports the pure data and URL helper surface from:
; - openai-codex/codex-rs/agent-identity/src/lib.rs
;
; Covered in this increment:
; - AgentIdentityKey / AgentTaskAuthorizationTarget data shapes
; - AgentBillOfMaterials / build_abom
; - agent_identity_request_id
; - agent_registration_url, agent_task_registration_url, agent_identity_biscuit_url
; - normalize_chatgpt_base_url
;
; Required CeTTa representation notes for audit:
; - Rust signing/decryption helpers depend on Ed25519 PKCS#8, SHA-512, base64url,
;   and crypto_box seal support. Those are runtime-library work, not pure MeTTa
;   rewrites, and are intentionally not claimed by this helper slice.

!(import! &self str)
!(import! &self system)
!(import! &self protocol)

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
