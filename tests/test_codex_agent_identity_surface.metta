!(register-module! ../codex)
!(import! &self codex:agent_identity)
!(import! &self codex:protocol)
!(import! &self str)
!(import! &self json)

(= (codex-agent-identity-key)
   (codex:agent-identity-key "agent-123" "pkcs8-base64"))

(= (codex-agent-task-target)
   (codex:agent-task-authorization-target "agent-123" "task-456"))

!(assertEqualToResult
  ((codex:agent-identity-key-agent-runtime-id
      (codex-agent-identity-key))
   (codex:agent-identity-key-private-key-pkcs8-base64
      (codex-agent-identity-key))
   (codex:agent-task-authorization-target-agent-runtime-id
      (codex-agent-task-target))
   (codex:agent-task-authorization-target-task-id
      (codex-agent-task-target)))
  (("agent-123" "pkcs8-base64" "agent-123" "task-456")))

!(assertEqualToResult
  (codex:agent-assertion-envelope-agent-runtime-id
    (codex:agent-assertion-envelope
      "agent-123"
      "task-456"
      "2026-05-18T10:20:30Z"
      "sig-abc"))
  ("agent-123"))

!(assertEqualToResult
  (codex:agent-assertion-envelope-task-id
    (codex:agent-assertion-envelope
      "agent-123"
      "task-456"
      "2026-05-18T10:20:30Z"
      "sig-abc"))
  ("task-456"))

!(assertEqualToResult
  (json-stringify
    (codex:agent-assertion-envelope-json
      (codex:agent-assertion-envelope
        "agent-123"
        "task-456"
        "2026-05-18T10:20:30Z"
        "sig-abc")))
  ("{\"agent_runtime_id\":\"agent-123\",\"signature\":\"sig-abc\",\"task_id\":\"task-456\",\"timestamp\":\"2026-05-18T10:20:30Z\"}"))

!(assertEqualToResult
  (codex:serialize-agent-assertion
    (codex:agent-assertion-envelope
      "agent-123"
      "task-456"
      "2026-05-18T10:20:30Z"
      "sig-abc"))
  ("eyJhZ2VudF9ydW50aW1lX2lkIjoiYWdlbnQtMTIzIiwic2lnbmF0dXJlIjoic2lnLWFiYyIsInRhc2tfaWQiOiJ0YXNrLTQ1NiIsInRpbWVzdGFtcCI6IjIwMjYtMDUtMThUMTA6MjA6MzBaIn0"))

!(assertEqualToResult
  (codex:agent-identity-auth-header-value
    (codex:authorization-header-for-agent-task-with-signature-timestamp
      (codex-agent-identity-key)
      (codex-agent-task-target)
      "sig-abc"
      "2026-05-18T10:20:30Z"))
  ("AgentAssertion eyJhZ2VudF9ydW50aW1lX2lkIjoiYWdlbnQtMTIzIiwic2lnbmF0dXJlIjoic2lnLWFiYyIsInRhc2tfaWQiOiJ0YXNrLTQ1NiIsInRpbWVzdGFtcCI6IjIwMjYtMDUtMThUMTA6MjA6MzBaIn0"))

!(assertEqualToResult
  (codex:agent-identity-auth-header-error
    (codex:authorization-header-for-agent-task-with-signature-timestamp
      (codex-agent-identity-key)
      (codex:agent-task-authorization-target "agent-999" "task-456")
      "sig-abc"
      "2026-05-18T10:20:30Z"))
  ("agent task runtime agent-999 does not match stored agent identity agent-123"))

!(assertEqualToResult
  (json-stringify
    (codex:register-task-request-json
      (codex:register-task-request "2026-05-18T10:20:30Z" "sig-abc")))
  ("{\"timestamp\":\"2026-05-18T10:20:30Z\",\"signature\":\"sig-abc\"}"))

!(assertEqualToResult
  (codex:agent-task-registration-timeout-seconds)
  (30))

!(assertEqualToResult
  (codex:register-task-response-task-id
    (codex:register-task-response
      "snake-task"
      "camel-task"
      "enc-snake"
      "enc-camel"))
  ("snake-task"))

