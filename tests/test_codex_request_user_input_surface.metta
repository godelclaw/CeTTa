!(register-module! ../codex)
!(import! &self json)
!(import! &self list)
!(import! &self codex:protocol)
!(import! &self codex:request_user_input)
!(import! &self codex:tools)
!(import! &self codex:turn)

(= (codex-rui-test-args)
   (codex:request-user-input-args
     ((codex:request-user-input-basic-question
        "choice"
        "Pick"
        "Choose one."
        ((codex:request-user-input-option
           "A (Recommended)"
           "Prefer the stable path.")
         (codex:request-user-input-option
           "B"
           "Use the alternate path."))))))

(= (codex-rui-test-input-json)
   (json-stringify (codex:request-user-input-args-json (codex-rui-test-args))))

(= (codex-rui-test-response)
   (codex:request-user-input-response
     ((codex:request-user-input-response-entry
        "choice"
        (codex:request-user-input-answer
          ("A (Recommended)" "note: keep the stable path"))))))

(= (codex-rui-plan-context)
   (codex:request-user-input-handler-context
     (codex:collaboration-mode-plan)
     False
     "turn-rui"
     (codex:request-user-input-session-source-root)
     (codex:request-user-input-response-behavior-return
       (codex-rui-test-response))))

(= (codex-rui-subagent-context)
   (codex:request-user-input-handler-context
     (codex:collaboration-mode-plan)
     False
     "turn-rui"
     (codex:request-user-input-session-source-subagent)
     (codex:request-user-input-response-behavior-return
       (codex-rui-test-response))))

!(assertEqualToResult
  (codex-rui-test-input-json)
  ("{\"questions\":[{\"id\":\"choice\",\"header\":\"Pick\",\"question\":\"Choose one.\",\"isOther\":false,\"isSecret\":false,\"options\":[{\"label\":\"A (Recommended)\",\"description\":\"Prefer the stable path.\"},{\"label\":\"B\",\"description\":\"Use the alternate path.\"}]}]}"))

!(assertEqualToResult
  (codex:request-user-input-question-is-other
    (list:first
      (codex:request-user-input-args-questions
        (codex:request-user-input-normalize-result-args
          (codex:normalize-request-user-input-args
            (codex-rui-test-args))))))
  (True))

!(assertEqualToResult
  (codex:request-user-input-normalize-result-message
    (codex:normalize-request-user-input-args
      (codex:request-user-input-args
        ((codex:request-user-input-question
           "choice"
           "Pick"
           "Choose one."
           False
           False
           ())))))
  ("request_user_input requires non-empty options for every question"))

!(assertEqual
  (codex:request-user-input-unavailable-message
    (codex:collaboration-mode-plan)
    False)
  Empty)

!(assertEqualToResult
  (codex:request-user-input-unavailable-message
    (codex:collaboration-mode-default)
    False)
  ("request_user_input is unavailable in Default mode"))

!(assertEqualToResult
  (codex:request-user-input-tool-description True)
  ("Request user input for one to three short questions and wait for the response. This tool is only available in Default or Plan mode."))

!(assertEqualToResult
  (let $result
    (codex:handle-request-user-input-payload
      (codex-rui-plan-context)
      "call-rui"
      (codex:request-user-input-function-payload
        (codex-rui-test-input-json)))
    (json-stringify
      (codex:request-user-input-event-json
        (codex:request-user-input-handler-result-event $result))))
  ("{\"call_id\":\"call-rui\",\"turn_id\":\"turn-rui\",\"questions\":[{\"id\":\"choice\",\"header\":\"Pick\",\"question\":\"Choose one.\",\"isOther\":true,\"isSecret\":false,\"options\":[{\"label\":\"A (Recommended)\",\"description\":\"Prefer the stable path.\"},{\"label\":\"B\",\"description\":\"Use the alternate path.\"}]}]}"))

!(assertEqualToResult
  (let $result
    (codex:handle-request-user-input-payload
      (codex-rui-plan-context)
      "call-rui"
      (codex:request-user-input-function-payload
        (codex-rui-test-input-json)))
    (codex:request-user-input-handler-result-output-text $result))
  ("{\"answers\":{\"choice\":{\"answers\":[\"A (Recommended)\",\"note: keep the stable path\"]}}}"))

!(assertEqualToResult
  (codex:request-user-input-handler-result-message
    (codex:handle-request-user-input-payload
      (codex-rui-subagent-context)
      "call-rui"
      (codex:request-user-input-function-payload
        (codex-rui-test-input-json))))
  ("request_user_input can only be used by the root thread"))

!(assertEqualToResult
  (codex:request-user-input-handler-result-message
    (codex:handle-request-user-input-payload
      (codex-rui-plan-context)
      "call-rui"
      (codex:request-user-input-unsupported-payload "custom")))
  ("request_user_input handler received unsupported payload"))

!(assertEqualToResult
  (codex:tool-result-output-text
    (codex:run-tool-call-item
      (codex:tool-call
        "call-rui-default"
        "request_user_input"
        (codex-rui-test-input-json))))
  ("request_user_input is unavailable in Default mode"))
