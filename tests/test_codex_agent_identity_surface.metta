!(register-module! ../codex)
!(import! &self codex:agent_identity)
!(import! &self codex:protocol)
!(import! &self str)

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