!(assertEqualToResult
  (codex:register-task-response-task-id-camel
    (codex:register-task-response-from-json
      (json-parse "{\"taskId\":\"camel-task\"}")))
  ("camel-task"))

!(assertEqualToResult
  (codex:register-task-response-encrypted-task-id
    (codex:register-task-response-from-json
      (json-parse "{\"encrypted_task_id\":\"enc-snake\"}")))
  ("enc-snake"))

!(assertEqualToResult
  (codex:register-task-response-encrypted-task-id-camel
    (codex:register-task-response-from-json
      (json-parse "{\"encryptedTaskId\":\"enc-camel\"}")))
  ("enc-camel"))

!(assertEqualToResult
  (codex:register-task-response-selected-task-id
    (codex:register-task-response
      "snake-task"
      "camel-task"
      "enc-snake"
      "enc-camel"))
  ("snake-task"))

!(assertEqualToResult
  (codex:register-task-response-selected-task-id
    (codex:register-task-response
      CodexAbsent
      "camel-task"
      "enc-snake"
      "enc-camel"))
  ("camel-task"))

!(assertEqualToResult
  (codex:register-task-response-selected-encrypted-task-id
    (codex:register-task-response
      CodexAbsent
      CodexAbsent
      "enc-snake"
      "enc-camel"))
  ("enc-snake"))

!(assertEqualToResult
  (codex:register-task-response-selected-encrypted-task-id
    (codex:register-task-response
      CodexAbsent
      CodexAbsent
      CodexAbsent
      "enc-camel"))
  ("enc-camel"))

!(assertEqualToResult
  (codex:register-task-response-selected-task-id
    (codex:register-task-response-from-json
      (json-parse "{\"task_id\":null,\"taskId\":\"camel-task\"}")))
  ("camel-task"))

!(assertEqualToResult
  (codex:agent-task-id-result-value
    (codex:task-id-from-register-task-response-with-decryption-result
      (codex-agent-identity-key)
      (codex:register-task-response
        "snake-task"
        "camel-task"
        "enc-snake"
        "enc-camel")
      (codex:agent-task-id-result-ok "decrypted-task")))
  ("snake-task"))

!(assertEqualToResult
  (codex:agent-task-id-result-value
    (codex:task-id-from-register-task-response-with-decryption-result
      (codex-agent-identity-key)
      (codex:register-task-response
        CodexAbsent
        "camel-task"
        "enc-snake"
        "enc-camel")
      (codex:agent-task-id-result-ok "decrypted-task")))
  ("camel-task"))

!(assertEqualToResult
  (codex:agent-task-id-result-value
    (codex:task-id-from-register-task-response-with-decryption-result
      (codex-agent-identity-key)
      (codex:register-task-response
        CodexAbsent
        CodexAbsent
        "enc-snake"
        "enc-camel")
      (codex:agent-task-id-result-ok "decrypted-task")))
  ("decrypted-task"))

!(assertEqualToResult
  (codex:agent-task-id-result-error
    (codex:task-id-from-register-task-response-with-decryption-result
      (codex-agent-identity-key)
      (codex:register-task-response
        CodexAbsent
        CodexAbsent
        "enc-snake"
        CodexAbsent)
      (codex:agent-task-id-result-err "decrypt failed")))
  ("decrypt failed"))

!(assertEqualToResult
  (codex:agent-task-id-result-error
    (codex:task-id-from-register-task-response-with-decryption-result
      (codex-agent-identity-key)
      (codex:register-task-response
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent)
      (codex:agent-task-id-result-ok "decrypted-task")))
  ("agent task registration response omitted task id"))

!(assertEqualToResult
  (codex:agent-identity-string-result-value
    (codex:signing-key-from-agent-identity-key-with-crypto-results
      (codex-agent-identity-key)
      (codex:agent-identity-crypto-step-ok "private-key-der")
      (codex:agent-identity-crypto-step-ok "signing-key")))
  ("signing-key"))

!(assertEqualToResult
  (codex:agent-identity-string-result-error
    (codex:signing-key-from-agent-identity-key-with-crypto-results
      (codex-agent-identity-key)
      (codex:agent-identity-crypto-step-err "decoder detail")
      (codex:agent-identity-crypto-step-ok "signing-key")))
  ("stored agent identity private key is not valid base64"))

