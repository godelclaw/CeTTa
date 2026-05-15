!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)
!(import! &self codex:request_user_input)
!(import! &self codex:update_plan)

(= (codex-up-step-1)
   (codex:update-plan-step
     "Inspect workspace"
     (codex:update-plan-step-status-in-progress)))

(= (codex-up-step-2)
   (codex:update-plan-step
     "Report results"
     (codex:update-plan-step-status-pending)))

(= (codex-up-args)
   (codex:update-plan-args
     "Tool harness check"
     ((codex-up-step-1)
      (codex-up-step-2))))

(= (codex-up-input-json)
   (json-stringify (codex:update-plan-args-json (codex-up-args))))

(= (codex-up-default-context)
   (codex:update-plan-handler-context
     (codex:collaboration-mode-default)))

(= (codex-up-plan-context)
   (codex:update-plan-handler-context
     (codex:collaboration-mode-plan)))

!(assertEqualToResult
  (codex:update-plan-tool-name)
  ("update_plan"))

!(assertEqualToResult
  (codex:update-plan-tool-description)
  ("Updates the task plan.\nProvide an optional explanation and a list of plan items, each with a step and status.\nAt most one step can be in_progress at a time.\n"))

!(assertEqualToResult
  (codex-up-input-json)
  ("{\"explanation\":\"Tool harness check\",\"plan\":[{\"step\":\"Inspect workspace\",\"status\":\"in_progress\"},{\"step\":\"Report results\",\"status\":\"pending\"}]}"))

!(assertEqualToResult
  (json-stringify
    (codex:update-plan-args-json
      (codex:update-plan-args-without-explanation
        ((codex:update-plan-step
           "Finish port"
           (codex:update-plan-step-status-completed))))))
  ("{\"explanation\":null,\"plan\":[{\"step\":\"Finish port\",\"status\":\"completed\"}]}"))

!(assertEqualToResult
  (codex:update-plan-handler-result-message
    (codex:handle-update-plan-payload
      (codex-up-default-context)
      "call-up"
      (codex:update-plan-function-payload
        "{\"explanation\":\"Missing plan data\"}")))
  ("failed to parse function arguments: missing field `plan`"))

!(assertEqualToResult
  (codex:update-plan-handler-result-message
    (codex:handle-update-plan-payload
      (codex-up-default-context)
      "call-up"
      (codex:update-plan-function-payload
        "{\"plan\":[{\"step\":\"Inspect workspace\",\"status\":\"blocked\"}]}")))
  ("failed to parse function arguments: unknown variant `blocked`, expected one of `pending`, `in_progress`, `completed`"))

!(assertEqualToResult
  (codex:update-plan-handler-result-message
    (codex:handle-update-plan-payload
      (codex-up-plan-context)
      "call-up"
      (codex:update-plan-function-payload
        (codex-up-input-json))))
  ("update_plan is a TODO/checklist tool and is not allowed in Plan mode"))

!(assertEqualToResult
  (codex:update-plan-handler-result-message
    (codex:handle-update-plan-payload
      (codex-up-default-context)
      "call-up"
      (codex:update-plan-unsupported-payload "custom")))
  ("update_plan handler received unsupported payload"))
