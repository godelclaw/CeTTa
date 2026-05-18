!(register-module! ../codex)
!(import! &self codex:agent_identity)

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
  ((codex:normalize-chatgpt-base-url "https://chatgpt.com/codex")
   (codex:normalize-chatgpt-base-url "https://chatgpt.com/backend-api/")
   (codex:normalize-chatgpt-base-url "https://chat.openai.com")
   (codex:normalize-chatgpt-base-url
     "https://chatgpt.com/wham/remote/control/server/enroll")
   (codex:normalize-chatgpt-base-url
     "https://chatgpt.com/wham/remote/control/server")
   (codex:normalize-chatgpt-base-url "https://example.com/codex/")
   (codex:normalize-chatgpt-base-url
     "https://chatgpt.com/backend-api/codex"))
  (("https://chatgpt.com/backend-api"
    "https://chatgpt.com/backend-api"
    "https://chat.openai.com/backend-api"
    "https://chatgpt.com/backend-api"
    "https://chatgpt.com/backend-api"
    "https://example.com"
    "https://chatgpt.com/backend-api")))

!(assertEqualToResult
  ((codex:agent-registration-url "https://chatgpt.com/backend-api/")
   (codex:agent-task-registration-url
     "https://chatgpt.com/backend-api/"
     "agent-123")
   (codex:agent-identity-biscuit-url "https://chatgpt.com/backend-api/"))
  (("https://chatgpt.com/backend-api/v1/agent/register"
    "https://chatgpt.com/backend-api/v1/agent/agent-123/task/register"
    "https://chatgpt.com/backend-api/authenticate_app_v2")))
