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

!(assertEqualToResult
  (codex:tool-result-output-text
    (list:at
      (codex:fixture-steps-items
        ((codex:fixture-request-user-input-step
           "call-rui"
           (codex-rui-test-input-json)
           (codex-rui-plan-context))))
      1))
  ("{\"answers\":{\"choice\":{\"answers\":[\"A (Recommended)\",\"note: keep the stable path\"]}}}"))