!(assertEqualToResult
  (codex:agent-identity-string-result-error
    (codex:signing-key-from-agent-identity-key-with-crypto-results
      (codex-agent-identity-key)
      (codex:agent-identity-crypto-step-ok "private-key-der")
      (codex:agent-identity-crypto-step-err "pkcs8 detail")))
  ("stored agent identity private key is not valid PKCS#8"))

!(assertEqualToResult
  (codex:task-registration-signing-payload
    (codex-agent-identity-key)
    "2026-05-18T10:20:30Z")
  ("agent-123:2026-05-18T10:20:30Z"))

!(assertEqualToResult
  (codex:agent-assertion-signing-payload
    (codex-agent-identity-key)
    "task-456"
    "2026-05-18T10:20:30Z")
  ("agent-123:task-456:2026-05-18T10:20:30Z"))

!(assertEqualToResult
  (codex:agent-identity-string-result-value
    (codex:sign-task-registration-payload-with-signature-result
      (codex-agent-identity-key)
      "2026-05-18T10:20:30Z"
      (codex:agent-identity-string-result-ok "signing-key")
      "signature-base64"))
  ("signature-base64"))

!(assertEqualToResult
  (codex:agent-identity-string-result-error
    (codex:sign-task-registration-payload-with-signature-result
      (codex-agent-identity-key)
      "2026-05-18T10:20:30Z"
      (codex:agent-identity-string-result-err
        "stored agent identity private key is not valid PKCS#8")
      "signature-base64"))
  ("stored agent identity private key is not valid PKCS#8"))

!(assertEqualToResult
  (codex:agent-identity-string-result-value
    (codex:decrypt-task-id-response-with-crypto-results
      (codex-agent-identity-key)
      "encrypted-task-id"
      (codex:agent-identity-string-result-ok "signing-key")
      (codex:agent-identity-crypto-step-ok "ciphertext")
      (codex:agent-identity-crypto-step-ok "plaintext-bytes")
      (codex:agent-identity-crypto-step-ok "decrypted-task")))
  ("decrypted-task"))

!(assertEqualToResult
  (codex:agent-identity-string-result-error
    (codex:decrypt-task-id-response-with-crypto-results
      (codex-agent-identity-key)
      "encrypted-task-id"
      (codex:agent-identity-string-result-err
        "stored agent identity private key is not valid base64")
      (codex:agent-identity-crypto-step-ok "ciphertext")
      (codex:agent-identity-crypto-step-ok "plaintext-bytes")
      (codex:agent-identity-crypto-step-ok "decrypted-task")))
  ("stored agent identity private key is not valid base64"))

!(assertEqualToResult
  (codex:agent-identity-string-result-error
    (codex:decrypt-task-id-response-with-crypto-results
      (codex-agent-identity-key)
      "encrypted-task-id"
      (codex:agent-identity-string-result-ok "signing-key")
      (codex:agent-identity-crypto-step-err "base64 detail")
      (codex:agent-identity-crypto-step-ok "plaintext-bytes")
      (codex:agent-identity-crypto-step-ok "decrypted-task")))
  ("encrypted task id is not valid base64"))

!(assertEqualToResult
  (codex:agent-identity-string-result-error
    (codex:decrypt-task-id-response-with-crypto-results
      (codex-agent-identity-key)
      "encrypted-task-id"
      (codex:agent-identity-string-result-ok "signing-key")
      (codex:agent-identity-crypto-step-ok "ciphertext")
      (codex:agent-identity-crypto-step-err "unseal detail")
      (codex:agent-identity-crypto-step-ok "decrypted-task")))
  ("failed to decrypt encrypted task id"))

!(assertEqualToResult
  (codex:agent-identity-string-result-error
    (codex:decrypt-task-id-response-with-crypto-results
      (codex-agent-identity-key)
      "encrypted-task-id"
      (codex:agent-identity-string-result-ok "signing-key")
      (codex:agent-identity-crypto-step-ok "ciphertext")
      (codex:agent-identity-crypto-step-ok "plaintext-bytes")
      (codex:agent-identity-crypto-step-err "utf8 detail")))
  ("decrypted task id is not valid UTF-8"))

