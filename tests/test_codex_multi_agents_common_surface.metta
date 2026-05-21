!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:function_tool)
!(import! &self codex:multi_agents_common)
!(import! &self codex:protocol)

!(assertEqual
  (codex:multi-agent-min-wait-timeout-ms)
  10000)

!(assertEqual
  (codex:multi-agent-default-wait-timeout-ms)
  30000)

!(assertEqual
  (codex:multi-agent-max-wait-timeout-ms)
  3600000)

!(assertEqual
  (codex:multi-agent-function-arguments
    (codex:function-payload "{\"message\":\"hi\"}"))
  (codex:multi-agent-common-ok "{\"message\":\"hi\"}"))

!(assertEqual
  (codex:multi-agent-function-arguments
    (codex:custom-payload "raw"))
  (codex:multi-agent-common-err
    (codex:function-call-error-respond-to-model
      "collab handler received unsupported payload")))

!(assertEqual
  (codex:multi-agent-build-wait-agent-statuses
    ((codex:multi-agent-status-map-entry
       "/root/reviewer"
       (codex:protocol-agent-status-errored "tool failed"))
     (codex:multi-agent-status-map-entry
       "/root/scout"
       (codex:protocol-agent-status-running))
     (codex:multi-agent-status-map-entry
       "/root/alpha"
       (codex:protocol-agent-status-completed "done")))
    ((codex:collab-agent-ref "/root/scout" "Scout" "explorer")
     (codex:collab-agent-ref "/root/missing" "Missing" CodexAbsent)))
  ((codex:collab-agent-status-entry
     "/root/scout"
     "Scout"
     "explorer"
     (codex:protocol-agent-status-running))
   (codex:collab-agent-status-entry
     "/root/alpha"
     CodexAbsent
     CodexAbsent
     (codex:protocol-agent-status-completed "done"))
   (codex:collab-agent-status-entry
     "/root/reviewer"
     CodexAbsent
     CodexAbsent
     (codex:protocol-agent-status-errored "tool failed"))))

!(assertEqualToResult
  (json-stringify
    (let $entries
      (codex:multi-agent-build-wait-agent-statuses
        ((codex:multi-agent-status-map-entry
           "/root/reviewer"
           (codex:protocol-agent-status-errored "tool failed"))
         (codex:multi-agent-status-map-entry
           "/root/scout"
           (codex:protocol-agent-status-running)))
        ((codex:collab-agent-ref "/root/scout" "Scout" "explorer")))
      (JsonArray
        (map-atom
          $entries
          $entry
          (codex:collab-agent-status-entry-json $entry)))))
  ("[{\"thread_id\":\"/root/scout\",\"agent_nickname\":\"Scout\",\"agent_role\":\"explorer\",\"status\":\"running\"},{\"thread_id\":\"/root/reviewer\",\"status\":{\"errored\":\"tool failed\"}}]"))

!(assertEqual
  (codex:multi-agent-collab-spawn-error
    (codex:multi-agent-codex-err-unsupported-operation
      "thread manager dropped"))
  (codex:function-call-error-respond-to-model
    "collab manager unavailable"))

!(assertEqual
  (codex:multi-agent-collab-spawn-error
    (codex:multi-agent-codex-err-unsupported-operation
      "spawn disabled"))
  (codex:function-call-error-respond-to-model
    "spawn disabled"))

!(assertEqual
  (codex:multi-agent-collab-spawn-error
    (codex:multi-agent-codex-err-other "disk full"))
  (codex:function-call-error-respond-to-model
    "collab spawn failed: disk full"))

!(assertEqual
  (codex:multi-agent-collab-agent-error
    "/root/worker"
    (codex:multi-agent-codex-err-thread-not-found "/root/worker"))
  (codex:function-call-error-respond-to-model
    "agent with id /root/worker not found"))

!(assertEqual
  (codex:multi-agent-collab-agent-error
    "/root/worker"
    (codex:multi-agent-codex-err-internal-agent-died))
  (codex:function-call-error-respond-to-model
    "agent with id /root/worker is closed"))

!(assertEqual
  (codex:multi-agent-collab-agent-error
    "/root/worker"
    (codex:multi-agent-codex-err-unsupported-operation "closed"))
  (codex:function-call-error-respond-to-model
    "collab manager unavailable"))

!(assertEqual
  (codex:multi-agent-thread-spawn-source
    "/root/parent"
    (codex:session-source-cli)
    1
    "explorer"
    "scout")
  (codex:multi-agent-common-ok
    (codex:session-source-subagent
      (codex:subagent-source-thread-spawn
        "/root/parent"
        1
        (codex:agent-path "/root/scout")
        CodexAbsent
        "explorer"))))

