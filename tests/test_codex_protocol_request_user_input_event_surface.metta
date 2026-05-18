!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:item-type
    (codex:protocol-request-user-input-event
      "call-rui"
      ""
      ((codex:protocol-request-user-input-question
         "free"
         "Note"
         "What changed?"
         False
         True
         CodexAbsent))))
  ("request_user_input"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:protocol-request-user-input-event
        "call-rui"
        ""
        ((codex:protocol-request-user-input-question
           "free"
           "Note"
           "What changed?"
           False
           True
           CodexAbsent)))))
  ("{\"type\":\"request_user_input\",\"call_id\":\"call-rui\",\"turn_id\":\"\",\"questions\":[{\"id\":\"free\",\"header\":\"Note\",\"question\":\"What changed?\",\"isOther\":false,\"isSecret\":true}]}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:protocol-request-user-input-event
        "call-rui-2"
        "turn-rui"
        ((codex:protocol-request-user-input-question
           "choice"
           "Pick"
           "Choose one."
           True
           False
           ((codex:protocol-request-user-input-question-option
              "A (Recommended)"
              "Prefer the stable path.")
            (codex:protocol-request-user-input-question-option
              "B"
              "Use the alternate path.")))))))
  ("{\"type\":\"request_user_input\",\"call_id\":\"call-rui-2\",\"turn_id\":\"turn-rui\",\"questions\":[{\"id\":\"choice\",\"header\":\"Pick\",\"question\":\"Choose one.\",\"isOther\":true,\"isSecret\":false,\"options\":[{\"label\":\"A (Recommended)\",\"description\":\"Prefer the stable path.\"},{\"label\":\"B\",\"description\":\"Use the alternate path.\"}]}]}"))
