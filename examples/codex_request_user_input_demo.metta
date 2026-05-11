!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:request_user_input)
!(import! &self codex:turn)

(= (codex-rui-demo-args)
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

(= (codex-rui-demo-input-json)
   (json-stringify (codex:request-user-input-args-json (codex-rui-demo-args))))

(= (codex-rui-demo-response)
   (codex:request-user-input-response
     ((codex:request-user-input-response-entry
        "choice"
        (codex:request-user-input-answer
          ("A (Recommended)" "note: keep the stable path"))))))

(= (codex-rui-demo-context)
   (codex:request-user-input-handler-context
     (codex:collaboration-mode-plan)
     False
     "turn-demo-rui"
     (codex:request-user-input-session-source-root)
     (codex:request-user-input-response-behavior-return
       (codex-rui-demo-response))))

(= (codex-rui-demo-result)
   (codex:handle-request-user-input-payload
     (codex-rui-demo-context)
     "call-rui-demo"
     (codex:request-user-input-function-payload
       (codex-rui-demo-input-json))))

!(println! "=== Codex request_user_input demo ===")
!(println! (codex:request-user-input-tool-description False))
!(println!
  (json-stringify
    (codex:request-user-input-event-json
      (codex:request-user-input-handler-result-event
        (codex-rui-demo-result)))))
!(println!
  (codex:request-user-input-handler-result-output-text
    (codex-rui-demo-result)))

!(println!
  (json-stringify
    (codex:fixture-turn-json
      (codex:run-fixture-turn
        ((codex:fixture-user-step "Ask the user before continuing.")
         (codex:fixture-commentary-step "Need user input before answering.")
         (codex:fixture-request-user-input-step
           "call-rui-demo"
           (codex-rui-demo-input-json)
           (codex-rui-demo-context))
         (codex:fixture-final-step "User input captured."))))))
