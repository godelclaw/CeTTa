!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:op-type
    (codex:override-turn-context-op))
  ("override_turn_context"))

!(assertEqualToResult
  (codex:op-json-string
    (codex:override-turn-context-op))
  ("{\"type\":\"override_turn_context\"}"))

!(assertEqualToResult
  (codex:op-json-string
    (codex:override-turn-context-op
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      (codex:session-reasoning-effort-high)
      CodexAbsent
      (codex:session-service-tier-fast)
      CodexAbsent
      CodexAbsent))
  ("{\"type\":\"override_turn_context\",\"effort\":\"high\",\"service_tier\":\"fast\"}"))

!(assertEqualToResult
  (codex:op-json-string
    (codex:override-turn-context-op
      "/repo"
      (codex:session-approval-policy-on-request)
      (codex:session-approvals-reviewer-auto-review)
      (codex:session-sandbox-policy-danger-full-access)
      (codex:session-permission-profile-managed-unrestricted-json
        (codex:session-network-sandbox-policy-enabled))
      (codex:windows-sandbox-level-restricted-token)
      "gpt-5.2-codex"
      JsonNull
      (codex:reasoning-summary-detailed)
      JsonNull
      (codex:collaboration-mode
        (codex:mode-kind-default)
        (codex:settings
          "gpt-5.2-codex"
          (codex:session-reasoning-effort-high)
          "Stay focused."))
      (codex:personality-pragmatic)))
  ("{\"type\":\"override_turn_context\",\"cwd\":\"/repo\",\"approval_policy\":\"on-request\",\"approvals_reviewer\":\"guardian_subagent\",\"sandbox_policy\":{\"type\":\"danger-full-access\"},\"permission_profile\":{\"type\":\"managed\",\"file_system\":{\"type\":\"unrestricted\"},\"network\":\"enabled\"},\"windows_sandbox_level\":\"restricted-token\",\"model\":\"gpt-5.2-codex\",\"effort\":null,\"summary\":\"detailed\",\"service_tier\":null,\"collaboration_mode\":{\"mode\":\"default\",\"settings\":{\"model\":\"gpt-5.2-codex\",\"reasoning_effort\":\"high\",\"developer_instructions\":\"Stay focused.\"}},\"personality\":\"pragmatic\"}"))