!(assertEqualToResult
  (codex:agent-task-id-result-value
    (codex:task-id-from-register-task-response-with-agent-identity-decryption-result
      (codex-agent-identity-key)
      (codex:register-task-response
        CodexAbsent
        CodexAbsent
        "enc-snake"
        CodexAbsent)
      (codex:agent-identity-string-result-ok "decrypted-task")))
  ("decrypted-task"))

!(assertEqualToResult
  (codex:agent-task-id-result-value
    (codex:task-id-from-register-task-response-with-agent-identity-decryption-result
      (codex-agent-identity-key)
      (codex:register-task-response
        "snake-task"
        CodexAbsent
        "enc-snake"
        CodexAbsent)
      (codex:agent-identity-string-result-err "decrypt should not be used")))
  ("snake-task"))

!(assertEqualToResult
  (codex:agent-bill-of-materials-agent-version
    (codex:build-agent-bill-of-materials-with-version-os
      (codex:session-source-vscode)
      "0.124.0"
      "linux"))
  ("0.124.0"))

!(assertEqualToResult
  (codex:agent-bill-of-materials-agent-harness-id
    (codex:build-agent-bill-of-materials-with-version-os
      (codex:session-source-vscode)
      "0.124.0"
      "linux"))
  ("codex-app"))

!(assertEqualToResult
  (codex:agent-bill-of-materials-running-location
    (codex:build-agent-bill-of-materials-with-version-os
      (codex:session-source-vscode)
      "0.124.0"
      "linux"))
  ("vscode-linux"))

!(assertEqualToResult
  (codex:agent-bill-of-materials-agent-harness-id
    (codex:build-agent-bill-of-materials-with-version-os
      (codex:session-source-cli)
      "0.124.0"
      "linux"))
  ("codex-cli"))

!(assertEqualToResult
  (codex:agent-bill-of-materials-running-location
    (codex:build-agent-bill-of-materials-with-version-os
      (codex:session-source-custom "atlas")
      "0.124.0"
      "linux"))
  ("atlas-linux"))

!(assertEqualToResult
  (codex:agent-bill-of-materials-running-location
    (codex:build-agent-bill-of-materials-with-version-os
      (codex:session-source-mcp)
      "0.124.0"
      "linux"))
  ("mcp-linux"))

!(assertEqualToResult
  (str-starts-with?
    (codex:agent-identity-request-id)
    (codex:agent-identity-request-id-prefix))
  (True))

!(assertEqualToResult
  (str-length (codex:agent-identity-request-id))
  (43))

!(assertEqualToResult
  (codex:normalize-chatgpt-base-url "https://chatgpt.com/codex")
  ("https://chatgpt.com/backend-api"))

!(assertEqualToResult
  (codex:normalize-chatgpt-base-url "https://chatgpt.com/backend-api/")
  ("https://chatgpt.com/backend-api"))

!(assertEqualToResult
  (codex:normalize-chatgpt-base-url "https://chat.openai.com")
  ("https://chat.openai.com/backend-api"))

!(assertEqualToResult
  (codex:normalize-chatgpt-base-url
    "https://chatgpt.com/wham/remote/control/server/enroll")
  ("https://chatgpt.com/backend-api"))

!(assertEqualToResult
  (codex:normalize-chatgpt-base-url
    "https://chatgpt.com/wham/remote/control/server")
  ("https://chatgpt.com/backend-api"))

!(assertEqualToResult
  (codex:normalize-chatgpt-base-url "https://example.com/codex/")
  ("https://example.com"))

!(assertEqualToResult
  (codex:normalize-chatgpt-base-url
    "https://chatgpt.com/backend-api/codex")
  ("https://chatgpt.com/backend-api"))

!(assertEqualToResult
  (codex:agent-registration-url "https://chatgpt.com/backend-api/")
  ("https://chatgpt.com/backend-api/v1/agent/register"))

!(assertEqualToResult
  (codex:agent-task-registration-url
    "https://chatgpt.com/backend-api/"
    "agent-123")
  ("https://chatgpt.com/backend-api/v1/agent/agent-123/task/register"))

!(assertEqualToResult
  (codex:agent-identity-biscuit-url "https://chatgpt.com/backend-api/")
  ("https://chatgpt.com/backend-api/authenticate_app_v2"))
