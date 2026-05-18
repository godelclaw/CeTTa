!(register-module! ../codex)
!(import! &self codex:auth_provider)

!(assertEqualToResult
  (codex:auth-provider-to-auth-headers
    (codex:unauthenticated-auth-provider))
  (()))

!(assertEqualToResult
  (codex:auth-header-telemetry
    (codex:bearer-auth-provider
      "access-token"
      CodexAbsent
      False))
  ((CodexAuthHeaderTelemetry True "authorization")))

!(assertEqualToResult
  (codex:headers-get
    (codex:auth-provider-to-auth-headers
      (codex:bearer-auth-provider-for-test
        "access-token"
        "workspace-123"))
    "authorization")
  ("Bearer access-token"))

!(assertEqualToResult
  (codex:headers-get
    (codex:auth-provider-to-auth-headers
      (codex:bearer-auth-provider-for-test
        "access-token"
        "workspace-123"))
    "ChatGPT-Account-ID")
  ("workspace-123"))

!(assertEqualToResult
  (codex:headers-get
    (codex:auth-provider-to-auth-headers
      (codex:bearer-auth-provider
        "access-token"
        "workspace-123"
        True))
    "X-OpenAI-Fedramp")
  ("true"))

!(assertEqualToResult
  (codex:headers-get
    (codex:headers-insert
      ((CodexHeader "AUTHORIZATION" "Bearer old-token"))
      "authorization"
      "Bearer new-token")
    "Authorization")
  ("Bearer new-token"))

!(assertEqualToResult
  (codex:headers-get
    (codex:auth-provider-to-auth-headers
      (codex:bearer-auth-provider
        "bad\ntoken"
        "workspace-123"
        False))
    "authorization")
  (CodexAbsent))

!(assertEqualToResult
  (codex:auth-header-telemetry
    (codex:bearer-auth-provider
      CodexAbsent
      "workspace-123"
      False))
  ((CodexAuthHeaderTelemetry False CodexAbsent)))
