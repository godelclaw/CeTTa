!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:op-type
    (codex:user-input-answer-op
      "turn_123"
      (codex:protocol-request-user-input-response
        ((codex:protocol-request-user-input-response-entry
           "q1"
           (codex:protocol-request-user-input-answer ("yes")))))))
  ("user_input_answer"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:user-input-answer-op
        "turn_123"
        (codex:protocol-request-user-input-response
          ((codex:protocol-request-user-input-response-entry
             "q1"
             (codex:protocol-request-user-input-answer ("yes"))))))))
  ("{\"type\":\"user_input_answer\",\"id\":\"turn_123\",\"response\":{\"answers\":{\"q1\":{\"answers\":[\"yes\"]}}}}"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:user-input-answer-op
        "turn_456"
        (codex:protocol-request-user-input-response
          ((codex:protocol-request-user-input-response-entry
             "q1"
             (codex:protocol-request-user-input-answer ("yes" "later")))
           (codex:protocol-request-user-input-response-entry
             "q2"
             (codex:protocol-request-user-input-answer ("blue"))))))))
  ("{\"type\":\"user_input_answer\",\"id\":\"turn_456\",\"response\":{\"answers\":{\"q1\":{\"answers\":[\"yes\",\"later\"]},\"q2\":{\"answers\":[\"blue\"]}}}}"))
