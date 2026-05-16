!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

(= (codex-ga)
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
       "/repo")))

!(assertEqualToResult
  (codex:item-type
    (codex-ga))
  ("guardian_assessment"))
