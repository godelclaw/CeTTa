!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqual
  (json-stringify
    (codex:guardian-assessment-event-json
      (codex:guardian-assessment-event
        "ga_42"
        "item_7"
        "turn_99"
        (codex:guardian-assessment-status-denied)
        (codex:guardian-risk-level-high)
        (codex:guardian-user-authorization-medium)
        "User did not authorize destructive changes."
        (codex:guardian-assessment-decision-source-agent)
        (codex:guardian-assessment-action-command
          (codex:guardian-command-source-shell)
          "rm -rf build"
          "/repo"))))
  "{\"id\":\"ga_42\",\"turn_id\":\"turn_99\",\"status\":\"denied\",\"action\":{\"type\":\"command\",\"source\":\"shell\",\"command\":\"rm -rf build\",\"cwd\":\"/repo\"},\"target_item_id\":\"item_7\",\"risk_level\":\"high\",\"user_authorization\":\"medium\",\"rationale\":\"User did not authorize destructive changes.\",\"decision_source\":\"agent\"}")

!(assertEqual
  (json-stringify
    (codex:op-json
      (codex:approve-guardian-denied-action-op
        (codex:guardian-assessment-event
          "ga_42"
          "item_7"
          "turn_99"
          (codex:guardian-assessment-status-denied)
          (codex:guardian-risk-level-high)
          (codex:guardian-user-authorization-medium)
          "User did not authorize destructive changes."
          (codex:guardian-assessment-decision-source-agent)
          (codex:guardian-assessment-action-command
            (codex:guardian-command-source-shell)
            "rm -rf build"
            "/repo")))))
  "{\"type\":\"approve_guardian_denied_action\",\"event\":{\"id\":\"ga_42\",\"turn_id\":\"turn_99\",\"status\":\"denied\",\"action\":{\"type\":\"command\",\"source\":\"shell\",\"command\":\"rm -rf build\",\"cwd\":\"/repo\"},\"target_item_id\":\"item_7\",\"risk_level\":\"high\",\"user_authorization\":\"medium\",\"rationale\":\"User did not authorize destructive changes.\",\"decision_source\":\"agent\"}}")
