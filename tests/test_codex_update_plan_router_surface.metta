!(register-module! ../codex)
!(import! &self codex:protocol)
!(import! &self codex:tools)

(= (codex-update-plan-router-input)
   "{\"plan\":[{\"step\":\"Inspect workspace\",\"status\":\"in_progress\"}]}")

!(assertEqualToResult
  (codex:tool-result-output-text
    (once
      (codex:run-tool-call-item
        (CodexResponseItemCustomToolCall
          "call-up-raw"
          "update_plan"
          (codex-update-plan-router-input)))))
  ("Plan updated"))

!(assertEqualToResult
  (codex:tool-result-output-text
    (once
      (codex:run-tool-call-item
        (codex:tool-call
          "call-up-helper"
          "update_plan"
          (codex-update-plan-router-input)))))
  ("Plan updated"))
