!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:update_plan)

(= (codex-up-input-json)
   "{\"explanation\":\"Tool harness check\",\"plan\":[{\"step\":\"Inspect workspace\",\"status\":\"in_progress\"},{\"step\":\"Report results\",\"status\":\"pending\"}]}")

(= (codex-up-default-context)
   (codex:update-plan-handler-context
     (codex:collaboration-mode-default)
     (codex:update-plan-response-behavior-return)))

!(assertEqualToResult
  (json-stringify
    (codex:update-plan-event-json
      (codex:update-plan-handler-result-event
        (codex:handle-update-plan-payload
          (codex-up-default-context)
          "call-up"
          (codex:update-plan-function-payload
            (codex-up-input-json))))))
  ("{\"explanation\":\"Tool harness check\",\"plan\":[{\"step\":\"Inspect workspace\",\"status\":\"in_progress\"},{\"step\":\"Report results\",\"status\":\"pending\"}]}"))
