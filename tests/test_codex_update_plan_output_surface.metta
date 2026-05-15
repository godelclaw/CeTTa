!(register-module! ../codex)
!(import! &self codex:update_plan)

(= (codex-up-input-json)
   "{\"explanation\":\"Tool harness check\",\"plan\":[{\"step\":\"Inspect workspace\",\"status\":\"in_progress\"},{\"step\":\"Report results\",\"status\":\"pending\"}]}")

(= (codex-up-default-context)
   (codex:update-plan-handler-context
     (codex:collaboration-mode-default)
     (codex:update-plan-response-behavior-return)))

!(assertEqualToResult
  (codex:update-plan-handler-result-output-text
    (codex:handle-update-plan-payload
      (codex-up-default-context)
      "call-up"
      (codex:update-plan-function-payload
        (codex-up-input-json))))
  ("Plan updated"))
