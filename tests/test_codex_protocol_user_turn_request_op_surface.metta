!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:op-type
    (codex:user-turn-op
      ((codex:user-input-text "Hello turn."))
      "/repo"
      (codex:session-approval-policy-on-request)
      (codex:session-sandbox-policy-danger-full-access)
      "gpt-5.2-codex"))
  ("user_turn"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:user-turn-op
        ((codex:user-input-text "Hello turn."))
        "/repo"
        (codex:session-approval-policy-on-request)
        (codex:session-sandbox-policy-danger-full-access)
        "gpt-5.2-codex")))
  ("{\"type\":\"user_turn\",\"items\":[{\"type\":\"text\",\"text\":\"Hello turn.\",\"text_elements\":[]}],\"cwd\":\"/repo\",\"approval_policy\":\"on-request\",\"sandbox_policy\":{\"type\":\"danger-full-access\"},\"model\":\"gpt-5.2-codex\",\"final_output_json_schema\":null}"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:user-turn-op
        ((codex:user-input-text
           "Turn body"
           ((codex:text-element
              (codex:byte-range 0 4)
              CodexAbsent))))
        "/repo"
        (codex:session-approval-policy-on-request)
        (codex:session-approvals-reviewer-auto-review)
        (codex:session-sandbox-policy-danger-full-access)
        (codex:session-permission-profile-managed-unrestricted-json
          (codex:session-network-sandbox-policy-enabled))
        "gpt-5.2-codex"
        (codex:session-reasoning-effort-high)
        (codex:reasoning-summary-detailed)
        JsonNull
        (JsonObject
          ((JsonPair "type" (JsonString "object"))
           (JsonPair
             "required"
             (JsonArray
               ((JsonString "answer"))))))
        (codex:collaboration-mode
          (codex:mode-kind-default)
          (codex:settings
            "gpt-5.2-codex"
            (codex:session-reasoning-effort-high)
            "Stay focused."))
        (codex:personality-pragmatic)
        ((codex:turn-environment-selection "env_1" "/repo")))))
  ("{\"type\":\"user_turn\",\"items\":[{\"type\":\"text\",\"text\":\"Turn body\",\"text_elements\":[{\"byte_range\":{\"start\":0,\"end\":4},\"placeholder\":null}]}],\"cwd\":\"/repo\",\"approval_policy\":\"on-request\",\"approvals_reviewer\":\"guardian_subagent\",\"sandbox_policy\":{\"type\":\"danger-full-access\"},\"permission_profile\":{\"type\":\"managed\",\"file_system\":{\"type\":\"unrestricted\"},\"network\":\"enabled\"},\"model\":\"gpt-5.2-codex\",\"effort\":\"high\",\"summary\":\"detailed\",\"service_tier\":null,\"final_output_json_schema\":{\"type\":\"object\",\"required\":[\"answer\"]},\"collaboration_mode\":{\"mode\":\"default\",\"settings\":{\"model\":\"gpt-5.2-codex\",\"reasoning_effort\":\"high\",\"developer_instructions\":\"Stay focused.\"}},\"personality\":\"pragmatic\",\"environments\":[{\"environment_id\":\"env_1\",\"cwd\":\"/repo\"}]}"))
