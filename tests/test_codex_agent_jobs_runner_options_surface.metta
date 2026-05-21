!(register-module! ../codex)
!(import! &self codex:agent_jobs)
!(import! &self codex:agent_jobs_runner_options)
!(import! &self codex:function_tool)
!(import! &self codex:protocol)

!(assertEqual
  (codex:agent-job-required-state-db CodexAbsent)
  (codex:agent-job-err
    (codex:function-call-error-fatal
      "sqlite state db is unavailable for this session")))

!(assertEqual
  (codex:agent-job-required-state-db state-db-1)
  (codex:agent-job-ok state-db-1))

!(assertEqual
  (codex:agent-job-session-depth (codex:session-source-cli))
  0)

!(assertEqual
  (codex:agent-job-session-depth
    (codex:session-source-subagent
      (codex:subagent-source-review)))
  0)

!(assertEqual
  (codex:agent-job-session-depth
    (codex:session-source-subagent
      (codex:subagent-source-thread-spawn
        "/root"
        2
        CodexAbsent
        CodexAbsent
        CodexAbsent)))
  2)

!(assertEqual
  (codex:agent-job-next-thread-spawn-depth (codex:session-source-cli))
  1)

!(assertEqual
  (codex:agent-job-next-thread-spawn-depth
    (codex:session-source-subagent
      (codex:subagent-source-thread-spawn
        "/root"
        2
        CodexAbsent
        CodexAbsent
        CodexAbsent)))
  3)

!(assertEqual
  (codex:agent-job-saturating-add-one-i32 2147483647)
  2147483647)

!(assertEqual
  (codex:agent-job-exceeds-thread-spawn-depth-limit 2 1)
  True)

!(assertEqual
  (codex:agent-job-exceeds-thread-spawn-depth-limit 1 1)
  False)

!(assertEqual
  (codex:agent-job-build-runner-options
    (codex:session-source-subagent
      (codex:subagent-source-thread-spawn
        "/root"
        1
        CodexAbsent
        CodexAbsent
        CodexAbsent))
    1
    CodexAbsent
    4
    (codex:agent-job-err
      (codex:function-call-error-respond-to-model "spawn config failed")))
  (codex:agent-job-err
    (codex:function-call-error-respond-to-model
      "agent depth limit reached; this session cannot spawn more subagents")))

!(assertEqual
  (codex:agent-job-build-runner-options
    (codex:session-source-cli)
    1
    12
    20
    (codex:agent-job-ok spawn-config-1))
  (codex:agent-job-ok
    (codex:agent-job-runner-options 12 spawn-config-1)))

!(assertEqual
  (codex:agent-job-build-runner-options
    (codex:session-source-cli)
    1
    CodexAbsent
    2
    (codex:agent-job-err
      (codex:function-call-error-respond-to-model "approval_policy is invalid: bad")))
  (codex:agent-job-err
    (codex:function-call-error-respond-to-model
      "approval_policy is invalid: bad")))
