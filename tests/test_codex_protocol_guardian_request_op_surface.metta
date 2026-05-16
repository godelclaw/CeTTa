!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:network_policy_decision)
!(import! &self codex:protocol)
!(import! &self codex:request_permissions)

!(assertEqualToResult
  (codex:op-type
    (codex:approve-guardian-denied-action-op
      (codex:guardian-assessment-event
        "ga_1"
        CodexAbsent
        "turn_1"
        (codex:guardian-assessment-status-approved)
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        (codex:guardian-assessment-action-command
          (codex:guardian-command-source-shell)
          "rm -f /tmp/file"
          "/tmp"))))
  ("approve_guardian_denied_action"))

!(assertEqualToResult
  (json-stringify
    (codex:guardian-assessment-status-json
      (codex:guardian-assessment-status-timed-out)))
  ("\"timed_out\""))

!(assertEqualToResult
  (json-stringify
    (codex:guardian-assessment-action-json
      (codex:guardian-assessment-action-command
        (codex:guardian-command-source-shell)
        "rm -f /tmp/file"
        "/tmp")))
  ("{\"type\":\"command\",\"source\":\"shell\",\"command\":\"rm -f /tmp/file\",\"cwd\":\"/tmp\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:guardian-assessment-action-json
      (codex:guardian-assessment-action-execve
        (codex:guardian-command-source-unified-exec)
        "/bin/rm"
        ("/usr/bin/rm" "-f" "/tmp/file.sqlite")
        "/tmp")))
  ("{\"type\":\"execve\",\"source\":\"unified_exec\",\"program\":\"/bin/rm\",\"argv\":[\"/usr/bin/rm\",\"-f\",\"/tmp/file.sqlite\"],\"cwd\":\"/tmp\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:guardian-assessment-action-json
      (codex:guardian-assessment-action-apply-patch
        "/repo"
        ("/repo/a.txt" "/repo/b.txt"))))
  ("{\"type\":\"apply_patch\",\"cwd\":\"/repo\",\"files\":[\"/repo/a.txt\",\"/repo/b.txt\"]}"))

!(assertEqualToResult
  (json-stringify
    (codex:guardian-assessment-action-json
      (codex:guardian-assessment-action-network-access
        "https://api.example.com/v1"
        "api.example.com"
        (codex:network-approval-protocol-https)
        443)))
  ("{\"type\":\"network_access\",\"target\":\"https://api.example.com/v1\",\"host\":\"api.example.com\",\"protocol\":\"https\",\"port\":443}"))

!(assertEqualToResult
  (json-stringify
    (codex:guardian-assessment-action-json
      (codex:guardian-assessment-action-mcp-tool-call
        "github"
        "search_repos"
        CodexAbsent
        CodexAbsent
        CodexAbsent)))
  ("{\"type\":\"mcp_tool_call\",\"server\":\"github\",\"tool_name\":\"search_repos\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:guardian-assessment-action-json
      (codex:guardian-assessment-action-request-permissions
        CodexAbsent
        (codex:request-permission-profile
          (codex:request-permissions-network True)
          (codex:request-permissions-file-system
            ()
            ("/repo/runtime"))))))
  ("{\"type\":\"request_permissions\",\"permissions\":{\"network\":{\"enabled\":true},\"file_system\":{\"write\":[\"/repo/runtime\"]}}}"))
