!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:item-type
    (codex:session-configured-event
      "session-1"
      CodexAbsent
      CodexAbsent
      "gpt-5"
      "openai"
      CodexAbsent
      (codex:session-approval-policy-never)
      (codex:session-approvals-reviewer-user)
      (codex:session-sandbox-policy-read-only
        (codex:session-read-only-access-full)
        False)
      CodexAbsent
      "/home/user/project"
      (codex:session-reasoning-effort-medium)
      0
      0
      CodexAbsent
      CodexAbsent
      "/tmp/rollout.jsonl"))
  ("session_configured"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:session-configured-event
        "67e55044-10b1-426f-9247-bb680e5fe0c8"
        "thread-parent"
        "Buckminster notes"
        "gpt-5"
        "openai"
        (codex:session-service-tier-fast)
        (codex:session-approval-policy-never)
        (codex:session-approvals-reviewer-auto-review)
        (codex:session-sandbox-policy-workspace-write
          ("/repo/tmp" "/repo/out")
          (codex:session-read-only-access-restricted
            True
            ("/repo/include"))
          True
          False
          True)
        (codex:session-permission-profile-external-json
          (codex:session-network-sandbox-policy-enabled))
        "/repo"
        (codex:session-reasoning-effort-xhigh)
        42
        3
        ((codex:user-message-event
           "resume prompt"
           CodexAbsent
           ()
           ()))
        (codex:session-network-proxy-runtime
          "http://127.0.0.1:8080"
          "socks5://127.0.0.1:1080")
        "/tmp/rollout.jsonl")))
  ("{\"type\":\"session_configured\",\"session_id\":\"67e55044-10b1-426f-9247-bb680e5fe0c8\",\"forked_from_id\":\"thread-parent\",\"thread_name\":\"Buckminster notes\",\"model\":\"gpt-5\",\"model_provider_id\":\"openai\",\"service_tier\":\"fast\",\"approval_policy\":\"never\",\"approvals_reviewer\":\"guardian_subagent\",\"sandbox_policy\":{\"type\":\"workspace-write\",\"writable_roots\":[\"/repo/tmp\",\"/repo/out\"],\"read_only_access\":{\"type\":\"restricted\",\"include_platform_defaults\":true,\"readable_roots\":[\"/repo/include\"]},\"network_access\":true,\"exclude_tmpdir_env_var\":false,\"exclude_slash_tmp\":true},\"permission_profile\":{\"type\":\"external\",\"network\":\"enabled\"},\"cwd\":\"/repo\",\"reasoning_effort\":\"xhigh\",\"history_log_id\":42,\"history_entry_count\":3,\"initial_messages\":[{\"type\":\"user_message\",\"message\":\"resume prompt\",\"local_images\":[],\"text_elements\":[]}],\"network_proxy\":{\"http_addr\":\"http://127.0.0.1:8080\",\"socks_addr\":\"socks5://127.0.0.1:1080\"},\"rollout_path\":\"/tmp/rollout.jsonl\"}"))
