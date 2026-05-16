!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:user-message "Inspect the repo.")))
  ("{\"type\":\"message\",\"role\":\"user\",\"content\":[{\"type\":\"input_text\",\"text\":\"Inspect the repo.\"}]}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:final-response "Done.")))
  ("{\"type\":\"message\",\"role\":\"assistant\",\"content\":[{\"type\":\"output_text\",\"text\":\"Done.\"}],\"phase\":\"final_answer\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:tool-call "call_1" "exec_command" "{\"cmd\":\"pwd\"}")))
  ("{\"type\":\"custom_tool_call\",\"call_id\":\"call_1\",\"name\":\"exec_command\",\"input\":\"{\\\"cmd\\\":\\\"pwd\\\"}\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:tool-result "call_1" "ok")))
  ("{\"type\":\"custom_tool_call_output\",\"call_id\":\"call_1\",\"output\":\"ok\"}"))

!(assertEqualToResult
  (codex:message-phase
    (codex:final-response "Done."))
  ("final_answer"))

!(assertEqualToResult
  (json-stringify
    (codex:items-json
      ((codex:user-message "u")
       (codex:assistant-message "a"))))
  ("[{\"type\":\"message\",\"role\":\"user\",\"content\":[{\"type\":\"input_text\",\"text\":\"u\"}]},{\"type\":\"message\",\"role\":\"assistant\",\"content\":[{\"type\":\"output_text\",\"text\":\"a\"}]}]"))

!(assertEqualToResult
  (codex:error-event-affects-turn-status
    (codex:error-event
      "rollback failed"
      (codex:codex-error-info-thread-rollback-failed)))
  (False))

!(assertEqualToResult
  (codex:error-event-affects-turn-status
    (codex:error-event
      "cannot steer"
      (codex:codex-error-info-active-turn-not-steerable
        (codex:non-steerable-turn-kind-review))))
  (False))

!(assertEqualToResult
  (codex:error-event-affects-turn-status
    (codex:error-event
      "generic"
      (codex:codex-error-info-other)))
  (True))

!(assertEqualToResult
  (codex:error-event-affects-turn-status
    (codex:error-event "message only" CodexAbsent))
  (True))