!(assertEqual
  (codex:multi-agent-thread-spawn-source
    "/root/parent"
    (codex:session-source-subagent
      (codex:subagent-source-thread-spawn
        "/root/grand"
        1
        (codex:agent-path "/root/existing")
        CodexAbsent
        CodexAbsent))
    2
    CodexAbsent
    "child")
  (codex:multi-agent-common-ok
    (codex:session-source-subagent
      (codex:subagent-source-thread-spawn
        "/root/parent"
        2
        (codex:agent-path "/root/existing/child")
        CodexAbsent
        CodexAbsent))))

!(assertEqual
  (codex:multi-agent-thread-spawn-source
    "/root/parent"
    (codex:session-source-cli)
    1
    CodexAbsent
    CodexAbsent)
  (codex:multi-agent-common-ok
    (codex:session-source-subagent
      (codex:subagent-source-thread-spawn
        "/root/parent"
        1
        CodexAbsent
        CodexAbsent
        CodexAbsent))))

!(assertEqual
  (codex:multi-agent-thread-spawn-source
    "/root/parent"
    (codex:session-source-cli)
    1
    CodexAbsent
    "bad/name")
  (codex:multi-agent-common-err
    (codex:function-call-error-respond-to-model
      "agent_name must not contain `/`")))

!(assertEqual
  (codex:multi-agent-parse-collab-input
    "hello"
    CodexAbsent)
  (codex:multi-agent-common-ok
    (codex:user-input-op
      ((codex:user-input-text "hello")))))

!(assertEqual
  (codex:multi-agent-parse-collab-input
    CodexAbsent
    ((codex:user-input-text "from items")))
  (codex:multi-agent-common-ok
    (codex:user-input-op
      ((codex:user-input-text "from items")))))

!(assertEqual
  (codex:multi-agent-parse-collab-input
    "hello"
    ((codex:user-input-text "from items")))
  (codex:multi-agent-common-err
    (codex:function-call-error-respond-to-model
      "Provide either message or items, but not both")))

!(assertEqual
  (codex:multi-agent-parse-collab-input CodexAbsent CodexAbsent)
  (codex:multi-agent-common-err
    (codex:function-call-error-respond-to-model
      "Provide one of: message or items")))

!(assertEqual
  (codex:multi-agent-parse-collab-input "   " CodexAbsent)
  (codex:multi-agent-common-err
    (codex:function-call-error-respond-to-model
      "Empty message can't be sent to an agent")))

!(assertEqual
  (codex:multi-agent-parse-collab-input CodexAbsent ())
  (codex:multi-agent-common-err
    (codex:function-call-error-respond-to-model
      "Items can't be empty")))

!(assertEqual
  (codex:multi-agent-reject-full-fork-spawn-overrides
    CodexAbsent
    CodexAbsent
    CodexAbsent)
  (codex:multi-agent-common-ok ()))

!(assertEqual
  (codex:multi-agent-reject-full-fork-spawn-overrides
    "worker"
    CodexAbsent
    CodexAbsent)
  (codex:multi-agent-common-err
    (codex:function-call-error-respond-to-model
      "Full-history forked agents inherit the parent agent type, model, and reasoning effort; omit agent_type, model, and reasoning_effort, or spawn without a full-history fork.")))

!(assertEqual
  (codex:multi-agent-find-spawn-agent-model-name
    ("gpt-5.2" "gpt-5.2-codex")
    "gpt-5.2-codex")
  (codex:multi-agent-common-ok "gpt-5.2-codex"))

!(assertEqual
  (codex:multi-agent-find-spawn-agent-model-name
    ("gpt-5.2" "gpt-5.2-codex")
    "gpt-4.1")
  (codex:multi-agent-common-err
    (codex:function-call-error-respond-to-model
      "Unknown model `gpt-4.1` for spawn_agent. Available models: gpt-5.2, gpt-5.2-codex")))

!(assertEqual
  (codex:multi-agent-validate-spawn-agent-reasoning-effort
    "gpt-5.2-codex"
    ("low" "medium" "high")
    "high")
  (codex:multi-agent-common-ok ()))

!(assertEqual
  (codex:multi-agent-validate-spawn-agent-reasoning-effort
    "gpt-5.2-codex"
    ("medium" "high")
    "xhigh")
  (codex:multi-agent-common-err
    (codex:function-call-error-respond-to-model
      "Reasoning effort `xhigh` is not supported for model `gpt-5.2-codex`. Supported reasoning efforts: medium, high")))
