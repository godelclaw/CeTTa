!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:user-input-with-turn-context-op
        ((codex:user-input-text
           "See plan"
           ((codex:text-element
              (codex:byte-range 0 3)
              CodexAbsent))))
        ((codex:turn-environment-selection "env_1" "/repo"))
        (JsonObject
          ((JsonPair "type" (JsonString "object"))
           (JsonPair
             "required"
             (JsonArray
               ((JsonString "answer"))))))
        ((codex:responsesapi-client-metadata-entry "origin" "chat"))
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
        (codex:personality-pragmatic))))
  ("{\"type\":\"user_input_with_turn_context\",\"items\":[{\"type\":\"text\",\"text\":\"See plan\",\"text_elements\":[{\"byte_range\":{\"start\":0,\"end\":3},\"placeholder\":null}]}],\"environments\":[{\"environment_id\":\"env_1\",\"cwd\":\"/repo\"}],\"final_output_json_schema\":{\"type\":\"object\",\"required\":[\"answer\"]},\"responsesapi_client_metadata\":{\"origin\":\"chat\"},\"cwd\":\"/repo\",\"approval_policy\":\"on-request\",\"approvals_reviewer\":\"guardian_subagent\",\"sandbox_policy\":{\"type\":\"danger-full-access\"},\"permission_profile\":{\"type\":\"managed\",\"file_system\":{\"type\":\"unrestricted\"},\"network\":\"enabled\"},\"windows_sandbox_level\":\"restricted-token\",\"model\":\"gpt-5.2-codex\",\"effort\":null,\"summary\":\"detailed\",\"service_tier\":null,\"collaboration_mode\":{\"mode\":\"default\",\"settings\":{\"model\":\"gpt-5.2-codex\",\"reasoning_effort\":\"high\",\"developer_instructions\":\"Stay focused.\"}},\"personality\":\"pragmatic\"}"))
