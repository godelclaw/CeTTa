!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (json-stringify
    (codex:protocol-agent-status-json
      (codex:protocol-agent-status-pending-init)))
  ("\"pending_init\""))

!(assertEqualToResult
  (json-stringify
    (codex:protocol-agent-status-json
      (codex:protocol-agent-status-completed CodexAbsent)))
  ("{\"completed\":null}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:collab-agent-spawn-begin-event
        "call-spawn-1"
        "/root"
        "investigate"
        "gpt-5"
        (codex:session-reasoning-effort-medium))))
  ("{\"type\":\"collab_agent_spawn_begin\",\"call_id\":\"call-spawn-1\",\"sender_thread_id\":\"/root\",\"prompt\":\"investigate\",\"model\":\"gpt-5\",\"reasoning_effort\":\"medium\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:collab-agent-interaction-begin-event
        "call-send-1"
        "/root"
        "/root/scout"
        "check docs")))
  ("{\"type\":\"collab_agent_interaction_begin\",\"call_id\":\"call-send-1\",\"sender_thread_id\":\"/root\",\"receiver_thread_id\":\"/root/scout\",\"prompt\":\"check docs\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:collab-agent-interaction-end-event
        "call-send-2"
        "/root"
        "/root/scout"
        "Scout"
        "explorer"
        "check docs"
        (codex:protocol-agent-status-interrupted))))
  ("{\"type\":\"collab_agent_interaction_end\",\"call_id\":\"call-send-2\",\"sender_thread_id\":\"/root\",\"receiver_thread_id\":\"/root/scout\",\"receiver_agent_nickname\":\"Scout\",\"receiver_agent_role\":\"explorer\",\"prompt\":\"check docs\",\"status\":\"interrupted\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:collab-waiting-begin-event
        "/root"
        ("/root/scout" "/root/reviewer")
        ((codex:collab-agent-ref "/root/scout" "Scout" "explorer")
         (codex:collab-agent-ref "/root/reviewer" CodexAbsent CodexAbsent))
        "wait-1")))
  ("{\"type\":\"collab_waiting_begin\",\"sender_thread_id\":\"/root\",\"receiver_thread_ids\":[\"/root/scout\",\"/root/reviewer\"],\"receiver_agents\":[{\"thread_id\":\"/root/scout\",\"agent_nickname\":\"Scout\",\"agent_role\":\"explorer\"},{\"thread_id\":\"/root/reviewer\"}],\"call_id\":\"wait-1\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:collab-waiting-end-event
        "/root"
        "wait-1"
        ((codex:collab-agent-status-entry
           "/root/scout"
           "Scout"
           "explorer"
           (codex:protocol-agent-status-running))
         (codex:collab-agent-status-entry
           "/root/reviewer"
           CodexAbsent
           CodexAbsent
           (codex:protocol-agent-status-errored "tool failed")))
        ((codex:collab-waiting-status-entry
           "/root/scout"
           (codex:protocol-agent-status-running))
         (codex:collab-waiting-status-entry
           "/root/reviewer"
           (codex:protocol-agent-status-errored "tool failed"))))))
  ("{\"type\":\"collab_waiting_end\",\"sender_thread_id\":\"/root\",\"call_id\":\"wait-1\",\"agent_statuses\":[{\"thread_id\":\"/root/scout\",\"agent_nickname\":\"Scout\",\"agent_role\":\"explorer\",\"status\":\"running\"},{\"thread_id\":\"/root/reviewer\",\"status\":{\"errored\":\"tool failed\"}}],\"statuses\":{\"/root/scout\":\"running\",\"/root/reviewer\":{\"errored\":\"tool failed\"}}}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:collab-close-begin-event
        "close-1"
        "/root"
        "/root/scout")))
  ("{\"type\":\"collab_close_begin\",\"call_id\":\"close-1\",\"sender_thread_id\":\"/root\",\"receiver_thread_id\":\"/root/scout\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:collab-close-end-event
        "close-2"
        "/root"
        "/root/scout"
        "Scout"
        "explorer"
        (codex:protocol-agent-status-shutdown))))
  ("{\"type\":\"collab_close_end\",\"call_id\":\"close-2\",\"sender_thread_id\":\"/root\",\"receiver_thread_id\":\"/root/scout\",\"receiver_agent_nickname\":\"Scout\",\"receiver_agent_role\":\"explorer\",\"status\":\"shutdown\"}"))

!(assertEqualToResult
  (codex:item-type
    (codex:collab-resume-begin-event
      "resume-1"
      "/root"
      "/root/scout"
      CodexAbsent
      CodexAbsent))
  ("collab_resume_begin"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:collab-resume-begin-event
        "resume-1"
        "/root"
        "/root/scout"
        CodexAbsent
        CodexAbsent)))
  ("{\"type\":\"collab_resume_begin\",\"call_id\":\"resume-1\",\"sender_thread_id\":\"/root\",\"receiver_thread_id\":\"/root/scout\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:collab-resume-end-event
        "resume-2"
        "/root"
        "/root/scout"
        "Scout"
        "explorer"
        (codex:protocol-agent-status-not-found))))
  ("{\"type\":\"collab_resume_end\",\"call_id\":\"resume-2\",\"sender_thread_id\":\"/root\",\"receiver_thread_id\":\"/root/scout\",\"receiver_agent_nickname\":\"Scout\",\"receiver_agent_role\":\"explorer\",\"status\":\"not_found\"}"))
