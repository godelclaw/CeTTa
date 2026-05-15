!(register-module! ../codex)
!(import! &self codex:update_plan)
!(import! &self codex:protocol)

(= (codex-up-input-json)
   "{\"explanation\":\"Tool harness check\",\"plan\":[{\"step\":\"Inspect workspace\",\"status\":\"in_progress\"},{\"step\":\"Report results\",\"status\":\"pending\"}]}")

!(assertEqual
  (once
    (codex:tool-result-output-text
      (once
        (codex:run-update-plan-tool-call
          "call-up"
          (codex-up-input-json)))))
  "Plan updated")
