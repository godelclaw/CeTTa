!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:collab-agent-spawn-end-event
        "call-spawn-2"
        "/root"
        CodexAbsent
        CodexAbsent
        CodexAbsent
        ""
        "gpt-5"
        (codex:session-reasoning-effort-low)
        (codex:protocol-agent-status-completed CodexAbsent))))
  ("{\"type\":\"collab_agent_spawn_end\",\"call_id\":\"call-spawn-2\",\"sender_thread_id\":\"/root\",\"new_thread_id\":null,\"prompt\":\"\",\"model\":\"gpt-5\",\"reasoning_effort\":\"low\",\"status\":{\"completed\":null}}"))
