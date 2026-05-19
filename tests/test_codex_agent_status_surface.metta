!(register-module! ../codex)
!(import! &self codex:agent_status)

!(assertEqual
  (codex:agent-status-from-event
    (codex:turn-started-event
      "turn-1"
      CodexAbsent
      CodexAbsent
      (codex:mode-kind-default)))
  (codex:protocol-agent-status-running))

!(assertEqual
  (codex:agent-status-from-event
    (codex:turn-complete-event
      "turn-1"
      "done"
      CodexAbsent
      CodexAbsent
      CodexAbsent))
  (codex:protocol-agent-status-completed "done"))

!(assertEqual
  (codex:agent-status-from-event
    (codex:turn-complete-event
      "turn-1"
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent))
  (codex:protocol-agent-status-completed CodexAbsent))

!(assertEqual
  (codex:agent-status-from-event
    (codex:error-event
      "boom"
      CodexAbsent))
  (codex:protocol-agent-status-errored "boom"))

!(assertEqual
  (codex:agent-status-from-event
    (codex:turn-aborted-event
      "turn-1"
      (codex:turn-abort-reason-interrupted)
      CodexAbsent
      CodexAbsent))
  (codex:protocol-agent-status-interrupted))

!(assertEqual
  (codex:agent-status-from-event
    (codex:turn-aborted-event
      "turn-1"
      (codex:turn-abort-reason-replaced)
      CodexAbsent
      CodexAbsent))
  (codex:protocol-agent-status-errored "Replaced"))

!(assertEqual
  (codex:agent-status-from-event
    (codex:turn-aborted-event
      "turn-1"
      (codex:turn-abort-reason-review-ended)
      CodexAbsent
      CodexAbsent))
  (codex:protocol-agent-status-errored "ReviewEnded"))

!(assertEqual
  (codex:agent-status-from-event
    (codex:shutdown-complete-event))
  (codex:protocol-agent-status-shutdown))

!(assertEqual
  (codex:agent-status-from-event
    (codex:warning-event "heads up"))
  CodexAbsent)

!(assertEqual
  (codex:is-agent-status-final
    (codex:protocol-agent-status-pending-init))
  False)

!(assertEqual
  (codex:is-agent-status-final
    (codex:protocol-agent-status-running))
  False)

!(assertEqual
  (codex:is-agent-status-final
    (codex:protocol-agent-status-interrupted))
  False)

!(assertEqual
  (codex:is-agent-status-final
    (codex:protocol-agent-status-completed CodexAbsent))
  True)

!(assertEqual
  (codex:is-agent-status-final
    (codex:protocol-agent-status-errored "boom"))
  True)

!(assertEqual
  (codex:is-agent-status-final
    (codex:protocol-agent-status-shutdown))
  True)

!(assertEqual
  (codex:is-agent-status-final
    (codex:protocol-agent-status-not-found))
  True)
